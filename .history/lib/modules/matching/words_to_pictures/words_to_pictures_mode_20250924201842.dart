import 'package:flutter/material.dart';
import '../matching_models.dart';

class MatchingWordsToPicturesMode extends MatchingGameMode {
  MatchingWordsToPicturesMode(List<MatchingPair> pairs) : super(pairs);
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return Container(
        padding: const EdgeInsets.all(8), child: Text(item as String));
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(item as String, width: 64, height: 64));
  }
}
