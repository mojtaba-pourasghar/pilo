class_name SkeletonRig
extends CharacterRig
## A character made of separate painted parts (assets/characters/<name>/<part>.png + skel.json,
## cut by tools/art/make_skel_rig.py from the approved parts sheet) and moved joint by joint:
## walk/run cycle, jump, fall, hurt, celebrate, a bow-aim stance, spring scarves, breathing,
## squash and stretch. Same states/API as the other rigs (state, speed, run_speed, expression)
## so PlayerController can use it unchanged. Origin = feet, facing right (flip the parent).
##
## docs/34 tables: stand 4.2 s breathing loop, walk 720 ms, run 520 ms, scarf spring k=40, z=0.7.

const FOLDER := "res://assets/characters/%s/"

@export var character := "arsam"

## Bow stance (Arsam): aiming = true raises the bow arm toward aim_angle (radians, 0 = forward).
var aiming := false
var aim_angle := 0.0
var draw_amount := 0.0                 ## 0..1 bow draw amount (pulls the string hand back)
## What the other hand carries: "" | "egg" | "sling" | "staff" | "lantern" (grandfather)
var holding := ""
var squash := Vector2.ONE

var _skel: Dictionary = {}
var _root: Node2D
var _nodes: Dictionary = {}      # part -> Node2D (joint)
var _sprites: Dictionary = {}    # part -> Sprite2D
var _parts: Dictionary = {}
var _spring: Dictionary = {}     # scarf joint -> [angle, velocity]
var _spring_base: Dictionary = {}
var _prev_speed := 0.0
var _flash := 0.0


static func available(name: String) -> bool:
	return FileAccess.file_exists(FOLDER % name + "skel.json")


static func make(name: String) -> SkeletonRig:
	var rig := SkeletonRig.new()
	rig.character = name
	return rig


func _ready() -> void:
	var file := FileAccess.open(FOLDER % character + "skel.json", FileAccess.READ)
	_skel = JSON.parse_string(file.get_as_text())
	_parts = _skel.parts
	_root = Node2D.new()
	var s := float(_skel.scale)
	_root.scale = Vector2(s, s)
	add_child(_root)
	var hip := Node2D.new()
	hip.position = Vector2(_skel.hip[0], _skel.hip[1])
	_root.add_child(hip)
	_nodes["hip"] = hip
	# parents first
	var pending: Array = _parts.keys()
	var guard := 0
	while not pending.is_empty() and guard < 20:
		guard += 1
		for pname in pending.duplicate():
			var info: Dictionary = _parts[pname]
			if not _nodes.has(info.parent):
				continue
			var joint := Node2D.new()
			joint.position = Vector2(info.at[0], info.at[1])
			_nodes[info.parent].add_child(joint)
			joint.z_as_relative = false
			joint.z_index = int(info.z)
			var spr := Sprite2D.new()
			spr.texture = load(FOLDER % character + String(info.file))
			spr.centered = false
			spr.offset = Vector2(-info.pivot[0], -info.pivot[1])
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			joint.add_child(spr)
			joint.rotation_degrees = float(info.get("rot", 0.0))
			_nodes[pname] = joint
			_sprites[pname] = spr
			if info.has("spring"):
				_spring[pname] = [0.0, 0.0]
				_spring_base[pname] = deg_to_rad(float(info.get("rot", 0.0)))
			pending.erase(pname)
	_refresh_visibility()


## A short bow stance after a shot (the player calls this when it fires): the string hand
## springs forward as the arrow leaves. Nothing happens for characters without a bow.
func aim_pulse(seconds := 0.35, angle := 0.0) -> void:
	if not _nodes.has("bow"):
		return
	_aim_time = seconds
	_aim_total = seconds
	aim_angle = angle


var _aim_time := 0.0
var _aim_total := 0.35


func _process(delta: float) -> void:
	if _aim_time > 0.0:
		_aim_time = maxf(0.0, _aim_time - delta)
		aiming = true
		draw_amount = clampf(_aim_time / _aim_total * 1.2 - 0.2, 0.0, 1.0)
		if _aim_time == 0.0:
			aiming = false
			draw_amount = 0.0
	super._process(delta)
	if _root == null:
		return
	_apply(delta)


# --- State -> joint targets (same names/values family as HeroRig) -----------------

