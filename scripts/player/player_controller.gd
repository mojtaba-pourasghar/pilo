extends CharacterBody2D
## Hero movement tuned for small hands: forgiving jump timing (coyote time and jump
## buffer), variable jump height and squash-and-stretch feedback instead of sprite sheets.

signal jumped
signal landed

const BODY_SIZE := Vector2(40, 84)
const SPEED := 330.0
const GROUND_ACCEL := 2600.0
const AIR_ACCEL := 1800.0
const FRICTION := 3200.0
const GRAVITY := 2000.0
const JUMP_VELOCITY := -830.0
const JUMP_CUT := -320.0
const SPRING_VELOCITY := -1250.0
const MAX_FALL := 1100.0
const COYOTE_TIME := 0.14
const JUMP_BUFFER := 0.16
const FEET := 42.0

var controls_enabled := true
var facing := 1.0

var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false
var _was_on_floor := true
var _run_phase := 0.0
var _squash := Vector2.ONE
var _emote: Label

@onready var visual: Node2D = $Visual


func _ready() -> void:
	z_index = 4
	_emote = UIKit.make_label("!", 48, UIKit.RED, 10, Color.WHITE)
	_emote.size = Vector2(80, 60)
	_emote.position = Vector2(-40, -130)
	_emote.visible = false
	add_child(_emote)


func _physics_process(delta: float) -> void:
	var dir := 0.0
	if controls_enabled:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_buffer = JUMP_BUFFER
	_buffer -= delta
	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	var accel := FRICTION
	if dir != 0.0:
		accel = GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		# A buffered tap that was already released still gets a full jump (no tiny hop).
		_jump_held = controls_enabled and Input.is_action_pressed("jump")
		_squash = Vector2(0.78, 1.22)
		jumped.emit()
	if _jump_held and (not controls_enabled or not Input.is_action_pressed("jump")):
		_jump_held = false
		velocity.y = maxf(velocity.y, JUMP_CUT)
	if velocity.y >= 0.0:
		_jump_held = false

	move_and_slide()
	_check_springs()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		_squash = Vector2(1.25, 0.8)
		landed.emit()
	_was_on_floor = on_floor
	if dir != 0.0:
		facing = signf(dir)
	_animate(delta, on_floor)


func _check_springs() -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider()
		if body is Node and body.is_in_group("spring") and hit.get_normal().y < -0.6:
			velocity.y = SPRING_VELOCITY
			_jump_held = false
			_squash = Vector2(0.7, 1.3)
			body.call("boing")
			AudioManager.play_sfx("bounce")
			return


func _animate(delta: float, on_floor: bool) -> void:
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, 10.0 * delta))
	var bob := 0.0
	var tilt := 0.0
	if on_floor and absf(velocity.x) > 30.0:
		var before := int(_run_phase / PI)
		_run_phase += delta * 15.0
		if int(_run_phase / PI) != before:
			AudioManager.play_sfx("step", randf_range(0.9, 1.12), -10.0)
		bob = -absf(sin(_run_phase)) * 7.0
		tilt = 0.08 * signf(velocity.x)
	elif not on_floor:
		tilt = clampf(velocity.x / SPEED, -1.0, 1.0) * 0.12
		_run_phase = 0.0
	visual.scale = Vector2(facing * _squash.x, _squash.y)
	visual.position.y = FEET + bob
	visual.rotation = lerpf(visual.rotation, tilt, minf(1.0, 12.0 * delta))


func get_body_rect() -> Rect2:
	return Rect2(global_position - BODY_SIZE * 0.5, BODY_SIZE)


## Small hop with a "!" when the time lens refuses to work here.
func react_surprise() -> void:
	_show_emote("!", UIKit.RED)
	_squash = Vector2(1.2, 0.85)


func celebrate() -> void:
	_show_emote("!!", UIKit.GREEN)
	var tween := create_tween()
	for i in 2:
		tween.tween_property(visual, "position:y", FEET - 40.0, 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "position:y", FEET, 0.18).set_ease(Tween.EASE_IN)
	FX.burst(get_parent(), global_position + Vector2(0, -40), UIKit.GOLD, 24)


func respawn(pos: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	await tween.finished
	global_position = pos
	velocity = Vector2.ZERO
	_buffer = 0.0
	_jump_held = false
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.reset_smoothing()
	tween = create_tween()
	tween.tween_property(visual, "modulate:a", 1.0, 0.25)
	await tween.finished


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
