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
		if not wanted(obj, game):
			continue
		if String(obj.get("type", "")) == "shot_target":
			var tgt := ShotTarget.new()
			tgt.game = game
			tgt.position = Vector2(float(obj.x) * TILE + TILE * 0.5, float(obj.y) * TILE)
			tgt.setup(obj)
			root.add_child(tgt)
			made.append(tgt)
			continue
		var part := _make(String(obj.get("type", "")))
		if part == null:
			continue
		part.game = game
		part.position = Vector2(float(obj.x) * TILE + TILE * 0.5, float(obj.y) * TILE)
		part.setup(obj)
		root.add_child(part)
		made.append(part)
	return made


## An object may be limited to a variant of the new level (docs/33 section 5): "when": ["full", "partial", "none"],
## or to a deed: "needs_deed" (only if done) / "no_deed" (only if not done).
static func wanted(obj: Dictionary, game: Node) -> bool:
	var variant := String(game.data.get("variant", "")) if game != null and game.get("data") is Dictionary else ""
	if obj.has("when") and variant != "" and not (obj.when as Array).has(variant):
		return false
	if obj.has("needs_deed") and not DeedsStore.has(String(obj.needs_deed)):
		return false
	if obj.has("no_deed") and DeedsStore.has(String(obj.no_deed)):
		return false
	return true


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
		"form_point":
			return FormPoint.new()
		"spin_beam":
			return SpinBeam.new()
		"gate":
			return Gate.new()
		"hatch_nest":
			return HatchNest.new()
		"spike_pit":
			return SpikePit.new()
		"tar":
			return Tar.new()
		"snapper":
			return Snapper.new()
		"door_trap":
			return DoorTrap.new()
		"net":
			return NetTrap.new()
		"quicksand":
			return QuickSand.new()
		"boulder_chase":
			return BoulderChase.new()
		"island":
			return Island.new()
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

	## Draws one painted picture centred at `at`, `w` px wide (keeps the aspect), rotated; false if the art is missing.
	func pic(sheet: String, row: int, idx: int, at: Vector2, w: float, rot := 0.0, bottom := false) -> bool:
		var tex := SideRig.pic(sheet, row, idx)
		if tex == null:
			return false
		var h := w * tex.get_height() / maxf(tex.get_width(), 1.0)
		draw_set_transform(at, rot)
		draw_texture_rect(tex, Rect2(-w * 0.5, -h if bottom else -h * 0.5, w, h), false)
		draw_set_transform(Vector2.ZERO)
		return true


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
		if pic("v3f_i_bridges", 1, 4, hp + Vector2(0, 4), 92.0, -angle):
			draw_circle(Vector2.ZERO, 8.0, Color("2a1f3d"))
			return
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
			var look: int = [1, 2, 3][int(entry[2])]
			if pic("v3f_i_bridges", 1, look, c + Vector2(0, 2), 74.0, 0.0 if int(entry[2]) < 2 else float(entry[4]) * 0.002):
				continue
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
		if _state != 3 and pic("v3f_i_hazards2", 0, 0, _home + Vector2(0, 16), 66.0, _vy * 0.0004):
			return
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
		if SideRig.pic("v3f_i_hazards2", 0, 4) != null:
			if _on:
				var ch := height * TILE * smoothstep(0.55, 0.65, phase)
				draw_rect(Rect2(-26, -ch, 52, ch), Color(1, 0.85, 1, 0.16))
			var look := 6 if _on else (5 if phase > 0.4 and phase <= 0.55 else 4)
			pic("v3f_i_hazards2", 0, look, Vector2(0, 6), 74.0, 0.0, true)
			return
		draw_rect(Rect2(-26, -10, 52, 12), Color("2a1f3d"))
		draw_rect(Rect2(-22, -8, 44, 8), Color("7a7f8a"))
		if phase > 0.4 and phase <= 0.55:                  # warm-up puffs
			draw_circle(Vector2(0, -16), 8.0 + (phase - 0.4) * 60.0, Color(1, 1, 1, 0.5))
		elif _on:
			var h := height * TILE * smoothstep(0.55, 0.65, phase)
			draw_rect(Rect2(-30, -h, 60, h), Color(1, 1, 1, 0.18))


# ---- "you get stuck" traps (docs/40 section 9.3). None is ever required: each one sits beside a plain route. ----

