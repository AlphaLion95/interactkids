import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';

class MatchingPicturesMode extends MatchingGameMode {
  final Map<String, Widget>? visuals;
  final double? _preferredCellSize;
  final String? _progressKeySuffix;
  MatchingPicturesMode(List<MatchingPair> pairs, [this.visuals, double? preferredCellSize, String? progressKeySuffix])
      : _preferredCellSize = preferredCellSize,
        _progressKeySuffix = progressKeySuffix,
        super(pairs);

  @override
  String get progressKey => 'matching_pictures_progress' +
      (_progressKeySuffix != null ? '_${_progressKeySuffix}' : '');

  @override
  double? get preferredCellSize => _preferredCellSize;

  @override
  bool get showMatchedTray => false;

  @override
  bool get supportsDragMatch => true;

  @override
  Widget buildLeftItem(BuildContext context, dynamic item) =>
      _resolveTile(item);

  @override
  Widget buildRightItem(BuildContext context, dynamic item) =>
      _resolveTile(item);

  Widget _resolveTile(dynamic item) {
    if (item is Widget) {
      return Container(padding: const EdgeInsets.all(8), child: item);
    }
    if (item is String) {
      if (visuals != null && visuals!.containsKey(item)) {
        return Container(
            padding: const EdgeInsets.all(8), child: visuals![item]!);
      }
      // If no visual is provided for this key, render a safe placeholder
      // instead of attempting to load an asset by the key name.
      return Container(
        padding: const EdgeInsets.all(8),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
            child:
                Icon(Icons.image_not_supported, size: 28, color: Colors.grey)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
    );
  }
}
