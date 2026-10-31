#!/usr/bin/env python3
"""Turns the raw generated art (art_src/<id>.png) into game assets, following the "post" field
of each job in tools/art/manifest.json:

  cutout  → transparent background (rembg, isnet-general-use), trimmed  → assets/art/<id>.png
  sheet   → like cutout, then split into the separate views (left to right) → <id>_1.png ...
  tile_x  → left and right edges blended so it repeats sideways          → assets/art/<id>.png
  tile_xy → seamless in both directions                                  → assets/art/<id>.png
  texture → made seamless by blending with itself shifted by half, resized → assets/art/<id>.png
  none    → copied as it is (story pictures go to assets/story/)

Needs rembg:  python3 -m venv venv && venv/bin/pip install "rembg[cpu]" pillow
    venv/bin/python tools/art/postprocess.py [ids...]
"""
import json, os, sys
from PIL import Image, ImageChops

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "assets", "art")
STORY = os.path.join(ROOT, "assets", "story")
_session = None


def cutout(im):
    global _session
    from rembg import remove, new_session
    if _session is None:
        _session = new_session("isnet-general-use")
    out = remove(im, session=_session, alpha_matting=True)
    r, g, b, a = out.split()
    a = a.point(lambda v: 0 if v < 24 else v)
    out = Image.merge("RGBA", (r, g, b, a))
    box = out.getbbox()
    return out.crop(box) if box else out


def split_views(im):
    """Columns of empty space separate the views of a turnaround sheet."""
    alpha = im.split()[3]
    w, h = im.size
    filled = [any(alpha.getpixel((x, y)) > 40 for y in range(0, h, 3)) for x in range(w)]
    views, start = [], None
    for x, f in enumerate(filled + [False]):
        if f and start is None:
            start = x
        elif not f and start is not None:
            if x - start > w * 0.05:
                part = im.crop((start, 0, x, h))
                views.append(part.crop(part.getbbox()))
            start = None
    return views


def tile_x(im, blend=0.12):
    w, h = im.size
    k = int(w * blend)
    out = im.copy()
    for i in range(k):
        t = i / k
        right = im.crop((w - k + i, 0, w - k + i + 1, h))
        left = im.crop((i, 0, i + 1, h))
        out.paste(Image.blend(right, left, t), (w - k + i, 0))
    return out.crop((0, 0, w - k, h))


def seamless(im):
    """Repeats without a seam: the picture blended with itself shifted by half, the shifted
    copy taking over towards the edges (where it continues across the wrap)."""
    import numpy as np
    a = np.asarray(im).astype(np.float32)
    h, w = a.shape[:2]
    shifted = np.roll(np.roll(a, h // 2, axis=0), w // 2, axis=1)
    wx = np.sin(np.linspace(0, np.pi, w)) ** 0.6
    wy = np.sin(np.linspace(0, np.pi, h)) ** 0.6
    weight = (wy[:, None] * wx[None, :])[..., None]
    out = a * weight + shifted * (1.0 - weight)
    return Image.fromarray(out.clip(0, 255).astype(np.uint8))


def tile_xy(im):
    im = tile_x(im)
    return tile_x(im.rotate(90, expand=True)).rotate(-90, expand=True)


def main():
    manifest = json.load(open(os.path.join(ROOT, "tools", "art", "manifest.json"), encoding="utf-8"))
    only = set(sys.argv[1:])
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(STORY, exist_ok=True)
    for job in manifest["jobs"]:
        src = os.path.join(SRC, job["id"] + ".png")
        if (only and job["id"] not in only) or not os.path.exists(src):
            continue
        im = Image.open(src).convert("RGBA")
        post = job.get("post", "cutout")
        if post == "none":
            if job["id"].startswith("card_"):
                dest = os.path.join(ROOT, "assets", "ui", "worlds", job["id"][5:] + ".png")
            else:
                dest = os.path.join(STORY if job["id"].startswith("story_") else OUT, job["id"] + ".png")
            im.convert("RGB").save(dest)
        elif post == "cutout":
            out = cutout(im)
            if job.get("trim_top"):
                # the generator sometimes adds a prop above the subject: cut those rows off
                out = out.crop((0, job["trim_top"], out.width, out.height))
                out = out.crop(out.getbbox())
            for box in job.get("erase", []):
                # leftover bits of such a prop, in pixels of the trimmed cut-out
                out.paste((0, 0, 0, 0), tuple(box))
            # sprites are shown small: keep them at most "max" pixels on the long side
            limit = job.get("max", 1024)
            if max(out.size) > limit:
                f = limit / max(out.size)
                out = out.resize((round(out.width * f), round(out.height * f)), Image.LANCZOS)
            out.save(os.path.join(OUT, job["id"] + ".png"))
        elif post == "bust":
            # head and shoulders: the top part of the cut-out (portraits in the dialogue box)
            out = cutout(im)
            out = out.crop((0, 0, out.width, round(out.height * job.get("bust", 0.45))))
            out = out.crop(out.getbbox())
            out.thumbnail((job.get("max", 640),) * 2, Image.LANCZOS)
            out.save(os.path.join(OUT, job["id"] + ".png"))
        elif post == "sheet":
            views = split_views(cutout(im))
            for i, view in enumerate(views):
                view.save(os.path.join(OUT, f"{job['id']}_{i + 1}.png"))
        elif post == "texture_plain":
            # panoramas: shown mirrored every other copy in the game, so kept whole
            out = im.convert("RGB")
            limit = job.get("max", 1536)
            out.thumbnail((limit, limit), Image.LANCZOS)
            out.save(os.path.join(OUT, job["id"] + ".png"))
        elif post == "texture":
            out = seamless(im.convert("RGB"))
            limit = job.get("max", 1024)
            out.thumbnail((limit, limit), Image.LANCZOS)
            out.save(os.path.join(OUT, job["id"] + ".png"))
        elif post in ("tile_x", "tile_xy"):
            out = tile_x(im.convert("RGB")) if post == "tile_x" else tile_xy(im.convert("RGB"))
            limit = job.get("max", 1024)
            if max(out.size) > limit:
                f = limit / max(out.size)
                out = out.resize((round(out.width * f), round(out.height * f)), Image.LANCZOS)
            out.save(os.path.join(OUT, job["id"] + ".png"))
        print("done", job["id"], post)


if __name__ == "__main__":
    main()
