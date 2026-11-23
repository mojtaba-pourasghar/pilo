#!/usr/bin/env python3
"""Cuts the side-view sheets of docs/37 (assets/art/v3/*.png) into frames/pieces.

  python3 tools/art/build_v3.py [sheet ...]

Output: assets/art/v3/cut/<sheet>/<sheet>_rRR_fNN.png (transparent PNG, rows top->bottom, frames
left->right) + <sheet>.atlas.json with every frame's box in the sheet and the row's ground line
(`base`: the lowest point of the row = where the feet touch the ground).
"""
import json, os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import build_pair1 as b1  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SRC = os.path.join(ROOT, "assets", "art", "v3")
OUT = os.path.join(SRC, "cut")
# merge = how many px apart parts still belong to one frame; min_area = smallest piece kept
SHEETS = {
    "v3_arsam_run": (14, 800), "v3_arsam_air": (14, 500), "v3_arsam_actions": (10, 800),
    "v3_grandfather_run": (14, 800), "v3_grandfather_air": (14, 500), "v3_grandfather_actions": (10, 500),
    "v3_embri_move": (10, 500), "v3_embri_actions": (10, 400), "v3_tikkit_fly": (10, 300),
    "v3_terrain_old": (6, 1500), "v3_terrain_new": (6, 1500), "v3_props_motion": (8, 1500), "v3_props_tower": (8, 1500),
    "v3_bg_old_far": (8, 20000), "v3_bg_old_village": (8, 20000), "v3_bg_old_near": (8, 20000),
    "v3_bg_old_front": (8, 20000), "v3_bg_new_far": (8, 20000), "v3_bg_new_village": (8, 20000),
    "v3_bg_new_trees": (8, 20000), "v3_bg_new_near": (8, 20000), "v3_bg_new_front": (8, 20000),
}


# frames per row (counted on the delivered sheets); these sheets are cut by empty gaps, not by connected parts
GRID = {
    "v3_arsam_run": [8, 6, 6], "v3_arsam_air": [6, 8, 8], "v3_arsam_actions": [6, 7, 8],
    "v3_grandfather_run": [8, 6, 6], "v3_grandfather_air": [6, 5, 8], "v3_grandfather_actions": [6, 8, 8, 9],
    "v3_embri_move": [8, 8, 10], "v3_embri_actions": [8, 8, 7], "v3_tikkit_fly": [8, 8, 10],
}


def _runs(empty):
    """[(start, end)] of consecutive True values."""
    out, start = [], None
    for i, e in enumerate(empty):
        if e and start is None:
            start = i
        if not e and start is not None:
            out.append((start, i))
            start = None
    if start is not None:
        out.append((start, len(empty)))
    return out


