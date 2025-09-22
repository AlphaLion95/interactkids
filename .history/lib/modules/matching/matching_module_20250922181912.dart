import 'package:flutter/material.dart';
import 'matching_game_base.dart';
import 'matching_models.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Matching Game Type')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _MatchingTypeButton(
            label: 'Matching Letters',
            icon: Icons.text_fields,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MatchingLettersScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _MatchingTypeButton(
            label: 'Matching Pictures',
            icon: Icons.image,
            color: Colors.green,
            onTap: () {
              // TODO: Implement MatchingPicturesScreen
            },
          ),
          const SizedBox(height: 24),
          _MatchingTypeButton(
            label: 'Words to Pictures',
            icon: Icons.link,
            color: Colors.orange,
            onTap: () {
              // TODO: Implement MatchingWordsToPicturesScreen
            },
          ),
          const SizedBox(height: 24),
          _MatchingTypeButton(
            label: 'Words to Words',
            icon: Icons.compare_arrows,
            color: Colors.purple,
            onTap: () {
              // TODO: Implement MatchingWordsToWordsScreen
            },
          ),
        ],
      ),
    );
  }
}

class _MatchingTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MatchingTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 22, fontFamily: 'Nunito'),
        elevation: 6,
      ),
      icon: Icon(icon, size: 36),
      label: Text(label),
      onPressed: onTap,
    );
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
