# مشخصات فنی Godot (نسخهٔ ۴)

> مخاطب: Claude Code. **موتور فعلی (v3) کار می‌کند و باید تکامل پیدا کند، نه از صفر نوشته شود.** هر بخش مشخص می‌کند «موجود» است یا «جدید». ترتیب کار در [BUILD_BRIEF.md](BUILD_BRIEF.md).

## ۰. ثابت‌ها

| مورد | مقدار |
|---|---|
| موتور | Godot 4.3، GDScript، GL Compatibility |
| رزولوشن | ۱۲۸۰×۷۲۰، افقی، `stretch=canvas_items`, `aspect=expand` (موجود) |
| فونت | Vazirmatn (موجود)؛ نامزدها و تصمیم در [16](16_typography_and_screens.md) |
| جهت متن | راست‌به‌چپ؛ همه متن‌ها از `data/strings_fa.json` (جدید؛ کلید `c{فصل}_l{مرحله}_{nn}`) |
| بدنهٔ بازیکن | `BODY_SIZE=(36,80)`؛ ثابت‌های حرکت در `scripts/player/player_controller.gd` (WALK 300، RUN 470، GRAVITY 2100، JUMP −870، DASH 780…) **تغییر نکند مگر با دستور** |
| کاشی | موجود: ASCII ردیف ۲۲ × ستون ~۱۹۲؛ اندازهٔ هر خانه ۶۴px (در `level_builder.gd` ببین) |
| تست | `godot --headless --path . res://tests/test_runner.tscn` و `python3 tests/validate_levels.py` (باید سبز بماند) |

## ۱. ساختار پوشه‌ها

```
scripts/
  characters/   rigها (موجود) — قهرمان‌ها و همراه‌ها با «حالت»های جدا
  combat/       weapons.gd (موجود) + element.gd, mods.gd, damage.gd (جدید)
  economy/      loadout.gd, store_adapter.gd (موجود) + wallet.gd, hearts.gd, shop_catalog.gd (جدید)
  enemies/      boss.gd (موجود، بازنویسی به «فاز و راز») + keeper.gd و keepers/k01…k12.gd (جدید)
  heroes/       hero_def.gd, hero_roster.gd (جدید)
  companions/   companion_def.gd, companion_team.gd, companion_commands.gd (جدید)
  keys/         key_placer.gd (جدید) — جای تصادفی کلیدها
  progression/  level_manager.gd, progress_manager.gd (موجود) + chapter_manager.gd, memory_book.gd (جدید)
  online/       api_client.gd, ghost_recorder.gd, ghost_player.gd, event_client.gd (جدید؛ نسخهٔ ۲)
  puzzle/       time_shift_manager.gd (موجود → بازنویسی به «دو لایهٔ هم‌زمان»)
  ui/           صفحه‌ها (موجود) + صفحه‌های جدید طبق [17](17_ui_screens_design.md)
data/
  chapters/ch01.json … (جدید)   heroes.json  companions.json  weapons.json  tools.json
  keepers.json  bosses.json  shop.json  strings_fa.json  stickers.json  (جدید)
  levels/<chapter>/level_XX.json   (قالب v4؛ بخش ۴)
tools/levels/   compose.py, story.py, routes.py, authored.py (موجود) → خروجی قالب v4
```

## ۲. شبکهٔ خودکارها (Autoload)

موجود: `SaveManager, GameInput, AudioManager, Analytics, StoreAdapter, TimeShift, LevelManager, ProgressManager`.
جدید: `Wallet` (سکه/الماس)، `Hearts` (جان)، `Roster` (قهرمان‌ها و همراه‌ها)، `Chapters`، `MemoryBook`، `Online` (نسخهٔ ۲، با «آفلاین» پیش‌فرض)، `Names` (نام قهرمان قابل‌تغییر).

## ۳. موتور زمان: «دو لایهٔ هم‌زمان»

**قاعده (قفل):** گذشته و حال جدا نیستند. هر مرحله یک نقشهٔ واحد با دو لایهٔ هم‌زمان‌اند.

