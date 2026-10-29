#!/usr/bin/env python3
"""Builds levels 2-72 (nine worlds x 8) from hand-designed segments.

    python3 tools/levels/compose.py            # every level
    python3 tools/levels/compose.py 9 16       # only these ids

Every segment is a small, deliberately designed piece of level (an upper, a lower and often
an underground route, secrets, a puzzle or a hazard to time). A level is a start, a run of
segments chosen for its world and difficulty, checkpoints, a "key" segment (the time key is
always somewhere off the obvious path) and the time gate. The secret level of a world is a
treasure run, the eighth level is the boss arena. Level 1 is hand-made (forest_01.py).
Every map is checked by tests/validate_levels.py.
"""
import json, os, random, sys

H, G = 22, 16          # rows; top row of the ground
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")

WORLDS = ["forest", "coral_beach", "golden_desert", "snow_mountain", "sky_islands",
          "crystal_caves", "clock_factory", "shadow_castle", "inverted_land"]
# world-specific segments (on top of the shared ones) and what is special about the world
SPECIAL = {
    "forest": ["tree_route", "rafts", "glide_gap"],
    "coral_beach": ["swim_pool", "swim_pool", "rafts", "tide_steps"],
    "golden_desert": ["quicksand", "quicksand", "cannon_alley", "glide_gap"],
    "snow_mountain": ["ice_slide", "ice_slide", "crusher_corridor", "glide_gap"],
    "sky_islands": ["wind_bridge", "wind_bridge", "storm", "glide_gap"],
    "crystal_caves": ["crusher_corridor", "moving", "cracked_cave", "lens_river"],
    "clock_factory": ["conveyor", "conveyor", "crusher_corridor", "moving"],
    "shadow_castle": ["vanish", "vanish", "storm", "cannon_alley", "lens_river"],
    "inverted_land": ["vanish", "wind_bridge", "conveyor", "ice_slide", "swim_pool", "quicksand"],
}
SHARED = ["blocks", "pit", "stairs", "wheel", "cannon_alley", "thorn_jumps", "secret_pipe",
          "cracked_cave", "lens_river", "moving", "crusher_corridor"]
DARK = {"crystal_caves", "shadow_castle"}

# what each segment teaches the first time a world shows it (sign texts)
SIGNS = {
    "swim_pool": "آب عمیق! با دکمهٔ پرش شنا کن و رو به بالا برو.",
    "quicksand": "شن روان! تند بپر، وگرنه فرو می‌روی.",
    "ice_slide": "یخ لیز است! زودتر ترمز کن.",
    "wind_bridge": "باد تو را می‌برد؛ ستون باد رو به بالا هلت می‌دهد.",
    "storm": "ابر رعدی! وقتی برق زد صبر کن، بعد بدو.",
    "conveyor": "تسمه‌ها تو را می‌برند؛ خلاف جهتشان بدو!",
    "vanish": "سکوهای سایه پیدا و ناپیدا می‌شوند. صبر کن و به‌موقع بپر!",
    "glide_gap": "دره خیلی پهن است! بپر و پرش را نگه دار تا پیلو تو را ببرد.",
    "secret_pipe": "روی لولهٔ درخشان ↓ را بزن.",
    "cracked_cave": "دیوار ترک‌دار با دَش یا پیلو می‌شکند.",
    "lens_river": "پل فقط در گذشته هست. عدسی زمان را بزن!",
    "key": "کلید زمان جایی پنهان است. پیلو بو می‌کشد؛ دنبالش برو!",
}


class Level:
    def __init__(self, width, rng):
        self.w = width
        self.g = [["."] * width for _ in range(H)]
        for y in range(G, H):
            for x in range(width):
                self.g[y][x] = "#"
        self.rng = rng
        self.warps = []
        self.stars = []          # candidate star spots (harder places)
        self.signs = []
        self.taught = set()

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < H:
            self.g[y][x] = c

    def row(self, x0, x1, y, c):
        for x in range(x0, x1 + 1):
            self.put(x, y, c)

    def rect(self, x0, x1, y0, y1, c):
        for y in range(y0, y1 + 1):
            self.row(x0, x1, y, c)

    def text(self, x, y, s):
        for i, c in enumerate(s):
            if c != " ":
                self.put(x + i, y, c)

    def sign(self, x, key):
        if key in SIGNS and key not in self.taught:
            self.taught.add(key)
            self.put(x, G - 1, "i")
            self.signs.append((x, SIGNS[key]))

    def pit(self, x0, x1):
        self.rect(x0, x1, G, H - 1, ".")

    def warp(self, a, b):
        self.warps.append({"from": list(a), "to": list(b)})


