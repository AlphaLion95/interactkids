import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/letters/matching_models.dart';

class MatchingWordsToWordsMode extends MatchingGameMode {
  MatchingWordsToWordsMode(List<MatchingPair> pairs) : super(pairs);
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return Container(
        padding: const EdgeInsets.all(8), child: Text(item as String));
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return Container(
        padding: const EdgeInsets.all(8), child: Text(item as String));
  }
}
