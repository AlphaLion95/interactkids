import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/matching_game_base.dart';
import 'package:interactkids/modules/matching/matching_models.dart';
import 'pictures_mode.dart';

class MatchingPicturesScreen extends StatelessWidget {
  const MatchingPicturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Provide actual picture asset pairs
    final pairs = <MatchingPair>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Match the Pictures',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.green.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          MatchingGameBase(
            mode: MatchingPicturesMode(pairs),
            title: '',
          ),
        ],
      ),
    );
  }
}
