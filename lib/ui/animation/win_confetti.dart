import 'dart:math' show Random, cos, pi, sin;

import 'package:flutter/material.dart';

import '../../core/palette.dart';

/// A short confetti burst drawn above the board when a level is won
/// (PLAN.md §14.3).
class WinConfetti extends StatefulWidget {
  const WinConfetti({super.key});

  @override
  State<WinConfetti> createState() => _WinConfettiState();
}

class _WinConfettiState extends State<WinConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(painter: _ConfettiPainter(_controller.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const int _count = 44;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint();

    for (var i = 0; i < _count; i++) {
      final random = Random(i * 31 + 7);
      final angle = random.nextDouble() * pi * 2;
      final speed = size.width * (0.25 + random.nextDouble() * 0.55);
      final spin = random.nextDouble() * pi * 2;
      final color = kPalette[random.nextInt(kPalette.length)];
      final particleSize = size.width * (0.012 + random.nextDouble() * 0.016);

      final dx = cos(angle) * speed * t;
      final dy = sin(angle) * speed * t + size.height * 0.55 * t * t;
      final position = origin + Offset(dx, dy);
      if (position.dy > size.height + 20) continue;

      final opacity = (1 - t).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particleSize,
          height: particleSize * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
