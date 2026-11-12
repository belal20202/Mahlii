import 'package:flutter/material.dart';

import '../../core/firebase_config.dart';
import '../../core/theme.dart';
import '../../widgets/fx.dart';
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..forward();

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  Animation<double> _iv(double a, double b, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  late final Animation<double> _logo = _iv(0.0, 0.45, Curves.elasticOut);
  late final Animation<double> _logoFade = _iv(0.0, 0.2);
  late final Animation<double> _title = _iv(0.35, 0.6);
  late final Animation<double> _sub = _iv(0.5, 0.75);
  late final Animation<double> _dev = _iv(0.65, 0.9);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => FirebaseConfig.ready
              ? const AuthGate()
              : const SetupRequiredScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _shine.dispose();
    super.dispose();
  }

  Widget _fadeSlide(Animation<double> a, Widget child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.4), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald,
      body: AnimatedBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logo,
                  child: const AppLogo(size: 104),
                ),
              ),
              _fadeSlide(
                _title,
                const Text('محلي',
                    style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              _fadeSlide(
                _title,
                AnimatedBuilder(
                  animation: _shine,
                  builder: (_, child) {
                    final v = _shine.value;
                    return ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => LinearGradient(
                        colors: const [
                          AppColors.gold,
                          Colors.white,
                          AppColors.gold
                        ],
                        stops: [
                          (v - 0.3).clamp(0.0, 1.0).toDouble(),
                          v,
                          (v + 0.3).clamp(0.0, 1.0).toDouble(),
                        ],
                      ).createShader(r),
                      child: child,
                    );
                  },
                  child: const Text('MAHALLI',
                      style: TextStyle(
                          letterSpacing: 8,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              _fadeSlide(
                _sub,
                const Text('نظام إدارة المحلات الذكي',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              const Spacer(flex: 2),
              _fadeSlide(
                _dev,
                Column(children: const [
                  Text('المطور: بلال النعيمي  •  Belal Alnaimi',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('صنع في العراق  •  Made in Iraq',
                      style: TextStyle(color: AppColors.gold, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) => SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _c.value,
                      minHeight: 5,
                      color: AppColors.gold,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('جارٍ التحميل...',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
