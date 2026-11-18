#!/usr/bin/env python3
"""Cuts the UI pieces that the kit (p9_ui_*.png) does not have out of the approved screen designs
(assets/art/p9_ui/screen_*.png, sheet_screen_*.png) and makes clean scene backgrounds.

    python3 tools/art/cut_ui.py            # every screen
    python3 tools/art/cut_ui.py hud shop   # only these

Pieces go to assets/art/p9_ui/cut/<screen>_<name>.png with a transparent background (GrabCut from
a rectangle, or an exact circle / rounded-rectangle mask). Backgrounds go to
assets/art/p9_ui/cut/<screen>_bg.png: the design with the cut regions painted over (OpenCV
inpaint) - the scene art without its interface. Coordinates are in the design's own pixels.
These are drafts derived from the approved designs (the manager's kit should replace them:
comms/ART_REQUESTS.md); positions on screen come from the same numbers (layout JSON)."""
import json, os, sys
import cv2
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UI = os.path.join(ROOT, "assets", "art", "p9_ui")
OUT = os.path.join(UI, "cut")
LAYOUT = os.path.join(ROOT, "data", "ui_layout.json")

# shape: "circle" (cx, cy, r) | "round" (x0, y0, x1, y1, radius) | "grab" (x0, y0, x1, y1)
# keep_bg: the piece is not painted out of the background (e.g. it never changes)
SCREENS = {}


def load_specs():
    path = os.path.join(os.path.dirname(__file__), "ui_cut_specs.json")
    return json.load(open(path, encoding="utf-8"))


