# سفر پیلو — راهنمای کار روی پروژه

## قانون طراحی (از طرف صاحب پروژه)

صاحب پروژه **قبل از پیاده‌سازی، طرح هر صفحه را خودش طراحی می‌کند و تصویرش را می‌دهد.**
انتظار این است که **عین همان طرح** پیاده شود:

- همان چیدمان و جای دقیق عناصر (چپ/راست/بالا/پایین)، همان اندازه‌ها و تناسب‌ها.
- همان رنگ‌ها و همان سبک عناصر (مثلاً دکمه‌های شیشه‌ای/براق، قاب‌ها، ربان‌ها، آیکون‌ها).
- همان متن‌ها و همان ترتیب گزینه‌ها.
- کیفیت در حد محصول قابل فروش؛ استفاده از جایگزین تخت، ساده یا «موقت» به‌جای طرح، قابل قبول نیست.
- طرح را بازطراحی یا «بهتر» نکن. اگر بخشی از طرح با یک محدودیت فنی یا قانون محصول تضاد دارد،
  نزدیک‌ترین نسخهٔ وفادار را بساز و صریحاً گزارش بده و بپرس.
- قبل از تحویل، از صفحهٔ ساخته‌شده اسکرین‌شات بگیر و کنار تصویر طرح مقایسه کن.

## Design rule (from the project owner)

The owner designs every screen in advance and supplies the image. Implement **exactly that
design**: same layout and positions, sizes and proportions, colors, element style (e.g. glossy
glass buttons), texts and option order, at sellable quality. Do not redesign, simplify or ship
flat placeholders. If something in the design conflicts with a technical or product rule, build
the closest faithful version, say so explicitly and ask. Compare a screenshot of the result
side by side with the design before handing it over.

- طرح‌های مرجع: `assets/reference/` (منوها: `ui_menus_design.webp`).
- هنر رابط کاربری با `python3 tools/ui_art.py .` ساخته می‌شود؛ اسکرین‌شات با `tools/screenshot.tscn` (README).
- قبل از commit: `python3 tests/validate_levels.py` و `godot --headless --path . res://tests/test_runner.tscn`.
- صدای شخصیت‌ها: دیالوگ را در فایل مرحله بنویس، بعد `python3 tools/voice/build_voice_lines.py` و
  `python3 tools/voice/make_recording_script.py`. صدا با استودیوی `tools/voice-studio` (آواشو، هر شخصیت صدای خودش) ساخته می‌شود؛
  ضبط انسانی (فایل‌های خارج از `docs/voice/tts_generated.json`) هرگز بازنویسی نشود.
- صدای محیط: ضبط واقعی از Commons با `tools/audio/fetch_ambience.py` (منبع و مجوز در `docs/audio/sound_sources.json`)،
  وگرنه با `tools/audio/synth_ambience.py`؛ بقیهٔ جلوه‌ها با `tools/audio.py`.
