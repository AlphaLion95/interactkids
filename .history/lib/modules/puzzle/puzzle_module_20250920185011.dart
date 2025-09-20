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
          const Positioned.fill(child: AnimatedBubbles()),
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
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final img in defaultImages[level]!)
                              GestureDetector(
                                onTap: () => _onImageTap(level, img),
                                child: Stack(
                                  children: [
                                    _PuzzleImageTile(
                                      imagePath: img,
                                      progress: progress[level]![img] ?? 0.0,
                                      onTap: () {}, // no-op, handled by parent
                                    ),
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
                          ],
                        ),
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
      if (correct) {
        hasWon = true;
        // Simple win dialog
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
                        child: Icon(Icons.arrow_back,
                            color: Colors.orange, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
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
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : Stack(
                                            children: [
                                              const Positioned.fill(
                                                  child: AnimatedBubbles()),
                                              AspectRatio(
                                                aspectRatio: _imageAspectRatio!,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Opacity(
                                                          opacity: 0.7,
                                                          child: Image(
                                                            image:
                                                                _imageProvider,
                                                            fit: BoxFit.fill,
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned.fill(
                                                        child:
                                                            _PuzzleBoardWithTray(
                                                          imageProvider:
                                                              _imageProvider,
                                                          rows: rows,
                                                          cols: cols,
                                                          boardState:
                                                              boardState,
                                                          draggingIndex:
                                                              draggingIndex,
                                                          onPieceDropped:
                                                              _onPieceDroppedToBoard,
                                                          onPieceRemoved:
                                                              _onPieceRemovedFromBoard,
                                                          trayPieces:
                                                              pieceOrder,
                                                          onStartDraggingFromTray:
                                                              (index) {
                                                            setState(() {
                                                              draggingIndex =
                                                                  index;
                                                              _draggingPieceIdx =
                                                                  index;
                                                            });
                                                          },
                                                          onEndDragging: () {
                                                            setState(() {
                                                              draggingIndex =
                                                                  null;
                                                              _draggingPieceIdx =
                                                                  null;
                                                            });
                                                          },
                                                          slotKeys: _slotKeys,
                                                          dragGlobalPosition:
                                                              _dragGlobalPosition,
                                                          draggingPieceIdx:
                                                              _draggingPieceIdx,
                                                          onHighlightSlot:
                                                              (idx) {
                                                            if (_highlightedSlotIdx !=
                                                                idx) {
                                                              setState(() {
                                                                _highlightedSlotIdx =
                                                                    idx;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Reset button floating at top right of puzzle area
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Material(
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
                                              // Offset so the top left of the piece is at the finger, not the center
                                              offset: Offset(0, 0),
                                              child: SizedBox(
                                                width: 88,
                                                height: 88,
                                                child: _PuzzlePiece(
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
                                    ),
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
      // Notify parent of the highlighted slot
      if (onHighlightSlot != null) {
        onHighlightSlot!(highlightIndex);
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
                      // Center the piece under the finger
                      offset: Offset(-tileWidth / 2, -tileHeight / 2),
                      child: SizedBox(
                        width: tileWidth,
                        height: tileHeight,
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

/* Puzzle selection screens (Type -> Level -> Play) */
