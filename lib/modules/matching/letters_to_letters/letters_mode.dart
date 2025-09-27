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
  Widget buildRightItem(BuildContext context, dynamic item) {
    return _letterTile(item as String, isUpper: false);
  }

  Widget _letterTile(String letter, {required bool isUpper}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isUpper ? Colors.blue.shade200 : Colors.pink.shade200,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: (isUpper ? Colors.blue : Colors.pink)
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
  MatchingNumbersMode(List<MatchingPair> pairs) : super(pairs);

  @override
  bool get shuffleLeft => false;

  @override
  String get progressKey => 'matching_numbers_progress';

  @override
  Widget buildLeftItem(BuildContext context, dynamic item) {
    // Left side shows the numeric digits
    final s = item.toString();
    return _numberTile(s, isLeft: true);
  }

  @override
  Widget buildRightItem(BuildContext context, dynamic item) {
    // Right side shows the spelled-out word
    final s = item.toString();
    return _numberTile(s, isLeft: false);
  }

  Widget _numberTile(String label, {required bool isLeft}) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isLeft ? Colors.green.shade300 : Colors.orange.shade300,
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
