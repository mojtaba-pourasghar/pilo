class_name WorldParts
extends RefCounted
## Switches, gates, wind and crumbling platforms. Each draws itself in the look of its world
## (palette.theme: forest / sky_islands / crystal_caves).


class Lever extends Area2D:
	## Touch to switch on (it stays on). Forest: a wooden lever; sky: a windmill that starts to
	## turn; caves: a crystal that lights up.
	var mechanisms: Mechanisms
	var palette: Dictionary = {}
	var on := false
	var _turn := 0.0
	var _spin := 0.0
	var _hint := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 2
		add_to_group("time_visual")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(56, 96)
		shape.shape = rect
		shape.position = Vector2(32, 16)
		add_child(shape)
		body_entered.connect(_on_body_entered)

	func _on_body_entered(body: Node) -> void:
		if on or not body.is_in_group("player"):
			return
		on = true
		AudioManager.play_sfx("key", 0.8)
		AudioManager.play_sfx("creak", 1.2, -8.0)
		create_tween().tween_property(self, "_turn", 1.0, 0.4).set_trans(Tween.TRANS_BACK)
		mechanisms.refresh()

	func hint_flash(pos: Vector2, radius: float) -> void:
		if global_position.distance_to(pos) > radius:
			return
		var tween := create_tween()
		for i in 3:
			tween.tween_property(self, "_hint", 1.0, 0.25)
			tween.tween_property(self, "_hint", 0.0, 0.35)

	func _process(delta: float) -> void:
		if on:
			_spin += delta * 5.0
		queue_redraw()

	func _draw() -> void:
		var theme: String = palette.get("theme", "forest")
		var wood: Color = palette.get("wood", Color("c08048"))
		match theme:
			"sky_islands":
				draw_rect(Rect2(26, 0, 12, 64), Color("e8e2d6"))
				draw_colored_polygon(PackedVector2Array([Vector2(20, 64), Vector2(44, 64), Vector2(38, 0), Vector2(26, 0)]), Color("f4efe4"))
				draw_circle(Vector2(32, 0), 7.0, Color("b06a3a"))
				for i in 4:
					var a := _spin + i * TAU / 4.0
					var tip := Vector2(32, 0) + Vector2(cos(a), sin(a)) * 40.0
					var side := Vector2(cos(a + 0.3), sin(a + 0.3)) * 34.0
					draw_colored_polygon(PackedVector2Array([Vector2(32, 0), tip, Vector2(32, 0) + side]),
						Color("ff8f6b") if on else Color("c8c2d0"))
			"crystal_caves":
				draw_rect(Rect2(20, 48, 24, 16), Color("6f6699"))
				var glow := Color("7ef0ff") if on else Color("8d84b8")
				draw_colored_polygon(PackedVector2Array([Vector2(32, -6), Vector2(46, 22), Vector2(32, 50), Vector2(18, 22)]), glow)
				if on:
					draw_circle(Vector2(32, 22), 34.0, Color(0.5, 0.95, 1.0, 0.22))
			_:
				draw_rect(Rect2(14, 50, 36, 14), wood.darkened(0.3))
				draw_set_transform(Vector2(32, 54), lerpf(-0.6, 0.6, _turn), Vector2.ONE)
				draw_rect(Rect2(-4, -44, 8, 44), wood)
				draw_circle(Vector2(0, -46), 9.0, Color("e5533d") if not on else Color("4cb84a"))
				draw_set_transform(Vector2.ZERO)
		if _hint > 0.01:
			draw_arc(Vector2(32, 24), 48.0, 0.0, TAU, 32, Color(1, 0.95, 0.4, _hint), 5.0)


