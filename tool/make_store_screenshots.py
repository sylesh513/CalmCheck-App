#!/usr/bin/env python3
"""Compose App Store marketing screenshots from the rendered app shots.

    flutter test test/submission_shots_test.dart   # writes build/submission/
    python3 tool/make_store_screenshots.py         # writes build/store/

Each frame is an SVG laid out at exactly 1320x2868 — Apple's 6.9" iPhone size —
carrying a caption in the app's own typeface above the real screen. The SVG
embeds both the font and the screenshot as data URIs and is rasterised through
headless Chrome, which is the only local renderer that resolves @font-face
reliably; fontconfig-based rasterisers silently substitute a default face and
the caption stops looking like the app.

Output is flattened onto an opaque background because App Store Connect rejects
PNGs carrying an alpha channel.
"""

from __future__ import annotations

import base64
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHOTS = ROOT / "build" / "submission"
OUT = ROOT / "build" / "store"
FONTS = ROOT / "assets" / "fonts"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

W, H = 1320, 2868

# Design tokens, lifted from lib/design/tokens.dart so the frames and the app
# are the same artifact rather than two things that merely look alike.
STOCK = "#F4EFE6"
INK = "#1A1714"
INK_MUTED = "#4F4841"
SIGNAL = "#0B5F63"
RULE = "#D8D0C3"

# The order is the pitch — see docs/store-submission.md section 8.
FRAMES = [
    ("01-home", "Calm in one tap.", "The button is the first thing on screen."),
    ("02-panic", "Breathing you can feel,\nnot just watch.", "Paced with haptics and a voice that guides."),
    ("06-crisis", "No signal needed.\nEver.", "Helplines for 237 territories, on the device."),
    ("03-card-view", "What to do.\nWhat not to do.", "A care card anyone can follow in seconds."),
    ("04-share", "Share it with anyone.", "A QR code. No account, no upload."),
    ("05-privacy", "Nothing leaves\nyour phone.", "No analytics. No servers. No sign-in."),
]


def data_uri(path: pathlib.Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def build_svg(shot: pathlib.Path, headline: str, sub: str) -> str:
    regular = data_uri(FONTS / "AtkinsonHyperlegible-Regular.ttf", "font/ttf")
    bold = data_uri(FONTS / "AtkinsonHyperlegible-Bold.ttf", "font/ttf")
    mono = data_uri(FONTS / "IBMPlexMono-SemiBold.ttf", "font/ttf")
    img = data_uri(shot, "image/png")

    # The screen is scaled to 1080px wide (2347 tall) and sits just under the
    # caption, so the whole screen stays visible without bleeding off the
    # bottom edge and without a dead band in the middle of the frame.
    sw, sx, sy = 1080, 120, 470
    sh = round(sw * H / W)

    lines = headline.split("\n")
    line_h = 104
    top = 300 - (len(lines) - 1) * line_h // 2
    tspans = "".join(
        f'<tspan x="{W // 2}" y="{top + i * line_h}">{ln}</tspan>'
        for i, ln in enumerate(lines)
    )

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <style>
      @font-face {{ font-family: 'Atkinson'; font-weight: 400; src: url({regular}) format('truetype'); }}
      @font-face {{ font-family: 'Atkinson'; font-weight: 700; src: url({bold}) format('truetype'); }}
      @font-face {{ font-family: 'PlexMono'; font-weight: 600; src: url({mono}) format('truetype'); }}
      .h {{ font-family: 'Atkinson'; font-weight: 700; font-size: 88px; fill: {INK}; letter-spacing: -1.5px; }}
      .s {{ font-family: 'Atkinson'; font-weight: 400; font-size: 40px; fill: {INK_MUTED}; }}
      .k {{ font-family: 'PlexMono'; font-weight: 600; font-size: 26px; fill: {SIGNAL}; letter-spacing: 5px; }}
    </style>
    <clipPath id="screen">
      <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="64" ry="64"/>
    </clipPath>
  </defs>

  <rect width="{W}" height="{H}" fill="{STOCK}"/>

  <text class="k" x="{W // 2}" y="168" text-anchor="middle">CALMCHECK</text>
  <text class="h" text-anchor="middle">{tspans}</text>
  <text class="s" x="{W // 2}" y="{top + (len(lines) - 1) * line_h + 84}" text-anchor="middle">{sub}</text>

  <image href="{img}" x="{sx}" y="{sy}" width="{sw}" height="{sh}"
         preserveAspectRatio="xMidYMin slice" clip-path="url(#screen)"/>
  <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="64" ry="64"
        fill="none" stroke="{RULE}" stroke-width="3"/>
</svg>"""


def main() -> int:
    if not SHOTS.is_dir():
        sys.exit("build/submission missing — run the submission_shots test first")
    if not pathlib.Path(CHROME).exists():
        sys.exit(f"Chrome not found at {CHROME}")

    OUT.mkdir(parents=True, exist_ok=True)
    tmp = OUT / ".work"
    tmp.mkdir(exist_ok=True)

    for index, (name, headline, sub) in enumerate(FRAMES, start=1):
        shot = SHOTS / f"{name}.png"
        if not shot.exists():
            print(f"  skip {name}: no {shot.name}")
            continue

        svg_path = tmp / f"{name}.svg"
        svg_path.write_text(build_svg(shot, headline, sub))

        # Chrome writes the screenshot next to --screenshot=<path>. The window
        # size is the SVG's intrinsic size, so no scaling happens.
        target = OUT / f"{index:02d}-{name.split('-', 1)[1]}.png"
        subprocess.run(
            [
                CHROME,
                "--headless",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                f"--screenshot={target}",
                f"--window-size={W},{H}",
                f"--default-background-color={STOCK.lstrip('#')}FF",
                svg_path.as_uri(),
            ],
            check=True,
            capture_output=True,
        )
        print(f"  {target.name}")

    shutil.rmtree(tmp, ignore_errors=True)
    print(f"\nwrote {len(list(OUT.glob('*.png')))} frames to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
