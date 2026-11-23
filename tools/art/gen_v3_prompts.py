# Generates docs/37_art_v3_side_view.md and tools/art/v3_manifest.json (the side-view art request, docs/36)
import json, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STYLE = ("Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, "
         "chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, "
         "sellable casual-game quality. Original design with Persian/Iranian-inspired motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15.")
PINK = ("IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, "
        "NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. "
        "No part of any subject is pink or magenta. Every item fully separated with at least 60 px of empty magenta between items, nothing "
        "overlapping or touching, nothing cropped at the edges. Each item has a closed thick dark-navy outline. Flat even lighting. "
        "No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.")
NOPINK = "No text, letters, numbers, labels, watermark or logo. No magenta or pink background. Do not imitate any existing game, character or brand."
D = "assets/art/v3"
SIDE = ("PURE SIDE VIEW (profile), facing RIGHT, the whole body seen from the side exactly like a 2D side-scrolling platformer character, NOT front view, "
        "NOT three-quarter view. Same proportions in every cell, feet on the same baseline row in each row, grid of equal cells.")
ARS = ("Arsam: a 12-year-old boy, round-oval head, straight dark eyebrows, big warm-brown eyes, calm smile, messy dark hair with one stubborn cowlick, "
       "turquoise tunic with gold trim, brown boots, small leather quiver on his back, golden-yellow scarf that flows behind him")
GF = ("the young grandfather (about 20 years old): tidy dark hair, navy scarf that flows behind, cream tunic with gold embroidery, orange trousers, "
      "brown boots, leather backpack with a small hourglass, walking staff, slingshot at the belt, brass lantern at the belt")
EMB = ("Embri: a tiny clay-oven beetle creature (like a small Persian tandoor oven with legs): terracotta body with tile patterns, small brass chimney "
       "on top puffing a few sparks, glowing molten belly window, six stubby legs, big round friendly eyes, about 1/4 the height of the hero")
TIK = ("Tikkit: a tiny pearly translucent egg-shaped time spirit with a small hourglass in its belly, six golden clock-hand feathers around it acting as "
       "wings, big amber eyes, a star-shaped tail")
items = []


def add(id_, title, size, kind, refs, body):
    items.append(dict(id=id_, title=title, size=size, kind=kind, refs=refs, body=body))


# ---- heroes (side view frames) ----
add("v3_arsam_run", "Arsam: run and walk cycles (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_arsam_parts.png (face and outfit)"],
    f"Animation frame sheet of {ARS}. {SIDE} Row 1: a RUN cycle of 8 frames (contact, down, passing, up, contact other leg, down, passing, up), body leaning forward, arms pumping, scarf streaming back. Row 2: a WALK cycle of 6 frames. Row 3: IDLE breathing 4 frames and a STOP/skid 2 frames.")
add("v3_arsam_air", "Arsam: jump, fall, glide, wall, slide (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_arsam_parts.png"],
    f"Animation frame sheet of {ARS}. {SIDE} Row 1: JUMP: anticipation crouch, take-off stretch, rising, apex, falling, landing squash (6 frames). Row 2: GLIDE with the scarf opening into two glowing light wings (3 frames), FLOAT pose (2), ROPE SWING hanging on a rope (3 frames). Row 3: WALL-SLIDE hand on a wall (2 frames), WALL-JUMP kick off (2), GROUND SLIDE (2), CROUCH (2). Draw a short plain wall segment only where needed for the wall poses.")
add("v3_arsam_actions", "Arsam: bow, hurt, victory (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_arsam_parts.png", "assets/art/pair1_sheets/p0_h01t_arsam_tools.png"],
    f"Animation frame sheet of {ARS}, holding a wooden time bow. {SIDE} Row 1: BOW draw sequence: raise bow, nock arrow, half draw, full draw (4 frames), release with the string vibrating and body recoil (2 frames). Row 2: aiming UP at 45 degrees (2 frames), aiming DOWN 30 degrees (2), HURT recoil (2), STUNNED (1). Row 3: VICTORY jump with the bow raised (3 frames), happy wave (2), surprised (1), sleeping/sitting (2).")
