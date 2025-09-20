import 'package:flutter/material.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_piece.dart';

class PuzzleBoardWithTray extends StatelessWidget {
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
  final int? highlightedIndex; // <-- new: provided by parent
  final void Function(Offset globalPosition, int pieceIdx)? onDragUpdateFromBoard;
  final void Function(Offset globalPos, int pieceIdx)? onDragUpdate;

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
  }) : super(key: key);

  @override
  State<PuzzleBoardWithTray> createState() => _PuzzleBoardWithTrayState();
}

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
                        key: ValueKey(
                            'board_rb_${index}_${rows}_${cols}'),
                        child: PuzzlePiece(
                          key: ValueKey(
                              'board_${index}_${rows}_${cols}'),
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

      return Stack(children: children);
    });
  }
}
