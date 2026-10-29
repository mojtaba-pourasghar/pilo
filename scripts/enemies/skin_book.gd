class_name SkinBook
extends RefCounted
## Which shadow creatures live in which world, and how they look (drawn in code until their
## painted art arrives). Every skin has a shadow colouring and its real colours once freed.
## Walkers (map "e"), flyers ("y") and spiky ones that only Pilo can free ("h").

const WALKERS := {
	"forest": "shroom", "coral_beach": "crab", "golden_desert": "scorpion", "snow_mountain": "penguin",
	"sky_islands": "cloudling", "crystal_caves": "beetle", "clock_factory": "robot", "shadow_castle": "knight",
	"inverted_land": "knight",
}
const FLYERS := {
	"forest": "bee", "coral_beach": "jelly", "golden_desert": "vulture", "snow_mountain": "owl",
	"sky_islands": "stormbird", "crystal_caves": "bat", "clock_factory": "drone", "shadow_castle": "wraith",
	"inverted_land": "wraith",
}
const SPIKIES := {
	"forest": "hog", "coral_beach": "urchin", "golden_desert": "cactus", "snow_mountain": "iceball",
	"sky_islands": "thunderpuff", "crystal_caves": "porcupine", "clock_factory": "gear", "shadow_castle": "spikeball",
	"inverted_land": "spikeball",
}
const ACCENT := {
	"forest": Color("8bd06a"), "coral_beach": Color("ff8a7a"), "golden_desert": Color("f2c46d"),
	"snow_mountain": Color("bfe8ff"), "sky_islands": Color("ffe46b"), "crystal_caves": Color("b48cff"),
	"clock_factory": Color("ffb347"), "shadow_castle": Color("a06bff"), "inverted_land": Color("ff7fd0"),
}
## real colours of each skin: [main, second]
const REAL := {
	"crab": [Color("ff6b4a"), Color("ffd2b8")], "scorpion": [Color("d9963a"), Color("8a5a24")],
	"penguin": [Color("2e3a52"), Color("ffffff")], "cloudling": [Color("ffffff"), Color("cfe6ff")],
	"beetle": [Color("6fd0e8"), Color("2a6f8a")], "robot": [Color("c9ced8"), Color("ffb347")],
	"knight": [Color("8a7fb0"), Color("e0d7ff")],
	"jelly": [Color("ff9ad8"), Color("ffe0f4")], "vulture": [Color("9a6a44"), Color("f1d3ae")],
	"owl": [Color("ffffff"), Color("c9d6e8")], "stormbird": [Color("4a90e2"), Color("ffe46b")],
	"bat": [Color("8a6fd0"), Color("e0d0ff")], "drone": [Color("c9ced8"), Color("ff6b4a")],
	"wraith": [Color("c7b8ff"), Color("ffffff")],
	"urchin": [Color("8a4fd0"), Color("ffb0e0")], "cactus": [Color("6cc24a"), Color("ffd166")],
	"iceball": [Color("9fd8ff"), Color("ffffff")], "thunderpuff": [Color("fff3a0"), Color("ffcf4a")],
	"porcupine": [Color("b48cff"), Color("f1d3ae")], "gear": [Color("c9a24a"), Color("8a6a2a")],
	"spikeball": [Color("9a7fd0"), Color("e0d7ff")],
}
const SHADOW := Color("3d2d5c")
const SHADOW_2 := Color("5a4a80")


static func walker(world: String) -> String:
	return WALKERS.get(world, "shroom")


static func flyer(world: String) -> String:
	return FLYERS.get(world, "bee")


static func spiky(world: String) -> String:
	return SPIKIES.get(world, "hog")


static func accent(world: String) -> Color:
	return ACCENT.get(world, Color("8bd06a"))


static func colors(rig: EnemyRig, skin: String) -> Array:
	var real: Array = REAL.get(skin, [Color.WHITE, Color.WHITE])
	return [SHADOW.lerp(real[0], rig.freed_amount), SHADOW_2.lerp(real[1], rig.freed_amount)]


