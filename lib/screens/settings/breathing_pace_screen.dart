/// The Pro breathing pace, reached from settings. The same control as EX-02,
/// with the orb running the chosen cadence so the change can be felt before it
/// is kept.
library;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../exercises/exercise_detail_screen.dart' show CadenceControl;

class BreathingPaceScreen extends StatelessWidget {
  const BreathingPaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Breathing pace'),
              const CcSub(
                'Set your own inhale and exhale lengths. Every exercise that '
                'paces your breath will use them.',
              ),
            ],
          ),
          SizedBox(
            height: 220,
            child: BreathOrb(
              cadence: app.cadence,
              reducedMotion: app.reduceMotion,
              haptics: app.vibration,
              verticalCentre: 0.5,
            ),
          ),
          const CcRule(),
          const CadenceControl(showLabel: false),
        ],
      ),
    );
  }
}
