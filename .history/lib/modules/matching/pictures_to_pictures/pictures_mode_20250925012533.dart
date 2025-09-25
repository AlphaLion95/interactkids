import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';

class MatchingPicturesMode extends MatchingGameMode {
  final Map<String, Widget>? visuals;
  MatchingPicturesMode(List<MatchingPair> pairs, [this.visuals]) : super(pairs);

  @override
  String get progressKey => 'matching_pictures_progress';

  @override
  bool get showMatchedTray => false;

  @override
  bool get supportsDragMatch => true;

  @override
  Widget buildLeftItem(BuildContext context, dynamic item) => _resolveTile(item);

  @override
  Widget buildRightItem(BuildContext context, dynamic item) => _resolveTile(item);

  Widget _resolveTile(dynamic item) {
    if (item is Widget) {
      return Container(padding: const EdgeInsets.all(8), child: item);
    }
    if (item is String) {
      if (visuals != null && visuals!.containsKey(item)) {
        return Container(padding: const EdgeInsets.all(8), child: visuals![item]!);
      }
      return Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(item, width: 64, height: 64),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
    );
  }
}
