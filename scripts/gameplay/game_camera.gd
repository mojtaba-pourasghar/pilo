class_name GameCamera
extends Camera2D
## Follows Nima with a look-ahead in the running direction (so at speed you see what is
## coming) and a short shake for heavy landings and crushers.

const LOOK_AHEAD := 0.32
const LOOK_MAX := 220.0

var target: CharacterBody2D
var _shake := 0.0
var _look := 0.0
var _trauma := 0.0
var _punch := 0.0
var _noise := FastNoiseLite.new()
var _time := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	drag_vertical_enabled = true
	drag_top_margin = 0.25
	drag_bottom_margin = 0.15
	ignore_rotation = false
	_noise.frequency = 3.0


func _process(delta: float) -> void:
	if target:
		var want := clampf(target.velocity.x * LOOK_AHEAD, -LOOK_MAX, LOOK_MAX)
		_look = lerpf(_look, want, 1.0 - exp(-2.5 * delta))
	_shake = maxf(0.0, _shake - delta * 30.0)
	# trauma shake: smooth noise, grows with trauma squared, a little roll for big hits
	_time += delta
	_trauma = maxf(0.0, _trauma - delta * 1.6)
	var amount := _trauma * _trauma
	var wobble := Vector2(_noise.get_noise_2d(_time * 60.0, 0.0), _noise.get_noise_2d(0.0, _time * 60.0)) * 38.0 * amount
	offset = Vector2(_look, -40.0) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake + wobble
	rotation = _noise.get_noise_2d(_time * 40.0, 99.0) * 0.05 * amount
	_punch = move_toward(_punch, 0.0, delta * 0.6)
	# taller screens (tablets, 4:3) show more of the level above and below: zoom in a little
	# so Nima stays as big as on a phone
	var view := get_viewport().get_visible_rect().size
	var base := sqrt(maxf(1.0, view.y / 720.0))
	zoom = Vector2.ONE * (base + _punch)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
	add_trauma(amount / 14.0)


func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)
	_punch = maxf(_punch, amount * 0.04)
