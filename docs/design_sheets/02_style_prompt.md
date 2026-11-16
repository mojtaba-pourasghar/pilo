# سبک هنری ذخیره‌شده و پرامپت پایه (برای **همهٔ** طراحی‌ها)

> قاعده: **هر** پرامپت تصویر (Canva/FLUX/Gemini) باید با «پیشوند سبک» شروع شود و «پسوند ایمنی» داشته باشد. سبک از ویدئوی مرجع صاحب پروژه برداشت شده (فقط حس؛ بدون کپی). جزئیات: [00_style_lock.md](00_style_lock.md).

## پیشوند سبک (انگلیسی؛ ثابت)
```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines, soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Original design with Persian/Iranian-inspired motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15.
```
## پسوند (ثابت)
```
No text, no letters, no numbers, no labels, no watermark, no logo. Plain light neutral background for easy cut-out. Do not imitate any existing game, character or brand.
```
## قواعد ثابت
- شخصیت‌ها ۳ تا ۳٫۵ سر؛ سیلوئت مشخص؛ خط دور ضخیم تیره (`#2A1F3D`).
- گذشته: رنگ گرم‌تر و درخشان + لبهٔ آبی روشن؛ حال: رنگ خسته‌تر + لبهٔ نارنجی.
- رابط: دکمهٔ اصلی طلایی براق، دوم آبی، پنل نیلی نیمه‌شفاف، ربان و نشان.
- بدون خون/خشونت؛ بدون متن داخل تصویر.
- آرسام: [01_arsam.md](01_arsam.md) (چهره از عکس؛ عکس در مخزن نیست).

## گردش تولید با Canva
1. پرامپت = پیشوند + توضیح پارت + پسوند (ثبت در `docs/design_sheets/prompts/<id>.txt`).
2. `generate-image` ← لینک رسانه (media id) در `assets/manifest/assets.csv` ستون `note: canva=<id>`.
3. پیش‌نمایش کوچک در `docs/design_sheets/previews/`؛ **نسخهٔ کامل را صاحب پروژه از لینک Canva دانلود و در `assets/art/<پارت>/` می‌گذارد** (دسترسی دانلود کامل از این محیط ممکن نیست).
4. تأیید ← `status: final`.
