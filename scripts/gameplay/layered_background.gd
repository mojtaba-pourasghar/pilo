class_name LayeredBackground
extends CanvasLayer
## Seven depth layers, all drawn in code and all moving (the forest world):
##   1 sky gradient with a slowly turning sun      (fixed)
##   2 clouds drifting on the wind                 (scroll 0.05)
##   3 blue mountains with a far waterfall          (scroll 0.12)
##   4 hills with giant mushrooms, birds flying     (scroll 0.25)
##   5 tree line, canopies swaying                  (scroll 0.45)
##   6 bushes, flowers and tall grass               (scroll 0.7)
##   — the level itself —
##   7 foreground leaves, hanging vines, falling leaves and light rays in front of the
##     player (scroll 1.3, own canvas layer above the world).
## Layers also move a little vertically so tall levels feel deep.

const TILE_W := 2048.0

var level_size := Vector2(4096, 1408)
var _layers: Array = []
var _front: CanvasLayer
var _view := Vector2(1280, 720)
var _tween: Tween


func _ready() -> void:
	layer = -10
	_add(SkyLayer.new(), 0.0, 0.0)
	_add(CloudLayer.new(), 0.05, 0.02)
	_add(MountainLayer.new(), 0.12, 0.05)
	_add(HillLayer.new(), 0.25, 0.1)
	_add(TreeLayer.new(), 0.45, 0.2)
	_add(BushLayer.new(), 0.7, 0.35)
	_front = CanvasLayer.new()
	_front.layer = 5
	add_child(_front)
	var front := FrontLayer.new()
	front.scroll = Vector2(1.3, 1.0)
	_front.add_child(front)
	_layers.append(front)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _add(node: BgLayer, scroll_x: float, scroll_y: float) -> void:
	node.scroll = Vector2(scroll_x, scroll_y)
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
	var animated := false

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

	static func blob(canvas: CanvasItem, c: Vector2, r: float, color: Color) -> void:
		canvas.draw_circle(c, r, color)


class SkyLayer extends BgLayer:
	func _init() -> void:
		animated = true

	func _process(delta: float) -> void:
		t += delta
		position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		var top := Color("3d8ee6")
		var bottom := Color("c6ecff")
		var bands := 24
		for i in bands:
			var k := float(i) / bands
			draw_rect(Rect2(0, view.y * k, view.x, view.y / bands + 1.0), top.lerp(bottom, k))
		var sun := Vector2(view.x * 0.78, view.y * 0.18)
		for i in 12:
			var a := t * 0.05 + i * TAU / 12.0
			var dir := Vector2(cos(a), sin(a))
			draw_colored_polygon(PackedVector2Array([sun + dir.orthogonal() * 18.0, sun + dir * 420.0 + dir.orthogonal() * 60.0,
				sun + dir * 420.0 - dir.orthogonal() * 60.0, sun - dir.orthogonal() * 18.0]), Color(1, 1, 0.85, 0.07))
		draw_circle(sun, 120.0, Color(1, 0.98, 0.8, 0.12))
		draw_circle(sun, 72.0, Color(1, 0.96, 0.7, 0.25))
		draw_circle(sun, 46.0, Color("fff6c2"))


class CloudLayer extends BgLayer:
	var clouds: Array = []

	func _init() -> void:
		animated = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 7:
			clouds.append({"x": i * TILE_W / 7.0 + rng.randf_range(-80, 80), "y": rng.randf_range(0.08, 0.34), "s": rng.randf_range(0.7, 1.3)})

	func draw_strip(x0: float) -> void:
		for c in clouds:
			var x := fposmod(float(c.x) + t * 12.0, TILE_W) + x0
			var y: float = float(c.y) * view.y
			var s: float = c.s
			for part in [[Vector2(0, 0), 46.0], [Vector2(-50, 14), 34.0], [Vector2(52, 12), 38.0], [Vector2(-22, -24), 32.0], [Vector2(26, -28), 36.0], [Vector2(90, 22), 26.0], [Vector2(-88, 24), 24.0]]:
				draw_circle(Vector2(x, y + 10.0 * s) + part[0] * s, part[1] * s, Color(0.75, 0.86, 0.97))
			for part in [[Vector2(0, 0), 46.0], [Vector2(-50, 14), 34.0], [Vector2(52, 12), 38.0], [Vector2(-22, -24), 32.0], [Vector2(26, -28), 36.0], [Vector2(90, 22), 26.0], [Vector2(-88, 24), 24.0]]:
				draw_circle(Vector2(x, y) + part[0] * s, part[1] * s, Color.WHITE)


