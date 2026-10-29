"""World 1, level 1 «راه سنجابک»: the sample platformer level of version 2.

Writes data/levels/forest/level_01.json. Run:  python3 tools/levels/forest_01.py
The map is built from named pieces at tile coordinates so it stays readable and easy to
change. Routes: ground (main), tree tops (fast, coins, a diamond), underground corridor
(the time key is down there: the "right path"), a secret pipe room, a cracked-wall cave.
"""
import json, os

W, H = 192, 22
G = 16                      # top row of the ground
grid = [["."] * W for _ in range(H)]


def put(x, y, ch):
    grid[y][x] = ch


def row(x0, x1, y, ch):
    for x in range(x0, x1 + 1):
        grid[y][x] = ch


def rect(x0, x1, y0, y1, ch):
    for y in range(y0, y1 + 1):
        row(x0, x1, y, ch)


def text(x, y, s):
    for i, ch in enumerate(s):
        if ch != " ":
            grid[y][x + i] = ch


# --- ground everywhere, then pits and caves ------------------------------------
rect(0, W - 1, G, H - 1, "#")

# A. start: learn to run, jump and bump blocks (x 0-24)
put(3, G - 1, "P")
put(6, G - 1, "i")
text(9, G - 3, "Q.bUb")
text(10, G - 6, "ccc")
put(19, G - 1, "e")
text(15, G - 2, "c.c.c")

# B. first pit with stepping blocks, a warp pipe to the secret room (x 25-45)
rect(27, 29, G, H - 1, ".")
text(26, G - 3, "cccc")
put(23, G - 1, "i")
put(34, G - 2, "p")                      # warp pipe -> secret room
put(40, G - 1, "e")
row(38, 42, G - 4, "o")
text(38, G - 5, "c*c.c")
put(28, G - 3, "y")                     # bee over the pit

# Secret room under the start (x 1-17, rows 17-20), reached from the pipe at x 34
rect(1, 17, G + 1, H - 2, ".")
text(3, G + 2, "cccccccc")
text(3, G + 3, "cccccccc")
put(12, G + 4, "d")
put(13, G + 1, "J")
put(15, G + 3, "p")                     # exit pipe back up -> surface pipe at x 44
put(44, G - 2, "p")

# C. flag, then the fork: tree tops (spring) or the thorny ground path (x 46-72)
put(47, G - 1, "C")
put(49, G - 1, "M")
row(51, 56, G - 6, "o")
text(52, G - 7, "cccc")
row(59, 63, G - 7, "o")
put(61, G - 8, "d")
row(66, 71, G - 6, "o")
text(66, G - 7, "c.y..c")
put(69, G - 9, "*")
put(52, G - 1, "i")
row(55, 56, G - 1, "A")
put(58, G - 1, "h")                     # hedgehog: Pilo has to free it
put(61, G - 5, "T")                     # crusher over the ground path
row(64, 65, G - 1, "A")
text(66, G - 4, "QHQ")

# D. big pit: falling rafts below, planks above; a hidden diamond block (x 73-95)
rect(74, 87, G, H - 1, ".")
put(75, G - 2, "t")
put(79, G - 3, "t")
put(83, G - 2, "t")
put(79, G - 6, "n")                     # hidden block: jump from the middle raft to find it
row(73, 76, G - 6, "o")
row(80, 83, G - 7, "o")
row(87, 91, G - 6, "o")
text(80, G - 8, "cccc")
put(85, G - 4, "y")
put(93, G - 1, "e")
put(90, G - 1, "Y")                     # a fox den with a diamond (Pilo's nose finds it)
put(96, G - 1, "N")                     # shadow cannon

# E. the river: a bridge that only exists in the past (time lens) (x 98-125)
put(99, G - 1, "C")
put(101, G - 1, "i")
put(103, G - 2, "?")
row(104, 111, G, "B")
row(104, 111, G + 1, "~")
text(105, G - 3, "cccccc")
put(108, G - 4, "*")
put(117, G - 3, "F")                    # thorn wheel
put(121, G - 1, "e")
put(123, G - 1, "e")

