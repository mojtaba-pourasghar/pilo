class_name LayeredBackground
extends CanvasLayer
## Seven depth layers drawn in code and all moving, themed for each world (THEMES):
##   1 sky gradient with the sun or moon (and stars at night)   (fixed)
##   2 clouds, smoke or mist drifting                             (scroll 0.05)
##   3 far mountains / sea / mesas / peaks / towers               (scroll 0.12)
##   4 hills with the world's landmarks, birds or bats            (scroll 0.25)
##   5 tree line: trees, palms, cacti, pines, crystals, chimneys  (scroll 0.45)
##   6 bushes, coral, shrubs, snow mounds, crates, thorns         (scroll 0.7)
##   — the level itself —
##   7 foreground plants, light rays and falling particles (leaves, bubbles, sand, snow,
##     sparks, embers) in front of the player (own canvas layer above the world).
## Layers also move a little vertically so tall levels feel deep.

const TILE_W := 2048.0

const THEMES := {
	"forest": {"sky": ["3d8ee6", "c6ecff"], "sun": true, "far": "9cc4e6", "near": "7fb6c9", "caps": true, "fall": true,
		"hill": "8fd06a", "mark": "mushroom", "marks": ["e8473a", "f3a33a", "e8473a", "b56ad8"], "fly": "bird",
		"tree": "round", "trees": ["6b4a2e", "3f8f3e", "4aa046", "357d36"], "band": "4f9a45",
		"bush": ["2f7a31", "4c9e3f", "ff5d73"], "grass": "5fb04a", "front": "2a612c", "bits": "leaf", "cloud": "ffffff"},
	"coral_beach": {"sky": ["2f9be8", "c4f2ff"], "sun": true, "far": "4fb6e0", "near": "8ad8ea", "caps": false, "fall": false, "sea": true,
		"hill": "f4e0a8", "mark": "lighthouse", "marks": ["ffffff", "e8473a"], "fly": "bird",
		"tree": "palm", "trees": ["b98552", "3fae5a", "4cc06a", "2f9a4a"], "band": "e8c98a",
		"bush": ["ff7f9f", "ff9f5f", "fff3c9"], "grass": "3fc1b0", "front": "2f8a5a", "bits": "bubble", "cloud": "ffffff"},
	"golden_desert": {"sky": ["ff9f4a", "ffe7b0"], "sun": true, "far": "d9935a", "near": "e8b36a", "caps": false, "fall": false,
		"hill": "f2c46d", "mark": "pyramid", "marks": ["e0a850", "c98b40"], "fly": "bird",
		"tree": "cactus", "trees": ["4a8a3a", "5aa04a", "6cb85a", "4a9a3a"], "band": "e8b36a",
		"bush": ["a8743f", "c9944f", "ff6f61"], "grass": "c9a35a", "front": "8a5a2a", "bits": "sand", "cloud": "fff3d9"},
	"snow_mountain": {"sky": ["6fa8e0", "eaf6ff"], "sun": true, "far": "dfeaf7", "near": "b9c8dc", "caps": true, "fall": false,
		"hill": "f4f8ff", "mark": "igloo", "marks": ["ffffff", "cfe6ff"], "fly": "bird",
		"tree": "pine", "trees": ["5a3a2a", "2f6a4a", "3a7a5a", "285a40"], "band": "e8f0fa",
		"bush": ["ffffff", "dfeaf7", "9fd8ff"], "grass": "cfe6ff", "front": "2f5a4a", "bits": "snow", "cloud": "ffffff"},
	"sky_islands": {"sky": ["6fb8ff", "ffe9f6"], "sun": true, "far": "b9d8ff", "near": "d9ecff", "caps": false, "fall": true, "islands": true,
		"hill": "ffffff", "mark": "windmill", "marks": ["fff3d9", "e8473a"], "fly": "bird", "rainbow": true,
		"tree": "puff", "trees": ["ffffff", "ffffff", "f2f8ff", "e6f0ff"], "band": "ffffff",
		"bush": ["ffffff", "eaf4ff", "ffd166"], "grass": "c2f08a", "front": "6aa0d0", "bits": "feather", "cloud": "ffffff"},
	"crystal_caves": {"sky": ["160d2a", "3a2a5a"], "sun": false, "far": "2a1f40", "near": "3a2a5a", "caps": false, "fall": false, "cave": true,
		"hill": "4a3a70", "mark": "crystal", "marks": ["7ef0ff", "c7b8ff", "ff9af0"], "fly": "bat",
		"tree": "stalagmite", "trees": ["4a3a70", "6a5aa0", "5fd0e8", "8f7fd6"], "band": "2a1f40",
		"bush": ["5fd0e8", "8f7fd6", "ff9af0"], "grass": "7ef0ff", "front": "1e1530", "bits": "glow", "cloud": "6a5aa0"},
	"clock_factory": {"sky": ["5a3a2a", "d9a066"], "sun": false, "far": "6b4a33", "near": "8a6448", "caps": false, "fall": false,
		"hill": "7a5a44", "mark": "gear", "marks": ["c9a24a", "b5793d"], "fly": "bird",
		"tree": "chimney", "trees": ["6b4a33", "8a6448", "a87850", "5a3a2a"], "band": "5a3f2e",
		"bush": ["b5793d", "8a5a2c", "ffcf4a"], "grass": "d9a441", "front": "3a2a1e", "bits": "spark", "cloud": "c9b8a8"},
	"shadow_castle": {"sky": ["0e0820", "3a2a5a"], "sun": false, "moon": true, "far": "1e1530", "near": "2a1f40", "caps": false, "fall": false,
		"hill": "2a1f40", "mark": "spire", "marks": ["3a2a5a", "a06bff"], "fly": "bat",
		"tree": "dead", "trees": ["3a2a4a", "4a3a6a", "5a4a80", "3a2a5a"], "band": "1e1530",
		"bush": ["4a3a6a", "6a4fa0", "d07fff"], "grass": "6a4fa0", "front": "120a20", "bits": "ember", "cloud": "5a4a80"},
	"inverted_land": {"sky": ["7f9fff", "ffb0e0"], "sun": true, "far": "b48cff", "near": "d0a0ff", "caps": false, "fall": true, "islands": true,
		"hill": "e07fd0", "mark": "clock", "marks": ["fff07f", "6a4a9a"], "fly": "bird", "rainbow": true,
		"tree": "puff", "trees": ["ffffff", "ffd0f0", "e0c0ff", "d0b0ff"], "band": "6a4a9a",
		"bush": ["e07fd0", "7fe0d0", "fff07f"], "grass": "7fe0d0", "front": "4a2a6a", "bits": "glow", "cloud": "ffe0f8"},
}

