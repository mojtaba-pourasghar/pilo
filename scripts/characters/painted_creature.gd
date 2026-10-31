class_name PaintedCreature
extends EnemyRig
## A creature shown with its generated, rendered pictures (assets/art/<art>_shadow.png and
## <art>_free.png, or a single <art>.png): shadow creatures, the world guardians, companions
## and story characters. Like Pilo, it is cut into parts that move on their own: the head
## nods, the two feet step in turn under a bobbing body, a flyer's wings flap, a guardian's
## arms swing and rise for a slam, a spiky one rolls. The pictures cross-fade from the
## shadow look to the real one as `freed_amount` grows. Origin = feet, facing right.

const ART := "res://assets/art/%s.png"
const PART_SHADER := preload("res://assets/vfx/part.gdshader")

## Parts as regions of the picture (fractions):
## [name, x0, y0, x1, y1, pivot x, pivot y, z, soft edges (left, top, right, bottom)]
## Parts overlap and their inner edges fade, so the joints never show a cut.
const WALKER := [
	["leg_l", 0.0, 0.58, 0.62, 1.0, 0.32, 0.66, 0, [0.0, 0.1, 0.12, 0.0]],
	["leg_r", 0.38, 0.58, 1.0, 1.0, 0.68, 0.66, 0, [0.12, 0.1, 0.0, 0.0]],
	["body", 0.0, 0.34, 1.0, 0.86, 0.5, 0.74, 1, [0.0, 0.06, 0.0, 0.16]],
	["head", 0.0, 0.0, 1.0, 0.48, 0.5, 0.42, 2, [0.0, 0.0, 0.0, 0.1]],
]
const FLYER := [
	["wing_l", 0.0, 0.0, 0.5, 0.8, 0.38, 0.42, 0, [0.0, 0.0, 0.12, 0.08]],
	["wing_r", 0.5, 0.0, 1.0, 0.8, 0.62, 0.42, 0, [0.12, 0.0, 0.0, 0.08]],
	["body", 0.22, 0.0, 0.78, 1.0, 0.5, 0.6, 1, [0.07, 0.0, 0.07, 0.0]],
]
const BOSS := [
	["leg_l", 0.0, 0.62, 0.62, 1.0, 0.32, 0.7, 0, [0.0, 0.1, 0.12, 0.0]],
	["leg_r", 0.38, 0.62, 1.0, 1.0, 0.68, 0.7, 0, [0.12, 0.1, 0.0, 0.0]],
	["body", 0.0, 0.3, 1.0, 0.88, 0.5, 0.76, 1, [0.0, 0.06, 0.0, 0.16]],
	["arm_l", 0.0, 0.2, 0.32, 0.78, 0.22, 0.3, 3, [0.0, 0.08, 0.12, 0.06]],
	["arm_r", 0.68, 0.2, 1.0, 0.78, 0.78, 0.3, 3, [0.12, 0.08, 0.0, 0.06]],
	["head", 0.0, 0.0, 1.0, 0.44, 0.5, 0.4, 2, [0.0, 0.0, 0.0, 0.1]],
]

var art := ""
var height := 60.0          ## height in the game, in pixels
var motion := "walk"        ## "walk", "fly", "roll", "boss", "idle"
var face_left := false
var anger := 1.0            ## bosses: speeds the motion
var flash := 0.0            ## bosses: white glow when a move is coming or a hit lands

var _holder: Node2D
var _parts := {}            ## name -> Node2D (holding the shadow and the free sprite)
var _layers: Array = []     ## [shadow sprites, free sprites]
var _w := 60.0


static func available(name: String) -> bool:
	return ResourceLoader.exists(ART % (name + "_shadow")) or ResourceLoader.exists(ART % name)


static func make(name: String, game_height: float, kind_of_motion := "walk") -> PaintedCreature:
	var creature := PaintedCreature.new()
	creature.art = name
	creature.height = game_height
	creature.motion = kind_of_motion
	return creature


## Separate drawn poses of this creature (assets/art/<art>_walk_a.png ...), played one after
## another like a cartoon. When they exist they are used instead of the cut parts.
const FRAMES := {
	"walk": ["walk_a", "walk_b", "walk_c", "walk_b"],
	"fly": ["fly_a", "fly_b", "fly_c", "fly_b"],
	"roll": ["roll_a", "roll_b"],
}

