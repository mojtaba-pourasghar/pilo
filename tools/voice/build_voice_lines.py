#!/usr/bin/env python3
"""Builds data/voice/voice_lines.json — every line a character says in the game.

    python3 tools/voice/build_voice_lines.py

Sources:
  - dialogue in data/levels/*/level_XX.json ("intro", "outro", "rescue"); each line gets a
    stable "id" (written back into the level file the first time), e.g. l03_intro_2
  - the level signs ("signs"), read aloud by Pilo: l03_sign_1
  - short in-game messages and popups (APP_LINES below), also spoken by Pilo

The game plays assets/audio/voice/<id>.mp3 (or .ogg/.wav) when the line is shown; with no file
the text still shows in the bubble. The voice studio (tools/voice-studio) reads this file and
voices each line with the character's own voice. A hand-written "spoken" respelling (vowels for
the TTS service) is kept across rebuilds; the game only shows "text".
"""
import glob
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "voice", "voice_lines.json")

CHARACTERS = {
    "nima": {"name": "نیما", "about": "پسر ماجراجوی ۸ ساله؛ کنجکاو، مهربان و پرانرژی"},
    "pilo": {"name": "پیلو", "about": "همراه کوچک و بامزهٔ نیما؛ گرم، شاد و راهنما (جواب را لو نمی‌دهد)"},
    "ghubarak": {"name": "غبارک", "about": "موجود غباری بازیگوش؛ شیطون و خنده‌رو، اصلاً ترسناک نیست"},
    "squirrel": {"name": "سنجابک", "about": "سنجاب کوچولو و تند‌حرف؛ هیجان‌زده و قدردان"},
}

# Spoken versions of on-screen messages (ids are used in scripts/: game.gd, level_complete.gd).
APP_LINES = [
    ("app_unsafe", "pilo", "اینجا جای امن نیست!", "لنز زمان رد شد"),
    ("app_need_key", "pilo", "کلید کجاست؟", "به در قفل رسیدی بدون کلید"),
    ("app_rescue_first", "pilo", "اول دوستمان را نجات بده!", "پایان مرحله قبل از نجات دوست"),
    ("app_catch_first", "pilo", "اول غبارک را بگیر!", "پایان مرحلهٔ تعقیب قبل از گرفتن غبارک"),
    ("app_well_done", "pilo", "آفرین!", "پنجرهٔ پایان مرحله"),
    ("app_shard_found", "pilo", "یک تکهٔ زمان پیدا کردی!", "پنجرهٔ پایان مرحله، بار اول"),
    ("app_next_world_soon", "pilo", "دنیای بعدی به‌زودی می‌آید!", "پایان مرحلهٔ آخر دنیا"),
]


def main():
    previous = {}
    if os.path.exists(OUT):
        with open(OUT, encoding="utf-8") as f:
            previous = {l["id"]: l for l in json.load(f).get("lines", [])}

    lines = []

    def add(line_id, who, text, level, kind, event):
        entry = {"id": line_id, "file": "voice/%s.mp3" % line_id, "who": who, "text": text,
                 "level": level, "kind": kind, "event": event}
        spoken = previous.get(line_id, {}).get("spoken")
        if spoken:
            entry["spoken"] = spoken
        lines.append(entry)

    for path in sorted(glob.glob(os.path.join(ROOT, "data", "levels", "*", "level_*.json"))):
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        data = json.loads(raw)
        level = int(data["id"])
        changed = False
        for kind, event in (("intro", "شروع مرحله"), ("rescue", "نجات دوست"), ("outro", "پایان مرحله")):
            for n, line in enumerate(data.get(kind, []), 1):
                if "id" not in line:
                    line["id"] = "l%02d_%s_%d" % (level, kind, n)
                    changed = True
                add(line["id"], line.get("who", "pilo"), line["text"], level, kind,
                    "%s — مرحلهٔ %d" % (event, level))
        for n, text in enumerate(data.get("signs", []), 1):
            add("l%02d_sign_%d" % (level, n), "pilo", text, level, "sign", "تابلوی %d مرحلهٔ %d" % (n, level))
        if changed:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=1)
                f.write("\n")

    for line_id, who, text, event in APP_LINES:
        add(line_id, who, text, 0, "app", event)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({
            "note": "Built by tools/voice/build_voice_lines.py — edit dialogue in the level files. "
                    "Only 'spoken' (TTS respelling) may be edited here; it survives rebuilds.",
            "characters": CHARACTERS,
            "format": {"bitrateKbps": 96, "loudnessLufs": -16, "silenceMs": {"head": 80, "tail": 150}},
            "lines": lines,
        }, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("%d lines -> %s" % (len(lines), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
