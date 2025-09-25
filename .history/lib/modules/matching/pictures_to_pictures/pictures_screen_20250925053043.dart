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

  // Widgets grouped by difficulty: easy (large), medium, hard (small)
  static const Map<String, Map<String, List<Widget>>> _categoryWidgets = {
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
      'easy': [ColoredBox(color: Colors.red, child: SizedBox(width: 100, height: 100))],
      'medium': [ColoredBox(color: Colors.green, child: SizedBox(width: 72, height: 72))],
      'hard': [ColoredBox(color: Colors.blue, child: SizedBox(width: 48, height: 48)), ColoredBox(color: Colors.yellow, child: SizedBox(width: 48, height: 48))],
    },
    'Shapes': {
      'easy': [Icon(Icons.circle, size: 100, color: Colors.indigo)],
      'medium': [Icon(Icons.square_foot, size: 72, color: Colors.brown)],
      'hard': [Icon(Icons.change_history, size: 48, color: Colors.pink), Icon(Icons.crop_square, size: 48, color: Colors.cyan)],
    },
  };

  List<MatchingPair> _makePairsForCategory(String category) {
    final groups = _categoryWidgets[category] ?? {};
    final items = <String>[];
    for (final entry in groups.entries) {
      final difficulty = entry.key;
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
    final pairs = _makePairsForCategory(_selectedCategory);
    final visuals = <String, Widget>{};
    final groups = _categoryWidgets[_selectedCategory] ?? {};
    groups.forEach((difficulty, widgets) {
      for (var i = 0; i < widgets.length; i++) {
        final id = '$_selectedCategory-$difficulty-$i';
        // wrap in fixed-size container according to difficulty
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
