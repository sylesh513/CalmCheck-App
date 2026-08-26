/// PANIC-02 — the breathing pacer. The most important screen in the app.
///
/// Its job is to pace a person's breath without them having to read or think.
/// The orb's expansion *is* the instruction; the word is a fallback for people
/// who need it. Nothing else on screen moves.
///
/// No navigation chrome, no back button, no status indicators, no badges, no
/// progress bars, no cycle counters, and no monetization surface of any kind.
/// A progress bar is a thing to watch; a cycle counter is a thing to fail at.
///
/// Screen-reader focus order: the orb (one label carrying the current phase),
/// then "Breathing isn't helping", then "I'm done".
library;

import 'package:flutter/material.dart';

import '../../design/breath.dart';
import '../../routes.dart';
import '../../services/voice.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import 'panic_exits.dart';
import '../../services/keep_awake.dart';

class PacerArgs {
  const PacerArgs({this.cadence, this.title, this.forceReducedMotion = false});

  /// Null means "use the person's saved cadence".
  final BreathCadence? cadence;
  final String? title;

  /// Forces the reduced-motion treatment regardless of the setting. Used by the
  /// design reference.
  final bool forceReducedMotion;
}

class PanicPacerScreen extends StatefulWidget {
  const PanicPacerScreen({super.key, this.args = const PacerArgs()});

  final PacerArgs args;

  @override
  State<PanicPacerScreen> createState() => _PanicPacerScreenState();
}

class _PanicPacerScreenState extends State<PanicPacerScreen>
    with KeepAwake<PanicPacerScreen> {
  late final bool _showHelper;

  @override
  void initState() {
    super.initState();
    // The first-cycle helper appears once, ever, then never again.
    final app = context.appRead;
    _showHelper = !app.pacerHelperSeen;
    if (_showHelper) app.markPacerHelperSeen();
    CcVoice.instance.enabled = app.guideVoice;
  }

  @override
  void dispose() {
    CcVoice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final reduced =
        widget.args.forceReducedMotion ||
        MediaQuery.disableAnimationsOf(context) ||
        app.reduceMotion;

    return AcuteScaffold(
      onSystemBack: () =>
          Navigator.of(context).pushReplacementNamed(Routes.panicCheckIn),
      child: AcuteScreen(
        children: [
          // An empty leading child so the light lands on the optical centre of
          // the screen rather than at the top of it.
          const SizedBox.shrink(),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: CcSpace.xl,
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: SizedBox(
                  height: acuteOrbHeight(context),
                  child: BreathOrb(
                    cadence: widget.args.cadence ?? app.cadence,
                    reducedMotion: reduced,
                    // Haptics stay on under reduced motion — they are how the
                    // pacing survives when the movement stops.
                    haptics: app.vibration,
                    voice: app.guideVoice,
                    verticalCentre: 0.5,
                  ),
                ),
              ),
              if (_showHelper)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    "Follow the circle. You don't need to look at the screen — "
                    "you'll feel it.",
                    textAlign: TextAlign.center,
                    style: context.ccText.bodyLarge!.copyWith(
                      color: context.cc.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
          PanicExits(
            // Somebody breathing through an attack should have a person to
            // reach without hunting for one. A personal contact wins; a care
            // card contact is the fallback.
            showCareFallback: true,
            // Breath focus increases anxiety for some people. That is real and
            // documented, and the app must not trap them.
            alternative: "Breathing isn't helping",
            onAlternative: () => Navigator.of(
              context,
            ).pushReplacementNamed(Routes.panicGrounding),
            onDone: () =>
                Navigator.of(context).pushReplacementNamed(Routes.panicCheckIn),
          ),
        ],
      ),
    );
  }
}
