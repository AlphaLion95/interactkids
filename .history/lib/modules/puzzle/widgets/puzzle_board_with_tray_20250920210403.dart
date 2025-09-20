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
    class PuzzleBoardWithTray extends StatefulWidget {
      final void Function(int?)? onHighlightSlot;
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
      }) : super(key: key);

      @override
      State<PuzzleBoardWithTray> createState() => _PuzzleBoardWithTrayState();
    }

    class _PuzzleBoardWithTrayState extends State<PuzzleBoardWithTray> {
      Offset? _dragPosition;
      int? _draggingPieceIdx;

      Rect _getPieceRect(int pieceIdx, Offset pos, double tileWidth, double tileHeight) {
        return Rect.fromCenter(center: pos, width: tileWidth, height: tileHeight);
      }

      @override
      Widget build(BuildContext context) {
        return LayoutBuilder(builder: (context, constraints) {
          final double tileWidth = constraints.maxWidth / widget.cols;
          final double tileHeight = constraints.maxHeight / widget.rows;
          final children = <Widget>[];

          int? highlightIndex;
          Map<int, Rect> slotRects = {};
          if (_dragPosition != null && _draggingPieceIdx != null) {
            for (int index = 0; index < widget.rows * widget.cols; index++) {
              if (widget.boardState[index] != null) continue;
              final key = widget.slotKeys != null ? widget.slotKeys![index] : null;
              if (key == null) continue;
              final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox == null) continue;
              final slotRect = (renderBox.localToGlobal(Offset.zero) & renderBox.size).inflate(6);
              slotRects[index] = slotRect;
              if (_getPieceRect(_draggingPieceIdx!, _dragPosition!, tileWidth, tileHeight).overlaps(slotRect)) {
                highlightIndex = index;
                break;
              }
            }
          }
          if (widget.onHighlightSlot != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onHighlightSlot!(highlightIndex);
            });
          }


            _dragPosition = null;
            _draggingPieceIdx = null;
          });
        },
        child: Stack(children: children),
      );
    });
  }
}