var _frames := {}            ## animation -> Array[Texture2D]
var _frame_sprite: Sprite2D
var _tint: ShaderMaterial
var _base_h := 0.0           ## height of the base picture: every pose keeps its scale


func _base_name() -> String:
	return art.trim_suffix("_free")


func _load_frames() -> void:
	var base := _base_name()
	for anim in FRAMES:
		var list: Array = []
		for f in FRAMES[anim]:
			var path := ART % (base + "_" + f)
			if ResourceLoader.exists(path):
				list.append(load(path))
		if list.size() == FRAMES[anim].size():
			_frames[anim] = list
	for single in ["hurt", "windup", "stunned"]:
		if ResourceLoader.exists(ART % (base + "_" + single)):
			_frames[single] = [load(ART % (base + "_" + single))]


func _ready() -> void:
	_holder = Node2D.new()
	if face_left:
		_holder.scale.x = -1.0
	add_child(_holder)
	_load_frames()
	if not _frames.is_empty() and motion != "idle":
		var base_pic := ART % (art if ResourceLoader.exists(ART % art) else art + "_free")
		_base_h = float(load(base_pic).get_height()) if ResourceLoader.exists(base_pic) else 0.0
		_frame_sprite = Sprite2D.new()
		_frame_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_tint = ShaderMaterial.new()
		_tint.shader = preload("res://assets/vfx/shadow_tint.gdshader")
		_frame_sprite.material = _tint
		_holder.add_child(_frame_sprite)
		if not ResourceLoader.exists(ART % (art + "_shadow")):
			freed_amount = 1.0
		return
	var looks: Array = []
	if ResourceLoader.exists(ART % (art + "_shadow")):
		var free_name := art + "_free"
		looks = [load(ART % (art + "_shadow")), load(ART % (free_name if ResourceLoader.exists(ART % free_name) else art + "_shadow"))]
	else:
		looks = [load(ART % art)]
		freed_amount = 1.0
	var layout: Array = {"walk": WALKER, "boss": BOSS, "fly": FLYER}.get(motion, [["all", 0.0, 0.0, 1.0, 1.0, 0.5, 1.0, 0, [0.0, 0.0, 0.0, 0.0]]])
	_layers = [[], []]
	for spec in layout:
		var part := Node2D.new()
		part.z_index = int(spec[7])
		part.z_as_relative = true
		_holder.add_child(part)
		_parts[spec[0]] = part
		for i in looks.size():
			var sprite := _cut(looks[i], spec, part)
			_layers[i].append(sprite)


## One part: a region of the picture, placed so its pivot sits at the pivot's spot in the
## whole creature (feet at the origin).
func _cut(texture: Texture2D, spec: Array, part: Node2D) -> Sprite2D:
	var tw := float(texture.get_width())
	var th := float(texture.get_height())
	var k := height / th
	_w = tw * k
	var region := Rect2(spec[1] * tw, spec[2] * th, (spec[3] - spec[1]) * tw, (spec[4] - spec[2]) * th)
	var pivot := Vector2(spec[5] * tw, spec[6] * th)
	part.position = (pivot - Vector2(tw * 0.5, th)) * k
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.offset = region.position - pivot
	sprite.scale = Vector2(k, k)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var soft: Array = spec[8]
	if soft.max() > 0.0:
		var material := ShaderMaterial.new()
		material.shader = PART_SHADER
		material.set_shader_parameter("region", Vector4(spec[1], spec[2], spec[3], spec[4]))
		material.set_shader_parameter("fade", Vector4(soft[0], soft[1], soft[2], soft[3]))
		sprite.material = material
	part.add_child(sprite)
	return sprite


func target_pose(delta: float) -> Dictionary:
	var rate := 10.0
	match motion:
		"fly":
			rate = 14.0
		"boss":
			rate = 4.0 + anger * 2.5
		"roll":
			rate = 7.0
	if state == "charge":
		rate *= 1.8
	if state == "stunned" or state == "freed" or state == "free":
		rate *= 0.4
	phase += delta * rate
	return {}


