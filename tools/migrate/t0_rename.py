#!/usr/bin/env python3
"""T0 (one-off): Nima -> the hero (default name «آرسام», changeable: Names autoload), Kian removed
(the rival is now a «روح رقیب»), «تکهٔ زمان» -> «قلب زمان». Idempotent; run from the repo root."""
import glob, json, os, re, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.chdir(ROOT)


def git_mv(a, b):
    if os.path.exists(a) and not os.path.exists(b):
        subprocess.check_call(["git", "mv", a, b])


def git_rm(path):
    if os.path.exists(path):
        subprocess.check_call(["git", "rm", "-rq", path])


# --- files --------------------------------------------------------------------------
git_mv("scripts/characters/nima_rig.gd", "scripts/characters/hero_rig.gd")
git_mv("assets/characters/nima", "assets/characters/hero")
for f in sorted(glob.glob("assets/art/nima_*.png")):
    git_mv(f, f.replace("/nima_", "/hero_"))
    if os.path.exists(f + ".import"):
        git_mv(f + ".import", f.replace("/nima_", "/hero_") + ".import")
for f in glob.glob("assets/art/kian_*.png*") + glob.glob("assets/art/npc_kian.png*"):
    git_rm(f)
git_rm("assets/characters/kian")
git_rm("scripts/gameplay/rival.gd")

