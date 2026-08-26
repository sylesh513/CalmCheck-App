/// Tiles and rows: the pieces that make lists in this system read as printed
/// entries rather than as a mobile list view.
library;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import '../services/haptics.dart';
import 'primitives.dart';

/// Compact home-shelf tile. A stranger must be able to tell two cards apart at
/// a glance, so name and signal both carry.
class CareTile extends StatelessWidget {
  const CareTile({
    super.key,
    required this.name,
    this.signal,
    this.initial,
    this.onTap,
    this.addNew = false,
    this.ghost = false,
  });

  final String name;
  final String? signal;
  final String? initial;
  final VoidCallback? onTap;

  /// The add-new tile: a ghosted form of the missing thing.
  final bool addNew;

  /// Non-interactive, used inside empty states.
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final avatarChild = addNew
        ? Text(
            '+',
            style: context.ccText.labelMedium!.copyWith(
              fontSize: 20,
              color: t.inkMuted,
            ),
          )
        : Text(
            initial ??
                (name.isEmpty ? '?' : name.characters.first.toUpperCase()),
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: t.signalInk,
            ),
          );

    final body = Container(
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: addNew ? Colors.transparent : t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(
          color: t.rule,
          width: CcStructure.cardEdge,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      foregroundDecoration: addNew
          ? _DashedBorder(color: t.rule, radius: t.radiusCard)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.xs,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: CcSpace.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: addNew ? Colors.transparent : t.signal,
              borderRadius: BorderRadius.circular(3),
              border: addNew ? Border.all(color: t.rule) : null,
            ),
            child: avatarChild,
          ),
          Text(
            name,
            style: context.ccText.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (signal != null) CcCaption(signal!),
        ],
      ),
    );

    if (ghost || onTap == null) {
      return ExcludeSemantics(child: body);
    }

    return Semantics(
      button: true,
      label: addNew ? 'New card. ${signal ?? ''}' : '$name. ${signal ?? ''}',
      excludeSemantics: true,
      child: _PressTile(onTap: onTap!, radius: t.radiusCard, child: body),
    );
  }
}

/// Tap-to-call. The whole row is the target, never an icon inside it. One of
/// only two components allowed to carry the alert token.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.name,
    this.relationship,
    this.number,
    this.onCall,
    this.onAddNumber,
  });

  final String name;
  final String? relationship;
  final String? number;
  final VoidCallback? onCall;
  final VoidCallback? onAddNumber;

  bool get _missing => (number ?? '').trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      button: true,
      label: _missing ? 'Add a number for $name' : 'Call $name on $number',
      excludeSemantics: true,
      child: _PressTile(
        radius: t.radiusCard,
        onTap: () {
          if (_missing) {
            onAddNumber?.call();
          } else {
            CcHaptics.instance.fire(CcHaptic.emergency);
            onCall?.call();
          }
        },
        haptic: null,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: CcStructure.targetContact,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.lg,
            vertical: CcSpace.md,
          ),
          decoration: BoxDecoration(
            color: t.stockRaised,
            borderRadius: t.cardBorderRadius,
            border: Border(
              // The heavy left edge is the alert channel that survives
              // greyscale: shape as well as colour.
              left: BorderSide(color: t.alert, width: _missing ? 2 : 6),
              top: BorderSide(color: t.alert, width: 2),
              right: BorderSide(color: t.alert, width: 2),
              bottom: BorderSide(color: t.alert, width: 2),
            ),
          ),
          child: _WhoAndNumber(
            stacked: MediaQuery.textScalerOf(context).scale(17) > 24,
            who: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.hair,
              children: [
                Text(
                  name,
                  style: context.ccText.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((relationship ?? '').isNotEmpty)
                  Text(
                    relationship!.toUpperCase(),
                    style: context.ccText.labelSmall,
                  ),
              ],
            ),
            number: Text(
              _missing ? 'No number saved · Add' : number!,
              style: TextStyle(
                fontFamily: ccLabelFace,
                fontSize: 14,
                color: _missing ? t.inkMuted : t.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Side by side while they fit; stacked once the type grows, so the number is
/// never squeezed, wrapped mid-group, or clipped.
class _WhoAndNumber extends StatelessWidget {
  const _WhoAndNumber({
    required this.stacked,
    required this.who,
    required this.number,
  });

  final bool stacked;
  final Widget who;
  final Widget number;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.sm,
        children: [who, number],
      );
    }
    return Row(
      spacing: CcSpace.lg,
      children: [
        Expanded(child: who),
        Flexible(child: number),
      ],
    );
  }
}

enum ExerciseCardState { free, unlocked, locked }

/// The locked treatment is quiet: a hairline change and a plain line of text.
/// No strikethrough, no crown, no "UPGRADE". A locked exercise is an
/// invitation, not a taunt.
class ExerciseCardTile extends StatelessWidget {
  const ExerciseCardTile({
    super.key,
    required this.name,
    required this.duration,
    required this.purpose,
    this.state = ExerciseCardState.free,
    this.onTap,
    this.ghost = false,
  });

