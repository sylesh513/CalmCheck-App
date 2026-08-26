/// CalmCheck — "Field Card" tokens.
///
/// Named constants only. There are no magic numbers anywhere else in the app;
/// where this file and a mockup disagree, this file wins.
library;

import 'package:flutter/widgets.dart';

/// Spacing scale — 4dp base.
class CcSpace {
  const CcSpace._();

  static const double hair = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;
}

class CcStructure {
  const CcStructure._();

  /// One card-stock radius, held everywhere.
  static const Radius cardRadius = Radius.circular(5);
  static const BorderRadius card = BorderRadius.all(cardRadius);

  /// Hairline rule weight. Never thicker, never doubled.
  static const double ruleWeight = 1;

  /// The one horizontal margin.
  static const double marginH = 20;

  /// Minimum interactive size, enforced everywhere including steppers.
  static const double targetMin = 48;

  /// Crisis call rows only — the largest targets in the app.
  static const double targetCrisis = 88;

  /// Emergency contact rows.
  static const double targetContact = 64;

  /// Bottom band reachable one-handed on 412x915.
  static const double thumbZoneFraction = 0.45;

  /// HOME: the share of the screen the door is designed to occupy. The Ground
  /// layout realises it by giving the door every pixel the card ledge does not
  /// need — which lands here on a 412x915 screen, and grows rather than clips
  /// when the type does.
  static const double doorFraction = 0.70;

  /// The card edge. Same weight as a rule, but it draws an object, not a divide.
  static const double cardEdge = 1;
}

/// The mode a surface is painted in. Three registers, one identity.
enum CcMode {
  /// The card printed on warm stock. The primary mode.
  calmLight,

  /// The same card printed on dark stock — not an inversion.
  calmDark,

  /// Panic flow only. One ground, one light, no rules, no raised surface.
  acute;

  bool get isAcute => this == CcMode.acute;
  bool get isDark => this != CcMode.calmLight;
}

/// Palette A — warm stock, deep teal signal. The shipped palette.
class CcColors {
  const CcColors._();

  // CALM-light
  static const Color stockLight = Color(0xFFF4EFE6);
  static const Color stockRaisedLight = Color(0xFFFBF8F2);
  static const Color inkLight = Color(0xFF1A1714);
  static const Color inkMutedLight = Color(0xFF4F4841);
  static const Color ruleLight = Color(0xFFD8D0C3);
  static const Color signalLight = Color(0xFF0B5F63);
  static const Color signalInkLight = Color(0xFFFBF8F2);
  static const Color alertLight = Color(0xFF8A3B12);
  static const Color alertInkLight = Color(0xFFFBF8F2);

  // CALM-dark
  static const Color stockDark = Color(0xFF1B1A17);
  static const Color stockRaisedDark = Color(0xFF232220);
  static const Color inkDark = Color(0xFFF2EDE4);
  static const Color inkMutedDark = Color(0xFFB8B1A6);
  static const Color ruleDark = Color(0xFF3A3833);
  static const Color signalDark = Color(0xFF5FC6C4);
  static const Color signalInkDark = Color(0xFF10201F);
  static const Color alertDark = Color(0xFFE4924F);
  static const Color alertInkDark = Color(0xFF201408);

  // ACUTE
  static const Color stockAcute = Color(0xFF121412);
  static const Color inkAcute = Color(0xFFEDE8DF);
  static const Color inkMutedAcute = Color(0xFFA9A49B);
  static const Color signalAcute = Color(0xFF7FD8D2);
  static const Color signalInkAcute = Color(0xFF0C1A19);
  static const Color alertAcute = Color(0xFFE4924F);
  static const Color alertInkAcute = Color(0xFF201408);
  static const Color ruleAcute = Color(0x00000000);

  /// Forced paper-white, for the QR quiet zone and the print layout. Both must
  /// stay white in every mode — a scanner and a printer don't have a theme.
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color paperBlack = Color(0xFF000000);
}

/// The resolved token set for one mode. Widgets read this, never a literal.
@immutable
class CcTokens {
  const CcTokens({
    required this.mode,
    required this.stock,
    required this.stockRaised,
    required this.ink,
    required this.inkMuted,
    required this.rule,
    required this.signal,
    required this.signalInk,
    required this.alert,
    required this.alertInk,
    required this.bodySize,
    required this.bodyLargeSize,
    required this.displaySize,
    required this.radiusCard,
  });

  final CcMode mode;
  final Color stock;
  final Color stockRaised;
  final Color ink;
  final Color inkMuted;
  final Color rule;
  final Color signal;
  final Color signalInk;
  final Color alert;
  final Color alertInk;
  final double bodySize;
  final double bodyLargeSize;
  final double displaySize;
  final double radiusCard;

  bool get isAcute => mode.isAcute;

  BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);

  static const CcTokens calmLight = CcTokens(
    mode: CcMode.calmLight,
    stock: CcColors.stockLight,
    stockRaised: CcColors.stockRaisedLight,
    ink: CcColors.inkLight,
    inkMuted: CcColors.inkMutedLight,
    rule: CcColors.ruleLight,
    signal: CcColors.signalLight,
    signalInk: CcColors.signalInkLight,
    alert: CcColors.alertLight,
    alertInk: CcColors.alertInkLight,
    bodySize: 17,
    bodyLargeSize: 19,
    displaySize: 34,
    radiusCard: 5,
  );

  static const CcTokens calmDark = CcTokens(
    mode: CcMode.calmDark,
    stock: CcColors.stockDark,
    stockRaised: CcColors.stockRaisedDark,
    ink: CcColors.inkDark,
    inkMuted: CcColors.inkMutedDark,
    rule: CcColors.ruleDark,
    signal: CcColors.signalDark,
    signalInk: CcColors.signalInkDark,
    alert: CcColors.alertDark,
    alertInk: CcColors.alertInkDark,
    bodySize: 17,
    bodyLargeSize: 19,
    displaySize: 34,
    radiusCard: 5,
  );

  /// Panic flow only. No elevation, no dividers, no cards.
  static const CcTokens acute = CcTokens(
    mode: CcMode.acute,
    stock: CcColors.stockAcute,
    stockRaised: CcColors.stockAcute,
    ink: CcColors.inkAcute,
    inkMuted: CcColors.inkMutedAcute,
    rule: CcColors.ruleAcute,
    signal: CcColors.signalAcute,
    signalInk: CcColors.signalInkAcute,
    alert: CcColors.alertAcute,
    alertInk: CcColors.alertInkAcute,
    bodySize: 22,
    bodyLargeSize: 26,
    displaySize: 40,
    radiusCard: 0,
  );

  static CcTokens of(CcMode mode) => switch (mode) {
    CcMode.calmLight => calmLight,
    CcMode.calmDark => calmDark,
    CcMode.acute => acute,
  };
}
