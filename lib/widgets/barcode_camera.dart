import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme.dart';

/// كاميرا الباركود: تطلب الإذن، وتشغّل الكاميرا يدوياً، وتعرض نص الخطأ الحقيقي.
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
  String? _error;
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
    setState(() => _status = st);
    if (st.isGranted) await _startCamera();
  }

  Future<void> _startCamera() async {
    final old = _c;
    final c = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: false,
    );
    setState(() {
      _c = c;
      _error = null;
    });
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    try {
      await c.start();
    } on MobileScannerException catch (e) {
      final m = e.errorDetails?.message;
      if (mounted) {
        setState(() => _error = '${e.errorCode.name}${m == null ? '' : '\n$m'}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_status != null && !_status!.isGranted) {
      _init(ask: false);
    } else if (_c != null && _error == null) {
      // إعادة تشغيل الكاميرا بعد الرجوع للتطبيق
      _c!.start().then((_) {}, onError: (_) {});
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
    required String title,
    String? details,
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
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink)),
              if (details != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  details,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: AppColors.ink, fontSize: 12),
                ),
              ],
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
        title: 'يحتاج التطبيق إذن الكاميرا لقراءة الباركود',
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
    if (_error != null) {
      return _box(
        icon: Icons.error_outline,
        title: 'تعذر تشغيل الكاميرا',
        details: _error,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(190, 44)),
            onPressed: _startCamera,
            child: const Text('إعادة المحاولة'),
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
    final c = _c;
    if (c == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return MobileScanner(controller: c, onDetect: _onDetect);
  }
}
