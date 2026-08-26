/// PANIC-05 — the exit. The room coming back up.
///
/// Nobody is dumped from a dark, quiet screen straight onto a bright home
/// screen: the ground brightens frame by frame from the ACUTE stock to whatever
/// stock the person will land on, the light goes out on the way, and only then
/// does HOME arrive. If the system theme is CALM-light, the rise is longer.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/breath.dart';
import '../../design/motion.dart';
import '../../routes.dart';
import '../../services/voice.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class PanicRiseScreen extends StatefulWidget {
  const PanicRiseScreen({super.key});

  @override
  State<PanicRiseScreen> createState() => _PanicRiseScreenState();
}

class _PanicRiseScreenState extends State<PanicRiseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Color _target;
  late final bool _targetIsLight;

  @override
  void initState() {
    super.initState();
    CcVoice.instance.stop();

    final app = context.appRead;
    final systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    _targetIsLight = switch (app.themeChoice) {
      ThemeChoice.light => true,
      ThemeChoice.dark => false,
      ThemeChoice.system => !systemDark,
    };
    _target = _targetIsLight ? CcColors.stockLight : CcColors.stockDark;

    final reduced = app.reduceMotion;
    final base = _targetIsLight
        // A longer rise into the light: the eyes have been in the dark.
        ? CcMotion.lift * 1.25
        : CcMotion.lift;

    _controller =
        AnimationController(
          vsync: this,
          duration: CcMotion.reduce(base, reduced: reduced) == Duration.zero
              ? CcMotion.liftReduced
              : (reduced ? CcMotion.liftReduced : base),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(Routes.home, (route) => false);
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final ground = Color.lerp(CcColors.stockAcute, _target, t)!;
        // The light goes out before the room is fully back.
        final orbOpacity = (1 - (t / 0.62)).clamp(0.0, 1.0);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: _targetIsLight && t > 0.5
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: ground,
          ),
          child: Theme(
            data: acuteTheme,
            child: Scaffold(
              backgroundColor: ground,
              body: Center(
                child: Opacity(
                  opacity: orbOpacity,
                  child: const SizedBox(
                    height: 300,
                    child: IgnorePointer(
                      child: BreathOrb(
                        staticPhase: BreathPhase.rest,
                        showCue: false,
                        verticalCentre: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