var level_size := Vector2(4096, 1408)
var world_id := "forest"
var _layers: Array = []
var _front: CanvasLayer
var _view := Vector2(1280, 720)
var _tween: Tween


func _ready() -> void:
	layer = -10
	var theme: Dictionary = THEMES.get(world_id, THEMES.forest)
	_add(SkyLayer.new(), 0.0, 0.0, theme)
	_add(CloudLayer.new(), 0.05, 0.02, theme)
	_add(MountainLayer.new(), 0.12, 0.05, theme)
	_add(HillLayer.new(), 0.25, 0.1, theme)
	_add(TreeLayer.new(), 0.45, 0.2, theme)
	_add(BushLayer.new(), 0.7, 0.35, theme)
	_front = CanvasLayer.new()
	_front.layer = 5
	add_child(_front)
	var front := FrontLayer.new()
	front.theme = theme
	front.scroll = Vector2(1.3, 1.0)
	_front.add_child(front)
	_layers.append(front)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _add(node: BgLayer, scroll_x: float, scroll_y: float, theme: Dictionary) -> void:
	node.scroll = Vector2(scroll_x, scroll_y)
	node.theme = theme
	add_child(node)
	_layers.append(node)


func _fit() -> void:
	_view = get_viewport().get_visible_rect().size
	for node in _layers:
		node.view = _view
		node.queue_redraw()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	# 0 when the camera looks at the bottom of the level, positive when it looks higher up
	var height := (level_size.y - _view.y * 0.5) - center.y
	for node in _layers:
		node.camera_x = center.x
		node.lift = height * node.scroll.y


func set_tint(color: Color, instant: bool) -> void:
	if _tween:
		_tween.kill()
	if instant:
		modulate_all(color)
		return
	_tween = create_tween()
	_tween.tween_method(modulate_all, _layers[0].modulate, color, 0.4)


