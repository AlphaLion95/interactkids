import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'matching/matching_game_base.dart';
import 'matching/matching_models.dart';
import 'letters/letters_screen.dart';
import 'pictures/pictures_screen.dart';
import 'words_to_pictures/words_to_pictures_screen.dart';
import 'words_to_words/words_to_words_screen.dart';

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
    final onTaps = [
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingLettersScreen()),
          ),
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingPicturesScreen()),
          ),
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingWordsToPicturesScreen()),
          ),
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingWordsToWordsScreen()),
          ),
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
            color: widget.color.withOpacity(0.78), // Slightly transparent
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
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
                      color: Colors.white.withOpacity(0.18),
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

class MatchingLettersScreen extends StatelessWidget {
  const MatchingLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate all alphabet pairs: A-a, B-b, ..., Z-z
    final pairs = List.generate(26, (i) {
      final upper = String.fromCharCode(65 + i); // 'A'..'Z'
      final lower = String.fromCharCode(97 + i); // 'a'..'z'
      return MatchingPair(left: upper, right: lower);
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Match the Letters',
            style: TextStyle(fontFamily: 'Nunito')),
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
    );
  }
}