class MountainLayer extends BgLayer:
	func _init() -> void:
		animated = true

	func draw_strip(x0: float) -> void:
		var base := horizon() + 20.0
		var far := PackedVector2Array()
		var near := PackedVector2Array()
		for i in 65:
			var x := i * TILE_W / 64.0
			far.append(Vector2(x0 + x, base - 150.0 - 90.0 * sin(x * TAU / TILE_W * 3.0) - 50.0 * sin(x * TAU / TILE_W * 7.0 + 1.0)))
			near.append(Vector2(x0 + x, base - 70.0 - 70.0 * sin(x * TAU / TILE_W * 4.0 + 2.0) - 30.0 * sin(x * TAU / TILE_W * 11.0)))
		far.append(Vector2(x0 + TILE_W, view.y + 400.0))
		far.append(Vector2(x0, view.y + 400.0))
		near.append(Vector2(x0 + TILE_W, view.y + 400.0))
		near.append(Vector2(x0, view.y + 400.0))
		draw_colored_polygon(far, Color("9cc4e6"))
		# snow caps on the far range
		for i in 3:
			var px := x0 + (i * 3.0 + 0.75) * TILE_W / 9.0 + 40.0
			var peak := base - 150.0 - 90.0 - 30.0
			draw_colored_polygon(PackedVector2Array([Vector2(px - 60, peak + 60), Vector2(px, peak + 6), Vector2(px + 60, peak + 60), Vector2(px + 20, peak + 48), Vector2(px - 15, peak + 64)]), Color(1, 1, 1, 0.75))
		draw_colored_polygon(near, Color("7fb6c9"))
		# a far waterfall, its stripes falling
		var wx := x0 + TILE_W * 0.32
		var wy := base - 120.0
		draw_rect(Rect2(wx, wy, 26, 150), Color(0.85, 0.95, 1.0, 0.85))
		for k in 6:
			var y := fposmod(t * 90.0 + k * 25.0, 150.0)
			draw_line(Vector2(wx + 4 + (k % 3) * 8, wy + y), Vector2(wx + 4 + (k % 3) * 8, wy + minf(150.0, y + 14.0)), Color(0.6, 0.8, 0.95, 0.9), 3.0)
		draw_circle(Vector2(wx + 13, wy + 150), 24.0 + sin(t * 4.0) * 3.0, Color(1, 1, 1, 0.5))


