#!/usr/bin/env python3
"""Static checks for level maps (run before committing level changes).

    python3 tests/validate_levels.py            # every level
    python3 tests/validate_levels.py 12 27      # only these

For every data/levels/*/level_XX.json it checks the legend, start / exit / checkpoint
placement and runs a coarse reachability search with the hero's jump limits. The search state
is (column, row, time, mirror orientations, switches), and the light beam is traced for each
combination, so a level that needs a mirror turned or a rock to vanish so the light can pass is
modelled. Keys open doors and switches + lit sensors open gates (both stay open, as in the
game). It reports exits that cannot be reached and stars that look unreachable. It is an
approximation of the real physics: a passing level still needs to be played by a person.
"""
import glob
import json
import os
import sys
from collections import deque

PAST, PRESENT = 0, 1
LEGEND = set(".#roBVMKD*CEPi?GRf~wamu<>^Lg/\\SOxz") | set("QUJHb$ncd+keyhFTtANpWYX") | set("Isq=_vZ&|")
REACH = {0: 4, 1: 3, 2: 2}        # rise in tiles -> horizontal reach (puzzle levels: walk 330)
# Platformer levels ("format": 2): JUMP_VELOCITY -870 plus run bonus, RUN 470, one air dash.
REACH_V2 = {0: 6, 1: 5, 2: 4, 3: 2}
SPRING_RISE = 6
BLOCKS = set("QUJHb$N")           # solid blocks (bricks are kept solid: conservative)
WIND_BONUS = 2                    # extra reach with the wind behind you
DIRS = {"right": (1, 0), "left": (-1, 0), "up": (0, -1), "down": (0, 1)}
TIME_MASKS = {"past": {PAST}, "present": {PRESENT}, "both": {PAST, PRESENT}}


