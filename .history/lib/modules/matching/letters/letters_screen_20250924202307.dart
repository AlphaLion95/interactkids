import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters/matching_models.dart';
import 'letters_mode.dart';

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
