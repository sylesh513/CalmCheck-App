/// The signature object: edge, stock, and printed-label typography. The
/// on-screen card and the printed PDF must read as the same artifact.
library;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'primitives.dart';

class CareCardFrame extends StatelessWidget {
  const CareCardFrame({
    super.key,
    required this.title,
    required this.children,
    this.meta,
    this.label = 'Care card',
  });

  final Widget title;
  final String? meta;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CcStructure.marginH,
        vertical: CcSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: CcSpace.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.rule,
                  width: CcStructure.ruleWeight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.xs,
              children: [
                FieldLabel(label),
                title,
                if (meta != null) CcCaption(meta!),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

enum GuidanceTone { doThis, dontDo }

/// A labelled group of Do or Do-not rows. The label is never optional.
class GuidanceList extends StatelessWidget {
  const GuidanceList({
    super.key,
    required this.tone,
    required this.items,
    this.label,
  });

  final GuidanceTone tone;
  final List<String> items;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final heading =
        label ?? (tone == GuidanceTone.doThis ? 'What to do' : 'Do not');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.sm,
        children: [
          FieldLabel(
            heading,
            tone: tone == GuidanceTone.doThis ? CcTone.signal : CcTone.alert,
          ),
          for (var i = 0; i < items.length; i++)
            GuidanceRow(
              tone: tone,
              text: items[i],
              last: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One instruction row.
///
/// The highest-stakes component in the app: confusing these causes harm. Do and
/// Do-not are distinguished on three channels at once — colour, the marker's
/// shape (filled square vs open ring with a bar), and the group's micro-label —
/// so the distinction survives greyscale printing and every colour-vision
/// simulation. The screen reader hears "Do:" or "Do not:" as well.
class GuidanceRow extends StatelessWidget {
  const GuidanceRow({
    super.key,
    required this.tone,
    required this.text,
    this.last = false,
  });

  final GuidanceTone tone;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final isDo = tone == GuidanceTone.doThis;
    return Semantics(
      label: isDo ? 'Do: $text' : 'Do not: $text',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: CcSpace.md),
        decoration: last || t.isAcute
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: t.rule,
                    width: CcStructure.ruleWeight,
                  ),
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CcSpace.md,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CustomPaint(
                  painter: _GuidanceMark(
                    isDo: isDo,
                    color: isDo ? t.signal : t.alert,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: context.ccText.bodyMedium!.copyWith(
                  // Weight is a fourth channel on the do-not rows.
                  fontWeight: isDo ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painted, never an icon font — a missing glyph on a do-not row is a safety
/// failure, not a rendering bug.
class _GuidanceMark extends CustomPainter {
  const _GuidanceMark({required this.isDo, required this.color});

  final bool isDo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (isDo) {
      // Filled square.
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    // Open ring with a bar through it.
    final r = size.width / 2;
    canvas.drawCircle(
      Offset(r, r),
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    canvas.drawRect(Rect.fromLTWH(0, r - 1, size.width, 2), paint);
  }

  @override
  bool shouldRepaint(covariant _GuidanceMark old) =>
      old.isDo != isDo || old.color != color;
}