func modulate_all(color: Color) -> void:
	for node in _layers:
		node.modulate = Color(color, node.modulate.a)


## Base: draws a TILE_W wide strip twice so it wraps seamlessly while scrolling.
class BgLayer extends Node2D:
	var scroll := Vector2.ZERO
	var view := Vector2(1280, 720)
	var camera_x := 0.0
	var lift := 0.0
	var t := 0.0
	var animated := true
	var theme: Dictionary = {}

	func _process(delta: float) -> void:
		t += delta
		var shift := fposmod(camera_x * scroll.x, TILE_W)
		position = Vector2(-shift, lift)
		if animated:
			queue_redraw()

	func _draw() -> void:
		for copy in 2:
			draw_strip(copy * TILE_W)

	func draw_strip(_x0: float) -> void:
		pass

	func horizon() -> float:
		return view.y * 0.62

	func c(key: String, i := -1) -> Color:
		var value = theme.get(key, "ff00ff")
		if value is Array:
			return Color(String(value[maxi(i, 0) % value.size()]))
		return Color(String(value))

	func flag(key: String) -> bool:
		return bool(theme.get(key, false))

	func wave(x0: float, base: float, a: float, f1: float, b: float, f2: float, phase := 0.0) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 65:
			var x := i * TILE_W / 64.0
			pts.append(Vector2(x0 + x, base - a - a * sin(x * TAU / TILE_W * f1 + phase) - b * sin(x * TAU / TILE_W * f2 + phase * 2.0)))
		pts.append(Vector2(x0 + TILE_W, view.y + 500.0))
		pts.append(Vector2(x0, view.y + 500.0))
		return pts


class SkyLayer extends BgLayer:
	func _process(delta: float) -> void:
		t += delta
		position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		var top := c("sky", 0)
		var bottom := c("sky", 1)
		var bands := 24
		for i in bands:
			var k := float(i) / bands
			draw_rect(Rect2(0, view.y * k, view.x, view.y / bands + 1.0), top.lerp(bottom, k))
		if not flag("sun"):
			# night or cave: stars or glowing motes, and maybe a moon
			for i in 60:
				var p := Vector2(fposmod(i * 211.0, view.x), fposmod(i * 97.0, view.y * 0.7))
				draw_circle(p, 1.5 + float(i % 3) * 0.6, Color(1, 1, 1, 0.25 + 0.25 * sin(t * 2.0 + i)))
			if flag("moon"):
				var moon := Vector2(view.x * 0.78, view.y * 0.2)
				draw_circle(moon, 110.0, Color(0.8, 0.7, 1.0, 0.12))
				draw_circle(moon, 56.0, Color("f0e8ff"))
				draw_circle(moon + Vector2(16, -8), 48.0, top.lerp(bottom, 0.15))
			return
		var sun := Vector2(view.x * 0.78, view.y * 0.18)
		for i in 12:
			var a := t * 0.05 + i * TAU / 12.0
			var dir := Vector2(cos(a), sin(a))
			draw_colored_polygon(PackedVector2Array([sun + dir.orthogonal() * 18.0, sun + dir * 420.0 + dir.orthogonal() * 60.0,
				sun + dir * 420.0 - dir.orthogonal() * 60.0, sun - dir.orthogonal() * 18.0]), Color(1, 1, 0.85, 0.07))
		draw_circle(sun, 120.0, Color(1, 0.98, 0.8, 0.12))
		draw_circle(sun, 72.0, Color(1, 0.96, 0.7, 0.25))
		draw_circle(sun, 46.0, Color("fff6c2"))
		if flag("rainbow"):
			var center := Vector2(view.x * 0.35, view.y * 0.75)
			var colors := ["ff6b6b", "ffb347", "ffe46b", "8be06a", "6cc8ff", "b48cff"]
			for i in colors.size():
				draw_arc(center, 420.0 - i * 14.0, PI, TAU, 64, Color(colors[i], 0.35), 14.0)


