#!/usr/bin/env python3
"""Compose App Store marketing screenshots from the rendered app shots.

    flutter test test/submission_shots_test.dart                          # build/submission/
    flutter test test/submission_shots_test.dart --dart-define=SHOT_DEVICE=ipad13
    python3 tool/make_store_screenshots.py            # both, into build/store{,-ipad}/
    python3 tool/make_store_screenshots.py ipad13     # just the one

Each frame is an SVG laid out at exactly the pixel size one App Store Connect
slot accepts, carrying a caption in the app's own typeface above the real
screen. The SVG embeds both the font and the screenshot as data URIs and is
rasterised through headless Chrome, which is the only local renderer that
resolves @font-face reliably; fontconfig-based rasterisers silently substitute
a default face and the caption stops looking like the app.

The console takes one size per slot and refuses everything else — 1284x2778
for the 6.5" iPhone, 2064x2752 for the 13" iPad — and the iPad slot is required
as long as the binary declares iPad support. Output is flattened onto an opaque
background because App Store Connect rejects PNGs carrying an alpha channel.
"""

from __future__ import annotations

import base64
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Design tokens, lifted from lib/design/tokens.dart so the frames and the app
# are the same artifact rather than two things that merely look alike.
STOCK = "#F4EFE6"
INK = "#1A1714"
INK_MUTED = "#4F4841"
SIGNAL = "#0B5F63"
RULE = "#D8D0C3"


class Device:
    """One App Store Connect screenshot slot.

    `k` scales the caption typography. It is not the width ratio: the iPad
    frame is 61% wider than the phone but far squarer, so scaling type by width
    would eat the frame. The square root of the width ratio keeps the caption
    in proportion to the frame's diagonal, which is what the eye reads.
    """

    def __init__(self, name: str, w: int, h: int, shots: str, out: str):
        self.name = name
        self.w = w
        self.h = h
        self.shots = ROOT / shots
        self.out = ROOT / out
        self.k = (w / 1284) ** 0.5


DEVICES = {
    d.name: d
    for d in [
        Device("iphone65", 1284, 2778, "build/submission", "build/store"),
        Device("ipad13", 2064, 2752, "build/submission-ipad", "build/store-ipad"),
    ]
}

# The order is the pitch — see docs/store-submission.md section 9.
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


def build_svg(dev: Device, shot: pathlib.Path, headline: str, sub: str) -> str:
    regular = data_uri(FONTS / "AtkinsonHyperlegible-Regular.ttf", "font/ttf")
    bold = data_uri(FONTS / "AtkinsonHyperlegible-Bold.ttf", "font/ttf")
    mono = data_uri(FONTS / "IBMPlexMono-SemiBold.ttf", "font/ttf")
    img = data_uri(shot, "image/png")

    W, H, k = dev.w, dev.h, dev.k

    def s(v: float) -> int:
        return round(v * k)

    # The screen is sized by the height left under the caption rather than by
    # a width fraction, so it always lands whole: no bleed off the bottom edge
    # on the tall phone frame, no overshoot on the squarer iPad one. The shot
    # has the frame's aspect ratio, so one dimension determines the other.
    cap, margin_bottom = s(470), s(58)
    sh = H - cap - margin_bottom
    sw = round(sh * W / H)
    sx, sy = (W - sw) // 2, cap
    radius = s(64)

    lines = headline.split("\n")
    line_h = s(104)
    top = s(300) - (len(lines) - 1) * line_h // 2
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
      .h {{ font-family: 'Atkinson'; font-weight: 700; font-size: {s(88)}px; fill: {INK}; letter-spacing: {-1.5 * k:.1f}px; }}
      .s {{ font-family: 'Atkinson'; font-weight: 400; font-size: {s(40)}px; fill: {INK_MUTED}; }}
      .k {{ font-family: 'PlexMono'; font-weight: 600; font-size: {s(26)}px; fill: {SIGNAL}; letter-spacing: {5 * k:.1f}px; }}
    </style>
    <clipPath id="screen">
      <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="{radius}" ry="{radius}"/>
    </clipPath>
  </defs>

  <rect width="{W}" height="{H}" fill="{STOCK}"/>

  <text class="k" x="{W // 2}" y="{s(168)}" text-anchor="middle">CALMCHECK</text>
  <text class="h" text-anchor="middle">{tspans}</text>
  <text class="s" x="{W // 2}" y="{top + (len(lines) - 1) * line_h + s(84)}" text-anchor="middle">{sub}</text>

  <image href="{img}" x="{sx}" y="{sy}" width="{sw}" height="{sh}"
         preserveAspectRatio="xMidYMin slice" clip-path="url(#screen)"/>
  <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="{radius}" ry="{radius}"
        fill="none" stroke="{RULE}" stroke-width="{s(3)}"/>
</svg>"""


def compose(dev: Device) -> None:
    if not dev.shots.is_dir():
        sys.exit(
            f"{dev.shots.relative_to(ROOT)} missing — run:\n"
            f"  flutter test test/submission_shots_test.dart"
            + ("" if dev.name == "iphone65" else f" --dart-define=SHOT_DEVICE={dev.name}")
        )

    dev.out.mkdir(parents=True, exist_ok=True)
    tmp = dev.out / ".work"
    tmp.mkdir(exist_ok=True)

    print(f"{dev.name} → {dev.out.relative_to(ROOT)} ({dev.w}x{dev.h})")
    for index, (name, headline, sub) in enumerate(FRAMES, start=1):
        shot = dev.shots / f"{name}.png"
        if not shot.exists():
            print(f"  skip {name}: no {shot.name}")
            continue

        svg_path = tmp / f"{name}.svg"
        svg_path.write_text(build_svg(dev, shot, headline, sub))

        # Chrome writes the screenshot next to --screenshot=<path>. The window
        # size is the SVG's intrinsic size, so no scaling happens.
        target = dev.out / f"{index:02d}-{name.split('-', 1)[1]}.png"
        subprocess.run(
            [
                CHROME,
                "--headless",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                f"--screenshot={target}",
                f"--window-size={dev.w},{dev.h}",
                f"--default-background-color={STOCK.lstrip('#')}FF",
                svg_path.as_uri(),
            ],
            check=True,
            capture_output=True,
        )
        print(f"  {target.name}")

    shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    if not pathlib.Path(CHROME).exists():
        sys.exit(f"Chrome not found at {CHROME}")

    wanted = sys.argv[1:] or list(DEVICES)
    for name in wanted:
        if name not in DEVICES:
            sys.exit(f"unknown device {name!r} — one of {', '.join(DEVICES)}")
        compose(DEVICES[name])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
