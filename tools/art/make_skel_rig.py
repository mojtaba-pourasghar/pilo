#!/usr/bin/env python3
"""ساخت ریگ اسکلتی (قطعه‌به‌قطعه) برای قهرمان‌های جفت ۱ از برگه‌های اجزا.

  python3 tools/art/make_skel_rig.py [arsam] [grandfather]

ورودی: assets/art/pair1_sheets/g2_<name>_parts.png (پس‌زمینهٔ مجنتا) — هر قطعه با نزدیک‌ترین
مرکزِ «anchor» (مختصات نمایشیِ تصویر ۲۰۰۰px عرض) شناسایی می‌شود.
خروجی: assets/characters/<name>/<part>.png  +  skel.json (برای scripts/characters/skeleton_rig.gd)
       + preview_assembled.png (چیدمان ایستاده برای بررسی چشمی).

skel.json: parts[name] = {file,size,pivot,parent,at,z,...}. «at» = جای لولا در دستگاه مختصاتِ لولای والد
(پیکسل منبع، y رو به پایین). ریشه «hip» = کمر؛ پا = مبدأ y=0 (کف پوتین‌ها).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
from key_pink import key_pink  # noqa: E402
from build_pair1 import split_components  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# name: (anchor_cx, anchor_cy, pivot_fx, pivot_fy, parent, attach, z, extra)
#   attach: (fx, fy) نقطه‌ای از جعبهٔ والد (کسری)، یا ("abs", dx, dy) نسبت به لولای والد (px)
SPECS = {
    "arsam": {
        "sheet": "g2_arsam_parts",
        "height": 118,           # قد در بازی (px) از کف تا بالای سر
        "parts": {
            "torso":      (635, 505, 0.50, 0.93, "hip",   ("abs", 0, 0), 10, {}),
            "head":       (173, 168, 0.50, 0.90, "torso", (0.50, 0.04), 30, {"expr": "neutral"}),
            "head_happy": (440, 169, 0.50, 0.90, "torso", (0.50, 0.04), 30, {"expr": "happy"}),
            "head_angry": (707, 168, 0.50, 0.90, "torso", (0.50, 0.04), 30, {"expr": "angry"}),
            "head_hurt":  (976, 168, 0.50, 0.90, "torso", (0.50, 0.04), 30, {"expr": "hurt"}),
            "collar":     (920, 391, 0.50, 0.55, "torso", (0.50, 0.06), 20, {}),
            "scarf_a":    (1139, 415, 0.08, 0.30, "torso", (0.52, 0.07), -5, {"spring": 1}),
            "scarf_b":    (1351, 410, 0.08, 0.30, "torso", (0.50, 0.08), -6, {"spring": 2}),
            "quiver":     (1778, 585, 0.45, 0.30, "torso", (0.30, 0.22), -8, {"rot": -22}),
            "pouch":      (880, 539, 0.50, 0.10, "torso", (0.82, 0.86), 12, {}),
            "sleeve_f":   (107, 580, 0.50, 0.08, "torso", (0.06, 0.12), 14, {"side": "front"}),
            "sleeve_b":   (295, 580, 0.50, 0.08, "torso", (0.94, 0.12), -2, {"side": "back"}),
            "arm_f":      (94, 854, 0.50, 0.05, "sleeve_f", (0.50, 0.90), 15, {}),
            "arm_b":      (304, 854, 0.50, 0.05, "sleeve_b", (0.50, 0.90), -1, {}),
            "hand_grip":  (478, 858, 0.45, 0.05, "sleeve_f", (0.50, 0.90), 16, {"alt": "arm_f"}),
            "hand_pull":  (651, 851, 0.50, 0.05, "sleeve_b", (0.50, 0.90), 0, {"alt": "arm_b"}),
            "thigh_f":    (861, 728, 0.50, 0.10, "hip",   ("abs", -34, 0), 6, {}),
            "thigh_b":    (1018, 728, 0.50, 0.10, "hip",  ("abs", 34, 0), 2, {}),
            "shin_f":     (843, 956, 0.50, 0.06, "thigh_f", (0.50, 0.90), 5, {}),
            "shin_b":     (1034, 956, 0.50, 0.06, "thigh_b", (0.50, 0.90), 1, {}),
            "boot_f":     (1182, 975, 0.40, 0.18, "shin_f", (0.50, 0.95), 7, {}),
            "boot_b":     (1361, 975, 0.40, 0.18, "shin_b", (0.50, 0.95), 3, {}),
            "bow":        (1557, 585, 0.50, 0.50, "hand_grip", (0.45, 0.60), 17, {"hidden": 1}),
            "arrow":      (1928, 610, 0.50, 0.50, "hand_pull", (0.50, 0.60), 0, {"hidden": 1}),
        },
    },
    "grandfather": {
        "sheet": "g2_grandfather_parts",
        "height": 132,
        "parts": {
            "pants":     (225, 920, 0.50, 0.04, "hip",   ("abs", 0, 0), 8, {}),
            "torso":     (274, 374, 0.50, 0.93, "hip",   ("abs", 0, -40), 10, {}),
            "sash":      (259, 614, 0.50, 0.10, "torso", (0.50, 0.86), 12, {}),
            "head":      (304, 132, 0.50, 0.92, "torso", (0.50, 0.04), 30, {"expr": "neutral"}),
            "head_happy": (479, 132, 0.50, 0.92, "torso", (0.50, 0.04), 30, {"expr": "happy"}),
            "head_worry": (634, 132, 0.50, 0.92, "torso", (0.50, 0.04), 30, {"expr": "worried"}),
            "head_hurt":  (787, 132, 0.50, 0.92, "torso", (0.50, 0.04), 30, {"expr": "hurt"}),
            "scarf_ring": (988, 109, 0.50, 0.55, "torso", (0.50, 0.06), 20, {}),
            "scarf_a":   (1020, 230, 0.06, 0.40, "torso", (0.55, 0.07), -5, {"spring": 1, "rot": 70}),
            "scarf_b":   (1676, 156, 0.50, 0.04, "torso", (0.46, 0.08), -6, {"spring": 2, "rot": -35}),
            "arm_f":     (1221, 443, 0.50, 0.05, "torso", (0.12, 0.62), 15, {}),
            "arm_b":     (1336, 443, 0.50, 0.05, "torso", (0.88, 0.62), -1, {}),
            "hand_sling": (1472, 443, 0.50, 0.05, "torso", (0.12, 0.62), 16, {"alt": "arm_f"}),
            "hand_staff": (1610, 438, 0.50, 0.05, "torso", (0.88, 0.62), 16, {"alt": "arm_b"}),
            "hand_lamp":  (1775, 450, 0.30, 0.05, "torso", (0.12, 0.62), 16, {"alt": "arm_f"}),
            "shin_f":    (516, 933, 0.50, 0.05, "pants", (0.27, 0.90), 6, {}),
            "shin_b":    (659, 933, 0.50, 0.05, "pants", (0.73, 0.90), 2, {}),
            "boot_f":    (835, 960, 0.50, 0.22, "shin_f", (0.50, 0.96), 7, {}),
            "boot_b":    (1024, 960, 0.50, 0.22, "shin_b", (0.50, 0.96), 3, {}),
            "backpack":  (1314, 833, 0.45, 0.30, "torso", (0.30, 0.30), -8, {}),
            "staff":     (1901, 563, 0.50, 0.50, "hand_staff", (0.50, 0.40), 17, {"hidden": 1}),
            "sling_pouch": (1662, 847, 0.50, 0.05, "hip", ("abs", 30, -10), 11, {"hidden": 1}),
        },
        "extras": {
            "egg": {"src": "assets/art/pair1/tikkit/p0_c1e_egg_hatch/p0_c1e_egg_hatch_r00_c00.png", "width": 190,
                    "pivot": (0.5, 0.5), "parent": "torso", "attach": (0.5, 0.60), "z": 18},
        },
    },
}


def build(name, spec):
    src = Image.open(os.path.join(ROOT, "assets/art/pair1_sheets", spec["sheet"] + ".png"))
    k = 2000.0 / src.width
    rgba = key_pink(src, tol=60, soft=40)
    boxes = split_components(rgba, 3, 1500)
    cents = [((b[0] + b[2]) / 2 * k, (b[1] + b[3]) / 2 * k, b) for b in boxes]
    out = os.path.join(ROOT, "assets/characters", name)
    os.makedirs(out, exist_ok=True)
    parts, used = {}, set()
    for pname, (ax, ay, pfx, pfy, parent, attach, z, extra) in spec["parts"].items():
        j = min(range(len(cents)), key=lambda i: (cents[i][0] - ax) ** 2 + (cents[i][1] - ay) ** 2)
        if j in used:
            print(f"!! {name}/{pname}: قطعهٔ {j} دو بار انتخاب شد")
        used.add(j)
        x0, y0, x1, y1, _ = cents[j][2]
        crop = rgba.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2))
        # magenta left in enclosed holes (strap loops, chain rings) -> transparent
        a = np.asarray(crop).copy()
        hole = (a[..., 0] > 165) & (a[..., 2] > 150) & (a[..., 1] < 125) & (a[..., 3] > 0)
        a[hole, 3] = 0
        crop = Image.fromarray(a, "RGBA")
        crop.save(os.path.join(out, pname + ".png"))
        w, h = crop.size
        parts[pname] = {"file": pname + ".png", "size": [w, h], "pivot": [round(pfx * w, 1), round(pfy * h, 1)],
                        "parent": parent, "attach": list(attach), "z": z, **extra}
    for xname, ex in spec.get("extras", {}).items():
        img = Image.open(os.path.join(ROOT, ex["src"])).convert("RGBA")
        k2 = ex["width"] / img.width
        img = img.resize((ex["width"], max(1, int(img.height * k2))), Image.LANCZOS)
        img.save(os.path.join(out, xname + ".png"))
        w, h = img.size
        parts[xname] = {"file": xname + ".png", "size": [w, h], "pivot": [round(ex["pivot"][0] * w, 1), round(ex["pivot"][1] * h, 1)],
                        "parent": ex["parent"], "attach": list(ex["attach"]), "z": ex["z"], "hidden": 1}
    unused = [i for i in range(len(cents)) if i not in used]
    if unused:
        print(f"{name}: قطعه‌های مصرف‌نشده: {unused} ({[[int(v * k) for v in cents[i][2][:4]] for i in unused]})")
    # جای مطلقِ لولاها در چیدمان ایستاده، سپس «at» محلی
    absp = {"hip": (0.0, 0.0)}
    order = list(parts.keys())
    for _ in range(6):
        for pn in order:
            p = parts[pn]
            if pn in absp:
                continue
            par = p["parent"]
            if par not in absp:
                continue
            ax0, ay0 = absp[par]
            a = p["attach"]
            if a[0] == "abs":
                absp[pn] = (ax0 + a[1], ay0 + a[2])
            else:
                pp = parts[par]
                absp[pn] = (ax0 + a[0] * pp["size"][0] - pp["pivot"][0], ay0 + a[1] * pp["size"][1] - pp["pivot"][1])
    # کف: پایین‌ترین نقطهٔ پوتین‌ها
    low = max(absp[pn][1] + (parts[pn]["size"][1] - parts[pn]["pivot"][1]) for pn in parts if pn.startswith("boot"))
    high = min(absp[pn][1] - parts[pn]["pivot"][1] for pn in parts if pn.startswith("head"))
    total = low - high
    sc = spec["height"] / total
    for pn, p in parts.items():
        ap = absp[pn]
        par = p["parent"]
        pa = absp[par]
        p["at"] = [round(ap[0] - pa[0], 1), round(ap[1] - pa[1], 1)]
        p.pop("attach")
    hip_y = -low  # hip در دستگاه «کف=۰»، y منفی بالا
    skel = {"name": name, "height": spec["height"], "scale": round(sc, 5), "hip": [0.0, round(hip_y, 1)],
            "parts": parts}
    json.dump(skel, open(os.path.join(out, "skel.json"), "w"), indent=1, ensure_ascii=False)
    # پیش‌نمایش چیدمان
    pad = 80
    W, H = 700, int(total) + 2 * pad
    canvas = Image.new("RGBA", (W, H), (70, 80, 120, 255))
    shift = (W // 2, pad - high if False else int(-high + pad))
    for pn in sorted(parts, key=lambda n: parts[n]["z"]):
        p = parts[pn]
        if p.get("hidden") or p.get("alt") or (p.get("expr") and p["expr"] != "neutral"):
            continue
        ap = absp[pn]
        img = Image.open(os.path.join(out, p["file"]))
        canvas.alpha_composite(img, (int(W // 2 + ap[0] - p["pivot"][0]), int(ap[1] - p["pivot"][1] + (-high) + pad)))
    canvas.convert("RGB").save(os.path.join(out, "preview_assembled.png"))
    print(f"OK {name}: {len(parts)} قطعه، مقیاس {sc:.4f}، قد منبع {total:.0f}px")


def main():
    names = sys.argv[1:] or list(SPECS)
    for n in names:
        build(n, SPECS[n])


if __name__ == "__main__":
    main()
