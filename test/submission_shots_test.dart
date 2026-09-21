/// Renders the App Store submission screenshots at the sizes the console takes.
///
/// Run with:  flutter test test/submission_shots_test.dart
///            flutter test test/submission_shots_test.dart --dart-define=SHOT_DEVICE=ipad13
/// Output:    build/submission/*.png at 1284x2778 (6.5" iPhone)
///            build/submission-ipad/*.png at 2064x2752 (13" iPad)
///
/// This is deliberately separate from `render_shots_test.dart`, which renders
/// small design-review images at 824x1830 — a size App Store Connect rejects.
/// Two differences matter here:
///
///   1. **Size.** 428x926 logical at pixelRatio 3 is exactly 1284x2778 — the
///      6.5" iPhone size. That is the slot this app's App Store Connect
///      record actually offers, and it rejects anything else; a 6.9" frame
///      (1320x2868) is refused outright rather than scaled down.
///   2. **The paywall has a store.** `PurchaseService.forTest()` defaults to
///      `unavailable`, so the design-review shot renders the "Pro is not
///      available on this device" screen rather than the paywall. Apple's IAP
///      review screenshot has to show the actual purchase UI, so this file
///      supplies products at the real App Store Connect prices.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:calmcheck/data/helplines.dart';
import 'fixtures/sample_cards.dart';
import 'package:calmcheck/design/theme.dart';
import 'package:calmcheck/screens/cards/card_share_screen.dart';
import 'package:calmcheck/screens/cards/card_view_screen.dart';
import 'package:calmcheck/screens/crisis/crisis_screen.dart';
import 'package:calmcheck/screens/home/home_screen.dart';
import 'package:calmcheck/screens/panic/panic_pacer_screen.dart';
import 'package:calmcheck/screens/paywall/paywall_screen.dart';
import 'package:calmcheck/screens/settings/privacy_screen.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which device the frames are rendered for:
///
///     flutter test test/submission_shots_test.dart
///     flutter test test/submission_shots_test.dart --dart-define=SHOT_DEVICE=ipad13
///
/// App Store Connect asks for both when the binary declares iPad support
/// (`TARGETED_DEVICE_FAMILY = "1,2"`), and refuses the submission until the
/// iPad slot is filled — a phone-sized image will not stand in for it.
const _device = String.fromEnvironment('SHOT_DEVICE', defaultValue: 'iphone65');

/// Logical size, pixel ratio and output directory per device. The pixel sizes
/// these produce are the only ones the two slots accept:
///
///   iphone65  428x926 @3  = 1284x2778   (also takes 1242x2688)
///   ipad13   1032x1376 @2 = 2064x2752   (also takes 2048x2732)
class _Device {
  const _Device(this.logical, this.scale, this.out);

  final Size logical;
  final double scale;
  final String out;
}

const Map<String, _Device> _devices = {
  'iphone65': _Device(Size(428, 926), 3, 'build/submission'),
  'ipad13': _Device(Size(1032, 1376), 2, 'build/submission-ipad'),
};

final _Device _target = _devices[_device]!;
final Size _logical = _target.logical;
final double _scale = _target.scale;
final String _out = _target.out;

/// The real prices configured in App Store Connect, so the paywall shot shows
/// what a US customer actually sees rather than invented numbers.
final List<ProProduct> _storeProducts = [
  const ProProduct(
    id: ProProductIds.annual,
    title: 'CalmCheck Pro Annual',
    price: r'$19.99',
    rawPrice: 19.99,
    currencyCode: 'USD',
    freeTrialDays: 7,
  ),
  const ProProduct(
    id: ProProductIds.monthly,
    title: 'CalmCheck Pro Monthly',
    price: r'$2.99',
    rawPrice: 2.99,
    currencyCode: 'USD',
  ),
  const ProProduct(
    id: ProProductIds.lifetime,
    title: 'CalmCheck Pro Lifetime',
    price: r'$59.99',
    rawPrice: 59.99,
    currencyCode: 'USD',
  ),
];

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
    final dir = Directory.systemTemp.createTempSync('calmcheck-submission');
    state = await AppState.load(
      cardRepository: CardRepository(directory: dir),
      purchaseService: PurchaseService.forTest(
        availability: StoreAvailability.available,
        products: _storeProducts,
      ),
    );
    // The app ships no cards, so the shots supply their own.
    state.upsertCard(ravi);
    state.upsertCard(aanya);
    addTearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
  });

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget screen, {
    bool dark = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = _logical;
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

    // A screen that overflows its viewport by a hair leaves a half-cut control
    // at the bottom edge, which reads as a rendering bug in a marketing frame
    // rather than as "there is more below". Where the slack is small — the
    // card view on iPad is the case that prompted this — show the end of the
    // screen instead of the middle of a button. Longer screens are left where
    // they are; scrolling those away from the top would change the subject.
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      final position = tester
          .state<ScrollableState>(scrollables.first)
          .position;
      if (position.maxScrollExtent > 0 && position.maxScrollExtent <= 240) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    late ui.Image image;
    await tester.runAsync(() async {
      image = await boundary.toImage(pixelRatio: _scale);
    });
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    tester.takeException();
  }

  testWidgets('submission shots', (tester) async {
    // The six the design specifies, in the order the design specifies —
    // the order is the pitch. See docs/store-submission.md section 8.
    await shot(tester, '01-home', const HomeScreen());
    await shot(tester, '02-panic', const PanicPacerScreen());
    await shot(tester, '03-card-view', CardViewScreen(previewCard: ravi));
    await shot(
      tester,
      '04-share',
      CardShareScreen(cardId: state.cards.first.id),
    );
    await shot(tester, '05-privacy', const PrivacyScreen());
    await shot(tester, '06-crisis', const CrisisScreen());

    // Not a marketing shot: this is the one Apple wants attached to each
    // in-app purchase as review information.
    await shot(tester, '07-paywall', const PaywallScreen());
  });
}
