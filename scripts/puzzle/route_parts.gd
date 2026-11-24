class_name RouteParts
extends RefCounted
## Route mechanics of the reference-video gameplay (docs/38 §4). Built from the level's `objects`
## (x, y in tiles; y = the ground the thing stands on, or the top anchor for hanging things):
##   rope_swing   a plank on two ropes; jump into it to grab, it swings like a pendulum, jump to let go
##   vine         a hanging vine; hold up/down to climb, push sideways to let go
##   ramp         end of a downhill: running over it launches the hero (speed becomes a long jump)
##   crumble      a bridge whose planks fall 0.4 s after a foot touches them
##   falling_rock a rock that waits above, shows a shadow marker 0.8 s, then drops
##   steam_vent   a vent that blows a column of steam every 2 s: it lifts the hero (or hurts if marked)
## Pictures: the cut art under assets/art/v3/cut/ when it exists, simple painted shapes otherwise.

const TILE := 64.0


static func build_all(objects: Array, root: Node2D, game: Node) -> Array:
	var made: Array = []
	for obj in objects:
		var part := _make(String(obj.get("type", "")))
		if part == null:
			continue
		part.game = game
		part.position = Vector2(float(obj.x) * TILE + TILE * 0.5, float(obj.y) * TILE)
		part.setup(obj)
		root.add_child(part)
		made.append(part)
	return made


static func _make(kind: String) -> Part:
	match kind:
		"rope_swing":
			return RopeSwing.new()
		"vine":
			return Vine.new()
		"ramp":
			return Ramp.new()
		"crumble":
			return Crumble.new()
		"falling_rock":
			return FallingRock.new()
		"steam_vent":
			return SteamVent.new()
	return null


class Part extends Node2D:
	var game: Node
	var data: Dictionary = {}

	func setup(obj: Dictionary) -> void:
		data = obj
		add_to_group("route_part")
		z_index = 2
		_build()

	func _build() -> void:
		pass

	func player() -> CharacterBody2D:
		return game.player if game and game.get("player") else null


## A plank on two ropes. The hero grabs it when he is in the air within reach and presses jump (or just touches
## it falling); while attached he follows the plank; jump releases with the plank's speed.
class RopeSwing extends Part:
	var length := 260.0
	var angle := 0.5          ## radians from straight down
	var _vel := 0.0
	var _attached := false
	var _cool := 0.0
	var _anchor := Vector2.ZERO

	func _build() -> void:
		length = float(data.get("length", 4)) * TILE
		angle = deg_to_rad(float(data.get("start", 28)))
		_anchor = Vector2.ZERO

	func handle() -> Vector2:
		return _anchor + Vector2(sin(angle), cos(angle)) * length

	func _physics_process(delta: float) -> void:
		_cool = maxf(0.0, _cool - delta)
		# pendulum: a = -g/L sin(angle), light damping, a small drive keeps an empty swing going
		var g := 2400.0
		var acc := -g / length * sin(angle) - 0.35 * _vel
		if not _attached:
			acc += 0.9 * sin(Time.get_ticks_msec() * 0.0012 + position.x) * 0.0
		_vel += acc * delta
		angle += _vel * delta
		if absf(angle) < 0.02 and absf(_vel) < 0.05 and not _attached:
			_vel = 0.9 * signf(angle if angle != 0.0 else 1.0)     # never stops completely
		var p := player()
		if p == null:
			queue_redraw()
			return
		var hp := to_global(handle())
		if _attached:
			p.global_position = hp + Vector2(0, 52)
			# the hero's weight pumps the swing: pushing sideways adds energy
			var push := Input.get_axis("move_left", "move_right")
			_vel += push * 1.4 * delta
			if Input.is_action_just_pressed("jump") or not p.controls_enabled:
				_release(p)
		elif _cool <= 0.0 and not p.is_on_floor() and p.global_position.distance_to(hp + Vector2(0, 52)) < 64.0 and p.get("hanging") == "":
			_attach(p)
		queue_redraw()

	func _attach(p: CharacterBody2D) -> void:
		_attached = true
		p.hanging = "rope"
		p.velocity = Vector2.ZERO
		_vel += clampf(p.velocity.x, -400.0, 400.0) * 0.002 + 0.3 * signf(p.facing)
		AudioManager.play_sfx("pickup", 1.4, -8.0)

	func _release(p: CharacterBody2D) -> void:
		_attached = false
		_cool = 0.4
		p.hanging = ""
		var tangent := Vector2(cos(angle), -sin(angle)) * (_vel * length)
		p.velocity = Vector2(clampf(tangent.x * 1.1, -760.0, 760.0), clampf(tangent.y * 0.8 - 560.0, -900.0, -200.0))
		p.facing = signf(p.velocity.x) if absf(p.velocity.x) > 40.0 else p.facing
		p.call("play_jump_sound") if p.has_method("play_jump_sound") else null

	func _draw() -> void:
		var hp := handle()
		var rope := Color("8a5a2b")
		draw_line(Vector2(-18, 0), hp + Vector2(-26, 0), Color("2a1f3d"), 7.0)
		draw_line(Vector2(18, 0), hp + Vector2(26, 0), Color("2a1f3d"), 7.0)
		draw_line(Vector2(-18, 0), hp + Vector2(-26, 0), rope, 4.0)
		draw_line(Vector2(18, 0), hp + Vector2(26, 0), rope, 4.0)
		var plank := PackedVector2Array([hp + Vector2(-44, -4), hp + Vector2(44, -4), hp + Vector2(44, 12), hp + Vector2(-44, 12)])
		draw_colored_polygon(plank, Color("b07a45"))
		draw_polyline(plank + PackedVector2Array([plank[0]]), Color("2a1f3d"), 3.0)
		draw_circle(Vector2.ZERO, 8.0, Color("2a1f3d"))