class Level:
    def __init__(self, data):
        rows = data["map"]
        self.w = max(len(r) for r in rows)
        self.h = len(rows)
        self.g = [r.ljust(self.w, ".") for r in rows]
        self.move_range = int(data.get("move_range", 4))
        self.v2 = int(data.get("format", 1)) >= 2
        # pipes: two tiles wide, from the 'p' down to the ground
        self.pipe_cells = set()
        self.pipe_tops = {}
        for (x, y) in [(x, y) for y, r in enumerate(self.g) for x, c in enumerate(r) if c == "p"]:
            yy = y
            while yy < self.h and self.g[yy][x] not in "#roBV":
                self.pipe_cells.update({(x, yy), (x + 1, yy)})
                yy += 1
            self.pipe_tops[(x, y)] = True
        self.warps = {}
        for warp in data.get("warps", []):
            self.warps[tuple(warp["from"])] = tuple(warp["to"])
        self.rafts = set()
        for (x, y) in [(x, y) for y, r in enumerate(self.g) for x, c in enumerate(r) if c == "t"]:
            self.rafts.update({(x, y), (x + 1, y)})
        self.start_time = PAST if data.get("start_time", "present") == "past" else PRESENT
        self.wind_times = TIME_MASKS[data.get("wind_time", "both")]
        self.doors_open = False
        self.gates_open = False
        self.ride = set()
        for y, row in enumerate(self.g):
            for x, c in enumerate(row):
                if c == "m":
                    for dx in range(self.move_range + 2):
                        self.ride.add((x + dx, y))
                elif c == "u":
                    for dy in range(self.move_range + 1):
                        self.ride.update({(x, y - dy), (x + 1, y - dy)})
        self.mirrors = self.find("/") + self.find("\\")
        self.mirrors.sort(key=lambda p: (p[1], p[0]))
        self.mirror_bit = {cell: 1 << i for i, cell in enumerate(self.mirrors)}
        self.levers = self.find("L")
        self.lever_bit = {cell: 1 << i for i, cell in enumerate(self.levers)}
        self.sensors = set(self.find("O"))
        self.crystals = set(self.find("x"))
        dirs = data.get("source_dirs", [])
        self.sources = [(cell, DIRS[dirs[i] if i < len(dirs) else "right"]) for i, cell in enumerate(self.find("S"))]
        # updraft hover cells: the column itself and the cell just above its top
        self.updraft = set()
        for x, y in self.find("^"):
            self.updraft.add((x, y))
            if self.at(x, y - 1) != "^":
                self.updraft.add((x, y - 1))
        self._beam_cache = {}

    def find(self, char):
        return [(x, y) for y, row in enumerate(self.g) for x, c in enumerate(row) if c == char]

    def at(self, x, y):
        if y >= self.h or x < 0 or x >= self.w:
            return "#" if y < self.h else "."
        if y < 0:
            return "."
        return self.g[y][x]

    # --- light -------------------------------------------------------------
    def lit(self, t, cfg):
        key = (t, cfg, self.gates_open)
        if key not in self._beam_cache:
            lit = set()
            for (cell, d) in self.sources:
                x, y = cell
                dx, dy = d
                for _ in range(240):
                    x, y = x + dx, y + dy
                    c = self.at(x, y)
                    if (x, y) in self.mirror_bit:
                        slash = (c == "/") != bool(cfg & self.mirror_bit[(x, y)])
                        dx, dy = (-dy, -dx) if slash else (dy, dx)
                        continue
                    if (x, y) in self.sensors:
                        lit.add((x, y))
                        break
                    if (x, y) in self.crystals:
                        lit.add((x, y))
                        continue
                    if c in "#DM" or (c == "r" and t == PAST) or (c == "g" and not self.gates_open) or not (0 <= y < self.h):
                        break
            self._beam_cache[key] = lit
        return self._beam_cache[key]

    def sensors_lit(self, t, cfg):
        return self.sensors <= self.lit(t, cfg)

    # --- tiles ---------------------------------------------------------------
    def solid(self, x, y, t):
        c = self.at(x, y)
        return (c in "#MI=_" or c in BLOCKS or c == "F" or (x, y) in self.pipe_cells or (c == "r" and t == PAST)
                or (c == "D" and not self.doors_open) or (c == "g" and not self.gates_open))

    def one_way(self, x, y, t, cfg):
        c = self.at(x, y)
        return (c in "ozqv" or (x, y) in self.rafts or (c == "B" and t == PAST) or (c == "V" and t == PRESENT) or (x, y) in self.ride
                or (c == "x" and (x, y) in self.lit(t, cfg)))

    def hazard(self, x, y, t):
        c = self.at(x, y)
        return c in "aA" or (c == "~" and t == PRESENT) or (c == "w" and t == PAST)

    def free(self, x, y, t):
        return not self.solid(x, y, t) and not self.hazard(x, y, t)

    def body_free(self, x, y, t):
        return 0 <= x < self.w and self.free(x, y, t) and self.free(x, y - 1, t)

    def hover(self, x, y, t):
        # updrafts lift the hero; in deep water ("s") he swims anywhere
        return ((x, y) in self.updraft and t in self.wind_times) or self.at(x, y) == "s" or self.at(x, y + 1) == "s"

    def standable(self, x, y, t, cfg):
        if not self.body_free(x, y, t):
            return False
        if self.hover(x, y, t):
            return True
        return y + 1 < self.h and (self.solid(x, y + 1, t) or self.one_way(x, y + 1, t, cfg))

    def fall(self, x, y, t, cfg):
        while y < self.h:
            if self.hazard(x, y, t):
                return None
            if self.standable(x, y, t, cfg):
                return (x, y)
            y += 1
        return None

    def column_clear(self, x, y0, y1, t):
        lo, hi = min(y0, y1), max(y0, y1)
        return all(self.free(x, y, t) for y in range(lo, hi + 1))

    def wind_helps(self, x0, x1, row, t):
        if t not in self.wind_times:
            return False
        want = ">" if x1 > x0 else "<"
        step = 1 if x1 > x0 else -1
        return any(self.at(cx, r) == want for cx in range(x0, x1 + step, step) for r in (row, row - 1, row + 1))

    # --- search --------------------------------------------------------------
    def touches(self, x, y, cells):
        return [c for c in cells if c[0] == x and c[1] in (y, y - 1)]

    def moves(self, state):
        x, y, t, cfg, lev = state
        for cell in self.touches(x, y, self.mirror_bit):
            yield (x, y, t, cfg ^ self.mirror_bit[cell], lev)
        for cell in self.touches(x, y, self.lever_bit):
            yield (x, y, t, cfg, lev | self.lever_bit[cell])
        other = 1 - t
        if self.body_free(x, y, other):
            landing = self.fall(x, y, other, cfg)
            if landing:
                yield (landing[0], landing[1], other, cfg, lev)
        for (px, py), dest in self.warps.items():
            if y == py - 1 and x in (px, px + 1):
                tx, ty = dest
                landing = (tx, ty - 1) if (tx, ty) in self.pipe_tops else self.fall(tx, ty, t, cfg)
                if landing and self.standable(landing[0], landing[1], t, cfg):
                    yield (landing[0], landing[1], t, cfg, lev)
        if self.v2:
            # Pilo carries Nima in a glide: far across, slowly down (at most one row up)
            for dx in range(-12, 13):
                nx = x + dx
                for ny in range(max(0, y - 1), self.h):
                    if abs(dx) > min(12, 6 + 3 * max(0, ny - y)) or abs(dx) < 4:
                        continue
                    if not self.standable(nx, ny, t, cfg):
                        continue
                    top = min(y, ny) - 2
                    step = 1 if dx > 0 else -1
                    if all(self.free(cx, top, t) and self.free(cx, top + 1, t) for cx in range(x, nx + step, step)) \
                            and self.column_clear(nx, top, ny, t):
                        yield (nx, ny, t, cfg, lev)
        on_spring = self.at(x, y + 1) == "M"
        max_rise = SPRING_RISE if on_spring else (3 if self.v2 else 2)
        for dx in range(-8, 9):
            nx = x + dx
            for ny in range(max(0, y - max_rise), self.h):
                rise = y - ny
                table = REACH_V2 if self.v2 else REACH
                if rise > 0:
                    reach = 3 if on_spring else table[rise]
                else:
                    reach = table[0] + (-rise) // 2
                if dx and self.wind_helps(x, nx, min(y, ny), t):
                    reach += WIND_BONUS
                if abs(dx) > reach or (dx == 0 and rise == 0):
                    continue
                if not self.standable(nx, ny, t, cfg):
                    continue
                top = min(y, ny)
                ok = self.column_clear(x, top - 1, y, t)
                step = 1 if dx > 0 else -1
                for cx in range(x + step, nx + step, step) if dx else []:
                    if not (self.free(cx, top, t) and self.free(cx, top - 1, t)):
                        ok = False
                        break
                if ok and self.column_clear(nx, top - 1, ny, t):
                    yield (nx, ny, t, cfg, lev)

    def search(self, starts):
        seen = set(starts)
        queue = deque(starts)
        while queue:
            for nxt in self.moves(queue.popleft()):
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return seen


