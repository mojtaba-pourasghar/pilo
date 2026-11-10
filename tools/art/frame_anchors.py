#!/usr/bin/env python3
"""Where each drawn pose of Nima, Pilo and Kian stands, so the game can line the frames up.

The pose pictures come from an image generator one by one: each is cut to its own bounding box
and scaled to the base picture's painted area (postprocess.py "frame"), so from frame to frame
the character can sit a little left or right in its picture and be a little bigger or smaller
(a compact crouch gets blown up). Swapping such frames makes the body jump. This measures, in
every frame:

  scale     upright frames (walk, run, idle): how much to scale the frame so the head (the
            top of the figure) is as wide as in the base picture; other poses keep 1
  anchor_x  the x (in the picture) that must sit over the character's origin: the head's
            centre for upright poses (walk, run, idle), the body's centre for the others
  feet_y    the lowest painted row (the feet)

and writes assets/art/frame_anchors.json, which PaintedRig reads.

    venv/bin/python tools/art/frame_anchors.py
"""
import json
import os
import re

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
ART = os.path.join(ROOT, "assets", "art")
OUT = os.path.join(ART, "frame_anchors.json")
CHARACTERS = ["nima", "kian", "pilo"]
UPRIGHT = re.compile(r"_(rig|walk_[a-z]|run_[a-z]|idle_[a-z])$")


def head(rgba, name):
    """(width, centre x) of the head: the top of the figure, steady from frame to frame in
    upright poses."""
    a = rgba[..., 3] > 40
    ys, xs = np.nonzero(a)
    top = ys.min()
    # the head: rows from the top down to roughly a third of the base height (head + hair)
    band = a[top + 40: top + 260]
    bx = np.nonzero(band)[1]
    lo, hi = np.percentile(bx, [2, 98])
    return float(hi - lo), float((lo + hi) / 2)


def main():
    result = {}
    for character in CHARACTERS:
        base_file = os.path.join(ART, f"{character}_rig.png")
        if not os.path.exists(base_file):
            continue
        base = np.array(Image.open(base_file).convert("RGBA"))
        base_w, _ = head(base, character + "_rig")
        for f in sorted(os.listdir(ART)):
            name = f[:-4]
            if not f.endswith(".png") or not name.startswith(character + "_"):
                continue
            if name.endswith(("_portrait", "_sheet", "_shadow", "_free")):
                continue
            rgba = np.array(Image.open(os.path.join(ART, f)).convert("RGBA"))
            a = rgba[..., 3] > 40
            if a.sum() < 500:
                continue
            ys, xs = np.nonzero(a)
            w, cx = head(rgba, name)
            if UPRIGHT.search(name):
                anchor = cx
            else:
                mid = (ys > ys.min() + (ys.max() - ys.min()) * 0.25)
                anchor = float(xs[mid].mean())
            # upright frames: scaled so the head matches the base picture's; bent poses (crouch,
            # crawl, jump...) keep the scale postprocess gave them, which fits their head already
            scale = base_w / w if w > 4 and UPRIGHT.search(name) else 1.0
            # pilo is a fox: his "head width" changes with the pose; keep his frames as they are
            if character == "pilo":
                scale = 1.0
            result[name] = {"scale": round(float(np.clip(scale, 0.6, 1.6)), 4), "anchor_x": round(anchor, 1),
                            "feet_y": int(ys.max()), "size": [int(rgba.shape[1]), int(rgba.shape[0])]}
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=1, sort_keys=True)
    print(f"{len(result)} frames -> {os.path.relpath(OUT, ROOT)}")
    for k in ("nima_rig", "nima_walk_a", "nima_run_d", "nima_crouch", "nima_crawl_a"):
        if k in result:
            print(" ", k, result[k])


if __name__ == "__main__":
    main()