## The common test: is the hero inside this part's box? (box = size in px, centred horizontally on the part,
## standing on its y)
## A floating island you can stand on (docs/44): `width` tiles, `variant` 0-7 picks the painted island, `bob` px up/down
## (it rises and falls slowly), `drift` px sideways. The top of the island is the walkable edge (one-way).
class Island extends Part:
	var _body: AnimatableBody2D
	var _w := 192.0
	var _t := 0.0
	var _bob := 0.0
	var _drift := 0.0
	var _variant := 0

	func _build() -> void:
		_w = float(data.get("width", 3)) * TILE
		_variant = int(data.get("variant", 0))
		_bob = float(data.get("bob", 0))
		_drift = float(data.get("drift", 0))
		_t = float(data.get("phase", 0.0))
		_body = AnimatableBody2D.new()
		_body.collision_layer = 1
		_body.collision_mask = 0
		_body.sync_to_physics = false
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(_w * 0.86, 18.0)
		shape.shape = rect
		shape.one_way_collision = true
		shape.position = Vector2(0, 9)
		_body.add_child(shape)
		add_child(_body)

	func _physics_process(delta: float) -> void:
		_t += delta
		_body.position = Vector2(sin(_t * 0.7) * _drift, sin(_t * 1.1) * _bob)
		queue_redraw()

	func _draw() -> void:
		var row := _variant / 4
		var tex := SideRig.pic("v3f_i_islands", row, _variant % 4)
		if tex == null:
			draw_rect(Rect2(_body.position + Vector2(-_w * 0.5, 0), Vector2(_w, 24)), Color("5a8a3a"))
			return
		var w := _w * 1.08
		var h := w * tex.get_height() / tex.get_width()
		var top := _body.position + Vector2(0, h * 0.5 - 14.0)
		draw_texture_rect(tex, Rect2(top - Vector2(w, h) * 0.5, Vector2(w, h)), false)


class Zone extends Part:
	var box := Vector2(128, 48)

	func inside(p: Node2D) -> bool:
		var local := to_local(p.global_position + Vector2(0, 30))
		return absf(local.x) < box.x * 0.5 and local.y > -box.y and local.y < 24.0