def touches(states, cx, cy, level, rise=3, arc=False):
    """Can a body standing in one of `states` reach the cell by jumping straight up? With
    arc=True a cell up to two columns away also counts (a star hanging over a gap is met on the
    way across)."""
    span = 2 if arc else 1
    for (x, y, t, cfg, lev) in states:
        lift = SPRING_RISE if level.at(x, y + 1) == "M" else rise
        if abs(x - cx) <= span and y - lift <= cy <= y:
            return True
    return False


def body_touches(states, cx, cy):
    return any(s[0] == cx and cy in (s[1], s[1] - 1, s[1] + 1) for s in states)


def explore(level, starts):
    """Searches, opening doors and gates (they latch) whenever the reachable states allow it."""
    states = level.search(starts)
    while True:
        changed = False
        keys = level.find("K")
        if level.find("D") and keys and not level.doors_open and any(touches(states, kx, ky, level) for kx, ky in keys):
            level.doors_open = changed = True
        all_levers = (1 << len(level.levers)) - 1
        if level.find("g") and not level.gates_open and (level.levers or level.sensors):
            if any(s[4] == all_levers and level.sensors_lit(s[2], s[3]) for s in states):
                level.gates_open = changed = True
        if not changed:
            return states
        level._beam_cache.clear()
        states = level.search(list(states))


