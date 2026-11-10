import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound_service.dart';
import '../../core/units.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../auth/auth_providers.dart';
import '../barcode/scan_screen.dart';
import '../providers.dart';

class ProductForm extends ConsumerStatefulWidget {
  final Product? product;
  final String? initialBarcode;
  const ProductForm({super.key, this.product, this.initialBarcode});

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController name, barcode, category, maker, cost, sale,
      perCarton, cartons, pieces, minStock;
  bool _saving = false;

  bool get _edit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final per = p?.piecesPerCarton ?? 1;
    name = TextEditingController(text: p?.name);
    barcode =
        TextEditingController(text: p?.barcode ?? widget.initialBarcode);
    category = TextEditingController(text: p?.category);
    maker = TextEditingController(text: p?.manufacturer);
    cost = TextEditingController(text: p == null ? '' : '${p.costPrice}');
    sale = TextEditingController(text: p == null ? '' : '${p.salePrice}');
    perCarton = TextEditingController(text: '$per');
    cartons =
        TextEditingController(text: p == null ? '0' : '${p.qtyPieces ~/ per}');
    pieces =
        TextEditingController(text: p == null ? '0' : '${p.qtyPieces % per}');
    minStock = TextEditingController(text: '${p?.minStock ?? 10}');
  }

  @override
  void dispose() {
    for (final c in [
      name,
      barcode,
      category,
      maker,
      cost,
      sale,
      perCarton,
      cartons,
      pieces,
      minStock
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;

  String? _num(String? v) =>
      (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null)
          ? 'أدخل رقماً صحيحاً'
          : null;

  Future<void> _save() async {
    if (!canWriteNow(ref)) {
      _snack(kExpiredMsg);
      return;
    }
    if (!_key.currentState!.validate()) return;
    final per = _n(perCarton) < 1 ? 1 : _n(perCarton);
    final p = Product(
      id: widget.product?.id,
      name: name.text.trim(),
      barcode: barcode.text.trim().isEmpty ? null : barcode.text.trim(),
      internalCode: widget.product?.internalCode,
      category: category.text.trim().isEmpty ? null : category.text.trim(),
      manufacturer: maker.text.trim().isEmpty ? null : maker.text.trim(),
      costPrice: _n(cost),
      salePrice: _n(sale),
      qtyPieces: Units.toPieces(
          cartons: _n(cartons), pieces: _n(pieces), perCarton: per),
      piecesPerCarton: per,
      minStock: _n(minStock),
    );
    setState(() => _saving = true);
    try {
      final repo = ref.read(repoProvider);
      _edit ? await repo.update(p) : await repo.insert(p);
      ref.invalidate(productsProvider);
      ref.invalidate(statsProvider);
      await SoundService.play(Sfx.added);
      if (mounted) Navigator.of(context).pop();
    } on DuplicateBarcodeException {
      await SoundService.play(Sfx.error);
      _snack('هذا الباركود مسجل لمنتج آخر');
    } catch (_) {
      await SoundService.play(Sfx.error);
      _snack('تعذر حفظ المنتج');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!canWriteNow(ref)) {
      _snack(kExpiredMsg);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنتج'),
        content:
            const Text('سيتم إخفاء المنتج مع الاحتفاظ بسجله. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(repoProvider)
        .softDelete(widget.product!.id!, widget.product!.name);
    ref.invalidate(productsProvider);
    ref.invalidate(statsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _field(String label, TextEditingController c,
      {String? Function(String?)? validator,
      bool number = false,
      Widget? suffix,
      void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        onChanged: onChanged,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, suffixIcon: suffix),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final margin = _n(cost) == 0
        ? '—'
        : '${(((_n(sale) - _n(cost)) / _n(cost)) * 100).toStringAsFixed(1)}%';
    return Scaffold(
      appBar: AppBar(
        title: Text(_edit ? 'تعديل منتج' : 'منتج جديد'),
        actions: [
          if (_edit)
            IconButton(
                onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('اسم المنتج', name, validator: _req),
            _field(
              'الباركود (اختياري)',
              barcode,
              suffix: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final code = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                        builder: (_) => const ScanScreen(pickMode: true)),
                  );
                  if (code != null) setState(() => barcode.text = code);
                },
              ),
            ),
            _field('التصنيف', category),
            _field('الشركة المصنعة', maker),
            Row(children: [
              Expanded(
                  child: _field('سعر الشراء (للقطعة)', cost,
                      number: true,
                      validator: _num,
                      onChanged: (_) => setState(() {}))),
              const SizedBox(width: 10),
              Expanded(
                  child: _field('سعر البيع (للقطعة)', sale,
                      number: true,
                      validator: _num,
                      onChanged: (_) => setState(() {}))),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('هامش الربح: $margin'),
            ),
            _field('عدد القطع في الكارتون', perCarton,
                number: true, validator: _num),
            Row(children: [
              Expanded(
                  child: _field('الكمية (كراتين)', cartons,
                      number: true, validator: _num)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field('الكمية (قطع)', pieces,
                      number: true, validator: _num)),
            ]),
            _field('حد التنبيه (قطع)', minStock,
                number: true, validator: _num),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
