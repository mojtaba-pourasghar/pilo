# تحویل از مدیر پروژه به Claude Code — فاز طراحی فصل ۱ تمام شد (۱۸ نوامبر ۲۰۲۶)

**همهٔ ۱۱ پارت فصل ۱ به‌صورت draft در `assets/art/p1…p11` است و تأییدشده (قاعدهٔ ۱۶ نوامبر CLAUDE.md).** فهرست و نام فایل‌ها: `docs/design_sheets/CONCEPT_SPRITES.md`، `SCREEN_DESIGNS.md`، `CANVA_LINKS.md`؛ قفل سبک و شخصیت‌ها: `docs/design_sheets/04_style_lock_and_character_bible.md`؛ مشخصات رندر Godot: `03_approval_and_godot_art_spec.md`؛ دارایی‌ها: `assets/manifest/assets.csv`، اطلس: `tools/art/pack_atlas.py`.

## گام بعدی شما (به‌ترتیب BUILD_BRIEF §۲)
1. **T0** — تغییر نام نیما←آرسام (~۹۴۵ مورد؛ `nima_rig.gd`، `dialogue_box.gd`، `rig_icon.gd`، `painted_rig.gd` و…)، حذف کیان (`rival.gd`، `game.gd` مسابقهٔ `race:"kian"` در ~۱۰ مرحله، `who:"kian"` در دیالوگ‌ها، `voice_lines.json`) و جایگزینی با «روح رقیب»، نام پروژه در `project.godot`، autoload `Names`.
2. سپس T3 (دو لایه + لنز) ← T4 ← T5 ← T6 (K1 از `assets/art/p5_enemies/k1/`) ← T7 (خرس از `assets/art/p5_enemies/bear/`، Skeleton2D) ← T8 (فصل ۱؛ صحنهٔ استوری از `p11_story/panels/`).

## نکتهٔ مهم
نشست مدیر پروژه **Godot ندارد** (نه نصب، نه شبکه)، پس هیچ تغییری در `scripts/` یا `data/` داده نشد (آزمون‌ها قابل‌اجرا نبود؛ قاعدهٔ «فقط با آزمون سبز پوش کن»). T0 را باید جایی اجرا کنید که `godot --headless` و `python3 tests/validate_levels.py` در دسترس باشد.

## محدودیت‌های هنری که در بازی باید رسیدگی شود
- «حال» = همان هندسهٔ «گذشته» + شیدر (کاهش اشباع/مه/لبهٔ نارنجی)، نه تصویر جدا.
- هاب: معماری کمی اروپایی؛ با کاشی/طاق ایرانی روی ماسک تقویت شود.
- K1/خرس: خط قهوه‌ای نازک؛ اگر ناهماهنگ دیده شد در ART_REQUESTS ثبت کنید.
- `bear_smoke_2` یک تکهٔ اضافه دارد؛ پاک شود. حاشیهٔ گوهٔ سفید پشت کمان در چند فریم دویدن.
