/// Tappable starting points for the two hardest fields on a care card. Tone
/// drives the marker shape as well as the colour, so Do and Do-not stay apart
/// in greyscale here too.
library;

import 'package:flutter/material.dart';

import '../data/suggestions.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'care_card_frame.dart';
import 'primitives.dart';

class SuggestionPicker extends StatelessWidget {
  const SuggestionPicker({
    super.key,
    required this.tone,
    required this.groups,
    required this.chosen,
    required this.onToggle,
  });

  final GuidanceTone tone;
  final List<SuggestionGroup> groups;
  final List<String> chosen;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDo = tone == GuidanceTone.doThis;
    return CcStack(
      gap: CcGap.md,
      children: [
        FieldLabel(
          isDo ? 'Add a common step' : 'Add a common warning',
          tone: isDo ? CcTone.signal : CcTone.alert,
        ),
        for (final group in groups)
          CcStack(
            gap: CcGap.sm,
            children: [
              CcCaption(group.label),
              Wrap(
                spacing: CcSpace.sm,
                runSpacing: CcSpace.sm,
                children: [
                  for (final item in group.items)
                    _Chip(
                      label: item,
                      on: chosen.contains(item),
                      isDo: isDo,
                      onTap: () => onToggle(item),
                    ),
                ],
              ),
            ],
          ),
        CcCaption(
          'Tap to add it to the field above. You can edit the wording '
          'afterwards.',
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.on,
    required this.isDo,
    required this.onTap,
  });

  final String label;
  final bool on;
  final bool isDo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final accent = isDo ? t.signal : t.alert;
    return Semantics(
      button: true,
      toggled: on,
      label: '${isDo ? 'Add step' : 'Add warning'}: $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: t.cardBorderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.md,
            vertical: CcSpace.sm,
          ),
          decoration: BoxDecoration(
            color: on ? t.stockRaised : Colors.transparent,
            borderRadius: t.cardBorderRadius,
            border: Border.all(
              color: on ? accent : t.rule,
              width: on ? 2 : CcStructure.cardEdge,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: CcSpace.sm,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CustomPaint(
                  painter: _ChipMark(
                    isDo: isDo,
                    on: on,
                    accent: accent,
                    rule: t.rule,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  label,
                  style: context.ccText.bodySmall!.copyWith(color: t.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipMark extends CustomPainter {
  const _ChipMark({
    required this.isDo,
    required this.on,
    required this.accent,
    required this.rule,
  });

  final bool isDo;
  final bool on;
  final Color accent;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    final color = on ? accent : rule;
    if (isDo) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = color
          ..style = on ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }
    final r = size.width / 2;
    canvas.drawCircle(
      Offset(r, r),
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, r - 1, size.width, 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ChipMark old) =>
      old.isDo != isDo ||
      old.on != on ||
      old.accent != accent ||
      old.rule != rule;
}
