#!/usr/bin/env python3
"""Pair 1, old level (docs/36 section 5, docs/38, docs/40 section 2) -> data/levels/pair1/old_01.json.

    python3 tools/levels/pair1_old.py

150 x 22 tiles, SIX different scenes one after the other; the ground is a curve (rolling up and down), the
mechanics change from scene to scene (docs/38 sections 3-4). Every obstacle has a plain route around it, so
no deed and no mechanic is ever required (never a dead end).
 S1  meadow hills     rolling hills, coin arcs, first Murkwisp
 S2  creek valley     8-tile creek: rope swings (high route), stepping stones (low), the creek bed (climb out);
                      the broken bridge = seed site (deed bridge_planted); a vine up to a ledge
 S3  ruins            stairs up, a crumbling bridge over a pit, falling rocks, the shrine (deed shrine_lit)
 S4  big hill         a long uphill, a crest, a long downhill and a launch ramp over a gap
 S5  steam valley     a dip with steam vents (lift to a high strip of coins), a wall-jump shaft
 S6  tree stairs      the egg on the ground, stairs of ledges up to the high nest (deed egg_saved), the exit
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "levels", "pair1", "old_01.json")
W, H, T = 150, 22, 64
B = 16            # base ground row

# control points (tile x, surface row) per ground segment; the gaps between segments are chasms
SEGMENTS = [
    # S1
    [(0, B), (5, B), (9, B - 0.8), (13, B - 1.4), (17, B - 0.6), (21, B + 0.2), (24, B + 0.1)],
    # S2: down to the creek, the creek bed, up the far bank
    [(24, B + 0.1), (27, B + 0.6), (30.2, B + 1.2)],
    [(30.2, B + 3.2), (39.8, B + 3.2)],                           # the creek bed (a safe floor, 2-tile climb out)
    [(39.8, B + 1.2), (42, B + 0.5), (46, B), (50, B)],
    # S3: ground stairs up to the ruins, a pit, a crumble bridge, the far side
    [(50, B), (54, B - 1.0), (58, B - 2.6), (62, B - 3.6)],
    [(62, B - 0.8), (68, B - 0.8)],                               # the pit under the crumble bridge (3 tiles deep, climbable by the ledges)
    [(68, B - 3.6), (72, B - 3.0), (76, B - 1.6)],
    # S4: the big hill and its long downhill, a ramp, a gap
    [(76, B - 1.6), (80, B - 3.0), (86, B - 6.6), (90, B - 7.4), (94, B - 5.4), (98, B - 2.0), (102, B + 0.6), (104, B + 0.9)],
    [(104, B + 3.2), (110, B + 3.2)],                             # floor of the ramp gap (2-tile climb out)
    [(110, B + 0.9), (113, B + 1.0)],
    # S5: the steam valley
    [(113, B + 1.0), (118, B + 2.2), (122, B + 2.2), (125, B + 1.0), (128, B + 0.4)],
    # S6: the tree stairs
    [(128, B + 0.4), (134, B), (142, B), (150, B)],
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


# --- S2: stepping stones and a ledge reached by the vine ---
strip(33, 34, B + 2)
strip(36, 37, B + 2)                                               # stepping stones above the creek bed
strip(43, 48, B - 4)                                               # the vine's ledge (coins on it)
for x in range(44, 48):
    put(x, B - 5, "c")
coins_arc(31, 38, 2.6, 4)                                          # an arc over the creek
# --- S3: a stepping ledge in the pit (a second jump out) and the stairs' upper ledge ---
strip(64, 65, B - 2)

strip(56, 60, B - 6)
for x in range(57, 60):
    put(x, B - 7, "c")
# --- S4: a high route over the crest ---
strip(84, 88, B - 11)
for x in range(85, 88):
    put(x, B - 12, "c")
coins_arc(100, 108, 3.0, 2)                                        # over the ramp gap
# --- S5: a high strip of coins that the steam vents lift you to, and the wall-jump shaft ---
strip(115, 122, B - 4)
for x in range(116, 122):
    put(x, B - 5, "c")
for y in range(B - 8, B + 1):
    put(125, y, "#")
    put(129, y, "#")                                               # shaft walls (wall-jump up)
strip(125, 133, B - 9)
for x in range(126, 133):
    put(x, B - 10, "c")
# --- S6: stairs of ledges up to the nest platform ---
strip(136, 138, B - 2)
strip(140, 142, B - 4)
strip(144, 147, B - 6)

coins_arc(6, 13)
coins_arc(15, 20, 2.0, 2)
coins_arc(70, 76, 2.0, 2)
coins_arc(138, 143, 2.2, 2)
on_ground(2, "P")
for x in (24, 49, 75, 103, 127):
    on_ground(x, "C")
for x in (14, 41, 52, 79, 93, 119, 134):
    on_ground(x, "e")
put(26, B - 5, "y")
put(66, B - 7, "y")
put(95, B - 12, "y")
on_ground(149, "E")
rows = ["".join(r) for r in grid]

terrain = {"era": "old", "segments": [[[round(x * T, 1), round(y * T, 1)] for x, y in seg] for seg in SEGMENTS]}
objects = [
    # S2 creek
    {"type": "rope_swing", "x": 33, "y": 6, "length": 6, "start": 30},
    {"type": "rope_swing", "x": 37, "y": 6, "length": 6, "start": -30},
    {"type": "seed", "x": 31, "y": round(ground(31.5), 2), "deed": "bridge_planted", "width": 8},
    {"type": "vine", "x": 44, "y": B - 7, "length": 4},
    # S1/S2 beside plain routes: a tar puddle (walk around over the stones), a snapping plant under the vine ledge
    {"type": "tar", "x": 17, "y": round(ground(17.5), 2), "width": 3},
    {"type": "snapper", "x": 41, "y": round(ground(41.5), 2)},
    # S3 ruins
    {"type": "crumble", "x": 65, "y": B - 3.6, "count": 6},
    {"type": "falling_rock", "x": 55, "y": B - 9, "drop": 9.5, "reach": 220},
    {"type": "falling_rock", "x": 70, "y": B - 10, "drop": 10.0, "reach": 200},
    {"type": "shrine", "x": 74, "y": round(ground(74.5), 2), "deed": "shrine_lit"},
    {"type": "spike_pit", "x": 62, "y": B - 0.8, "width": 2},
    {"type": "net", "x": 71, "y": round(ground(71.5), 2), "width": 2, "height": 3},
    # S4 hill
    {"type": "ramp", "x": 103, "y": round(ground(103.5), 2), "power": 1.2},
    {"type": "boulder_chase", "x": 88, "y": round(ground(88.5), 2), "length": 18},
    # S5 steam valley
    {"type": "steam_vent", "x": 117, "y": round(ground(117.5), 2), "period": 2.0, "height": 4},
    {"type": "steam_vent", "x": 121, "y": round(ground(121.5), 2), "period": 2.4, "height": 4},
    # S6 stairs
    {"type": "egg", "x": 130, "y": round(ground(130.5), 2)},
    {"type": "nest", "x": 146, "y": B - 6, "deed": "egg_saved"},
]
level = {
    "id": 101, "format": 4, "world": "forest", "chapter": "pair1", "index": 1, "kind": "normal",
    "title": "دشت صبح", "era": "old", "scenery": "pair1", "hero": "grandfather", "weapon": "", "companion": "none",
    "framing": {"x": 0.30, "y": 0.62, "zoom": 0.86},
    "lens": False, "dual_physics": False, "weapon_level_required": 1, "bee_span": 140,
    "terrain": terrain, "surface": "grass",
    "ambient": {"weather": "none", "critters": ["squirrel", "butterfly", "snail", "bird", "ladybug", "dragonfly", "frog"],
                "critter_count": 22},
    "backdrops": [{"from": 24 * T, "art": "v3_scene_valley_old"}, {"from": 50 * T, "art": "v3_scene_ruins_old"},
                  {"from": 76 * T, "art": ""}, {"from": 113 * T, "art": "v3_scene_roots_old"}, {"from": 128 * T, "art": ""}],
    "scenes": [["S1", 0], ["S2", 24], ["S3", 50], ["S4", 76], ["S5", 113], ["S6", 128]],
    "swipe_start": True,
    "enemy_kinds": {"e": "imp", "y": "wisp"},
    "briefing": {
        "backdrop": "v3_scene_valley_old", "duration": 11.5, "zoom": [1.0, 1.12], "pan": [-0.03, 0.0],
        "actors": [{"who": "grandfather", "at": [0.30, 0.80], "scale": 2.4, "anim": "sleep"}],
        "props": [{"sheet": "v3_cut_props", "row": 0, "n": 6, "fps": 5, "at": [0.72, 0.80], "scale": 1.0, "start_shown": True, "loop": False, "from": 0.4}],
        "events": [
            {"t": 0.5, "caption": "intro_old1_a", "dur": 2.4},
            {"t": 3.0, "actor": 0, "anim": "wake"},
            {"t": 4.4, "actor": 0, "anim": "idle", "caption": "intro_old1_b", "dur": 3.0},
            {"t": 7.6, "actor": 0, "anim": "walk", "move": [0.46, 0.80], "dur": 2.0, "after": "idle"},
            {"t": 8.0, "caption": "intro_old1_c", "dur": 2.0},
            {"t": 9.4, "objective": True, "text": "intro_old1_goal"},
        ],
    },
    "objects": objects,
    "map": rows,
}
os.makedirs(os.path.dirname(OUT), exist_ok=True)
json.dump(level, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", OUT, "%dx%d" % (W, H), "segments", len(SEGMENTS), "objects", len(objects))
