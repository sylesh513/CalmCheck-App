/// CARD-VIEW — the second most important screen in the app.
///
/// The test it is built against: a stranger, holding someone else's phone,
/// mid-emergency, finds "what not to do" in under ten seconds. The information
/// order is fixed and identical to the printed card — who this is, WHAT TO DO,
/// DO NOT, CALL, then everything else. Nothing may be inserted above DO NOT.
library;

import 'package:flutter/material.dart';

import '../../models/care_card.dart';
import '../../routes.dart';
import '../../services/dialer.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class CardViewScreen extends StatefulWidget {
  const CardViewScreen({super.key, this.cardId, this.previewCard})
    : assert(cardId != null || previewCard != null);

  final String? cardId;

  /// A card rendered straight through, without a store lookup. Used by the
  /// design reference so the sample cards are always viewable.
  final CareCardData? previewCard;

  @override
  State<CardViewScreen> createState() => _CardViewScreenState();
}

class _CardViewScreenState extends State<CardViewScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _dontKey = GlobalKey();
  bool _dontVisible = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkDont);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDont());
  }

  @override
  void dispose() {
    _scroll.removeListener(_checkDont);
    _scroll.dispose();
    super.dispose();
  }

  /// At large text scale the WHAT TO DO list can be taller than the screen, so
  /// DO NOT would fall below the fold. That is a critical failure, not a
  /// cosmetic one, so the first do-not line pins itself to the bottom edge
  /// until the real block is on screen.
  void _checkDont() {
    final box = _dontKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final visible = top < MediaQuery.sizeOf(context).height * 0.85;
    if (visible != _dontVisible) setState(() => _dontVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final card = widget.previewCard ?? app.cardById(widget.cardId!);
    if (card == null) {
      return CalmScaffold(
        child: CcScreen(
          children: [
            const CcBackBar(),
            SystemState(
              label: 'Care card',
              headline: 'That card is gone',
              direction:
                  'It was deleted on this device. Nothing is stored anywhere '
                  'else, so there is no copy to bring back.',
              action: CcButton(
                'Back to home',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(Routes.home, (r) => false),
              ),
            ),
          ],
        ),
      );
    }

    final showPin = !_dontVisible && card.dontDo.isNotEmpty;

    return CalmScaffold(
      child: Stack(
        children: [
          CcScreen(
            controller: _scroll,
            gap: CcGap.lg,
            children: [
              const CcBackBar(),
              if (card.readOnly) _ReceivedBar(card: card),
              CareCardFrame(
                title: _Identity(card: card),
                meta: card.meta,
                children: [
                  // 2. WHAT TO DO
                  if (card.doThis.isNotEmpty)
                    GuidanceList(tone: GuidanceTone.doThis, items: card.doThis),
                  // 3. DO NOT — where harm gets prevented
                  KeyedSubtree(
                    key: _dontKey,
                    child: card.dontDo.isEmpty
                        ? const SizedBox.shrink()
                        : GuidanceList(
                            tone: GuidanceTone.dontDo,
                            items: card.dontDo,
                          ),
                  ),
                  // 4. CALL — always present, even empty. It is item four of
                  // an information order that never moves, and a section that
                  // silently disappears leaves a stranger unable to tell
                  // "nobody to call" from "I must have missed it".
                  FieldRow(
                    label: 'Call',
                    tone: CcTone.alert,
                    child: card.call.isEmpty
                        ? _NoContacts(card: card)
                        : CcStack(
                            gap: CcGap.sm,
                            children: [
                              for (final c in card.call)
                                ContactRow(
                                  name: c.name,
                                  relationship: c.relationship,
                                  number: c.number,
                                  onCall: () => dial(c.number!),
                                  onAddNumber: card.readOnly
                                      ? null
                                      : () => Navigator.of(context).pushNamed(
                                          Routes.cardEdit,
                                          arguments: card.id,
                                        ),
                                ),
                            ],
                          ),
                  ),
                  // 5. Everything else
                  FieldRow(
                    label: 'About',
                    divided: false,
                    child: _About(card: card),
                  ),
                ],
              ),
              const CcRule(),
              _Foot(card: card),
            ],
          ),
          if (showPin)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _DoNotPin(card: card),
            ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: CcSpace.md,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: t.rule, width: CcStructure.cardEdge),
          ),
          child: Text(card.initial, style: context.ccText.titleLarge),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.name, style: context.ccText.titleLarge),
              if (card.relation.isNotEmpty) CcCaption(card.relation),
              if (card.readOnly) CcCaption('Shared with you · read only'),
            ],
          ),
        ),
      ],
    );
  }
}

