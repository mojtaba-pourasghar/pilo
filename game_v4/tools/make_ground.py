#!/usr/bin/env python3
"""Ground textures for the curved path from the painted kit (art/cut/<kit>): a repeating ROCK BODY texture and a
repeating MOSS LIP strip (the mossy top edge with its drips), both made tileable left-right by a soft cross-fade.
  python3 game_v4/tools/make_ground.py forest_old_kit forest_old
Writes art/ground/<name>_rock.png and art/ground/<name>_lip.png."""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(__file__)


def tileable(img: Image.Image, fade: int) -> Image.Image:
    """Cross-fades the right `fade` px over the left edge so the strip repeats without a seam."""
    a = np.asarray(img).astype(np.float32)
    w = a.shape[1]
    out = a[:, : w - fade].copy()
    ramp = np.linspace(0.0, 1.0, fade)[None, :, None]
    out[:, :fade] = a[:, w - fade:] * (1.0 - ramp) + a[:, :fade] * ramp
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), img.mode)


def main(kit: str, name: str) -> None:
    cut = os.path.join(HERE, "..", "art", "cut", kit)
    meta = json.load(open(os.path.join(cut, kit + ".json")))
    big = Image.open(os.path.join(cut, meta["pieces"][0]["file"])).convert("RGBA")     # the big rock mass (hole on the right)
    w, h = big.size
    alpha = np.asarray(big)[..., 3]
    # rows where the piece is solid across the middle: the body under the moss
    solid_rows = [y for y in range(h) if (alpha[y, int(w * 0.1):int(w * 0.5)] > 200).mean() > 0.97]
    top = solid_rows[0]
    bottom = solid_rows[-1]
    x0, x1 = int(w * 0.06), int(w * 0.94)
    # moss lip: from the very top of the moss down past the drips (alpha kept: drips hang free)
    lip_bottom = top + int((bottom - top) * 0.55)
    lip = big.crop((x0, 0, x1, lip_bottom))
    # the rock body: the solid stone band of the painted back tier (wide and detailed), else the kit piece
    near = os.path.join(HERE, "..", "art", "layers", name + "_near.png")
    if os.path.exists(near):
        ni = Image.open(near).convert("RGBA")
        na = np.asarray(ni)[..., 3]
        rows = [y for y in range(ni.height) if (na[y] > 200).mean() > 0.98]
        y0 = rows[0] + int((rows[-1] - rows[0]) * 0.35)
        rock = ni.crop((0, y0, ni.width, rows[-1])).convert("RGB")
    else:
        rock = big.crop((int(w * 0.06), top + int((bottom - top) * 0.40), int(w * 0.55), bottom - 4)).convert("RGB")
    out = os.path.join(HERE, "..", "art", "ground")
    os.makedirs(out, exist_ok=True)
    tileable(lip, lip.width // 6).save(os.path.join(out, name + "_lip.png"))
    # the rock body repeats both ways: fade left-right, then top-bottom
    r = tileable(rock, rock.width // 6)
    r = tileable(r.transpose(Image.Transpose.ROTATE_90), r.height // 5).transpose(Image.Transpose.ROTATE_270)
    r.save(os.path.join(out, name + "_rock.png"))
    print("ok", name, lip.size, r.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "forest_old_kit", sys.argv[2] if len(sys.argv) > 2 else "forest_old")
