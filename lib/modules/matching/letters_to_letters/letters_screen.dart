import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'letters_mode.dart';

enum _LetterFilter { all, vowels, consonants }

enum _NumberFilter { all, even, odd }

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
                      width: 32,
                      height: 32,
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
                        child: Text(widget.showingLetters ? 'A' : '#',
                            style: const TextStyle(
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
  // Filter for letters: all, vowels or consonants
  _LetterFilter _letterFilter = _LetterFilter.all;
  // Filter for numbers: all, even or odd
  _NumberFilter _numberFilter = _NumberFilter.all;

  List<MatchingPair> _letterPairs() {
    const vowels = {'A', 'E', 'I', 'O', 'U'};
    final all = List.generate(26, (i) {
      final upper = String.fromCharCode(65 + i);
      final lower = String.fromCharCode(97 + i);
      return MatchingPair(left: upper, right: lower);
    });
    if (_letterFilter == _LetterFilter.all) return all;
    if (_letterFilter == _LetterFilter.vowels) {
      return all.where((p) => vowels.contains(p.left)).toList();
    }
    // consonants
    return all.where((p) => !vowels.contains(p.left)).toList();
  }

  List<MatchingPair> _numberPairs() {
    // Create numeric pairs based on the selected number filter.
    // Left shows ordered digits, right shows the matching digits
    // (MatchingGameBase will randomize the right column).
    final all = List.generate(
        100, (i) => MatchingPair(left: '${i + 1}', right: '${i + 1}'));
    switch (_numberFilter) {
      case _NumberFilter.even:
        return all.where((p) => int.tryParse(p.left)! % 2 == 0).toList();
      case _NumberFilter.odd:
        return all.where((p) => int.tryParse(p.left)! % 2 == 1).toList();
      case _NumberFilter.all:
        return all;
    }
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
    // Responsive screen width used to size the filter area.
    // pairs are provided by helper methods depending on selected mode

    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.blue.shade300,
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  const SizedBox(width: 4),
                  // Put the Match label and pill into an Expanded sub-row so they
                  // share the available space and can ellipsize/contract safely.
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // When showing letters, present Vowels/Consonants; when
                        // showing numbers, present Even/Odd. Keep the primary
                        // 'All' button in a small fixed slot so it's always
                        // visible. The variable buttons are scrollable on the
                        // left to avoid any right-side overflow hiding the
                        // pill toggle.
                        Flexible(
                          fit: FlexFit.loose,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: _showingLetters
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildFilterButton(context,
                                            _LetterFilter.vowels, 'Vowels'),
                                        const SizedBox(width: 2),
                                        _buildFilterButton(
                                            context,
                                            _LetterFilter.consonants,
                                            'Consonants'),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildNumberFilterButton(context,
                                            _NumberFilter.even, 'Even'),
                                        const SizedBox(width: 6),
                                        _buildNumberFilterButton(
                                            context, _NumberFilter.odd, 'Odd'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Small fixed slot for the 'All' button so it's always
                        // visible next to the pill toggle.
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _showingLetters
                              ? _buildFilterButton(
                                  context, _LetterFilter.all, 'All')
                              : _buildNumberFilterButton(
                                  context, _NumberFilter.all, 'All'),
                        ),
                        // Fixed area for the pill toggle: slightly reduce the
                        // minimum width to allow more space for the left
                        // scrollable filter buttons (prevents consonants from
                        // being clipped on small screens).
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 64),
                            child: Align(
                              alignment: Alignment.centerRight,
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
                  ? MatchingLettersMode(
                      _letterPairs(),
                      progressSuffix: _letterFilter == _LetterFilter.all
                          ? '_all'
                          : _letterFilter == _LetterFilter.vowels
                              ? '_vowels'
                              : '_consonants',
                    )
                  : MatchingNumbersMode(_numberPairs(),
                      progressSuffix: _numberFilter == _NumberFilter.all
                          ? '_all'
                          : _numberFilter == _NumberFilter.even
                              ? '_even'
                              : '_odd'),
              title: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      BuildContext context, _LetterFilter f, String label) {
    final selected = _letterFilter == f;
    final theme = Theme.of(context);
    // Choose colors that stay readable on the AppBar background.
    final bgSelected = Colors.white; // solid white for selected
    final fgSelected = theme.primaryColor; // primary color for selected text
    final fgUnselected = Colors.white; // keep unselected text white
    final borderColor = Colors.white.withOpacity(0.18);

    return Material(
      color: selected ? bgSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _letterFilter = f;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? fgSelected : fgUnselected,
                  fontWeight: FontWeight.w700,
                  shadows: selected
                      ? null
                      : [
                          Shadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 1),
                              blurRadius: 1)
                        ])),
        ),
      ),
    );
  }

  Widget _buildNumberFilterButton(
      BuildContext context, _NumberFilter f, String label) {
    final selected = _numberFilter == f;
    final theme = Theme.of(context);
    final bgSelected = Colors.white;
    final fgSelected = theme.primaryColor;
    final fgUnselected = Colors.white;
    final borderColor = Colors.white.withOpacity(0.18);

    return Material(
      color: selected ? bgSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _numberFilter = f;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? fgSelected : fgUnselected,
                  fontWeight: FontWeight.w700,
                  shadows: selected
                      ? null
                      : [
                          Shadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 1),
                              blurRadius: 1)
                        ])),
        ),
      ),
    );
  }
}
