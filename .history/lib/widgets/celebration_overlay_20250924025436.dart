import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:just_audio/just_audio.dart';

/// A widget that displays confetti and animated balloons overlay when called.
/// Call [show] to trigger the celebration.
class CelebrationOverlay extends StatefulWidget {
  final bool show;
  final VoidCallback? onComplete;
  const CelebrationOverlay({Key? key, required this.show, this.onComplete})
      : super(key: key);

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _balloonController;
  late AnimationController _flowersController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _balloonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _flowersController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _audioPlayer = AudioPlayer();
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
    _flowersController.forward(from: 0);
    // Play short celebratory sound if available
    try {
      _audioPlayer.setAsset('assets/audio/sfx/card_tap.mp3').then((_) {
        _audioPlayer.play();
      });
    } catch (_) {}
    Future.delayed(const Duration(seconds: 4), () {
      if (widget.onComplete != null) widget.onComplete!();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _balloonController.dispose();
    _flowersController.dispose();
    _audioPlayer.dispose();
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
        // Balloons - spread across full width with varied offsets
        AnimatedBuilder(
          animation: _balloonController,
          builder: (context, child) {
            final t = _balloonController.value;
            final w = MediaQuery.of(context).size.width;
            final h = MediaQuery.of(context).size.height;
            const count = 10;
            return Stack(
              children: [
                for (int i = 0; i < count; i++)
                  Positioned(
                    left: (w - 80) * (i / (count - 1)) + 20 * math.sin(t * math.pi * 2 + i),
                    bottom: -120 + t * (h + 240) + (i % 3) * 20,
                    child: Opacity(
                      opacity: (1.0 - t) * 0.9 + 0.1,
                      child: _Balloon(color: Colors.primaries[i % Colors.primaries.length]),
                    ),
                  ),
              ],
            );
          },
        ),
        // Falling flowers / petals across full width
        AnimatedBuilder(
          animation: _flowersController,
          builder: (context, child) {
            final t = _flowersController.value;
            final height = MediaQuery.of(context).size.height;
            final width = MediaQuery.of(context).size.width;
            const petalCount = 14;
            return Stack(
              children: [
                for (int i = 0; i < petalCount; i++)
                  Positioned(
                    left: (width - 20) * ((i + 1) / (petalCount + 1)) + 10 * math.cos(t * math.pi * 2 + i),
                    top: -40 + t * (height + 80) + (i * 8),
                    child: Opacity(
                      opacity: (1.0 - (t + i * 0.02)).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: (t * 3.1415) * (i.isEven ? 1 : -1) + i * 0.1,
                        child: _FlowerPetal(color: Colors.pink[(100 + (i * 50)) % 400]?.withOpacity(0.95) ?? Colors.pink.shade200),
                      ),
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

class _FlowerPetal extends StatelessWidget {
  final Color color;
  const _FlowerPetal({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
