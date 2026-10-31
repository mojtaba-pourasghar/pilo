#!/usr/bin/env python3
"""Glossy ("glass") UI art for the approved menu design (assets/reference/ui_menus_design.webp).

    python3 tools/ui_art.py .

Everything is drawn at 4x and downsampled for clean edges. Pill buttons and panels are
nine-patch textures; the game stretches them with StyleBoxTexture so text stays sharp.
"""
import math
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = f"{ROOT}/assets/ui/glass"
SS = 4


def rgba(hex_color, a=255):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(im):
    return im.resize((im.width // SS, im.height // SS), Image.LANCZOS)


def mask_rrect(size, box, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([v * SS for v in box], radius * SS, fill=255)
    return m


def mask_ellipse(size, box):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).ellipse([v * SS for v in box], fill=255)
    return m


def gradient(size, top, bottom, y0=0, y1=None):
    w, h = size
    y1 = h if y1 is None else y1
    t = np.clip((np.arange(h)[:, None] - y0) / max(1, (y1 - y0)), 0, 1)
    top, bottom = np.array(top, float), np.array(bottom, float)
    arr = top + (bottom - top) * t[..., None]
    arr = np.broadcast_to(arr, (h, w, 4)).astype(np.uint8)
    return Image.fromarray(np.ascontiguousarray(arr), "RGBA")


def fill(im, mask, top, bottom, box=None):
    y0, y1 = (box[1] * SS, box[3] * SS) if box else (0, im.height)
    layer = gradient(im.size, top, bottom, y0, y1)
    alpha = ImageChops.multiply(layer.getchannel("A"), mask)
    layer.putalpha(alpha)
    im.alpha_composite(layer)


def shadow(im, mask, offset=(0, 6), blur=8, alpha=90):
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    m = ImageChops.offset(mask, offset[0] * SS, offset[1] * SS).filter(ImageFilter.GaussianBlur(blur * SS))
    sh.putalpha(m.point(lambda v: v * alpha // 255))
    im.alpha_composite(sh)


def gloss(im, box, radius, strength=150):
    """White highlight on the upper half that fades out downwards (the glass look)."""
    x0, y0, x1, y1 = box
    inset = max(3, (y1 - y0) * 0.08)
    gbox = (x0 + inset * 1.6, y0 + inset, x1 - inset * 1.6, y0 + (y1 - y0) * 0.52)
    m = mask_rrect(im.size, gbox, max(2, radius - inset))
    fill(im, m, (255, 255, 255, strength), (255, 255, 255, 14), gbox)


def outline(im, box, radius, color, width):
    o = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(o).rounded_rectangle([v * SS for v in box], radius * SS, outline=color, width=int(width * SS))
    im.alpha_composite(o)


def pill(name, w, h, top, bottom, edge, rim=(255, 255, 255, 230), radius=None, gloss_strength=150):
    """Glossy pill with a darker 3D edge below and a thin bright rim."""
    radius = radius or (h - 14) / 2
    im = canvas(w, h)
    body = (6, 4, w - 6, h - 12)
    base = (6, 10, w - 6, h - 6)
    shadow(im, mask_rrect(im.size, base, radius), (0, 3), 4, 80)
    fill(im, mask_rrect(im.size, base, radius), edge, edge)
    fill(im, mask_rrect(im.size, body, radius), top, bottom, body)
    gloss(im, body, radius, gloss_strength)
    outline(im, body, radius, rim, 2.2)
    finish(im).save(f"{OUT}/{name}.png")


def circle_button(name, d, top, bottom, edge, ring, glyph=None):
    im = canvas(d, d)
    pad = 8
    shadow(im, mask_ellipse(im.size, (pad, pad + 4, d - pad, d - pad + 2)), (0, 4), 6, 100)
    fill(im, mask_ellipse(im.size, (pad, pad, d - pad, d - pad)), ring, ring)
    r = d * 0.075
    inner = (pad + r, pad + r, d - pad - r, d - pad - r)
    fill(im, mask_ellipse(im.size, (inner[0], inner[1] + 4, inner[2], inner[3] + 2)), edge, edge)
    fill(im, mask_ellipse(im.size, inner), top, bottom, inner)
    gx0, gy0, gx1 = inner[0] + d * 0.12, inner[1] + d * 0.04, inner[2] - d * 0.12
    gbox = (gx0, gy0, gx1, inner[1] + (inner[3] - inner[1]) * 0.5)
    fill(im, mask_ellipse(im.size, gbox), (255, 255, 255, 170), (255, 255, 255, 10), gbox)
    if glyph:
        g = Image.new("RGBA", im.size, (0, 0, 0, 0))
        glyph(ImageDraw.Draw(g), d * SS)
        shadow_g = g.getchannel("A")
        shadow(im, shadow_g, (0, 2), 2, 70)
        im.alpha_composite(g)
    finish(im).save(f"{OUT}/{name}.png")


def panel(name, w, h, radius, top, bottom, border, border_w, inner_rim=(255, 255, 255, 200)):
    im = canvas(w, h)
    box = (10, 8, w - 10, h - 14)
    shadow(im, mask_rrect(im.size, box, radius), (0, 6), 8, 110)
    fill(im, mask_rrect(im.size, box, radius), border, border)
    ib = (box[0] + border_w, box[1] + border_w, box[2] - border_w, box[3] - border_w)
    fill(im, mask_rrect(im.size, ib, radius - border_w), top, bottom, ib)
    outline(im, ib, radius - border_w, inner_rim, 2)
    finish(im).save(f"{OUT}/{name}.png")


def frame(name, w, h, radius, top, bottom, edge, thick):
    """Card frame with a transparent window in the middle (the world picture shows through)."""
    im = canvas(w, h)
    box = (8, 6, w - 8, h - 12)
    shadow(im, mask_rrect(im.size, box, radius), (0, 6), 7, 110)
    fill(im, mask_rrect(im.size, (box[0], box[1] + 6, box[2], box[3] + 6), radius), edge, edge)
    outer = mask_rrect(im.size, box, radius)
    window = (box[0] + thick, box[1] + thick, box[2] - thick, box[3] - thick)
    hole = mask_rrect(im.size, window, radius - thick * 0.6)
    ring = ImageChops.subtract(outer, hole)
    fill(im, ring, top, bottom, box)
    hl = ImageChops.multiply(ImageChops.subtract(mask_rrect(im.size, (box[0] + 3, box[1] + 3, box[2] - 3, box[1] + thick * 0.9), radius), hole), outer)
    fill(im, hl, (255, 255, 255, 120), (255, 255, 255, 20), (0, box[1], 0, box[1] + thick))
    outline(im, box, radius, (255, 255, 255, 170), 2)
    outline(im, window, radius - thick * 0.6, (0, 0, 0, 60), 2)
    cut = finish(im)
    cut.putalpha(ImageChops.subtract(cut.getchannel("A"), finish_mask(hole, w, h)))
    cut.save(f"{OUT}/{name}.png")


def finish_mask(m, w, h):
    return m.resize((w, h), Image.LANCZOS)


def chevron(name, flip):
    w, h = 90, 140
    im = canvas(w, h)
    outer = [(62, 10), (84, 32), (46, 70), (84, 108), (62, 130), (6, 70)]
    inner = [(62, 22), (76, 34), (36, 70), (76, 106), (62, 118), (18, 70)]
    m_out = Image.new("L", im.size, 0); ImageDraw.Draw(m_out).polygon([(x * SS, y * SS) for x, y in outer], fill=255)
    m_in = Image.new("L", im.size, 0); ImageDraw.Draw(m_in).polygon([(x * SS, y * SS) for x, y in inner], fill=255)
    m_out = m_out.filter(ImageFilter.MaxFilter(9))
    shadow(im, m_out, (0, 4), 4, 90)
    fill(im, m_out, rgba("8a4e0c"), rgba("6a3a08"))
    fill(im, m_in, rgba("ffe066"), rgba("f5a90f"), (0, 20, 0, 120))
    top_half = Image.new("L", im.size, 0); ImageDraw.Draw(top_half).rectangle((0, 0, im.width, 70 * SS), fill=255)
    fill(im, ImageChops.multiply(m_in, top_half), (255, 255, 255, 110), (255, 255, 255, 0), (0, 20, 0, 70))
    out = finish(im)
    if flip:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    out.save(f"{OUT}/{name}.png")


def leaf(draw, cx, cy, length, width, angle, color, vein):
    pts = []
    for i in range(25):
        t = i / 24
        x = (t - 0.5) * length
        y = math.sin(t * math.pi) * width / 2
        pts.append((x, y))
    pts += [(x, -y) for x, y in reversed(pts)]
    ca, sa = math.cos(angle), math.sin(angle)
    poly = [((cx + x * ca - y * sa) * SS, (cy + x * sa + y * ca) * SS) for x, y in pts]
    draw.polygon(poly, fill=color)
    draw.line([((cx - 0.45 * length * ca) * SS, (cy - 0.45 * length * sa) * SS),
               ((cx + 0.45 * length * ca) * SS, (cy + 0.45 * length * sa) * SS)], fill=vein, width=2 * SS)


def logo_sign():
    w, h = 820, 330
    im = canvas(w, h)
    board = (40, 52, w - 40, h - 46)
    shadow(im, mask_rrect(im.size, board, 54), (0, 10), 10, 120)
    fill(im, mask_rrect(im.size, (board[0], board[1] + 8, board[2], board[3] + 8), 54), rgba("5a3412"), rgba("4a2a0e"))
    fill(im, mask_rrect(im.size, board, 54), rgba("7a4518"), rgba("5f3613"))
    inner = (board[0] + 12, board[1] + 12, board[2] - 12, board[3] - 12)
    fill(im, mask_rrect(im.size, inner, 44), rgba("c98a4b"), rgba("9c6230"), inner)
    # wood grain
    grain = Image.new("RGBA", im.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grain)
    for i, y in enumerate(range(inner[1] + 26, inner[3] - 10, 30)):
        pts = [((inner[0] + 30 + x) * SS, (y + math.sin(x / 70 + i) * 4) * SS) for x in range(0, inner[2] - inner[0] - 60, 8)]
        gd.line(pts, fill=(110, 62, 24, 90), width=3 * SS)
    grain.putalpha(ImageChops.multiply(grain.getchannel("A"), mask_rrect(im.size, inner, 44)))
    im.alpha_composite(grain)
    gloss(im, inner, 44, 90)
    outline(im, inner, 44, (255, 220, 170, 160), 2)
    # nails
    nd = ImageDraw.Draw(im)
    for x in (inner[0] + 26, inner[2] - 26):
        for y in (inner[1] + 24, inner[3] - 24):
            nd.ellipse(((x - 7) * SS, (y - 7) * SS, (x + 7) * SS, (y + 7) * SS), fill=(90, 60, 40, 255))
            nd.ellipse(((x - 4) * SS, (y - 5) * SS, (x + 2) * SS, (y + 1) * SS), fill=(200, 170, 140, 255))
    # leaf clusters on the top corners and middle
    ld = ImageDraw.Draw(im)
    dark, mid, light, vein = rgba("2f7d32"), rgba("4caf50"), rgba("8bd34a"), rgba("1f5a22")
    clusters = [(90, 58, -1), (w - 92, 56, 1), (w * 0.62, 44, 1)]
    for cx, cy, side in clusters:
        for (dx, dy, ln, wd, ang, col) in (
            (-20 * side, -8, 70, 30, -2.4 if side < 0 else -0.7, dark),
            (6 * side, -26, 64, 28, -1.9 if side < 0 else -1.2, mid),
            (26 * side, -4, 58, 26, -2.9 if side < 0 else -0.2, light),
            (-2 * side, 6, 50, 22, 2.6 if side < 0 else 0.5, mid),
        ):
            leaf(ld, cx + dx, cy + dy, ln, wd, ang, col, vein)
    finish(im).save(f"{OUT}/logo_sign.png")


def ribbon(name, w, h, top, bottom, edge):
    im = canvas(w, h)
    body = (8, 6, w - 8, h - 12)
    shadow(im, mask_rrect(im.size, body, 26), (0, 5), 6, 100)
    fill(im, mask_rrect(im.size, (body[0], body[1] + 5, body[2], body[3] + 5), 26), edge, edge)
    fill(im, mask_rrect(im.size, body, 26), top, bottom, body)
    gloss(im, body, 26, 110)
    outline(im, body, 26, (255, 255, 255, 200), 3)
    finish(im).save(f"{OUT}/{name}.png")


def ribbon_corner():
    w, h = 150, 64
    im = canvas(w, h)
    body = (4, 4, w - 4, h - 10)
    shadow(im, mask_rrect(im.size, body, 14), (0, 3), 3, 90)
    fill(im, mask_rrect(im.size, body, 14), rgba("ff5a4f"), rgba("d22d2d"), body)
    gloss(im, body, 14, 100)
    outline(im, body, 14, (255, 255, 255, 200), 2)
    finish(im).save(f"{OUT}/ribbon_red.png")


def main():
    import os
    os.makedirs(OUT, exist_ok=True)
    white = (255, 255, 255, 255)
    # menu options: white glass with grey edge (main menu)
    colors = {
        "cream": (rgba("ffffff"), rgba("e4e8ef"), rgba("b3bac8")),
        "green": (rgba("7fdc5a"), rgba("2f9e2f"), rgba("1f7a22")),
        "blue": (rgba("5cc0ff"), rgba("1f7fe0"), rgba("1559a8")),
        "orange": (rgba("ffc145"), rgba("f07c12"), rgba("b85400")),
        "red": (rgba("ff7a6b"), rgba("d93a2b"), rgba("a32416")),
        "grey": (rgba("d7d9de"), rgba("a4a8b1"), rgba("7c808a")),
        "purple": (rgba("c79bff"), rgba("8a4fe0"), rgba("6532ad")),
    }
    for key, (top, bottom, edge) in colors.items():
        pill(f"pill_{key}", 300, 80, top, bottom, edge)
        pill(f"pill_{key}_s", 240, 64, top, bottom, edge)
        pill(f"tile_{key}", 200, 110, top, bottom, edge, radius=24)
    pill("pill_dark", 240, 64, (30, 40, 70, 200), (18, 26, 50, 210), (10, 14, 30, 120), rim=(255, 255, 255, 90), gloss_strength=60)
    pill("tab_cream", 260, 96, rgba("fffaf0"), rgba("efe0c6"), rgba("c9ae86"), radius=24)
    pill("tab_green", 260, 96, rgba("7fdc5a"), rgba("2f9e2f"), rgba("1f7a22"), radius=24)
    # circles
    tri = lambda d, s: d.polygon([(s * 0.40, s * 0.30), (s * 0.40, s * 0.68), (s * 0.71, s * 0.49)], fill=white)
    circle_button("btn_play", 240, rgba("ffd84a"), rgba("f59a0c"), rgba("c06a00"), rgba("fff3c4"), tri)

    def gear(d, s):
        cx, cy, r = s * 0.5, s * 0.48, s * 0.25
        pts = []
        for i in range(32):
            a = i * math.pi / 16
            rr = r if (i // 2) % 2 == 0 else r * 0.74
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
        d.polygon(pts, fill=white)
        d.ellipse((cx - r * 0.38, cy - r * 0.38, cx + r * 0.38, cy + r * 0.38), fill=(0, 0, 0, 0))
    circle_button("btn_gear", 140, rgba("8be06a"), rgba("2f9e2f"), rgba("1f7a22"), rgba("f1ffe8"), gear)

    def back(d, s):
        # a plain "back" arrow pointing left (a circular arrow read as "reload")
        c = rgba("7a4a1c")
        d.polygon([(s * 0.22, s * 0.48), (s * 0.45, s * 0.27), (s * 0.45, s * 0.69)], fill=c)
        d.rounded_rectangle((s * 0.40, s * 0.40, s * 0.75, s * 0.56), s * 0.04, fill=c)
    circle_button("btn_back", 140, rgba("ffe27a"), rgba("f5b417"), rgba("c07d00"), rgba("fff8dc"), back)

    def pause(d, s):
        d.rounded_rectangle((s * 0.35, s * 0.30, s * 0.45, s * 0.66), s * 0.03, fill=white)
        d.rounded_rectangle((s * 0.55, s * 0.30, s * 0.65, s * 0.66), s * 0.03, fill=white)
    circle_button("btn_pause", 140, rgba("e9a35a"), rgba("b86a25"), rgba("7f4512"), rgba("ffe9cc"), pause)

    def bulb(d, s):
        d.ellipse((s * 0.34, s * 0.24, s * 0.66, s * 0.56), fill=white)
        d.rectangle((s * 0.42, s * 0.54, s * 0.58, s * 0.66), fill=white)
        d.rectangle((s * 0.43, s * 0.68, s * 0.57, s * 0.72), fill=white)
    circle_button("btn_hint", 140, rgba("ffd84a"), rgba("f59a0c"), rgba("c06a00"), rgba("fff3c4"), bulb)

    def cross(d, s):
        c = rgba("ee5a24")
        w = int(s * 0.12)
        d.line((s * 0.32, s * 0.32, s * 0.68, s * 0.66), fill=c, width=w)
        d.line((s * 0.68, s * 0.32, s * 0.32, s * 0.66), fill=c, width=w)
    circle_button("btn_close", 130, rgba("ffffff"), rgba("f1e6d2"), rgba("c9ae86"), rgba("ffffff"), cross)
    chevron("arrow_left", False)
    chevron("arrow_right", True)
    # panels
    panel("panel_cream", 300, 300, 46, rgba("fffdf6"), rgba("f6ecd6"), rgba("2e3b63"), 9)
    panel("panel_store", 300, 300, 46, rgba("fffaf0"), rgba("f3e6cf"), rgba("e8d3ad"), 6)
    panel("card_white", 200, 220, 26, rgba("ffffff"), rgba("f7f1e6"), rgba("e3d6bf"), 3)
    panel("title_strip", 300, 100, 30, rgba("fff7c2"), rgba("ffeaa0"), rgba("ffeaa0"), 0, inner_rim=(255, 255, 255, 0))
    ribbon("ribbon_blue", 380, 104, rgba("3a6fd8"), rgba("1d3f8f"), rgba("13285c"))
    ribbon_corner()
    frame("frame_green", 300, 400, 34, rgba("8be06a"), rgba("2f9e2f"), rgba("1f6e22"), 16)
    frame("frame_blue", 300, 400, 34, rgba("6cc8ff"), rgba("1f6fd0"), rgba("13459a"), 16)
    frame("frame_orange", 300, 400, 34, rgba("ffd25a"), rgba("e08a10"), rgba("a85c00"), 16)
    frame("frame_grey", 300, 400, 34, rgba("e2e4e8"), rgba("a4a8b1"), rgba("6e727c"), 16)
    logo_sign()
    # touch controls (in-level): smoky glass disc, white ring
    for name, glyph in TOUCH.items():
        im = canvas(170, 170)
        m = mask_ellipse(im.size, (8, 8, 162, 162))
        fill(im, m, (40, 44, 60, 120), (20, 22, 34, 140))
        gb = (30, 16, 140, 84)
        fill(im, mask_ellipse(im.size, gb), (255, 255, 255, 70), (255, 255, 255, 0), gb)
        o = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(o).ellipse((10 * SS, 10 * SS, 160 * SS, 160 * SS), outline=(255, 255, 255, 235), width=6 * SS)
        im.alpha_composite(o)
        g = Image.new("RGBA", im.size, (0, 0, 0, 0))
        glyph(ImageDraw.Draw(g), 170 * SS)
        im.alpha_composite(g)
        finish(im).save(f"{OUT}/touch_{name}.png")


W = (255, 255, 255, 245)


def _fire(d, s):
    # a shot flying right with speed lines behind it
    d.ellipse((s * .52, s * .36, s * .76, s * .60), fill=W)
    for i, y in enumerate((.40, .48, .56)):
        d.rounded_rectangle((s * (.22 + .06 * (i % 2)), s * (y - .02), s * .47, s * (y + .02)), s * .02, fill=W)


def _swap(d, s):
    # two arrows chasing each other: switch the weapon
    w = int(s * .07)
    d.arc((s * .27, s * .27, s * .73, s * .73), 200, 340, fill=W, width=w)
    d.arc((s * .27, s * .27, s * .73, s * .73), 20, 160, fill=W, width=w)
    d.polygon([(s * .70, s * .26), (s * .78, s * .42), (s * .62, s * .40)], fill=W)
    d.polygon([(s * .30, s * .74), (s * .22, s * .58), (s * .38, s * .60)], fill=W)


TOUCH = {
    "fire": _fire,
    "swap": _swap,
    "left": lambda d, s: (d.polygon([(s * .27, s * .5), (s * .5, s * .29), (s * .5, s * .71)], fill=W), d.rounded_rectangle((s * .46, s * .42, s * .72, s * .58), s * .03, fill=W)),
    "right": lambda d, s: (d.polygon([(s * .73, s * .5), (s * .5, s * .29), (s * .5, s * .71)], fill=W), d.rounded_rectangle((s * .28, s * .42, s * .54, s * .58), s * .03, fill=W)),
    "jump": lambda d, s: (d.polygon([(s * .5, s * .26), (s * .71, s * .5), (s * .29, s * .5)], fill=W), d.rounded_rectangle((s * .42, s * .46, s * .58, s * .73), s * .03, fill=W)),
    "time": lambda d, s: (d.polygon([(s * .34, s * .28), (s * .66, s * .28), (s * .5, s * .5)], fill=W), d.polygon([(s * .5, s * .5), (s * .66, s * .72), (s * .34, s * .72)], fill=W),
                          d.rounded_rectangle((s * .3, s * .24, s * .7, s * .29), s * .02, fill=W), d.rounded_rectangle((s * .3, s * .71, s * .7, s * .76), s * .02, fill=W)),
    "dash": lambda d, s: (d.polygon([(s * .26, s * .3), (s * .48, s * .5), (s * .26, s * .7), (s * .36, s * .5)], fill=W),
                          d.polygon([(s * .5, s * .3), (s * .74, s * .5), (s * .5, s * .7), (s * .6, s * .5)], fill=W)),
    "pilo": lambda d, s: (d.ellipse((s * .33, s * .48, s * .67, s * .74), fill=W), d.ellipse((s * .24, s * .36, s * .36, s * .5), fill=W),
                          d.ellipse((s * .36, s * .25, s * .48, s * .41), fill=W), d.ellipse((s * .52, s * .25, s * .64, s * .41), fill=W),
                          d.ellipse((s * .64, s * .36, s * .76, s * .5), fill=W)),
    "down": lambda d, s: (d.polygon([(s * .5, s * .74), (s * .71, s * .5), (s * .29, s * .5)], fill=W), d.rounded_rectangle((s * .42, s * .27, s * .58, s * .54), s * .03, fill=W)),
}

if __name__ == "__main__":
    main()
