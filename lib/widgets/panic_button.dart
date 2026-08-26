/// The card's front face, not a button sitting on a page.
///
/// It fills the door — roughly the top 70% of HOME — so it can be hit
/// one-handed, shaking, without aiming. The eyes-closed test: anywhere in the
/// upper two-thirds of the screen starts the breathing.
library;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../services/haptics.dart';

class PanicButton extends StatefulWidget {
  const PanicButton({
    super.key,
    required this.onPressed,
    this.label = 'When it starts',
    this.text = 'I need calm now',
    this.hint = 'Starts breathing straight away',
  });

  final VoidCallback onPressed;
  final String label;
  final String text;
  final String? hint;

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = CcMotion.reduce(CcMotion.tap, reduced: reduced);

    return Semantics(
      button: true,
      label: '${widget.text}. ${widget.hint ?? ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          CcHaptics.instance.fire(CcHaptic.pressFirm);
          widget.onPressed();
        },
        // Stock with thickness: a darker edge layer, and the printed face
        // sitting on top of it. Pressing compresses the edge — the same
        // gesture as pressing something that is actually made of card.
        child: AnimatedContainer(
          duration: duration,
          curve: CcMotion.tapCurve,
          transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
          padding: EdgeInsets.only(bottom: _pressed ? 1 : 4),
          decoration: BoxDecoration(
            color: _shade(t.signal),
            borderRadius: t.cardBorderRadius,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              CcStructure.marginH,
              CcSpace.xxl,
              CcStructure.marginH,
              CcSpace.xxl,
            ),
            decoration: BoxDecoration(
              color: t.signal,
              borderRadius: t.cardBorderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              spacing: CcSpace.sm,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: context.ccText.labelSmall!.copyWith(
                    color: t.signalInk.withValues(alpha: 0.78),
                  ),
                ),
                Text(
                  widget.text,
                  style: context.ccText.displaySmall!.copyWith(
                    color: t.signalInk,
                  ),
                ),
                if (widget.hint != null)
                  Text(
                    widget.hint!,
                    style: context.ccText.bodySmall!.copyWith(
                      color: t.signalInk.withValues(alpha: 0.82),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The lit edge of the stock, a shade under the face — this is what gives the
  /// button thickness without an elevation shadow.
  Color _shade(Color base) => Color.lerp(base, const Color(0xFF000000), 0.34)!;
}

/// The quiet row at the foot of HOME. The crisis route is always one tap away
/// and never sits near anything that asks for money.
class QuietRow extends StatelessWidget {
  const QuietRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.only(top: CcSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.rule, width: CcStructure.ruleWeight),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CcSpace.md,
        runSpacing: CcSpace.xs,
        children: children,
      ),
    );
  }
}

/// Keeps the wrap spread across the full width even with two children.
class QuietRowSpread extends StatelessWidget {
  const QuietRowSpread({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.only(top: CcSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.rule, width: CcStructure.ruleWeight),
        ),
      ),
      // At large text scale the two links stop fitting side by side; they
      // stack rather than shrink.
      child: MediaQuery.textScalerOf(context).scale(12) > 19
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.xs,
              children: children,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // The links carry their own edge now, so they must be allowed to
              // give way rather than overflow the row by a couple of pixels.
              children: [for (final child in children) Flexible(child: child)],
            ),
    );
  }
}

/// A dummy so `primitives.dart` stays imported where the label style is reused.
