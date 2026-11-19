#!/usr/bin/env python3
"""Generates the raster art of the EcoPoint home-screen widgets.

Why raster: RemoteViews can only use FrameLayout / LinearLayout / ImageView /
TextView, so the premium look (sky gradients, soft glows, stars, layered hills)
is pre-rendered here and shown through ImageViews. Everything is deterministic
(fixed seeds) so re-running produces identical files.

Outputs (tool/android_res/widget/):
  art/ep_w_bg_<scene>_<sq|wide>.webp     scene backgrounds, rounded corners baked in
  ecofriend/ecofriend_w_<variant>.png    EcoFriend + soft shadow + scene accessories

EcoFriend itself is NEVER redrawn: the original PNG is composited untouched,
only light, shadow and floating accessories are added around it.

Usage:  python3 tool/gen_widget_art.py
Needs:  pip install pillow numpy
"""
import math
import pathlib
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "android_res" / "widget"
SS = 2  # supersampling

# --------------------------------------------------------------------------
# primitives
# --------------------------------------------------------------------------


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def vgrad(w, h, stops):
    """stops: [(pos 0..1, '#rrggbb'), ...] top -> bottom."""
    ys = np.linspace(0, 1, h)[:, None]
    pos = [s[0] for s in stops]
    cols = np.array([hexc(s[1])[:3] for s in stops], dtype=np.float32)
    out = np.zeros((h, w, 3), dtype=np.float32)
    for c in range(3):
        out[:, :, c] = np.interp(ys, pos, cols[:, c]).repeat(w, axis=1)
    img = np.dstack([out, np.full((h, w, 1), 255, dtype=np.float32)])
    return Image.fromarray(img.astype(np.uint8), "RGBA")


def glow(size, cx, cy, r, color, alpha=1.0, power=2.0):
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / max(r, 1)
    a = np.clip(1 - d, 0, 1) ** power * alpha
    rgb = np.array(hexc(color)[:3], dtype=np.float32)
    arr = np.zeros((h, w, 4), dtype=np.float32)
    arr[:, :, :3] = rgb
    arr[:, :, 3] = a * 255
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def over(base, layer):
    base.alpha_composite(layer)


def blur(img, r):
    return img.filter(ImageFilter.GaussianBlur(r))


def cloud(size, cx, cy, s, color, alpha=200, soft=2):
    w, h = size
    lay = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    c = hexc(color, alpha)
    for dx, dy, r in [(-1.1, 0.15, 0.55), (-0.45, -0.2, 0.75), (0.35, -0.1, 0.8), (1.05, 0.15, 0.55)]:
        d.ellipse([cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s], fill=c)
    d.rounded_rectangle([cx - 1.65 * s, cy + 0.05 * s, cx + 1.6 * s, cy + 0.7 * s], radius=0.35 * s, fill=c)
    return blur(lay, soft * SS)


def sparkle(draw, cx, cy, r, color):
    """4-point star."""
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.28
        pts.append((cx + math.cos(ang) * rad, cy + math.sin(ang) * rad))
    draw.polygon(pts, fill=color)


def star5(draw, cx, cy, r, color):
    pts = []
    for i in range(10):
        ang = math.pi / 5 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(ang) * rad, cy + math.sin(ang) * rad))
    draw.polygon(pts, fill=color)


def hills(size, layers, seed=1):
    """layers: [(base_y_frac, amp_frac, freq, phase, color, rim_color|None)]"""
    w, h = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    xs = np.arange(w)
    for base, amp, freq, phase, color, rim in layers:
        y = h * base + h * amp * (np.sin(xs / w * math.pi * 2 * freq + phase) * 0.65 +
                                  np.sin(xs / w * math.pi * 2 * freq * 2.3 + phase * 1.7) * 0.35)
        lay = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(lay)
        poly = [(0, h)] + [(int(x), float(y[x])) for x in range(0, w, 2)] + [(w, float(y[-1])), (w, h)]
        d.polygon(poly, fill=hexc(color))
        if rim:
            d.line([(int(x), float(y[x])) for x in range(0, w, 2)], fill=hexc(rim, 150), width=max(2, SS * 2))
        out.alpha_composite(lay)
    return out


