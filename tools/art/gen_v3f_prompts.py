# Generates docs/44_art_redesign_enemies_interactive.md and tools/art/v3f_manifest.json
import json, os
ROOT = "c:/MyData/Projects/Android/Pilo/pilo"
STYLE = ("Premium mobile-game cartoon illustration with BOLD DYNAMIC SHAPES: thick dark-navy outlines (#2A1F3D), rich saturated glossy colors, "
         "two-tone cel shading with strong rim light, a clear readable silhouette, expressive faces and poses, original design with Persian/Iranian-inspired "
         "motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15 (cool and a little mischievous, never gory or scary).")
COOL = ("DESIGN BRIEF: these must look COOL, CHARACTERFUL and POLISHED like top-tier mobile game art, not cute generic blobs and not flat clip-art: "
        "strong personality, dynamic asymmetric anatomy, layered materials (wood, bark, brass, smoke, glowing cracks), glowing accents, visible weight and "
        "anticipation in the poses, secondary motion (cloth, smoke tails, loose threads) drawn into the frames. ")
PINK = ("IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, "
        "NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. "
        "No part of any subject is pink or magenta. Every frame fully separated by at least 150 px of empty magenta, nothing overlapping or touching, "
        "nothing cropped at the edges. No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.")
SIDE = ("PURE SIDE VIEW (profile), facing RIGHT. STRICT LAYOUT: ONE animation per row, AT MOST 8 frames per row, equal-sized cells, the same scale in every "
        "frame, feet or body on the same baseline in each row, frames side by side separated by wide empty gaps. ")
D = "assets/art/v3"
A = "assets/art/pair1_sheets/"
items = []


def add(id_, title, size, refs, body):
    items.append(dict(id=id_, title=title, size=size, refs=refs, body=body))


def enemy(id_, title, refs, who, rows):
    add(id_, title, "2720x1536", refs, COOL + SIDE + who + " Rows (top to bottom): " + rows + " " + STYLE)


FREED = ("After it is freed the dark smoke blows away and its TRUE FORM appears: bright, warm, grateful and charming (not a different monster).")
enemy("v3f_e_wisp", "Enemy v2: Wispfiend (smoke spirit) + freed Cindrel", [A + "g2_enemies_old.png"],
      "ENEMY: a mischievous smoke spirit: a swirling violet-indigo smoke body with a ragged flowing tail, two big glowing yellow eyes with sharp brows, a half pale wooden mask clinging to one side, orange sparks drifting off it. " + FREED + " Freed form: Cindrel, a tiny red-orange ember sprite with a flame tail and a joyful grin.",
      "1 FLOAT idle 8 frames (smoke tail waving); 2 ALERT 3 frames (eyes flare, mask glows red-orange) ; 3 LUNGE attack 6 frames with a streaking smoke tail; 4 HIT recoil 3 frames; 5 SMOKE-BURST defeat 6 frames; 6 Cindrel freed hopping and waving 8 frames.")
enemy("v3f_e_imp", "Enemy v2: Murkling (masked imp) + freed Nimbeak", [A + "g2_enemies_new.png"],
      "ENEMY: a small imp-knight made of dark smoke: a big cracked wooden mask with a glowing crack and one burning eye, ragged smoke cape, wiry wooden arms with a knobby club, bouncy confident stance. " + FREED + " Freed form: Nimbeak, a fluffy indigo-white cloud bird with a lightning-zigzag tail.",
      "1 PATROL WALK 8 frames (swagger, cape flowing); 2 ALERT 3 frames (rears back, mask crack glows); 3 CLUB SWING attack 6 frames; 4 HIT 3 frames; 5 DEFEAT burst 6 frames; 6 Nimbeak flying away 8 frames.")
