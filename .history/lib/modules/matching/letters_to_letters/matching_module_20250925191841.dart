import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../widgets/navigation_helpers.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/widgets/bouncing_button.dart';
import 'package:interactkids/modules/matching/letters_to_letters/letters_screen.dart';
import 'package:interactkids/modules/matching/pictures_to_pictures/pictures_screen.dart';
import 'package:interactkids/modules/matching/words_to_pictures/words_to_pictures_screen.dart';
import 'package:interactkids/modules/matching/words_to_words/words_to_words_screen.dart';

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
      'Letters & Numbers',
      'Matching Pictures',
      'Words to Pictures',
      'Words to Words',
    ];
    // Use pushGameScreen so each game screen is wrapped with GameExitGuard
    final onTaps = [
      () => pushGameScreen(context, const MatchingLettersScreen()),
      () => pushGameScreen(context, const MatchingPicturesScreen()),
      () => pushGameScreen(context, const MatchingWordsToPicturesScreen()),
      () => pushGameScreen(context, const MatchingWordsToWordsScreen()),
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
                    _AnimatedMatchingTypeButton(
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

                  for (int i = 0; i < labels.length; i++) ...[
                    AnimatedBouncingActionButton(
                      label: labels[i],
                      icon: icons[i],
                      color: colors[i],
                      onTap: onTaps[i],
                      delay: i * 200,
                    ),
                    const SizedBox(height: 36),
                  ],
    required this.onTap,
    required this.delay,
  });
  @override
  State<_AnimatedMatchingTypeButton> createState() =>
      _AnimatedMatchingTypeButtonState();
}

class _AnimatedMatchingTypeButtonState
// Individual game type screens live under their respective folders.
  late AnimationController _controller;
