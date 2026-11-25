# ۴۶ — هنر v4، دستهٔ ۱ (پدربزرگ + دشت قدیم)

> همهٔ فایل‌ها در `game_v4/art/` (پوشه‌ها را بساز). نام فایل دقیقاً همین باشد (یک بار `.png`).
> نام بازی یا سبک بازی دیگری در پرامپت نیاید (قاعدهٔ ۹). هیچ متنی داخل تصویر نیاید.
> سبک مشترک همهٔ تصویرها (در هر پرامپت تکرار شده):
> *lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges*

---

## ۱) اعضای جدای پدربزرگ جوان — `game_v4/art/chars/grandfather_parts.png`
- **اندازه:** 2048x2048 · **پس‌زمینه:** مجنتای خالص #FF00FF
- **کاربرد:** هر عضو جدا بریده و روی اسکلت سوار می‌شود؛ همهٔ حرکت‌ها (راه، دو، پرش، سُر با شنل، ضربه با عصا، آویزان، دیوار) با کد ساخته می‌شود.

```
Character cut-out PARTS SHEET for 2D skeletal animation, one young adventurer man (about 25 years old, slim and agile, warm olive skin, short dark curly hair with a small loose curl, kind brave face, short neat beard), wearing a sand-colored tunic with a teal sash, brown trousers, soft leather boots, a short deep-teal cloak with golden Persian pattern trim, and a carved wooden walking staff. SIDE VIEW facing RIGHT for every part, all parts drawn at the SAME SCALE, neutral flat lighting. Every body part is a SEPARATE piece with empty space around it, arranged in a clean grid: Row 1: HEAD with hair (3 versions: neutral, happy open mouth, determined), and a separate hair curl tuft. Row 2: TORSO with tunic and sash (no arms, no head), PELVIS with belt. Row 3: UPPER ARM, FOREARM, HAND open, HAND fist, HAND gripping (for holding the staff) — each drawn once. Row 4: THIGH, SHIN, FOOT with boot — each drawn once. Row 5: CLOAK folded (hanging down), CLOAK spread wide open like a glider wing, the WALKING STAFF alone. Joint ends of limbs are ROUNDED and slightly overlapping-friendly (like a paper puppet), no cut lines, no skeleton, no joints drawn. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. IMPORTANT BACKGROUND RULE: the entire background is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform, no shadows, no gradient, no floor. No part of any subject is pink or magenta. At least 80 px of empty magenta between all pieces, nothing touching, nothing cropped. No text, letters, numbers, labels, watermark or logo. Original character, do not imitate any existing game or brand.
```

---

> **به‌روزرسانی ۲۵ نوامبر (ویدئوهای مرجع):** ساختار لایه‌ها مثل ویدئوها: **مه دور ← تنه‌های غول میانی ← ردیف زمینِ پشتی مه‌آلود ← پرتو نور ← مسیر اصلی (توده‌های سنگ خزه‌دار پله‌ای با حفره‌های تیره) ← پیش‌زمینهٔ تیره لبهٔ قاب**؛ هر مرحله **یک فضای رنگی** (این مرحله: جنگل سبز صبح با مه سبز-فیروزه‌ای). نمونهٔ کدی همین ساختار را دارد؛ این عکس‌ها جایش می‌نشینند.

## ۲) کیت مسیر جنگل قدیم — `game_v4/art/kits/forest_old_kit.png`
- **اندازه:** 2048x2048 · **پس‌زمینه:** مجنتا #FF00FF
- **کاربرد:** زمین و همهٔ اجزای مسیر از این قطعه‌ها چیده می‌شود (بدون کاشی، بدون بلوک).

