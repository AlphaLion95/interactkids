import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';

class MatchingLettersMode extends MatchingGameMode {
  final String progressSuffix;

  /// progressSuffix allows separate progress buckets for variants
  /// like '_all', '_vowels', '_consonants'. Defaults to empty.
  MatchingLettersMode(List<MatchingPair> pairs, {this.progressSuffix = ''})
      : super(pairs);

  @override
  bool get shuffleLeft => false;

  @override
  String get progressKey => 'matching_letters_progress$progressSuffix';
  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    return _letterTile(item as String, isUpper: true);
  }

  @override
  Widget? buildSelectedLeftItem(BuildContext context, dynamic item) {
    return _letterTile(item as String, isUpper: true, selected: true);
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    return _letterTile(item as String, isUpper: false);
  }

  @override
  Widget? buildSelectedRightItem(BuildContext context, dynamic item) {
    return _letterTile(item as String, isUpper: false, selected: true);
  }

  Widget _letterTile(String letter,
          {required bool isUpper, bool selected = false}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: selected
              ? (isUpper
                  ? Colors.deepOrange.shade400
                  : Colors.deepOrange.shade200)
              : (isUpper ? Colors.blue.shade200 : Colors.pink.shade200),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: (selected
                      ? Colors.deepOrange
                      : (isUpper ? Colors.blue : Colors.pink))
                  .withAlpha((0.25 * 255).round()),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
        ),
      );
}

class MatchingNumbersMode extends MatchingGameMode {
  final String progressSuffix;

  /// progressSuffix allows separate progress buckets for variants
  /// like '_all', '_even', '_odd'. Defaults to empty.
  MatchingNumbersMode(List<MatchingPair> pairs, {this.progressSuffix = ''})
      : super(pairs);

  @override
  bool get shuffleLeft => false;

  @override
  String get progressKey => 'matching_numbers_progress$progressSuffix';

  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    // Left side shows the numeric digits
    final s = item.toString();
    return _numberTile(s, isLeft: true);
  }

  @override
  Widget? buildSelectedLeftItem(BuildContext context, dynamic item) {
    final s = item.toString();
    return _numberTile(s, isLeft: true, selected: true);
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    // Right side shows the spelled-out word
    final s = item.toString();
    return _numberTile(s, isLeft: false);
  }

  @override
  Widget? buildSelectedRightItem(BuildContext context, dynamic item) {
    final s = item.toString();
    return _numberTile(s, isLeft: false, selected: true);
  }

  Widget _numberTile(String label,
          {required bool isLeft, bool selected = false}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: selected
              ? Colors.deepOrange.shade300
              : (isLeft ? Colors.green.shade300 : Colors.orange.shade300),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: (isLeft ? Colors.green : Colors.orange)
                  .withAlpha((0.25 * 255).round()),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      );
}
