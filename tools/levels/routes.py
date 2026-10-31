#!/usr/bin/env python3
"""Measures the routes of the platformer levels with the validator's reachability search:

  upper   share of the level's columns where Nima can stand high above the ground road
          (on planks, roofs, tree tops...)
  under   columns of the underground he can actually reach (secret rooms, corridors)
  secret  reachable warp pipes + fox dens

    python3 tools/levels/routes.py            # every level, a table
    python3 tools/levels/routes.py 12 27      # only these

`measure(data)` is also used by compose.py to enforce the minimum: every regular level has
an upper route, an underground route and a pipe or a den.
"""
import glob
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tests"))
import validate_levels as V  # noqa: E402

G = 16
UPPER_ROW = G - 4          # standing on row <= this (feet) counts as the upper route

# the minimum every regular level (not the secret level or the boss arena) must reach
MIN_UPPER = 0.40
MIN_UNDER = 14
MIN_SECRET = 1


def measure(data):
    level = V.Level(data)
    starts = level.find("P")
    if len(starts) != 1:
        return None
    sx, sy = starts[0]
    states = V.explore(level, [(sx, sy, level.start_time, 0, 0)])
    upper = {s[0] for s in states if s[1] <= UPPER_ROW}
    under = {s[0] for s in states if s[1] >= G + 1}
    warps = sum(1 for (px, py) in level.warps if any(s[1] == py - 1 and s[0] in (px, px + 1) for s in states))
    dens = sum(1 for d in level.find("X") + level.find("Y") if V.touches(states, d[0], d[1], level))
    return {"width": level.w, "upper": len(upper) / level.w, "under": len(under), "secret": warps + dens,
            "warps": warps, "dens": dens}


def meets_minimum(m):
    return m["upper"] >= MIN_UPPER and m["under"] >= MIN_UNDER and m["secret"] >= MIN_SECRET


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "data", "levels", "*", "level_*.json")),
                   key=lambda p: int(os.path.basename(p)[6:8]))
    only = {int(a) for a in sys.argv[1:] if a.isdigit()}
    weak = 0
    print("id  world          width upper under warps dens  ok")
    for path in files:
        data = json.load(open(path, encoding="utf-8"))
        if only and data["id"] not in only:
            continue
        m = measure(data)
        n = (data["id"] - 1) % 8 + 1
        regular = n <= 6
        ok = meets_minimum(m) if regular else True
        weak += not ok
        print("%2d  %-14s %5d %4d%% %5d %5d %4d  %s" % (data["id"], data.get("world", ""), m["width"], round(m["upper"] * 100),
                                                    m["under"], m["warps"], m["dens"], "ok" if ok else ("WEAK" if regular else "-")))
    print("%d regular level(s) below the minimum" % weak)


if __name__ == "__main__":
    main()
