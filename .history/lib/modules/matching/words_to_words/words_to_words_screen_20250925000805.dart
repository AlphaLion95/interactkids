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
  bool _isPlaying = true;

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

  Future<bool> _onWillPop() async {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      final leave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pause'),
          content: const Text('Do you want to quit the game?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Resume')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quit')),
          ],
        ),
      );
      if (leave == true) return true;
      setState(() => _isPlaying = true);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pairs = <MatchingPair>[];
    return GameExitGuard(
      child: WillPopScope(
        onWillPop: _onWillPop,
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
      ),
    );
  }
}