1. هر شیء (کاشی، دشمن، کلید، پل، گیاه…) یک **برچسب زمان** دارد: `past`، `present` یا `both`.
2. `TimeShift.state` همچنان دو حالت `PAST/PRESENT` دارد (موجود) و تعیین می‌کند **با کدام لایه برخورد فیزیکی** می‌کنی. **لایهٔ غیرفعال همیشه رندر می‌شود** به‌صورت شبح (آلفا ۰٫۳۵، رنگ‌مایه آبی برای گذشته/نارنجی برای حال) تا بازیکن هر دو را در یک صحنه ببیند.
3. جابه‌جایی لنز با `blocker_in()` ایمن است (موجود). **کپی ایمنی:** اگر هدف داخل جامد است، لنز رد و اشاره می‌شود.
4. **اثر پروانه‌ای:** رویدادهای ثبت‌شده در گذشته (کاشتن دانه، باز کردن در…) در `TimeShift.history` ذخیره و در حال اعمال می‌شود؛ برعکسش نه. هر رویداد: `{id, time:"past", effect:"present_changes"}` در JSON مرحله.
5. **پژواک** (از فصل ۷): `EchoRecorder` ۵ ثانیه حرکت را ضبط می‌کند و «شبح گذشته» همان را تکرار می‌کند (روی کلید و کلید فشاری اثر می‌گذارد).
6. **فصل ۱۴:** هر دو لایه هم‌زمان فیزیکی‌اند (بدون لنز). پرچم `dual_physics: true` در JSON فصل.
7. رندر: دو `CanvasLayer`/گروه نود (`layer_past`, `layer_present`) با `modulate` متغیر؛ پارالکس جدا برای هر لایه (از `layered_background.gd` موجود).

## ۴. قالب داده

### ۴.۱ مرحله (`format: 4`)
```json
{
  "id": 17, "format": 4, "chapter": "ch03", "index": 1,
  "title": "تپه‌های روان", "kind": "normal|race|memory|boss",
  "weapon_level_required": 2,
  "dual_physics": false,
  "map": ["....", "..."],
  "keeper": { "type": "K3", "id": "sandshade", "secret": "twin_3s" },
  "key_slots": {
    "past":    [[12,8],[40,14],[88,5]],
    "present": [[20,16],[61,9],[102,12]]
  },
  "hints": ["near_water", "above_rock", "tree"],
  "boxes": [], "enemies": [], "signs": [], "warps": [],
  "intro": [{"who":"pilo","text_key":"c03_l01_00"}],
  "outro": [],
  "rewards": {"coins":[20,40], "stars":3, "material":"iron"}
}
```
- `map` همان نقشهٔ ASCII موجود است (`level_builder.gd`): هر نویسه خودش برچسب زمان دارد (مثلاً `r` فقط گذشته، `V` فقط حال، `#` هر دو). **نیازی به دو نقشهٔ جدا نیست**؛ فقط نویسه‌های تازه برای پاسدار و کلیدها اضافه می‌شود (legend در [03](03_levels_ch1-15.md)).
- `key_slots`: **سه جا برای هر کلید**؛ `KeyPlacer` با `seed = hash(level_id, run_counter)` یکی را انتخاب می‌کند (در حالت روزانه/آنلاین `seed` مشترک).
- فرمت قدیمی `format:2` با `tools/levels/migrate_v2_to_v4.py` تبدیل می‌شود: `map` و نویسه‌ها بدون تغییر؛ فیلدهای تازه (`keeper`, `key_slots`, `kind`, …) اضافه می‌شوند. نویسهٔ قدیمی `k` (یک کلید) → دو کلید `kp`/`kh` (گذشته/حال) با سه جای ممکن.

### ۴.۲ فصل (`data/chapters/chNN.json`)
`{id, title, color_theme, weapon_level, heart:1|null, boss:"id", hero_unlock:"id|null", egg:"id", memory_room_level, preview_card:{...}}`

### ۴.۳ قهرمان (`heroes.json`)
`{id, name_fa, age, element, power:{id,charge,cooldown}, movement:{type,params}, combat:{style,weapon_id}, companion_signature:"id", unlock:{chapter,coins}, lines:{select,start,hit,win,lose,idle,power,special}, stats:{atk,spd,range,def}}`