def check(path):
    errors, warnings = [], []
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for key in ("id", "title", "map"):
        if key not in data:
            errors.append("missing key '%s'" % key)
    if errors:
        return errors, warnings
    level = Level(data)
    bad = set("".join(level.g)) - LEGEND
    if bad:
        errors.append("unknown map characters: %s" % "".join(sorted(bad)))
    starts, exits = level.find("P"), level.find("E")
    if len(starts) != 1 or len(exits) != 1:
        errors.append("need exactly one P and one E (found %d / %d)" % (len(starts), len(exits)))
        return errors, warnings
    for (x, y) in starts + level.find("C"):
        if level.at(x, y + 1) not in "#":
            errors.append("start/checkpoint at %d,%d must stand on '#' (exists in both times)" % (x, y))
    if level.find("i") and len(level.find("i")) > len(data.get("signs", [])):
        errors.append("more 'i' signs than texts in 'signs'")
    if data.get("lens", True) is False and any(c in "".join(level.g) for c in "rBV~wz"):
        errors.append("lens is off but the map has time-dependent tiles")
    if level.find("g") and not (level.levers or level.sensors):
        errors.append("gates but no switch or sensor to open them")
    if len(level.mirrors) > 6:
        errors.append("too many mirrors for the checker (max 6)")
    if data.get("chase") and len(level.find("G")) != 1:
        errors.append("a chase level needs exactly one G")

    sx, sy = starts[0]
    states = explore(level, [(sx, sy, level.start_time, 0, 0)])
    if level.find("D") and not level.doors_open:
        errors.append("key is unreachable, so the door never opens")
    if level.find("g") and not level.gates_open:
        errors.append("gates never open (switches/sensors cannot all be reached or lit)")
    ex, ey = exits[0]
    if not body_touches(states, ex, ey):
        errors.append("exit looks unreachable from the start")
    for kx, ky in level.find("k") + level.find("X"):
        if not touches(states, kx, ky, level):
            errors.append("time key at %d,%d looks unreachable" % (kx, ky))
        else:
            near = [s for s in states if abs(s[0] - kx) <= 1 and ky - 2 <= s[1] <= ky + 1]
            if not body_touches(level.search(near), ex, ey):
                errors.append("exit unreachable after taking the time key")
    for warp in data.get("warps", []):
        if tuple(warp["from"]) not in level.pipe_tops:
            errors.append("warp from %s is not the top-left of a pipe" % (warp["from"],))
    for d in level.find("d") + level.find("c"):
        # coins hanging over a gap are met in flight (a long jump, a glide or the wind)
        over_gap = all(level.at(d[0], yy) in ".cd*^><" for yy in range(d[1] + 1, min(level.h, d[1] + 5)))
        if over_gap and any(abs(s[0] - d[0]) <= 7 and d[1] - 4 <= s[1] for s in states):
            continue
        if not touches(states, d[0], d[1], level, arc=True):
            warnings.append("%s at %d,%d may be unreachable" % (level.at(*d), d[0], d[1]))
    for rx, ry in level.find("R"):
        if not touches(states, rx, ry, level, rise=2):
            errors.append("friend at %d,%d looks unreachable" % (rx, ry))
        else:
            near = [s for s in states if abs(s[0] - rx) <= 1 and ry - 2 <= s[1] <= ry + 1]
            if not body_touches(level.search(near), ex, ey):
                errors.append("exit unreachable after rescuing the friend")
    stars = level.find("*")
    if len(stars) != 3:
        warnings.append("has %d stars (3 expected)" % len(stars))
    for (x, y) in stars:
        over_gap = all(level.at(x, yy) in ".cd*^><" for yy in range(y + 1, min(level.h, y + 5)))
        if over_gap and any(abs(s[0] - x) <= 7 and y - 4 <= s[1] for s in states):
            continue
        if not touches(states, x, y, level, arc=True):
            warnings.append("star at %d,%d may be unreachable" % (x, y))
    return errors, warnings


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "levels")
    files = sorted(glob.glob(os.path.join(root, "*", "level_*.json")))
    only = {int(a) for a in sys.argv[1:] if a.isdigit()}
    if only:
        files = [f for f in files if int(os.path.basename(f)[6:8]) in only]
    failed = 0
    for path in files:
        errors, warnings = check(path)
        name = os.path.relpath(path, root)
        print("%-4s %s" % ("FAIL" if errors else "ok", name))
        for e in errors:
            print("     error:", e)
        for w in warnings:
            print("     warn: ", w)
        failed += bool(errors)
    print("%d level(s), %d failed" % (len(files), failed))
    return 1 if failed or not files else 0


if __name__ == "__main__":
    sys.exit(main())