```
2D side-view PLATFORMER PATH KIT for a lush ancient forest, green morning light with soft green-teal mist. Separate pieces with empty space around each, arranged in rows: Row 1: three big MOSSY ROCK TERRAIN MASSES (wide chunky stone blocks overgrown with thick rounded moss on top, moss drips hanging over the edge, big rounded stone slabs in the body, a dark hollow cave opening in one of them), each with a clear walkable top line; one STEP-UP piece (a rock riser about one character height) and one gentle SLOPE piece. Row 2: a LEFT EDGE and a RIGHT EDGE end-cap of the mossy rock (moss curling over, roots hanging), a FLOATING MOSSY ROCK island with roots. Row 3: a huge TREE TRUNK segment (straight, with bark texture, climbable), two curved TREE BRANCHES with leaves (walkable on top), a hanging green VINE with a flower at its end, a rope-and-plank SWING. Row 4: a big red BOUNCE MUSHROOM with white spots, a floating LILY LEAF with a pink flower, a cracked stone vent with a rising WIND of petals, a small stone ruin arch. Row 5: decorations: ferns, tall grass tufts, glowing flowers, hanging moss strands, small mushrooms, a broken tiled vase. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. IMPORTANT BACKGROUND RULE: the entire background is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform, no shadows, no gradient, no floor. No part of any subject is pink or magenta. At least 80 px of empty magenta between pieces, nothing touching, nothing cropped. No text, letters, numbers, labels, watermark or logo. Original design, do not imitate any existing game or brand.
```

## ۳) لایه‌های عمق جنگل قدیم — ۵ تصویر جدا
همه **3072x1024**، **بی‌درز تکرارپذیر از چپ به راست**. رنگ همه یک خانواده باشد (سبز-فیروزه‌ای مه‌آلود)؛ هرچه دورتر، کم‌رنگ‌تر و مه‌آلودتر.

### ۳-الف) آسمان و مه — `game_v4/art/bg/forest_old_sky.png` (تصویر کامل)
```
Seamless horizontally tileable 3:1 panorama of the SKY AND MIST deep inside a forest at morning: soft pale green-teal glow, bright haze near the middle, a few soft light rays coming down from above. No trees in front, no ground, no characters. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. No text, letters, numbers, watermark or logo.
```

### ۳-ب) جنگل دور در مه — `game_v4/art/bg/forest_old_far.png` (مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of a FAR FOREST seen through thick morning mist: tall pale tree silhouettes and soft round canopies, very low contrast, washed-out pale green-teal, hanging vines barely visible. It fills the whole height except the top 15 percent. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges but very soft and hazy. IMPORTANT: everything that is not forest is solid flat pure magenta RGB(255,0,255) #FF00FF. No part of the forest is pink or magenta. No text, letters, numbers, watermark or logo.
```

### ۳-ج) تنه‌های غول میانی — `game_v4/art/bg/forest_old_mid.png` (مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of GIANT ANCIENT TREE TRUNKS in the middle distance: 5 to 6 huge twisted trunks with big roots, thick drooping canopies at the top edge, hanging vines and moss, medium contrast, green-teal with light mist between them. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. IMPORTANT: the gaps between the trunks and everything that is not tree are solid flat pure magenta RGB(255,0,255) #FF00FF. No part of the trees is pink or magenta. No text, letters, numbers, watermark or logo.
```

### ۳-د) ردیف زمین پشتی — `game_v4/art/bg/forest_old_near.png` (مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of a BACK TIER OF TERRAIN just behind the play path: stepped mossy rock masses at different heights (some higher, some lower), thick moss tops, ferns, small trees, broken stone ruins, slightly hazy so it stays behind the main path, darker green. It occupies the lower 45 percent; everything above is EMPTY. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. IMPORTANT: everything that is not terrain or plants is solid flat pure magenta RGB(255,0,255) #FF00FF. No part of the terrain is pink or magenta. No text, letters, numbers, watermark or logo.
```

### ۳-ه) پیش‌زمینهٔ تیره — `game_v4/art/bg/forest_old_front.png` (مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of a DARK FOREGROUND for the bottom edge of the screen, in front of the camera: big dark silhouette leaves, fern fronds, grass clumps and a few branches, almost black dark green, slightly soft and blurry like out of focus. Clumps of different heights along the bottom edge; the upper 65 percent is EMPTY. IMPORTANT: everything that is not foliage is solid flat pure magenta RGB(255,0,255) #FF00FF. No part of the foliage is pink or magenta. No text, letters, numbers, watermark or logo.
```

> نسخهٔ قبلی این بخش‌ها (`meadow_old_*`) لغو شد؛ اگر ساخته‌ای، نیازی به آن‌ها نیست.

## دسته‌های بعد (بعد از تأیید نمونه)
اعضای آرسام، کیت و لایه‌های دشت جدید، دشمن‌ها به‌صورت اعضای جدا، ساعتک و قفس، شبنم، افکت‌ها.