add("v3_grandfather_run", "Grandfather: run and walk cycles (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_grandfather_parts.png"],
    f"Animation frame sheet of {GF}. {SIDE} Row 1: a RUN cycle of 8 frames, a little heavier and steadier than a boy, scarf streaming back, staff carried in the back hand. Row 2: WALK cycle 6 frames, with the staff tapping the ground every second step. Row 3: IDLE 4 frames leaning on the staff, STOP 2 frames.")
add("v3_grandfather_air", "Grandfather: jump, fall, pole-vault, swing (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_grandfather_parts.png"],
    f"Animation frame sheet of {GF}. {SIDE} Row 1: JUMP 6 frames (anticipation, take-off, rise, apex, fall, landing squash). Row 2: POLE-VAULT jump with the root staff planted and bent, 5 frames. Row 3: ROPE SWING hanging on a rope 3 frames, CLIMB a vine 3 frames, CROUCH 2 frames.")
add("v3_grandfather_actions", "Grandfather: tools, carrying the egg (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_grandfather_parts.png", "assets/art/pair1_sheets/p0_h02t_grandfather_tools.png"],
    f"Animation frame sheet of {GF}. {SIDE} Row 1: CARRYING a glowing pearly egg in both hands in front of the chest: careful WALK cycle 6 frames. Row 2: PLACE the egg into a nest (4 frames), PLANT a seed tapping the staff on the ground (4 frames). Row 3: SLINGSHOT: spin the sling overhead 4 frames, release 2 frames; LANTERN raise 3 frames. Row 4: HURT 2, VICTORY 2, SLEEPING on the grass 2, waking up and stretching 3.")
# ---- companions ----
add("v3_embri_move", "Embri: run, hop, idle (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_tikkit_evolution_v1.png (style only)"],
    f"Animation frame sheet of {EMB}. {SIDE} Row 1: RUN cycle 8 frames (legs scurrying, chimney bobbing, sparks). Row 2: HOP up a ledge 5 frames, LEAP across a gap 3 frames. Row 3: IDLE look around 4 frames, TURN around 3 frames, CATCH UP sprint 3 frames.")
add("v3_embri_actions", "Embri: light, burn, react (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_tikkit_evolution_v1.png (style only)"],
    f"Animation frame sheet of {EMB}. {SIDE} Row 1: LIGHT UP the belly glow growing 4 frames with a soft light ring; BURN a dry bush with a short flame breath 4 frames. Row 2: HAPPY bounce 3 frames, PICK UP a coin dew-drop 3 frames, SURPRISED 2. Row 3: HURT 2, SLEEPING curled with Z-less peaceful sleep 3 frames, WAKE UP 2.")
add("v3_tikkit_fly", "Tikkit: fly, lift, cast (side view)", "2720x1536", "pink", ["assets/art/pair1_sheets/g2_tikkit_evolution_v1.png"],
    f"Animation frame sheet of {TIK}. {SIDE} Row 1: FLY cycle 8 frames (feather-wings flapping, tail trailing sand-light). Row 2: LIFTWING lifting upward 4 frames, SANDBURST casting 4 frames. Row 3: HAPPY loop 3, HURT 2, SLEEPING 3, HATCH-greeting wave 3.")
