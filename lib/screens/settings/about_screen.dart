/// SET-03 — about and the full wellness disclaimer, in the same wording as
/// ONB-04, plus the font licences.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../services/dialer.dart';
import '../../services/errors.dart';
import '../../routes.dart';
import '../../widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('About'),
              const CcHeadline('CalmCheck'),
              const CcBody('Version 1.0 · Works fully offline'),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Please read', tone: CcTone.alert),
                  const CcBody(StateCopy.disclaimerBody),
                  const CcBody(StateCopy.disclaimerDanger),
                ],
              ),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Type'),
                  const CcBody(
                    'Atkinson Hyperlegible — Braille Institute of America, '
                    'SIL Open Font License 1.1.',
                  ),
                  const CcBody(
                    'IBM Plex Mono — IBM, SIL Open Font License 1.1.',
                  ),
                ],
              ),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Legal'),
                  CcButton(
                    'Terms of use',
                    variant: CcButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.terms),
                  ),
                  CcButton(
                    'Privacy policy',
                    variant: CcButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.privacyPolicy),
                  ),
                ],
              ),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Contact'),
                  const CcBody('hello@calmcheck.app'),
                  CcButton(
                    'Write to us',
                    variant: CcButtonVariant.quiet,
                    fullWidth: true,
                    onPressed: composeSupportEmail,
                  ),
                ],
              ),
              const _RecentProblems(),
              const CcRule(),
              CcStack(
                gap: CcGap.sm,
                children: [
                  FieldLabel('Crisis'),
                  CcButton(
                    'See crisis helplines',
                    variant: CcButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.crisis),
                  ),
                ],
              ),
              // The gallery renders paywall specimens with placeholder prices
              // that do not match the store. Debug builds only.
              if (kDebugMode) const CcRule(),
              if (kDebugMode)
                CcStack(
                  gap: CcGap.sm,
                  children: [
                    FieldLabel('Design reference'),
                    const CcCaption(
                      'Every screen and every state in this build, laid out the '
                      'way the design sessions specified them.',
                    ),
                    CcButton(
                      'Open the design reference',
                      variant: CcButtonVariant.quiet,
                      fullWidth: true,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(Routes.gallery),
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

/// Nothing is reported anywhere, so if something did go wrong the only place it
/// exists is here — and the only way it reaches us is if a person chooses to
/// send it.
class _RecentProblems extends StatelessWidget {
  const _RecentProblems();

  @override
  Widget build(BuildContext context) {
    final failures = FailureLog.instance.entries;
    if (failures.isEmpty) return const SizedBox.shrink();
    return CcStack(
      gap: CcGap.sm,
      children: [
        const CcRule(),
        FieldLabel('Recent problems'),
        CcCaption(
          'Kept on this device only, and forgotten when the app closes. '
          'Nothing is sent anywhere unless you send it.',
        ),
        for (final failure in failures.reversed.take(5))
          CcCaption('\u00b7 ${failure.summary}'),
        CcButton(
          'Send these to us',
          variant: CcButtonVariant.quiet,
          fullWidth: true,
          onPressed: () => composeSupportEmail(
            body: failures.map((f) => f.toString()).join('\n'),
          ),
        ),
      ],
    );
  }
}
