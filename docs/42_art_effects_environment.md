# هنر افکت و فضای محیط (۱۰ تصویر) — پرامپت دقیق، نام فایل و مسیر

> ساخته‌شده با `tools/art/gen_v3d_prompts.py`. هدف: `docs/40` §۸ (افکت، فضای محیط، حرکت طبیعی). مسیرها نسبت به ریشهٔ مخزن `pilo/`.

> همه برگهٔ برش‌خور روی **مجنتای خالص `#FF00FF` (نه سفید)**؛ هر ردیف **یک انیمیشن** با فریم‌های هم‌اندازه. مرجع: `assets/art/pair1_sheets/g4_fx_sheet.png` (سبک افکت‌ها).

> بعد از گذاشتن فایل‌ها: `python3 tools/art/check_v3d.py` یا بگویید «چک کن».

---

## 01 — Ground impacts per surface (dust, sand, snow powder, splash, leaves, stone chips)

- **نام فایل:** `v3_fx_ground_impacts.png`
- **مسیر:** `assets/art/v3/v3_fx_ground_impacts.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: SOIL dust puff when landing, 8 frames, brown-tan, expanding and fading. Row 2: SAND dust cloud, 8 frames, golden, wide and soft. Row 3: SNOW POWDER burst, 8 frames, white-blue sparkly powder. Row 4: WATER SPLASH, 8 frames, a crown splash with droplets and two ripple rings. Row 5: GRASS and LEAF scatter, 8 frames, green blades and a few leaves flying up. Row 6: STONE CHIPS and sparks, 8 frames, grey chips with small orange sparks. Row 7: small FOOTSTEP puffs, 6 frames each for soil, sand, snow. Row 8: a LANDING shockwave ring on the ground, 6 frames. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 02 — Light effects (sun shafts, lantern glow, glints, flares)

- **نام فایل:** `v3_fx_light.png`
- **مسیر:** `assets/art/v3/v3_fx_light.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: four SUN RAY SHAFTS of different widths, each a soft slanted translucent golden beam, single frame each, tall. Row 2: LANTERN GLOW halo pulsing, 6 frames, warm orange-gold soft circle with a tiny flicker. Row 3: SPARKLE GLINTS, 6 frames each for two glint styles (four-point star glints). Row 4: LENS FLARE with soft hexagon spots, 4 variants. Row 5: DUST MOTES floating in a beam, 6 frames. Row 6: a soft SPOTLIGHT circle in warm white, 4 sizes. Glossy, additive-friendly, bright, no pink. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 03 — Water: river flow, waterfall, foam, ripples, drips

- **نام فایل:** `v3_fx_water.png`
- **مسیر:** `assets/art/v3/v3_fx_water.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: RIVER SURFACE strip, seamless left-right tile, flowing from left to right, 8 frames, bright blue-turquoise with white foam streaks and sun glints. Row 2: WATERFALL falling water strip, seamless top-bottom tile, 6 frames, white-blue streams with mist. Row 3: FOAM and mist at the bottom of a waterfall, 8 frames. Row 4: RIPPLE rings expanding, 6 frames. Row 5: BIG SPLASH, 8 frames. Row 6: WATER DRIP falling from a ceiling and hitting a puddle, 6 frames. Row 7: a SMALL STREAM tile with flowing pebbles, 8 frames, seamless. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 04 — Forest critters that run on walls, trunks and branches (clearer layout)

- **نام فایل:** `v3_critters_forest.png`
- **مسیر:** `assets/art/v3/v3_critters_forest.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Animation frame sheet of small friendly forest animals for background life. PURE SIDE VIEW (profile), facing RIGHT. STRICT LAYOUT: ONE animation per row, AT MOST 8 frames per row, every frame in its own cell, frames separated by at least 120 px of empty background, NO overlapping or touching between neighbouring frames, the same scale in every frame of an animation, feet on the same baseline. Rows (top to bottom): 1 SQUIRREL run cycle 8 frames; 2 SQUIRREL climbing up a short tree trunk 6 frames; 3 LIZARD (gecko) crawling along a wall 8 frames; 4 SNAIL sliding 6 frames; 5 LADYBUG walking 6 frames; 6 SONGBIRD flying 8 frames (wings clearly up and down, no frame touching the next); 7 SONGBIRD perched singing 4 frames; 8 DRAGONFLY hovering 6 frames; 9 ORANGE BUTTERFLY flapping 6 frames; 10 BLUE BUTTERFLY flapping 6 frames; 11 BEE flying 6 frames; 12 MOTH fluttering 6 frames; 13 FROG idle 3 frames then hopping 5 frames (8 in the row). Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 05 — Night effects: pulsing glowing flowers, fireflies, spores

