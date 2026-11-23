# Generates docs/35_art_pack/P0_PROMPTS.md and tools/art/p0_manifest.json
import json, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STYLE = ("Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, "
 "chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, "
 "sellable casual-game quality. Original design with Persian/Iranian-inspired motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15.")
PINK = ("IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, NOT light pink, NOT transparent. Solid flat pure magenta background #FF00FF, perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. "
 "No part of any subject is pink or magenta. Every item fully separated with at least 60 px of empty magenta between items, nothing overlapping or touching, "
 "nothing cropped at the edges. Each item has a closed thick dark-navy outline. Flat even lighting, orthographic side view unless stated. "
 "No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.")
NOPINK = "No text, letters, numbers, labels, watermark or logo. No magenta or pink background. Do not imitate any existing game, character or brand."
D = "assets/art/pair1_sheets"
ARS = ("Arsam: a 12-year-old boy, round-oval head, straight dark eyebrows, big warm-brown eyes, calm gentle smile, messy dark hair with one "
       "stubborn cowlick, turquoise tunic, small leather quiver on back, golden-yellow scarf")
GF = ("the young grandfather (about 20 years old, 'time gardener'): tidy dark hair, navy scarf, leather backpack, walking staff with a "
      "root-shaped tip, small slingshot at belt, small brass lantern")
PANEL = "Cinematic painted illustration, warm painterly lighting, depth with foreground, midground and background layers, "
items = []


def add(id_, title, size, kind, refs, body):
    items.append(dict(id=id_, title=title, size=size, kind=kind, refs=refs, body=body))


add("p0_h01a_arsam_modelsheet", "Arsam model sheet (faces + turnaround + poses)", "2720x1536", "pink",
    [f"{D}/g2_arsam_parts.png (face reference)"],
    f"Character model sheet of {ARS}. Row 1: 8 head close-ups in a row: neutral, determined, surprised, happy, worried, scared, mischievous laugh, dreamy; then 4 mouth shapes (closed, half-open, open, round 'oh') and one closed-eyes head. Row 2: full body standing, front view, side view, back view. Row 3: 8 full-body key poses: running, jump apex, landing squash, wall-slide with hand on wall, ground slide, aiming bow (3 angles: low, level, high), hurt recoil, victory arms raised. Same face as the reference image.")
add("p0_h01f_arsam_fuse", "Arsam Fuse form (Auraform with time spirit)", "2720x1536", "pink",
    [f"{D}/g2_arsam_parts.png", f"{D}/g2_tikkit_evolution_v1.png"],
    "Fusion form 'Auraform' of Arsam (same face, hair, turquoise tunic, quiver as the reference) merged with a tiny egg-shaped time spirit: translucent golden sand-light wings made of flowing ribbon sand, his golden scarf turned into a long flowing hourglass-sand ribbon, a faint thin clock-ring halo behind his head, arrows glowing gold, a small glowing egg-shaped emblem on his chest. Three full-body poses in a row: (1) arrival, standing with halo and wings opening; (2) running with wings streaming; (3) shooting the bow with a glowing golden arrow. Plus one small separate close-up of the chest emblem.")
add("p0_h02a_grandfather_modelsheet", "Young grandfather model sheet", "2720x1536", "pink",
    [f"{D}/g2_grandfather_parts.png (face reference)"],
    f"Character model sheet of {GF}. Warmer golden palette, light-blue rim light. Row 1: 5 head expressions (neutral, determined, surprised, happy, worried) plus a sleepy face and 4 mouth shapes. Row 2: full body front, side, back. Row 3: 8 full-body poses: carrying a glowing egg with both hands (slow careful walk), placing the egg gently into a nest, planting a seed by tapping the staff on the ground, pole-vault jump with the staff, spinning the slingshot over his head, raising the lantern, crouching, hurt recoil. Same face as the reference image.")
add("p0_c1e_egg_hatch", "Egg and hatching sequence", "2720x1536", "pink",
    [f"{D}/g2_tikkit_evolution_v1.png (Tikkit design)"],
    "Sequence sheet of a magical egg hatching, 5 stages left to right in one row: (1) intact pearly cream-turquoise egg with faint golden clock marks, (2) first thin crack with a tiny light, (3) many glowing cracks with golden light leaking, (4) half-shattered shell with strong light, (5) the tiny egg-shaped time spirit Tikkit emerging (pearly translucent body, small hourglass in its belly, six clock-hand feathers around, big amber eyes, star-shaped tail) exactly as in the reference. Second row: 6 separate eggshell fragments of different sizes. Third row: one alternate smoke-damaged dark cracked egg (dark purple smoke clinging, cracks) in two angles.")