## Walkers: drawn facing right, feet at the origin.
static func draw_walker(r: EnemyRig, skin: String, step: float) -> void:
	var c := colors(r, skin)
	var bob := -absf(step) * 2.0
	match skin:
		"crab":
			for side in [-1.0, 1.0]:
				for k in 3:
					var base := Vector2(side * (8 + k * 7), -10)
					r.capsule(base, base + Vector2(side * 10, 10 + sin(r.t * 12.0 + k + side) * 3), 4.0, c[0])
			r.ellipse(Vector2(0, -20 + bob), Vector2(26, 15), c[0])
			for side in [-1.0, 1.0]:
				r.ellipse(Vector2(side * 30, -30 + bob + sin(r.t * 6.0) * 3), Vector2(10, 8), c[0])
			r.angry_eyes(Vector2(-6, -36 + bob), Vector2(6, -36 + bob), 4.5)
		"scorpion":
			r.ellipse(Vector2(-4, -14 + bob), Vector2(24, 11), c[0])
			var tail := [Vector2(-24, -16), Vector2(-34, -30), Vector2(-28, -46), Vector2(-12, -50)]
			for i in 3:
				r.capsule(tail[i], tail[i + 1], 9.0 - i, c[1])
			r.shape(PackedVector2Array([Vector2(-14, -54), Vector2(-4, -50), Vector2(-14, -44)]), c[0])
			for k in 3:
				r.capsule(Vector2(-10 + k * 9, -8), Vector2(-14 + k * 9 + step * 3, 0), 3.5, c[1])
			r.angry_eyes(Vector2(12, -20 + bob), Vector2(20, -20 + bob), 3.5)
		"penguin":
			for side in [-1.0, 1.0]:
				r.ellipse(Vector2(side * 8 + step * side * 3, -3), Vector2(8, 4), Color("ffb347"))
			r.ellipse(Vector2(0, -24 + bob), Vector2(19, 24), c[0])
			r.ellipse(Vector2(3, -20 + bob), Vector2(12, 17), c[1])
			r.shape(PackedVector2Array([Vector2(14, -34 + bob), Vector2(24, -31 + bob), Vector2(14, -28 + bob)]), Color("ffb347"))
			r.angry_eyes(Vector2(2, -38 + bob), Vector2(11, -38 + bob), 4.0)
		"cloudling":
			for p in [Vector2(-14, -18), Vector2(12, -18), Vector2(0, -30), Vector2(-4, -12), Vector2(8, -10)]:
				r.ellipse(p + Vector2(0, bob + sin(r.t * 4.0 + p.x) * 2.0), Vector2(14, 12), c[0])
			r.angry_eyes(Vector2(-4, -24 + bob), Vector2(8, -24 + bob), 4.0)
		"beetle":
			for k in 3:
				r.capsule(Vector2(-12 + k * 12, -10), Vector2(-14 + k * 12 + step * 3, 0), 3.5, c[1])
			r.ellipse(Vector2(0, -18 + bob), Vector2(24, 15), c[0])
			r.shape(PackedVector2Array([Vector2(-6, -32 + bob), Vector2(2, -46 + bob), Vector2(8, -30 + bob)]), c[1])
			r.angry_eyes(Vector2(12, -22 + bob), Vector2(20, -22 + bob), 3.6)
		"robot":
			for side in [-1.0, 1.0]:
				r.capsule(Vector2(side * 9, -14), Vector2(side * 9 + step * side * 4, 0), 7.0, c[1])
			r.shape(r.round_rect_points(Vector2(0, -30 + bob), Vector2(36, 30), 6.0), c[0])
			r.capsule(Vector2(0, -46 + bob), Vector2(0, -56 + bob), 3.0, c[1])
			r.ellipse(Vector2(0, -59 + bob), Vector2(5, 5), c[1])
			r.angry_eyes(Vector2(-6, -32 + bob), Vector2(8, -32 + bob), 4.5)
			r.draw_arc(Vector2(-20, -30 + bob), 7.0, r.t * 3.0, r.t * 3.0 + 4.5, 8, c[1], 3.0)
		"knight":
			for side in [-1.0, 1.0]:
				r.capsule(Vector2(side * 8, -16), Vector2(side * 8 + step * side * 4, 0), 8.0, c[0])
			r.shape(r.round_rect_points(Vector2(0, -32 + bob), Vector2(30, 32), 8.0), c[0])
			r.ellipse(Vector2(2, -54 + bob), Vector2(15, 15), c[0])
			r.shape(PackedVector2Array([Vector2(-6, -66 + bob), Vector2(2, -80 + bob), Vector2(8, -66 + bob)]), c[1])
			r.angry_eyes(Vector2(-2, -54 + bob), Vector2(9, -54 + bob), 3.6)
			r.capsule(Vector2(18, -30 + bob), Vector2(30, -50 + bob), 4.0, c[1])
		_:
			pass
	r.draw_wisps(Vector2(0, -50), 18.0)


