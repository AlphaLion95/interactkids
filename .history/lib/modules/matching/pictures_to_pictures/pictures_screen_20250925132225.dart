import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static Map<String, Map<String, List<Widget>>> _categoryWidgets = {
    'Fruits': {
      'easy': [
        Icon(Icons.apple, size: 100, color: Colors.red),
        Icon(Icons.local_pizza, size: 100, color: Colors.deepOrange),
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
      'easy': [Icon(Icons.eco, size: 100, color: Colors.greenAccent)],
      'medium': [Icon(Icons.grass, size: 72, color: Colors.green)],
      'hard': [Icon(Icons.spa, size: 48, color: Colors.lightGreen)],
    },
    'Colors': {
      'easy': [
        ColoredBox(color: Colors.red, child: SizedBox(width: 100, height: 100))
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
        Icon(Icons.circle, size: 100, color: Colors.indigo),
        Icon(Icons.crop_square, size: 100, color: Colors.deepPurple),
        Icon(Icons.change_history, size: 100, color: Colors.orange),
        Icon(Icons.star, size: 100, color: Colors.amber),
        Icon(Icons.favorite, size: 100, color: Colors.pink),
        // simple styled square/diamond via container
        Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.teal, borderRadius: BorderRadius.circular(8))),
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
    if (key == 'Fruits') return 'Shapes';
    if (key == 'Shapes') return 'Fruits';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryWidgets.keys.toList();
    final pairs = _selectedCategory == null
        ? <MatchingPair>[]
        : _makePairsForCategory(_selectedCategory!);
    final visuals = <String, Widget>{};
    final mq = MediaQuery.of(context).size;
    final double screenMin = mq.shortestSide;
    // If Shapes + easy, show near-fullscreen tiles (screen shortest side minus padding)
    final double shapesEasyFullSize = (screenMin - 48).clamp(64.0, 800.0);
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
        double tileSize;
        if (_selectedCategory == 'Shapes' && difficulty == 'easy') {
          tileSize = shapesEasyFullSize;
        } else if (difficulty == 'easy') {
          tileSize = 120.0;
        } else if (difficulty == 'medium') {
          tileSize = 90.0;
        } else {
          tileSize = 64.0;
        }
        w = SizedBox(width: tileSize, height: tileSize, child: Center(child: w));
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
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        // Immediately enter gameplay and default to easy
                        _selectedDifficulty = 'easy';
                      }),
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
                    const SizedBox(height: 12),
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
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          // Small difficulty selector on top of gameplay
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                            // Reset the game when difficulty changes
                                            _gameKey.currentState?.resetGame();
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 100,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _selectedDifficulty ==
                                                      level
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
                                            child: Center(
                                              child: Text(level.toUpperCase(),
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _selectedDifficulty ==
                                                              level
                                                          ? Colors.white
                                                          : Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: MatchingGameBase(
                              key: _gameKey,
                              mode: MatchingPicturesMode(
                                  pairs,
                                  visuals,
                                  // choose preferred size consistent with visuals
                                  (_selectedCategory == 'Shapes' &&
                                          _selectedDifficulty == 'easy')
                                      ? shapesEasyFullSize
                                      : _selectedDifficulty == 'medium'
                                          ? 90
                                          : _selectedDifficulty == 'hard'
                                              ? 64
                                              : 120),
                              title: '',
                            ),
                          ),
                        ],
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
