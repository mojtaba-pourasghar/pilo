extends CharacterBody2D
## Nima's movement, in the spirit of Mario and Sonic but tuned for small hands:
## - momentum: walking speed at first, holding a direction opens up running speed;
##   faster runs jump higher; turning at speed skids;
## - dash (its own button): a short burst that also smashes cracked walls; once per jump
##   in the air;
## - stomp: landing on a stompable enemy frees it and bounces Nima up (higher if jump is held);
## - hitting a block from below bumps it (coins, diamonds, bricks);
## - glide: holding jump while falling, Pilo carries Nima and they float down slowly (a few
##   seconds, refilled on landing) — some gaps can only be crossed this way;
## - hearts: a hit costs one heart, knocks Nima back, spills a few coins and gives a short
##   blinking invulnerability. Forgiving jump timing (coyote time and jump buffer) stays.
## Nima is drawn in code (NimaRig), every joint animated.

signal jumped
signal landed
signal dashed

const BODY_SIZE := Vector2(36, 80)
const FEET := 40.0
const WALK := 300.0
const RUN := 470.0
const RUN_AFTER := 0.65         # seconds of running in one direction before top speed opens
const GROUND_ACCEL := 1500.0
const AIR_ACCEL := 1150.0
const FRICTION := 1900.0
const OVERSPEED_DECEL := 700.0  # after a dash, speed above the cap fades out gently
const SKID_DECEL := 3600.0
const GRAVITY := 2100.0
const JUMP_VELOCITY := -870.0
const JUMP_SPEED_BONUS := 0.14  # extra jump height per px/s of run speed
const JUMP_CUT := -330.0
const STOMP_BOUNCE := -640.0
const STOMP_BOUNCE_HELD := -930.0
const SPRING_VELOCITY := -1320.0
const MAX_FALL := 1150.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.15
const DASH_SPEED := 780.0
const DASH_TIME := 0.26
const DASH_COOLDOWN := 0.45
const INVULNERABLE := 1.6
const KNOCKBACK := Vector2(340, -560)
const GLIDE_FALL := 110.0      # fall speed while Pilo carries Nima
const GLIDE_TIME := 2.2
const WIND_PUSH := 260.0
const UPDRAFT_ACCEL := 3400.0
const UPDRAFT_MAX := -560.0

var controls_enabled := true
var facing := 1.0
var hearts := 3
var max_hearts := 3
## Set from the companion and the tools (apply_loadout).
var walk_speed := WALK
var run_speed := RUN
var jump_scale := 1.0
var glide_time := GLIDE_TIME
var glide_fall := GLIDE_FALL
var dash_speed := DASH_SPEED
var dash_time := DASH_TIME
var wall_jump := false
var double_jump := false
var ice_grip := false
var sand_free := false
var swim_fast := false
var thorn_proof := false
var dash_frees_spiky := false
var dash_breaks_bricks := false
var shield := 0
var _double_used := false
var invulnerable := 0.0
var dashing := 0.0
var can_glide := true           ## false in levels before Pilo learns it (or without Pilo)
var gliding := false
var glide_left := GLIDE_TIME
var _air_dash_used := false

var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false
var _was_on_floor := true
var _run_hold := 0.0
var _dash_cooldown := 0.0
var _hurt_lock := 0.0
var _pose_lock := 0.0
var _pose_lock_state := ""
var _squash := Vector2.ONE
var _emote: Label
var _wind := Vector2.ZERO      # set by wind zones for the next physics frame
var _on_ice := false
var _belt := 0.0
var _swim := 0                 # deep water areas Nima is in (swimming when > 0)
var _sand := 0                 # quicksand areas Nima is in (slowed when > 0)

@onready var visual: Node2D = $Visual
@onready var rig: CharacterRig = $Visual/Rig


func _ready() -> void:
	z_index = 4
	if PaintedRig.available("nima"):
		# the generated, rendered Nima replaces the drawn one
		var painted := PaintedRig.make("nima")
		painted.name = "Rig"
		rig.replace_by(painted)
		rig.queue_free()
		rig = painted
	_emote = UIKit.make_label("!", 48, UIKit.RED, 10, Color.WHITE)
	_emote.size = Vector2(80, 60)
	_emote.position = Vector2(-40, -130)
	_emote.visible = false
	add_child(_emote)


