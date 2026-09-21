#!/usr/bin/env python3
"""Compose LinkedIn-ready marketing images from the rendered app shots.

    flutter test test/submission_shots_test.dart   # build/submission/*.png
    python3 tool/make_social_images.py             # build/social/<ratio>/*.png
    python3 tool/make_social_images.py square      # just the one ratio

Same machinery as `make_store_screenshots.py` — an SVG laid out at exactly the
pixel size the slot wants, embedding the font and the screenshot as data URIs
and rasterised through headless Chrome, which is the only local renderer that
resolves @font-face reliably.

The ratios are LinkedIn's, and only LinkedIn's:

    landscape  1200x627   1.91:1  link preview and the classic feed image
    square     1200x1200  1:1     feed, and each slide of a document carousel
    portrait   1080x1350  4:5     the tallest the feed will show uncropped
    banner     1584x396   4:1     personal profile cover

Anything taller than 4:5 is centre-cropped in the feed, so nothing here is.
Text stays inside a safe margin on every ratio because LinkedIn crops the
link-preview card differently on mobile than on the web.

Nothing in the copy claims a release that has not happened — `CTA` below is the
one line to edit when the app leaves TestFlight.
"""

from __future__ import annotations

import base64
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"
SHOTS = ROOT / "build" / "submission"
OUT = ROOT / "build" / "social"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Design tokens, lifted from lib/design/tokens.dart so the posts and the app
# are the same artifact rather than two things that merely look alike.
STOCK = "#F4EFE6"
STOCK_RAISED = "#FBF8F2"
INK = "#1A1714"
INK_MUTED = "#4F4841"
SIGNAL = "#0B5F63"
SIGNAL_INK = "#FBF8F2"
RULE = "#D8D0C3"

# The one factual footer. The app is on TestFlight and has not been submitted
# for review, so nothing here says "download on the App Store" yet.
CTA = "betterintegrations.org/calmcheck"

# Rough advance widths, in ems, for the two faces. Used only to break lines;
# the renderer does the real typesetting.
EM_BOLD = 0.545
EM_REGULAR = 0.505


class Ratio:
    """One LinkedIn slot.

    `k` scales typography by the frame's diagonal rather than its width: the
    banner is wider than the square and the portrait is narrower, but type that
    tracked width alone would be comic on one and unreadable on the other.
    """

    def __init__(self, name: str, w: int, h: int, *, margin: float, shot_top: float, shot_h: float):
        self.name = name
        self.w = w
        self.h = h
        self.margin = margin  # fraction of the short edge
        self.shot_top = shot_top  # fraction of H where the phone starts
        self.shot_h = shot_h  # fraction of H the phone occupies (>1-top bleeds)
        self.k = (w * h) ** 0.5 / 1200

    @property
    def split(self) -> bool:
        """Wide frames put the phone beside the words, tall ones beneath them."""
        return self.w / self.h >= 1.6


RATIOS = {
    r.name: r
    for r in [
        Ratio("landscape", 1200, 627, margin=0.105, shot_top=0.10, shot_h=1.06),
        Ratio("square", 1200, 1200, margin=0.075, shot_top=0.40, shot_h=0.72),
        Ratio("portrait", 1080, 1350, margin=0.075, shot_top=0.38, shot_h=0.74),
        Ratio("banner", 1584, 396, margin=0.13, shot_top=0.0, shot_h=0.0),
    ]
}

# The text-only card is the care card itself: micro-labels over values, with
# hairline rules between, which is the one device this design system signs with.
FIELDS = [
    ("WHAT IT DOES", "Paced breathing, sensory grounding, crisis helplines."),
    ("WHO IT IS FOR", "You in the moment — or the person you look after."),
    ("WHAT IT COSTS", "The crisis half is free forever and never sits near an upsell."),
    ("WHERE IT RUNS", "Entirely on the device. Airplane mode is a supported state."),
]

# Each post is one idea. The order is the pitch — the same order as the store
# frames, so a carousel and the listing tell the story the same way.
POSTS = [
    (
        "01-offline",
        "01-home",
        "WHEN IT STARTS",
        "Panic help that works\nin airplane mode.",
        "One tap from the home screen. No signal, no sign-in, no account.",
    ),
    (
        "02-breathing",
        "02-panic",
        "THE PANIC FLOW",
        "Breathing you can feel,\nnot just watch.",
        "Paced with haptics and a voice, for eyes that are half closed.",
    ),
    (
        "03-helplines",
        "06-crisis",
        "CRISIS HELPLINES",
        "237 territories.\nNone of them need a network.",
        "Every helpline ships inside the app. Free forever, never behind a paywall.",
    ),
    (
        "04-care-cards",
        "03-card-view",
        "CARE CARDS",
        "What to do.\nWhat not to do.",
        "A page about one person that any stranger can follow in seconds.",
    ),
    (
        "05-share",
        "04-share",
        "SHARING",
        "Phone to phone.\nNo server in between.",
        "A care card travels as a QR code or a file. Nothing is uploaded.",
    ),
    (
        "06-privacy",
        "05-privacy",
        "PRIVACY",
        "Nothing leaves\nyour phone.",
        "No analytics, no servers, no sign-in. The one network call checks a purchase.",
    ),
    (
        "07-thesis",
        None,
        "THE WHOLE IDEA",
        "Someone is in distress right now.\nTell them what to do in the next\n60 seconds.",
        "CalmCheck — offline-first calm, and a care card for the person you look after.",
    ),
]


def esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def data_uri(path: pathlib.Path, mime: str) -> str:
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def wrap(text: str, size: float, width: float, em: float) -> list[str]:
    """Greedy wrap at an approximate advance width. `\\n` is a hard break."""
    out: list[str] = []
    for para in text.split("\n"):
        line = ""
        for word in para.split():
            trial = f"{line} {word}".strip()
            if len(trial) * size * em > width and line:
                out.append(line)
                line = word
            else:
                line = trial
        out.append(line)
    return out


def fit(text: str, size: float, width: float, em: float, max_lines: int) -> tuple[list[str], float]:
    """Shrink until the headline fits the column in at most `max_lines`."""
    while size > 8:
        lines = wrap(text, size, width, em)
        if len(lines) <= max_lines:
            return lines, size
        size *= 0.92
    return wrap(text, size, width, em), size


def build_svg(r: Ratio, shot: pathlib.Path | None, label: str, headline: str, sub: str) -> str:
    regular = data_uri(FONTS / "AtkinsonHyperlegible-Regular.ttf", "font/ttf")
    bold = data_uri(FONTS / "AtkinsonHyperlegible-Bold.ttf", "font/ttf")
    mono = data_uri(FONTS / "IBMPlexMono-SemiBold.ttf", "font/ttf")

    W, H, k = r.w, r.h, r.k
    m = round(min(W, H) * r.margin)

    if r.name == "banner":
        return build_banner(W, H, k, m, regular, bold, mono)

    # A frame with no screenshot becomes the object the whole design system is
    # about: a card with an edge, printed on raised stock.
    card = shot is None
    pad = round(52 * k) if card else 0
    x = m + pad
    col = (W - 2 * m - 2 * pad) if card else (W - 2 * m)

    # Where the phone goes. A split frame stands it beside the words; a stacked
    # one hangs it under them and lets it bleed off the bottom edge, so there is
    # never a flat cut across the screen.
    sx = sy = sw = sh = 0
    if shot is not None and r.split:
        sh = round(H * r.shot_h)
        sw = round(sh * 1284 / 2778)
        sx, sy = W - m - sw, round(H * r.shot_top)
        col = sx - m - round(44 * k)

    label_size = 17 * k
    head_size = (64 if shot is not None else 60) * k
    lines, head_size = fit(headline, head_size, col, EM_BOLD, 5 if r.split else 4)
    line_h = head_size * 1.16

    sub_size = 25 * k
    sub_lines = wrap(sub, sub_size, col * (0.88 if card else 1.0), EM_REGULAR)

    rule_gap = round(26 * k)
    head_gap = round(44 * k)
    sub_gap = round(38 * k)
    block = (
        label_size
        + rule_gap
        + head_gap
        + len(lines) * line_h
        + sub_gap
        + len(sub_lines) * sub_size * 1.42
    )

    # The field rows only earn their place if the frame is tall enough to print
    # them at full size. A short frame drops them and centres the words instead.
    rows: list[tuple[str, list[str]]] = []
    natural: list[float] = []
    if card:
        rows = [(lbl, wrap(val, 26 * k, col, EM_REGULAR)) for lbl, val in FIELDS]
        natural = [16 * k + 30 * k + (len(v) - 1) * 26 * k * 1.35 + 12 * k for _, v in rows]
        foot = H - m - pad - round(30 * k)
        while rows and m + pad + block + 72 * k + sum(natural) + len(rows) * 34 * k > foot:
            rows.pop()
            natural.pop()

    if r.split and not card:
        top = (H - block) / 2
    elif card:
        top = m + pad if rows else (H - block) / 2
    else:
        top = m + round(20 * k)

    parts: list[str] = []

    if card:
        parts.append(
            f'<rect x="{m}" y="{m}" width="{W - 2 * m}" height="{H - 2 * m}" rx="{round(10 * k)}" '
            f'ry="{round(10 * k)}" fill="{STOCK_RAISED}" stroke="{RULE}" stroke-width="{max(1, round(2 * k))}"/>'
        )

    y = top + label_size
    parts.append(f'<text class="lbl" x="{x}" y="{y:.0f}">{esc(label)}</text>')

    y += rule_gap
    parts.append(
        f'<rect x="{x}" y="{y:.0f}" width="{round(72 * k)}" height="{max(1, round(2 * k))}" fill="{SIGNAL}"/>'
    )

    y += head_gap + head_size * 0.76
    head = "".join(f'<tspan x="{x}" y="{y + i * line_h:.0f}">{esc(ln)}</tspan>' for i, ln in enumerate(lines))
    parts.append(f'<text class="h">{head}</text>')

    y += (len(lines) - 1) * line_h + sub_gap + sub_size
    subs = "".join(
        f'<tspan x="{x}" y="{y + i * sub_size * 1.42:.0f}">{esc(ln)}</tspan>'
        for i, ln in enumerate(sub_lines)
    )
    parts.append(f'<text class="s">{subs}</text>')
    text_bottom = y + (len(sub_lines) - 1) * sub_size * 1.42

    if rows:
        # Space the rows through whatever the headline left, but never tighter
        # than the type needs — a squeezed field row stops looking printed.
        gap = max(34 * k, (foot - (text_bottom + 72 * k) - sum(natural)) / len(rows))
        fy = text_bottom + 72 * k
        for (lbl, vals), nat in zip(rows, natural):
            parts.append(
                f'<rect x="{x}" y="{fy:.0f}" width="{col}" height="1" fill="{RULE}"/>'
            )
            fy += gap * 0.42
            parts.append(f'<text class="flbl" x="{x}" y="{fy + 16 * k:.0f}">{esc(lbl)}</text>')
            fy += 16 * k + round(30 * k)
            vv = "".join(
                f'<tspan x="{x}" y="{fy + i * 26 * k * 1.35:.0f}">{esc(ln)}</tspan>'
                for i, ln in enumerate(vals)
            )
            parts.append(f'<text class="fval">{vv}</text>')
            fy += (len(vals) - 1) * 26 * k * 1.35 + gap * 0.58

    # The stacked phone starts under whatever the text actually needed, rather
    # than at a fixed fraction that leaves a hole when the copy is short.
    if shot is not None and not r.split:
        sy = round(text_bottom + 60 * k)
        sh = round(H * 1.05 - sy)
        sw = round(sh * 1284 / 2778)
        if sw > W - 2 * m:
            sw = W - 2 * m
            sh = round(sw * 2778 / 1284)
        sx = (W - sw) // 2

    # The wordmark line: bottom-left where the phone stands beside the words,
    # top-right where it stands beneath them, clear of the bleed either way.
    if r.split or card:
        cta = f'<text class="cta" x="{x}" y="{H - m - round(4 * k)}">{esc(CTA)}</text>'
    else:
        cta = f'<text class="cta" x="{W - m}" y="{top + label_size:.0f}" text-anchor="end">{esc(CTA)}</text>'
    parts.append(cta)

    shot_svg = ""
    if shot is not None:
        radius = round(30 * k)
        img = data_uri(shot, "image/png")
        shot_svg = f"""
  <clipPath id="screen">
    <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="{radius}" ry="{radius}"/>
  </clipPath>
  <image href="{img}" x="{sx}" y="{sy}" width="{sw}" height="{sh}"
         preserveAspectRatio="xMidYMin slice" clip-path="url(#screen)"/>
  <rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="{radius}" ry="{radius}"
        fill="none" stroke="{RULE}" stroke-width="{max(1, round(2 * k))}"/>"""

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <style>
      @font-face {{ font-family: 'Atkinson'; font-weight: 400; src: url({regular}) format('truetype'); }}
      @font-face {{ font-family: 'Atkinson'; font-weight: 700; src: url({bold}) format('truetype'); }}
      @font-face {{ font-family: 'PlexMono'; font-weight: 600; src: url({mono}) format('truetype'); }}
      .h {{ font-family: 'Atkinson'; font-weight: 700; font-size: {head_size:.0f}px; fill: {INK}; letter-spacing: {-1.1 * k:.1f}px; }}
      .s {{ font-family: 'Atkinson'; font-weight: 400; font-size: {sub_size:.0f}px; fill: {INK_MUTED}; }}
      .lbl {{ font-family: 'PlexMono'; font-weight: 600; font-size: {label_size:.0f}px; fill: {SIGNAL}; letter-spacing: {3.4 * k:.1f}px; }}
      .flbl {{ font-family: 'PlexMono'; font-weight: 600; font-size: {15 * k:.0f}px; fill: {SIGNAL}; letter-spacing: {3 * k:.1f}px; }}
      .fval {{ font-family: 'Atkinson'; font-weight: 400; font-size: {26 * k:.0f}px; fill: {INK}; }}
      .cta {{ font-family: 'PlexMono'; font-weight: 600; font-size: {15 * k:.0f}px; fill: {INK_MUTED}; letter-spacing: {2.2 * k:.1f}px; }}
    </style>
  </defs>

  <rect width="{W}" height="{H}" fill="{STOCK}"/>
{shot_svg}
  {"".join(parts)}
