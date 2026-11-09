#!/usr/bin/env python3
"""Builds data/voice/voice_lines.json — every line a character says in the game.

    python3 tools/voice/build_voice_lines.py

Sources:
  - dialogue in data/levels/*/level_XX.json ("intro", "outro", "rescue"); each line gets a
    stable "id" (written back into the level file the first time), e.g. l03_intro_2
  - the level signs ("signs"), read aloud by Pilo: l03_sign_1
  - short in-game messages and popups (APP_LINES below), also spoken by Pilo, and a
    "<guardian> آزاد شد!" line for every world
  - the opening story (data/story/intro.json), the chapter cards (data/story/chapters.json)
    and the opening tutorial (scripts/ui/tutorial.gd)

The game plays assets/audio/voice/<id>.mp3 (or .ogg/.wav) when the line is shown; with no file
the text still shows in the bubble. The voice studio (tools/voice-studio, Avasho) reads this file
and voices each line with the character's own voice, sending the vowelled form ("spoken", from
tools/voice/spoken_fa.json or a respelling saved in the studio); the game only shows "text".
"""
import glob
import re
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "voice", "voice_lines.json")

# Every speaker: name, who they are, and the Avasho voice and pace the voice studio
# (tools/voice-studio) uses for their lines. Avasho has no child voices, so the boys Nima and
# Kian are voiced by young female voices, as in Persian dubbing of children's films.
CHARACTERS = {
    "narrator": {"name": "راوی", "about": "قصه‌گوی گرم و مهربان", "speaker": "shahrzad", "speed": 0.95},
    "nima": {"name": "نیما", "about": "پسر ماجراجوی ۸ ساله؛ کنجکاو، مهربان و پرانرژی", "speaker": "bahar", "speed": 1.0},
    "pilo": {"name": "پیلو", "about": "همراه کوچک و بامزهٔ نیما؛ گرم، شاد و راهنما (جواب را لو نمی‌دهد)", "speaker": "pune", "speed": 0.9},
    "ghubarak": {"name": "غبارک", "about": "موجود غباری بازیگوش؛ شیطون و خنده‌رو، اصلاً ترسناک نیست", "speaker": "ariya", "speed": 1.1},
    "squirrel": {"name": "سنجابک", "about": "سنجاب کوچولو و تند‌حرف؛ هیجان‌زده و قدردان", "speaker": "sheyda", "speed": 1.15},
    "kian": {"name": "کیان", "about": "رقیب نیما؛ مغرور ولی ته دلش خوب", "speaker": "sara", "speed": 1.05},
    "grandpa": {"name": "بابابزرگ ساعت‌ساز", "about": "ساعت‌ساز پیر و مهربان", "speaker": "parviz", "speed": 0.9},
    "grandma": {"name": "مادربزرگ کاکتوس", "about": "کاکتوس پیر و مهربان بیابان", "speaker": "shirin", "speed": 0.9},
    "captain": {"name": "ناخدا موج", "about": "ناخدای خوش‌خندهٔ ساحل", "speaker": "bahman", "speed": 1.0},
    "zurvan": {"name": "زروان", "about": "جادوگر زمان؛ مرموز ولی نه ترسناک", "speaker": "dara", "speed": 0.85},
    "masked": {"name": "نقاب‌دار", "about": "آدم نقاب‌دار مرموز", "speaker": "nourai", "speed": 0.9},
    "shadow_king": {"name": "شاه‌سایه", "about": "پادشاه سایه‌ها؛ باشکوه و نمایشی، نه ترسناک", "speaker": "shahriyar", "speed": 0.85},
    "bear": {"name": "خرس پیر جنگل", "about": "نگهبان جنگل؛ صدای بم و آرام", "speaker": "kiani", "speed": 0.85},
    "octopus": {"name": "اختاپوس بزرگ", "about": "نگهبان ساحل؛ مهربان", "speaker": "shirin", "speed": 1.0},
    "worm": {"name": "کرم شنی", "about": "نگهبان بیابان؛ آرام و دانا", "speaker": "dara", "speed": 0.8},
    "yeti": {"name": "غول یخی", "about": "نگهبان کوهستان؛ بزرگ و مهربان", "speaker": "bahman", "speed": 0.85},
    "eagle": {"name": "عقاب طوفان", "about": "نگهبان آسمان؛ مغرور و نجیب", "speaker": "farhad", "speed": 1.0},
    "spider": {"name": "عنکبوت بلورین", "about": "نگهبان غارها؛ آرام و مرموز", "speaker": "shahrzad", "speed": 1.05},
    "turtle": {"name": "لاکی", "about": "لاک‌پشت همراه؛ آرام و شاد", "speaker": "kiani", "speed": 1.0},
    "mole": {"name": "خال‌خالی", "about": "موش‌کور همراه؛ بامزه", "speaker": "ariya", "speed": 1.0},
    "penguin": {"name": "یخک", "about": "پنگوئن همراه؛ سرزنده", "speaker": "sheyda", "speed": 1.05},
    "butterfly": {"name": "پَرپَری", "about": "پروانهٔ همراه؛ سبک و رؤیایی", "speaker": "sara", "speed": 1.1},
    "owl": {"name": "پیچ‌پیچ", "about": "جغد کیان؛ دانا و آرام", "speaker": "nourai", "speed": 1.0},
    "spark": {"name": "جرقه", "about": "جرقهٔ همراه؛ تند و پرانرژی", "speaker": "pune", "speed": 1.15},
    "dragon": {"name": "اژدهاک", "about": "اژدهای کوچک همراه؛ بازیگوش", "speaker": "shahriyar", "speed": 1.1},
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
    ("app_race_start", "pilo", "مسابقه با کیان! زودتر به دروازه برس.", "شروع مسابقه با کیان"),
    ("app_race_lost", "pilo", "کیان زودتر به دروازه رسید! باز هم می‌شود کلید را پیدا کرد.", "کیان برد"),
    ("app_race_won", "pilo", "تو از کیان زودتر رسیدی! پنجاه سکه جایزه.", "نیما برد"),
    ("app_time_key", "pilo", "کلید زمان! حالا دروازه باز می‌شود.", "کلید زمان پیدا شد"),
    ("app_gate_locked", "pilo", "دروازه قفل است؛ کلید زمان را پیدا کن!", "دروازهٔ قفل بدون کلید زمان"),
    ("app_try_again", "pilo", "اوه! دوباره امتحان کنیم.", "افتادن یا از دست دادن قلب‌ها"),
]