def finish(img, radius):
    """Gloss, rim light, rounded corners (alpha)."""
    w, h = img.size
    gloss = vgrad(w, h, [(0, "#ffffff"), (1, "#ffffff")])
    a = np.zeros((h, w), dtype=np.float32)
    top = int(h * 0.42)
    a[:top, :] = np.linspace(0.20, 0.0, top)[:, None]
    gl = np.array(gloss)
    gl[:, :, 3] = (a * 255).astype(np.uint8)
    over(img, Image.fromarray(gl, "RGBA"))
    # bottom depth shade (premium 'lip')
    shade = np.zeros((h, w, 4), dtype=np.uint8)
    sh = int(h * 0.10)
    shade[h - sh:, :, 3] = (np.linspace(0, 46, sh)[:, None]).astype(np.uint8).repeat(w, axis=1)
    over(img, Image.fromarray(shade, "RGBA"))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    # inner rim
    rim = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle([1, 1, w - 2, h - 2], radius=radius - 1, outline=(255, 255, 255, 70), width=SS * 2)
    over(img, rim)
    img.putalpha(ImageChops.multiply(img.getchannel("A"), mask))
    return img


# --------------------------------------------------------------------------
# scenes
# --------------------------------------------------------------------------


def scene_morning(w, h, wide):
    img = vgrad(w, h, [(0, "#ff8f6b"), (0.45, "#ffb77a"), (0.78, "#ffe0a0"), (1, "#fff1c2")])
    sx, sy = (w * 0.80, h * 0.62) if wide else (w * 0.74, h * 0.58)
    over(img, glow((w, h), sx, sy, w * 0.62, "#fff0a8", 0.65, 2.2))
    over(img, glow((w, h), sx, sy, w * 0.30, "#ffffff", 0.75, 2.0))
    d = ImageDraw.Draw(img)
    r = h * (0.12 if wide else 0.085)
    d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=hexc("#fff6c9"))
    over(img, cloud((w, h), w * 0.22, h * (0.2 if wide else 0.17), h * 0.07, "#ffffff", 150))
    over(img, cloud((w, h), w * 0.58, h * (0.33 if wide else 0.30), h * 0.045, "#ffe6e0", 130))
    over(img, cloud((w, h), w * 0.90, h * 0.15, h * 0.04, "#ffffff", 110))
    # birds
    rnd = random.Random(3)
    for bx, by in [(0.38, 0.17), (0.45, 0.13), (0.52, 0.19)]:
        x, y, s = w * bx, h * by, h * 0.025
        d.arc([x - s * 1.4, y - s, x, y + s], 200, 340, fill=hexc("#c0583a", 190), width=SS * 2)
        d.arc([x, y - s, x + s * 1.4, y + s], 200, 340, fill=hexc("#c0583a", 190), width=SS * 2)
    over(img, hills((w, h), [
        (0.78, 0.035, 1.2, 0.3, "#9bd86a", "#d8f5a0"),
        (0.86, 0.03, 1.6, 2.1, "#5cbf6a", "#9be08a"),
        (0.94, 0.02, 1.1, 4.0, "#3b9f57", None),
    ]))
    # golden dust
    rnd = random.Random(5)
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dd = ImageDraw.Draw(lay)
    for _ in range(26):
        x, y = rnd.uniform(0, w), rnd.uniform(h * 0.2, h * 0.85)
        r = rnd.uniform(1.4, 3.6) * SS
        dd.ellipse([x - r, y - r, x + r, y + r], fill=hexc("#fff3b0", rnd.randint(110, 210)))
    over(img, blur(lay, 0.8 * SS))
    return img