class Gate extends StaticBody2D:
	## A column of bars; opens once (Mechanisms) and stays open.
	var cells := 1
	var palette: Dictionary = {}
	var size := Vector2(64, 64)
	var _open := 0.0
	var _shape: CollisionShape2D

	func _ready() -> void:
		size = Vector2(64, 64 * cells)
		collision_layer = 1
		collision_mask = 0
		z_index = 1
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		_shape.shape = rect
		_shape.position = size * 0.5
		add_child(_shape)

	func open() -> void:
		_shape.set_deferred("disabled", true)
		var tween := create_tween()
		tween.tween_property(self, "_open", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.8)

	func _draw() -> void:
		var theme: String = palette.get("theme", "forest")
		var bar: Color = palette.get("wood", Color("c08048"))
		if theme == "sky_islands":
			bar = Color("ffd166")
		elif theme == "crystal_caves":
			bar = Color("7ef0ff")
		var lift := size.y * _open
		var alpha := 1.0 - _open * 0.85
		draw_rect(Rect2(0, 0, 64, 10), Color(bar.darkened(0.4), 1.0))
		for i in 4:
			var x := 8.0 + i * 16.0
			draw_rect(Rect2(x, 8 - lift, 8, size.y - 8), Color(bar, alpha))
			draw_rect(Rect2(x, 8 - lift, 3, size.y - 8), Color(1, 1, 1, 0.3 * alpha))
		draw_rect(Rect2(0, size.y * 0.45 - lift, 64, 8), Color(bar.darkened(0.25), alpha))


class WindZone extends Area2D:
	## A run of wind tiles. Sideways wind carries the hero further while in the air (never
	## while standing, so it cannot push anyone off a ledge); an updraft lifts the hero up its
	## column. A level may limit the wind to one time ("wind_time").
	var dir := Vector2.RIGHT
	var size := Vector2(64, 64)
	var active_mask := 3
	var _presence := 1.0
	var _t := 0.0
	var _hint := 0.0
	var _tween: Tween

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 3
		add_to_group("time_visual")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size - Vector2(12, 12) if dir.y == 0.0 else Vector2(size.x - 24, size.y)
		shape.shape = rect
		shape.position = size * 0.5
		add_child(shape)
		TimeShift.time_changed.connect(_on_time_changed)
		_on_time_changed(TimeShift.state, true)
		_t = randf() * 10.0

	func is_active() -> bool:
		return (active_mask & (1 << TimeShift.state)) != 0

	func _on_time_changed(_state: int, instant: bool) -> void:
		var target := 1.0 if is_active() else 0.0
		if _tween:
			_tween.kill()
		if instant:
			_presence = target
		else:
			_tween = create_tween()
			_tween.tween_property(self, "_presence", target, 0.4)
			if is_active():
				AudioManager.play_sfx_once("rustle", 0.4, 0.7, -4.0)

	func hint_flash(pos: Vector2, radius: float) -> void:
		if (global_position + size * 0.5).distance_to(pos) > radius:
			return
		var tween := create_tween()
		for i in 3:
			tween.tween_property(self, "_hint", 1.0, 0.25)
			tween.tween_property(self, "_hint", 0.0, 0.35)

	func _physics_process(_delta: float) -> void:
		if not is_active():
			return
		for body in get_overlapping_bodies():
			if body.has_method("apply_wind"):
				body.apply_wind(dir)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var vertical := dir.y != 0.0
		var along := size.y if vertical else size.x
		var across := size.x if vertical else size.y
		if _presence > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.9, 1.0, 0.16 * _presence))
		# streaks
		var count := int(across / 18.0)
		for i in count:
			var lane := (i + 0.5) * across / count
			var speed := 200.0 + float(i * 37 % 70)
			var offset := fposmod(_t * speed + i * 53.0, along + 60.0) - 60.0
			var a := _point(offset, lane)
			var b := _point(offset + 40.0, lane)
			if _presence > 0.01:
				draw_line(a, b, Color(1, 1, 1, 0.65 * _presence), 3.0)
			else:
				draw_dashed_line(a, b, Color(1, 1, 1, 0.2), 2.0, 6.0)
		# big moving chevrons so a child sees which way it blows
		if _presence > 0.01:
			var step := 96.0
			for k in int(along / step) + 1:
				var d := fposmod(_t * 120.0 + k * step, along)
				var center := _point(d, across * 0.5)
				var fwd := dir * 14.0
				var side := Vector2(-dir.y, dir.x) * 16.0
				draw_polyline(PackedVector2Array([center - fwd + side, center + fwd, center - fwd - side]),
					Color(0.85, 0.97, 1.0, 0.85 * _presence), 6.0)
		if _hint > 0.01:
			draw_rect(Rect2(Vector2.ZERO, size).grow(4.0), Color(1, 0.95, 0.4, _hint), false, 5.0)

	## Point at distance `d` along the wind (from where it comes) and `lane` across it.
	func _point(d: float, lane: float) -> Vector2:
		if dir == Vector2.RIGHT:
			return Vector2(d, lane)
		if dir == Vector2.LEFT:
			return Vector2(size.x - d, lane)
		return Vector2(lane, size.y - d)


