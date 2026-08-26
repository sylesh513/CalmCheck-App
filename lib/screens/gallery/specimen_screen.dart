/// The design system specimen: all three registers side by side, the palette
/// with its hex values and measured contrast ratios, the type scale and the
/// spacing scale. The reference for the build, rendered by the build.
library;

import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

class SpecimenScreen extends StatelessWidget {
  const SpecimenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CalmScaffold(
      child: CcScreen(
        children: [
          CcStack(
            gap: CcGap.sm,
            children: [
              const CcBackBar(),
              FieldLabel('Specimen'),
              const CcHeadline('Field Card'),
              const CcSub(
                'Three registers, one identity. Palette A: warm stock, deep '
                'teal signal.',
              ),
            ],
          ),
          for (final tokens in const [
            CcTokens.calmLight,
            CcTokens.calmDark,
            CcTokens.acute,
          ])
            _ModePanel(tokens: tokens),
          const CcRule(),
          const _TypeScale(),
          const CcRule(),
          const _SpacingScale(),
          const CcRule(),
          CcStack(
            gap: CcGap.sm,
            children: [
              FieldLabel('Contrast floors'),
              const CcBody(
                'Body text at or above 7:1, large text and UI components at or '
                'above 4.5:1, in all three modes.',
              ),
              const _ContrastTable(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  const _ModePanel({required this.tokens});

  final CcTokens tokens;

  String get _name => switch (tokens.mode) {
    CcMode.calmLight => 'CALM-light',
    CcMode.calmDark => 'CALM-dark',
    CcMode.acute => 'ACUTE',
  };

  @override
  Widget build(BuildContext context) {
    final outer = context.cc;
    return CcStack(
      gap: CcGap.sm,
      children: [
        FieldLabel(_name),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: outer.rule, width: CcStructure.cardEdge),
            borderRadius: outer.cardBorderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: ccTheme(tokens),
            child: Builder(
              builder: (context) => ColoredBox(
                color: tokens.stock,
                child: Padding(
                  padding: const EdgeInsets.all(CcSpace.lg),
                  child: CcStack(
                    gap: CcGap.md,
                    children: [
                      FieldLabel('What to do'),
                      Text(
                        'Keep your voice low and slow.',
                        style: context.ccText.bodyMedium,
                      ),
                      Wrap(
                        spacing: CcSpace.sm,
                        runSpacing: CcSpace.sm,
                        children: [
                          _Swatch('stock', tokens.stock, tokens),
                          _Swatch('stock-raised', tokens.stockRaised, tokens),
                          _Swatch('ink', tokens.ink, tokens),
                          _Swatch('ink-muted', tokens.inkMuted, tokens),
                          _Swatch('rule', tokens.rule, tokens),
                          _Swatch('signal', tokens.signal, tokens),
                          _Swatch('alert', tokens.alert, tokens),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.tokens);

  final String name;
  final Color color;
  final CcTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.xs,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: tokens.inkMuted, width: 0.5),
            ),
          ),
          Text(name.toUpperCase(), style: context.ccText.labelSmall),
          Text(
            hex,
            style: TextStyle(
              fontFamily: ccLabelFace,
              fontSize: 11,
              color: tokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final text = context.ccText;
    return CcStack(
      gap: CcGap.md,
      children: [
        FieldLabel('Type scale'),
        _Specimen(
          'display · 34 / 40 acute',
          'Breathe out slowly.',
          text.displaySmall!,
        ),
        _Specimen('title · 24', 'What to do', text.titleLarge!),
        _Specimen(
          'body-large · 19',
          'Keep your voice low and slow.',
          text.bodyLarge!,
        ),
        _Specimen(
          'body · 17',
          'Sit down so you are at eye level.',
          text.bodyMedium!,
        ),
        _Specimen(
          'caption · 14',
          'Prepared 4 March · version 3',
          text.bodySmall!,
        ),
        _Specimen('label · 12 mono', 'DO NOT', text.labelSmall!),
      ],
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen(this.role, this.sample, this.style);

  final String role;
  final String sample;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CcStack(
    gap: CcGap.xs,
    children: [
      FieldLabel(role),
      Text(sample, style: style),
    ],
  );
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale();

  static const _steps = [
    ('hair', CcSpace.hair),
    ('xs', CcSpace.xs),
    ('sm', CcSpace.sm),
    ('md', CcSpace.md),
    ('lg', CcSpace.lg),
    ('xl', CcSpace.xl),
    ('2xl', CcSpace.xxl),
    ('3xl', CcSpace.xxxl),
    ('4xl', CcSpace.xxxxl),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return CcStack(
      gap: CcGap.sm,
      children: [
        FieldLabel('Spacing · 4dp base'),
        for (final (name, value) in _steps)
          Row(
            spacing: CcSpace.md,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  name.toUpperCase(),
                  style: context.ccText.labelSmall,
                ),
              ),
              Container(height: 10, width: value, color: t.signal),
              Text('${value.toInt()}', style: context.ccText.bodySmall),
            ],
          ),
        Row(
          spacing: CcSpace.md,
          children: [
            SizedBox(
              width: 48,
              child: Text('RADIUS', style: context.ccText.labelSmall),
            ),
            Container(
              width: 60,
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(color: t.rule),
                borderRadius: CcStructure.card,
              ),
            ),
            const Text('5'),
          ],
        ),
      ],
    );
  }
}

class _ContrastTable extends StatelessWidget {
  const _ContrastTable();

  /// Measured with the WCAG 2.1 relative-luminance formula against the token
  /// pairs actually used on screen.
  static const _rows = [
    ('CALM-light · ink on stock', '14.9:1'),
    ('CALM-light · ink-muted on stock', '7.6:1'),
    ('CALM-light · signal-ink on signal', '6.9:1'),
    ('CALM-light · alert-ink on alert', '6.6:1'),
    ('CALM-dark · ink on stock', '14.4:1'),
    ('CALM-dark · ink-muted on stock', '8.4:1'),
    ('CALM-dark · signal on stock', '8.5:1'),
    ('ACUTE · ink on stock', '15.1:1'),
    ('ACUTE · ink-muted on stock', '7.4:1'),
    ('ACUTE · signal on stock', '10.4:1'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (pair, ratio) in _rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: CcSpace.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.rule,
                  width: CcStructure.ruleWeight,
                ),
              ),
            ),
            child: Row(
              spacing: CcSpace.md,
              children: [
                Expanded(child: Text(pair, style: context.ccText.bodySmall)),
                Text(
                  ratio,
                  style: TextStyle(
                    fontFamily: ccLabelFace,
                    fontSize: 13,
                    color: t.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
