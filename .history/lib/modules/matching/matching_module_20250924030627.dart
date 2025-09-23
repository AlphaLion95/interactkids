import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/widgets/animated_bouncy_button.dart';
import 'matching_game_base.dart';
import 'matching_models.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
    ];
    final icons = [
      Icons.text_fields,
      Icons.image,
      Icons.link,
      Icons.compare_arrows,
    ];
    final labels = [
      'Matching Letters',
      'Matching Pictures',
      'Words to Pictures',
      'Words to Words',
    ];
    final onTaps = [
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingLettersScreen()),
          ),
      () {}, // TODO: MatchingPicturesScreen
      () {}, // TODO: MatchingWordsToPicturesScreen
      () {}, // TODO: MatchingWordsToWordsScreen
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Select Matching Game Type',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Unified animated bubbles background
          const Positioned.fill(child: AnimatedBubblesBackground()),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    AnimatedBouncyButton(
                      label: labels[i],
                      icon: icons[i],
                      color: colors[i],
                      onTap: onTaps[i],
                      delay: i * 200,
                    ),
                    const SizedBox(height: 36),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchingLettersScreen extends StatelessWidget {
  const MatchingLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate all alphabet pairs: A-a, B-b, ..., Z-z
    final pairs = List.generate(26, (i) {
      final upper = String.fromCharCode(65 + i); // 'A'..'Z'
      final lower = String.fromCharCode(97 + i); // 'a'..'z'
      return MatchingPair(left: upper, right: lower);
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Match the Letters',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          MatchingGameBase(
            mode: MatchingLettersMode(pairs),
            title: '',
          ),
        ],
      ),
    );
  }
}
