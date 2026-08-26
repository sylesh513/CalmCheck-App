/// The guide voice. Speaks the breathing cues aloud so you can keep your eyes
/// closed. Fired from the same controller value as the orb and the haptics, so
/// it can never drift out of phase.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CcVoice {
  CcVoice._();

  static final CcVoice instance = CcVoice._();

  FlutterTts? _tts;
  bool _enabled = false;
  bool _ready = false;

  set enabled(bool value) {
    _enabled = value;
    if (!value) stop();
  }

  bool get enabled => _enabled;

  Future<void> warmUp() async {
    if (_ready || kIsWeb) return;
    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(0.38); // unhurried; a cue, not an announcement
      await tts.setVolume(0.85);
      await tts.setPitch(0.95);
      await tts.awaitSpeakCompletion(false);
      _tts = tts;
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void say(String text) {
    if (!_enabled || !_ready) return;
    final tts = _tts;
    if (tts == null) return;
    tts.stop().then((_) => tts.speak(text)).catchError((_) => null);
  }

  void stop() {
    _tts?.stop().catchError((_) => null);
  }
}