### ۴.۴ همراه (`companions.json`)
`{id, name_fa, element, command:{id,cooldown}, movement, forms:[3], egg_chapter, free:bool, lines:{...6}}`

### ۴.۵ سلاح و ابزار (`weapons.json`, `tools.json`)
`{id, kind, tiers:[{level,name,damage_mult,mod_slots,art}], mods_allowed:[shape,element,effect]}`؛ ابزار: `{id, uses, cooldown, effect}`.

### ۴.۶ پاسدار و نگهبان
`keepers.json`: `{id, type:"K1".."K12", hp_hits, secret:{...}, weakness:{...}}`
`bosses.json`: `{id, hp, phases:[{id,pattern,weak_point,flashback:bool}], secret, weapon_tier_min, release_line_key}`

## ۵. پاسدار (K1–K12) — پیاده‌سازی

کلاس پایه `Keeper` (`scripts/enemies/keeper.gd`) با سیگنال‌های `hit`, `exposed`, `defeated(key_drop)` و رفتار «حامل کلید». هر نوع زیرکلاس است:

| نوع | هستهٔ منطق |
|---|---|
| K1 | `awake_in = PAST|PRESENT`؛ در زمان خواب آسیب‌پذیر؛ بیدار شدن با صدای نزدیک (`noise_radius`) |
| K2 | سپر جهت‌دار؛ پرتابه‌ها را برمی‌گرداند؛ آینه‌ٔ بازیکن بازتاب می‌دهد |
| K3 | دو نود هم‌زاد در دو لایه؛ هر دو باید در ≤۳ ثانیه ضربه بخورند |
| K4 | دنباله `pattern:[ids]`؛ در گذشته نمایش داده می‌شود؛ در حال باید به همان ترتیب ضربه بخورد |
| K5 | نوار ریتم؛ پنجرهٔ آسیب‌پذیری با دوره و آفست |
| K6 | حرکات بازیکن را با تأخیر تقلید می‌کند؛ با حرکت اشتباه در تله می‌افتد |
| K7 | فراری با کلید؛ مسیر را «ردپای گذشته» لو می‌دهد؛ تله |
| K8 | پنهان در `dark|cloud|water`؛ با `light` (پیلو/فانوس/بمب دودی) آشکار |
| K9 | `armor_level`؛ با سلاح `tier >= armor_level` آسیب می‌بیند وگرنه ×۰٫۰۵؛ راه جایگزین `drop_from_above` |
| K10 | `element` متغیر با زمان؛ ضربهٔ هم‌عنصر ×۰٫۵، مخالف ×۱٫۵ (جدول در [08](08_combat_and_overworld.md)) |
| K11 | معما از `strings_fa.json`؛ جواب از `signs` گذشته؛ پاسخ نادرست = ضربه‌ای به بازیکن |
| K12 | `needs_item` که فقط در یک لایه وجود دارد؛ آن را به لایهٔ دیگر ببر (بعد از اثر پروانه‌ای) |

**راهنمای رایگان:** بعد از ۳ شکست پشت‌سرهم `Keeper.reveal_hint()` فراخوانی می‌شود.

## ۶. نگهبان فصل (بوس)

`Boss` به «فاز»ها شکسته می‌شود: `BossPhase{pattern, weak_point, duration}`. وضعیت‌ها: `intro → phase1 → phase2(+flashback) → phase3 → released`. **کشتن نیست**؛ پایان = `released` (آزاد شدن). نوار جان با قلب‌ها. در `weapon_tier_min` پایین‌تر هشدار + دکمه «برو کارگاه».

## ۷. جنگ و سلاح

- `Damage.calc(attacker, defender)` = `base × tier_mult × element_mult × crit`.
- عناصر: آتش>گیاه>آب>آتش؛ نور>باد>سایه>نور.
- مود: `Mods` سه نوع (shape/element/effect)؛ تعداد جا از `tier` (۱:۰، ۲:۰، ۳:۱، ۴:۲، ۵:۳).
- ابزار آنی: سه جای میان‌زمان (Metro-style) با دکمهٔ لمسی؛ استفاده بدون باز کردن منو.
- تیر محدود؛ پر شدن از جعبه.

