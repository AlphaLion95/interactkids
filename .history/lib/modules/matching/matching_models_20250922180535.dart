import 'package:flutter/material.dart';

/// Enum for all matching game types.
enum MatchingGameType {
  letters,
  pictures,
  wordsToPictures,
  wordsToWords,
}

/// Model for a matching pair (generic for all types)
class MatchingPair {
  final dynamic left;
  final dynamic right;
  MatchingPair({required this.left, required this.right});
}

/// Abstract base class for a matching game mode
a bstract class MatchingGameMode {
  final List<MatchingPair> pairs;
  MatchingGameMode(this.pairs);
  Widget buildLeftItem(BuildContext context, dynamic item);
  Widget buildRightItem(BuildContext context, dynamic item);
}

/// Example: Matching Letters Mode
class MatchingLettersMode extends MatchingGameMode {
  MatchingLettersMode(List<MatchingPair> pairs) : super(pairs);
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return _letterTile(item as String);
  }
  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return _letterTile(item as String);
  }
  Widget _letterTile(String letter) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(letter, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      );
}

/// Example: Matching Pictures Mode
class MatchingPicturesMode extends MatchingGameMode {
  MatchingPicturesMode(List<MatchingPair> pairs) : super(pairs);
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return _imageTile(item as String);
  }
  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return _imageTile(item as String);
  }
  Widget _imageTile(String assetPath) => Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(assetPath, width: 64, height: 64),
      );
}

// More modes (wordsToPictures, wordsToWords) can be added similarly.
