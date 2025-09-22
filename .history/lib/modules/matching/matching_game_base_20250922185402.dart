import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'matching_models.dart';

/// Base widget for any matching game type.
class MatchingGameBase extends StatefulWidget {
  final MatchingGameMode mode;
  final String title;
  const MatchingGameBase({required this.mode, required this.title, super.key});

  @override
  State<MatchingGameBase> createState() => _MatchingGameBaseState();
}

class _MatchingGameBaseState extends State<MatchingGameBase> {
  late List<dynamic> leftItems;
  late List<dynamic> rightItems;
  late Map<dynamic, dynamic> matches; // left -> right
  dynamic selectedLeft;
  dynamic selectedRight;
  bool completed = false;

  static const _progressKey = 'matching_letters_progress';

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
      }
    }
    selectedLeft = null;
    selectedRight = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.title.isNotEmpty ? AppBar(title: Text(widget.title)) : null,
      body: completed
          ? Center(
              child: Text('Great job! All pairs matched!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))
          : Column(
              children: [
                const SizedBox(height: 12),
                _MatchedTray(matches: matches, mode: widget.mode),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
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
                                        borderRadius: BorderRadius.circular(12),
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
                                        borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MatchedTray extends StatelessWidget {
  final Map<dynamic, dynamic> matches;
  final MatchingGameMode mode;
  const _MatchedTray({required this.matches, required this.mode});
  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return SizedBox(
        height: 64,
        child: Center(
          child: Text('Matched Pairs will appear here!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade400,
                fontFamily: 'Nunito',
              )),
        ),
      );
    }
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
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
    if (mode is MatchingLettersMode && left is String && right is String) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.10),
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
