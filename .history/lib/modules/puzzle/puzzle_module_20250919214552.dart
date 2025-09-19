// Puzzle module entry
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  const PuzzleScreen({Key? key, this.imagePath}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final int rows = 2;
  final int cols = 3;
  late List<int> pieceOrder; // shuffled order for tray
  late List<int?> boardState; // null = empty, int = piece index
  int? draggingIndex;
  bool hasWon = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
    boardState = List.filled(rows * cols, null);
    if (widget.imagePath != null) {
      if (widget.imagePath!.startsWith('assets/')) {
        _imageProvider = AssetImage(widget.imagePath!);
      } else {
        _imageProvider = FileImage(File(widget.imagePath!));
      }
    }
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

  void _onPieceDropped(int boardIdx, int pieceIdx) {
    setState(() {
      boardState[boardIdx] = pieceIdx;
      pieceOrder.remove(pieceIdx);
      draggingIndex = null;
      if (_isSolved()) {
        hasWon = true;
        _showWinDialog();
      }
    });
  }

  bool _isSolved() {
    for (int i = 0; i < boardState.length; i++) {
      if (boardState[i] != i) return false;
    }
    return true;
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Congratulations!', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            const Text('You solved the puzzle!', style: TextStyle(fontFamily: 'Nunito', fontSize: 20)),
            const SizedBox(height: 16),
            // Simple confetti animation
            SizedBox(
              height: 60,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Icon(Icons.star, color: Colors.pinkAccent, size: 48 + value * 16),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                hasWon = false;
                pieceOrder.shuffle();
              });
            },
            child: const Text('Play Again', style: TextStyle(fontFamily: 'Nunito', color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubbles()),
          SafeArea(
            child: Row(
              children: [
                // Tray of pieces on the left
                Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: ListView(
                    children: [
                      for (final idx in pieceOrder)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Draggable<int>(
                            data: idx,
                            onDragStarted: () => setState(() => draggingIndex = idx),
                            onDraggableCanceled: (_, __) => setState(() => draggingIndex = null),
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: _PuzzlePiece(
                                  imageProvider: _imageProvider!,
                                  rows: rows,
                                  cols: cols,
                                  row: idx ~/ cols,
                                  col: idx % cols,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: _PuzzlePiece(
                                  imageProvider: _imageProvider!,
                                  rows: rows,
                                  cols: cols,
                                  row: idx ~/ cols,
                                  col: idx % cols,
                                ),
                              ),
                            ),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: _PuzzlePiece(
                                imageProvider: _imageProvider!,
                                rows: rows,
                                cols: cols,
                                row: idx ~/ cols,
                                col: idx % cols,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Puzzle board with guide image
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Use most of the available height for the board
                        final double boardHeight = constraints.maxHeight * 0.92;
                        final double boardWidth = boardHeight * (cols / rows);
                        return AspectRatio(
                          aspectRatio: cols / rows,
                          child: SizedBox(
                            width: boardWidth,
                            height: boardHeight,
                            child: Stack(
                              children: [
                                // Guide image
                                Opacity(
                                  opacity: 0.18,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Image(
                                      image: _imageProvider!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                // Puzzle grid
                                _PuzzleBoardWithTray(
                                  imageProvider: _imageProvider!,
                                  rows: rows,
                                  cols: cols,
                                  boardState: boardState,
                                  draggingIndex: draggingIndex,
                                  onPieceDropped: _onPieceDropped,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
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
  factory _Bubble.random() {
  final rand = math.Random();
    return _Bubble(
      rand.nextDouble(),
      16 + rand.nextDouble() * 24,
      0.2 + rand.nextDouble() * 0.5,
  rand.nextDouble() * 2 * math.pi,
      Colors.primaries[rand.nextInt(Colors.primaries.length)].withOpacity(0.18 + rand.nextDouble() * 0.18),
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
      final paint = Paint()..color = b.color;
      canvas.drawCircle(Offset(x, y), b.radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int row;
  final int col;
  const _PuzzlePiece({required this.imageProvider, required this.rows, required this.cols, required this.row, required this.col});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth;
        final double tileHeight = constraints.maxHeight;
        return Stack(
          children: [
            Positioned(
              left: -col * tileWidth,
              top: -row * tileHeight,
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: tileWidth * cols,
                height: tileHeight * rows,
              ),
            ),
            ClipRect(
              child: Container(
                width: tileWidth,
                height: tileHeight,
                color: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
  }
}

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
  final List<String> levels = ['Easy', 'Medium', 'Hard'];
  late Map<String, List<String>> defaultImages;
  late Map<String, List<String>> userImages;
  late Map<String, Map<String, double>> progress; // level -> image -> percent

  @override
  void initState() {
    super.initState();
    // Placeholder asset paths for default images
    defaultImages = {
      for (var level in levels)
        level: List.generate(5, (i) => 'assets/puzzle/${widget.type.name.toLowerCase()}_${level.toLowerCase()}_$i.png'),
    };
    userImages = { for (var level in levels) level: [] };
    progress = { for (var level in levels) level: {} };
  }

  Future<void> _addImage(String level) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        userImages[level]!.add(picked.path);
        progress[level]![picked.path] = 0.0;
      });
      // Do NOT navigate to gameplay, just stay on this screen
    }
  }

  void _onImageTap(String level, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleScreen(imagePath: imagePath),
      ),
    );
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
            // Circular image with pillow effect
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
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.image, color: Colors.grey[400], size: 40)),
                ),
              ),
            ),
            // Progress ring (optional, can be removed if not needed)
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
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
      ),
    );
  }
}

class _PuzzleBoardWithTray extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final List<int?> boardState;
  final int? draggingIndex;
  final void Function(int boardIdx, int pieceIdx)? onPieceDropped;
  const _PuzzleBoardWithTray({
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.boardState,
    this.draggingIndex,
    this.onPieceDropped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth / cols;
        final double tileHeight = constraints.maxHeight / rows;
        return Stack(
          children: List.generate(rows * cols, (index) {
            final int row = index ~/ cols;
            final int col = index % cols;
            final int? pieceIdx = boardState[index];
            return Positioned(
              left: col * tileWidth,
              top: row * tileHeight,
              child: DragTarget<int>(
                onWillAccept: (data) => pieceIdx == null,
                onAccept: (data) {
                  if (pieceIdx == null && onPieceDropped != null) {
                    onPieceDropped!(index, data);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: tileWidth,
                    height: tileHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: pieceIdx != null
                        ? _PuzzlePiece(
                            imageProvider: imageProvider,
                            rows: rows,
                            cols: cols,
                            row: pieceIdx ~/ cols,
                            col: pieceIdx % cols,
                          )
                        : null,
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}
