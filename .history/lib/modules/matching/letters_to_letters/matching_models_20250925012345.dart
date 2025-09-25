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
  /// A unique key used to persist progress for this mode.
  /// Concrete modes should override this to provide a distinct key.
  String get progressKey => 'matching_default_progress';

  Widget buildLeftItem(BuildContext context, dynamic item);
  Widget buildRightItem(BuildContext context, dynamic item);

  /// Whether the matched-tray UI should be shown for this mode.
  /// Some modes (like picture-to-picture) prefer a direct connect UI.
  bool get showMatchedTray => true;

  /// Whether this mode supports drag-to-match (drawing a line to connect)
  /// instead of simple tap-to-select. Default is false.
  bool get supportsDragMatch => false;
}
