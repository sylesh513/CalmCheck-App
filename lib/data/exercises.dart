import 'package:flutter/foundation.dart';

import '../design/breath.dart';

enum ExerciseTier { free, pro }

enum ExerciseKind { pacedBreath, grounding, coldWater, muscleRelease }

@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.tier,
    required this.purpose,
    required this.duration,
    required this.kind,
    this.cadence,
    this.steps = const [],
  });

  final String id;
  final String name;
  final ExerciseTier tier;
  final String purpose;
  final String duration;
  final ExerciseKind kind;

  /// The pacer cadence this exercise runs at, when it runs the orb.
  final BreathCadence? cadence;

  /// For the exercises that are instructions rather than a pacer.
  final List<String> steps;

  bool get isFree => tier == ExerciseTier.free;
}

/// The two free exercises are never locked, in any state, for any reason.
const String lockedString =
    'Every exercise is included with Pro. Breathing and grounding stay free.';

const List<Exercise> exercises = [
  Exercise(
    id: 'paced',
    name: 'Paced breathing',
    tier: ExerciseTier.free,
    purpose: 'Slow your breathing to about five and a half breaths a minute.',
    duration: '4 min',
    kind: ExerciseKind.pacedBreath,
    cadence: BreathCadence.standard,
  ),
  Exercise(
    id: 'grounding',
    name: '5-4-3-2-1 grounding',
    tier: ExerciseTier.free,
    purpose: 'Bring your attention back to the room through your senses.',
    duration: '3 min',
    kind: ExerciseKind.grounding,
  ),
  Exercise(
    id: 'sigh',
    name: 'Physiological sigh',
    tier: ExerciseTier.pro,
    purpose: 'Two quick breaths in, one long breath out. Fast to take effect.',
    duration: '1 min',
    kind: ExerciseKind.pacedBreath,
    cadence: BreathCadence.physiologicalSigh,
  ),
  Exercise(
    id: 'box',
    name: 'Box breathing',
    tier: ExerciseTier.pro,
    purpose: 'Even counts in, hold, out, hold. Steady and predictable.',
    duration: '5 min',
    kind: ExerciseKind.pacedBreath,
    cadence: BreathCadence.box,
  ),
  Exercise(
    id: 'cold',
    name: 'Cold water',
    tier: ExerciseTier.pro,
    purpose: 'A temperature change to interrupt a spiral.',
    duration: '2 min',
    kind: ExerciseKind.coldWater,
    steps: [
      'Run the cold tap until it is properly cold.',
      'Hold your wrists under it for thirty seconds.',
      'Splash your face, or hold a cold flannel to your cheeks and eyes.',
      'Breathe out slowly while the cold is on your skin.',
    ],
  ),
  Exercise(
    id: 'pmr',
    name: 'Progressive muscle release',
    tier: ExerciseTier.pro,
    purpose: 'Tense and release, working up from your feet.',
    duration: '9 min',
    kind: ExerciseKind.muscleRelease,
    steps: [
      'Curl your toes hard for five seconds, then let go.',
      'Tighten your calves, then let go.',
      'Press your knees together, then let go.',
      'Clench your fists, then let them fall open.',
      'Pull your shoulders up to your ears, then drop them.',
      'Screw your face up, then let it all go slack.',
    ],
  ),
];

/// Null for an id that no longer exists — a stale route argument must fall
/// back to the library, not throw a StateError.
Exercise? exerciseById(String id) {
  for (final e in exercises) {
    if (e.id == id) return e;
  }
  return null;
}