add("p0_h01t_arsam_tools", "Arsam tools and upgrade levels", "2720x1536", "pink",
    [f"{D}/g2_arsam_hands_hair_v1.png"],
    "Equipment progression sheet for the hero Arsam. Row 1: his time bow at levels 1 to 5, each in its own cell: level 1 plain wood with simple string; level 2 reinforced with metal tips; level 3 with a silver-blue gem in the grip; level 4 gold-trimmed with glowing string; level 5 'time bow' with sand-light aura and clock-ring engraving. Row 2: his glider scarf at levels 1 to 5 (small floating scarf growing to a wide glowing wing-scarf). Row 3: four special arrow heads, each separate: Lumen arrow (white-gold glowing tip), Root arrow (green with sprouting leaves), Stasis arrow (blue-gold hourglass tip), Volley arrow (three arrows fanned out). Row 4: his quiver in 5 sizes (6, 8, 10, 12, 15 arrows visible). Persian arabesque engravings on every item.")
add("p0_h02t_grandfather_tools", "Young grandfather tools and upgrade levels", "2720x1536", "pink",
    [f"{D}/g2_grandfather_parts.png"],
    "Equipment progression sheet for the young grandfather. Row 1: root staff at levels 1 to 5 (plain wood; with a spring knot for jumping; with a bridge-seed pouch; with a shield-seed canopy bud; level 5 with a tiny glowing tree growing from the tip). Row 2: slingshot levels 1 to 5 (simple stone; quick-draw bands; sticky stone with rope; slow blue-glow stone; triple-stone pouch). Row 3: brass lantern levels 1 to 5 (plain; wider glass; glowing reveal runes; warm red-gold glass; protective ring of light). Row 4: seed bag in 5 sizes (from 3 to 12 seeds). Warm golden palette, light-blue rim light.")
add("p0_c1m_tikkit_moves_fx", "Tikkit four moves effects + icons", "2720x1536", "pink",
    [f"{D}/g2_tikkit_evolution_v1.png"],
    "Effect sheet for a time spirit's four moves, palette of gold sand, cream and turquoise only. Four rows of 5 animation frames each: row 1 'Sandburst' a ring of glowing golden sand expanding outward with slow swirl; row 2 'Liftwing' two golden sand-light wings lifting upward with an updraft column; row 3 'Stasis Pulse' a pulsing blue-gold hourglass shockwave freezing small clock gears in mid-air; row 4 'Rewind' a reverse spiral of clock hands and sand flowing backward. At the right end of each row: one square rounded move icon (normal) and one upgraded icon with extra sparkles.")
add("p0_fxa_bow_sling_fx", "Bow, arrow and sling effects", "2720x1536", "pink",
    [f"{D}/g4_fx_sheet.png (same effect style)"],
    "Effect sprite sheet for a platformer, each effect in its own cell, rows of 4 to 8 frames: row 1 aiming dotted curved path (4 dot styles) and target ring (3 states); row 2 bowstring being drawn (4 frames) and released vibrating (4 frames); row 3 arrow trails in 4 types: plain white-gold, power arrow with big glow, Lumen arrow white-gold, Root arrow green with leaves; row 4 arrow impact (star burst + 4 sparks) and arrow stuck and quivering (3 frames), Stasis arrow bubble, Volley triple arrow; row 5 rope cut (bronze spark), falling nest (leaf particles), sling: spinning stone with ring, stone trail, dotted aim line. Glossy, additive-friendly, no pink in any effect.")
add("p0_fxb_enemy_free_fx", "Enemy telegraph, hit and release effects", "2720x1536", "pink",
    [f"{D}/g4_fx_sheet.png", f"{D}/g2_enemies_new.png"],
    "Effect sprite sheet for a platformer, each effect in its own cell: row 1 attack warning rings in red-orange in 3 sizes plus a plain exclamation-shaped warning mark (a shape only, no letters); row 2 hit flash (3 frames), brass spark hit (3 frames); row 3 release puff: dark purple smoke turning into golden particles (6 frames) plus a tiny flower bud and a tiny happy sparkle critter; row 4 thrown red pomegranate (3 frames spinning), pomegranate splash into red-orange seeds; row 5 rolling dust cloud with leaves and cracks (4 frames), glowing weak-point thread on a bark (3 states: dim, bright, broken); row 6 four brass clock-hand feathers falling, egg smoke crack puff. No pink in any effect.")
