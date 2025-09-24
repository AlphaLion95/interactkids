import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:interactkids/widgets/game_exit_guard.dart';

/// Helper to push a game screen route while disabling iOS back-swipe.
/// Uses a platform-specific route that disables interactive pop on iOS.
Future<T?> pushGameScreen<T>(BuildContext context, Widget page) {
  // Wrap the page in GameExitGuard so gameplay screens get consistent back-guard
  final guarded = GameExitGuard(child: page);
  return Navigator.of(context).push<T>(
    MaterialPageRoute(builder: (_) => guarded),
  );
}
