class_name Water
extends Area2D
## Water that may flow in only one time. Touching flowing water sends the hero back to the
## last checkpoint (no lives lost). In the other time a dry, cracked bed is drawn instead.

var cells := 1
var active_mask := 3
var surface := true
var game: Node
var palette: Dictionary = {}
var size := Vector2(64, 64)

var _presence := 1.0
var _t := 0.0
var _hint := 0.0
var _warn := 0.0
var _tween: Tween
var _babble: AudioStreamPlayer2D


func _ready() -> void:
	size = Vector2(cells * 64, 64)
	z_index = 3
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size - Vector2(8, 20)
	shape.shape = rect
	shape.position = size * 0.5 + Vector2(0, 10)
	add_child(shape)
	add_to_group("time_hazard")
	add_to_group("time_visual")
	_add_babble()
	TimeShift.time_changed.connect(_on_time_changed)
	_on_time_changed(TimeShift.state, true)


## A positional stream sound on the water surface; it fades with the water when time changes.
func _add_babble() -> void:
	const PATH := "res://assets/audio/ambient/stream.ogg"
	if not surface or not ResourceLoader.exists(PATH):
		return
	var stream: AudioStream = load(PATH)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_babble = AudioStreamPlayer2D.new()
	_babble.stream = stream
	_babble.bus = "Ambient"
	_babble.position = Vector2(size.x * 0.5, 20)
	_babble.max_distance = 900.0
	_babble.attenuation = 1.6
	add_child(_babble)
	_babble.play(randf() * 10.0)


func is_active_in(state: int) -> bool:
	return (active_mask & (1 << state)) != 0


func get_world_rect() -> Rect2:
	return Rect2(global_position + Vector2(4, 20), size - Vector2(8, 20))


func flash_warning() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_warn", 1.0, 0.1)
	tween.tween_property(self, "_warn", 0.0, 0.7)


func hint_flash(pos: Vector2, radius: float) -> void:
	if get_world_rect().get_center().distance_to(pos) > radius:
		return
	var tween := create_tween()
	for i in 3:
		tween.tween_property(self, "_hint", 1.0, 0.25)
		tween.tween_property(self, "_hint", 0.0, 0.35)


func _on_time_changed(state: int, instant: bool) -> void:
	var on := is_active_in(state)
	if _tween:
		_tween.kill()
	if instant:
		_presence = 1.0 if on else 0.0
	else:
		_tween = create_tween()
		_tween.tween_property(self, "_presence", 1.0 if on else 0.0, 0.4)


func _physics_process(_delta: float) -> void:
	if game == null or not is_active_in(TimeShift.state):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			game.on_hazard("water")
			return


func _process(delta: float) -> void:
	_t += delta
	if _babble:
		_babble.volume_db = linear_to_db(maxf(_presence, 0.001)) - 3.0
	queue_redraw()


func _draw() -> void:
	var water: Color = palette.get("water", Color("3d9be0"))
	var p := _presence
	if p > 0.01:
		var top := 10.0 if surface else 0.0
		draw_rect(Rect2(0, top, size.x, size.y - top), Color(water, 0.72 * p))
		if surface:
			var wave := PackedVector2Array()
			for i in int(size.x / 8.0) + 1:
				var x := i * 8.0
				wave.append(Vector2(x, top + sin(_t * 3.0 + (global_position.x + x) * 0.05) * 4.0))
			draw_polyline(wave, Color(1, 1, 1, 0.8 * p), 4.0)
			for i in cells:
				var x := i * 64.0 + fmod(_t * 30.0 + i * 23.0, 64.0)
				draw_line(Vector2(x, top + 20), Vector2(x + 14, top + 20), Color(1, 1, 1, 0.35 * p), 3.0)
	var g := 1.0 - p
	if g > 0.01 and surface:
		var dry := Color(0.45, 0.3, 0.18, 0.45 * g)
		for i in cells:
			var x := i * 64.0
			draw_line(Vector2(x + 10, 56), Vector2(x + 26, 46), dry, 3.0)
			draw_line(Vector2(x + 26, 46), Vector2(x + 44, 54), dry, 3.0)
			draw_line(Vector2(x + 44, 54), Vector2(x + 58, 44), dry, 3.0)
		draw_dashed_line(Vector2(0, 10), Vector2(size.x, 10), Color(0.6, 0.85, 1.0, 0.6 * g), 3.0, 10.0)
	if _warn > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size).grow(3.0), Color(1.0, 0.25, 0.2, _warn), false, 6.0)
	if _hint > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size).grow(6.0), Color(1.0, 0.95, 0.4, _hint), false, 5.0)
