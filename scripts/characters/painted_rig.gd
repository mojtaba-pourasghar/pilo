class_name PaintedRig
extends CharacterRig
## A painted character made of separate part pictures (assets/characters/<name>/: head, body,
## legs, tail and rig.json with the pivots), from the generated character art, animated part by
## part: legs swing in the walk and gallop cycles, the body bobs and
## leans, the head tilts and lags a little behind, Pilo's tail wags. Same states and API
## as the drawn rigs (state, speed, run_speed, phase, expression). Origin = feet.

const FOLDER := "res://assets/characters/%s/"

@export var character := "nima"

var glow := Color(0.4, 0.9, 1.0)
var _rig: Dictionary = {}
var _body: Sprite2D
var _head: Sprite2D
var _tail: Sprite2D
var _legs: Array = []          ## [sprite, kind] kind: "front", "back", "hind", "far_front", "far_hind"
var _hue_material: ShaderMaterial
var _flash := 0.0


func _ready() -> void:
	var file := FileAccess.open(FOLDER % character + "rig.json", FileAccess.READ)
	_rig = JSON.parse_string(file.get_as_text())
	_hue_material = ShaderMaterial.new()
	_hue_material.shader = load("res://assets/vfx/hue_shift.gdshader")
	_hue_material.set_shader_parameter("hue_shift", 0.0)
	if character == "nima":
		_build_nima()
	else:
		_build_pilo()


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


## Where a part's pivot sits, relative to the feet (the rig origin).
func _anchor(part: String) -> Vector2:
	var info: Dictionary = _rig.parts[part]
	return _v(info.box) + _v(info.pivot) - _v(_rig.feet)


func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _build_nima() -> void:
	var back := _part("leg", self, _v(_rig.hip_back) - _v(_rig.feet), 0.78)
	_legs.append([back, "back"])
	var front := _part("leg", self, _v(_rig.hip_front) - _v(_rig.feet))
	_legs.append([front, "front"])
	_body = _part("body", self, _anchor("body"))
	_head = _part("head", _body, _anchor("head") - _anchor("body"))


func _build_pilo() -> void:
	var body_at := _anchor("body")
	var far_hind := _part("leg_hind", self, _v(_rig.far_hind) - _v(_rig.feet), 0.7)
	_legs.append([far_hind, "far_hind"])
	var far_front := _part("leg_front", self, _v(_rig.far_front) - _v(_rig.feet), 0.7)
	_legs.append([far_front, "far_front"])
	_tail = _part("tail", self, _anchor("tail"))
	var hind := _part("leg_hind", self, _anchor("leg_hind"))
	_legs.append([hind, "hind"])
	var front := _part("leg_front", self, _anchor("leg_front"))
	_legs.append([front, "front"])
	_body = _part("body", self, body_at)
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
			return {"lean": lerpf(0.05, 0.16, stride), "bob": -absf(sin(phase)) * lerpf(6.0, 12.0, stride),
				"front": s * amp, "back": -s * amp, "head": sin(phase * 2.0) * 0.03 - 0.03, "squash": 0.0}
		"jump":
			return {"lean": -0.06, "bob": 0.0, "front": 0.7, "back": -0.35, "head": -0.1, "squash": 0.0}
		"fall":
			return {"lean": 0.04, "bob": 0.0, "front": 0.35, "back": -0.2, "head": 0.06, "squash": 0.0}
		"dash":
			return {"lean": 0.32, "bob": 0.0, "front": 0.9, "back": -0.8, "head": -0.12, "squash": 0.0}
		"skid":
			return {"lean": -0.2, "bob": 0.0, "front": 0.6, "back": 0.15, "head": 0.1, "squash": 0.0}
		"hurt":
			return {"lean": -0.3, "bob": 0.0, "front": 0.5, "back": -0.5, "head": 0.2, "squash": 0.0}
		"stomp":
			return {"lean": 0.0, "bob": 0.0, "front": 0.3, "back": -0.3, "head": -0.08, "squash": 0.0}
		"celebrate":
			return {"lean": -0.05, "bob": -absf(sin(t * 7.0)) * 10.0, "front": 0.15, "back": -0.15,
				"head": sin(t * 6.0) * 0.12, "squash": 0.0}
		"lens":
			return {"lean": 0.0, "bob": 0.0, "front": 0.1, "back": -0.1, "head": -0.15, "squash": 0.0}
		_:
			var breath := sin(t * 2.4)
			return {"lean": 0.0, "bob": breath * 1.5, "front": 0.04, "back": -0.04, "head": sin(t * 0.9) * 0.05,
				"squash": breath * 0.012}


func _pilo_pose(delta: float) -> Dictionary:
	match state:
		"run":
			var stride := clampf(absf(speed) / run_speed, 0.3, 1.0)
			phase += delta * lerpf(11.0, 17.0, stride)
			var s := sin(phase)
			return {"lean": 0.04, "bob": -absf(sin(phase)) * 10.0 * stride, "front": s * 0.6, "back": -s * 0.6,
				"head": sin(phase * 2.0) * 0.04, "tail": 0.3 + sin(phase) * 0.25, "squash": 0.0}
		"leap", "fly":
			return {"lean": -0.08, "bob": sin(t * 5.0) * 4.0, "front": 0.8, "back": -0.8, "head": -0.06,
				"tail": 0.6 + sin(t * 8.0) * 0.12, "squash": 0.0}
		"attack":
			return {"lean": 0.25, "bob": -8.0, "front": 1.0, "back": -0.6, "head": 0.1, "tail": 0.8, "squash": 0.0}
		"happy":
			return {"lean": 0.0, "bob": -absf(sin(t * 8.0)) * 18.0, "front": 0.2, "back": -0.2, "head": sin(t * 10.0) * 0.1,
				"tail": sin(t * 18.0) * 0.5, "squash": 0.0}
		"sad":
			return {"lean": 0.05, "bob": 0.0, "front": 0.0, "back": 0.0, "head": 0.18, "tail": -0.35, "squash": 0.0}
		_:
			var breath := sin(t * 2.6)
			return {"lean": 0.0, "bob": breath * 1.2, "front": 0.0, "back": 0.0, "head": sin(t * 1.3) * 0.06,
				"tail": sin(t * 3.0) * 0.35, "squash": breath * 0.015}


func _process(delta: float) -> void:
	super(delta)
	if _body == null:
		return
	_flash = maxf(0.0, _flash - delta * 3.0)
	_body.rotation = p("lean")
	_body.position.y = _anchor("body").y + p("bob")
	_body.scale = Vector2(1.0 - p("squash"), 1.0 + p("squash"))
	_head.rotation = p("head") - p("lean") * 0.4
	if _tail:
		_tail.rotation = p("tail")
		_tail.position.y = _anchor("tail").y + p("bob") * 0.8
	for leg in _legs:
		var sprite: Sprite2D = leg[0]
		match String(leg[1]):
			"front", "far_hind":
				sprite.rotation = -p("front")
			_:
				sprite.rotation = -p("back")
	modulate = Color(1, 1, 1).lerp(Color(1.6, 0.6, 0.6), _flash)
	if state == "hurt" or expression == "hurt":
		modulate = Color(1.4, 0.8, 0.8)


func _draw() -> void:
	if character == "pilo" and (state == "fly" or state == "leap"):
		var aura := 1.0 + sin(t * 6.0) * 0.08
		draw_circle(Vector2(0, -120), 140.0 * aura, Color(glow, 0.12))
		draw_circle(Vector2(0, -120), 95.0 * aura, Color(glow, 0.16))
