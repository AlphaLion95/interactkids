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
  final GlobalKey<MatchingGameBaseState> _gameKey = GlobalKey<MatchingGameBaseState>();
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
          actions: [
            IconButton(
              tooltip: 'Undo last match',
              icon: const Icon(Icons.undo),
              onPressed: () async {
                final undone = await _gameKey.currentState?.undoLastMatch();
                if (undone == true) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Undid last match')));
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nothing to undo')));
                }
              },
            ),
            IconButton(
              tooltip: 'Clear current stroke',
              icon: const Icon(Icons.brush),
              onPressed: () {
                _gameKey.currentState?.clearStroke();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBubblesBackground()),
            MatchingGameBase(
              key: _gameKey,
              mode: MatchingWordsToWordsMode(pairs),
              title: '',
            ),
          ],
        ),
      ),
    );
  }
}
