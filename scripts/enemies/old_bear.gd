class_name OldBear
extends ChapterBoss
## «خرس پیر» — the guardian of chapter 1 (content/01_chapters_act1.md). A shadow stole his cub's
## lullaby; he attacks out of fear, not hate.
##   phase 1: slams (a shock wave on the floor: jump it) and charges (he is dazed at the wall).
##   phase 2: roars and stones fall from the ceiling - in the past only; purple smoke.
##   phase 3: rage, faster. Calmed by the lullaby his back opens: the heart crystal is the target.
## Lens trick: in the present he wears bark armour (hits bounce off); in the past he can be hurt
## but is more dangerous (faster).
## Secret: the song stone in the past of the lair. Once it has sung, phase 3 is calm: he stops
## attacking and the heart crystal can be hit in either time. Without it phase 3 is harder.

const FAST_IN_PAST := 1.3

var arena_left := 0.0
var arena_right := 0.0
var lullaby := false
var rig: BearRig
var _action := "idle"
var _action_time := 0.0
var _charge_dir := 1.0


func setup() -> void:
	boss_id = "old_bear"
	body_size = Vector2(300, 210)
	hearts = 3
	max_hearts = 3
	rig = BearRig.new()
	add_child(rig)
	arena_left = float(params.get("arena_left", position.x - 700.0))
	arena_right = float(params.get("arena_right", position.x + 300.0))


func speed_k() -> float:
	return FAST_IN_PAST if TimeShift.state == TimeShift.PAST else 1.0


func calm() -> bool:
	return phase == 3 and lullaby


## The song stone sang in the past: from now on the bear can be calmed.
func hear_lullaby() -> void:
	if lullaby:
		return
	lullaby = true
	if phase == 3:
		on_phase(3)


func can_be_hurt(how: String, from: Vector2) -> bool:
	if calm():
		# calm: the heart crystal on his back; any hit near it counts, in either time
		return true
	if TimeShift.state == TimeShift.PRESENT:
		return false              # bark armour in the present
	if phase == 3:
		return _action == "dazed" and signf(from.x - global_position.x) != facing or how == "stomp" and _action == "dazed"
	return _action == "dazed" or how == "stomp"


func on_blocked(how: String, from: Vector2) -> void:
	super.on_blocked(how, from)
	FX.burst(get_parent(), global_position + Vector2(0, -150), Color(0.75, 0.6, 0.4), 8)
	if game and game.has_method("on_boss_armour"):
		game.on_boss_armour(self)


func harmful() -> bool:
	return super.harmful() and not calm() and _action != "dazed"


func on_phase(p: int) -> void:
	match p:
		1:
			rig.head_mood = "neutral"
			rig.smoke = 0.0
		2:
			rig.head_mood = "angry"
			create_tween().tween_property(rig, "smoke", 1.0, 0.8)
			AudioManager.play_sfx("rumble", 0.7)
		3:
			if lullaby:
				rig.head_mood = "calm"
				create_tween().tween_property(rig, "smoke", 0.0, 1.0)
				create_tween().tween_property(rig, "heart_open", 1.0, 1.0)
				_set_action("calm")
			else:
				rig.head_mood = "angry"
	if p != 3 or not lullaby:
		_set_action("rest")


func _set_action(a: String) -> void:
	_action = a
	_action_time = 0.0


func on_hit() -> void:
	super.on_hit()
	rig.flash = 1.0


func phase_process(delta: float) -> void:
	_action_time += delta * speed_k()
	var h := hero()
	rig.facing = facing
	match _action:
		"calm":
			velocity.x = 0.0
			rig.walk = 0.0
			rig.crouch = move_toward(rig.crouch, 0.6, delta)
		"rest":
			velocity.x = 0.0
			rig.walk = 0.0
			rig.raise = move_toward(rig.raise, 0.0, delta * 3.0)
			rig.crouch = move_toward(rig.crouch, 0.0, delta * 3.0)
			if h:
				facing = signf(h.global_position.x - global_position.x)
			if _action_time > (1.2 if phase < 3 else 0.7):
				_choose_attack()
		"slam_tell":
			rig.raise = move_toward(rig.raise, 1.0, delta * 2.0)
			if _action_time > 0.7:
				_slam()
				_set_action("rest")
		"charge_tell":
			rig.crouch = move_toward(rig.crouch, 0.4, delta * 3.0)
			if _action_time > 0.6:
				_charge_dir = facing
				_set_action("charge")
		"charge":
			rig.crouch = 0.0
			rig.walk = 1.0
			velocity.x = _charge_dir * 520.0 * speed_k() * (1.25 if phase == 3 else 1.0)
			var x := global_position.x
			if (_charge_dir > 0 and x >= arena_right) or (_charge_dir < 0 and x <= arena_left) or is_on_wall():
				velocity.x = 0.0
				Juice.shake(self, 0.5)
				AudioManager.play_sfx("impact", 0.7)
				_set_action("dazed")
		"dazed":
			rig.walk = 0.0
			rig.crouch = move_toward(rig.crouch, 1.0, delta * 4.0)
			velocity.x = 0.0
			if _action_time > 1.6:
				facing = -_charge_dir
				_set_action("rest")
		"roar":
			velocity.x = 0.0
			rig.raise = 0.6 + 0.2 * sin(_action_time * 20.0)
			if _action_time > 0.8:
				_rocks()
				_set_action("dazed")


