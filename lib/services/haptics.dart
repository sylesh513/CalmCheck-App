/// Haptics are designed, not left to implementation. Every pattern below is
/// specified in `docs/motion.md`; nothing here fires on scroll, on a list item,
/// or as decoration.
///
/// Haptics stay on under reduced motion — they are how the pacing survives when
/// the movement stops.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

enum CcHaptic {
  /// Phase enters inhale. Ramps low -> medium, ~220ms.
  breathRise,

  /// Phase enters exhale. Mirror of the rise, softer, ~280ms.
  breathFall,

  /// Marks hold and rest. One tap, 12ms.
  phaseTap,

  /// The only heavy haptic in CALM. 28ms.
  pressFirm,

  /// Distinct from every other tap in the app. ~130ms.
  emergency,
}

class CcHaptics {
  CcHaptics._();

  static final CcHaptics instance = CcHaptics._();

  /// Mirrors the Vibration setting. When off, nothing fires.
  bool enabled = true;
  bool _probed = false;
  bool _hasVibrator = false;
  bool _hasWaveform = false;

  /// Android drives the exact waveforms; iOS drives the Taptic engine through
  /// the impact mapping, which is the closer match to the same intent there.
  bool get _useWaveform => !kIsWeb && Platform.isAndroid && _hasWaveform;

  Future<void> warmUp() async {
    if (_probed) return;
    _probed = true;
    if (kIsWeb) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _hasWaveform =
          _hasVibrator && await Vibration.hasCustomVibrationsSupport();
    } catch (_) {
      _hasVibrator = false;
      _hasWaveform = false;
    }
  }

  void fire(CcHaptic event) {
    if (!enabled) return;
    if (_useWaveform) {
      final spec = _waveforms[event]!;
      Vibration.vibrate(pattern: spec.pattern, intensities: spec.intensities);
      return;
    }
    switch (event) {
      case CcHaptic.breathRise:
        HapticFeedback.lightImpact();
      case CcHaptic.breathFall:
        HapticFeedback.mediumImpact();
      case CcHaptic.phaseTap:
        HapticFeedback.selectionClick();
      case CcHaptic.pressFirm:
        HapticFeedback.heavyImpact();
      case CcHaptic.emergency:
        HapticFeedback.heavyImpact();
        Future<void>.delayed(
          const Duration(milliseconds: 84),
          HapticFeedback.heavyImpact,
        );
    }
  }
}

@immutable
class _Waveform {
  const _Waveform(this.pattern, this.intensities);

  /// `[delay, on, delay, on, ...]` in milliseconds.
  final List<int> pattern;

  /// One amplitude per pattern entry; 0 on the silent entries.
  final List<int> intensities;
}

const Map<CcHaptic, _Waveform> _waveforms = {
  // 8ms · 90 · 12ms · 90 · 18ms — low rising to medium.
  CcHaptic.breathRise: _Waveform(
    [0, 8, 90, 12, 90, 18],
    [0, 90, 0, 150, 0, 210],
  ),
  // 18ms · 120 · 12ms · 120 · 8ms — the mirror, falling away.
  CcHaptic.breathFall: _Waveform(
    [0, 18, 120, 12, 120, 8],
    [0, 200, 0, 140, 0, 90],
  ),
  CcHaptic.phaseTap: _Waveform([0, 12], [0, 90]),
  CcHaptic.pressFirm: _Waveform([0, 28], [0, 255]),
  CcHaptic.emergency: _Waveform([0, 24, 60, 24], [0, 255, 0, 255]),
};