</svg>"""


def build_banner(W, H, k, m, regular, bold, mono) -> str:
    """The profile cover.

    Both LinkedIn page types drop the avatar over the lower-left corner, so
    nothing that has to be read starts before 30% of the width. Sizes track the
    banner's own height rather than the shared `k`, which is tuned for frames
    with a phone in them.
    """
    head = round(H * 0.135)
    sub = round(H * 0.058)
    lbl = round(H * 0.046)
    x = round(W * 0.30)
    mid = H // 2

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <defs>
    <style>
      @font-face {{ font-family: 'Atkinson'; font-weight: 400; src: url({regular}) format('truetype'); }}
      @font-face {{ font-family: 'Atkinson'; font-weight: 700; src: url({bold}) format('truetype'); }}
      @font-face {{ font-family: 'PlexMono'; font-weight: 600; src: url({mono}) format('truetype'); }}
      .h {{ font-family: 'Atkinson'; font-weight: 700; font-size: {head}px; fill: {INK}; letter-spacing: -1px; }}
      .s {{ font-family: 'Atkinson'; font-weight: 400; font-size: {sub}px; fill: {INK_MUTED}; }}
      .lbl {{ font-family: 'PlexMono'; font-weight: 600; font-size: {lbl}px; fill: {SIGNAL}; letter-spacing: {lbl * 0.22:.1f}px; }}
    </style>
  </defs>

  <rect width="{W}" height="{H}" fill="{STOCK}"/>
  <rect x="0" y="0" width="{round(W * 0.012)}" height="{H}" fill="{SIGNAL}"/>

  <text class="lbl" x="{x}" y="{mid - head - round(H * 0.06)}">CALMCHECK</text>
  <rect x="{x}" y="{mid - head - round(H * 0.035)}" width="{round(H * 0.20)}" height="2" fill="{SIGNAL}"/>
  <text class="h" x="{x}" y="{mid + round(H * 0.03)}">Panic help that works in airplane mode.</text>
  <text class="s" x="{x}" y="{mid + head * 0.55 + sub + round(H * 0.03)}">Breathing, grounding, crisis helplines and care cards — all on the device.</text>
</svg>"""


