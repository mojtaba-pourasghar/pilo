#!/usr/bin/env python3
"""خط برش جفت ۱ (P1 دستور ساخت): برگه‌های assets/art/pair1_sheets → قطعه‌های PNG شفاف.

  python3 tools/art/build_pair1.py            # همهٔ برگه‌های pair1_cuts.json
  python3 tools/art/build_pair1.py p0_h01a_arsam_modelsheet   # یکی

برای هر برگه: ۱) کلید پس‌زمینه (مجنتا یا سفید؛ خودکار) ۲) اجزای متصل → قطعه‌ها
(مرتب سطر به سطر) ۳) خروجی assets/art/pair1/<group>/<sheet>/<sheet>_rRR_cCC.png
+ <sheet>.atlas.json (جعبهٔ هر قطعه در برگهٔ اصلی) + <sheet>_preview.png.
صحنه‌های کامل (بدون برش) کپی/تقسیم می‌شوند. افکت‌هایی که باید روی مجنتا بازسازی شوند رد می‌شوند.
"""
import json
import io
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from key_pink import key_pink  # noqa: E402
from key_white import key_white  # noqa: E402


def detect_bg(img):
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    k = max(4, min(a.shape[:2]) // 60)
    patches = [a[:k, :k], a[:k, -k:], a[-k:, :k], a[-k:, -k:]]
    c = np.median(np.concatenate([p.reshape(-1, 3) for p in patches]), axis=0)
    if c[0] > 215 and c[2] > 215 and c[1] > 215:
        return "white"
    if c[0] > 200 and c[2] > 200 and c[1] < 90:
        return "magenta"
    return "other"


def key(img, mode):
    if mode == "auto":
        mode = detect_bg(img)
    if mode == "white":
        return key_white(img), "white"
    if mode == "pink":
        return key_pink(img, tol=60, soft=40), "pink"
    if mode == "white_fx":
        return key_white(img, tol=10, fx_band=16), "white_fx"
    if mode == "white_global":
        return key_white(img, tol=26, global_=True), "white_global"
    if mode == "magenta":
        return key_pink(img), "magenta"
    raise SystemExit(f"پس‌زمینهٔ ناشناخته: {mode}")


def split_components(rgba, merge, min_area):
    alpha = np.asarray(rgba)[..., 3] > 24
    grown = ndi.binary_dilation(alpha, iterations=max(1, merge))
    lab, n = ndi.label(grown)
    boxes = []
    for i, sl in enumerate(ndi.find_objects(lab), start=1):
        if sl is None:
            continue
        comp = (lab[sl] == i) & alpha[sl]
        if comp.sum() < min_area:
            continue
        ys, xs = np.where(comp)
        y0, y1 = sl[0].start + ys.min(), sl[0].start + ys.max() + 1
        x0, x1 = sl[1].start + xs.min(), sl[1].start + xs.max() + 1
        boxes.append([int(x0), int(y0), int(x1), int(y1), int(comp.sum())])
    return boxes


def order_rows(boxes):
    if not boxes:
        return []
    boxes = sorted(boxes, key=lambda b: (b[1] + b[3]) / 2)
    med_h = float(np.median([b[3] - b[1] for b in boxes]))
    rows, cur = [], [boxes[0]]
    for b in boxes[1:]:
        cy = (b[1] + b[3]) / 2
        cur_cy = np.mean([(c[1] + c[3]) / 2 for c in cur])
        if abs(cy - cur_cy) <= max(40, 0.55 * med_h):
            cur.append(b)
        else:
            rows.append(cur)
            cur = [b]
    rows.append(cur)
    return [sorted(r, key=lambda b: b[0]) for r in rows]


def cut_sheet(cfg, src_dir, out_dir):
    sid = cfg["id"]
    src = os.path.join(ROOT, src_dir, sid + ".png")
    if not os.path.exists(src):
        print(f"MISSING {sid}")
        return None
    img = Image.open(src)
    rgba, used = key(img, cfg.get("key", "auto"))
    boxes = split_components(rgba, cfg.get("merge", 10), cfg.get("min_area", 500))
    rows = order_rows(boxes)
    odir = os.path.join(ROOT, out_dir, cfg["group"], sid)
    os.makedirs(odir, exist_ok=True)
    for f in os.listdir(odir):
        if f.endswith(".png") or f.endswith(".json"):
            os.remove(os.path.join(odir, f))
    atlas = {"sheet": sid, "key": used, "size": list(img.size), "parts": []}
    pad = 3
    for r, row in enumerate(rows):
        for c, (x0, y0, x1, y1, area) in enumerate(row):
            X0, Y0 = max(0, x0 - pad), max(0, y0 - pad)
            X1, Y1 = min(img.width, x1 + pad), min(img.height, y1 + pad)
            name = f"{sid}_r{r:02d}_c{c:02d}.png"
            rgba.crop((X0, Y0, X1, Y1)).save(os.path.join(odir, name))
            atlas["parts"].append({"file": name, "row": r, "col": c, "box": [X0, Y0, X1, Y1]})
    json.dump(atlas, open(os.path.join(odir, sid + ".atlas.json"), "w"), indent=1)
    prev = Image.new("RGBA", img.size, (60, 70, 100, 255))
    prev.alpha_composite(rgba)
    prev.convert("RGB").save(os.path.join(odir, sid + "_preview.png"))
    print(f"OK {sid}: {len(atlas['parts'])} قطعه در {len(rows)} سطر ({used})")
    return atlas


def copy_scene(cfg, src_dir, out_dir):
    sid = cfg["id"]
    src = os.path.join(ROOT, src_dir, sid + ".png")
    if not os.path.exists(src):
        print(f"MISSING {sid}")
        return
    img = Image.open(src).convert("RGB")
    odir = os.path.join(ROOT, out_dir, cfg["group"])
    os.makedirs(odir, exist_ok=True)
    n = cfg.get("split", 1)
    if n == 1:
        img.save(os.path.join(odir, sid + ".png"))
        print(f"OK {sid}: صحنه")
        return
    w = img.width // n
    for i in range(n):
        img.crop((i * w, 0, (i + 1) * w if i < n - 1 else img.width, img.height)).save(
            os.path.join(odir, f"{sid}_{i + 1}.png"))
    print(f"OK {sid}: {n} پنل")


def main():
    cfg = json.load(open(os.path.join(HERE, "pair1_cuts.json"), encoding="utf-8"))
    only = set(sys.argv[1:])
    for s in cfg["sheets"]:
        if not only or s["id"] in only:
            cut_sheet(s, cfg["src_dir"], cfg["out_dir"])
    for s in cfg["scenes"]:
        if not only or s["id"] in only:
            copy_scene(s, cfg["src_dir"], cfg["out_dir"])
    if not only:
        for sid in cfg.get("redo_on_magenta", []):
            print(f"SKIP {sid}: باید روی مجنتا بازسازی شود")


if __name__ == "__main__":
    main()
