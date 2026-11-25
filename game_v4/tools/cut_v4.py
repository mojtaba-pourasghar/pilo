#!/usr/bin/env python3
"""v4 art pipeline: keys the white (or magenta) background of the delivered pictures and cuts the sheets into pieces.

  python3 game_v4/tools/cut_v4.py            # everything
  python3 game_v4/tools/cut_v4.py sheets     # only the part / kit / item sheets
  python3 game_v4/tools/cut_v4.py layers     # only the background layers

Sheets (art/chars, art/kits, art/items) -> art/cut/<sheet>/pNN.png + <sheet>.json {"pieces": [{"file", "box"}]}
(pieces in reading order: rows top to bottom, left to right) + a numbered contact sheet art/cut/<sheet>/_index.png.
Layers (art/bg) -> art/layers/<name>.png: the sky stays whole; the others lose the background connected to the edges.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

ROOT = os.path.join(os.path.dirname(__file__), "..", "art")
SHEETS = {"chars": ["grandfather_parts", "arsam_parts", "tikkit_parts", "enemies_forest_parts"],
          "kits": ["forest_old_kit", "forest_new_kit"], "items": ["items_forest"]}
SKIES = {"forest_old_sky", "forest_new_sky"}


def key(img: Image.Image, tol=28, soft=30, everywhere=False) -> Image.Image:
    """Removes the background that touches the picture's edges (white, near-white or magenta), with soft edges and
    the white fringe taken out of the semi-transparent border."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w = a.shape[:2]
    white = 255.0 - a.min(axis=2)
    magenta = np.sqrt((a[..., 0] - 255) ** 2 + (a[..., 1]) ** 2 + (a[..., 2] - 255) ** 2)
    corner = np.median(np.concatenate([a[:6, :6].reshape(-1, 3), a[-6:, -6:].reshape(-1, 3)]), axis=0)
    is_mag = corner[0] > 200 and corner[2] > 200 and corner[1] < 90
    dist = magenta if is_mag else white
    near = dist <= tol
    lab, _ = ndi.label(near)
    border = np.unique(np.concatenate([lab[0, :], lab[-1, :], lab[:, 0], lab[:, -1]]))
    bg = np.isin(lab, border[border > 0])
    if everywhere:
        # enclosed holes too (the gaps between trunks under a closed canopy): any large near-white area
        sizes = ndi.sum(near, lab, index=np.arange(lab.max() + 1))
        bg |= np.isin(lab, np.nonzero(sizes > 400)[0]) & near
    # soft edge: a band around the background takes alpha from its distance to the background colour
    band = ndi.binary_dilation(bg, iterations=3) & ~bg
    alpha = np.ones((h, w), np.float32)
    alpha[bg] = 0.0
    alpha[band] = np.clip((dist[band] - tol) / soft, 0.0, 1.0)
    rgb = a.copy()
    if not is_mag:
        # un-premultiply white out of the border pixels
        k = np.clip(alpha, 0.05, 1.0)[..., None]
        rgb = np.where(band[..., None], np.clip((a - 255.0 * (1.0 - k)) / k, 0, 255), a)
    # stray magenta specks inside (the picture tool sometimes leaves them)
    speck = ((magenta < 90) | ((a[..., 0] > 170) & (a[..., 2] > 170) & (a[..., 1] < 150))) & ~bg
    alpha[speck] = 0.0
    return Image.fromarray(np.dstack([rgb, alpha * 255.0]).clip(0, 255).astype(np.uint8), "RGBA")


def cut_sheet(folder: str, name: str) -> None:
    src = os.path.join(ROOT, folder, name + ".png")
    if not os.path.exists(src):
        print("MISSING", src)
        return
    rgba = key(Image.open(src))
    al = np.asarray(rgba)[..., 3] > 40
    # pieces = connected parts after a small closing (so a thin gap inside one piece does not split it)
    grown = ndi.binary_dilation(al, iterations=4)
    lab, n = ndi.label(grown)
    boxes = []
    for i, sl in enumerate(ndi.find_objects(lab)):
        if sl is None:
            continue
        ys, xs = sl
        area = int((al[sl] & (lab[sl] == i + 1)).sum())
        if area < 300:
            continue
        boxes.append([xs.start, ys.start, xs.stop, ys.stop])
    # reading order: group into rows by vertical centre
    boxes.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows, cur = [], []
    for b in boxes:
        cy = (b[1] + b[3]) / 2
        if cur and cy - np.mean([(c[1] + c[3]) / 2 for c in cur]) > max(30, 0.35 * np.mean([c[3] - c[1] for c in cur])):
            rows.append(cur)
            cur = []
        cur.append(b)
    if cur:
        rows.append(cur)
    out_dir = os.path.join(ROOT, "cut", name)
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        os.remove(os.path.join(out_dir, f))
    pieces = []
    for row in rows:
        for b in sorted(row, key=lambda b: b[0]):
            x0, y0, x1, y1 = max(0, b[0] - 2), max(0, b[1] - 2), min(rgba.width, b[2] + 2), min(rgba.height, b[3] + 2)
            fn = "p%02d.png" % len(pieces)
            rgba.crop((x0, y0, x1, y1)).save(os.path.join(out_dir, fn))
            pieces.append({"file": fn, "box": [x0, y0, x1, y1]})
    json.dump({"sheet": name, "size": [rgba.width, rgba.height], "pieces": pieces}, open(os.path.join(out_dir, name + ".json"), "w"), indent=1)
    # numbered index picture
    idx = Image.new("RGB", rgba.size, (70, 80, 90))
    idx.paste(rgba, (0, 0), rgba)
    d = ImageDraw.Draw(idx)
    for k, p in enumerate(pieces):
        b = p["box"]
        d.rectangle(b, outline=(255, 220, 0), width=2)
        d.rectangle([b[0], b[1], b[0] + 30, b[1] + 18], fill=(0, 0, 0))
        d.text((b[0] + 3, b[1] + 3), str(k), fill=(255, 255, 0))
    idx.save(os.path.join(out_dir, "_index.png"))
    print("OK %s: %d pieces in %d rows %s" % (name, len(pieces), len(rows), [len(r) for r in rows]))


def do_layers() -> None:
    out = os.path.join(ROOT, "layers")
    os.makedirs(out, exist_ok=True)
    for f in sorted(os.listdir(os.path.join(ROOT, "bg"))):
        if not f.endswith(".png"):
            continue
        name = f[:-4]
        img = Image.open(os.path.join(ROOT, "bg", f))
        res = img.convert("RGBA") if name in SKIES else key(img, everywhere=name.endswith(("_mid", "_far", "_near")))
        res.save(os.path.join(out, f))
        print("layer", name, res.size)


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("all", "sheets"):
        for folder, names in SHEETS.items():
            for nm in names:
                cut_sheet(folder, nm)
    if what in ("all", "layers"):
        do_layers()
