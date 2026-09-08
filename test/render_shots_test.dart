/// Renders screens to PNGs so the build can be looked at, not just asserted on.
/// Run with:  flutter test test/render_shots_test.dart
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'fixtures/sample_cards.dart';
import 'package:calmcheck/design/theme.dart';
import 'package:calmcheck/screens/cards/card_share_screen.dart';
import 'package:calmcheck/data/helplines.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/screens/cards/card_view_screen.dart';
import 'package:calmcheck/screens/crisis/crisis_screen.dart';
import 'package:calmcheck/screens/exercises/exercise_library_screen.dart';
import 'package:calmcheck/screens/home/home_screen.dart';
import 'package:calmcheck/screens/onboarding/onboarding_screens.dart';
import 'package:calmcheck/screens/panic/panic_pacer_screen.dart';
import 'package:calmcheck/screens/paywall/paywall_screen.dart';
import 'package:calmcheck/screens/settings/privacy_screen.dart';
import 'package:calmcheck/screens/settings/settings_screen.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Written into the build directory, which is not checked in.
const _out = 'build/shots';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      loader.addFont(rootBundle.load(p));
    }
    await loader.load();
  }

  await load('AtkinsonHyperlegible', [
    'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
  ]);
  await load('IBMPlexMono', [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ]);
}

void main() {
  late AppState state;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    Directory(_out).createSync(recursive: true);
  });

  setUp(() async {
    await Helplines.instance.load();
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final dir = Directory.systemTemp.createTempSync('calmcheck-shots');
    state = await AppState.load(
      cardRepository: CardRepository(directory: dir),
      purchaseService: PurchaseService.forTest(),
    );
    // The app ships no cards, so the shots supply their own.
    state.upsertCard(ravi);
    state.upsertCard(aanya);
    // Let every queued write land before the directory goes away.
    addTearDown(() async {
      await _flushAndRemove(dir);
    });
  });

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget screen, {
    bool dark = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          state: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? calmDarkTheme : calmLightTheme,
            home: screen,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2600));

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: 2);
    });
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    tester.takeException();
  }

  testWidgets('shots', (tester) async {
    await shot(tester, '01-onboarding', const OnboardingPromiseScreen());
    await shot(tester, '02-home', const HomeScreen());
    await shot(tester, '03-home-dark', const HomeScreen(), dark: true);
    await shot(tester, '04-panic', const PanicPacerScreen());
    await shot(tester, '05-card-view', CardViewScreen(previewCard: ravi));
    await shot(
      tester,
      '05b-card-no-contacts',
      CardViewScreen(previewCard: aanya.copyWith(call: const [])),
    );
    state.setRegion('IN');
    await shot(tester, '06-crisis-verified', const CrisisScreen());
    state.setRegion('JP');
    await shot(tester, '06b-crisis-no-line', const CrisisScreen());
    state.clearRegionOverride();
    await shot(tester, '07-paywall', const PaywallScreen());
    await shot(tester, '08-privacy', const PrivacyScreen());
    await shot(tester, '09-exercises', const ExerciseLibraryScreen());
    await shot(tester, '10-settings', const SettingsScreen());
    await shot(
      tester,
      '11-share',
      CardShareScreen(cardId: state.cards.first.id),
    );
    await shot(
      tester,
      '12-card-dark',
      CardViewScreen(previewCard: ravi),
      dark: true,
    );
  });
}

/// Card writes are queued, so a test directory cannot be removed until the
/// queue has drained.
Future<void> _flushAndRemove(Directory dir) async {
  await Future<void>.delayed(const Duration(milliseconds: 40));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}
