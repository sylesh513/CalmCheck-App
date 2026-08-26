/// PAY-04 — the trial and subscription moments.
///
/// The expiry state is the one that matters most: existing care cards stay
/// readable, shareable and printable from a saved PDF. Losing access to your
/// grandfather's care card because a payment failed would be indefensible.
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import 'manage_subscription_screen.dart' show openStoreSubscriptions;
import 'paywall_screen.dart' show FreeForeverBlock, ProList;

enum LifecycleMoment { started, ending, expired }

class LifecycleScreen extends StatelessWidget {
  const LifecycleScreen({super.key, required this.moment});

  final LifecycleMoment moment;

  @override
  Widget build(BuildContext context) => switch (moment) {
    LifecycleMoment.started => const _Started(),
    LifecycleMoment.ending => const _Ending(),
    LifecycleMoment.expired => const _Expired(),
  };
}

class _Started extends StatelessWidget {
  const _Started();

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              FieldLabel('Pro'),
              const CcHeadline('You have Pro.'),
              const CcSub(
                'Everything below is unlocked on this device. Renewal, price '
                'and cancellation live in the store you bought it from.',
              ),
              const CcRule(),
              const ProList(),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                'Try a Pro exercise',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(Routes.exercises),
              ),
              CcButton(
                'Not now',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(Routes.home, (r) => false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Ending extends StatelessWidget {
  const _Ending();

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Pro'),
              const CcHeadline('Your trial is ending.'),
              const CcSub(
                'When it ends, the plan starts at the price the store showed '
                'you. Cancel in the store before then and nothing is charged.',
              ),
              const CcRule(),
              const FreeForeverBlock(),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                'Keep Pro',
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              CcButton(
                'Cancel the trial',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: () => openStoreSubscriptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Expired extends StatelessWidget {
  const _Expired();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cards = app.cards.length;
    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Pro'),
              const CcHeadline('Pro has ended.'),
              const CcSub(
                "Nothing has been deleted. Here's exactly what changed.",
              ),
              const CcRule(),
              _Keeps(
                label: 'Still yours',
                tone: _KeepTone.keep,
                items: [
                  'All $cards of your care cards — readable, shareable, '
                      'printable from a saved PDF',
                  'The full panic flow',
                  'Paced breathing and 5-4-3-2-1 grounding',
                  'Crisis helplines',
                ],
              ),
              _Keeps(
                label: 'Paused until you renew',
                tone: _KeepTone.paused,
                items: const [
                  'Making new care cards',
                  'New PDF exports',
                  'Custom breathing pace — back to 4s in, 6s out',
                  'The four Pro exercises',
                ],
              ),
            ],
          ),
          CcStack(
            gap: CcGap.sm,
            children: [
              CcButton(
                'Renew Pro',
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.paywall),
              ),
              CcButton(
                'Carry on without it',
                variant: CcButtonVariant.quiet,
                fullWidth: true,
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(Routes.home, (r) => false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _KeepTone { keep, paused }

/// Kept and paused are told apart by the marker shape as well as the ink
/// weight: an open square against a bar.
class _Keeps extends StatelessWidget {
  const _Keeps({required this.label, required this.tone, required this.items});

  final String label;
  final _KeepTone tone;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final keep = tone == _KeepTone.keep;
    return CcStack(
      gap: CcGap.xs,
      children: [
        FieldLabel(label),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: CcSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CcSpace.md,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: keep ? 7 : 11),
                  child: keep
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            border: Border.all(color: t.ink, width: 2),
                          ),
                        )
                      : Container(width: 12, height: 2, color: t.inkMuted),
                ),
                Expanded(child: CcBody(item, muted: !keep)),
              ],
            ),
          ),
      ],
    );
  }
}
