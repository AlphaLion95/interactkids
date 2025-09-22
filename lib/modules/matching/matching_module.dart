import 'dart:math';
import 'package:flutter/material.dart';
import 'matching_game_base.dart';
import 'matching_models.dart';

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
    ];
    final icons = [
      Icons.text_fields,
      Icons.image,
      Icons.link,
      Icons.compare_arrows,
    ];
    final labels = [
      'Matching Letters',
      'Matching Pictures',
      'Words to Pictures',
      'Words to Words',
    ];
    final onTaps = [
      () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MatchingLettersScreen()),
          ),
      () {}, // TODO: MatchingPicturesScreen
      () {}, // TODO: MatchingWordsToPicturesScreen
      () {}, // TODO: MatchingWordsToWordsScreen
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Select Matching Game Type',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated floating bubbles background
          const Positioned.fill(child: _AnimatedMatchingBubbles()),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    _AnimatedMatchingTypeButton(
                      label: labels[i],
                      icon: icons[i],
                      color: colors[i],
                      onTap: onTaps[i],
                      delay: i * 200,
                    ),
                    const SizedBox(height: 36),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMatchingTypeButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  const _AnimatedMatchingTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });
  @override
  State<_AnimatedMatchingTypeButton> createState() =>
      _AnimatedMatchingTypeButtonState();
}

class _AnimatedMatchingTypeButtonState
    extends State<_AnimatedMatchingTypeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
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
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.translate(
            offset: Offset(
                0,
                -_floatAnim.value *
                    sin(DateTime.now().millisecondsSinceEpoch / 600 +
                        widget.delay)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 320,
          height: 110,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Icon(widget.icon, size: 38, color: widget.color),
              ),
              const SizedBox(width: 28),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMatchingBubbles extends StatefulWidget {
  const _AnimatedMatchingBubbles();
  @override
  State<_AnimatedMatchingBubbles> createState() =>
      _AnimatedMatchingBubblesState();
}

class _AnimatedMatchingBubblesState extends State<_AnimatedMatchingBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  final _bubbleCount = 18;
  late List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _bubbles = List.generate(_bubbleCount, (i) => _Bubble(_random));
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
  late double x, y, radius, speed, phase;
  late Color color;
  _Bubble(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    radius = 28 + random.nextDouble() * 32;
    speed = 0.12 + random.nextDouble() * 0.18;
    phase = random.nextDouble() * 2 * pi;
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.pink.shade100,
      Colors.cyan.shade100,
    ];
    color = colors[random.nextInt(colors.length)];
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double t;
  _BubblesPainter(this.bubbles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final dx = b.x * size.width + 24 * sin(t * 2 * pi * b.speed + b.phase);
      final dy =
          (b.y + 0.12 * sin(t * 2 * pi * b.speed + b.phase)) * size.height;
      final paint = Paint()
        ..color = b.color.withOpacity(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dx, dy), b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MatchingLettersScreen extends StatelessWidget {
  const MatchingLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate all alphabet pairs: A-a, B-b, ..., Z-z
    final pairs = List.generate(26, (i) {
      final upper = String.fromCharCode(65 + i); // 'A'..'Z'
      final lower = String.fromCharCode(97 + i); // 'a'..'z'
      return MatchingPair(left: upper, right: lower);
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Match the Letters',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedMatchingBubbles()),
          MatchingGameBase(
            mode: MatchingLettersMode(pairs),
            title: '',
          ),
        ],
      ),
    );
  }
}