func _choose_attack() -> void:
	if phase == 2 and randf() < 0.5:
		_set_action("roar")
		AudioManager.play_sfx("rumble", 0.6)
		return
	_set_action("slam_tell" if randf() < 0.5 else "charge_tell")


## The front paw hits the floor: a shock wave runs both ways (jump over it).
func _slam() -> void:
	AudioManager.play_sfx("impact", 0.6)
	for dir in [-1.0, 1.0]:
		var wave := ShockWave.new()
		wave.dir = dir
		wave.speed = 420.0 * speed_k()
		wave.position = global_position + Vector2(facing * 120.0, 0)
		get_parent().add_child(wave)


## Phase 2: stones drop from the ceiling of the lair (in the past layer: they only fall there).
func _rocks() -> void:
	var count := 4
	for i in count:
		var stone := FallingStone.new()
		var x := randf_range(arena_left, arena_right)
		if hero() and i == 0:
			x = hero().global_position.x
		stone.position = Vector2(x, global_position.y - 560.0)
		stone.floor_y = global_position.y
		stone.delay = 0.5 + i * 0.35
		stone.set_meta("time_layer", true)
		if game and game.info.get("layer_past"):
			game.info.layer_past.add_child(stone)
		else:
			get_parent().add_child(stone)


func on_released() -> void:
	rig.head_mood = "calm"
	rig.smoke = 0.0
	rig.heart_open = 1.0
	rig.walk = 0.0
	rig.raise = 0.0
	rig.crouch = 0.0


## A wave of dust along the floor; touching it is a hit (jump over it).
class ShockWave extends Area2D:
	var dir := 1.0
	var speed := 420.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(60, 40)
		shape.shape = rect
		shape.position = Vector2(0, -20)
		add_child(shape)
		body_entered.connect(func(b):
			if b.is_in_group("player") and b.has_method("take_hit"):
				b.take_hit(global_position.x - dir * 10.0))

	func _physics_process(delta: float) -> void:
		_t += delta
		position.x += dir * speed * delta
		if _t > 1.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.6 - _t, 0.0, 1.0)
		for i in 3:
			draw_circle(Vector2(-dir * i * 16.0, -12.0 - i * 4.0), 18.0 - i * 4.0, Color(0.85, 0.75, 0.6, 0.7 * a))


## A stone from the ceiling: a shadow marks where it lands (0.5 s or more before).
class FallingStone extends Area2D:
	const ART := "res://assets/art/p5_enemies/p5_concept_ch01_trap_rock_falling.png"
	var floor_y := 0.0
	var delay := 0.6
	var _vy := 0.0
	var _t := 0.0
	var _tex: Texture2D

	func time_mask() -> int:
		return 1

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		monitoring = false
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 34.0
		shape.shape = c
		add_child(shape)
		_tex = load(ART) if ResourceLoader.exists(ART) else null
		body_entered.connect(func(b):
			if TimeShift.state == TimeShift.PAST and b.is_in_group("player") and b.has_method("take_hit"):
				b.take_hit(global_position.x))

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > delay:
			monitoring = true
			_vy += 1800.0 * delta
			position.y += _vy * delta
			if position.y >= floor_y - 34.0:
				FX.dust(get_parent(), Vector2(position.x, floor_y), 6)
				AudioManager.play_sfx("rumble", 1.3, -6.0)
				queue_free()
		queue_redraw()

	func _draw() -> void:
		# the warning shadow on the floor
		var to_floor := floor_y - position.y
		var k := clampf(_t / maxf(delay, 0.01), 0.0, 1.0)
		draw_set_transform(Vector2(0, to_floor), 0.0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 20.0 + 20.0 * k, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO)
		if _tex:
			var s := 80.0 / maxf(_tex.get_width(), _tex.get_height())
			var size := _tex.get_size() * s
			draw_texture_rect(_tex, Rect2(-size * 0.5, size), false)


## «سنگ آواز»: in the past of the lair. Touch it (in the past) and it sings the cub's lullaby.
class SongStone extends Area2D:
	var game: Node
	var sung := false
	var _t := 0.0

	func time_mask() -> int:
		return 1

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		add_to_group("song_stone")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(90, 90)
		shape.shape = rect
		shape.position = Vector2(0, -45)
		add_child(shape)

	func _physics_process(_delta: float) -> void:
		if sung or TimeShift.state != TimeShift.PAST:
			return
		for b in get_overlapping_bodies():
			if b.is_in_group("player"):
				sing()
				return

	func sing() -> void:
		sung = true
		AudioManager.play_sfx("star", 0.7)
		AudioManager.play_sfx("star", 0.9, -3.0)
		if game and game.has_method("on_lullaby"):
			game.on_lullaby()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-44, 0), Vector2(-36, -70), Vector2(0, -92), Vector2(38, -66), Vector2(46, 0)]), Color("7d8796"))
		draw_colored_polygon(PackedVector2Array([Vector2(-36, -6), Vector2(-28, -62), Vector2(0, -80), Vector2(30, -60), Vector2(38, -6)]), Color("a7b0bd"))
		# carved notes; they float up while it sings
		var glow := 1.0 if sung else 0.5 + 0.5 * sin(_t * 3.0)
		for i in 3:
			var p := Vector2(-16 + i * 16, -44 + (i % 2) * 8)
			if sung:
				p.y -= fmod(_t * 30.0 + i * 20.0, 60.0)
			draw_circle(p, 6.0, Color(0.45, 0.8, 1.0, glow))
			draw_line(p + Vector2(5, 0), p + Vector2(5, -18), Color(0.45, 0.8, 1.0, glow), 2.5)
