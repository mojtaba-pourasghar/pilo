class_name GameCamera
extends Camera2D
## Follows Nima with a look-ahead in the running direction (so at speed you see what is
## coming) and a short shake for heavy landings and crushers.

const LOOK_AHEAD := 0.32
const LOOK_MAX := 220.0

var target: CharacterBody2D
var _shake := 0.0
var _look := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	drag_vertical_enabled = true
	drag_top_margin = 0.25
	drag_bottom_margin = 0.15


func _process(delta: float) -> void:
	if target:
		var want := clampf(target.velocity.x * LOOK_AHEAD, -LOOK_MAX, LOOK_MAX)
		_look = lerpf(_look, want, 1.0 - exp(-2.5 * delta))
	_shake = maxf(0.0, _shake - delta * 30.0)
	offset = Vector2(_look, -40.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
