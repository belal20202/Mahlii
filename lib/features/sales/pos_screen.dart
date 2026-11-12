import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../repositories/invoice_repository.dart';
import '../../widgets/barcode_camera.dart';
import '../../widgets/product_thumb.dart';
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
  bool _saving = false;
  bool _scanning = false;

  @override
  void dispose() {
    _discount.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _onCode(String code) async {
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

  Future<bool> _confirm(int total) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الدفع نقداً'),
            const SizedBox(height: 8),
            Text(iqd(total),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald)),
            const SizedBox(height: 8),
            const Text('هل استلمت المبلغ؟ سيتم إصدار الفاتورة عند التأكيد.',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد وإصدار')),
        ],
      ),
    );
    return ok == true;
  }

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
    if (!await _confirm(total)) return;

    setState(() => _saving = true);
    try {
      final Invoice inv = await ref.read(invoiceRepoProvider).createSale(
            lines: lines,
            discount: disc,
            userName: s!.userName,
          );
      ref.read(cartProvider.notifier).clear();
      refreshData(ref);
      _discount.clear();
      await SoundService.play(Sfx.sold);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoice: inv)));
      }
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
                icon: Icon(_scanning
                    ? Icons.stop_circle_outlined
                    : Icons.qr_code_scanner),
                label: Text(_scanning ? 'إيقاف الكاميرا' : 'مسح باركود'),
                onPressed: () => setState(() => _scanning = !_scanning),
              ),
            ),
          ]),
          if (_scanning)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BarcodeCamera(onCode: _onCode),
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
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Text('الإجمالي (نقداً)')),
              Text(iqd(total),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald)),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.payments_outlined),
              onPressed: _saving ? null : _save,
              label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد البيع نقداً'),
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
        child: Row(children: [
          ProductThumb(path: l.product.imagePath, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(iqd(l.unitPrice),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Row(children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (l.qty > 1) cart.setQty(i, l.qty - 1);
                      },
                      icon: const Icon(Icons.remove_circle_outline)),
                  Text('${l.qty}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (!cart.setQty(i, l.qty + 1)) {
                          SoundService.play(Sfx.error);
                          _msg('الكمية المتوفرة غير كافية');
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline)),
                  const Spacer(),
                  Text(iqd(l.total),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
          IconButton(
              onPressed: () => cart.remove(i),
              icon: const Icon(Icons.close, size: 20)),
        ]),
      ),
    );
  }
}