# ---- terrain & props ----
add("v3_terrain_old", "Terrain kit, old era (curved ground textures)", "2720x1536", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    "Terrain texture kit for a curved side-scrolling ground, warm golden sunrise meadow. Items separated: (1) three variants of a horizontal seamless GRASS-LIP strip 1024x160 (lush grass blades on top, flowers, a thick dark-navy outline along the bottom edge) that tiles left-right; (2) a seamless SOIL FILL tile 512x512 (brown earth with small stones and root lines, no outline); (3) a seamless ROCK FACE tile 512x512 (mossy stone with arabesque tile carvings); (4) four ROOT/VINE pieces hanging down from the grass lip; (5) three mossy boulder pieces; (6) a wooden plank bridge segment and a bridge post.")
add("v3_terrain_new", "Terrain kit, new era (curved ground textures)", "2720x1536", "pink", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    "Terrain texture kit for a curved side-scrolling ground, cool teal evening world years later with violet smoke. Items separated: (1) three variants of a horizontal seamless GRASS-LIP strip 1024x160 (dim teal grass, glowing green traces, a thick dark-navy outline along the bottom) that tiles left-right; (2) a seamless SOIL FILL tile 512x512 (dark earth, cracks, small glowing seeds); (3) a seamless ROCK FACE tile 512x512 (cracked dark stone with violet smoke wisps); (4) four hanging ROOT/VINE pieces; (5) three broken mossy ruin boulders; (6) a broken plank bridge segment and a post.")
add("v3_props_motion", "Motion props: rope swing, vine, signs, arches, columns", "2720x1536", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    "Prop sheet for a side-scrolling platformer, warm meadow: ROPE SWING (two ropes hanging from the top with a thin wooden plank, in 2 sizes), a long hanging VINE, a rope with a knot, a wooden HINT SIGNPOST with a plain arrow (no text) pointing right and one pointing up, a stone RUIN ARCH in 3 sizes (mossy), a broken mossy COLUMN in 3 heights, a big fallen LOG, a stack of ROUND STONES, a large LEAF platform, a hanging lantern on a hook. Each item separated.")
add("v3_props_tower", "Tower props: crossbeam wheel, chains, webs, wall", "2720x1536", "pink", ["assets/art/pair1_sheets/p0_r2f_tower_interior_set.png"],
    "Prop sheet for a dark blue ruined tower interior in a side-scrolling platformer: a rotating plus-shaped wooden CROSSBEAM (hub, beam, metal end cap with small studs, big dark wheel disc behind it), a long hanging CHAIN in 2 lengths, a smoky cobweb in 3 shapes, a stone WALL section with mossy ledges for wall-jumping in 2 heights, a crumbling stone LEDGE, a stack of crates, a lantern on a bracket, broken clock gears pile, a stone doorway. Each item separated.")
# ---- backgrounds ----
LAYER = ("Seamless horizontally tileable side-scrolling parallax layer, TALL image 3072 px wide by 2048 px high, the interesting content in the lower "
         "two thirds, the top of the image fades softly into transparent-looking haze (do not draw a hard top edge). ")
add("v3_bg_old_sky", "Old world: sky layer (opaque)", "3072x2048", "none", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    STYLE + " Tall sky background layer, warm golden sunrise, soft layered clouds, sun glow with long god-ray beams, a few distant birds, gradient from deep blue at the top to warm gold at the horizon. No ground, no characters. " + NOPINK)
add("v3_bg_old_far", "Old world: far silhouettes", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    LAYER + "Layer FAR: snowy blue mountains and a distant castle with domes in morning mist, very hazy blue desaturated colors. On flat magenta above the silhouettes.")
add("v3_bg_old_village", "Old world: misty hills and village", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    LAYER + "Layer MIDFAR: rolling hills with a hilltop village of small domed towers, cypress trees, a stone aqueduct ruin, a waterfall in the distance, layered mist between hills, hazy green-blue colors. On flat magenta above the silhouettes.")
add("v3_bg_old_trees", "Old world: giant trees and arches", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    LAYER + "Layer MID: one huge thousand-year tree with a wide crown and exposed roots, a tall stone arch ruin covered in moss and vines, two smaller trees, god rays slanting through leaves, medium saturation warm light. On flat magenta above.")
add("v3_bg_old_near", "Old world: near foliage", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_old_plain_v3.png"],
    LAYER + "Layer NEAR: lush saturated bushes, tall grass, large flowers, ferns, a tilted mossy column, hanging vines from the top corners, rich saturated colors. On flat magenta above.")
add("v3_bg_old_front", "Old world: dark foreground silhouettes", "3072x1024", "pink", ["assets/art/pair1_sheets/p0_r4_leaf_overlays.png"],
    "Seamless horizontally tileable foreground strip 3072x1024, solid dark navy silhouettes with a faint lighter rim: big leaves and stalks rising from the bottom, thin vines and leaf clusters hanging from the top. On flat magenta #FF00FF. No text.")
