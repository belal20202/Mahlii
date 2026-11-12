import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../models/receipt.dart';
import '../../widgets/product_thumb.dart';
import '../auth/auth_providers.dart';
import '../permissions.dart';
import '../products/product_form.dart';
import '../providers.dart';
import '../sales/product_picker.dart';
import 'receipts_log_screen.dart';

class _RLine {
  final Product product;
  int qty;
  _RLine(this.product, [this.qty = 1]);
}

/// إضافة بضاعة (مشتريات): امسح الباركود، ثم أكّد الإدخال ليُصدر رقم سجل.
class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final List<_RLine> _lines = [];
  MobileScannerController? _sc;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _saving = false;

  @override
  void dispose() {
    _sc?.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  void _stopScan() {
    if (_sc == null) return;
    final old = _sc;
    setState(() => _sc = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  void _toggleScan() {
    if (_sc != null) {
      _stopScan();
    } else {
      setState(() => _sc =
          MobileScannerController(detectionSpeed: DetectionSpeed.normal));
    }
  }

  int get _totalPieces => _lines.fold(0, (a, l) => a + l.qty);

  void _addProduct(Product p) {
    final i = _lines.indexWhere((l) => l.product.id == p.id);
    setState(() {
      if (i >= 0) {
        _lines[i].qty++;
      } else {
        _lines.insert(0, _RLine(p));
      }
    });
    SoundService.play(Sfx.added);
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
    if (p != null) {
      _addProduct(p);
      return;
    }
    await SoundService.play(Sfx.error);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('منتج غير مسجل'),
        action: SnackBarAction(
            label: 'إضافته', onPressed: () => _createNew(code)),
      ));
  }

  Future<void> _createNew(String code) async {
    _stopScan();
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductForm(initialBarcode: code)));
    final p = await ref.read(repoProvider).findByBarcode(code);
    if (p != null && mounted) _addProduct(p);
  }

  Future<void> _editQty(int i) async {
    final c = TextEditingController(text: '${_lines[i].qty}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_lines[i].product.name),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'عدد القطع'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(c.text.trim());
              if (n != null && n > 0) Navigator.pop(ctx, n);
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
    c.dispose();
    if (v != null) setState(() => _lines[i].qty = v);
  }

  Future<void> _save() async {
    final s = ref.read(bootProvider).valueOrNull?.session;
    if (!canPurchase(s)) {
      _msg('ليس لديك صلاحية إضافة البضاعة');
      return;
    }
    if (!canWriteNow(ref)) {
      _msg(kExpiredMsg);
      return;
    }
    if (_lines.isEmpty) {
      _msg('أضف منتجاً واحداً على الأقل');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الإدخال'),
        content: Text(
            'سيتم إضافة $_totalPieces قطعة من ${_lines.length} صنف إلى المخزن، وإصدار رقم في السجل.'),
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
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      final r = await ref.read(receiptRepoProvider).create(
            lines: [
              for (final l in _lines)
                ReceiptLine(product: l.product, qty: l.qty)
            ],
            userName: s!.userName,
          );
      refreshData(ref);
      _stopScan();
      await SoundService.play(Sfx.invoice);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تم الإدخال'),
          content: Text(
              'رقم السجل: ${r.number}\n${r.totalPieces} قطعة من ${r.itemsCount} صنف'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تم')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      await SoundService.play(Sfx.error);
      _msg('تعذر حفظ الإدخال');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة بضاعة'),
        actions: [
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReceiptsLogScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                icon: Icon(_sc == null
                    ? Icons.qr_code_scanner
                    : Icons.stop_circle_outlined),
                label: Text(_sc == null ? 'مسح الباركود' : 'إيقاف الكاميرا'),
                onPressed: _toggleScan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.search),
                label: const Text('بحث يدوي'),
                onPressed: () async {
                  final p = await pickProduct(context);
                  if (p != null) _addProduct(p);
                },
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
          if (_lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('امسح باركود المنتجات الواصلة لتسجيلها',
                      textAlign: TextAlign.center)),
            ),
          for (var i = 0; i < _lines.length; i++) _lineCard(i),
          if (_lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${_lines.length} صنف')),
              Text('$_totalPieces قطعة',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald)),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: _saving ? null : _save,
              label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد الإدخال'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineCard(int i) {
    final l = _lines[i];
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
                Text('الرصيد الحالي: ${l.product.qtyPieces}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Row(children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (l.qty > 1) setState(() => l.qty--);
                      },
                      icon: const Icon(Icons.remove_circle_outline)),
                  InkWell(
                    onTap: () => _editQty(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text('${l.qty}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => l.qty++),
                      icon: const Icon(Icons.add_circle_outline)),
                ]),
              ],
            ),
          ),
          IconButton(
              onPressed: () => setState(() => _lines.removeAt(i)),
              icon: const Icon(Icons.close, size: 20)),
        ]),
      ),
    );
  }
}
