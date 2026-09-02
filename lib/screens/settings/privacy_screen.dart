/// SET-02 — privacy and data.
///
/// A marketing screen disguised as a settings screen, and designed to be
/// screenshot-worthy. In Field Card terms this is the back of the card, where
/// the terms are printed plainly and you can actually read them.
library;

import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final firstCard = app.cards.isEmpty ? null : app.cards.first;

    return CalmScaffold(
      child: CcScreen(
        align: CcAlign.between,
        children: [
          CcStack(
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              FieldLabel('Privacy and data'),
              const CcHeadline('Your data stays on this phone.'),
              const CcSub(
                'CalmCheck has no accounts and no servers of ours. Your care '
                'cards, your settings, and everything you do in the app are '
                'stored on this device only. Nothing about you is uploaded '
                'and nothing is tracked. The one network call the app ever '
                'makes is checking a Pro purchase with the store.',
              ),
              const CcRule(),
              const _PrivacyGrid(),
              const CcRule(),
              const CcBody(
                'If you delete the app, that data is gone. Save a PDF of any '
                'card you want to keep.',
              ),
            ],
          ),
          CcButton(
            'Save a PDF of my cards',
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.lg,
            fullWidth: true,
            onPressed: firstCard == null
                ? null
                : () => Navigator.of(
                    context,
                  ).pushNamed(Routes.cardShare, arguments: firstCard.id),
          ),
        ],
      ),
    );
  }
}

/// Four cells. The claim is checkable at a glance — and stays honest about
/// the one network call that exists (purchase validation).
class _PrivacyGrid extends StatelessWidget {
  const _PrivacyGrid();

  static const _cells = [
    ('Accounts', 'None'),
    ('Analytics', 'None'),
    ('Your data uploaded', 'Never'),
    ('Network use', 'Purchases only'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    // The grid's rule-coloured ground shows through the gaps: the dividers are
    // the same hairline as everywhere else, drawn once.
    return Container(
      color: t.rule,
      padding: const EdgeInsets.all(CcStructure.ruleWeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CcStructure.ruleWeight,
        children: [
          for (var row = 0; row < 2; row++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: CcStructure.ruleWeight,
                children: [
                  for (var col = 0; col < 2; col++)
                    Expanded(child: _Cell(cell: _cells[row * 2 + col])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.cell});

  final (String, String) cell;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      color: t.stockRaised,
      padding: const EdgeInsets.all(CcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.xs,
        children: [
          FieldLabel(cell.$1),
          Text(cell.$2, style: context.ccText.titleLarge),
        ],
      ),
    );
  }
}
