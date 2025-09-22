import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// A widget that displays confetti and animated balloons overlay when called.
/// Call [show] to trigger the celebration.
class CelebrationOverlay extends StatefulWidget {
  final bool show;
  final VoidCallback? onComplete;
  const CelebrationOverlay({Key? key, required this.show, this.onComplete}) : super(key: key);

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _balloonController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _balloonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.show) _start();
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _start();
    }
  }

  void _start() {
    _confettiController.play();
    _balloonController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (widget.onComplete != null) widget.onComplete!();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _balloonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    return Stack(
      children: [
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.12,
            numberOfParticles: 32,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
        // Balloons
        AnimatedBuilder(
          animation: _balloonController,
          builder: (context, child) {
            final t = _balloonController.value;
            return Stack(
              children: [
                for (int i = 0; i < 6; i++)
                  Positioned(
                    left: 40.0 + i * 48.0 + 24 * (1 - t),
                    bottom: -120 + t * (MediaQuery.of(context).size.height + 120),
                    child: Opacity(
                      opacity: 0.7 * (1 - t) + 0.3,
                      child: _Balloon(color: Colors.primaries[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Balloon extends StatelessWidget {
  final Color color;
  const _Balloon({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 54,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.brown.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
