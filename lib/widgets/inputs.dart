/// Form controls. Every toggle carries an explanation; every text field saves
/// itself. There is no save button anywhere in this app, and so no save
/// anxiety either.
library;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'primitives.dart';

/// Label, one-line explanation, control. The explanation is not optional —
/// this app explains itself.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.explanation,
    required this.value,
    this.onChanged,
  });

  final String label;
  final String explanation;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$label. $explanation',
      excludeSemantics: true,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CcSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CcSpace.lg,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: CcSpace.hair,
                    children: [
                      Text(label, style: context.ccText.bodyMedium),
                      CcCaption(explanation),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label above, generous target, per-field saved status. No global save button.
class TextFieldRow extends StatelessWidget {
  const TextFieldRow({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
    this.hint,
    this.status,
    this.error,
    this.multiline = false,
    this.minLines,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;
  final String? hint;

  /// "Saved" — the autosave indicator, shown per field.
  final String? status;
  final String? error;
  final bool multiline;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final hasError = (error ?? '').isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: t.cardBorderRadius,
      borderSide: BorderSide(
        color: hasError ? t.alert : t.rule,
        width: CcStructure.cardEdge,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CcSpace.sm,
      children: [
        FieldLabel(label, tone: hasError ? CcTone.alert : CcTone.neutral),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType:
              keyboardType ??
              (multiline ? TextInputType.multiline : TextInputType.text),
          minLines: multiline ? (minLines ?? 3) : 1,
          maxLines: multiline ? null : 1,
          textCapitalization: TextCapitalization.sentences,
          style: context.ccText.bodyMedium,
          cursorColor: t.signal,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.ccText.bodyMedium!.copyWith(color: t.inkMuted),
            filled: true,
            fillColor: t.stockRaised,
            isDense: false,
            contentPadding: const EdgeInsets.all(CcSpace.md),
            constraints: const BoxConstraints(minHeight: 52),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: t.cardBorderRadius,
              borderSide: BorderSide(
                color: hasError ? t.alert : t.signal,
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError)
          Text(
            error!,
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: 14,
              color: t.alert,
            ),
          )
        else if ((status ?? '').isNotEmpty)
          Text(
            status!,
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: 14,
              color: t.inkMuted,
            ),
          ),
        if (helper != null) CcCaption(helper!),
      ],
    );
  }
}

/// The Pro cadence control's stepper. 48dp targets on both buttons, even though
/// they are the smallest controls in the app.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.floor,
    this.floorNote,
  });

  final String label;
  final int value;
  final int min;
  final int max;

  /// The visible constraint: exhale can never be set shorter than inhale.
  final int? floor;
  final String? floorNote;
  final ValueChanged<int> onChanged;

  bool get _atFloor => floor != null && value <= floor!;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: CcSpace.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: CcSpace.hair,
            children: [
              FieldLabel(label),
              Text('$value seconds', style: context.ccText.bodyLarge),
              if (_atFloor && floorNote != null) CcCaption(floorNote!),
            ],
          ),
        ),
        _StepButton(
          glyph: '−',
          semantic: 'Shorten ${label.toLowerCase()}',
          enabled: value > min && !_atFloor,
          onTap: () => onChanged(value - 1),
          color: t.ink,
          rule: t.rule,
        ),
        _StepButton(
          glyph: '+',
          semantic: 'Lengthen ${label.toLowerCase()}',
          enabled: value < max,
          onTap: () => onChanged(value + 1),
          color: t.ink,
          rule: t.rule,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.glyph,
    required this.semantic,
    required this.enabled,
    required this.onTap,
    required this.color,
    required this.rule,
  });

  final String glyph;
  final String semantic;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;
  final Color rule;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: semantic,
    excludeSemantics: true,
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: CcStructure.card,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: CcStructure.targetMin,
          height: CcStructure.targetMin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: CcStructure.card,
            border: Border.all(color: rule, width: CcStructure.cardEdge),
          ),
          child: Text(
            glyph,
            style: TextStyle(
              fontFamily: ccContentFace,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}

/// ONB-02's two doors. Selection is the mark, the border weight and the printed
/// word — never colour alone.
class PathOption extends StatelessWidget {
  const PathOption({
    super.key,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $sub${selected ? ' Selected.' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: t.cardBorderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
          padding: const EdgeInsets.all(CcSpace.lg),
          decoration: BoxDecoration(
            color: t.stockRaised,
            borderRadius: t.cardBorderRadius,
            border: Border.all(
              color: selected ? t.signal : t.rule,
              width: selected ? 2 : CcStructure.cardEdge,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CcSpace.md,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? t.signal : t.inkMuted,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: t.signal,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: CcSpace.xs,
                  children: [
                    Text(
                      title,
                      style: context.ccText.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CcBody(sub, muted: true),
                  ],
                ),
              ),
              if (selected) FieldLabel('Selected', tone: CcTone.signal),
            ],
          ),
        ),
      ),
    );
  }
}
