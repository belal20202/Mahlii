import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme.dart';

/// كاميرا الباركود: تطلب الإذن صراحةً وتعرض سبب أي فشل بدل شاشة سوداء.
class BarcodeCamera extends StatefulWidget {
  final ValueChanged<String> onCode;
  const BarcodeCamera({super.key, required this.onCode});

  @override
  State<BarcodeCamera> createState() => _BarcodeCameraState();
}

class _BarcodeCameraState extends State<BarcodeCamera>
    with WidgetsBindingObserver {
  MobileScannerController? _c;
  PermissionStatus? _status;
  String? _last;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init({bool ask = true}) async {
    var st = await Permission.camera.status;
    if (!st.isGranted && ask) st = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _status = st;
      if (st.isGranted && _c == null) {
        _c = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند الرجوع من إعدادات الهاتف بعد منح الإذن
    if (state == AppLifecycleState.resumed &&
        _status != null &&
        !_status!.isGranted) {
      _init(ask: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    final now = DateTime.now();
    if (code == _last && now.difference(_lastAt).inMilliseconds < 1200) {
      return;
    }
    _last = code;
    _lastAt = now;
    widget.onCode(code);
  }

  Widget _box({
    required IconData icon,
    required String text,
    List<Widget> actions = const [],
  }) {
    return Container(
      color: AppColors.mint,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppColors.emerald),
              const SizedBox(height: 10),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink)),
              const SizedBox(height: 12),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = _status;
    if (st == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!st.isGranted) {
      return _box(
        icon: Icons.no_photography_outlined,
        text: 'يحتاج التطبيق إذن الكاميرا لقراءة الباركود',
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(190, 44)),
            onPressed: () => _init(),
            child: const Text('السماح بالكاميرا'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(190, 44)),
            onPressed: openAppSettings,
            child: const Text('فتح الإعدادات'),
          ),
        ],
      );
    }
    return MobileScanner(
      controller: _c!,
      onDetect: _onDetect,
      errorBuilder: (context, error, child) => _box(
        icon: Icons.error_outline,
        text: 'تعذر تشغيل الكاميرا\n(${error.errorCode.name})',
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(190, 44)),
            onPressed: openAppSettings,
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
