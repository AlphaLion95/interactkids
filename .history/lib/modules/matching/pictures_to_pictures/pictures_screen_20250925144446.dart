import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'dart:math' as math;
import 'pictures_mode.dart';

// Small decorative widgets used by the pictures screen to create
// non-rectangular, varied visuals (triangles, popsicles, cones, etc.)
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(size.width / 2, 0);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TriangleBadge extends StatelessWidget {
  final Color color;
  final double size;
  final Widget? child;
  const _TriangleBadge(
      {this.color = Colors.orange, this.size = 100, this.child, super.key});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TriangleClipper(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color.withOpacity(0.6)]),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _Popsicle extends StatelessWidget {
  final Color color;
  const _Popsicle({this.color = Colors.pink, super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final stickW = w * 0.18;
      final bodyH = h * 0.75;
      return SizedBox(
        width: w,
        height: h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: w * 0.78,
              height: bodyH,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.icecream, color: Colors.white, size: 20)),
            ),
            SizedBox(height: h * 0.05),
            Container(width: stickW, height: h * 0.14, decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(3))),
          ],
        ),
      );
    });
  }
}

class _IceCreamCone extends StatelessWidget {
  const _IceCreamCone({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final scoopH = h * 0.55;
      return SizedBox(
        width: w,
        height: h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: w * 0.8,
              height: scoopH,
              decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(scoopH / 2)),
              child: const Center(
                  child: Icon(Icons.icecream, color: Colors.white, size: 18)),
            ),
            SizedBox(
              width: w * 0.72,
              height: h - scoopH,
              child: ClipPath(
                clipper: _TriangleClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.brown, Colors.orange])),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PizzaSlice extends StatelessWidget {
  const _PizzaSlice({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final s = math.min(constraints.maxWidth, constraints.maxHeight) * 0.9;
      return Center(
          child: Transform.rotate(
              angle: -0.28,
              child:
                  Icon(Icons.local_pizza, size: s, color: Colors.deepOrange)));
    });
  }
}

class MatchingPicturesScreen extends StatefulWidget {
  const MatchingPicturesScreen({super.key});
  @override
  State<MatchingPicturesScreen> createState() => _MatchingPicturesScreenState();
}

