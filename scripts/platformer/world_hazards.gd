class_name WorldHazards
extends RefCounted
## The special pieces of the later worlds, drawn in code:
##   SwimWater    deep water at the beach: Nima swims (jump = stroke), no drowning;
##   Quicksand    desert sand that swallows Nima to the chest and slows him down;
##   VanishPlatform  shadow stones in the castle that come and go in turn;
##   StormCloud   a thundercloud that flashes, then strikes a bolt straight down;
##   BossDoor     a barred gate that opens when the boss of the world is freed.

const TILE := 64.0
const OUTLINE := Color("3b2418")


class SwimWater extends Area2D:
	var size := Vector2(TILE, TILE)
	var surface := true
	var palette: Dictionary = {}
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 5
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		shape.position = size * 0.5
		add_child(shape)
		body_entered.connect(func(b): if b.has_method("enter_water"): b.enter_water())
		body_exited.connect(func(b): if b.has_method("exit_water"): b.exit_water())

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var water: Color = palette.get("water", Color("2fa7e0"))
		draw_rect(Rect2(Vector2.ZERO, size), Color(water, 0.42))
		if surface:
			var pts := PackedVector2Array()
			for i in int(size.x / 8.0) + 1:
				var x := i * 8.0
				pts.append(Vector2(x, 4.0 + sin(_t * 3.0 + x * 0.06) * 3.0))
			draw_polyline(pts, Color(1, 1, 1, 0.8), 3.0)
		# light rays and rising bubbles
		for i in int(size.x / 96.0) + 1:
			var x := fposmod(i * 96.0 + 30.0, size.x)
			var y := size.y - fposmod(_t * 40.0 + i * 37.0, size.y)
			draw_circle(Vector2(x + sin(_t * 2.0 + i) * 5.0, y), 4.0, Color(1, 1, 1, 0.45))


class Quicksand extends Area2D:
	var cells := 1
	var palette: Dictionary = {}
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 6
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(cells * TILE, TILE)
		shape.shape = rect
		shape.position = rect.size * 0.5
		add_child(shape)
		body_entered.connect(func(b): if b.has_method("enter_sand"): b.enter_sand())
		body_exited.connect(func(b): if b.has_method("exit_sand"): b.exit_sand())

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var sand: Color = palette.get("grass", Color("f2c46d"))
		var w := cells * TILE
		var top := PackedVector2Array([Vector2(0, TILE)])
		for i in int(w / 8.0) + 1:
			var x := i * 8.0
			top.append(Vector2(x, 14.0 + sin(_t * 1.5 + x * 0.05) * 3.0))
		top.append(Vector2(w, TILE))
		draw_colored_polygon(top, sand.darkened(0.08))
		for i in cells * 2:
			# slowly turning swirls show the sand is moving
			var c := Vector2(i * 32.0 + 16.0, 34.0)
			draw_arc(c, 9.0, _t * 1.4 + i, _t * 1.4 + i + 4.0, 12, sand.darkened(0.3), 2.0)


class VanishPlatform extends StaticBody2D:
	const CYCLE := 3.6
	var cells := 1
	var offset := 0.0
	var _shape: CollisionShape2D
	var _t := 0.0
	var _alpha := 1.0

	func _ready() -> void:
		collision_layer = 1
		z_index = 1
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(cells * TILE, 22)
		_shape.shape = rect
		_shape.position = Vector2(cells * TILE * 0.5, 11)
		_shape.one_way_collision = true
		add_child(_shape)

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := fposmod(_t + offset, CYCLE)
		# solid 2.2 s, fading 0.6 s (blinking), gone 0.8 s
		var solid := k < 2.8
		_alpha = 1.0 if k < 2.2 else (0.35 + 0.35 * float(int(k * 12.0) % 2) if k < 2.8 else 0.12)
		if _shape.disabled == solid:
			_shape.set_deferred("disabled", not solid)
		queue_redraw()

	func _draw() -> void:
		for i in cells:
			var r := Rect2(i * TILE + 2, 0, TILE - 4, 22)
			draw_rect(r.grow(2), Color(OUTLINE, _alpha))
			draw_rect(r, Color(0.42, 0.31, 0.62, _alpha))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color(0.62, 0.5, 0.85, _alpha))
			draw_circle(r.get_center() + Vector2(0, 3), 4.0, Color(0.85, 0.7, 1.0, _alpha))


