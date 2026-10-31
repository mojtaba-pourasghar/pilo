class_name Weather
extends Node2D
## The air of each level: wind that sways the trees (and pushes rain and snow sideways),
## rain with splashes on the ground and a darker sky, storms with lightning and thunder,
## the desert's heat haze, a warm sun glare, steam puffs in the clock factory.
## Chosen per world and level by `for_level`.

const SWAY := {
	"forest": 5.0, "coral_beach": 7.0, "golden_desert": 3.0, "snow_mountain": 4.0, "sky_islands": 12.0,
	"crystal_caves": 0.0, "clock_factory": 0.0, "shadow_castle": 4.0, "inverted_land": 6.0,
}

var world := "forest"
var rain := false
var storm := false
var heat := false
var sun := false
var steam := false
var wind := 1.0                 ## how hard the wind blows (sways trees, slants rain)

var _view := Vector2(1280, 720)
var _screen: Node2D
var _layer: CanvasLayer
var _shade: ColorRect
var _flash: ColorRect
var _sway: ShaderMaterial
var _lightning := 6.0
var _splash := 0.0
var _steam := 1.0
var _gust := 0.0
var _gust_target := 0.0
var _gust_timer := 3.0


## The weather of a level: rain on some forest, beach and castle levels, storms over the sky
## islands and the castle, heat in the desert, steam in the factory, sun where there is sky.
static func for_level(world_id: String, level_id: int, first: int) -> Weather:
	var weather := Weather.new()
	weather.world = world_id
	var index := level_id - first + 1
	match world_id:
		"forest":
			weather.rain = index in [3, 5]
			weather.sun = not weather.rain
		"coral_beach":
			weather.rain = index == 5
			weather.storm = index == 5
			weather.sun = not weather.rain
		"golden_desert":
			weather.heat = true
			weather.sun = true
		"snow_mountain":
			weather.wind = 1.6
			weather.sun = index % 2 == 1
		"sky_islands":
			weather.wind = 2.0
			weather.rain = index in [4, 6]
			weather.storm = weather.rain
			weather.sun = not weather.rain
		"clock_factory":
			weather.steam = true
		"shadow_castle":
			weather.rain = index in [2, 4, 6, 8]
			weather.storm = weather.rain
		"inverted_land":
			weather.sun = true
	return weather


func _ready() -> void:
	z_index = 4
	_sway = ShaderMaterial.new()
	_sway.shader = load("res://assets/vfx/sway.gdshader")
	_sway.set_shader_parameter("strength", float(SWAY.get(world, 4.0)) * (1.0 + (wind - 1.0) * 0.5))
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	if rain:
		_shade = ColorRect.new()
		_shade.color = Color(0.08, 0.1, 0.2, 0.22 if storm else 0.15)
		_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		_layer.add_child(_shade)
		# an overcast sky: the background (behind the level) turns grey-blue
		var overcast_layer := CanvasLayer.new()
		overcast_layer.layer = -6
		var overcast := ColorRect.new()
		overcast.color = Color(0.32, 0.36, 0.46, 0.5 if storm else 0.4)
		overcast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overcast.set_anchors_preset(Control.PRESET_FULL_RECT)
		overcast_layer.add_child(overcast)
		add_child(overcast_layer)
		AudioManager.play_ambient("rain")
	_screen = Screen.new()
	_screen.weather = self
	_layer.add_child(_screen)
	if storm:
		_flash = ColorRect.new()
		_flash.color = Color(1, 1, 1, 0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_layer.add_child(_flash)
	if heat:
		# shimmer over the background only (this layer sits between the background and the level)
		var haze_layer := CanvasLayer.new()
		haze_layer.layer = -5
		var haze := ColorRect.new()
		haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		haze.set_anchors_preset(Control.PRESET_FULL_RECT)
		var material := ShaderMaterial.new()
		material.shader = load("res://assets/vfx/heat_haze.gdshader")
		haze.material = material
		haze_layer.add_child(haze)
		add_child(haze_layer)
	if sun:
		var glare_layer := CanvasLayer.new()
		glare_layer.layer = 4
		var glare := Glare.new()
		glare_layer.add_child(glare)
		add_child(glare_layer)


## The background asks for the wind material for its trees and bushes.
func sway_material() -> ShaderMaterial:
	return _sway


func _process(delta: float) -> void:
	_view = get_viewport().get_visible_rect().size
	# gusts come and go
	_gust_timer -= delta
	if _gust_timer <= 0.0:
		_gust_target = randf_range(0.2, 1.0) * wind if randf() < 0.5 else 0.0
		_gust_timer = randf_range(2.0, 5.0)
	_gust = lerpf(_gust, _gust_target, 1.0 - exp(-1.5 * delta))
	_sway.set_shader_parameter("gust", _gust)
	if rain:
		_splash -= delta
		while _splash <= 0.0:
			_splash += 0.035
			_drop_splash()
	if storm:
		_lightning -= delta
		if _lightning <= 0.0:
			_lightning = randf_range(6.0, 12.0)
			_strike()
	if steam:
		_steam -= delta
		if _steam <= 0.0:
			_steam = randf_range(0.8, 1.8)
			_steam_puff()


func _camera_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Rect2(Vector2.ZERO, _view)
	var center := camera.get_screen_center_position()
	return Rect2(center - _view * 0.5, _view)


## The first solid ground straight below a point (rain splashes and steam vents land there).
func _ground_below(x: float, top: float) -> Variant:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, top), Vector2(x, top + _view.y * 1.4), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return null if hit.is_empty() else hit.position


