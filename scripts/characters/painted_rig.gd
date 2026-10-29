class_name PaintedRig
extends CharacterRig
## A character made of generated, rendered part pictures (assets/characters/<name>/: head,
## body, arm, legs, tail and rig.json, cut by tools/art/make_rig.py), animated part by part:
## legs and arms swing in the walk and gallop cycles, the body bobs and leans, the head tilts
## and lags a little behind, Pilo's tail wags. For big actions (jump, glide, hurt...) a whole
## rendered pose picture is shown instead when one exists. Same states and API as the drawn
## rigs (state, speed, run_speed, phase, expression). Origin = feet, facing right.

const FOLDER := "res://assets/characters/%s/"

@export var character := "nima"

var glow := Color(0.4, 0.9, 1.0)
var _rig: Dictionary = {}
var _root: Node2D
var _parts: Node2D
var _body: Sprite2D
var _head: Sprite2D
var _tail: Sprite2D
var _arms: Array = []          ## [sprite, kind] kind: "front", "back"
var _legs: Array = []          ## [sprite, kind] kind: "front", "back", "hind", "far_front", "far_hind"
var _poses: Dictionary = {}    ## state -> Sprite2D
var _hue_material: ShaderMaterial
var _flash := 0.0
var _s := 1.0                ## source pixels -> game pixels


## Is there generated art for this character?
static func available(name: String) -> bool:
	return FileAccess.file_exists(FOLDER % name + "rig.json")


static func make(name: String) -> PaintedRig:
	var rig := PaintedRig.new()
	rig.character = name
	return rig


func _ready() -> void:
	var file := FileAccess.open(FOLDER % character + "rig.json", FileAccess.READ)
	_rig = JSON.parse_string(file.get_as_text())
	_hue_material = ShaderMaterial.new()
	_hue_material.shader = load("res://assets/vfx/hue_shift.gdshader")
	_hue_material.set_shader_parameter("hue_shift", 0.0)
	_root = Node2D.new()
	_s = float(_rig.get("scale", 0.2))
	_root.scale = Vector2(_s, _s)
	add_child(_root)
	_parts = Node2D.new()
	_root.add_child(_parts)
	if _rig.parts.has("tail") or _rig.parts.has("leg_front"):
		_build_quadruped()
	else:
		_build_biped()
	for pose_state in _rig.get("poses", {}):
		var info: Dictionary = _rig.poses[pose_state]
		var sprite := Sprite2D.new()
		sprite.texture = load(FOLDER % character + String(info.file))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var k := float(info.get("scale", 1.0))
		sprite.scale = Vector2(k, k)
		sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
		sprite.set_meta("lift", float(info.get("lift", 0)))
		sprite.visible = false
		if character == "pilo":
			sprite.material = _hue_material
		_root.add_child(sprite)
		_poses[pose_state] = sprite


func _part(part: String, parent: Node, at: Vector2, shade := 1.0) -> Sprite2D:
	var info: Dictionary = _rig.parts[part]
	var sprite := Sprite2D.new()
	sprite.texture = load(FOLDER % character + part + ".png")
	sprite.centered = false
	sprite.offset = -_v(info.pivot)
	sprite.position = at
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if character == "pilo":
		sprite.material = _hue_material
	if shade < 1.0:
		sprite.self_modulate = Color(shade, shade, shade * 1.02)
	parent.add_child(sprite)
	return sprite


## Where a part's pivot sits, relative to the feet (the rig origin), in source pixels.
func _anchor(part: String) -> Vector2:
	var info: Dictionary = _rig.parts[part]
	return _v(info.box) + _v(info.pivot) - _v(_rig.feet)


func _point(key: String, fallback: String) -> Vector2:
	if _rig.has(key):
		return _v(_rig[key]) - _v(_rig.feet)
	return _anchor(fallback)