## ۸. قهرمان و همراه

- `HeroDef` ثابت‌های حرکت را **روی** `PlayerController` اعمال می‌کند (ضرب سرعت، پرش، قابلیت‌ها: `glide, swim, wall_jump, teleport_short, gravity_flip, roll`).
- لنز: فقط آرسام `lens_free=true`؛ بقیه `lens_charge` (نوار ۰..۱۰۰؛ هر تعویض ۲۵؛ پر شدن با «ساعت کوچک» و زمان).
- `CompanionTeam`: ۳ جا (فعال + ۲ ذخیره)؛ تعویض بدون وقفهٔ مرحله، با هم‌افزایی با همراه مخصوص.
- رنگ‌مایه، نقش، کلاه، آویز: `CompanionCustom{palette, pattern, hat, charm, name_key, voice_tone}`.

## ۹. اقتصاد

- `Wallet`: سکه، الماس، مواد (`iron, silver, guardian_shard, time_dust, companion_dust`).
- `Hearts`: ۵ قلب انرژی، بازسازی ۲۰ دقیقه؛ زمان از ساعت دستگاه + بررسی تقلب ساده (ذخیرهٔ آخرین زمان).
- ورود به مرحله: هزینهٔ سکه طبق جدول فصل ([09](content/09_economy_shop.md)).
- خرید: `StoreAdapter` (کافه‌بازار/مایکت). **خرید همیشه با سد ساده‌ٔ تأیید.** بدون جعبه‌شانس پولی.
- تبلیغ پاداشی: `AdsAdapter` (Adivery) با سقف ۵ در روز؛ هرگز اجباری.

## ۱۰. ذخیره

`SaveManager` (موجود) با نسخه‌دار کردن: `save_version: 4`، `player_name`، `wallet`, `hearts`, `roster`, `companion_team`, `chapters`, `memories[15]`, `eggs`, `daily`, `settings`, `purchases_log`. مهاجرت از v3: «نیما» → نام قهرمان پیش‌فرض.

## ۱۱. آنلاین (نسخهٔ ۲؛ فایل‌های `scripts/online/`)

API (REST + WebSocket) — فقط مشخصات رابط:
`POST /ghost` (ثبت)، `GET /ghost?level=&seed=` (روح رقیب)، `GET /event/status`, `WS /event/room`, `POST /report`. **بدون ارسال دادهٔ شخصی؛ شناسه تصادفی.** حالت «آفلاین» همیشه دسترس‌پذیر؛ روح ساختگی از `tools/ghosts/` (زمان‌های ثابت).

## ۱۲. صدا

موجود: `AudioManager`, `tools/voice`, `tools/audio`. قانون: **صداگذاری‌ها نام قهرمان را نمی‌گویند** (نام قابل‌تغییر)؛ ضبط انسانی بازنویسی نمی‌شود؛ هر شخصیت صدای خودش. جمله‌های جدید در `data/voice/voice_lines.json` با سازندهٔ `tools/voice/build_voice_lines.py`.

## ۱۳. تست و اعتبارسنج

- `tests/validate_levels.py` (v4): برای هر مرحله **همهٔ ۹ ترکیب** جای کلید قابل‌رسیدن (BFS هر دو لایه با رعایت لنز)، پاسدار قابل‌شکست، تابلو/ابزار لازم راز موجود، و سطح سلاح لازم ≤ سطح قابل‌دستیابی تا آن فصل.
- `tests/test_runner.gd`: هر سیستم جدید تست واحد (Damage, KeyPlacer, Hearts, Wallet, Keepers K1–K12, Boss phases, Companion team, Save migration).
- اسکرین‌شات: `tools/screenshot.tscn` و مقایسه با طرح صاحب پروژه.

## ۱۴. قواعد ممنوع

- کپی از بازی دیگر ممنوع (فقط توضیح متنی سبک).
- هنرِ ساخته‌شده با کد فقط `art/drafts/` و موقتی است.
- کلید/توکن در مخزن نیاید.
- دیالوگ نام قهرمان را در صدا نگوید.
