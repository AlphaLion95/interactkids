import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Helper to push a game screen route while disabling iOS back-swipe.
/// Uses a platform-specific route that disables interactive pop on iOS.
Future<T?> pushGameScreen<T>(BuildContext context, Widget page) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS) {
    return Navigator.of(context).push<T>(
      CupertinoPageRoute<T>(
        builder: (_) => page,
        // disable the swipe back gesture on iOS
        gestureEnabled: false,
      ),
    );
  }
  return Navigator.of(context).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
}
