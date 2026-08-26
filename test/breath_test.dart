/// The breath timeline is the one piece of maths in this app that has to be
/// exactly right — the orb, the haptics and the voice all derive from it.
library;

import 'package:calmcheck/design/breath.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cadence', () {
    test('the default is ~5.2 breaths a minute with a longer exhale', () {
      const c = BreathCadence.standard;
      expect(c.cycleLength, 11.5);
      expect(c.breathsPerMinute, closeTo(5.2, 0.05));
      expect(c.exhale, greaterThan(c.inhale));
    });

    test('copyWith clamps the exhale to the inhale — never the reverse', () {
      const c = BreathCadence.standard;
      final clamped = c.copyWith(exhale: 2);
      expect(clamped.exhale, c.inhale);

      final raised = c.copyWith(inhale: 8);
      expect(raised.exhale, greaterThanOrEqualTo(raised.inhale));
    });
  });

  group('frameAt', () {
    const c = BreathCadence.standard;

    test('walks inhale, hold, exhale, rest in order', () {
      expect(frameAt(0.1, c).phase, BreathPhase.inhale);
      expect(frameAt(4.5, c).phase, BreathPhase.hold);
      expect(frameAt(7.0, c).phase, BreathPhase.exhale);
      expect(frameAt(11.2, c).phase, BreathPhase.rest);
    });

    test(
      'amplitude reaches the peak at the top and the trough at the bottom',
      () {
        expect(frameAt(0, c).amplitude, closeTo(0, 0.001));
        expect(frameAt(4.5, c).amplitude, 1.0);
        expect(frameAt(11.2, c).amplitude, 0.0);
      },
    );

    test('the crest is asymmetric — not an ease-in-out', () {
      // Halfway through the inhale the breath is already well past halfway up;
      // halfway through the exhale it has already fallen below halfway down.
      expect(frameAt(2.0, c).amplitude, greaterThan(0.7));
      expect(frameAt(5 + 3.0, c).amplitude, lessThan(0.35));
    });

    test('is continuous across the cycle boundary', () {
      expect(frameAt(11.49, c).amplitude, frameAt(11.49 + 11.5, c).amplitude);
      expect(frameAt(-0.1, c).phase, BreathPhase.rest);
    });

    test('every phase carries a cue', () {
      for (final t in [0.5, 4.5, 8.0, 11.3]) {
        expect(frameAt(t, c).cue, isNotEmpty);
      }
    });
  });
}
