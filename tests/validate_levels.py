#!/usr/bin/env python3
"""Static checks for level maps (run before committing level changes).

    python3 tests/validate_levels.py

For every data/levels/*/level_XX.json it checks the legend, start / exit / checkpoint
placement and runs a coarse reachability search over (column, row, time) using the
hero's jump limits. It reports levels whose exit cannot be reached without a purchase or
optional stars, and stars that look unreachable. The search is an approximation of the
real physics: a passing level still needs to be played by a person.
"""
import glob
import json
import os
import sys
from collections import deque

PAST, PRESENT = 0, 1
LEGEND = set(".#roBVMKD*CEPi?GRf~wamu")
# Jump limits in tiles (rise -> horizontal reach) for JUMP_VELOCITY -830, SPEED 330.
REACH = {0: 4, 1: 3, 2: 2}
SPRING_RISE = 6


class Level:
    def __init__(self, data):
        rows = data["map"]
        self.w = max(len(r) for r in rows)
        self.h = len(rows)
        self.g = [r.ljust(self.w, ".") for r in rows]
        self.move_range = int(data.get("move_range", 4))
        self.start_time = PAST if data.get("start_time", "present") == "past" else PRESENT
        self.doors_open = False
        self.ride = set()  # cells covered by moving platforms (treated as one-way floor)
        for y, row in enumerate(self.g):
            for x, c in enumerate(row):
                if c == "m":
                    for dx in range(self.move_range + 2):
                        self.ride.add((x + dx, y))
                elif c == "u":
                    for dy in range(self.move_range + 1):
                        self.ride.update({(x, y - dy), (x + 1, y - dy)})

    def at(self, x, y):
        if x < 0 or x >= self.w or y >= self.h:
            return "#" if y < self.h and (x < 0 or x >= self.w) else "."
        if y < 0:
            return "."
        return self.g[y][x]

    def solid(self, x, y, t):
        c = self.at(x, y)
        return c in "#M" or (c == "r" and t == PAST) or (c == "D" and not self.doors_open)

    def one_way(self, x, y, t):
        c = self.at(x, y)
        return c == "o" or (c == "B" and t == PAST) or (c == "V" and t == PRESENT) or (x, y) in self.ride

    def hazard(self, x, y, t):
        c = self.at(x, y)
        return c == "a" or (c == "~" and t == PRESENT) or (c == "w" and t == PAST)

    def free(self, x, y, t):
        return not self.solid(x, y, t) and not self.hazard(x, y, t)

    def body_free(self, x, y, t):
        return 0 <= x < self.w and self.free(x, y, t) and self.free(x, y - 1, t)

    def standable(self, x, y, t):
        return self.body_free(x, y, t) and y + 1 < self.h and (self.solid(x, y + 1, t) or self.one_way(x, y + 1, t))

    def fall(self, x, y, t):
        """Where a body released at (x, y) in time t comes to rest, or None (pit / water)."""
        while y < self.h:
            if self.hazard(x, y, t):
                return None
            if self.standable(x, y, t):
                return (x, y)
            y += 1
        return None

    def column_clear(self, x, y0, y1, t):
        lo, hi = min(y0, y1), max(y0, y1)
        return all(self.free(x, y, t) for y in range(lo, hi + 1))

    def moves(self, x, y, t):
        on_spring = self.at(x, y + 1) == "M"
        max_rise = SPRING_RISE if on_spring else 2
        # time shift in place
        other = 1 - t
        if self.body_free(x, y, other):
            landing = self.fall(x, y, other)
            if landing:
                yield (landing[0], landing[1], other)
        for dx in range(-6, 7):
            nx = x + dx
            for ny in range(max(0, y - max_rise), self.h):
                rise = y - ny
                if rise > 0:
                    reach = 3 if on_spring else REACH[rise]
                else:
                    reach = 4 + (-rise) // 2
                if abs(dx) > reach or (dx == 0 and rise == 0):
                    continue
                if not self.standable(nx, ny, t):
                    continue
                top = min(y, ny)
                ok = self.column_clear(x, top - 1, y, t)
                step = 1 if dx > 0 else -1
                for cx in range(x + step, nx + step, step) if dx else []:
                    if not (self.free(cx, top, t) and self.free(cx, top - 1, t)):
                        ok = False
                        break
                if ok and self.column_clear(nx, top - 1, ny, t):
                    yield (nx, ny, t)

    def search(self, starts):
        seen = set(starts)
        queue = deque(starts)
        while queue:
            state = queue.popleft()
            for nxt in self.moves(*state):
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return seen

    def find(self, char):
        return [(x, y) for y, row in enumerate(self.g) for x, c in enumerate(row) if c == char]


def touches(states, cx, cy, level, rise=3):
    for (x, y, t) in states:
        lift = SPRING_RISE if level.at(x, y + 1) == "M" else rise
        if abs(x - cx) <= 1 and y - lift <= cy <= y:
            return True
    return False


def body_touches(states, cx, cy):
    return any(x == cx and cy in (y, y - 1, y + 1) for (x, y, t) in states)


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
        if level.at(x, y + 1) != "#":
            errors.append("start/checkpoint at %d,%d must stand on '#' (exists in both times)" % (x, y))
    if level.find("i") and len(level.find("i")) > len(data.get("signs", [])):
        errors.append("more 'i' signs than texts in 'signs'")
    if data.get("lens", True) is False and any(c in "".join(level.g) for c in "rBV~w"):
        errors.append("lens is off but the map has time-dependent tiles")

    sx, sy = starts[0]
    states = level.search([(sx, sy, level.start_time)])
    keys = level.find("K")
    if level.find("D") and keys:
        if any(touches(states, kx, ky, level) for kx, ky in keys):
            level.doors_open = True
            states = level.search([(sx, sy, level.start_time)])
        else:
            errors.append("key is unreachable, so the door never opens")
    ex, ey = exits[0]
    if not body_touches(states, ex, ey):
        errors.append("exit looks unreachable from the start")
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
        if not touches(states, x, y, level):
            warnings.append("star at %d,%d may be unreachable" % (x, y))
    return errors, warnings


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "levels")
    files = sorted(glob.glob(os.path.join(root, "*", "level_*.json")))
    failed = 0
    for path in files:
        errors, warnings = check(path)
        name = os.path.relpath(path, root)
        status = "FAIL" if errors else "ok"
        print("%-4s %s" % (status, name))
        for e in errors:
            print("     error:", e)
        for w in warnings:
            print("     warn: ", w)
        failed += bool(errors)
    print("%d level(s), %d failed" % (len(files), failed))
    return 1 if failed or not files else 0


if __name__ == "__main__":
    sys.exit(main())
