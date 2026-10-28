class_name TimeBlock
extends StaticBody2D
## A horizontal run of tiles that may exist in only one time. Both looks are drawn so the
## child can compare: the missing version stays visible as a faint "ghost" outline.

enum Kind { GROUND, ROCK, PLANK, BRIDGE, VINE }

const TILE := 64.0
const THIN := 20.0

var kind: int = Kind.GROUND
var cells := 1
var active_mask := 3
var caps: Array = []
var palette: Dictionary = {}
var size := Vector2(TILE, TILE)

var _shape: CollisionShape2D
var _presence := 1.0
var _warn := 0.0
var _hint := 0.0
var _tween: Tween


func _ready() -> void:
	size = Vector2(cells * TILE, TILE)
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	if is_one_way():
		rect.size = Vector2(size.x, THIN)
		_shape.position = Vector2(size.x * 0.5, THIN * 0.5)
		_shape.one_way_collision = true
	else:
		rect.size = size
		_shape.position = size * 0.5
	_shape.shape = rect
	add_child(_shape)
	set_process(active_mask != 3)
	if active_mask != 3:
		add_to_group("time_solid")
		add_to_group("time_visual")
		TimeShift.time_changed.connect(_on_time_changed)
		_on_time_changed(TimeShift.state, true)


func is_one_way() -> bool:
	return kind == Kind.PLANK or kind == Kind.BRIDGE or kind == Kind.VINE


func exists_in(state: int) -> bool:
	return (active_mask & (1 << state)) != 0


## One-way platforms never trap the hero, so only full blocks can veto a time shift.
func is_solid_in(state: int) -> bool:
	return exists_in(state) and not is_one_way()


func get_world_rect() -> Rect2:
	return Rect2(global_position, size)


func flash_warning() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_warn", 1.0, 0.1)
	tween.tween_property(self, "_warn", 0.2, 0.25)
	tween.tween_property(self, "_warn", 1.0, 0.1)
	tween.tween_property(self, "_warn", 0.0, 0.5)


## Called by the hint system: pulses the outline of nearby time pieces.
func hint_flash(pos: Vector2, radius: float) -> void:
	if get_world_rect().get_center().distance_to(pos) > radius:
		return
	var tween := create_tween()
	for i in 3:
		tween.tween_property(self, "_hint", 1.0, 0.25)
		tween.tween_property(self, "_hint", 0.0, 0.35)


func _on_time_changed(state: int, instant: bool) -> void:
	var on := exists_in(state)
	_shape.set_deferred("disabled", not on)
	if _tween:
		_tween.kill()
	if instant:
		_presence = 1.0 if on else 0.0
	else:
		_tween = create_tween()
		_tween.tween_property(self, "_presence", 1.0 if on else 0.0, 0.35)
		_play_change_sound(on)
	queue_redraw()


## The world answers the time lens: vines rustle as they grow, rocks rumble, bridges creak.
## Only pieces on screen make a sound, and each kind once per shift.
func _play_change_sound(appearing: bool) -> void:
	var screen := get_viewport().get_visible_rect().grow(64.0)
	var on_screen := Rect2(get_global_transform_with_canvas().origin, size)
	if not screen.intersects(on_screen):
		return
	match kind:
		Kind.VINE:
			AudioManager.play_sfx_once("grow" if appearing else "rustle", 0.3)
		Kind.ROCK:
			AudioManager.play_sfx_once("rumble", 0.3, 1.0 if appearing else 1.2, -2.0)
		Kind.BRIDGE:
			AudioManager.play_sfx_once("creak", 0.3, 1.0 if appearing else 0.8)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var ghost := 1.0 - _presence
	match kind:
		Kind.GROUND:
			_draw_ground()
		Kind.ROCK:
			_draw_ghost_outline(Rect2(Vector2.ZERO, size), ghost)
			match _theme():
				"sky_islands":
					_draw_wisps(ghost)
					_draw_storm_clouds(_presence)
				"crystal_caves":
					_draw_rubble(ghost)
					_draw_crystal_cluster(_presence)
				_:
					_draw_rubble(ghost)
					_draw_rocks(_presence)
		Kind.PLANK:
			_draw_plank()
		Kind.BRIDGE:
			_draw_ghost_outline(Rect2(0, 0, size.x, THIN), ghost)
			if _theme() == "sky_islands":
				_draw_energy_bridge(_presence)
			else:
				_draw_broken_bridge(ghost)
				_draw_bridge(_presence)
		Kind.VINE:
			_draw_ghost_outline(Rect2(0, 0, size.x, THIN), ghost)
			match _theme():
				"sky_islands":
					_draw_wisps(ghost * 0.6)
					_draw_cloud_shelf(_presence)
				"crystal_caves":
					_draw_sprouts(ghost)
					_draw_crystal_shelf(_presence)
				_:
					_draw_sprouts(ghost)
					_draw_vine(_presence)
	var outline := Rect2(Vector2.ZERO, size) if not is_one_way() else Rect2(0, 0, size.x, THIN)
	if _warn > 0.01:
		draw_rect(outline.grow(4.0), Color(1.0, 0.25, 0.2, _warn), false, 6.0)
	if _hint > 0.01:
		draw_rect(outline.grow(7.0), Color(1.0, 0.95, 0.4, _hint), false, 5.0)


