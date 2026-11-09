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
import re
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "voice", "voice_lines.json")

# Every speaker: name, who they are, the TTS voice, a short acting tag (newer models take it as
# "[tag] line") and a longer acting note (older model) — tools/voice/gemini_tts.py --lines.
CHARACTERS = {
    "narrator": {"name": "راوی", "about": "قصه‌گوی گرم و مهربان", "voice": "Sulafat", "tag": "warm, gentle storyteller",
                 "style": "a warm, gentle, expressive storyteller for young children, natural pace"},
    "nima": {"name": "نیما", "about": "پسر ماجراجوی ۸ ساله؛ کنجکاو، مهربان و پرانرژی", "voice": "Leda", "tag": "excited, curious young boy",
             "style": "a brave, curious, excited 8-year-old boy, bright and energetic"},
    "pilo": {"name": "پیلو", "about": "همراه کوچک و بامزهٔ نیما؛ گرم، شاد و راهنما (جواب را لو نمی‌دهد)", "voice": "Laomedeia", "tag": "cheerful, bouncy, cute",
             "style": "a tiny cute magical creature, warm, cheerful and encouraging, a little high and bouncy"},
    "ghubarak": {"name": "غبارک", "about": "موجود غباری بازیگوش؛ شیطون و خنده‌رو، اصلاً ترسناک نیست", "voice": "Puck", "tag": "mischievous, giggly",
                 "style": "a mischievous giggly little dust sprite, playful and teasing, never scary"},
    "squirrel": {"name": "سنجابک", "about": "سنجاب کوچولو و تند‌حرف؛ هیجان‌زده و قدردان", "voice": "Sadachbia", "tag": "fast, very excited",
                 "style": "a tiny squirrel who talks fast, very excited and thankful"},
    "kian": {"name": "کیان", "about": "رقیب نیما؛ مغرور ولی ته دلش خوب", "voice": "Fenrir", "tag": "proud, cocky boy",
             "style": "a proud, competitive boy showing off, cocky but not mean"},
    "grandpa": {"name": "بابابزرگ ساعت‌ساز", "about": "ساعت‌ساز پیر و مهربان", "voice": "Algenib", "tag": "kind, wise old man",
                "style": "a kind, wise old clockmaker grandpa, slow and warm"},
    "grandma": {"name": "مادربزرگ کاکتوس", "about": "کاکتوس پیر و مهربان بیابان", "voice": "Vindemiatrix", "tag": "sweet, gentle old lady",
                "style": "a sweet, gentle old grandmother, soft and kind"},
    "captain": {"name": "ناخدا موج", "about": "ناخدای خوش‌خندهٔ ساحل", "voice": "Rasalgethi", "tag": "jolly, hearty",
                "style": "a jolly hearty sea captain, loud and friendly"},
    "zurvan": {"name": "زروان", "about": "جادوگر زمان؛ مرموز", "voice": "Iapetus", "tag": "mysterious, calm, low",
               "style": "a mysterious calm sorcerer, low and slow, a little spooky but not frightening for kids"},
    "masked": {"name": "نقاب‌دار", "about": "آدم نقاب‌دار مرموز", "voice": "Umbriel", "tag": "quiet, secretive",
               "style": "a mysterious masked figure, quiet and secretive, not frightening for kids"},
    "shadow_king": {"name": "شاه‌سایه", "about": "پادشاه سایه‌ها", "voice": "Alnilam", "tag": "grand, dramatic, deep",
                    "style": "a grand, proud shadow king, deep and dramatic, cartoonish, not frightening for kids"},
    "bear": {"name": "خرس پیر جنگل", "about": "نگهبان جنگل", "voice": "Orus", "tag": "deep, slow, grateful", "style": "a big old gentle bear, deep, slow and grateful"},
    "octopus": {"name": "اختاپوس بزرگ", "about": "نگهبان ساحل", "voice": "Aoede", "tag": "kind, relieved", "style": "a kind giant octopus, flowing and relieved"},
    "worm": {"name": "کرم شنی", "about": "نگهبان بیابان", "voice": "Enceladus", "tag": "slow, breathy, wise", "style": "a huge sand worm, breathy, slow and wise"},
    "yeti": {"name": "غول یخی", "about": "نگهبان کوهستان", "voice": "Schedar", "tag": "deep, slow, friendly", "style": "a big friendly snow giant, deep and slow"},
    "eagle": {"name": "عقاب طوفان", "about": "نگهبان آسمان", "voice": "Kore", "tag": "proud, noble", "style": "a proud noble storm eagle, clear and firm"},
    "spider": {"name": "عنکبوت بلورین", "about": "نگهبان غارها", "voice": "Erinome", "tag": "soft, mysterious, kind", "style": "a crystal spider, soft and mysterious, kind"},
    "turtle": {"name": "لاکی", "about": "لاک‌پشت همراه", "voice": "Achird", "tag": "calm, happy", "style": "a friendly calm little turtle, happy"},
    "mole": {"name": "خال‌خالی", "about": "موش‌کور همراه", "voice": "Zubenelgenubi", "tag": "cheerful, funny", "style": "a cheerful little mole, casual and funny"},
    "penguin": {"name": "یخک", "about": "پنگوئن همراه", "voice": "Despina", "tag": "bubbly, cheerful", "style": "a bubbly little penguin, cheerful"},
    "butterfly": {"name": "پَرپَری", "about": "پروانهٔ همراه", "voice": "Pulcherrima", "tag": "airy, dreamy, sweet", "style": "a light dreamy butterfly, airy and sweet"},
    "owl": {"name": "پیچ‌پیچ", "about": "جغد کیان", "voice": "Algieba", "tag": "wise, calm", "style": "a wise friendly owl, smooth and calm"},
    "spark": {"name": "جرقه", "about": "جرقهٔ همراه", "voice": "Zephyr", "tag": "lively, quick", "style": "a lively little spark, quick and bright"},
    "dragon": {"name": "اژدهاک", "about": "اژدهای کوچک همراه", "voice": "Sadaltager", "tag": "playful, proud", "style": "a playful little baby dragon, proud and happy"},
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
    for world, name in GUARDIANS.items():
        if name:
            add("app_freed_" + world, "pilo", "%s آزاد شد! دروازه باز است." % name, 0, "app", "آزاد شدن نگهبان")

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
