#!/usr/bin/env python3
"""کلید پس‌زمینهٔ سفید (برای برگه‌هایی که ابزار تصویر به‌جای مجنتا سفید داده).

فقط سفیدِ **متصل به لبهٔ تصویر** حذف می‌شود؛ سفیدِ داخل طرح (چشم، تخم، ساعت) می‌ماند.
لبه‌ها نرم (alpha) و هالهٔ سفید با un-premultiply کم می‌شود.
استفاده:  python3 tools/art/key_white.py in.png out.png [--tol 18]
(tol = فاصلهٔ مجاز از سفید خالص برای «پس‌زمینه» حساب شدن؛ کم‌تر = محافظه‌کارتر)
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi


def key_white(img, tol=18, edge_soft=34, global_=False, fx_band=0):
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w = a.shape[:2]
    dist = 255.0 - a.min(axis=2)               # 0 = سفید خالص
    near = dist <= tol
    lab, n = ndi.label(near)
    if global_:                     # همهٔ سفیدها شفاف (اورلی‌هایی که داخلشان سوراخ دارد)
        bg = near
    else:
        border = np.unique(np.concatenate([lab[0, :], lab[-1, :], lab[:, 0], lab[:, -1]]))
        border = border[border > 0]
        bg = np.isin(lab, border)
    if fx_band:                     # افکت نورانی: در باند کنار پس‌زمینه، آلفا از «سفیدی» (white→alpha)
        band = ndi.binary_dilation(bg, iterations=fx_band) & ~bg
        wa = np.clip((255.0 - a.min(axis=2)) / 255.0 * 1.35, 0, 1)
        alpha = np.ones((h, w), np.float32)
        alpha[bg] = 0.0
        alpha[band] = np.maximum(wa[band], 0.0)
        out = a.copy()
        r = band & (alpha > 0.03)
        for c in range(3):
            ch = out[..., c]
            ch[r] = (ch[r] - 255.0 * (1 - alpha[r])) / alpha[r]
        alpha[band & (alpha < 0.05)] = 0.0
        rgba = np.dstack([np.clip(out, 0, 255), alpha * 255]).astype(np.uint8)
        return Image.fromarray(rgba, "RGBA")
    # ناحیهٔ لبه: پیکسل‌های غیرپس‌زمینه که تا ۲px با پس‌زمینه همسایه‌اند
    ring = ndi.binary_dilation(bg, iterations=2) & ~bg
    alpha = np.ones((h, w), np.float32)
    alpha[bg] = 0.0
    # نرم‌کردن لبه: هر چه به سفید نزدیک‌تر، شفاف‌تر
    soft = np.clip((dist - tol) / max(edge_soft, 1), 0, 1)
    alpha[ring] = soft[ring]
    # un-premultiply روی حلقه (حذف هالهٔ سفید)
    out = a.copy()
    r = ring & (alpha > 0.02)
    for c in range(3):
        ch = out[..., c]
        ch[r] = (ch[r] - 255.0 * (1 - alpha[r])) / alpha[r]
    out = np.clip(out, 0, 255)
    rgba = np.dstack([out, alpha * 255]).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    tol = 18
    if "--tol" in sys.argv:
        tol = float(sys.argv[sys.argv.index("--tol") + 1])
    key_white(Image.open(sys.argv[1]), tol).save(sys.argv[2])


if __name__ == "__main__":
    main()
