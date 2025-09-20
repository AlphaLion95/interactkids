import 'package:flutter/material.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_piece.dart';

class PuzzleBoardWithTray extends StatefulWidget {
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
  final void Function(Offset globalPosition, int pieceIdx)?
      onDragUpdateFromBoard;
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
    this.onHighlightSlot,
    this.dragGlobalPosition,
    this.draggingPieceIdx,
    this.onDragUpdateFromBoard,
    this.onDragUpdate,
  }) : super(key: key);

  @override
  State<PuzzleBoardWithTray> createState() => _PuzzleBoardWithTrayState();
}

class _PuzzleBoardWithTrayState extends State<PuzzleBoardWithTray> {
  Offset? _dragPosition;
  int? _draggingPieceIdx;
  int? _highlightedIndex;

  Rect _getPieceRect(
      int pieceIdx, Offset pos, double tileWidth, double tileHeight) {
    return Rect.fromCenter(center: pos, width: tileWidth, height: tileHeight);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double tileWidth = constraints.maxWidth / widget.cols;
      final double tileHeight = constraints.maxHeight / widget.rows;
      final children = <Widget>[];

      Map<int, Rect> slotRects = {};
      int? newHighlightedIndex;
      if (_dragPosition != null && _draggingPieceIdx != null) {
        for (int index = 0; index < widget.rows * widget.cols; index++) {
          if (widget.boardState[index] != null) continue;
          final key = widget.slotKeys != null ? widget.slotKeys![index] : null;
          if (key == null) continue;
          final renderBox =
              key.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) continue;
          final slotRect =
              (renderBox.localToGlobal(Offset.zero) & renderBox.size)
                  .inflate(6);
          slotRects[index] = slotRect;
          if (_getPieceRect(
                  _draggingPieceIdx!, _dragPosition!, tileWidth, tileHeight)
              .overlaps(slotRect)) {
            newHighlightedIndex = index;
            break;
          }
        }
      }
      if (_highlightedIndex != newHighlightedIndex) {
        setState(() {
          _highlightedIndex = newHighlightedIndex;
        });
      }
      if (widget.onHighlightSlot != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onHighlightSlot!(_highlightedIndex);
        });
      }

      for (int index = 0; index < widget.rows * widget.cols; index++) {
        final int row = index ~/ widget.cols;
        final int col = index % widget.cols;
        final int? pieceIdx = widget.boardState[index];
        final key = widget.slotKeys != null ? widget.slotKeys![index] : null;

        children.add(Positioned(
          left: col * tileWidth,
          top: row * tileHeight,
          width: tileWidth,
          height: tileHeight,
          child: DragTarget<int>(
            onWillAccept: (data) => pieceIdx == null,
            onAccept: (data) {
              if (widget.onPieceDropped != null && _highlightedIndex != null) {
                widget.onPieceDropped!(_highlightedIndex!, data);
              }
            },
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
                          imageProvider: widget.imageProvider,
                          rows: widget.rows,
                          cols: widget.cols,
                          row: pieceIdx ~/ widget.cols,
                          col: pieceIdx % widget.cols,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: tileWidth,
                    height: tileHeight,
                  ),
                  onDragStarted: () {
                    setState(() {
                      _draggingPieceIdx = pieceIdx;
                    });
                  },
                  onDragUpdate: (details) {
                    if (widget.onDragUpdate != null) {
                      widget.onDragUpdate!(details.globalPosition, pieceIdx);
                    }
                  },
                  onDragEnd: (details) {
                    setState(() {
                      _draggingPieceIdx = null;
                      _dragPosition = null;
                    });
                    if (widget.onEndDragging != null) widget.onEndDragging!();
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (widget.onPieceRemoved != null)
                        widget.onPieceRemoved!(index);
                    },
                    child: SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: RepaintBoundary(
                        key: ValueKey(
                            'board_rb_${index}_${widget.rows}_${widget.cols}'),
                        child: PuzzlePiece(
                          key: ValueKey(
                              'board_${index}_${widget.rows}_${widget.cols}'),
                          imageProvider: widget.imageProvider,
                          rows: widget.rows,
                          cols: widget.cols,
                          row: pieceIdx ~/ widget.cols,
                          col: pieceIdx % widget.cols,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                bool isHighlighted = (_highlightedIndex == index);
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

      return Listener(
        onPointerMove: (event) {
          setState(() {
            _dragPosition = event.localPosition;
          });
        },
        onPointerUp: (_) {
          setState(() {
            _dragPosition = null;
            _draggingPieceIdx = null;
          });
        },
        child: Stack(children: children),
      );
    });
  }
}
