/// The structural half of the Field Card system: micro-labels, rules, stacks,
/// field rows, and the screen frame every page is built in.
library;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

enum CcTone { neutral, signal, alert }

/// The signature device. A small uppercase field label sitting above its
/// content — the thing a stranger scans for. Uppercased at the call site, never
/// faked by style.
class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.text, {
    super.key,
    this.tone = CcTone.neutral,
    this.align,
  });

  final String text;
  final CcTone tone;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final color = switch (tone) {
      CcTone.neutral => t.inkMuted,
      CcTone.signal => t.signal,
      CcTone.alert => t.alert,
    };
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: context.ccText.labelSmall!.copyWith(color: color),
      ),
    );
  }
}

/// A hairline rule the way a printed form draws one. Never thicker, never
/// doubled, and never present in ACUTE.
class CcRule extends StatelessWidget {
  const CcRule({super.key, this.inset = false});

  final bool inset;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    if (t.isAcute) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: inset ? CcStructure.marginH : 0,
      ),
      child: Container(height: CcStructure.ruleWeight, color: t.rule),
    );
  }
}

enum CcGap { xs, sm, md, lg, xl, xxl }

double gapValue(CcGap gap) => switch (gap) {
  CcGap.xs => CcSpace.xs,
  CcGap.sm => CcSpace.sm,
  CcGap.md => CcSpace.md,
  CcGap.lg => CcSpace.lg,
  CcGap.xl => CcSpace.xl,
  CcGap.xxl => CcSpace.xxl,
};

/// A vertical stack with one of the named gaps. Nothing in the app sets an
/// arbitrary margin.
class CcStack extends StatelessWidget {
  const CcStack({
    super.key,
    required this.children,
    this.gap = CcGap.md,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CcGap gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    spacing: gapValue(gap),
    children: children,
  );
}

/// Label above, content below. Deliberately not a ListTile — its paddings are
/// wrong for printed matter.
class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.label,
    required this.child,
    this.tone = CcTone.neutral,
    this.divided = true,
  });

  final String label;
  final Widget child;
  final CcTone tone;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CcSpace.lg),
      decoration: divided && !t.isAcute
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.rule,
                  width: CcStructure.ruleWeight,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.sm,
        children: [
          FieldLabel(label, tone: tone),
          child,
        ],
      ),
    );
  }
}

/// Body copy at the app's reading size.
class CcBody extends StatelessWidget {
  const CcBody(this.text, {super.key, this.muted = false, this.align});

  final String text;
  final bool muted;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: muted
        ? context.ccText.bodyMedium!.copyWith(color: context.cc.inkMuted)
        : context.ccText.bodyMedium,
  );
}

/// The sub-line under a headline.
class CcSub extends StatelessWidget {
  const CcSub(this.text, {super.key, this.align});

  final String text;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: context.ccText.bodyLarge!.copyWith(color: context.cc.inkMuted),
  );
}

/// The screen headline, set in the display role.
class CcHeadline extends StatelessWidget {
  const CcHeadline(this.text, {super.key, this.align, this.scale = 1.0});

  final String text;
  final TextAlign? align;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final base = context.ccText.displaySmall!;
    return Text(
      text,
      textAlign: align,
      style: scale == 1.0
          ? base
          : base.copyWith(fontSize: base.fontSize! * scale),
    );
  }
}

/// A caption or helper line.
class CcCaption extends StatelessWidget {
  const CcCaption(
    this.text, {
    super.key,
    this.align,
    this.tone = CcTone.neutral,
  });

  final String text;
  final TextAlign? align;
  final CcTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final color = switch (tone) {
      CcTone.neutral => t.inkMuted,
      CcTone.signal => t.signal,
      CcTone.alert => t.alert,
    };
    return Text(
      text,
      textAlign: align,
      style: context.ccText.bodySmall!.copyWith(color: color),
    );
  }
}

enum CcAlign { start, center, between }

/// The frame every page is built in.
///
/// Content fills the viewport when it fits and scrolls when it doesn't, so a
/// layout at 200% text scale reflows rather than clipping or pushing a primary
/// action off-screen. The column is measured, never intrinsically guessed —
/// which is what lets a screen hold a camera preview or a QR code without the
/// layout falling over.
///
/// Because the height is unbounded during layout, no child of a [CcScreen] may
/// be an [Expanded] or a [Spacer]. Push things apart with [CcAlign.between].
class CcScreen extends StatelessWidget {
  const CcScreen({
    super.key,
    required this.children,
    this.align = CcAlign.start,
    this.gap = CcGap.xl,
    this.padded = true,
    this.top = CcSpace.xxl,
    this.bottom = CcSpace.xl,
    this.controller,
  });

  final List<Widget> children;
  final CcAlign align;
  final CcGap gap;
  final bool padded;
  final double top;
  final double bottom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final mainAxis = switch (align) {
      CcAlign.start => MainAxisAlignment.start,
      CcAlign.center => MainAxisAlignment.center,
      CcAlign.between => MainAxisAlignment.spaceBetween,
    };

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: controller,
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: padded
                  ? EdgeInsets.fromLTRB(
                      CcStructure.marginH,
                      top,
                      CcStructure.marginH,
                      bottom,
                    )
                  : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: mainAxis,
                spacing: gapValue(gap),
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two things pushed to opposite ends of a line, that fall onto two lines
/// rather than colliding when the type grows.
class CcSpread extends StatelessWidget {
  const CcSpread({super.key, required this.children, this.gap = CcSpace.md});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: gap,
    runSpacing: CcSpace.xs,
    children: children,
  );
}

/// A back affordance for CALM screens. Never used in ACUTE — the panic flow has
/// no navigation chrome.
class CcBackBar extends StatelessWidget {
  const CcBackBar({super.key, this.label = 'Back', this.onBack});

  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
          borderRadius: t.cardBorderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
            child: Padding(
              padding: const EdgeInsets.only(right: CcSpace.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: CcSpace.sm,
                children: [
                  Icon(Icons.arrow_back, size: 20, color: t.inkMuted),
                  Text(label.toUpperCase(), style: context.ccText.labelSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
