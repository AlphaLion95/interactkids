import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/matching_models.dart';

class MatchingPicturesMode extends MatchingGameMode {
  MatchingPicturesMode(List<MatchingPair> pairs) : super(pairs);

  @override
  Widget buildLeftItem(BuildContext context, dynamic item) => _resolveTile(item);

  @override
  Widget buildRightItem(BuildContext context, dynamic item) => _resolveTile(item);

  Widget _resolveTile(dynamic item) {
    if (item is Widget) {
      return Container(padding: const EdgeInsets.all(8), child: item);
    }
    if (item is String) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(item, width: 64, height: 64),
      );
    }
    // Fallback: show a placeholder box for unknown item types
    return Container(
      padding: const EdgeInsets.all(8),
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
    );
  }
}