func _c(key: String, alpha := 1.0) -> Color:
	var color: Color = palette.get(key, Color.MAGENTA)
	return Color(color, color.a * alpha)


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _c("dirt"))
	var row := int(global_position.y / TILE)
	for i in cells:
		var seed := int(global_position.x / TILE) + i + row * 7
		var ox := float((seed * 37) % 40) + 12.0
		var oy := float((seed * 23) % 30) + 18.0
		draw_circle(Vector2(i * TILE + ox, oy), 6.0, _c("dirt_dark"))
		draw_circle(Vector2(i * TILE + fmod(ox + 25.0, 52.0) + 6.0, fmod(oy + 22.0, 44.0) + 12.0), 4.0, _c("dirt_dark"))
	for i in caps.size():
		if caps[i]:
			var x := i * TILE
			draw_rect(Rect2(x, 0, TILE, 16), _c("grass"))
			for k in 4:
				draw_circle(Vector2(x + 8 + k * 16, 16), 9.0, _c("grass"))
			draw_rect(Rect2(x, 0, TILE, 5), _c("grass_light"))


func _draw_rocks(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var center := Vector2(i * TILE + 32, 33)
		draw_circle(center, 31.0, _c("rock_dark", alpha))
		draw_circle(center + Vector2(-2, -3), 28.0, _c("rock", alpha))
		draw_circle(center + Vector2(-10, -12), 9.0, Color(1, 1, 1, 0.35 * alpha))
		draw_line(center + Vector2(4, -6), center + Vector2(12, 8), _c("rock_dark", alpha), 3.0)
		draw_line(center + Vector2(12, 8), center + Vector2(6, 18), _c("rock_dark", alpha), 3.0)


func _draw_rubble(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var x := i * TILE
		draw_circle(Vector2(x + 18, 56), 7.0, _c("rock", 0.8 * alpha))
		draw_circle(Vector2(x + 40, 58), 6.0, _c("rock_dark", 0.8 * alpha))
		draw_circle(Vector2(x + 30, 52), 4.0, _c("rock", 0.8 * alpha))


func _draw_plank() -> void:
	draw_rect(Rect2(0, 2, size.x, 16), _c("wood"))
	draw_rect(Rect2(0, 14, size.x, 5), _c("wood_dark"))
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 3), Vector2(x, 17), _c("wood_dark"), 2.0)
		draw_circle(Vector2(x + 16, 9), 2.0, _c("wood_dark"))


func _draw_bridge(alpha: float) -> void:
	if alpha <= 0.01:
		return
	var rope := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		rope.append(Vector2(t * size.x, -18.0 + sin(t * PI) * 8.0))
	draw_polyline(rope, _c("wood_dark", alpha), 3.0)
	for x in range(0, int(size.x), 32):
		draw_rect(Rect2(x + 2, 2, 28, 15), _c("wood", alpha))
		draw_rect(Rect2(x + 2, 13, 28, 4), _c("wood_dark", alpha))
		draw_line(Vector2(x + 16, 2), Vector2(x + 16, -12.0 + sin((x + 16) / size.x * PI) * 8.0), _c("wood_dark", alpha), 2.0)
	draw_rect(Rect2(-5, -26, 9, 46), _c("wood_dark", alpha))
	draw_rect(Rect2(size.x - 4, -26, 9, 46), _c("wood_dark", alpha))


func _draw_broken_bridge(alpha: float) -> void:
	if alpha <= 0.01:
		return
	draw_rect(Rect2(-5, -26, 9, 46), _c("wood_dark", alpha))
	draw_rect(Rect2(size.x - 4, -26, 9, 46), _c("wood_dark", alpha))
	draw_set_transform(Vector2(4, 4), 0.5, Vector2.ONE)
	draw_rect(Rect2(0, 0, 28, 14), _c("wood", alpha))
	draw_set_transform(Vector2(size.x - 6, 4), PI - 0.5, Vector2.ONE)
	draw_rect(Rect2(0, -14, 28, 14), _c("wood", alpha))
	draw_set_transform(Vector2.ZERO)


func _draw_vine(alpha: float) -> void:
	if alpha <= 0.01:
		return
	draw_rect(Rect2(0, 6, size.x, 14), _c("vine_dark", alpha))
	for x in range(8, int(size.x), 16):
		draw_circle(Vector2(x, 8), 10.0, _c("vine", alpha))
	draw_line(Vector2(0, 19), Vector2(size.x, 19), _c("vine_dark", alpha), 3.0)
	for x in range(20, int(size.x), 48):
		draw_circle(Vector2(x, 2), 5.0, _c("flower", alpha))
		draw_circle(Vector2(x, 2), 2.0, Color(1, 1, 0.7, alpha))
	for x in range(10, int(size.x), 40):
		draw_line(Vector2(x, 19), Vector2(x - 4, 38), _c("vine_dark", alpha), 3.0)


