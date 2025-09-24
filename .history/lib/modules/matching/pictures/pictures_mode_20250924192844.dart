import 'package:flutter/material.dart';
import '../matching_models.dart';

class MatchingPicturesMode extends MatchingGameMode {
  MatchingPicturesMode(List<MatchingPair> pairs) : super(pairs);
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return _imageTile(item as String);
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return _imageTile(item as String);
  }

  Widget _imageTile(String assetPath) => Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(assetPath, width: 64, height: 64),
      );
