import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'pictures_mode.dart';

class MatchingPicturesScreen extends StatefulWidget {
  const MatchingPicturesScreen({super.key});
  @override
  State<MatchingPicturesScreen> createState() => _MatchingPicturesScreenState();
}

class _MatchingPicturesScreenState extends State<MatchingPicturesScreen> {
  String _selectedCategory = 'Fruits';
  final GlobalKey<MatchingGameBaseState> _gameKey =
      GlobalKey<MatchingGameBaseState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  static final Map<String, List<Widget>> _categoryWidgets = {
    'Fruits': [
      SizedBox(
          width: 120,
          height: 120,
          child:
              Center(child: Icon(Icons.apple, size: 100, color: Colors.red))),
      SizedBox(
          width: 120,
          height: 120,
          child: Center(
              child:
                  Icon(Icons.brightness_1, size: 100, color: Colors.orange))),
      SizedBox(
          width: 120,
          height: 120,
          child: Center(
              child: Icon(Icons.circle, size: 100, color: Colors.purple))),
      SizedBox(
          width: 120,
          height: 120,
          child:
              Center(child: Icon(Icons.star, size: 100, color: Colors.yellow))),
      SizedBox(
          width: 120,
          height: 120,
          child: Center(
              child: Icon(Icons.favorite, size: 100, color: Colors.pink))),
      SizedBox(
          width: 120,
          height: 120,
          child: Center(
              child: Icon(Icons.local_pizza,
                  size: 100, color: Colors.deepOrange))),
      SizedBox(
          width: 120,
          height: 120,
          child:
              Center(child: Icon(Icons.cake, size: 100, color: Colors.brown))),
      SizedBox(
          width: 120,
          height: 120,
          child: Center(
              child: Icon(Icons.icecream, size: 100, color: Colors.blueGrey))),
    ],
    'Vegetables': [
      Icon(Icons.grass, size: 60, color: Colors.green),
      Icon(Icons.eco, size: 60, color: Colors.greenAccent),
      Icon(Icons.local_florist, size: 60, color: Colors.teal),
      Icon(Icons.spa, size: 60, color: Colors.lightGreen),
    ],
    'Colors': [
      ColoredBox(color: Colors.red, child: SizedBox(width: 60, height: 60)),
      ColoredBox(color: Colors.green, child: SizedBox(width: 60, height: 60)),
      ColoredBox(color: Colors.blue, child: SizedBox(width: 60, height: 60)),
      ColoredBox(color: Colors.yellow, child: SizedBox(width: 60, height: 60)),
    ],
    'Shapes': [
      // Regular polygons and fun shapes
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 3, color: Colors.deepPurple))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 4, color: Colors.indigo))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 5, color: Colors.pink))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 6, color: Colors.teal))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 7, color: Colors.orange))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 8, color: Colors.blue))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 9, color: Colors.green))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 10, color: Colors.brown))),
      SizedBox(width: 60, height: 60, child: Center(child: RegularPolygon(sides: 12, color: Colors.cyan))),
      // fun icons
      SizedBox(width: 60, height: 60, child: Center(child: Icon(Icons.local_pizza, size: 48, color: Colors.deepOrange))),
      SizedBox(width: 60, height: 60, child: Center(child: Icon(Icons.icecream, size: 48, color: Colors.pinkAccent))),
    ],
  };

// Draw a regular polygon with given number of sides.
class RegularPolygon extends StatelessWidget {
  final int sides;
  final Color color;
  final double strokeWidth;
  const RegularPolygon({super.key, required this.sides, required this.color, this.strokeWidth = 2.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: _RegularPolygonPainter(sides: sides, color: color, strokeWidth: strokeWidth),
    );
  }
}

class _RegularPolygonPainter extends CustomPainter {
  final int sides;
  final Color color;
  final double strokeWidth;
  _RegularPolygonPainter({required this.sides, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - strokeWidth;
    final path = Path();
    if (sides < 3) {
      canvas.drawCircle(Offset(cx, cy), radius, paint);
      canvas.drawCircle(Offset(cx, cy), radius, stroke);
      return;
    }
    for (var i = 0; i < sides; i++) {
      final theta = (i / sides) * 2 * Math.pi - Math.pi / 2;
      final x = cx + radius * Math.cos(theta);
      final y = cy + radius * Math.sin(theta);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

  List<MatchingPair> _makePairsForCategory(String category) {
    final items = _categoryWidgets[category] ?? [];
    return List.generate(
      items.length,
      (i) => MatchingPair(left: '$category-$i', right: '$category-$i'),
    );
  }

  String _displayLabel(String key) {
    if (key == 'Fruits') return 'Shapes';
    if (key == 'Shapes') return 'Fruits';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryWidgets.keys.toList();
    final pairs = _makePairsForCategory(_selectedCategory);
    final visuals = <String, Widget>{};
    final items = _categoryWidgets[_selectedCategory] ?? [];
    for (var i = 0; i < items.length; i++) {
      visuals['$_selectedCategory-$i'] = items[i];
    }
    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: AppBar(
          title: const Text('Match the Pictures',
              style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: Colors.green.shade300,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Undo last match',
              icon: const Icon(Icons.undo),
              onPressed: () async {
                final messenger = ScaffoldMessenger.maybeOf(context);
                final undone = await _gameKey.currentState?.undoLastMatch();
                if (!mounted) return;
                if (undone == true) {
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Undid last match')));
                } else {
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Nothing to undo')));
                }
              },
            ),
            IconButton(
              tooltip: 'Clear current stroke',
              icon: const Icon(Icons.brush),
              onPressed: () {
                _gameKey.currentState?.clearStroke();
              },
            ),
            IconButton(
              tooltip: 'Reset progress',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final messenger = ScaffoldMessenger.maybeOf(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset progress?'),
                    content: const Text(
                        'This will clear your progress for this game mode.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (!mounted) return;
                if (confirmed == true) {
                  await _gameKey.currentState?.resetGame();
                  if (!mounted) return;
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Progress reset')));
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBubblesBackground()),
            Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.green.shade400 : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _displayLabel(cat),
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: MatchingGameBase(
                    key: _gameKey,
                    mode: MatchingPicturesMode(pairs, visuals),
                    title: '',
                  ),
                ),
              ],
            ),
            // duplicate floating reset removed; AppBar already provides reset
          ],
        ),
      ),
    );
  }
}
