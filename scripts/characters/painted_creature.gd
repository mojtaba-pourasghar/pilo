class_name PaintedCreature
extends EnemyRig
## A creature shown with its generated, rendered pictures (assets/art/<art>_shadow.png and
## <art>_free.png, or a single <art>.png): shadow creatures, the world guardians, companions
## and story characters. The pictures cross-fade from the shadow look to the real one as
## `freed_amount` grows, and the creature moves in code: it bobs and squashes as it walks,
## hovers and tilts when it flies, leans into a charge and glows when a move is coming.
## Origin = feet, facing right (`face_left` for art that is used mirrored).

const ART := "res://assets/art/%s.png"

var art := ""
var height := 60.0          ## height in the game, in pixels
var motion := "walk"        ## "walk", "fly", "roll", "boss", "idle"
var face_left := false
var anger := 1.0            ## bosses: speeds the idle motion
var flash := 0.0            ## bosses: white glow when a move is coming or a hit lands

var _shadow: MeshInstance2D
var _free: MeshInstance2D
var _holder: Node2D
var _material: ShaderMaterial
var _size := Vector2(60, 60)


## Is there generated art for this name (either the shadow/free pair or a single picture)?
static func available(name: String) -> bool:
	return ResourceLoader.exists(ART % (name + "_shadow")) or ResourceLoader.exists(ART % name)


static func make(name: String, game_height: float, kind_of_motion := "walk") -> PaintedCreature:
	var creature := PaintedCreature.new()
	creature.art = name
	creature.height = game_height
	creature.motion = kind_of_motion
	return creature


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/vfx/creature.gdshader")
	_holder = Node2D.new()
	add_child(_holder)
	if ResourceLoader.exists(ART % (art + "_shadow")):
		_shadow = _sprite(art + "_shadow")
		var free_name := art + "_free"
		_free = _sprite(free_name if ResourceLoader.exists(ART % free_name) else art + "_shadow")
	else:
		_free = _sprite(art)
		freed_amount = 1.0


## The picture on a grid mesh, so the creature shader can bend it (feet, wings, arms).
func _sprite(name: String) -> MeshInstance2D:
	var texture: Texture2D = load(ART % name)
	var h := height
	var w := texture.get_width() * h / texture.get_height()
	var node := MeshInstance2D.new()
	node.mesh = _grid(w, h, 10)
	node.texture = texture
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.material = _material
	if face_left:
		node.scale.x = -1.0
	_holder.add_child(node)
	_size = Vector2(w, h)
	_material.set_shader_parameter("size", _size)
	return node


static func _grid(w: float, h: float, n: int) -> ArrayMesh:
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in n + 1:
		for i in n + 1:
			var u := float(i) / n
			var v := float(j) / n
			verts.append(Vector2((u - 0.5) * w, (v - 1.0) * h))
			uvs.append(Vector2(u, v))
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			idx.append_array([a, a + 1, a + n + 1, a + 1, a + n + 2, a + n + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func target_pose(delta: float) -> Dictionary:
	var rate := 9.0
	match motion:
		"fly":
			rate = 7.0
		"boss":
			rate = 3.0 + anger * 2.0
	if state == "charge":
		rate *= 2.0
	phase += delta * rate
	return {}


func _process(delta: float) -> void:
	super(delta)
	flash = maxf(0.0, flash - delta * 2.5)
	if _free == null:
		return
	if _shadow:
		_shadow.modulate.a = 1.0 - freed_amount
		_free.modulate.a = freed_amount
	var bob := 0.0
	var tilt := 0.0
	var stretch := 0.0
	match motion:
		"walk":
			bob = -absf(sin(phase)) * height * 0.035
			stretch = sin(phase * 2.0) * 0.025
			tilt = sin(phase) * 0.03
		"fly":
			bob = -height * 0.15 + sin(phase) * height * 0.1
			tilt = sin(phase * 0.5) * 0.12
			stretch = sin(phase * 3.0) * 0.03
		"roll":
			bob = -absf(sin(phase * 0.5)) * height * 0.04
			tilt = sin(phase * 0.7) * 0.08
		"boss":
			bob = -absf(sin(phase)) * height * 0.03
			stretch = sin(phase * 2.0) * 0.025
			match state:
				"windup":
					stretch = -0.1
				"stunned":
					stretch = -0.14
					tilt = sin(t * 14.0) * 0.08
				"charge":
					tilt = 0.12
		_:
			stretch = sin(t * 2.4) * 0.02
	if state == "freed" or state == "free":
		bob = -absf(sin(t * 8.0)) * height * 0.2
		stretch = 0.0
	var walking := 1.0 if (motion == "walk" or (motion == "boss" and state in ["walk", "charge"])) and not (state == "freed" or state == "free") else 0.0
	_material.set_shader_parameter("phase", phase)
	_material.set_shader_parameter("time_s", t)
	_material.set_shader_parameter("stride", walking * (1.4 if state == "charge" else 1.0))
	_material.set_shader_parameter("flap", 1.0 if motion == "fly" else 0.0)
	_material.set_shader_parameter("sway", _size.x * (0.04 if motion != "fly" else 0.02))
	_material.set_shader_parameter("breathe", 1.0)
	_material.set_shader_parameter("arms", 1.0 if motion == "boss" else 0.0)
	_material.set_shader_parameter("slam", 1.0 if state == "windup" else 0.0)
	_holder.position = Vector2(0, bob)
	_holder.rotation = tilt
	_holder.scale = Vector2(1.0 - stretch, 1.0 + stretch)
	modulate = Color(1, 1, 1).lerp(Color(2.0, 1.6, 1.6), flash)


func _draw() -> void:
	draw_wisps(Vector2(0, -height * 0.6), height * 0.35)