class CrumblePlatform extends StaticBody2D:
	## Stone shelf (one-way). In the past it is whole and stable; in the present it is cracked:
	## standing on it makes it shake, fall after a moment and come back a little later.
	var cells := 1
	var palette: Dictionary = {}
	var size := Vector2(64, 20)
	var _shape: CollisionShape2D
	var _sensor: Area2D
	var _state := "solid"      # solid | shaking | fallen
	var _timer := 0.0
	var _drop := 0.0
	var _t := 0.0

	func _ready() -> void:
		size = Vector2(64 * cells, 20)
		collision_layer = 1
		collision_mask = 0
		z_index = 1
		add_to_group("time_visual")
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		_shape.shape = rect
		_shape.position = size * 0.5
		_shape.one_way_collision = true
		add_child(_shape)
		_sensor = Area2D.new()
		_sensor.collision_layer = 0
		_sensor.collision_mask = 2
		var sensor_shape := CollisionShape2D.new()
		var sensor_rect := RectangleShape2D.new()
		sensor_rect.size = Vector2(size.x - 8, 12)
		sensor_shape.shape = sensor_rect
		sensor_shape.position = Vector2(size.x * 0.5, -6)
		_sensor.add_child(sensor_shape)
		add_child(_sensor)
		TimeShift.time_changed.connect(_on_time_changed)

	func _on_time_changed(state: int, _instant: bool) -> void:
		if state == TimeShift.PAST:
			_restore()

	func hint_flash(_pos: Vector2, _radius: float) -> void:
		pass

	func _restore() -> void:
		_state = "solid"
		_drop = 0.0
		_shape.set_deferred("disabled", false)

	func _physics_process(delta: float) -> void:
		_t += delta
		match _state:
			"solid":
				if TimeShift.state == TimeShift.PRESENT:
					for body in _sensor.get_overlapping_bodies():
						if body.is_in_group("player") and body.is_on_floor():
							_state = "shaking"
							_timer = 0.7
							AudioManager.play_sfx_once("rumble", 0.3, 1.5, -8.0)
			"shaking":
				_timer -= delta
				if _timer <= 0.0:
					_state = "fallen"
					_timer = 2.6
					_shape.set_deferred("disabled", true)
					AudioManager.play_sfx_once("rumble", 0.3, 1.1, -4.0)
			"fallen":
				_drop = minf(_drop + delta * 3.0, 1.0)
				_timer -= delta
				if _timer <= 0.0:
					_restore()
		queue_redraw()

	func _draw() -> void:
		var stone: Color = palette.get("rock", Color("9ea3ad"))
		var dark: Color = palette.get("rock_dark", Color("6f7580"))
		var past := TimeShift.state == TimeShift.PAST
		var shake := Vector2(sin(_t * 60.0) * 3.0, 0) if _state == "shaking" else Vector2.ZERO
		var alpha := 1.0 - _drop
		var offset := Vector2(0, _drop * 60.0) + shake
		for i in cells:
			var x := i * 64.0
			draw_rect(Rect2(Vector2(x + 2, 0) + offset, Vector2(60, 18)), Color(stone, alpha))
			draw_rect(Rect2(Vector2(x + 2, 14) + offset, Vector2(60, 6)), Color(dark, alpha))
			if not past:
				draw_line(Vector2(x + 18, 2) + offset, Vector2(x + 28, 16) + offset, Color(dark, alpha), 2.0)
				draw_line(Vector2(x + 28, 16) + offset, Vector2(x + 44, 4) + offset, Color(dark, alpha), 2.0)
		if _state == "fallen":
			draw_dashed_line(Vector2(0, 2), Vector2(size.x, 2), Color(1, 1, 1, 0.4), 2.0, 8.0)
