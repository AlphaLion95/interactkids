import 'dart:math';
import 'package:flutter/material.dart';

/// A reusable animated floating bubbles/circles background widget.
class AnimatedBubblesBackground extends StatefulWidget {
  final int bubbleCount;
  final double opacity;
  final double minRadius;
  final double maxRadius;
  final List<Color>? colors;
  const AnimatedBubblesBackground({
    super.key,
    this.bubbleCount = 18,
    this.opacity = 0.88,
    this.minRadius = 38,
    this.maxRadius = 86,
    this.colors,
  });

  @override
  State<AnimatedBubblesBackground> createState() => _AnimatedBubblesBackgroundState();
}

class _AnimatedBubblesBackgroundState extends State<AnimatedBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Bubble> _bubbles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _bubbles = List.generate(widget.bubbleCount, (i) => _Bubble(_random, widget.minRadius, widget.maxRadius, widget.colors));
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
          painter: _BubblesPainter(_bubbles, _controller.value, widget.opacity),
        );
      },
    );
  }
}

class _Bubble {
  late double x, y, radius, speed, phase;
  late Color color;
  _Bubble(Random random, double minRadius, double maxRadius, List<Color>? customColors) {
    x = random.nextDouble();
    y = random.nextDouble();
    radius = minRadius + random.nextDouble() * (maxRadius - minRadius);
    speed = 0.10 + random.nextDouble() * 0.16;
    phase = random.nextDouble() * 2 * pi;
    final colors = customColors ?? [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.yellowAccent,
      Colors.redAccent,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double t;
  final double opacity;
  _BubblesPainter(this.bubbles, this.t, this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final dx = b.x * size.width + 32 * sin(t * 2 * pi * b.speed + b.phase);
      final dy = (b.y + 0.16 * sin(t * 2 * pi * b.speed + b.phase)) * size.height;
      final paint = Paint()
        ..color = b.color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(Offset(dx, dy), b.radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
