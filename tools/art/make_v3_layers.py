#!/usr/bin/env python3
"""Cuts the delivered v3 background pictures (each is a whole scene) into parallax layers:
a band of the picture is keyed (magenta or white background -> transparent) and its top/bottom edges
fade out so layers blend into each other. Output: assets/art/v3/layers/<era>_<name>.png

    python3 tools/art/make_v3_layers.py
"""
import os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import build_pair1 as b1  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SRC = os.path.join(ROOT, "assets", "art", "v3")
OUT = os.path.join(SRC, "layers")
# (era, name, source, x0, x1, y0, y1, fade_top, fade_bottom) - fractions of the source picture
BANDS = [
    ("old", "far", "v3_bg_old_far", 0.0, 1.0, 0.24, 0.62, 0.10, 0.30),
    ("old", "village", "v3_bg_old_village", 0.12, 1.0, 0.22, 0.68, 0.30, 0.30),
    ("old", "trees", "v3_bg_old_trees", 0.0, 1.0, 0.14, 0.92, 0.0, 0.0),
    ("old", "near", "v3_bg_old_near", 0.0, 1.0, 0.46, 0.82, 0.35, 0.25),
    ("new", "far", "v3_bg_new_far", 0.0, 1.0, 0.10, 0.70, 0.0, 0.30),
    ("new", "village", "v3_bg_new_village", 0.0, 1.0, 0.08, 0.74, 0.25, 0.30),
    ("new", "trees", "v3_bg_new_trees", 0.0, 1.0, 0.24, 0.92, 0.0, 0.0),
]


def make(era, name, src, x0, x1, y0, y1, ft, fb):
    path = os.path.join(SRC, src + ".png")
    if not os.path.exists(path):
        print("MISSING", src)
        return
    img = Image.open(path).convert("RGB")
    w, h = img.size
    arr = np.asarray(img).astype(np.float32)
    corner = np.median(arr[:24, :24].reshape(-1, 3), axis=0)           # the top-left corner is always background
    if corner[0] > 200 and corner[2] > 200 and corner[1] < 100:        # magenta
        d = np.sqrt(((arr - corner) ** 2).sum(axis=2))
        alpha = np.clip((d - 60) / 50, 0, 1)
        rgb = arr.copy()
        near = (alpha > 0) & (alpha < 1)
        excess = np.clip(np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1], 0, 255)
        rgb[..., 0] = np.where(near, rgb[..., 0] - excess * 0.9, rgb[..., 0])
        rgb[..., 2] = np.where(near, rgb[..., 2] - excess * 0.9, rgb[..., 2])
        full = Image.fromarray(np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8), "RGBA")
        used = "magenta"
    else:
        from key_white import key_white
        full = key_white(img, tol=16)
        used = "white"
    rgba = full.crop((int(w * x0), int(h * y0), int(w * x1), int(h * y1)))
    a = np.asarray(rgba).copy()
    hh = a.shape[0]
    fade = np.ones(hh, np.float32)
    if ft > 0:
        n = int(hh * ft)
        fade[:n] = np.linspace(0, 1, n)
    if fb > 0:
        n = int(hh * fb)
        fade[hh - n:] = np.minimum(fade[hh - n:], np.linspace(1, 0, n))
    a[..., 3] = (a[..., 3] * fade[:, None]).astype(np.uint8)
    os.makedirs(OUT, exist_ok=True)
    out = Image.fromarray(a, "RGBA")
    out.save(os.path.join(OUT, f"{era}_{name}.png"))
    print(f"OK {era}_{name}: {out.size} ({used})")


if __name__ == "__main__":
    for spec in BANDS:
        make(*spec)
