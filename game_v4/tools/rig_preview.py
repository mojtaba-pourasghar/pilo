#!/usr/bin/env python3
"""Draws the cut-out rig in a few poses with the same math as scripts/cutout_rig.gd (to check pivots quickly).
  python3 game_v4/tools/rig_preview.py grandfather out.png"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(__file__)


def load(who):
    rig = json.load(open(os.path.join(HERE, "..", "data", "rig_%s.json" % who)))
    sheet = rig["sheet"]
    meta = json.load(open(os.path.join(HERE, "..", "art", "cut", sheet, sheet + ".json")))
    parts = {}
    for name, d in rig["parts"].items():
        p = meta["pieces"][d["piece"]]
        img = Image.open(os.path.join(HERE, "..", "art", "cut", sheet, p["file"])).convert("RGBA")
        w, h = img.size
        piv = (d["pivot"][0] * w, d["pivot"][1] * h)
        tip = (d["tip"][0] * w, d["tip"][1] * h)
        extra = {k: (v[0] * w, v[1] * h) for k, v in d.items() if k in ("shoulder", "shoulder_b", "hip")}
        parts[name] = {"img": img, "piv": piv, "tip": tip, "extra": extra}
    return rig["scale"], parts


def length(part, s):
    return math.dist(part["piv"], part["tip"]) * s


def place(canvas, part, at, ang, s, shade=1.0):
    """Draws `part` with its pivot at `at` and pivot->tip pointing along angle `ang`; returns a function that maps a
    picture point to the canvas."""
    v = (part["tip"][0] - part["piv"][0], part["tip"][1] - part["piv"][1])
    r = ang - math.atan2(v[1], v[0])
    c, sn = math.cos(r), math.sin(r)

    def to_canvas(q):
        dx, dy = (q[0] - part["piv"][0]) * s, (q[1] - part["piv"][1]) * s
        return (at[0] + c * dx - sn * dy, at[1] + sn * dx + c * dy)

    img = part["img"]
    if shade < 1.0:
        px = img.split()
        rgb = Image.merge("RGB", px[:3]).point(lambda v: int(v * shade))
        img = Image.merge("RGBA", (*rgb.split(), px[3]))
    # inverse affine: canvas -> picture
    ic, isn = math.cos(-r), math.sin(-r)
    a = ic / s
    b = -isn / s
    d = isn / s
    e = ic / s
    cx = part["piv"][0] - (a * at[0] + b * at[1])
    cy = part["piv"][1] - (d * at[0] + e * at[1])
    layer = img.transform(canvas.size, Image.AFFINE, (a, b, cx, d, e, cy), resample=Image.BICUBIC)
    canvas.alpha_composite(layer)
    return to_canvas


def down(t):
    return math.pi / 2 + t


def draw(canvas, s, P, origin, pose):
    ox, oy = origin
    thigh, shin, foot = length(P["thigh"], s), length(P["shin"], s), length(P["foot"], s)
    hip = (ox, oy - (thigh + shin + foot * 0.85) + pose.get("bob", 0))
    lean = pose.get("lean", 0)
    up = -math.pi / 2 + lean

    def leg(jt, t, k, fa, shade):
        knee = (jt[0] + math.cos(down(t)) * thigh, jt[1] + math.sin(down(t)) * thigh)
        ankle = (knee[0] + math.cos(down(t + k)) * shin, knee[1] + math.sin(down(t + k)) * shin)
        place(canvas, P["foot"], ankle, down(fa), s, shade)
        place(canvas, P["shin"], knee, down(t + k), s, shade)
        place(canvas, P["thigh"], jt, down(t), s, shade)

    def arm(sh, a, e, shade, hand="hand"):
        up_l, fo_l = length(P["upper"], s), length(P["fore"], s)
        el = (sh[0] + math.cos(down(a)) * up_l, sh[1] + math.sin(down(a)) * up_l)
        wr = (el[0] + math.cos(down(a + e)) * fo_l, el[1] + math.sin(down(a + e)) * fo_l)
        place(canvas, P["upper"], sh, down(a), s, shade)
        place(canvas, P["fore"], el, down(a + e), s, shade)
        place(canvas, P[hand], wr, down(a + e), s, shade)
        return wr

    # torso transform (needed for the shoulder point), drawn later
    tmp = Image.new("RGBA", canvas.size)
    to_t = place(tmp, P["torso"], hip, up, s)
    shoulder = to_t(P["torso"]["extra"]["shoulder"])
    shoulder_b = to_t(P["torso"]["extra"]["shoulder_b"])
    neck = to_t(P["torso"]["tip"])
    to_p = place(Image.new("RGBA", canvas.size), P["pelvis"], hip, down(lean * 0.5), s)
    hipj = to_p(P["pelvis"]["extra"]["hip"])
    arm(shoulder_b, pose["sh_b"], pose["el_b"], 0.72, "fist")
    leg((hipj[0] - 6, hipj[1]), pose["thigh_b"], pose["knee_b"], pose.get("foot_b", 0), 0.72)
    place(canvas, P["cloak"], (shoulder[0] - 6, shoulder[1] - 6), down(lean + pose.get("cloak", 0.25)), s)
    place(canvas, P["pelvis"], hip, down(lean * 0.5), s)
    leg((hipj[0] + 6, hipj[1]), pose["thigh_f"], pose["knee_f"], pose.get("foot_f", 0), 1.0)
    canvas.alpha_composite(tmp)
    place(canvas, P["head"], neck, up + pose.get("head", 0), s)
    wr = arm(shoulder, pose["sh_f"], pose["el_f"], 1.0, "grip")
    place(canvas, P["staff"], wr, down(pose.get("staff", -0.12)), s)


POSES = {
    "idle": {"thigh_f": -0.05, "knee_f": 0.1, "thigh_b": 0.08, "knee_b": 0.1, "sh_f": 0.1, "el_f": -0.4, "sh_b": -0.1, "el_b": -0.4},
    "run1": {"lean": 0.16, "thigh_f": -0.85, "knee_f": 0.4, "thigh_b": 0.7, "knee_b": 1.2, "sh_f": 0.75, "el_f": -1.1, "sh_b": -0.75, "el_b": -1.1, "bob": -4},
    "run2": {"lean": 0.16, "thigh_f": 0.7, "knee_f": 1.2, "thigh_b": -0.85, "knee_b": 0.4, "sh_f": -0.75, "el_f": -1.1, "sh_b": 0.75, "el_b": -1.1},
    "jump": {"staff": -2.4, "lean": 0.1, "thigh_f": -1.1, "knee_f": 1.5, "thigh_b": -0.15, "knee_b": 0.8, "sh_f": -2.5, "el_f": -0.2, "sh_b": 0.9, "el_b": -0.6, "cloak": 0.9},
}

if __name__ == "__main__":
    who = sys.argv[1] if len(sys.argv) > 1 else "grandfather"
    out = sys.argv[2] if len(sys.argv) > 2 else "rig.png"
    s, P = load(who)
    s *= 2.0
    canvas = Image.new("RGBA", (300 * len(POSES), 520), (90, 120, 110, 255))
    for i, (name, pose) in enumerate(POSES.items()):
        draw(canvas, s, P, (150 + i * 300, 480), pose)
    canvas.save(out)
    print("ok", out)
