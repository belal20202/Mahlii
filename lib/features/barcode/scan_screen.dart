import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/sound_service.dart';

/// يفتح الكاميرا ويعيد أول باركود مقروء.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture c) async {
    if (_done) return;
    final code = c.barcodes.isEmpty ? null : c.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _done = true;
    await SoundService.play(Sfx.scan);
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('امسح الباركود')),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MobileScanner(controller: _controller, onDetect: _onDetect),
      ),
    );
  }
}