func _draw_sprouts(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var base := Vector2(i * TILE + 32, 18)
		draw_line(base, base + Vector2(0, -14), _c("vine_dark", alpha), 3.0)
		draw_circle(base + Vector2(-6, -14), 5.0, _c("vine", alpha))
		draw_circle(base + Vector2(6, -16), 5.0, _c("vine", alpha))
		draw_circle(base + Vector2(0, 2), 5.0, Color(0.55, 0.38, 0.2, alpha))


func _draw_ghost_outline(rect: Rect2, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var color := Color(1, 1, 1, 0.55 * alpha)
	var a := rect.position
	var b := Vector2(rect.end.x, rect.position.y)
	var c := rect.end
	var d := Vector2(rect.position.x, rect.end.y)
	draw_dashed_line(a, b, color, 3.0, 10.0)
	draw_dashed_line(b, c, color, 3.0, 10.0)
	draw_dashed_line(c, d, color, 3.0, 10.0)
	draw_dashed_line(d, a, color, 3.0, 10.0)


# --- world looks (palette.theme) -------------------------------------------

func _theme() -> String:
	return String(palette.get("theme", "forest"))


## Sky: a dark puffy storm cloud that blocks the way (past only).
func _draw_storm_clouds(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var x := i * 64.0
		for p in [Vector2(18, 38), Vector2(46, 38), Vector2(32, 22), Vector2(14, 22), Vector2(50, 20)]:
			draw_circle(Vector2(x, 0) + p, 20.0, Color(0.42, 0.45, 0.58, alpha))
		draw_circle(Vector2(x + 26, 18), 10.0, Color(0.62, 0.66, 0.78, alpha))
		draw_line(Vector2(x + 30, 42), Vector2(x + 24, 56), Color(1, 0.9, 0.4, alpha), 3.0)
		draw_line(Vector2(x + 24, 56), Vector2(x + 32, 56), Color(1, 0.9, 0.4, alpha), 3.0)


## Sky: a few thin mist wisps where a cloud will be (or was).
func _draw_wisps(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var x := i * 64.0
		draw_line(Vector2(x + 8, 12), Vector2(x + 40, 12), Color(1, 1, 1, 0.45 * alpha), 3.0)
		draw_line(Vector2(x + 24, 20), Vector2(x + 56, 20), Color(1, 1, 1, 0.35 * alpha), 3.0)


## Sky: a soft white cloud you can stand on (present only).
func _draw_cloud_shelf(alpha: float) -> void:
	if alpha <= 0.01:
		return
	draw_rect(Rect2(6, 8, size.x - 12, 14), Color(0.86, 0.92, 1.0, alpha))
	for x in range(10, int(size.x), 18):
		draw_circle(Vector2(x, 10), 12.0, Color(1, 1, 1, alpha))
	draw_line(Vector2(8, 22), Vector2(size.x - 8, 22), Color(0.7, 0.8, 0.95, alpha), 3.0)


## Sky: a glowing band of light, the energy bridge (past only).
func _draw_energy_bridge(alpha: float) -> void:
	var rainbow := [Color("ff8fb1"), Color("ffd166"), Color("7fd65a"), Color("7cc8f5")]
	if alpha > 0.01:
		for i in rainbow.size():
			draw_rect(Rect2(0, 3 + i * 4, size.x, 4), Color(rainbow[i], 0.85 * alpha))
		draw_rect(Rect2(0, 2, size.x, 2), Color(1, 1, 1, 0.8 * alpha))
	draw_circle(Vector2(0, 10), 10.0, Color("ffd166"))
	draw_circle(Vector2(size.x, 10), 10.0, Color("ffd166"))
	draw_circle(Vector2(0, 10), 5.0, Color(1, 1, 1, 0.5 + 0.5 * alpha))
	draw_circle(Vector2(size.x, 10), 5.0, Color(1, 1, 1, 0.5 + 0.5 * alpha))


## Caves: a cluster of crystals that blocks the way (past only).
func _draw_crystal_cluster(alpha: float) -> void:
	if alpha <= 0.01:
		return
	for i in cells:
		var x := i * 64.0
		for spike in [[14.0, 64.0, 46.0], [32.0, 64.0, 60.0], [50.0, 64.0, 42.0]]:
			var cx: float = x + spike[0]
			var tip: float = spike[1] - spike[2]
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 11, 64), Vector2(cx, tip), Vector2(cx + 11, 64)]),
				_c("rock", alpha))
			draw_line(Vector2(cx, tip + 4), Vector2(cx - 4, 60), Color(1, 1, 1, 0.45 * alpha), 2.0)


## Caves: a ledge of glowing crystal (present only).
func _draw_crystal_shelf(alpha: float) -> void:
	if alpha <= 0.01:
		return
	draw_rect(Rect2(0, 4, size.x, 14), _c("vine_dark", alpha))
	for x in range(0, int(size.x), 16):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 6), Vector2(x + 8, -6), Vector2(x + 16, 6)]), _c("vine", alpha))
	draw_line(Vector2(0, 5), Vector2(size.x, 5), Color(1, 1, 1, 0.5 * alpha), 2.0)
