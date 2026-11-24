class_name Pair1Parallax
extends CanvasLayer
## Scenery of pair 1 (old "Dawn Plain" / new "Dawn Plain, years later"), docs/27 + docs/21 §4:
## seven depth layers, each with its own horizontal AND vertical factor, built from the cut art in
## assets/art/pair1 (tools/art/build_pair1.py):
##   L0/L1 sky and far scenery (the top of the approved scene picture)       x 0.03 / y 0.05
##   L2..L4 hills, ruins and big trees, bushes and the stream (mid strips)   x 0.20 .. 0.70
##   L5   the level itself
##   L6   dark foreground: leaves at the screen corners (own canvas layer, in front of the hero)
##   L7   light rays and particles (fireflies / pollen, drifting leaves)
## `variant` follows the deeds of the old level: "full" and "partial" show the grown scenery,
## "none" the bare plain (g3_bg_new_bare). Set pieces (the thousand-year tree, the bridge, the
## shrine...) are placed by the level with add_set_piece().

const ART := "res://assets/art/pair1/"
const SCENE := "res://assets/art/pair1_sheets/"

## era -> {scene, mids: [[file, x factor, y factor, height as a fraction of the screen]], leaves}
const ERAS := {
	"old": {
		"scene": "bg_old_plain_v3.png",
		"mids": [["bg_old/p0_bg_old_mid_layers/p0_bg_old_mid_layers_r00_c00.png", 0.22, 0.20, 0.82],
			["bg_old/p0_bg_old_mid_layers/p0_bg_old_mid_layers_r01_c00.png", 0.62, 0.55, 0.42]],
		"tint": Color(1, 0.98, 0.92),
	},
	"new": {
		"scene": "bg_new_plain_v3.png",
		"mids": [["bg_new/p0_bg_new_mid_layers/p0_bg_new_mid_layers_r00_c00.png", 0.18, 0.15, 0.40],
			["bg_new/p0_bg_new_mid_layers/p0_bg_new_mid_layers_r01_c00.png", 0.38, 0.35, 0.56],
			["bg_new/p0_bg_new_mid_layers/p0_bg_new_mid_layers_r02_c00.png", 0.68, 0.62, 0.44]],
		"tint": Color(0.95, 1, 1),
	},
}
const LAYERS_V3 := "res://assets/art/v3/layers/%s_%s.png"
const SKY_V3 := {"old": "res://assets/art/v3/v3_bg_old_sky.png", "new": "res://assets/art/v3/v3_bg_new_sky.png"}
## v3 layers (docs/36 §8): name -> [x factor, y factor, height as a fraction of the screen, where the layer's
## bottom edge rests as a fraction of the screen height]. Far = slow, near = fast; the hero's ground is at ~0.74.
const V3 := {
	"old": [["far", 0.06, 0.10, 0.34, 0.60], ["village", 0.14, 0.20, 0.34, 0.68], ["trees", 0.30, 0.38, 0.58, 0.92, 1.6], ["near", 0.52, 0.60, 0.34, 0.96]],
	"new": [["far", 0.06, 0.10, 0.50, 0.66], ["village", 0.14, 0.20, 0.50, 0.74], ["trees", 0.30, 0.38, 0.58, 0.92, 1.6]],
}
const BARE := "g3_bg_new_bare_v1.png"
const CORNERS := ["r00_c00", "r00_c01", "r02_c00", "r02_c01"]      ## top-left, top-right, bottom-left, bottom-right

var level_size := Vector2(4096, 1408)
var world_id := "forest"
var era := "new"
var variant := "full"           ## "full" | "partial" | "none" (deeds of the old level)