class HillLayer extends BgLayer:
	func _init() -> void:
		animated = true

	func draw_strip(x0: float) -> void:
		var base := horizon() + 60.0
		var hill := PackedVector2Array()
		for i in 65:
			var x := i * TILE_W / 64.0
			hill.append(Vector2(x0 + x, base - 40.0 - 50.0 * sin(x * TAU / TILE_W * 5.0) - 20.0 * sin(x * TAU / TILE_W * 13.0 + 0.5)))
		hill.append(Vector2(x0 + TILE_W, view.y + 400.0))
		hill.append(Vector2(x0, view.y + 400.0))
		draw_colored_polygon(hill, Color("8fd06a"))
		# giant mushrooms (the forest's landmark, like in the art direction)
		for m in [[0.12, 1.0, Color("e8473a")], [0.38, 0.7, Color("f3a33a")], [0.61, 1.15, Color("e8473a")], [0.86, 0.8, Color("b56ad8")]]:
			var mx: float = x0 + float(m[0]) * TILE_W
			var s: float = m[1]
			var ground := base - 40.0 - 50.0 * sin(float(m[0]) * TAU * 5.0) - 20.0 * sin(float(m[0]) * TAU * 13.0 + 0.5)
			var sway := sin(t * 0.8 + mx) * 3.0 * s
			draw_colored_polygon(PackedVector2Array([Vector2(mx - 12 * s, ground), Vector2(mx - 8 * s + sway, ground - 150 * s),
				Vector2(mx + 8 * s + sway, ground - 150 * s), Vector2(mx + 12 * s, ground)]), Color("f4e3cc"))
			var cap := Vector2(mx + sway, ground - 150 * s)
			var dome := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				dome.append(cap + Vector2(cos(a) * 90.0 * s, sin(a) * 60.0 * s))
			draw_colored_polygon(dome, m[2])
			draw_rect(Rect2(cap + Vector2(-88 * s, -4 * s), Vector2(176 * s, 10 * s)), Color(m[2]).darkened(0.25))
			for spot in [Vector2(-40, -26), Vector2(10, -44), Vector2(48, -22), Vector2(-8, -16)]:
				draw_circle(cap + spot * s, 11.0 * s, Color(1, 0.96, 0.85, 0.9))
		# birds gliding
		for b in 4:
			var bx := x0 + fposmod(b * 520.0 + t * (40.0 + b * 6.0), TILE_W)
			var by := view.y * (0.22 + b * 0.05) + sin(t * 1.5 + b) * 10.0
			var flap := sin(t * 9.0 + b * 2.0) * 6.0
			draw_polyline(PackedVector2Array([Vector2(bx - 12, by - flap), Vector2(bx, by), Vector2(bx + 12, by - flap)]), Color("35506e"), 2.5)


class TreeLayer extends BgLayer:
	var trees: Array = []

	func _init() -> void:
		animated = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var x := 0.0
		while x < TILE_W:
			trees.append({"x": x, "h": rng.randf_range(170, 280), "r": rng.randf_range(70, 110), "k": rng.randi_range(0, 2)})
			x += rng.randf_range(150, 260)

	func draw_strip(x0: float) -> void:
		var ground := horizon() + 120.0
		draw_rect(Rect2(x0, ground, TILE_W, view.y + 400.0), Color("4f9a45"))
		for tree in trees:
			var tx: float = x0 + float(tree.x)
			var h: float = tree.h
			var r: float = tree.r
			var sway := sin(t * 1.1 + tx * 0.01) * 6.0
			draw_colored_polygon(PackedVector2Array([Vector2(tx - 14, ground), Vector2(tx - 9 + sway * 0.3, ground - h), Vector2(tx + 9 + sway * 0.3, ground - h), Vector2(tx + 14, ground)]), Color("6b4a2e"))
			var top := Vector2(tx + sway, ground - h)
			var green: Color = [Color("3f8f3e"), Color("4aa046"), Color("357d36")][int(tree.k)]
			for part in [[Vector2(0, 0), 1.0], [Vector2(-0.6, 0.35), 0.75], [Vector2(0.6, 0.3), 0.8], [Vector2(0, -0.5), 0.7]]:
				draw_circle(top + part[0] * r, r * float(part[1]) * 0.75, green)
			draw_circle(top + Vector2(-0.25, -0.45) * r, r * 0.3, Color(green).lightened(0.15))


