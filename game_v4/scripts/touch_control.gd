class_name TouchControl
extends Node
## The finger controls (owner's order, docs/45 section 3). No joystick, no auto-run; one finger anywhere:
##   rub / drag left or right      -> walk / run that way (speed follows how actively the finger moves)
##   quick flick upward            -> jump (up-right / up-left = jump that way; a longer flick jumps higher)
##   tap above the hero            -> leap toward that point (a ledge, a platform, over an obstacle)
##   tap below the hero / flick down -> go down (through a thin platform, off a ledge, slide)
##   keep the finger down in the air -> open the cloak / scarf and glide
##   tap on an enemy or a cage     -> strike it
## The hero reads: `run` (-1..1), and one-shot requests: `jump_power` (0..1, with `jump_dir`), `leap_to` (world point),
## `drop`, `strike_at` (world point); `holding` is true while a finger is down.
## Keyboard (developer only): arrows move, Space/Up jump, Down drop, X strike.

signal tapped(world: Vector2)

const FLICK_SPEED := 900.0          ## px/s upward on the screen for a flick
const FLICK_MIN := 46.0             ## px of upward travel
const TAP_TIME := 0.22
const TAP_MOVE := 22.0
const RUB_FULL := 650.0             ## finger speed (px/s) for a full run
const RUB_DECAY := 2.6              ## how fast running fades when the finger rests (per s)
const HOLD_RUN := 0.7               ## a finger resting far to one side keeps running at this much
const HOLD_FAR := 90.0

var hero: Node2D
var camera: Camera2D

var run := 0.0
var holding := false
var jump_power := 0.0
var jump_dir := 0.0
var leap_to := Vector2.INF
var drop := false
var strike_at := Vector2.INF

var _finger := -1
var _start := Vector2.ZERO
var _start_t := 0.0
var _last := Vector2.ZERO
var _last_t := 0.0
var _vel := Vector2.ZERO
var _activity := 0.0
var _dir := 0.0
var _flicked := false
var _moved := false
var trail: Array = []                ## recent finger points on screen (for the light trail)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_finger = event.index
			_start = event.position
			_last = event.position
			_start_t = _now()
			_last_t = _start_t
			_vel = Vector2.ZERO
			_flicked = false
			_moved = false
			holding = true
			trail = [event.position]
		elif not event.pressed and event.index == _finger:
			var dt := _now() - _start_t
			if not _moved and not _flicked and dt < TAP_TIME and event.position.distance_to(_start) < TAP_MOVE:
				_tap(event.position)
			_finger = -1
			holding = false
			trail.clear()
	elif event is InputEventScreenDrag and event.index == _finger:
		var t := _now()
		var dt := maxf(t - _last_t, 0.001)
		var v: Vector2 = (event.position - _last) / dt
		_vel = _vel.lerp(v, 0.5)
		_last = event.position
		_last_t = t
		trail.append(event.position)
		if trail.size() > 14:
			trail.pop_front()
		if event.position.distance_to(_start) > TAP_MOVE:
			_moved = true
		# a flick upward: fast and long enough, once per stroke
		var up: float = _start.y - event.position.y
		if not _flicked and _vel.y < -FLICK_SPEED and up > FLICK_MIN and absf(_vel.y) > absf(_vel.x) * 0.8:
			_flicked = true
			jump_power = clampf(0.55 + up / 260.0, 0.55, 1.0)
			jump_dir = clampf(_vel.x / 900.0, -1.0, 1.0) if absf(_vel.x) > 250.0 else 0.0
		# a flick downward
		elif not _flicked and _vel.y > FLICK_SPEED and event.position.y - _start.y > FLICK_MIN and absf(_vel.y) > absf(_vel.x):
			_flicked = true
			drop = true
		# rubbing sideways: the hero goes the way the finger is (from where it went down), as long as it keeps moving
		var side: float = event.position.x - _start.x
		if absf(side) > 14.0:
			_dir = signf(side)
		if absf(v.x) > 40.0:
			_activity = clampf(_activity + absf(v.x) * dt / (RUB_FULL * 0.18), 0.0, 1.0)
		# a stroke back the other way while far out restarts the reference point (rubbing back and forth)
		if absf(side) > 160.0:
			_start.x = event.position.x - signf(side) * 120.0


func _tap(screen: Vector2) -> void:
	var world := _to_world(screen)
	tapped.emit(world)
	if hero == null:
		return
	if hero.has_method("strike_target") and hero.strike_target(world):
		strike_at = world
		return
	var feet: Vector2 = hero.global_position
	if world.y < feet.y - 70.0:
		leap_to = world
	elif world.y > feet.y + 40.0:
		drop = true
		_dir = signf(world.x - feet.x) if absf(world.x - feet.x) > 60.0 else 0.0
	else:
		leap_to = world              # level with the hero: a short hop toward that spot


func _process(delta: float) -> void:
	# keyboard for the developer
	var key := Input.get_axis("ui_left", "ui_right")
	if key != 0.0:
		run = key
	elif _finger == -1:
		_activity = maxf(0.0, _activity - delta * RUB_DECAY * 1.6)
		run = _dir * _activity
		if _activity <= 0.0:
			_dir = 0.0
	else:
		_activity = maxf(0.0, _activity - delta * RUB_DECAY)
		var held := 0.0
		if absf(_last.x - _start.x) > HOLD_FAR:
			held = HOLD_RUN
		run = _dir * maxf(_activity, held)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
		jump_power = 1.0
		jump_dir = 0.0
	if Input.is_action_just_pressed("ui_down"):
		drop = true
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_UP):
		holding = true
	elif _finger == -1:
		holding = false
	if Input.is_physical_key_pressed(KEY_X) and hero:
		strike_at = hero.global_position + Vector2(hero.facing * 80.0, -60.0)


## Takes the one-shot requests (the hero calls this once per physics step).
func consume() -> Dictionary:
	var out := {"jump": jump_power, "jump_dir": jump_dir, "leap": leap_to, "drop": drop, "strike": strike_at}
	jump_power = 0.0
	leap_to = Vector2.INF
	drop = false
	strike_at = Vector2.INF
	return out


func _to_world(screen: Vector2) -> Vector2:
	if camera == null:
		return screen
	return camera.get_canvas_transform().affine_inverse() * screen


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
