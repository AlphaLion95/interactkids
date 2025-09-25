import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'package:interactkids/modules/matching/pictures_to_pictures/pictures_match_area.dart';
import 'package:interactkids/widgets/celebration_overlay.dart';

/// Base widget for any matching game type.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;
  final String title;

  /// When false, the matched-pairs tray at the top is hidden.
  final bool showMatchedTray;
  const MatchingGameBase(
      {required this.mode,
      required this.title,
      // ...existing code...
                                                  _tapPulse[item] == true;
                                              final translateY = isSelected
                                                  ? _selectedLoopAnim.value
                                                  : (isPulsed
                                                      ? _bounceAnim.value
                                                      : 0.0);
                                              final scale =
                                                  isPulsed ? 1.06 : 1.0;
                                              return Transform.translate(
                                                offset: Offset(0, translateY),
                                                child: Transform.scale(
                                                  scale: scale,
                                                  child: Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? Colors.orange
                                                            : Colors
                                                                .transparent,
                                                                // Drag/draw helpers were extracted to
                                                                // lib/modules/matching/pictures_to_pictures/pictures_match_area.dart
                                                                // to keep matching modes modular.
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
                child: LayoutBuilder(builder: (context, constraints) {
                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        widget.isDrawingNotifier ?? ValueNotifier<bool>(false),
                    builder: (context, isDrawing, child) {
                      return SingleChildScrollView(
                        physics: isDrawing
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
                        physics: isDrawing
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
