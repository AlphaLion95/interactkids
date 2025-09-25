import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small reusable widget that applies the "bouncy + float" animation used
/// throughout the matching selection screens. It simply animates a child with
/// a scale + vertical float loop and exposes a convenient [delay] and [onTap].
class AnimatedBouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int delay; // ms
  final double width;
  final double height;

  const AnimatedBouncingButton({
    required this.child,
    this.onTap,
    this.delay = 0,
    this.width = 320,
    this.height = 110,
    super.key,
  });

  @override
  State<AnimatedBouncingButton> createState() => _AnimatedBouncingButtonState();
}

class _AnimatedBouncingButtonState extends State<AnimatedBouncingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Stagger the start so multiple buttons don't animate in perfect sync
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Transform.translate(
              offset: Offset(
                0,
                -_floatAnim.value *
                    math.sin(DateTime.now().millisecondsSinceEpoch / 600 + widget.delay),
              ),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Convenience widget that builds the same matching-type tile used on the
/// "Select Matching Game Type" screen. It composes [AnimatedBouncingButton]
/// with the expected visuals (icon circle + label) so callers can instantiate
/// the same styled button in one line.
class AnimatedBouncingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const AnimatedBouncingActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.delay = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBouncingButton(
      onTap: onTap,
      delay: delay,
      child: Container(
        width: 320,
        height: 110,
        decoration: BoxDecoration(
          color: color.withAlpha((0.78 * 255).round()),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.35 * 255).round()),
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
                    color: Colors.white.withAlpha((0.18 * 255).round()),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Icon(icon, size: 38, color: color),
            ),
            const SizedBox(width: 28),
            Flexible(
              child: Text(
                label,
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
    );
  }
}
