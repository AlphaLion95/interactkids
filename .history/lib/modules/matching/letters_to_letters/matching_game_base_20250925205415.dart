import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
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

class _DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;
  final ValueNotifier<bool>? isDrawingNotifier;
  final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;

  const _DragMatchArea({
    required Key key,
    required this.leftItems,
    required this.rightItems,
    required this.buildLeft,
    required this.buildRight,
    required this.onProposeMatch,
    this.isDrawingNotifier,
  }) : super(key: key);

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

  late ImmediateMultiDragGestureRecognizer _immediateDragRecognizer;
  // If pointer-down starts within these many pixels from the left/right edge,
  // allow the vertical Scrollables to handle the gesture instead of starting
  // a drawing gesture here.
  static const double _sideScrollMargin = 80.0;
  bool _startInSideMargin = false;

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
      if (p != null) {
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      }
      _hoverTarget = null;
      final width = (context.findRenderObject() as RenderBox?)?.size.width ??
          MediaQuery.of(context).size.width;
      _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
      try {
        widget.isDrawingNotifier?.value = false;
      } catch (_) {}
    });
  }

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
      if (_points.length >= 2) {
        final a = _points[_points.length - 2].point;
        final b = _points.last.point;
        if ((b - a).distance > 6.0) {
          try {
            widget.isDrawingNotifier?.value = true;
          } catch (_) {}
        }
      }

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
    return Listener(
      onPointerDown: (ev) {
        // determine local X and whether it is in the side margins
        final rb = context.findRenderObject() as RenderBox?;
        if (rb != null && rb.hasSize) {
          final local = rb.globalToLocal(ev.position);
          final w = rb.size.width;
          final inMargin = local.dx <= _sideScrollMargin || local.dx >= (w - _sideScrollMargin);
          if (_startInSideMargin != inMargin) {
            setState(() {
              _startInSideMargin = inMargin;
            });
          }
        }
      },
      onPointerUp: (_) {
        if (_startInSideMargin) {
          setState(() {
            _startInSideMargin = false;
          });
        }
      },
      onPointerCancel: (_) {
        if (_startInSideMargin) {
          setState(() {
            _startInSideMargin = false;
          });
        }
      },
      child: GestureDetector(
        // Only attach pan handlers when the pointer didn't start in side margins
        onPanStart: _startInSideMargin ? null : (d) => _handlePanStart(d.globalPosition),
        onPanUpdate: _startInSideMargin ? null : (details) => _handlePanUpdate(details.globalPosition),
        onPanEnd: _startInSideMargin ? null : (_) => _handlePanEnd(),
        onPanCancel: _startInSideMargin ? null : () => _handlePanEnd(),
        child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                    builder: (context, isDrawing, child) {
                      return SingleChildScrollView(
                        physics: (isDrawing || !_startInSideMargin)
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: widget.leftItems.length > 3
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: widget.leftItems.map((item) {
                                return GestureDetector(
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
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                      );
                    },
                  );
                }),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                    builder: (context, isDrawing, child) {
                      return SingleChildScrollView(
                        physics: (isDrawing || !_startInSideMargin)
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: widget.rightItems.length > 3
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: widget.rightItems.map((item) {
                                return GestureDetector(
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
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
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
                    color: Colors.orange.withOpacity(0.18),
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

class _DragMatchArea extends StatefulWidget {
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final _BuildItem buildLeft;
  final _BuildItem buildRight;
  final ValueNotifier<bool>? isDrawingNotifier;
  final Future<bool> Function(dynamic left, dynamic right) onProposeMatch;

  const _DragMatchArea({
    required Key key,
    required this.leftItems,
    required this.rightItems,
    required this.buildLeft,
    required this.buildRight,
    required this.onProposeMatch,
    this.isDrawingNotifier,
  }) : super(key: key);

  @override
  State<_DragMatchArea> createState() => _DragMatchAreaState();
}

// _MatchedTray is declared later in the file (moved) to keep MatchingGameBaseState
// methods inside the class. See bottom of file for the implementation.

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
      if (p != null) {
        _points.add(_TimedPoint(p, DateTime.now().millisecondsSinceEpoch));
      }
      _hoverTarget = null;
      final width = (context.findRenderObject() as RenderBox?)?.size.width ??
          MediaQuery.of(context).size.width;
      _draggingFromLeft = (p?.dx ?? 0) < (width / 2);
      try {
        widget.isDrawingNotifier?.value = false;
      } catch (_) {}
    });
  }

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
      if (_points.length >= 2) {
        final a = _points[_points.length - 2].point;
        final b = _points.last.point;
        if ((b - a).distance > 6.0) {
          try {
            widget.isDrawingNotifier?.value = true;
          } catch (_) {}
        }
      }

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
    return Listener(
      onPointerDown: (ev) {
        // determine local X and whether it is in the side margins
        final rb = context.findRenderObject() as RenderBox?;
        if (rb != null && rb.hasSize) {
          final local = rb.globalToLocal(ev.position);
          final w = rb.size.width;
          final inMargin = local.dx <= _sideScrollMargin || local.dx >= (w - _sideScrollMargin);
          if (_startInSideMargin != inMargin) {
            setState(() {
              _startInSideMargin = inMargin;
            });
          }
        }
      },
      onPointerUp: (_) {
        if (_startInSideMargin) {
          setState(() {
            _startInSideMargin = false;
          });
        }
      },
      onPointerCancel: (_) {
        if (_startInSideMargin) {
          setState(() {
            _startInSideMargin = false;
          });
        }
      },
      child: GestureDetector(
        // Only attach pan handlers when the pointer didn't start in side margins
        onPanStart: _startInSideMargin ? null : (d) => _handlePanStart(d.globalPosition),
        onPanUpdate: _startInSideMargin ? null : (details) => _handlePanUpdate(details.globalPosition),
        onPanEnd: _startInSideMargin ? null : (_) => _handlePanEnd(),
        onPanCancel: _startInSideMargin ? null : () => _handlePanEnd(),
        child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                    builder: (context, isDrawing, child) {
                      return SingleChildScrollView(
                        physics: (isDrawing || !_startInSideMargin)
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: widget.leftItems.length > 3
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: widget.leftItems.map((item) {
                                return GestureDetector(
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
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 12),
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
                      );
                    },
                  );
                }),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                    builder: (context, isDrawing, child) {
                      return SingleChildScrollView(
                        physics: (isDrawing || !_startInSideMargin)
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: widget.rightItems.length > 3
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: widget.rightItems.map((item) {
                                return GestureDetector(
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
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
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
                    color: Colors.orange.withOpacity(0.18),
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
      final combinedAlpha =
          (220 * alphaFactor * (1 - fade)).clamp(0, 255).toInt();
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
