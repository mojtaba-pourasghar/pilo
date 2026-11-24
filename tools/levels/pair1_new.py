#!/usr/bin/env python3
"""Pair 1, NEW level "the plain after" (docs/33 section 5, docs/36 section 6, docs/40 section 2) -> data/levels/pair1/new_01.json.

    python3 tools/levels/pair1_new.py

163 x 22 tiles, SIX scenes; Arsam with the bow; the variant (full / partial / none) is chosen by the deeds of the old level
and changes objects through "when" / "needs_deed" / "no_deed" (never a dead end):
 N1 smoky meadow        hills, two Murklings, the bow
 N2 creek and ruins     a gap: the living bridge exists only with bridge_planted; otherwise two rope swings, stepping stones, the creek bed
 N3 the egg tree        shoot the rope: the nest falls and the egg hatches, Tikkit joins (deed egg_saved: the nest hangs close and clean)
 N4 inside the tower    dark teal hall: crossed spinning beams, a wall-jump shaft, an extra beam when there are no deeds
 N5 the shrine hall     a stone gate: open at once when shrine_lit, else three crystals to shoot
 N6 the guardian        Stumpguard in a flat arena; freeing it opens the exit
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "levels", "pair1", "new_01.json")
W, H, T = 163, 22, 64
B = 16

SEGMENTS = [
    # N1
    [(0, B), (6, B), (10, B - 1.0), (14, B - 1.6), (18, B - 0.6), (22, B + 0.2), (24, B + 0.2)],
    # N2
    [(24, B + 0.2), (27, B + 0.7), (30.2, B + 1.2)],
    [(30.2, B + 3.2), (39.8, B + 3.2)],
    [(39.8, B + 1.2), (43, B + 0.4), (48, B), (52, B)],
    # N3
    [(52, B), (56, B - 1.0), (60, B - 2.0), (64, B - 2.4), (68, B - 1.6), (72, B - 0.6), (76, B)],
    # N4: the tower floor (flat with one low step)
    [(76, B), (88, B), (90, B - 0.8), (98, B - 0.8), (100, B), (112, B)],
    # N5
    [(112, B), (120, B - 0.4), (130, B - 0.4), (136, B)],
    # N6
    [(136, B), (163, B)],
]


def ground(x):
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
    put(x, int(g) - lift if g is not None else B - 1, c)


def coins_arc(x0, x1, peak=2.0, lift=2):
    n = x1 - x0
    for i in range(n + 1):
        g = ground(x0 + i + 0.5)
        base = g if g is not None else B
        t = i / max(n, 1)
        put(x0 + i, round(base - lift - 4 * peak * t * (1 - t)), "c")


def strip(x0, x1, row):
    for x in range(x0, x1 + 1):
        put(x, row, "#")


# stepping stones in the creek, the vine ledge, tower platforms, the shaft
strip(33, 34, B + 2)
strip(36, 37, B + 2)
coins_arc(31, 38, 2.6, 4)
strip(79, 83, B - 4)                    # tower: a high ledge
strip(102, 108, B - 9)                  # shaft top
for y in range(B - 8, B + 1):
    put(101, y, "#")
    put(109, y, "#")                    # the shaft's walls
for x in range(103, 108):
    put(x, B - 10, "c")
for x in range(80, 83):
    put(x, B - 5, "c")
coins_arc(6, 13)
coins_arc(53, 60, 2.0, 2)
coins_arc(114, 122, 2.0, 2)
on_ground(2, "P")
for x in (24, 52, 76, 100, 136):
    on_ground(x, "C")
for x in (12, 20, 44, 66):
    on_ground(x, "e")
on_ground(162, "E")
rows = ["".join(r) for r in grid]

terrain = {"era": "new", "segments": [[[round(x * T, 1), round(y * T, 1)] for x, y in seg] for seg in SEGMENTS]}
g = lambda x: round(ground(x + 0.5), 2)
objects = [
    # N2: the bridge of the old level (only with the deed), else rope swings and stones
    {"type": "bridge", "x": 31, "y": g(31), "width": 8, "needs_deed": "bridge_planted"},
    {"type": "rope_swing", "x": 33, "y": 6, "length": 6, "start": 30, "no_deed": "bridge_planted"},
    {"type": "rope_swing", "x": 37, "y": 6, "length": 6, "start": -30, "no_deed": "bridge_planted"},
    {"type": "vine", "x": 44, "y": B - 6, "length": 4},
    {"type": "tar", "x": 46, "y": g(46), "width": 3, "when": ["none"]},
    # N3: the egg tree; rope target at shooting height, the nest hangs 4 tiles above
    {"type": "shot_target", "kind": "rope", "x": 62, "y": g(62), "rope": 4},
    {"type": "hatch_nest", "x": 62, "y": round(ground(62.5) - 4.0, 2), "drop": 4, "needs_deed": "egg_saved"},
    {"type": "hatch_nest", "x": 62, "y": round(ground(62.5) - 4.0, 2), "drop": 4, "cracked": True, "no_deed": "egg_saved"},
    {"type": "form_point", "x": 68, "y": g(68), "form": "wings"},
    {"type": "snapper", "x": 56, "y": g(56), "when": ["none", "partial"]},
    # N4: the tower
    {"type": "spin_beam", "x": 84, "y": B - 4.2, "arm": 2.3, "speed": 45, "phase": 0},
    {"type": "spin_beam", "x": 94, "y": B - 4.2, "arm": 2.3, "speed": 60, "phase": 45},
    {"type": "spin_beam", "x": 89, "y": B - 4.2, "arm": 2.0, "speed": 30, "phase": 20, "when": ["none"]},
    # high route over the tower: floating islands (docs/44)
    {"type": "island", "x": 79, "y": B - 7.0, "width": 3, "variant": 0, "bob": 8},
    {"type": "island", "x": 87.5, "y": B - 9.0, "width": 3, "variant": 1, "bob": 12, "phase": 1.5},
    {"type": "island", "x": 92, "y": B - 9.2, "width": 3.5, "variant": 2, "drift": 40},
    {"type": "island", "x": 99.5, "y": B - 7.4, "width": 3, "variant": 4, "bob": 10, "phase": 3.0},
    {"type": "falling_rock", "x": 98, "y": B - 9, "drop": 9.2, "reach": 200},
    {"type": "form_point", "x": 96, "y": g(96), "form": "bubble"},
    # N5: the shrine hall
    {"type": "gate", "x": 126, "y": g(126), "id": "shrine_gate", "height": 4, "need": 1, "start_open": True, "needs_deed": "shrine_lit"},
    {"type": "gate", "x": 126, "y": g(126), "id": "shrine_gate", "height": 4, "need": 3, "no_deed": "shrine_lit"},
    {"type": "shot_target", "kind": "crystal", "x": 117, "y": g(117), "opens": "shrine_gate", "no_deed": "shrine_lit"},
    {"type": "shot_target", "kind": "crystal", "x": 120, "y": g(120), "opens": "shrine_gate", "no_deed": "shrine_lit"},
    {"type": "shot_target", "kind": "crystal", "x": 123, "y": g(123), "opens": "shrine_gate", "no_deed": "shrine_lit"},
    {"type": "form_point", "x": 114, "y": g(114), "form": "sandbridge"},
]
level = {
    "id": 102, "format": 4, "world": "forest", "chapter": "pair1", "index": 2, "kind": "normal",
    "title": "دشت بعد", "era": "new", "scenery": "pair1", "hero": "arsam", "weapon": "time_bow", "companion": "none",
    "team": [],
    "lock_exit": True,
    "stumpguard": {"x": 150, "y": B},
    "framing": {"x": 0.30, "y": 0.62, "zoom": 0.86},
    "lens": False, "dual_physics": False, "weapon_level_required": 1, "bee_span": 140,
    "terrain": terrain, "surface": "grass",
    "ambient": {"weather": "none", "critters": ["bird", "butterfly", "snail", "dragonfly", "frog"], "critter_count": 14},
    "backdrops": [{"from": 24 * T, "art": "v3_scene_valley_new"}, {"from": 52 * T, "art": ""},
                  {"from": 76 * T, "art": "v3_scene_tower_inside"}, {"from": 112 * T, "art": ""},
                  {"from": 136 * T, "art": "v3_scene_antlerion_den_new"}],
    "scenes": [["N1", 0], ["N2", 24], ["N3", 52], ["N4", 76], ["N5", 112], ["N6", 136]],
    "swipe_start": True,
    "enemy_kinds": {"e": "imp", "y": "wisp"},
    "briefing": {
        "backdrop": "v3_scene_valley_new", "duration": 11.0, "zoom": [1.0, 1.1], "pan": [0.03, 0.0],
        "actors": [{"who": "arsam", "at": [0.24, 0.80], "scale": 2.4, "anim": "idle"}],
        "props": [{"sheet": "v3_cut_props", "row": 1, "n": 4, "fps": 6, "at": [0.74, 0.74], "scale": 0.8, "from": 5.2, "loop": True}],
        "events": [
            {"t": 0.5, "caption": "intro_new1_a", "dur": 2.4},
            {"t": 3.0, "actor": 0, "anim": "walk", "move": [0.50, 0.80], "dur": 2.4, "after": "idle"},
            {"t": 5.2, "prop": 0, "show": True, "restart": True, "caption": "intro_new1_b", "dur": 3.0},
            {"t": 5.6, "actor": 0, "anim": "surprised"},
            {"t": 8.0, "actor": 0, "anim": "idle", "caption": "intro_new1_c", "dur": 2.0},
            {"t": 9.2, "objective": True, "text": "intro_new1_goal"},
        ],
    },
    "objects": objects,
    "map": rows,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(level, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", OUT, "%dx%d" % (W, H), "objects", len(objects))
