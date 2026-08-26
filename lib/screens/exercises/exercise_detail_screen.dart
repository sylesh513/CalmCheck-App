/// EX-02 — exercise detail, and the Pro cadence control.
///
/// The constraint — the exhale is never shorter than the inhale — is shown, not
/// silently enforced: the attempt is clamped and the reason is printed in
/// words.
library;

import 'package:flutter/material.dart';

import '../../data/exercises.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../panic/panic_pacer_screen.dart';
import 'exercise_steps_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final ex = exerciseById(exerciseId);
    final locked = !ex.isFree && !app.isPro;

    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Exercise'),
              CcHeadline(ex.name),
              CcSub(ex.purpose),
              const CcRule(),
              CcStack(
                gap: CcGap.xs,
                children: [FieldLabel('Length'), CcBody(ex.duration)],
              ),
              if (ex.steps.isNotEmpty && !locked) ...[
                const CcRule(),
                CcStack(
                  gap: CcGap.sm,
                  children: [
                    FieldLabel('Steps'),
                    for (final step in ex.steps) CcBody('· $step'),
                  ],
                ),
              ],
              if (!locked &&
                  app.isPro &&
                  ex.kind == ExerciseKind.pacedBreath) ...[
                const CcRule(),
                const CadenceControl(),
              ],
              if (locked) ...[const CcRule(), const CcBody(lockedString)],
            ],
          ),
          if (locked)
            CcStack(
              gap: CcGap.sm,
              children: [
                CcButton(
                  'See what Pro includes',
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(Routes.paywall, arguments: 'locked-exercise'),
                ),
                CcButton(
                  'Use paced breathing instead',
                  variant: CcButtonVariant.quiet,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    Routes.exerciseDetail,
                    arguments: 'paced',
                  ),
                ),
              ],
            )
          else
            CcButton(
              'Start',
              size: CcButtonSize.lg,
              fullWidth: true,
              onPressed: () => _start(context, ex, app),
            ),
        ],
      ),
    );
  }

  void _start(BuildContext context, Exercise ex, AppState app) {
    switch (ex.kind) {
      case ExerciseKind.pacedBreath:
        Navigator.of(context).pushNamed(
          Routes.panicPacer,
          arguments: PacerArgs(
            // "Paced breathing" honours the person's own cadence; the named
            // patterns keep the shape that gives them their name.
            cadence: ex.id == 'paced' ? app.cadence : ex.cadence,
            title: ex.name,
          ),
        );
      case ExerciseKind.grounding:
        Navigator.of(context).pushNamed(Routes.panicGrounding);
      case ExerciseKind.coldWater:
      case ExerciseKind.muscleRelease:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExerciseStepsScreen(exercise: ex)),
        );
    }
  }
}

/// The Pro cadence control. Two adjustments, inhale and exhale, set
/// independently — with the floor made visible the moment someone hits it.
class CadenceControl extends StatelessWidget {
  const CadenceControl({super.key, this.showLabel = true});

  final bool showLabel;

  static const int _min = 2;
  static const int _max = 12;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cadence = app.cadence;
    final inhale = cadence.inhale.round();
    final exhale = cadence.exhale.round();
    final blocked = exhale <= inhale;

    return CcStack(
      gap: CcGap.md,
      children: [
        if (showLabel) FieldLabel('Cadence · Pro'),
        StepperRow(
          label: 'Inhale',
          value: inhale,
          min: _min,
          max: _max,
          onChanged: (next) {
            // Raising the inhale carries the exhale up with it rather than
            // silently producing an inverted breath.
            app.setCadence(
              cadence.copyWith(
                inhale: next.toDouble(),
                exhale: exhale < next ? next.toDouble() : exhale.toDouble(),
              ),
            );
          },
        ),
        StepperRow(
          label: 'Exhale',
          value: exhale,
          min: _min,
          max: _max,
          floor: inhale,
          floorNote: 'Floor · matches the inhale',
          onChanged: (next) =>
              app.setCadence(cadence.copyWith(exhale: next.toDouble())),
        ),
        CcBody(
          blocked
              ? "Exhale can't be shorter than the inhale. Held at "
                    '$exhale seconds.'
              : 'The exhale is never shorter than the inhale. That’s what '
                    'settles you.',
          muted: !blocked,
        ),
        CcCaption(
          '${inhale}s in · ${exhale}s out · '
          // The full cycle, not just inhale + exhale: hold and rest are part
          // of a breath, and leaving them out overstated the rate.
          '${cadence.breathsPerMinute.toStringAsFixed(1)} breaths a minute',
        ),
      ],
    );
  }
}