func _physics_process(delta: float) -> void:
	var dir := 0.0
	var can_move := controls_enabled and _hurt_lock <= 0.0
	if can_move:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_buffer = JUMP_BUFFER
			if not is_on_floor() and _coyote <= 0.0 and _swim == 0:
				_air_jump()
		if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and (is_on_floor() or not _air_dash_used):
			_air_dash_used = not is_on_floor()
			_start_dash(dir)
	_buffer -= delta
	_dash_cooldown -= delta
	_hurt_lock -= delta
	_pose_lock -= delta
	invulnerable = maxf(0.0, invulnerable - delta)
	var on_floor := is_on_floor()
	_coyote = COYOTE_TIME if on_floor else _coyote - delta
	if on_floor:
		_air_dash_used = false
		_double_used = false
		glide_left = glide_time

	if dashing > 0.0:
		dashing -= delta
		velocity.x = facing * dash_speed
		velocity.y = minf(velocity.y + GRAVITY * 0.15 * delta, 120.0)
	elif _swim > 0:
		# swimming: soft gravity, slow sinking, every jump press is a stroke upward
		gliding = false
		velocity.y = minf(velocity.y + 650.0 * delta, 210.0)
		if can_move and Input.is_action_just_pressed("jump"):
			velocity.y = -600.0 if swim_fast else -470.0
			_buffer = 0.0
			_squash = Vector2(0.85, 1.15)
			AudioManager.play_sfx_once("splash", 0.2, 1.5, -10.0)
		_horizontal(dir, delta, false)
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		gliding = can_glide and can_move and not on_floor and velocity.y > 0.0 and glide_left > 0.0 \
			and Input.is_action_pressed("jump") and not _jump_held
		if gliding:
			glide_left -= delta
			velocity.y = minf(velocity.y, glide_fall)
		if _wind.y < 0.0:
			velocity.y = maxf(velocity.y - UPDRAFT_ACCEL * delta, UPDRAFT_MAX)
		_horizontal(dir, delta, on_floor)
	_wind = Vector2.ZERO

	if _buffer > 0.0 and _coyote > 0.0 and can_move and _swim == 0:
		velocity.y = (JUMP_VELOCITY - absf(velocity.x) * JUMP_SPEED_BONUS) * jump_scale
		if _sand > 0 and not sand_free:
			velocity.y *= 0.78
		_buffer = 0.0
		_coyote = 0.0
		dashing = minf(dashing, 0.05)
		# A buffered tap that was already released still gets a full jump (no tiny hop).
		_jump_held = Input.is_action_pressed("jump")
		_squash = Vector2(0.78, 1.22)
		jumped.emit()
	if _jump_held and (not controls_enabled or not Input.is_action_pressed("jump")):
		_jump_held = false
		velocity.y = maxf(velocity.y, JUMP_CUT)
	if velocity.y >= 0.0:
		_jump_held = false

	move_and_slide()
	_check_collisions()
	if _belt != 0.0 and is_on_floor():
		move_and_collide(Vector2(_belt * TimeBlock.BELT_SPEED * delta, 0))

	on_floor = is_on_floor()
	if on_floor and not _was_on_floor:
		_squash = Vector2(1.25, 0.8)
		landed.emit()
	_was_on_floor = on_floor
	if dir != 0.0 and dashing <= 0.0 and _hurt_lock <= 0.0:
		facing = signf(dir)
	_animate(delta, on_floor, dir)


func _horizontal(dir: float, delta: float, on_floor: bool) -> void:
	if dir != 0.0 and on_floor and signf(dir) == signf(velocity.x):
		_run_hold += delta
	elif dir == 0.0 or signf(dir) != signf(velocity.x):
		_run_hold = 0.0
	var cap := run_speed if _run_hold > RUN_AFTER else walk_speed
	var drift := 0.0
	if _wind.x != 0.0 and not on_floor:
		drift = signf(_wind.x) * WIND_PUSH
	var target := dir * cap + drift
	var rate := FRICTION
	if dir != 0.0:
		rate = GROUND_ACCEL if on_floor else AIR_ACCEL
		if on_floor and signf(dir) != signf(velocity.x) and absf(velocity.x) > 200.0:
			rate = SKID_DECEL
	if absf(velocity.x) > cap and signf(velocity.x) == signf(target):
		rate = OVERSPEED_DECEL
	if _on_ice and on_floor and not ice_grip:
		rate *= 0.18 if dir == 0.0 else 0.4      # ice: slow to start, slower to stop
	var slowed := (_swim > 0 and not swim_fast) or (_sand > 0 and not sand_free)
	if slowed:
		cap *= 0.7 if _swim > 0 else 0.45
		target = dir * cap
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _start_dash(dir: float) -> void:
	if dir != 0.0:
		facing = signf(dir)
	dashing = dash_time
	_dash_cooldown = DASH_COOLDOWN
	velocity.y = minf(velocity.y, 0.0) * 0.4
	_squash = Vector2(1.25, 0.85)
	dashed.emit()
	AudioManager.play_sfx("dash")


