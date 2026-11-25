class_name Scenery
extends RefCounted
## The layered look of the reference videos (docs/45 section 1-2), as code placeholders until the painted layers
## arrive (CLAUDE.md rule 10):
##   far haze forest (pale, foggy) -> big mid trunks -> a hazy BACK TIER of terrain behind the path -> light shafts
##   -> the MAIN PATH (mossy rock masses in steps, dark hollows) -> a dark blurred FOREGROUND at the frame's edge.
## One colour atmosphere per level (here: green forest morning); depth = more haze, less contrast.

const PAL := {
	"sky_top": Color("6fbf9a"), "sky_low": Color("d6efc9"), "far": Color("a9dcbc"), "mid": Color("6aae8a"), "mid_dark": Color("4f8f70"),
	"back": Color("4d8f6c"), "back_top": Color("78b874"), "moss": Color("4e9a3e"), "moss_light": Color("9fd65e"),
	"rock_top": Color("6a8f5e"), "rock_low": Color("223a2c"), "slab": Color("7c9c6a"), "crack": Color("2c4433"), "hole": Color("15261c"),
	"fg": Color("0d2419"), "fg_leaf": Color("163a27"),
}


## The main path's look: a mossy rock mass (the collision is made by the level from the same polygon).
class MossTerrain extends Node2D:
	var top: PackedVector2Array
	var depth := 1600.0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(top[0].x * 7.0 + top[0].y)
		var poly := top.duplicate()
		poly.append(Vector2(top[top.size() - 1].x, depth))
		poly.append(Vector2(top[0].x, depth))
		var cols := PackedColorArray()
		for q in poly:
			var ground_y := _top_y(q.x)
			cols.append(PAL.rock_top.lerp(PAL.rock_low, clampf((q.y - ground_y) / 420.0, 0.0, 1.0)))
		draw_colored_polygon(poly, PAL.rock_low)
		draw_polygon(poly, cols)
		# big rounded stone slabs under the moss, lit from above
		var x := top[0].x + 40.0
		while x < top[top.size() - 1].x - 40.0:
			var gy := _top_y(x)
			var w := rng.randf_range(90.0, 180.0)
			var h := rng.randf_range(60.0, 110.0)
			var c := Vector2(x + w * 0.5, gy + 30.0 + h * 0.5 + rng.randf_range(0.0, 30.0))
			_slab(c, Vector2(w, h), rng)
			if rng.randf() < 0.6:
				_slab(c + Vector2(rng.randf_range(-40, 40), h + rng.randf_range(10, 40)), Vector2(w * 0.8, h * 0.9), rng, 0.55)
			x += w + rng.randf_range(10.0, 50.0)
		# dark hollows deeper down
		for i in int((top[top.size() - 1].x - top[0].x) / 420.0):
			var hx := top[0].x + 200.0 + i * 420.0 + rng.randf_range(-60, 60)
			var hy := _top_y(hx) + rng.randf_range(260.0, 380.0)
			draw_set_transform(Vector2(hx, hy), 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, rng.randf_range(80.0, 140.0), PAL.hole)
			draw_set_transform(Vector2.ZERO)
		# moss: a thick rounded lip, a light top, drips hanging over the stone, tufts
		draw_polyline(top, PAL.moss.darkened(0.35), 46.0)
		var lip := PackedVector2Array()
		for q in top:
			lip.append(q + Vector2(0, 4))
		draw_polyline(lip, PAL.moss, 34.0)
		var hi := PackedVector2Array()
		for q in top:
			hi.append(q + Vector2(0, -6))
		draw_polyline(hi, PAL.moss_light, 10.0)
		for i in range(0, top.size(), 3):
			var q: Vector2 = top[i]
			if rng.randf() < 0.45:
				var dl := rng.randf_range(20.0, 60.0)
				draw_line(q + Vector2(0, 14), q + Vector2(0, 14 + dl), PAL.moss.darkened(0.15), rng.randf_range(8.0, 16.0))
				draw_circle(q + Vector2(0, 14 + dl), 6.0, PAL.moss.darkened(0.15))
			if rng.randf() < 0.35:
				for k in 3:
					var a := -PI * 0.5 + (k - 1) * 0.4
					draw_line(q + Vector2(0, -8), q + Vector2(0, -8) + Vector2.from_angle(a) * rng.randf_range(16, 30), PAL.moss_light, 4.0)

	func _slab(c: Vector2, s: Vector2, rng: RandomNumberGenerator, k := 1.0) -> void:
		draw_set_transform(c, rng.randf_range(-0.12, 0.12), Vector2(1.0, s.y / s.x))
		draw_circle(Vector2.ZERO, s.x * 0.5 + 4.0, PAL.crack)
		draw_circle(Vector2.ZERO, s.x * 0.5, PAL.slab.lerp(PAL.rock_low, 1.0 - k))
		draw_circle(Vector2(-s.x * 0.12, -s.x * 0.16), s.x * 0.3, PAL.slab.lightened(0.12).lerp(PAL.rock_low, 1.0 - k))
		draw_set_transform(Vector2.ZERO)

	func _top_y(x: float) -> float:
		for i in top.size() - 1:
			if x >= top[i].x and x <= top[i + 1].x:
				var t := (x - top[i].x) / maxf(top[i + 1].x - top[i].x, 0.001)
				return lerpf(top[i].y, top[i + 1].y, t)
		return top[0].y if x < top[0].x else top[top.size() - 1].y


