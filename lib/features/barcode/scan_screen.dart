import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/sound_service.dart';
import '../../core/units.dart';
import '../../models/product.dart';
import '../auth/auth_providers.dart';
import '../products/product_form.dart';
import '../providers.dart';

/// pickMode=true: يعيد الباركود فقط (لاستخدامه داخل نموذج المنتج)
class ScanScreen extends ConsumerStatefulWidget {
  final bool pickMode;
  const ScanScreen({super.key, this.pickMode = false});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  Product? _found;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null) return;
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastAt).inMilliseconds < 1500) {
      return;
    }
    _lastCode = code;
    _lastAt = now;

    if (widget.pickMode) {
      await SoundService.play(Sfx.scan);
      if (mounted) Navigator.of(context).pop(code);
      return;
    }
    final p = await ref.read(repoProvider).findByBarcode(code);
    if (!mounted) return;
    if (p == null) {
      await SoundService.play(Sfx.error);
      setState(() => _found = null);
      _offerAdd(code);
    } else {
      await SoundService.play(Sfx.scan);
      setState(() => _found = p);
    }
  }

  void _offerAdd(String code) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('منتج غير مسجل'),
      action: SnackBarAction(
        label: 'إضافته',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductForm(initialBarcode: code))),
      ),
    ));
  }

  Future<void> _sellOne() async {
    if (!canWriteNow(ref)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(kExpiredMsg)));
      return;
    }
    final p = _found!;
    try {
      await ref.read(repoProvider).sellPieces(p.id!, 1);
      ref.invalidate(productsProvider);
      ref.invalidate(statsProvider);
      final fresh = await ref.read(repoProvider).findByBarcode(p.barcode!);
      await SoundService.play(Sfx.sold);
      if (mounted) setState(() => _found = fresh);
    } on StateError {
      await SoundService.play(Sfx.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الكمية المتوفرة غير كافية')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _found;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.pickMode ? 'امسح الباركود' : 'مسح الباركود')),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  MobileScanner(controller: _controller, onDetect: _onDetect),
            ),
          ),
          if (p != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('سعر البيع: ${iqd(p.salePrice)}'),
                    Text(
                        'المتوفر: ${Units.format(p.qtyPieces, p.piecesPerCarton)}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _sellOne,
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('بيع قطعة واحدة'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
