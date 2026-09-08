/// CARD-EMPTY.
///
/// This state carries the entire second half of the product's value
/// proposition, so the concept lands visually rather than verbally: a ghosted
/// example card, in the fixed information order, with the labels legible.
library;

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class CardEmptyScreen extends StatelessWidget {
  const CardEmptyScreen({super.key});

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
              FieldLabel('Care cards'),
              EmptyState(
                headline: StateCopy.emptyCardsHeadline,
                body: StateCopy.emptyCardsDirection,
                ghost: const GhostCard(),
              ),
            ],
          ),
          CcButton(
            StateCopy.emptyCardsPrimary,
            size: CcButtonSize.lg,
            fullWidth: true,
            onPressed: () {
              final app = context.appRead;
              Navigator.of(
                context,
              ).pushNamed(app.canCreateCard ? Routes.cardEdit : Routes.paywall);
            },
          ),
        ],
      ),
    );
  }
}

/// The ghosted card: enough structure to read as a care card, no content to
/// mistake for someone's.
class GhostCard extends StatelessWidget {
  const GhostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return ExcludeSemantics(
      child: DottedFrame(
        color: t.rule,
        radius: t.radiusCard,
        child: Padding(
          padding: const EdgeInsets.all(CcSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              FieldLabel('Care card'),
              Text('Their name', style: context.ccText.titleLarge),
              FieldLabel('What to do'),
              _Bar(color: t.rule),
              _Bar(color: t.rule, fraction: 0.62),
              FieldLabel('Do not'),
              _Bar(color: t.rule),
              FieldLabel('Call'),
              _Bar(color: t.rule, fraction: 0.62),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, this.fraction = 1});

  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: fraction,
    child: Container(height: 8, color: color),
  );
}