## Flyers: centred around (0, -20).
static func draw_flyer(r: EnemyRig, skin: String, wing: float) -> void:
	var c := colors(r, skin)
	var o := Vector2(0, -20 + sin(r.t * 5.0) * 2.0)
	match skin:
		"jelly":
			for k in 4:
				var x := -12.0 + k * 8.0
				var pts := PackedVector2Array()
				for s in 6:
					pts.append(o + Vector2(x + sin(r.t * 4.0 + s + k) * 4.0, 6 + s * 6))
				r.draw_polyline(pts, c[1], 3.0)
			var dome := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				dome.append(o + Vector2(cos(a) * 22.0, sin(a) * 18.0 * (1.0 + wing * 0.08) + 6))
			r.shape(dome, c[0])
			r.angry_eyes(o + Vector2(-6, -2), o + Vector2(6, -2), 4.0)
		"vulture", "owl", "stormbird", "bat":
			var span := 26.0 if skin != "bat" else 30.0
			for side in [-1.0, 1.0]:
				var tip := o + Vector2(side * span, -8 + wing * 14.0)
				var wing_pts := PackedVector2Array([o + Vector2(side * 6, -6), tip, o + Vector2(side * 14, 6)])
				r.shape(wing_pts, c[1] if skin != "bat" else c[0])
			r.ellipse(o, Vector2(16, 14), c[0])
			if skin == "owl":
				r.ellipse(o + Vector2(0, 2), Vector2(10, 9), c[1])
			r.shape(PackedVector2Array([o + Vector2(12, -2), o + Vector2(22, 2), o + Vector2(12, 5)]), Color("ffb347"))
			r.angry_eyes(o + Vector2(0, -5), o + Vector2(9, -5), 4.0)
		"drone":
			r.shape(r.round_rect_points(o, Vector2(34, 18), 6.0), c[0])
			for side in [-1.0, 1.0]:
				r.capsule(o + Vector2(side * 16, -10), o + Vector2(side * 16, -14), 3.0, c[1])
				r.draw_line(o + Vector2(side * 16 - 12 * wing, -16), o + Vector2(side * 16 + 12 * wing, -16), c[1], 3.0)
			r.angry_eyes(o + Vector2(-6, 0), o + Vector2(6, 0), 4.0)
		"wraith":
			var cloak := PackedVector2Array([o + Vector2(-16, -10), o + Vector2(0, -24), o + Vector2(16, -10),
				o + Vector2(14, 18), o + Vector2(6, 12 + wing * 4), o + Vector2(-2, 20), o + Vector2(-10, 12 - wing * 4), o + Vector2(-16, 18)])
			r.shape(cloak, c[0])
			r.angry_eyes(o + Vector2(-5, -6), o + Vector2(6, -6), 4.0)
		_:
			pass
	r.draw_wisps(o + Vector2(0, -16), 14.0)


## Spiky ones: feet at the origin.
static func draw_spiky(r: EnemyRig, skin: String, step: float) -> void:
	var c := colors(r, skin)
	var center := Vector2(-2, -22)
	var spikes := 10
	var long := 16.0
	match skin:
		"cactus":
			r.shape(r.round_rect_points(center + Vector2(0, 2), Vector2(34, 40), 14.0), c[0])
			r.capsule(center + Vector2(-17, 0), center + Vector2(-24, -14), 9.0, c[0])
			r.capsule(center + Vector2(17, 4), center + Vector2(24, -8), 9.0, c[0])
			r.ellipse(center + Vector2(0, -22), Vector2(6, 5), c[1])
		"gear":
			var turn := r.t * 2.0
			for i in 10:
				var a := turn + i * TAU / 10.0
				r.shape(r.round_rect_points(center + Vector2(cos(a), sin(a)) * 20.0, Vector2(10, 10), 2.0, a), c[0])
			r.ellipse(center, Vector2(20, 20), c[0])
			r.ellipse(center, Vector2(7, 7), c[1])
		_:
			for i in spikes:
				var a := PI + 0.1 + i * (PI * 0.95 / (spikes - 1)) if skin != "urchin" else i * TAU / spikes + r.t
				var dir := Vector2(cos(a), sin(a))
				r.shape(PackedVector2Array([center + dir * 12 + dir.orthogonal() * 6, center + dir * (18 + long), center + dir * 12 - dir.orthogonal() * 6]), c[1])
			r.ellipse(center, Vector2(22, 18), c[0])
	for side in [-1.0, 1.0]:
		r.ellipse(Vector2(side * 12, -3 - maxf(0.0, step * side) * 4.0), Vector2(6, 4), c[1].darkened(0.3))
	r.angry_eyes(center + Vector2(4, -2), center + Vector2(13, -2), 3.8)
	if skin == "thunderpuff" and r.freed_amount < 0.5:
		r.draw_line(center + Vector2(-20, -24), center + Vector2(-12, -14), Color("fff3a0"), 3.0)
	r.draw_wisps(center + Vector2(0, -26), 20.0)
