/// Free forever means free in every state, for every reason.
library;

import 'package:calmcheck/data/exercises.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('breathing and grounding are free, and they are the only free ones', () {
    final free = exercises.where((e) => e.isFree).map((e) => e.id).toList();
    expect(free, ['paced', 'grounding']);
  });

  test('every exercise names what it is for', () {
    for (final ex in exercises) {
      expect(ex.purpose, isNotEmpty, reason: ex.id);
      expect(ex.duration, isNotEmpty, reason: ex.id);
    }
  });

  test('every paced exercise has an exhale at least as long as its inhale', () {
    for (final ex in exercises) {
      final cadence = ex.cadence;
      if (cadence == null) continue;
      expect(
        cadence.exhale,
        greaterThanOrEqualTo(cadence.inhale),
        reason: ex.id,
      );
    }
  });
}
