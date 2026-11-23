# ۰۶ — همترازی جفت ۱ (قدیم ۱ + جدید ۱) با دو ویدئوی مرجع (۲۳ نوامبر ۲۰۲۶)

> مرجع: `video_2026-11-23_09-57-27.mp4` (جنگل و ویرانه‌ها، ۳:۰۷) و `…09-57-37.mp4` (سیاه‌چالِ تاریک، منوها، نقشه، ۴:۰۰). فقط **حس و سازوکار** توصیف شده؛ هیچ طرح، شخصیت یا نامی کپی نمی‌شود (قاعدهٔ ۹).
> نتیجه در `docs/33` §۱۱ به سناریو افزوده شد. این فایل: (آ) آنچه ویدئو نشان می‌دهد، (ب) آیا قبلاً در سناریو بود، (پ) هنر لازم.

## ۱. آنچه در ویدئوها دیدم → وضعیت در سناریو
| # | ویژگی ویدئو | در `docs/33` بود؟ | اقدام |
|---|---|---|---|
| ۱ | **پیش‌پردهٔ هر مرحله:** صحنهٔ غروب/طلوع گرم، گل/لانه، افق با قلعه‌ای دور، سپس نوشتهٔ «بکش و شروع کن» با دست اشاره‌گر | نیمه (A0/B0 ورود دوربین؛ بدون «کشیدن برای شروع») | **اضافه شد** A0/B0 + رشتهٔ `start_swipe` |
| ۲ | **زمین منحنی و نرم** (تپه‌های موج‌دار، شیب، لبهٔ چمن، گذر بی‌درز)؛ نه کاشی تخت | نه (فقط «تپه‌های ملایم») | **اضافه شد:** قاعدهٔ زمین منحنی (§۱۱٫۲) + کیت هنر `TS01c` |
| ۳ | **تاب طنابی** (سکوی آویز، پاندول) و **ریسمان/پیچک** | نه | **اضافه شد** تاب در قدیم ۱ (A6 بالا) و جدید ۱ (B3/B6) |
| ۴ | **«نگه‌دار تا شناور شوی»** (سر خوردن در هوا) | آرسام شال دارد؛ آموزش نبود | **اضافه شد** آموزش شناوری B1 |
| ۵ | **ردیف جمع‌کردنی** (تخم‌های طلایی روی قوس/مارپیچ/روی تنه) و بخش‌های مخفی پشت برگ‌ها | نیمه («سکه‌ها») | **اضافه شد:** مسیرهای قوسی + «قطرهٔ شبنم طلایی» (§۱۱٫۴) |
| ۶ | **عمق چندلایه:** مه آبی-سبز دور، برج و ویرانهٔ ساختاری، پرتو نور، **سیلوئت تیره و برگ جلوی دوربین** | بله (۶–۷ لایه) ولی بدون «قاب برگ» و برج‌های دور | **اضافه شد** لایه ۷ = قاب برگ، §۱۱٫۵ + هنر `LEAF` |
| ۷ | **همراه** که دنبال می‌کند، جست‌وخیز می‌کند، شادی نشان می‌دهد | بله (Tikkit) | تقویت: رفتار «پیش‌رو/عقب‌مانده/جمع‌کننده» §۱۱٫۶ |
| ۸ | **سیاه‌چال تاریک آبی:** **تیرهای چرخان صلیبی** با سرِ میخ‌دار روی چرخ بزرگ؛ **شفت عمودی** و دیوارپرش؛ تار عنکبوت؛ زنجیر؛ فلش قرمز راهنما | نه | **اضافه شد** B6 «برج ویران» با تیر چرخان آرام، شفت، تار دودی (بدون استخوان: سن ۸–۱۵) |
| ۹ | **HUD:** شمارندهٔ مسافت + نوار توان کوتاه، دکمهٔ تکرار و مکث | نیمه (ساعت جیبی) | تأیید همین؛ نوار «Chrono Spark» اضافه §۱۱٫۷ |
| ۱۰ | **صفحهٔ نتیجه:** عدد بزرگ، همراه شاد، «بعدی»؛ **نقشه** با مسیر خط‌چین قرمز بین برج‌ها، تخم انتهای مسیر | بله (G5 v3) | بدون تغییر |
| ۱۱ | **جوجه‌کشی:** تخم روی پایه در اتاق گرم با نور؛ پنجره‌های گرد | بله (کات‌سین تفریخ) | هنر `INCUB` در فایل ۰۵ (P1) |
| ۱۲ | منوی دستاوردها/پروفایل/فروشگاه/«انرژی نداری» با قاب چوبی-کاغذی | G5 و ۰۵ | همین‌ها |

