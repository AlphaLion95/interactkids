import 'package:flutter/material.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_piece.dart';

class PuzzleBoardWithTray extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final List<int?> boardState;
  final List<int>? trayPieces;
  final int? draggingIndex;
  final void Function(int boardIdx, int pieceIdx)? onPieceDropped;
  final void Function(int boardIdx)? onPieceRemoved;
  final void Function(int pieceIdx)? onStartDraggingFromTray;
  final VoidCallback? onEndDragging;
  final Map<int, GlobalKey>? slotKeys;
  final Offset? dragGlobalPosition;
  final int? draggingPieceIdx;
  final int? highlightedIndex;
  final void Function(Offset globalPosition, int pieceIdx)?
      onDragUpdateFromBoard;
  final void Function(Offset globalPos, int pieceIdx)? onDragUpdate;
  final double? trayAreaWidth;

  const PuzzleBoardWithTray({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.boardState,
    this.trayPieces,
    this.draggingIndex,
    this.onPieceDropped,
    this.onPieceRemoved,
    this.onStartDraggingFromTray,
    this.onEndDragging,
    this.slotKeys,
    this.dragGlobalPosition,
    this.draggingPieceIdx,
    this.highlightedIndex,
    this.onDragUpdateFromBoard,
    this.onDragUpdate,
    this.trayAreaWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double tileWidth = constraints.maxWidth / cols;
      final double tileHeight = constraints.maxHeight / rows;
      final children = <Widget>[];

      for (int index = 0; index < rows * cols; index++) {
        final int row = index ~/ cols;
        final int col = index % cols;
        final int? pieceIdx = boardState[index];
        final key = slotKeys != null ? slotKeys![index] : null;

        children.add(Positioned(
          left: col * tileWidth,
          top: row * tileHeight,
          width: tileWidth,
          height: tileHeight,
          child: DragTarget<int>(
            builder: (context, candidateData, rejectedData) {
              if (pieceIdx != null) {
                return Draggable<int>(
                  data: pieceIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.translate(
                      offset: Offset(-tileWidth / 2, -tileHeight / 2),
                      child: SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: PuzzlePiece(
                          imageProvider: imageProvider,
                          rows: rows,
                          cols: cols,
                          row: pieceIdx ~/ cols,
                          col: pieceIdx % cols,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: tileWidth,
                    height: tileHeight,
                  ),
                  onDragUpdate: (details) {
                    if (onDragUpdate != null) {
                      onDragUpdate!(details.globalPosition, pieceIdx);
                    }
                  },
                  onDragEnd: (details) {
                    if (highlightedIndex != null && onPieceDropped != null) {
                      onPieceDropped!(highlightedIndex!, pieceIdx);
                    }
                    if (onEndDragging != null) onEndDragging!();
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (onPieceRemoved != null) {
                        onPieceRemoved!(index);
                      }
                    },
                    child: SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: RepaintBoundary(
                        key: ValueKey('board_rb_${index}_${rows}_${cols}'),
                        child: PuzzlePiece(
                          key: ValueKey('board_${index}_${rows}_${cols}'),
                          imageProvider: imageProvider,
                          rows: rows,
                          cols: cols,
                          row: pieceIdx ~/ cols,
                          col: pieceIdx % cols,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                bool isHighlighted = (highlightedIndex == index);
                return Container(
                  key: key,
                  width: tileWidth,
                  height: tileHeight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      border: isHighlighted
                          ? Border.all(color: Colors.deepOrange, width: 4)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      color: isHighlighted
                          ? Colors.orange.withOpacity(0.18)
                          : Colors.transparent,
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.18),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: isHighlighted
                        ? Center(
                            child: Opacity(
                                opacity: 0.7,
                                child: Icon(Icons.open_in_new,
                                    size: 32, color: Colors.deepOrange)))
                        : null,
                  ),
                );
              }
            },
          ),
        ));
      }

<<<<<<< HEAD
      // Add tray pieces as a vertical ListView aligned to the right if trayAreaWidth is set
      if (trayAreaWidth != null && trayPieces != null && trayPieces!.isNotEmpty) {
        children.add(Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: trayAreaWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 64, left: 8, right: 8, bottom: 8),
            child: ListView.builder(
              itemCount: trayPieces!.length,
              itemBuilder: (context, idx) {
                final pieceIdx = trayPieces![idx];
                return LongPressDraggable<int>(
                  data: pieceIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: PuzzlePiece(
                        imageProvider: imageProvider,
                        rows: rows,
                        cols: cols,
                        row: pieceIdx ~/ cols,
                        col: pieceIdx % cols,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: PuzzlePiece(
                        imageProvider: imageProvider,
                        rows: rows,
                        cols: cols,
                        row: pieceIdx ~/ cols,
                        col: pieceIdx % cols,
                      ),
                    ),
                  ),
                  onDragStarted: () {
                    if (onStartDraggingFromTray != null) {
                      onStartDraggingFromTray!(pieceIdx);
                    }
                  },
                  onDraggableCanceled: (_, __) {
                    if (onEndDragging != null) onEndDragging!();
                  },
                  onDragEnd: (_) {
                    if (onEndDragging != null) onEndDragging!();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    width: 64,
                    height: 64,
                    child: PuzzlePiece(
                      imageProvider: imageProvider,
                      rows: rows,
                      cols: cols,
                      row: pieceIdx ~/ cols,
                      col: pieceIdx % cols,
                    ),
                  ),
                );
              },
            ),
          ),
        ));
      }

      // Render board tiles and then overlay subtle grid lines on top
      return Stack(children: [
        ...children,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BoardGridPainter(
                  rows: rows,
                  cols: cols,
                  color: Colors.grey.withOpacity(0.18),
                  strokeWidth: 1.0),
            ),
          ),
        ),
      ]);
=======
      return Stack(children: [
        ...children,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BoardGridPainter(
                  rows: rows,
                  cols: cols,
                  color: Colors.grey.withOpacity(0.18),
                  strokeWidth: 1.0),
            ),
          ),
        ),
      ]);
>>>>>>> a16902b (Update the Puzzle sizes Board)
    });
  }
}

class _BoardGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final Color color;
  final double strokeWidth;

  _BoardGridPainter(
      {required this.rows,
      required this.cols,
      this.color = const Color(0x22000000),
      this.strokeWidth = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final tileW = size.width / cols;
    final tileH = size.height / rows;

    // Vertical lines
    for (int c = 1; c < cols; c++) {
      final x = c * tileW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (int r = 1; r < rows; r++) {
      final y = r * tileH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
