import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/widgets/celebration_overlay.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

/// Base widget for any matching game type.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;
  final String title;
  const MatchingGameBase({required this.mode, required this.title, super.key});

  @override
  State<MatchingGameBase> createState() => MatchingGameBaseState();
}

class MatchingGameBaseState extends State<MatchingGameBase> {
  List<dynamic> leftItems = [];
  List<dynamic> rightItems = [];
  Map<dynamic, dynamic> matches = {}; // left -> right
  // history stack for undo support: list of (left,right)
  final List<MapEntry<dynamic, dynamic>> _matchHistory = [];
  dynamic selectedLeft;
  dynamic selectedRight;
  bool completed = false;
  bool _showCelebration = false;
  // key to access the drag area state to clear strokes
  final GlobalKey _dragAreaKey = GlobalKey();

  // Use the progress key provided by the active mode so different game types
  // do not share the same persisted progress store.
  String get _progressKey => widget.mode.progressKey;

  @override
  void initState() {
    super.initState();
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

  /// Public wrapper so parent widgets can trigger a reset via a GlobalKey.
  Future<void> resetGame() async {
    await _resetGame();
  }

  /// Undo the last match, if any.
  Future<bool> undoLastMatch() async {
    if (_matchHistory.isEmpty) return false;
    final last = _matchHistory.removeLast();
    final left = last.key;
    final right = last.value;
    // restore
    matches.remove(left);
    leftItems.add(left);
    rightItems.add(right);
    leftItems.shuffle();
    rightItems.shuffle();
    completed = false;
    _showCelebration = false;
    await _saveProgress();
    setState(() {});
    return true;
  }

  /// Clear the current stroke lines from the drag area.
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
              // Only show the matched tray when the current mode wants it
              if (widget.mode.showMatchedTray)
                _MatchedTray(
                    matches: matches, mode: widget.mode, onReset: _resetGame),
              if (widget.mode.showMatchedTray) const SizedBox(height: 12),
              Expanded(
                child: completed
                    ? Center(
                        child: Text('Great job! All pairs matched!',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(builder: (context, constraints) {
                          if (widget.mode.supportsDragMatch) {
                            return _DragMatchArea(
                              key: const ValueKey('drag-match-area'),
                              leftItems: leftItems,
                              rightItems: rightItems,
                              buildLeft: (item) =>
                                  widget.mode.buildLeftItem(context, item),
                              buildRight: (item) =>
                                  widget.mode.buildRightItem(context, item),
                              onProposeMatch: (l, r) async {
                                // Validate against the canonical pairs
                                final pair = widget.mode.pairs.firstWhere(
                                  (p) => p.left == l && p.right == r,
                                  orElse: () =>
                                      MatchingPair(left: null, right: null),
                                );
                                if (pair.left != null) {
                                  // play small animation then remove
                                  setState(() {});
                                  await Future.delayed(
                                      const Duration(milliseconds: 220));
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
                                  return true;
                                }
                                return false;
                              },
                            );
                          }

                          // Default tap-to-select UI
                          return Row(
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
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: selectedLeft == item
                                                    ? Colors.orange
                                                    : Colors.transparent,
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: widget.mode
                                                .buildLeftItem(context, item),
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
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: selectedRight == item
                                                    ? Colors.orange
                                                    : Colors.transparent,
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: widget.mode
                                                .buildRightItem(context, item),
                                          ),
                                        ),
                                    ],
                                  ),
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

typedef _BuildItem = Widget Function(dynamic item);

class _TimedPoint {
  final Offset point;
  final int timeMs;
  _TimedPoint(this.point, this.timeMs);
}

class _DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;

  /// Called when the user attempts a match (drag finishes or both tapped).
  /// Should return a Future<bool> indicating whether the match is valid.
  final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;
  const _DragMatchArea(
      {required Key key,
      required this.leftItems,
      required this.rightItems,
      required this.buildLeft,
      required this.buildRight,
      required this.onProposeMatch})
      : super(key: key);
  @override
  State<_DragMatchArea> createState() => _DragMatchAreaState();
}

class _DragMatchAreaState extends State<_DragMatchArea>
    with SingleTickerProviderStateMixin {
  List<_TimedPoint> _points = [];
  bool _draggingFromLeft = true;
  dynamic _hoverTarget;
  dynamic _lastHoverTarget;
  late AnimationController _fadeController;
  double _fadeProgress = 0.0;
  late ConfettiController _confettiController;
  Offset? _confettiPosition;

  final Map<dynamic, GlobalKey> _leftKeys = {};
  final Map<dynamic, GlobalKey> _rightKeys = {};
  final Map<dynamic, bool> _animating = {};
  dynamic _selectedLeft;
  dynamic _selectedRight;

  @override
  void initState() {
    super.initState();
    for (final l in widget.leftItems) {
      _leftKeys[l] = GlobalKey();
    }
    for (final r in widget.rightItems) {
      _rightKeys[r] = GlobalKey();
    }
    _lastHoverTarget = null;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        setState(() {
          _fadeProgress = _fadeController.value;
        });
      });
    _fadeController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _points = [];
          _fadeProgress = 0.0;
        });
      }
    });
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void didUpdateWidget(covariant _DragMatchArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final l in widget.leftItems) {
      _leftKeys.putIfAbsent(l, () => GlobalKey());
    }
    for (final r in widget.rightItems) {
      _rightKeys.putIfAbsent(r, () => GlobalKey());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Offset? _centerOfKey(GlobalKey? key) {
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Offset? _toLocal(Offset? global) {
    if (global == null) return null;
    final rootBox = context.findRenderObject() as RenderBox?;
    if (rootBox == null || !rootBox.hasSize) return null;
    return rootBox.globalToLocal(global);
  }

  void _handlePanStart(Offset globalPos) {
    setState(() {
      _points = [];
      final p = _toLocal(globalPos);
      if (p != null)
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      _hoverTarget = null;
      // Guess initial side from x coordinate
      final width = (context.findRenderObject() as RenderBox?)?.size.width ??
          MediaQuery.of(context).size.width;
      _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
    });
  }

  /// Clear any current stroke immediately.
  void clearStroke() {
    _fadeController.stop();
    setState(() {
      _points = [];
      _fadeProgress = 0.0;
    });
  }

  void _handlePanUpdate(Offset globalPos) {
    setState(() {
      final p = _toLocal(globalPos);
      if (p != null)
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));

      // update hover target depending on last point
      // increase hover threshold to be more forgiving for non-horizontal strokes
      final threshold = 40.0;
      _hoverTarget = null;
      if (_points.isEmpty) return;
      final last = _points.last;
      if (_draggingFromLeft) {
        for (final entry in _rightKeys.entries) {
          final centerLocal = _toLocal(_centerOfKey(entry.value));
          if (centerLocal == null) continue;
          if ((centerLocal - last.point).distance <= threshold) {
            _hoverTarget = entry.key;
            break;
          }
        }
      } else {
        for (final entry in _leftKeys.entries) {
          final centerLocal = _toLocal(_centerOfKey(entry.value));
          if (centerLocal == null) continue;
          if ((centerLocal - last.point).distance <= threshold) {
            _hoverTarget = entry.key;
            break;
          }
        }
      }
      // Play light haptic when hover target changes
      if (_hoverTarget != _lastHoverTarget) {
        if (_hoverTarget != null) {
          try {
            HapticFeedback.lightImpact();
          } catch (_) {}
        }
        _lastHoverTarget = _hoverTarget;
      }
    });
  }

  void _handlePanEnd() {
    if (_points.isEmpty) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }
    // Enforce minimum stroke length (by distance) to avoid accidental short scribbles
    // Use a distance threshold instead of point count so short vertical strokes count.
    double totalDist = 0.0;
    for (var i = 1; i < _points.length; i++) {
      totalDist += (_points[i].point - _points[i - 1].point).distance;
    }
    const minStrokeDistance = 20.0;
    if (totalDist < minStrokeDistance) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }
    // Find the first occurrence in the stroke where the path is near any
    // left or right item center. Then if both sides are hit, check order.
  // increase proximity threshold to make vertical and diagonal strokes more forgiving
  final threshold = 48.0;
    int? firstLeftIndex;
    int? firstRightIndex;
    dynamic firstLeftKey;
    dynamic firstRightKey;

    for (var i = 0; i < _points.length; i++) {
      final pt = _points[i].point;
      // check lefts
      for (final entry in _leftKeys.entries) {
        final c = _toLocal(_centerOfKey(entry.value));
        if (c == null) continue;
        if ((c - pt).distance <= threshold) {
          if (firstLeftIndex == null) {
            firstLeftIndex = i;
            firstLeftKey = entry.key;
          }
        }
      }
      // check rights
      for (final entry in _rightKeys.entries) {
        final c = _toLocal(_centerOfKey(entry.value));
        if (c == null) continue;
        if ((c - pt).distance <= threshold) {
          if (firstRightIndex == null) {
            firstRightIndex = i;
            firstRightKey = entry.key;
          }
        }
      }
      if (firstLeftIndex != null && firstRightIndex != null) break;
    }

    // If a path-proximity match was found, use it.
    if (firstLeftIndex != null && firstRightIndex != null) {
      _attemptProposedMatch(firstLeftKey, firstRightKey);
    } else {
      // No path-proximity match — try endpoint heuristic: if start/end
      // of the stroke are near left/right centers (or vice versa), accept.
      if (_points.isNotEmpty) {
        final start = _points.first.point;
        final end = _points.last.point;
  const endpointThreshold = 60.0;
        dynamic startLeftKey;
        dynamic startRightKey;
        dynamic endLeftKey;
        dynamic endRightKey;

        for (final entry in _leftKeys.entries) {
          final c = _toLocal(_centerOfKey(entry.value));
          if (c == null) continue;
          if ((c - start).distance <= endpointThreshold) startLeftKey = entry.key;
          if ((c - end).distance <= endpointThreshold) endLeftKey = entry.key;
        }
        for (final entry in _rightKeys.entries) {
          final c = _toLocal(_centerOfKey(entry.value));
          if (c == null) continue;
          if ((c - start).distance <= endpointThreshold) startRightKey = entry.key;
          if ((c - end).distance <= endpointThreshold) endRightKey = entry.key;
        }

        // If start near a left and end near a right -> match
        if (startLeftKey != null && endRightKey != null) {
          _attemptProposedMatch(startLeftKey, endRightKey);
        } else if (startRightKey != null && endLeftKey != null) {
          // If start near a right and end near a left -> match (reverse draw)
          _attemptProposedMatch(endLeftKey, startRightKey);
        }
      }
    }

    setState(() {
      _points = [];
      _hoverTarget = null;
    });
  }

  Future<void> _attemptProposedMatch(dynamic left, dynamic right) async {
    final ok = await widget.onProposeMatch(left, right);
    if (ok) {
      await playMatchAnimation(left, right);
      // show confetti at approximate center of matched pair
      final leftCenter = _toLocal(_centerOfKey(_leftKeys[left]));
      final rightCenter = _toLocal(_centerOfKey(_rightKeys[right]));
      if (leftCenter != null && rightCenter != null) {
        setState(() {
          _confettiPosition = Offset((leftCenter.dx + rightCenter.dx) / 2,
              (leftCenter.dy + rightCenter.dy) / 2);
        });
        try {
          _confettiController.play();
        } catch (_) {}
      }
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    } else {
      // wrong match feedback: briefly flash red on targets
      final savedHover = _hoverTarget;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _hoverTarget = savedHover == null ? null : savedHover;
      });
    }
  }

  Future<void> playMatchAnimation(dynamic left, dynamic right) async {
    _animating[left] = true;
    _animating[right] = true;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 260));
    _animating[left] = false;
    _animating[right] = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _handlePanStart(d.globalPosition),
      onPanUpdate: (details) => _handlePanUpdate(details.globalPosition),
      onPanEnd: (_) => _handlePanEnd(),
      onPanCancel: () => _handlePanEnd(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              // Left column: make scrollable to avoid vertical overflow
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: widget.leftItems.length > 3
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            for (final item in widget.leftItems)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedLeft == item)
                                      _selectedLeft = null;
                                    else
                                      _selectedLeft = item;
                                  });
                                  if (_selectedLeft != null && _selectedRight != null) {
                                    _attemptProposedMatch(_selectedLeft, _selectedRight);
                                    _selectedLeft = null;
                                    _selectedRight = null;
                                  }
                                },
                                child: AnimatedScale(
                                  scale: _animating[item] == true ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  child: Container(
                                    key: _leftKeys[item],
                                    margin: const EdgeInsets.symmetric(vertical: 12),
                                    width: 96,
                                    height: 96,
                                    alignment: Alignment.center,
                                    child: widget.buildLeft(item),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // increase horizontal gap to push items further toward edges
              const SizedBox(width: 48),
              // Right column: make scrollable to avoid vertical overflow
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: widget.rightItems.length > 3
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            for (final item in widget.rightItems)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedRight == item)
                                      _selectedRight = null;
                                    else
                                      _selectedRight = item;
                                  });
                                  if (_selectedLeft != null &&
                                      _selectedRight != null) {
                                    _attemptProposedMatch(
                                        _selectedLeft, _selectedRight);
                                    _selectedLeft = null;
                                    _selectedRight = null;
                                  }
                                },
                                child: AnimatedScale(
                                  scale: _animating[item] == true ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  child: Container(
                                    key: _rightKeys[item],
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    width: 96,
                                    height: 96,
                                    alignment: Alignment.center,
                                    child: widget.buildRight(item),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (_points.isNotEmpty)
            CustomPaint(
              painter: _FreehandPainter(
                  points: List.of(_points), fade: _fadeProgress),
            ),
          if (_hoverTarget != null)
            Builder(builder: (context) {
              final center = _toLocal(_centerOfKey(_draggingFromLeft
                  ? _rightKeys[_hoverTarget]
                  : _leftKeys[_hoverTarget]));
              if (center == null) return const SizedBox.shrink();
              return Positioned(
                left: center.dx - 18,
                top: center.dy - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(46),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          if (_confettiPosition != null)
            Positioned(
              left: _confettiPosition!.dx - 16,
              top: _confettiPosition!.dy - 16,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.orange, Colors.green, Colors.blue],
                emissionFrequency: 0.5,
                numberOfParticles: 16,
                maxBlastForce: 20,
                minBlastForce: 8,
              ),
            ),
        ],
      ),
    );
  }
}