class BushLayer extends BgLayer:
	func _init() -> void:
		animated = true

	func draw_strip(x0: float) -> void:
		var ground := horizon() + 190.0
		draw_rect(Rect2(x0, ground, TILE_W, view.y + 400.0), Color("3f8a3a"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var x := 0.0
		while x < TILE_W:
			var bx := x0 + x
			var r := rng.randf_range(40, 70)
			var green := Color("2f7a31").lerp(Color("4c9e3f"), rng.randf())
			for part in [Vector2(0, 0), Vector2(-0.7, 0.3), Vector2(0.7, 0.25)]:
				draw_circle(Vector2(bx, ground) + part * r, r * 0.7, green)
			if rng.randf() < 0.5:
				for berry in 4:
					draw_circle(Vector2(bx, ground) + Vector2(rng.randf_range(-r, r) * 0.6, rng.randf_range(-r, 0) * 0.5), 5.0, Color("ff5d73"))
			# tall grass blades bending in the wind
			for g in 6:
				var gx := bx + rng.randf_range(-r, r)
				var lean := sin(t * 2.0 + gx * 0.05) * 8.0
				draw_line(Vector2(gx, ground + 6), Vector2(gx + lean, ground - rng.randf_range(24, 46)), Color("5fb04a"), 3.0)
			x += rng.randf_range(90, 170)


class FrontLayer extends BgLayer:
	var leaves: Array = []

	func _init() -> void:
		animated = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in 14:
			leaves.append({"x": rng.randf_range(0, 1), "y": rng.randf_range(0, 1), "s": rng.randf_range(0.6, 1.2), "p": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		var shift := fposmod(camera_x * scroll.x, TILE_W)
		position = Vector2(-shift, 0)
		queue_redraw()

	func _draw() -> void:
		var shift := -position.x
		# light rays slanting through the canopy (screen space)
		for i in 4:
			var x := fposmod(i * 470.0 - shift * 0.2, view.x + 600.0) - 300.0
			var alpha := 0.05 + 0.03 * sin(t * 0.7 + i)
			draw_colored_polygon(PackedVector2Array([Vector2(x + shift, -20), Vector2(x + 90 + shift, -20),
				Vector2(x - 120 + shift, view.y), Vector2(x - 260 + shift, view.y)]), Color(1, 0.97, 0.75, alpha))
		for copy in 2:
			draw_strip(copy * TILE_W)
		# falling leaves drifting across the screen
		for leaf in leaves:
			var lx := fposmod(float(leaf.x) * view.x + t * 30.0 + sin(t + float(leaf.p)) * 40.0, view.x) + shift
			var ly := fposmod(float(leaf.y) * view.y + t * 45.0 * float(leaf.s), view.y)
			var a := t * 2.0 + float(leaf.p)
			var s: float = leaf.s
			var dir := Vector2(cos(a), sin(a))
			draw_colored_polygon(PackedVector2Array([Vector2(lx, ly) - dir * 9.0 * s, Vector2(lx, ly) + dir.orthogonal() * 4.0 * s,
				Vector2(lx, ly) + dir * 9.0 * s, Vector2(lx, ly) - dir.orthogonal() * 4.0 * s]), Color(0.95, 0.65, 0.2, 0.9))

	func draw_strip(x0: float) -> void:
		# big dark leaves rising from the bottom edge and vines hanging from the top
		for i in 9:
			var x := x0 + i * TILE_W / 9.0 + 60.0
			if i % 2 == 0:
				var sway := sin(t * 1.4 + i) * 0.08
				for k in 3:
					var a := -PI * 0.5 + (k - 1) * 0.5 + sway
					var tip := Vector2(x, view.y + 20.0) + Vector2(cos(a), sin(a)) * (70.0 + k * 12.0)
					var mid := Vector2(x, view.y + 20.0).lerp(tip, 0.5)
					var side := Vector2(cos(a), sin(a)).orthogonal() * 18.0
					draw_colored_polygon(PackedVector2Array([Vector2(x, view.y + 20.0), mid + side, tip, mid - side]), Color(0.16, 0.38, 0.17, 0.7))
			else:
				var len := 70.0 + (i % 3) * 35.0
				var swing := sin(t * 1.2 + i) * 10.0
				draw_line(Vector2(x, -10), Vector2(x + swing, len), Color(0.15, 0.35, 0.16, 0.9), 6.0)
				for k in 4:
					var p := Vector2(x, -10).lerp(Vector2(x + swing, len), (k + 1) / 5.0)
					draw_circle(p + Vector2(8, 0), 9.0, Color(0.18, 0.42, 0.18, 0.92))