def scene_day(w, h, wide):
    img = vgrad(w, h, [(0, "#1fb27a"), (0.5, "#5fd6a0"), (0.8, "#b6f2d2"), (1, "#e6fff1")])
    sx, sy = w * 0.80, h * (0.22 if wide else 0.18)
    over(img, glow((w, h), sx, sy, w * 0.55, "#eaffd0", 0.55, 2.0))
    over(img, glow((w, h), sx, sy, w * 0.20, "#ffffff", 0.9, 1.6))
    d = ImageDraw.Draw(img)
    r = h * (0.10 if wide else 0.075)
    d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=hexc("#fffbe0"))
    # light rays
    ray = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ray)
    for i in range(7):
        ang = math.radians(100 + i * 14)
        x2, y2 = sx + math.cos(ang) * w * 1.1, sy + math.sin(ang) * h * 1.4
        rd.polygon([(sx, sy), (x2 - w * 0.04, y2), (x2 + w * 0.04, y2)], fill=(255, 255, 255, 22))
    over(img, blur(ray, 3 * SS))
    over(img, cloud((w, h), w * 0.24, h * (0.22 if wide else 0.2), h * 0.08, "#ffffff", 235))
    over(img, cloud((w, h), w * 0.56, h * (0.4 if wide else 0.34), h * 0.05, "#ffffff", 190))
    over(img, hills((w, h), [
        (0.74, 0.04, 1.1, 0.8, "#7fe08a", "#c9ffb0"),
        (0.84, 0.035, 1.7, 2.6, "#34c46a", "#8cf0a0"),
        (0.93, 0.025, 1.2, 4.4, "#1f9d55", None),
    ]))
    # floating leaves
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay)
    rnd = random.Random(8)
    for _ in range(9):
        x, y = rnd.uniform(w * 0.05, w * 0.95), rnd.uniform(h * 0.25, h * 0.8)
        s = rnd.uniform(5, 9) * SS
        leaf = Image.new("RGBA", (int(s * 4), int(s * 4)), (0, 0, 0, 0))
        ImageDraw.Draw(leaf).ellipse([s * 0.5, s * 1.3, s * 3.5, s * 2.7], fill=hexc("#ffffff", 170))
        leaf = leaf.rotate(rnd.uniform(0, 180), resample=Image.BICUBIC)
        lay.alpha_composite(leaf, (int(x), int(y)))
    over(img, blur(lay, 0.6 * SS))
    return img


def scene_evening(w, h, wide):
    img = vgrad(w, h, [(0, "#4b3a9c"), (0.38, "#9a4fa8"), (0.68, "#ee6f8f"), (0.88, "#ff9a5c"), (1, "#ffc06a")])
    sx, sy = w * 0.26, h * (0.74 if wide else 0.70)
    over(img, glow((w, h), sx, sy, w * 0.75, "#ffb36a", 0.70, 2.0))
    over(img, glow((w, h), sx, sy, w * 0.28, "#fff0b0", 0.85, 1.8))
    d = ImageDraw.Draw(img)
    r = h * (0.13 if wide else 0.095)
    d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=hexc("#ffe7a0"))
    # streak clouds
    for cx, cy, s, col, a in [(0.60, 0.30, 0.06, "#ffc0d0", 110), (0.78, 0.44, 0.05, "#ffb0a0", 120), (0.40, 0.20, 0.045, "#c9a0ff", 100)]:
        over(img, cloud((w, h), w * cx, h * cy, h * s, col, a, 3))
    # stars
    d = ImageDraw.Draw(img)
    for x, y, rr in [(0.12, 0.1, 5), (0.35, 0.07, 4), (0.62, 0.1, 6), (0.88, 0.08, 4), (0.5, 0.22, 3), (0.94, 0.28, 3)]:
        sparkle(d, w * x, h * y, rr * SS, hexc("#ffffff", 210))
    over(img, hills((w, h), [
        (0.80, 0.03, 1.3, 1.0, "#6a3c8e", "#b074c0"),
        (0.88, 0.03, 1.8, 3.0, "#3f2a74", None),
        (0.95, 0.02, 1.2, 5.0, "#2a1d56", None),
    ]))
    return img


