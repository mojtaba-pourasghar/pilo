# بستهٔ کامل طراحی (۲۳ نوامبر ۲۰۲۶) — همهٔ تصویرهای باقی‌مانده

> **برای مالک پروژه:** هر «برگه» یک تصویر است که با پرامپتش می‌سازید و برمی‌گردانید؛ من برش و اطلس را انجام می‌دهم.
> **وضعیت:** پیشنهاد برای تأیید. هیچ‌چیز ساخته یا وارد بازی نمی‌شود مگر با تأیید شما (CLAUDE.md).
> فایل‌ها: `01` قهرمان‌ها و همراهان · `02` دشمن‌ها و غول‌ها · `03` ابزار، ارتقا و افکت · `04` پس‌زمینه‌ها · `05` منو، داستان و رابط · `06` همترازی جفت ۱ با ویدئوهای مرجع (**اول این را ببینید**).

## ۰. تصمیم‌هایی که از شما می‌خواهم (قبل از تولید)
| # | سؤال | پیشنهاد من |
|---|---|---|
| D1 | **همراهان:** گفتید همراهان فعلی به درد نمی‌خورند. من فهرست نو ساختم (`01` §۳): ۶ خانواده، هر کدام یک **کار گیم‌پلی یکتا**. فقط **Tikkit** می‌ماند (در داستان جفت ۱ و کشیده‌شده است). Embrix/Verdlin/Rippa/Zephyk/Gemmo کنار می‌روند (Verdlin فقط شکل آزادشدهٔ Stumpguard می‌ماند). | تأیید یا تغییر |
| D2 | **نام ۱۰ قهرمان دیگر:** نام‌های فارسی فهرست قدیم با قاعدهٔ «غیرفارسی» نمی‌خواند؛ نام انگلیسی پیشنهاد دادم (`01` §۲). | تأیید یا تغییر |
| D3 | **قدیم برای فصل‌های ۲–۱۵:** قاعدهٔ ۲ می‌گوید همیشه پدربزرگ جوان. فرض من همین است؛ ۱۰ قهرمان دیگر فقط در «جدید» بازی می‌شوند. | تأیید |
| D4 | دشمنان فصل ۲–۱۵ را به قالب «مسخ‌شدهٔ یک Auraling کوچک» تبدیل کردم (`02`). | تأیید |

## ۱. قواعد ثابت هر پرامپت
**پیشوند سبک (اول هر پرامپت):**
```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Original design with Persian/Iranian-inspired motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15.
```
**پسوند صورتی (آخر هر برگهٔ برش‌خور؛ بخش‌هایی که جدا می‌کنم):**
```
Solid flat pure magenta background #FF00FF, perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta. Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. Each item has a closed thick dark-navy outline. Flat even lighting, orthographic side view unless stated. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```
**پسوند «بدون برش»** (فقط برای صحنه/پس‌زمینهٔ کامل): همان «No text…» بدون بند مجنتا.
**اندازه:** ≥ ۲۷۲۰×۱۵۳۶ برای برگه‌ها (مثل برگه‌های قبلی). **نام فایل:** `<شناسه>.png` در `assets/art/pair1_sheets/` (برگه‌های جفت ۱) یا `assets/art/sheets/` (بقیه).
**چیدمان خانه‌ها:** «سطر ۱ چپ→راست، سطر ۲…» همیشه در جدول زیر هر برگه آمده؛ **چیزی روی تصویر نوشته نشود** (جدول من نقش خانه‌ها را می‌گوید).
**رنگ ممنوع برای خود طرح:** صورتی/سرخابی (قلب بلورین، گل و … رنگ دیگر بگیرند: کهربایی، قرمز، نارنجی).

## ۲. اولویت
- **P0** = لازم برای تمام کردن جفت ۱ (دستور ساخت فعلی؛ **اول اینها**).
- **P1** = بقیهٔ فصل ۱ (جفت ۲ تا ۶ + Antlerion).
- **P2** = فصل ۲ تا ۱۵ و ۱۰ قهرمان دیگر.

## ۳. فهرست کل و شمارش
| فایل | بخش | P0 | P1 | P2 | جمع |
|---|---|---|---|---|---|
| `01` | قهرمان‌ها (۱۳) و همراهان (۶ خانواده) | ۴ | ۱۳ | ۳۳ | ۵۰ |
| `02` | دشمن‌ها، پاسدارها (K1–K12)، غول‌ها، NPC | ۰ | ۱۰ | ۶۸ | ۷۸ |
| `03` | ابزار/ارتقا هر قهرمان، حرکت‌های همراه، افکت | ۶ | ۶ | ۱۹ | ۳۱ |
| `04` | پس‌زمینه‌ها (۳ تصویر هر دنیا) و کاشی‌ها | ۵ | ۳۱ | ۹۸ | ۱۳۴ |
| `05` | منو، داستان‌سرایی، آیکون، رابط | ۶ | ۱۵ | ۲۸ | ۴۹ |
| `06` | **همترازی جفت ۱ با دو ویدئوی مرجع** | ۷ | ۰ | ۰ | ۷ |
| | **جمع** | **۲۸** | **۷۵** | **۲۴۶** | **۳۴۹** |

> عدد بزرگ است؛ **هر P را جدا تحویل بدهید**. P0 (۲۸ تصویر) برای بستن جفت ۱ کافی است.

## ۴. آنچه از قبل داریم (تکراری نخواهید)
`g2_arsam_parts` · `g2_arsam_hands_hair_v1` · `g2_grandfather_parts` · `g2_tikkit_evolution_v1/v2` · `g2_tikkit_extra_states_v1` · `g2_enemies_new` (Murkling، Stiltmurk، Nimbeak، Rootstomp، Stumpguard ۳ حالت، Verdlin نوزاد) · `g2_enemies_old` (Murkwisp، Cindrel، Clockcrow ×۳) · `g2_rootstomp_v1` · `g2_barkshield_v1` · `g2_freed_forms_v1` · `g3_bg_*` / `bg_*_v3` (دو نوار دشت) · `g4_fx_sheet` · ۷ منوی G5 v3.
