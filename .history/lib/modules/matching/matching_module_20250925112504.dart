import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/navigation_helpers.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
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
      'Matching Letters',
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

class _AnimatedMatchingTypeButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  const _AnimatedMatchingTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });
  @override
  State<_AnimatedMatchingTypeButton> createState() =>
      _AnimatedMatchingTypeButtonState();
}

class _AnimatedMatchingTypeButtonState
    extends State<_AnimatedMatchingTypeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.translate(
            offset: Offset(
                0,
                -_floatAnim.value *
                    sin(DateTime.now().millisecondsSinceEpoch / 600 +
                        widget.delay)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 320,
          height: 110,
          decoration: BoxDecoration(
            color: widget.color
                .withAlpha((0.78 * 255).round()), // Slightly transparent
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha((0.35 * 255).round()),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha((0.18 * 255).round()),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Icon(widget.icon, size: 38, color: widget.color),
              ),
              const SizedBox(width: 28),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Individual game type screens live under their respective folders.
