import 'package:flutter/material.dart';
import 'package:interactkids/modules/matching/matching_models.dart';

class MatchingLettersMode extends MatchingGameMode {
  MatchingLettersMode(List<MatchingPair> pairs) : super(pairs);
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
              color: (isUpper ? Colors.blue : Colors.pink).withOpacity(0.25),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
              shadows: const [
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
