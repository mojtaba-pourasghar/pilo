# Generates docs/39_art_gameplay_sections.md and tools/art/v3b_manifest.json (art for docs/38)
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
SIDE = ("PURE SIDE VIEW (profile), facing RIGHT, like a 2D side-scrolling platformer sprite, NOT front view. Grid of equal rows, the same size "
        "of creature in every frame, feet or body on the same baseline in each row, frames side by side with clear gaps.")
D = "assets/art/v3"
items = []


def add(id_, title, size, kind, refs, body):
    items.append(dict(id=id_, title=title, size=size, kind=kind, refs=refs, body=body))


MURK = ("made of dark violet-indigo smoke with a cracked pale wooden mask and small wooden limbs (a creature captured by dark Murk smoke); "
        "the FREED form is a bright, happy, tiny creature that appears when the smoke clears")


def E(s):
    return "Animation frame sheet. " + SIDE + " " + s


A = "assets/art/pair1_sheets/"
add("v3_enemy_murkwisp", "Enemy: Murkwisp (floating smoke) + freed Cindrel", "2720x1536", "pink", [A + "g2_enemies_old.png"],
    E("Murkwisp: a small floating blob of dark violet smoke with two big round yellow eyes and a smoke tail. Row 1: FLOAT bobbing 6 frames. Row 2: ALERT (eyes narrow, red-orange glow) 2 frames, LUNGE attack 3 frames, HIT 2 frames. Row 3: FREED smoke-puff burst 4 frames then Cindrel (a tiny happy red-orange ember sprite with a flame tail) hopping away 4 frames."))