class CloudLayer extends BgLayer:
	var clouds: Array = []

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 7:
			clouds.append({"x": i * TILE_W / 7.0 + rng.randf_range(-80, 80), "y": rng.randf_range(0.08, 0.34), "s": rng.randf_range(0.7, 1.3)})

	func draw_strip(x0: float) -> void:
		var white := c("cloud")
		var alpha := 1.0 if flag("sun") else 0.35
		for cl in clouds:
			var x := fposmod(float(cl.x) + t * 12.0, TILE_W) + x0
			var y: float = float(cl.y) * view.y
			var s: float = cl.s
			var parts := [[Vector2(0, 0), 46.0], [Vector2(-50, 14), 34.0], [Vector2(52, 12), 38.0], [Vector2(-22, -24), 32.0], [Vector2(26, -28), 36.0], [Vector2(90, 22), 26.0], [Vector2(-88, 24), 24.0]]
			for part in parts:
				draw_circle(Vector2(x, y + 10.0 * s) + part[0] * s, part[1] * s, Color(white.darkened(0.15), alpha))
			for part in parts:
				draw_circle(Vector2(x, y) + part[0] * s, part[1] * s, Color(white, alpha))


class MountainLayer extends BgLayer:
	func draw_strip(x0: float) -> void:
		var base := horizon() + 20.0
		if flag("sea"):
			# open sea with far islands and a sparkling horizon
			draw_rect(Rect2(x0, base - 60.0, TILE_W, view.y + 500.0), c("far"))
			for i in 4:
				var ix := x0 + (i + 0.3) * TILE_W / 4.0
				draw_colored_polygon(PackedVector2Array([Vector2(ix - 120, base - 60), Vector2(ix - 40, base - 120), Vector2(ix + 60, base - 110), Vector2(ix + 140, base - 60)]), c("near").darkened(0.15))
			for i in 30:
				var sx := x0 + fposmod(i * 131.0 + t * 8.0, TILE_W)
				draw_line(Vector2(sx, base - 40 + (i % 5) * 14), Vector2(sx + 24, base - 40 + (i % 5) * 14), Color(1, 1, 1, 0.35), 2.0)
			return
		if flag("islands"):
			# floating islands hanging in the sky, waterfalls pouring off them
			for i in 5:
				var ix := x0 + (i + 0.2) * TILE_W / 5.0
				var iy := base - 170.0 - (i % 3) * 60.0 + sin(t * 0.6 + i) * 6.0
				draw_colored_polygon(PackedVector2Array([Vector2(ix - 110, iy), Vector2(ix + 110, iy), Vector2(ix + 50, iy + 70), Vector2(ix - 10, iy + 110), Vector2(ix - 60, iy + 60)]), c("far").darkened(0.25))
				draw_rect(Rect2(ix - 110, iy - 14, 220, 18), c("hill").darkened(0.05))
				draw_line(Vector2(ix + 30, iy + 40), Vector2(ix + 30, iy + 200), Color(1, 1, 1, 0.5), 8.0)
			return
		var far := wave(x0, base - 150.0, 90.0, 3.0, 50.0, 7.0, 1.0)
		var near := wave(x0, base - 70.0, 60.0, 4.0, 30.0, 11.0, 2.0)
		if flag("cave"):
			far = wave(x0, base - 60.0, 120.0, 5.0, 60.0, 13.0, 1.0)
		draw_colored_polygon(far, c("far"))
		if flag("caps"):
			for i in 3:
				var px := x0 + (i * 3.0 + 0.75) * TILE_W / 9.0 + 40.0
				var peak := base - 150.0 - 90.0 - 30.0
				draw_colored_polygon(PackedVector2Array([Vector2(px - 60, peak + 60), Vector2(px, peak + 6), Vector2(px + 60, peak + 60), Vector2(px + 20, peak + 48), Vector2(px - 15, peak + 64)]), Color(1, 1, 1, 0.75))
		draw_colored_polygon(near, c("near"))
		if flag("fall"):
			var wx := x0 + TILE_W * 0.32
			var wy := base - 120.0
			draw_rect(Rect2(wx, wy, 26, 150), Color(0.85, 0.95, 1.0, 0.85))
			for k in 6:
				var y := fposmod(t * 90.0 + k * 25.0, 150.0)
				draw_line(Vector2(wx + 4 + (k % 3) * 8, wy + y), Vector2(wx + 4 + (k % 3) * 8, wy + minf(150.0, y + 14.0)), Color(0.6, 0.8, 0.95, 0.9), 3.0)
			draw_circle(Vector2(wx + 13, wy + 150), 24.0 + sin(t * 4.0) * 3.0, Color(1, 1, 1, 0.5))