func _check_collisions() -> void:
	_on_ice = false
	_belt = 0.0
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider()
		if not (body is Node):
			continue
		var normal := hit.get_normal()
		if normal.y < -0.6 and body is TimeBlock:
			_on_ice = body.kind == TimeBlock.Kind.ICE
			_belt = body.belt
		if normal.y > 0.6 and body.has_method("bump"):
			body.call("bump", self)
		elif normal.y < -0.6 and body.is_in_group("spring"):
			velocity.y = SPRING_VELOCITY
			_jump_held = false
			_squash = Vector2(0.7, 1.3)
			body.call("boing")
			AudioManager.play_sfx("bounce")
			return
		elif absf(normal.x) > 0.6 and dashing > 0.0 and body is Block and dash_breaks_bricks and body.kind == Block.Kind.BRICK:
			body.smash()
		elif absf(normal.x) > 0.6 and dashing > 0.0 and body.has_method("smash") and not body is Block:
			body.call("smash")
			dashing = 0.0
			velocity.x = -facing * 120.0
		elif normal.y < -0.6 and body.has_method("stood_on"):
			body.call("stood_on", self)


func _animate(delta: float, on_floor: bool, dir: float) -> void:
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, 10.0 * delta))
	var state := "idle"
	if _pose_lock > 0.0:
		state = _pose_lock_state
	elif _hurt_lock > 0.0:
		state = "hurt"
	elif dashing > 0.0:
		state = "dash"
	elif _swim > 0:
		state = "fall" if velocity.y > 0.0 else "jump"
	elif gliding:
		state = "glide"
	elif not on_floor:
		state = "jump" if velocity.y < -120.0 else "fall"
	elif dir != 0.0 and signf(dir) != signf(velocity.x) and absf(velocity.x) > 200.0:
		state = "skid"
	elif absf(velocity.x) > 30.0:
		state = "run" if absf(velocity.x) > WALK + 20.0 else "walk"
	rig.state = state
	rig.speed = velocity.x
	rig.run_speed = run_speed
	if state == "skid" and Engine.get_physics_frames() % 6 == 0:
		FX.dust(get_parent(), global_position + Vector2(facing * 14.0, FEET))
	visual.scale = Vector2(facing * _squash.x, _squash.y)
	visual.position.y = FEET
	visual.modulate.a = 0.35 + 0.65 * float(int(invulnerable * 12.0) % 2) if invulnerable > 0.0 else 1.0


## Footstep sounds follow the drawn stride (called by the rig's phase in _process).
func _process(_delta: float) -> void:
	if not is_on_floor() or (rig.state != "walk" and rig.state != "run"):
		return
	var step := int(rig.phase / PI)
	if step != int(get_meta("step", -1)):
		set_meta("step", step)
		AudioManager.play_sfx("step", randf_range(0.9, 1.12), -10.0)


## True when Nima is falling onto something whose top is at `top_y`.
func is_stomping(top_y: float) -> bool:
	return velocity.y > 40.0 and global_position.y + FEET <= top_y + 22.0


func stomp_bounce() -> void:
	velocity.y = STOMP_BOUNCE_HELD if Input.is_action_pressed("jump") and controls_enabled else STOMP_BOUNCE
	_jump_held = false
	_coyote = 0.0
	_squash = Vector2(0.8, 1.2)
	_hold_pose("stomp", 0.25)


## A hit from an enemy or hazard at x = `source_x`. Returns false while invulnerable.
func take_hit(source_x: float) -> bool:
	if invulnerable > 0.0 or hearts <= 0:
		return false
	if shield > 0:
		# the bubble shield takes this hit instead
		shield -= 1
		invulnerable = 1.0
		FX.ring(get_parent(), global_position, Color(0.6, 0.9, 1.0))
		AudioManager.play_sfx("pop")
		return false
	hearts -= 1
	invulnerable = INVULNERABLE
	_hurt_lock = 0.35
	dashing = 0.0
	var away := signf(global_position.x - source_x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * KNOCKBACK.x, KNOCKBACK.y)
	rig.expression = "hurt"
	get_tree().create_timer(0.7).timeout.connect(func(): rig.expression = "normal")
	AudioManager.play_sfx("hurt")
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("on_player_hurt"):
		game.on_player_hurt(away)
	return true


