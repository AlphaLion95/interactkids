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
import 'package:interactkids/modules/puzzle/widgets/confetti_and_balloons_overlay.dart';

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
// ...existing code...
          toolbarTitle: 'Edit Puzzle Image',
          toolbarColor: Colors.orange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Edit Puzzle Image',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    if (cropped != null && cropped.path != imgPath) {
      setState(() {
        final idx = userImages[level]!.indexOf(imgPath);
        if (idx != -1) {
          userImages[level]![idx] = cropped.path;
          // Optionally reset progress for the new image
          progress[level]!.remove(imgPath);
          progress[level]![cropped.path] = 0.0;
        }
      });
    }
  }

  final List<String> levels = ['Easy', 'Medium', 'Hard'];
  late Map<String, List<String>> defaultImages;
  late Map<String, List<String>> userImages;
  late Map<String, Map<String, double>> progress; // level -> image -> percent

  @override
  void initState() {
    super.initState();
    defaultImages = {
      for (var level in levels)
        level: List.generate(
            5,
            (i) =>
                'assets/puzzle/${widget.type.name.toLowerCase()}_${level.toLowerCase()}_$i.png'),
    };
    userImages = {for (var level in levels) level: []};
    progress = {for (var level in levels) level: {}};
    _loadProgress();
  }

  Future<void> _addImage(String level) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        userImages[level]!.add(picked.path);
        progress[level]![picked.path] = 0.0;
      });
      await _saveProgress();
    }
  }

  void _onImageTap(String level, String imagePath) {
    final int numPieces = (level == 'Easy')
        ? 3 * 3
        : (level == 'Medium')
            ? 4 * 4
            : 5 * 5;
    print('DEBUG: Selected $level puzzle with $numPieces pieces');
    final int gridSize = level == 'Easy'
        ? 3
        : level == 'Medium'
            ? 4
            : 5;
    // Ensure progress entry exists for default images
    if (!progress[level]!.containsKey(imagePath)) {
// ...existing code...
                                      onTap: () {} // no-op, handled by parent
                                    )
                                    // Invisible edit/delete for alignment
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Row(
                                        children: [
                                          Opacity(
                                            opacity: 0.0,
                                            child: IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 18, color: Colors.blue),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: null,
                                            ),
                                          ),
                                          Opacity(
                                            opacity: 0.0,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 18, color: Colors.red),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            for (final img in userImages[level]!)
                              Stack(
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
                                              size: 18, color: Colors.blue),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Edit',
                                          onPressed: () async {
                                            await _editImage(level, img);
                                            await _saveProgress();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
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
                              ),
                        ], // end children of Column
                      ), // end Center
                      const SizedBox(height: 24),
                    ],
                  ), // end main Column
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
  // Store the board's onDragUpdate callback so tray Draggables can call it
  void Function(Offset, int)? _boardOnDragUpdate;
  // For advanced drag highlight
  Offset? _dragGlobalPosition;
  Offset? _dragPosition;
  int? _draggingPieceIdx;
  final Map<int, GlobalKey> _slotKeys = {};
  int? _highlightedSlotIdx;
  int? draggingIndex;
  late int rows;
  late int cols;
  late List<int?> boardState;
  late List<int> pieceOrder;
  late ImageProvider _imageProvider;
  double? _imageAspectRatio;
  bool _showCelebration = false;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    rows = widget.rows;
    cols = widget.cols;
    boardState = widget.initialBoardState ?? List<int?>.filled(rows * cols, null);
    pieceOrder = widget.initialPieceOrder ?? List<int>.generate(rows * cols, (i) => i);
    // Dummy image provider for now; replace with actual image loading logic
    _imageProvider = const AssetImage('assets/sample.jpg');
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
      print('DEBUG: pieceOrder = '
          'pieceOrder.toString()');
      return Scaffold(
        body: SafeArea(
          child: Listener(
            onPointerMove: (details) {
              if (_draggingPieceIdx != null) {
                setState(() {
                  _dragGlobalPosition = details.position;
                });
              }
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
            child: Stack(
              children: [
                ConfettiAndBalloonsOverlay(
                  show: _showCelebration,
                  onAllBalloonsPopped: () {
                    setState(() {
                      _showCelebration = false;
                    });
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('You Win!'),
                        content: const Text('Great job — puzzle complete.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                          child: Icon(Icons.arrow_back,
                              color: Colors.orange, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;
                    return isLandscape
                        ? Row(
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
                                                            onHighlightSlot: (idx) {
                                                              if (_highlightedSlotIdx != idx) {
                                                                setState(() {
                                                                  _highlightedSlotIdx = idx;
                                                                });
                                                              }
                                                            },
                                                            onDragUpdate: (globalPos, pieceIdx) {
                                                              final boardBox = _slotKeys[0]?.currentContext?.findRenderObject() as RenderBox?;
                                                              if (boardBox != null) {
                                                                final local = boardBox.globalToLocal(globalPos);
                                                                setState(() {
                                                                  _draggingPieceIdx = pieceIdx;
                                                                  _dragGlobalPosition = globalPos;
                                                                  _dragPosition = local;
                                                                });
                                                              }
                                                              _boardOnDragUpdate = (globalPos, pieceIdx);
                                                            },
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
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 180,
                                color: Colors.grey.withOpacity(0.04),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.separated(
                                        scrollDirection: Axis.vertical,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        itemBuilder: (context, index) {
                                          final pieceIdx = pieceOrder[index];
                                          return Draggable<int>(
                                            data: pieceIdx,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: Transform.translate(
                                                offset: Offset(0, 0),
                                                child: SizedBox(
                                                  width: 88,
                                                  height: 88,
                                                  child: PuzzlePiece(
                                                    imageProvider: _imageProvider,
                                                    rows: rows,
                                                    cols: cols,
                                                    row: pieceIdx ~/ cols,
                                                    col: pieceIdx % cols,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.25,
                                              child: _trayPieceWidget(_imageProvider, pieceIdx),
                                            ),
                                            onDragStarted: () => setState(() {
                                              draggingIndex = pieceIdx;
                                              _draggingPieceIdx = pieceIdx;
                                            }),
                                            onDragUpdate: (details) {
                                              if (_boardOnDragUpdate != null) {
                                                _boardOnDragUpdate!(details.globalPosition, pieceIdx);
                                              }
                                            },
                                            onDraggableCanceled: (_, __) => setState(() {
                                              draggingIndex = null;
                                              _draggingPieceIdx = null;
                                            }),
                                            onDragEnd: (_) => setState(() {
                                              draggingIndex = null;
                                              _draggingPieceIdx = null;
                                            }),
                                            child: _trayPieceWidget(_imageProvider, pieceIdx),
                                          );
                                        },
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemCount: pieceOrder.length,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Text('Please rotate your device to landscape for the best puzzle experience.'),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      );
                                                  color: Colors.transparent,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.refresh,
                                                        color: Colors.orange,
                                                        size: 32),
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
                              width: 180,
                              color: Colors.grey.withOpacity(0.04),
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.separated(
                                      scrollDirection: Axis.vertical,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      itemBuilder: (context, index) {
                                        final pieceIdx = pieceOrder[index];
                                        return Draggable<int>(
                                          data: pieceIdx,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: Transform.translate(
                                              offset: Offset(0, 0),
                                              child: SizedBox(
                                                width: 88,
                                                height: 88,
                                                child: PuzzlePiece(
                                                  imageProvider: _imageProvider,
                                                  rows: rows,
                                                  cols: cols,
                                                  row: pieceIdx ~/ cols,
                                                  col: pieceIdx % cols,
                                                ),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.25,
                                            child: _trayPieceWidget(
                                                _imageProvider, pieceIdx),
                                          ),
                                          onDragStarted: () => setState(() {
                                            draggingIndex = pieceIdx;
                                            _draggingPieceIdx = pieceIdx;
                                          }),
                                          onDragUpdate: (details) {
                                            if (_boardOnDragUpdate != null) {
                                              _boardOnDragUpdate!(details.globalPosition, pieceIdx);
                                            }
                                          },
                                          onDraggableCanceled: (_, __) =>
                                              setState(() {
                                            draggingIndex = null;
                                            _draggingPieceIdx = null;
                                          }),
                                          onDragEnd: (_) => setState(() {
                                            draggingIndex = null;
                                            _draggingPieceIdx = null;
                                          }),
                                          child: _trayPieceWidget(
                                              _imageProvider, pieceIdx),
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemCount: pieceOrder.length,
                            );
                              }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                              'Please rotate your device to landscape for the best puzzle experience.'),
                        );
                },
              ),
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
                    child: PuzzlePiece(
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
