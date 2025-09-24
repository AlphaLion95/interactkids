import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'letters_mode.dart';

class MatchingLettersScreen extends StatefulWidget {
  const MatchingLettersScreen({super.key});

  @override
  State<MatchingLettersScreen> createState() => _MatchingLettersScreenState();
}

class _MatchingLettersScreenState extends State<MatchingLettersScreen> {
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Enter immersive mode to reduce accidental edge taps while playing.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen.
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Resume')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Quit')),
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
    final pairs = List.generate(26, (i) {
      final upper = String.fromCharCode(65 + i);
      final lower = String.fromCharCode(97 + i);
      return MatchingPair(left: upper, right: lower);
    });

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: AppBar(
          title: const Text('Match the Letters', style: TextStyle(fontFamily: 'Nunito')),
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
      ),
    );
  }
}
