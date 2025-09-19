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
  String selectedTheme = 'Zoo';
  final List<_PuzzleTheme> themes = const [
    _PuzzleTheme('Zoo', Icons.pets, Color(0xFFffb347)),
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
  ];
  File? _selectedImage;
  final int rows = 2;
  final int cols = 3;
  late List<int> pieceOrder;
  int? draggingIndex;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
    if (widget.imagePath != null) {
      _selectedImage = File(widget.imagePath!);
    }
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _shufflePieces() {
    setState(() {
      pieceOrder.shuffle();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
      });
    }
  }

  void _onPieceDropped(int from, int to) {
    setState(() {
      final temp = pieceOrder[from];
      pieceOrder[from] = pieceOrder[to];
      pieceOrder[to] = temp;
      draggingIndex = null;
      if (_isSolved()) {
        hasWon = true;
        _showWinDialog();
      }
    });
  }

  bool _isSolved() {
    for (int i = 0; i < pieceOrder.length; i++) {
      if (pieceOrder[i] != i) return false;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'mascot',
                      child: Icon(Icons.emoji_nature, size: 56, color: Colors.orange.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Puzzle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: Colors.orange.shade700)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Choose a Theme:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: themes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 24),
                    itemBuilder: (context, i) {
                      final t = themes[i];
                      final isSelected = selectedTheme == t.name;
                      return AnimatedScale(
                        scale: isSelected ? 1.13 : 1.0,
                        duration: const Duration(milliseconds: 350),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            selectedTheme = t.name;
                            _selectedImage = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSelected ? t.color : t.color.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: t.color.withOpacity(0.4),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                              ],
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(t.icon, size: 48, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(t.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text('Select Level:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // For demo, just set rows and cols
                            // In real app, you might want to show a level selection screen
                            _selectedImage != null ? null : _pickImage();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                        ),
                        child: const Text('Level 1'),
                      ),
                      const SizedBox(width: 18),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // For demo, just set rows and cols
                            // In real app, you might want to show a level selection screen
                            _selectedImage != null ? null : _pickImage();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                        ),
                        child: const Text('Level 2'),
                      ),
                      const SizedBox(width: 18),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // For demo, just set rows and cols
                            // In real app, you might want to show a level selection screen
                            _selectedImage != null ? null : _pickImage();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                        ),
                        child: const Text('Level 3'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Image for Puzzle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: _shufflePieces,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle Pieces'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_selectedImage != null)
                  Container(
                    width: 220,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: _PuzzleBoard(
                      image: _selectedImage!,
                      rows: rows,
                      cols: cols,
                      pieceOrder: pieceOrder,
                      draggingIndex: draggingIndex,
                      onDragStarted: (i) => setState(() => draggingIndex = i),
                      onDragEnded: () => setState(() => draggingIndex = null),
                      onPieceDropped: _onPieceDropped,
                    ),
                  ),
                const SizedBox(height: 32),
                if (_selectedImage != null)
                  Container(
                    width: 220,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: _PuzzleBoard(
                      image: _selectedImage!,
                      rows: rows,
                      cols: cols,
                      pieceOrder: pieceOrder,
                      draggingIndex: draggingIndex,
                      onDragStarted: (i) => setState(() => draggingIndex = i),
                      onDragEnded: () => setState(() => draggingIndex = null),
                      onPieceDropped: _onPieceDropped,
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

class _PuzzleBoard extends StatelessWidget {
  final File image;
  final int rows;
  final int cols;
  final List<int> pieceOrder;
  final int? draggingIndex;
  final void Function(int)? onDragStarted;
  final void Function()? onDragEnded;
  final void Function(int, int)? onPieceDropped;

  const _PuzzleBoard({
    required this.image,
    required this.rows,
    required this.cols,
    required this.pieceOrder,
    this.draggingIndex,
    this.onDragStarted,
    this.onDragEnded,
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
            final int pieceIndex = pieceOrder[index];
            return Positioned(
              left: col * tileWidth,
              top: row * tileHeight,
              child: Draggable<int>(
                data: pieceIndex,
                onDragStarted: () => onDragStarted?.call(pieceIndex),
                onDraggableCanceled: (_, __) => onDragEnded?.call(),
                childWhenDragging: Container(
                  width: tileWidth,
                  height: tileHeight,
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: tileWidth,
                    height: tileHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                        alignment: FractionalOffset(col / (cols - 1), row / (rows - 1)),
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                child: DragTarget<int>(
                  onAcceptWithDetails: (details) {
                    final from = details.data;
                    if (from != pieceIndex) {
                      onPieceDropped?.call(from, pieceIndex);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: tileWidth,
                      height: tileHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                          alignment: FractionalOffset(col / (cols - 1), row / (rows - 1)),
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
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
      // Immediately go to gameplay with the new image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PuzzleScreen(imagePath: picked.path),
        ),
      );
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