## Thorny roots in a pit: a hit and a push out, with a short grace so it never chains.
class SpikePit extends Zone:
	var _cool := 0.0

	func _build() -> void:
		box = Vector2(float(data.get("width", 2)) * TILE, 44)

	func _physics_process(delta: float) -> void:
		_cool = maxf(0.0, _cool - delta)
		var p := player()
		if p != null and _cool <= 0.0 and inside(p) and p.invulnerable <= 0.0:
			_cool = 1.0
			p.take_hit(global_position.x - signf(p.velocity.x if absf(p.velocity.x) > 10.0 else 1.0) * 80.0)
			p.velocity.y = -640.0
		queue_redraw()

	func _draw() -> void:
		var up := 10.0 + 8.0 * sin(Time.get_ticks_msec() * 0.004 + position.x)
		var n := int(box.x / 26.0)
		for i in n:
			var x := -box.x * 0.5 + 13.0 + i * 26.0
			var pts := PackedVector2Array([Vector2(x - 11, 0), Vector2(x, -22 - up), Vector2(x + 11, 0)])
			draw_colored_polygon(pts, Color("5a3a2a"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a1f3d"), 2.5)


## Sticky tar: speed x0.4 and a weak jump while inside; jumping three times frees a hero from it.
class Tar extends Zone:
	var _taps := 0

	func _build() -> void:
		box = Vector2(float(data.get("width", 3)) * TILE, 26)

	func _physics_process(_delta: float) -> void:
		var p := player()
		if p == null:
			return
		if inside(p) and p.is_on_floor():
			p.tar = 0.4
			if Input.is_action_just_pressed("jump"):
				_taps += 1
				if _taps >= 3:
					_taps = 0
					p.velocity.y = -760.0
					p.tar = 1.0
		else:
			if p.tar < 1.0:
				p.tar = 1.0
			_taps = 0
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(-box.x * 0.5, -10, box.x, 14)
		draw_rect(r, Color("2a1f3d"))
		draw_rect(Rect2(r.position.x + 3, r.position.y + 2, r.size.x - 6, 8), Color("463a52"))
		for i in 4:
			var bx := -box.x * 0.5 + 24.0 + i * (box.x - 48.0) / 3.0
			var t := fmod(Time.get_ticks_msec() * 0.0015 + i * 0.37, 1.0)
			draw_circle(Vector2(bx, -8 - t * 8), 3.0 * (1.0 - t), Color("6b5a7a"))


## A snapping plant: the mouth opens and shuts on a rhythm; it bites only while it closes.
class Snapper extends Zone:
	var _t := 0.0
	var _cool := 0.0

	func _build() -> void:
		box = Vector2(96, 70)
		_t = randf() * 2.0

	func _physics_process(delta: float) -> void:
		_t += delta
		_cool = maxf(0.0, _cool - delta)
		var phase := fmod(_t, 2.0) / 2.0
		var p := player()
		if p != null and phase > 0.80 and phase < 0.92 and _cool <= 0.0 and inside(p) and p.invulnerable <= 0.0:
			_cool = 1.2
			p.take_hit(global_position.x)
		queue_redraw()

	func _draw() -> void:
		var phase := fmod(_t, 2.0) / 2.0
		var open := 1.0 - smoothstep(0.80, 0.9, phase) if phase > 0.5 else smoothstep(0.0, 0.5, phase)
		draw_rect(Rect2(-6, -30, 12, 30), Color("3f8f3e"))
		for sgn in [-1.0, 1.0]:
			var pts := PackedVector2Array([Vector2(0, -34), Vector2(sgn * 46, -34 - 40 * open), Vector2(sgn * 52, -34 - 6 * open), Vector2(sgn * 14, -22)])
			draw_colored_polygon(pts, Color("d0453a"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a1f3d"), 3.0)
			for k in 3:
				var tx: float = sgn * (14.0 + k * 12.0)
				draw_line(Vector2(tx, -30 - 8 * open), Vector2(tx + sgn * 3, -24 - 6 * open), Color("f6efe0"), 3.0)


## A stone door that drops behind the hero when he steps on the trigger; a pressure plate inside opens it again.
class DoorTrap extends Zone:
	var height := 3.0
	var _door: StaticBody2D
	var _closed := false
	var _plate_x := 0.0

	func _build() -> void:
		height = float(data.get("height", 3))
		box = Vector2(TILE * 0.5, TILE * height)
		_plate_x = float(data.get("plate", 6)) * TILE
		_door = StaticBody2D.new()
		_door.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE * 0.5, TILE * height)
		shape.shape = rect
		_door.add_child(shape)
		_door.position = Vector2(0, -TILE * height * 0.5 - TILE * height)    # starts raised, out of the way
		add_child(_door)
		shape.disabled = true

	func _physics_process(delta: float) -> void:
		var p := player()
		if p == null:
			return
		var raised_y := -TILE * height * 0.5 - TILE * height
		var down_y := -TILE * height * 0.5
		var shape: CollisionShape2D = _door.get_child(0)
		if not _closed:
			# the trigger is a spot just in front of the door's column
			if absf(p.global_position.x - (global_position.x + TILE * 1.2)) < 28.0 and p.is_on_floor():
				_closed = true
				shape.set_deferred("disabled", false)
				AudioManager.play_sfx("creak", 0.8, -2.0)
			_door.position.y = move_toward(_door.position.y, raised_y, 900.0 * delta)
		else:
			var plate := to_global(Vector2(_plate_x, 0))
			if absf(p.global_position.x - plate.x) < 40.0 and p.is_on_floor():
				_closed = false
				shape.set_deferred("disabled", true)
				SpriteFX.play(get_parent(), "stone_chips", global_position + Vector2(0, -20), 0.8)
			_door.position.y = move_toward(_door.position.y, down_y, 900.0 * delta)
		queue_redraw()

	func _draw() -> void:
		var h := TILE * height
		draw_rect(Rect2(-16, _door.position.y - h * 0.5, 32, h), Color("2a1f3d"))
		draw_rect(Rect2(-13, _door.position.y - h * 0.5 + 3, 26, h - 6), Color("8a8f9a"))
		var plate := Rect2(_plate_x - 24, -6, 48, 8)
		draw_rect(plate, Color("2a1f3d"))
		draw_rect(Rect2(plate.position.x + 3, plate.position.y + 2, plate.size.x - 6, 4), Color("d9b44a") if _closed else Color("6b6f78"))


## A net of sticky violet thread: the hero hangs in it and must press jump three times to tear free.
class NetTrap extends Zone:
	var _stuck := false
	var _taps := 0
	var _torn := 0.0

	func _build() -> void:
		box = Vector2(float(data.get("width", 2)) * TILE, float(data.get("height", 3)) * TILE)

	func inside(p: Node2D) -> bool:
		var local := to_local(p.global_position)
		return absf(local.x) < box.x * 0.5 and local.y > -box.y and local.y < 20.0

	func _physics_process(delta: float) -> void:
		var p := player()
		_torn = maxf(0.0, _torn - delta)
		if p == null:
			return
		if not _stuck and _torn <= 0.0 and inside(p):
			_stuck = true
			_taps = 0
			p.velocity = Vector2.ZERO
		if _stuck:
			p.velocity = Vector2(0, minf(p.velocity.y, 20.0))
			if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("fire"):
				_taps += 1
				SpriteFX.play(get_parent(), "brass_spark", p.global_position, 0.5)
				if _taps >= 3:
					_stuck = false
					_torn = 5.0
					p.velocity = Vector2(p.facing * 240.0, -420.0)
		queue_redraw()

	func _draw() -> void:
		if pic("v3f_i_hazards2", 3, 5 if _torn > 0.0 else 4, Vector2(0, 4), box.x * 1.05, 0.0, true):
			return
		var a := 0.15 if _torn > 0.0 else 0.85
		var w := box.x * 0.5
		var h := box.y
		for i in 5:
			var y := -h + i * h / 4.0
			draw_line(Vector2(-w, y), Vector2(w, y), Color(0.55, 0.35, 0.8, a), 3.0)
		for i in 5:
			var x := -w + i * w / 2.0
			draw_line(Vector2(x, -h), Vector2(x, 0), Color(0.55, 0.35, 0.8, a), 3.0)


## Quicksand: the hero sinks slowly (speed x0.45, jump x0.78); jumping repeatedly climbs out.
class QuickSand extends Zone:
	var _in := false

	func _build() -> void:
		box = Vector2(float(data.get("width", 3)) * TILE, 30)

	func _physics_process(_delta: float) -> void:
		var p := player()
		if p == null:
			return
		var now := inside(p) and p.is_on_floor()
		if now and not _in:
			_in = true
			p._sand += 1
		elif not now and _in:
			_in = false
			p._sand = maxi(0, p._sand - 1)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(-box.x * 0.5, -6, box.x, 12)
		draw_rect(r, Color("c9a35a"))
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), Color("e8c98a"))
		var t := Time.get_ticks_msec() * 0.002
		for i in 3:
			draw_arc(Vector2(-box.x * 0.3 + i * box.x * 0.3, -4), 7.0 + sin(t + i) * 2.0, 0, TAU, 14, Color("8a6a30"), 2.0)


## A boulder that chases: when the hero crosses the trigger it shows a rumble warning for 0.8 s, then rolls after him
## at a speed a running hero can beat; a jump over it or a shelter notch avoids it.
class BoulderChase extends Part:
	var length := 20.0
	var _state := 0
	var _t := 0.0
	var _x := 0.0
	var _rot := 0.0
	var _hit := false

	func _build() -> void:
		length = float(data.get("length", 20))

	func _ground_y(wx: float) -> float:
		var terrain: Node = null
		if game != null and game.get("info") is Dictionary:
			terrain = game.info.get("terrain", null)
		if terrain != null and terrain.has_method("height_at"):
			var h: float = terrain.height_at(wx)
			if h != INF:
				return h
		return global_position.y

	func _physics_process(delta: float) -> void:
		var p := player()
		if p == null:
			return
		match _state:
			0:
				if p.global_position.x > global_position.x:
					_state = 1
					_t = 0.8
					_x = global_position.x - TILE * 6.0
			1:
				_t -= delta
				if _t <= 0.0:
					_state = 2
			2:
				_x += 330.0 * delta
				_rot += 330.0 * delta / 40.0
				if not _hit and p.global_position.distance_to(Vector2(_x, _ground_y(_x) - 40.0)) < 54.0 and p.invulnerable <= 0.0:
					_hit = true
					p.take_hit(_x)
					p.velocity = Vector2(300, -520)
				if _x > global_position.x + length * TILE:
					_state = 3
		queue_redraw()

	func _draw() -> void:
		if _state < 1 or _state == 3:
			return
		var c := to_local(Vector2(_x, _ground_y(_x) - 40.0))
		if _state == 1:
			draw_line(to_local(Vector2(_x - 120.0, _ground_y(_x) - 6.0)), to_local(Vector2(_x - 40.0, _ground_y(_x) - 6.0)), Color(1, 0.6, 0.2, 0.7), 6.0)
		if pic("v3f_i_hazards2", 0, 3, c, 96.0, _rot):
			return
		draw_circle(c, 44.0, Color("2a1f3d"))
		draw_circle(c, 40.0, Color("8d8f9a"))
		for i in 4:
			var a := _rot + i * TAU / 4.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * 34.0, Color("6b6f78"), 3.0)
		if _state == 1:
			draw_line(to_local(Vector2(_x - 120.0, _ground_y(_x) - 6.0)), to_local(Vector2(_x - 40.0, _ground_y(_x) - 6.0)), Color(1, 0.6, 0.2, 0.7), 6.0)


