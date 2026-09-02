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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      // Portrait only. This app is held one-handed, in the dark, by someone
      // who should not have to fight a rotation.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // The helpline dataset is a 24 KB bundled asset. Loading it before the
      // first frame means the crisis screen is never a moment behind the rest
      // of the app.
      final loaded = await Future.wait([
        AppState.load(),
        Helplines.instance.load(),
      ]);
      final state = loaded.first as AppState;

      // Then ask the network which country the phone is actually in. Slower
      // than the locale and more accurate, so it runs after the first answer
      // is already on screen.
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
    } catch (error, stack) {
      // Boot must never end at a permanently blank screen. Whatever threw —
      // a platform channel, a corrupt store — is logged, and the person gets
      // a retry instead of a coloured box that answers nothing.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'boot'),
      );
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    unawaited(_start());
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state != null) return CalmCheckApp(state: state);
    if (_failed) return _BootFailed(onRetry: _retry);
    return const _Stock();
  }
}

/// Boot failed. Plain words and one thing to do about it — the same contract
/// as every other broken state in the app.
class _BootFailed extends StatelessWidget {
  const _BootFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final stock = dark ? const Color(0xFF1B1A17) : const Color(0xFFF4EFE6);
    final ink = dark ? const Color(0xFFF4EFE6) : const Color(0xFF1B1A17);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: stock,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "CalmCheck couldn't start.",
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Something on this phone stopped the app from loading. '
                'Nothing you saved is lost.',
                style: TextStyle(color: ink, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: ink, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Try again',
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
