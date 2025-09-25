import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/widgets/celebration_overlay.dart';

/// Base widget for any matching game type.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;
  final String title;
  const MatchingGameBase({required this.mode, required this.title, super.key});

  @override
  State<MatchingGameBase> createState() => _MatchingGameBaseState();
}

class _MatchingGameBaseState extends State<MatchingGameBase> {
  List<dynamic> leftItems = [];
  List<dynamic> rightItems = [];
  Map<dynamic, dynamic> matches = {}; // left -> right
  dynamic selectedLeft;
  dynamic selectedRight;
  bool completed = false;
  bool _showCelebration = false;

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
                _MatchedTray(matches: matches, mode: widget.mode, onReset: _resetGame),
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
                              leftItems: leftItems,
                              rightItems: rightItems,
                              buildLeft: (item) => widget.mode.buildLeftItem(context, item),
                              buildRight: (item) => widget.mode.buildRightItem(context, item),
                              onMatched: (l, r) {
                                setState(() {
                                  matches[l] = r;
                                  leftItems.remove(l);
                                  rightItems.remove(r);
                                  _saveProgress();
                                  if (leftItems.isEmpty && rightItems.isEmpty) {
                                    completed = true;
                                    _showCelebration = true;
                                  }
                                });
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

class _DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;
  final void Function(dynamic left, dynamic right) onMatched;
  const _DragMatchArea({required this.leftItems, required this.rightItems, required this.buildLeft, required this.buildRight, required this.onMatched});
  @override
  State<_DragMatchArea> createState() => _DragMatchAreaState();
}

class _DragMatchAreaState extends State<_DragMatchArea> {
  Offset? _start;
  Offset? _current;
  dynamic _draggingItem;
  bool _draggingFromLeft = true;
  dynamic _hoverTarget;

  final Map<dynamic, GlobalKey> _leftKeys = {};
  final Map<dynamic, GlobalKey> _rightKeys = {};

  @override
  void initState() {
    super.initState();
    for (final l in widget.leftItems) {
      _leftKeys[l] = GlobalKey();
    }
    for (final r in widget.rightItems) {
      _rightKeys[r] = GlobalKey();
    }
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

  void _startDrag(dynamic item, bool fromLeft, Offset globalPos) {
    setState(() {
      _draggingItem = item;
      _draggingFromLeft = fromLeft;
      _start = _centerOfKey(fromLeft ? _leftKeys[item] : _rightKeys[item]);
      _current = globalPos;
      _hoverTarget = null;
    });
  }

  void _updateDrag(Offset globalPos) {
    setState(() {
      _current = globalPos;
      // update hover target depending on drag direction
      final threshold = 28.0;
      _hoverTarget = null;
      if (_draggingFromLeft) {
        for (final entry in _rightKeys.entries) {
          final center = _centerOfKey(entry.value);
          if (center == null) continue;
          if ((center - globalPos).distance <= threshold) {
            _hoverTarget = entry.key;
            break;
          }
        }
      } else {
        for (final entry in _leftKeys.entries) {
          final center = _centerOfKey(entry.value);
          if (center == null) continue;
          if ((center - globalPos).distance <= threshold) {
            _hoverTarget = entry.key;
            break;
          }
        }
      }
    });
  }

  void _endDrag() {
    if (_draggingItem == null || _current == null) {
      setState(() { _start = null; _current = null; _draggingItem = null; _hoverTarget = null; });
      return;
    }
    // Determine hit depending on drag direction
    dynamic hit;
    final threshold = 28.0;
    if (_draggingFromLeft) {
      for (final entry in _rightKeys.entries) {
        final center = _centerOfKey(entry.value);
        if (center == null) continue;
        if ((center - _current!).distance <= threshold) {
          hit = entry.key;
          break;
        }
      }
      if (hit != null) {
        widget.onMatched(_draggingItem, hit);
      }
    } else {
      for (final entry in _leftKeys.entries) {
        final center = _centerOfKey(entry.value);
        if (center == null) continue;
        if ((center - _current!).distance <= threshold) {
          hit = entry.key;
          break;
        }
      }
      if (hit != null) {
        widget.onMatched(hit, _draggingItem);
      }
    }
  setState(() { _start = null; _current = null; _draggingItem = null; _hoverTarget = null; });
  }

  Offset? _centerOfKey(GlobalKey? key) {
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _updateDrag(details.globalPosition),
      onPanEnd: (_) => _endDrag(),
      onPanCancel: () => _endDrag(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final item in widget.leftItems)
                      GestureDetector(
                        onPanStart: (d) => _startDrag(item, true, d.globalPosition),
                        child: Container(
                          key: _leftKeys[item],
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          child: widget.buildLeft(item),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final item in widget.rightItems)
                      GestureDetector(
                        onPanStart: (d) => _startDrag(item, false, d.globalPosition),
                        child: Container(
                          key: _rightKeys[item],
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          width: 96,
                          height: 96,
                          alignment: Alignment.center,
                          child: widget.buildRight(item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_start != null && _current != null)
            CustomPaint(
              painter: _LinePainter(start: _start!, end: (_hoverTarget != null ? (_centerOfKey(_draggingFromLeft ? _rightKeys[_hoverTarget] : _leftKeys[_hoverTarget]) ?? _current!) : _current!) ),
            ),
          if (_hoverTarget != null)
            Builder(builder: (context) {
              final center = _centerOfKey(_draggingFromLeft ? _rightKeys[_hoverTarget] : _leftKeys[_hoverTarget]);
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
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  _LinePainter({required this.start, required this.end});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
  ..color = Colors.orange.withAlpha(230)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}