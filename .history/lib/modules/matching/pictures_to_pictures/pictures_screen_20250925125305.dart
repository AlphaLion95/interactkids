import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';
import 'package:interactkids/widgets/animated_bubbles_background.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_game_base.dart';
import 'package:interactkids/modules/matching/letters_to_letters/matching_models.dart';
import 'pictures_mode.dart';

class MatchingPicturesScreen extends StatefulWidget {
  const MatchingPicturesScreen({super.key});
  @override
  State<MatchingPicturesScreen> createState() => _MatchingPicturesScreenState();
}

class _MatchingPicturesScreenState extends State<MatchingPicturesScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;
  final GlobalKey<MatchingGameBaseState> _gameKey =
      GlobalKey<MatchingGameBaseState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    return GameExitGuard(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6FF),
        appBar: AppBar(
          leading: _selectedCategory != null
              ? BackButton(onPressed: () => setState(() {
                  _selectedCategory = null;
                  _selectedDifficulty = null;
                }))
              : null,
          title: const Text('Match the Pictures', style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: Colors.green.shade300,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Undo last match',
              icon: const Icon(Icons.undo),
              onPressed: () async {
                final messenger = ScaffoldMessenger.maybeOf(context);
                final undone = await _gameKey.currentState?.undoLastMatch();
                if (!mounted) return;
                if (undone == true) {
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Undid last match')));
                } else {
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Nothing to undo')));
                }
              },
            ),
            IconButton(
              tooltip: 'Clear current stroke',
              icon: const Icon(Icons.brush),
              onPressed: () {
                _gameKey.currentState?.clearStroke();
              },
            ),
            IconButton(
              tooltip: 'Reset progress',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final messenger = ScaffoldMessenger.maybeOf(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset progress?'),
                    content: const Text(
                        'This will clear your progress for this game mode.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (!mounted) return;
                if (confirmed == true) {
                  await _gameKey.currentState?.resetGame();
                  if (!mounted) return;
                  messenger?.showSnackBar(
                      const SnackBar(content: Text('Progress reset')));
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedBubblesBackground()),
            // If no category selected, show big animated category buttons
            if (_selectedCategory == null)
              Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: categories.map((cat) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = cat;
                        _selectedDifficulty = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 12),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category, size: 48, color: Colors.green.shade400),
                            const SizedBox(height: 8),
                            Text(_displayLabel(cat),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 12),
                  // If difficulty not selected yet, show large level buttons
                  if (_selectedDifficulty == null)
                    SizedBox(
                      height: 180,
                      child: Center(
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: ['easy', 'medium', 'hard', 'all'].map((level) {
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDifficulty = level;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: _selectedDifficulty == level
                                      ? Colors.green.shade400
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 12),
                                  ],
                                ),
                                child: Center(
                                  child: Text(level.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedDifficulty == level
                                              ? Colors.white
                                              : Colors.black)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: MatchingGameBase(
                        key: _gameKey,
                        mode: MatchingPicturesMode(pairs, visuals),
                        title: '',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 12),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.category, size: 48, color: Colors.green.shade400),
                                const SizedBox(height: 8),
                                Text(_displayLabel(cat),
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      // If difficulty not selected yet, show large level buttons
                      if (_selectedDifficulty == null)
                        SizedBox(
                          height: 180,
                          child: Center(
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: ['easy', 'medium', 'hard', 'all'].map((level) {
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedDifficulty = level;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: _selectedDifficulty == level
                                          ? Colors.green.shade400
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black12, blurRadius: 12),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(level.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedDifficulty == level
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: MatchingGameBase(
                            key: _gameKey,
                            mode: MatchingPicturesMode(pairs, visuals),
                            title: '',
                          ),
                        ),
                    ],
                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                // If difficulty not selected yet, show level buttons
                if (_selectedDifficulty == null)
                  SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final level in ['easy', 'medium', 'hard', 'all'])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedDifficulty == level
                                    ? Colors.green.shade400
                                    : Colors.white,
                                foregroundColor: _selectedDifficulty == level
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onPressed: () => setState(() {
                                _selectedDifficulty = level;
                              }),
                              child: Text(level.toUpperCase()),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: MatchingGameBase(
                      key: _gameKey,
                      mode: MatchingPicturesMode(pairs, visuals),
                      title: '',
                    ),
                  ),
              ],
            ),
            // duplicate floating reset removed; AppBar already provides reset
          ],
        ),
      ),
    );
  }
}
