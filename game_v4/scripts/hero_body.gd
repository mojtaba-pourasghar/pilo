class_name HeroBody
extends CharacterBody2D
## The hero's movement (docs/45 section 4): quick acceleration, a short skid on stopping, variable jump with a floating
## apex, coyote time and jump buffer, glide with the cloak, wall slide and wall jump, leaps toward a tapped point,
## dropping through thin platforms, a strike. Origin = between the feet.

signal landed(speed: float)
signal jumped
signal struck(at: Vector2)

const RUN_MAX := 560.0
const ACCEL := 3200.0
const BRAKE := 2800.0
const TURN := 5500.0
const AIR_ACCEL := 2400.0
const JUMP_V := 1080.0
const G_UP := 2600.0
const G_DOWN := 3800.0
const APEX_BAND := 140.0
const FALL_MAX := 1500.0
const GLIDE_FALL := 170.0
const WALL_SLIDE := 220.0
const WALL_KICK := 480.0
const COYOTE := 0.12
const BUFFER := 0.15
const CUT := 0.45
const STRIKE_REACH := 170.0
const LAYER_ONEWAY := 2

var control: TouchControl
var facing := 1.0
var state := "idle"              ## idle, run, skid, jump, fall, glide, wall, strike
var gliding := false
var on_wall := 0.0               ## -1 / 1: the wall side while sliding
var strike_t := 0.0
var land_squash := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _buffer_power := 1.0
var _leap_vx := INF               ## a leap's fixed air speed until it lands
var _drop_t := 0.0
var _wall_lock := 0.0
var _prev_air_vy := 0.0

## path pieces (docs/45 section 5): a vine he hangs on, a wind stream that lifts him, wall-runs up tree trunks, slides
var vine: Node = null              ## the vine he hangs on (it moves him)
var wind_lift := 0.0               ## upward push of a wind stream this step (set by the stream)
var wallrun_t := 0.0
var _wallrun_used := false
var _vine_cool := 0.0
const WALLRUN_TIME := 0.42
const WALLRUN_V := 640.0
const SLIDE_MAX := 860.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1 | (1 << (LAYER_ONEWAY - 1)) | 8
	floor_snap_length = 18.0
	floor_max_angle = deg_to_rad(46.0)
	floor_constant_speed = true
	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 26.0
	cap.height = 150.0
	shape.shape = cap
	shape.position = Vector2(0, -75)
	add_child(shape)
	add_to_group("hero")


