/// HOME — the whole thesis on one screen.
///
/// Layout "Ground": the action *is* the background, and the cards are printed
/// onto a ledge at the thumb line. The eyes-closed test passes because there is
/// nothing to aim at — anywhere in the upper two-thirds starts the breathing.
library;

import 'package:flutter/material.dart';

import '../../data/copy.dart';
import '../../models/care_card.dart';
import '../../routes.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../cards/card_empty_screen.dart' show GhostCard;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.forceEmpty = false});

  /// Renders the first-run shelf whatever is saved. Used by the design
  /// reference; the live home always shows the real cards.
  final bool forceEmpty;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cards = forceEmpty ? const <CareCardData>[] : app.cards;

    return CalmScaffold(
      child: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The door takes everything the ledge does not — and when
                  // its own type outgrows the screen, the whole screen grows
                  // and scrolls rather than clipping the action.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CcStructure.marginH,
                        CcSpace.lg,
                        CcStructure.marginH,
                        CcSpace.md,
                      ),
                      child: PanicButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.panicPacer),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CcStructure.marginH,
                      CcSpace.lg,
                      CcStructure.marginH,
                      CcSpace.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      spacing: CcSpace.md,
                      children: [
                        if (cards.isEmpty)
                          const _EmptyShelf()
                        else
                          _Shelf(cards: cards),
                        const _QuietFoot(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.cards});

  final List<CareCardData> cards;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // At large text scale a tile takes nearly the full width rather than
    // shrinking its type.
    final large = MediaQuery.textScalerOf(context).scale(17) > 26;
    final tileWidth = large ? width * 0.82 : (width * 0.60).clamp(160.0, 220.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CcSpace.sm,
      children: [
        CcSpread(
          children: [
            FieldLabel('Care cards'),
            QuietLink(
              'Scan a card',
              onTap: () => Navigator.of(context).pushNamed(Routes.cardScan),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: CcSpace.sm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CcSpace.md,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: tileWidth,
                    child: CareTile(
                      name: card.name,
                      signal: card.signal,
                      initial: card.initial,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(Routes.cardView, arguments: card.id),
                    ),
                  ),
                SizedBox(
                  width: tileWidth,
                  child: CareTile(
                    name: 'New card',
                    signal: 'Takes about two minutes',
                    addNew: true,
                    onTap: () => _newCard(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CcSpace.sm,
      children: [
        FieldLabel('Care cards'),
        EmptyState(
          headline: StateCopy.emptyCardsHeadline,
          body: StateCopy.emptyCardsDirection,
          ghost: const GhostCard(),
          action: CcButton(
            StateCopy.emptyCardsPrimary,
            fullWidth: true,
            onPressed: () => _newCard(context),
          ),
        ),
      ],
    );
  }
}

/// An always-present, quiet route to the helplines, and a quiet route to
/// settings. Neither ever sits next to anything that asks for money.
class _QuietFoot extends StatelessWidget {
  const _QuietFoot();

  @override
  Widget build(BuildContext context) {
    return QuietRowSpread(
      children: [
        QuietLink(
          'Crisis helplines',
          onTap: () => Navigator.of(context).pushNamed(Routes.crisis),
        ),
        QuietLink(
          'Settings',
          onTap: () => Navigator.of(context).pushNamed(Routes.settings),
        ),
      ],
    );
  }
}

/// The first card is free forever. Only the second one meets the paywall.
void _newCard(BuildContext context) {
  final app = context.appRead;
  if (app.canCreateCard) {
    Navigator.of(context).pushNamed(Routes.cardEdit);
  } else {
    Navigator.of(context).pushNamed(Routes.paywall, arguments: 'second-card');
  }
}
