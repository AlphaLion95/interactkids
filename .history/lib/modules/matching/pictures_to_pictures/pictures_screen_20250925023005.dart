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

  static const Map<String, List<Widget>> _categoryWidgets = {
    'Fruits': [
      Icon(Icons.apple, size: 60, color: Colors.red),
      Icon(Icons.brightness_1, size: 60, color: Colors.orange),
      Icon(Icons.circle, size: 60, color: Colors.purple),
      Icon(Icons.star, size: 60, color: Colors.yellow),
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
      Icon(Icons.circle, size: 60, color: Colors.indigo),
      Icon(Icons.square_foot, size: 60, color: Colors.brown),
      Icon(Icons.change_history, size: 60, color: Colors.pink),
      Icon(Icons.crop_square, size: 60, color: Colors.cyan),
    ],
  };

  List<MatchingPair> _makePairsForCategory(String category) {
    final items = _categoryWidgets[category] ?? [];
    return List.generate(
      items.length,
      (i) => MatchingPair(left: '$category-$i', right: '$category-$i'),
    );
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
              tooltip: 'Reset progress',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              cat,
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
            // A floating reset button overlay so the action is available even
            // if the AppBar is hidden or obscured.
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'pictures-reset',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                  onPressed: () async {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Progress reset')));
                    }
                  },
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