## A mark on the scene: here the companion's form helps most (docs/40 section 1.2). Only a hint (a soft glowing
## sign near the spot); the form works anywhere, the mark just tells the player where to use it.
class FormPoint extends Part:
	var form := "rocket"
	var _t := 0.0

	func _build() -> void:
		form = String(data.get("form", "rocket"))
		add_to_group("form_point")
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		var col := Color(1.0, 0.85, 0.4, 0.5 + 0.3 * pulse)
		draw_arc(Vector2(0, -60), 26.0 + pulse * 4.0, 0, TAU, 28, col, 3.0)
		draw_circle(Vector2(0, -60), 7.0, Color(1.0, 0.95, 0.7, 0.8))
		draw_line(Vector2(0, -34), Vector2(0, -6), col, 2.0)


# ---- parts of the NEW-era level (docs/33 section 5, docs/40 section 2): shooting targets, doors, the hatching nest ----

## Something the hero shoots: a hanging rope, a crystal, a button. Arrows and stones call receive_hit(); `kind` says what
## it does when hit: "rope" (drops what hangs on it), "crystal" (counts toward opening a door), "button" (opens a door).
class ShotTarget extends StaticBody2D:
	var game: Node
	var data: Dictionary = {}
	var kind := "crystal"
	var group_id := ""
	var hit_done := false
	var _flash := 0.0
	var _after := 0.0
	var _t := 0.0
	var size := Vector2(46, 46)

	func setup(obj: Dictionary) -> void:
		data = obj
		kind = String(obj.get("kind", "crystal"))
		group_id = String(obj.get("group", ""))
		collision_layer = 4          # the layer shots test (enemies' layer)
		collision_mask = 0
		add_to_group("route_part")
		add_to_group("shot_target")
		z_index = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		shape.position = Vector2(0, -size.y * 0.5)
		add_child(shape)

	func receive_hit(_how: String, _from: Vector2) -> bool:
		if hit_done:
			return true
		hit_done = true
		_flash = 0.3
		SpriteFX.play(get_parent(), "hit_flash", global_position + Vector2(0, -size.y * 0.5), 0.8)
		AudioManager.play_sfx("star", 1.1, -6.0)
		if game != null and game.has_method("on_target_hit"):
			game.on_target_hit(self)
		return true

	func _process(delta: float) -> void:
		_t += delta
		_flash = maxf(0.0, _flash - delta)
		if hit_done:
			_after += delta
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(0, -size.y * 0.5)
		if kind == "rope":
			var sway := sin(_t * 1.6) * 4.0
			var rope_len := float(data.get("rope", 3)) * 64.0
			draw_line(Vector2(sway, -size.y - rope_len), Vector2(0, -size.y), Color("2a1f3d"), 7.0)
			draw_line(Vector2(sway, -size.y - rope_len), Vector2(0, -size.y), Color("a8743f") if not hit_done else Color(0.7, 0.5, 0.3, 0.3), 4.0)
			draw_circle(c, 14.0, Color("2a1f3d"))
			draw_circle(c, 11.0, Color("d9b44a") if not hit_done else Color(0.8, 0.8, 0.8, 0.3))
			return
		var idx := 1 + int(_t * 6.0) % 3
		if hit_done:
			var since := _after
			idx = 4 if since < 0.15 else (5 if since < 0.3 else (6 + int((since - 0.3) * 8.0) if since < 0.6 else 9))
		var tex := SideRig.pic("v3f_i_shrine_gate", 2, idx)
		if tex != null:
			var th := 104.0
			var tw := tex.get_width() * th / tex.get_height()
			draw_texture_rect(tex, Rect2(Vector2(-tw * 0.5, 6.0 - th), Vector2(tw, th)), false)
			return
		var col := Color("6fe0f0") if not hit_done else Color("2a6a80")
		var pts := PackedVector2Array([c + Vector2(0, -24), c + Vector2(15, -4), c + Vector2(10, 20), c + Vector2(-10, 20), c + Vector2(-15, -4)])
		draw_colored_polygon(pts, col.lightened(0.15 * sin(_t * 3.0)) if not hit_done else col)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a1f3d"), 3.0)
		if _flash > 0.0:
			draw_circle(c, 34.0, Color(1, 1, 0.8, _flash))