add("p0_fxc_pair1_special_fx", "Pair 1 special effects (deeds, mirror, Fuse)", "2720x1536", "pink",
    [f"{D}/g4_fx_sheet.png"],
    "Effect sprite sheet for a platformer, each effect in its own cell: row 1 soft green glow halo marking an effect of a past deed (4 frames), golden hourglass marker on the ground in 3 states (dim, lit, done), morning dew sparkle (4 frames); row 2 shrine mirror beam: a golden light beam hitting a mirror and reflecting (4 frames), slanted sunbeam through leaves (3 frames); row 3 morning mist wisp strips (3), glowing butterfly (4 frames); row 4 mini Fusion: arrival of golden sand-wings (8 frames), sand ring (3 frames), small shield bubble (3 frames); row 5 tiny 'hello' stars burst from a small spirit (4 frames). Glossy, bright, no pink in any effect.")
add("p0_bg_old_mid_layers", "Old Dawn Plain parallax mid layers", "4096x2744", "pink",
    [f"{D}/bg_old_plain_v3.png (same world)"],
    "Three separate horizontal parallax layers stacked vertically with pink gaps, each seamless left-to-right and anchored at its bottom edge, sitting on flat magenta #FF00FF above their silhouettes. Warm golden sunrise meadow world, healthy untouched nature. Layer 3 (far midground): soft rolling hills with a distant village of intact small towers, hazy blue-green atmospheric haze, desaturated. Layer 4 (midground): rolling hills with scattered trees and one huge thousand-year-old tree, medium saturation, warm light. Layer 5 (near midground): lush saturated bushes, tall grass, flowers and small rocks on curved ground. Closed dark-navy outlines.")
add("p0_bg_new_mid_layers", "New Dawn Plain parallax mid layers", "4096x2744", "pink",
    [f"{D}/bg_new_plain_v3.png (same world)"],
    "Three separate horizontal parallax layers stacked vertically with pink gaps, each seamless left-to-right and anchored at its bottom edge, on flat magenta #FF00FF above their silhouettes. Same meadow years later: cool teal evening light, violet smoke traces, ruins. Layer 3 (far): rolling hills with a distant ruined village of broken towers overgrown with green, hazy blue. Layer 4 (mid): hills with scattered dry trees, one big lush green tree glowing softly, ruined stone arch. Layer 5 (near): bushes, tall grass, mossy stones, smoke patches. Closed dark-navy outlines.")
add("p0_bg_old_setpieces", "Old Dawn Plain set-pieces", "2720x1536", "pink",
    [f"{D}/bg_old_plain_v3.png"],
    "Set-piece sheet for a warm golden sunrise meadow platformer, each object separate: a huge thousand-year-old tree (complete, with a wide crown); a small stream bridge broken in the middle; the same bridge grown from living roots and green vines (complete); a tall branch nest, empty; the same nest with a softly glowing egg; a small shrine of stone with a round mirror, unlit; the same shrine lit by golden light; a small cave entrance; a golden hourglass sign painted on soil (3 states: dim, lit, done); a tall hill chunk; a fallen trunk.")
add("p0_bg_new_setpieces", "New Dawn Plain set-pieces", "2720x1536", "pink",
    [f"{D}/bg_new_plain_v3.png", f"{D}/g3_bg_new_bare_v1.png"],
    "Set-piece sheet for a cool teal meadow years later with violet smoke, each object separate: a huge lush green thousand-year-old tree glowing (variant A) and a tiny sapling (variant B); a green living root bridge complete and the same bridge broken; a branch nest with a rope (hanging) and the same nest fallen; a smoke-cracked dark egg in a smoky crevice; a ruined three-floor tower with platforms and a balcony; a far smoke ship silhouette floating; a shrine with an active glowing mirror and closed crystals; three soft green glow halos in three sizes.")
add("p0_ts01_tileset", "Chapter 1 tileset (old and new)", "2720x1536", "pink",
    [f"{D}/bg_old_plain_v3.png", f"{D}/bg_new_plain_v3.png"],
    "Tileset sheet for a forest-meadow platformer, 64 px grid style. Two rows of identical items: top row warm golden (old era), bottom row cool teal with violet smoke (new era). Items in each row: ground tile in 9 pieces (4 corners, 4 edges, center) with grass lip and soil body; wooden platform; stone platform; thin stalk platform; slope piece; 2 hazards (thorn bush, smoke patch); mushroom spring; broken plank; hanging rope; checkpoint unlit and lit; nest pillar.")