## Wall jump (Sanjabak) and double jump (Shakh-Tala) — pressed in the air.
func _air_jump() -> void:
	if wall_jump and is_on_wall_only():
		var away := get_wall_normal().x
		velocity = Vector2(away * 420.0, JUMP_VELOCITY * 0.92)
		facing = signf(away)
		_squash = Vector2(0.8, 1.2)
		jumped.emit()
		_buffer = 0.0
	elif double_jump and not _double_used:
		_double_used = true
		velocity.y = JUMP_VELOCITY * 0.85
		_jump_held = true
		_squash = Vector2(0.8, 1.2)
		FX.dust(get_parent(), global_position + Vector2(0, FEET), 6)
		jumped.emit()
		_buffer = 0.0


## The companion picked in the village and the tools in the bag change how Nima moves.
func apply_loadout() -> void:
	var c := Loadout.companion()
	wall_jump = c == "squirrel"
	swim_fast = c == "turtle"
	sand_free = c == "mole"
	ice_grip = c == "penguin"
	glide_time = GLIDE_TIME * (2.0 if c == "butterfly" else 1.0) * (1.5 if Loadout.has_tool("umbrella") else 1.0)
	if Loadout.has_tool("balloon"):
		glide_time = 9999.0
	glide_fall = 0.0 if c == "dragon" else (70.0 if Loadout.has_tool("umbrella") else GLIDE_FALL)
	dash_frees_spiky = c == "hedgehog"
	dash_breaks_bricks = c == "hedgehog" or Loadout.has_tool("hammer")
	double_jump = c == "goat"
	thorn_proof = c == "cat"
	max_hearts = 4 if c == "lion" else 3
	hearts = max_hearts
	walk_speed = WALK * (1.12 if Loadout.has_tool("shoes") else 1.0)
	run_speed = RUN * (1.15 if Loadout.has_tool("shoes") else 1.0)
	jump_scale = 1.08 if Loadout.has_tool("springs") else 1.0
	dash_speed = DASH_SPEED * (1.3 if Loadout.has_tool("skateboard") else 1.0)
	dash_time = DASH_TIME * (1.4 if Loadout.has_tool("skateboard") else 1.0)
	shield = 1 if Loadout.has_tool("shield") else 0
	glide_left = glide_time


func heal(amount := 1) -> void:
	hearts = mini(max_hearts, hearts + amount)


func enter_water() -> void:
	_swim += 1
	velocity.y *= 0.3
	AudioManager.play_sfx("splash", 1.1, -4.0)


func exit_water() -> void:
	_swim = maxi(0, _swim - 1)
	if _swim == 0 and velocity.y < 0.0:
		velocity.y = minf(velocity.y, -560.0)   # a little hop out onto the bank


func enter_sand() -> void:
	_sand += 1


func exit_sand() -> void:
	_sand = maxi(0, _sand - 1)


## Called by wind zones every physics frame the hero is inside them.
func apply_wind(direction: Vector2) -> void:
	_wind += direction


func get_body_rect() -> Rect2:
	return Rect2(global_position - BODY_SIZE * 0.5, BODY_SIZE)


## Small hop with a "!" when the time lens refuses to work here.
func react_surprise() -> void:
	_show_emote("!", UIKit.RED)
	_squash = Vector2(1.2, 0.85)


func celebrate() -> void:
	_show_emote("!!", UIKit.GREEN)
	_hold_pose("celebrate", 3.0)
	rig.expression = "happy"
	var tween := create_tween()
	for i in 2:
		tween.tween_property(visual, "position:y", FEET - 40.0, 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "position:y", FEET, 0.18).set_ease(Tween.EASE_IN)
	FX.burst(get_parent(), global_position + Vector2(0, -40), UIKit.GOLD, 24)


func use_lens_pose() -> void:
	_hold_pose("lens", 0.3)


func respawn(pos: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	await tween.finished
	global_position = pos
	velocity = Vector2.ZERO
	_buffer = 0.0
	_jump_held = false
	dashing = 0.0
	_hurt_lock = 0.0
	rig.expression = "normal"
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.reset_smoothing()
	tween = create_tween()
	tween.tween_property(visual, "modulate:a", 1.0, 0.25)
	await tween.finished


func _hold_pose(state: String, time: float) -> void:
	_pose_lock_state = state
	_pose_lock = time


func _show_emote(text: String, color: Color) -> void:
	_emote.text = text
	_emote.add_theme_color_override("font_color", color)
	_emote.visible = true
	_emote.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_emote, "position:y", -150.0, 0.2).from(-120.0)
	tween.tween_interval(0.5)
	tween.tween_property(_emote, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): _emote.visible = false)
