class_name Living
extends RefCounted
## A living environment (docs/47 section 5): nothing in the scenery stands still like a photograph.
##   - a sway shader for the painted layers (canopies and plants move in the wind, more toward their tops)
##   - drifting mist banks between the layers
##   - pollen and fireflies floating in the light, falling leaves (screen space)
##   - birds crossing the far forest now and then

const SWAY := """shader_type canvas_item;
uniform float amount = 4.0;      // pixels of sway at the top of the picture
uniform float speed = 0.9;
uniform float top_weight = 1.0;  // 1 = the top moves most (trees), 0 = the bottom moves most (foreground plants)
void fragment() {
	float w = mix(1.0 - UV.y, UV.y, 1.0 - top_weight);
	w = w * w;
	float s = sin(TIME * speed + UV.x * 9.0) * 0.6 + sin(TIME * speed * 1.7 + UV.x * 23.0) * 0.4;
	vec2 off = vec2(s * amount * w * TEXTURE_PIXEL_SIZE.x, 0.0);
	COLOR = texture(TEXTURE, UV + off) * COLOR;
}
"""

static var _sway_shader: Shader


static func sway(node: CanvasItem, amount: float, speed: float, top_weight := 1.0) -> void:
	if _sway_shader == null:
		_sway_shader = Shader.new()
		_sway_shader.code = SWAY
	var m := ShaderMaterial.new()
	m.shader = _sway_shader
	m.set_shader_parameter("amount", amount)
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("top_weight", top_weight)
	node.material = m


## Soft mist banks drifting sideways (put one in front of each far layer: depth = haze).
class Mist extends Node2D:
	var width := 3600.0
	var y := 500.0
	var thick := 260.0
	var color := Color(0.85, 0.95, 0.9, 0.16)
	var drift := 18.0
	var _t := 0.0
	var _blobs: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(y)
		for i in 26:
			_blobs.append([rng.randf() * width, y + rng.randf_range(-thick * 0.5, thick * 0.5), rng.randf_range(160, 340), rng.randf_range(0.6, 1.4)])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	static var _puff: Texture2D

	static func puff() -> Texture2D:
		if _puff == null:
			_puff = load("res://art/fx/puff.png")
		return _puff

	func _draw() -> void:
		var tex := puff()
		for b in _blobs:
			var x := fposmod(float(b[0]) + _t * drift * float(b[3]), width)
			var r := float(b[2]) * 1.6
			# wide flat soft puffs: mist, not balls
			draw_texture_rect(tex, Rect2(x - r * 1.6, float(b[1]) - r * 0.5, r * 3.2, r), false, color)


## Glowing pollen and fireflies drifting in the light, and leaves falling (screen space, in front of the path).
static func air(parent: Node, view: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	parent.add_child(layer)
	var pollen := CPUParticles2D.new()
	pollen.amount = 70
	pollen.lifetime = 9.0
	pollen.preprocess = 9.0
	pollen.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pollen.emission_rect_extents = view * 0.6
	pollen.position = view * 0.5
	pollen.direction = Vector2(0.3, -1)
	pollen.spread = 60.0
	pollen.gravity = Vector2(4, -6)
	pollen.initial_velocity_min = 6.0
	pollen.initial_velocity_max = 22.0
	pollen.scale_amount_min = 2.0
	pollen.scale_amount_max = 5.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 0.95, 0.6, 0.0))
	grad.add_point(0.25, Color(1, 0.95, 0.6, 0.8))
	grad.add_point(0.75, Color(1, 1, 0.8, 0.6))
	grad.set_color(1, Color(1, 1, 0.8, 0.0))
	pollen.color_ramp = grad
	layer.add_child(pollen)
	var leaves := CPUParticles2D.new()
	leaves.amount = 12
	leaves.lifetime = 8.0
	leaves.preprocess = 8.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(view.x * 0.6, 10)
	leaves.position = Vector2(view.x * 0.5, -30)
	leaves.direction = Vector2(-0.4, 1)
	leaves.spread = 30.0
	leaves.gravity = Vector2(-10, 26)
	leaves.initial_velocity_min = 20.0
	leaves.initial_velocity_max = 50.0
	leaves.angular_velocity_min = -120.0
	leaves.angular_velocity_max = 120.0
	leaves.scale_amount_min = 7.0
	leaves.scale_amount_max = 12.0
	leaves.color = Color("7fb347")
	var lg := Gradient.new()
	lg.set_color(0, Color(0.6, 0.8, 0.35, 0.0))
	lg.add_point(0.1, Color(0.6, 0.8, 0.35, 0.9))
	lg.set_color(1, Color(0.5, 0.65, 0.3, 0.0))
	leaves.color_ramp = lg
	layer.add_child(leaves)


## Birds crossing the far forest now and then (flapping V shapes in the haze colour).
class Birds extends Node2D:
	var width := 3600.0
	var _flock: Array = []
	var _t := 0.0
	var _next := 2.0

	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_next = randf_range(6.0, 12.0)
			var y := randf_range(150.0, 450.0)
			var x := randf_range(0.0, width)
			for i in randi_range(3, 6):
				_flock.append([x - i * 40.0, y + (i % 2) * 18.0 + i * 6.0, randf() * TAU, 0.0])
		for b in _flock:
			b[0] += 90.0 * delta
			b[1] -= 6.0 * delta
			b[3] += delta
		_flock = _flock.filter(func(b): return b[3] < 14.0)
		queue_redraw()

	func _draw() -> void:
		for b in _flock:
			var p := Vector2(b[0], b[1])
			var f := sin(_t * 9.0 + float(b[2])) * 6.0
			var c := Color(0.25, 0.35, 0.33, 0.55)
			draw_line(p, p + Vector2(-10, -4 - f), c, 2.5)
			draw_line(p, p + Vector2(10, -4 - f), c, 2.5)