  final String name;
  final String duration;
  final String purpose;
  final ExerciseCardState state;
  final VoidCallback? onTap;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final locked = state == ExerciseCardState.locked;

    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: locked
            ? null
            : Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      foregroundDecoration: locked
          ? _DashedBorder(color: t.rule, radius: t.radiusCard)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.xs,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CcSpace.md,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: context.ccText.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                duration,
                style: TextStyle(
                  fontFamily: ccLabelFace,
                  fontSize: 14,
                  color: t.inkMuted,
                ),
              ),
            ],
          ),
          CcCaption(purpose),
          if (state != ExerciseCardState.free)
            Padding(
              padding: const EdgeInsets.only(top: CcSpace.sm),
              child: FieldLabel(
                locked ? 'Included with Pro' : 'Unlocked',
                tone: locked ? CcTone.neutral : CcTone.signal,
              ),
            ),
        ],
      ),
    );

    if (ghost || onTap == null) return ExcludeSemantics(child: body);

    return Semantics(
      button: true,
      label:
          '$name. $purpose $duration.'
          '${locked ? ' Included with Pro.' : ''}',
      excludeSemantics: true,
      child: _PressTile(onTap: onTap!, radius: t.radiusCard, child: body),
    );
  }
}

/// Selection is carried by the mark, the border weight and the printed word —
/// never by colour alone.
class PriceOption extends StatelessWidget {
  const PriceOption({
    super.key,
    required this.term,
    required this.price,
    required this.equivalent,
    required this.selected,
    required this.onTap,
    this.savings,
    this.enabled = true,
  });

  final String term;
  final String price;
  final String equivalent;
  final String? savings;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label:
          '$term, $price, $equivalent.'
          '${savings != null ? ' $savings.' : ''}'
          '${selected ? ' Selected.' : ''}',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: _PressTile(
          radius: t.radiusCard,
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(CcSpace.lg),
            decoration: BoxDecoration(
              color: t.stockRaised,
              borderRadius: t.cardBorderRadius,
              border: Border.all(
                color: selected ? t.ink : t.rule,
                width: selected ? 2 : CcStructure.cardEdge,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.xs,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CcSpace.md,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _RadioMark(
                        selected: selected,
                        color: t.ink,
                        muted: t.inkMuted,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: CcSpace.hair,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: CcSpace.sm,
                            children: [
                              Text(
                                term,
                                style: context.ccText.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (savings != null)
                                Text(
                                  savings!.toUpperCase(),
                                  style: context.ccText.labelSmall!.copyWith(
                                    color: t.signal,
                                  ),
                                ),
                            ],
                          ),
                          CcCaption(equivalent),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: context.ccText.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: FieldLabel('Selected'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({
    required this.selected,
    required this.color,
    required this.muted,
  });

  final bool selected;
  final Color color;
  final Color muted;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: selected ? color : muted, width: 2),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )
        : null,
  );
}

/// A settings row that opens something. Every row carries its explanation —
/// a settings screen where you have to guess what a switch does is a failure
/// of nerve.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    required this.explanation,
    this.value,
    this.marker,
    this.onTap,
  });

  final String label;
  final String explanation;
  final String? value;

  /// The quiet Pro marker. Never a crown, never a colour on its own.
  final String? marker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      button: onTap != null,
      label:
          '$label. $explanation'
          '${value != null ? ' $value.' : ''}'
          '${marker != null ? ' $marker.' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CcSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CcSpace.md,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: CcSpace.hair,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: CcSpace.sm,
                        children: [
                          Text(label, style: context.ccText.bodyLarge),
                          if (marker != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: t.rule,
                                  width: CcStructure.ruleWeight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                marker!.toUpperCase(),
                                style: context.ccText.labelSmall,
                              ),
                            ),
                        ],
                      ),
                      CcCaption(explanation),
                    ],
                  ),
                ),
                if (value != null)
                  Text(value!.toUpperCase(), style: context.ccText.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pressable card that dips 2dp instead of splashing. The system has stock
/// and thickness, not Material ink.
class _PressTile extends StatefulWidget {
  const _PressTile({
    required this.child,
    required this.onTap,
    required this.radius,
    this.haptic = CcHaptic.pressFirm,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final CcHaptic? haptic;

  @override
  State<_PressTile> createState() => _PressTileState();
}

class _PressTileState extends State<_PressTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        if (widget.haptic != null) CcHaptics.instance.fire(widget.haptic!);
        widget.onTap!();
      },
      child: Transform.translate(
        offset: Offset(0, _pressed ? 2 : 0),
        child: widget.child,
      ),
    );
  }
}

/// A dashed edge, painted. Used for the add-new tile and the locked exercise —
/// both are "this is not filled in yet" rather than "this is disabled".
class _DashedBorder extends Decoration {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBorderPainter(color, radius);
}

class _DashedBorderPainter extends BoxPainter {
  _DashedBorderPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size!;
    final rect = (offset & size).deflate(0.5);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }
}