# --- Kian's lines: who says them now (the rival is a ghost and never speaks) -----------------
KIAN_LINES = {
    "مسابقه تا دروازهٔ زمان! هر کس زودتر برسد، برنده است.": ("pilo", "یک روح رقیب هم دنبال قلب زمان است! هر کس زودتر به دروازه برسد، برنده است."),
    "قلب زمان ساحل مال من است!": ("pilo", "مسافرهای دیگر هم دنبال قلب زمان‌اند!"),
    "مسابقهٔ دوم! این بار تا قله.": ("pilo", "مسابقهٔ روح دوم! این بار تا قله."),
    "بهمن! نیما، از این طرف!": ("pilo", "بهمن! از این طرف!"),
    "مسابقهٔ سوم... ولی دلم با مسابقه نیست.": ("pilo", "مسابقهٔ روح سوم! دنبال روح نرو؛ راه خودت را پیدا کن."),
    "در گذشتهٔ این غار... دهکدهٔ من را دیدم!": ("pilo", "در گذشتهٔ این غار... یک دهکده پیداست!"),
    "پیچ‌پیچ، با نیما برو. ما یک تیمیم.": ("pilo", "پیچ‌پیچ، با ما بیا. ما یک تیمیم."),
    "نگهبان‌ها پشت سرمان‌اند. نترس!": ("pilo", "نگهبان‌ها پشت سرمان‌اند. نترس!"),
    "دهکده‌ام... دارم صدایش را می‌شنوم!": ("pilo", "صدای ساعت وارونه را می‌شنوم! نزدیکیم."),
    "سلام! من کیانم، گنج‌یاب. تکه‌های زمان مال من‌اند؛ می‌خواهم دهکدهٔ گم‌شده‌ام را برگردانم!": ("narrator", "مسافرهای دیگر هم دنبال قلب‌های زمان‌اند. از حالا با روح رقیب مسابقه می‌دهی!"),
    "او به من دروغ گفته؟ نیما... باید با هم برویم.": ("pilo", "نقاب‌دار به خیلی‌ها دروغ گفته. باید زودتر برسیم!"),
    "همهٔ نگهبان‌ها و همراه‌ها کمک می‌کنند. برویم!": ("pilo", "همهٔ نگهبان‌ها و همراه‌ها کمک می‌کنند. برویم!"),
}
TEXT_FIX = {
    "چیزی شده کیان؟": "باشد، راه خودم!",
    "مراقب یخ‌ها باش!": "مراقب یخ‌ها باشیم!",
    "از طلسم آزادم کردید. آن پسر، کیان، فریب خورده؛ کمکش کنید.": "از طلسم آزادم کردید. مسافران دیگر هم می‌آیند؛ با آن‌ها مهربان باشید، همه دنبال چیزی هستند.",
    "من پیچ‌پیچم، جغد کیان! در تاریکی می‌بینم و از دور راز را بو می‌کشم.": "من پیچ‌پیچم! در تاریکی می‌بینم و از دور راز را بو می‌کشم.",
    "بوی دریا! کیان هم اینجاست؛ می‌خواهد زودتر از ما به قلب زمان برسد.": "بوی دریا! روح مسافران دیگر هم اینجاست؛ می‌خواهند زودتر از ما به قلب زمان برسند.",
    "کیان فهمید نقاب‌دار به او دروغ گفته. حالا با ماست!": "نقاب‌دار به خیلی‌ها دروغ گفته. ما باید راستش را پیدا کنیم!",
    "کیان قلب زمان ساحل را زودتر برداشت، ولی اختاپوس آزاد شد و لاکی به تیم پیوست.": "روح رقیب زودتر رسید، ولی اختاپوس آزاد شد و لاکی به تیم پیوست.",
    "در هرم، اولین الماس افسانه‌ای و نقش یک نقاب‌دار پیدا شد. کیان ساکت ماند.": "در هرم، اولین الماس افسانه‌ای و نقش یک نقاب‌دار پیدا شد.",
    "بهمن نیما و کیان را با هم گیر انداخت و با هم فرار کردند. غبارک اعتراف کرد: نقاب‌دار فریبش داده بود.": "بهمن آمد و همه با هم فرار کردند. غبارک اعتراف کرد: نقاب‌دار فریبش داده بود.",
    "عقاب طوفان آزاد شد و نقشهٔ قلعهٔ سایه را داد. ولی در غارها، کیان پیام تازه‌ای از نقاب‌دار گرفت.": "عقاب طوفان آزاد شد و نقشهٔ قلعهٔ سایه را داد. ولی در غارها، کلاغ‌ساعت پیام تازه‌ای از نقاب‌دار آورد.",
    "کیان، تکه‌ها را برایم بیاور... وگرنه دهکده‌ات را هرگز نمی‌بینی.": "کلاغ‌ساعت، قلب‌ها را برایم بیاور...",
    "کیان و جغدش پیچ‌پیچ به تیم پیوستند. در گذشتهٔ غار، دهکدهٔ کیان دیده شد؛ هنوز می‌شود نجاتش داد.": "جغد پیچ‌پیچ به تیم پیوست. در گذشتهٔ غار، دهکدهٔ سبزدره دیده شد؛ هنوز می‌شود نجاتش داد.",
    "ساعت وارونه را می‌شکنیم و دهکدهٔ کیان را برمی‌گردانیم.": "ساعت وارونه را می‌شکنیم و سبزدره را برمی‌گردانیم.",
    "مسابقه با کیان! زودتر به دروازه برس.": "مسابقه با روح رقیب! زودتر به دروازه برس.",
    "کیان زودتر به دروازه رسید! باز هم می‌شود کلید را پیدا کرد.": "روح رقیب زودتر رسید! باز هم می‌شود کلیدها را پیدا کرد.",
    "کیان زودتر به دروازه رسید! بازهم می‌شود کلید را پیدا کرد.": "روح رقیب زودتر رسید! باز هم می‌شود کلیدها را پیدا کرد.",
    "تو از کیان زودتر رسیدی! پنجاه سکه جایزه.": "از روح رقیب زودتر رسیدی! پنجاه سکه جایزه.",
    "تو از کیان زودتر رسیدی! ۵۰ سکه جایزه.": "از روح رقیب زودتر رسیدی! ۵۰ سکه جایزه.",
    "شروع مسابقه با کیان": "شروع مسابقهٔ روح", "کیان برد": "روح رقیب برد", "نیما برد": "قهرمان برد",
    "رقیب نیما؛ مغرور ولی ته دلش خوب": "",
}


def fix_text(t: str) -> str:
    t = TEXT_FIX.get(t, t)
    t = t.replace("تکه‌های زمان", "قلب‌های زمان").replace("تکهٔ زمان", "قلب زمان").replace("تکه‌ی زمان", "قلب زمان")
    # the hero's name is the player's choice: {hero} is filled in by Names.fmt() at display time
    t = re.sub(r"نیما(?=[\s،!؟.?:؛»\"]|$)", "{hero}", t)
    t = t.replace("نیما", "{hero}")
    return t


