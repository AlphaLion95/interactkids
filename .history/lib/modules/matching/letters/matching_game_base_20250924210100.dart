// Forwarding stub to canonical implementation in letters_to_letters
export 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';

class _MatchedTray extends StatelessWidget {
  final Map<dynamic, dynamic> matches;
  final MatchingGameMode mode;
  final VoidCallback? onReset;
  const _MatchedTray({required this.matches, required this.mode, this.onReset});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.13),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text('Matched Pairs will appear here!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          fontFamily: 'Nunito',
                        )),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final left = matches.keys.elementAt(i);
                      final right = matches[left];
                      return _MatchedPairDisplay(
                        left: left,
                        right: right,
                        mode: mode,
                      );
                    },
                  ),
          ),
          if (onReset != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: onReset,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.refresh, color: Colors.blue, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchedPairDisplay extends StatelessWidget {
  final dynamic left;
  final dynamic right;
  final MatchingGameMode mode;
  const _MatchedPairDisplay(
      {required this.left, required this.right, required this.mode});
  @override
  Widget build(BuildContext context) {
    // For MatchingLettersMode, show compact Aa, Bb, etc.
    if (left is String &&
        right is String &&
        left.length == 1 &&
        right.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              left + right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      );
    }
    // Fallback for other modes
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mode.buildLeftItem(context, left),
        const SizedBox(width: 8),
        const Icon(Icons.check_circle, color: Colors.green, size: 28),
        const SizedBox(width: 8),
        mode.buildRightItem(context, right),
      ],
    );
  }
}