class HillLayer extends BgLayer:
	func draw_strip(x0: float) -> void:
		var base := horizon() + 60.0
		draw_colored_polygon(wave(x0, base - 40.0, 50.0, 5.0, 20.0, 13.0, 0.5), c("hill"))
		var marks: Array = theme.get("marks", [])
		for i in 4:
			var u := (i + 0.12) / 4.0
			var mx := x0 + u * TILE_W
			var ground := base - 40.0 - 50.0 - 50.0 * sin(u * TAU * 5.0 + 0.5) - 20.0 * sin(u * TAU * 13.0 + 1.0)
			_landmark(String(theme.get("mark", "")), Vector2(mx, ground + 30.0), 0.8 + (i % 2) * 0.35, Color(String(marks[i % marks.size()])), i)
		var fly := String(theme.get("fly", "bird"))
		for b in 4:
			var bx := x0 + fposmod(b * 520.0 + t * (40.0 + b * 6.0), TILE_W)
			var by := view.y * (0.22 + b * 0.05) + sin(t * 1.5 + b) * 10.0
			var flap := sin(t * (9.0 if fly == "bird" else 16.0) + b * 2.0) * 6.0
			var dark := Color("35506e") if fly == "bird" else Color("1a1028")
			draw_polyline(PackedVector2Array([Vector2(bx - 12, by - flap), Vector2(bx, by), Vector2(bx + 12, by - flap)]), dark, 2.5)

	func _landmark(kind: String, at: Vector2, s: float, color: Color, i: int) -> void:
		var sway := sin(t * 0.8 + at.x) * 3.0 * s
		match kind:
			"mushroom":
				draw_colored_polygon(PackedVector2Array([at + Vector2(-12, 0) * s, at + Vector2(-8 * s + sway, -150 * s), at + Vector2(8 * s + sway, -150 * s), at + Vector2(12, 0) * s]), Color("f4e3cc"))
				var cap := at + Vector2(sway, -150 * s)
				var dome := PackedVector2Array()
				for k in 17:
					var a := PI + PI * k / 16.0
					dome.append(cap + Vector2(cos(a) * 90.0 * s, sin(a) * 60.0 * s))
				draw_colored_polygon(dome, color)
				for spot in [Vector2(-40, -26), Vector2(10, -44), Vector2(48, -22)]:
					draw_circle(cap + spot * s, 11.0 * s, Color(1, 0.96, 0.85, 0.9))
			"lighthouse":
				draw_colored_polygon(PackedVector2Array([at + Vector2(-26, 0) * s, at + Vector2(-16, -200) * s, at + Vector2(16, -200) * s, at + Vector2(26, 0) * s]), Color.WHITE)
				for k in 3:
					draw_rect(Rect2(at + Vector2(-22 + k * 2, -50 - k * 60) * s, Vector2(44 - k * 4, 18) * s), Color("e8473a"))
				draw_circle(at + Vector2(0, -214) * s, 16.0 * s, Color(1, 0.95, 0.6, 0.7 + 0.3 * sin(t * 3.0)))
			"pyramid":
				draw_colored_polygon(PackedVector2Array([at + Vector2(-150, 0) * s, at + Vector2(0, -160) * s, at + Vector2(150, 0) * s]), color)
				draw_colored_polygon(PackedVector2Array([at + Vector2(0, -160) * s, at + Vector2(150, 0) * s, at + Vector2(40, 0) * s]), color.darkened(0.15))
			"igloo":
				var dome := PackedVector2Array()
				for k in 17:
					var a := PI + PI * k / 16.0
					dome.append(at + Vector2(cos(a) * 70.0, sin(a) * 55.0) * s)
				draw_colored_polygon(dome, Color.WHITE)
				draw_circle(at + Vector2(30, -14) * s, 16.0 * s, Color("8aa3c0"))
			"windmill":
				draw_colored_polygon(PackedVector2Array([at + Vector2(-24, 0) * s, at + Vector2(-14, -120) * s, at + Vector2(14, -120) * s, at + Vector2(24, 0) * s]), color)
				for k in 4:
					var a := t * 1.2 + i + k * PI * 0.5
					draw_line(at + Vector2(0, -120) * s, at + Vector2(0, -120) * s + Vector2(cos(a), sin(a)) * 70.0 * s, Color("e8473a"), 8.0 * s)
			"crystal":
				for k in 3:
					var h := (120.0 + k * 50.0) * s
					var x := at.x + (k - 1) * 40.0 * s
					draw_colored_polygon(PackedVector2Array([Vector2(x - 22 * s, at.y), Vector2(x, at.y - h), Vector2(x + 22 * s, at.y)]), Color(color, 0.85))
					draw_circle(Vector2(x, at.y - h * 0.5), 40.0 * s, Color(color, 0.12 + 0.06 * sin(t * 2.0 + k)))
			"gear":
				var center := at + Vector2(0, -90) * s
				var r := 80.0 * s
				for k in 10:
					var a := t * 0.4 * (1.0 if i % 2 == 0 else -1.0) + k * TAU / 10.0
					draw_rect(Rect2(center + Vector2(cos(a), sin(a)) * r - Vector2(14, 14) * s, Vector2(28, 28) * s), color)
				draw_circle(center, r, color)
				draw_circle(center, r * 0.35, color.darkened(0.3))
			"spire":
				draw_rect(Rect2(at + Vector2(-30, -220) * s, Vector2(60, 220) * s), color)
				draw_colored_polygon(PackedVector2Array([at + Vector2(-40, -220) * s, at + Vector2(0, -300) * s, at + Vector2(40, -220) * s]), color.darkened(0.2))
				draw_rect(Rect2(at + Vector2(-8, -180) * s, Vector2(16, 26) * s), Color(1, 0.8, 0.4, 0.7 + 0.3 * sin(t * 2.0 + i)))
			"clock":
				var center := at + Vector2(0, -120) * s
				draw_circle(center, 60.0 * s, color)
				draw_circle(center, 50.0 * s, Color("fff8e1"))
				draw_line(center, center + Vector2(sin(-t), -cos(-t)) * 40.0 * s, Color("3b2418"), 4.0)
			_:
				pass


