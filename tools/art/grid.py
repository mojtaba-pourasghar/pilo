#!/usr/bin/env python3
"""Draws a labelled coordinate grid over a picture (on magenta where it is transparent), to
measure the polygons and joints for tools/art/rigs.json by eye.

    python3 tools/art/grid.py assets/art/nima_rig.png out.png [step]
"""
import sys
from PIL import Image, ImageDraw

src, out = sys.argv[1], sys.argv[2]
step = int(sys.argv[3]) if len(sys.argv) > 3 else 50
im = Image.open(src).convert("RGBA")
bg = Image.new("RGBA", im.size, (255, 0, 255, 255))
bg.alpha_composite(im)
draw = ImageDraw.Draw(bg)
w, h = im.size
for x in range(0, w, step):
    draw.line([(x, 0), (x, h)], fill=(0, 0, 0, 255) if x % (step * 2) == 0 else (60, 60, 60, 255), width=1)
    draw.text((x + 2, 2), str(x), fill=(255, 255, 255, 255))
for y in range(0, h, step):
    draw.line([(0, y), (w, y)], fill=(0, 0, 0, 255) if y % (step * 2) == 0 else (60, 60, 60, 255), width=1)
    draw.text((2, y + 2), str(y), fill=(255, 255, 255, 255))
bg.convert("RGB").save(out)