add("v3_bg_new_sky", "New world: sky layer (opaque)", "3072x2048", "none", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    STYLE + " Tall sky background layer, cool teal evening, violet smoke clouds, floating islands far away with thin waterfalls, faint stars, a smoky ship silhouette, gradient from dark blue-violet at the top to teal-green at the horizon. No ground, no characters. " + NOPINK)
add("v3_bg_new_far", "New world: far ruins", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    LAYER + "Layer FAR: a ruined domed castle city overgrown with green on a far mountain, hazy blue-violet mist, a few floating islands. On flat magenta above.")
add("v3_bg_new_village", "New world: smoky hills and ruins", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    LAYER + "Layer MIDFAR: hills with broken towers and arches, violet smoke trails rising, misty valleys, teal-green colors. On flat magenta above.")
add("v3_bg_new_trees", "New world: giant glowing tree and ruins", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    LAYER + "Layer MID: a huge lush green glowing thousand-year tree with golden-green light, a ruined stone shrine arch with a dull mirror, broken columns, violet smoke wisps, fireflies. On flat magenta above.")
add("v3_bg_new_near", "New world: near foliage and smoke", "3072x2048", "pink", ["assets/art/pair1_sheets/bg_new_plain_v3.png"],
    LAYER + "Layer NEAR: dark teal bushes, purple flowers, glowing green seeds, broken mossy stones, hanging roots, smoke wisps. On flat magenta above.")
add("v3_bg_new_front", "New world: dark foreground silhouettes", "3072x1024", "pink", ["assets/art/pair1_sheets/p0_r4_leaf_overlays.png"],
    "Seamless horizontally tileable foreground strip 3072x1024, solid dark navy-violet silhouettes with a faint teal rim: big leaves, broken branches and stalks rising from the bottom, thin roots hanging from the top. On flat magenta #FF00FF. No text.")

man = []
md = ["# هنر نسخهٔ ۳ — نمای جانبی (۲۵ تصویر) + پرامپت دقیق، نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_v3_prompts.py`. هدف: `docs/36`. **همه‌چیز از پهلو (نیم‌رخ) و رو به راست.** بدون متن روی تصویر. مسیرها نسبت به ریشهٔ مخزن `pilo/`.\n",
      "> «مرجع» = تصویری که همراه پرامپت به ابزار تصویر می‌دهید تا چهره و سبک یکسان بماند. اگر ابزار فقط ۱۶:۹ می‌دهد و برای لایه‌های پس‌زمینه ۳:۲ بهتر است، همان نزدیک‌ترین را بسازید.\n",
      "> بعد از گذاشتن فایل‌ها: `python3 tools/art/check_v3.py` یا بگویید «چک کن».\n",
      "> **پس‌زمینهٔ برگه‌های برش‌خور باید مجنتای خالص `#FF00FF` باشد (نه سفید).**\n\n---\n"]
for i, it in enumerate(items, 1):
    path = f"{D}/{it['id']}.png"
    body = it["body"]
    if it["kind"] == "pink" and "IMPORTANT BACKGROUND RULE" not in body:
        body = (STYLE + " " + body + " " + PINK) if not body.startswith(STYLE) else body + " " + PINK
    elif it["kind"] == "none" and not body.startswith(STYLE):
        body = STYLE + " " + body + " " + NOPINK
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind=it["kind"], title=it["title"]))
    md.append(f"## {i:02d} — {it['title']}\n")
    md.append(f"- **نام فایل:** `{it['id']}.png`\n- **مسیر:** `{path}`\n- **اندازه:** {it['size']} · **پس‌زمینه:** "
              f"{'مجنتا #FF00FF' if it['kind'] == 'pink' else 'بدون مجنتا (تصویر کامل)'}\n")
    md.append("- **مرجع برای ضمیمه:** " + ("؛ ".join(f"`{r}`" for r in it["refs"]) if it["refs"] else "ندارد") + "\n")
    md.append("```\n" + body + "\n```\n")
open(os.path.join(ROOT, "docs", "37_art_v3_side_view.md"), "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(os.path.join(ROOT, "tools", "art", "v3_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(len(items), "prompts")
