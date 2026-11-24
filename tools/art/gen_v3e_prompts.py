# Generates docs/43_art_traps_environments.md and tools/art/v3e_manifest.json (art for docs/40 section 9)
import json, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STYLE = ("Bright saturated glossy mobile-game cartoon illustration, thick dark-navy outlines (#2A1F3D), soft painterly gradients, "
         "chunky rounded shapes, vivid joyful colors, two-tone cel shading with glossy highlights, high contrast, clean and polished, "
         "sellable casual-game quality. Original design with Persian/Iranian-inspired motifs (arabesque swirls, tile patterns, domes). Kid-friendly for ages 8-15.")
PINK = ("IMPORTANT BACKGROUND RULE: the entire background must be solid flat pure magenta, exactly RGB(255,0,255) hex #FF00FF. It must NOT be white, "
        "NOT light pink, NOT transparent. Perfectly uniform: no shadow, no gradient, no floor line, no texture, no glow on the background. "
        "No part of any subject is pink or magenta. Every item fully separated with at least 120 px of empty magenta between items, nothing "
        "overlapping or touching, nothing cropped at the edges. Each item has a closed thick dark-navy outline. Flat even lighting. "
        "No text, letters, numbers, labels, watermark or logo. Do not imitate any existing game, character or brand.")
NOPINK = "No text, letters, numbers, labels, watermark or logo. No magenta or pink background. Do not imitate any existing game, character or brand."
SC = ("Wide side-scrolling background SCENE painting, 3:1 panorama, layered depth (far, middle, near) with a clear walkable ground strip in the bottom third, "
      "no characters, no text. ")
D = "assets/art/v3"
A = "assets/art/pair1_sheets/"
items = []


def add(id_, title, size, kind, refs, body):
    items.append(dict(id=id_, title=title, size=size, kind=kind, refs=refs, body=body))


add("v3_obst_traps", "Traps: spike pit, sticky tar, snapping plant, closing doors, net, quicksand, rolling boulder, ice", "2720x1536", "pink", [A + "g4_fx_sheet.png"],
    "Side-view trap sprites for a kid-friendly platformer (no blood, no skeletons, playful but clearly dangerous), each item separate with its animation frames in one row left to right: Row 1: SPIKY ROOT PIT, a pit with thorny roots rising and sinking, 6 frames. Row 2: STICKY TAR or mud puddle with bubbles, 6 frames. Row 3: SNAPPING PLANT with a big toothy mouth opening and closing, 6 frames. Row 4: a pair of STONE SLIDING DOORS closing together, 6 frames, and a stone button pressed in 3 frames. Row 5: a NET TRAP of sticky violet thread stretched across, intact then torn, 5 frames. Row 6: QUICKSAND swirl, 6 frames. Row 7: a big ROLLING BOULDER with a face-less cracked stone texture, rolling 8 frames. Row 8: a patch of slippery ICE, 3 variants, and a CRACKING ICE floor, 4 frames. " + STYLE)
add("v3_scene_ruins_new", "Scene: broken ruins hall with smoke (new era)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "Ruined stone arches and columns years later, cool teal light, thick violet smoke wisps between the pillars, crumbling stairs, vines, glowing green traces on the stones, a few dark doorways. " + NOPINK)
add("v3_scene_tower_old", "Scene: inside a tower hall (old era)", "3072x1024", "none", [A + "p0_r2s_tower_interior_sky.png"],
    STYLE + " " + SC + "The inside of a tall watch-tower hall at golden warm light: stone walls with tall arched windows, wooden beams, hanging brass lanterns, spiral wooden stairs on the wall, bookshelves, big wooden wheels behind. " + NOPINK)
add("v3_scene_marsh_old", "Scene: sunken marsh with reeds (old era)", "3072x1024", "none", [A + "bg_old_plain_v3.png"],
    STYLE + " " + SC + "A quiet shallow marsh: still water with lily pads, tall reeds and cattails, fallen logs as bridges, soft golden fog, dragonflies. " + NOPINK)
add("v3_scene_overgrown_cave_new", "Scene: dark overgrown cave (new era)", "3072x1024", "none", [A + "bg_new_plain_v3.png"],
    STYLE + " " + SC + "A dark cave tunnel overgrown with glowing green roots and vines, violet smoke, a single beam of teal light from a crack in the roof, wet rocks. " + NOPINK)

man = []
md = ["# هنر تله‌ها و محیط‌های تازه (۵ تصویر) — پرامپت دقیق، نام فایل و مسیر\n",
      "> ساخته‌شده با `tools/art/gen_v3e_prompts.py`. هدف: `docs/40` §۹ (محیط‌های متفاوت و گیرکردن). مسیرها نسبت به ریشهٔ مخزن `pilo/`.\n",
      "> «مرجع» = تصویری که همراه پرامپت ضمیمه می‌کنید. **برگهٔ برش‌خور مجنتای خالص `#FF00FF` (نه سفید)**؛ صحنه‌ها بدون مجنتا. بعد از گذاشتن: `python3 tools/art/check_v3e.py` یا بگویید «چک کن».\n",
      "> **یادآوری:** صحنه‌های `docs/39` (۷ صحنه: غار، دره، ویرانه، شفت درخت، قدیم و جدید) هم هنوز لازم‌اند؛ آن‌ها پس‌زمینهٔ چند صحنهٔ مرحله‌اند.\n\n---\n"]
for i, it in enumerate(items, 1):
    path = D + "/" + it["id"] + ".png"
    body = it["body"]
    if it["kind"] == "pink":
        body = body + " " + PINK
    man.append(dict(n=i, id=it["id"], path=path, size=it["size"], kind=it["kind"], title=it["title"]))
    md.append("## %02d — %s\n" % (i, it["title"]))
    md.append("- **نام فایل:** `%s.png`\n- **مسیر:** `%s`\n- **اندازهٔ ایده‌آل:** %s · **پس‌زمینه:** %s\n" % (
        it["id"], path, it["size"], "مجنتا #FF00FF" if it["kind"] == "pink" else "تصویر کامل (بدون مجنتا)"))
    md.append("- **مرجع:** " + ("؛ ".join("`%s`" % r for r in it["refs"]) if it["refs"] else "ندارد") + "\n")
    md.append("```\n" + body + "\n```\n")
open(os.path.join(ROOT, "docs", "43_art_traps_environments.md"), "w", encoding="utf-8").write("\n".join(md))
json.dump(man, open(os.path.join(ROOT, "tools", "art", "v3e_manifest.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(len(items), "prompts")