def scene_night(w, h, wide):
    img = vgrad(w, h, [(0, "#060f2e"), (0.45, "#0c2552"), (0.78, "#0d4a5c"), (1, "#0f6a52")])
    mx, my = w * 0.80, h * (0.26 if wide else 0.2)
    over(img, glow((w, h), mx, my, w * 0.5, "#6fa8ff", 0.35, 2.0))
    over(img, glow((w, h), mx, my, w * 0.22, "#dfe9ff", 0.55, 1.8))
    # aurora-ish emerald haze
    over(img, glow((w, h), w * 0.3, h * 1.0, w * 0.9, "#25d6a0", 0.38, 2.2))
    r = h * (0.12 if wide else 0.085)
    moon = Image.new("L", (w, h), 0)
    ImageDraw.Draw(moon).ellipse([mx - r, my - r, mx + r, my + r], fill=255)
    cut = Image.new("L", (w, h), 0)
    ImageDraw.Draw(cut).ellipse([mx - r * 0.45, my - r * 1.1, mx + r * 1.45, my + r * 0.85], fill=255)
    moon = ImageChops.subtract(moon, cut)
    disc = Image.new("RGBA", (w, h), hexc("#fff4cf"))
    disc.putalpha(moon)
    over(img, disc)
    rnd = random.Random(11)
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay)
    for i in range(46):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h * 0.62)
        if abs(x - mx) < r * 2 and abs(y - my) < r * 2:
            continue
        rr = rnd.uniform(1.0, 2.6) * SS
        ld.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(255, 255, 255, rnd.randint(110, 230)))
    over(img, lay)
    d = ImageDraw.Draw(img)
    for x, y, rr in [(0.14, 0.14, 6), (0.40, 0.09, 5), (0.62, 0.2, 5), (0.93, 0.5, 4), (0.06, 0.42, 4)]:
        sparkle(d, w * x, h * y, rr * SS, hexc("#ffffff", 235))
    # shooting star
    ss = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(ss)
    sd.line([(w * 0.50, h * 0.12), (w * 0.38, h * 0.21)], fill=(255, 255, 255, 170), width=2 * SS)
    over(img, blur(ss, 0.7 * SS))
    over(img, hills((w, h), [
        (0.78, 0.035, 1.2, 0.5, "#157a52", "#46c79a"),
        (0.87, 0.03, 1.7, 2.4, "#0f5a3e", None),
        (0.95, 0.02, 1.1, 4.2, "#093b2a", None),
    ]))
    # fireflies
    fl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fl)
    for x, y in [(0.18, 0.72), (0.34, 0.80), (0.58, 0.76), (0.7, 0.84), (0.9, 0.74), (0.08, 0.86)]:
        rr = 3 * SS
        fd.ellipse([w * x - rr, h * y - rr, w * x + rr, h * y + rr], fill=hexc("#e9ff7a", 240))
    over(img, blur(fl, 1.6 * SS))
    over(img, fl)
    return img


SCENES = {"morning": scene_morning, "day": scene_day, "evening": scene_evening, "night": scene_night}
SIZES = {"sq": (640, 640, False), "wide": (800, 360, True)}


def build_backgrounds():
    (OUT / "art").mkdir(parents=True, exist_ok=True)
    for scene, fn in SCENES.items():
        for tag, (w, h, wide) in SIZES.items():
            W, H = w * SS, h * SS
            img = fn(W, H, wide)
            radius = int((0.105 if not wide else 0.17) * min(W, H))
            img = finish(img, radius).resize((w, h), Image.LANCZOS)
            img.save(OUT / "art" / f"ep_w_bg_{scene}_{tag}.webp", "WEBP", quality=90, method=6)


# --------------------------------------------------------------------------
# mascot variants
# --------------------------------------------------------------------------

