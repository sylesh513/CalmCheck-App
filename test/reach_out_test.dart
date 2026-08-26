/// Reaching your person. The message is the product here — it is read on a
/// lock screen by somebody who has just been startled.
library;

import 'package:calmcheck/models/personal_contact.dart';
import 'package:calmcheck/services/reach_out.dart';
import 'package:calmcheck/services/whereabouts.dart';
import 'package:flutter_test/flutter_test.dart';

const _dana = PersonalContact(name: 'Dana Okoro', number: '07700 900 118');

void main() {
  group('the contact', () {
    test('the button label uses a first name, and never a long one', () {
      expect(_dana.shortName, 'Dana');
      expect(
        const PersonalContact(
          name: 'Bartholomew-Fitzwilliam',
          number: '1',
        ).shortName.length,
        lessThanOrEqualTo(14),
      );
    });

    test('a half-filled contact is not usable', () {
      expect(const PersonalContact(name: 'Dana', number: '').isUsable, isFalse);
      expect(const PersonalContact(name: '', number: '123').isUsable, isFalse);
      expect(_dana.isUsable, isTrue);
    });
  });

  group('the message', () {
    test('says what is happening in the first sentence', () {
      final body = reachOutMessage(contact: _dana);
      expect(body, startsWith("I'm having a panic attack"));
    });

    test(
      'can be signed with a name, for when somebody else holds the phone',
      () {
        final body = reachOutMessage(contact: _dana, senderName: 'Sam');
        expect(body, startsWith('Sam is having a panic attack'));
      },
    );

    test('carries a map link only when a fix arrived', () {
      const where = Whereabouts(latitude: 51.50733, longitude: -0.12775);
      expect(reachOutMessage(contact: _dana), isNot(contains('maps')));
      expect(
        reachOutMessage(contact: _dana, whereabouts: where),
        contains('maps.google.com/?q=51.50733,-0.12775'),
      );
    });

    test('a slow or refused fix does not stop the message', () {
      // Null whereabouts is the ordinary case, not an error path.
      final body = reachOutMessage(contact: _dana, whereabouts: null);
      expect(body, isNotEmpty);
      expect(body, contains('panic attack'));
    });

    test('names the app, so a startled reader knows what this is', () {
      expect(reachOutMessage(contact: _dana), contains('CalmCheck'));
    });

    test('holds the voice rules: no exclamation marks, no banned words', () {
      for (final body in [
        reachOutMessage(contact: _dana),
        reachOutMessage(contact: _dana, senderName: 'Sam'),
        reachOutMessage(
          contact: _dana,
          whereabouts: const Whereabouts(latitude: 1, longitude: 2),
        ),
      ]) {
        expect(body, isNot(contains('!')));
        for (final banned in [
          'journey',
          'oops',
          'sorry',
          'diagnose',
          'treat',
        ]) {
          expect(body.toLowerCase(), isNot(contains(banned)), reason: body);
        }
      }
    });

    test('is short enough to read at a glance', () {
      final body = reachOutMessage(
        contact: _dana,
        whereabouts: const Whereabouts(latitude: 51.50733, longitude: -0.12775),
      );
      expect(body.length, lessThan(200), reason: body);
    });
  });
}
