/// EX-01 — the exercise library.
///
/// The two free exercises are never locked, in any state, for any reason. The
/// locked treatment on the rest is quiet: a dashed edge and a plain line of
/// text. No strikethrough, no crown, no "UPGRADE".
library;

import 'package:flutter/material.dart';

import '../../data/exercises.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final pro = app.isPro;

    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Exercises'),
              CcSub(
                pro
                    ? 'Everything is unlocked. Start whichever one suits the '
                          'moment.'
                    : 'Breathing and grounding are free, always.',
              ),
            ],
          ),
          CcStack(
            gap: CcGap.md,
            children: [
              for (final ex in exercises)
                ExerciseCardTile(
                  name: ex.name,
                  duration: ex.duration,
                  purpose: ex.purpose,
                  state: ex.isFree
                      ? ExerciseCardState.free
                      : pro
                      ? ExerciseCardState.unlocked
                      : ExerciseCardState.locked,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(Routes.exerciseDetail, arguments: ex.id),
                ),
            ],
          ),
          if (!pro)
            CcStack(
              gap: CcGap.lg,
              children: [
                const CcRule(),
                const CcBody(lockedString),
                CcButton(
                  'See what Pro includes',
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.lg,
                  fullWidth: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(Routes.paywall, arguments: 'exercise-library'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
