#!/usr/bin/env python3
"""Procedural painted sky (used when no generated sky is available): a warm sunrise, soft fluffy
clouds lit gold from below, a sun with light rays. Tileable left-right. 3072 x 2048.

    python3 tools/art/make_sky.py [old]        # -> assets/art/v3/v3_bg_old_sky.png
"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H = 3072, 2048
rng = np.random.default_rng(7)


def periodic_noise(w, h, cells_x, cells_y, seed):
    r = np.random.default_rng(seed)
    g = r.random((cells_y + 1, cells_x))
    g = np.concatenate([g, g[:, :1]], axis=1)             # wraps horizontally
    img = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.asarray(img).astype(np.float32) / 255.0


def fbm(w, h, base_x, base_y, octaves=5):
    out = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        out += amp * periodic_noise(w, h, base_x * 2 ** o, base_y * 2 ** o, 100 + o)
        total += amp
        amp *= 0.5
    return out / total


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def make(name="old"):
    y = np.linspace(0, 1, H, dtype=np.float32)[:, None]
    top, mid, low = np.array([26, 84, 196]), np.array([118, 178, 240]), np.array([255, 224, 150])
    t = y
    col = np.where(t < 0.55, top + (mid - top) * (t / 0.55)[..., None] if False else 0, 0)
    sky = np.zeros((H, W, 3), np.float32)
    a = np.clip(t / 0.55, 0, 1)
    b = np.clip((t - 0.55) / 0.45, 0, 1)
    for c in range(3):
        sky[..., c] = np.where(t < 0.55, top[c] + (mid[c] - top[c]) * a, mid[c] + (low[c] - mid[c]) * b)
    # clouds: layered fbm, more of them in the middle band
    n = fbm(W, H, 8, 4, 6)
    band = smooth(0.12, 0.40, y) * (1 - smooth(0.72, 0.98, y))
    density = smooth(0.56, 0.68, n + 0.22 * (band - 0.5))
    density *= band
    soft = Image.fromarray((density * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
    dens = np.asarray(soft).astype(np.float32) / 255.0
    # lighting: a cloud is white on top and gold underneath (gradient along y inside the cloud)
    shift = np.roll(dens, -26, axis=0)
    rim_below = np.asarray(Image.fromarray((np.clip(dens - shift, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10))).astype(np.float32) / 255.0 * 4.5   # lower edges, smooth
    rim_above = np.clip(np.roll(dens, 26, axis=0) - dens, 0, 1) * 1.5
    white = np.array([255, 252, 246], np.float32)
    gold = np.array([255, 205, 120], np.float32)
    shade = np.array([186, 205, 238], np.float32)
    cloud_col = white[None, None, :] * (1 - 0.35 * dens[..., None]) + shade[None, None, :] * (0.35 * dens[..., None])
    cloud_col = cloud_col * (1 - np.clip(rim_below, 0, 1)[..., None]) + gold * np.clip(rim_below, 0, 1)[..., None]
    sky = sky * (1 - dens[..., None] * 0.96) + cloud_col * (dens[..., None] * 0.96)
    # the sun and its glow, low on the right; light rays fanning out
    sx, sy = 0.78 * W, 0.62 * H
    xs = np.arange(W, dtype=np.float32)[None, :]
    ys = np.arange(H, dtype=np.float32)[:, None]
    d = np.sqrt((xs - sx) ** 2 + (ys - sy) ** 2)
    glow = np.exp(-(d / (0.16 * W)) ** 1.3)
    disc = smooth(110, 85, d)
    ang = np.arctan2(ys - sy, xs - sx)
    rays = (0.5 + 0.5 * np.sin(ang * 18 + 1.3) * np.sin(ang * 7 - 0.4)) * np.exp(-(d / (0.55 * W)) ** 1.2)
    warm = np.array([255, 232, 160], np.float32)
    sky += warm * glow[..., None] * 0.28 + warm * (rays * 0.10)[..., None]
    sky = sky * (1 - disc[..., None]) + np.array([255, 250, 225]) * disc[..., None]
    out = Image.fromarray(np.clip(sky, 0, 255).astype(np.uint8))
    path = os.path.join(ROOT, "assets", "art", "v3", f"v3_bg_{name}_sky.png")
    out.save(path)
    print("wrote", path)


if __name__ == "__main__":
    make(sys.argv[1] if len(sys.argv) > 1 else "old")