var _view := Vector2(1280, 720)
var _v3 := false
## Own backdrops per scene (docs/40 section 9): [{from: px, art: "v3_scene_valley_old" | "" }] ordered by x. Inside a zone
## with art, that painting replaces the standard hills/trees layers (it has its own middle ground); between zones the
## paintings crossfade over BACKDROP_FADE px. A missing picture file simply means "use the standard layers".
var backdrops: Array = []
const BACKDROP_FADE := 420.0
const BACKDROP_PATH := "res://assets/art/v3/%s.png"
var _backs: Array = []           ## {rect: TextureRect, from: float, to: float}
var _sky: TextureRect
var _rays: Control
var _layers: Array = []          ## {node, fx, fy, period}
var _front: CanvasLayer
var _corners: Array = []
var _t := 0.0


func _ready() -> void:
	layer = -10
	_view = get_viewport().get_visible_rect().size
	var cfg: Dictionary = ERAS.get(era, ERAS.new)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	if ResourceLoader.exists(SKY_V3.get(era, "")) and ResourceLoader.exists(LAYERS_V3 % [era, "far"]):
		_v3 = true
		_build_sky(root, cfg)
		var specs: Array = V3.get(era, V3.old)
		if era == "new" and variant == "none":
			specs = specs.slice(0, 2)       # no grown tree: only the far scenery
		for spec in specs:
			_add_v3_layer(spec)
	else:
		_build_sky(root, cfg)
		var mids: Array = cfg.mids
		if era == "new" and variant == "none":
			mids = mids.slice(0, 1)       # the other strips carry the lush tree and bridge: only the far hills stay
		for spec in mids:
			_add_mid(spec, cfg.tint)
	_build_backdrops(root)
	_build_front()
	_add_particles(root)


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _build_sky(root: Control, cfg: Dictionary) -> void:
	_sky = TextureRect.new()
	var path := SCENE + (BARE if (era == "new" and variant == "none") else String(cfg.scene))
	var tex := _tex(path)
	if ResourceLoader.exists(SKY_V3.get(era, "")):
		tex = _tex(SKY_V3[era])
		path = SKY_V3[era]
	if tex:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var keep := 1.0 if (path.ends_with(BARE) or path == SKY_V3.get(era, "")) else 0.62      # the top of the scene is sky and far land
		atlas.region = Rect2(0, 0, tex.get_width(), tex.get_height() * keep)
		_sky.texture = atlas
	_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sky)
	# slanted light shafts: soft additive gradients that breathe slowly
	_rays = Control.new()
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_rays)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 4:
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 0.95, 0.75, 0.0))
		grad.add_point(0.5, Color(1, 0.95, 0.75, 0.55))
		grad.set_color(grad.get_point_count() - 1, Color(1, 0.95, 0.75, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0, 0.5)
		gt.fill_to = Vector2(1, 0.5)
		var shaft := TextureRect.new()
		shaft.texture = gt
		shaft.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shaft.material = add
		shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shaft.modulate = Color(1, 1, 1, 0.0)
		_rays.add_child(shaft)


const FADE_SHADER := """
shader_type canvas_item;
uniform float fade = 0.16;
void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= smoothstep(0.0, fade, UV.y);
}
"""
var _fade_material: ShaderMaterial


func _fade() -> ShaderMaterial:
	if _fade_material == null:
		var sh := Shader.new()
		sh.code = FADE_SHADER
		_fade_material = ShaderMaterial.new()
		_fade_material.shader = sh
	return _fade_material


func _build_backdrops(root: Control) -> void:
	var zones: Array = []
	for i in backdrops.size():
		var b: Dictionary = backdrops[i]
		var art := String(b.get("art", ""))
		var to := float(backdrops[i + 1].from) if i + 1 < backdrops.size() else 1.0e9
		var tex: Texture2D = _tex(BACKDROP_PATH % art) if art != "" and ResourceLoader.exists(BACKDROP_PATH % art) else null
		zones.append({"from": float(b.from), "to": to, "tex": tex})
	for z in zones:
		if z.tex == null:
			continue
		var r := TextureRect.new()
		r.texture = z.tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.modulate.a = 0.0
		root.add_child(r)
		root.move_child(r, 2)                 # above the sky and the light shafts, below the standard layers' nodes
		_backs.append({"rect": r, "from": z.from, "to": z.to})


func _update_backdrops(cx: float, left: float) -> float:
	## Returns how much the backdrops cover the standard layers (0..1).
	var cover := 0.0
	for b in _backs:
		var a: float = smoothstep(b.from - BACKDROP_FADE, b.from + BACKDROP_FADE * 0.2, cx) 			* (1.0 - smoothstep(b.to - BACKDROP_FADE * 0.2, b.to + BACKDROP_FADE, cx))
		var r: TextureRect = b.rect
		r.modulate.a = a
		r.size = _view * 1.12
		r.position = Vector2(-_view.x * 0.06 - fposmod(left * 0.03, 40.0), -_view.y * 0.06)
		cover = maxf(cover, a)
	return cover


## One mid strip, repeated sideways with every other copy mirrored (so seams never show).
func _add_mid(spec: Array, tint: Color) -> void:
	var tex := _tex(ART + String(spec[0]))
	if tex == null:
		return
	var node := Node2D.new()
	add_child(node)
	var h := _view.y * float(spec[3])
	var k := h / tex.get_height()
	var w := tex.get_width() * k
	for i in 4:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2(-k if i % 2 == 1 else k, k)
		s.position = Vector2(i * w + (w if i % 2 == 1 else 0.0), -h)
		s.modulate = tint
		s.material = _fade()
		node.add_child(s)
	_layers.append({"node": node, "fx": float(spec[1]), "fy": float(spec[2]), "period": w * 2.0})


## One v3 layer picture, repeated sideways (every other copy mirrored so seams never show).
func _add_v3_layer(spec: Array) -> void:
	var tex := _tex(LAYERS_V3 % [era, String(spec[0])])
	if tex == null:
		return
	var node := Node2D.new()
	add_child(node)
	var h := _view.y * float(spec[3])
	var k := h / tex.get_height()
	var w := tex.get_width() * k
	var gap := float(spec[5]) if spec.size() > 5 else 0.0
	if gap > 0.0:
		# set-piece layer: the picture appears alone with open scenery between the copies (never mirrored)
		var step := w * (1.0 + gap)
		for i in 5:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(k, k)
			sp.position = Vector2(i * step, -h)
			node.add_child(sp)
		_layers.append({"node": node, "fx": float(spec[1]), "fy": float(spec[2]), "period": step * 3.0, "rest": float(spec[4])})
		return
	for i in 5:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.scale = Vector2(-k if i % 2 == 1 else k, k)
		sp.position = Vector2(i * w + (w if i % 2 == 1 else 0.0), -h)
		node.add_child(sp)
	_layers.append({"node": node, "fx": float(spec[1]), "fy": float(spec[2]), "period": w * 2.0, "rest": float(spec[4])})


## A set piece (tree, bridge, shrine...) at a world x, standing `bottom` px above the screen bottom.
func add_set_piece(path: String, x: float, bottom: float, factor: float, height: float) -> Sprite2D:
	var tex := _tex(path)
	if tex == null:
		return null
	var node := Node2D.new()
	add_child(node)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var k := height / tex.get_height()
	s.scale = Vector2(k, k)
	s.position = Vector2(x, -bottom - height)
	node.add_child(s)
	_layers.append({"node": node, "fx": factor, "fy": factor * 0.9, "period": 0.0})
	return s


## L6: dark leaves at the screen corners, in front of the hero; they sway a little.
func _build_front() -> void:
	_front = CanvasLayer.new()
	_front.layer = 5
	add_child(_front)
	for i in CORNERS.size():
		var tex := _tex("%soverlays/p0_r4_leaf_overlays/p0_r4_leaf_overlays_%s.png" % [ART, CORNERS[i]])
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.modulate = Color(1, 1, 1, 0.9)
		_front.add_child(s)
		_corners.append([s, i])


func _place_corners() -> void:
	for entry in _corners:
		var s: Sprite2D = entry[0]
		var i: int = entry[1]
		var k := _view.y * 0.30 / s.texture.get_height()
		var sw := sin(_t * (0.5 + i * 0.13) + i) * 0.012
		s.scale = Vector2(k, k)
		s.rotation = sw
		var w := s.texture.get_width() * k
		var h := s.texture.get_height() * k
		var left := i % 2 == 0
		var top := i < 2
		s.position = Vector2(-4.0 if left else _view.x - w + 4.0, -4.0 if top else _view.y - h + 4.0)


func _add_particles(root: Control) -> void:
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var motes := CPUParticles2D.new()
	motes.texture = FX.soft()
	motes.material = glow
	motes.amount = 10 if era == "old" else 16
	motes.lifetime = 6.0
	motes.preprocess = 6.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(700, 240)
	motes.position = Vector2(640, 430)
	motes.direction = Vector2(0, -1)
	motes.spread = 180.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 6.0
	motes.initial_velocity_max = 20.0
	motes.scale_amount_min = 0.12
	motes.scale_amount_max = 0.22
	var ramp := Gradient.new()
	var c := Color(1, 0.95, 0.6) if era == "old" else Color(0.7, 1, 0.7)
	ramp.set_color(0, Color(c, 0))
	ramp.add_point(0.3, Color(c, 1))
	ramp.add_point(0.7, Color(c, 0.8))
	ramp.set_color(ramp.get_point_count() - 1, Color(c, 0))
	motes.color_ramp = ramp
	_front.add_child(motes)
	var leaves := CPUParticles2D.new()
	leaves.texture = FX.soft()
	leaves.color = Color(0.75, 0.95, 0.5, 0.7) if era == "old" else Color(0.7, 0.9, 0.85, 0.6)
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
	leaves.scale_amount_min = 0.1
	leaves.scale_amount_max = 0.2
	_front.add_child(leaves)


func _process(delta: float) -> void:
	_t += delta
	_view = get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else _view * 0.5
	var left := center.x - _view.x * 0.5
	var rise := center.y - (level_size.y - _view.y * 0.5)      # 0 = camera at the bottom of the level
	# L0: sky, slow; its picture is a little taller than the screen so it can move up and down
	var cover := _view * Vector2(1.0, 1.0)
	_sky.size = cover * Vector2(1.0, 1.0)
	_sky.position = Vector2(-0.03 * left * 0.0, -0.05 * rise * -1.0 * 0.0)
	_sky.position.y = clampf(-0.05 * (center.y - level_size.y * 0.5), -40.0, 40.0)
	for i in _rays.get_child_count():
		var shaft: TextureRect = _rays.get_child(i)
		shaft.size = Vector2(_view.x * (0.10 + 0.04 * i), _view.y * 1.5)
		shaft.pivot_offset = Vector2(shaft.size.x * 0.5, 0.0)
		shaft.rotation = deg_to_rad(-22.0)
		shaft.position = Vector2(_view.x * (0.12 + 0.24 * i) + sin(_t * 0.05 + i) * 30.0, -_view.y * 0.2)
		shaft.modulate.a = 0.07 + 0.05 * sin(_t * 0.7 + i * 1.7)
	for entry in _layers:
		var node: Node2D = entry.node
		var period: float = entry.period
		node.position.x = -fposmod(left * entry.fx, period) if period > 0.0 else -left * entry.fx
		var rest := _view.y * float(entry.get("rest", 1.0))
		node.position.y = rest - rise * entry.fy
	var covered := _update_backdrops(center.x, left)
	for entry in _layers:
		entry.node.modulate.a = 1.0 - covered
	_place_corners()


## LayeredBackground's calls (the time look is the TimeGrade shader).
func set_tint(_tint: Color, _instant: bool) -> void:
	pass


func set_sway(_material: Material) -> void:
	pass
