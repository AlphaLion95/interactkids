import 'package:flutter/material.dart';

// DragMatchArea: handles freehand strokes and proposes matches via onProposeMatch
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

  /// Optional notifier to indicate whether the user is currently drawing.
  /// When true, parent scrollables should disable vertical scroll.
  final ValueNotifier<bool>? isDrawingNotifier;

  const DragMatchArea(
      {required Key key,
      required this.leftItems,
      required this.rightItems,
      required this.buildLeft,
      required this.buildRight,
      required this.onProposeMatch,
      this.isDrawingNotifier})
      : super(key: key);

  @override
  State<DragMatchArea> createState() => _DragMatchAreaState();
}

class _DragMatchAreaState extends State<DragMatchArea> {
  List<_TimedPoint> _points = [];
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
    for (final l in widget.leftItems) _leftKeys[l] = GlobalKey();
    for (final r in widget.rightItems) _rightKeys[r] = GlobalKey();
  }

  @override
  void didUpdateWidget(covariant DragMatchArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final l in widget.leftItems)
      _leftKeys.putIfAbsent(l, () => GlobalKey());
    for (final r in widget.rightItems)
      _rightKeys.putIfAbsent(r, () => GlobalKey());
  }

  Offset? _centerOfKey(GlobalKey? key) {
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    // Avoid calling findRenderObject on inactive elements which throws.
    if (ctx is Element && !ctx.mounted) return null;
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
    // Determine if the touch started within side margins; if so, don't treat
    // it as a drawing gesture (allow scroll). Otherwise, mark drawing active.
    final local = _toLocal(globalPos);
    final width = (context.findRenderObject() as RenderBox?)?.size.width ??
        MediaQuery.of(context).size.width;
    final marginPx = width * 0.12; // 12% margins on each side
    final startedInMargin = local == null
        ? false
        : (local.dx <= marginPx || local.dx >= (width - marginPx));

    try {
      if (widget.isDrawingNotifier != null)
        widget.isDrawingNotifier!.value = !startedInMargin;
    } catch (_) {}

    setState(() {
      _points = [];
      final p = local;
      if (p != null)
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      _hoverTarget = null;
      _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
    });
  }

  void _handlePanUpdate(Offset globalPos) {
    setState(() {
      final p = _toLocal(globalPos);
      if (p != null)
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));

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

  /// Clear any current stroke immediately.
  void clearStroke() {
    setState(() {
      _points = [];
      _hoverTarget = null;
    });
  }

  void _handlePanEnd() async {
    if (_points.isEmpty) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }
    if (_points.length < 3) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }

    final threshold = 36.0;
    int? firstLeftIndex;
    int? firstRightIndex;
    dynamic firstLeftKey;
    dynamic firstRightKey;

    for (var i = 0; i < _points.length; i++) {
      final pt = _points[i].point;
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
        await _attemptProposedMatch(firstLeftKey, firstRightKey);
      } else {
        await _attemptProposedMatch(firstLeftKey, firstRightKey);
      }
    } else {
      // endpoint heuristics omitted for brevity
    }

    setState(() {
      _points = [];
      _hoverTarget = null;
    });

    try {
      if (widget.isDrawingNotifier != null)
        widget.isDrawingNotifier!.value = false;
    } catch (_) {}
  }

  Future<void> _attemptProposedMatch(dynamic left, dynamic right) async {
    bool ok = false;
    try {
      ok = await widget.onProposeMatch(left, right);
    } catch (e, st) {
      // Log but don't rethrow — prevent transient errors from showing the red error screen.
      debugPrint('Error in onProposeMatch: $e\n$st');
      ok = false;
    }

    if (ok) {
      try {
        await playMatchAnimation(left, right);
      } catch (e, st) {
        debugPrint('Error during playMatchAnimation: $e\n$st');
      }
    } else {
      final savedHover = _hoverTarget;
      if (mounted) setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _hoverTarget = savedHover == null ? null : savedHover;
        });
      }
    }
  }

  Future<void> playMatchAnimation(dynamic left, dynamic right) async {
    _animating[left] = true;
    _animating[right] = true;
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.leftItems.map((item) {
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            if (_selectedLeft == item)
                              _selectedLeft = null;
                            else
                              _selectedLeft = item;
                          });
                          if (_selectedLeft != null && _selectedRight != null) {
                            await _attemptProposedMatch(
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
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.rightItems.map((item) {
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            if (_selectedRight == item)
                              _selectedRight = null;
                            else
                              _selectedRight = item;
                          });
                          if (_selectedLeft != null && _selectedRight != null) {
                            await _attemptProposedMatch(
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
                      );
                    }).toList(),
                  ),
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
    final n = points.length;
    if (n < 2) return;

    const minWidth = 3.0;
    const maxWidth = 12.0;
    const maxSpeed = 2000.0;

    for (var i = 1; i < n; i++) {
      final a = points[i - 1];
      final b = points[i];
      final dt = (b.timeMs - a.timeMs).clamp(1, 10000);
      final dist = (b.point - a.point).distance;
      final speed = dist / (dt / 1000.0);
      final t = (speed / maxSpeed).clamp(0.0, 1.0);
      final strokeW = (maxWidth * (1 - t)) + (minWidth * t);

      final alphaFactor = 0.2 + 0.8 * (i / n);
      final combinedAlpha = (220 * alphaFactor).clamp(0, 255).toInt();
      final color = Colors.deepOrange.withOpacity(combinedAlpha / 255.0);

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
