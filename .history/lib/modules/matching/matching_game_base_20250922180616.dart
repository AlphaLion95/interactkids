import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    leftItems = widget.mode.pairs.map((p) => p.left).toList()..shuffle();
    rightItems = widget.mode.pairs.map((p) => p.right).toList()..shuffle();
    matches = {};
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
      appBar: AppBar(title: Text(widget.title)),
      body: completed
          ? Center(child: Text('Great job! All pairs matched!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final item in leftItems)
                          GestureDetector(
                            onTap: () => _onLeftTap(item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedLeft == item ? Colors.orange : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: widget.mode.buildLeftItem(context, item),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final item in rightItems)
                          GestureDetector(
                            onTap: () => _onRightTap(item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedRight == item ? Colors.orange : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: widget.mode.buildRightItem(context, item),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
