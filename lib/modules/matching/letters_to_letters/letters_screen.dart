import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'letters_mode.dart';

// A small animated pill-like toggle used in the AppBar to switch modes.
class PillToggleButton extends StatefulWidget {
  final bool showingLetters;
  final VoidCallback onToggle;
  const PillToggleButton(
      {required this.showingLetters, required this.onToggle, super.key});

  @override
  State<PillToggleButton> createState() => _PillToggleButtonState();
}

class _PillToggleButtonState extends State<PillToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLetters = widget.showingLetters;
    return GestureDetector(
      onTapDown: (_) => _ctl.forward(),
      onTapUp: (_) {
        _ctl.reverse();
        widget.onToggle();
      },
      onTapCancel: () => _ctl.reverse(),
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_ctl.value);
          final elevation = 6.0 - (4.0 * t);
          final scale = 1.0 - (0.03 * t);
          return Transform.scale(
            scale: scale,
            child: Material(
              elevation: elevation,
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: isLetters
                        ? [Colors.blue.shade400, Colors.blue.shade300]
                        : [Colors.deepOrange.shade400, Colors.orange.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(24),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: const Text('A',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isLetters ? 'Letters' : 'Numbers',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MatchingLettersScreen extends StatefulWidget {
  const MatchingLettersScreen({super.key});

  @override
  State<MatchingLettersScreen> createState() => _MatchingLettersScreenState();
}

class _MatchingLettersScreenState extends State<MatchingLettersScreen> {
  bool _showingLetters = true;

  List<MatchingPair> _letterPairs() => List.generate(26, (i) {
        final upper = String.fromCharCode(65 + i);
        final lower = String.fromCharCode(97 + i);
        return MatchingPair(left: upper, right: lower);
      });

  List<MatchingPair> _numberPairs() {
    // Create numeric pairs 1..100. Left shows ordered digits, right shows the
    // matching digits (MatchingGameBase will randomize the right column).
    return List.generate(
        100, (i) => MatchingPair(left: '${i + 1}', right: '${i + 1}'));
  }

  @override
  void initState() {
    super.initState();
    // Enter immersive mode to reduce accidental edge taps while playing.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Back navigation handled by GameExitGuard

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final pillMaxWidth = screenW * 0.45;
    // Shift the pill to the right by a small responsive amount (12% of
    // screen width) but clamp it so very small screens don't break layout.
    final extraShift = (screenW * 0.18).clamp(8.0, 72.0);
    // pairs are provided by helper methods depending on selected mode

    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.blue.shade300,
              child: Row(
                children: [
                  BackButton(color: Colors.white),
                  const SizedBox(width: 6),
                  // Put the Match label and pill into an Expanded sub-row so they
                  // share the available space and can ellipsize/contract safely.
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Label shows fully when possible; Spacer pushes the pill
                        // toward the right without stealing the label's intrinsic
                        // width. We keep a small right-gap (extraShift) so the
                        // pill isn't flush with the edge.
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            _showingLetters ? 'Match Letters' : 'Match Numbers',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(width: extraShift),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: pillMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: PillToggleButton(
                              showingLetters: !_showingLetters,
                              onToggle: () {
                                setState(() {
                                  _showingLetters = !_showingLetters;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBubblesBackground()),
            MatchingGameBase(
              mode: _showingLetters
                  ? MatchingLettersMode(_letterPairs())
                  : MatchingNumbersMode(_numberPairs()),
              title: '',
            ),
          ],
        ),
      ),
    );
  }
}
