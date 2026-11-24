class_name AmbientFX
extends Node2D
## Living scenery and weather of a level (docs/40 §8), from the level's `ambient` data:
##   weather   "none" | "rain" | "snow" | "wind"  (particles in front of the screen)
##   critters  ["squirrel", "snail", "bird", ...] spread along the ground (frame-animated, never still)
##   critter_count   how many in total
##   gust      true = wind gusts that push the hero (warned 0.8 s ahead by streaks of leaves)
##   wet       true = rain makes the ground slippery (friction x0.7); snow: ice
## Weather particles use the cut art (v3_fx_rain_wind, v3_fx_snow) and count against the particle budget.

const RAIN := "res://assets/art/v3/cut/v3_fx_rain_wind/v3_fx_rain_wind_r00_f%02d.png"
const SNOW := "res://assets/art/v3/cut/v3_fx_snow/v3_fx_snow_r00_f%02d.png"
const LEAF_GUST := "res://assets/art/v3/cut/v3_fx_rain_wind/v3_fx_rain_wind_r04_f%02d.png"

var config: Dictionary = {}
var game: Node
var terrain: Node
var level_width := 6000.0
var level_height := 1024.0

var weather := "none"
var critters: Array = []
var _layer: CanvasLayer
var _particles: CPUParticles2D
var _gust_t := 4.0
var _gust_left := 0.0
var _gust_warn := 0.0
var _gust_dir := 1.0
var _wind_push := 0.0


func _ready() -> void:
	weather = String(config.get("weather", "none"))
	_layer = CanvasLayer.new()
	_layer.layer = 4
	add_child(_layer)
	if weather == "rain":
		_build_rain()
	elif weather == "snow":
		_build_snow()
	elif weather == "wind":
		_gust_t = 1.0
	_spawn_critters()
	if game and game.get("player") and bool(config.get("wet", weather == "rain")):
		game.player.wet = true


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _make_particles(tex: Texture2D, amount: int, life: float) -> CPUParticles2D:
	var units := FX.take(amount)
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = maxi(units, 1)
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.local_coords = false
	return p


func _build_rain() -> void:
	var tex := _tex(RAIN % 1)
	var view := get_viewport().get_visible_rect().size
	_particles = _make_particles(tex, 90, 0.9)
	_particles.emission_rect_extents = Vector2(view.x * 0.75, 6)
	_particles.position = Vector2(view.x * 0.55, -30)
	_particles.direction = Vector2(-0.25, 1)
	_particles.spread = 4.0
	_particles.initial_velocity_min = 900.0
	_particles.initial_velocity_max = 1100.0
	_particles.gravity = Vector2.ZERO
	_particles.scale_amount_min = 0.35
	_particles.scale_amount_max = 0.55
	_particles.color = Color(0.85, 0.92, 1.0, 0.7)
	_layer.add_child(_particles)
	# a cool dark veil: rain takes some of the light
	var veil := ColorRect.new()
	veil.color = Color(0.1, 0.16, 0.3, 0.16)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(veil)


func _build_snow() -> void:
	var tex := _tex(SNOW % 8)
	var view := get_viewport().get_visible_rect().size
	_particles = _make_particles(tex, 70, 6.0)
	_particles.emission_rect_extents = Vector2(view.x * 0.7, 6)
	_particles.position = Vector2(view.x * 0.5, -20)
	_particles.direction = Vector2(-0.3, 1)
	_particles.spread = 20.0
	_particles.initial_velocity_min = 60.0
	_particles.initial_velocity_max = 130.0
	_particles.angular_velocity_min = -60.0
	_particles.angular_velocity_max = 60.0
	_particles.scale_amount_min = 0.25
	_particles.scale_amount_max = 0.55
	_particles.color = Color(1, 1, 1, 0.9)
	_layer.add_child(_particles)


func _spawn_critters() -> void:
	var kinds: Array = config.get("critters", [])
	var count := int(config.get("critter_count", kinds.size() * 2))
	if kinds.is_empty() or count <= 0:
		return
	count = maxi(1, int(round(count * FX.quality_scale())))
	var step := level_width / float(count)
	for i in count:
		var c := Critter.new()
		c.kind = String(kinds[i % kinds.size()])
		c.terrain = terrain
		c.base_y = level_height * 0.75
		c.x_min = i * step + 80.0
		c.x_max = minf(c.x_min + step * 0.8, level_width - 80.0)
		add_child(c)
		critters.append(c)


func _process(delta: float) -> void:
	if weather == "wind" or bool(config.get("gust", false)):
		_update_gusts(delta)


## Gusts push the hero sideways; a rush of leaves warns 0.8 s before (docs/40 §8.4).
func _update_gusts(delta: float) -> void:
	if _gust_left > 0.0:
		_gust_left -= delta
		if game and game.get("player"):
			game.player._wind = Vector2(_gust_dir, 0.0)
		return
	if _gust_warn > 0.0:
		_gust_warn -= delta
		if _gust_warn <= 0.0:
			_gust_left = 1.6
		return
	_gust_t -= delta
	if _gust_t <= 0.0:
		_gust_t = randf_range(5.0, 9.0)
		_gust_dir = 1.0 if randf() < 0.5 else -1.0
		_gust_warn = 0.8
		if game and game.get("player"):
			SpriteFX.play(game._world_root, "leaf_gust", game.player.global_position + Vector2(-_gust_dir * 200.0, -60.0), 1.2, _gust_dir < 0.0)