def render(svg: str, target: pathlib.Path, w: int, h: int) -> None:
    tmp = target.parent / ".work"
    tmp.mkdir(parents=True, exist_ok=True)
    svg_path = tmp / (target.stem + ".svg")
    svg_path.write_text(svg)
    subprocess.run(
        [
            CHROME,
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--screenshot={target}",
            f"--window-size={w},{h}",
            f"--default-background-color={STOCK.lstrip('#')}FF",
            svg_path.as_uri(),
        ],
        check=True,
        capture_output=True,
    )


def compose(r: Ratio) -> None:
    out = OUT / r.name
    out.mkdir(parents=True, exist_ok=True)
    print(f"{r.name} → {out.relative_to(ROOT)} ({r.w}x{r.h})")

    if r.name == "banner":
        target = out / "banner.png"
        render(build_svg(r, None, "", "", ""), target, r.w, r.h)
        print(f"  {target.name}")
    else:
        for slug, shot_name, label, headline, sub in POSTS:
            shot = SHOTS / f"{shot_name}.png" if shot_name else None
            if shot is not None and not shot.exists():
                print(f"  skip {slug}: no {shot.name}")
                continue
            target = out / f"{slug}.png"
            render(build_svg(r, shot, label, headline, sub), target, r.w, r.h)
            print(f"  {target.name}")

    shutil.rmtree(out / ".work", ignore_errors=True)


def main() -> int:
    if not pathlib.Path(CHROME).exists():
        sys.exit(f"Chrome not found at {CHROME}")
    if not SHOTS.is_dir():
        sys.exit(
            f"{SHOTS.relative_to(ROOT)} missing — run:\n"
            "  flutter test test/submission_shots_test.dart"
        )

    wanted = sys.argv[1:] or list(RATIOS)
    for name in wanted:
        if name not in RATIOS:
            sys.exit(f"unknown ratio {name!r} — one of {', '.join(RATIOS)}")
        compose(RATIOS[name])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
