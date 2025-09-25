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
  late ConfettiController _confettiController;
  Offset? _confettiPosition;

  final Map<dynamic, GlobalKey> _leftKeys = {};
  final Map<dynamic, GlobalKey> _rightKeys = {};
  final Map<dynamic, bool> _animating = {};
  dynamic _selectedLeft;
  dynamic _selectedRight;

  late ImmediateMultiDragGestureRecognizer _immediateDragRecognizer;

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

    _immediateDragRecognizer = ImmediateMultiDragGestureRecognizer()
      ..onStart = (Offset globalPosition) {
        try {
          _handlePanStart(globalPosition);
        } catch (_) {}
        return _ImmediateDrag(this);
      };
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePanStart(Offset globalPos) {
    _fadeController.stop();
    _fadeController.value = 0.0;
    try {
      widget.isDrawingNotifier?.value = true;
    } catch (_) {}
    setState(() {
      _points = [ _TimedPoint(globalPos, DateTime.now().millisecondsSinceEpoch) ];
      _hoverTarget = null;
    });
  }

  void _handlePanUpdate(Offset globalPos) {
    setState(() {
      _points.add(_TimedPoint(globalPos, DateTime.now().millisecondsSinceEpoch));

      // find nearest left/right hover target
      const hoverThreshold = 36.0;
      dynamic found;
      bool fromLeft = _draggingFromLeft;
      final allEntries = (fromLeft ? _rightKeys.entries : _leftKeys.entries);
      for (final entry in allEntries) {
        final c = _toLocal(_centerOfKey(entry.value));
        if (c == null) continue;
        if ((c - globalPos).distance <= hoverThreshold) {
          found = entry.key;
          break;
        }
      }
      _hoverTarget = found;
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
    if (_points.length < 3) {
      setState(() {
        _points = [];
        _hoverTarget = null;
      });
      return;
    }

    const threshold = 36.0;
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
        _attemptProposedMatch(firstLeftKey, firstRightKey);
      } else {
        _attemptProposedMatch(firstLeftKey, firstRightKey);
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
      final savedHover = _hoverTarget;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _hoverTarget = savedHover;
      });
    }
  }
```}]}```}]}]}