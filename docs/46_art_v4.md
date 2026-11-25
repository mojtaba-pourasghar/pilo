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

## ۲) کیت محیط دشت قدیم — `game_v4/art/kits/meadow_old_kit.png`
- **اندازه:** 2048x2048 · **پس‌زمینه:** مجنتا #FF00FF
- **کاربرد:** زمین و سکوهای مرحله از همین قطعه‌ها چیده می‌شوند (نه کاشی تکراری).

```
2D platformer ENVIRONMENT KIT sheet, side view, sunny ancient Persian meadow in springtime. Separate pieces with empty space around each, arranged in rows: Row 1: three long GROUND TOP strips (thick grassy earth with flowers and small stones on top, rich soil body below, rounded bottom edge), one gentle UP-SLOPE piece and one DOWN-SLOPE piece. Row 2: a LEFT CLIFF EDGE end-cap and a RIGHT CLIFF EDGE end-cap (grass curling over the edge, roots hanging), a big ROUNDED BOULDER platform, a FLOATING EARTH ISLAND with dangling roots. Row 3: two WOODEN PLANK PLATFORMS (one short, one long) with rope bindings, a carved STONE PILLAR (tall, can be climbed), a broken stone ARCH piece. Row 4: decorations: three FLOWER BUSHES, two SMALL TREES, tall GRASS TUFTS, MUSHROOMS, a blue-tiled ancient VASE, a SIGNPOST without text. Row 5: FOREGROUND silhouettes for in front of the camera: big dark leaves, a tall grass clump, a branch. Every ground piece has a clear flat walkable top line. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines, rounded organic shapes, Persian-inspired motifs, kid-friendly, high detail, crisp clean edges. IMPORTANT BACKGROUND RULE: the entire background is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform, no shadows, no gradient. No part of any subject is pink or magenta. At least 80 px of empty magenta between pieces, nothing touching, nothing cropped. No text, letters, numbers, labels, watermark or logo. Original design, do not imitate any existing game or brand.
```

---

## ۳) پس‌زمینهٔ دشت قدیم — ۴ لایهٔ جدا (برای عمق)

همه **3072x1024** (پانورامای ۳ به ۱). همه باید **از چپ به راست بی‌درز تکرارپذیر** باشند (لبهٔ چپ و راست به هم بخورند).

### ۳-الف) آسمان — `game_v4/art/bg/meadow_old_sky.png` (تصویر کامل)
```
Seamless horizontally tileable 3:1 panorama SKY for a 2D side-scroller: soft morning sky, warm golden light near the horizon fading to fresh blue above, a few big fluffy painterly clouds, gentle sun glow at left. No ground, no mountains, no characters. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors. No text, letters, numbers, watermark or logo.
```

### ۳-ب) کوه‌های دور — `game_v4/art/bg/meadow_old_far.png` (پس‌زمینهٔ مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of FAR DISTANT MOUNTAINS for parallax: soft hazy blue-violet mountain range with snowy peaks and a tiny far-away palace with turquoise domes on one hill, atmospheric perspective, low contrast. The mountains sit in the lower half; everything above them is EMPTY. lush hand-painted 2D storybook illustration, soft painterly brush textures. IMPORTANT: the empty sky area and everything that is not mountain is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform. No part of the mountains is pink or magenta. No text, letters, numbers, watermark or logo.
```

### ۳-ج) تپه‌های میانی — `game_v4/art/bg/meadow_old_mid.png` (پس‌زمینهٔ مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of MIDDLE-DISTANCE ROLLING HILLS for parallax: green meadow hills with cypress trees, a winding stream, a small stone bridge, an ancient tiled pavilion, orchards in blossom, medium detail, slightly hazy. The hills fill the lower 55 percent; everything above is EMPTY. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light. IMPORTANT: everything that is not hills is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform. No part of the hills is pink or magenta. No text, letters, numbers, watermark or logo.
```

### ۳-د) درخت‌های نزدیک — `game_v4/art/bg/meadow_old_near.png` (پس‌زمینهٔ مجنتا)
```
Seamless horizontally tileable 3:1 panorama strip of NEAR BACKGROUND for parallax just behind the play area: big old trees with twisted trunks and lush canopies, flowering bushes, tall grass, wildflowers, a few stone ruins, rich detail and strong color, darker at the bottom. The trees rise from the bottom edge and leave the upper 30 percent EMPTY between the canopies. lush hand-painted 2D storybook illustration, soft painterly brush textures, rich saturated but gentle colors, warm rim light, subtle thin dark-brown outlines. IMPORTANT: everything that is not trees or plants is solid flat pure magenta RGB(255,0,255) #FF00FF, perfectly uniform. No part of the plants is pink or magenta. No text, letters, numbers, watermark or logo.
```

---

## دسته‌های بعد (بعد از تأیید نمونه)
اعضای آرسام، کیت و لایه‌های دشت جدید، دشمن‌ها به‌صورت اعضای جدا، ساعتک و قفس، شبنم، افکت‌ها.