class TreeLayer extends BgLayer:
	var trees: Array = []

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var x := 0.0
		while x < TILE_W:
			trees.append({"x": x, "h": rng.randf_range(170, 280), "r": rng.randf_range(70, 110), "k": rng.randi_range(1, 3)})
			x += rng.randf_range(150, 260)

	func draw_strip(x0: float) -> void:
		var ground := horizon() + 120.0
		draw_rect(Rect2(x0, ground, TILE_W, view.y + 400.0), c("band"))
		var kind := String(theme.get("tree", "round"))
		for tree in trees:
			var tx: float = x0 + float(tree.x)
			var h: float = tree.h
			var r: float = tree.r
			var sway := sin(t * 1.1 + tx * 0.01) * 6.0
			var green := c("trees", int(tree.k))
			var trunk := c("trees", 0)
			match kind:
				"palm":
					var top := Vector2(tx + sway * 2.0, ground - h)
					draw_polyline(PackedVector2Array([Vector2(tx, ground), Vector2(tx + 10, ground - h * 0.5), top]), trunk, 14.0)
					for k in 6:
						var a := -PI * 0.5 + (k - 2.5) * 0.55 + sway * 0.02
						draw_line(top, top + Vector2(cos(a), sin(a) * 0.6 + 0.4) * r, green, 12.0)
				"cactus":
					var w := 26.0
					draw_rect(Rect2(tx - w * 0.5, ground - h * 0.7, w, h * 0.7), green)
					draw_circle(Vector2(tx, ground - h * 0.7), w * 0.5, green)
					draw_rect(Rect2(tx - w * 1.6, ground - h * 0.5, w * 0.7, h * 0.25), green)
					draw_rect(Rect2(tx + w * 0.9, ground - h * 0.42, w * 0.7, h * 0.2), green)
				"pine":
					draw_rect(Rect2(tx - 8, ground - 40, 16, 40), trunk)
					for k in 3:
						var y := ground - 30 - k * h * 0.28
						var half := r * (0.9 - k * 0.22)
						draw_colored_polygon(PackedVector2Array([Vector2(tx - half + sway * 0.3, y), Vector2(tx + sway * (0.4 + k * 0.2), y - h * 0.4), Vector2(tx + half + sway * 0.3, y)]), green)
						draw_colored_polygon(PackedVector2Array([Vector2(tx - half * 0.5, y - h * 0.12), Vector2(tx + sway * 0.5, y - h * 0.4), Vector2(tx + half * 0.4, y - h * 0.16)]), Color(1, 1, 1, 0.8))
				"puff":
					var top := Vector2(tx + sway, ground - h * 0.5)
					for part in [[Vector2(0, 0), 1.0], [Vector2(-0.7, 0.3), 0.75], [Vector2(0.7, 0.25), 0.8]]:
						draw_circle(top + part[0] * r, r * float(part[1]) * 0.7, green)
				"stalagmite":
					draw_colored_polygon(PackedVector2Array([Vector2(tx - r * 0.4, ground), Vector2(tx, ground - h), Vector2(tx + r * 0.4, ground)]), green)
					draw_colored_polygon(PackedVector2Array([Vector2(tx - r * 0.3, -40), Vector2(tx + 30, h * 0.6), Vector2(tx + r * 0.3, -40)]), trunk)
				"chimney":
					draw_rect(Rect2(tx - 24, ground - h, 48, h), green)
					draw_rect(Rect2(tx - 30, ground - h, 60, 16), trunk)
					for k in 4:
						var p := fposmod(t * 0.3 + k * 0.25, 1.0)
						draw_circle(Vector2(tx + p * 40.0, ground - h - p * 160.0), 18.0 + p * 30.0, Color(0.85, 0.8, 0.75, 0.4 * (1.0 - p)))
				"dead":
					draw_line(Vector2(tx, ground), Vector2(tx + sway * 0.3, ground - h), trunk, 12.0)
					for k in 4:
						var y := ground - h * (0.4 + k * 0.15)
						var side := 1.0 if k % 2 == 0 else -1.0
						draw_line(Vector2(tx, y), Vector2(tx + side * r * 0.6, y - 40), trunk, 6.0)
				_:
					draw_colored_polygon(PackedVector2Array([Vector2(tx - 14, ground), Vector2(tx - 9 + sway * 0.3, ground - h), Vector2(tx + 9 + sway * 0.3, ground - h), Vector2(tx + 14, ground)]), trunk)
					var top := Vector2(tx + sway, ground - h)
					for part in [[Vector2(0, 0), 1.0], [Vector2(-0.6, 0.35), 0.75], [Vector2(0.6, 0.3), 0.8], [Vector2(0, -0.5), 0.7]]:
						draw_circle(top + part[0] * r, r * float(part[1]) * 0.75, green)
					draw_circle(top + Vector2(-0.25, -0.45) * r, r * 0.3, green.lightened(0.15))


