/// ThemeData for the three registers. ACUTE is a separate ThemeData, never a
/// variant of CALM: its type is larger, its dividers are transparent, and its
/// elevation is zero everywhere.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Content face — Atkinson Hyperlegible, Braille Institute of America,
/// SIL OFL 1.1. Chosen for disambiguated letterforms (1/l/I, 0/O, rn/m):
/// someone reading a medication name off a care card cannot afford to guess.
const String ccContentFace = 'AtkinsonHyperlegible';

/// Label face — IBM Plex Mono, IBM, SIL OFL 1.1. The micro-labels only.
const String ccLabelFace = 'IBMPlexMono';

TextTheme ccTextTheme(CcTokens t) {
  final ink = t.ink;
  final muted = t.inkMuted;
  return TextTheme(
    // display — the panic instruction and every screen headline
    displaySmall: TextStyle(
      fontFamily: ccContentFace,
      fontSize: t.displaySize,
      height: 1.15,
      letterSpacing: t.displaySize * -0.01,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    // title
    titleLarge: TextStyle(
      fontFamily: ccContentFace,
      fontSize: t.isAcute ? 28 : 24,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    // body-large
    bodyLarge: TextStyle(
      fontFamily: ccContentFace,
      fontSize: t.bodyLargeSize,
      height: 1.5,
      color: ink,
    ),
    // body
    bodyMedium: TextStyle(
      fontFamily: ccContentFace,
      fontSize: t.bodySize,
      height: 1.55,
      color: ink,
    ),
    // caption
    bodySmall: TextStyle(
      fontFamily: ccContentFace,
      fontSize: t.isAcute ? 16 : 14,
      height: 1.4,
      letterSpacing: 0.14,
      color: muted,
    ),
    // micro-label — always uppercased at the call site, never faked by style
    labelSmall: TextStyle(
      fontFamily: ccLabelFace,
      fontSize: 12,
      height: 1.2,
      letterSpacing: 1.44,
      fontWeight: FontWeight.w600,
      color: muted,
    ),
    labelMedium: TextStyle(
      fontFamily: ccLabelFace,
      fontSize: 14,
      height: 1.3,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w400,
      color: muted,
    ),
  );
}

ThemeData ccTheme(CcTokens t) {
  final brightness = t.mode.isDark ? Brightness.dark : Brightness.light;
  final text = ccTextTheme(t);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: t.stock,
    canvasColor: t.stock,
    splashFactory: t.isAcute ? NoSplash.splashFactory : InkRipple.splashFactory,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: t.signal,
      onPrimary: t.signalInk,
      secondary: t.signal,
      onSecondary: t.signalInk,
      error: t.alert,
      onError: t.alertInk,
      surface: t.stock,
      onSurface: t.ink,
      surfaceContainerHighest: t.stockRaised,
      onSurfaceVariant: t.inkMuted,
      outline: t.rule,
      outlineVariant: t.rule,
    ),
    dividerColor: t.rule,
    dividerTheme: DividerThemeData(
      color: t.rule,
      thickness: t.isAcute ? 0 : CcStructure.ruleWeight,
      space: 0,
    ),
    textTheme: text,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.signal,
      selectionColor: t.signal.withValues(alpha: 0.28),
      selectionHandleColor: t.signal,
    ),
    cardTheme: CardThemeData(
      color: t.stockRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: t.cardBorderRadius,
        side: BorderSide(color: t.rule, width: CcStructure.cardEdge),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.signal,
        foregroundColor: t.signalInk,
        disabledBackgroundColor: t.signal.withValues(alpha: 0.45),
        disabledForegroundColor: t.signalInk.withValues(alpha: 0.7),
        minimumSize: const Size(CcStructure.targetMin, CcStructure.targetMin),
        shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: CcSpace.xl,
          vertical: CcSpace.md,
        ),
        textStyle: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.ink,
        side: BorderSide(color: t.inkMuted, width: CcStructure.cardEdge),
        minimumSize: const Size(CcStructure.targetMin, CcStructure.targetMin),
        shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: CcSpace.xl,
          vertical: CcSpace.md,
        ),
        textStyle: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.inkMuted,
        minimumSize: const Size(CcStructure.targetMin, CcStructure.targetMin),
        shape: RoundedRectangleBorder(borderRadius: t.cardBorderRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: CcSpace.md,
          vertical: CcSpace.md,
        ),
        textStyle: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? t.signalInk : t.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? t.signal
            : Colors.transparent,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? t.signal : t.inkMuted,
      ),
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: t.signal,
      inactiveTrackColor: t.rule,
      thumbColor: t.signal,
      overlayColor: t.signal.withValues(alpha: 0.14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.stockRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.stockRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: t.cardBorderRadius,
        side: BorderSide(color: t.alert, width: 2),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.stock,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    iconTheme: IconThemeData(color: t.ink, size: 22),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(t.rule),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: <ThemeExtension<dynamic>>[CcThemeTokens(t)],
  );
}

/// Carries the resolved token set on the Theme so any widget can read it
/// without threading it through constructors.
@immutable
class CcThemeTokens extends ThemeExtension<CcThemeTokens> {
  const CcThemeTokens(this.tokens);

  final CcTokens tokens;

  @override
  CcThemeTokens copyWith({CcTokens? tokens}) =>
      CcThemeTokens(tokens ?? this.tokens);

  @override
  CcThemeTokens lerp(ThemeExtension<CcThemeTokens>? other, double t) {
    // Tokens are a discrete register, not a continuum. The dim and lift
    // transitions cross-fade whole surfaces instead of interpolating tokens.
    if (other is! CcThemeTokens) return this;
    return t < 0.5 ? this : other;
  }
}

final ThemeData calmLightTheme = ccTheme(CcTokens.calmLight);
final ThemeData calmDarkTheme = ccTheme(CcTokens.calmDark);
final ThemeData acuteTheme = ccTheme(CcTokens.acute);

extension CcThemeAccess on BuildContext {
  /// The token set for the surface this widget is painted on.
  CcTokens get cc =>
      Theme.of(this).extension<CcThemeTokens>()?.tokens ?? CcTokens.calmLight;

  TextTheme get ccText => Theme.of(this).textTheme;
}
