/// Surfaces. `CalmScaffold` paints the card's stock; `AcuteScaffold` paints the
/// one ground the panic flow lives on and strips every piece of chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

class CalmScaffold extends StatelessWidget {
  const CalmScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.mode.isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: t.mode.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: t.stock,
        systemNavigationBarIconBrightness: t.mode.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: t.stock,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: child,
      ),
    );
  }
}

/// ACUTE is entered only from the panic action and is exclusive: no navigation
/// chrome, no counters, no progress, no monetization surface. Its theme is a
/// separate ThemeData, never a variant of CALM.
class AcuteScaffold extends StatelessWidget {
  const AcuteScaffold({super.key, required this.child, this.onSystemBack});

  final Widget child;

  /// The hardware back gesture is a deliberate exit, not a dump to home.
  final VoidCallback? onSystemBack;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: acuteTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: CcColors.stockAcute,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: PopScope(
          canPop: onSystemBack == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) onSystemBack?.call();
          },
          child: Scaffold(backgroundColor: CcColors.stockAcute, body: child),
        ),
      ),
    );
  }
}

/// The frame for the panic flow. Same measured-not-guessed structure as
/// [CcScreen], but with no card, no rule and no chrome — ground and one light.
class AcuteScreen extends StatelessWidget {
  const AcuteScreen({
    super.key,
    required this.children,
    this.top = CcSpace.xxxl,
  });

  final List<Widget> children;
  final double top;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              CcStructure.marginH,
              top,
              CcStructure.marginH,
              CcSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: CcSpace.xl,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The orb's box on a panic screen: generous, but never so tall that the exit
/// is pushed off the bottom when the type is at 200%.
double acuteOrbHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.42).clamp(200.0, 420.0);
