import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/widgets/celebration_overlay.dart';

/// Base widget for any matching game type.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;
  final String title;
  const MatchingGameBase({required this.mode, required this.title, super.key});

  @override
  @override
  State<MatchingGameBase> createState() => MatchingGameBaseState();
}

class MatchingGameBaseState extends State<MatchingGameBase> with TickerProviderStateMixin {
  late List<dynamic> leftItems;
  late List<dynamic> rightItems;
  late Map<dynamic, dynamic> matches; // left -> right
  dynamic selectedLeft;
  dynamic selectedRight;
  bool completed = false;
  bool _showCelebration = false;
  // transient tap pulse states for non-drag tap-list UI
  final Map<dynamic, bool> _tapPulse = {};

  // controllers for animations
  late final AnimationController _pulseController;
  late final Animation<double> _bounceAnim;
  late final AnimationController _selectedLoopController;
  late final Animation<double> _selectedLoopAnim;
  // pulse item is tracked in _tapPulse map; no standalone field needed

  // Use the progress key provided by the active mode so different game types
  // do not share the same persisted progress store.
  String get _progressKey => widget.mode.progressKey;

  // drag/draw support (used by modes that enable drag-to-match)
  final GlobalKey _dragAreaKey = GlobalKey();
  late final ValueNotifier<bool> _isDrawingNotifier;

