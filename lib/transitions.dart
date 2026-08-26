/// The two designed transitions in the app.
///
/// `dim` is the fall from CALM into ACUTE — the room dimming, 780ms. `lift` is
/// the room coming back, 680ms, and slower still when the system theme is
/// CALM-light. Everything else settles in 280ms and never bounces.
library;

import 'package:flutter/material.dart';

import 'design/motion.dart';
import 'design/tokens.dart';

/// CALM -> ACUTE. A veil closes over the room, then the one light comes up
/// inside it. The two overlap, so it reads as dimming rather than a cut.
class DimRoute<T> extends PageRouteBuilder<T> {
  DimRoute({required this.page, required RouteSettings settings})
    : super(
        settings: settings,
        opaque: false,
        barrierColor: null,
        transitionDuration: CcMotion.dim,
        reverseTransitionDuration: CcMotion.lift,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          if (MediaQuery.disableAnimationsOf(context)) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0, 0.16),
              ),
              child: child,
            );
          }
          final veil = CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.62, curve: Curves.easeInOut),
          );
          final light = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.38, 1, curve: Curves.easeOut),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: FadeTransition(
                  opacity: veil,
                  child: const ColoredBox(color: CcColors.stockAcute),
                ),
              ),
              FadeTransition(opacity: light, child: child),
            ],
          );
        },
      );

  final Widget page;
}

/// Movement inside the panic flow. A quiet cross-fade — nothing else on screen
/// is allowed to move while the orb is breathing.
class AcutePageRoute<T> extends PageRouteBuilder<T> {
  AcutePageRoute({required this.page, required RouteSettings settings})
    : super(
        settings: settings,
        transitionDuration: CcMotion.settle,
        reverseTransitionDuration: CcMotion.settle,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
      );

  final Widget page;
}

/// Carries the rise screen in. The rise itself is animated inside the screen,
/// frame by frame, so nobody is dumped from a dark quiet screen straight onto
/// a bright one.
class RiseRoute<T> extends PageRouteBuilder<T> {
  RiseRoute({required this.page, required RouteSettings settings})
    : super(
        settings: settings,
        transitionDuration: CcMotion.settle,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  final Widget page;
}
