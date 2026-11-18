#!/usr/bin/env python3
"""T2: every player-facing text lives in data/strings_fa.json (key -> Persian text).

Levels keep only keys: lines {"who", "text_key", "id"(voice)}, "sign_keys", "title_key".
Level text keys follow c{chapter}_l{level}_{nn} (here chapter = the old world index; chapter 1 is
rewritten in T8). Story cards and the opening use their voice ids as keys; on-screen messages use
app_* keys (the same ids as their voice lines). Idempotent: texts already moved stay; new "text"
fields (e.g. after tools/levels/compose.py) are moved again. Run from anywhere."""
import glob, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "data", "strings_fa.json")
sys.path.insert(0, os.path.join(ROOT, "tools", "voice"))

strings = json.load(open(OUT, encoding="utf-8")) if os.path.exists(OUT) else {}
WORLDS = ["forest", "coral_beach", "golden_desert", "snow_mountain", "sky_islands",
          "crystal_caves", "clock_factory", "shadow_castle", "inverted_land"]


def put(key, text):
    if key in strings and strings[key] != text:
        raise SystemExit("key %s already holds another text" % key)
    strings[key] = text
    return key


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")


# --- levels ---------------------------------------------------------------------------------
for path in sorted(glob.glob(os.path.join(ROOT, "data", "levels", "*", "level_*.json"))):
    data = json.load(open(path, encoding="utf-8"))
    if data.get("chapter_key_prefix"):
        prefix = data["chapter_key_prefix"]
    else:
        w = WORLDS.index(data.get("world", "forest")) + 1
        local = (int(data["id"]) - 1) % 8 + 1
        prefix = "c%02d_l%02d" % (w, local)
    n = 0
    used = {v for k, v in strings.items() if k.startswith(prefix + "_")}
    taken = [k for k in strings if k.startswith(prefix + "_") and k[len(prefix) + 1:].isdigit()]
    n = max([int(k[len(prefix) + 1:]) + 1 for k in taken] + [0])
    for kind in ("intro", "rescue", "outro"):
        for line in data.get(kind, []):
            if "text" in line:
                line["text_key"] = put("%s_%02d" % (prefix, n), line.pop("text"))
                n += 1
    if "signs" in data:
        keys = data.get("sign_keys", [])
        for text in data.pop("signs"):
            keys.append(put("%s_%02d" % (prefix, n), text))
            n += 1
        data["sign_keys"] = keys
    if "title" in data:
        data["title_key"] = put(prefix + "_title", data.pop("title"))
    if "goal" in data:
        data["goal_key"] = put(prefix + "_goal", data.pop("goal"))
    save_json(path, data)

# --- story: chapter cards and the opening -----------------------------------------------------------
path = os.path.join(ROOT, "data", "story", "chapters.json")
chapters = json.load(open(path, encoding="utf-8"))
for world, chapter in chapters.items():
    if "title" in chapter:
        chapter["title_key"] = put("chapter_%s_title" % world, chapter.pop("title"))
    for line in chapter.get("lines", []):
        if "text" in line:
            line["text_key"] = put(line["id"], line.pop("text"))
save_json(path, chapters)
path = os.path.join(ROOT, "data", "story", "intro.json")
intro = json.load(open(path, encoding="utf-8"))
for panel in intro["panels"]:
    if "text" in panel:
        panel["text_key"] = put(panel["voice_id"], panel.pop("text"))
save_json(path, intro)

# --- on-screen messages (same ids as their voice lines) ------------------------------------------
from build_voice_lines import APP_LINES, GUARDIANS  # noqa: E402
for line_id, _who, text, _event in APP_LINES:
    put(line_id, text)
for world, name in GUARDIANS.items():
    put("app_freed_" + world, "%s آزاد شد! دروازه باز است." % name)
for key, text in {
    "app_no_companion": "هنوز همراه دیگری نداری؛ در دهکده پیدایش کن.",
    "app_companion_joined": "{name} همراهت شد!",
    "app_freed_generic": "{name} آزاد شد! دروازه باز است.",
    "companion_pilo": "پیلو",
}.items():
    put(key, text)

ordered = dict(sorted(strings.items()))
save_json(OUT, ordered)
print("%d strings -> %s" % (len(ordered), os.path.relpath(OUT, ROOT)))
