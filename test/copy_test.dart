/// The voice rules, enforced. Plain verbs, sentence case, short lines, no
/// exclamation marks anywhere — and none of the words that would make this a
/// medical claim or a wellness cliché.
library;

import 'package:calmcheck/data/copy.dart';
import 'package:calmcheck/data/exercises.dart';
import 'package:calmcheck/data/helplines.dart';
import 'package:calmcheck/data/suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

const _banned = [
  // Voice
  'journey', 'mindful', 'tribe', 'warrior', "you've got this", 'oops',
  'uh oh', 'sorry',
  // Policy — these would make the app a medical device
  'diagnose', 'treat', 'therapy', 'therapeutic', 'cure', 'prescribe',
  'medical grade', 'clinically proven',
];

/// Every string the app can show that isn't a proper noun or a phone number.
List<String> _allCopy() => [
  StateCopy.cameraHeadline,
  StateCopy.cameraDirection,
  StateCopy.notificationsHeadline,
  StateCopy.notificationsDirection,
  StateCopy.purchaseHeadline,
  StateCopy.purchaseDirection,
  StateCopy.emptyCardsHeadline,
  StateCopy.emptyCardsDirection,
  StateCopy.emptyExercisesHeadline,
  StateCopy.emptyExercisesDirection,
  StateCopy.emptyScanHeadline,
  StateCopy.emptyScanDirection,
  StateCopy.noCameraDirection,
  StateCopy.deleteCardTitle,
  StateCopy.deleteCardBody,
  ProCopy.freeForever,
  ProCopy.giveBack,
  ProCopy.sponsoredBody,
  ProCopy.sponsoredLimit,
  ProCopy.autoRenewDisclosure,
  ProCopy.storeUnavailable,
  lockedString,
  ...ProCopy.proList,
  ...exercises.map((e) => e.purpose),
  ...doSuggestions.expand((g) => g.items),
  ...dontSuggestions.expand((g) => g.items),
  findAHelpline.sub,
];

void main() {
  test('no exclamation marks anywhere in the app', () {
    for (final line in _allCopy()) {
      expect(line, isNot(contains('!')), reason: line);
    }
  });

  test('no banned words, in the voice or in the policy list', () {
    for (final line in _allCopy()) {
      final lower = line.toLowerCase();
      for (final word in _banned) {
        expect(lower.contains(word), isFalse, reason: '"$word" in: $line');
      }
    }
  });

  test(
    'the disclaimer states the limit without using the banned verbs as claims',
    () {
      // The disclaimer is the one place "diagnose or treat" appears, and only to
      // say the app does neither.
      expect(StateCopy.disclaimerBody, contains('not a medical device'));
      expect(StateCopy.disclaimerBody, contains('does not diagnose or treat'));
    },
  );

  test('the free-forever line names all four free things', () {
    final line = ProCopy.freeForever.toLowerCase();
    for (final thing in ['breathing', 'grounding', 'card', 'helpline']) {
      expect(line, contains(thing));
    }
  });

  test('a dialable number is told apart from a web address', () {
    expect(isDialable('988'), isTrue);
    expect(isDialable('116 123'), isTrue);
    expect(isDialable('1-800-891-4416'), isTrue);
    expect(isDialable('findahelpline.com'), isFalse);
    expect(isDialable('Your local emergency number'), isFalse);
  });
}
