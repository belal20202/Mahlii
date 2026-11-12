import 'package:flutter/material.dart';

import '../../core/sound_service.dart';
import '../../widgets/barcode_camera.dart';

/// يفتح الكاميرا ويعيد أول باركود مقروء.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _done = false;

  Future<void> _onCode(String code) async {
    if (_done) return;
    _done = true;
    await SoundService.play(Sfx.scan);
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('امسح الباركود')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BarcodeCamera(onCode: _onCode),
        ),
      ),
    );
  }
}