## ۲. هنر جدید P0 برای جفت ۱ (۷ تصویر)
### R1 — `TS01c`: کیت زمین منحنی و اشیای مسیر
```
{سبک} Organic curved ground and path-objects kit for a side-scrolling forest-meadow platformer, in two rows (top: warm golden "old era", bottom: cool teal "new era with violet smoke"). Items separated on flat magenta: rolling-hill ground chunks in several lengths (gentle upslope, downslope, hill crest, valley dip, flat) each with a lush grass lip and soil body; ground ledge with overhang; stone ruin arch (two sizes); broken mossy stone pillar; rope swing platform (thin plank hanging from two ropes) in 2 sizes; hanging vine; wooden hint signpost with a plain arrow (no text) in two directions; mossy stone wall segment with ledges for wall-jumping; gap edges (crumbling); golden dew-drop collectible in 4 sizes plus a coin-trail arc and a spiral trail of dew-drops; small seed-coin; hidden-alcove leaf curtain. Thick dark navy outlines, no text, no pink in objects.
```
### R2 — `w1n-I` (۳ تصویر): داخل «برج ویران» جدید ۱ (B6)
```
S: {سبک} Seamless horizontal interior background layers 1-2 of a ruined clock-tower interior: deep teal-blue stone wall with arched windows letting in soft god rays, distant dusty stairs, faint smoke haze. No pink.
M: three stacked layers on magenta: crossbeam wheels (large dark wooden wheel disks) and stone columns; chain curtain and dusty cobweb-smoke veils; mid stone arches.
F: six separate set-pieces on magenta: rotating plus-shaped wooden crossbeam assembly with metal end caps (hub, beam, end cap each separate), broken clock gears pile, hanging chain, crate stack, crumbling stone ledge, lantern bracket; plus dark navy leaf/stalk foreground silhouette strip.
```
### R3 — `INTRO1o`, `INTRO1n`: ۳ فریم پیش‌پردهٔ هر مرحله (کامل، بدون صورتی)
- **قدیم:** (۱) غنچهٔ گل در طلوع که باز می‌شود و قطرهٔ شبنم می‌افتد؛ (۲) پدربزرگ خفته روی تپه با شال؛ (۳) افق با **قلعه‌ای دور** در مه و پرتو.
- **جدید:** (۱) همان گل، پژمرده و دودی؛ (۲) لانهٔ شاخه با تخم تیره در دود؛ (۳) افق خنک با ویرانهٔ برج و ابر بنفش.
```
{سبک} Three cinematic key frames, warm sunrise: (1) a white flower bud opening on a green stem with a falling dewdrop over layered misty forest; (2) {…}; (3) {…}. Painterly depth, god rays, no characters except where stated, no text. (No pink.)
```
### R4 — `LEAF`: سیلوئت‌های جلوی دوربین (P0)
۴ سیلوئت برگ/ساقه/شاخه در گوشهٔ بالا-چپ، بالا-راست، پایین-چپ، پایین-راست + ۳ سیلوئت تک‌برگ بزرگ، همگی سرمه‌ای تیره، روی صورتی.
```
Dark navy foreground leaf and branch silhouettes meant as screen-corner overlays: four corner pieces (top-left, top-right, bottom-left, bottom-right) with big leaves and thin stalks, plus three single large leaf silhouettes, all solid dark navy with subtle rim light, on flat magenta, no text.
```
> **P0 این فایل:** R1 + R2×۳ + R3×۲ + R4 = **۷ تصویر**.
