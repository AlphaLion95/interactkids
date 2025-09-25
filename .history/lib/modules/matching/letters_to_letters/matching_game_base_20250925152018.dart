import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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
  // notifier used to inform scrollables when drawing is active
  late final ValueNotifier<bool> _isDrawingNotifier;

  // Use the progress key provided by the active mode so different game types
  // do not share the same persisted progress store.
  String get _progressKey => widget.mode.progressKey;

  @override
  void initState() {
    super.initState();
    _isDrawingNotifier = ValueNotifier<bool>(false);
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant MatchingGameBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the active mode changed (e.g. different visuals or difficulty),
    // reload persisted progress and rebuild the item lists so the UI
    // reflects the new mode's pairs/visuals.
    if (oldWidget.mode != widget.mode) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_progressKey);
    final allPairs = widget.mode.pairs;

    matches = {};
    // initialize item lists from mode pairs
    leftItems = allPairs.map((p) => p.left).toList();
    rightItems = allPairs.map((p) => p.right).toList();

    // restore saved matches (stored as "left=right") if present
    if (saved != null) {
      for (final entry in saved) {
        final parts = entry.split('=');
        if (parts.length != 2) continue;
        final left = parts[0];
        final right = parts[1];
        matches[left] = right;
        leftItems.remove(left);
        rightItems.remove(right);
      }
    }

    // shuffle remaining items for a fresh layout but keep left/right aligned
    // by applying the same permutation to both lists.
    if (leftItems.isNotEmpty) {
      final rng = DateTime.now().millisecondsSinceEpoch;
      final perm = List<int>.generate(leftItems.length, (i) => i);
      perm.shuffle(math.Random(rng));
      leftItems = perm.map((i) => leftItems[i]).toList();
      rightItems = perm.map((i) => rightItems[i]).toList();
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
                    ? const Center(
                        child: Text('Great job! All pairs matched!',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(builder: (context, constraints) {
                          if (widget.mode.supportsDragMatch) {
                            return _DragMatchArea(
                              key: const ValueKey('drag-match-area'),
                              isDrawingNotifier: _isDrawingNotifier,
                              leftItems: leftItems,
                              rightItems: rightItems,
                              preferredCellSize: widget.mode.preferredCellSize,
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
        // Top-layer listener: capture raw pointer events (avoids inner Scrollables stealing vertical drags)
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (ev) {
              final areaState = _dragAreaKey.currentState;
              if (areaState is _DragMatchAreaState) {
                try {
                  // If the touch is roughly in the central area (not on the left/right
                  // scroll columns), immediately mark as drawing so scrollables
                  // don't steal the gesture. Use a safe margin so we don't block
                  // intended column scrolls.
                  final local = areaState._toLocal(ev.position);
                  if (local != null) {
                    final box =
                        areaState.context.findRenderObject() as RenderBox?;
                    final w = box?.size.width ??
                        MediaQuery.of(areaState.context).size.width;
                    const margin = 120.0;
                    if (local.dx > margin && local.dx < (w - margin)) {
                      try {
                        areaState.widget.isDrawingNotifier?.value = true;
                      } catch (_) {}
                    }
                  }
                  areaState._handlePanStart(ev.position);
                } catch (_) {}
              }
            },
            onPointerMove: (ev) {
              final areaState = _dragAreaKey.currentState;
              if (areaState is _DragMatchAreaState) {
                try {
                  areaState._handlePanUpdate(ev.position);
                } catch (_) {}
              }
            },
            onPointerUp: (ev) {
              final areaState = _dragAreaKey.currentState;
              if (areaState is _DragMatchAreaState) {
                try {
                  areaState._handlePanEnd();
                  try {
                    areaState.widget.isDrawingNotifier?.value = false;
                  } catch (_) {}
                } catch (_) {}
              }
            },
            onPointerCancel: (ev) {
              final areaState = _dragAreaKey.currentState;
              if (areaState is _DragMatchAreaState) {
                try {
                  areaState._handlePanEnd();
                  try {
                    areaState.widget.isDrawingNotifier?.value = false;
                  } catch (_) {}
                } catch (_) {}
              }
            },
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

// Top-level immediate drag that forwards updates into the drag area state.
class _ImmediateDrag implements Drag {
  final _DragMatchAreaState _state;
  _ImmediateDrag(this._state);

  @override
  void update(DragUpdateDetails details) {
    try {
      _state._handlePanUpdate(details.globalPosition);
    } catch (_) {}
  }

  @override
  void end(DragEndDetails details) {
    try {
      _state._handlePanEnd();
    } catch (_) {}
  }

  @override
  void cancel() {
    try {
      _state._handlePanEnd();
    } catch (_) {}
  }
}

class _DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;
  final double? preferredCellSize;
  final ValueNotifier<bool>? isDrawingNotifier;

  /// Called when the user attempts a match (drag finishes or both tapped).
  /// Should return a Future<bool> indicating whether the match is valid.
  final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;
  const _DragMatchArea(
      {required Key key,
      required this.leftItems,
      required this.rightItems,
      required this.buildLeft,
      required this.buildRight,
      required this.onProposeMatch,
      this.isDrawingNotifier,
      this.preferredCellSize})
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
  // Threshold for proximity hit-testing (pixels). Tunable.
  final double _hitThreshold = 44.0;
  // Debug overlay flag enabled only in debug builds via assert.
  bool _showHitDebug = false;
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
    // Enable debug overlay in debug mode only.
    assert(() {
      _showHitDebug = true;
      return true;
    }());
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

    // set up an immediate drag recognizer so drawing gestures can claim
    // the pointer immediately (preventing scrollables from stealing it).
    _immediateDragRecognizer = ImmediateMultiDragGestureRecognizer()
      ..onStart = (Offset globalPosition) {
        try {
          _handlePanStart(globalPosition);
        } catch (_) {}
        return _ImmediateDrag(this);
      };
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
    _immediateDragRecognizer.dispose();
    super.dispose();
  }

  late ImmediateMultiDragGestureRecognizer _immediateDragRecognizer;

  // Immediate drag implementation is provided by the top-level
  // `_ImmediateDrag` class declared above so no nested class needed here.

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

  // Distance from point p to segment [a,b]
  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / abLen2;
    if (t <= 0) return (p - a).distance;
    if (t >= 1) return (p - b).distance;
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  void _handlePanStart(Offset globalPos) {
    setState(() {
      _points = [];
      final p = _toLocal(globalPos);
      if (p != null) {
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      }
      _hoverTarget = null;
      // Guess initial side from x coordinate
      final width = (context.findRenderObject() as RenderBox?)?.size.width ??
          MediaQuery.of(context).size.width;
      _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
      // reset drawing flag; user just touched down
      try {
        widget.isDrawingNotifier?.value = false;
      } catch (_) {}
    });
  }

  /// Clear any current stroke immediately.
  void clearStroke() {
    _fadeController.stop();
    setState(() {
      _points = [];
      _fadeProgress = 0.0;
      try {
        widget.isDrawingNotifier?.value = false;
      } catch (_) {}
    });
  }

  void _handlePanUpdate(Offset globalPos) {
    setState(() {
      final p = _toLocal(globalPos);
      if (p != null) {
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      }

      // If movement between last two points exceeds a small threshold,
      // consider this a drawing gesture so parent scrollables can be disabled.
      if (_points.length >= 2) {
        final a = _points[_points.length - 2].point;
        final b = _points.last.point;
        if ((b - a).distance > 6.0) {
          try {
            widget.isDrawingNotifier?.value = true;
          } catch (_) {}
        }
      }

      // update hover target depending on last point
      const threshold = 32.0;
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

    // Enforce minimum stroke length to avoid accidental short scribbles
    if (_points.length < 3) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }

    final threshold = _hitThreshold;

    // Collect candidate hits per side
    final List<Map<String, dynamic>> leftHits = [];
    final List<Map<String, dynamic>> rightHits = [];

    for (var i = 0; i < _points.length - 1; i++) {
      final a = _points[i].point;
      final b = _points[i + 1].point;

      for (final entry in _leftKeys.entries) {
        final c = _toLocal(_centerOfKey(entry.value));
        if (c == null) continue;
        final dist = _distancePointToSegment(c, a, b);
        if (dist <= threshold) {
          leftHits.add({'idx': i, 'key': entry.key, 'dist': dist});
          if (_showHitDebug)
            print(
                'DragMatch: left candidate ${entry.key} dist=${dist.toStringAsFixed(1)} segment=$i');
        }
      }

      for (final entry in _rightKeys.entries) {
        final c = _toLocal(_centerOfKey(entry.value));
        if (c == null) continue;
        final dist = _distancePointToSegment(c, a, b);
        if (dist <= threshold) {
          rightHits.add({'idx': i, 'key': entry.key, 'dist': dist});
          if (_showHitDebug)
            print(
                'DragMatch: right candidate ${entry.key} dist=${dist.toStringAsFixed(1)} segment=$i');
        }
      }
    }

    // If endpoints are close to centers (in case stroke ended inside a tile), check last point too
    final lastPt = _points.last.point;
    for (final entry in _leftKeys.entries) {
      final c = _toLocal(_centerOfKey(entry.value));
      if (c == null) continue;
      final d = (c - lastPt).distance;
      if (d <= threshold)
        leftHits.add({'idx': _points.length - 1, 'key': entry.key, 'dist': d});
    }
    for (final entry in _rightKeys.entries) {
      final c = _toLocal(_centerOfKey(entry.value));
      if (c == null) continue;
      final d = (c - lastPt).distance;
      if (d <= threshold)
        rightHits.add({'idx': _points.length - 1, 'key': entry.key, 'dist': d});
    }

    if (_showHitDebug)
      print(
          'DragMatch: leftHits=${leftHits.length} rightHits=${rightHits.length}');

    // Prefer a left/right pair where the keys match (same item id).
    Map<String, dynamic>? chosenLeft;
    Map<String, dynamic>? chosenRight;

    for (final l in leftHits) {
      for (final r in rightHits) {
        if (l['key'] == r['key']) {
          // prefer earliest occurrence (min max(idx)) and then nearest sum of distances
          final currentScore = (chosenLeft == null)
              ? null
              : math.max(chosenLeft['idx'] as int, chosenRight!['idx'] as int);
          final candidateScore = math.max(l['idx'] as int, r['idx'] as int);
          if (chosenLeft == null ||
              candidateScore < (currentScore ?? double.infinity)) {
            chosenLeft = l;
            chosenRight = r;
          } else if (candidateScore == currentScore) {
            // tie-breaker: smaller combined distance
            final nonNullChosenLeft = chosenLeft!;
            final nonNullChosenRight = chosenRight!;
            final currentDist = (nonNullChosenLeft['dist'] as double) +
                (nonNullChosenRight['dist'] as double);
            final candDist = (l['dist'] as double) + (r['dist'] as double);
            if (candDist < currentDist) {
              chosenLeft = l;
              chosenRight = r;
            }
          }
        }
      }
    }

    // If no matching-key pair found, pick earliest-per-side then attempt
    if (chosenLeft == null && leftHits.isNotEmpty) {
      leftHits.sort((a, b) => (a['idx'] as int).compareTo(b['idx'] as int));
      chosenLeft = leftHits.first;
    }
    if (chosenRight == null && rightHits.isNotEmpty) {
      rightHits.sort((a, b) => (a['idx'] as int).compareTo(b['idx'] as int));
      chosenRight = rightHits.first;
    }

    if (_showHitDebug)
      print('DragMatch: chosenLeft=$chosenLeft chosenRight=$chosenRight');

    if (chosenLeft != null && chosenRight != null) {
      final leftKey = chosenLeft['key'];
      final rightKey = chosenRight['key'];
      if (leftKey == rightKey) {
        if (_showHitDebug) print('DragMatch: proposing match for $leftKey');
        _attemptProposedMatch(leftKey, rightKey);
      } else {
        if (_showHitDebug)
          print(
              'DragMatch: ambiguous candidates left=$leftKey right=$rightKey; not proposing');
        // don't propose a match if the detected left/right keys don't match
        // to avoid false-negative feedback; user can try again or tap.
      }
    }

    setState(() {
      _points = [];
      _hoverTarget = null;
      try {
        widget.isDrawingNotifier?.value = false;
      } catch (_) {}
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
      if (mounted) {
        setState(() {});
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _hoverTarget = savedHover;
        });
      }
    }
  }

  Future<void> playMatchAnimation(dynamic left, dynamic right) async {
    _animating[left] = true;
    _animating[right] = true;
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 260));
    _animating[left] = false;
    _animating[right] = false;
    if (mounted) setState(() {});
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
              // Left + Right columns rendered as aligned rows so items match side-by-side
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable:
                      widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                  builder: (context, isDrawing, child) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 8, left: 16, right: 16),
                      child: LayoutBuilder(builder: (context, constraints) {
                        // Compute rows: we want left and right items to align by row.
                        final double desiredCellSize =
                            widget.preferredCellSize ?? 120.0; // preferred max
                        // Allow multiple items per side per row depending on horizontal space
                        final double availWidth = constraints.maxWidth;
                        final int perRow = math.max(
                            1, (availWidth / (desiredCellSize * 2)).floor());
                        final int leftCount = widget.leftItems.length;
                        final int rightCount = widget.rightItems.length;
                        final int rows = math.max(
                            (leftCount + perRow - 1) ~/ perRow,
                            (rightCount + perRow - 1) ~/ perRow);

                        // Compute a cellSize that will fit all rows into the
                        // available vertical space. Keep a reasonable minimum.
                        final availableHeight = constraints.maxHeight;
                        final totalVerticalSpacing = (rows - 1) * 12.0 +
                            16.0; // row gaps + small padding
                        double maxCellPerRow = rows > 0
                            ? (availableHeight - totalVerticalSpacing) / rows
                            : desiredCellSize;
                        if (maxCellPerRow.isNaN || maxCellPerRow.isInfinite) {
                          maxCellPerRow = desiredCellSize;
                        }
                        final double cellSize = math.max(
                            48.0, math.min(desiredCellSize, maxCellPerRow));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(rows, (rowIndex) {
                            final leftRowStart = rowIndex * perRow;
                            final rightRowStart = rowIndex * perRow;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left group for this row
                                  Row(
                                    children: List.generate(perRow, (i) {
                                      final idx = leftRowStart + i;
                                      if (idx >= widget.leftItems.length)
                                        return const SizedBox.shrink();
                                      final item = widget.leftItems[idx];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_selectedLeft == item) {
                                                _selectedLeft = null;
                                              } else {
                                                _selectedLeft = item;
                                              }
                                            });
                                            if (_selectedLeft != null &&
                                                _selectedRight != null) {
                                              _attemptProposedMatch(
                                                  _selectedLeft,
                                                  _selectedRight);
                                              _selectedLeft = null;
                                              _selectedRight = null;
                                            }
                                          },
                                          child: Transform.scale(
                                            scale: _animating[item] == true
                                                ? 1.2
                                                : 1.0,
                                            child: SizedBox(
                                              key: _leftKeys[item],
                                              width: cellSize,
                                              height: cellSize,
                                              child: Center(
                                                  child:
                                                      widget.buildLeft(item)),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  // Right group for this row
                                  Row(
                                    children: List.generate(perRow, (i) {
                                      final idx = rightRowStart + i;
                                      if (idx >= widget.rightItems.length)
                                        return const SizedBox.shrink();
                                      final item = widget.rightItems[idx];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_selectedRight == item) {
                                                _selectedRight = null;
                                              } else {
                                                _selectedRight = item;
                                              }
                                            });
                                            if (_selectedLeft != null &&
                                                _selectedRight != null) {
                                              _attemptProposedMatch(
                                                  _selectedLeft,
                                                  _selectedRight);
                                              _selectedLeft = null;
                                              _selectedRight = null;
                                            }
                                          },
                                          child: Transform.scale(
                                            scale: _animating[item] == true
                                                ? 1.2
                                                : 1.0,
                                            child: SizedBox(
                                              key: _rightKeys[item],
                                              width: cellSize,
                                              height: cellSize,
                                              child: Center(
                                                  child:
                                                      widget.buildRight(item)),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                    );
                  },
                ),
              ),
              // Right column removed - rendering is handled by aligned rows above
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
