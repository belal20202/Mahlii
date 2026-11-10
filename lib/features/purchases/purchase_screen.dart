import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../auth/auth_providers.dart';
import '../permissions.dart';
import '../providers.dart';
import '../sales/product_picker.dart';

class _PLine {
  final Product product;
  bool carton = false;
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController price;

  _PLine(this.product)
      : price = TextEditingController(text: '${product.costPrice}');

  int get per => product.piecesPerCarton < 1 ? 1 : product.piecesPerCarton;
  int get q => int.tryParse(qty.text.trim()) ?? 0;
  int get p => int.tryParse(price.text.trim()) ?? 0;

  void toggle() {
    final piece = p / (carton ? per : 1);
    carton = !carton;
    price.text = (piece * (carton ? per : 1)).round().toString();
  }

  CartLine toLine() =>
      CartLine(product: product, qty: q, carton: carton, unitPrice: p);

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final _supplier = TextEditingController();
  final _discount = TextEditingController();
  final _paid = TextEditingController();
  final List<_PLine> _lines = [];
  bool _paidAll = true;
  bool _saving = false;

  @override
  void dispose() {
    _supplier.dispose();
    _discount.dispose();
    _paid.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _subtotal => _lines.fold(0, (a, l) => a + l.q * l.p);

  Future<void> _save() async {
    final s = ref.read(bootProvider).valueOrNull?.session;
    if (!canPurchase(s)) {
      _msg('ليس لديك صلاحية المشتريات');
      return;
    }
    if (!canWriteNow(ref)) {
      _msg(kExpiredMsg);
      return;
    }
    if (_supplier.text.trim().isEmpty) {
      _msg('أدخل اسم المورد');
      return;
    }
    if (_lines.isEmpty) {
      _msg('أضف منتجاً واحداً على الأقل');
      return;
    }
    if (_lines.any((l) => l.q < 1 || l.p < 0)) {
      _msg('تحقق من الكميات والأسعار');
      return;
    }
    final sub = _subtotal;
    final disc = _int(_discount).clamp(0, sub);
    final total = sub - disc;
    final paid = _paidAll ? total : _int(_paid);
    setState(() => _saving = true);
    try {
      final inv = await ref.read(invoiceRepoProvider).createPurchase(
            lines: _lines.map((l) => l.toLine()).toList(),
            discount: disc,
            paid: paid,
            supplier: _supplier.text,
            userName: s!.userName,
          );
      refreshData(ref);
      await SoundService.play(Sfx.invoice);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تم حفظ فاتورة الشراء'),
          content: Text('رقم الفاتورة: ${inv.number}\nالإجمالي: ${iqd(inv.total)}'),
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
      _msg('تعذر حفظ الفاتورة');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subtotal;
    final disc = _int(_discount).clamp(0, sub);
    final total = sub - disc;
    final paid = _paidAll ? total : _int(_paid).clamp(0, total);

    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة شراء جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _supplier,
            decoration: const InputDecoration(labelText: 'اسم المورد'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج'),
            onPressed: () async {
              final p = await pickProduct(context);
              if (p != null) setState(() => _lines.add(_PLine(p)));
            },
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _lines.length; i++) _lineCard(i),
          if (_lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _discount,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'الخصم (د.ع)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مدفوعة بالكامل'),
              value: _paidAll,
              onChanged: (v) => setState(() => _paidAll = v),
            ),
            if (!_paidAll)
              TextField(
                controller: _paid,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'المبلغ المدفوع'),
              ),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('الإجمالي')),
              Text(iqd(total),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald)),
            ]),
            Row(children: [
              const Expanded(child: Text('المتبقي للمورد')),
              Text(iqd(total - paid),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: total - paid > 0 ? AppColors.danger : null)),
            ]),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الفاتورة'),
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
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(l.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _lines.removeAt(i).dispose();
                }),
                icon: const Icon(Icons.close, size: 20),
              ),
            ]),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: l.qty,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: l.price,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      labelText:
                          l.carton ? 'سعر شراء الكرتون' : 'سعر شراء القطعة'),
                ),
              ),
              if (l.per > 1)
                TextButton(
                  onPressed: () => setState(l.toggle),
                  child: Text(l.carton ? 'كرتون ⇄' : 'قطعة ⇄'),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('المجموع: ${iqd(l.q * l.p)}'),
            ),
          ],
        ),
      ),
    );
  }
}