class StormCloud extends Node2D:
	const PERIOD := 3.4
	var offset := 0.0
	var _t := 0.0
	var _bolt := 0.0
	var _ground := 600.0

	func _ready() -> void:
		z_index = 6
		_t = offset

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := fposmod(_t, PERIOD)
		var striking := k > PERIOD - 0.45
		if striking and _bolt <= 0.0:
			_strike()
		_bolt = maxf(0.0, _bolt - delta)
		queue_redraw()

	func _strike() -> void:
		_bolt = 0.4
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(32, 40)
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 1400), 1))
		_ground = (hit.position.y - global_position.y) if not hit.is_empty() else 1200.0
		AudioManager.play_sfx_once("thud", 0.3, 1.6, -4.0)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and absf(player.global_position.x - from.x) < 34.0 and player.global_position.y > global_position.y:
			player.take_hit(from.x)

	func _draw() -> void:
		var k := fposmod(_t, PERIOD)
		var warn := k > PERIOD - 1.2
		var dark := Color(0.32, 0.33, 0.42) if not warn else Color(0.42, 0.42, 0.55).lerp(Color(1, 1, 0.8), float(int(k * 10.0) % 2) * 0.3)
		for part in [[Vector2(10, 30), 26.0], [Vector2(38, 20), 30.0], [Vector2(62, 32), 22.0], [Vector2(32, 40), 24.0]]:
			draw_circle(part[0], part[1] + 2.5, OUTLINE)
		for part in [[Vector2(10, 30), 26.0], [Vector2(38, 20), 30.0], [Vector2(62, 32), 22.0], [Vector2(32, 40), 24.0]]:
			draw_circle(part[0], part[1], dark)
		draw_circle(Vector2(26, 34), 3.0, Color.WHITE)
		draw_circle(Vector2(40, 34), 3.0, Color.WHITE)
		if warn:
			draw_line(Vector2(32, 64), Vector2(32, minf(_ground, 400.0)), Color(1, 1, 0.6, 0.18), 18.0)
		if _bolt > 0.0:
			var pts := PackedVector2Array([Vector2(32, 60)])
			var y := 60.0
			var i := 0
			while y < _ground:
				y = minf(_ground, y + 40.0)
				pts.append(Vector2(32 + (14.0 if i % 2 == 0 else -14.0), y))
				i += 1
			draw_polyline(pts, Color(1, 1, 0.7, _bolt * 2.5), 10.0)
			draw_polyline(pts, Color.WHITE, 4.0)


class BossDoor extends StaticBody2D:
	var cells := 1
	var _open := 0.0
	var _shape: CollisionShape2D

	func _ready() -> void:
		collision_layer = 1
		z_index = 2
		add_to_group("boss_door")
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE, TILE * cells)
		_shape.shape = rect
		_shape.position = rect.size * 0.5
		add_child(_shape)

	func open() -> void:
		_shape.set_deferred("disabled", true)
		AudioManager.play_sfx("door")
		var tween := create_tween()
		tween.tween_method(func(v: float):
			_open = v
			queue_redraw(), 0.0, 1.0, 1.2)

	func _draw() -> void:
		var h := TILE * cells
		var lift := _open * h
		for x in [8.0, 28.0, 48.0]:
			var r := Rect2(x - 6, -lift, 12, h)
			draw_rect(r.grow(2), OUTLINE)
			draw_rect(r, Color("6b5a7a"))
			draw_line(r.position + Vector2(3, 4), r.position + Vector2(3, h - 4), Color("9a86ad"), 2.0)
		draw_rect(Rect2(0, h - 18 - lift, TILE, 14), Color("4a3a5a"))
