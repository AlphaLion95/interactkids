// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PuzzleTypeScreen extends StatelessWidget {
  final List<_PuzzleTheme> types = const [
    _PuzzleTheme('Zoo', Icons.pets, Color(0xFFffb347)),
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
    _PuzzleTheme('Flying', Icons.flight, Color(0xFFb39ddb)),
  ];
  const PuzzleTypeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubbles()),
          Column(
            children: [
              AppBar(
                title: const Text('Select Puzzle Type', style: TextStyle(fontFamily: 'Nunito')),
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
                            label: Text(type.name, style: const TextStyle(fontFamily: 'Nunito', fontSize: 22)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: type.color,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
  RouteObserver<PageRoute>? _routeObserver;

  static const String _progressKey = 'puzzle_progress_v1';

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Flatten the progress map to a string map for storage
    final flat = <String, String>{};
    for (final level in progress.keys) {
      for (final img in progress[level]!.keys) {
        flat['$level|$img'] = progress[level]![img]!.toString();
      }
    }
    await prefs.setStringList(_progressKey, flat.entries.map((e) => '${e.key}=${e.value}').toList());
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_progressKey);
    if (list == null) return;
    for (final entry in list) {
      final idx = entry.indexOf('=');
      if (idx == -1) continue;
      final key = entry.substring(0, idx);
      final value = entry.substring(idx + 1);
      final parts = key.split('|');
      if (parts.length != 2) continue;
      final level = parts[0];
      final img = parts[1];
      final val = double.tryParse(value) ?? 0.0;
      if (progress.containsKey(level)) {
        progress[level]![img] = val;
      }
    }
    setState(() {});
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
        level: List.generate(5, (i) => 'assets/puzzle/${widget.type.name.toLowerCase()}_${level.toLowerCase()}_$i.png'),
    };
    userImages = {for (var level in levels) level: []};
    progress = {for (var level in levels) level: {}};
    _loadProgress();
    _routeObserver = RouteObserver<PageRoute>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    ModalRoute.of(context)?.observer?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    ModalRoute.of(context)?.observer?.unsubscribe(this);
    super.dispose();
  }

  // Called when coming back to this screen
  void didPopNext() {
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

  void _onImageTap(String level, String imagePath) async {
    final int gridSize = level == 'Easy' ? 3 : level == 'Medium' ? 4 : 5;
    // When returning from the puzzle, reload progress in case it changed
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleScreen(imagePath: imagePath, rows: gridSize, cols: gridSize),
      ),
    );
    await _loadProgress();
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
                title: Text('Select Level - ${widget.type.name}', style: const TextStyle(fontFamily: 'Nunito')),
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
                          Text(level, style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_a_photo, color: Colors.blue),
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
                              _PuzzleImageTile(
                                imagePath: img,
                                progress: progress[level]![img] ?? 0.0,
                                onTap: () => _onImageTap(level, img),
                              ),
                            for (final img in userImages[level]!)
                              _PuzzleImageTile(
                                imagePath: img,
                                progress: progress[level]![img] ?? 0.0,
                                onTap: () => _onImageTap(level, img),
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
  const _PuzzleImageTile({required this.imagePath, required this.progress, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bool isAsset = imagePath.startsWith('assets/');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.orange.withOpacity(0.18), blurRadius: 12, spreadRadius: 2, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.10), blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2)),
                ],
              ),
              child: ClipOval(
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.image, color: Colors.grey[400], size: 40)),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40)),
                      ),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 8,
              right: 8,
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
            if (progress >= 0.999) // Show badge if completed
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// --- PUZZLE MODULE: GAMIFIED UI RESTORE ---



/// Full puzzle module with fixes:
/// - initializes missing fields
/// - supports asset and file images
/// - drag & drop between tray and board
/// - reset, win detection, and win dialog
/// - pass rows/cols from level screen

