import 'package:flutter/material.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_piece.dart';

class PuzzleBoardWithTray extends StatelessWidget {
  final void Function(int?)? onHighlightSlot;
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final List<int?> boardState;
  final List<int>? trayPieces; // indices remaining in tray
  final int? draggingIndex;
  final void Function(int boardIdx, int pieceIdx)? onPieceDropped;
  final void Function(int boardIdx)? onPieceRemoved;
  final void Function(int pieceIdx)? onStartDraggingFromTray;
  final VoidCallback? onEndDragging;

  final Map<int, GlobalKey>? slotKeys;
  final Offset? dragGlobalPosition;
  final int? draggingPieceIdx;
  final void Function(Offset globalPosition, int pieceIdx)? onDragUpdateFromBoard;

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
    this.onHighlightSlot,
    this.onDragUpdateFromBoard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // build a grid of stack positioned DragTargets and placed Draggables
    return LayoutBuilder(builder: (context, constraints) {
      final double tileWidth = constraints.maxWidth / cols;
      final double tileHeight = constraints.maxHeight / rows;

      final children = <Widget>[];

      // --- Find the empty slot with the largest overlap (if any) ---
      int? highlightIndex;
      double maxOverlap = 0.0;
      Map<int, Rect> slotRects = {};
      Rect? dragRect;
      if (dragGlobalPosition != null && draggingPieceIdx != null) {
        // Compute dragRect size
        double dragW = 88, dragH = 88;
        if (trayPieces != null && !trayPieces!.contains(draggingPieceIdx)) {
          // Dragging from board
          dragW = tileWidth;
          dragH = tileHeight;
        }
        dragRect = Rect.fromCenter(
            center: dragGlobalPosition!, width: dragW, height: dragH);
        // For each empty slot, compute overlap area
        for (int index = 0; index < rows * cols; index++) {
          if (boardState[index] != null) continue;
          final key = slotKeys != null ? slotKeys![index] : null;
          if (key == null) continue;
          final renderBox =
              key.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) continue;
          final slotRect =
              renderBox.localToGlobal(Offset.zero) & renderBox.size;
          slotRects[index] = slotRect;
          if (dragRect.overlaps(slotRect)) {
            final overlapRect = dragRect.intersect(slotRect);
            final overlapArea = overlapRect.width * overlapRect.height;
            if (overlapArea > maxOverlap) {
              maxOverlap = overlapArea;
              highlightIndex = index;
            }
          }
        }
      }
      // Notify parent of the highlighted slot, but only after build
      if (onHighlightSlot != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onHighlightSlot!(highlightIndex);
        });
      }

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
            onWillAccept: (data) => pieceIdx == null, // accept only when empty
            onAccept: (data) {
              if (onPieceDropped != null) onPieceDropped!(index, data);
            },
            builder: (context, candidateData, rejectedData) {
              if (pieceIdx != null) {
                // placed piece: make it draggable so it can be moved to other slots or removed
                return Draggable<int>(
                  data: pieceIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.translate(
                      // Center the fixed-size piece under the finger
                      offset: Offset(-44, -44),
                      child: SizedBox(
                        width: 88,
                        height: 88,
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
                    // No border, transparent background
                  ),
                  onDragEnd: (details) {
                    if (onEndDragging != null) onEndDragging!();
                  },
                  onDragUpdate: (details) {
                    if (onDragUpdateFromBoard != null) {
                      final renderBox = context.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final globalPos = renderBox.localToGlobal(details.localPosition);
                        onDragUpdateFromBoard!(globalPos, pieceIdx);
                      }
                    }
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (onPieceRemoved != null) onPieceRemoved!(index);
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
                // Only highlight the empty slot with the largest overlap
                bool isHighlighted = (highlightIndex == index);
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

      return Stack(children: children);
    });
  }
}
