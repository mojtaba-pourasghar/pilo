#!/usr/bin/env python3
"""کلید پس‌زمینهٔ صورتی/مجنتا (#FF00FF) برای برش برگه‌ها.

استفاده:  python3 tools/art/key_pink.py in.png out.png [--tol 70] [--soft 40]
خروجی: PNG با آلفا؛ هالهٔ صورتی لبه‌ها کاهش می‌یابد (despill).
قاعدهٔ هنر: هیچ بخشی از طرح مجنتا/صورتی نیست (docs/29 §۱٫۱).
"""
import sys
import numpy as np
from PIL import Image


def sample_bg(a):
    """رنگ پس‌زمینه از میانهٔ چهار گوشه (Canva رنگ را دقیقاً FF00FF نمی‌کشد)."""
    h, w = a.shape[:2]
    k = max(4, min(h, w) // 40)
    patches = [a[:k, :k], a[:k, -k:], a[-k:, :k], a[-k:, -k:]]
    return np.median(np.concatenate([p.reshape(-1, 3) for p in patches]), axis=0)


def key_pink(img, tol=70, soft=40):
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    bg = sample_bg(a)
    d = np.sqrt((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2)
    alpha = np.clip((d - tol) / max(soft, 1), 0, 1)
    # despill: سرخابی باقی‌مانده در لبه‌ها را به سمت g می‌کشیم
    spill = np.clip(np.minimum(r, b) - g, 0, 255) * (1 - alpha) * 0.0
    near = (alpha < 1) & (alpha > 0)
    m = np.minimum(r, b)
    excess = np.clip(m - g, 0, 255)
    r2 = np.where(near, r - excess * 0.9, r)
    b2 = np.where(near, b - excess * 0.9, b)
    out = np.dstack([r2 - spill, g, b2 - spill, alpha * 255]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    tol, soft = 70, 40
    args = sys.argv[3:]
    for i, v in enumerate(args):
        if v == "--tol":
            tol = float(args[i + 1])
        if v == "--soft":
            soft = float(args[i + 1])
    key_pink(Image.open(sys.argv[1]), tol, soft).save(sys.argv[2])


if __name__ == "__main__":
    main()
