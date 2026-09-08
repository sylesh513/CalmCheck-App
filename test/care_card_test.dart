/// A care card has to survive the trip through a QR code and back with the
/// fixed information order intact — and it must never carry a device-local
/// file path off the device.
library;

import 'fixtures/sample_cards.dart';
import 'package:calmcheck/models/care_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a card round-trips through its share payload', () {
    final original = ravi;
    final decoded = CareCardData.tryParseShareString(original.toShareString());

    expect(decoded, isNotNull);
    expect(decoded!.name, 'Ravi');
    expect(decoded.doThis, original.doThis);
    expect(decoded.dontDo, original.dontDo);
    expect(
      decoded.call.map((c) => c.number),
      original.call.map((c) => c.number),
    );
  });

  test('the payload never carries the photo path', () {
    final withPhoto = aanya.copyWith(photoPath: '/var/mobile/photo.jpg');
    final decoded = CareCardData.tryParseShareString(
      withPhoto.toShareString(),
    )!;
    expect(decoded.photoPath, isNull);
  });

  test('a code that is not a CalmCheck card returns null, never throws', () {
    expect(CareCardData.tryParseShareString('https://example.com'), isNull);
    expect(CareCardData.tryParseShareString('CALMCHECK1:not-base64!'), isNull);
    expect(CareCardData.tryParseShareString(''), isNull);
  });

  test('a minimal card is not a broken card', () {
    final minimal = CareCardData(
      id: 'x',
      name: 'Sam',
      preparedAt: DateTime(2026, 3, 4),
    );
    expect(minimal.initial, 'S');
    expect(minimal.hasAbout, isFalse);
    expect(minimal.signal, isNotEmpty);
    expect(minimal.meta, contains('on this device only'));
  });

  test('a contact with no number says so rather than pretending', () {
    const contact = CareContact(name: 'Priya', relationship: 'daughter');
    expect(contact.hasNumber, isFalse);
  });
}
