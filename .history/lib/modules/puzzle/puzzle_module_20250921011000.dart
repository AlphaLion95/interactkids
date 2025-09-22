// --- PUZZLE PIECE PAINTER (top-level, for cropping) ---

// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

// import 'dart:io';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_piece.dart';
import 'package:interactkids/modules/puzzle/widgets/animated_bubbles.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_board_with_tray.dart';

// ...existing code...

// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

class PuzzleLevelScreen extends StatefulWidget {
  final dynamic type;
  const PuzzleLevelScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<PuzzleLevelScreen> createState() => _PuzzleLevelScreenState();
}

class _PuzzleLevelScreenState extends State<PuzzleLevelScreen> {
  // Add all required fields here (levels, defaultImages, userImages, progress, etc.)
  // For now, use stubs to allow the file to compile. Replace with your real logic as needed.
  final List<String> levels = const ['Easy', 'Medium', 'Hard'];
  final Map<String, List<String>> defaultImages = const {
    'Easy': ['assets/puzzle/easy1.png'],
    'Medium': ['assets/puzzle/medium1.png'],
    'Hard': ['assets/puzzle/hard1.png'],
  };
  final Map<String, List<String>> userImages = const {
    'Easy': [],
    'Medium': [],
    'Hard': [],
  };
  final Map<String, Map<String, double>> progress = const {
    'Easy': {},
    'Medium': {},
    'Hard': {},
  };

