#!/usr/bin/env python3
"""
فیلم‌نامهٔ ضبط صدای شخصیت‌ها را از data/voice/voice_lines.json می‌سازد:

    python3 tools/voice/make_recording_script.py

خروجی:
  docs/voice/RECORDING_SCRIPT.md   برای گوینده‌ها و کارگردان صدا (به تفکیک شخصیت، با راهنمای لحن)
  docs/voice/recording_list.csv    برای استودیو: شناسه، نام فایل، شخصیت، متن، رویداد، وضعیت

منبع حقیقت همان JSON است (که خودش از فایل مرحله‌ها ساخته می‌شود)؛ این فایل‌ها را دستی ویرایش نکنید.
"""
import csv
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, "data", "voice", "voice_lines.json")
OUT = os.path.join(ROOT, "docs", "voice")
RECORDED = os.path.join(ROOT, "assets", "audio", "voice")

TONE = {
    "nima": "پسربچهٔ کنجکاو و پرانرژی؛ طبیعی و صمیمی، با تعجب واقعی. معمولاً یک بانوی گوینده یا کودک گوینده.",
    "pilo": "گرم، شاد و دلگرم‌کننده؛ کمی آهسته‌تر از گفت‌وگوی عادی تا کودک ۵ ساله هم بفهمد. "
            "راهنمایی‌ها را مثل یک دوست بگویید، نه مثل معلم؛ هرگز جواب معما را با تأکید لو ندهید.",
    "ghubarak": "شیطون و خنده‌رو، با کمی دستپاچگی؛ ابداً ترسناک یا شرور نه. عذرخواهی آخر صادقانه.",
    "squirrel": "زیر و تند، هیجان‌زده و قدردان.",
}


def main():
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    lines = data["lines"]
    chars = data.get("characters", {})
    recorded = set(os.listdir(RECORDED)) if os.path.isdir(RECORDED) else set()
    tts_path = os.path.join(OUT, "tts_generated.json")
    tts = set()
    if os.path.exists(tts_path):
        with open(tts_path, encoding="utf-8") as f:
            tts = {k + ".mp3" for k in json.load(f).get("files", {})}
    os.makedirs(OUT, exist_ok=True)

    fmt = data.get("format", {})
    md = [
        "# فیلم‌نامهٔ ضبط صدای «سفر پیلو»",
        "",
        "> این فایل خودکار از `data/voice/voice_lines.json` ساخته می‌شود "
        "(`python3 tools/voice/make_recording_script.py`). متن‌ها را در فایل مرحله‌ها اصلاح کنید و "
        "`python3 tools/voice/build_voice_lines.py` را بزنید.",
        "",
        "## مخاطب",
        "",
        "کودکان ۵ تا ۹ سال. جمله‌ها کوتاه‌اند؛ واضح و شمرده بخوانید، با مکث کوتاه بعد از هر جمله. "
        "فارسی معیار و روشن، بدون لهجهٔ غلیظ.",
        "",
        "## مشخصات فنی",
        "",
        "- هر جمله یک فایل جدا، با **دقیقاً** همان نام ستون «فایل».",
        "- ضبط: WAV، ۴۸ کیلوهرتز، ۲۴ بیت، مونو، اتاق بی‌پژواک، فاصلهٔ ثابت از میکروفون.",
        "- تحویل نهایی را اسکریپت `tools/voice/import_recordings.sh` خودش می‌سازد: MP3 مونو %s kbps، "
        "بلندی %s LUFS، %s میلی‌ثانیه سکوت اول و %s میلی‌ثانیه آخر."
        % (fmt.get("bitrateKbps", 96), fmt.get("loudnessLufs", -16),
           fmt.get("silenceMs", {}).get("head", 80), fmt.get("silenceMs", {}).get("tail", 150)),
        "- از هر جمله دو برداشت ضبط کنید؛ بهترین را با همان نام تحویل دهید.",
        "",
        "تعداد کل جمله‌ها: **%d**" % len(lines),
        "",
    ]
    for who, meta in chars.items():
        items = [l for l in lines if l["who"] == who]
        if not items:
            continue
        md += ["## %s — %d جمله" % (meta.get("name", who), len(items)), "",
               "*شخصیت:* %s" % meta.get("about", ""), "", "*لحن:* %s" % TONE.get(who, ""), "",
               "| # | فایل | متن | کجا پخش می‌شود |", "|---|---|---|---|"]
        for i, l in enumerate(items, 1):
            md.append("| %d | `%s` | %s | %s |" % (i, os.path.basename(l["file"]), l["text"], l.get("event", "")))
        md.append("")

    with open(os.path.join(OUT, "RECORDING_SCRIPT.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md))

    with open(os.path.join(OUT, "recording_list.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "file", "who", "text", "event", "recorded"])  # recorded: yes | tts | no
        for l in lines:
            name = os.path.basename(l["file"])
            w.writerow([l["id"], name, l["who"], l["text"], l.get("event", ""),
                        "tts" if name in tts and name in recorded else ("yes" if name in recorded else "no")])

    names = [os.path.basename(l["file"]) for l in lines]
    print("%d lines -> docs/voice/RECORDING_SCRIPT.md, docs/voice/recording_list.csv "
          "(%d recorded, %d temporary TTS)"
          % (len(lines), len([n for n in names if n in recorded and n not in tts]),
             len([n for n in names if n in recorded and n in tts])))


if __name__ == "__main__":
    main()
