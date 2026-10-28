class_name LightParts
extends RefCounted
## The pieces of the light puzzle (see Mechanisms): mirrors the hero turns by touching,
## sensors that light up, and crystal shelves that are solid only while the beam shines on them.


class Mirror extends Area2D:
	## "/" or "\" — touching the mirror flips it to the other diagonal.
	var slash := true
	var mechanisms: Mechanisms
	var _angle := 0.0
	var _cooldown := 0.0
	var _hint := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 3
		add_to_group("time_visual")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(48, 96)
		shape.shape = rect
		shape.position = Vector2(32, 16)
		add_child(shape)
		_angle = _target()
		body_entered.connect(_on_body_entered)

	func _target() -> float:
		return -PI / 4.0 if slash else PI / 4.0

	## Direction after reflection (screen coordinates, y down).
	func reflect(dir: Vector2i) -> Vector2i:
		return Vector2i(-dir.y, -dir.x) if slash else Vector2i(dir.y, dir.x)

	func _on_body_entered(body: Node) -> void:
		if not body.is_in_group("player") or _cooldown > 0.0:
			return
		_cooldown = 0.6
		slash = not slash
		AudioManager.play_sfx("creak", 1.6, -6.0)
		create_tween().tween_property(self, "_angle", _target(), 0.25).set_trans(Tween.TRANS_BACK)
		mechanisms.refresh()

	func hint_flash(pos: Vector2, radius: float) -> void:
		if global_position.distance_to(pos) > radius:
			return
		var tween := create_tween()
		for i in 3:
			tween.tween_property(self, "_hint", 1.0, 0.25)
			tween.tween_property(self, "_hint", 0.0, 0.35)

	func _process(delta: float) -> void:
		_cooldown -= delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(26, 44, 12, 20), Color("6f6699"))
		draw_circle(Vector2(32, 44), 9.0, Color("8d84b8"))
		draw_set_transform(Vector2(32, 32), _angle, Vector2.ONE)
		draw_rect(Rect2(-6, -40, 12, 80), Color("5a4f80"))
		draw_rect(Rect2(-3, -36, 8, 72), Color("dff6ff"))
		draw_rect(Rect2(-1, -36, 3, 72), Color(1, 1, 1, 0.9))
		draw_set_transform(Vector2.ZERO)
		if _hint > 0.01:
			draw_arc(Vector2(32, 32), 46.0, 0.0, TAU, 32, Color(1, 0.95, 0.4, _hint), 5.0)


class LightSensor extends Node2D:
	## Crystal eye; lit while the beam reaches it.
	var lit := false
	var _glow := 0.0
	var _hint := 0.0

	func _ready() -> void:
		z_index = 2
		add_to_group("time_visual")

	func set_lit(value: bool) -> void:
		if value == lit:
			return
		lit = value
		if lit:
			AudioManager.play_sfx("star", 1.3, -4.0)
		create_tween().tween_property(self, "_glow", 1.0 if lit else 0.0, 0.3)

	func hint_flash(pos: Vector2, radius: float) -> void:
		if (global_position + Vector2(32, 32)).distance_to(pos) > radius:
			return
		var tween := create_tween()
		for i in 3:
			tween.tween_property(self, "_hint", 1.0, 0.25)
			tween.tween_property(self, "_hint", 0.0, 0.35)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(32, 32)
		draw_circle(center, 28.0, Color("40345c"))
		draw_circle(center, 22.0, Color("6f6699").lerp(Color("fff3a8"), _glow))
		draw_circle(center, 10.0, Color("2d2340").lerp(Color.WHITE, _glow))
		if _glow > 0.01:
			draw_circle(center, 40.0, Color(1, 0.95, 0.6, 0.25 * _glow))
		if _hint > 0.01:
			draw_arc(center, 40.0, 0.0, TAU, 32, Color(1, 0.95, 0.4, _hint), 5.0)


class CrystalPlatform extends StaticBody2D:
	## One-way crystal shelf: solid only while lit (one-way, so it can never trap the hero).
	var palette: Dictionary = {}
	var lit := false
	var _glow := 0.0
	var _shape: CollisionShape2D

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		z_index = 1
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(64, 20)
		_shape.shape = rect
		_shape.position = Vector2(32, 10)
		_shape.one_way_collision = true
		_shape.disabled = true
		add_child(_shape)

	func set_lit(value: bool) -> void:
		if value == lit:
			return
		lit = value
		_shape.set_deferred("disabled", not lit)
		create_tween().tween_property(self, "_glow", 1.0 if lit else 0.0, 0.25)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var base: Color = palette.get("vine", Color("5fd0e8"))
		var a := 0.3 + 0.7 * _glow
		var pts := PackedVector2Array([Vector2(2, 4), Vector2(16, 0), Vector2(32, 6), Vector2(48, 0), Vector2(62, 4),
			Vector2(54, 20), Vector2(32, 26), Vector2(10, 20)])
		draw_colored_polygon(pts, Color(base, a))
		draw_line(Vector2(16, 0), Vector2(22, 18), Color(1, 1, 1, 0.5 * a), 2.0)
		draw_line(Vector2(48, 0), Vector2(42, 18), Color(1, 1, 1, 0.5 * a), 2.0)
		if _glow > 0.01:
			draw_circle(Vector2(32, 10), 30.0, Color(base.lightened(0.4), 0.18 * _glow))
		else:
			draw_dashed_line(Vector2(0, 2), Vector2(64, 2), Color(1, 1, 1, 0.4), 2.0, 8.0)
