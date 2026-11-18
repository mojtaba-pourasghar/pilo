class_name ReleaseFX
extends Node2D
## «آزاد شدن»: nothing is ever killed. A freed creature lets go of its shadow: a soft light, a
## puff of purple shadow drifting away and a few butterflies flying up (p7 butterfly frames).

const FRAMES := [
	"res://assets/art/p7_living/p7_living_ch01_butterfly_f1.png",
	"res://assets/art/p7_living/p7_living_ch01_butterfly_f2.png",
	"res://assets/art/p7_living/p7_living_ch01_butterfly_f3.png",
	"res://assets/art/p7_living/p7_living_ch01_butterfly_f4.png",
]
static var _textures: Array = []

var count := 5
var _t := 0.0
var _flies: Array = []


static func spawn(parent: Node, pos: Vector2, butterflies := 5) -> ReleaseFX:
	var fx := ReleaseFX.new()
	fx.count = butterflies
	fx.position = pos
	parent.add_child(fx)
	return fx


func _ready() -> void:
	z_index = 6
	if _textures.is_empty():
		for path in FRAMES:
			if ResourceLoader.exists(path):
				_textures.append(load(path))
	for i in count:
		_flies.append({
			"pos": Vector2(randf_range(-30, 30), randf_range(-40, 0)),
			"vel": Vector2(randf_range(-90, 90), randf_range(-170, -90)),
			"phase": randf() * TAU, "size": randf_range(30, 46),
		})
	FX.burst(get_parent(), global_position, Color(1.0, 0.95, 0.7), 16)


func _process(delta: float) -> void:
	_t += delta
	for f in _flies:
		f.vel.x += sin(_t * 5.0 + f.phase) * 140.0 * delta
		f.pos += f.vel * delta
	if _t > 2.6:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := clampf(2.6 - _t, 0.0, 1.0)
	# the shadow drifting off, the light where it was
	draw_circle(Vector2(0, -40), 70.0 * minf(1.0, _t * 2.0), Color(1.0, 0.95, 0.75, 0.35 * a))
	for i in 5:
		var p := Vector2(sin(i * 1.7 + _t) * 30.0, -40.0 - _t * 90.0 - i * 14.0)
		draw_circle(p, 18.0 - i * 2.0, Color(0.42, 0.3, 0.62, 0.35 * a))
	if _textures.is_empty():
		return
	for f in _flies:
		var tex: Texture2D = _textures[int(_t * 12.0 + f.phase * 3.0) % _textures.size()]
		var s: float = f.size / maxf(tex.get_width(), tex.get_height())
		var size := tex.get_size() * s
		draw_texture_rect(tex, Rect2(f.pos - size * 0.5, size), false, Color(1, 1, 1, a))
