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
abstract class MatchingGameMode {
  final List<MatchingPair> pairs;
  MatchingGameMode(this.pairs);
  Widget buildLeftItem(BuildContext context, dynamic item);
  Widget buildRightItem(BuildContext context, dynamic item);
}