func _process(delta: float) -> void:
	super(delta)
	flash = maxf(0.0, flash - delta * 2.5)
	if _frame_sprite:
		_play_frames()
		return
	if _layers.is_empty():
		return
	if _layers[1].size() > 0:
		for s in _layers[0]:
			s.modulate.a = 1.0 - freed_amount
		for s in _layers[1]:
			s.modulate.a = freed_amount
	var s := sin(phase)
	var freed := state == "freed" or state == "free"
	var bob := 0.0
	match motion:
		"walk":
			# feet step in turn, the body bobs and rocks, the head nods against it
			_rot("leg_l", s * 0.38)
			_rot("leg_r", -s * 0.38)
			_rot("body", sin(phase * 2.0) * 0.06)
			_rot("head", -sin(phase * 2.0) * 0.12 + sin(t * 1.3) * 0.05)
			bob = -absf(s) * height * 0.1
		"fly":
			_rot("wing_l", -0.1 - absf(sin(phase)) * 0.65)
			_rot("wing_r", 0.1 + absf(sin(phase)) * 0.65)
			_rot("body", sin(phase * 0.5) * 0.12)
			bob = -height * 0.25 + sin(phase * 0.5) * height * 0.12
		"roll":
			# spiky ones roll along, bouncing
			_holder.rotation = phase * 0.9
			bob = -absf(sin(phase)) * height * 0.12
		"boss":
			var walking := state in ["walk", "charge", "intro"]
			_rot("leg_l", s * (0.3 if walking else 0.06))
			_rot("leg_r", -s * (0.3 if walking else 0.06))
			var raise := 1.0 if state == "windup" else 0.0
			_rot("arm_l", -raise * 1.2 + sin(phase) * 0.25)
			_rot("arm_r", raise * 1.2 - sin(phase + 1.0) * 0.25)
			_rot("head", sin(phase * 0.7) * 0.1 + (0.2 if state == "stunned" else 0.0))
			_rot("body", sin(phase * 2.0) * 0.04 + (0.15 if state == "charge" else 0.0))
			bob = -absf(s) * height * (0.06 if walking else 0.02)
			if state == "stunned":
				_holder.rotation = sin(t * 14.0) * 0.06
			else:
				_holder.rotation = 0.0
		_:
			# idle (portraits, icons): breathing and a little sway
			bob = sin(t * 2.4) * height * 0.015
			_holder.rotation = sin(t * 1.1) * 0.03
	if freed:
		bob = -absf(sin(t * 8.0)) * height * 0.25
	_holder.position = Vector2(0, bob)
	modulate = Color(1, 1, 1).lerp(Color(2.0, 1.6, 1.6), flash)


func _rot(part: String, angle: float) -> void:
	if _parts.has(part):
		_parts[part].rotation = angle


func _draw() -> void:
	draw_wisps(Vector2(0, -height * 0.6), height * 0.35)


## Frame mode: picks this moment's pose and places it with the feet on the origin.
func _play_frames() -> void:
	var freed := state == "freed" or state == "free"
	var list: Array = []
	var bob := 0.0
	if freed and _frames.has("hurt"):
		list = _frames.hurt
	elif state == "windup" and _frames.has("windup"):
		list = _frames.windup
	elif (state == "stunned" or state == "hurt") and _frames.has("stunned"):
		list = _frames.stunned
	elif _frames.has(motion):
		list = _frames[motion]
	elif _frames.has("walk"):
		list = _frames.walk
	else:
		list = _frames.values()[0]
	var i := int(phase / 1.4) % list.size()
	var texture: Texture2D = list[i]
	_frame_sprite.texture = texture
	var k := height / (_base_h if _base_h > 0.0 else float(texture.get_height()))
	if motion == "fly":
		bob = -height * 0.25 + sin(phase * 0.4) * height * 0.08
	_frame_sprite.scale = Vector2(k, k)
	_frame_sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	_tint.set_shader_parameter("amount", 1.0 - freed_amount)
	if freed:
		bob = -absf(sin(t * 8.0)) * height * 0.2
	_holder.position = Vector2(0, bob)
	_holder.rotation = 0.0
	modulate = Color(1, 1, 1).lerp(Color(2.0, 1.6, 1.6), flash)
