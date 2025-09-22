import 'package:flutter/material.dart';
import 'matching_game_base.dart';
import 'matching_models.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MatchingLettersScreen();
  }
}

class MatchingLettersScreen extends StatelessWidget {
  const MatchingLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example pairs: A-A, B-B, C-C
    final pairs = [
      MatchingPair(left: 'A', right: 'A'),
      MatchingPair(left: 'B', right: 'B'),
      MatchingPair(left: 'C', right: 'C'),
      MatchingPair(left: 'D', right: 'D'),
    ];
    return MatchingGameBase(
      mode: MatchingLettersMode(pairs),
      title: 'Match the Letters',
    );
  }
}
