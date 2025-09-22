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
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.amber.shade400,
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
        title: const Text('Select Matching Game Type', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated background bubbles
          const Positioned.fill(child: _AnimatedBubblesBG()),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonSize = min(constraints.maxWidth, constraints.maxHeight) / 2.2;
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 32,
                  children: List.generate(4, (i) => _AnimatedGameTypeButton(
                    label: labels[i],
                    icon: icons[i],
                    color: colors[i % colors.length],
                    size: buttonSize,
                    onTap: onTaps[i],
                  )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGameTypeButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _AnimatedGameTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });
  @override
  State<_AnimatedGameTypeButton> createState() => _AnimatedGameTypeButtonState();
}

class _AnimatedGameTypeButtonState extends State<_AnimatedGameTypeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color.withOpacity(0.95), widget.color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: widget.size * 0.38, color: Colors.white),
                    const SizedBox(height: 18),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.size * 0.13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Gamified sparkle
              const Positioned(
                top: 18,
                right: 18,
                child: _AnimatedSparkle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSparkle extends StatefulWidget {
  const _AnimatedSparkle();
  @override
  State<_AnimatedSparkle> createState() => _AnimatedSparkleState();
}
class _AnimatedSparkleState extends State<_AnimatedSparkle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: Icon(Icons.auto_awesome, color: Colors.yellow.shade200, size: 32),
        );
      },
    );
  }
}

class _AnimatedBubblesBG extends StatelessWidget {
  const _AnimatedBubblesBG();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(12, (i) => _BubbleAnim(i)),
    );
  }
}

class _BubbleAnim extends StatefulWidget {
  final int index;
  const _BubbleAnim(this.index);
  @override
  State<_BubbleAnim> createState() => _BubbleAnimState();
}
class _BubbleAnimState extends State<_BubbleAnim> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  late double left, size, duration, delay;
  @override
  void initState() {
    super.initState();
    final rand = Random(widget.index);
    left = rand.nextDouble() * 0.9;
    size = 40 + rand.nextDouble() * 60;
    duration = 8 + rand.nextDouble() * 6;
    delay = rand.nextDouble() * 3;
    _controller = AnimationController(vsync: this, duration: Duration(seconds: duration.toInt()))
      ..forward(from: delay / duration);
    _anim = Tween<double>(begin: 1.2, end: -0.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.forward(from: 0);
      }
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
      animation: _anim,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: MediaQuery.of(context).size.height * _anim.value,
          child: Opacity(
            opacity: 0.18,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.primaries[widget.index % Colors.primaries.length].withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MatchingLettersScreen extends StatelessWidget {
  const MatchingLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example pairs: A-A, B-B, C-C
    final pairs = [
      MatchingPair(left: 'A', right: 'A'),
      MatchingPair(left: 'B', right: 'B'),
      MatchingPair(left: 'C', right: 'C'),
      MatchingPair(left: 'D', right: 'D'),
    ];
    return MatchingGameBase(
      mode: MatchingLettersMode(pairs),
      title: 'Match the Letters',
    );
  }
}
