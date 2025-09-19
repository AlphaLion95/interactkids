import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'core/voice_audio.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  await Hive.openBox('settings');
  runApp(const InteractKidsApp());
}

class InteractKidsApp extends StatelessWidget {
  const InteractKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InteractKids',
      home: FutureBuilder(
        future: Hive.box('settings').get('voice'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == null) {
            return const VoiceSelectionScreen();
          }
          return MainMenu();
        },
      ),
    );
  }
}

class MainMenu extends StatelessWidget {
  final List<_MenuItem> menuItems = const [
    _MenuItem('Puzzle', Icons.extension, 'PuzzleModule', Colors.orange),
    _MenuItem('Matching', Icons.link, 'MatchingModule', Colors.blue),
    _MenuItem('Reading', Icons.menu_book, 'ReadingModule', Colors.green),
    _MenuItem('Writing', Icons.edit, 'WritingModule', Colors.purple),
    _MenuItem('Painting', Icons.brush, 'PaintingModule', Colors.pink),
    _MenuItem('Community Helpers', Icons.people, 'CommunityHelpersModule', Colors.teal),
    _MenuItem('Planets', Icons.public, 'PlanetsModule', Colors.indigo),
    _MenuItem('Plants', Icons.local_florist, 'PlantsModule', Colors.lightGreen),
    _MenuItem('Geography', Icons.map, 'GeographyModule', Colors.cyan),
    _MenuItem('Parts of House', Icons.home, 'PartsOfHouseModule', Colors.brown),
    _MenuItem('Vocabulary', Icons.text_fields, 'VocabularyModule', Colors.red),
  ];

  MainMenu({super.key});

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
          // Mascot character (custom image)
          Positioned(
            top: 40,
            right: 24,
            child: Hero(
              tag: 'mascot',
              child: Image.asset(
                'assets/images/mascot.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Animated grid of feature cards
          Center(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _AnimatedFeatureCard(item: item, delay: index * 100);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatefulWidget {
  final _MenuItem item;
  final int delay;
  const _AnimatedFeatureCard({required this.item, required this.delay});

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: widget.delay), () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _onTapCard(BuildContext context) async {
    setState(() => _showConfetti = true);
    await _sfxPlayer.setAsset('assets/audio/sfx/card_tap.mp3');
    _sfxPlayer.play();
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _showConfetti = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ModuleScreen(title: widget.item.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: () => _onTapCard(context),
            child: Card(
              color: widget.item.color.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 12,
              shadowColor: widget.item.color.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.item.icon, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showConfetti) ConfettiBurst(color: widget.item.color),
      ],
    );
  }
}

class ConfettiBurst extends StatelessWidget {
  final Color color;
  const ConfettiBurst({required this.color});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size(120, 120),
        painter: _ConfettiPainter(color),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Color color;
  _ConfettiPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.8);
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 3.14159 * 2;
      final radius = 40 + 20 * (i % 2);
      final dx = size.width / 2 + radius * math.cos(angle);
      final dy = size.height / 2 + radius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 8, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  const _MenuItem(this.title, this.icon, this.route, this.color);
}

class _ModuleScreen extends StatelessWidget {
  final String title;
  const _ModuleScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to $title!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                VoiceAudioPlayer().play('welcome.mp3');
              },
              child: const Text('Play Welcome Voice'),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceSelectionScreen extends StatefulWidget {
  const VoiceSelectionScreen({super.key});

  @override
  State<VoiceSelectionScreen> createState() => _VoiceSelectionScreenState();
}

class _VoiceOption {
  final String name;
  final String desc;
  final String key;
  final String image;
  const _VoiceOption(this.name, this.desc, this.key, this.image);
}

class _VoiceSelectionScreenState extends State<VoiceSelectionScreen> with SingleTickerProviderStateMixin {
  String? selectedVoice;
  final List<_VoiceOption> voices = const [
    _VoiceOption('Brycen', 'Boy voice (Crocodile)', 'brycen', 'assets/images/characters/brycen.png'),
    _VoiceOption('Yliana', 'Girl voice (Panda)', 'yliana', 'assets/images/characters/yliana.png'),
    _VoiceOption('Kaida', 'Baby voice (Dog)', 'kaida', 'assets/images/characters/kaida.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Playful gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFDEB71), Color(0xFFF8D800), Color(0xFFF1C40F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Animated bubbles
          Positioned.fill(child: AnimatedBubbles()),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Choose Your Voice', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: voices.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 24),
                    itemBuilder: (context, i) {
                      final v = voices[i];
                      final isSelected = selectedVoice == v.key;
                      return AnimatedScale(
                        scale: isSelected ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedVoice = v.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white70,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.5),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                              ],
                              border: Border.all(
                                color: isSelected ? Colors.orange : Colors.transparent,
                                width: 4,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: v.key,
                                  child: Image.asset(v.image, width: 90, height: 90),
                                ),
                                const SizedBox(height: 12),
                                Text(v.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                                Text(v.desc, style: const TextStyle(fontSize: 14, fontFamily: 'Nunito')),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 20, fontFamily: 'Nunito'),
                  ),
                  onPressed: selectedVoice == null
                      ? null
                      : () async {
                          await Hive.box('settings').put('voice', selectedVoice);
                          // Play welcome audio for selected voice
                          await VoiceAudioPlayer().play('welcome.mp3');
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => MainMenu()),
                            );
                          }
                        },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBubbles extends StatefulWidget {
  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
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
          painter: _BubblesPainter(_controller.value),
        );
      },
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double progress;
  _BubblesPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.15);
    for (int i = 0; i < 12; i++) {
      final dx = (size.width / 12) * i + 20 * (progress + i) % 1;
      final dy = size.height * ((progress + i * 0.08) % 1);
      canvas.drawCircle(Offset(dx, dy), 18 + 8 * (i % 3), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