BASE = OUT / "ecofriend"
CANVAS = 448
PAD = (CANVAS - 384) // 2


def load(mood):
    im = Image.open(BASE / f"ecofriend_{mood}.png").convert("RGBA")
    out = Image.new("RGBA", (CANVAS * SS, CANVAS * SS), (0, 0, 0, 0))
    out.alpha_composite(im.resize((384 * SS, 384 * SS), Image.LANCZOS), (PAD * SS, PAD * SS - 6 * SS))
    return out


def tint(img, rgb, strength):
    """Colour wash clipped to the mascot's own alpha (light atmosphere)."""
    wash = Image.new("RGBA", img.size, rgb + (255,))
    mix = Image.blend(img.convert("RGB"), wash.convert("RGB"), strength).convert("RGBA")
    mix.putalpha(img.getchannel("A"))
    return mix


def shadow(img, color=(10, 30, 20), alpha=70):
    bb = img.getchannel("A").getbbox()
    cx = (bb[0] + bb[2]) / 2
    by = bb[3]
    w = (bb[2] - bb[0]) * 0.55
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - w, by - 10 * SS, cx + w, by + 16 * SS], fill=color + (alpha,))
    sh = blur(sh, 9 * SS)
    sh.alpha_composite(img)
    return sh


def zzz(draw, x, y, s, color):
    pts = [(x, y), (x + s, y), (x, y + s), (x + s, y + s)]
    draw.line(pts, fill=color, width=max(3, int(s * 0.22)), joint="curve")
    for px, py in (pts[0], pts[-1]):
        draw.ellipse([px - s * 0.11, py - s * 0.11, px + s * 0.11, py + s * 0.11], fill=color)


def confetti(draw, rnd, n, area, colors):
    x0, y0, x1, y1 = area
    for _ in range(n):
        x, y = rnd.uniform(x0, x1), rnd.uniform(y0, y1)
        c = hexc(rnd.choice(colors))
        if rnd.random() < 0.5:
            s = rnd.uniform(9, 15) * SS
            draw.ellipse([x - s / 2, y - s / 2, x + s / 2, y + s / 2], fill=c)
        else:
            s = rnd.uniform(14, 24) * SS
            ang = rnd.uniform(0, math.pi)
            dx, dy = math.cos(ang) * s / 2, math.sin(ang) * s / 2
            draw.line([(x - dx, y - dy), (x + dx, y + dy)], fill=c, width=int(6 * SS))