func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _build_biped() -> void:
	var leg := _anchor("leg")
	var back := _part("leg", _parts, _point("hip_back", "leg") + Vector2(-6, 0) * float(not _rig.has("hip_back")), 0.72)
	_legs.append([back, "back"])
	if _rig.parts.has("arm"):
		var arm := _part("arm", _parts, _point("shoulder_back", "arm"), 0.7)
		_arms.append([arm, "back"])
	var front := _part("leg", _parts, _point("hip_front", "leg") if _rig.has("hip_front") else leg)
	_legs.append([front, "front"])
	_body = _part("body", _parts, _anchor("body"))
	_head = _part("head", _body, _anchor("head") - _anchor("body"))
	if _rig.parts.has("arm"):
		var arm := _part("arm", _body, _anchor("arm") - _anchor("body"))
		_arms.append([arm, "front"])


func _build_quadruped() -> void:
	var body_at := _anchor("body")
	var far_hind := _part("leg_hind", _parts, _point("far_hind", "leg_hind") + Vector2(10, 0) * float(not _rig.has("far_hind")), 0.7)
	_legs.append([far_hind, "far_hind"])
	var far_front := _part("leg_front", _parts, _point("far_front", "leg_front") + Vector2(10, 0) * float(not _rig.has("far_front")), 0.7)
	_legs.append([far_front, "far_front"])
	_tail = _part("tail", _parts, _anchor("tail"))
	var hind := _part("leg_hind", _parts, _anchor("leg_hind"))
	_legs.append([hind, "hind"])
	var front := _part("leg_front", _parts, _anchor("leg_front"))
	_legs.append([front, "front"])
	_body = _part("body", _parts, body_at)
	_head = _part("head", _body, _anchor("head") - body_at)


func set_hue_shift(shift: float) -> void:
	_hue_material.set_shader_parameter("hue_shift", shift)


func flash() -> void:
	_flash = 1.0


func blend_rate() -> float:
	return 14.0


func target_pose(delta: float) -> Dictionary:
	if character == "pilo":
		return _pilo_pose(delta)
	var stride := clampf(absf(speed) / run_speed, 0.0, 1.0)
	match state:
		"walk", "run":
			phase += delta * lerpf(9.0, 15.0, stride)
			var s := sin(phase)
			var amp := lerpf(0.45, 0.75, stride)
			return {"lean": lerpf(0.05, 0.14, stride), "bob": -absf(sin(phase)) * lerpf(5.0, 11.0, stride),
				"front": s * amp, "back": -s * amp, "arm": -s * amp * 0.9, "head": sin(phase * 2.0) * 0.03 - 0.03, "squash": 0.0}
		"jump":
			return {"lean": -0.06, "bob": 0.0, "front": 0.7, "back": -0.35, "arm": -1.6, "head": -0.1, "squash": 0.0}
		"fall":
			return {"lean": 0.04, "bob": 0.0, "front": 0.35, "back": -0.2, "arm": -1.1, "head": 0.06, "squash": 0.0}
		"glide":
			return {"lean": 0.0, "bob": sin(t * 4.0) * 3.0, "front": 0.2, "back": -0.2, "arm": -2.6, "head": -0.06, "squash": 0.0}
		"dash":
			return {"lean": 0.3, "bob": 0.0, "front": 0.9, "back": -0.8, "arm": 1.0, "head": -0.12, "squash": 0.0}
		"skid":
			return {"lean": -0.2, "bob": 0.0, "front": 0.6, "back": 0.15, "arm": 0.8, "head": 0.1, "squash": 0.0}
		"hurt":
			return {"lean": -0.3, "bob": 0.0, "front": 0.5, "back": -0.5, "arm": -1.2, "head": 0.2, "squash": 0.0}
		"stomp":
			return {"lean": 0.0, "bob": 0.0, "front": 0.3, "back": -0.3, "arm": -0.8, "head": -0.08, "squash": 0.0}
		"celebrate":
			return {"lean": -0.05, "bob": -absf(sin(t * 7.0)) * 10.0, "front": 0.15, "back": -0.15, "arm": -2.4 + sin(t * 14.0) * 0.3,
				"head": sin(t * 6.0) * 0.12, "squash": 0.0}
		"lens":
			return {"lean": 0.0, "bob": 0.0, "front": 0.1, "back": -0.1, "arm": -1.3, "head": -0.15, "squash": 0.0}
		_:
			var breath := sin(t * 2.4)
			return {"lean": 0.0, "bob": breath * 1.2, "front": 0.04, "back": -0.04, "arm": sin(t * 1.2) * 0.05,
				"head": sin(t * 0.9) * 0.05, "squash": breath * 0.012}