func target_pose(delta: float) -> Dictionary:
	var stride := clampf(absf(speed) / run_speed, 0.0, 1.0)
	match state:
		"walk", "run":
			phase += delta * lerpf(8.7, 12.1, stride)   # 720 ms .. 520 ms per cycle
			var amp := lerpf(0.5, 0.95, stride)
			var s := sin(phase)
			var c := cos(phase)
			return {
				"lean": lerpf(0.05, 0.14, stride), "bob": -absf(sin(phase)) * lerpf(2.5, 5.0, stride),
				"hipF": s * amp, "hipB": -s * amp,
				"kneeF": 0.15 + maxf(0.0, c) * lerpf(0.8, 1.4, stride),
				"kneeB": 0.15 + maxf(0.0, -c) * lerpf(0.8, 1.4, stride),
				"shF": -s * lerpf(0.4, 0.75, stride), "shB": s * lerpf(0.4, 0.75, stride),
				"elF": lerpf(0.3, 0.9, stride), "elB": lerpf(0.3, 0.9, stride),
				"head": -0.04, "sx": 1.0, "sy": 1.0,
			}
		"jump":
			return {"lean": 0.08, "bob": 0.0, "hipF": 1.0, "hipB": -0.35, "kneeF": 1.5, "kneeB": 0.7,
				"shF": 1.7, "shB": -1.1, "elF": 0.9, "elB": 0.6, "head": -0.1, "sx": 0.94, "sy": 1.06}
		"fall":
			var flap := sin(t * 14.0) * 0.18
			return {"lean": 0.02, "bob": 0.0, "hipF": 0.45, "hipB": -0.25, "kneeF": 0.6, "kneeB": 0.35,
				"shF": 1.9 + flap, "shB": -1.6 - flap, "elF": 0.25, "elB": 0.25, "head": 0.1, "sx": 0.97, "sy": 1.03}
		"glide":
			var sway := sin(t * 4.0) * 0.15
			return {"lean": 0.05, "bob": 0.0, "hipF": 0.3 + sway, "hipB": -0.2 + sway, "kneeF": 0.4, "kneeB": 0.3,
				"shF": 2.9, "shB": 2.7, "elF": 0.1, "elB": 0.1, "head": -0.15, "sx": 1.0, "sy": 1.0}
		"dash":
			return {"lean": 0.42, "bob": 0.0, "hipF": 1.15, "hipB": -1.0, "kneeF": 0.7, "kneeB": 0.5,
				"shF": -1.0, "shB": -1.3, "elF": 0.4, "elB": 0.3, "head": -0.25, "sx": 1.06, "sy": 0.94}
		"skid":
			return {"lean": -0.2, "bob": 0.0, "hipF": 0.75, "hipB": 0.05, "kneeF": 0.0, "kneeB": 0.8,
				"shF": 1.3, "shB": 0.9, "elF": 0.2, "elB": 0.2, "head": 0.1, "sx": 1.0, "sy": 1.0}
		"hurt":
			return {"lean": -0.3, "bob": 0.0, "hipF": 0.6, "hipB": -0.5, "kneeF": 0.5, "kneeB": 0.5,
				"shF": 1.8, "shB": -1.9, "elF": 0.7, "elB": 0.7, "head": 0.2, "sx": 1.0, "sy": 1.0}
		"celebrate":
			var wave := sin(t * 12.0) * 0.35
			return {"lean": -0.05, "bob": -absf(sin(t * 6.0)) * 4.0, "hipF": 0.1, "hipB": -0.1,
				"kneeF": 0.1, "kneeB": 0.1, "shF": 2.9 + wave, "shB": -2.7 - wave, "elF": 0.3, "elB": 0.3,
				"head": -0.1, "sx": 1.0, "sy": 1.0}
		"crouch", "crawl":
			return {"lean": 0.25, "bob": 14.0, "hipF": 1.1, "hipB": -0.1, "kneeF": 2.0, "kneeB": 1.6,
				"shF": 0.6, "shB": 0.2, "elF": 0.8, "elB": 0.5, "head": -0.1, "sx": 1.06, "sy": 0.9}
		_:
			var breath := sin(t * TAU / 4.2)           # 4.2 s breathing loop
			return {"lean": 0.0, "bob": breath * 0.8, "hipF": 0.06, "hipB": -0.06, "kneeF": 0.05, "kneeB": 0.05,
				"shF": 0.12 + breath * 0.05, "shB": -0.1 - breath * 0.05, "elF": 0.3, "elB": 0.25,
				"head": sin(t * 0.9) * 0.04, "sx": 1.0 + breath * 0.008, "sy": 1.0 - breath * 0.008}


func blend_rate() -> float:
	return 16.0


var show_shadow := true


func _draw() -> void:
	if show_shadow:
		draw_colored_polygon(ellipse_points(Vector2(0, -2), Vector2(24, 6)), Color(0, 0, 0, 0.2))


# --- Applying the pose to the part joints ------------------------------------------

func _rot(part: String, value: float) -> void:
	if _nodes.has(part):
		_nodes[part].rotation = value


