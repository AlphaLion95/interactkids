import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ConfettiAndBalloonsOverlay extends StatefulWidget {
  final bool show;
  final VoidCallback? onAllBalloonsPopped;
  const ConfettiAndBalloonsOverlay({Key? key, required this.show, this.onAllBalloonsPopped}) : super(key: key);

  @override
  State<ConfettiAndBalloonsOverlay> createState() => _ConfettiAndBalloonsOverlayState();
}

class _ConfettiAndBalloonsOverlayState extends State<ConfettiAndBalloonsOverlay> {
  late ConfettiController _confettiController;
  final List<_BalloonData> _balloons = [];
  final int _balloonCount = 12;
  int _poppedCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.show) {
      _confettiController.play();
      _spawnBalloons();
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiAndBalloonsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _confettiController.play();
      _spawnBalloons();
    }
  }

  void _spawnBalloons() {
    _balloons.clear();
    _poppedCount = 0;
    final rand = Random();
    for (int i = 0; i < _balloonCount; i++) {
      _balloons.add(_BalloonData(
        left: rand.nextDouble() * 0.8 + 0.1,
        color: Colors.primaries[i % Colors.primaries.length],
        id: i,
        speed: 0.5 + rand.nextDouble() * 0.7,
      ));
    }
    setState(() {});
  }

  void _popBalloon(int id) {
    setState(() {
      _balloons.removeWhere((b) => b.id == id);
      _poppedCount++;
      if (_poppedCount >= _balloonCount && widget.onAllBalloonsPopped != null) {
        widget.onAllBalloonsPopped!();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
            numberOfParticles: 24,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.25,
            colors: [
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
        ..._balloons.map((b) => _AnimatedBalloon(
              key: ValueKey(b.id),
              left: b.left,
              color: b.color,
              speed: b.speed,
              onPop: () => _popBalloon(b.id),
            )),
      ],
    );
  }
}

class _BalloonData {
  final double left;
  final Color color;
  final int id;
  final double speed;
  _BalloonData({required this.left, required this.color, required this.id, required this.speed});
}

class _AnimatedBalloon extends StatefulWidget {
  final double left;
  final Color color;
  final double speed;
  final VoidCallback onPop;
  const _AnimatedBalloon({Key? key, required this.left, required this.color, required this.speed, required this.onPop}) : super(key: key);

  @override
  State<_AnimatedBalloon> createState() => _AnimatedBalloonState();
}

class _AnimatedBalloonState extends State<_AnimatedBalloon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: (5 ~/ widget.speed)));
    _controller.forward();
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
        final double top = (1.0 - _controller.value) * MediaQuery.of(context).size.height * 0.8 + 40;
        return Positioned(
          left: widget.left * MediaQuery.of(context).size.width,
          top: top,
          child: GestureDetector(
            onTap: widget.onPop,
            child: Icon(Icons.emoji_emotions, color: widget.color, size: 48),
          ),
        );
      },
    );
  }
}