## A background layer of the forest (drawn over a strip `width` wide, repeated by its ParallaxLayer).
class ForestLayer extends Node2D:
	var kind := "far"          ## sky, far, mid, back, shafts
	var width := 3200.0
	var _t := 0.0

	func _process(delta: float) -> void:
		if kind == "shafts":
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = {"sky": 1, "far": 2, "mid": 3, "back": 4, "shafts": 5}[kind]
		match kind:
			"sky":
				for i in 16:
					draw_rect(Rect2(-100, -800 + i * 140, width + 200, 142), PAL.sky_top.lerp(PAL.sky_low, i / 15.0))
			"far":
				# pale far forest in the mist: tall thin trunks and soft round crowns
				for i in 40:
					var x := rng.randf() * width
					var h := rng.randf_range(500.0, 900.0)
					draw_line(Vector2(x, 900), Vector2(x + rng.randf_range(-30, 30), 900 - h), PAL.far.darkened(0.06), rng.randf_range(10, 22))
					draw_circle(Vector2(x, 900 - h), rng.randf_range(90, 160), PAL.far)
				draw_rect(Rect2(-100, 760, width + 200, 1400), PAL.far)
			"mid":
				# huge twisted trunks with roots and drooping crowns
				for i in 7:
					var x := 200.0 + i * width / 7.0 + rng.randf_range(-80, 80)
					var w := rng.randf_range(120, 220)
					var pts := PackedVector2Array([Vector2(x - w * 1.4, 1000), Vector2(x - w * 0.5, 820), Vector2(x - w * 0.45, 150),
						Vector2(x - w * 0.9, -120), Vector2(x + w * 0.9, -120), Vector2(x + w * 0.45, 150), Vector2(x + w * 0.5, 820), Vector2(x + w * 1.5, 1000)])
					draw_colored_polygon(pts, PAL.mid_dark)
					for k in 5:
						draw_circle(Vector2(x + rng.randf_range(-260, 260), -160 + rng.randf_range(-60, 80)), rng.randf_range(140, 230), PAL.mid)
					for k in 4:
						var vx := x + rng.randf_range(-200, 200)
						draw_line(Vector2(vx, -80), Vector2(vx + rng.randf_range(-20, 20), rng.randf_range(150, 420)), PAL.mid_dark, 5.0)
				draw_rect(Rect2(-100, 960, width + 200, 1400), PAL.mid_dark)
			"back":
				# a hazy tier of terrain behind the path: stepped rock masses with moss tops
				var x := -100.0
				var y := 760.0
				var pts2 := PackedVector2Array([Vector2(-100, 2000)])
				while x < width + 100.0:
					pts2.append(Vector2(x, y))
					x += rng.randf_range(160, 380)
					pts2.append(Vector2(x, y + rng.randf_range(-20, 20)))
					y = clampf(y + rng.randf_range(-120, 120), 600.0, 860.0)
					x += rng.randf_range(20, 50)
				pts2.append(Vector2(width + 100, 2000))
				draw_colored_polygon(pts2, PAL.back)
				var top_line := PackedVector2Array()
				for i in range(1, pts2.size() - 1):
					top_line.append(pts2[i])
				draw_polyline(top_line, PAL.back_top, 20.0)
			"shafts":
				for i in 6:
					var x0 := 300.0 + i * width / 6.0
					var a := 0.05 + 0.03 * sin(_t * 0.6 + i)
					draw_colored_polygon(PackedVector2Array([Vector2(x0, -400), Vector2(x0 + 120, -400), Vector2(x0 + 520, 1100), Vector2(x0 + 260, 1100)]),
						Color(1, 1, 0.85, a))


## The dark foreground at the bottom and corners of the frame (screen space, slides faster than the path).
class Foreground extends Node2D:
	var width := 2600.0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		for i in 14:
			var x := i * width / 14.0 + rng.randf_range(-40, 40)
			var big := rng.randf() < 0.35
			var h := rng.randf_range(90, 170) if not big else rng.randf_range(220, 320)
			_leaf_clump(Vector2(x, 760), h, rng)

	func _leaf_clump(base: Vector2, h: float, rng: RandomNumberGenerator) -> void:
		for k in 5:
			var a := -PI * 0.5 + rng.randf_range(-0.9, 0.9)
			var tip := base + Vector2.from_angle(a) * h * rng.randf_range(0.6, 1.0)
			var side := Vector2.from_angle(a).orthogonal() * h * 0.16
			var mid := base.lerp(tip, 0.5)
			draw_colored_polygon(PackedVector2Array([base, mid + side, tip, mid - side]), PAL.fg_leaf if k % 2 else PAL.fg)
		draw_circle(base + Vector2(0, 20), h * 0.35, PAL.fg)
