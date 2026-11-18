#!/usr/bin/env python3
"""T4: converts level files from format 2 to format 4 (docs/02_godot_spec.md §4.1).

    python3 tools/levels/migrate_v2_to_v4.py          # every format-2 level
    python3 tools/levels/migrate_v2_to_v4.py 9 16      # only these ids

The map stays as it is, except the single time key: 'k' is removed and 'X' (fox den with the key)
becomes 'Y' (fox den with a diamond). New fields: chapter, index, kind, weapon_level_required,
dual_physics, keeper, key_slots (three places for the past key and three for the present key),
key_hints (a clue per place, keys into data/strings_fa.json) and rewards.

The places are found with the level checker's own search (tests/validate_levels.py): past places
are cells the hero can stand on in the past - preferably ones that need the lens - and present
places cells reachable in the present; spread along the level (the old key spot is kept as one of
the present places). These old worlds (2-9) are kept as "legacy_v3" until they are rewritten
(T13): they have no keeper yet. Every result is checked; a level that fails stays format 2."""
import json, os, sys, glob

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tests"))
import validate_levels as V  # noqa: E402

STRINGS_PATH = os.path.join(ROOT, "data", "strings_fa.json")
WORLDS = ["forest", "coral_beach", "golden_desert", "snow_mountain", "sky_islands",
          "crystal_caves", "clock_factory", "shadow_castle", "inverted_land"]
HINTS = {
    "hint_near_water": "نزدیک آب",
    "hint_high": "آن بالا، روی سکوها",
    "hint_underground": "زیر زمین",
    "hint_on_bridge": "روی پل",
    "hint_near_rock": "کنار سنگ‌ها",
    "hint_near_gate": "نزدیک دروازه",
    "hint_ground": "روی زمین، سر راه",
    "hint_far_end": "ته مسیر",
    "hint_near_start": "نزدیک شروع",
}


def hint_for(level, x, y, ground_row, exit_x):
    near = lambda chars, r=3: any(level.at(x + dx, y + dy) in chars for dx in range(-r, r + 1) for dy in range(-2, 3))
    if near("~wa s", 3):
        return "hint_near_water"
    if any(level.at(x, yy) == "#" for yy in range(0, y)):
        return "hint_underground"
    if level.at(x, y + 1) in "B":
        return "hint_on_bridge"
    if y < ground_row - 3:
        return "hint_high"
    if near("r", 2):
        return "hint_near_rock"
    if abs(x - exit_x) < 12:
        return "hint_near_gate"
    if x < 25:
        return "hint_near_start"
    return "hint_ground"


def pick_spread(cells, width, ok, n=3, avoid=()):
    """n cells spread along the level (around 30%, 55% and 80% of its width), at least 8 apart;
    `ok(cell)` (the costly reachability test) is only asked for the nearest candidates."""
    chosen = list(avoid)
    out = []
    targets = (0.3, 0.55, 0.8) if n == 3 else ((0.45, 0.8) if n == 2 else (0.6,))
    for target in targets:
        tx = target * width
        tried = 0
        for c in sorted(cells, key=lambda c: abs(c[0] - tx)):
            if not all(abs(c[0] - o[0]) >= 8 or abs(c[1] - o[1]) >= 4 for o in chosen):
                continue
            tried += 1
            if tried > 40:
                break
            if ok(c):
                chosen.append(c)
                out.append(c)
                break
    return out


def migrate(path, strings):
    data = json.load(open(path, encoding="utf-8"))
    if int(data.get("format", 1)) >= 4:
        return "skip"
    world = data.get("world", "forest")
    w_index = WORLDS.index(world) + 1
    local = (int(data["id"]) - 1) % 8 + 1
    old_keys = []
    rows = []
    for y, row in enumerate(data["map"]):
        for x, c in enumerate(row):
            if c == "k":
                old_keys.append((x, y))
        rows.append(row.replace("k", ".").replace("X", "Y"))
    new = dict(data)
    new["map"] = rows
    new["format"] = 4
    new["chapter"] = "ch%02d" % w_index
    new["index"] = local
    kind = "boss" if local == 8 else ("memory" if local == 7 else ("race" if data.get("race") else "normal"))
    new["kind"] = kind
    new["weapon_level_required"] = 1
    new["dual_physics"] = False
    new["keeper"] = None
    new["legacy_v3"] = True
    new.pop("start_time", None)
    new["rewards"] = {"coins": [20, 40], "stars": 3}
    if kind in ("normal", "race"):
        level = V.Level(new)
        sx, sy = level.find("P")[0]
        states = V.explore(level, [(sx, sy, V.PRESENT, 0, 0)])
        alone = V.Level(new)
        alone.no_shift = True
        present_only = {(s[0], s[1]) for s in V.explore(alone, [(sx, sy, V.PRESENT, 0, 0)])}
        ex, ey = level.find("E")[0]
        ground = max(y for (_, y) in level.find("#")) if level.find("#") else level.h - 2
        ground_row = min(y for y in range(level.h) if level.g[y].count("#") > level.w * 0.3) if level.find("#") else level.h - 2

        def ok_for(t):
            def ok(cell):
                x, y = cell
                if x < 10 or abs(x - ex) < 3:
                    return False
                if level.solid(x, y, t) or level.hazard(x, y, t) or level.solid(x, y, 1 - t):
                    return False
                reach, back = V.key_reach(level, states, (x, y), t, (ex, ey))
                return reach and back
            return ok

        past_cells = {(s[0], s[1]) for s in states if s[2] == V.PAST}
        need_lens = [c for c in past_cells if c not in present_only]
        past = pick_spread(need_lens, level.w, ok_for(V.PAST))
        if len(past) < 3:
            past = pick_spread(sorted(past_cells), level.w, ok_for(V.PAST))
        present_cells = sorted({(s[0], s[1]) for s in states if s[2] == V.PRESENT})
        keep = [c for c in old_keys if ok_for(V.PRESENT)(c)][:1]
        present = keep + pick_spread(present_cells, level.w, ok_for(V.PRESENT), 3 - len(keep), avoid=keep + past)
        if len(past) < 3 or len(present) < 3:
            return "no places (%d/%d)" % (len(past), len(present))
        new["key_slots"] = {"past": [list(c) for c in past], "present": [list(c) for c in present]}
        new["key_hints"] = {
            "past": [hint_for(level, x, y, ground_row, ex) for x, y in past],
            "present": [hint_for(level, x, y, ground_row, ex) for x, y in present],
        }
    for k, v in HINTS.items():
        strings.setdefault(k, v)
    tmp = path + ".v4tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(new, f, ensure_ascii=False, indent=1)
        f.write("\n")
    V.STRINGS = strings
    errors, _ = V.check(tmp)
    if errors:
        os.remove(tmp)
        return "check failed: " + "; ".join(errors[:3])
    os.replace(tmp, path)
    return "ok"


def main():
    strings = json.load(open(STRINGS_PATH, encoding="utf-8"))
    only = {int(a) for a in sys.argv[1:] if a.isdigit()}
    failed = 0
    for path in sorted(glob.glob(os.path.join(ROOT, "data", "levels", "*", "level_*.json"))):
        if only and int(os.path.basename(path)[6:8]) not in only:
            continue
        result = migrate(path, strings)
        if result not in ("ok", "skip"):
            failed += 1
        print("%-60s %s" % (os.path.relpath(path, ROOT), result))
    with open(STRINGS_PATH, "w", encoding="utf-8") as f:
        json.dump(dict(sorted(strings.items())), f, ensure_ascii=False, indent=1)
        f.write("\n")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