add("p0_m1_hud_extended", "Extended HUD (companion moves, Spark bar, guardian bar)", "2720x1536", "none",
    [f"{D}/g5v3_hud_v3.png (SAME style and layout; extend it)"],
    "Full mobile game HUD mockup over a soft blurred cool-teal meadow scene with the boy hero Arsam in the middle, matching the reference HUD style exactly (same glossy glass buttons, gold and blue colors, navy panels). Add to the reference: bottom-right four small glossy round move buttons (ring-shaped, each with a different element icon: sand, wing, hourglass, reverse arrow) next to the companion button; a thin glossy horizontal 'Chrono Spark' bar under the heart row, half full with golden sparks; top-center a wide smoke-purple guardian bar with a small cracked wooden mask icon at its left, filled 70 percent; top-right coin, pause and restart buttons. All counters empty or ornamental, no digits, no text.")
add("p0_m2a_open_attic", "Opening panel 1: attic", "2720x1536", "none", [],
    STYLE + " " + PANEL + "a cozy attic room at golden sunset, a wooden desk with an open old notebook and a brass pocket watch lying on it, dusty light shafts through a round window, framed portrait of a young man (the grandfather) on the wall, a 12-year-old boy Arsam (turquoise tunic, messy dark hair) sitting on a chair looking at the desk curiously.")
add("p0_m2b_open_watch", "Opening panel 2: watch trembles", "2720x1536", "none", [],
    STYLE + " " + PANEL + "extreme close-up of the brass pocket watch on the desk trembling, tiny golden vibration lines and dust jumping, the notebook beside it, the boy's eyes widening at the edge of the frame, warm attic light.")
add("p0_m2c_open_book", "Opening panel 3: notebook opens", "2720x1536", "none", [],
    STYLE + " " + PANEL + "the old notebook opening by itself, pages fluttering like wings with golden light spilling out, small sand-light sparkles, the boy leaning back in awe, the pocket watch glowing.")
add("p0_m2d_open_smoke", "Opening panel 4: light and smoke", "2720x1536", "none", [],
    STYLE + " " + PANEL + "golden light and swirling violet smoke pouring through the attic window and from the notebook, the boy shielding his face, swirling time sand and clock gears in the air, dramatic contrast of gold and purple.")
add("p0_m2e_open_sky", "Opening panel 5: watch flies to the sky", "2720x1536", "none", [],
    STYLE + " " + PANEL + "the pocket watch flying up into a huge sunrise sky above a wide misty meadow with a distant castle, a long golden trail behind it, tiny boy silhouette at a small window far below in the corner, vast depth.")
add("p0_r1_ts01c_organic_ground", "Organic ground and path objects kit", "2720x1536", "pink",
    [f"{D}/bg_old_plain_v3.png"],
    "Organic curved ground and path-objects kit for a side-scrolling forest-meadow platformer, two rows (top warm golden old era, bottom cool teal with violet smoke new era). Items separated: rolling-hill ground chunks in several lengths (gentle upslope, downslope, hill crest, valley dip, flat), each with a lush grass lip and soil body; ground ledge with overhang; stone ruin arch in two sizes; broken mossy stone pillar; rope swing platform (a thin plank hanging from two ropes) in 2 sizes; hanging vine; wooden hint signpost with a plain arrow (no text) pointing right and pointing up; mossy stone wall segment with ledges for wall-jumping; crumbling gap edge; golden dew-drop collectible in 4 sizes; a coin-trail arc made of dew-drops; a spiral trail of dew-drops; a leaf-curtain for a hidden alcove.")
add("p0_r2s_tower_interior_sky", "Ruined tower interior far layers", "4096x1365", "none", [],
    STYLE + " Seamless horizontally tileable background strip, layers 1-2 of a ruined clock-tower interior: deep teal-blue stone wall with tall arched windows letting in soft god rays, distant dusty stone stairs, faint smoke haze, calm and a little eerie but kid-friendly. Wide 3:1 aspect ratio, no characters.")