# F. cracked wall cave (dash!) and the two ways to the gate (x 126-170)
put(127, G - 1, "i")
rect(129, 129, G - 3, G - 1, "W")
rect(130, 136, G - 4, G - 4, "#")       # cave roof
text(131, G - 1, "d.cc.d")
put(141, G - 2, "p")                    # pipe down to the corridor with the time key
row(144, 149, G - 4, "o")               # upper way (from the pipe top): coins, then the locked gate
text(144, G - 5, "cccccc")
row(152, 157, G - 6, "o")
put(154, G - 7, "d")
put(150, G - 1, "e")
put(158, G - 1, "h")
# underground corridor (rows 17-20) from x 140 to x 172, the key in the middle
rect(139, 173, G + 1, H - 2, ".")
put(141, H - 3, "p")                    # arrival pipe under the entry
text(146, H - 2, "cc.cc")
put(150, H - 2, "e")
put(156, H - 2, "X")                    # the time key, deep in a fox den: only Pilo can fetch it
text(158, G + 2, "Q.b$b")
put(162, H - 2, "e")
put(166, H - 2, "d")
put(170, H - 3, "p")                    # pipe back up near the gate
put(168, G - 2, "p")                    # surface pipe near the gate (both ways)

# G. last flag and the time gate (x 171-191)
put(173, G - 1, "C")
put(176, G - 1, "i")
put(185, G - 1, "E")
text(178, G - 4, "c.c.c")

warps = [
    {"from": [34, G - 2], "to": [15, G + 3]},     # surface -> secret room
    {"from": [15, G + 3], "to": [44, G - 2]},     # secret room -> back up
    {"from": [141, G - 2], "to": [141, H - 3]},   # down to the key corridor
    {"from": [141, H - 3], "to": [141, G - 2]},
    {"from": [170, H - 3], "to": [168, G - 2]},   # corridor -> near the gate
    {"from": [168, G - 2], "to": [170, H - 3]},   # gate -> corridor (if you came the top way)
]

level = {
    "id": 1,
    "format": 2,
    "world": "forest",
    "title": "راه سنجابک",
    "goal": "دویدن، پریدن روی سایه‌ها، جعبه‌ها، پیلو، عدسی زمان و پیدا کردن کلید زمان",
    "lens": True,
    "start_time": "present",
    "bee_span": 140,
    "wheel_length": 4,
    "intro": [
        {"who": "pilo", "text": "نیما! سایه‌ها جنگل را گرفته‌اند. باید کلید زمان را پیدا کنیم!", "id": "l01_intro_1"},
        {"who": "nima", "text": "کجاست؟", "id": "l01_intro_2"},
        {"who": "pilo", "text": "یکی از راه‌ها به کلید می‌رسد. همه را بگردیم!", "id": "l01_intro_3"},
    ],
    "outro": [
        {"who": "pilo", "text": "دروازه باز شد! سایه‌ها دارند از جنگل می‌روند.", "id": "l01_outro_1"},
        {"who": "nima", "text": "بعدی کجاست، پیلو؟", "id": "l01_outro_2"},
    ],
    "signs": [
        "دکمهٔ آبی: راه برو. نگه داری تندتر می‌دوی!",
        "روی سر قارچ‌سایه بپر تا آزاد شود. به جعبه‌ها از زیر ضربه بزن!",
        "خارپشت سایه تیغ دارد! دکمهٔ پیلو را بزن تا آزادش کند. وسط پرش، پرش را نگه دار تا پیلو تو را ببرد!",
        "پل فقط در گذشته هست. عدسی زمان را بزن!",
        "دیوار ترک‌دار؟ با دکمهٔ دَش بدو و بشکنش!",
        "دروازه قفل است. کلید زمان زیر زمین، در لانهٔ روباه است؛ از لوله پایین برو و پیلو را بفرست!",
    ],
    "warps": warps,
    "map": ["".join(r) for r in grid],
}

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "levels", "forest", "level_01.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(level, f, ensure_ascii=False, indent=1)
print("wrote", os.path.normpath(out))
for r in level["map"]:
    print(r)
