extends Camera2D
## Side-scroller camera (docs/45 section 4): the hero sits about 30% from the side he runs from, with a soft
## look-ahead; vertically it follows calmly and settles on the ground level after a landing (no bobbing with every
## jump); a short shake on hard landings.

var hero: HeroBody
var _ahead := 0.0
var _ground_y := 0.0
var _shake := 0.0


func _ready() -> void:
	zoom = Vector2(0.9, 0.9)
	position_smoothing_enabled = false
	make_current()
	snap()


func snap() -> void:
	if hero:
		_ground_y = hero.global_position.y
		global_position = _target()


func shake(px: float) -> void:
	_shake = maxf(_shake, px)


func _target() -> Vector2:
	var view := get_viewport_rect().size / zoom
	return Vector2(hero.global_position.x + _ahead, _ground_y - view.y * 0.12)


func _process(delta: float) -> void:
	if hero == null:
		return
	var view := get_viewport_rect().size / zoom
	# look ahead in the running direction: the hero ends up ~30% from the trailing side
	var want := hero.facing * view.x * 0.2 if absf(hero.velocity.x) > 60.0 else _ahead * 0.98
	_ahead = lerpf(_ahead, want, 1.0 - exp(-delta * 2.2))
	# vertical: follow the ground the hero stands on; in the air only when he leaves the comfortable band
	if hero.is_on_floor():
		_ground_y = lerpf(_ground_y, hero.global_position.y, 1.0 - exp(-delta * 5.0))
	else:
		var top := _ground_y - view.y * 0.42
		var bottom := _ground_y + view.y * 0.12
		if hero.global_position.y < top:
			_ground_y += (hero.global_position.y - top) * (1.0 - exp(-delta * 6.0))
		elif hero.global_position.y > bottom:
			_ground_y += (hero.global_position.y - bottom) * (1.0 - exp(-delta * 8.0))
	var goal := _target()
	global_position = global_position.lerp(goal, 1.0 - exp(-delta * 7.0))
	_shake = maxf(0.0, _shake - delta * 30.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
