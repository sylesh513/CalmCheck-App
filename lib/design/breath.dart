/// One timeline. The orb, the haptics and the voice cue all read from the same
/// clock so they can never drift — a single AnimationController drives all
/// three, and every consumer derives from [frameAt].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum BreathPhase { inhale, hold, exhale, rest }

@immutable
class BreathCadence {
  const BreathCadence({
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.rest,
  });

  /// Seconds.
  final double inhale;
  final double hold;
  final double exhale;
  final double rest;

  /// ~5.2 breaths per minute. Exhale is always longer than inhale.
  static const BreathCadence standard = BreathCadence(
    inhale: 4,
    hold: 1,
    exhale: 6,
    rest: 0.5,
  );

  /// Two quick breaths in, one long breath out.
  static const BreathCadence physiologicalSigh = BreathCadence(
    inhale: 2,
    hold: 0.5,
    exhale: 6,
    rest: 0.5,
  );

  /// Even counts in, hold, out, hold.
  static const BreathCadence box = BreathCadence(
    inhale: 4,
    hold: 4,
    exhale: 4,
    rest: 4,
  );

  double get cycleLength => inhale + hold + exhale + rest;

  double get breathsPerMinute => 60 / cycleLength;

  Duration get cycleDuration =>
      Duration(milliseconds: (cycleLength * 1000).round());

  /// The Pro cadence control clamps to `exhale >= inhale` and prints the reason
  /// when it clamps. No preset can offer the reverse.
  BreathCadence copyWith({
    double? inhale,
    double? hold,
    double? exhale,
    double? rest,
  }) {
    final nextInhale = inhale ?? this.inhale;
    final nextExhale = math.max(exhale ?? this.exhale, nextInhale);
    return BreathCadence(
      inhale: nextInhale,
      hold: hold ?? this.hold,
      exhale: nextExhale,
      rest: rest ?? this.rest,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BreathCadence &&
      other.inhale == inhale &&
      other.hold == hold &&
      other.exhale == exhale &&
      other.rest == rest;

  @override
  int get hashCode => Object.hash(inhale, hold, exhale, rest);
}

const Map<BreathPhase, String> phaseCue = {
  BreathPhase.inhale: 'Breathe in',
  BreathPhase.hold: 'Hold',
  BreathPhase.exhale: 'Breathe out',
  BreathPhase.rest: 'Rest',
};

/// "Crest" easing. Real breath decelerates into the top of an inhale and falls
/// away fastest at the start of an exhale, so the curve is deliberately
/// asymmetric — never a symmetric ease-in-out.
double crestIn(double t) => 1 - math.pow(1 - t, 2.4).toDouble();

double crestOut(double t) => math.pow(1 - t, 1.7).toDouble();

@immutable
class BreathFrame {
  const BreathFrame({
    required this.phase,
    required this.amplitude,
    required this.phaseProgress,
  });

  final BreathPhase phase;

  /// 0 at the trough, 1 at the peak. Drives scale and glow together, so the
  /// light and the form can never disagree.
  final double amplitude;

  /// 0..1 progress within the current phase.
  final double phaseProgress;

  String get cue => phaseCue[phase]!;
}

/// Pure function of elapsed seconds — the single source of truth.
BreathFrame frameAt(double elapsedSeconds, BreathCadence c) {
  final total = c.cycleLength;
  final t = (elapsedSeconds % total + total) % total;

  if (t < c.inhale) {
    final p = c.inhale > 0 ? t / c.inhale : 1.0;
    return BreathFrame(
      phase: BreathPhase.inhale,
      amplitude: crestIn(p),
      phaseProgress: p,
    );
  }
  if (t < c.inhale + c.hold) {
    final p = c.hold > 0 ? (t - c.inhale) / c.hold : 1.0;
    return BreathFrame(phase: BreathPhase.hold, amplitude: 1, phaseProgress: p);
  }
  if (t < c.inhale + c.hold + c.exhale) {
    final p = c.exhale > 0 ? (t - c.inhale - c.hold) / c.exhale : 1.0;
    return BreathFrame(
      phase: BreathPhase.exhale,
      amplitude: crestOut(p),
      phaseProgress: p,
    );
  }
  final p = c.rest > 0 ? (t - c.inhale - c.hold - c.exhale) / c.rest : 1.0;
  return BreathFrame(phase: BreathPhase.rest, amplitude: 0, phaseProgress: p);
}

/// Under reduced motion the orb holds at a fixed amplitude and the phase cue
/// text changes instead. The pacing does not stop.
const double reducedMotionAmplitude = 0.62;