add("p0_r2m_tower_interior_mid", "Ruined tower interior mid layers", "4096x2744", "pink", [],
    "Three separate horizontal parallax layers stacked vertically with pink gaps, seamless left-to-right, each anchored at the bottom, on flat magenta #FF00FF. Ruined clock-tower interior, deep teal-blue palette. Layer 3: large dark wooden wheel disks and tall stone columns. Layer 4: hanging chain curtains and faint dusty smoke-cobweb veils between columns. Layer 5: near stone arches and a crumbling ledge. Closed dark-navy outlines.")
add("p0_r2f_tower_interior_set", "Ruined tower interior set-pieces", "2720x1536", "pink", [],
    "Set-piece sheet for a ruined clock tower, each object separate: rotating plus-shaped wooden crossbeam assembly (hub and big wheel disk as one piece; separate wooden beam; separate metal end cap); a pile of broken clock gears; a hanging chain; a stack of crates; a crumbling stone ledge; a lantern bracket with a lantern; and below, a seamless dark navy foreground silhouette strip of leaves and stalks. Teal-blue palette.")
add("p0_r3o_intro_old", "Intro frames old level (3 panels)", "2720x900", "none", [],
    STYLE + " Three cinematic key frames side by side in one wide image, separated by thin dark-navy gaps, warm golden sunrise: (left) a white flower bud on a green stem opening, a dewdrop falling, over layered misty forest; (middle) a young man in a navy scarf asleep on a grassy hilltop at dawn with a staff beside him; (right) a wide horizon with a distant castle in morning mist and sun rays. Painterly depth, god rays.")
add("p0_r3n_intro_new", "Intro frames new level (3 panels)", "2720x900", "none", [],
    STYLE + " Three cinematic key frames side by side in one wide image, separated by thin dark-navy gaps, cool teal evening with violet smoke: (left) the same white flower now withered and wrapped in smoke on a bent stem; (middle) a branch nest high on a tree with a dark cracked egg in smoke; (right) a wide horizon with a ruined tower and violet clouds. Painterly depth.")
add("p0_r4_leaf_overlays", "Foreground leaf overlays", "2720x1536", "pink", [],
    "Dark navy foreground leaf and branch silhouettes meant as screen-corner overlays: four corner pieces (top-left, top-right, bottom-left, bottom-right) with big leaves and thin stalks, plus three single large leaf silhouettes in different shapes, all solid dark navy with a subtle lighter rim, on flat magenta #FF00FF, 60 px gaps, no text.")

man = []
md = ["# P0 — پرامپت دقیق هر تصویر (۲۸ تصویر) + نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_p0_prompts.py`. همهٔ مسیرها نسبت به ریشهٔ مخزن `pilo/` هستند.\n",
      "> **چطور:** پرامپت داخل کادر را **کامل کپی** کنید. «مرجع» = تصویری که همراه پرامپت به ابزار تصویر می‌دهید (برای یکسان ماندن چهره و سبک). خروجی را با **همان نام** در **همان پوشه** بگذارید؛ روی تصویر چیزی نوشته نشود.\n",
      "> **بعد از گذاشتن فایل‌ها:** `python3 tools/art/check_p0.py` یا به من بگویید «چک کن».\n",
      "> اندازه: همان که کنار هر تصویر آمده؛ اگر ابزار فقط ۱۶:۹ می‌دهد قبول است ولی برای نوارها ۳:۱ بهتر است.\n\n---\n"]
for i, it in enumerate(items, 1):
    path = f"{D}/{it['id']}.png"
    suffix = PINK if it["kind"] == "pink" else NOPINK
    body = it["body"] if it["body"].startswith(STYLE) else STYLE + " " + it["body"]
    prompt = body + " " + suffix
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind=it["kind"], title=it["title"]))
    md.append(f"## {i:02d} — {it['title']}\n")
    md.append(f"- **نام فایل:** `{it['id']}.png`\n- **مسیر:** `{path}`\n- **اندازه:** {it['size']} · **پس‌زمینه:** "
              f"{'صورتی #FF00FF' if it['kind'] == 'pink' else 'بدون صورتی (تصویر کامل)'}\n")
    md.append("- **مرجع برای ضمیمه:** " + ("؛ ".join(f"`{r}`" for r in it["refs"]) if it["refs"] else "ندارد") + "\n")
    md.append("```\n" + prompt + "\n```\n")
open(os.path.join(ROOT, "docs", "35_art_pack", "P0_PROMPTS.md"), "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(os.path.join(ROOT, "tools", "art", "p0_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(len(items), "prompts")