func _pilo_pose(delta: float) -> Dictionary:
	match state:
		"run":
			var stride := clampf(absf(speed) / run_speed, 0.3, 1.0)
			phase += delta * lerpf(11.0, 17.0, stride)
			var s := sin(phase)
			return {"lean": 0.04, "bob": -absf(sin(phase)) * 9.0 * stride, "front": s * 0.6, "back": -s * 0.6,
				"head": sin(phase * 2.0) * 0.04, "tail": 0.3 + sin(phase) * 0.25, "squash": 0.0}
		"leap", "fly":
			return {"lean": -0.08, "bob": sin(t * 5.0) * 4.0, "front": 0.8, "back": -0.8, "head": -0.06,
				"tail": 0.6 + sin(t * 8.0) * 0.12, "squash": 0.0}
		"attack":
			return {"lean": 0.25, "bob": -8.0, "front": 1.0, "back": -0.6, "head": 0.1, "tail": 0.8, "squash": 0.0}
		"happy":
			return {"lean": 0.0, "bob": -absf(sin(t * 8.0)) * 16.0, "front": 0.2, "back": -0.2, "head": sin(t * 10.0) * 0.1,
				"tail": sin(t * 18.0) * 0.5, "squash": 0.0}
		"sad":
			return {"lean": 0.05, "bob": 0.0, "front": 0.0, "back": 0.0, "head": 0.18, "tail": -0.35, "squash": 0.0}
		_:
			var breath := sin(t * 2.6)
			return {"lean": 0.0, "bob": breath * 1.0, "front": 0.0, "back": 0.0, "head": sin(t * 1.3) * 0.06,
				"tail": sin(t * 3.0) * 0.35, "squash": breath * 0.015}


func _process(delta: float) -> void:
	super(delta)
	if _body == null:
		return
	_flash = maxf(0.0, _flash - delta * 3.0)
	# a whole rendered pose for this action, if there is one
	var pose_sprite: Sprite2D = _poses.get(state)
	if pose_sprite == null and state == "fall":
		pose_sprite = _poses.get("jump")
	if pose_sprite == null and state == "leap":
		pose_sprite = _poses.get("fly")
	for key in _poses:
		_poses[key].visible = _poses[key] == pose_sprite
	_parts.visible = pose_sprite == null
	if pose_sprite:
		pose_sprite.rotation = p("lean") * 0.5
		pose_sprite.position.y = -float(pose_sprite.get_meta("lift")) + p("bob") / _s
		pose_sprite.scale.y = absf(pose_sprite.scale.x) * (1.0 + p("squash"))
	_body.rotation = p("lean")
	_body.position.y = _anchor("body").y + p("bob") / _s
	_body.scale = Vector2(1.0 - p("squash"), 1.0 + p("squash"))
	_head.rotation = p("head") - p("lean") * 0.4
	if _tail:
		_tail.rotation = p("tail")
		_tail.position.y = _anchor("tail").y + p("bob") * 0.8 / _s
	for leg in _legs:
		var sprite: Sprite2D = leg[0]
		match String(leg[1]):
			"front", "far_hind":
				sprite.rotation = -p("front")
			_:
				sprite.rotation = -p("back")
	for arm in _arms:
		var sprite: Sprite2D = arm[0]
		sprite.rotation = -p("arm") if arm[1] == "front" else p("arm") * 0.8
	modulate = Color(1, 1, 1).lerp(Color(1.6, 0.6, 0.6), _flash)
	if state == "hurt" or expression == "hurt":
		modulate = Color(1.4, 0.8, 0.8)


func _draw() -> void:
	if character == "pilo" and (state == "fly" or state == "leap"):
		var aura := 1.0 + sin(t * 6.0) * 0.08
		draw_circle(Vector2(0, -40), 70.0 * aura, Color(glow, 0.12))
		draw_circle(Vector2(0, -40), 48.0 * aura, Color(glow, 0.16))