func _physics_process(delta: float) -> void:
	var req: Dictionary = control.consume() if control else {"jump": 0.0, "jump_dir": 0.0, "leap": Vector2.INF, "drop": false, "strike": Vector2.INF}
	var run: float = control.run if control else 0.0
	var hold: bool = control.holding if control else false
	var grounded := is_on_floor()
	_coyote = COYOTE if grounded else maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)
	_wall_lock = maxf(0.0, _wall_lock - delta)
	strike_t = maxf(0.0, strike_t - delta)
	land_squash = maxf(0.0, land_squash - delta * 4.0)
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0:
			set_collision_mask_value(LAYER_ONEWAY, true)

	if float(req.jump) > 0.0:
		_buffer = BUFFER
		_buffer_power = float(req.jump)
		if float(req.jump_dir) != 0.0:
			facing = signf(float(req.jump_dir))
			run = float(req.jump_dir)
	if req.leap != Vector2.INF:
		_leap(req.leap, grounded)
	if bool(req.drop):
		if grounded:
			set_collision_mask_value(LAYER_ONEWAY, false)
			_drop_t = 0.25
			position.y += 2.0
		else:
			velocity.y = maxf(velocity.y, 900.0)
	if req.strike != Vector2.INF:
		_strike(req.strike)
	_vine_cool = maxf(0.0, _vine_cool - delta)

	# hanging on a vine: the vine swings him; a flick / tap lets go with the swing's speed (and a boost)
	if vine != null:
		state = "hang"
		if _buffer > 0.0 or req.leap != Vector2.INF or bool(req.drop):
			var v: Vector2 = vine.call("release_velocity")
			vine.call("let_go")
			vine = null
			_vine_cool = 0.35
			_buffer = 0.0
			if not bool(req.drop):
				velocity = v + Vector2(signf(v.x if absf(v.x) > 40.0 else facing) * 120.0, -620.0)
			else:
				velocity = v * 0.5
			facing = signf(velocity.x) if absf(velocity.x) > 20.0 else facing
			state = "jump"
			jumped.emit()
		else:
			vine.call("pump", run, delta)
			global_position = vine.call("grip_point")
			velocity = vine.call("release_velocity")
			if absf(velocity.x) > 30.0:
				facing = signf(velocity.x)
			return

	# horizontal
	if _leap_vx != INF and not grounded:
		velocity.x = move_toward(velocity.x, _leap_vx, AIR_ACCEL * 0.5 * delta)
	else:
		_leap_vx = INF
		var target := run * RUN_MAX
		var rate: float
		if grounded:
			if absf(run) < 0.05:
				rate = BRAKE
			elif signf(target) != signf(velocity.x) and absf(velocity.x) > 40.0:
				rate = TURN
			else:
				rate = ACCEL
		else:
			rate = AIR_ACCEL if absf(run) > 0.05 else AIR_ACCEL * 0.25
		if _wall_lock <= 0.0:
			velocity.x = move_toward(velocity.x, target, rate * delta)
	if absf(velocity.x) > 30.0:
		facing = signf(velocity.x)

	# wall-run: running hard into a tree trunk carries him up it for a moment (once until he lands again)
	if grounded:
		_wallrun_used = false
	if wallrun_t > 0.0:
		wallrun_t -= delta
		velocity.y = -WALLRUN_V
		if not is_on_wall() or absf(run) < 0.1:
			wallrun_t = 0.0
	elif is_on_wall() and not _wallrun_used and absf(run) > 0.6 and absf(velocity.x) > 10.0 and signf(run) == -signf(get_wall_normal().x):
		if grounded or velocity.y < 200.0:
			wallrun_t = WALLRUN_TIME
			_wallrun_used = true

	# walls (slide down, jump off)
	on_wall = 0.0
	if not grounded and is_on_wall() and velocity.y > 0.0:
		var n := get_wall_normal()
		if absf(run) > 0.1 and signf(run) == -signf(n.x):
			on_wall = -signf(n.x)
			velocity.y = minf(velocity.y, WALL_SLIDE)

	# jumping
	if _buffer > 0.0:
		if _coyote > 0.0:
			_do_jump(_buffer_power)
		elif on_wall != 0.0:
			_do_jump(1.0)
			velocity.x = -on_wall * WALL_KICK
			facing = -on_wall
			_wall_lock = 0.16
	# gravity: lighter going up, a floating apex, heavy falling; the cloak glides while the finger stays down
	var g := G_UP if velocity.y < 0.0 else G_DOWN
	if absf(velocity.y) < APEX_BAND and not grounded:
		g *= 0.5
	if wallrun_t <= 0.0:
		velocity.y += g * delta
	# a wind stream: lifts strongly while gliding, a little otherwise
	if wind_lift > 0.0 and not grounded:
		velocity.y -= wind_lift * (1.0 if hold else 0.45) * delta
		velocity.y = maxf(velocity.y, -720.0)
	wind_lift = 0.0
	gliding = not grounded and (velocity.y > 0.0 or wind_lift > 0.0) and hold and on_wall == 0.0 and wallrun_t <= 0.0
	if gliding:
		velocity.y = minf(velocity.y, GLIDE_FALL)
	# steep ground: he slides down it, faster than running (the slide slopes of the paths)
	if grounded and get_floor_angle() > deg_to_rad(24.0):
		var down := signf(get_floor_normal().x)
		if absf(run) < 0.05 or signf(run) == down:
			velocity.x = move_toward(velocity.x, down * SLIDE_MAX, 2600.0 * delta)
	velocity.y = minf(velocity.y, FALL_MAX)

	var was_air := not grounded
	_prev_air_vy = velocity.y
	move_and_slide()
	if was_air and is_on_floor():
		_leap_vx = INF
		land_squash = clampf(_prev_air_vy / 1400.0, 0.15, 1.0)
		landed.emit(_prev_air_vy)
	_update_state(run)


