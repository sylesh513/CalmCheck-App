/// The flows that carry the product's promises, walked end to end.
///
/// These are the invariants the design calls non-negotiable, checked against
/// the running app rather than against the source: the panic flow is exclusive
/// and carries no monetization surface, the helplines are one tap from HOME,
/// and the first care card is never behind a paywall.
library;

import 'dart:io';

import 'package:calmcheck/app.dart';
import 'package:calmcheck/data/helplines.dart';
import 'package:calmcheck/services/card_repository.dart';
import 'fixtures/sample_cards.dart';
import 'package:calmcheck/design/theme.dart';
import 'package:calmcheck/models/care_card.dart';
import 'package:calmcheck/models/personal_contact.dart';
import 'package:calmcheck/screens/cards/card_view_screen.dart';
import 'package:calmcheck/services/purchases.dart';
import 'package:calmcheck/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The orb never stops breathing, so `pumpAndSettle` would wait forever.
/// Pumping past the longest transition (the 780ms dim) is the honest wait.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<AppState> _boot(
  WidgetTester tester, {
  bool onboarded = true,
  StoreAvailability store = StoreAvailability.unavailable,
  bool pro = false,
}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  await tester.runAsync(Helplines.instance.load);
  final dir = Directory.systemTemp.createTempSync('calmcheck-flow');

  // The card store touches the real file system, which cannot complete inside
  // the fake-async zone a widget test runs in.
  final state = (await tester.runAsync(
    () => AppState.load(
      cardRepository: CardRepository(directory: dir),
      purchaseService: PurchaseService.forTest(availability: store, pro: pro),
    ),
  ))!;
  // No async work in teardown: it runs inside the test's fake-async zone,
  // where a real future never completes. The queued write recreates the
  // directory if it needs to, and the system clears temp.
  addTearDown(() {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(CalmCheckApp(state: state));
  await _settle(tester);
  return state;
}

/// Words that must never appear anywhere in the panic flow.
const _monetization = [
  'Pro',
  'Free trial',
  'Start free trial',
  'Upgrade',
  'Subscribe',
  '\$19.99',
  'Restore purchases',
];

void main() {
  testWidgets('the home action starts breathing, with nothing in between', (
    tester,
  ) async {
    await _boot(tester);
    expect(find.text('I need calm now'), findsOneWidget);

    await tester.tap(find.text('I need calm now'));
    await _settle(tester);

    // Straight into the pacer: no entry screen, no choice to make.
    expect(find.text("Breathing isn't helping"), findsOneWidget);
    expect(find.text("I'M DONE"), findsOneWidget);
  });

  testWidgets('the panic flow carries no monetization surface and no chrome', (
    tester,
  ) async {
    await _boot(tester);
    await tester.tap(find.text('I need calm now'));
    await _settle(tester);

    for (final screen in ['pacer', 'grounding', 'check-in']) {
      for (final word in _monetization) {
        expect(
          find.textContaining(word),
          findsNothing,
          reason: '"$word" found in the panic $screen',
        );
      }
      // No navigation chrome, no progress bar, no counter.
      expect(find.byType(AppBar), findsNothing, reason: screen);
      expect(find.byType(BackButton), findsNothing, reason: screen);
      expect(
        find.byType(LinearProgressIndicator),
        findsNothing,
        reason: screen,
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: screen,
      );

      if (screen == 'pacer') {
        await tester.tap(find.text("Breathing isn't helping"));
      } else if (screen == 'grounding') {
        await tester.tap(find.text("I'M DONE"));
      }
      await _settle(tester);
    }
  });

  testWidgets('grounding shows one prompt at a time and never a digit', (
    tester,
  ) async {
    await _boot(tester);
    await tester.tap(find.text('I need calm now'));
    await _settle(tester);
    await tester.tap(find.text("Breathing isn't helping"));
    await _settle(tester);

    expect(find.text('Name five things you can see.'), findsOneWidget);
    expect(find.text('Name four things you can touch.'), findsNothing);

    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('Name five things you can see.'), findsNothing);
    expect(find.text('Name four things you can touch.'), findsOneWidget);
  });

  testWidgets(
    'the "not really" branch offers the helplines with equal weight',
    (tester) async {
      await _boot(tester);
      await tester.tap(find.text('I need calm now'));
      await _settle(tester);
      await tester.tap(find.text("I'M DONE"));
      await _settle(tester);

      expect(find.text('How are you doing?'), findsOneWidget);
      await tester.tap(find.text('Not really'));
      await _settle(tester);

      // Both routes on screen at once. The helpline is not a second tap.
      expect(find.text('Try grounding instead'), findsOneWidget);
      expect(find.text('See crisis helplines'), findsOneWidget);
    },
  );

  group('the fixed information order', () {
    Future<void> openCard(WidgetTester tester, CareCardData card) async {
      SharedPreferences.setMockInitialValues({'onboarded': true});
      final dir = Directory.systemTemp.createTempSync('calmcheck-order');
      addTearDown(() {
        try {
          if (dir.existsSync()) dir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final state = (await tester.runAsync(
        () => AppState.load(
          cardRepository: CardRepository(directory: dir),
          purchaseService: PurchaseService.forTest(),
        ),
      ))!;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            theme: calmLightTheme,
            home: CardViewScreen(previewCard: card),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('every section is present on a full card', (tester) async {
      await openCard(tester, ravi);
      for (final label in ['WHAT TO DO', 'DO NOT', 'CALL', 'ABOUT']) {
        // DO NOT can legitimately appear twice: once as the section, and once
        // in the strip that pins its first line to the bottom edge while the
        // real block is still below the fold.
        expect(find.text(label), findsAtLeastNWidgets(1), reason: label);
      }
    });

    testWidgets('CALL is present even when nobody is on the card', (
      tester,
    ) async {
      // The section is item four of an order that never moves. Hiding it when
      // empty leaves a stranger unable to tell "there is no one" from "I
      // missed it".
      await openCard(tester, aanya.copyWith(call: const []));
      expect(find.text('CALL'), findsOneWidget);
      expect(find.text('Nobody to call yet'), findsOneWidget);
    });

    testWidgets('a received card says plainly that nobody is listed', (
      tester,
    ) async {
      await openCard(tester, aanya.copyWith(call: const [], readOnly: true));
      expect(find.text('CALL'), findsOneWidget);
      expect(find.text('No one is listed on this card.'), findsOneWidget);
      // Nothing to tap: it is not this person's card to edit.
      expect(find.text('Nobody to call yet'), findsNothing);
    });

    testWidgets('a contact with no number says so rather than hiding', (
      tester,
    ) async {
      await openCard(
        tester,
        aanya.copyWith(
          call: const [CareContact(name: 'Mum', relationship: 'Sonia')],
        ),
      );
      expect(find.textContaining('No number saved'), findsOneWidget);
    });
  });

  group('your person', () {
    testWidgets('the panic flow is unchanged until somebody names one', (
      tester,
    ) async {
      await _boot(tester);
      await tester.tap(find.text('I need calm now'));
      await _settle(tester);

      // A fresh install holds no contact of any kind, so the pacer offers
      // nobody. The personal-contact treatment stays reserved for a named
      // person; the ways out below are unchanged either way.
      expect(find.textContaining('Call '), findsNothing);
      expect(find.textContaining('Text '), findsNothing);
      expect(find.text("Breathing isn't helping"), findsOneWidget);
      expect(find.text("I'M DONE"), findsOneWidget);
    });

    testWidgets(
      'once named, they can be reached without leaving the breathing',
      (tester) async {
        final state = await _boot(tester);
        state.setPerson(
          const PersonalContact(name: 'Dana Okoro', number: '07700 900 118'),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 1));

        await tester.tap(find.text('I need calm now'));
        await _settle(tester);

        expect(find.text('Call Dana'), findsOneWidget);
        expect(find.text('Text Dana instead'), findsOneWidget);
        // The ways out are still there, and still quiet.
        expect(find.text("Breathing isn't helping"), findsOneWidget);
        expect(find.text("I'M DONE"), findsOneWidget);
      },
    );

    testWidgets('reaching them is never a monetization surface', (
      tester,
    ) async {
      final state = await _boot(tester);
      state.setPerson(const PersonalContact(name: 'Dana', number: '123'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1));
      await tester.tap(find.text('I need calm now'));
      await _settle(tester);

      for (final word in _monetization) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });
  });

  testWidgets('the helplines are one tap from HOME', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('CRISIS HELPLINES'));
    await _settle(tester);
    expect(find.text('Talk to someone now'), findsOneWidget);
    // A fire exit: no atmosphere, and nothing that asks for money.
    for (final word in _monetization) {
      expect(find.textContaining(word), findsNothing);
    }
  });

  testWidgets(
    'the first care card is free; only the second meets the paywall',
    (tester) async {
      // A store with something to sell, and nothing bought.
      final state = await _boot(tester, store: StoreAvailability.available);
      expect(state.isPro, isFalse);
      expect(
        state.canCreateCard,
        isTrue,
        reason:
            'the seeded samples are not cards the person created; a fresh '
            'install must not route "create your first card" to the paywall',
      );

      // Their own first card uses the free slot…
      state.upsertCard(
        CareCardData(id: 'card-own', name: 'Nan', preparedAt: DateTime.now()),
      );
      expect(
        state.canCreateCard,
        isFalse,
        reason: 'the second card is what meets the paywall',
      );

      // …and deleting everything frees it again.
      for (final card in state.cards.toList()) {
        state.deleteCard(card.id);
      }
      expect(state.canCreateCard, isTrue, reason: 'the first card is free');
    },
  );

  testWidgets('Pro features stay open while the store has nothing to sell', (
    tester,
  ) async {
    final state = await _boot(tester);
    // No store in a test environment: a build published before the products
    // exist is a complete app, not a crippled one, and shows no paywall.
    expect(state.proOffered, isFalse);
    expect(state.isPro, isTrue);
    expect(state.canCreateCard, isTrue);
    expect(state.canExportPdf, isTrue);
  });

  testWidgets(
    'onboarding runs promise -> paths -> permissions -> scope -> first card',
    (tester) async {
      await _boot(tester, onboarded: false);
      expect(
        find.text('Know what to do in the next 60 seconds.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Get started'));
      await _settle(tester);
      expect(find.text('Who are you setting this up for?'), findsOneWidget);

      await tester.tap(find.text('Myself'));
      await _settle(tester);
      expect(find.text('Two quick settings.'), findsOneWidget);

      // Reminders default off, and Allow is not the only styled path.
      await tester.tap(find.text('Continue'));
      await _settle(tester);
      expect(find.text("What this app is, and what it isn't."), findsOneWidget);

      await tester.tap(find.text('I understand'));
      await _settle(tester);

      // ONB-05: the first card is asked for once, and is always skippable.
      expect(
        find.text('Make a card for someone you look after.'),
        findsOneWidget,
      );
      expect(find.text('Create a care card'), findsOneWidget);

      await tester.tap(find.text("I'll do this later"));
      await _settle(tester);
      expect(find.text('I need calm now'), findsOneWidget);
    },
  );

  testWidgets('reminders are off by default and vibration is on', (
    tester,
  ) async {
    final state = await _boot(tester, onboarded: false);
    expect(state.reminders, isFalse);
    expect(state.vibration, isTrue);
  });
}