def mask_for(img, shape):
    h, w = img.shape[:2]
    m = np.zeros((h, w), np.uint8)
    kind = shape[0]
    if kind == "circle":
        _, cx, cy, r = shape
        cv2.circle(m, (int(cx), int(cy)), int(r), 255, -1, cv2.LINE_AA)
    elif kind == "ellipse":
        _, cx, cy, rx, ry = shape
        cv2.ellipse(m, (int(cx), int(cy)), (int(rx), int(ry)), 0, 0, 360, 255, -1, cv2.LINE_AA)
    elif kind == "round":
        _, x0, y0, x1, y1, rad = shape
        rad = int(rad)
        cv2.rectangle(m, (x0 + rad, y0), (x1 - rad, y1), 255, -1)
        cv2.rectangle(m, (x0, y0 + rad), (x1, y1 - rad), 255, -1)
        for cx, cy in ((x0 + rad, y0 + rad), (x1 - rad, y0 + rad), (x0 + rad, y1 - rad), (x1 - rad, y1 - rad)):
            cv2.circle(m, (cx, cy), rad, 255, -1, cv2.LINE_AA)
    elif kind == "grab":
        _, x0, y0, x1, y1 = shape
        gm = np.zeros((h, w), np.uint8)
        bgd = np.zeros((1, 65), np.float64)
        fgd = np.zeros((1, 65), np.float64)
        cv2.grabCut(img, gm, (x0, y0, x1 - x0, y1 - y0), bgd, fgd, 6, cv2.GC_INIT_WITH_RECT)
        m = np.where((gm == cv2.GC_FGD) | (gm == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
        # keep the biggest blob, fill its holes, soften the edge
        n, lab, stats, _ = cv2.connectedComponentsWithStats(m)
        if n > 1:
            big = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
            m = np.where(lab == big, 255, 0).astype(np.uint8)
        flood = m.copy()
        ff = np.zeros((h + 2, w + 2), np.uint8)
        cv2.floodFill(flood, ff, (0, 0), 255)
        m = m | cv2.bitwise_not(flood)
        m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    m = cv2.GaussianBlur(m, (3, 3), 0)
    return m


def bbox(shape):
    kind = shape[0]
    if kind == "circle":
        _, cx, cy, r = shape
        return int(cx - r - 2), int(cy - r - 2), int(cx + r + 2), int(cy + r + 2)
    if kind == "ellipse":
        _, cx, cy, rx, ry = shape
        return int(cx - rx - 2), int(cy - ry - 2), int(cx + rx + 2), int(cy + ry + 2)
    return int(shape[1]) - 2, int(shape[2]) - 2, int(shape[3]) + 2, int(shape[4]) + 2


def cut_screen(name, spec, layout):
    src = os.path.join(UI, spec["file"])
    img = cv2.imread(src, cv2.IMREAD_COLOR)
    h, w = img.shape[:2]
    paint = np.zeros((h, w), np.uint8)
    pieces = {}
    for piece, p in spec["pieces"].items():
        shape = p["shape"]
        m = mask_for(img, shape)
        x0, y0, x1, y1 = bbox(shape)
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(w, x1), min(h, y1)
        rgba = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        rgba[:, :, 3] = m
        crop = rgba[y0:y1, x0:x1]
        out = os.path.join(OUT, "%s_%s.png" % (name, piece))
        if p.get("hole"):
            # a part that moves on its own (the joystick knob): painted out of this piece
            hm = np.zeros((h, w), np.uint8)
            _, hx, hy, hr = p["hole"]
            cv2.circle(hm, (int(hx), int(hy)), int(hr), 255, -1)
            filled = cv2.inpaint(img, hm, 15, cv2.INPAINT_TELEA)
            crop = crop.copy()
            crop[:, :, :3] = filled[y0:y1, x0:x1]
        cv2.imwrite(out, crop)
        if p.get("dim"):
            # an "off" state: same piece, greyed and darker (empty key, locked...)
            g = crop.copy()
            grey = cv2.cvtColor(cv2.cvtColor(g[:, :, :3], cv2.COLOR_BGR2GRAY), cv2.COLOR_GRAY2BGR)
            g[:, :, :3] = (grey * 0.55).astype(np.uint8)
            cv2.imwrite(out.replace(".png", "_off.png"), g)
        if p.get("empty"):
            # a bar without its fill: the coloured inside painted the dark navy of the bar's well
            e = crop.copy()
            ex0, ey0, ex1, ey1 = [int(v) for v in p["empty"]]
            well = np.array(p.get("well", [44, 24, 14]), np.uint8)
            region = e[ey0 - y0:ey1 - y0, ex0 - x0:ex1 - x0]
            region[:, :, :3] = well
            cv2.imwrite(out.replace(".png", "_empty.png"), e)
        if not p.get("keep_bg"):
            paint = np.maximum(paint, cv2.dilate(m, np.ones((9, 9), np.uint8)))
        pieces[piece] = {"rect": [x0 / w, y0 / h, (x1 - x0) / w, (y1 - y0) / h], "file": "res://assets/art/p9_ui/cut/%s_%s.png" % (name, piece)}
        if "content" in p:
            c = p["content"]
            pieces[piece]["content"] = [c[0] / w, c[1] / h, (c[2] - c[0]) / w, (c[3] - c[1]) / h]
    if spec.get("background", True):
        small = cv2.resize(img, (w // 2, h // 2))
        sp = cv2.resize(paint, (w // 2, h // 2))
        bg = cv2.inpaint(small, sp, 9, cv2.INPAINT_TELEA)
        bg = cv2.resize(bg, (w, h), interpolation=cv2.INTER_CUBIC)
        keep = (paint == 0)[:, :, None]
        bg = np.where(keep, img, bg)
        bg = cv2.resize(bg, (min(w, 2048), int(h * min(w, 2048) / w)), interpolation=cv2.INTER_AREA)
        cv2.imwrite(os.path.join(OUT, "%s_bg.png" % name), bg)
    extra = {k: [v[0] / w, v[1] / h, (v[2] - v[0]) / w, (v[3] - v[1]) / h] for k, v in spec.get("areas", {}).items()}
    layout[name] = {"size": [w, h], "pieces": pieces, "areas": extra, "design": "res://assets/art/p9_ui/" + spec["file"]}


def main():
    os.makedirs(OUT, exist_ok=True)
    specs = load_specs()
    layout = json.load(open(LAYOUT, encoding="utf-8")) if os.path.exists(LAYOUT) else {}
    only = sys.argv[1:]
    for name, spec in specs.items():
        if only and name not in only:
            continue
        cut_screen(name, spec, layout)
        print("cut", name, len(spec["pieces"]))
    with open(LAYOUT, "w", encoding="utf-8") as f:
        json.dump(layout, f, ensure_ascii=False, indent=1)
        f.write("\n")


if __name__ == "__main__":
    main()
