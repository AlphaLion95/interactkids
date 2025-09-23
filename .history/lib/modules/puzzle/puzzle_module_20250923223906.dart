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
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_board_with_tray.dart';

class PuzzleTypeScreen extends StatelessWidget {
  final List<_PuzzleTheme> types = const [
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
    _PuzzleTheme('Flying', Icons.flutter_dash,
        Color(0xFFb39ddb)), // Changed to bird icon
  ];
  const PuzzleTypeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // No forced orientation here; handled per screen
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonHeight = (constraints.maxHeight - 120) / 3;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final type in types)
                            _AnimatedBigTypeButton(
                              type: type,
                              height: buttonHeight,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PuzzleLevelScreen(type: type),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
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
  // Save progress, userImages, and board states to shared_preferences
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = jsonEncode(progress);
    final userImagesJson = jsonEncode(userImages);
    await prefs.setString('puzzle_progress_${widget.type.name}', progressJson);
    await prefs.setString(
        'puzzle_userImages_${widget.type.name}', userImagesJson);
    // Save board states
    final boardStatesKey = 'puzzle_boardStates_${widget.type.name}';
    final boardStatesJson = jsonEncode(_boardStates);
    await prefs.setString(boardStatesKey, boardStatesJson);
  }

  // Load progress, userImages, and board states from shared_preferences
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressStr = prefs.getString('puzzle_progress_${widget.type.name}');
    final userImagesStr =
        prefs.getString('puzzle_userImages_${widget.type.name}');
    final boardStatesKey = 'puzzle_boardStates_${widget.type.name}';
    final boardStatesStr = prefs.getString(boardStatesKey);
    if (progressStr != null) {
      final decoded = jsonDecode(progressStr) as Map<String, dynamic>;
      progress = decoded.map((level, imgMap) => MapEntry(
            level,
            (imgMap as Map<String, dynamic>)
                .map((img, val) => MapEntry(img, (val as num).toDouble())),
          ));
    }
    if (userImagesStr != null) {
      final decoded = jsonDecode(userImagesStr) as Map<String, dynamic>;
      userImages = decoded
          .map((level, list) => MapEntry(level, List<String>.from(list)));
    }
    if (boardStatesStr != null) {
      final decoded = jsonDecode(boardStatesStr) as Map<String, dynamic>;
      _boardStates = decoded.map((level, imgMap) => MapEntry(
            level,
            (imgMap as Map<String, dynamic>).map(
                (img, state) => MapEntry(img, state as Map<String, dynamic>)),
          ));
    } else {
      _boardStates = {};
    }
    setState(() {});
  }

  // Structure: {level: {imagePath: {"boardState": [...], "pieceOrder": [...]}}}
  Map<String, Map<String, Map<String, dynamic>>> _boardStates = {};

  Future<void> _editImage(String level, String imgPath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imgPath,
      uiSettings: [
        AndroidUiSettings(
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
      progress[level]![imagePath] = 0.0;
      _saveProgress();
    }
    // Try to restore board state if exists
    List<int?>? boardState;
    List<int>? pieceOrder;
    if (_boardStates[level] != null &&
        _boardStates[level]![imagePath] != null) {
      final state = _boardStates[level]![imagePath]!;
      boardState = (state['boardState'] as List)
          .map((e) => e == null ? null : e as int)
          .toList();
      pieceOrder = (state['pieceOrder'] as List).map((e) => e as int).toList();
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleScreen(
          imagePath: imagePath,
          rows: gridSize,
          cols: gridSize,
          onProgress: (percent,
              {List<int?>? boardState, List<int>? pieceOrder}) async {
            setState(() {
              progress[level]![imagePath] = percent;
              // Save board state
              _boardStates[level] ??= {};
              _boardStates[level]![imagePath] = {
                'boardState': boardState,
                'pieceOrder': pieceOrder,
              };
            });
            await _saveProgress();
          },
          initialBoardState: boardState,
          initialPieceOrder: pieceOrder,
        ),
      ),
    ).then((_) {
      setState(() {}); // Refresh progress bar after returning
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          Column(
            children: [
              AppBar(
                title: Text('Select Level - ${widget.type.name}',
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
                          ...defaultImages[level]!
                              .map((img) => _PuzzleImageTile(
                                    imagePath: img,
                                    progress: progress[level]![img] ?? 0.0,
                                    onTap: () => _onImageTap(level, img),
                                    completed:
                                        (progress[level]![img] ?? 0.0) >= 1.0,
                                  )),
                          ...userImages[level]!.map((img) => Stack(
                                children: [
                                  _PuzzleImageTile(
                                    imagePath: img,
                                    progress: progress[level]![img] ?? 0.0,
                                    onTap: () => _onImageTap(level, img),
                                    completed:
                                        (progress[level]![img] ?? 0.0) >= 1.0,
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
  final bool completed;
  const _PuzzleImageTile({
    required this.imagePath,
    required this.progress,
    required this.onTap,
    this.completed = false,
  });
  @override
  Widget build(BuildContext context) {
    final bool isAsset = imagePath.startsWith('assets/');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Material(
              color: Colors.transparent,
              elevation: 12,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: Colors.orange.withOpacity(0.18),
                highlightColor: Colors.orange.withOpacity(0.10),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
                  child: ClipOval(
                    child: isAsset
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
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
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
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
            if (completed)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.white, size: 18),
                      SizedBox(width: 2),
                      Text(
                        'Done!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
  // --- State fields ---
  late List<int?> boardState;
  late List<int> pieceOrder;
  late int rows;
  late int cols;
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Always use Row: board (expanded) + tray (right)
              return Stack(
                children: [
                  // Back button at top left OUTSIDE the tray
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_back,
                                color: Colors.orange, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Board centered and maximized
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (_imageAspectRatio == null) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              // Maximize board size to all available height and width
                              const double trayWidth = 200;
                              const double trayMargin = 16;
                              double availableWidth = constraints.maxWidth;
                              double availableHeight = constraints.maxHeight;
                              double boardWidth = availableWidth;
                              double boardHeight =
                                  boardWidth / _imageAspectRatio!;
                              if (boardHeight > availableHeight) {
                                boardHeight = availableHeight;
                                boardWidth =
                                    boardHeight * _imageAspectRatio!;
                              }
                              return SizedBox(
                                width: boardWidth,
                                height: boardHeight,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(
                                          child:
                                              AnimatedBubblesBackground()),
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
                                          onPieceDropped:
                                              _onPieceDroppedToBoard,
                                          onPieceRemoved: (slotIdx) {
                                            if (boardState[slotIdx] != null) {
                                              _onPieceRemovedFromBoard(
                                                  slotIdx,
                                                  boardState[slotIdx]!);
                                            }
                                          },
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
                                          slotKeys: {
                                            for (var i = 0;
                                                i < _slotKeys.length;
                                                i++)
                                              i: _slotKeys[i]
                                          },
                                          dragGlobalPosition:
                                              _dragGlobalPosition,
                                          draggingPieceIdx: _draggingPieceIdx,
                                          highlightedIndex: _highlightedSlotIdx,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: IconButton(
                                            icon: const Icon(Icons.refresh,
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
                              );
                            },
                          ),
                        ),
                      ),
                      // Tray pinned to right (background and tray pieces)
                      Builder(
                        builder: (context) {
                          // Calculate board piece size to match tray pieces
                          double trayWidth = 200;
                          double availableWidth = constraints.maxWidth;
                          double availableHeight = constraints.maxHeight;
                          double boardWidth = availableWidth;
                          double boardHeight =
                              boardWidth / _imageAspectRatio!;
                          if (boardHeight > availableHeight) {
                            boardHeight = availableHeight;
                            boardWidth = boardHeight * _imageAspectRatio!;
                          }
                          double pieceSize = boardWidth / cols;
                          return DragTarget<int>(
                            onWillAccept: (data) {
                              // Accept if the piece is not already in the tray
                              return !pieceOrder.contains(data);
                            },
                            onAccept: (pieceIdx) {
                              // Remove from board and add to tray
                              int fromIdx = boardState.indexOf(pieceIdx);
                              if (fromIdx != -1) {
                                setState(() {
                                  boardState[fromIdx] = null;
                                  if (!pieceOrder.contains(pieceIdx)) {
                                    pieceOrder.add(pieceIdx);
                                  }
                                  widget.onProgress?.call(
                                    boardState.where((e) => e != null).length /
                                        (rows * cols),
                                    boardState: boardState,
                                    pieceOrder: pieceOrder,
                                  );
                                });
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                width: trayWidth,
                                margin: const EdgeInsets.only(
                                    top: 18, bottom: 18, right: 16),
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
                                          errorBuilder: (_, __, ___) =>
                                              SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                    // Tray pieces list
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        child: pieceOrder.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No pieces',
                                                  style: TextStyle(
                                                      color: Colors.orange
                                                          .shade700,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: pieceOrder.length,
                                                primary: false,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                itemBuilder:
                                                    (context, trayIdx) {
                                                  final pieceIdx =
                                                      pieceOrder[trayIdx];
                                                  return Draggable<int>(
                                                    data: pieceIdx, // Pass the actual piece index
                                                    feedback: Material(
                                                      color: Colors.transparent,
                                                      child: SizedBox(
                                                        width: pieceSize,
                                                        height: pieceSize,
                                                        child: PuzzlePiece(
                                                          imageProvider:
                                                              _imageProvider,
                                                          rows: rows,
                                                          cols: cols,
                                                          row: pieceIdx ~/
                                                              cols,
                                                          col: pieceIdx %
                                                              cols,
                                                        ),
                                                      ),
                                                    ),
                                                    childWhenDragging: Opacity(
                                                      opacity: 0.3,
                                                      child: SizedBox(
                                                        width: pieceSize,
                                                        height: pieceSize,
                                                        child: PuzzlePiece(
                                                          imageProvider:
                                                              _imageProvider,
                                                          rows: rows,
                                                          cols: cols,
                                                          row: pieceIdx ~/
                                                              cols,
                                                          col: pieceIdx %
                                                              cols,
                                                        ),
                                                      ),
                                                    ),
                                                    onDragStarted: () {
                                                      setState(() {
                                                        draggingIndex =
                                                            pieceIdx;
                                                        _draggingPieceIdx =
                                                            pieceIdx;
                                                      });
                                                    },
                                                    onDraggableCanceled:
                                                        (_, __) {
                                                      setState(() {
                                                        draggingIndex = null;
                                                        _draggingPieceIdx =
                                                            null;
                                                      });
                                                    },
                                                    onDragEnd: (_) {
                                                      setState(() {
                                                        draggingIndex = null;
                                                        _draggingPieceIdx =
                                                            null;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                              vertical: 6),
                                                      width: pieceSize,
                                                      height: pieceSize,
                                                      child: PuzzlePiece(
                                                        imageProvider:
                                                            _imageProvider,
                                                        rows: rows,
                                                        cols: cols,
                                                        row: pieceIdx ~/
                                                            cols,
                                                        col: pieceIdx %
                                                            cols,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                    // Optional: highlight tray when dragging over
                                    if (candidateData.isNotEmpty)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(32),
                                            border: Border.all(
                                                color: Colors.deepOrange,
                                                width: 4),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
                                                  child: pieceOrder.isEmpty
                                                      ? Center(
                                                          child: Text(
                                                            'No pieces',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .orange
                                                                    .shade700,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        )
                                                      : ListView.builder(
                                                          itemCount:
                                                              pieceOrder.length,
                                                          primary: false,
                                                          physics:
                                                              const ClampingScrollPhysics(),
                                                          itemBuilder: (context,
                                                              trayIdx) {
                                                            final pieceIdx =
                                                                pieceOrder[
                                                                    trayIdx];
                                                            return Draggable<
                                                                int>(
                                                              data:
                                                                  pieceIdx, // Pass the actual piece index
                                                              feedback:
                                                                  Material(
                                                                color: Colors
                                                                    .transparent,
                                                                child: SizedBox(
                                                                  width:
                                                                      pieceSize,
                                                                  height:
                                                                      pieceSize,
                                                                  child:
                                                                      PuzzlePiece(
                                                                    imageProvider:
                                                                        _imageProvider,
                                                                    rows: rows,
                                                                    cols: cols,
                                                                    row: pieceIdx ~/
                                                                        cols,
                                                                    col: pieceIdx %
                                                                        cols,
                                                                  ),
                                                                ),
                                                              ),
                                                              childWhenDragging:
                                                                  Opacity(
                                                                opacity: 0.3,
                                                                child: SizedBox(
                                                                  width:
                                                                      pieceSize,
                                                                  height:
                                                                      pieceSize,
                                                                  child:
                                                                      PuzzlePiece(
                                                                    imageProvider:
                                                                        _imageProvider,
                                                                    rows: rows,
                                                                    cols: cols,
                                                                    row: pieceIdx ~/
                                                                        cols,
                                                                    col: pieceIdx %
                                                                        cols,
                                                                  ),
                                                                ),
                                                              ),
                                                              onDragStarted:
                                                                  () {
                                                                setState(() {
                                                                  draggingIndex =
                                                                      pieceIdx;
                                                                  _draggingPieceIdx =
                                                                      pieceIdx;
                                                                });
                                                              },
                                                              onDraggableCanceled:
                                                                  (_, __) {
                                                                setState(() {
                                                                  draggingIndex =
                                                                      null;
                                                                  _draggingPieceIdx =
                                                                      null;
                                                                });
                                                              },
                                                              onDragEnd: (_) {
                                                                setState(() {
                                                                  draggingIndex =
                                                                      null;
                                                                  _draggingPieceIdx =
                                                                      null;
                                                                });
                                                              },
                                                              child: Container(
                                                                margin: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        6),
                                                                width:
                                                                    pieceSize,
                                                                height:
                                                                    pieceSize,
                                                                child:
                                                                    PuzzlePiece(
                                                                  imageProvider:
                                                                      _imageProvider,
                                                                  rows: rows,
                                                                  cols: cols,
                                                                  row:
                                                                      pieceIdx ~/
                                                                          cols,
                                                                  col:
                                                                      pieceIdx %
                                                                          cols,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                ),
                                              ),
                                              // Optional: highlight tray when dragging over
                                              if (candidateData.isNotEmpty)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              32),
                                                      border: Border.all(
                                                          color:
                                                              Colors.deepOrange,
                                                          width: 3),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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

  // _trayPieceWidget is now unused and can be removed.
}

// --- Animated, gamified, kid-friendly big type button ---
class _AnimatedBigTypeButton extends StatefulWidget {
  final _PuzzleTheme type;
  final double height;
  final VoidCallback onTap;
  const _AnimatedBigTypeButton(
      {required this.type, required this.height, required this.onTap});
  @override
  State<_AnimatedBigTypeButton> createState() => _AnimatedBigTypeButtonState();
}

class _AnimatedBigTypeButtonState extends State<_AnimatedBigTypeButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;
  late Animation<double> _sparkleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _sparkleAnim = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: widget.height.clamp(120, 200),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.type.color.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                      widget.type.color.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: widget.type.color.withOpacity(0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(
                    color: widget.type.color.withOpacity(0.7),
                    width: 4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _sparkleAnim,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _sparkleAnim.value,
                          child: Icon(widget.type.icon,
                              size: 54, color: Colors.white.withOpacity(0.95)),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.type.name,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: widget.type.color.darken(0.2),
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: widget.type.color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _AnimatedSparkle(color: widget.type.color),
                            const SizedBox(width: 8),
                            Text(
                              'Let\'s Go!',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: widget.type.color.darken(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Confetti overlay for extra fun
              Positioned(
                right: 32,
                top: 12,
                child: Opacity(
                  opacity: 0.7,
                  child: Icon(Icons.celebration,
                      color: widget.type.color, size: 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper sparkle animation
class _AnimatedSparkle extends StatefulWidget {
  final Color color;
  const _AnimatedSparkle({required this.color});
  @override
  State<_AnimatedSparkle> createState() => _AnimatedSparkleState();
}

class _AnimatedSparkleState extends State<_AnimatedSparkle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Transform.scale(
          scale: _anim.value,
          child: Icon(Icons.auto_awesome, color: widget.color, size: 28),
        );
      },
    );
  }
}

// Color darken extension
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _PuzzleTheme {
  final String name;
  final IconData icon;
  final Color color;
  const _PuzzleTheme(this.name, this.icon, this.color);
}

/* Puzzle selection screens (Type -> Level -> Play) */