class _FreehandPainter extends CustomPainter {
  final List<_TimedPoint> points;
  final double fade;
  _FreehandPainter({required this.points, this.fade = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw segment-by-segment allowing per-segment width and alpha.
    final n = points.length;
    if (n < 2) return;

    const minWidth = 3.0;
    const maxWidth = 12.0;
    const maxSpeed = 2000.0; // px/sec cap for normalization

    for (var i = 1; i < n; i++) {
      final a = points[i - 1];
      final b = points[i];
      final dt = (b.timeMs - a.timeMs).clamp(1, 10000);
      final dist = (b.point - a.point).distance;
      final speed = dist / (dt / 1000.0);
      final t = (speed / maxSpeed).clamp(0.0, 1.0);
      // faster -> thinner
      final strokeW = (maxWidth * (1 - t)) + (minWidth * t);

      // alpha fade: older segments more transparent; head (later) more opaque
      final alphaFactor = 0.2 + 0.8 * (i / n);
      // apply overall fade progress where 0 -> no fade, 1 -> fully faded
      final combinedAlpha =
          (220 * alphaFactor * (1 - fade)).clamp(0, 255).toInt();
      final color = Colors.deepOrange.withAlpha(combinedAlpha);

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(a.point.dx, a.point.dy);
      final mid =
          Offset((a.point.dx + b.point.dx) / 2, (a.point.dy + b.point.dy) / 2);
      path.quadraticBezierTo(a.point.dx, a.point.dy, mid.dx, mid.dy);
      path.lineTo(b.point.dx, b.point.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FreehandPainter oldDelegate) => true;
}
