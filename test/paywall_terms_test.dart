/// The terms under the prices are what somebody agrees to when they tap
/// Continue, so they must describe the plan that is selected.
///
/// Build 3 always said "$19.99 a year. Cancel any time." — with Lifetime
/// selected, and while hiding the annual plan's free trial — and told a
/// lifetime buyer their purchase renews yearly.
library;

import 'dart:io';

import 'package:calmcheck/data/helplines.dart';
import 'package:calmcheck/design/theme.dart';
import 'package:calmcheck/screens/paywall/paywall_screen.dart';
import 'package:calmcheck/screens/settings/settings_screen.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<ProProduct> _products = [
  ProProduct(
    id: ProProductIds.annual,
    title: 'CalmCheck Pro Annual',
    price: r'$19.99',
    rawPrice: 19.99,
    currencyCode: 'USD',
    freeTrialDays: 7,
  ),
  ProProduct(
    id: ProProductIds.monthly,
    title: 'CalmCheck Pro Monthly',
    price: r'$2.99',
    rawPrice: 2.99,
    currencyCode: 'USD',
  ),
  ProProduct(
    id: ProProductIds.lifetime,
    title: 'CalmCheck Pro Lifetime',
    price: r'$59.99',
    rawPrice: 59.99,
    currencyCode: 'USD',
  ),
];

/// [ownedProduct] is written where the entitlement cache lives, because the
/// service reads that cache at launch and would overwrite anything set sooner.
Future<AppState> _boot(
  WidgetTester tester, {
  List<ProProduct> products = _products,
  String? ownedProduct,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarded': true,
    if (ownedProduct != null) ...{
      'proActive': true,
      'proProductId': ownedProduct,
      'proEverPurchased': true,
    },
  });
  final dir = Directory.systemTemp.createTempSync('calmcheck-terms');
  addTearDown(() {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  final purchases = PurchaseService.forTest(
    availability: StoreAvailability.available,
    products: products,
  );
  return (await tester.runAsync(() async {
    await Helplines.instance.load();
    return AppState.load(
      cardRepository: CardRepository(directory: dir),
      purchaseService: purchases,
    );
  }))!;
}

Future<void> _pump(WidgetTester tester, AppState state, Widget screen) async {
  tester.view.devicePixelRatio = 1.0;
  // Tall enough that nothing the test looks for is below the fold.
  tester.view.physicalSize = const Size(412, 3200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(theme: calmLightTheme, home: screen),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('paywall terms follow the selected plan', () {
    testWidgets('annual shows its free trial', (tester) async {
      final state = await _boot(tester);
      await _pump(tester, state, const PaywallScreen());
      expect(
        find.text(r'7 days free, then $19.99 a year. Cancel any time.'),
        findsOneWidget,
      );
    });

    testWidgets('annual without a trial says so plainly', (tester) async {
      final state = await _boot(
        tester,
        products: [
          const ProProduct(
            id: ProProductIds.annual,
            title: 'CalmCheck Pro Annual',
            price: r'$19.99',
            rawPrice: 19.99,
            currencyCode: 'USD',
          ),
          ..._products.skip(1),
        ],
      );
      await _pump(tester, state, const PaywallScreen());
      expect(find.text(r'$19.99 a year. Cancel any time.'), findsOneWidget);
      expect(find.textContaining('days free'), findsNothing);
    });

    testWidgets('monthly and lifetime describe themselves', (tester) async {
      final state = await _boot(tester);
      await _pump(tester, state, const PaywallScreen());

      await tester.tap(find.text('Monthly'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(r'$2.99 a month. Cancel any time.'), findsOneWidget);
      // "Billed once a year" stays on the annual option; only the terms move.
      expect(find.textContaining(r'$19.99 a year'), findsNothing);

      await tester.tap(find.text('Lifetime'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text(r'$59.99 once. No subscription, nothing to renew.'),
        findsOneWidget,
      );
      expect(find.textContaining('Cancel any time'), findsNothing);
    });
  });

  group('a lifetime buyer is never told it renews', () {
    const lifetime = ProProductIds.lifetime;

    testWidgets('on the paywall', (tester) async {
      final state = await _boot(tester, ownedProduct: lifetime);
      await _pump(tester, state, const PaywallScreen());
      expect(find.text('You already have Pro.'), findsOneWidget);
      expect(find.textContaining('Renewal and cancellation'), findsNothing);
    });

    testWidgets('in Settings', (tester) async {
      final state = await _boot(tester, ownedProduct: lifetime);
      await _pump(tester, state, const SettingsScreen());
      expect(
        find.text('Lifetime. A single payment, nothing to renew.'),
        findsOneWidget,
      );
      expect(find.textContaining('Renews'), findsNothing);
    });

    testWidgets('a monthly subscriber is told monthly', (tester) async {
      final state = await _boot(tester, ownedProduct: ProProductIds.monthly);
      await _pump(tester, state, const SettingsScreen());
      expect(
        find.text('Renews monthly through the app store. Cancel any time.'),
        findsOneWidget,
      );
    });
  });
}
