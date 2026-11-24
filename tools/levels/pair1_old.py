#!/usr/bin/env python3
"""Pair 1, old level «دشت صبح» (docs/33 §3, docs/36 §5) -> data/levels/pair1/old_01.json.

    python3 tools/levels/pair1_old.py

150 x 16 tiles. The ground is a CURVE (data "terrain": smooth rolling hills, a valley, a tall hill with a
long downhill, a rock mound in the middle of the broken-bridge gap); only ledges, the upper route and
the nest platform are tiles. Everything that stands on the ground is placed from the curve.
 A1-A2 gentle hills, A3 first wisp, A4 broken bridge (seed site: bridge_planted, jumpable without it),
 A5 tall hill and its long downhill, A6 upper route (coins), A7 shrine (shrine_lit), A8 the egg,
 A9-A10 the stair of ledges up to the nest (egg_saved), the exit.
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "levels", "pair1", "old_01.json")
W, H, T = 150, 16, 64

# control points of each ground segment: (tile x, surface row); gaps lie between the segments
SEGMENTS = [
    [(0, 12), (6, 12), (10, 11.3), (14, 10.8), (18, 11.6), (22, 12.4), (27, 12.0), (31, 12.8), (34, 13.0), (38, 12.2), (42, 12.0)],
    [(44.2, 12.3), (45.2, 11.6), (46.8, 11.6), (47.8, 12.3)],                       # the mound in the gap
    [(50, 12.0), (54, 11.4), (58, 10.2), (62, 9.0), (66, 8.8), (70, 9.6), (74, 11.0), (78, 12.2), (84, 12.6), (90, 12.0), (96, 11.5), (100, 12.0)],
    [(100, 12.0), (110, 12.0), (116, 12.0), (120, 12.0), (126, 12.3), (134, 12.5), (142, 12.0), (150, 12.0)],
]


def ground(x):
    """Surface row at tile x (linear between the control points)."""
    for seg in SEGMENTS:
        if seg[0][0] <= x <= seg[-1][0]:
            for (x0, y0), (x1, y1) in zip(seg, seg[1:]):
                if x0 <= x <= x1:
                    return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return None


grid = [["."] * W for _ in range(H)]
def put(x, row, c):
    if 0 <= x < W and 0 <= row < H:
        grid[int(row)][int(x)] = c
def on_ground(x, c, lift=1):
    g = ground(x + 0.5)
    put(x, int(g) - lift if g is not None else 11, c)

def coins_arc(x0, x1, peak=2.0, lift=2):
    n = x1 - x0
    for i in range(n + 1):
        t = i / max(n, 1)
        g = ground(x0 + i + 0.5)
        if g is None:                                     # over a gap: a smooth arc across it
            g = 12.0
        put(x0 + i, round(g - lift - 4 * peak * t * (1 - t) * 1.0), "c")

# A6: the upper route (a strip of tiles with coins)
for x in range(76, 92): put(x, 8, "#")
for x in range(78, 90, 2): put(x, 7, "c")
# A9/A10: stair of ledges up to the high nest platform
for x in range(121, 124): put(x, 10, "#")
for x in range(126, 129): put(x, 8, "#")
for x in range(131, 134): put(x, 6, "#")
for x in range(134, 143): put(x, 6, "#")
coins_arc(8, 14); coins_arc(36, 41, 2.5); coins_arc(41, 51, 3.0, 1)   # the long arc over the broken bridge
coins_arc(60, 66, 1.0, 2); coins_arc(94, 98); coins_arc(138, 144)
on_ground(2, "P")
for x in (35, 70, 105): on_ground(x, "C")
on_ground(24, "e"); on_ground(86, "e")
put(34, 8, "y"); put(61, 5, "y")
on_ground(146, "E")
rows = ["".join(r) for r in grid]

terrain = {"era": "old", "segments": [[[round(x * T, 1), round(y * T, 1)] for x, y in seg] for seg in SEGMENTS]}
level = {
    "id": 101, "format": 4, "world": "forest", "chapter": "pair1", "index": 1, "kind": "normal",
    "title": "دشت صبح", "era": "old", "scenery": "pair1", "hero": "grandfather", "weapon": "", "companion": "none",
    "framing": {"x": 0.30, "y": 0.62, "zoom": 0.86},
    "lens": False, "dual_physics": False, "weapon_level_required": 1, "bee_span": 140,
    "terrain": terrain,
    "objects": [
        {"type": "seed", "x": 46, "y": 12, "deed": "bridge_planted", "width": 8},
        {"type": "shrine", "x": 100, "y": round(ground(100.5), 2), "deed": "shrine_lit"},
        {"type": "egg", "x": 116, "y": round(ground(116.5), 2)},
        {"type": "nest", "x": 138, "y": 6, "deed": "egg_saved"},
    ],
    "map": rows,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(level, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", OUT, f"{W}x{H}", "segments", len(SEGMENTS))