def cut_grid(name, counts):
    path = os.path.join(SRC, name + ".png")
    if not os.path.exists(path):
        print("MISSING", name)
        return
    img = Image.open(path)
    rgba, used = b1.key(img, "auto")
    a = np.asarray(rgba)[..., 3] > 24
    rows_y = [(y0, y1) for (y0, y1) in _runs(~a.any(axis=1))]     # empty bands between rows
    # content row bands = complement of the empty runs
    bands, prev = [], 0
    for (e0, e1) in rows_y:
        if e0 - prev > 20:
            bands.append((prev, e0))
        prev = e1
    if a.shape[0] - prev > 20:
        bands.append((prev, a.shape[0]))
    if len(bands) != len(counts):
        print(f"!! {name}: found {len(bands)} rows, expected {len(counts)}")
    odir = os.path.join(OUT, name)
    os.makedirs(odir, exist_ok=True)
    for f in os.listdir(odir):
        os.remove(os.path.join(odir, f))
    atlas = {"sheet": name, "key": used, "size": list(img.size), "rows": []}
    for r, (y0, y1) in enumerate(bands):
        n = counts[r] if r < len(counts) else 1
        cols_empty = ~a[y0:y1].any(axis=0)
        gaps = sorted(_runs(cols_empty), key=lambda g: g[1] - g[0], reverse=True)
        inner = [g for g in gaps if g[0] > 0 and g[1] < a.shape[1]][: n - 1]
        cuts = sorted((g[0] + g[1]) // 2 for g in inner)
        frames_boxes = None
        masks = None
        if len(cuts) < n - 1:           # frames touch: give every connected part to the nearest frame centre
            from scipy import ndimage as ndi
            band = a[y0:y1]
            grown = ndi.binary_dilation(band, iterations=4)
            lab, count = ndi.label(grown)
            area = ndi.sum(band, lab, range(1, count + 1))
            ids = [i + 1 for i in range(count) if area[i] >= 60]
            xs_all = np.where(band.any(axis=0))[0]
            lo, hi = int(xs_all.min()), int(xs_all.max()) + 1
            big = sorted(ids, key=lambda i: -area[i - 1])[:n]
            if len(big) == n:
                centres = sorted(float(ndi.center_of_mass(band, lab, i)[1]) for i in big)
            else:                       # even the parts are joined: equal pitch
                centres = [lo + (hi - lo) * (k + 0.5) / n for k in range(n)]
                print(f"   {name} row {r}: equal cells ({len(big)} parts for {n} frames)")
            voronoi = len(big) != n
            groups = [[] for _ in range(n)]
            for i in ([] if voronoi else ids):
                cx = float(ndi.center_of_mass(band, lab, i)[1])
                groups[min(range(n), key=lambda k: abs(centres[k] - cx))].append(i)
            frames_boxes, masks = [], []
            xs_grid = np.arange(band.shape[1])
            for k, g in enumerate(groups):
                if voronoi:      # pixel columns nearest to this frame's centre
                    nearest = np.argmin(np.abs(xs_grid[:, None] - np.array(centres)[None, :]), axis=1)
                    m = band & (nearest == k)[None, :]
                else:
                    m = np.isin(lab, g) & band
                if not m.any():
                    continue
                ys, xs = np.where(m)
                frames_boxes.append([int(xs.min()), int(ys.min()) + y0, int(xs.max()) + 1, int(ys.max()) + 1 + y0])
                masks.append((m, y0))
            print(f"   {name} row {r}: masked by parts ({len(inner)} gaps for {n} frames)")
        edges = [0] + cuts + [a.shape[1]]
        frames, base = [], 0
        for c in range(len(frames_boxes) if frames_boxes else len(edges) - 1):
            if frames_boxes:
                fb = frames_boxes[c]
                box = [int(fb[0] - 2), int(fb[1] - 2), int(fb[2] + 2), int(fb[3] + 2)]
            else:
                x0, x1 = edges[c], edges[c + 1]
                sub = a[y0:y1, x0:x1]
                if not sub.any():
                    continue
                ys, xs = np.where(sub)
                box = [int(x0 + xs.min() - 2), int(y0 + ys.min() - 2), int(x0 + xs.max() + 3), int(y0 + ys.max() + 3)]
            box = [max(0, box[0]), max(0, box[1]), min(img.width, box[2]), min(img.height, box[3])]
            base = max(base, box[3])
            fn = f"{name}_r{r:02d}_f{len(frames):02d}.png"
            crop = rgba.crop(box)
            if masks:                    # keep only this frame's own pixels (neighbours may overlap the box)
                m, my0 = masks[c]
                mm = np.zeros((img.height, img.width), bool)
                mm[my0:my0 + m.shape[0], :m.shape[1]] = m
                arr = np.asarray(crop).copy()
                arr[..., 3] = np.where(mm[box[1]:box[3], box[0]:box[2]], arr[..., 3], 0)
                crop = Image.fromarray(arr, "RGBA")
            crop.save(os.path.join(odir, fn))
            frames.append({"file": fn, "box": box})
        atlas["rows"].append({"base": int(base), "frames": frames})
    json.dump(atlas, open(os.path.join(odir, name + ".atlas.json"), "w"), indent=1)
    print(f"OK {name}: rows {[len(r['frames']) for r in atlas['rows']]} (expected {counts})")


def cut(name, merge, min_area):
    if name in GRID:
        return cut_grid(name, GRID[name])
    path = os.path.join(SRC, name + ".png")
    if not os.path.exists(path):
        print("MISSING", name)
        return
    img = Image.open(path)
    rgba, used = b1.key(img, "auto")
    boxes = b1.split_components(rgba, merge, min_area)
    rows = b1.order_rows(boxes)
    odir = os.path.join(OUT, name)
    os.makedirs(odir, exist_ok=True)
    for f in os.listdir(odir):
        os.remove(os.path.join(odir, f))
    atlas = {"sheet": name, "key": used, "size": list(img.size), "rows": []}
    for r, row in enumerate(rows):
        base = max(bx[3] for bx in row)
        frames = []
        for c, (x0, y0, x1, y1, _a) in enumerate(row):
            pad = 2
            box = [max(0, x0 - pad), max(0, y0 - pad), min(img.width, x1 + pad), min(img.height, y1 + pad)]
            fn = f"{name}_r{r:02d}_f{c:02d}.png"
            rgba.crop(box).save(os.path.join(odir, fn))
            frames.append({"file": fn, "box": box})
        atlas["rows"].append({"base": base, "frames": frames})
    json.dump(atlas, open(os.path.join(odir, name + ".atlas.json"), "w"), indent=1)
    print(f"OK {name}: rows {[len(r['frames']) for r in atlas['rows']]} ({used})")


if __name__ == "__main__":
    names = sys.argv[1:] or list(SHEETS)
    for n in names:
        cut(n, *SHEETS[n])