enemy("v3f_e_stilt", "Enemy v2: Stiltmurk (stilt walker) + freed Rootstomp", [A + "g2_enemies_new.png"],
      "ENEMY: a tall lanky smoke creature on two long jointed wooden root stilts, a periscope-like brass lens eye on a long neck, a sling of pebbles at its hip, comically precise balance. " + FREED + " Freed form: Rootstomp, a sturdy mossy tree-stump creature with a sprout crown and a seed lantern.",
      "1 STRIDE on stilts 8 frames; 2 ALERT 3 frames (lens swings toward the hero); 3 PEBBLE THROW 6 frames; 4 HIT wobble 3 frames; 5 TOPPLE and burst 6 frames; 6 Rootstomp walking 8 frames.")
enemy("v3f_e_barkshield", "Enemy v2: Barkshield (shield knight) + freed Shardling", [A + "g2_barkshield_v1.png"],
      "ENEMY: an armored smoke-and-bark knight carrying a huge round bark shield with a carved arabesque medallion, root-like feet, a small grumpy face peeking over the shield rim. " + FREED + " Freed form: Shardling, a tiny prismatic crystal spirit.",
      "1 MARCH shield forward 8 frames; 2 SHIELD BASH 6 frames; 3 BRACE (shield raised, weak back exposed) 3 frames; 4 STUNNED tilted back with stars 4 frames; 5 DEFEAT burst 6 frames; 6 Shardling hopping 8 frames.")
enemy("v3f_e_weaver", "Enemy v2: Murkweaver (thread spider) + freed Lanternit", [A + "g2_enemies_new.png"],
      "ENEMY: a smoke spider with eight thin jointed wooden legs and two big candle-flame eyes, hanging on a glowing silk thread (draw the thread above it). " + FREED + " Freed form: Lanternit, a small glowing lantern-moth.",
      "1 DANGLE swaying 6 frames; 2 DROP down fast 4 frames; 3 CLIMB back up 6 frames; 4 STRIKE (legs spread) 5 frames; 5 THREAD CUT falling and bursting 6 frames; 6 Lanternit fluttering 8 frames.")
enemy("v3f_e_bat", "Enemy v2: Gloombat (diving bat) + freed Lampmoth", [A + "g2_enemies_old.png"],
      "ENEMY: a sleek bat of dark violet smoke with tattered translucent wings, glowing yellow slit eyes, tiny fangs of pale wood, a ragged smoke trail. " + FREED + " Freed form: Lampmoth, a soft glowing moth.",
      "1 FLY flapping 8 frames; 2 HANG upside down alert 3 frames; 3 DIVE attack 6 frames; 4 HIT tumble 3 frames; 5 DEFEAT burst 6 frames; 6 Lampmoth fluttering 8 frames.")
enemy("v3f_e_roller", "Enemy v2: Rollerbug (armored roller) + freed beetle", [A + "g2_enemies_new.png"],
      "ENEMY: an armored pill-bug of dark smoke and overlapping bark plates with small angry eyes and stubby legs, curls into a heavy ball. " + FREED + " Freed form: a tiny happy beetle spirit.",
      "1 WALK 8 frames; 2 CURL UP 5 frames; 3 ROLLING ball 8 frames with motion arcs (a smooth rotation); 4 BOUNCE off a wall 4 frames; 5 STUNNED unrolled with stars 4 frames; 6 beetle hopping 8 frames.")
enemy("v3f_e_spitter", "Enemy v2: Spitter (seed cannon plant) + freed bloom", [A + "g2_enemies_new.png"],
      "ENEMY: a thorny smoke-touched plant rooted in a mound, a big tubular flower mouth like a small cannon, a swaying armored stem, glowing seed pods. " + FREED + " Freed form: a happy blooming flower spirit.",
      "1 IDLE sway 8 frames; 2 WIND-UP 4 frames (the mouth swells); 3 SPIT 6 frames with a visible flying seed; 4 HIT recoil 3 frames; 5 DEFEAT burst 6 frames; 6 bloom spirit dancing 8 frames.")
