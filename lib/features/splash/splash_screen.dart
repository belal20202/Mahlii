import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../home/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      // المرحلة 2: الانتقال إلى تسجيل الدخول بدلاً من الرئيسية
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.emerald,
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(fade),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 58, color: AppColors.emerald),
                ),
                const SizedBox(height: 22),
                const Text('محلي',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const Text('MAHALLI',
                    style: TextStyle(
                        letterSpacing: 4,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text('نظام إدارة المحلات الذكي',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 56),
                const Text('المطور: بلال النعيمي  •  Belal Alnaimi',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('صنع في العراق  •  Made in Iraq',
                    style: TextStyle(color: AppColors.gold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
