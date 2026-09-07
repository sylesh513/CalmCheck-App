/// PAY-02 — sponsored access.
///
/// Credibility comes from a specific number and an honest limit, not from
/// illustration. When the pool is empty this page says so, with the real
/// figure, because that will happen.
library;

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../services/dialer.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

enum SponsoredState { open, empty, submitted, granted }

class SponsoredScreen extends StatelessWidget {
  const SponsoredScreen({super.key, this.forcedState});

  final SponsoredState? forcedState;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    // A granted licence is issued by a person, not by the app granting itself
    // Pro, so `granted` is only ever reached from the design reference.
    // `empty` and `granted` are design-reference states only. The app has no
    // server, so it cannot know how many licences are left any more than it can
    // grant itself one — it used to read a constant, which meant the figure was
    // never true. Whether the pool is empty is answered by the reply to the
    // email, not by this screen.
    final state =
        forcedState ??
        (app.sponsorApplicationSent
            ? SponsoredState.submitted
            : SponsoredState.open);

    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Sponsored access'),
              const CcHeadline('Sponsored access'),
              if (state == SponsoredState.granted) ...[
                const _Figure(
                  label: 'Your licence',
                  value: 'One year of Pro',
                  note: 'Granted today · runs for twelve months',
                ),
                const CcBody(
                  "Someone else's subscription paid for this. You owe nothing "
                  'and nobody is told who you are. When the year is up, '
                  'everything free stays free.',
                ),
              ] else
                const CcSub(ProCopy.sponsoredBody),
              const CcRule(),
              if (state == SponsoredState.empty)
                const _Figure(
                  label: 'Licences available now',
                  value: '0',
                  note:
                      'The pool is empty. It refills when subscriptions do — '
                      'usually within a few weeks.',
                  empty: true,
                ),
              if (state == SponsoredState.submitted)
                const _Figure(
                  label: 'Your application',
                  value: 'Received',
                  note:
                      'We answer everyone, usually within a week, by email. '
                      'Nothing about your application is stored in the app.',
                ),
              const CcBody(ProCopy.sponsoredLimit),
            ],
          ),
          switch (state) {
            SponsoredState.open => CcButton(
              'Apply for a sponsored year',
              size: CcButtonSize.lg,
              fullWidth: true,
              // Opens a mail draft: there is no server to receive an
              // application, and no way for the app to grant itself a licence.
              onPressed: () {
                app.submitSponsorApplication();
                composeSponsorApplication();
              },
            ),
            // No server means no waiting list we could hold for somebody, so
            // this is an email they send and can see in their own outbox.
            SponsoredState.empty => CcButton(
              'Ask to be told when it refills',
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.lg,
              fullWidth: true,
              onPressed: () => composeSupportEmail(
                body: 'Please let me know when a sponsored year is available.',
              ),
            ),
            SponsoredState.submitted => CcButton(
              'Withdraw my application',
              variant: CcButtonVariant.quiet,
              fullWidth: true,
              onPressed: app.withdrawSponsorApplication,
            ),
            SponsoredState.granted => CcButton(
              'Pass my licence on early',
              variant: CcButtonVariant.quiet,
              fullWidth: true,
              onPressed: () => composeSupportEmail(
                body:
                    'I would like to pass my sponsored year on to somebody '
                    'else.',
              ),
            ),
          },
        ],
      ),
    );
  }
}

/// A printed figure with a label, stated plainly. If the count is small, the
/// small number is what shows.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.note,
    this.empty = false,
  });

  final String label;
  final String value;
  final String note;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final inner = CcStack(
      gap: CcGap.xs,
      children: [
        FieldLabel(label),
        Text(
          value,
          style: TextStyle(
            fontFamily: ccLabelFace,
            fontSize: t.displaySize * 1.2,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: t.ink,
          ),
        ),
        CcCaption(note),
      ],
    );

    if (empty) {
      return DottedFrame(
        color: t.rule,
        radius: t.radiusCard,
        child: Padding(padding: const EdgeInsets.all(CcSpace.lg), child: inner),
      );
    }
    return Container(
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: inner,
    );
  }
}
