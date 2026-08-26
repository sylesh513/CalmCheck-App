import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/helplines.dart';
import 'services/errors.dart';
import 'services/haptics.dart';
import 'services/reminders.dart';
import 'services/voice.dart';
import 'state/app_state.dart';

Future<void> main() async {
  runGuarded(() {
    // Placeholder while the state loads. In practice this frame is never seen:
    // the load is a preferences read and a small file.
    return const _Boot();
  });
}

class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  AppState? _state;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    // Portrait only. This app is held one-handed, in the dark, by someone who
    // should not have to fight a rotation.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // The helpline dataset is a 24 KB bundled asset. Loading it before the
    // first frame means the crisis screen is never a moment behind the rest of
    // the app.
    final loaded = await Future.wait([
      AppState.load(),
      Helplines.instance.load(),
    ]);
    final state = loaded.first as AppState;

    // Then ask the network which country the phone is actually in. Slower than
    // the locale and more accurate, so it runs after the first answer is
    // already on screen.
    unawaited(state.refreshDetectedRegion());

    // These warm up alongside the first frame. Nothing about reaching the
    // panic action waits on any of them.
    unawaited(CcHaptics.instance.warmUp());
    unawaited(CcReminders.instance.warmUp());
    unawaited(
      CcVoice.instance.warmUp().then((_) {
        CcVoice.instance.enabled = state.guideVoice;
      }),
    );

    if (!mounted) return;
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) return const _Stock();
    return CalmCheckApp(state: state);
  }
}

/// The stock, so the launch screen hands over to the same colour rather than
/// flashing.
class _Stock extends StatelessWidget {
  const _Stock();

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF1B1A17) : const Color(0xFFF4EFE6),
      child: const SizedBox.expand(),
    );
  }
}