/// A card with nobody on it. For the person who wrote it this is the most
/// useful thing the screen can say; for a stranger holding somebody else's
/// phone it is the difference between "there is no one" and "I cannot find it".
class _NoContacts extends StatelessWidget {
  const _NoContacts({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;

    if (card.readOnly) {
      return const CcBody('No one is listed on this card.', muted: true);
    }

    return Semantics(
      button: true,
      label: 'Add someone to call. This card has no contacts yet.',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).pushNamed(Routes.cardEdit, arguments: card.id),
        borderRadius: t.cardBorderRadius,
        child: DottedFrame(
          color: t.alert,
          radius: t.radiusCard,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: CcStructure.targetContact,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: CcSpace.lg,
              vertical: CcSpace.md,
            ),
            alignment: Alignment.centerLeft,
            child: CcStack(
              gap: CcGap.xs,
              children: [
                Text(
                  'Nobody to call yet',
                  style: context.ccText.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const CcCaption(
                  'Whoever picks this card up will have no one to ring. '
                  'Add someone.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    if (!card.hasAbout) {
      // A minimal card is not a broken card.
      return const CcBody('Nothing written here yet.', muted: true);
    }
    return CcStack(
      gap: CcGap.md,
      children: [
        if (card.livesWith.isNotEmpty) ...[
          FieldLabel('What they live with'),
          CcBody(card.livesWith),
        ],
        if (card.medications.isNotEmpty) ...[
          FieldLabel('Medications'),
          CcBody(card.medications),
        ],
        if (card.triggers.isNotEmpty) ...[
          FieldLabel('What can set things off'),
          CcBody(card.triggers),
        ],
        if (card.notes.isNotEmpty) ...[
          FieldLabel('Anything else'),
          CcBody(card.notes),
        ],
      ],
    );
  }
}

/// A received card has no edit affordance. It can be read, called from, and
/// saved — the person who wrote it keeps the original.
class _ReceivedBar extends StatelessWidget {
  const _ReceivedBar({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    return CcStack(
      gap: CcGap.xs,
      children: [
        FieldLabel('Received card'),
        CcCaption(
          'You can read and call from this card.'
          '${card.sharedBy != null ? ' Only ${card.sharedBy} can change it.' : ''}',
        ),
      ],
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    if (card.readOnly) {
      return CcButton(
        'Save a copy to this device',
        variant: CcButtonVariant.secondary,
        fullWidth: true,
        onPressed: () {
          final app = context.appRead;
          app.upsertCard(
            card.copyWith(readOnly: false, preparedAt: DateTime.now()),
          );
          Navigator.of(
            context,
          ).pushReplacementNamed(Routes.cardView, arguments: card.id);
        },
      );
    }
    return Row(
      spacing: CcSpace.md,
      children: [
        Expanded(
          child: CcButton(
            'Edit card',
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(Routes.cardEdit, arguments: card.id),
          ),
        ),
        Expanded(
          child: CcButton(
            'Share',
            variant: CcButtonVariant.quiet,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(Routes.cardShare, arguments: card.id),
          ),
        ),
      ],
    );
  }
}

/// The pinned strip. Nothing is hidden, the fixed order is unchanged, and the
/// strip disappears the moment the real DO NOT block is on screen.
class _DoNotPin extends StatelessWidget {
  const _DoNotPin({required this.card});

  final CareCardData card;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final more = card.dontDo.length - 1;
    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          CcStructure.marginH,
          CcSpace.md,
          CcStructure.marginH,
          CcSpace.md + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: t.stock,
          border: Border(top: BorderSide(color: t.alert, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: CcSpace.hair,
          children: [
            FieldLabel('Do not', tone: CcTone.alert),
            Text(
              card.dontDo.first,
              style: context.ccText.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (more > 0)
              Text('$more more below', style: context.ccText.labelSmall),
          ],
        ),
      ),
    );
  }
}
