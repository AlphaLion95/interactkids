import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// confetti and haptic are used inside the drag area; keep this file minimal
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/modules/matching/pictures_to_pictures/pictures_match_area.dart';
import 'package:interactkids/modules/matching/letters_to_letters/letters_mode.dart';
import 'package:interactkids/widgets/celebration_overlay.dart';
import 'package:interactkids/widgets/bouncing_button.dart';

/// Shared matching UI used by letters and pictures modes.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;

  final String title;

  /// When false the matched-pairs tray at the top is hidden (used by pictures mode).
  final bool showMatchedTray;

  const MatchingGameBase(
      {required this.mode,
      required this.title,
      this.showMatchedTray = true,
      super.key});

  @override
  State<MatchingGameBase> createState() => MatchingGameBaseState();
}

class MatchingGameBaseState extends State<MatchingGameBase> {
  List<dynamic> leftItems = [];
  List<dynamic> rightItems = [];
  Map<dynamic, dynamic> matches = {};
  final List<MapEntry<dynamic, dynamic>> _matchHistory = [];
  dynamic selectedLeft;
  dynamic selectedRight;
  bool completed = false;
  bool _showCelebration = false;

  final GlobalKey _dragAreaKey = GlobalKey();
  final ValueNotifier<bool> _isDrawingNotifier = ValueNotifier<bool>(false);
  late final ScrollController _leftScrollController;
  late final ScrollController _rightScrollController;

