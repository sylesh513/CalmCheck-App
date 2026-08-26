"""Generates the app icon set from one description of the mark.

The mark is the orb: the one light in the Field Card system, on the ACUTE
ground. No heart, no lotus, no brain, no plus sign, no leaf, no hands. It has to
survive at 48x48, so it is one shape and one glow — nothing that turns to mush.
"""
import math, os
from PIL import Image, ImageDraw

GROUND = (0x12, 0x14, 0x12, 255)   # ACUTE stock
SIGNAL = (0x7F, 0xD8, 0xD2)        # ACUTE signal


def draw_orb(size, *, ground, orb_fraction, centre_y=0.5, mono=False, supersample=4):
    """One orb, painted the way the CustomPainter paints it: a solid core with
    a radial glow behind it, no blur filter anywhere."""
    s = size * supersample
    img = Image.new("RGBA", (s, s), ground if ground else (0, 0, 0, 0))
    px = img.load()

    cx, cy = s / 2, s * centre_y
    r = s * orb_fraction / 2
    glow_r = r * 2.1
    colour = (255, 255, 255) if mono else SIGNAL

    # Glow: the same three stops as the painter, at full amplitude.
    for y in range(s):
        dy = y - cy
        if abs(dy) > glow_r:
            continue
        for x in range(s):
            dx = x - cx
            d = math.hypot(dx, dy)
            if d > glow_r:
                continue
            t = d / glow_r
            if t <= 0.55:
                a = 0.55 + (0.16 - 0.55) * (t / 0.55)
            else:
                a = 0.16 * (1 - (t - 0.55) / 0.45)
            if a <= 0:
                continue
            base = px[x, y]
            out = []
            for i in range(3):
                out.append(int(base[i] + (colour[i] - base[i]) * a))
            alpha = base[3] if ground else int(255 * a)
            px[x, y] = (out[0], out[1], out[2], max(base[3], alpha) if not ground else 255)

    d = ImageDraw.Draw(img)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=colour + (255,))

    # A soft off-centre highlight, so the core reads as a lit body.
    hr = r * 0.62
    hx, hy = cx - r * 0.16, cy - r * 0.24
    highlight = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    steps = 26
    for i in range(steps, 0, -1):
        f = i / steps
        a = int(34 * (1 - f) ** 1.7)
        hd.ellipse([hx - hr * f, hy - hr * f, hx + hr * f, hy + hr * f],
                   fill=(255, 255, 255, a))
    img = Image.alpha_composite(img, highlight)

    return img.resize((size, size), Image.LANCZOS)


def save(img, path, *, rgb=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert("RGB") if rgb else img).save(path)
    print("wrote", path)


root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Store icon: 1024x1024, no alpha, no rounded corners baked in.
store_icon = draw_orb(1024, ground=GROUND, orb_fraction=0.46)
save(store_icon, f"{root}/store/icon-1024.png", rgb=True)

# The 48x48 legibility test, rendered from the same mark.
save(store_icon.resize((48, 48), Image.LANCZOS), f"{root}/store/icon-48.png", rgb=True)

# iOS: one 1024 asset, flat, no alpha.
save(store_icon, f"{root}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", rgb=True)
for name, px in [
    ("Icon-App-20x20@1x", 20), ("Icon-App-20x20@2x", 40), ("Icon-App-20x20@3x", 60),
    ("Icon-App-29x29@1x", 29), ("Icon-App-29x29@2x", 58), ("Icon-App-29x29@3x", 87),
    ("Icon-App-40x40@1x", 40), ("Icon-App-40x40@2x", 80), ("Icon-App-40x40@3x", 120),
    ("Icon-App-60x60@2x", 120), ("Icon-App-60x60@3x", 180),
    ("Icon-App-76x76@1x", 76), ("Icon-App-76x76@2x", 152),
    ("Icon-App-83.5x83.5@2x", 167),
]:
    save(draw_orb(px, ground=GROUND, orb_fraction=0.46),
         f"{root}/ios/Runner/Assets.xcassets/AppIcon.appiconset/{name}.png", rgb=True)

# Android legacy launcher icons.
for folder, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    save(draw_orb(px, ground=GROUND, orb_fraction=0.46),
         f"{root}/android/app/src/main/res/mipmap-{folder}/ic_launcher.png", rgb=True)

# Android adaptive: the foreground respects the 66% safe zone, so the orb is
# drawn small enough to survive every mask the launcher applies.
for folder, px in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)]:
    save(draw_orb(px, ground=None, orb_fraction=0.40),
         f"{root}/android/app/src/main/res/mipmap-{folder}/ic_launcher_foreground.png")
    save(draw_orb(px, ground=None, orb_fraction=0.40, mono=True),
         f"{root}/android/app/src/main/res/mipmap-{folder}/ic_launcher_monochrome.png")
