/// The crisis screen is a fire exit. Its data has to be there, has to be
/// dialable, and has to be for the right country.
library;

import 'package:calmcheck/data/helplines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => Helplines.instance.load());

  test('the dataset loads and covers most of the world', () {
    expect(Helplines.instance.isLoaded, isTrue);
    expect(Helplines.instance.all.length, greaterThan(200));
  });

  test('every territory has at least one emergency number', () {
    for (final region in Helplines.instance.all) {
      expect(region.emergency.numbers, isNotEmpty, reason: region.label);
      for (final number in region.emergency.numbers) {
        expect(isDialable(number), isTrue, reason: '${region.label}: $number');
      }
    }
  });

  test('the emergency number people actually dial comes first', () {
    const expected = {
      'US': '911',
      'CA': '911',
      'MX': '911',
      'GB': '999',
      'IE': '999',
      'SG': '999',
      'AU': '000',
      'NZ': '111',
      'IN': '112',
      'DE': '112',
      'FR': '112',
      'IT': '112',
      'ZA': '112',
      'JP': '110',
      'CN': '110',
      'PH': '911',
      'BR': '190',
    };
    expected.forEach((code, first) {
      final region = Helplines.instance.forCode(code);
      expect(region, isNotNull, reason: code);
      expect(region!.emergency.numbers.first, first, reason: region.label);
    });
  });

  test('a verified crisis line is listed above emergency services', () {
    final india = Helplines.instance.forCode('IN')!;
    expect(india.hasCrisisLine, isTrue);
    expect(india.lines.first.name, 'Tele-MANAS');
    expect(india.lines.last.name, 'Emergency services');
  });

  test('every crisis line names its operator, its numbers and when it was '
      'checked', () {
    var checked = 0;
    for (final region in Helplines.instance.all) {
      for (final line in region.crisis) {
        expect(line.name, isNotEmpty, reason: region.label);
        expect(line.numbers, isNotEmpty, reason: region.label);
        expect(line.sub, isNotEmpty, reason: region.label);
        expect(
          line.verified,
          isNotNull,
          reason:
              'an unverified crisis number must not ship: '
              '${region.label}',
        );
        for (final number in line.numbers) {
          expect(
            isDialable(number),
            isTrue,
            reason: '${region.label}: $number',
          );
        }
        checked++;
      }
    }
    expect(checked, greaterThan(0));
  });

  test('an unknown country resolves to nothing rather than to a guess', () {
    expect(Helplines.instance.forCode('ZZ'), isNull);
    expect(Helplines.instance.forCode(null), isNull);
  });

  test('country names are the ones people use, not the legal forms', () {
    expect(Helplines.instance.forCode('GB')!.label, 'United Kingdom');
    expect(Helplines.instance.forCode('US')!.label, 'United States');
    expect(Helplines.instance.forCode('KR')!.label, 'South Korea');
    expect(Helplines.instance.forCode('BO')!.label, 'Bolivia');
  });
}
