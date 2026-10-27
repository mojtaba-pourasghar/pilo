extends Node2D
## Pilo floats beside the hero, glows in the color of the current time and flies to
## hint spots. Pilo points at clues but never says the answer.

const PAST_GLOW := Color(1.0, 0.72, 0.3)
const PRESENT_GLOW := Color(0.4, 0.9, 1.0)
const HINT_TIME := 4.0

var target: Node2D

var _t := 0.0
var _glow := PRESENT_GLOW
var _hint_pos := Vector2.ZERO
var _hint_left := 0.0
var _base_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	z_index = 6
	_base_scale = sprite.scale


func _process(delta: float) -> void:
	_t += delta
	var goal := global_position
	if _hint_left > 0.0:
		_hint_left -= delta
		goal = _hint_pos + Vector2(0, -36.0 + sin(_t * 7.0) * 10.0)
	elif target:
		var facing: float = target.facing
		goal = target.global_position + Vector2(-64.0 * facing, -78.0 + sin(_t * 3.0) * 8.0)
	global_position = global_position.lerp(goal, 1.0 - exp(-5.0 * delta))
	var dx := goal.x - global_position.x
	if absf(dx) > 6.0:
		sprite.flip_h = dx < 0.0
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_t * 4.0) * 0.08
	draw_circle(Vector2.ZERO, 46.0 * pulse, Color(_glow, 0.16))
	draw_circle(Vector2.ZERO, 32.0 * pulse, Color(_glow, 0.22))
	if _hint_left > 0.0:
		for i in 6:
			var angle := _t * 2.5 + i * TAU / 6.0
			draw_circle(Vector2(cos(angle), sin(angle)) * 60.0, 6.0, Color(1, 0.95, 0.5, 0.9))


func on_time_changed(state: int, instant: bool) -> void:
	_glow = PAST_GLOW if state == TimeShift.PAST else PRESENT_GLOW
	if instant:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "scale", _base_scale * 1.35, 0.15)
	tween.parallel().tween_property(sprite, "rotation", TAU, 0.45).from(0.0)
	tween.tween_property(sprite, "scale", _base_scale, 0.2)
	tween.tween_callback(func(): sprite.rotation = 0.0)


## Head shake: "not here".
func shake() -> void:
	var tween := create_tween()
	for angle in [-0.3, 0.3, -0.2, 0.2, 0.0]:
		tween.tween_property(sprite, "rotation", angle, 0.07)


func show_hint(pos: Vector2) -> void:
	_hint_pos = pos
	_hint_left = HINT_TIME
	AudioManager.play_sfx("star", 1.4)


func apply_color(color_id: String) -> void:
	var entry: Dictionary = StoreAdapter.PILO_COLORS.get(color_id, StoreAdapter.PILO_COLORS.classic)
	var material := sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("hue_shift", float(entry.hue))
