import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'words_to_words_mode.dart';

class MatchingWordsToWordsScreen extends StatefulWidget {
  const MatchingWordsToWordsScreen({super.key});
  @override
  State<MatchingWordsToWordsScreen> createState() =>
      _MatchingWordsToWordsScreenState();
}

class _MatchingWordsToWordsScreenState
    extends State<MatchingWordsToWordsScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairs = <MatchingPair>[];
    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: AppBar(
          title: const Text('Words to Words',
              style: TextStyle(fontFamily: 'Nunito')),
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
      ),
    );
  }
}