## A hanging vine of `length` tiles; the hero climbs while he is inside it and presses up (jump) or down.
class Vine extends Part:
	var length := 5.0
	var _area: Area2D

	func _build() -> void:
		length = float(data.get("length", 5))
		_area = Area2D.new()
		_area.collision_layer = 0
		_area.collision_mask = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(46, length * TILE)
		shape.shape = rect
		shape.position = Vector2(0, length * TILE * 0.5)
		_area.add_child(shape)
		add_child(_area)

	func _inside(p: Node2D) -> bool:
		var local := to_local(p.global_position + Vector2(0, -30))
		return absf(local.x) < 26.0 and local.y > -10.0 and local.y < length * TILE + 20.0

	func _physics_process(delta: float) -> void:
		var p := player()
		if p == null:
			return
		var inside := _inside(p)
		if p.get("hanging") == "vine" and p.get("hang_node") == self:
			if not inside or not p.controls_enabled:
				_let_go(p)
				return
			var v := 0.0
			if Input.is_action_pressed("jump"):
				v = -1.0
			elif Input.is_action_pressed("down"):
				v = 1.0
			p.velocity = Vector2(0, v * 200.0)
			p.global_position.x = lerpf(p.global_position.x, global_position.x, 0.25)
			p.global_position.y += v * 200.0 * delta
			var side := Input.get_axis("move_left", "move_right")
			if absf(side) > 0.6 and Input.is_action_just_pressed("dash"):
				_let_go(p)
				p.velocity = Vector2(side * 380.0, -420.0)
		elif inside and p.get("hanging") == "" and not p.is_on_floor() and (Input.is_action_pressed("jump") or p.velocity.y > 120.0):
			p.hanging = "vine"
			p.hang_node = self
			p.velocity = Vector2.ZERO
		queue_redraw()

	func _let_go(p: CharacterBody2D) -> void:
		p.hanging = ""
		p.hang_node = null

	func _draw() -> void:
		var sway := sin(Time.get_ticks_msec() * 0.0014 + position.x) * 6.0
		var pts := PackedVector2Array()
		for i in 12:
			var t := float(i) / 11.0
			pts.append(Vector2(sway * t * t, t * length * TILE))
		draw_polyline(pts, Color("2a1f3d"), 9.0)
		draw_polyline(pts, Color("4a9a3f"), 6.0)
		for i in range(1, 11):
			var q := pts[i]
			draw_circle(q + Vector2(10, 0), 6.0, Color("5fb04a"))
			draw_circle(q + Vector2(-10, 4), 6.0, Color("3f8f3e"))


