/// Renders every screen at the design canvas (412x915) at 100% and at 200%
/// text scale, and fails on any overflow, clip, or render error.
///
/// 200% is not an edge case here: a meaningful share of this app's users run
/// their phone there, and that is the population it is for. Where a layout
/// can't hold it must reflow, never shrink the type.
library;

import 'dart:io';

import 'package:calmcheck/design/theme.dart';
import 'package:calmcheck/data/helplines.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/models/care_card.dart';
import 'fixtures/sample_cards.dart';
import 'package:calmcheck/screens/cards/card_edit_screen.dart';
import 'package:calmcheck/screens/cards/card_empty_screen.dart';
import 'package:calmcheck/screens/cards/card_share_screen.dart';
import 'package:calmcheck/screens/cards/card_view_screen.dart';
import 'package:calmcheck/screens/crisis/crisis_screen.dart';
import 'package:calmcheck/screens/exercises/exercise_detail_screen.dart';
import 'package:calmcheck/screens/exercises/exercise_library_screen.dart';
import 'package:calmcheck/screens/gallery/gallery_screen.dart';
import 'package:calmcheck/screens/gallery/specimen_screen.dart';
import 'package:calmcheck/screens/home/home_screen.dart';
import 'package:calmcheck/screens/onboarding/onboarding_screens.dart';
import 'package:calmcheck/screens/panic/panic_check_in_screen.dart';
import 'package:calmcheck/screens/panic/panic_grounding_screen.dart';
import 'package:calmcheck/screens/panic/panic_pacer_screen.dart';
import 'package:calmcheck/screens/paywall/lifecycle_screen.dart';
import 'package:calmcheck/screens/paywall/manage_subscription_screen.dart';
import 'package:calmcheck/screens/paywall/paywall_screen.dart';
import 'package:calmcheck/screens/paywall/sponsored_screen.dart';
import 'package:calmcheck/screens/settings/about_screen.dart';
import 'package:calmcheck/screens/settings/breathing_pace_screen.dart';
import 'package:calmcheck/screens/settings/display_screen.dart';
import 'package:calmcheck/screens/settings/helpline_region_screen.dart';
import 'package:calmcheck/screens/settings/privacy_screen.dart';
import 'package:calmcheck/screens/settings/settings_screen.dart';
import 'package:calmcheck/screens/states/system_state_screens.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The primary canvas from the design brief.
const Size _canvas = Size(412, 915);

