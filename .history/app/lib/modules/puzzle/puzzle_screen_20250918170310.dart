import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../core/models.dart';
import '../../core/animated_bubbles.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    pieceOrder = List.generate(rows * cols, (i) => i)..shuffle();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated playful background
          Positioned.fill(child: AnimatedBubbles()),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Mascot (placeholder)
          Positioned(
            top: 40,
            right: 24,
            child: Hero(
              tag: 'mascot',
              child: Icon(Icons.emoji_nature, size: 64, color: Colors.orange.shade700),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 32),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 8),
                      const Text('Puzzle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: themes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 24),
                    itemBuilder: (context, i) {
                      final t = themes[i];
                      final isSelected = selectedTheme == t.name;
                      return AnimatedScale(
                        scale: isSelected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTheme = t.name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.extension, size: 80, color: Colors.orange.shade400),
                        const SizedBox(height: 24),
                        Text(
                          'Let\'s solve a $selectedTheme puzzle!\n(Puzzle board coming soon)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontFamily: 'Nunito', color: Colors.black87),
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
                        // Placeholder for future puzzle board
                        Container(
                          width: 220,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.orange, width: 3),
                          ),
                          child: _selectedImage != null
                              ? _PuzzleBoard(
                                  image: _selectedImage!,
                                  rows: rows,
                                  cols: cols,
                                  pieceOrder: pieceOrder,
                                  draggingIndex: draggingIndex,
                                  onDragStarted: (i) => setState(() => draggingIndex = i),
                                  onDragEnded: () => setState(() => draggingIndex = null),
                                  onPieceDropped: (from, to) {
                                    setState(() {
                                      final temp = pieceOrder[from];
                                      pieceOrder[from] = pieceOrder[to];
                                      pieceOrder[to] = temp;
                                      draggingIndex = null;
                                    });
                                  },
                                )
                              : const Center(
                                  child: Text('Puzzle Board Area', style: TextStyle(fontSize: 18, fontFamily: 'Nunito', color: Colors.orange)),
                                ),
                        ),
                      ],
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

class _PuzzleBoard extends StatelessWidget {
  final File image;
  final int rows;
  final int cols;
  final List<int> pieceOrder;
  final int? draggingIndex;
  final ValueChanged<int> onDragStarted;
  final VoidCallback onDragEnded;
  final Function(int from, int to) onPieceDropped;

  const _PuzzleBoard({
    required this.image,
    required this.rows,
    required this.cols,
    required this.pieceOrder,
    this.draggingIndex,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onPieceDropped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileWidth = constraints.maxWidth / cols;
        final double tileHeight = constraints.maxHeight / rows;
        return Stack(
          children: List.generate(rows * cols, (index) {
            final int currentRow = index ~/ cols;
            final int currentCol = index % cols;
            final int pieceIndex = pieceOrder[index];
            final double left = tileWidth * (pieceIndex % cols);
            final double top = tileHeight * (pieceIndex ~/ cols);
            return Positioned(
              left: left,
              top: top,
              child: Draggable<int>(
                data: index,
                onDragStarted: () => onDragStarted(index),
                onDraggableCanceled: (_, __) => onDragEnded(),
                child: _buildTile(image, pieceIndex, tileWidth, tileHeight),
                feedback: _buildTile(image, pieceIndex, tileWidth, tileHeight, isFeedback: true),
                childWhenDragging: Container(
                  width: tileWidth,
                  height: tileHeight,
                  color: Colors.transparent,
                ),
              );
            },
          )),
        );
      },
    );
  }

  Widget _buildTile(File image, int index, double width, double height, {bool isFeedback = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
          alignment: FractionalOffset(
            (index % cols) / cols,
            (index ~/ cols) / rows,
          ),
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
    );
  }
}