enemy("v3f_e_hauler", "Enemy v2: Haulmurk (porter) + freed Gustbag", [A + "g2_enemies_new.png"],
      "ENEMY: a big hunched smoke porter carrying a huge torn leather backpack full of stolen things (visible spoils), tiny hands, heavy waddling gait. " + FREED + " Freed form: Gustbag, a cheerful puffy wind-sack with coins swirling around it.",
      "1 WADDLE 8 frames; 2 WIND-UP to throw a stone 4 frames; 3 THROW 5 frames; 4 HIT 3 frames; 5 BACKPACK RIPS OPEN with coins spilling 6 frames; 6 Gustbag bobbing 8 frames.")
enemy("v3f_e_sparker", "Enemy v2: Sparkchaser (fast spark imp) + freed Flintling", [A + "g2_enemies_new.png"],
      "ENEMY: a small quick imp of smoke and sparks with a spiky ember mane and wide frightened eyes, skittering run, afraid of light. " + FREED + " Freed form: Flintling, a happy tiny spark sprite with a flint-stone body.",
      "1 SPRINT 8 frames; 2 SKID and look back 4 frames; 3 DASH attack 5 frames; 4 HIT 3 frames; 5 DEFEAT burst 6 frames; 6 Flintling hopping 8 frames.")
add("v3f_g_stumpguard", "Guardian v2: Stumpguard (K1) full animation + freed Verdlin baby", "2720x1536", [A + "g2_enemies_new.png"],
    COOL + SIDE + "GUARDIAN BOSS (large, fill the cells, about three times the size of a normal enemy): Stumpguard, a majestic ancient tree-trunk guardian: a massive round gnarled trunk body with deep bark, glowing amber runes carved in the bark, thick root legs, long branch arms, a crown of white flowers and red pomegranates, mossy beard, a stern but noble face with deep-set glowing eyes. When it rolls it curls into a huge spiked bark ball. Its weak spot is a bright glowing amber thread running down its back. Rows (top to bottom): 1 IDLE breathing 8 frames; 2 TELEGRAPH roll (rears back, runes flare red-orange) 6 frames; 3 ROLLING spiked ball 8 frames; 4 THROW a pomegranate 8 frames; 5 REST with the glowing back thread visible 6 frames; 6 HIT and ENRAGED 6 frames; 7 FREED: smoke clears, it shrinks into Verdlin the baby fawn spirit of vines and moss with leaf antlers, 8 frames. " + STYLE)
add("v3f_g_clockcrow", "Guardian v2: Clockcrow full animation + freed Tickwing", "2720x1536", [A + "g2_enemies_old.png"],
    COOL + SIDE + "GUARDIAN BOSS (large): Clockcrow, a grand brass-and-feather crow with a big ticking clock in its chest, clockwork gears on its wings, glowing violet smoke leaking from the joints, sharp curved beak, fierce golden eyes. Rows (top to bottom): 1 HOVER flapping 8 frames; 2 TELEGRAPH dive (red-orange glow, gears spinning) 6 frames; 3 DIVE 6 frames; 4 LAND and stagger 5 frames; 5 STUNNED on the ground with the chest gear exposed 5 frames; 6 HIT 4 frames; 7 FREED: the smoke clears and it becomes Tickwing, a warm golden-cream clock-feathered bird, 8 frames. " + STYLE)
OBJ = ("Game OBJECT sheet for a 2D side-scrolling platformer, premium polished art, thick dark-navy outlines, rich materials and rim light, each object clearly "
       "separate, drawn in side view, ready to be cut out. Everything the player touches must look solid, readable and beautiful. ")
add("v3f_i_spinbeams", "Interactive: spinning cross beams (parts and variants)", "2720x1536", [A + "p0_r2f_tower_interior_set.png"],
    OBJ + "Spinning cross-beam hazard parts, each separate so they can be rotated in the game: (1) a big wooden HUB disc with brass studs and an arabesque medallion; (2) a long wooden ARM with an iron-banded tip and studs, drawn straight and horizontal, in three styles: weathered wood, stone-and-iron, glowing amber crystal; (3) a rounded iron CAP for the tip; (4) a complete assembled plus-shaped crossbeam shown for reference in each of the three styles; (5) a dark wooden wheel disc to sit behind it; (6) a soft warning ring decal; (7) a smaller version of the hub. " + STYLE)
