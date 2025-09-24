import 'package:flutter/material.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/matching_game_base.dart';
import 'package:interactkids/modules/matching/matching_models.dart';
import 'pictures_mode.dart';

class MatchingPicturesScreen extends StatefulWidget {
  const MatchingPicturesScreen({super.key});
  @override
  State<MatchingPicturesScreen> createState() => _MatchingPicturesScreenState();
}

class _MatchingPicturesScreenState extends State<MatchingPicturesScreen> {
  String _selectedCategory = 'Fruits';

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
    // create id keys so progress can be stored as strings
    return List.generate(
      items.length,
      (i) => MatchingPair(left: '$category-$i', right: '$category-$i'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryWidgets.keys.toList();
    final pairs = _makePairsForCategory(_selectedCategory);
    // build visuals map for ids -> widget
    final visuals = <String, Widget>{};
    final items = _categoryWidgets[_selectedCategory] ?? [];
    for (var i = 0; i < items.length; i++) {
      visuals['$_selectedCategory-$i'] = items[i];
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Match the Pictures', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.green.shade300,
        elevation: 0,
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
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? Colors.green.shade400 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: Center(
                          child: Text(cat, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: MatchingGameBase(
                  mode: MatchingPicturesMode(pairs, visuals),
                  title: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
