import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/image_store.dart';
import '../../core/sound_service.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/product_thumb.dart';
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
  late final TextEditingController name, barcode, section, price, qty;
  late bool _hasBarcode;
  String? _image;
  bool _saving = false;
  late final Future<List<String>> _sections;

  bool get _edit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name);
    barcode =
        TextEditingController(text: p?.barcode ?? widget.initialBarcode);
    section = TextEditingController(text: p?.category);
    price = TextEditingController(text: p == null ? '' : '${p.salePrice}');
    qty = TextEditingController(text: p == null ? '' : '${p.qtyPieces}');
    _hasBarcode = p == null ? true : p.barcode != null;
    _image = p?.imagePath;
    _sections = ref.read(repoProvider).sections();
  }

  @override
  void dispose() {
    for (final c in [name, barcode, section, price, qty]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;

  Future<void> _pickImage(ImageSource s) async {
    try {
      final path = await ImageStore.pick(s);
      if (path != null && mounted) setState(() => _image = path);
    } catch (_) {
      _snack('تعذر فتح الكاميرا أو المعرض، تحقق من الأذونات');
    }
  }

  Future<void> _save() async {
    if (!canWriteNow(ref)) {
      _snack(kExpiredMsg);
      return;
    }
    if (!_key.currentState!.validate()) return;
    final session = ref.read(bootProvider).valueOrNull?.session;
    final p = Product(
      id: widget.product?.id,
      name: name.text.trim(),
      barcode: _hasBarcode ? barcode.text.trim() : null,
      internalCode: widget.product?.internalCode,
      category: section.text.trim(),
      salePrice: int.parse(price.text.trim()),
      qtyPieces: int.parse(qty.text.trim()),
      minStock: widget.product?.minStock ?? 10,
      imagePath: _image,
    );
    setState(() => _saving = true);
    try {
      final repo = ref.read(repoProvider);
      if (_edit) {
        await repo.update(p, userName: session?.userName);
        final old = widget.product!.imagePath;
        if (old != null && old != _image) await ImageStore.delete(old);
      } else {
        await repo.insert(p, userName: session?.userName);
      }
      refreshData(ref);
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
    refreshData(ref);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _gap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
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
            Center(child: ProductThumb(path: _image, size: 120)),
            const SizedBox(height: 8),
            Center(
              child: Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('كاميرا'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('المعرض'),
                ),
                if (_image != null)
                  IconButton(
                    onPressed: () => setState(() => _image = null),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('منتج بباركود')),
                ButtonSegment(
                    value: false,
                    icon: Icon(Icons.edit_outlined),
                    label: Text('بدون باركود')),
              ],
              selected: {_hasBarcode},
              onSelectionChanged: (v) =>
                  setState(() => _hasBarcode = v.first),
            ),
            _gap(),
            if (_hasBarcode)
              TextFormField(
                controller: barcode,
                validator: _req,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'الباركود',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                      if (code != null) setState(() => barcode.text = code);
                    },
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'سيُنشأ رمز داخلي للمنتج تلقائياً، وتبحث عنه بالاسم.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            _gap(),
            TextFormField(
              controller: name,
              validator: _req,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
            ),
            _gap(),
            TextFormField(
              controller: section,
              validator: _req,
              decoration: const InputDecoration(labelText: 'اسم القسم'),
            ),
            FutureBuilder<List<String>>(
              future: _sections,
              builder: (context, snap) {
                final list = snap.data ?? const <String>[];
                if (list.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(spacing: 8, children: [
                    for (final s in list)
                      ActionChip(
                        label: Text(s),
                        onPressed: () => setState(() => section.text = s),
                      ),
                  ]),
                );
              },
            ),
            _gap(),
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final r = _req(v);
                if (r != null) return r;
                if ((int.tryParse(v!.trim()) ?? 0) <= 0) {
                  return 'أدخل سعراً صحيحاً';
                }
                return null;
              },
              decoration: const InputDecoration(labelText: 'سعر البيع (د.ع)'),
            ),
            _gap(),
            TextFormField(
              controller: qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _req,
              decoration:
                  const InputDecoration(labelText: 'عدد القطع المتوفرة'),
            ),
            const SizedBox(height: 20),
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
