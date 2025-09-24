import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A simple wrapper that prevents accidental back navigation while a game is active.
///
/// It shows a pause/confirm dialog when a back attempt is detected. It also
/// enters immersive fullscreen while mounted and restores UI on dispose.
class GameExitGuard extends StatefulWidget {
  final Widget child;
  final String pauseTitle;
  final String pauseMessage;

  const GameExitGuard({
    Key? key,
    required this.child,
    this.pauseTitle = 'Pause',
    this.pauseMessage = 'Do you want to quit the game?',
  }) : super(key: key);

  @override
  State<GameExitGuard> createState() => _GameExitGuardState();
}

class _GameExitGuardState extends State<GameExitGuard> {
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isPlaying) return true;
    setState(() => _isPlaying = false);
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.pauseTitle),
        content: Text(widget.pauseMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Resume')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quit')),
        ],
      ),
    );
    if (leave == true) return true;
    setState(() => _isPlaying = true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // PopScope is recommended, but not available on all SDK versions in
    // this workspace. Use WillPopScope and ignore the deprecation lint
    // to preserve runtime behavior across SDKs.
    // ignore: deprecated_member_use
    return WillPopScope(onWillPop: _onWillPop, child: widget.child);
  }
}