class _MatchingPicturesScreenState extends State<MatchingPicturesScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;
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

  // Widgets grouped by difficulty: easy (large), medium, hard (small)
  // Made non-const so we can use richer, non-const decorated widgets for easy shapes
  static final Map<String, Map<String, List<Widget>>> _categoryWidgets = {
    'Fruits': {
      'easy': [
        const Icon(Icons.apple, size: 100, color: Colors.red),
        const Icon(Icons.local_pizza, size: 100, color: Colors.deepOrange),
        // additional fruit-like visuals for variety: use varied non-rectangular widgets
        const _PizzaSlice(),
        const _IceCreamCone(),
        const _Popsicle(color: Colors.orangeAccent),
        _TriangleBadge(
            color: Colors.pink,
            size: 100,
            child: const Text('�', style: TextStyle(fontSize: 36))),
        CircleAvatar(
            radius: 48,
            backgroundColor: Colors.yellow,
            child: const Text('🍌', style: TextStyle(fontSize: 36))),
      ],
      'medium': [
        Icon(Icons.star, size: 72, color: Colors.yellow),
        Icon(Icons.favorite, size: 72, color: Colors.pink),
      ],
      'hard': [
        Icon(Icons.cake, size: 48, color: Colors.brown),
        Icon(Icons.icecream, size: 48, color: Colors.blueGrey),
      ],
    },
    'Vegetables': {
      'easy': [
        const Icon(Icons.eco, size: 100, color: Colors.greenAccent),
        Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
                child: Text('🥕', style: TextStyle(fontSize: 36)))),
        const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.green,
            child: Text('🥦', style: TextStyle(fontSize: 36))),
      ],
      'medium': [Icon(Icons.grass, size: 72, color: Colors.green)],
      'hard': [Icon(Icons.spa, size: 48, color: Colors.lightGreen)],
    },
    'Colors': {
      'easy': [
        const ColoredBox(
            color: Colors.red, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.orange, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.yellow, child: SizedBox(width: 100, height: 100)),
        const ColoredBox(
            color: Colors.green, child: SizedBox(width: 100, height: 100)),
      ],
      'medium': [
        ColoredBox(color: Colors.green, child: SizedBox(width: 72, height: 72))
      ],
      'hard': [
        ColoredBox(color: Colors.blue, child: SizedBox(width: 48, height: 48)),
        ColoredBox(color: Colors.yellow, child: SizedBox(width: 48, height: 48))
      ],
    },
    'Shapes': {
      'easy': [
        // Solid indigo circle (responsive)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle)));
        }),
        // Solid rounded square
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(s * 0.12))));
        }),
        // Solid triangle badge
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.9;
          return Center(child: ClipPath(clipper: _TriangleClipper(), child: Container(width: s, height: s, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange])))));
        }),
        // Solid star (icon-shaped)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.75;
          return Center(child: Icon(Icons.star, size: s, color: Colors.amber));
        }),
        // Solid pink circle
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle)));
        }),
        // Teal rounded box
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(s * 0.12), border: Border.all(color: Colors.teal.shade700, width: s * 0.04))));
        }),
        // Diamond (rotated square)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.75;
          return Center(child: Transform.rotate(angle: 0.785398, child: Container(width: s, height: s, color: Colors.blueAccent)));
        }),
        // Gradient rounded square
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]), borderRadius: BorderRadius.circular(s * 0.12))));
        }),
        // Ringed circle (solid center)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.85;
          return Center(child: Container(width: s, height: s, decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: s * 0.07))));
        }),
        // Hexagon-like solid shape (rotated rounded rect)
        LayoutBuilder(builder: (ctx, c) {
          final s = math.min(c.maxWidth, c.maxHeight) * 0.78;
          return Center(child: Transform.rotate(angle: 0.26, child: Container(width: s, height: s * 0.72, decoration: BoxDecoration(color: Colors.lime, borderRadius: BorderRadius.circular(s * 0.12)))));
        }),
      ],
      'medium': [Icon(Icons.square_foot, size: 72, color: Colors.brown)],
      'hard': [
        Icon(Icons.change_history, size: 48, color: Colors.pink),
        Icon(Icons.crop_square, size: 48, color: Colors.cyan)
      ],
    },
  };

  List<MatchingPair> _makePairsForCategory(String category) {
    final groups = _categoryWidgets[category] ?? {};
    final items = <String>[];
    for (final entry in groups.entries) {
      final difficulty = entry.key;
      if (_selectedDifficulty != null &&
          _selectedDifficulty != 'all' &&
          difficulty != _selectedDifficulty) continue;
      for (var i = 0; i < entry.value.length; i++) {
        items.add('$category-$difficulty-$i');
      }
    }
    return items.map((id) => MatchingPair(left: id, right: id)).toList();
  }

  String _displayLabel(String key) {
    // Use the raw category name as the display label (no swapping).
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryWidgets.keys.toList();
    final pairs = _selectedCategory == null
        ? <MatchingPair>[]
        : _makePairsForCategory(_selectedCategory!);
    final visuals = <String, Widget>{};
    final groups = _selectedCategory == null
        ? {}
        : _categoryWidgets[_selectedCategory!] ?? {};
    groups.forEach((difficulty, widgets) {
      if (_selectedDifficulty != null &&
          _selectedDifficulty != 'all' &&
          difficulty != _selectedDifficulty) return;
      for (var i = 0; i < widgets.length; i++) {
        final id = '$_selectedCategory-$difficulty-$i';
        Widget w = widgets[i];
        if (difficulty == 'easy') {
          w = SizedBox(width: 120, height: 120, child: Center(child: w));
        } else if (difficulty == 'medium') {
          w = SizedBox(width: 90, height: 90, child: Center(child: w));
        } else {
          w = SizedBox(width: 64, height: 64, child: Center(child: w));
        }
        visuals[id] = w;
      }
    });

    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: AppBar(
          leading: _selectedCategory != null
              ? BackButton(
                  onPressed: () => setState(() {
                        _selectedCategory = null;
                        _selectedDifficulty = null;
                      }))
              : null,
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
            if (_selectedCategory == null)
              Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: categories.map((cat) {
                    return GestureDetector(
                      onTap: () {
                        if (_selectedCategory == cat) return;
                        setState(() {
                          _selectedCategory = cat;
                          // Immediately enter gameplay and default to easy
                          _selectedDifficulty = 'easy';
                        });
                        // Reset game after the mode is mounted so progressKey is correct
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _gameKey.currentState?.resetGame();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 12)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category,
                                size: 48, color: Colors.green.shade400),
                            const SizedBox(height: 8),
                            Text(_displayLabel(cat),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              SizedBox.expand(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Top-level difficulty selector: small buttons placed at the very top
                    if (_selectedDifficulty == null)
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children:
                                ['easy', 'medium', 'hard', 'all'].map((level) {
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedDifficulty = level;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: _selectedDifficulty == level
                                        ? Colors.green.shade400
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 12)
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(level.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedDifficulty == level
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: SizedBox(
                          height: 56,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['easy', 'medium', 'hard', 'all']
                                  .map((level) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_selectedDifficulty == level)
                                              return;
                                            setState(() {
                                              _selectedDifficulty = level;
                                            });
                                            // Reset the game after the frame so the new
                                            // MatchingPicturesMode (with updated progressKey)
                                            // is mounted and resetGame removes the correct key.
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              _gameKey.currentState
                                                  ?.resetGame();
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            constraints: const BoxConstraints(
                                              minWidth: 72,
                                              maxWidth: 140,
                                            ),
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedDifficulty == level
                                                      ? Colors.green.shade400
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: const [
                                                BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 8)
                                              ],
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Center(
                                                child: Text(level.toUpperCase(),
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            _selectedDifficulty ==
                                                                    level
                                                                ? Colors.white
                                                                : Colors
                                                                    .black)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: MatchingGameBase(
                        key: _gameKey,
                        mode: MatchingPicturesMode(
                          pairs,
                          visuals,
                          // let mode suggest size by difficulty
                          _selectedDifficulty == 'easy'
                              ? 140.0
                              : _selectedDifficulty == 'medium'
                                  ? 96.0
                                  : 64.0,
                          // unique progress key per category and difficulty so toggling doesn't wipe visuals
                          '${_selectedCategory}_${_selectedDifficulty ?? 'all'}',
                        ),
                        title: '',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