def variant(name):
    S = SS
    rnd = random.Random(hash(name) & 0xFFFF)
    base_mood = {"morning": "normal", "day": "normal", "evening": "normal", "night": "normal",
                 "excited": "excited", "cheering": "cheering", "proud": "proud", "sad": "sad"}[name]
    m = load(base_mood)
    full = Image.new("RGBA", m.size, (0, 0, 0, 0))
    deco_back = Image.new("RGBA", m.size, (0, 0, 0, 0))
    deco = Image.new("RGBA", m.size, (0, 0, 0, 0))
    db, dd = ImageDraw.Draw(deco_back), ImageDraw.Draw(deco)
    W = CANVAS * S
    if name == "morning":
        m = tint(m, (255, 190, 120), 0.07)
        for x, y, r in [(0.80, 0.18, 18), (0.20, 0.30, 12), (0.88, 0.42, 9)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#fff0a0"))
    elif name == "day":
        for x, y, r in [(0.82, 0.16, 15), (0.16, 0.26, 11)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#ffffff"))
        for x, y, a in [(0.12, 0.5, 30), (0.9, 0.34, -25), (0.84, 0.6, 20)]:
            leaf = Image.new("RGBA", (60 * S, 60 * S), (0, 0, 0, 0))
            ImageDraw.Draw(leaf).ellipse([8 * S, 22 * S, 52 * S, 40 * S], fill=hexc("#8ff0a8"))
            leaf = leaf.rotate(a, resample=Image.BICUBIC)
            deco.alpha_composite(leaf, (int(W * x), int(W * y)))
    elif name == "evening":
        m = tint(m, (255, 150, 140), 0.08)
        for x, y, r in [(0.84, 0.2, 14), (0.15, 0.22, 10), (0.9, 0.46, 8)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#ffe3f0"))
        star5(dd, W * 0.14, W * 0.44, 12 * S, hexc("#ffd36b"))
    elif name == "night":
        m = tint(m, (120, 150, 230), 0.13)
        zzz(dd, W * 0.74, W * 0.22, 34 * S, hexc("#ffffff", 235))
        zzz(dd, W * 0.84, W * 0.11, 24 * S, hexc("#cfe0ff", 220))
        zzz(dd, W * 0.91, W * 0.03, 16 * S, hexc("#9fc0ff", 200))
        for x, y, r in [(0.14, 0.2, 10), (0.2, 0.42, 7)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#dfe9ff"))
    elif name == "excited":
        db.ellipse([W * 0.1, W * 0.1, W * 0.9, W * 0.9], fill=hexc("#fff3a0", 70))
        deco_back = blur(deco_back, 18 * S)
        for x, y, r in [(0.84, 0.16, 20), (0.14, 0.2, 16), (0.9, 0.46, 12), (0.08, 0.5, 10)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#ffe14d"))
        for x, y in [(0.2, 0.08), (0.74, 0.06)]:
            r = 13 * S
            dd.ellipse([W * x - r, W * y - r, W * x + r, W * y + r], fill=hexc("#c8f23a"), outline=hexc("#6e9e0f"), width=3 * S)
    elif name == "cheering":
        confetti(dd, rnd, 34, (W * 0.04, W * 0.02, W * 0.96, W * 0.62),
                 ["#ff5d8f", "#ffd23f", "#3ddc97", "#4cc9f0", "#c77dff", "#ff9f1c"])
        for x, y, r in [(0.84, 0.18, 16), (0.15, 0.2, 14)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#ffffff"))
    elif name == "proud":
        db.ellipse([W * 0.08, W * 0.06, W * 0.92, W * 0.9], fill=hexc("#ffd86b", 90))
        deco_back = blur(deco_back, 20 * S)
        for x, y, r in [(0.86, 0.16, 26), (0.12, 0.2, 20), (0.5, 0.03, 16)]:
            star5(dd, W * x, W * y, r * S, hexc("#ffc928"))
        for x, y, r in [(0.9, 0.42, 11), (0.08, 0.46, 9)]:
            sparkle(dd, W * x, W * y, r * S, hexc("#fff1b0"))
    elif name == "sad":
        # gentle welcome-back: a small green heart and a soft cool glow, no guilt
        db.ellipse([W * 0.16, W * 0.14, W * 0.84, W * 0.88], fill=hexc("#bfe8ff", 55))
        deco_back = blur(deco_back, 20 * S)
        hx, hy, hs = W * 0.84, W * 0.2, 17 * S
        dd.ellipse([hx - hs, hy - hs, hx, hy + hs * 0.2], fill=hexc("#5ed38a"))
        dd.ellipse([hx, hy - hs, hx + hs, hy + hs * 0.2], fill=hexc("#5ed38a"))
        dd.polygon([(hx - hs, hy - hs * 0.2), (hx + hs, hy - hs * 0.2), (hx, hy + hs * 1.25)], fill=hexc("#5ed38a"))
        sparkle(dd, W * 0.14, W * 0.28, 10 * S, hexc("#dff3ff"))
    full.alpha_composite(deco_back)
    full.alpha_composite(shadow(m))
    full.alpha_composite(deco)
    return full.resize((CANVAS, CANVAS), Image.LANCZOS)


def build_mascots():
    for name in ["morning", "day", "evening", "night", "excited", "cheering", "proud", "sad"]:
        variant(name).save(BASE / f"ecofriend_w_{name}.png", optimize=True)


if __name__ == "__main__":
    build_backgrounds()
    build_mascots()
    print("ok")
