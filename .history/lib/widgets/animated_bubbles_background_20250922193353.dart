import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated background bubbles, as used in the Welcome to InteractKids screen.
class AnimatedBubblesBackground extends StatefulWidget {
  const AnimatedBubblesBackground({Key? key}) : super(key: key);
  @override
  State<AnimatedBubblesBackground> createState() => _AnimatedBubblesBackgroundState();
}

class _AnimatedBubblesBackgroundState extends State<AnimatedBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
    // Add a mix of small, medium, large, extra large, and double extra large bubbles
    _bubbles = [
      // Small (original)
      ...List.generate(10, (i) => _Bubble.randomWithRadius(10, 18)),
      // Medium
      ...List.generate(6, (i) => _Bubble.randomWithRadius(22, 32)),
      // Large
      ...List.generate(4, (i) => _Bubble.randomWithRadius(38, 54)),
      // Extra Large
      ...List.generate(2, (i) => _Bubble.randomWithRadius(60, 80)),
      // Double Extra Large
      ...List.generate(1, (i) => _Bubble.randomWithRadius(100, 140)),
    ];
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
        return CustomPaint(
          painter: _BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
}

class _Bubble {
  final double x, radius, speed, phase;
  final Color color;
  _Bubble(this.x, this.radius, this.speed, this.phase, this.color);
  static _Bubble random() {
    return _Bubble.randomWithRadius(10, 18);
  }

  static _Bubble randomWithRadius(double minRadius, double maxRadius) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.pink,
      Colors.yellow
    ];
    final rnd = math.Random();
    return _Bubble(
      rnd.nextDouble(),
      minRadius + rnd.nextDouble() * (maxRadius - minRadius),
      0.08 + rnd.nextDouble() * 0.12,
      rnd.nextDouble(),
      colors[rnd.nextInt(colors.length)],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double t;
  _BubblesPainter(this.bubbles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final y = size.height * ((b.speed * t + b.phase) % 1.0);
      final x = size.width * b.x;
      final paint = Paint()..color = b.color.withOpacity(0.18);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