add("v3f_i_swings", "Interactive: rope swings, vines, anchors", "2720x1536", [A + "bg_old_plain_v3.png"],
    OBJ + "Swing and climbing parts: (1) a ROPE SWING assembly: two thick twisted ropes with knots, a carved wooden seat plank with arabesque ends, shown straight down, in two sizes; (2) the ANCHOR bracket at the top: an iron ring on a carved wooden beam stub; (3) the same swing at three swing angles (left, centre, right) with the ropes slightly curved; (4) a CLIMBING VINE strip, seamless vertical, with leaves and small flowers, in three variants; (5) a vine END piece and a vine ANCHOR knot; (6) a rope with a hand-loop for a zipline and its two anchor posts; (7) a hanging lantern on a hook. " + STYLE)
add("v3f_i_islands", "Interactive: floating islands (platforms)", "2720x1536", [A + "bg_new_plain_v3.png"],
    OBJ + "Eight FLOATING ISLAND platforms for a side-scrolling platformer, each a separate sprite with a flat walkable grassy top and an interesting hanging rock underside with roots, drawn in side view: tiny (2 tiles wide), small, medium, large; one with a trickling waterfall pouring off its edge; one with a small ruined arch; one with a glowing crystal; one dark and smoky with violet wisps. Soft golden rim light on top, shadowed underside. " + STYLE)
add("v3f_i_bridges", "Interactive: bridges (living root, rope, plank states, stone arch)", "2720x1536", [A + "bg_old_plain_v3.png"],
    OBJ + "Bridge parts, each separate and modular so they tile: (1) a LIVING ROOT BRIDGE: left end, middle section, right end, made of woven glowing green roots and vines with small flowers, in two lengths; (2) a ROPE BRIDGE: left post, a middle plank section, right post, with sagging ropes; (3) a single wooden PLANK in five states: intact, cracked, breaking, tilted falling, a broken half; (4) a stone ARCH bridge piece with carved tile patterns, mossy; (5) a BROKEN BRIDGE: two stubs with dangling planks and ropes; (6) a rope-bridge plank swinging animation 4 frames. " + STYLE)
add("v3f_i_shrine_gate", "Interactive: shrine, gates, crystals, levers, nest and hatching", "2720x1536", [A + "p0_bg_old_setpieces.png"],
    OBJ + "Puzzle objects, each separate with their state frames in a row: Row 1: a MIRROR SHRINE: a stone shrine with a big round mirror: dull and dusty 1 frame, then lighting up 4 frames, then fully active with a beam of golden light 3 frames. Row 2: a tall stone GATE with a sun medallion: closed 1 frame, opening 5 frames, open 1 frame. Row 3: a CRYSTAL target: dim 1 frame, glowing 3 frames, hit flash 2 frames, shattering 5 frames. Row 4: a PRESSURE PLATE up and down 2 frames, a LEVER left and right 2 frames, a ROPE KNOT target with a brass ring 2 frames, a stone BUTTON up and pressed 2 frames. Row 5: an EGG NEST in a branch holding a glowing pearly egg 1 frame, then falling nest 3 frames, then the egg HATCHING: cracks, light, a tiny time spirit emerging 8 frames. " + STYLE)
add("v3f_i_hazards2", "Interactive: falling rock, boulder, steam vent, ramp, spikes, platforms", "2720x1536", [A + "g4_fx_sheet.png"],
    OBJ + "Hazard and mover objects, each separate: (1) a FALLING ROCK in three sizes plus a ground SHADOW marker decal for each; (2) a big rolling BOULDER with carved runes; (3) a STEAM VENT: a stone vent with a brass grille and an animated steam column 8 frames; (4) a launch RAMP of carved stone and wood in two sizes; (5) thorny ROOT SPIKES rising from a pit, animation 6 frames; (6) a moving wooden PLATFORM with rope ends in two sizes; (7) three floating LEAF pads; (8) a bouncy SPRING flower or mushroom 3 frames; (9) a swinging heavy log on chains at three angles; (10) a sticky TAR puddle with bubbles 6 frames; (11) a SNAPPING PLANT opening and closing 6 frames; (12) a violet-thread NET intact and torn. " + STYLE)