  void _addImage(String level) {}
  void _onImageTap(String level, String img) {}
  void _editImage(String level, String img) async {}
  void _saveProgress() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubbles()),
          Column(
            children: [
              AppBar(
                title: Text('Select Level - {widget.type.name}',
                    style: const TextStyle(fontFamily: 'Nunito')),
                backgroundColor: widget.type.color,
                elevation: 0,
                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final level in levels) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(level,
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_a_photo,
                                color: Colors.blue),
                            onPressed: () => _addImage(level),
                          ),
                        ],
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        children: [
                          ...defaultImages[level]!.map((img) => _PuzzleImageTile(
                                imagePath: img,
                                progress: progress[level]![img] ?? 0.0,
                                onTap: () => _onImageTap(level, img),
                              )),
                          ...userImages[level]!.map((img) => Stack(
                                children: [
                                  _PuzzleImageTile(
                                    imagePath: img,
                                    progress: progress[level]![img] ?? 0.0,
                                    onTap: () => _onImageTap(level, img),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 32, color: Colors.blue),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          tooltip: 'Edit',
                                          onPressed: () async {
                                            await _editImage(level, img);
                                            await _saveProgress();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 32, color: Colors.red),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            setState(() {
                                              userImages[level]!.remove(img);
                                              progress[level]!.remove(img);
                                            });
                                            await _saveProgress();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            splashColor: Colors.orange.withOpacity(0.18),
            highlightColor: Colors.orange.withOpacity(0.10),
            child: Container(
              width: 96,
              height: 82,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.orange.shade50,
                    Colors.orange.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.18),
                    blurRadius: 18,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.orange.withOpacity(0.22),
                  width: 2.2,
                ),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: Colors.white,
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
            ),
          ),
        ),
        const SizedBox(height: 8),
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
  // Helper to update highlight index based on pointer position
  void _updateHighlightSlot(Offset globalPosition) {
    // Find the board area RenderBox
    final boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null) return;
    // Find the board widget's position and size
    final boardStack = boardBox.size;
    // Find the board area (centered in parent)
    final boardWidth = 500.0; // match maxWidth constraint
    final boardHeight = 500.0; // match maxHeight constraint
    final parentSize = boardStack;
    final boardLeft = (parentSize.width - boardWidth) / 2 + 16; // 16 padding
    final boardTop = (parentSize.height - boardHeight) / 2 + 16;
    final tileWidth = boardWidth / cols;
    final tileHeight = boardHeight / rows;
    // Convert global pointer to board-local
    final local =
        Offset(globalPosition.dx - boardLeft, globalPosition.dy - boardTop);
    int? foundIdx;
    for (int idx = 0; idx < rows * cols; idx++) {
      if (boardState[idx] != null) continue;
      final row = idx ~/ cols;
      final col = idx % cols;
      final rect = Rect.fromLTWH(
              col * tileWidth, row * tileHeight, tileWidth, tileHeight)
          .inflate(6);
      if (rect.contains(local)) {
        foundIdx = idx;
        break;
      }
    }
    if (_highlightedSlotIdx != foundIdx) {
      setState(() {
        _highlightedSlotIdx = foundIdx;
      });
    }
  }

  // For advanced drag highlight
  Offset? _dragGlobalPosition;
  int? _draggingPieceIdx;
  final Map<int, GlobalKey> _slotKeys = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerMove: (details) {
          setState(() {
            _dragGlobalPosition = details.position;
          });
          _updateHighlightSlot(details.position);
        },
        onPointerUp: (_) {
          if (_draggingPieceIdx != null && _highlightedSlotIdx != null) {
            _onPieceDroppedToBoard(_highlightedSlotIdx!, _draggingPieceIdx!);
          }
          setState(() {
            _dragGlobalPosition = null;
            _draggingPieceIdx = null;
            _highlightedSlotIdx = null;
          });
        },
        child: SafeArea(
          child: Stack(
            children: [
              if (hasWon)
                const ConfettiAndBalloonsOverlay(show: true),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = constraints.maxWidth > constraints.maxHeight;
                  if (!isLandscape) {
                    return const Center(
                      child: Text('Please rotate your device to landscape for the best puzzle experience.'),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 500,
                              maxHeight: 500,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: (_imageAspectRatio == null)
                                  ? const Center(child: CircularProgressIndicator())
                                  : Stack(
                                      children: [
                                        const Positioned.fill(child: AnimatedBubbles()),
                                        AspectRatio(
                                          aspectRatio: _imageAspectRatio!,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: Opacity(
                                                    opacity: 0.7,
                                                    child: Image(
                                                      image: _imageProvider,
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: PuzzleBoardWithTray(
                                                    imageProvider: _imageProvider,
                                                    rows: rows,
                                                    cols: cols,
                                                    boardState: boardState,
                                                    draggingIndex: draggingIndex,
                                                    onPieceDropped: _onPieceDroppedToBoard,
                                                    onPieceRemoved: _onPieceRemovedFromBoard,
                                                    trayPieces: pieceOrder,
                                                    onStartDraggingFromTray: (index) {
                                                      setState(() {
                                                        draggingIndex = index;
                                                        _draggingPieceIdx = index;
                                                      });
                                                    },
                                                    onEndDragging: () {
                                                      setState(() {
                                                        draggingIndex = null;
                                                        _draggingPieceIdx = null;
                                                      });
                                                    },
                                                    slotKeys: _slotKeys,
                                                    dragGlobalPosition: _dragGlobalPosition,
                                                    draggingPieceIdx: _draggingPieceIdx,
                                                    highlightedIndex: _highlightedSlotIdx,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: IconButton(
                                              icon: const Icon(Icons.refresh, color: Colors.orange, size: 32),
                                              onPressed: _resetGame,
                                              tooltip: 'Reset',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 200,
                        margin: const EdgeInsets.only(top: 18, bottom: 18, right: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade200,
                              Colors.yellow.shade100,
                              Colors.orange.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.18),
                              blurRadius: 24,
                              spreadRadius: 4,
                              offset: Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.deepOrange,
                            width: 4,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.10,
                                child: Image.asset(
                                  'assets/puzzle/tray_pattern.png',
                                  fit: BoxFit.cover,
                                  repeat: ImageRepeat.repeat,
                                  errorBuilder: (_, __, ___) => SizedBox.shrink(),
                                ),
                              ),
                            ),
                            DragTarget<int>(
                              onWillAccept: (data) {
                                return data != null && boardState.contains(data);
                              },
                              onAccept: (data) {
                                _onPieceRemovedFromBoard(boardState.indexOf(data));
                              },
                              builder: (context, candidateData, rejectedData) {
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                                  itemBuilder: (context, idx) {
                                    final pieceIdx = pieceOrder[idx];
                                    return LongPressDraggable<int>(
                                      data: pieceIdx,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: _trayPieceWidget(_imageProvider, pieceIdx),
                                      ),
                                      childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: _trayPieceWidget(_imageProvider, pieceIdx)),
                                      onDragStarted: () {
                                        if (onStartDraggingFromTray != null) {
                                          onStartDraggingFromTray!(pieceIdx);
                                        }
                                      },
                                      onDragEnd: (_) {
                                        if (onEndDragging != null) {
                                          onEndDragging!();
                                        }
                                      },
                                      child: _trayPieceWidget(_imageProvider, pieceIdx),
                                    );
                                  },
                                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                                  itemCount: pieceOrder.length,
                                );
                              },
                            ),
                            Positioned(
                              right: 6,
                              top: 24,
                              bottom: 24,
                              child: IgnorePointer(
                                child: Container(
                                  width: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade300.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepOrange.withOpacity(0.18),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Floating Back Button (top left, pillow style, outside puzzle box)
              Positioned(
                top: 18,
                left: 18,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: Colors.orange, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ...existing code...

// ...existing code...

// Top-level painter for puzzle piece cropping
// ...existing code...
// --------------------------
// Rest of the screens & helpers (top-level)
// --------------------------


class _PuzzleTheme {
  final String name;
  final IconData icon;
  final Color color;
  const _PuzzleTheme(this.name, this.icon, this.color);
}

// ...existing code...
// AnimatedBubbles and helpers moved to widgets/animated_bubbles.dart

/* Puzzle selection screens (Type -> Level -> Play) */