func _drop_splash() -> void:
	var view := _camera_rect()
	var at = _ground_below(randf_range(view.position.x, view.end.x), view.position.y)
	if at != null:
		FX.splash(get_parent(), at)


func _steam_puff() -> void:
	var view := _camera_rect()
	var at = _ground_below(randf_range(view.position.x, view.end.x), view.position.y + view.size.y * 0.3)
	if at == null:
		return
	var puff := CPUParticles2D.new()
	puff.texture = FX.soft()
	puff.amount = 14
	puff.one_shot = true
	puff.explosiveness = 0.4
	puff.lifetime = 1.6
	puff.position = at
	puff.direction = Vector2.UP
	puff.spread = 12.0
	puff.initial_velocity_min = 80.0
	puff.initial_velocity_max = 150.0
	puff.gravity = Vector2(20, -10)
	puff.damping_min = 30.0
	puff.damping_max = 60.0
	puff.scale_amount_min = 0.8
	puff.scale_amount_max = 1.6
	puff.color = Color(1, 1, 1, 0.35)
	puff.z_index = 3
	get_parent().add_child(puff)
	puff.finished.connect(puff.queue_free)
	puff.emitting = true
	AudioManager.play_sfx_once("whoosh", 1.0, 0.6, -18.0)


func _strike() -> void:
	if _flash == null:
		return
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.65, 0.04)
	tween.tween_property(_flash, "color:a", 0.1, 0.08)
	tween.tween_property(_flash, "color:a", 0.5, 0.04)
	tween.tween_property(_flash, "color:a", 0.0, 0.5)
	get_tree().create_timer(randf_range(0.25, 0.9)).timeout.connect(func():
		AudioManager.play_sfx("thunder", randf_range(0.85, 1.1), -2.0)
		Juice.shake(self, 0.18)
		Juice.vibrate(30))


## Screen-space rain streaks (slanted by the wind) and wind streaks on windy worlds.
class Screen extends Node2D:
	var weather: Weather
	var drops: Array = []
	var t := 0.0

	func _ready() -> void:
		for i in 170:
			drops.append(Vector3(randf(), randf(), randf_range(0.7, 1.3)))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var view := get_viewport().get_visible_rect().size
		var slant := 0.18 + weather._gust * 0.25 * weather.wind
		if weather.rain:
			for d in drops:
				var speed: float = 1500.0 * d.z
				var y := fposmod(d.y * view.y + t * speed, view.y + 80.0) - 40.0
				var x := fposmod(d.x * view.x + y * slant + t * 60.0, view.x + 60.0) - 30.0
				var length: float = 34.0 * d.z
				draw_line(Vector2(x, y), Vector2(x - slant * length, y - length), Color(0.82, 0.9, 1.0, 0.5 * d.z), 2.2)
		if weather.wind >= 1.5:
			# airy streaks that rush past on gusts
			for i in 6:
				var k := fposmod(t * (0.6 + i * 0.07) + i * 0.37, 1.0)
				var y := view.y * (0.15 + 0.12 * i) + sin(t * 2.0 + i) * 20.0
				var x := view.x * (1.2 - k * 1.4)
				var alpha := sin(k * PI) * 0.35 * clampf(weather._gust * 1.5, 0.15, 1.0)
				var pts := PackedVector2Array()
				for s in 12:
					pts.append(Vector2(x + s * 18.0, y + sin(s * 0.6 + t * 3.0) * 6.0))
				draw_polyline(pts, Color(1, 1, 1, alpha), 2.5, true)


## A warm sun glare in the top corner, gently breathing.
class Glare extends Node2D:
	var t := 0.0

	func _ready() -> void:
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = additive

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var view := get_viewport().get_visible_rect().size
		var sun := Vector2(view.x * 0.82, view.y * 0.08)
		var pulse := 1.0 + sin(t * 0.8) * 0.05
		var soft := FX.soft()
		for ring in [[900.0, 0.08], [460.0, 0.12], [200.0, 0.2]]:
			var size: float = ring[0] * pulse
			draw_texture_rect(soft, Rect2(sun - Vector2(size, size) * 0.5, Vector2(size, size)), false, Color(1, 0.85, 0.55, ring[1]))
		# lens ghosts along the line through the screen centre
		var axis := view * 0.5 - sun
		for g in [[0.6, 60.0, 0.06], [1.1, 34.0, 0.08], [1.5, 90.0, 0.04]]:
			var p: Vector2 = sun + axis * g[0]
			var size2: float = g[1]
			draw_texture_rect(soft, Rect2(p - Vector2(size2, size2) * 0.5, Vector2(size2, size2)), false, Color(0.8, 0.9, 1.0, g[2]))
