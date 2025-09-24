import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/matching_game_base.dart';
import 'package:interactkids/modules/matching/matching_models.dart';
import 'words_to_words_mode.dart';

class MatchingWordsToWordsScreen extends StatelessWidget {
  const MatchingWordsToWordsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pairs = <MatchingPair>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Words to Words', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.purple.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          MatchingGameBase(
            mode: MatchingWordsToWordsMode(pairs),
            title: '',
          ),
        ],
      ),
    );
  }
}