func _apply(delta: float) -> void:
	var hip: Node2D = _nodes["hip"]
	hip.position.y = float(_skel.hip[1]) + p("bob") / float(_skel.scale) * 0.35
	_root.scale = Vector2(float(_skel.scale) * p("sx") * squash.x, float(_skel.scale) * p("sy") * squash.y)
	_rot("torso", p("lean"))
	var head_rot := p("head") - p("lean") * 0.35
	for h in ["head", "head_happy", "head_angry", "head_hurt", "head_worry"]:
		_rot(h, head_rot)
	_refresh_visibility()

	# arms: front = nearer the camera, swings opposite to the back one. Forward = negative angle.
	var sh_f := -p("shF")
	var sh_b := -p("shB")
	var el_f := -p("elF") * 0.5
	var el_b := -p("elB") * 0.5
	if aiming:
		# bow arm points at aim_angle; string hand is pulled back by draw
		sh_f = -(PI * 0.5 + aim_angle) + 0.0
		el_f = 0.0
		sh_b = -(PI * 0.5 + aim_angle) + 0.25 + draw_amount * 0.9
		el_b = -0.35 - draw_amount * 1.1
	elif holding == "egg":
		sh_f = -0.9
		sh_b = -0.9
		el_f = -1.0
		el_b = -1.0
	_apply_arm("f", sh_f, el_f)
	_apply_arm("b", sh_b, el_b)
	# held items
	_rot("bow", 0.0)
	_rot("staff", 0.0 if holding == "staff" else -0.3)

	# legs: thigh swings (-hip = forward), shin bends back (+knee), boot stays level
	_apply_leg("f", -p("hipF"), p("kneeF"))
	_apply_leg("b", -p("hipB"), p("kneeB"))

	_update_springs(delta)


func _apply_arm(side: String, sh: float, el: float) -> void:
	var sleeve := "sleeve_" + side
	var arm := "arm_" + side
	var alt := _active_alt(side)
	if _nodes.has(sleeve):
		_rot(sleeve, sh)
		_rot(arm, el)
		if alt != "":
			_rot(alt, el)
	else:                              # no separate upper arm: swing the whole arm piece
		_rot(arm, sh + el)
		if alt != "":
			_rot(alt, sh + el)


func _apply_leg(side: String, hip_angle: float, knee: float) -> void:
	var thigh := "thigh_" + side
	var shin := "shin_" + side
	var boot := "boot_" + side
	var shin_rot := knee
	if _nodes.has(thigh):
		_rot(thigh, hip_angle)
	else:                              # trousers are one piece: the shin swings from the hem
		shin_rot = hip_angle * 0.7 + knee * 0.6
	_rot(shin, shin_rot)
	var total := (hip_angle if _nodes.has(thigh) else 0.0) + shin_rot
	_rot(boot, -total * 0.65 + (0.0 if state != "jump" else -0.25))


func _update_springs(delta: float) -> void:
	# scarf tails: damped spring toward a target that depends on speed; wind keeps them lively
	var drive := -clampf(speed / maxf(run_speed, 1.0), -1.0, 1.0) * 0.9
	var accel := (speed - _prev_speed) / maxf(delta, 0.001)
	_prev_speed = speed
	drive += -clampf(accel / 4000.0, -0.5, 0.5)
	if state == "jump" or state == "fall":
		drive -= 0.5
	var k := 40.0
	var z := 0.7
	var idx := 0
	for name in _spring:
		idx += 1
		var sp: Array = _spring[name]
		var target := drive * (1.0 if idx == 1 else 0.8) + sin(t * (1.9 + idx * 0.6)) * 0.07
		var acc: float = k * (target - sp[0]) - 2.0 * z * sqrt(k) * sp[1]
		sp[1] += acc * delta
		sp[0] += sp[1] * delta
		_nodes[name].rotation = _spring_base[name] + clampf(sp[0], -1.4, 1.4)


# --- Which piece is visible -------------------------------------------------------

func _active_alt(side: String) -> String:
	## hand pieces that replace the plain arm: bow hands (Arsam), staff/sling/lantern (grandfather)
	var want := ""
	if aiming:
		want = "hand_grip" if side == "f" else "hand_pull"
	elif holding == "staff" and side == "b":
		want = "hand_staff"
	elif holding == "sling" and side == "f":
		want = "hand_sling"
	elif holding == "lantern" and side == "f":
		want = "hand_lamp"
	return want if _nodes.has(want) else ""


func _head_part() -> String:
	var want := "head"
	match expression:
		"happy":
			want = "head_happy"
		"hurt":
			want = "head_hurt"
		"angry":
			want = "head_angry" if _nodes.has("head_angry") else "head_worry"
		"worried":
			want = "head_worry" if _nodes.has("head_worry") else "head"
	if state == "hurt":
		want = "head_hurt"
	elif state == "celebrate":
		want = "head_happy"
	return want if _nodes.has(want) else "head"


func _refresh_visibility() -> void:
	var head := _head_part()
	var alts := {"f": _active_alt("f"), "b": _active_alt("b")}
	for pname in _parts:
		var info: Dictionary = _parts[pname]
		var vis := true
		if info.has("expr"):
			vis = pname == head
		elif info.has("alt"):
			vis = _is_alt_active(pname, alts)
		elif pname.begins_with("arm_"):
			vis = alts[pname.substr(4)] == ""
		elif info.has("hidden"):
			vis = _hidden_part_active(pname)
		_nodes[pname].visible = vis


func _is_alt_active(pname: String, alts: Dictionary) -> bool:
	return alts["f"] == pname or alts["b"] == pname


func _hidden_part_active(pname: String) -> bool:
	match pname:
		"bow":
			return aiming
		"arrow":
			return aiming and draw_amount > 0.05
		"staff":
			return holding == "staff"
		"egg":
			return holding == "egg"
		"sling_pouch":
			return false
	return false
