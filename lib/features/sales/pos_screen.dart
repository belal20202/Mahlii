import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../repositories/invoice_repository.dart';
import '../auth/auth_providers.dart';
import '../invoices/invoice_detail_screen.dart';
import '../permissions.dart';
import '../providers.dart';
import 'cart.dart';
import 'product_picker.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _discount = TextEditingController();
  final _paid = TextEditingController();
  final _customer = TextEditingController();
  String _method = 'cash';
  bool _saving = false;
  MobileScannerController? _sc;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _discount.dispose();
    _paid.dispose();
    _customer.dispose();
    _sc?.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  void _toggleScan() {
    if (_sc != null) {
      final old = _sc;
      setState(() => _sc = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    } else {
      setState(() => _sc =
          MobileScannerController(detectionSpeed: DetectionSpeed.normal));
    }
  }

  Future<void> _onDetect(BarcodeCapture c) async {
    final code = c.barcodes.isEmpty ? null : c.barcodes.first.rawValue;
    if (code == null) return;
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastAt).inMilliseconds < 1200) {
      return;
    }
    _lastCode = code;
    _lastAt = now;
    final p = await ref.read(repoProvider).findByBarcode(code);
    if (!mounted) return;
    if (p == null) {
      await SoundService.play(Sfx.error);
      _msg('منتج غير مسجل');
      return;
    }
    _addProduct(p);
  }

  void _addProduct(Product p) {
    if (ref.read(cartProvider.notifier).add(p)) {
      SoundService.play(Sfx.sold);
    } else {
      SoundService.play(Sfx.error);
      _msg('الكمية المتوفرة من "${p.name}" غير كافية');
    }
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    final s = ref.read(bootProvider).valueOrNull?.session;
    if (!canSell(s)) {
      _msg('ليس لديك صلاحية البيع');
      return;
    }
    if (!canWriteNow(ref)) {
      _msg(kExpiredMsg);
      return;
    }
    final lines = ref.read(cartProvider);
    if (lines.isEmpty) {
      _msg('السلة فارغة');
      return;
    }
    final sub = lines.fold<int>(0, (a, l) => a + l.total);
    final disc = _int(_discount).clamp(0, sub);
    final total = sub - disc;
    final paid = _int(_paid);
    if (_method != 'cash' && _customer.text.trim().isEmpty) {
      _msg('أدخل اسم العميل للبيع الآجل أو الجزئي');
      return;
    }
    if (_method == 'partial' && (paid <= 0 || paid >= total)) {
      _msg('في الدفع الجزئي يجب أن يكون المدفوع أكبر من صفر وأقل من الإجمالي');
      return;
    }
    setState(() => _saving = true);
    try {
      final inv = await ref.read(invoiceRepoProvider).createSale(
            lines: lines,
            discount: disc,
            method: _method,
            paid: paid,
            customer: _customer.text,
            userName: s!.userName,
          );
      ref.read(cartProvider.notifier).clear();
      refreshData(ref);
      _discount.clear();
      _paid.clear();
      _customer.clear();
      setState(() => _method = 'cash');
      await SoundService.play(Sfx.sold);
      if (mounted) _showDone(inv);
    } on InsufficientStockException catch (e) {
      await SoundService.play(Sfx.error);
      _msg('الكمية غير كافية للمنتج: ${e.productName}');
    } catch (_) {
      await SoundService.play(Sfx.error);
      _msg('تعذر حفظ الفاتورة');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDone(Invoice inv) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم حفظ الفاتورة'),
        content: Text('${inv.number}\nالإجمالي: ${iqd(inv.total)}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(invoice: inv)));
            },
            child: const Text('عرض'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(bootProvider).valueOrNull?.session;
    if (!canSell(s)) {
      return const Center(child: Text('ليس لديك صلاحية البيع'));
    }
    final lines = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final sub = lines.fold<int>(0, (a, l) => a + l.total);
    final disc = _int(_discount).clamp(0, sub);
    final total = sub - disc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
                tooltip: 'تفريغ السلة',
                onPressed: cart.clear,
                icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('بحث عن منتج'),
                onPressed: () async {
                  final p = await pickProduct(context);
                  if (p != null) _addProduct(p);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                icon: Icon(_sc == null
                    ? Icons.qr_code_scanner
                    : Icons.stop_circle_outlined),
                label: Text(_sc == null ? 'مسح باركود' : 'إيقاف الكاميرا'),
                onPressed: _toggleScan,
              ),
            ),
          ]),
          if (_sc != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(controller: _sc!, onDetect: _onDetect),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('امسح باركود أو ابحث لإضافة منتجات')),
            ),
          for (var i = 0; i < lines.length; i++) _lineCard(i, lines[i], cart),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _discount,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'الخصم (د.ع)'),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('نقدي')),
                ButtonSegment(value: 'credit', label: Text('آجل')),
                ButtonSegment(value: 'partial', label: Text('جزئي')),
              ],
              selected: {_method},
              onSelectionChanged: (v) => setState(() => _method = v.first),
            ),
            if (_method == 'partial') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _paid,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'المبلغ المدفوع'),
              ),
            ],
            if (_method != 'cash') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customer,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
              ),
            ],
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Text('الإجمالي')),
              Text(iqd(total),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald)),
            ]),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الفاتورة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineCard(int i, CartLine l, CartNotifier cart) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(l.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  onPressed: () => cart.remove(i),
                  icon: const Icon(Icons.close, size: 20)),
            ]),
            Row(children: [
              IconButton(
                  onPressed: () {
                    if (l.qty > 1) cart.setQty(i, l.qty - 1);
                  },
                  icon: const Icon(Icons.remove_circle_outline)),
              Text('${l.qty}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(
                  onPressed: () {
                    if (!cart.setQty(i, l.qty + 1)) {
                      SoundService.play(Sfx.error);
                      _msg('الكمية المتوفرة غير كافية');
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline)),
              if (l.product.piecesPerCarton > 1)
                TextButton(
                  onPressed: () {
                    if (!cart.switchUnit(i)) {
                      SoundService.play(Sfx.error);
                      _msg('الكمية المتوفرة غير كافية');
                    }
                  },
                  child: Text(l.carton ? 'كرتون ⇄' : 'قطعة ⇄'),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(iqd(l.total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