## Releasing the finger early cuts the jump (variable height).
func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and not event.pressed) or (event is InputEventKey and not event.pressed and event.keycode in [KEY_SPACE, KEY_UP]):
		if velocity.y < -200.0 and state == "jump" and _leap_vx == INF:
			velocity.y *= CUT


func _do_jump(power: float) -> void:
	velocity.y = -JUMP_V * lerpf(0.7, 1.0, power)
	_buffer = 0.0
	_coyote = 0.0
	state = "jump"
	jumped.emit()


## A leap to a tapped point: the arc is high enough to reach it (as far as a jump can) and lands on it.
func _leap(target: Vector2, grounded: bool) -> void:
	if not grounded and _coyote <= 0.0:
		# in the air: only turn toward it
		_leap_vx = clampf((target.x - global_position.x) * 1.6, -RUN_MAX * 1.1, RUN_MAX * 1.1)
		return
	var h := maxf(global_position.y - target.y, 40.0) + 50.0
	var vy := minf(sqrt(2.0 * G_UP * h * 0.82), JUMP_V)
	var t_up := vy / G_UP
	var apex := vy * vy / (2.0 * G_UP)
	var down := maxf(apex - (global_position.y - target.y), 10.0)
	var t := t_up + sqrt(2.0 * down / G_DOWN)
	var dx := target.x - global_position.x
	_leap_vx = clampf(dx / maxf(t, 0.25), -RUN_MAX * 1.1, RUN_MAX * 1.1)
	velocity.y = -vy
	velocity.x = _leap_vx * 0.8
	facing = signf(dx) if absf(dx) > 4.0 else facing
	_coyote = 0.0
	state = "jump"
	jumped.emit()


## Is there something to strike near this world point? (the touch control asks before leaping there)
func strike_target(world: Vector2) -> bool:
	for n in get_tree().get_nodes_in_group("strikeable"):
		if n.global_position.distance_to(world) < 90.0 and n.global_position.distance_to(global_position + Vector2(0, -60)) < STRIKE_REACH * 2.2:
			return true
	return false


func _strike(at: Vector2) -> void:
	facing = signf(at.x - global_position.x) if absf(at.x - global_position.x) > 4.0 else facing
	strike_t = 0.32
	struck.emit(at)
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("strikeable"):
		var d: float = n.global_position.distance_to(global_position + Vector2(facing * 60.0, -60))
		if d < STRIKE_REACH and d < best_d:
			best = n
			best_d = d
	if best == null:
		# out of reach: dash a little toward it
		velocity.x = facing * RUN_MAX * 1.2
		return
	best.hit(self)


## A bounce mushroom / flower throws him up.
func bounce(power: float) -> void:
	velocity.y = -power
	_coyote = 0.0
	_wallrun_used = false
	state = "jump"
	jumped.emit()


## A vine asks whether he can take it (in the air, not just let go).
func can_grab() -> bool:
	return vine == null and _vine_cool <= 0.0 and not is_on_floor()


func _update_state(run: float) -> void:
	if strike_t > 0.0:
		state = "strike"
	elif wallrun_t > 0.0:
		state = "wallrun"
	elif is_on_floor() and get_floor_angle() > deg_to_rad(24.0) and absf(velocity.x) > 300.0:
		state = "slide"
	elif is_on_floor():
		if absf(velocity.x) < 30.0:
			state = "idle"
		elif absf(run) < 0.05 or signf(run) != signf(velocity.x):
			state = "skid"
		else:
			state = "run"
	elif on_wall != 0.0:
		state = "wall"
	elif gliding:
		state = "glide"
	elif velocity.y < 0.0:
		state = "jump"
	else:
		state = "fall"
