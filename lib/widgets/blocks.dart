/// Blocks: the alert frame, the three empty states, the destructive
/// confirmation, the QR panel and the grounding prompt.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import 'buttons.dart';
import 'primitives.dart';

/// A framed notice in the alert register. Used sparingly: `alert` belongs to
/// emergency contacts and CRISIS-01, and this block is the only other place it
/// may appear.
class AlertBlock extends StatelessWidget {
  const AlertBlock({super.key, required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border(
          left: BorderSide(color: t.alert, width: 6),
          top: BorderSide(color: t.alert, width: 2),
          right: BorderSide(color: t.alert, width: 2),
          bottom: BorderSide(color: t.alert, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.sm,
        children: [
          FieldLabel(label, tone: CcTone.alert),
          Text(body, style: context.ccText.bodyLarge),
        ],
      ),
    );
  }
}

/// A plain framed notice in the ink register — for facts that are neither an
/// alert nor a system failure.
class NoticeBlock extends StatelessWidget {
  const NoticeBlock({super.key, required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CcSpace.lg,
        vertical: CcSpace.md,
      ),
      decoration: BoxDecoration(
        color: t.stockRaised,
        border: Border(left: BorderSide(color: t.ink, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.xs,
        children: [FieldLabel(label), CcBody(body)],
      ),
    );
  }
}

/// One pattern for every empty and blocked state: a ghosted form of the missing
/// thing, one line of direction, one action. Never an apology, never a shrug.
class SystemState extends StatelessWidget {
  const SystemState({
    super.key,
    required this.label,
    required this.headline,
    required this.direction,
    this.ghost,
    this.action,
    this.alternative,
  });

  final String label;
  final String headline;
  final String direction;
  final Widget? ghost;
  final Widget? action;
  final Widget? alternative;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.lg),
      decoration: BoxDecoration(
        color: t.stock,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.sm,
        children: [
          if (ghost != null)
            Padding(
              padding: const EdgeInsets.only(bottom: CcSpace.xs),
              child: Opacity(opacity: 0.35, child: ghost),
            ),
          FieldLabel(label),
          Text(
            headline,
            style: context.ccText.bodyLarge!.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          CcBody(direction),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: CcSpace.sm),
              child: SizedBox(width: double.infinity, child: action),
            ),
          if (alternative != null)
            SizedBox(width: double.infinity, child: alternative),
        ],
      ),
    );
  }
}

/// The home-shelf empty state: a dashed frame around the ghost of the thing
/// that isn't there yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.headline,
    required this.body,
    this.ghost,
    this.action,
  });

  final String headline;
  final String body;
  final Widget? ghost;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return DottedFrame(
      color: t.rule,
      radius: t.radiusCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CcSpace.xl,
          vertical: CcSpace.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: CcSpace.lg,
          children: [
            if (ghost != null)
              Opacity(
                opacity: 0.42,
                child: FractionallySizedBox(widthFactor: 0.86, child: ghost),
              ),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: context.ccText.titleLarge,
            ),
            CcBody(body, align: TextAlign.center),
            if (action != null) SizedBox(width: double.infinity, child: action),
          ],
        ),
      ),
    );
  }
}

