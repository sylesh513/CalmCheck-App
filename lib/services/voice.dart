/// The guide voice. Speaks the breathing cues aloud so you can keep your eyes
/// closed. Fired from the same controller value as the orb and the haptics, so
/// it can never drift out of phase.
///
/// The pacer only ever says four things, and never anything dynamic, so they
/// are rendered ahead of time rather than read by the platform narrator — which
/// is the same voice the phone uses for notifications and sounds like one.
/// `tool/make_voice_cues.py` renders them with Qwen3-TTS VoiceDesign.
///
/// Platform TTS stays as the fallback: if an asset is missing, or a caller ever
/// passes a phrase that was not rendered, the cue is still spoken.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CcVoice {
  CcVoice._();

  static final CcVoice instance = CcVoice._();

  /// Cue text to rendered asset. Keys are the values in `phaseCue`.
  static const Map<String, String> _rendered = {
    'Breathe in': 'voice/inhale.wav',
    'Hold': 'voice/hold.wav',
    'Breathe out': 'voice/exhale.wav',
    'Rest': 'voice/rest.wav',
  };

  FlutterTts? _tts;
  AudioPlayer? _player;
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
      final player = AudioPlayer();
      // `playback` on iOS means the cue is still audible with the ring switch
      // set to silent. Somebody doing this with their eyes closed has no way to
      // discover that a hardware switch is why they cannot hear it.
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            usageType: AndroidUsageType.assistanceAccessibility,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.9);
      _player = player;
    } catch (_) {
      _player = null;
    }

    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(0.38); // unhurried; a cue, not an announcement
      await tts.setVolume(0.85);
      await tts.setPitch(0.95);
      await tts.awaitSpeakCompletion(false);
      _tts = tts;
    } catch (_) {
      _tts = null;
    }

    _ready = _player != null || _tts != null;
  }

  void say(String text) {
    if (!_enabled || !_ready) return;

    final asset = _rendered[text];
    final player = _player;
    if (asset != null && player != null) {
      player
          .stop()
          .then((_) => player.play(AssetSource(asset)))
          .catchError((_) => _speakWithTts(text));
      return;
    }
    _speakWithTts(text);
  }

  void _speakWithTts(String text) {
    final tts = _tts;
    if (tts == null) return;
    tts.stop().then((_) => tts.speak(text)).catchError((_) => null);
  }

  void stop() {
    _player?.stop().catchError((_) => null);
    _tts?.stop().catchError((_) => null);
  }
}
