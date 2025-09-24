import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small reusable bouncing/float button used on selection screens.
class AnimatedBouncyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  final double width;
  final double height;

  const AnimatedBouncyButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.delay = 0,
    this.width = 320,
    this.height = 110,
  }) : super(key: key);

  @override
  State<AnimatedBouncyButton> createState() => _AnimatedBouncyButtonState();
}

class _AnimatedBouncyButtonState extends State<AnimatedBouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.repeat(reverse: true);
      });
    } else {
      _controller.repeat(reverse: true);
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
        final wobble = math.sin(
                (DateTime.now().millisecondsSinceEpoch / 600) + widget.delay) *
            0.5;
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.translate(
            offset: Offset(0, -_floatAnim.value * wobble),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(widget.icon, size: 34, color: widget.color),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