add("v3f_i_markers", "Interactive: checkpoint, exit portal, signs, form markers, coins", "2720x1536", [A + "g5v3_hud_v3.png"],
    OBJ + "Level markers and pickups, each separate with their frames in a row: Row 1: a CHECKPOINT banner pole: off 1 frame, lighting 4 frames, on and waving 4 frames. Row 2: an EXIT PORTAL arch of carved stone: closed 1 frame, opening 5 frames, open with golden light swirling 6 frames. Row 3: wooden SIGNPOSTS with plain arrows (no text): right, up, down, and a danger sign with a plain symbol, each 1 frame. Row 4: a FORM MARKER (a glowing ring with a small symbol, no text) pulsing 6 frames. Row 5: a golden DEW-DROP coin spinning 8 frames, a big dew-drop, a star bud opening 4 frames, a heart, a seed. " + STYLE)

man = []
md = ["# بازطراحی دشمن‌ها و همهٔ اشیای تعاملی (۱۹ تصویر) — پرامپت دقیق، نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_v3f_prompts.py`. **حکم مالک (۲۴ نوامبر):** دشمن‌هایی که بازیکن بهشان تیر می‌زند و اشیای تعاملی (تیر چرخان، تاب، جزیره‌های شناور، پل…) باید کامل **بازطراحی** شوند. این پرامپت‌ها جایگزین `docs/39` (دشمن‌ها و موانع) هستند؛ نسخهٔ قبلی را نسازید.\n",
      "> **سه تغییر در پرامپت نسبت به قبل:** (۱) «بریف طراحی» صریح: شخصیت قوی، سیلوئت خوانا، حرکت ثانویه، مواد لایه‌ای (چوب، پوست درخت، برنج، دود، ترک درخشان)، ظاهر خفن نه حباب بامزهٔ عمومی؛ (۲) **هر دشمن ۶ ردیف**: حرکت، علامت، حمله، ضربه، نابودی/آزادی، شکل آزادشده؛ (۳) چیدمان سخت‌گیرانه (یک انیمیشن در هر ردیف، حداکثر ۸ فریم، فاصلهٔ ≥۱۵۰px) تا برش تمیز شود.\n",
      "> برگه‌ها روی **مجنتای خالص `#FF00FF` (نه سفید)**. مسیرها نسبت به ریشهٔ مخزن `pilo/`. بعد از گذاشتن: `python3 tools/art/check_v3f.py` یا بگویید «چک کن».\n",
      "> **ترتیب پیشنهادی:** ۱) v3f_g_stumpguard، v3f_e_imp، v3f_e_wisp ۲) v3f_i_spinbeams، v3f_i_swings، v3f_i_bridges، v3f_i_islands ۳) بقیه.\n\n---\n"]
for i, it in enumerate(items, 1):
    path = D + "/" + it["id"] + ".png"
    body = it["body"] + " " + PINK
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind="pink", title=it["title"]))
    md.append("## %02d — %s\n" % (i, it["title"]))
    md.append("- **نام فایل:** `%s.png`\n- **مسیر:** `%s`\n- **اندازهٔ ایده‌آل:** %s · **پس‌زمینه:** مجنتا #FF00FF\n" % (it["id"], path, it["size"]))
    md.append("- **مرجع برای ضمیمه:** " + "؛ ".join("`%s`" % r for r in it["refs"]) + "\n")
    md.append("```\n" + body + "\n```\n")
open(ROOT + "/docs/44_art_redesign_enemies_interactive.md", "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(ROOT + "/tools/art/v3f_manifest.json", "w", encoding="utf-8"), indent=1, ensure_ascii=False)
open(ROOT + "/tools/art/gen_v3f_prompts.py", "w", encoding="utf-8").write(open(__file__, encoding="utf-8").read())
print(len(items), "prompts")