def fix_line(line):
    if not isinstance(line, dict):
        return line
    text = line.get("text", "")
    if line.get("who") == "kian" or text in KIAN_LINES:
        who, new = KIAN_LINES.get(text, ("pilo", fix_text(text)))
        line["who"], line["text"] = who, new
    if line.get("who") == "nima":
        line["who"] = "hero"
    if "text" in line:
        line["text"] = fix_text(line["text"])
    return line


def walk(obj):
    if isinstance(obj, dict):
        if "who" in obj or "text" in obj:
            fix_line(obj)
        for k in list(obj):
            if k == "race" and obj[k] == "kian":
                obj[k] = "ghost"
            elif isinstance(obj[k], str):
                obj[k] = fix_text(obj[k])
            else:
                walk(obj[k])
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            if isinstance(v, str):
                obj[i] = fix_text(v)
            else:
                walk(v)


for path in sorted(glob.glob("data/levels/*/level_*.json")) + ["data/story/chapters.json", "data/story/intro.json"]:
    data = json.load(open(path, encoding="utf-8"))
    walk(data)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")

# --- voice: lines whose recording said the old name (or was Kian's) must be re-recorded ---------
vpath = "data/voice/voice_lines.json"
voice = json.load(open(vpath, encoding="utf-8"))
voice["characters"].pop("kian", None)
if "nima" in voice["characters"]:
    hero = voice["characters"].pop("nima")
    hero.update({"name": "قهرمان", "about": "قهرمان ۱۲ ساله (پیش‌فرض آرسام؛ نامش قابل‌تغییر و هرگز گفته نمی‌شود)"})
    voice["characters"]["hero"] = hero
for line in voice["lines"]:
    old = line.get("text", "")
    stale = "نیما" in old or "کیان" in old or line.get("who") == "kian" or "تکه" in old
    fix_line(line)
    if stale:
        line["stale_audio"] = True      # the clip says the old name: AudioManager never plays it
        line.pop("spoken", None)
with open(vpath, "w", encoding="utf-8") as f:
    json.dump(voice, f, ensure_ascii=False, indent=1)
    f.write("\n")

# --- source code -------------------------------------------------------------------------
CODE_SUBS = [
    (r"\bNimaRig\b", "HeroRig"), (r"nima_rig\.gd", "hero_rig.gd"), (r"assets/characters/nima/", "assets/characters/hero/"),
    (r'"nima_', '"hero_'), (r"\bnima_", "hero_"), (r'"nima"', '"hero"'), (r"'nima'", "'hero'"),
    (r"\bNima's\b", "the hero's"), (r"\bNima\b", "the hero"), (r"\bKian's\b", "the ghost rival's"), (r"\bKian\b", "the ghost rival"),
]
files = [f for pat in ("scripts/**/*.gd", "tests/*.gd", "tools/*.gd", "scenes/**/*.tscn", "tools/levels/*.py",
                       "tools/voice/*.py", "tools/art/*.py", "tools/art/*.json", "assets/art/frame_anchors.json",
                       "assets/characters/hero/rig.json", "tools/voice/spoken_fa.json")
         for f in glob.glob(pat, recursive=True)]
for path in files:
    src = open(path, encoding="utf-8").read()
    out = src
    for a, b in CODE_SUBS:
        out = re.sub(a, b, out)
    for a, b in sorted(TEXT_FIX.items(), key=lambda kv: -len(kv[0])):
        if b:
            out = out.replace(a, b)
    for a, (_who, b) in KIAN_LINES.items():
        out = out.replace('("kian", "%s")' % a, '("pilo", "%s")' % b)
    out = out.replace('("nima", ', '("hero", ').replace("تکهٔ زمان", "قلب زمان").replace("تکه‌های زمان", "قلب‌های زمان")
    if out != src:
        open(path, "w", encoding="utf-8").write(out)
print("t0 done")