## A stone gate that rises when its `opens` id is triggered (by targets of the same group, the shrine or a variant).
class Gate extends Part:
	var gate_id := "gate"
	var height := 4.0
	var need := 1
	var _door: StaticBody2D
	var _open := false
	var _got := 0
	var _frame := 0

	func _build() -> void:
		gate_id = String(data.get("id", "gate"))
		height = float(data.get("height", 4))
		need = int(data.get("need", 1))
		add_to_group("gate")
		_door = StaticBody2D.new()
		_door.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE * 0.7, TILE * height)
		shape.shape = rect
		_door.add_child(shape)
		_door.position = Vector2(0, -TILE * height * 0.5)
		add_child(_door)
		if bool(data.get("start_open", false)):
			open(true)

	func trigger() -> void:
		_got += 1
		if _got >= need:
			open()

	func open(instant := false) -> void:
		if _open:
			return
		_open = true
		_door.get_child(0).set_deferred("disabled", true)
		if instant:
			_door.position.y = -TILE * height * 1.6
			_frame = 5
		else:
			create_tween().tween_property(_door, "position:y", -TILE * height * 1.6, 0.9)
			create_tween().tween_property(self, "_frame", 5, 0.9)
			AudioManager.play_sfx("creak", 0.9, -2.0)
			SpriteFX.play(get_parent(), "stone_chips", global_position + Vector2(0, -TILE * height * 0.5), 1.0)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var h := TILE * height
		var y := _door.position.y
		var gate_tex := SideRig.pic("v3f_i_shrine_gate", 1, _frame)
		if gate_tex != null:
			var gh := h * 1.15
			var gw := gate_tex.get_width() * gh / gate_tex.get_height()
			draw_texture_rect(gate_tex, Rect2(Vector2(-gw * 0.5, -gh + 6.0), Vector2(gw, gh)), false)
			return
		if _open and y <= -h * 1.45:
			return                    # raised out of sight
		draw_rect(Rect2(-22, y - h * 0.5, 44, h), Color("2a1f3d"))
		draw_rect(Rect2(-18, y - h * 0.5 + 4, 36, h - 8), Color("8a8f9a"))
		draw_circle(Vector2(0, y), 16.0, Color("2a1f3d"))
		draw_circle(Vector2(0, y), 12.0, Color("6fe0f0") if _open else Color("d9b44a"))