  @override
  void initState() {
    super.initState();
    // pulse controller: one-shot damped bounce
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -36.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -36.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
    ]).animate(_pulseController);
    _pulseController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (s == AnimationStatus.dismissed) {
        // clear any pulse markers once animation completes
        setState(() { _tapPulse.clear(); });
      }
    });

    // selected-loop controller: gentle up/down repeat while selected
    _selectedLoopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _selectedLoopAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_selectedLoopController);

    _isDrawingNotifier = ValueNotifier<bool>(false);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(_progressKey);
    final allPairs = widget.mode.pairs;
    matches = {};
    leftItems = allPairs.map((p) => p.left).toList();
    rightItems = allPairs.map((p) => p.right).toList();
    leftItems.shuffle();
    rightItems.shuffle();
    if (saved != null) {
      for (final entry in saved) {
        final parts = entry.split('=');
        if (parts.length == 2) {
          final left = parts[0];
          final right = parts[1];
          matches[left] = right;
          leftItems.remove(left);
          rightItems.remove(right);
        }
      }
    }
    completed = leftItems.isEmpty && rightItems.isEmpty;
    _showCelebration = completed;
    setState(() {});
  }

  @override
  void dispose() {
    try { _pulseController.dispose(); } catch (_) {}
    try { _selectedLoopController.dispose(); } catch (_) {}
    try { _isDrawingNotifier.dispose(); } catch (_) {}
    super.dispose();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
  final flat = matches.entries.map((e) => '${e.key}=${e.value}').toList();
  await prefs.setStringList(_progressKey, flat);
  }

  void _onLeftTap(dynamic item) {
    // play pulse then select/toggle and start continuous loop when selected
    setState(() {
      _tapPulse[item] = true;
    });
    _pulseController.forward(from: 0.0);
    final keepMs = (_pulseController.duration?.inMilliseconds ?? 900) + 200;
    Future.delayed(Duration(milliseconds: keepMs), () {
      if (!mounted) return;
      setState(() { _tapPulse[item] = false; });
    });

    setState(() {
      if (selectedLeft == item) {
        selectedLeft = null;
        try { _selectedLoopController.stop(); } catch (_) {}
      } else {
        selectedLeft = item;
        try { _selectedLoopController.repeat(reverse: true); } catch (_) {}
      }
      if (selectedRight != null) _tryMatch();
    });
  }

  void _onRightTap(dynamic item) {
    setState(() {
      _tapPulse[item] = true;
    });
    _pulseController.forward(from: 0.0);
    final keepMs = (_pulseController.duration?.inMilliseconds ?? 900) + 200;
    Future.delayed(Duration(milliseconds: keepMs), () {
      if (!mounted) return;
      setState(() { _tapPulse[item] = false; });
    });

    setState(() {
      if (selectedRight == item) {
        selectedRight = null;
        try { _selectedLoopController.stop(); } catch (_) {}
      } else {
        selectedRight = item;
        try { _selectedLoopController.repeat(reverse: true); } catch (_) {}
      }
      if (selectedLeft != null) _tryMatch();
    });
  }

  void _tryMatch() {
    final pair = widget.mode.pairs.firstWhere(
      (p) => p.left == selectedLeft && p.right == selectedRight,
      orElse: () => MatchingPair(left: null, right: null),
    );
    if (pair.left != null) {
      matches[selectedLeft] = selectedRight;
      leftItems.remove(selectedLeft);
      rightItems.remove(selectedRight);
      _saveProgress();
      if (leftItems.isEmpty && rightItems.isEmpty) {
        completed = true;
        _showCelebration = true;
      }
    }
    selectedLeft = null;
    selectedRight = null;
    try { _selectedLoopController.stop(); } catch (_) {}
    setState(() {});
  }

  void _resetGame() async {
    final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_progressKey);
    setState(() {
      leftItems = widget.mode.pairs.map((p) => p.left).toList();
      rightItems = widget.mode.pairs.map((p) => p.right).toList();
      leftItems.shuffle();
      rightItems.shuffle();
      matches.clear();
      completed = false;
      _showCelebration = false;
      selectedLeft = null;
      selectedRight = null;
    });
  }

  // Public API used by other screens via GlobalKey<MatchingGameBaseState>
  Future<void> resetGame() async {
    _resetGame();
    return Future.value();
  }

  /// Undo the most recent match if any. Returns true if something was undone.
  Future<bool> undoLastMatch() async {
    if (matches.isEmpty) return false;
    // Maps preserve insertion order; remove the last inserted match
    final lastKey = matches.keys.last;
    final lastValue = matches.remove(lastKey);
    // return matched items to the pools
    leftItems.add(lastKey);
    rightItems.add(lastValue);
    // shuffle to avoid always returning to same position
    leftItems.shuffle();
    rightItems.shuffle();
    await _saveProgress();
    setState(() {});
    return true;
  }

  /// Some matching modes allow drawing a stroke for drag-match; expose a
  /// no-op here so callers can clear stroke without knowing internals.
  void clearStroke() {
    final areaState = _dragAreaKey.currentState;
    if (areaState is _DragMatchAreaState) {
      areaState.clearStroke();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: widget.title.isNotEmpty
              ? AppBar(title: Text(widget.title))
              : null,
          body: Column(
            children: [
              const SizedBox(height: 12),
              _MatchedTray(
                  matches: matches, mode: widget.mode, onReset: _resetGame),
              const SizedBox(height: 12),
              Expanded(
                child: completed
                    ? Center(
                        child: Text('Great job! All pairs matched!',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Scrollbar(
                                thumbVisibility: true,
                                        child: ListView(
                                      children: [
                                        for (final item in leftItems)
                                          GestureDetector(
                                            onTap: () => _onLeftTap(item),
                                            child: AnimatedBuilder(
                                              animation: Listenable.merge([
                                                _pulseController,
                                                _selectedLoopController
                                              ]),
                                              builder: (_, __) {
                                                final isSelected = selectedLeft == item;
                                                final isPulsed = _tapPulse[item] == true;
                                                final translateY = isSelected
                                                    ? _selectedLoopAnim.value
                                                    : (isPulsed ? _bounceAnim.value : 0.0);
                                                final scale = isPulsed ? 1.06 : 1.0;
                                                return Transform.translate(
                                                  offset: Offset(0, translateY),
                                                  child: Transform.scale(
                                                    scale: scale,
                                                    child: Container(
                                                      margin: const EdgeInsets.symmetric(
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? Colors.orange
                                                              : Colors.transparent,
                                                          width: 3,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: isSelected || isPulsed
                                                            ? [
                                                                BoxShadow(
                                                                  color: Colors.orange.withOpacity(0.14),
                                                                  blurRadius: 10,
                                                                  offset: const Offset(0, 6),
                                                                )
                                                              ]
                                                            : null,
                                                      ),
                                                      child: widget.mode.buildLeftItem(context, item),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            SizedBox(
                              width: 120,
                              child: Scrollbar(
                                thumbVisibility: true,
                                    child: ListView(
                                  children: [
                                    for (final item in rightItems)
                                      GestureDetector(
                                        onTap: () => _onRightTap(item),
                                        child: AnimatedBuilder(
                                          animation: Listenable.merge([
                                            _pulseController,
                                            _selectedLoopController
                                          ]),
                                          builder: (_, __) {
                                            final isSelected = selectedRight == item;
                                            final isPulsed = _tapPulse[item] == true;
                                            final translateY = isSelected
                                                ? _selectedLoopAnim.value
                                                : (isPulsed ? _bounceAnim.value : 0.0);
                                            final scale = isPulsed ? 1.06 : 1.0;
                                            return Transform.translate(
                                              offset: Offset(0, translateY),
                                              child: Transform.scale(
                                                scale: scale,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(
                                                      vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Colors.orange
                                                          : Colors.transparent,
                                                      width: 3,
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: isSelected || isPulsed
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors.orange.withOpacity(0.14),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 6),
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                  child: widget.mode.buildRightItem(context, item),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (_showCelebration)
          CelebrationOverlay(
            show: true,
            onComplete: () {
              setState(() {
                _showCelebration = false;
              });
            },
          ),
      ],
    );
  }
}

class _MatchedPairDisplay extends StatelessWidget {
  final dynamic left;
  final dynamic right;
  final MatchingGameMode mode;
  const _MatchedPairDisplay(
      {required this.left, required this.right, required this.mode});
  @override
  Widget build(BuildContext context) {
    // For MatchingLettersMode, show compact Aa, Bb, etc.
    if (left is String &&
        right is String &&
        left.length == 1 &&
        right.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              left + right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      );
    }
    // Fallback for other modes
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mode.buildLeftItem(context, left),
        const SizedBox(width: 8),
        const Icon(Icons.check_circle, color: Colors.green, size: 28),
        const SizedBox(width: 8),
        mode.buildRightItem(context, right),
      ],
    );
  }
}

class _MatchedTray extends StatelessWidget {
  final Map<dynamic, dynamic> matches;
  final MatchingGameMode mode;
  final VoidCallback? onReset;
  const _MatchedTray({required this.matches, required this.mode, this.onReset});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.13),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text('Matched Pairs will appear here!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          fontFamily: 'Nunito',
                        )),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final left = matches.keys.elementAt(i);
                      final right = matches[left];
                      return _MatchedPairDisplay(
                        left: left,
                        right: right,
                        mode: mode,
                      );
                    },
                  ),
          ),
          if (onReset != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: onReset,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.refresh, color: Colors.blue, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}