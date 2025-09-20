import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({Key? key}) : super(key: key);
  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _bubbles = List.generate(18, (i) => Bubble.random());
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
          painter: BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
}
class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _bubbles = List.generate(18, (i) => Bubble.random());
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
          painter: BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
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
          painter: BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
}

class Bubble {
  final double x, radius, speed, phase;
  final Color color;
  Bubble(this.x, this.radius, this.speed, this.phase, this.color);
  static Bubble random() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.pink,
      Colors.yellow
    ];
    final rnd = math.Random();
    return Bubble(
      rnd.nextDouble(),
      10 + rnd.nextDouble() * 18,
      0.08 + rnd.nextDouble() * 0.12,
      rnd.nextDouble(),
      colors[rnd.nextInt(colors.length)],
    );
  }
}

class BubblesPainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double t;
  BubblesPainter(this.bubbles, this.t);
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