## Two beams crossed like a plus on a hub, turning slowly: the cross-shaped rotating hazard of the tower. Touching an
## arm costs a heart; the rhythm is regular and shown by a faint ring. `speed` in degrees per second.
class SpinBeam extends Part:
	var arm := 150.0
	var speed := 45.0
	var _ang := 0.0
	var _cool := 0.0

	func _build() -> void:
		arm = float(data.get("arm", 2.4)) * TILE
		speed = float(data.get("speed", 45.0))
		_ang = deg_to_rad(float(data.get("phase", 0.0)))

	func _physics_process(delta: float) -> void:
		_ang += deg_to_rad(speed) * delta
		_cool = maxf(0.0, _cool - delta)
		var p := player()
		if p != null and _cool <= 0.0 and p.invulnerable <= 0.0:
			var local := to_local(p.global_position + Vector2(0, -30))
			for k in 4:
				var dir := Vector2.from_angle(_ang + k * PI * 0.5)
				var along := local.dot(dir)
				if along > 20.0 and along < arm:
					var off := absf(local.cross(dir))
					if off < 22.0:
						_cool = 1.0
						p.take_hit(global_position.x - dir.x * 40.0)
						break
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, arm, 0, TAU, 40, Color(1, 1, 1, 0.07), 2.0)
		if pic("v3f_i_spinbeams", 1, 0, Vector2.ZERO, arm * 2.0 + 24.0, _ang):
			return
		for k in 4:
			var dir := Vector2.from_angle(_ang + k * PI * 0.5)
			var n := Vector2(-dir.y, dir.x)
			var tip := dir * arm
			var pts := PackedVector2Array([n * 11.0, tip + n * 11.0, tip - n * 11.0, -n * 11.0])
			draw_colored_polygon(pts, Color("a8743f"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a1f3d"), 3.0)
			draw_circle(tip, 13.0, Color("2a1f3d"))
			draw_circle(tip, 9.0, Color("8d8f9a"))
		draw_circle(Vector2.ZERO, 20.0, Color("2a1f3d"))
		draw_circle(Vector2.ZERO, 15.0, Color("d9b44a"))


## The egg's nest: a rope target holds it up; when the rope is shot the nest falls, the egg cracks and Tikkit hatches
## (2.3 s), then joins the hero. With the deed `egg_saved` the nest hangs in the branch within reach (full), without it
## the egg lies cracked in smoke lower down (none). Either way the hatch happens.
class HatchNest extends Part:
	var _state := 0              ## 0 hanging, 1 falling, 2 hatching, 3 done
	var _t := 0.0
	var _y := 0.0
	var _ground_y := 0.0
	var cracked := false

	func _build() -> void:
		cracked = bool(data.get("cracked", false))
		_ground_y = float(data.get("drop", 4)) * TILE
		add_to_group("hatch_nest")

	func release() -> void:
		if _state == 0:
			_state = 1

	func _physics_process(delta: float) -> void:
		match _state:
			1:
				_t += delta
				_y = minf(_y + _t * 1500.0 * delta, _ground_y)
				if _y >= _ground_y:
					_state = 2
					_t = 0.0
					SpriteFX.play(get_parent(), "dust_soil", global_position + Vector2(0, _ground_y), 1.0)
			2:
				_t += delta
				if _t >= 2.3:
					_state = 3
					if game != null and game.has_method("tikkit_joins"):
						game.tikkit_joins(global_position + Vector2(0, _ground_y - 40.0))
		queue_redraw()

	func _draw() -> void:
		var base := Vector2(0, _y)
		# painted nest (docs/44, v3f_i_shrine_gate row 4): hanging, falling, egg shaking and cracking, chick hatching
		var idx := 5
		match _state:
			0:
				idx = 7 if cracked else 5
			1:
				idx = 2 + int(_t * 8.0) % 2
			2:
				idx = [5, 6, 7, 8, 9][mini(int(_t / 2.3 * 5.0), 4)]
			3:
				idx = 4
		if pic("v3f_i_shrine_gate", 4, idx, base + Vector2(0, 4), 96.0, 0.0, true):
			return
		draw_arc(base + Vector2(0, -6), 34.0, 0.15, PI - 0.15, 18, Color("2a1f3d"), 12.0)
		draw_arc(base + Vector2(0, -6), 34.0, 0.15, PI - 0.15, 18, Color("8a5a2b"), 8.0)
		if _state < 3:
			var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			var egg := Vector2(0, -34) + base
			var shell := Color("f1e6d0") if not cracked else Color("8a7a8a")
			if _state == 2:
				shell = Color("f6efe0").lerp(Color(1, 0.95, 0.6), clampf(_t / 2.3, 0, 1))
				draw_circle(egg, 40.0 + _t * 22.0, Color(1, 0.9, 0.5, 0.12 + 0.2 * (_t / 2.3)))
			draw_circle(egg, 22.0, Color("2a1f3d"))
			draw_circle(egg, 19.0, shell)
			draw_line(egg + Vector2(-8, -6), egg + Vector2(0, 2), Color("2a1f3d"), 2.0)
			draw_line(egg + Vector2(0, 2), egg + Vector2(8, -4), Color("2a1f3d"), 2.0)
			draw_circle(egg + Vector2(0, 0), 6.0 + glow * 2.0, Color(1, 0.9, 0.5, 0.6))