class BushLayer extends BgLayer:
	func draw_strip(x0: float) -> void:
		var ground := horizon() + 190.0
		draw_rect(Rect2(x0, ground, TILE_W, view.y + 400.0), c("band").darkened(0.1))
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var x := 0.0
		while x < TILE_W:
			var bx := x0 + x
			var r := rng.randf_range(40, 70)
			var tone := c("bush", 0).lerp(c("bush", 1), rng.randf())
			for part in [Vector2(0, 0), Vector2(-0.7, 0.3), Vector2(0.7, 0.25)]:
				draw_circle(Vector2(bx, ground) + part * r, r * 0.7, tone)
			if rng.randf() < 0.5:
				for berry in 4:
					draw_circle(Vector2(bx, ground) + Vector2(rng.randf_range(-r, r) * 0.6, rng.randf_range(-r, 0) * 0.5), 5.0, c("bush", 2))
			for g in 6:
				var gx := bx + rng.randf_range(-r, r)
				var lean := sin(t * 2.0 + gx * 0.05) * 8.0
				draw_line(Vector2(gx, ground + 6), Vector2(gx + lean, ground - rng.randf_range(24, 46)), c("grass"), 3.0)
			x += rng.randf_range(90, 170)


class FrontLayer extends BgLayer:
	var bits: Array = []

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in 16:
			bits.append({"x": rng.randf_range(0, 1), "y": rng.randf_range(0, 1), "s": rng.randf_range(0.6, 1.2), "p": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		var shift := fposmod(camera_x * scroll.x, TILE_W)
		position = Vector2(-shift, 0)
		queue_redraw()

	func _draw() -> void:
		var shift := -position.x
		if flag("sun"):
			for i in 4:
				var x := fposmod(i * 470.0 - shift * 0.2, view.x + 600.0) - 300.0
				var alpha := 0.05 + 0.03 * sin(t * 0.7 + i)
				draw_colored_polygon(PackedVector2Array([Vector2(x + shift, -20), Vector2(x + 90 + shift, -20),
					Vector2(x - 120 + shift, view.y), Vector2(x - 260 + shift, view.y)]), Color(1, 0.97, 0.75, alpha))
		for copy in 2:
			draw_strip(copy * TILE_W)
		var kind := String(theme.get("bits", "leaf"))
		for bit in bits:
			var s: float = bit.s
			var speed := 45.0 if kind != "bubble" and kind != "ember" and kind != "glow" else -30.0
			var lx := fposmod(float(bit.x) * view.x + t * 30.0 + sin(t + float(bit.p)) * 40.0, view.x) + shift
			var ly := fposmod(float(bit.y) * view.y + t * speed * s, view.y)
			var p := Vector2(lx, ly)
			match kind:
				"bubble":
					draw_arc(p, 6.0 * s, 0.0, TAU, 12, Color(1, 1, 1, 0.6), 2.0)
				"sand":
					draw_circle(p, 2.5 * s, Color(1.0, 0.85, 0.55, 0.7))
				"snow":
					draw_circle(p, 4.0 * s, Color(1, 1, 1, 0.9))
				"spark":
					draw_line(p, p + Vector2(4, 6) * s, Color(1.0, 0.8, 0.3, 0.9), 2.0)
				"ember", "glow":
					draw_circle(p, 3.5 * s, Color(c("bush", 2), 0.6 + 0.3 * sin(t * 3.0 + float(bit.p))))
				"feather":
					draw_line(p, p + Vector2(cos(t + float(bit.p)), sin(t + float(bit.p))) * 10.0 * s, Color(1, 1, 1, 0.85), 3.0)
				_:
					var a := t * 2.0 + float(bit.p)
					var dir := Vector2(cos(a), sin(a))
					draw_colored_polygon(PackedVector2Array([p - dir * 9.0 * s, p + dir.orthogonal() * 4.0 * s, p + dir * 9.0 * s, p - dir.orthogonal() * 4.0 * s]), Color(0.95, 0.65, 0.2, 0.9))

	func draw_strip(x0: float) -> void:
		var front := c("front")
		for i in 9:
			var x := x0 + i * TILE_W / 9.0 + 60.0
			if i % 2 == 0:
				var sway := sin(t * 1.4 + i) * 0.08
				for k in 3:
					var a := -PI * 0.5 + (k - 1) * 0.5 + sway
					var tip := Vector2(x, view.y + 20.0) + Vector2(cos(a), sin(a)) * (70.0 + k * 12.0)
					var mid := Vector2(x, view.y + 20.0).lerp(tip, 0.5)
					var side := Vector2(cos(a), sin(a)).orthogonal() * 18.0
					draw_colored_polygon(PackedVector2Array([Vector2(x, view.y + 20.0), mid + side, tip, mid - side]), Color(front, 0.7))
			elif not flag("cave"):
				var len := 70.0 + (i % 3) * 35.0
				var swing := sin(t * 1.2 + i) * 10.0
				draw_line(Vector2(x, -10), Vector2(x + swing, len), Color(front, 0.9), 6.0)
				for k in 4:
					var p := Vector2(x, -10).lerp(Vector2(x + swing, len), (k + 1) / 5.0)
					draw_circle(p + Vector2(8, 0), 9.0, Color(front.lightened(0.1), 0.92))
			else:
				# hanging stalactites in caves
				draw_colored_polygon(PackedVector2Array([Vector2(x - 26, -10), Vector2(x, 90.0 + (i % 3) * 30.0), Vector2(x + 26, -10)]), Color(front, 0.95))
