
import 'dart:math' as math;
import 'package:flutter/material.dart';

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
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat();
    // Add more bubbles and more size variety
    final List<_Bubble> bubbles = [];
    final int small = 18;
    final int medium = 14;
    final int large = 10;
    final int xlarge = 6;
    // Small bubbles
    for (int i = 0; i < small; i++) {
      bubbles.add(_Bubble.random(
        minRadius: 8,
        maxRadius: 16,
        speedMultiplier: 2.5,
      ));
    }
    // Medium bubbles
    for (int i = 0; i < medium; i++) {
      bubbles.add(_Bubble.random(
        minRadius: 17,
        maxRadius: 28,
        speedMultiplier: 2.5,
      ));
    }
    // Large bubbles
    for (int i = 0; i < large; i++) {
      bubbles.add(_Bubble.random(
        minRadius: 29,
        maxRadius: 44,
        speedMultiplier: 2.5,
      ));
    }
    // Extra large bubbles
    for (int i = 0; i < xlarge; i++) {
      bubbles.add(_Bubble.random(
        minRadius: 45,
        maxRadius: 70,
        speedMultiplier: 2.5,
      ));
    }
    _bubbles = bubbles;
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
  static _Bubble random({double speedMultiplier = 1.0, double minRadius = 10, double maxRadius = 28}) {
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
      (0.08 + rnd.nextDouble() * 0.12) * speedMultiplier,
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
      final paint = Paint()..color = b.color.withOpacity(1.0);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
