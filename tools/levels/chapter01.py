#!/usr/bin/env python3
"""Chapter 1 «جنگل رنگارستان» (T8): eight format-4 levels, written to data/levels/forest/.

    python3 tools/levels/chapter01.py          # writes the 8 levels + their strings
    python3 tests/validate_levels.py 1 2 3 4 5 6 7 8

Source: docs/content/01_chapters_act1.md (levels, keepers, key places), docs/18_gameplay_design.md
§3.2 (six past/present verbs, at least three per level, both layers needed for the keys) and §9
(teaching order), docs/dialogue/ch01.md (lines; voice never says the hero's name: {hero}).

Each level is a row of hand-made segments. A segment may offer one place for the past key or the
present key (three of each per level: the KeyPlacer picks one per run). The keeper stands on the
places of the key it holds, so those are always on ground that exists in both times.
Verbs used (18_gameplay_design §3.2):
  ruin/restore   - bridge_past: a bridge only in the past; rock_stairs: stones only in the past
  open/closed    - rubble: present-only rubble closes the way; cave: a past-only rock wall
  hidden/shown   - treasure: rubble over a treasure in the present, free in the past
  seed and tree  - seed_tree: plant in the past, stand on the tree in the present
  clue           - signs that exist only in the past (K4 carving, K11 answer)
  carry          - K12: a mushroom from the past brought to the present
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "data", "levels", "forest")
STRINGS_PATH = os.path.join(ROOT, "data", "strings_fa.json")
H, G = 22, 16

STRINGS = {}


def s(key, text):
    STRINGS[key] = text
    return key


class Level:
    def __init__(self, lid):
        self.id = lid
        self.w = 0
        self.g = None
        self.slots = {"past": [], "present": []}
        self.extra = {"time_tiles": [], "seeds": [], "memory_marks": [], "clocks": [], "signs_timed": []}
        self.signs = []
        self.parts = []

    def prefix(self):
        return "c01_l%02d" % self.id

    def build(self, segments):
        self.w = sum(seg[0] for seg in segments)
        self.g = [["."] * self.w for _ in range(H)]
        for y in range(G, H):
            for x in range(self.w):
                self.g[y][x] = "#"
        x = 0
        for width, fn, kw in segments:
            fn(self, x, **kw)
            self.parts.append([fn.__name__, x])
            x += width

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def row(self, x0, x1, y, ch):
        for x in range(x0, x1 + 1):
            self.g[y][x] = ch

    def rect(self, x0, x1, y0, y1, ch):
        for y in range(y0, y1 + 1):
            self.row(x0, x1, y, ch)

    def text(self, x, y, txt):
        for i, ch in enumerate(txt):
            if ch != " ":
                self.g[y][x + i] = ch

    def slot(self, time, x, y, hint_text):
        n = len(self.slots[time])
        key = s("%s_hint_%s%d" % (self.prefix(), time[:2], n), hint_text)
        self.slots[time].append(([x, y], key))

    def sign(self, x, text):
        self.put(x, G - 1, "i")
        self.signs.append((x, text))

    def mark(self, x, y, time):
        self.extra["memory_marks"].append({"cell": [x, y], "time": time})

    def rows(self):
        return ["".join(r) for r in self.g]


# --- segments (width, function) ------------------------------------------------------------

def start(lv, x, sign=None):
    lv.put(x + 3, G - 1, "P")
    if sign:
        lv.sign(x + 6, sign)
    lv.text(x + 9, G - 3, "QbUbQ")
    lv.text(x + 9, G - 6, "c.c.c")
    lv.put(x + 15, G - 1, "e")


def flat(lv, x, slot=None, enemy="e", coins=True, item=False):
    if coins:
        lv.text(x + 2, G - 3, "c.c.c.c")
    lv.put(x + 4, G - 4, "Q")
    if enemy:
        lv.put(x + 9, G - 1, enemy)
    if slot:
        lv.slot(slot[0], x + 6, G - 1, slot[1])
    if item:
        lv.item_cell = [x + 6, G - 1]


def checkpoint(lv, x):
    lv.put(x + 1, G - 1, "C")
    lv.text(x + 0, G - 3, "ccc")


def bridge_past(lv, x, slot=True, sign=None, star=False):
    """A pit nine wide; the bridge over it exists only in the past (ruin/restore)."""
    if sign:
        lv.sign(x + 1, sign)
    lv.rect(x + 3, x + 11, G, H - 1, ".")
    lv.row(x + 3, x + 11, G, "B")
    lv.text(x + 4, G - 4, "c.c.c.c")
    lv.put(x + 7, G - 3, "y")
    if star:
        lv.put(x + 7, G - 6, "*")
    if slot:
        lv.slot("past", x + 7, G - 1, "روی پل کهنه، وسط پرتگاه")


def bridge_present(lv, x, slot=True):
    """A pit nine wide with a bridge of vines that only grows in the present."""
    lv.rect(x + 3, x + 11, G, H - 1, ".")
    lv.row(x + 3, x + 11, G, "V")
    lv.text(x + 4, G - 4, "c.c.c.c")
    if slot:
        lv.slot("present", x + 7, G - 1, "روی پل پیچک‌ها")


def rock_stairs(lv, x, slot=True, star=True, mark=False):
    """Stones that only exist in the past make a stair up to a high plank."""
    lv.put(x + 2, G - 1, "r")
    lv.rect(x + 4, x + 4, G - 2, G - 1, "r")
    lv.rect(x + 6, x + 6, G - 3, G - 1, "r")
    lv.row(x + 8, x + 13, G - 5, "o")
    lv.text(x + 9, G - 7, "cc.cc")
    if star:
        lv.put(x + 11, G - 8, "*")
    if mark:
        lv.mark(x + 13, G - 6, "past")
    if slot:
        lv.slot("past", x + 11, G - 6, "بالای سنگ‌هایی که فقط در گذشته‌اند")


def vine_shelf(lv, x, slot=True, mark=False, star=True):
    """Vines that only grow in the present lead up to a stone shelf (keeper-safe ground)."""
    lv.row(x + 3, x + 7, G - 3, "V")
    lv.row(x + 9, x + 11, G - 5, "V")
    lv.rect(x + 14, x + 21, G - 5, G - 4, "#")
    lv.text(x + 15, G - 7, "c.c.c.c")
    lv.put(x + 18, G - 1, "e")
    if star:
        lv.put(x + 20, G - 8, "*")
    if mark:
        lv.mark(x + 21, G - 7, "present")
    if slot:
        lv.slot("present", x + 18, G - 6, "روی سکوی سنگی بالا، از راه پیچک‌ها")


def cave(lv, x, slot=True, mark=False):
    """A cave; a rock wall in its middle exists only in the past (closed then, open now)."""
    lv.rect(x + 2, x + 17, G - 5, G - 4, "#")
    lv.rect(x + 10, x + 10, G - 3, G - 1, "r")
    lv.text(x + 4, G - 1, "c.c.c")
    lv.put(x + 6, G - 3, "Q")
    if mark:
        lv.mark(x + 15, G - 2, "past")
    if slot:
        lv.slot("past", x + 14, G - 1, "ته غار، پشت دیوار سنگی گذشته")


def water_past(lv, x, slot=True):
    """A river that only flows in the past: stepping planks then; a dry bed to walk in now."""
    lv.rect(x + 3, x + 12, G, G + 1, ".")
    lv.rect(x + 3, x + 12, G, G + 1, "w")
    lv.row(x + 4, x + 6, G - 3, "o")
    lv.row(x + 9, x + 11, G - 3, "o")
    lv.text(x + 4, G - 5, "c.c...c.c")
    if slot:
        lv.slot("present", x + 8, G + 1, "در بستر خشک رود (آب فقط در گذشته جاری است)")


def rubble(lv, x, slot=True):
    """Rubble that only lies in the present closes the way (open in the past)."""
    lv.extra["time_tiles"].append({"x": x + 3, "y": G - 5, "w": 2, "h": 5, "kind": "rock", "time": "present"})
    lv.text(x + 7, G - 3, "c.c")
    if slot:
        lv.slot("present", x + 8, G - 1, "پشت سنگ‌ریزه‌هایی که فقط در حال‌اند")


def treasure(lv, x, mark=True):
    """Hidden then shown: in the present a pile of rubble covers a diamond; in the past it is free."""
    lv.extra["time_tiles"].append({"x": x + 3, "y": G - 2, "w": 3, "h": 2, "kind": "rock", "time": "present"})
    lv.put(x + 4, G - 1, "d")
    if mark:
        lv.mark(x + 5, G - 1, "past")


def seed_tree(lv, x, star=True, mark=False):
    """Seed and tree: plant in the past; in the present a tree grows to stand on."""
    lv.extra["seeds"].append({"cell": [x + 3, G - 1], "tree": [x + 5, G - 3, 3]})
    lv.row(x + 9, x + 11, G - 6, "o")
    lv.text(x + 9, G - 8, "c.c")
    if star:
        lv.put(x + 10, G - 9, "*")
    if mark:
        lv.mark(x + 11, G - 7, "present")


def gate(lv, x, sign=None):
    if sign:
        lv.sign(x + 1, sign)
    lv.text(x + 3, G - 4, "c.c.c")
    lv.put(x + 7, G - 1, "E")


def clock(lv, x, y=G - 2):
    lv.extra["clocks"].append([x, y])


# --- the levels -----------------------------------------------------------------------------

def line(who, key, text, voice=None):
    """A dialogue line: text into strings_fa.json, voice id from docs/dialogue/ch01.md if recorded."""
    STRINGS[key] = text
    out = {"who": who, "text_key": key}
    out["id"] = voice or key
    return out


def write_level(lv, title, kind, keeper=None, intro=(), outro=(), extra=None):
    data = {
        "id": lv.id, "format": 4, "world": "forest", "chapter": "ch01", "index": lv.id,
        "title_key": s(lv.prefix() + "_title", title), "kind": kind,
        "weapon_level_required": 1, "dual_physics": False, "lens": True,
        "bee_span": 150, "wheel_length": 4,
        "keeper": keeper,
        "intro": list(intro), "outro": list(outro),
        "sign_keys": [s("%s_sign_%d" % (lv.prefix(), i), t) for i, (_, t) in enumerate(lv.signs)],
        "rewards": {"coins": [20, 40], "stars": 3},
        "map": lv.rows(),
        "segments": lv.parts,
    }
    if kind in ("normal", "race"):
        assert len(lv.slots["past"]) == 3 and len(lv.slots["present"]) == 3, (lv.id, lv.slots)
        data["key_slots"] = {t: [c for c, _ in lv.slots[t]] for t in ("past", "present")}
        data["key_hints"] = {t: [k for _, k in lv.slots[t]] for t in ("past", "present")}
    for k, v in lv.extra.items():
        if v:
            data[k] = v
    if extra:
        data.update(extra)
    path = os.path.join(OUT_DIR, "level_%02d.json" % lv.id)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")
    return data


def level_1():
    lv = Level(1)
    lv.build([
        (16, start, {"sign": "راه برو و بپر! دکمهٔ لنز تو را بین حال و گذشته می‌برد."}),
        (15, bridge_past, {"sign": "این پل فقط در گذشته هست. لنز را بزن!"}),
        (12, seed_tree, {}),
        (18, rock_stairs, {"mark": True}),
        (4, checkpoint, {}),
        (24, vine_shelf, {"mark": True}),
        (20, cave, {}),
        (4, checkpoint, {}),
        (16, water_past, {}),
        (12, rubble, {}),
        (10, treasure, {}),
        (12, gate, {"sign": "دروازه دو قفل دارد: کلید گذشته و کلید حال."}),
    ])
    clock(lv, 60)
    keeper = {"type": "K1", "id": "rootling", "holds": "present", "awake_in": "past", "hp_hits": 3,
              "hint_key": s("keeper_rootling_hint", "جوجه‌ریشه در حال خواب است. آرام راه برو (ندو، نپر) و کلید را بردار!")}
    s("keeper_rootling_name", "جوجه‌ریشه")
    s("keeper_rootling_line", "ریشه‌هایم راحت شدند.")
    intro = [
        line("pilo", "c01_l01_00", "لنز را بالا بگیر. همین‌جا... ببین!", "c01_s2_01"),
        line("hero", "c01_l01_01", "همه‌چیز زنده است! چقدر قشنگ.", "c01_s2_03"),
        line("pilo", "c01_l01_02", "این گذشته است. اگر دوباره بزنی، به حال برمی‌گردی.", "c01_s2_04"),
        line("hero", "c01_l01_03", "پس لنز یعنی دکمهٔ اکشنِ زمان؟", "c01_s2_05"),
        line("pilo", "c01_l01_04", "یک کلید در گذشته است و یکی در حال. نشانه‌ها را ببین!"),
    ]
    outro = [
        line("hero", "c01_l01_05", "نمی‌خواهم سایه‌ها را بزنم. می‌خواهم آزادشان کنم.", "c01_s2_07"),
        line("pilo", "c01_l01_06", "همین کار را می‌کنی. فقط ضربهٔ آرام.", "c01_s2_08"),
    ]
    return write_level(lv, "راه اول", "normal", keeper, intro, outro)


def level_2():
    lv = Level(2)
    lv.build([
        (16, start, {}),
        (15, bridge_past, {"sign": "پل کُنده‌ها فقط در گذشته‌اند؛ پیچک‌ها فقط در حال."}),
        (14, flat, {}),
        (15, bridge_present, {"slot": False}),
        (12, seed_tree, {"star": False, "mark": False}),
        (18, rock_stairs, {}),
        (4, checkpoint, {}),
        (24, vine_shelf, {"mark": True}),
        (15, bridge_past, {"slot": False, "star": True}),
        (12, rubble, {}),
        (20, cave, {"mark": True}),
        (4, checkpoint, {}),
        (14, flat, {"slot": ("present", "کنار درخت، نزدیک دروازه")}),
        (10, treasure, {}),
        (12, gate, {}),
    ])
    clock(lv, 75)
    keeper = {"type": "K2", "id": "stonewing", "holds": "present", "hp_hits": 3,
              "hint_key": s("keeper_stonewing_hint", "سپر سنگ‌بالک جلوی توست. از رویش بپر و از پشت بزن!")}
    s("keeper_stonewing_name", "سنگ‌بالک")
    s("keeper_stonewing_line", "سنگ هم می‌تواند سبک باشد.")
    intro = [
        line("pilo", "c01_l02_00", "پل کُنده‌ها فقط در گذشته‌اند. مراقب باش!"),
        line("hero", "c01_l02_01", "آن سنگِ بالدار با سپرش آن‌جا چه می‌کند؟"),
        line("pilo", "c01_l02_02", "سنگ‌بالک است. تیرها از سپرش برمی‌گردند."),
    ]
    outro = [line("pilo", "c01_l02_03", "دروازه باز شد! سایه‌ها دارند عقب می‌روند.")]
    return write_level(lv, "پل کُنده‌ها", "normal", keeper, intro, outro)


def level_3():
    lv = Level(3)
    lv.build([
        (16, start, {}),
        (16, water_past, {}),
        (20, cave, {"mark": True}),
        (12, seed_tree, {}),
        (4, checkpoint, {}),
        (18, rock_stairs, {}),
        (16, water_past, {}),
        (15, bridge_past, {"slot": False}),
        (20, cave, {}),
        (4, checkpoint, {}),
        (24, vine_shelf, {"mark": True, "star": True}),
        (10, treasure, {"mark": True}),
        (12, gate, {}),
    ])
    clock(lv, 52)
    clock(lv, 120)
    # the old waterfall flows only in the past: K8 hides by it; Pilo's light (or a mirror) draws it out
    keeper = {"type": "K8", "id": "fishcatcher", "holds": "past", "hp_hits": 3,
              "hint_key": s("keeper_fishcatcher_hint", "ماهی‌کش پشت آب پنهان است. نزدیک برو و دکمهٔ پیلو را بزن تا نورش بیرونش بکشد!")}
    s("keeper_fishcatcher_name", "ماهی‌کش")
    s("keeper_fishcatcher_line", "آب را دوست دارم، نه سایه را.")
    intro = [
        line("pilo", "c01_l03_00", "یک ردپا! کنارش ساعت کشیده‌اند.", "c01_s3_01"),
        line("hero", "c01_l03_01", "کسی اینجا بوده که دنبال قلب‌ها می‌گشته.", "c01_s3_02"),
        line("pilo", "c01_l03_02", "و هنوز دور نیست.", "c01_s3_03"),
    ]
    outro = [line("pilo", "c01_l03_03", "آبشار قدیمی دوباره می‌خواند... در گذشته!")]
    return write_level(lv, "آبشار قدیمی", "normal", keeper, intro, outro)


def level_4():
    lv = Level(4)
    lv.build([
        (16, start, {}),
        (20, cave, {}),
        (24, vine_shelf, {}),
        (18, rock_stairs, {"mark": True}),
        (4, checkpoint, {}),
        (12, rubble, {}),
        (14, flat, {"enemy": "h"}),
        (20, cave, {"mark": True}),
        (4, checkpoint, {}),
        (16, water_past, {}),
        (12, seed_tree, {"mark": True}),
        (12, gate, {}),
    ])
    sign_x = 70
    lv.extra["signs_timed"].append({"cell": [sign_x - 4, G - 1], "time": "past",
        "text_key": s("c01_l04_carving", "نقش روی تنهٔ کهنه: خورشید ← ماه ← برگ. ریشه‌ها همین ترتیب را می‌خواهند.")})
    clock(lv, 92)
    keeper = {"type": "K4", "id": "rootkeeper", "holds": "present", "hp_hits": 3, "pattern": [0, 1, 2],
              "sign_cell": [sign_x, G - 1],
              "hint_key": s("keeper_rootkeeper_hint", "ترتیب گره‌ها روی تنهٔ گذشته کنده شده: خورشید، ماه، برگ!")}
    s("keeper_rootkeeper_name", "ریشه‌دار")
    s("keeper_rootkeeper_line", "ریشه‌ها خوب حرف می‌زنند.")
    intro = [
        line("pilo", "c01_l04_00", "ریشه‌ها در گذشته نقش دارند. نقش‌ها چیزی می‌گویند!"),
        line("hero", "c01_l04_01", "پس اول در گذشته می‌خوانم، بعد در حال می‌زنم."),
    ]
    outro = [line("pilo", "c01_l04_02", "ریشه‌دار آزاد شد. تونل نفس کشید!")]
    return write_level(lv, "تونل ریشه‌ها", "normal", keeper, intro, outro)


def level_5():
    lv = Level(5)
    lv.build([
        (16, start, {}),
        (18, rock_stairs, {}),
        (12, seed_tree, {"mark": True}),
        (24, vine_shelf, {}),
        (4, checkpoint, {}),
        (15, bridge_past, {}),
        (14, flat, {"slot": ("present", "زیر شاخه‌های درخت بزرگ")}),
        (20, cave, {"mark": True}),
        (12, rubble, {}),
        (4, checkpoint, {}),
        (12, seed_tree, {"star": False, "mark": True}),
        (12, gate, {}),
    ])
    lv.extra["signs_timed"].append({"cell": [34, G - 1], "time": "past",
        "text_key": s("c01_l05_answer", "روی تابلوی جوانه: «وقتی برف آب می‌شود، بهار بیدار می‌شود.»")})
    clock(lv, 66)
    keeper = {"type": "K11", "id": "leaf_elder", "holds": "present", "hp_hits": 3, "who": "leaf_elder",
              "question_key": s("keeper_leaf_elder_question", "کدام فصل بیدار است؟"),
              "answer_keys": [s("keeper_leaf_elder_a0", "زمستان"), s("keeper_leaf_elder_a1", "بهار")], "correct": 1,
              "hint_key": s("keeper_leaf_elder_hint", "جواب روی تابلوی گذشته، کنار جوانه است!")}
    s("keeper_leaf_elder_name", "پیرمرد برگی")
    s("keeper_leaf_elder_line", "بهار. همیشه بهار.")
    intro = [
        line("hero", "c01_l05_00", "این درخت هزار سال دارد!"),
        line("pilo", "c01_l05_01", "در گذشته فقط یک جوانه بود. بذرها را ببین!"),
    ]
    outro = [line("pilo", "c01_l05_02", "پیرمرد برگی لبخند زد. درخت آواز می‌خواند!")]
    return write_level(lv, "درخت هزارساله", "normal", keeper, intro, outro)


def level_6():
    lv = Level(6)
    lv.build([
        (16, start, {}),
        (15, bridge_past, {}),
        (16, water_past, {}),
        (12, seed_tree, {"mark": True}),
        (18, rock_stairs, {}),
        (4, checkpoint, {}),
        (14, flat, {"item": True, "enemy": "e"}),
        (24, vine_shelf, {"mark": True}),
        (20, cave, {}),
        (12, rubble, {}),
        (4, checkpoint, {}),
        (10, treasure, {"mark": True}),
        (12, gate, {}),
    ])
    clock(lv, 70)
    keeper = {"type": "K12", "id": "mushroom_king", "holds": "present", "hp_hits": 3, "needs": "glow_mushroom",
              "item_cell": lv.item_cell,
              "hint_key": s("keeper_mushroom_king_hint", "قارچ درخشان فقط در گذشته می‌روید. برش دار و در حال برای قارچ‌شاه بیاور!")}
    s("keeper_mushroom_king_name", "قارچ‌شاه")
    s("keeper_mushroom_king_line", "قارچ من! ممنون.")
    intro = [
        line("pilo", "c01_l06_00", "قارچ‌ها فقط در گذشته می‌رویند."),
        line("hero", "c01_l06_01", "و قارچ‌شاه بدون قارچش کلید را نمی‌دهد؟"),
    ]
    outro = [line("pilo", "c01_l06_02", "دره دوباره رنگ گرفت. لانهٔ خرس نزدیک است!")]
    return write_level(lv, "درهٔ قارچ‌ها", "normal", keeper, intro, outro)


def level_7():
    """Memory room: no keeper, a gentle puzzle (plant a seed in the past to reach the egg now)."""
    lv = Level(7)
    lv.build([
        (16, start, {}),
        (12, seed_tree, {"star": True}),
        (10, treasure, {"mark": False}),
        (12, seed_tree, {"star": True}),
        (14, flat, {"enemy": ""}),
        (12, gate, {}),
    ])
    lv.put(48, G - 9, "*")
    lv.put(66, G - 4, "*")
    intro = [
        line("pilo", "c01_l07_00", "باغ پنهان... اینجا یک خاطره خوابیده است."),
    ]
    memory = [
        line("grandpa", "c01_l07_01", "اینجا قلب را کنار درخت می‌گذاریم تا جنگل همیشه بخواند.", "c01_s4_02"),
        line("hero", "c01_l07_02", "بابابزرگ جوان بود!", "c01_s4_03"),
        line("pilo", "c01_l07_03", "وای، آن چیست؟ یک تخم دیگر!", "c01_s4_04"),
    ]
    extra = {"memory": {"lines": memory, "egg": "bargak", "cell": [58, G - 1], "panel": "res://assets/art/p11_story/panels/s03_ghost_past_layer.png"},
             "unlock": {"memory_marks": 3, "from_levels": [1, 2, 3, 4, 5, 6]}}
    return write_level(lv, "باغ پنهان", "memory", None, intro, [], extra)


def level_8():
    """The Old Bear's lair: the guardian of chapter 1. The song stone is in the past of the lair."""
    lv = Level(8)
    w = 46
    lv.w = w
    lv.g = [["."] * w for _ in range(H)]
    for y in range(G, H):
        for x in range(w):
            lv.g[y][x] = "#"
    lv.rect(0, 0, 0, G - 1, "#")
    lv.rect(w - 1, w - 1, 0, G - 1, "#")
    lv.put(3, G - 1, "P")
    lv.put(w - 4, G - 1, "E")
    lv.text(8, G - 4, "c.c.c")
    lv.row(10, 14, G - 5, "o")
    lv.row(28, 32, G - 5, "o")
    lv.put(12, G - 7, "*")
    lv.put(30, G - 7, "*")
    lv.put(21, G - 3, "*")
    lv.parts = [["boss_arena", 0]]
    intro = [
        line("bear", "c01_l08_00", "بچه‌ام... بچه‌ام را برگردان!", "c01_s5_01"),
        line("hero", "c01_l08_01", "او ما را دزد فکر می‌کند.", "c01_s5_02"),
        line("pilo", "c01_l08_02", "بچه‌اش را سایه‌ها برده‌اند؛ لالایی را.", "c01_s5_03"),
    ]
    released = [
        line("bear", "c01_l08_03", "سایه‌ها دستور کسی را اجرا می‌کنند... مراقب باشید. این قلب زمان مال شماست.", "c01_s5_09"),
        line("hero", "c01_l08_04", "قلب اول. یکی از هشت.", "c01_s6_01"),
        line("pilo", "c01_l08_05", "هنوز هفت‌تا مانده. ولی اولی سخت‌ترین بود.", "c01_s6_02"),
    ]
    s("guardian_old_bear_phase2", "لالایی... کجاست؟")
    s("guardian_old_bear_song_clue", "سنگ آواز! در گذشتهٔ لانه‌اش باید باشد!")
    extra = {"guardian": {"id": "old_bear", "pos": [30, G - 1], "arena": [1, w - 1], "song_stone": [6, G - 1],
                          "flashback_panel": "res://assets/art/p11_story/panels/s07_bear_calm.png",
                          "flashback_key": "guardian_old_bear_flashback"},
             "released": released,
             "reward": {"heart_of_time": 1, "egg": "bargak", "tool": "slingshot", "unlocks": "hub"}}
    return write_level(lv, "لانهٔ خرس پیر", "boss", None, intro, [], extra)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for build in (level_1, level_2, level_3, level_4, level_5, level_6, level_7, level_8):
        data = build()
        print("level %d: %d x %d" % (data["id"], len(data["map"][0]), len(data["map"])))
    strings = json.load(open(STRINGS_PATH, encoding="utf-8"))
    # chapter 1's old texts (version 3) go; the new ones come in
    for k in [k for k in strings if k.startswith("c01_l0")]:
        del strings[k]
    strings.update(STRINGS)
    with open(STRINGS_PATH, "w", encoding="utf-8") as f:
        json.dump(dict(sorted(strings.items())), f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("%d strings" % len(STRINGS))


if __name__ == "__main__":
    main()
