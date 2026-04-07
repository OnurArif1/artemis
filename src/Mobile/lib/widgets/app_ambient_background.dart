import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppAmbientBackground extends StatefulWidget {
  const AppAmbientBackground({super.key});

  @override
  State<AppAmbientBackground> createState() => _AppAmbientBackgroundState();
}

class _AppAmbientBackgroundState extends State<AppAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return CustomPaint(
          painter: _AmbientPainter(phase: t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.surfaceLight);

    final ox = 26 * math.sin(phase * math.pi * 2);
    final oy = 20 * math.cos(phase * math.pi * 2);

    void orb(double cx, double cy, double r, Color a, Color b) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [a, b],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, p);
    }

    orb(
      size.width * 0.88 + ox,
      size.height * 0.07 + oy,
      size.width * 0.44,
      AppColors.purple200.withValues(alpha: 0.38),
      AppColors.purple50.withValues(alpha: 0),
    );
    orb(
      size.width * 0.1 - ox * 0.45,
      size.height * 0.2,
      size.width * 0.3,
      AppColors.purple100.withValues(alpha: 0.55),
      AppColors.surfaceLight.withValues(alpha: 0),
    );
    orb(
      size.width * 0.5,
      size.height * 0.95 - oy,
      size.width * 0.38,
      AppColors.purple300.withValues(alpha: 0.12),
      AppColors.surfaceLight.withValues(alpha: 0),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
