// Puzzle module entry
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with SingleTickerProviderStateMixin {
  String selectedTheme = 'Zoo';
  final List<_PuzzleTheme> themes = const [
    _PuzzleTheme('Zoo', Icons.pets, Color(0xFFffb347)),
    _PuzzleTheme('Sea', Icons.waves, Color(0xFF40c4ff)),
    _PuzzleTheme('Jungle', Icons.park, Color(0xFF66bb6a)),
  ];
  final List<String> levels = ['Level 1', 'Level 2', 'Level 3'];
  String? selectedLevel;
  late AnimationController _controller;
  File? _selectedImage;
  final int rows = 2;
  final int cols = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
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
                            selectedLevel = null;
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
                    children: levels.map((level) {
                      final isSelected = selectedLevel == level;
                      return Padding(
                        padding: const EdgeInsets.only(right: 18.0),
                        child: AnimatedScale(
                          scale: isSelected ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton(
                            onPressed: () => setState(() => selectedLevel = level),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.orange : Colors.grey.shade300,
                              foregroundColor: isSelected ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              textStyle: const TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                              elevation: isSelected ? 10 : 2,
                              shadowColor: isSelected ? Colors.orangeAccent : Colors.grey,
                            ),
                            child: Text(level),
                          ),
                        ),
                      );
                    }).toList(),
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
                    ),
                  ),
                const SizedBox(height: 32),
                if (selectedLevel != null)
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final t = _controller.value;
                          final bounce = sin(t * 2 * pi) * 8;
                          return Transform.translate(
                            offset: Offset(0, bounce),
                            child: Container(
                              width: 220,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.orange, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  'Puzzle for $selectedTheme\n$selectedLevel\n(Coming Soon!)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22, fontFamily: 'Nunito', color: Colors.orange),
                                ),
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
    final rand = Random();
    return _Bubble(
      rand.nextDouble(),
      16 + rand.nextDouble() * 24,
      0.2 + rand.nextDouble() * 0.5,
      rand.nextDouble() * 2 * pi,
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
  const _PuzzleBoard({required this.image, required this.rows, required this.cols});

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
            return Positioned(
              left: col * tileWidth,
              top: row * tileHeight,
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
            );
          }),
        );
      },
    );
  }
}
