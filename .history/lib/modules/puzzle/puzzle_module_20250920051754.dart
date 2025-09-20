// --- PUZZLE SELECTION SCREENS (Type -> Level -> Play) ---

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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


// --- PUZZLE LEVEL SELECTION SCREEN (FULL) ---
class PuzzleLevelScreen extends StatefulWidget {
  final _PuzzleTheme type;
  const PuzzleLevelScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<PuzzleLevelScreen> createState() => _PuzzleLevelScreenState();
}

class _PuzzleLevelScreenState extends State<PuzzleLevelScreen> with RouteAware {
  final List<String> levels = const ['Easy', 'Medium', 'Hard'];
  late Map<String, List<String>> imagesByLevel;
  Map<String, double> progress = {};
  late SharedPreferences prefs;
  final String _progressKey = 'puzzle_progress';

  @override
  void initState() {
    super.initState();
    imagesByLevel = {
      for (final level in levels)
        level: List.generate(
          5,
          (i) => 'assets/puzzle/${widget.type.name.toLowerCase()}_${level.toLowerCase()}_${i}.png',
        ),
    };
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_progressKey) ?? [];
    progress = {};
    for (final entry in list) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        progress[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
      }
    }
    setState(() {});
  }

  Future<void> _saveProgress() async {
    final flat = <String, String>{};
    progress.forEach((k, v) => flat[k] = v.toString());
    await prefs.setStringList(_progressKey, flat.entries.map((e) => '${e.key}=${e.value}').toList());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadProgress();
  }

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
                title: Text('Select Level - ${widget.type.name}', style: const TextStyle(fontFamily: 'Nunito')),
                backgroundColor: widget.type.color,
                elevation: 0,
                automaticallyImplyLeading: true,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: levels.length,
                  itemBuilder: (context, idx) {
                    final level = levels[idx];
                    final images = imagesByLevel[level]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text(level, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            itemBuilder: (context, imgIdx) {
                              final imgPath = images[imgIdx];
                              final prog = progress['${level}|$imgPath'] ?? 0.0;
                              return _PuzzleImageTile(
                                imagePath: imgPath,
                                progress: prog,
                                onTap: () async {
                                  final solved = prog >= 0.999;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PuzzleScreen(
                                        imagePath: imgPath,
                                        rows: idx == 0 ? 3 : idx == 1 ? 4 : 5,
                                        cols: idx == 0 ? 3 : idx == 1 ? 4 : 5,
                                        solved: solved,
                                        onProgress: (val) async {
                                          progress['${level}|$imgPath'] = val;
                                          await _saveProgress();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- PUZZLE GAME SCREEN (FULL) ---
typedef ProgressCallback = Future<void> Function(double progress);

class PuzzleScreen extends StatefulWidget {
  final String imagePath;
  final int rows;
  final int cols;
  final bool solved;
  final ProgressCallback? onProgress;
  const PuzzleScreen({Key? key, required this.imagePath, required this.rows, required this.cols, this.solved = false, this.onProgress}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late List<int?> boardState;
  late List<int> trayPieces;
  int? draggingIndex;
  bool isSolved = false;

  @override
  void initState() {
    super.initState();
    final total = widget.rows * widget.cols;
    if (widget.solved) {
      boardState = List.generate(total, (i) => i);
      trayPieces = [];
      isSolved = true;
    } else {
      boardState = List.filled(total, null);
      trayPieces = List.generate(total, (i) => i)..shuffle();
      isSolved = false;
    }
  }

  void _onPieceDropped(int boardIdx, int pieceIdx) {
    setState(() {
      boardState[boardIdx] = pieceIdx;
      trayPieces.remove(pieceIdx);
      _checkSolved();
    });
  }

  void _onPieceRemoved(int boardIdx) {
    setState(() {
      final piece = boardState[boardIdx];
      if (piece != null) {
        trayPieces.add(piece);
        boardState[boardIdx] = null;
      }
    });
  }

  void _onStartDraggingFromTray(int pieceIdx) {
    setState(() {
      draggingIndex = pieceIdx;
    });
  }

  void _onEndDragging() {
    setState(() {
      draggingIndex = null;
    });
  }

  void _resetPuzzle() {
    setState(() {
      final total = widget.rows * widget.cols;
      boardState = List.filled(total, null);
      trayPieces = List.generate(total, (i) => i)..shuffle();
      isSolved = false;
      widget.onProgress?.call(0.0);
    });
  }

  void _checkSolved() {
    final total = widget.rows * widget.cols;
    final correct = List.generate(total, (i) => boardState[i] == i).where((x) => x).length;
    final prog = correct / total;
    widget.onProgress?.call(prog);
    if (prog >= 0.999 && !isSolved) {
      setState(() {
        isSolved = true;
      });
      // Show win dialog
      Future.delayed(const Duration(milliseconds: 400), () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Congratulations!'),
            content: const Text('You solved the puzzle!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = widget.imagePath.startsWith('assets/')
        ? AssetImage(widget.imagePath)
        : FileImage(File(widget.imagePath)) as ImageProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPuzzle,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 320,
              height: 320,
              child: _PuzzleBoardWithTray(
                imageProvider: imageProvider,
                rows: widget.rows,
                cols: widget.cols,
                boardState: boardState,
                trayPieces: trayPieces,
                draggingIndex: draggingIndex,
                onPieceDropped: _onPieceDropped,
                onPieceRemoved: _onPieceRemoved,
                onStartDraggingFromTray: _onStartDraggingFromTray,
                onEndDragging: _onEndDragging,
              ),
            ),
            const SizedBox(height: 24),
            if (trayPieces.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final idx in trayPieces)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Draggable<int>(
                          data: idx,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: _PuzzlePiece(
                                imageProvider: imageProvider,
                                rows: widget.rows,
                                cols: widget.cols,
                                row: idx ~/ widget.cols,
                                col: idx % widget.cols,
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            width: 64,
                            height: 64,
                            color: Colors.transparent,
                          ),
                          onDragStarted: () => _onStartDraggingFromTray(idx),
                          onDragEnd: (_) => _onEndDragging(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: _PuzzlePiece(
                              imageProvider: imageProvider,
                              rows: widget.rows,
                              cols: widget.cols,
                              row: idx ~/ widget.cols,
                              col: idx % widget.cols,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (isSolved)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.celebration, color: Colors.green, size: 32),
                    SizedBox(width: 8),
                    Text('Puzzle Complete!', style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/* Puzzle selection screens (Type -> Level -> Play) */

