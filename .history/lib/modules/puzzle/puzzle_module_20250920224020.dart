

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Minimal stub for missing PuzzlePiece widget
class PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int row;
  final int col;
  const PuzzlePiece({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Just show the image for now; real implementation should crop to piece
    return Image(image: imageProvider, fit: BoxFit.cover);
  }
}

class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  final int rows;
  final int cols;
  final void Function(double percent, {List<int?>? boardState, List<int>? pieceOrder})? onProgress;
  final List<int?>? initialBoardState;
  final List<int>? initialPieceOrder;
  const PuzzleScreen({
    Key? key,
    this.imagePath,
    this.rows = 3,
    this.cols = 3,
    this.onProgress,
    this.initialBoardState,
    this.initialPieceOrder,
  }) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

// --- PUZZLE PIECE PAINTER (top-level, for cropping) ---
// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

class _PuzzleImageTile extends StatelessWidget {
  final String imagePath;
  final double progress;
  final VoidCallback onTap;
  const _PuzzleImageTile(
      {required this.imagePath, required this.progress, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bool isAsset = imagePath.startsWith('assets/');
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Container(
              width: 74,
              height: 74,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.10),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 2)),
                ],
              ),
              child: ClipOval(
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 74,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: progress < 1.0 ? Colors.blue : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleScreenState extends State<PuzzleScreen> {

  @override
  Widget build(BuildContext context) {
    // TODO: Implement the actual puzzle UI
    return const Center(child: Text('PuzzleScreen UI goes here'));
  }
  // Store the board's onDragUpdate callback so tray Draggables can call it
  late int rows;
  late int cols;
  late List<int?> boardState;
  late List<int> pieceOrder;

  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    rows = widget.rows;
    cols = widget.cols;
    boardState = widget.initialBoardState ?? List<int?>.filled(rows * cols, null);
    pieceOrder = widget.initialPieceOrder ?? List<int>.generate(rows * cols, (i) => i);
  // Removed unused _imageProvider assignment
    // Removed _imageAspectRatio assignment (unused)
  }




}

// ...existing code...

// ...existing code...

// Top-level painter for puzzle piece cropping
// ...existing code...
// --------------------------
// Rest of the screens & helpers (top-level)
// --------------------------



// AnimatedBubbles and helpers moved to widgets/animated_bubbles.dart

/* Puzzle selection screens (Type -> Level -> Play) */
