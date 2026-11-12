import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// خلفية خضراء متدرجة مع فقاعات ذهبية وبيضاء تطفو ببطء.
class AnimatedBackdrop extends StatefulWidget {
  final Widget? child;
  const AnimatedBackdrop({super.key, this.child});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF176B5B), Color(0xFF0B3D33)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _BubblesPainter(_c.value)),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double t;
  _BubblesPainter(this.t);

  double _r(int i, int k) =>
      ((math.sin(i * 12.9898 + k * 78.233) * 43758.5453) % 1).abs();

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 16; i++) {
      final speed = 1 + (i % 3);
      final phase = _r(i, 4) * 2 * math.pi;
      final radius = 12 + _r(i, 3) * 44;
      final x = (_r(i, 1) + 0.05 * math.sin(2 * math.pi * t * speed + phase)) *
          size.width;
      final y = ((_r(i, 2) - t * speed) % 1) * size.height;
      final paint = Paint()
        ..color = (i.isEven ? AppColors.gold : Colors.white)
            .withValues(alpha: i.isEven ? 0.12 : 0.07);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter old) => old.t != t;
}

/// شعار التطبيق مع حلقة ذهبية نابضة.
class AppLogo extends StatefulWidget {
  final double size;
  const AppLogo({super.key, this.size = 104});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2400 ~/ 1000 + 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.8,
      height: s * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final v = _c.value;
              return Transform.scale(
                scale: 1 + 0.6 * v,
                child: Opacity(
                  opacity: (1 - v) * 0.55,
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s * 0.3),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(s * 0.29),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.storefront_rounded,
                size: s * 0.55, color: AppColors.emerald),
          ),
        ],
      ),
    );
  }
}

/// ظهور تدريجي مع انزلاق خفيف بعد تأخير.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const FadeSlideIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(_curve),
        child: widget.child,
      ),
    );
  }
}
