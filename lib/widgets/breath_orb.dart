/// The one place in this app where boldness gets spent. Everything else is
/// quiet.
///
/// In the Field Card world the orb is the one thing that is not printed — it's
/// the light you're reading the card by. One AnimationController drives
/// geometry, glow, haptics and the voice cue; nothing in the panic flow owns a
/// second clock.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/breath.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../services/haptics.dart';
import '../services/voice.dart';

class BreathOrb extends StatefulWidget {
  const BreathOrb({
    super.key,
    this.cadence = BreathCadence.standard,
    this.paused = false,
    this.reducedMotion = false,
    this.haptics = false,
    this.voice = false,
    this.showCue = true,

    /// 0..1 — how far the glow is allowed to reach.
    this.glow = 1.0,

    /// Freeze at a phase, for the transition frames and for the onboarding
    /// screen where the orb is atmosphere rather than a pacer.
    this.staticPhase,
    this.onPhaseChange,

    /// The optical centre of the screen sits at 46% of height, not 50%.
    this.verticalCentre = 0.46,
  });

  final BreathCadence cadence;
  final bool paused;
  final bool reducedMotion;
  final bool haptics;
  final bool voice;
  final bool showCue;
  final double glow;
  final BreathPhase? staticPhase;
  final ValueChanged<BreathFrame>? onPhaseChange;
  final double verticalCentre;

  @override
  State<BreathOrb> createState() => _BreathOrbState();
}

class _BreathOrbState extends State<BreathOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// The painter repaints off this without rebuilding a single widget.
  final ValueNotifier<double> _amplitude = ValueNotifier(0);

  /// The cue rebuilds only when the phase turns over.
  final ValueNotifier<BreathPhase> _phase = ValueNotifier(BreathPhase.rest);

  BreathPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cadence.cycleDuration,
    )..addListener(_tick);
    _sync();
  }

  @override
  void didUpdateWidget(covariant BreathOrb old) {
    super.didUpdateWidget(old);
    if (old.cadence != widget.cadence) {
      _controller.duration = widget.cadence.cycleDuration;
      if (_controller.isAnimating) {
        _controller
          ..stop()
          ..repeat();
      }
    }
    if (old.paused != widget.paused ||
        old.staticPhase != widget.staticPhase ||
        old.reducedMotion != widget.reducedMotion) {
      _sync();
    }
  }

  void _sync() {
    if (widget.staticPhase != null) {
      _controller.stop();
      _apply(_frozenFrame(widget.staticPhase!), announce: false);
      return;
    }
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  /// Documentation frames: the peak of an inhale, the middle of a hold, the
  /// trough of an exhale.
  BreathFrame _frozenFrame(BreathPhase phase) {
    final c = widget.cadence;
    final at = switch (phase) {
      BreathPhase.inhale => c.inhale * 0.999,
      BreathPhase.hold => c.inhale + c.hold * 0.5,
      BreathPhase.exhale => c.inhale + c.hold + c.exhale * 0.98,
      BreathPhase.rest => c.inhale + c.hold + c.exhale + c.rest * 0.5,
    };
    return frameAt(at, c);
  }

  void _tick() => _apply(
    frameAt(_controller.value * widget.cadence.cycleLength, widget.cadence),
  );

  void _apply(BreathFrame f, {bool announce = true}) {
    // Under reduced motion the orb holds still at a fixed amplitude; the phase
    // cue changes instead, and the haptics keep running.
    _amplitude.value = widget.reducedMotion
        ? reducedMotionAmplitude
        : f.amplitude;

    if (f.phase == _lastPhase) return;
    _lastPhase = f.phase;
    _phase.value = f.phase;
    if (!announce) return;

    if (widget.haptics) {
      CcHaptics.instance.fire(switch (f.phase) {
        BreathPhase.inhale => CcHaptic.breathRise,
        BreathPhase.exhale => CcHaptic.breathFall,
        BreathPhase.hold || BreathPhase.rest => CcHaptic.phaseTap,
      });
    }
    if (widget.voice && f.phase != BreathPhase.rest) {
      CcVoice.instance.say(f.cue);
    }
    widget.onPhaseChange?.call(f);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    _amplitude.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cc;
    return Column(
      spacing: CcSpace.xl,
      children: [
        Expanded(
          child: ValueListenableBuilder<BreathPhase>(
            valueListenable: _phase,
            builder: (context, phase, child) => Semantics(
              // One label that carries the current phase, refreshed when the
              // phase turns over — never read out on every frame.
              label: 'Breathing pacer. ${phaseCue[phase]}.',
              liveRegion: widget.showCue,
              excludeSemantics: true,
              child: child,
            ),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _OrbPainter(
                  amplitude: _amplitude,
                  signal: t.signal,
                  glow: widget.glow.clamp(0.0, 1.0),
                  reduced: widget.reducedMotion,
                  verticalCentre: widget.verticalCentre,
                ),
              ),
            ),
          ),
        ),
        if (widget.showCue)
          ValueListenableBuilder<BreathPhase>(
            valueListenable: _phase,
            builder: (context, phase, _) => Text(
              phaseCue[phase]!.toUpperCase(),
              style: context.ccText.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.amplitude,
    required this.signal,
    required this.glow,
    required this.reduced,
    required this.verticalCentre,
  }) : super(repaint: amplitude);

  final ValueNotifier<double> amplitude;
  final Color signal;
  final double glow;
  final bool reduced;
  final double verticalCentre;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amplitude.value;
    final r0 = 0.22 * math.min(size.width, size.height);
    // The orb grows by just under a third. It never doubles.
    final r = r0 * (1 + 0.32 * a);
    final centre = Offset(size.width / 2, size.height * verticalCentre);

    if (reduced) {
      // Static ring. Nothing moves; the pacing lives in the cue and the hand.
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = signal.withValues(alpha: 0.85),
      );
      return;
    }

    // Glow, painted behind the core. A gradient, never a blur filter — blur
    // costs frames on low-end Androids and this must hold for minutes.
    final glowRadius = r * 2.1;
    final glowRect = Rect.fromCircle(center: centre, radius: glowRadius);
    canvas.drawCircle(
      centre,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            signal.withValues(alpha: (0.10 + 0.45 * a) * glow),
            signal.withValues(alpha: (0.04 + 0.12 * a) * glow),
            signal.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(glowRect),
    );

    // The core. Opacity moves 0.82 -> 1.0 with amplitude, off the same value as
    // the geometry, so the light and the form can never disagree.
    final coreRect = Rect.fromCircle(center: centre, radius: r);
    final coreOpacity = 0.82 + 0.18 * a;
    canvas.drawCircle(
      centre,
      r,
      Paint()..color = signal.withValues(alpha: coreOpacity),
    );

    // A soft inner highlight offset to 42%/38%, so the core reads as a lit body
    // rather than a flat disc.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.16, -0.24),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.16 * coreOpacity),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.72],
        ).createShader(coreRect),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.signal != signal ||
      old.glow != glow ||
      old.reduced != reduced ||
      old.verticalCentre != verticalCentre;
}
