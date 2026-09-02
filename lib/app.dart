import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'design/motion.dart';
import 'design/theme.dart';
import 'data/exercises.dart';
import 'routes.dart';
import 'screens/cards/card_edit_screen.dart';
import 'screens/cards/card_empty_screen.dart';
import 'screens/cards/card_scan_screen.dart';
import 'screens/cards/card_share_screen.dart';
import 'screens/cards/card_view_screen.dart';
import 'screens/crisis/crisis_screen.dart';
import 'screens/exercises/exercise_detail_screen.dart';
import 'screens/exercises/exercise_library_screen.dart';
import 'screens/gallery/gallery_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/legal/legal_screens.dart';
import 'screens/onboarding/onboarding_screens.dart';
import 'screens/panic/panic_check_in_screen.dart';
import 'screens/panic/panic_grounding_screen.dart';
import 'screens/panic/panic_pacer_screen.dart';
import 'screens/panic/panic_rise_screen.dart';
import 'screens/paywall/lifecycle_screen.dart';
import 'screens/paywall/manage_subscription_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/paywall/sponsored_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/breathing_pace_screen.dart';
import 'screens/settings/display_screen.dart';
import 'screens/settings/helpline_region_screen.dart';
import 'screens/settings/privacy_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/your_person_screen.dart';
import 'state/app_state.dart';
import 'transitions.dart';

/// How far the OS text-size setting may push past the in-app choice before the
/// layouts stop holding. The app is verified to 200%.
const double _maxSystemTextBoost = 2.0;

class CalmCheckApp extends StatefulWidget {
  const CalmCheckApp({super.key, required this.state});

  final AppState state;

  @override
  State<CalmCheckApp> createState() => _CalmCheckAppState();
}

class _CalmCheckAppState extends State<CalmCheckApp>
    with WidgetsBindingObserver {
  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // A card edit is never lost to a process kill: whatever is queued is on
    // disk before the app leaves the foreground.
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.detached) {
      unawaited(state.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return MaterialApp(
            title: 'CalmCheck',
            debugShowCheckedModeBanner: false,
            theme: calmLightTheme,
            darkTheme: calmDarkTheme,
            themeMode: switch (state.themeChoice) {
              ThemeChoice.system => ThemeMode.system,
              ThemeChoice.light => ThemeMode.light,
              ThemeChoice.dark => ThemeMode.dark,
            },
            initialRoute: state.onboarded
                ? Routes.home
                : Routes.onboardingPromise,
            // Exactly one route on launch. The default initial-route handling
            // splits a multi-segment name ('/onboarding/promise') and pushes a
            // route for every prefix — and because _onGenerateRoute has a
            // catch-all, each prefix became a fully functional HomeScreen
            // underneath: one Android back press from the first onboarding
            // screen skipped the safety disclaimer and landed on Home.
            onGenerateInitialRoutes: (initialRoute) => [
              _onGenerateRoute(RouteSettings(name: initialRoute))!,
            ],
            onGenerateRoute: _onGenerateRoute,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  // The in-app control multiplies the OS setting rather than
                  // replacing it: someone who already asked for 130% system-wide
                  // must not silently get 100% here just because they have not
                  // found the in-app slider.
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: state.textScale,
                    maxScaleFactor: state.textScale * _maxSystemTextBoost,
                  ),
                  // Reduce motion is a setting as well as an OS preference.
                  disableAnimations:
                      media.disableAnimations || state.reduceMotion,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final args = settings.arguments;

  Route<dynamic> calm(Widget page) =>
      CalmPageRoute(page: page, settings: settings);

  return switch (settings.name) {
    Routes.onboardingPromise => calm(const OnboardingPromiseScreen()),
    Routes.onboardingPaths => calm(const OnboardingPathsScreen()),
    Routes.onboardingPermissions => calm(const OnboardingPermissionsScreen()),
    Routes.onboardingScope => calm(const OnboardingScopeScreen()),
    Routes.home => calm(const HomeScreen()),

    // The fall into ACUTE. The room dims; it is never a cut.
    Routes.panicPacer => DimRoute(
      page: PanicPacerScreen(
        args: args is PacerArgs ? args : const PacerArgs(),
      ),
      settings: settings,
    ),
    Routes.panicGrounding => AcutePageRoute(
      page: const PanicGroundingScreen(),
      settings: settings,
    ),
    Routes.panicCheckIn => AcutePageRoute(
      page: const PanicCheckInScreen(),
      settings: settings,
    ),
    Routes.panicRise => RiseRoute(
      page: const PanicRiseScreen(),
      settings: settings,
    ),

    // Card and exercise routes carry an id argument. A missing or mistyped
    // argument (a stale deep link, a bad notification payload) falls back to
    // a sensible screen instead of throwing inside route generation.
    Routes.cardView => args is String
        ? calm(CardViewScreen(cardId: args))
        : calm(const HomeScreen()),
    Routes.cardEdit => calm(
      CardEditScreen(cardId: args is String ? args : null),
    ),
    Routes.cardShare => args is String
        ? calm(CardShareScreen(cardId: args))
        : calm(const HomeScreen()),
    Routes.cardScan => calm(const CardScanScreen()),
    Routes.cardEmpty => calm(const CardEmptyScreen()),

    Routes.exercises => calm(const ExerciseLibraryScreen()),
    Routes.exerciseDetail => args is String && exerciseById(args) != null
        ? calm(ExerciseDetailScreen(exerciseId: args))
        : calm(const ExerciseLibraryScreen()),

    Routes.crisis => calm(const CrisisScreen()),

    Routes.paywall => calm(PaywallScreen(entry: args is String ? args : null)),
    Routes.sponsored => calm(const SponsoredScreen()),
    Routes.manageSubscription => calm(const ManageSubscriptionScreen()),
    Routes.lifecycle => calm(
      LifecycleScreen(
        moment: args is LifecycleMoment ? args : LifecycleMoment.started,
      ),
    ),

    Routes.settings => calm(const SettingsScreen()),
    Routes.privacy => calm(const PrivacyScreen()),
    Routes.about => calm(const AboutScreen()),
    Routes.display => calm(const DisplayScreen()),
    Routes.breathingPace => calm(const BreathingPaceScreen()),
    Routes.helplineRegion => calm(const HelplineRegionScreen()),
    Routes.yourPerson => calm(const YourPersonScreen()),

    Routes.terms => calm(const TermsScreen()),
    Routes.privacyPolicy => calm(const PrivacyPolicyScreen()),

    // Debug only: the gallery shows paywall specimens with placeholder prices.
    Routes.onboardingFirstCard => calm(const OnboardingFirstCardScreen()),
    Routes.gallery when kDebugMode => calm(const GalleryScreen()),
    _ => calm(const HomeScreen()),
  };
}

/// Settle: 280ms, ease out, never bouncy.
class CalmPageRoute<T> extends PageRouteBuilder<T> {
  CalmPageRoute({required this.page, required RouteSettings settings})
    : super(
        settings: settings,
        transitionDuration: CcMotion.settle,
        reverseTransitionDuration: CcMotion.settle,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondary, child) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          if (reduced) {
            return FadeTransition(opacity: animation, child: child);
          }
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: CcMotion.settleCurve,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.012),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: CcMotion.settleCurve,
                    ),
                  ),
              child: child,
            ),
          );
        },
      );

  final Widget page;
}
