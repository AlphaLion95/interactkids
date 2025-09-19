// Shared data models (Category, UserProgress, etc.)

class PuzzleLevel {
  final String id;
  final String name;
  final String theme; // e.g. 'Zoo', 'Sea', 'Jungle'
  final List<PuzzlePiece> pieces;

  PuzzleLevel({
    required this.id,
    required this.name,
    required this.theme,
    required this.pieces,
  });
}

class PuzzlePiece {
  final String id;
  final String imageAsset;
  final int correctX;
  final int correctY;

  PuzzlePiece({
    required this.id,
    required this.imageAsset,
    required this.correctX,
    required this.correctY,
  });
}