add("v3_enemy_murkling", "Enemy: Murkling (walker) + freed Nimbeak", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Murkling: a small humanoid creature " + MURK + ", stubby wooden arms. Row 1: PATROL WALK cycle 8 frames. Row 2: ALERT with glowing mask crack 2 frames, ATTACK swing 3 frames, HIT recoil 2 frames. Row 3: FREED puff 3 frames, then Nimbeak (a tiny fluffy indigo-white cloud bird with a zigzag lightning tail) flying 5 frames."))
add("v3_enemy_stiltmurk", "Enemy: Stiltmurk (stilt thrower) + freed Rootstomp", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Stiltmurk: a tall smoke creature balancing on two long wooden root stilts, periscope-like eyes. Row 1: STRIDE on stilts 8 frames. Row 2: THROW a pebble 4 frames, ALERT 2 frames, HIT 2 frames. Row 3: FREED puff 3 frames, then Rootstomp (a sturdy round mossy tree-stump creature with a sprout crown and a seed lantern on its back) walking 5 frames."))
add("v3_enemy_barkshield", "Enemy: Barkshield (shield) + freed Shardling", "2720x1536", "pink", [A + "g2_barkshield_v1.png"],
    E("Barkshield: a small smoke creature carrying a big round tree-bark shield with an arabesque medallion, root feet. Row 1: MARCH with the shield forward 6 frames. Row 2: SHIELD BASH 3 frames, STUNNED tilted back with stars 3 frames, HIT 2 frames. Row 3: FREED puff 3 frames then Shardling (a tiny prismatic crystal-shard spirit) hopping 5 frames."))
add("v3_enemy_weaver", "Enemy: Murkweaver (thread spider) + freed Lanternit", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Murkweaver: a smoke spider with candle-flame eyes hanging on a silk thread (draw a short vertical thread above it). Row 1: DANGLE swaying 4 frames, DROP down fast 3 frames, CLIMB UP 3 frames. Row 2: ALERT 2 frames, THREAD CUT falling 3 frames, HIT 2 frames. Row 3: FREED puff 3 frames then Lanternit (a small glowing lantern-moth) fluttering 5 frames."))
add("v3_enemy_gloombat", "Enemy: Gloombat (diving bat) + freed Lampmoth", "2720x1536", "pink", [A + "g2_enemies_old.png"],
    E("Gloombat: a small bat made of dark violet smoke with glowing yellow eyes and torn wings. Row 1: FLY flapping 8 frames. Row 2: ALERT hanging upside-down 2 frames, DIVE attack 4 frames, HIT 2 frames. Row 3: FREED puff 3 frames then Lampmoth (a tiny soft glowing moth) fluttering 5 frames."))
add("v3_enemy_rollerbug", "Enemy: Rollerbug (rolls down slopes) + freed", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Rollerbug: a round armadillo-bug made of dark smoke and bark plates that curls into a ball and rolls. Row 1: WALK uncurled 6 frames. Row 2: CURL UP 3 frames, ROLLING ball spinning 6 frames (show rotation). Row 3: HIT 2 frames, STUNNED 2 frames, FREED puff 3 frames then a tiny happy beetle spirit hopping 4 frames."))
add("v3_enemy_spitter", "Enemy: Spitter (seed-shooting plant) + freed", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Spitter: a thorny smoke-touched flower plant rooted in a small mound with a big mouth bud that spits seeds in an arc. Row 1: IDLE swaying 6 frames. Row 2: WIND-UP 3 frames, SPIT 3 frames with a flying seed, HIT 2 frames. Row 3: FREED puff 3 frames then a happy blooming flower spirit 4 frames."))
add("v3_clockcrow_frames", "Guardian: Clockcrow frames + freed Tickwing", "2720x1536", "pink", [A + "g2_enemies_old.png"],
    E("Clockcrow: a big mechanical crow with a clock in its chest, brass gears on its wings, violet smoke leaking. Row 1: HOVER flapping 8 frames. Row 2: TELEGRAPH (red-orange glow) 3 frames, DIVE 4 frames, LAND on the ground 2 frames. Row 3: STUNNED on the ground 3 frames, HIT 2 frames, FREED puff 3 frames, then Tickwing (golden-cream clock-feathered bird) flapping 4 frames."))
add("v3_stumpguard_frames", "Guardian: Stumpguard frames + freed Verdlin baby", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Stumpguard: a big round tree-trunk guardian with thorny bark, white flower and pomegranate crown, moss. Row 1: IDLE breathing 4 frames, ROLL spinning 6 frames. Row 2: THROW a red pomegranate 4 frames, TELEGRAPH 2 frames, WEAK SPOT glowing thread on the back 2 frames. Row 3: HIT 2 frames, ENRAGED 2 frames, FREED puff 3 frames then Verdlin baby (a tiny fawn spirit of vines and moss with leaf antlers and a seed lantern) walking 4 frames."))
add("v3_obst_hazards", "Hazards: crumbling bridge, falling stones, spike roots, web, geyser, swinging log", "2720x1536", "pink", ["assets/art/v3/v3_props_motion.png"],
    "Side-view obstacle sprites for a platformer, each separate: (1) wooden plank bridge piece in 3 states: intact, cracking, falling apart; (2) falling stone in 3 sizes and a small ground shadow marker for each; (3) spiky thorn roots rising from a pit in 3 sizes; (4) dark violet smoke cobweb in 3 shapes; (5) steam geyser vent with a 4-frame steam column animation; (6) a heavy swinging wooden log hanging on two chains, shown at 3 swing angles; (7) a round rolling boulder; (8) a thorn bush in 2 sizes; (9) a dry bush that can be burnt in 2 sizes.")
add("v3_obst_platforms", "Platforms and boosters: moving, leaf, spring, ramp, zipline", "2720x1536", "pink", ["assets/art/v3/v3_props_motion.png"],
    "Side-view platformer element sprites, each separate: (1) wooden moving platform with rope ends in 2 sizes; (2) floating leaf platforms in 3 sizes; (3) spring mushroom in 3 frames: relaxed, compressed, stretched; (4) bounce flower in 3 frames; (5) speed-boost leaf pad glowing in 3 frames; (6) launch ramp (a wooden and stone ramp) in 2 sizes; (7) a long slide slope piece of mossy stone; (8) a zipline vine with a handle loop and its two anchor posts; (9) a tall mossy climbing wall segment with ledges; (10) a branch platform sticking out of a tree trunk in 3 sizes.")
add("v3_obst_gates", "Gates, switches, checkpoint, exit", "2720x1536", "pink", [A + "p0_bg_old_setpieces.png"],
    "Side-view platformer element sprites, each separate: (1) stone sliding door in 2 states: closed and open; (2) a stone lever in 2 states; (3) a mirror switch (a round mirror on a stand) in 2 states: dull and glowing; (4) a sun-lock gate with a round sun medallion in 2 states; (5) checkpoint banner pole in 3 frames: off, lighting, on; (6) exit portal arch of carved stone in 3 frames: closed, opening, open with golden light; (7) a wooden hint signpost with a plain arrow (no text) pointing right, up and down; (8) a hidden-alcove leaf curtain; (9) a nest on a tall branch, empty, and the same nest with a glowing egg.")
add("v3_collect_items", "Collectibles: dew-drops, seeds, hearts, pickups", "2720x1536", "pink", [A + "g4_fx_sheet.png"],
    "Collectible item sprites for a platformer, each separate with a small sparkle: (1) a golden dew-drop coin spinning in 6 frames; (2) a big golden dew-drop; (3) a hidden-star bud in 3 frames: closed, opening, open; (4) a glowing seed; (5) a heart; (6) a shield-bubble pickup; (7) a magnet-leaf pickup; (8) a time-hourglass pickup; (9) a small glowing butterfly bonus in 4 frames; (10) a pickup sparkle burst in 5 frames.")
SC = ("Wide side-scrolling background SCENE painting, 3:1 panorama, layered depth (far, middle, near) with a clear walkable ground strip at the bottom third, "
      "no characters, no text. ")
add("v3_scene_ruins_old", "Scene: sunlit stone ruins hall (old era)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "Sunlit ruins: mossy stone arches and columns, steps climbing up to the right, broken walls, light shafts through gaps in the roof, vines, golden warm light, a few doorways leading to dark rooms. " + NOPINK)
add("v3_scene_cave_old", "Scene: cave under the hill (old era)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A cave tunnel going downhill to the right: warm brown rock, glowworms and small glowing mushrooms, dripping water, hanging roots, a bright opening of daylight far behind, crystals. " + NOPINK)
add("v3_scene_canyon_old", "Scene: canyon with waterfall and bridge (old era)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A green canyon: a tall waterfall falling into a stream, a long wooden rope bridge across the gap, rock cliffs with ledges, a rainbow in the mist, birds. " + NOPINK)
add("v3_scene_canopy_old", "Scene: inside the giant tree, vertical shaft (old era)", "1536x3072", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " TALL vertical background SCENE painting 1:2: the inside of a giant hollow tree trunk seen from the side, a vertical shaft going up with branches as ledges, light coming from the top, vines, leaves, a nest high up, warm golden-green light. No characters. " + NOPINK)
add("v3_scene_cave_new", "Scene: smoky cave (new era)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A cave tunnel going downhill to the right, cool teal and violet: glowing green seeds and mushrooms, violet smoke wisps, broken old stone, hanging roots, faint stars of light. " + NOPINK)
add("v3_scene_canyon_new", "Scene: broken canyon (new era)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A canyon years later: the waterfall is half dry, the rope bridge is broken, violet smoke drifts, glowing green traces on the cliffs, floating islands in the distance. " + NOPINK)
add("v3_scene_canopy_new", "Scene: giant tree shaft with smoke (new era)", "1536x3072", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " TALL vertical background SCENE painting 1:2: the inside of a giant hollow tree trunk with violet smoke and glowing green traces, branches as ledges, a vertical shaft going up, a dark cracked nest high up, teal and violet light. No characters. " + NOPINK)

man = []
md = ["# هنر گیم‌پلی (۲۱ تصویر) — پرامپت دقیق، نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_v3b_prompts.py`. هدف: `docs/38`. همه از پهلو و رو به راست. مسیرها نسبت به ریشهٔ مخزن `pilo/`.\n",
      "> «مرجع» = تصویری که همراه پرامپت ضمیمه می‌کنید. بعد از گذاشتن فایل‌ها: `python3 tools/art/check_v3b.py` یا بگویید «چک کن».\n",
      "> **برگه‌های برش‌خور باید روی مجنتای خالص `#FF00FF` باشند (نه سفید).** صحنه‌های کامل بدون مجنتا. اگر ابزار اندازهٔ دقیق نمی‌دهد، نزدیک‌ترین نسبت کافی است.\n",
      "> **ترتیب پیشنهادی:** اول ۱۰ دشمن، بعد ۴ عنصر، بعد ۷ صحنه (اگر وقت کم است: murkwisp، murkling، obst_hazards، obst_platforms، scene_ruins_old، scene_cave_old).\n\n---\n"]
for i, it in enumerate(items, 1):
    path = D + "/" + it["id"] + ".png"
    body = it["body"]
    if it["kind"] == "pink":
        body = STYLE + " " + body + " " + PINK
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind=it["kind"], title=it["title"]))
    md.append("## %02d — %s\n" % (i, it["title"]))
    md.append("- **نام فایل:** `%s.png`\n- **مسیر:** `%s`\n- **اندازهٔ ایده‌آل:** %s · **پس‌زمینه:** %s\n" % (
        it["id"], path, it["size"], "مجنتا #FF00FF" if it["kind"] == "pink" else "بدون مجنتا (تصویر کامل)"))
    md.append("- **مرجع:** " + ("؛ ".join("`%s`" % r for r in it["refs"]) if it["refs"] else "ندارد") + "\n")
    md.append("```\n" + body + "\n```\n")
open(os.path.join(ROOT, "docs", "39_art_gameplay_sections.md"), "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(os.path.join(ROOT, "tools", "art", "v3b_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(len(items), "prompts")
