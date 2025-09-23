import 'package:flutter/material.dart';
import 'dart:math';
import '../../modules/puzzle/puzzle_module.dart';
import '../../modules/matching/matching_module.dart';
import '../../modules/reading/reading_module.dart';
import '../../modules/writing/writing_module.dart';
import '../../modules/painting/painting_module.dart';
import '../../modules/community_helpers/community_helpers_module.dart';
import '../../modules/planets/planets_module.dart';
import '../../modules/plants/plants_module.dart';
import '../../modules/geography/geography_module.dart';
import '../../modules/parts_of_house/parts_of_house_module.dart';
import '../../modules/vocabulary/vocabulary_module.dart';
import '../../widgets/animated_bubbles_background.dart';
import '../../widgets/animated_bouncy_button.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final features = [
    {'label': 'Puzzle', 'icon': Icons.extension, 'color': Colors.orange},
    {'label': 'Matching', 'icon': Icons.link, 'color': Colors.blue},
    {'label': 'Reading', 'icon': Icons.menu_book, 'color': Colors.green},
    {'label': 'Writing', 'icon': Icons.edit, 'color': Colors.purple},
    {'label': 'Painting', 'icon': Icons.brush, 'color': Colors.pink},
    {'label': 'Community Helpers', 'icon': Icons.people, 'color': Colors.teal},
    {'label': 'Planets', 'icon': Icons.public, 'color': Colors.indigo},
    {
      'label': 'Plants',
      'icon': Icons.local_florist,
      'color': Colors.lightGreen
    },
    {'label': 'Geography', 'icon': Icons.map, 'color': Colors.cyan},
    {'label': 'Parts of the House', 'icon': Icons.home, 'color': Colors.brown},
    {
      'label': 'Vocabulary',
      'icon': Icons.text_fields,
      'color': Colors.deepOrange
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubblesBackground()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Mascot
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'mascot',
                      child: Icon(Icons.emoji_nature,
                          size: 64, color: Colors.orange.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome to InteractKids!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a fun activity:',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, i) {
                      final f = features[i];
                      // Use AnimatedBouncyButton inside the grid cell
                      return Center(
                        child: AnimatedBouncyButton(
                          label: f['label'] as String,
                          icon: f['icon'] as IconData,
                          color: f['color'] as Color,
                          width: 300,
                          height: 110,
                          delay: i * 120,
                          onTap: () {
                            Widget screen;
                            switch (f['label']) {
                              case 'Puzzle':
                                screen = const PuzzleTypeScreen();
                                break;
                              case 'Matching':
                                screen = const MatchingScreen();
                                break;
                              case 'Reading':
                                screen = const ReadingScreen();
                                break;
                              case 'Writing':
                                screen = const WritingScreen();
                                break;
                              case 'Painting':
                                screen = const PaintingScreen();
                                break;
                              case 'Community Helpers':
                                screen = const CommunityHelpersScreen();
                                break;
                              case 'Planets':
                                screen = const PlanetsScreen();
                                break;
                              case 'Plants':
                                screen = const PlantsScreen();
                                break;
                              case 'Geography':
                                screen = const GeographyScreen();
                                break;
                              case 'Parts of the House':
                                screen = const PartsOfHouseScreen();
                                break;
                              case 'Vocabulary':
                                screen = const VocabularyScreen();
                                break;
                              default:
                                screen = const SizedBox();
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => screen),
                            );
                          },
                        ),
                      );
                    },
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

// _AnimatedFeatureCard removed; use AnimatedBouncyButton instead.

class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({super.key});

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(24, (i) => _Bubble.random());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
      Colors.primaries[rand.nextInt(Colors.primaries.length)]
          .withOpacity(0.18 + rand.nextDouble() * 0.18),
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