late AppState _state;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = _canvas;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    AppScope(
      state: _state,
      child: MaterialApp(
        theme: brightness == Brightness.light ? calmLightTheme : calmDarkTheme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: screen,
          ),
        ),
      ),
    ),
  );
  // Let one breath cycle's worth of frames run so the orb painters settle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() async {
    await Helplines.instance.load();
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('calmcheck-screens');
    _state = await AppState.load(
      cardRepository: CardRepository(directory: dir),
      purchaseService: PurchaseService.forTest(),
    );
    // The app ships no cards, so a screen that needs one gets it here.
    _state.upsertCard(ravi);
    _state.upsertCard(aanya);
    // Let every queued write land before the directory goes away.
    addTearDown(() async {
      await _flushAndRemove(dir);
    });
  });

  CareCardData sample() => _state.cards.first;

  /// Every screen in the build, by the name the design gives it.
  Map<String, Widget Function()> screens() => {
    'ONB-01 orb': () => const OnboardingPromiseScreen(),
    'ONB-01 type': () => const OnboardingPromiseTypeScreen(),
    'ONB-02': () => const OnboardingPathsScreen(),
    'ONB-03': () => const OnboardingPermissionsScreen(),
    'ONB-04': () => const OnboardingScopeScreen(),
    'HOME': () => const HomeScreen(),
    'HOME empty': () => const HomeScreen(forceEmpty: true),
    'PANIC-02': () => const PanicPacerScreen(),
    'PANIC-02 reduced': () =>
        const PanicPacerScreen(args: PacerArgs(forceReducedMotion: true)),
    'PANIC-03': () => const PanicGroundingScreen(),
    'PANIC-04': () => const PanicCheckInScreen(),
    'CARD-VIEW': () => CardViewScreen(cardId: sample().id),
    'CARD-VIEW minimal': () => CardViewScreen(
      previewCard: aanya.copyWith(
        doThis: aanya.doThis.take(2).toList(),
        dontDo: aanya.dontDo.take(1).toList(),
        call: aanya.call.take(1).toList(),
      ),
    ),
    'CARD-VIEW received': () => CardViewScreen(
      previewCard: aanya.copyWith(readOnly: true, sharedBy: 'Sonia'),
    ),
    'CARD-EDIT new': () => const CardEditScreen(),
    'CARD-EDIT existing': () => CardEditScreen(cardId: sample().id),
    'CARD-EMPTY': () => const CardEmptyScreen(),
    'CARD-SHARE': () => CardShareScreen(cardId: sample().id),
    'EX-01': () => const ExerciseLibraryScreen(),
    'EX-02 free': () => const ExerciseDetailScreen(exerciseId: 'paced'),
    'EX-02 locked': () => const ExerciseDetailScreen(exerciseId: 'box'),
    'CRISIS-01': () => const CrisisScreen(),
    'PAY-01 annual': () => const PaywallScreen(
      variant: PaywallVariant.annual,
      forcedState: PayState.free,
    ),
    'PAY-01 lifetime': () => const PaywallScreen(
      variant: PaywallVariant.lifetime,
      forcedState: PayState.free,
    ),
    'PAY-01 giveback': () => const PaywallScreen(
      variant: PaywallVariant.giveback,
      forcedState: PayState.free,
    ),
    'PAY-01 trial': () => const PaywallScreen(forcedState: PayState.trial),
    'PAY-01 subscribed': () =>
        const PaywallScreen(forcedState: PayState.subscribed),
    'PAY-01 error': () => const PaywallScreen(forcedState: PayState.error),
    'PAY-02 open': () =>
        const SponsoredScreen(forcedState: SponsoredState.open),
    'PAY-02 empty': () =>
        const SponsoredScreen(forcedState: SponsoredState.empty),
    'PAY-02 granted': () =>
        const SponsoredScreen(forcedState: SponsoredState.granted),
    'PAY-03 free': () =>
        const ManageSubscriptionScreen(forcedStatus: ProStatus.free),
    'PAY-03 expired': () =>
        const ManageSubscriptionScreen(forcedStatus: ProStatus.expired),
    'PAY-04 started': () =>
        const LifecycleScreen(moment: LifecycleMoment.started),
    'PAY-04 ending': () =>
        const LifecycleScreen(moment: LifecycleMoment.ending),
    'PAY-04 expired': () =>
        const LifecycleScreen(moment: LifecycleMoment.expired),
    'SET-01': () => const SettingsScreen(),
    'SET-02': () => const PrivacyScreen(),
    'SET-03': () => const AboutScreen(),
    'SET-04': () => const DisplayScreen(),
    'Breathing pace': () => const BreathingPaceScreen(),
    'Helpline region': () => const HelplineRegionScreen(),
    'State camera': () => const PermissionCameraScreen(),
    'State notifications': () => const PermissionNotificationsScreen(),
    'State purchase': () => const PurchaseFailedScreen(),
    'State empty cards': () => const EmptyCardsStateScreen(),
    'State empty exercises': () => const EmptyExercisesStateScreen(),
    'State empty scan': () => const EmptyScanStateScreen(),
    'State delete': () => const DeleteCardConfirmScreen(),
    'Specimen': () => const SpecimenScreen(),
    'Design reference': () => const GalleryScreen(),
  };

  for (final entry in screens().entries) {
    testWidgets('${entry.key} renders at 412x915', (tester) async {
      await _pump(tester, entry.value());
      expect(tester.takeException(), isNull);
    });

    testWidgets('${entry.key} renders at 200% text scale', (tester) async {
      await _pump(tester, entry.value(), textScale: 2.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${entry.key} renders on dark stock', (tester) async {
      await _pump(tester, entry.value(), brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Card writes are queued, so a test directory cannot be removed until the
/// queue has drained.
Future<void> _flushAndRemove(Directory dir) async {
  await Future<void>.delayed(const Duration(milliseconds: 40));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}
