/// One button component, three variants. Minimum target 48; the large size is
/// 56 so a primary action can be hit one-handed without aiming.
library;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';
import '../services/haptics.dart';

enum CcButtonVariant { primary, secondary, quiet, destructive }

enum CcButtonSize { md, lg }

class CcButton extends StatelessWidget {
  const CcButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = CcButtonVariant.primary,
    this.size = CcButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
    this.loadingLabel,
    this.haptic = CcHaptic.pressFirm,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final CcButtonVariant variant;
  final CcButtonSize size;
  final bool fullWidth;

  /// The button says what it is doing instead of spinning at you.
  final bool loading;
  final String? loadingLabel;
  final CcHaptic? haptic;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    final text = loading ? (loadingLabel ?? label) : label;
    final enabled = onPressed != null && !loading;

    void handle() {
      if (haptic != null) CcHaptics.instance.fire(haptic!);
      onPressed!();
    }

    final minHeight = size == CcButtonSize.lg ? 56.0 : CcStructure.targetMin;

    // The label's ink is named per variant. The text theme's colour is for text
    // sitting on stock, and a filled button is not stock.
    final ink = switch (variant) {
      CcButtonVariant.primary => t.signalInk,
      CcButtonVariant.destructive => t.alertInk,
      CcButtonVariant.secondary => t.ink,
      CcButtonVariant.quiet => t.inkMuted,
    };

    final textStyle =
        (size == CcButtonSize.lg
                ? context.ccText.bodyLarge
                : context.ccText.bodyMedium)!
            .copyWith(fontWeight: FontWeight.w700, height: 1.2, color: ink);

    final child = Text(
      text,
      textAlign: TextAlign.center,
      style: variant == CcButtonVariant.quiet
          ? textStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: t.inkMuted,
            )
          : textStyle,
    );

    final button = switch (variant) {
      CcButtonVariant.primary => FilledButton(
        onPressed: enabled ? handle : null,
        style: FilledButton.styleFrom(
          backgroundColor: t.signal,
          foregroundColor: t.signalInk,
          minimumSize: Size(CcStructure.targetMin, minHeight),
          shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.xl,
            vertical: CcSpace.md,
          ),
        ),
        child: child,
      ),
      CcButtonVariant.destructive => FilledButton(
        onPressed: enabled ? handle : null,
        style: FilledButton.styleFrom(
          backgroundColor: t.alert,
          foregroundColor: t.alertInk,
          minimumSize: Size(CcStructure.targetMin, minHeight),
          shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.xl,
            vertical: CcSpace.md,
          ),
        ),
        child: child,
      ),
      CcButtonVariant.secondary => OutlinedButton(
        onPressed: enabled ? handle : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.inkMuted, width: CcStructure.cardEdge),
          minimumSize: Size(CcStructure.targetMin, minHeight),
          shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.xl,
            vertical: CcSpace.md,
          ),
        ),
        child: child,
      ),
      // Quiet is quiet, not invisible: without an edge it read as a caption
      // and people did not know it could be pressed.
      CcButtonVariant.quiet => OutlinedButton(
        onPressed: enabled ? handle : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: t.inkMuted,
          side: BorderSide(color: t.rule, width: CcStructure.cardEdge),
          minimumSize: Size(CcStructure.targetMin, minHeight),
          shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
          padding: const EdgeInsets.symmetric(
            horizontal: CcSpace.md,
            vertical: CcSpace.md,
          ),
        ),
        child: child,
      ),
    };

    final wrapped = Semantics(
      button: true,
      label: semanticLabel,
      child: fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );

    return wrapped;
  }
}

/// The two quiet routes that sit at the foot of HOME. Small, uppercase, and
/// always there — the crisis route is one tap from the home screen.
class QuietLink extends StatelessWidget {
  const QuietLink(this.label, {super.key, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: t.cardBorderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: CcStructure.targetMin),
          // A hairline edge and a faint ground: still the quietest control in
          // the app, but unmistakably a control rather than a caption.
          decoration: BoxDecoration(
            color: t.stockRaised,
            borderRadius: t.cardBorderRadius,
            border: Border.all(color: t.rule, width: CcStructure.cardEdge),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CcSpace.md,
              vertical: CcSpace.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CcSpace.sm,
              children: [
                if (icon != null) Icon(icon, size: 18, color: t.inkMuted),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    style: context.ccText.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
