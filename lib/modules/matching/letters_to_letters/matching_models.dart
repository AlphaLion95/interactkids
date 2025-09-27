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

  /// Whether the left column should be shuffled. Defaults to true for
  /// existing modes; modes like letters/numbers that want a fixed
  /// left ordering should override this to return false.
  bool get shuffleLeft => true;

  /// A unique key used to persist progress for this mode.
  /// Concrete modes should override this to provide a distinct key.
  String get progressKey => 'matching_default_progress';

  Widget buildLeftItem(BuildContext context, dynamic item);
  Widget buildRightItem(BuildContext context, dynamic item);

  /// Optional builders used when an item is selected. Return null to use the
  /// default builders instead.
  Widget? buildSelectedLeftItem(BuildContext context, dynamic item) => null;
  Widget? buildSelectedRightItem(BuildContext context, dynamic item) => null;

  /// Whether the matched-tray UI should be shown for this mode.
  /// Some modes (like picture-to-picture) prefer a direct connect UI.
  bool get showMatchedTray => true;

  /// Whether this mode supports drag-to-match (drawing a line to connect)
  /// instead of simple tap-to-select. Default is false.
  bool get supportsDragMatch => false;

  /// Optional preferred size (in pixels) for tiles in drag-match layouts.
  /// Modes can override this to suggest a maximum tile size; null means no preference.
  double? get preferredCellSize => null;
}
