import 'package:flutter/material.dart';
import '../../widgets/animated_bubbles_background.dart';
import '../matching/matching_game_base.dart';
import '../matching/matching_models.dart';
import 'words_to_pictures_mode.dart';

class MatchingWordsToPicturesScreen extends StatelessWidget {
  const MatchingWordsToPicturesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pairs = <MatchingPair>[];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Words to Pictures', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.orange.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          MatchingGameBase(
            mode: MatchingWordsToPicturesMode(pairs),
            title: '',
          ),
        ],
      ),
    );
  }
}
