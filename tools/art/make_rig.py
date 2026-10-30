#!/usr/bin/env python3
"""Cuts a generated character (a transparent cut-out made by postprocess.py) into the parts
that PaintedRig animates, following tools/art/rigs.json:

    "nima": {
      "src": "nima_rig",                 # assets/art/nima_rig.png (side view, facing right)
      "height": 128,                     # height in the game, in pixels (feet to top)
      "feet": [x, y],                    # ground point between the feet (source pixels)
      "parts": {                         # every part: a polygon around it and its joint
                                         # ("shared": area the body keeps as well)
        "leg":  {"poly": [[x, y], ...], "pivot": [x, y]},
        "arm":  {"poly": [...], "pivot": [...], "fill": [[x, y], ...]},
        "head": {"poly": [...], "pivot": [...]}
      },
      "body_pivot": [x, y],              # the rest is the body; it leans around this point
      "drop": [[[x, y], ...]],           # pixels nobody keeps (far legs: the near leg is drawn twice)
      "points": {"hip_front": [x, y], "hip_back": [x, y]},
      "poses": {"jump": {"src": "nima_jump", "scale": 1.0}}
    }

A part takes the pixels inside its polygon; the body keeps everything else plus a small disc
around each joint, so no gap opens when a part turns. "fill" is the area behind a part that
must stay solid on the body (the shirt behind the arm): it is filled by inpainting.
Outputs assets/characters/<name>/<part>.png and rig.json (positions in source pixels and the
scale). Pose pictures are copied next to them.

    venv/bin/python tools/art/make_rig.py [names...] [--preview out.png]
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
ART = os.environ.get("RIG_ART", os.path.join(ROOT, "assets", "art"))
OUT = os.path.join(ROOT, "assets", "characters")
SPECS = os.environ.get("RIG_SPECS", os.path.join(ROOT, "tools", "art", "rigs.json"))
KEEP = 16   # radius of the disc the body keeps around a joint


def poly_mask(size, points):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon([tuple(p) for p in points], fill=255)
    return np.array(m) > 0


def disc_mask(size, center, radius):
    m = Image.new("L", size, 0)
    x, y = center
    ImageDraw.Draw(m).ellipse([x - radius, y - radius, x + radius, y + radius], fill=255)
    return np.array(m) > 0


def crop(rgba, mask):
    out = rgba.copy()
    out[..., 3] = np.where(mask, out[..., 3], 0)
    ys, xs = np.nonzero(out[..., 3] > 8)
    if len(xs) == 0:
        raise SystemExit("empty part")
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    return Image.fromarray(out[y0:y1, x0:x1]), [int(x0), int(y0)]


def inpaint(rgba, region):
    import cv2
    rgb = np.ascontiguousarray(rgba[..., :3])
    filled = cv2.inpaint(rgb, region.astype(np.uint8) * 255, 9, cv2.INPAINT_TELEA)
    out = rgba.copy()
    out[..., :3] = np.where(region[..., None], filled, rgba[..., :3])
    out[..., 3] = np.where(region, 255, rgba[..., 3])
    return out


def scaled(value, k):
    """Every coordinate in a spec, multiplied by k."""
    if isinstance(value, list):
        return [scaled(v, k) for v in value]
    if isinstance(value, dict):
        return {key: (v if key in ("src", "height", "scale", "hue", "tint") else scaled(v, k)) for key, v in value.items()}
    return round(value * k) if isinstance(value, (int, float)) else value


def build(name, spec):
    src = Image.open(os.path.join(ART, spec["src"] + ".png")).convert("RGBA")
    # keep about 2.5 source pixels per game pixel (sharp on big phones, small in memory)
    top = np.nonzero(np.array(src)[..., 3].max(axis=1) > 8)[0].min()
    k = min(1.0, 2.5 * spec["height"] / float(spec["feet"][1] - top))
    if k < 1.0:
        src = src.resize((round(src.width * k), round(src.height * k)), Image.LANCZOS)
        spec = scaled(spec, k)
    rgba = np.array(src)
    size = src.size
    alpha = rgba[..., 3] > 8
    folder = os.path.join(OUT, name)
    os.makedirs(folder, exist_ok=True)
    rig = {"scale": spec["height"] / float(spec["feet"][1] - np.nonzero(alpha.any(axis=1))[0].min()),
           "feet": spec["feet"], "parts": {}}
    taken = np.zeros_like(alpha)
    body_rgba = rgba.copy()
    for part, info in spec["parts"].items():
        mask = poly_mask(size, info["poly"]) & alpha
        image, box = crop(rgba, mask)
        image.save(os.path.join(folder, part + ".png"))
        pivot = info["pivot"]
        rig["parts"][part] = {"box": box, "pivot": [pivot[0] - box[0], pivot[1] - box[1]]}
        lost = mask & ~disc_mask(size, pivot, info.get("keep", KEEP))
        if "shared" in info:
            # the top of a leg stays on the body too (it hides the joint when the leg swings)
            lost &= ~poly_mask(size, info["shared"])
        taken |= lost
        if "fill" in info:
            region = poly_mask(size, info["fill"]) & mask
            body_rgba = inpaint(body_rgba, region)
            taken &= ~region
    for points in spec.get("drop", []):
        # pixels nobody keeps (the far legs: the rig draws the near leg twice instead)
        taken |= poly_mask(size, points) & ~np.zeros_like(alpha)
    body_alpha = (body_rgba[..., 3] > 8) & ~taken
    image, box = crop(body_rgba, body_alpha)
    image.save(os.path.join(folder, "body.png"))
    pivot = spec["body_pivot"]
    rig["parts"]["body"] = {"box": box, "pivot": [pivot[0] - box[0], pivot[1] - box[1]]}
    rig.update(spec.get("points", {}))
    rig["poses"] = {}
    for state, pose in spec.get("poses", {}).items():
        path = os.path.join(ART, pose["src"] + ".png")
        if not os.path.exists(path):
            continue
        pose_image = Image.open(path)
        if k < 1.0:
            pose_image = pose_image.resize((round(pose_image.width * k), round(pose_image.height * k)), Image.LANCZOS)
        pose_image.save(os.path.join(folder, "pose_" + state + ".png"))
        rig["poses"][state] = {"file": "pose_" + state + ".png", "scale": pose.get("scale", 1.0),
                               "lift": pose.get("lift", 0)}
    for key in ("hue", "tint"):
        if key in spec:
            rig[key] = spec[key]
    json.dump(rig, open(os.path.join(folder, "rig.json"), "w"), indent=1)
    print("rig", name, {k: v["box"] for k, v in rig["parts"].items()})
    return folder


def preview(names, out):
    """All parts of each rig side by side on a checkerboard, to check the cuts by eye."""
    tiles = []
    for name in names:
        folder = os.path.join(OUT, name)
        for f in sorted(os.listdir(folder)):
            if f.endswith(".png"):
                tiles.append(Image.open(os.path.join(folder, f)).convert("RGBA"))
    h = max(t.height for t in tiles)
    w = sum(t.width + 20 for t in tiles)
    sheet = Image.new("RGBA", (w, h), (255, 0, 255, 255))
    x = 0
    for t in tiles:
        sheet.alpha_composite(t, (x, h - t.height))
        x += t.width + 20
    sheet.convert("RGB").save(out)


def main():
    args = sys.argv[1:]
    out = None
    if "--preview" in args:
        i = args.index("--preview")
        out = args[i + 1]
        del args[i:i + 2]
    specs = json.load(open(SPECS, encoding="utf-8"))
    names = args or [n for n in specs if not n.startswith("_")]
    built = []
    for name in names:
        if not os.path.exists(os.path.join(ART, specs[name]["src"] + ".png")):
            print("skip", name, "(no picture yet)")
            continue
        build(name, specs[name])
        built.append(name)
    if out and built:
        preview(built, out)


if __name__ == "__main__":
    main()
