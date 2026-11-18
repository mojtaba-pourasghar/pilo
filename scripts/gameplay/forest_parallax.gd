class_name ForestParallax
extends CanvasLayer
## Chapter 1 scenery: five parallax layers from the approved past scene (p6 sheet_ch01_past_v1,
## cut by tools/art/cut_ui.py into depth pieces) - the present is the same picture through the
## TimeGrade shader, never a second picture (02_godot_spec §3, handoff 18 Nov).
##   0.05 sky and canopy   0.2 the old waterfall   0.4 big trees and gateways
##   0.7 glowing mushrooms near the path   1.1 flowers in front of the hero (own layer)
## Particles: CPUParticles2D fireflies and drifting leaves; light rays and fireflies use additive
## blending (glow). Each layer repeats sideways so any level length is covered.

const SKY := "res://assets/art/p6_scenes/sheet_ch01_past_v1.png"
const CUT := "res://assets/art/p9_ui/cut/scene_ch01_%s.png"
const FACTORS := [0.05, 0.2, 0.4, 0.7, 1.1]
## layer -> [[piece, x within the period, y from the screen bottom, height], ...], period
const LAYERS := {
	1: [[["far_falls", 300.0, 210.0, 430.0], ["far_falls", 1500.0, 230.0, 380.0]], 2400.0],
	2: [[["tree_r", 0.0, 140.0, 620.0], ["arch_l", 820.0, 170.0, 420.0], ["tree_l", 1500.0, 150.0, 560.0], ["arch_r", 2150.0, 190.0, 330.0]], 2700.0],
	3: [[["fg_mush_r", 120.0, 120.0, 170.0], ["fg_mush_l", 900.0, 125.0, 150.0], ["fg_mush_r", 1600.0, 118.0, 140.0]], 2100.0],
	4: [[["fg_mush_l", 200.0, -30.0, 140.0], ["fg_mush_r", 1400.0, -30.0, 130.0]], 2300.0],
}
const RAYS := ["res://assets/art/p7_living/p7_living_ch01_light_rays_f1.png", "res://assets/art/p7_living/p7_living_ch01_light_rays_f2.png"]
const FIREFLY := "res://assets/art/p7_living/p7_living_ch01_firefly.png"
const LEAF := "res://assets/art/p7_living/p7_living_ch01_leaf_f1.png"

var level_size := Vector2(4096, 1408)
var world_id := "forest"
var _sky: TextureRect
var _rays: TextureRect
var _layers: Array = []          ## [Node2D, factor, period]
var _front: CanvasLayer
var _t := 0.0


func _ready() -> void:
	layer = -10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_sky = TextureRect.new()
	var sky_tex: Texture2D = load(SKY) if ResourceLoader.exists(SKY) else null
	if sky_tex:
		# the top of the past scene (sky, canopy, cliffs) is the far background
		var atlas := AtlasTexture.new()
		atlas.atlas = sky_tex
		atlas.region = Rect2(0, 0, sky_tex.get_width(), sky_tex.get_height() * 0.62)
		_sky.texture = atlas
	_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sky.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sky)
	_rays = TextureRect.new()
	_rays.texture = load(RAYS[0]) if ResourceLoader.exists(RAYS[0]) else null
	_rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rays.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_rays.material = add
	_rays.modulate = Color(1, 0.95, 0.8, 0.35)
	root.add_child(_rays)
	for i in [1, 2, 3]:
		_layers.append(_make_layer(self, i))
	_front = CanvasLayer.new()
	_front.layer = 5
	add_child(_front)
	_layers.append(_make_layer(_front, 4))
	_add_particles(root)


func _make_layer(parent: Node, index: int) -> Array:
	var node := Node2D.new()
	parent.add_child(node)
	var spec: Array = LAYERS[index]
	var period: float = spec[1]
	# two periods side by side are enough for any screen; the node is moved modulo the period
	for copy in 3:
		for item in spec[0]:
			var path := CUT % item[0]
			if not ResourceLoader.exists(path):
				continue
			var s := Sprite2D.new()
			s.texture = load(path)
			s.centered = false
			var k: float = float(item[3]) / s.texture.get_height()
			s.scale = Vector2(k, k)
			s.position = Vector2(copy * period + float(item[1]), -float(item[2]) - s.texture.get_height() * k)
			if index == 4:
				s.modulate = Color(0.85, 0.9, 0.85, 0.95)
			node.add_child(s)
	return [node, FACTORS[index], period]


func _add_particles(root: Control) -> void:
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var flies := CPUParticles2D.new()
	flies.texture = load(FIREFLY) if ResourceLoader.exists(FIREFLY) else null
	flies.material = glow
	flies.amount = 14
	flies.lifetime = 6.0
	flies.preprocess = 6.0
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(700, 260)
	flies.position = Vector2(640, 420)
	flies.direction = Vector2(0, -1)
	flies.spread = 180.0
	flies.gravity = Vector2.ZERO
	flies.initial_velocity_min = 6.0
	flies.initial_velocity_max = 22.0
	flies.scale_amount_min = 0.05
	flies.scale_amount_max = 0.1
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 0.7, 0))
	ramp.add_point(0.3, Color(1, 1, 0.7, 1))
	ramp.add_point(0.7, Color(1, 1, 0.7, 0.8))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 0.7, 0))
	flies.color_ramp = ramp
	_front.add_child(flies)
	var leaves := CPUParticles2D.new()
	leaves.texture = load(LEAF) if ResourceLoader.exists(LEAF) else null
	leaves.amount = 8
	leaves.lifetime = 9.0
	leaves.preprocess = 9.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(760, 10)
	leaves.position = Vector2(640, -30)
	leaves.direction = Vector2(-0.3, 1)
	leaves.spread = 25.0
	leaves.gravity = Vector2(0, 18)
	leaves.initial_velocity_min = 30.0
	leaves.initial_velocity_max = 60.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.scale_amount_min = 0.06
	leaves.scale_amount_max = 0.1
	_front.add_child(leaves)


func _process(delta: float) -> void:
	_t += delta
	var view := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else view * 0.5
	var left := center.x - view.x * 0.5
	_sky.size = view * Vector2(1.0, 1.0)
	_sky.position = Vector2(0, -0.04 * (center.y - level_size.y * 0.5))
	_rays.size = view
	_rays.modulate.a = 0.25 + 0.1 * sin(_t * 0.7)
	for entry in _layers:
		var node: Node2D = entry[0]
		var factor: float = entry[1]
		var period: float = entry[2]
		node.position.x = -fposmod(left * factor, period)
		node.position.y = view.y - (center.y - level_size.y + view.y * 0.5) * (factor - 0.0) * 0.15


## LayeredBackground's calls (the time look is the TimeGrade shader now).
func set_tint(_tint: Color, _instant: bool) -> void:
	pass


func set_sway(_material: Material) -> void:
	pass
