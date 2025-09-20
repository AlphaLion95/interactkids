import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBubbles extends StatefulWidget {
  AnimatedBubbles({Key? key}) : super(key: key);
  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bubble> _bubbles = List.generate(18, (i) => Bubble.random());
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
  // ...random() factory...
}

class BubblesPainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    // ...existing code...
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