## The end of a downhill: a wooden and stone launch ramp. Reaching it with speed gives a long boosted jump.
class Ramp extends Part:
	var _area: Area2D
	var power := 1.0

	func _build() -> void:
		power = float(data.get("power", 1.0))
		_area = Area2D.new()
		_area.collision_layer = 0
		_area.collision_mask = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(110, 40)
		shape.shape = rect
		shape.position = Vector2(0, -22)
		_area.add_child(shape)
		_area.body_entered.connect(_on_body)
		add_child(_area)

	func _on_body(body: Node) -> void:
		if body != player():
			return
		var p: CharacterBody2D = body
		var speed := absf(p.velocity.x)
		if speed < 160.0:
			return
		var boost := clampf(speed / 470.0, 0.7, 1.4) * power
		p.velocity = Vector2(signf(p.velocity.x) * maxf(speed, 420.0) * 1.12, -760.0 * boost)
		p._squash = Vector2(0.8, 1.25)
		AudioManager.play_sfx("whoosh", 1.0, -4.0)
		SpriteFX.play(get_parent(), "shock_ring", global_position + Vector2(0, -8), 0.8)

	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(-56, 0), Vector2(56, 0), Vector2(56, -36), Vector2(-56, -4)])
		draw_colored_polygon(pts, Color("b07a45"))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a1f3d"), 3.0)
		for i in 4:
			var x := -40.0 + i * 26.0
			draw_line(Vector2(x, -2), Vector2(x, -4 - (x + 56.0) * 0.28), Color("7a522b"), 2.0)


## A plank bridge: each plank (a tile wide) drops 0.4 s after a foot touches it and comes back 4 s later.
class Crumble extends Part:
	var count := 6
	var _planks: Array = []       ## [AnimatableBody2D, home_y, state, timer, vel]

	func _build() -> void:
		count = int(data.get("count", 6))
		for i in count:
			var b := AnimatableBody2D.new()
			b.collision_layer = 1
			b.collision_mask = 0
			b.sync_to_physics = false
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE - 4.0, 16.0)
			shape.shape = rect
			shape.one_way_collision = true
			b.add_child(shape)
			b.position = Vector2(i * TILE - (count - 1) * TILE * 0.5, 0)
			add_child(b)
			_planks.append([b, b.position.y, 0, 0.0, 0.0])

	func _physics_process(delta: float) -> void:
		var p := player()
		for entry in _planks:
			var b: AnimatableBody2D = entry[0]
			match int(entry[2]):
				0:      # solid: a foot on it starts the countdown
					if p != null and p.is_on_floor() and absf(p.global_position.x - b.global_position.x) < TILE * 0.55 \
							and absf((p.global_position.y + 40.0) - b.global_position.y) < 22.0:
						entry[2] = 1
						entry[3] = 0.4
						AudioManager.play_sfx("creak", 1.2, -8.0)
				1:      # cracking
					entry[3] -= delta
					b.position.y = entry[1] + sin(entry[3] * 90.0) * 1.6
					if entry[3] <= 0.0:
						entry[2] = 2
						entry[4] = 0.0
						entry[3] = 4.0
						SpriteFX.play(get_parent(), "stone_chips", b.global_position, 0.7)
				2:      # falling, then waiting to return
					entry[4] = minf(entry[4] + 1800.0 * delta, 1100.0)
					b.position.y += entry[4] * delta
					entry[3] -= delta
					if entry[3] <= 0.0:
						b.position.y = entry[1]
						entry[2] = 0
		queue_redraw()

	func _draw() -> void:
		for entry in _planks:
			var b: AnimatableBody2D = entry[0]
			if int(entry[2]) == 2 and b.position.y > entry[1] + 400.0:
				continue
			var c := b.position
			var r := Rect2(c.x - 30, c.y - 8, 60, 16)
			var col := Color("b07a45") if int(entry[2]) == 0 else Color("8a5a2b")
			draw_rect(r, col)
			draw_rect(r, Color("2a1f3d"), false, 3.0)
			draw_line(Vector2(c.x - 22, c.y), Vector2(c.x + 22, c.y), Color("7a522b"), 2.0)