# --- shared segments: each returns its width -------------------------------------------

def seg_start(L, c, d, w):
    L.put(c + 2, G - 1, "P")
    L.text(c + 7, G - 3, "ccc")
    return 11


def seg_checkpoint(L, c, d, w):
    L.put(c + 2, G - 1, "C")
    return 5


def seg_blocks(L, c, d, w):
    L.text(c + 3, G - 3, "Q.bUb" if d < 0.5 else "b$bQb")
    L.text(c + 4, G - 6, "ccc")
    L.put(c + 11, G - 1, "e")
    if d > 0.35:
        L.put(c + 9, G - 6, "y")
    L.stars.append((c + 6, G - 7))
    return 14


def seg_pit(L, c, d, w):
    gap = 3 if d < 0.45 else 4
    L.pit(c + 3, c + 2 + gap)
    L.text(c + 3, G - 3, "c" * gap)
    if d > 0.3:
        L.put(c + 3 + gap // 2, G - 3, "y")
    return gap + 7


def seg_stairs(L, c, d, w):
    for i, h in enumerate([1, 2, 2, 3, 3, 3, 3]):
        L.rect(c + 3 + i, c + 3 + i, G - h, G - 1, "#")
    L.text(c + 7, G - 5, "ccc")
    L.put(c + 8, G - 4, "e")
    L.stars.append((c + 9, G - 7))
    L.pit(c + 10, c + 11 + (1 if d > 0.5 else 0))
    L.put(c + 14, G - 1, "e" if d < 0.6 else "h")
    return 17


def seg_wheel(L, c, d, w):
    L.put(c + 6, G - 3, "F")
    L.put(c + 2, G - 1, "e")
    L.put(c + 10, G - 1, "e")
    L.text(c + 5, G - 6, "c.c")
    return 13


def seg_cannon_alley(L, c, d, w):
    L.put(c + 3, G - 1, "N")
    L.text(c + 6, G - 3, "b.Q.b")
    L.put(c + 8, G - 1, "e")
    L.put(c + 13, G - 1, "N")
    L.text(c + 6, G - 6, "c.c.c")
    L.stars.append((c + 8, G - 7))
    return 16


def seg_thorn_jumps(L, c, d, w):
    L.row(c + 2, c + 3, G - 1, "A")
    L.row(c + 6, c + 8 if d > 0.4 else c + 7, G - 1, "A")
    L.row(c + 11, c + 12, G - 1, "A")
    L.text(c + 1, G - 4, "c.c.c.c.c.c")
    if d > 0.3:
        L.put(c + 7, G - 5, "y")
    return 15


def seg_secret_pipe(L, c, d, w):
    L.sign(c + 1, "secret_pipe")
    L.put(c + 3, G - 2, "p")
    L.rect(c + 1, c + 13, G + 1, H - 2, ".")
    L.text(c + 2, G + 2, "cccccc")
    L.text(c + 2, G + 3, "cccccc")
    L.put(c + 9, H - 2, "d")
    L.put(c + 7, G + 1, "J")
    L.put(c + 11, H - 3, "p")
    L.put(c + 11, G - 2, "p")
    L.warp((c + 3, G - 2), (c + 11, H - 3))
    L.warp((c + 11, H - 3), (c + 11, G - 2))
    L.warp((c + 11, G - 2), (c + 11, H - 3))
    L.put(c + 7, G - 1, "e")
    return 15


def seg_cracked_cave(L, c, d, w):
    L.sign(c + 1, "cracked_cave")
    L.rect(c + 3, c + 3, G - 3, G - 1, "W")
    L.row(c + 3, c + 10, G - 4, "#")
    L.rect(c + 12, c + 13, G - 2, G - 1, "#")      # a step up onto the cave roof, past its end
    L.text(c + 4, G - 1, "c.d.c")
    L.put(c + 9, G - 1, "Y")
    L.text(c + 4, G - 6, "ccc")
    L.stars.append((c + 7, G - 7))
    return 15


def seg_lens_river(L, c, d, w):
    L.sign(c + 1, "lens_river")
    L.put(c + 2, G - 2, "?")
    L.row(c + 3, c + 10, G, "B")
    L.row(c + 3, c + 10, G + 1, "~")
    L.text(c + 4, G - 3, "cccccc")
    L.stars.append((c + 7, G - 4))
    if d > 0.5:
        L.row(c + 13, c + 13, G - 2, "r")      # a rock that is only there in the past
        L.row(c + 13, c + 13, G - 1, "r")
    return 15


def seg_moving(L, c, d, w):
    L.pit(c + 2, c + 15)
    L.put(c + 2, G - 2, "m")
    L.put(c + 9, G - 3, "m")
    L.text(c + 5, G - 6, "cc.cc")
    L.stars.append((c + 12, G - 6))
    return 18


def seg_crusher_corridor(L, c, d, w):
    L.rect(c + 1, c + 1, G - 2, G - 1, "#")
    L.row(c + 3, c + 14, G - 5, "#")
    L.put(c + 6, G - 4, "T")
    L.put(c + 11, G - 4, "T")
    L.text(c + 4, G - 1, "c....c....c")
    L.text(c + 4, G - 6, "c.c.c.c.c")
    L.put(c + 9, G - 7, "y")
    L.stars.append((c + 13, G - 7))
    return 17


# --- world segments ----------------------------------------------------------------

def seg_tree_route(L, c, d, w):
    L.put(c + 2, G - 1, "M")
    L.row(c + 4, c + 9, G - 6, "o")
    L.row(c + 12, c + 16, G - 7, "o")
    L.row(c + 19, c + 23, G - 6, "o")
    L.text(c + 5, G - 7, "cccc")
    L.put(c + 14, G - 8, "d")
    L.row(c + 6, c + 7, G - 1, "A")
    L.put(c + 10, G - 1, "h")
    L.put(c + 14, G - 5, "T")
    L.row(c + 18, c + 19, G - 1, "A")
    L.stars.append((c + 21, G - 9))
    return 25


def seg_rafts(L, c, d, w):
    L.pit(c + 2, c + 15)
    L.put(c + 3, G - 2, "t")
    L.put(c + 7, G - 3, "t")
    L.put(c + 11, G - 2, "t")
    L.put(c + 7, G - 6, "n")
    L.row(c + 0, c + 3, G - 5, "o")
    L.row(c + 8, c + 11, G - 6, "o")
    L.row(c + 14, c + 17, G - 5, "o")
    L.text(c + 8, G - 7, "cccc")
    L.put(c + 13, G - 4, "y")
    L.stars.append((c + 15, G - 8))
    return 20


def seg_glide_gap(L, c, d, w):
    L.sign(c + 0, "glide_gap")
    L.put(c + 2, G - 1, "#")
    L.rect(c + 3, c + 3, G - 2, G - 1, "#")
    L.rect(c + 4, c + 5, G - 4, G - 1, "#")
    L.pit(c + 6, c + 15)
    for i in range(8):
        L.put(c + 7 + i, G - 5 + i // 3, "c")
    L.put(c + 11, G - 7, "d")
    L.stars.append((c + 11, G - 7))
    return 20


def seg_swim_pool(L, c, d, w):
    L.sign(c + 1, "swim_pool")
    L.rect(c + 3, c + 17, G, H - 2, "s")
    L.text(c + 5, G + 1, "c.c.c.c")
    L.put(c + 9, H - 2, "d")
    L.put(c + 12, G + 2, "y")
    L.row(c + 14, c + 15, H - 2, "A")
    L.stars.append((c + 16, G + 3))
    return 20


def seg_tide_steps(L, c, d, w):
    L.pit(c + 2, c + 15)
    L.rect(c + 2, c + 15, H - 3, H - 2, "a")
    for i, x in enumerate([c + 3, c + 7, c + 11]):
        L.rect(x, x + 1, G - 1 - (i % 2), G - 1 - (i % 2), "#")
        L.text(x, G - 3 - (i % 2), "cc")
    L.put(c + 9, G - 4, "y")
    return 18


def seg_quicksand(L, c, d, w):
    L.sign(c + 1, "quicksand")
    L.row(c + 3, c + 11, G, "q")
    L.text(c + 4, G - 3, "c.c.c.c")
    L.put(c + 7, G - 5, "y")
    L.put(c + 14, G - 1, "e")
    return 16


def seg_ice_slide(L, c, d, w):
    L.sign(c + 0, "ice_slide")
    L.row(c + 1, c + 18, G, "I")
    L.put(c + 6, G - 1, "e")
    L.text(c + 8, G - 3, "ccc")
    L.pit(c + 13, c + 15)
    L.row(c + 16, c + 18, G, "I")
    L.stars.append((c + 14, G - 4))
    return 20


def seg_wind_bridge(L, c, d, w):
    L.sign(c + 0, "wind_bridge")
    L.pit(c + 2, c + 15)
    L.rect(c + 4, c + 4, G - 5, H - 1, "^")
    L.row(c + 6, c + 12, G - 6, ">")
    L.row(c + 7, c + 9, G - 3, "o")
    L.text(c + 6, G - 8, "ccccccc")
    L.stars.append((c + 10, G - 8))
    return 18


def seg_storm(L, c, d, w):
    L.sign(c + 0, "storm")
    L.put(c + 4, G - 8, "Z")
    L.put(c + 10, G - 8, "Z")
    L.text(c + 3, G - 2, "c.c.c.c.c")
    L.put(c + 7, G - 1, "e")
    return 14


def seg_conveyor(L, c, d, w):
    L.sign(c + 0, "conveyor")
    L.row(c + 2, c + 9, G, "=")
    L.row(c + 10, c + 16, G, "_")
    L.put(c + 6, G - 4, "T")
    L.put(c + 13, G - 4, "T")
    L.text(c + 3, G - 3, "c.c.c.c.c.c.c")
    L.stars.append((c + 9, G - 4))
    return 18


def seg_vanish(L, c, d, w):
    L.sign(c + 0, "vanish")
    L.pit(c + 2, c + 15)
    L.row(c + 3, c + 4, G - 2, "v")
    L.row(c + 7, c + 8, G - 3, "v")
    L.row(c + 11, c + 12, G - 2, "v")
    L.text(c + 6, G - 6, "c.cc.c")
    L.stars.append((c + 8, G - 6))
    return 18


# --- the time key and the end ----------------------------------------------------

def seg_key_underground(L, c, d, w):
    """The key lies in a fox den down a pipe; the upper road looks easier but has no key."""
    L.sign(c + 0, "key")
    L.put(c + 2, G - 2, "p")
    L.rect(c + 1, c + 33, G + 1, H - 2, ".")
    L.put(c + 2, H - 3, "p")
    L.warp((c + 2, G - 2), (c + 2, H - 3))
    L.warp((c + 2, H - 3), (c + 2, G - 2))
    L.text(c + 7, H - 2, "cc.cc")
    L.put(c + 10, H - 2, "e")
    L.put(c + 17, H - 2, "X")
    L.text(c + 20, G + 2, "Q.b$b")
    L.put(c + 24, H - 2, "e" if d < 0.6 else "h")
    L.put(c + 28, H - 2, "d")
    L.put(c + 31, H - 3, "p")
    L.put(c + 29, G - 2, "p")
    L.warp((c + 31, H - 3), (c + 29, G - 2))
    L.warp((c + 29, G - 2), (c + 31, H - 3))
    # the upper road: coins, a diamond and creatures, but no key
    L.row(c + 5, c + 10, G - 4, "o")
    L.text(c + 5, G - 5, "cccccc")
    L.row(c + 13, c + 18, G - 6, "o")
    L.put(c + 15, G - 7, "d")
    L.put(c + 21, G - 1, "e")
    L.put(c + 25, G - 1, "h")
    L.stars.append((c + 16, G - 9))
    return 35


def seg_key_high(L, c, d, w):
    """The key waits at the top of a tower of blocks and planks."""
    L.sign(c + 0, "key")
    L.put(c + 3, G - 1, "M")
    L.row(c + 5, c + 8, G - 6, "o")
    L.row(c + 10, c + 13, G - 9, "o")
    L.row(c + 5, c + 8, G - 12, "o")
    L.put(c + 6, G - 13, "k")
    L.text(c + 10, G - 10, "ccc")
    L.put(c + 11, G - 1, "e")
    L.stars.append((c + 12, G - 13))
    return 16


def seg_gate(L, c, d, w):
    L.put(c + 2, G - 1, "C")
    L.text(c + 5, G - 4, "c.c.c")
    L.put(c + 12, G - 1, "E")
    return 16


def seg_boss_arena(L, c, d, w):
    L.put(c + 1, G - 1, "C")
    L.row(c + 8, c + 11, G - 3, "o")
    L.row(c + 20, c + 23, G - 3, "o")
    L.put(c + 25, G - 1, "&")
    L.stars.append((c + 9, G - 6))
    L.stars.append((c + 22, G - 6))
    L.rect(c + 30, c + 30, G - 7, G - 1, "|")
    L.put(c + 33, G - 1, "E")
    return 36


SEGMENTS = {k[4:]: v for k, v in globals().items() if k.startswith("seg_")}


# --- story lines ---------------------------------------------------------------------

STORY = {
    "forest": ("خرس پیر جنگل", "سایه‌ها جنگل را گرفته‌اند. باید جلوتر برویم!"),
    "coral_beach": ("اختاپوس بزرگ", "بوی دریا! کیان هم اینجاست؛ می‌خواهد زودتر از ما به قلب زمان برسد."),
    "golden_desert": ("کرم شنی", "روی دیوار هرم، نقش یک ساعت وارونه است... یعنی چه؟"),
    "snow_mountain": ("غول یخی", "غبارک! آمده‌ای کمک کنی؟ بیا با هم برویم."),
    "sky_islands": ("عقاب طوفان", "غبارک می‌گوید راه برج طوفان از ابرهاست."),
    "crystal_caves": ("عنکبوت بلورین", "کیان فهمید نقاب‌دار به او دروغ گفته. حالا با ماست!"),
    "clock_factory": ("ساعت‌ساز طلسم‌شده", "بابابزرگ اینجاست! نقاب‌دار، زروان است!"),
    "shadow_castle": ("شاه‌سایه", "تالار شاه‌سایه آن بالاست. همهٔ دوستان کمک می‌کنند!"),
    "inverted_land": ("زروان", "اینجا همه‌چیز وارونه است. ساعت وارونه را باید بشکنیم!"),
}


def dialogue(world, n, level_id):
    boss, beat = STORY[world]
    pre = f"l{level_id:02d}"
    if n == 1:
        return ([{"who": "pilo", "text": beat, "id": pre + "_intro_1"},
                 {"who": "nima", "text": "آماده‌ام! برویم.", "id": pre + "_intro_2"}],
                [{"who": "pilo", "text": "آفرین! یک تکهٔ زمان دیگر.", "id": pre + "_outro_1"}])
    if n == 7:
        return ([{"who": "pilo", "text": "اینجا راه مخفی است؛ پر از گنج! الماس افسانه‌ای هم اینجاست.", "id": pre + "_intro_1"}],
                [{"who": "nima", "text": "الماس افسانه‌ای! یکی دیگر به ساعت وارونه نزدیک شدیم.", "id": pre + "_outro_1"}])
    if n == 8:
        return ([{"who": "pilo", "text": f"{boss}! طلسم سایه او را عصبانی کرده. سه بار بزنیمش تا آزاد شود!", "id": pre + "_intro_1"}],
                [{"who": "pilo", "text": f"{boss} آزاد شد! قلب زمان این سرزمین برگشت.", "id": pre + "_outro_1"}])
    return ([{"who": "pilo", "text": "کلید زمان این مرحله را پیدا کنیم!", "id": pre + "_intro_1"}], [])


# --- assembling ----------------------------------------------------------------------

def _titles():
    """Level names live in scripts/progression/level_manager.gd (LEVEL_TITLES)."""
    import re
    src = open(os.path.join(ROOT, "scripts", "progression", "level_manager.gd"), encoding="utf-8").read()
    block = src[src.index("const LEVEL_TITLES"):]
    block = block[:block.index("]")]
    return re.findall(r'"([^"]+)"', block)


TITLES = _titles()


def compose(world_index, n, level_id):
    world = WORLDS[world_index]
    rng = random.Random(level_id * 7919 + 11)
    d = min(1.0, 0.15 + 0.11 * (n - 1) + 0.06 * world_index)
    lens = world in ("forest", "sky_islands", "crystal_caves", "shadow_castle", "inverted_land") or n % 2 == 0
    pool = [s for s in SHARED if lens or s != "lens_river"] + SPECIAL[world] * 2
    plan = ["start"]
    if n == 8:
        plan += rng.sample([s for s in pool if s not in ("secret_pipe", "lens_river")], 2) + ["checkpoint", "boss_arena"]
    elif n == 7:
        plan += ["secret_pipe", "rafts" if world != "golden_desert" else "quicksand", "checkpoint",
                 "cracked_cave", "glide_gap", rng.choice(SPECIAL[world]), "checkpoint", "secret_pipe", "gate"]
    else:
        body = []
        while len(body) < 7 + (1 if n >= 4 else 0):
            pick = rng.choice(pool)
            if not body or body[-1] != pick:
                body.append(pick)
        # the first level of a world opens with its special mechanic
        if n == 1:
            body[0] = SPECIAL[world][0]
        key = "key_underground" if n % 2 == 1 else "key_high"
        at = len(body) * 2 // 3
        body.insert(at, key)
        body.insert(3, "checkpoint")
        body.insert(at + 2, "checkpoint")
        plan += body + ["gate"]
    width = sum(_width(p) for p in plan) + 2
    L = Level(width, rng)
    x = 0
    layout = []
    for p in plan:
        layout.append([p, x])
        x += SEGMENTS[p](L, x, d, world)
    # three stars in the harder spots
    spots = L.stars[:]
    rng.shuffle(spots)
    while len(spots) < 3:
        spots.append((x - 20 + len(spots) * 3, G - 4))
    for sx, sy in sorted(spots[:3]):
        if L.g[sy][sx] in ".c":
            L.put(sx, sy, "*")
        else:
            L.put(sx, sy - 1, "*")
    intro, outro = dialogue(world, n, level_id)
    data = {
        "id": level_id, "format": 2, "world": world, "title": TITLES[level_id - 1], "lens": True, "start_time": "present",
        "difficulty": round(d, 2), "dark": world in DARK and n != 8, "move_range": 4,
        "bee_span": 120 + int(60 * d), "wheel_length": 3 + int(d * 2),
        "intro": intro, "outro": outro,
        "signs": [t for _, t in sorted(L.signs)],
        "warps": L.warps,
        "segments": layout,
        "map": ["".join(r).rstrip(".") or "." for r in L.g],
    }
    if n == 8:
        data["boss"] = world
    return data


_WIDTHS = {}


def _width(name):
    if name not in _WIDTHS:
        probe = Level(80, random.Random(0))
        _WIDTHS[name] = SEGMENTS[name](probe, 0, 0.5, "forest")
    return _WIDTHS[name]


def main():
    only = {int(a) for a in sys.argv[1:] if a.isdigit()}
    for wi, world in enumerate(WORLDS):
        folder = os.path.join(ROOT, "data", "levels", world)
        os.makedirs(folder, exist_ok=True)
        for n in range(1, 9):
            level_id = wi * 8 + n
            if level_id == 1 or (only and level_id not in only):
                continue
            data = compose(wi, n, level_id)
            with open(os.path.join(folder, "level_%02d.json" % level_id), "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=1)
    print("levels written")


if __name__ == "__main__":
    main()
