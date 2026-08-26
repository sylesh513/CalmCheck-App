/// Keeping the screen alive while an exercise is running.
///
/// A breathing session can run for four to eleven minutes with no touches at
/// all — that is the point of it. Without this the phone hits its display
/// timeout and locks partway through, which is the worst possible moment for
/// the screen to die.
///
/// The lock is released the moment the screen is left, so nothing here can
/// leave a phone awake in someone's pocket.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Mixin for a [State] that should hold the screen on for as long as it is
/// mounted. Failures are swallowed: a phone that refuses the request is not a
/// reason to interrupt an exercise.
mixin KeepAwake<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _set(true);
  }

  @override
  void dispose() {
    _set(false);
    super.dispose();
  }

  static void _set(bool on) {
    // `toggle` is asynchronous, so a synchronous try/catch would not see the
    // failure — it escapes as an unhandled rejection instead, which is what a
    // test host (no plugin registered) produces. Swallow it on the future.
    unawaited(
      WakelockPlus.toggle(enable: on).catchError((Object _) {
        // Not worth surfacing; the exercise still runs.
      }),
    );
  }
}
