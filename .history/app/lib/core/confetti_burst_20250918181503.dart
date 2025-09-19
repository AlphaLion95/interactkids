import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({Key? key}) : super(key: key);

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        emissionFrequency: 0.12,
        numberOfParticles: 30,
        maxBlastForce: 20,
        minBlastForce: 8,
        gravity: 0.3,
        colors: const [
          Colors.orange,
          Colors.blue,
          Colors.green,
          Colors.pink,
          Colors.yellow,
        ],
      ),
    );
  }
}
