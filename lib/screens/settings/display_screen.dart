/// SET-04 — text size and reduce motion, with a live preview.
///
/// Someone who needs 200% text should be able to confirm it works before
/// leaving the screen, so the sample below the control is real app type at the
/// size being chosen.
library;

import 'package:flutter/material.dart';

import '../../design/breath.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

const List<double> _steps = [1.0, 1.25, 1.5, 1.75, 2.0];

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final t = context.cc;

    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Text size and motion'),
              const CcSub(
                'Change it here and check it here. The sample below is real '
                'app type.',
              ),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              FieldLabel('Text size · ${(app.textScale * 100).round()}%'),
              Slider(
                value: app.textScale,
                min: 1.0,
                max: 2.0,
                divisions: 4,
                label: '${(app.textScale * 100).round()}%',
                onChanged: (v) => app.textScale = v,
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: CcSpace.sm,
                runSpacing: CcSpace.xs,
                children: [
                  for (final step in _steps)
                    Text(
                      '${(step * 100).round()}%',
                      style: context.ccText.labelSmall!.copyWith(
                        color: step == app.textScale ? t.ink : t.inkMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // The preview renders at the chosen scale even before the setting is
          // committed to the rest of the app, so nothing has to be imagined.
          Container(
            padding: const EdgeInsets.all(CcSpace.lg),
            decoration: BoxDecoration(
              color: t.stockRaised,
              borderRadius: t.cardBorderRadius,
              border: Border.all(color: t.rule, width: CcStructure.cardEdge),
            ),
            child: CcStack(
              gap: CcGap.sm,
              children: [
                FieldLabel('Preview'),
                const CcHeadline('Breathe out slowly.'),
                const CcBody(
                  'Follow the ring. Four seconds in, six seconds out. Nothing '
                  'else to do.',
                ),
                SizedBox(
                  height: 150,
                  child: BreathOrb(
                    showCue: true,
                    reducedMotion: app.reduceMotion,
                    verticalCentre: 0.5,
                    cadence: BreathCadence.standard,
                  ),
                ),
                CcCaption(
                  app.reduceMotion
                      ? 'Cue changes in place · the ring holds still'
                      : 'The ring scales with the breath',
                ),
              ],
            ),
          ),

          const CcRule(),
          ToggleRow(
            label: 'Reduce motion',
            explanation:
                'Replaces the moving orb with a counted cue that fades instead '
                'of scaling. The vibration keeps pacing your breath either way.',
            value: app.reduceMotion,
            onChanged: (v) => app.reduceMotion = v,
          ),
          const CcRule(),
          CcStack(
            gap: CcGap.sm,
            children: [
              FieldLabel('Stock'),
              const CcCaption(
                'The same card, printed on warm stock or on dark stock. '
                'Following the phone is the default.',
              ),
              Row(
                spacing: CcSpace.sm,
                children: [
                  for (final choice in ThemeChoice.values)
                    Expanded(
                      child: CcButton(
                        switch (choice) {
                          ThemeChoice.system => 'Phone',
                          ThemeChoice.light => 'Light',
                          ThemeChoice.dark => 'Dark',
                        },
                        variant: app.themeChoice == choice
                            ? CcButtonVariant.primary
                            : CcButtonVariant.secondary,
                        onPressed: () => app.themeChoice = choice,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