class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  final int rows;
  final int cols;
  const PuzzleScreen({
    Key? key,
    this.imagePath,
    this.rows = 3,
    this.cols = 3,
  }) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  bool _progressSaved = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force landscape orientation when this screen is shown
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore orientation to allow both portrait and landscape when leaving
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

  // pieceOrder: indices of pieces currently in the tray (available pieces)
  late List<int> pieceOrder;

  // boardState: length rows*cols, each entry is either an int piece index or null
  late List<int?> boardState;

  int? draggingIndex;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    rows = widget.rows;
    cols = widget.cols;

    // prepare image provider (asset or file)
    if (widget.imagePath == null) {
      _imageProvider = const AssetImage('assets/puzzle/default.png');
    } else {
      final path = widget.imagePath!;
      if (path.startsWith('assets/')) {
        _imageProvider = AssetImage(path);
      } else {
        _imageProvider = FileImage(File(path));
      }
    }

    _getImageAspectRatio();
    _resetGame();
  }

  void _getImageAspectRatio() async {
    final ImageStream stream = _imageProvider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final width = info.image.width.toDouble();
      final height = info.image.height.toDouble();
      double aspect = width / height;
      // Clamp aspect ratio to a reasonable range to avoid extreme stretching
      if (aspect < 0.5) aspect = 0.5;
      if (aspect > 2.0) aspect = 2.0;
      setState(() {
        _imageAspectRatio = aspect;
      });
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  void _resetGame() {
    pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
    boardState = List.filled(rows * cols, null);
    draggingIndex = null;
    hasWon = false;
  }

  bool _isSolved() {
    for (int i = 0; i < boardState.length; i++) {
      if (boardState[i] != i) return false;
    }
    return true;
  }

  void _showWinDialog() async {
    if (!_progressSaved && widget.imagePath != null) {
      // Save progress for this image as 1.0 (completed)
      final contextLevel = _findLevelFromGridSize(widget.rows);
      if (contextLevel != null) {
        // Use root navigator to find PuzzleLevelScreen state and update progress
        final state = context.findAncestorStateOfType<_PuzzleLevelScreenState>();
        if (state != null) {
          state.progress[contextLevel]![widget.imagePath!] = 1.0;
          await state._saveProgress();
        }
      }
      _progressSaved = true;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("You Win!"),
        content: const Text("Great job — puzzle complete."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _resetGame());
              _progressSaved = false;
            },
            child: const Text("Play again"),
          ),
        ],
      ),
    );
  }

  String? _findLevelFromGridSize(int gridSize) {
    if (gridSize == 3) return 'Easy';
    if (gridSize == 4) return 'Medium';
    if (gridSize == 5) return 'Hard';
    return null;
  }

  /// Called when a piece is dropped onto board index [boardIdx] with piece index [pieceIdx]
  void _onPieceDroppedToBoard(int boardIdx, int pieceIdx) {
    setState(() {
      // remove piece from tray if present
      if (pieceOrder.contains(pieceIdx)) {
        pieceOrder.remove(pieceIdx);
      } else {
        // if it's coming from another board cell, clear that cell
        final prev = boardState.indexOf(pieceIdx);
        if (prev != -1) boardState[prev] = null;
      }

      // place on board
      boardState[boardIdx] = pieceIdx;
      draggingIndex = null;

      if (_isSolved()) {
        hasWon = true;
        // delay to allow UI update of final piece before dialog
        Future.delayed(const Duration(milliseconds: 150), () => _showWinDialog());
      }
    });
  }

  /// Called when a placed piece is removed (double tap) from board index [boardIdx]
  void _onPieceRemovedFromBoard(int boardIdx) {
    setState(() {
      final pieceIdx = boardState[boardIdx];
      if (pieceIdx != null) {
        boardState[boardIdx] = null;
        if (!pieceOrder.contains(pieceIdx)) {
          pieceOrder.add(pieceIdx);
        }
      }
    });
  }

  /// Put the UI together: faded guide image behind, board in center, tray at bottom and reset button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Puzzle', style: TextStyle(fontFamily: 'Nunito')),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => setState(() => _resetGame()),
              tooltip: 'Reset',
            ),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            // removed unused trayHeight
  // removed unused availableHeight
            return isLandscape
                ? Row(
                    children: [
                      // Puzzle board area (left, takes most space)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _imageAspectRatio ?? 1.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 500,
                                maxHeight: 500,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _imageAspectRatio == null
                                    ? const Center(child: CircularProgressIndicator())
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Stack(
                                          children: [
                                            // guide image slightly brightened underneath
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final boardW = constraints.maxWidth;
                                                final boardH = constraints.maxHeight;
                                                final imgAR = _imageAspectRatio ?? 1.0;
                                                double imgW = boardW;
                                                double imgH = boardH;
                                                double offsetX = 0;
                                                double offsetY = 0;
                                                if (boardW / boardH > imgAR) {
                                                  // board is wider than image: letterbox left/right
                                                  imgH = boardH;
                                                  imgW = imgH * imgAR;
                                                  offsetX = (boardW - imgW) / 2;
                                                } else {
                                                  // board is taller than image: letterbox top/bottom
                                                  imgW = boardW;
                                                  imgH = imgW / imgAR;
                                                  offsetY = (boardH - imgH) / 2;
                                                }
                                                return Stack(
                                                  children: [
                                                    // Guide image
                                                    Positioned(
                                                      left: offsetX,
                                                      top: offsetY,
                                                      width: imgW,
                                                      height: imgH,
                                                      child: Opacity(
                                                        opacity: 0.7,
                                                        child: Image(
                                                          image: _imageProvider,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                    ),
                                                    // Puzzle board overlay, perfectly aligned
                                                    Positioned(
                                                      left: offsetX,
                                                      top: offsetY,
                                                      width: imgW,
                                                      height: imgH,
                                                      child: _PuzzleBoardWithTray(
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
                                                          });
                                                        },
                                                        onEndDragging: () {
                                                          setState(() {
                                                            draggingIndex = null;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Tray area (right, vertical)
                      Container(
                        width: 180,
                        color: Colors.grey.withOpacity(0.04),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Expanded(
                              child: SizedBox.expand(
                                child: ListView.separated(
                                  scrollDirection: Axis.vertical,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemBuilder: (context, index) {
                                    final pieceIdx = pieceOrder[index];
                                    return Draggable<int>(
                                      data: pieceIdx,
                                      feedback: Material(
                                        color: Colors.transparent,
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
                                      childWhenDragging: Opacity(opacity: 0.25, child: _trayPieceWidget(_imageProvider, pieceIdx)),
                                      onDragStarted: () => setState(() => draggingIndex = pieceIdx),
                                      onDraggableCanceled: (_, __) => setState(() => draggingIndex = null),
                                      onDragEnd: (_) => setState(() => draggingIndex = null),
                                      child: _trayPieceWidget(_imageProvider, pieceIdx),
                                    );
                                  },
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemCount: pieceOrder.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text('Please rotate your device to landscape for the best puzzle experience.'));
          },
        ),
      ),
    );
  }

  Widget _trayPieceWidget(ImageProvider provider, int pieceIdx) {
    // Use the same aspect ratio as a board tile
    final double tileAspect = (cols > 0 && rows > 0) ? (_imageAspectRatio ?? 1.0) * rows / cols : 1.0;
    // Use a fixed tray piece height, width from aspect
    const double trayPieceHeight = 40; // smaller, more natural size
    final double trayPieceWidth = trayPieceHeight * tileAspect;
    return AspectRatio(
      aspectRatio: tileAspect,
      child: Container(
        width: trayPieceWidth,
        height: trayPieceHeight,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: trayPieceWidth,
              height: trayPieceHeight,
              child: _PuzzlePiece(
                imageProvider: provider,
                rows: rows,
                cols: cols,
                row: pieceIdx ~/ cols,
                col: pieceIdx % cols,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PuzzleBoardWithTray extends StatelessWidget {
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // build a grid of stack positioned DragTargets and placed Draggables
    return LayoutBuilder(builder: (context, constraints) {
      final double tileWidth = constraints.maxWidth / cols;
      final double tileHeight = constraints.maxHeight / rows;

      final children = <Widget>[];

      for (int index = 0; index < rows * cols; index++) {
        final int row = index ~/ cols;
        final int col = index % cols;
        final int? pieceIdx = boardState[index];

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
                  childWhenDragging: Container(
                    width: tileWidth,
                    height: tileHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  onDragStarted: () {
                    // nothing special here
                  },
                  onDragEnd: (details) {
                    if (onEndDragging != null) onEndDragging!();
                  },
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (onPieceRemoved != null) onPieceRemoved!(index);
                    },
                    child: Container(
                      width: tileWidth,
                      height: tileHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: _PuzzlePiece(
                        imageProvider: imageProvider,
                        rows: rows,
                        cols: cols,
                        row: pieceIdx ~/ cols,
                        col: pieceIdx % cols,
                      ),
                    ),
                  ),
                );
              } else {
                // empty slot: show placeholder
                return Container(
                  width: tileWidth,
                  height: tileHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.02),
                  ),
                  child: candidateData.isNotEmpty
                      ? Center(child: Opacity(opacity: 0.6, child: Icon(Icons.open_in_new, size: 28, color: Colors.orange)))
                      : null,
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
  }) : super(key: key); // Removed miniature parameter

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth;
        final double tileHeight = constraints.maxHeight;
        // The full image size is the size of the whole puzzle (board)
        final double fullWidth = tileWidth * cols;
        final double fullHeight = tileHeight * rows;
        // The region for this piece
        final Rect pieceRect = Rect.fromLTWH(
          col * tileWidth,
          row * tileHeight,
          tileWidth,
          tileHeight,
        );
        // Use a Stack to position the image so only the correct region is visible
        return ClipRect(
          child: SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: OverflowBox(
              maxWidth: fullWidth,
              maxHeight: fullHeight,
              minWidth: fullWidth,
              minHeight: fullHeight,
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(-pieceRect.left, -pieceRect.top),
                child: Image(
                  image: imageProvider,
                  width: fullWidth,
                  height: fullHeight,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* --------------------------
   Rest of the screens & helpers
   -------------------------- */

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

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(18, (i) => _Bubble.random());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
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
    final colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green, Colors.pink, Colors.yellow];
    return _Bubble(
      math.Random().nextDouble(),
      10 + math.Random().nextDouble() * 18,
      0.08 + math.Random().nextDouble() * 0.12,
      math.Random().nextDouble(),
      colors[math.Random().nextInt(colors.length)],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


/* Puzzle selection screens (Type -> Level -> Play) */

