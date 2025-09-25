import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

// Local typedef for building items
typedef _BuildItem = Widget Function(dynamic item);

class _TimedPoint {
  final Offset point;
  final int timeMs;
  _TimedPoint(this.point, this.timeMs);
}

// Immediate drag forwarded into the drag area state
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

class DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;
  final ValueNotifier<bool>? isDrawingNotifier;
  final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;

  const DragMatchArea({
    required Key key,
    required this.leftItems,
    required this.rightItems,
    required this.buildLeft,
    required this.buildRight,
    required this.onProposeMatch,
    this.isDrawingNotifier,
  }) : super(key: key);

  @override
  State<DragMatchArea> createState() => _DragMatchAreaState();
}

class _DragMatchAreaState extends State<DragMatchArea>
    with SingleTickerProviderStateMixin {
  List<_TimedPoint> _points = [];
  bool _draggingFromLeft = true;
  dynamic _hoverTarget;
  dynamic _lastHoverTarget;
  late AnimationController _fadeController;
  double _fadeProgress = 0.0;
  import 'package:flutter/gestures.dart';
  import 'package:flutter/material.dart';

  // Local typedef for building items
  typedef _BuildItem = Widget Function(dynamic item);

  class _TimedPoint {
    final Offset point;
    final int timeMs;
    _TimedPoint(this.point, this.timeMs);
  }

  class DragMatchArea extends StatefulWidget {
    final List<dynamic> leftItems;
    final List<dynamic> rightItems;
    final _BuildItem buildLeft;
    final _BuildItem buildRight;

    /// Called when the user attempts a match (drag finishes or both tapped).
    /// Should return a Future<bool> indicating whether the match is valid.
    final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;
    const DragMatchArea(
        {required Key key,
        required this.leftItems,
        required this.rightItems,
        required this.buildLeft,
        required this.buildRight,
        required this.onProposeMatch})
        : super(key: key);
    @override
    State<DragMatchArea> createState() => _DragMatchAreaState();
  }

  class _DragMatchAreaState extends State<DragMatchArea> {
    List<_TimedPoint> _points = [];
    dynamic _draggingItem;
    bool _draggingFromLeft = true;
    dynamic _hoverTarget;

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
    }

    @override
    void didUpdateWidget(covariant DragMatchArea oldWidget) {
      super.didUpdateWidget(oldWidget);
      for (final l in widget.leftItems) {
        _leftKeys.putIfAbsent(l, () => GlobalKey());
      }
      for (final r in widget.rightItems) {
        _rightKeys.putIfAbsent(r, () => GlobalKey());
      }
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
        if (p != null) _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
        _hoverTarget = null;
        _draggingItem = null;
        // Guess initial side from x coordinate
        final width = (context.findRenderObject() as RenderBox?)?.size.width ??
            MediaQuery.of(context).size.width;
        _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
      });
    }

    void _handlePanUpdate(Offset globalPos) {
      setState(() {
        final p = _toLocal(globalPos);
        if (p != null) _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));

        // update hover target depending on last point
        final threshold = 32.0;
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
      });
    }

    void _handlePanEnd() {
      if (_points.isEmpty) {
        setState(() {
          _points = [];
          _draggingItem = null;
          _hoverTarget = null;
        });
        return;
      }
      // Enforce minimum stroke length to avoid accidental short scribbles
      if (_points.length < 3) {
        setState(() {
          _points = [];
          _draggingItem = null;
          _hoverTarget = null;
        });
        return;
      }
      // Find the first occurrence in the stroke where the path is near any
      // left or right item center. Then if both sides are hit, check order.
      final threshold = 36.0;
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

      if (firstLeftIndex != null && firstRightIndex != null) {
        if (firstLeftIndex <= firstRightIndex) {
          // drew from left to right
          _attemptProposedMatch(firstLeftKey, firstRightKey);
        } else {
          // drew from right to left
          _attemptProposedMatch(firstLeftKey, firstRightKey);
        }
      }

      setState(() {
        _points = [];
        _draggingItem = null;
        _hoverTarget = null;
      });
    }

    Future<void> _attemptProposedMatch(dynamic left, dynamic right) async {
      final ok = await widget.onProposeMatch(left, right);
      if (ok) {
        await playMatchAnimation(left, right);
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                              key: _leftKeys[item],
                              margin: const EdgeInsets.symmetric(vertical: 16),
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            if (_selectedLeft != null && _selectedRight != null) {
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
                              margin: const EdgeInsets.symmetric(vertical: 16),
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
              ],
            ),
                    if (_points.isNotEmpty)
                      CustomPaint(
                        painter: _FreehandPainter(points: List.of(_points)),
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
          ],
        ),
      );
    }
  }

  class _FreehandPainter extends CustomPainter {
    final List<_TimedPoint> points;
    _FreehandPainter({required this.points});

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
        final color = Colors.orange.withAlpha((220 * alphaFactor).toInt());

        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;

        final path = Path();
        path.moveTo(a.point.dx, a.point.dy);
        final mid = Offset((a.point.dx + b.point.dx) / 2, (a.point.dy + b.point.dy) / 2);
        path.quadraticBezierTo(a.point.dx, a.point.dy, mid.dx, mid.dy);
        path.lineTo(b.point.dx, b.point.dy);

        canvas.drawPath(path, paint);
      }
    }

    @override
    bool shouldRepaint(covariant _FreehandPainter oldDelegate) => true;
  }