/// One wording, used everywhere a card is deleted. It says what is lost and
/// that it can't be undone; the destructive action is second.
class DestructiveConfirm extends StatelessWidget {
  const DestructiveConfirm({
    super.key,
    required this.title,
    required this.consequence,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String consequence;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String consequence,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final t = context.cc;
        return AlertDialog(
          backgroundColor: t.stockRaised,
          shape: RoundedRectangleBorder(
            borderRadius: t.cardBorderRadius,
            side: BorderSide(color: t.alert, width: 2),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            CcSpace.xl,
            CcSpace.xl,
            CcSpace.xl,
            CcSpace.md,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: CcSpace.xl),
          actionsPadding: const EdgeInsets.all(CcSpace.xl),
          title: Text(title, style: context.ccText.titleLarge),
          content: CcBody(consequence),
          actions: [
            // The destructive action is second, and it is never the default.
            CcButton(
              cancelLabel,
              variant: CcButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CcButton(
              confirmLabel,
              variant: CcButtonVariant.destructive,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.xl),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.alert, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.md,
        children: [
          Text(title, style: context.ccText.titleLarge),
          CcBody(consequence),
          Padding(
            padding: const EdgeInsets.only(top: CcSpace.sm),
            child: Row(
              spacing: CcSpace.md,
              children: [
                Expanded(
                  child: CcButton(
                    cancelLabel,
                    variant: CcButtonVariant.secondary,
                    onPressed: onCancel,
                  ),
                ),
                Expanded(
                  child: CcButton(
                    confirmLabel,
                    variant: CcButtonVariant.destructive,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The QR is the hero. A generous quiet zone on forced paper-white, sized to
/// scan from a screen at arm's length in poor light.
class QrPanel extends StatelessWidget {
  const QrPanel({super.key, required this.data, required this.caption});

  final String data;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.xl),
      decoration: BoxDecoration(
        color: t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.lg,
        children: [
          // Forced paper-white: a scanner doesn't have a theme.
          Container(
            constraints: const BoxConstraints(minWidth: 296, minHeight: 296),
            padding: const EdgeInsets.all(CcSpace.xl),
            decoration: const BoxDecoration(
              color: CcColors.paperWhite,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
            child: Center(
              // A tight box: qr_flutter lays itself out with a LayoutBuilder,
              // which has no intrinsic size, and CcScreen measures intrinsics.
              child: SizedBox(
                width: 248,
                height: 248,
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 248,
                  // A card with long notes can exceed what a QR code can hold.
                  // qr_flutter throws in that case, and an uncaught throw here
                  // put someone mid-crisis on the generic recovery surface
                  // instead of their card. Say what happened and point at the
                  // route that still works.
                  errorStateBuilder: (context, _) => const Padding(
                    padding: EdgeInsets.all(CcSpace.md),
                    child: Center(
                      child: Text(
                        'This card holds too much to fit in a code.\n'
                        'Save it as a PDF or share the file instead.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CcColors.paperBlack,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  gapless: true,
                  backgroundColor: CcColors.paperWhite,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: CcColors.paperBlack,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: CcColors.paperBlack,
                  ),
                ),
              ),
            ),
          ),
          CcCaption(caption, align: TextAlign.center),
        ],
      ),
    );
  }
}

/// PANIC-03. One prompt per screen. The count remaining is dots, never digits —
/// a number is a thing to fail at.
class SensePrompt extends StatelessWidget {
  const SensePrompt({
    super.key,
    required this.label,
    required this.prompt,
    required this.remaining,
    required this.total,
    required this.advanceLabel,
    required this.onAdvance,
  });

  final String label;
  final String prompt;
  final int remaining;
  final int total;
  final String advanceLabel;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Container(
      padding: const EdgeInsets.all(CcSpace.xl),
      decoration: BoxDecoration(
        color: t.isAcute ? Colors.transparent : t.stockRaised,
        borderRadius: t.cardBorderRadius,
        border: t.isAcute
            ? null
            : Border.all(color: t.rule, width: CcStructure.cardEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CcSpace.lg,
        children: [
          FieldLabel(label),
          Text(prompt, style: context.ccText.bodyLarge),
          Semantics(
            label: '$remaining of $total left',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.sm,
              children: [
                for (var i = 0; i < total; i++)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < total - remaining
                          ? t.inkMuted
                          : Colors.transparent,
                      border: Border.all(color: t.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
          CcButton(advanceLabel, onPressed: onAdvance, size: CcButtonSize.lg),
        ],
      ),
    );
  }
}

/// A dashed frame, painted rather than borrowed from an icon set.
class DottedFrame extends StatelessWidget {
  const DottedFrame({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedFramePainter(color: color, radius: radius),
    child: child,
  );
}

class _DashedFramePainter extends CustomPainter {
  const _DashedFramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
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

  @override
  bool shouldRepaint(covariant _DashedFramePainter old) =>
      old.color != color || old.radius != radius;
}

/// One sheet pattern for the whole app. CALM only — never in ACUTE.
Future<T?> showCcSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  final t = context.cc;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.stockRaised,
    barrierColor: CcColors.paperBlack.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) {
      final t = context.cc;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: CcStructure.marginH,
            right: CcStructure.marginH,
            top: CcSpace.md,
            bottom: CcSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: CcSpace.lg,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: CcSpace.sm),
                  decoration: BoxDecoration(
                    color: t.rule,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title, style: context.ccText.titleLarge),
              Flexible(child: SingleChildScrollView(child: builder(context))),
            ],
          ),
        ),
      );
    },
  );
}