  String get _progressKey => widget.mode.progressKey;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _leftScrollController = ScrollController();
    _rightScrollController = ScrollController();
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _isDrawingNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MatchingGameBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the game mode changed (letters <-> numbers etc), reload progress and
    // reset transient state so modes remain independent.
    if (oldWidget.mode.runtimeType != widget.mode.runtimeType ||
        oldWidget.mode.progressKey != widget.mode.progressKey) {
      _matchHistory.clear();
      selectedLeft = null;
      selectedRight = null;
      matches.clear();
      completed = false;
      _showCelebration = false;
      // Reload the stored progress for the newly selected mode (or empty sets).
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_progressKey);
    final allPairs = widget.mode.pairs;
    matches = {};
    // Build left and right lists. Some modes (letters/numbers) prefer the
    // left column to stay in a stable, sorted order while the right column
    // is randomized for matching. Respect mode.shuffleLeft to decide.
    leftItems = allPairs.map((p) => p.left).toList();
    rightItems = allPairs.map((p) => p.right).toList();
    if (widget.mode.shuffleLeft) {
      leftItems.shuffle();
    } else {
      // ensure deterministic ordering for left side. If items look numeric,
      // sort numerically; otherwise fall back to string compare.
      try {
        bool allNumeric =
            leftItems.every((v) => int.tryParse(v.toString()) != null);
        if (allNumeric) {
          leftItems.sort((a, b) =>
              int.parse(a.toString()).compareTo(int.parse(b.toString())));
        } else {
          leftItems.sort((a, b) => a.toString().compareTo(b.toString()));
        }
      } catch (_) {}
    }
    // Right side should usually be randomized so the child items are mixed.
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

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final flat = matches.entries.map((e) => '${e.key}=${e.value}').toList();
    await prefs.setStringList(_progressKey, flat);
  }

  void _onLeftTap(dynamic item) {
    setState(() {
      selectedLeft = item;
      if (selectedRight != null) _tryMatch();
    });
  }

  void _onRightTap(dynamic item) {
    setState(() {
      selectedRight = item;
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
      _matchHistory.add(MapEntry(selectedLeft, selectedRight));
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
    setState(() {});
  }

  Future<void> _resetGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    // Clear transient state and reload lists according to mode settings.
    _matchHistory.clear();
    selectedLeft = null;
    selectedRight = null;
    matches.clear();
    completed = false;
    _showCelebration = false;
    await _loadProgress();
  }

  /// Public API used by external screens to reset progress.
  Future<void> resetGame() async => await _resetGame();

  Future<bool> undoLastMatch() async {
    if (_matchHistory.isEmpty) return false;
    final last = _matchHistory.removeLast();
    final left = last.key;
    final right = last.value;
    matches.remove(left);
    leftItems.add(left);
    rightItems.add(right);
    // Respect mode ordering: if left should not be shuffled, keep it
    // in sorted order; otherwise shuffle to mix it back in.
    if (widget.mode.shuffleLeft) {
      leftItems.shuffle();
    } else {
      try {
        leftItems.sort((a, b) => a.toString().compareTo(b.toString()));
      } catch (_) {}
    }
    rightItems.shuffle();
    completed = false;
    _showCelebration = false;
    await _saveProgress();
    setState(() {});
    return true;
  }

  void clearStroke() {
    final dynamic areaState = _dragAreaKey.currentState;
    try {
      if (areaState != null && areaState.clearStroke != null) {
        areaState.clearStroke();
      }
    } catch (_) {}
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
              if (widget.showMatchedTray)
                _MatchedTray(
                    matches: matches, mode: widget.mode, onReset: _resetGame),
              if (widget.showMatchedTray) const SizedBox(height: 12),
              Expanded(
                child: completed
                    ? const Center(
                        child: Text('Great job! All pairs matched!',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(builder: (context, constraints) {
                          if (widget.mode.supportsDragMatch) {
                            return DragMatchArea(
                              key: _dragAreaKey,
                              leftItems: leftItems,
                              rightItems: rightItems,
                              buildLeft: (item) =>
                                  widget.mode.buildLeftItem(context, item),
                              buildRight: (item) =>
                                  widget.mode.buildRightItem(context, item),
                              isDrawingNotifier: _isDrawingNotifier,
                              onProposeMatch: (l, r) async {
                                try {
                                  final ok = widget.mode.pairs
                                      .any((p) => p.left == l && p.right == r);
                                  if (ok) {
                                    if (mounted) {
                                      setState(() {
                                        matches[l] = r;
                                        leftItems.remove(l);
                                        rightItems.remove(r);
                                        _saveProgress();
                                        if (leftItems.isEmpty &&
                                            rightItems.isEmpty) {
                                          completed = true;
                                          _showCelebration = true;
                                        }
                                      });
                                    }
                                  }
                                  return Future.value(ok);
                                } catch (e, st) {
                                  debugPrint(
                                      'Exception in onProposeMatch handler: $e\n$st');
                                  return Future.value(false);
                                }
                              },
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _isDrawingNotifier,
                                  builder: (context, isDrawing, child) {
                                    return ListView(
                                      controller: _leftScrollController,
                                      primary: false,
                                      physics: isDrawing
                                          ? const NeverScrollableScrollPhysics()
                                          : null,
                                      children: [
                                        for (final item in leftItems)
                                          GestureDetector(
                                            onTap: () => _onLeftTap(item),
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                // Always keep border transparent to avoid
                                                // the orange focus ring when tapped.
                                                border: Border.all(
                                                  color: Colors.transparent,
                                                  width: 3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: selectedLeft == item
                                                  ? AnimatedBouncingButton(
                                                      width: 90,
                                                      height: 90,
                                                      child: widget.mode
                                                          .buildLeftItem(
                                                              context, item),
                                                    )
                                                  : widget.mode.buildLeftItem(
                                                      context, item),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 32),
                              SizedBox(
                                width: 120,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _isDrawingNotifier,
                                  builder: (context, isDrawing, child) {
                                    return ListView(
                                      controller: _rightScrollController,
                                      primary: false,
                                      physics: isDrawing
                                          ? const NeverScrollableScrollPhysics()
                                          : null,
                                      children: [
                                        for (final item in rightItems)
                                          GestureDetector(
                                            onTap: () => _onRightTap(item),
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                // Keep border transparent to avoid
                                                // orange focus ring on tap.
                                                border: Border.all(
                                                  color: Colors.transparent,
                                                  width: 3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: selectedRight == item
                                                  ? AnimatedBouncingButton(
                                                      width: 90,
                                                      height: 90,
                                                      child: widget.mode
                                                          .buildRightItem(
                                                              context, item),
                                                    )
                                                  : widget.mode.buildRightItem(
                                                      context, item),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
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
    // If the current mode is the Letters mode, keep the previous letters
    // style: a small green rounded pill showing the concatenated left+right
    // (e.g., 'Aa'). This avoids changing letters UI while still handling
    // numeric matches specially below.
    if (mode is MatchingLettersMode) {
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
                color: Colors.green.withAlpha(26),
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
    }

    // If both sides are identical numeric strings (e.g., '1' & '1'), show
    // the single number instead of concatenating them which would render '11'.
    if (left is String && right is String) {
      final leftStr = left as String;
      final rightStr = right as String;
      final bothNumeric =
          int.tryParse(leftStr) != null && int.tryParse(rightStr) != null;
      if (bothNumeric && leftStr == rightStr) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(26),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                leftStr,
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
    }
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
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(33),
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
                            fontFamily: 'Nunito')),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final left = matches.keys.elementAt(i);
                      final right = matches[left];
                      return _MatchedPairDisplay(
                          left: left, right: right, mode: mode);
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
                        color: Colors.blue.withAlpha(46),
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