## A rock hanging high up: when the hero is within `reach` px sideways it shows a shadow on the ground for 0.8 s,
## then falls; it breaks on the ground and the shadow fades. It hurts only if it hits him.
class FallingRock extends Part:
	var reach := 260.0
	var _state := 0         ## 0 waiting, 1 warning, 2 falling, 3 cooldown
	var _timer := 0.0
	var _vy := 0.0
	var _home := Vector2.ZERO
	var _ground_y := 0.0
	var _hit := false

	func _build() -> void:
		reach = float(data.get("reach", 260))
		_home = Vector2.ZERO
		_ground_y = float(data.get("drop", 5)) * TILE

	func _physics_process(delta: float) -> void:
		var p := player()
		match _state:
			0:
				if p != null and absf(p.global_position.x - global_position.x) < reach:
					_state = 1
					_timer = 0.8
			1:
				_timer -= delta
				if _timer <= 0.0:
					_state = 2
					_vy = 0.0
			2:
				_vy = minf(_vy + 2200.0 * delta, 1300.0)
				_home.y += _vy * delta
				if p != null and not _hit and p.global_position.distance_to(to_global(_home) + Vector2(0, 20)) < 52.0:
					_hit = true
					if p.has_method("take_hit"):
						p.take_hit(global_position.x)
				if _home.y >= _ground_y:
					SpriteFX.play(get_parent(), "stone_chips", to_global(Vector2(0, _ground_y)), 1.0)
					SpriteFX.play(get_parent(), "dust_soil", to_global(Vector2(0, _ground_y)), 0.9)
					_state = 3
					_timer = 3.5
			3:
				_timer -= delta
				if _timer <= 0.0:
					_home = Vector2.ZERO
					_state = 0
					_hit = false
		queue_redraw()

	func _draw() -> void:
		if _state == 1 or _state == 2:
			var a := 0.25 + 0.35 * (1.0 - _timer / 0.8) if _state == 1 else 0.6
			draw_colored_polygon(_ellipse(Vector2(0, _ground_y), Vector2(46, 9)), Color(0, 0, 0, a))
		if _state != 3:
			draw_circle(_home + Vector2(0, 16), 28.0, Color("2a1f3d"))
			draw_circle(_home + Vector2(0, 16), 25.0, Color("8d8f9a"))
			draw_circle(_home + Vector2(-8, 8), 8.0, Color("b7bac4"))

	func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		return pts


## A vent in the ground: steam column every 2 s (warm-up puffs first). The column lifts a hero standing in it.
class SteamVent extends Part:
	var _t := 0.0
	var _on := false
	var period := 2.0
	var height := 3.0

	func _build() -> void:
		period = float(data.get("period", 2.0))
		height = float(data.get("height", 3.0))
		_t = randf() * period

	func _physics_process(delta: float) -> void:
		_t += delta
		var phase := fmod(_t, period) / period
		_on = phase > 0.55
		var p := player()
		if _on and p != null:
			var local := to_local(p.global_position + Vector2(0, 30))
			if absf(local.x) < 36.0 and local.y < 10.0 and local.y > -height * TILE:
				p.velocity.y = maxf(p.velocity.y - 3200.0 * delta, -560.0)
		if _on and randf() < 0.5:
			SpriteFX.play(get_parent(), "foot_snow", global_position + Vector2(randf_range(-10, 10), -height * TILE * randf()), 0.8)
		queue_redraw()

	func _draw() -> void:
		var phase := fmod(_t, period) / period
		draw_rect(Rect2(-26, -10, 52, 12), Color("2a1f3d"))
		draw_rect(Rect2(-22, -8, 44, 8), Color("7a7f8a"))
		if phase > 0.4 and phase <= 0.55:                  # warm-up puffs
			draw_circle(Vector2(0, -16), 8.0 + (phase - 0.4) * 60.0, Color(1, 1, 1, 0.5))
		elif _on:
			var h := height * TILE * smoothstep(0.55, 0.65, phase)
			draw_rect(Rect2(-30, -h, 60, h), Color(1, 1, 1, 0.18))
