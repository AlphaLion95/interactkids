import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';

class MatchingWordsToWordsMode extends MatchingGameMode {
  MatchingWordsToWordsMode(List<MatchingPair> pairs) : super(pairs);
  @override
  String get progressKey => 'matching_words_to_words_progress';
  @override
  bool get showMatchedTray => false;
  @override
  bool get supportsDragMatch => true;
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