# "<guardian> آزاد شد!" for each world (game.gd: app_freed_<world>), same names as scripts/enemies/boss.gd.
GUARDIANS = {
    "forest": "خرس پیر جنگل", "coral_beach": "اختاپوس بزرگ", "golden_desert": "کرم شنی",
    "snow_mountain": "غول یخی", "sky_islands": "عقاب طوفان", "crystal_caves": "عنکبوت بلورین",
    "clock_factory": "ساعت‌ساز طلسم‌شده", "shadow_castle": "شاه‌سایه", "inverted_land": "زروان",
}


SPOKEN_FILE = os.path.join(ROOT, "tools", "voice", "spoken_fa.json")
SPOKEN = json.load(open(SPOKEN_FILE, encoding="utf-8")) if os.path.exists(SPOKEN_FILE) else {}


def main():
    previous = {}
    if os.path.exists(OUT):
        with open(OUT, encoding="utf-8") as f:
            previous = {l["id"]: l for l in json.load(f).get("lines", [])}

    lines = []

    def add(line_id, who, text, level, kind, event):
        entry = {"id": line_id, "file": "voice/%s.mp3" % line_id, "who": who, "text": text,
                 "level": level, "kind": kind, "event": event}
        # the fully vowelled form (اعراب) the studio sends to Avasho: tools/voice/spoken_fa.json,
        # else a respelling saved in the studio for the same text
        old = previous.get(line_id, {})
        spoken = SPOKEN.get(text) or (old.get("spoken") if old.get("text") == text else None)
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
    for world, name in GUARDIANS.items():
        if name:
            add("app_freed_" + world, "pilo", "%s آزاد شد! دروازه باز است." % name, 0, "app", "آزاد شدن نگهبان")

    # the opening story (data/story/intro.json), read by the narrator
    with open(os.path.join(ROOT, "data", "story", "intro.json"), encoding="utf-8") as f:
        for panel in json.load(f)["panels"]:
            add(panel["voice_id"], "narrator", panel["text"], 0, "story", "داستان آغاز بازی")

    # chapter cards (data/story/chapters.json), shown through the dialogue box
    with open(os.path.join(ROOT, "data", "story", "chapters.json"), encoding="utf-8") as f:
        for world, chapter in json.load(f).items():
            for line in chapter.get("lines", []):
                add(line["id"], line.get("who", "narrator"), line["text"], 0, "chapter", "کارت فصل " + world)

    # the opening tutorial (scripts/ui/tutorial.gd STEPS), read by Pilo
    with open(os.path.join(ROOT, "scripts", "ui", "tutorial.gd"), encoding="utf-8") as f:
        steps = re.findall(r'^\t\["(\w+)", "(.*)"\],$', f.read(), re.M)
    for n, (key, text) in enumerate(steps, 1):
        add("tutorial_%d" % n, "pilo", text, 0, "tutorial", "راهنمای شروع: " + key)

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
