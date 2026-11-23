#!/usr/bin/env python3
"""Pair 1, old level «دشت صبح» (docs/33 §3) -> data/levels/pair1/old_01.json.

    python3 tools/levels/pair1_old.py

Sections A1..A10 of the scenario, 150 x 16 tiles, ground along the bottom:
 A1 flat start, A2 small hills, A3 first wisp (y), A4 broken bridge gap (seed site: bridge_planted),
 A5 tall hill, A6 two routes (upper strip with coins), A7 shrine (shrine_lit), A8 the egg in its dirt
 nest, A9/A10 stairs of ledges up to the high nest (egg_saved), the exit.
No deed is needed to finish: the bridge gap is jumpable over a pillar, the shrine only gives the deed.
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "levels", "pair1", "old_01.json")
W, H = 150, 16

top = [12] * W                       # row of the ground surface; None = no ground (a gap)
def fill(a, b, row):
    for x in range(a, b + 1):
        top[x] = row
fill(16, 18, 11); fill(19, 22, 10); fill(23, 25, 11)            # A2 small hills
fill(30, 33, 13)                                                  # a dip
for x in range(43, 49): top[x] = None                             # A4 gap (6 tiles, a pillar in the middle)
fill(53, 55, 11); fill(56, 58, 10); fill(59, 65, 9); fill(66, 68, 10); fill(69, 71, 11)   # A5 tall hill

grid = [["."] * W for _ in range(H)]
for x in range(W):
    if top[x] is not None:
        for y in range(top[x], H):
            grid[y][x] = "#"
for y in range(12, H):
    grid[y][45] = "#"; grid[y][46] = "#"                          # a pillar in the gap: each jump is 2 tiles, so no deed is needed
def put(x, y, c): grid[y][x] = c
def coins_arc(x0, x1, base, peak):
    n = x1 - x0
    for i in range(n + 1):
        t = i / max(n, 1)
        put(x0 + i, int(round(base - 4 * peak * t * (1 - t))), "c")

# A6: the upper route: a strip of ground at row 8 with coins above it
for x in range(76, 92): put(x, 8, "#")
for x in range(78, 90, 2): put(x, 7, "c")
fill(0, 0, 12)
# A9/A10: a stair of ledges up to the high nest platform
for x in range(121, 124): put(x, 10, "#")
for x in range(126, 129): put(x, 8, "#")
for x in range(131, 134): put(x, 6, "#")
for x in range(134, 143): put(x, 5 + 1, "#")                     # the nest platform (row 6)
coins_arc(8, 14, 11, 2); coins_arc(36, 41, 11, 2); coins_arc(48, 52, 11, 2)
coins_arc(62, 66, 8, 1); coins_arc(94, 98, 11, 2); coins_arc(150 - 12, 150 - 6, 11, 2)
put(2, 11, "P")
for x in (35, 70, 105): put(x, 11, "C")
put(24, 11, "e"); put(86, 11, "e")
put(34, 8, "y"); put(61, 6, "y")
put(146, 11, "E")
rows = ["".join(r) for r in grid]

level = {
    "id": 101, "format": 4, "world": "forest", "chapter": "pair1", "index": 1, "kind": "normal",
    "title": "دشت صبح", "era": "old", "scenery": "pair1", "hero": "grandfather", "weapon": "", "companion": "none",
    "lens": False, "dual_physics": False, "weapon_level_required": 1, "bee_span": 140,
    "objects": [
        {"type": "seed", "x": 45, "y": 12, "deed": "bridge_planted", "width": 6},
        {"type": "shrine", "x": 100, "y": 12, "deed": "shrine_lit"},
        {"type": "egg", "x": 116, "y": 12},
        {"type": "nest", "x": 138, "y": 6, "deed": "egg_saved"},
    ],
    "map": rows,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(level, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", OUT, f"{W}x{H}")
