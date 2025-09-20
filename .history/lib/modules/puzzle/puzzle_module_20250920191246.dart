// --- PUZZLE PIECE PAINTER (top-level, for cropping) ---

// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class PuzzleTypeScreen extends StatelessWidget {
  final List<_PuzzleTheme> types = const [
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
    _PuzzleTheme('Flying', Icons.flight, Color(0xFFb39ddb)),
  ];
  const PuzzleTypeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // No forced orientation here; handled per screen
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubbles()),
          Column(
            children: [
              AppBar(
                title: const Text('Select Puzzle Type',
                    style: TextStyle(fontFamily: 'Nunito')),
                backgroundColor: Colors.orange,
                elevation: 0,
                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final type in types)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: ElevatedButton.icon(
                            icon: Icon(type.icon, color: Colors.white),
                            label: Text(type.name,
                                style: const TextStyle(
                                    fontFamily: 'Nunito', fontSize: 22)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: type.color,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PuzzleLevelScreen(type: type),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PuzzleLevelScreen extends StatefulWidget {
  final _PuzzleTheme type;
  const PuzzleLevelScreen({required this.type, super.key});
  @override
  State<PuzzleLevelScreen> createState() => _PuzzleLevelScreenState();
}

class _PuzzleLevelScreenState extends State<PuzzleLevelScreen> {
  final List<String> levels = ['Easy', 'Medium', 'Hard'];
  late Map<String, List<String>> defaultImages;
  late Map<String, List<String>> userImages;
  late Map<String, Map<String, double>> progress; // level -> image -> percent
  Map<String, Map<String, Map<String, dynamic>>> _boardStates = {};
  // Save progress, userImages, and board states to shared_preferences
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = jsonEncode(progress);
    final userImagesJson = jsonEncode(userImages);
    await prefs.setString('puzzle_progress_${widget.type.name}', progressJson);
    await prefs.setString('puzzle_userImages_${widget.type.name}', userImagesJson);
    // Save board states
    final boardStatesKey = 'puzzle_boardStates_${widget.type.name}';
    final boardStatesJson = jsonEncode(_boardStates);
    await prefs.setString(boardStatesKey, boardStatesJson);
  }
}

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
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PUZZLE MODULE: GAMEPLAY SCREEN ---

class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  final int rows;
  final int cols;
  final void Function(double percent,
      {List<int?>? boardState, List<int>? pieceOrder})? onProgress;
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

class _PuzzleScreenState extends State<PuzzleScreen> {
  // For advanced drag highlight
  Offset? _dragGlobalPosition;
  int? _draggingPieceIdx;
  final Map<int, GlobalKey> _slotKeys = {};
  int? _highlightedSlotIdx;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  double? _imageAspectRatio;
  late ImageProvider _imageProvider;
  late int rows;
  late int cols;
  late List<int?> boardState;
  late List<int> pieceOrder;
  int? draggingIndex;
  bool hasWon = false;
  bool showCelebration = false;

  @override
  void initState() {
    super.initState();
    rows = widget.rows;
    cols = widget.cols;
    _initImage();
    if (widget.initialBoardState != null && widget.initialPieceOrder != null) {
      boardState = List<int?>.from(widget.initialBoardState!);
      pieceOrder = List<int>.from(widget.initialPieceOrder!);
      draggingIndex = null;
      hasWon = false;
      setState(() {});
    } else {
      _resetGame();
    }
    // Initialize slot keys
    for (int i = 0; i < rows * cols; i++) {
      _slotKeys[i] = GlobalKey();
    }
  }

  void _initImage() {
    if (widget.imagePath != null && widget.imagePath!.startsWith('assets/')) {
      _imageProvider = AssetImage(widget.imagePath!);
    } else if (widget.imagePath != null) {
      _imageProvider = FileImage(File(widget.imagePath!));
    } else {
      _imageProvider = const AssetImage('assets/puzzle/zoo_easy_0.png');
    }
    // Preload image to get aspect ratio
    _getImageAspectRatio(_imageProvider).then((ratio) {
      setState(() {
        _imageAspectRatio = ratio;
      });
    });
  }

  Future<double> _getImageAspectRatio(ImageProvider provider) async {
    final completer = Completer<double>();
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final double aspect = info.image.width / info.image.height;
      completer.complete(aspect);
      stream.removeListener(listener);
    }, onError: (dynamic _, __) {
      completer.complete(1.0);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }

  // Removed per-screen orientation changes; handled globally

  void _resetGame() {
    boardState = List<int?>.filled(rows * cols, null);
    pieceOrder = List<int>.generate(rows * cols, (i) => i);
    draggingIndex = null;
    hasWon = false;
    setState(() {});
  }

  void _onPieceDroppedToBoard(int boardIdx, int pieceIdx) {
    setState(() {
      final prevIdx = boardState.indexOf(pieceIdx);
      final oldPiece = boardState[boardIdx];
      if (prevIdx != -1) {
        // Piece is being moved from another box (swap)
        boardState[prevIdx] = oldPiece;
        boardState[boardIdx] = pieceIdx;
      } else if (boardState[boardIdx] == null &&
          pieceOrder.contains(pieceIdx)) {
        // Piece is from tray
        boardState[boardIdx] = pieceIdx;
        pieceOrder.remove(pieceIdx);
      }
      draggingIndex = null;
      _checkWin();
      _updateProgress();
    });
  }

  void _onPieceRemovedFromBoard(int boardIdx) {
    setState(() {
      final pieceIdx = boardState[boardIdx];
      if (pieceIdx != null) {
        boardState[boardIdx] = null;
        pieceOrder.add(pieceIdx);
        draggingIndex = null;
        _updateProgress();
      }
    });
  }

  void _updateProgress() {
    // Calculate percent complete: only count pieces in the correct position
    int correct = 0;
    for (int i = 0; i < boardState.length; i++) {
      if (boardState[i] == i) {
        correct++;
      }
    }
    final percent = correct / boardState.length;
    if (widget.onProgress != null) {
      widget.onProgress!(percent,
          boardState: List<int?>.from(boardState),
          pieceOrder: List<int>.from(pieceOrder));
    }
  }

  void _checkWin() {
    if (boardState.every((e) => e != null)) {
      bool correct = true;
      for (int i = 0; i < boardState.length; i++) {
        if (boardState[i] != i) {
          correct = false;
          break;
        }
      }
      if (correct && !hasWon) {
        setState(() {
          hasWon = true;
          showCelebration = true;
        });
        // Show win dialog after a short delay so overlay is visible
        Future.delayed(const Duration(milliseconds: 400), () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('You Win!'),
              content: const Text('Great job — puzzle complete.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      showCelebration = false;
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: pieceOrder = '
        '${pieceOrder.toString()}');
    return Scaffold(
      body: SafeArea(
        child: Listener(
          onPointerMove: (details) {
            setState(() {
              _dragGlobalPosition = details.position;
            });
          },
          onPointerUp: (_) {
            // On drag end, if a piece is being dragged and a slot is highlighted, drop it there
            if (_draggingPieceIdx != null && _highlightedSlotIdx != null) {
              _onPieceDroppedToBoard(_highlightedSlotIdx!, _draggingPieceIdx!);
            }
            setState(() {
              _dragGlobalPosition = null;
              _draggingPieceIdx = null;
              _highlightedSlotIdx = null;
            });
          },
          child: Stack(
            children: [
              if (showCelebration) ConfettiAndBalloonsOverlay(),
              // ...existing code...
              // Floating Back Button (top left, pillow style, outside puzzle box)
              // ...existing code...
            ],
          ),
        ),
      ),
    );

  }

  Widget _trayPieceWidget(ImageProvider provider, int pieceIdx) {
    // Use a fixed size for tray pieces so all are visible
    const double trayPieceSize = 64;
    final int totalPieces = rows * cols;
    final bool valid = pieceIdx >= 0 && pieceIdx < totalPieces;
    // Make each tray slot a DragTarget so it can accept pieces from the board
    return DragTarget<int>(
      onWillAccept: (data) {
        // Accept if the piece is not already in the tray
        return data != null && !pieceOrder.contains(data);
      },
      onAccept: (data) {
        setState(() {
          // Remove from board and add back to tray
          final boardIdx = boardState.indexOf(data);
          if (boardIdx != -1) {
            boardState[boardIdx] = null;
            if (!pieceOrder.contains(data)) {
              pieceOrder.add(data);
            }
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: trayPieceSize,
          height: trayPieceSize,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: valid
                ? RepaintBoundary(
                    key: ValueKey('tray_rb_${pieceIdx}_${rows}_${cols}'),
                    child: _PuzzlePiece(
                      key: ValueKey('tray_${pieceIdx}_${rows}_${cols}'),
                      imageProvider: provider,
                      rows: rows,
                      cols: cols,
                      row: pieceIdx ~/ cols,
                      col: pieceIdx % cols,
                    ),
                  )
                : Center(child: Icon(Icons.error, color: Colors.red)),
          ),
        );
      },
    );
  }
}

class _PuzzleBoardWithTray extends StatelessWidget {
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

  const _PuzzleBoardWithTray({
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
        // Determine if dragging from tray or board
  bool fromTray = trayPieces?.contains(draggingPieceIdx) ?? false;
        double dragW, dragH;
        if (fromTray) {
          dragW = 88;
          dragH = 88;
        } else {
          dragW = tileWidth;
          dragH = tileHeight;
        }
    dragRect = Rect.fromCenter(
      center: dragGlobalPosition!, width: dragW, height: dragH).inflate(4);
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
                bool fromTray = trayPieces?.contains(pieceIdx) ?? false;
                double feedbackW = fromTray ? 88 : tileWidth;
                double feedbackH = fromTray ? 88 : tileHeight;
                return Draggable<int>(
                  data: pieceIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.translate(
                      // Center the piece under the finger
                      offset: Offset(-feedbackW / 2, -feedbackH / 2),
                      child: SizedBox(
                        width: feedbackW,
                        height: feedbackH,
                        child: _PuzzlePiece(
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
                  onDragStarted: () {
                    if (onStartDraggingFromTray != null) onStartDraggingFromTray!(pieceIdx);
                  },
                  onDragEnd: (details) {
                    if (onEndDragging != null) onEndDragging!();
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
                        child: _PuzzlePiece(
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

class _PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int row;
  final int col;

  const _PuzzlePiece({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageInfo>(
      future: _getImageInfo(imageProvider),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final imageInfo = snapshot.data!;
        final image = imageInfo.image;

        return CustomPaint(
          size: Size.infinite,
          painter: _PuzzlePainter(
            image: image,
            rows: rows,
            cols: cols,
            row: row,
            col: col,
          ),
        );
      },
    );
  }

  Future<ImageInfo> _getImageInfo(ImageProvider provider) async {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    return completer.future;
  }
}

// Top-level painter for puzzle piece cropping
class _PuzzlePainter extends CustomPainter {
  final ui.Image image;
  final int rows;
  final int cols;
  final int row;
  final int col;

  _PuzzlePainter({
    required this.image,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pieceWidth = image.width / cols;
    final pieceHeight = image.height / rows;

    final src = Rect.fromLTWH(
      col * pieceWidth,
      row * pieceHeight,
      pieceWidth,
      pieceHeight,
    );

    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// --------------------------
// Rest of the screens & helpers (top-level)
// --------------------------

class _PuzzleTheme {
  final String name;
  final IconData icon;
  final Color color;
  const _PuzzleTheme(this.name, this.icon, this.color);
}

class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({super.key});

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(18, (i) => _Bubble.random());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblesPainter(_bubbles, _controller.value),
        );
      },
    );
  }
}

class _Bubble {
  final double x, radius, speed, phase;
  final Color color;
  _Bubble(this.x, this.radius, this.speed, this.phase, this.color);
  static _Bubble random() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.pink,
      Colors.yellow
    ];
    final rnd = math.Random();
    return _Bubble(
      rnd.nextDouble(),
      10 + rnd.nextDouble() * 18,
      0.08 + rnd.nextDouble() * 0.12,
      rnd.nextDouble(),
      colors[rnd.nextInt(colors.length)],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double t;
  _BubblesPainter(this.bubbles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final y = size.height * ((b.speed * t + b.phase) % 1.0);
      final x = size.width * b.x;
      final paint = Paint()..color = b.color.withOpacity(0.18);
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
// --- Confetti and Balloons Celebration Overlay ---
class ConfettiAndBalloonsOverlay extends StatefulWidget {
  const ConfettiAndBalloonsOverlay({Key? key}) : super(key: key);

  @override
  State<ConfettiAndBalloonsOverlay> createState() => _ConfettiAndBalloonsOverlayState();
}

class _ConfettiAndBalloonsOverlayState extends State<ConfettiAndBalloonsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Balloon> _balloons;
  late List<_ConfettiParticle> _confetti;
  final int balloonCount = 8;
  final int confettiCount = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _balloons = List.generate(balloonCount, (i) => _Balloon.random(i));
    _confetti = List.generate(confettiCount, (i) => _ConfettiParticle.random());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _popBalloon(int idx) {
    setState(() {
      _balloons[idx] = _balloons[idx].copyWith(popped: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Stack(
              children: [
                // Confetti
                CustomPaint(
                  painter: _ConfettiPainter(_confetti, t),
                  size: MediaQuery.of(context).size,
                ),
                // Balloons
                ...List.generate(_balloons.length, (i) {
                  final b = _balloons[i];
                  if (b.popped) return SizedBox.shrink();
                  final animY = (1.0 - t) * (1.2 - b.speed) + b.initY * t;
                  return Positioned(
                    left: b.x * MediaQuery.of(context).size.width,
                    top: animY * MediaQuery.of(context).size.height - 80,
                    child: GestureDetector(
                      onTap: () => _popBalloon(i),
                      child: _BalloonWidget(color: b.color),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Balloon {
  final double x, speed, initY;
  final Color color;
  final bool popped;
  _Balloon(this.x, this.speed, this.initY, this.color, {this.popped = false});
  static _Balloon random(int i) {
    final rnd = math.Random(i * 1000 + DateTime.now().millisecondsSinceEpoch);
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.pink, Colors.yellow, Colors.cyan];
    return _Balloon(
      0.08 + rnd.nextDouble() * 0.84,
      0.7 + rnd.nextDouble() * 0.2,
      1.0 + rnd.nextDouble() * 0.2,
      colors[rnd.nextInt(colors.length)],
      popped: false,
    );
  }
  _Balloon copyWith({bool? popped}) => _Balloon(x, speed, initY, color, popped: popped ?? this.popped);
}

class _BalloonWidget extends StatelessWidget {
  final Color color;
  const _BalloonWidget({required this.color});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x, y, speed, angle, size;
  final Color color;
  _ConfettiParticle(this.x, this.y, this.speed, this.angle, this.size, this.color);
  static _ConfettiParticle random() {
    final rnd = math.Random();
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.pink, Colors.yellow, Colors.cyan];
    return _ConfettiParticle(
      rnd.nextDouble(),
      rnd.nextDouble() * 0.2,
      0.5 + rnd.nextDouble() * 0.7,
      rnd.nextDouble() * 2 * math.pi,
      6 + rnd.nextDouble() * 8,
      colors[rnd.nextInt(colors.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;
  final double t;
  _ConfettiPainter(this.confetti, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final progress = t;
      final x = c.x * size.width + math.sin(c.angle + t * 6) * 18;
      final y = c.y * size.height + progress * c.speed * size.height * 1.1;
      final paint = Paint()..color = c.color.withOpacity(0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.angle + t * 2);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.4), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/* Puzzle selection screens (Type -> Level -> Play) */

// --- Confetti and Balloons Celebration Overlay ---
