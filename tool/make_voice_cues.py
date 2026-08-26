#!/usr/bin/env python3
"""Render the breathing cues with Qwen3-TTS VoiceDesign.

The pacer speaks exactly four words-or-phrases, and never anything dynamic, so
they can be rendered once and shipped as assets instead of going through the
platform TTS voice — which is the stock Android/iOS narrator and sounds like a
notification, not like somebody sitting with you.

Run it from a venv that has the Qwen3-TTS package installed:

    ~/SaaS/youtube_automation/Qwen3-TTS/.venv/bin/python tool/make_voice_cues.py

Writes 24 kHz mono WAVs into assets/voice/. Regenerating is fine; the app looks
the files up by phase name.
"""

from __future__ import annotations

import os
import sys

import soundfile as sf
import torch
from qwen_tts import Qwen3TTSModel

MODEL = "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign"

# The voice is the product here. It is doing the same job as the orb: pacing
# somebody's breath while they are not in a state to read anything. Slow, low,
# unhurried, and with none of the brightness a normal assistant voice has.
VOICE = (
    "A soft, warm, calm woman's voice speaking slowly and very gently, "
    "at low volume, with a soothing and reassuring tone. Unhurried and "
    "steady, with a natural falling intonation and no brightness, no "
    "cheerfulness and no urgency — the voice of someone sitting quietly "
    "beside you and guiding your breathing."
)

# Keyed by BreathPhase name in lib/design/breath.dart.
CUES = {
    "inhale": "Breathe in",
    "hold": "Hold",
    "exhale": "Breathe out",
    "rest": "Rest",
}

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "voice")


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)

    print(f"Loading {MODEL} (first run downloads the weights)…")
    model = Qwen3TTSModel.from_pretrained(
        MODEL,
        device_map="cpu",
        dtype=torch.float32,
    )
    print("Model loaded.\n")

    for phase, text in CUES.items():
        print(f"  {phase:<7} {text!r}")
        wavs, sr = model.generate_voice_design(
            text=text,
            language="English",
            instruct=VOICE,
        )
        path = os.path.join(OUT_DIR, f"{phase}.wav")
        sf.write(path, wavs[0], sr)
        seconds = len(wavs[0]) / sr
        kb = os.path.getsize(path) / 1024
        print(f"          -> {path}  ({seconds:.2f}s, {kb:.0f} KB, {sr} Hz)\n")

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
