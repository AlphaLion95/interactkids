import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reusable animated bouncy button used across selection screens.
///
/// Parameters:
/// - `label`, `icon`, `color`, `onTap`, `delay` (ms), `width`, `height`.
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
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
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
        // Use a time-offset wobble for subtle variety
        final wobble = (math.sin((DateTime.now().millisecondsSinceEpoch / 600) + widget.delay) * 0.5);
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
            color: widget.color.withOpacity(0.78),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Icon(widget.icon, size: 38, color: widget.color),
              ),
              const SizedBox(width: 28),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(1, 2),
                      ),
                    ],
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
