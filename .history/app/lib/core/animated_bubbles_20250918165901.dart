import 'package:flutter/material.dart';

class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({Key? key}) : super(key: key);
  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
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
          painter: _BubblesPainter(_controller.value),
        );
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double progress;
  _BubblesPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15);
    for (int i = 0; i < 12; i++) {
      final dx = (size.width / 12) * i + 20 * (progress + i) % 1;
      final dy = size.height * ((progress + i * 0.08) % 1);
      canvas.drawCircle(Offset(dx, dy), 18 + 8 * (i % 3), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
