/// What Pro is allowed to do to somebody.
///
/// Two rules matter more than the rest: Pro must not evaporate when the phone
/// is offline, and a build published before the store products exist must be a
/// complete app rather than a crippled one.
library;

import 'dart:io';

import 'package:calmcheck/models/care_card.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> boot({
  StoreAvailability store = StoreAvailability.unavailable,
  bool pro = false,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final dir = Directory.systemTemp.createTempSync('calmcheck-pro');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return AppState.load(
    cardRepository: CardRepository(directory: dir),
    purchaseService: PurchaseService.forTest(availability: store, pro: pro),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what is for sale', () {
    test('no products means no paywall and nothing locked', () async {
      final app = await boot();
      expect(app.proOffered, isFalse, reason: 'nothing to sell, nothing shown');
      expect(app.isPro, isTrue, reason: 'and so nothing withheld');
      expect(app.canCreateCard, isTrue);
      expect(app.canExportPdf, isTrue);
    });

    test('products present means the gates apply', () async {
      final app = await boot(store: StoreAvailability.available);
      expect(app.proOffered, isTrue);
      expect(app.isPro, isFalse);
      expect(app.canExportPdf, isFalse);
    });

    test('a purchase unlocks everything', () async {
      final app = await boot(store: StoreAvailability.available, pro: true);
      expect(app.isPro, isTrue);
      expect(app.canExportPdf, isTrue);
      expect(app.proStatus, ProStatus.subscribed);
    });

    test('while the store is still being asked, gates stay closed', () async {
      final app = await boot(store: StoreAvailability.unknown);
      expect(app.proOffered, isFalse, reason: 'do not offer what is unknown');
      expect(
        app.isPro,
        isFalse,
        reason:
            'an unanswered store grants nothing — otherwise every cold start '
            'unlocked Pro for as long as the query took. A subscriber is '
            'covered by the cached entitlement, not by this window.',
      );
      expect(app.canCreateCard, isTrue, reason: 'the first card stays free');
    });
  });

  group('the free floor', () {
    test('the first card is free even with a store selling Pro', () async {
      final app = await boot(store: StoreAvailability.available);
      for (final card in app.cards.toList()) {
        app.deleteCard(card.id);
      }
      expect(app.canCreateCard, isTrue);
    });

    test('a fresh install ships no cards of its own', () async {
      final app = await boot(store: StoreAvailability.available);
      expect(
        app.cards,
        isEmpty,
        reason: 'nothing is bundled — every card is one somebody made or was sent',
      );
      expect(
        app.canCreateCard,
        isTrue,
        reason: 'a new install must not route "create your first card" to the '
            'paywall',
      );
    });

    test('a card someone else shared does not use up the free slot', () async {
      final app = await boot(store: StoreAvailability.available);
      app.upsertCard(
        CareCardData(
          id: 'card-received',
          name: 'Nan',
          readOnly: true,
          sharedBy: 'Sonia',
          preparedAt: DateTime.now(),
        ),
      );
      expect(app.canCreateCard, isTrue);
    });

    test('a lapsed subscription keeps every card readable', () async {
      final app = await boot(
        store: StoreAvailability.available,
        prefs: const {'proEverPurchased': true},
      );
      // The person made a card of their own while subscribed.
      app.upsertCard(
        CareCardData(id: 'card-own', name: 'Nan', preparedAt: DateTime.now()),
      );
      expect(app.proStatus, ProStatus.expired);
      expect(app.cards, isNotEmpty, reason: 'nothing is taken away');
      expect(app.canCreateCard, isFalse, reason: 'but no new ones');
      expect(app.canExportPdf, isFalse);
    });
  });

  group('entitlement cache', () {
    test(
      'a cached purchase survives a launch with no store reachable',
      () async {
        final service = PurchaseService.forTest(pro: true);
        SharedPreferences.setMockInitialValues({
          'proActive': true,
          'proProductId': ProProductIds.annual,
          'proEverPurchased': true,
        });
        await service.init(await SharedPreferences.getInstance());

        expect(
          service.isPro,
          isTrue,
          reason: 'a failed query must never revoke Pro',
        );
      },
    );
  });

  test('every product id is one the stores accept', () {
    final valid = RegExp(r'^[a-z0-9_.]+$');
    for (final id in ProProductIds.all) {
      expect(valid.hasMatch(id), isTrue, reason: id);
    }
    expect(ProProductIds.isSubscription(ProProductIds.annual), isTrue);
    expect(ProProductIds.isSubscription(ProProductIds.lifetime), isFalse);
  });
}
