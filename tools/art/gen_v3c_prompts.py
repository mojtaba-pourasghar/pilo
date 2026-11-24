# Generates docs/41_art_scenario_v3.md and tools/art/v3c_manifest.json (art for docs/40)
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
SC = ("Wide side-scrolling background SCENE painting, 3:1 panorama, layered depth (far, middle, near) with a clear walkable ground strip in the bottom third, "
      "no characters, no text. ")
UI = ("Mobile game menu screen mockup, landscape 16:9, glossy cartoon user-interface style: royal-blue translucent panels with golden filigree corners, "
      "glossy glass buttons (gold primary, blue secondary), wooden-and-glass frames, ribbons, warm lit workshop-market atmosphere. "
      "ALL text fields, price plates and counters are EMPTY ornamental plates: no letters, no digits, no symbols that look like text. ")
A = "assets/art/pair1_sheets/"
V = "assets/art/v3/"
D = "assets/art/v3"
items = []


def add(id_, title, size, kind, refs, body):
    items.append(dict(id=id_, title=title, size=size, kind=kind, refs=refs, body=body))


def E(s):
    return "Animation frame sheet. " + SIDE + " " + s


# ---- chapter 1 scenes, one distinct place per level pair ----
add("v3_scene_valley_old", "Scene: valley of logs (old, pair 2)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A deep green river valley with two high grassy banks, tall tree trunks and cut logs lying on the banks, thick ropes hanging from big branches over the river, blue-green morning mist, a faint waterfall far away, a broken old tandoor oven made of clay beside the water. Warm golden light. " + NOPINK)
add("v3_scene_valley_new", "Scene: log bridge valley (new, pair 2)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "The same valley years later at cool teal dusk: a long wooden log bridge swaying over the river, swinging rope platforms, a cave mouth under the bridge, violet smoke wisps, glowing green traces. " + NOPINK)
add("v3_scene_dam_old", "Scene: river with stone dam (old, pair 3)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A river blocked by a big stone dam, still water behind it, two round stone buttons on the dam wall, stone steps, a spring, a tall waterfall behind the scene, rainbow mist, bright blue water. " + NOPINK)
add("v3_scene_waterfall_new", "Scene: living waterfall with hidden alcove (new, pair 3)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A huge flowing waterfall with a walkable hidden alcove behind the water curtain, wooden platforms over the stream, mist, wall-jump cliffs, rainbow, glowing mirror stones. " + NOPINK)
add("v3_scene_waterfall_dry_new", "Scene: dry riverbed variant (new, pair 3)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "The same place with the waterfall DRY: a cracked dry riverbed, a dark cave in the cliff, dull mirror stones, violet smoke, grey-teal colors. " + NOPINK)
add("v3_scene_roots_old", "Scene: root tunnel underground (old, pair 4)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A dark warm underground tunnel full of thick twisting roots on the ceiling and walls, glowworms, dripping water, a single shaft of light, a glowing sacred hollow with soil ready for a seed at the far end. " + NOPINK)
add("v3_scene_mushroom_night_old", "Scene: giant mushroom night forest (old, pair 5)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A night forest of giant bouncy mushrooms with glowing caps in turquoise and violet, fireflies, star clouds, soft magical light, mushroom caps as platforms at different heights. " + NOPINK)
add("v3_scene_mushroom_valley_new", "Scene: glowing mushroom valley with smoke (new, pair 5)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A cave-like valley of glowing mushrooms, some dark and some lit, thick violet smoke, rotating wooden root beams, glowing green spores. " + NOPINK)
add("v3_scene_antlet_cave_old", "Scene: big cave with light opening (old, pair 6)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A huge cave with a round opening of golden daylight in the roof, rock pillars, a soft bed of moss where a lost fawn could hide, drifting violet smoke at the edges, warm amber light. " + NOPINK)
add("v3_scene_antlerion_den_new", "Scene: Antlerion boss arena (new, pair 6)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A giant cavern boss arena with huge antler-shaped stone pillars, roots, hanging violet smoke, flat arena floor with small ledges on both sides, a glowing amber crystal shape on the far wall, dramatic teal and amber light. " + NOPINK)
# ---- companion transformation, swap ----
add("v3_embri_forms", "Embri: traversal forms (lantern, fire cannon, rocket)", "2720x1536", "pink", [V + "v3_embri_move.png"],
    E("Embri is a tiny clay-oven beetle creature (terracotta body with tile patterns, brass chimney, glowing belly, six stubby legs). Row 1: LANTERN form: Embri transforms 4 frames into a hanging brass lantern with a warm light, then 4 frames glowing loop. Row 2: FIRE CANNON form: transform 3 frames, firing a short flame blast 5 frames, return 3 frames. Row 3: ROCKET KILN form: transform 3 frames, launching upward with a burst of flame and smoke 5 frames, return 3 frames."))
add("v3_tikkit_forms", "Tikkit: traversal forms (time bubble, sand bridge, wings)", "2720x1536", "pink", [V + "v3_tikkit_fly.png"],
    E("Tikkit is a tiny pearly translucent egg-shaped time spirit with an hourglass belly, six clock-hand feathers, big amber eyes. Row 1: TIME BUBBLE form: Tikkit inside a big golden hourglass-sand bubble shield, grow 4 frames and loop 4 frames. Row 2: SAND BRIDGE form: Tikkit spreads golden sand-light into a flat bridge platform 5 frames, platform loop 3 frames, fade 3 frames. Row 3: WINGS CARRY form: Tikkit with big glowing wings lifting a small hook handle 4 frames, loop 4 frames."))
add("v3_swap_fx", "Companion swap effects", "2720x1536", "pink", [A + "g4_fx_sheet.png"],
    "Effect sprite sheet for swapping a companion in and out, each row 6 frames: row 1 warm orange-gold element burst (fire companion); row 2 gold-cream sand-light burst (time companion); row 3 white-blue sparkle burst (neutral); row 4 a glowing summon ring on the ground that shrinks; row 5 a small glowing exit trail. Glossy, additive-friendly, no pink in any effect. " + PINK)
# ---- boss ----
add("v3_antlerion_phase1", "Boss: Antlerion phase 1 (smoke-slumber) frames", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Antlerion: a giant forest deity stag with huge branching antlers carrying tiny trees, an amber crystal heart glowing in its chest. PHASE 1: it is covered in dark violet smoke, antlers drooping, sleepy. Row 1: BREATHING idle 6 frames (large, fill the cell). Row 2: ANTLERSLAM attack: wind-up 3 frames, slam 3 frames, recover 2 frames. Row 3: ROOTLEAP jump 5 frames, SEEDRAIN antlers shaking seeds 3 frames, HIT 2 frames."))
add("v3_antlerion_phase2", "Boss: Antlerion phase 2 (smoke-raged) frames", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Antlerion PHASE 2: smoke rising to the antlers, red-violet glowing eyes, tall sharp antlers. Row 1: ANGRY idle 6 frames. Row 2: ANTLERSTORM spinning antlers 5 frames, MURKCANNON smoke blast from the mouth 4 frames. Row 3: DARK CALL (summons small smoke wisps) 4 frames, WEAK-SPOT OPEN (amber heart exposed glowing) 3 frames, HIT 2 frames."))
add("v3_antlerion_phase3", "Boss: Antlerion phase 3 (lullaby, freed) + Antlet", "2720x1536", "pink", [A + "g2_enemies_new.png"],
    E("Antlerion PHASE 3: smoke scattered, golden glowing body, antlers blooming with white blossoms, peaceful eyes. Row 1: LULLABY sway 6 frames. Row 2: BLOOM burst of petals 4 frames, FREED rising with golden butterflies 5 frames. Row 3: ANTLET, the lost baby fawn with tiny antlers (old era): scared idle 3 frames, crying 3 frames, calmed happy hop 4 frames."))
# ---- cutscene animation parts ----
add("v3_cut_props", "Cutscene animation strips (mission briefings)", "2720x1536", "pink", [A + "g4_fx_sheet.png"],
    "Animation strip sheet for story cutscenes, each row is one animation with equal frames: row 1 a white flower bud OPENING 6 frames; row 2 a glowing egg SHAKING 4 frames; row 3 a brass pocket watch SPINNING its hands 6 frames; row 4 an old notebook OPENING with pages fluttering 6 frames; row 5 a clay tandoor oven LIGHTING UP 5 frames; row 6 a stone dam button PRESSED 3 frames; row 7 a glowing sacred seed spot GROWING a sprout 5 frames; row 8 a mushroom cap PULSING with light 4 frames. Side view, centered, same size in each row.")
add("v3_ui_mission_kit", "Mission briefing UI kit", "2720x1536", "pink", [A + "g5v3_clock_v3.png"],
    "UI element kit for animated mission-briefing cutscenes, each separate: top and bottom cinematic letterbox bar pieces with golden trim; a SKIP button (a glossy round fast-forward arrow, no text); an objective banner ribbon with an hourglass icon and an empty plate; a small scroll with an empty plate; a spotlight ring marker in 3 frames; a hint arrow in 3 frames; an exclamation badge; a star badge.")
# ---- shop / market menus (designs for approval) ----
add("v3_ui_market_hub", "Menu: market hub with 6 tabs", "2720x1536", "none", [A + "g5v3_heart_v3.png", A + "g5v3_result_v3.png"],
    STYLE + " " + UI + "The MARKET HUB: a big wooden market-stall frame; along the top 6 glossy tabs with icons only (tools, heroes, companions, coins, hearts and bundles, outfits); the middle shows a grid of large item cards with empty price plates; a coin and diamond counter pill at the top right; a back button at the top left. " + NOPINK)
add("v3_ui_tools_upgrade", "Menu: tool upgrade screen (levels 1-5)", "2720x1536", "none", [A + "g5v3_card_v3.png"],
    STYLE + " " + UI + "TOOL UPGRADE screen: on the left a large glowing tool (a bow) on a stand; on the right a row of five level slots (three filled with glowing gems, two empty), a before/after stat bar, and a large golden UPGRADE button with an empty price plate and a coin icon; below a scroll of small tool icons to choose another tool. " + NOPINK)
add("v3_ui_heroes_shop", "Menu: heroes screen", "2720x1536", "none", [A + "g5v3_card_v3.png"],
    STYLE + " " + UI + "HEROES screen: a big carousel of tall hero cards (the center card large with a boy archer portrait, the sides smaller; one card dimmed with a padlock), element emblem at the top of each card, an empty plate for the name and price, a glossy blue SELECT button and a gold UNLOCK button. " + NOPINK)
add("v3_ui_companions_shop", "Menu: companions and evolution", "2720x1536", "none", [A + "g5v3_card_v3.png", V + "v3_tikkit_fly.png"],
    STYLE + " " + UI + "COMPANIONS screen: three companion cards on a shelf (a pearly time-spirit egg, a clay-oven beetle, a mirror moth); the selected one is shown big with three evolution stage silhouettes below it and a glowing gem slot; element emblems; an EVOLVE button and a BUY button with empty plates. " + NOPINK)
add("v3_ui_coins_shop", "Menu: coin shop with video reward", "2720x1536", "none", [A + "g5v3_heart_v3.png"],
    STYLE + " " + UI + "COIN SHOP screen with THREE big options as cards: left a stack of coin-pack chests (small, medium, large, empty price plates); center a glossy WATCH VIDEO card with a film-play icon and a small row of three ticket slots (two filled); right a DAILY GIFT card with a glowing gift box. Friendly, no countdown pressure, no red warning. " + NOPINK)
add("v3_ui_purchase_confirm", "Menu: purchase confirm + parent gate", "2720x1536", "none", [A + "g5v3_name_v3.png"],
    STYLE + " " + UI + "PURCHASE CONFIRM popup: a card flipping to show the chosen item with an empty price plate, two buttons (gold CONFIRM, blue CANCEL), and a second panel showing a PARENT GATE: three large number-less puzzle slots (a simple pattern puzzle) with a friendly owl icon. " + NOPINK)
add("v3_ui_market_icons", "Market icon kit", "2720x1536", "pink", [A + "g5v3_hud_v3.png"],
    "UI icon kit for a mobile game market, each icon separate in glossy style with a gold rim: currency icons (coin, diamond, heart, aura gem, video ticket, star); 6 tab icons (tools, heroes, companions, coins, bundles, outfits); 12 tool icons (time bow, scarf glider, root staff, slingshot, brass lantern, light lens, seed bag, quiver, spring boots, magnet leaf, shield bubble, hourglass); padlock closed and open, check mark, plus sign, NEW badge shape (no text), a price ribbon plate empty, an empty wide button in gold, blue and green. " + PINK)

man = []
md = ["# هنر سناریوی کامل (۲۵ تصویر) — پرامپت دقیق، نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_v3c_prompts.py`. هدف: `docs/40`. مسیرها نسبت به ریشهٔ مخزن `pilo/`.\n",
      "> «مرجع» = تصویری که همراه پرامپت ضمیمه می‌کنید. بعد از گذاشتن فایل‌ها: `python3 tools/art/check_v3c.py` یا بگویید «چک کن».\n",
      "> **برگه‌های برش‌خور مجنتای خالص `#FF00FF` (نه سفید)**؛ صحنه‌ها و طرح منوها تصویر کامل. منوها **طرح برای تأیید** هستند؛ تا تأیید شما ساخته نمی‌شوند.\n",
      "> **ترتیب پیشنهادی:** ۱) صحنه‌های جفت ۲ و ۳ (۴ تصویر) ۲) فرم‌های همراه (embri_forms، tikkit_forms) ۳) Antlerion (۳) ۴) منوها (۷) ۵) بقیه.\n\n---\n"]
for i, it in enumerate(items, 1):
    path = D + "/" + it["id"] + ".png"
    body = it["body"]
    if it["kind"] == "pink" and "IMPORTANT BACKGROUND RULE" not in body:
        body = STYLE + " " + body + " " + PINK
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind=it["kind"], title=it["title"]))
    md.append("## %02d — %s\n" % (i, it["title"]))
    md.append("- **نام فایل:** `%s.png`\n- **مسیر:** `%s`\n- **اندازهٔ ایده‌آل:** %s · **پس‌زمینه:** %s\n" % (
        it["id"], path, it["size"], "مجنتا #FF00FF" if it["kind"] == "pink" else "تصویر کامل (بدون مجنتا)"))
    md.append("- **مرجع:** " + ("؛ ".join("`%s`" % r for r in it["refs"]) if it["refs"] else "ندارد") + "\n")
    md.append("```\n" + body + "\n```\n")
open(os.path.join(ROOT, "docs", "41_art_scenario_v3.md"), "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(os.path.join(ROOT, "tools", "art", "v3c_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(len(items), "prompts")