- **نام فایل:** `v3_fx_night.png`
- **مسیر:** `assets/art/v3/v3_fx_night.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: a GLOWING NIGHT FLOWER (turquoise petals) pulsing from dim to bright, 6 frames. Row 2: a second glowing flower (violet-blue), 6 frames. Row 3: a third glowing flower (warm gold), 6 frames. Row 4: a FIREFLY blinking, 6 frames, plus a glowing path trail. Row 5: floating glowing SPORES drifting, 6 frames. Row 6: a small glowing night MOTH fluttering, 6 frames. Row 7: a hanging glowing LANTERN-VINE swaying, 6 frames. Warm and cool glows, no pink. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 06 — Heat and sun effects: glints, dust devil, sand drift

- **نام فایل:** `v3_fx_heat.png`
- **مسیر:** `assets/art/v3/v3_fx_heat.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: SUN GLINT sparkles on a surface, 6 frames. Row 2: a small DUST DEVIL (whirling sand column), 8 frames. Row 3: SAND DRIFT streaks blowing sideways, 6 frames. Row 4: HEAT-HAZE wavy translucent streak shapes, 4 variants (they will be used as a distortion mask). Row 5: floating golden DUST specks, 6 frames. Row 6: a MIRAGE shimmer shape, 4 frames. Warm gold and cream. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 07 — Snow effects: flakes, powder, sparkle, breath, slide trail

- **نام فایل:** `v3_fx_snow.png`
- **مسیر:** `assets/art/v3/v3_fx_snow.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: SNOWFLAKES in three sizes (small, medium, large), each rotating 6 frames. Row 2: SNOW POWDER puff, 8 frames. Row 3: ICE SPARKLE twinkle, 6 frames. Row 4: BREATH puff cloud, 6 frames. Row 5: SLIDE TRAIL on ice (white-blue streaks), 6 frames. Row 6: SNOW FALLING from a branch (a clump drops and bursts), 8 frames. Row 7: a slippery ICE PATCH on the ground, glossy, 3 variants. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 08 — Rain, wind, lightning

- **نام فایل:** `v3_fx_rain_wind.png`
- **مسیر:** `assets/art/v3/v3_fx_rain_wind.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. Effect and environment sprite sheet for a 2D side-scrolling platformer. Every row is ONE animation with equal-sized frames laid out left to right, centered in their cells, the same scale in each frame so the frames can be played as a smooth loop. Row 1: RAINDROP streaks in three sizes, single frame each, slanted. Row 2: RAIN SPLASH on the ground, 6 frames. Row 3: PUDDLE ripple, 6 frames. Row 4: WIND STREAK lines (white swoosh lines), 4 variants. Row 5: a LEAF GUST: a handful of leaves tumbling in the wind, 8 frames. Row 6: LIGHTNING BOLT, 4 variants. Row 7: a WHIRLWIND of leaves and dust, 8 frames. Row 8: a falling RAIN CURTAIN (long thin streaks) tile, 4 frames, seamless top-bottom. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 09 — Cloud sprites: puffy, streaks, storm, rain clouds

- **نام فایل:** `v3_clouds.png`
- **مسیر:** `assets/art/v3/v3_clouds.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Cloud sprite sheet for slowly moving parallax skies, each cloud a separate sprite: four PUFFY white clouds with golden-lit undersides in different sizes, three long thin STREAK clouds, three dark violet-grey STORM clouds, two RAIN clouds with a soft dark underside, two small WISP clouds. Soft painterly edges with a thin dark-navy outline. Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```

## 10 — Plants for swaying: grass, flowers, ferns, reeds, vines

- **نام فایل:** `v3_plants_sway.png`
- **مسیر:** `assets/art/v3/v3_plants_sway.png`
- **اندازهٔ ایده‌آل:** 2720x1536 · **پس‌زمینه:** مجنتا #FF00FF

- **مرجع:** `assets/art/pair1_sheets/g4_fx_sheet.png`

```
Plant sprite sheet for foreground and background vegetation that sways in the wind, each separate and drawn upright with its base at the bottom: four GRASS clumps of different heights, six FLOWERS on stalks (different colors), three FERNS, three REED/cattail stalks, two BUSHES, four hanging VINES of different lengths, a tall FLOWERING STALK. Each plant slightly asymmetrical so copies feel natural. Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, sellable casual-game quality. Kid-friendly for ages 8-15. IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. No part of any subject is pink or magenta (use warm orange, gold, cream, violet or blue for glows). Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.
```
