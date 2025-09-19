import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// ======================
///  PUZZLE GAME SCREEN
/// ======================
class PuzzleScreen extends StatefulWidget {
  final String? imagePath;
  final int rows;
  final int cols;

  const PuzzleScreen({
    super.key,
    this.imagePath,
    this.rows = 3,
    this.cols = 3,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with SingleTickerProviderStateMixin {
  late ImageProvider _imageProvider;
  late List<int?> boardState;
  late List<int> pieceOrder;
  int? draggingIndex;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = widget.imagePath != null
        ? FileImage(File(widget.imagePath!))
        : const AssetImage('assets/default_puzzle.png');

    pieceOrder = List.generate(widget.rows * widget.cols, (i) => i)..shuffle();
    boardState = List.filled(widget.rows * widget.cols, null);
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
      builder: (_) => AlertDialog(
        title: const Text("🎉 You Win!"),
        content: const Text("Congratulations, you solved the puzzle!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _resetPuzzle() {
    setState(() {
      pieceOrder.shuffle();
      boardState = List.filled(widget.rows * widget.cols, null);
      draggingIndex = null;
      hasWon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: _imageProvider,
            fit: BoxFit.cover,
            color: Colors.white.withOpacity(0.3),
            colorBlendMode: BlendMode.lighten,
          ),
          const AnimatedBubbles(),
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: _PuzzleBoardWithTray(
                    rows: widget.rows,
                    cols: widget.cols,
                    imageProvider: _imageProvider,
                    pieceOrder: pieceOrder,
                    boardState: boardState,
                    draggingIndex: draggingIndex,
                    onPiecePlaced: (index, piece) {
                      setState(() {
                        boardState[index] = piece;
                        draggingIndex = null;
                        if (_isSolved()) {
                          hasWon = true;
                          _showWinDialog();
                        }
                      });
                    },
                    onDragStarted: (piece) {
                      setState(() {
                        draggingIndex = piece;
                      });
                    },
                    onDragEnded: () {
                      setState(() {
                        draggingIndex = null;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _resetPuzzle,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Puzzle"),
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

/// ======================
///  BACKGROUND BUBBLES
/// ======================
class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({super.key});

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _bubbles = List.generate(20, (index) => _Bubble.random());
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
        for (final b in _bubbles) {
          b.update();
        }
        return CustomPaint(
          painter: _BubblePainter(_bubbles),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Bubble object
class _Bubble {
  double x;
  double y;
  double radius;
  double speed;
  Paint paint;

  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.paint,
  });

  factory _Bubble.random() {
    final random = Random();
    return _Bubble(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: 10 + random.nextDouble() * 20,
      speed: 0.001 + random.nextDouble() * 0.003,
      paint: Paint()
        ..color = Colors.white.withOpacity(0.2 + random.nextDouble() * 0.3),
    );
  }

  void update() {
    y -= speed;
    if (y < -0.1) {
      y = 1.1;
    }
  }
}

/// Painter for bubbles
class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;

  _BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final offset = Offset(b.x * size.width, b.y * size.height);
      canvas.drawCircle(offset, b.radius, b.paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ======================
///  PUZZLE TYPE SCREEN
/// ======================
class PuzzleTypeScreen extends StatelessWidget {
  const PuzzleTypeScreen({super.key});

  void _onCategoryTap(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleLevelScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Zoo', 'Sea', 'Jungle', 'Flying'];
    return Scaffold(
      appBar: AppBar(title: const Text("Select Puzzle Category")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: categories
            .map(
              (c) => GestureDetector(
                onTap: () => _onCategoryTap(context, c),
                child: Card(
                  child: Center(
                    child: Text(c,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// ======================
///  PUZZLE LEVEL SCREEN
/// ======================
class PuzzleLevelScreen extends StatefulWidget {
  final String category;

  const PuzzleLevelScreen({super.key, required this.category});

  @override
  State<PuzzleLevelScreen> createState() => _PuzzleLevelScreenState();
}

class _PuzzleLevelScreenState extends State<PuzzleLevelScreen> {
  final List<String> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCustomImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _images.add(picked.path);
      });
    }
  }

  void _onImageTap(String level, String imagePath) {
    int rows = level == 'Easy' ? 3 : level == 'Medium' ? 4 : 5;
    int cols = rows;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PuzzleScreen(imagePath: imagePath, rows: rows, cols: cols),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['Easy', 'Medium', 'Hard'];
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category} Puzzles")),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              children: [
                for (final level in levels)
                  for (final img in _images)
                    GestureDetector(
                      onTap: () => _onImageTap(level, img),
                      child: _PuzzleImageTile(imagePath: img, level: level),
                    ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _pickCustomImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text("Add Custom Image"),
          ),
        ],
      ),
    );
  }
}

class _PuzzleImageTile extends StatelessWidget {
  final String imagePath;
  final String level;

  const _PuzzleImageTile({
    required this.imagePath,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: ClipOval(
              child: imagePath.startsWith('assets/')
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : Image.file(File(imagePath), fit: BoxFit.cover),
            ),
          ),
          Text(level),
        ],
      ),
    );
  }
}

/// ======================
///  PUZZLE BOARD + PIECES
/// ======================
class _PuzzleBoardWithTray extends StatelessWidget {
  final int rows;
  final int cols;
  final ImageProvider imageProvider;
  final List<int> pieceOrder;
  final List<int?> boardState;
  final int? draggingIndex;
  final Function(int index, int piece) onPiecePlaced;
  final Function(int piece) onDragStarted;
  final VoidCallback onDragEnded;

  const _PuzzleBoardWithTray({
    required this.rows,
    required this.cols,
    required this.imageProvider,
    required this.pieceOrder,
    required this.boardState,
    required this.draggingIndex,
    required this.onPiecePlaced,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.8;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
            ),
            itemCount: rows * cols,
            itemBuilder: (context, index) {
              final piece = boardState[index];
              return DragTarget<int>(
                onAccept: (data) => onPiecePlaced(index, data),
                builder: (context, candidate, rejected) {
                  return Container(
                    margin: const EdgeInsets.all(1),
                    color: Colors.grey.shade300,
                    child: piece != null
                        ? _PuzzlePiece(
                            imageProvider: imageProvider,
                            rows: rows,
                            cols: cols,
                            index: piece,
                          )
                        : const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: pieceOrder
              .where((p) => !boardState.contains(p))
              .map(
                (piece) => Draggable<int>(
                  data: piece,
                  feedback: SizedBox(
                    width: 60,
                    height: 60,
                    child: _PuzzlePiece(
                      imageProvider: imageProvider,
                      rows: rows,
                      cols: cols,
                      index: piece,
                    ),
                  ),
                  childWhenDragging: const SizedBox(width: 60, height: 60),
                  onDragStarted: () => onDragStarted(piece),
                  onDraggableCanceled: (_, __) => onDragEnded(),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: _PuzzlePiece(
                      imageProvider: imageProvider,
                      rows: rows,
                      cols: cols,
                      index: piece,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int index;

  const _PuzzlePiece({
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: FractionalOffset(
          (index % cols) / (cols - 1),
          (index ~/ cols) / (rows - 1),
        ),
        widthFactor: 1 / cols,
        heightFactor: 1 / rows,
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
