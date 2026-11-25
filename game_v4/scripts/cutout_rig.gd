class_name CutoutRig
extends Node2D
## A cut-out puppet (docs/45 section 1): separate body parts on a skeleton, posed every frame from the hero's motion,
## so walking, running, jumping, gliding and striking are smooth and continuous (no frame sheets).
## Each part is drawn from the painted parts sheet when it is there (art/chars/<who>/<part>.png, cut by
## tools/cut_parts.py), otherwise as a soft placeholder shape (art made by code is only a stand-in, CLAUDE.md rule 10).
## Rig space: facing right, feet at y = 0. The poses blend toward their targets, so changes are never sudden.

const OUTLINE := Color("3b2416")

var who := "grandfather"
var body: HeroBody
var t := 0.0

## pose values (radians / px); limbs: 0 = hanging straight down, negative = swung forward
var p := {"lean": 0.0, "bob": 0.0, "thigh_f": 0.0, "knee_f": 0.1, "thigh_b": 0.0, "knee_b": 0.1, "foot_f": 0.0, "foot_b": 0.0,
	"sh_f": 0.1, "el_f": -0.4, "sh_b": -0.1, "el_b": -0.4, "head": 0.0, "cloak": 0.2, "spread": 0.0, "staff": 0.0}
var _phase := 0.0
var _cloak_v := 0.0
var _cloak := 0.2
var _tex := {}

const PART_SIZE := {"thigh": 38.0, "shin": 36.0, "upper": 28.0, "fore": 26.0, "torso": 50.0}
const COL := {"skin": Color("c98b5a"), "tunic": Color("e8d2a0"), "sash": Color("2a9d8f"), "trousers": Color("6b4a2e"),
	"boot": Color("4a2f1c"), "cloak": Color("1f6f78"), "trim": Color("e9c46a"), "hair": Color("2b1d14"), "staff": Color("8a5a2b")}


func _ready() -> void:
	for part in ["head", "torso", "pelvis", "upper", "fore", "hand", "thigh", "shin", "foot", "cloak", "cloak_open", "staff"]:
		var path := "res://art/chars/%s/%s.png" % [who, part]
		if ResourceLoader.exists(path):
			_tex[part] = load(path)


func _process(delta: float) -> void:
	t += delta
	if body == null:
		return
	var target := _target_pose(delta)
	var k := 1.0 - exp(-delta * 18.0)
	for key in target:
		p[key] = lerpf(float(p[key]), float(target[key]), k)
	# the cloak follows the motion with a little spring
	var want := clampf(0.25 + absf(body.velocity.x) / 700.0 * 0.9 - body.velocity.y / 2200.0, -0.2, 1.4)
	_cloak_v += (want - _cloak) * 90.0 * delta
	_cloak_v *= exp(-delta * 7.0)
	_cloak += _cloak_v * delta
	p.cloak = _cloak
	scale = Vector2(body.facing * (1.0 + body.land_squash * 0.16), 1.0 - body.land_squash * 0.2)
	if body.state == "jump":
		scale.y *= 1.0 + clampf(-body.velocity.y / 1080.0, 0.0, 1.0) * 0.08
	queue_redraw()


func _target_pose(delta: float) -> Dictionary:
	var v := body.velocity
	var speed := absf(v.x)
	var amt := clampf(speed / HeroBody.RUN_MAX, 0.0, 1.0)
	match body.state:
		"run", "idle":
			_phase += speed * delta * TAU / 190.0
			var s := sin(_phase)
			var c := cos(_phase)
			var breathe := sin(t * 2.2) * (1.0 - amt)
			return {"lean": 0.16 * amt, "bob": -absf(c) * 6.0 * amt + breathe * 1.5,
				"thigh_f": -0.85 * s * amt, "knee_f": 0.12 + 1.15 * clampf(-c, 0.0, 1.0) * amt + 0.25 * amt,
				"thigh_b": 0.85 * s * amt, "knee_b": 0.12 + 1.15 * clampf(c, 0.0, 1.0) * amt + 0.25 * amt,
				"foot_f": 0.3 * s * amt, "foot_b": -0.3 * s * amt,
				"sh_f": 0.75 * s * amt + 0.08 + breathe * 0.04, "el_f": -0.5 - 0.6 * amt,
				"sh_b": -0.75 * s * amt - 0.08, "el_b": -0.5 - 0.6 * amt,
				"head": -0.08 * amt + breathe * 0.03, "spread": 0.0, "staff": 0.0}
		"skid":
			return {"lean": -0.28, "bob": 4.0, "thigh_f": -0.75, "knee_f": 0.1, "thigh_b": 0.35, "knee_b": 0.9, "foot_f": -0.3, "foot_b": 0.2,
				"sh_f": -0.9, "el_f": -0.3, "sh_b": 0.7, "el_b": -0.5, "head": 0.12, "spread": 0.0, "staff": 0.0}
		"jump":
			return {"lean": 0.1, "bob": -4.0, "thigh_f": -1.1, "knee_f": 1.5, "thigh_b": -0.15, "knee_b": 0.8, "foot_f": 0.4, "foot_b": 0.5,
				"sh_f": -2.5, "el_f": -0.2, "sh_b": 0.9, "el_b": -0.6, "head": -0.15, "spread": 0.0, "staff": 0.0}
		"fall":
			var w := sin(t * 9.0) * 0.12
			return {"lean": 0.04, "bob": 0.0, "thigh_f": -0.45 + w, "knee_f": 0.5, "thigh_b": 0.25 - w, "knee_b": 0.35, "foot_f": 0.2, "foot_b": 0.1,
				"sh_f": -1.7 + w, "el_f": -0.4, "sh_b": 1.5 - w, "el_b": -0.4, "head": 0.1, "spread": 0.0, "staff": 0.0}
		"glide":
			var sway := sin(t * 3.0) * 0.18
			return {"lean": 0.12, "bob": sin(t * 3.0) * 3.0, "thigh_f": -0.2 + sway, "knee_f": 0.35, "thigh_b": 0.2 + sway, "knee_b": 0.45,
				"foot_f": 0.3, "foot_b": 0.3, "sh_f": -2.0, "el_f": -0.2, "sh_b": 2.0, "el_b": 0.2, "head": -0.05, "spread": 1.0, "staff": 0.0}
		"wall":
			return {"lean": -0.15, "bob": 0.0, "thigh_f": -0.9, "knee_f": 1.3, "thigh_b": -0.2, "knee_b": 0.9, "foot_f": -0.6, "foot_b": -0.4,
				"sh_f": -2.6, "el_f": -0.5, "sh_b": -2.2, "el_b": -0.7, "head": 0.2, "spread": 0.0, "staff": 0.0}
		"strike":
			var k := 1.0 - body.strike_t / 0.32          # 0 -> 1 through the swing
			var sw := lerpf(-2.7, 0.9, smoothstep(0.0, 0.55, k))
			return {"lean": 0.22, "bob": 2.0, "thigh_f": -0.6, "knee_f": 0.6, "thigh_b": 0.5, "knee_b": 0.3, "foot_f": 0.1, "foot_b": -0.2,
				"sh_f": sw, "el_f": -0.15, "sh_b": 0.8, "el_b": -0.6, "head": -0.1, "spread": 0.0, "staff": 1.0}
	return p


# ---------------------------------------------------------------- drawing (forward kinematics)

func _draw() -> void:
	var hip := Vector2(0, -78 + float(p.bob))
	var lean := float(p.lean)
	var torso_dir := Vector2(0, -1).rotated(lean)
	var shoulder := hip + torso_dir * 44.0
	var neck := hip + torso_dir * 52.0
	# back limbs (darker), cloak, body, front limbs
	_leg(hip + Vector2(-4, 4), float(p.thigh_b), float(p.knee_b), float(p.foot_b), 0.78)
	_arm(shoulder + Vector2(-3, 0), float(p.sh_b), float(p.el_b), 0.78, false)
	_cloak_draw(shoulder, lean)
	_torso(hip, lean)
	_leg(hip + Vector2(4, 4), float(p.thigh_f), float(p.knee_f), float(p.foot_f), 1.0)
	_head(neck, lean + float(p.head))
	_arm(shoulder + Vector2(3, 0), float(p.sh_f), float(p.el_f), 1.0, true)


func _shade(c: Color, k: float) -> Color:
	return c.darkened(1.0 - k) if k < 1.0 else c


## A soft limb segment from a to b: a capsule with an outline (placeholder for the painted part).
func _seg(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	draw_line(a, b, OUTLINE, w + 5.0)
	draw_circle(a, (w + 5.0) * 0.5, OUTLINE)
	draw_circle(b, (w + 5.0) * 0.5, OUTLINE)
	draw_line(a, b, col, w)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)
	# a soft highlight along the limb
	var n := (b - a).orthogonal().normalized() * w * 0.22
	draw_line(a - n, b - n, col.lightened(0.18), w * 0.25)


func _part_tex(part: String, a: Vector2, angle: float, length: float, k: float) -> bool:
	if not _tex.has(part):
		return false
	var tex: Texture2D = _tex[part]
	var sc := length / maxf(float(tex.get_height()), 1.0)
	draw_set_transform(a, angle, Vector2(sc, sc))
	draw_texture(tex, Vector2(-tex.get_width() * 0.5, 0), Color(k, k, k))
	draw_set_transform(Vector2.ZERO)
	return true


func _leg(hip: Vector2, thigh: float, knee: float, foot_a: float, k: float) -> void:
	var knee_p := hip + Vector2(0, PART_SIZE.thigh).rotated(thigh)
	var ankle := knee_p + Vector2(0, PART_SIZE.shin).rotated(thigh + knee)
	var toe := ankle + Vector2(20, 0).rotated(thigh + knee + foot_a - (thigh + knee) * 0.7)
	if not _part_tex("thigh", hip, thigh, PART_SIZE.thigh + 8.0, k):
		_seg(hip, knee_p, 19.0, _shade(COL.trousers, k))
	if not _part_tex("shin", knee_p, thigh + knee, PART_SIZE.shin + 8.0, k):
		_seg(knee_p, ankle, 16.0, _shade(COL.trousers, k))
	if not _part_tex("foot", ankle, thigh + knee, 26.0, k):
		_seg(ankle + Vector2(-2, 2), toe + Vector2(0, 2), 15.0, _shade(COL.boot, k))


func _arm(sh: Vector2, shoulder: float, elbow: float, k: float, front: bool) -> void:
	var el := sh + Vector2(0, PART_SIZE.upper).rotated(shoulder)
	var wr := el + Vector2(0, PART_SIZE.fore).rotated(shoulder + elbow)
	if not _part_tex("upper", sh, shoulder, PART_SIZE.upper + 8.0, k):
		_seg(sh, el, 15.0, _shade(COL.tunic, k))
	if not _part_tex("fore", el, shoulder + elbow, PART_SIZE.fore + 8.0, k):
		_seg(el, wr, 12.0, _shade(COL.skin, k))
	if front:
		# the walking staff in the front hand
		var dir := Vector2(0, 1).rotated(shoulder + elbow + 1.35 - float(p.staff) * 0.4)
		if not _part_tex("staff", wr - dir * 30.0, dir.angle() - PI * 0.5, 120.0, k):
			_seg(wr - dir * 34.0, wr + dir * 82.0, 7.0, _shade(COL.staff, k))
			draw_circle(wr - dir * 36.0, 7.0, COL.trim)
	if not _part_tex("hand", wr, shoulder + elbow, 18.0, k):
		draw_circle(wr, 9.5, OUTLINE)
		draw_circle(wr, 7.5, _shade(COL.skin, k))


func _torso(hip: Vector2, lean: float) -> void:
	if _part_tex("torso", hip, lean + PI, PART_SIZE.torso + 10.0, 1.0):
		return
	var up: Vector2 = Vector2(0, -1).rotated(lean)
	var side: Vector2 = up.orthogonal()
	var pts := PackedVector2Array([hip + side * 17.0 + up * 2.0, hip + side * 15.0 + up * 50.0, hip - side * 14.0 + up * 52.0,
		hip - side * 18.0 + up * 2.0, hip + up * -6.0])
	draw_colored_polygon(pts, OUTLINE)
	var inner := PackedVector2Array()
	var cen := hip + up * 24.0
	for q in pts:
		inner.append(cen + (q - cen) * 0.86)
	draw_colored_polygon(inner, COL.tunic)
	# sash and belt
	draw_line(hip + side * 16.0 + up * 10.0, hip - side * 16.0 + up * 10.0, COL.sash, 9.0)
	draw_line(hip + side * 12.0 + up * 40.0, hip - side * 10.0 + up * 14.0, COL.sash.lightened(0.15), 5.0)


func _head(neck: Vector2, tilt: float) -> void:
	var c := neck + Vector2(4, -20).rotated(tilt)
	if _part_tex("head", neck, tilt + PI, 52.0, 1.0):
		return
	draw_circle(c, 24.0, OUTLINE)
	draw_circle(c, 21.0, COL.skin)
	# hair and beard
	draw_circle(c + Vector2(-5, -10).rotated(tilt), 18.0, COL.hair)
	draw_circle(c + Vector2(-14, -2).rotated(tilt), 11.0, COL.hair)
	draw_circle(c + Vector2(8, -17).rotated(tilt), 8.0 + sin(t * 4.0) * 0.8, COL.hair)
	draw_arc(c + Vector2(4, 7).rotated(tilt), 13.0, 0.2 + tilt, 2.4 + tilt, 12, COL.hair, 6.0)
	# eye, brow and nose (looking ahead)
	var blink := 1.0 if fmod(t, 3.7) > 0.12 else 0.15
	draw_set_transform(c + Vector2(10, -2).rotated(tilt), tilt, Vector2(1.0, blink))
	draw_circle(Vector2.ZERO, 4.6, Color.WHITE)
	draw_circle(Vector2(1.4, 0.4), 2.8, Color("1d100a"))
	draw_set_transform(Vector2.ZERO)
	draw_line(c + Vector2(5, -9).rotated(tilt), c + Vector2(15, -8).rotated(tilt), COL.hair, 3.0)
	draw_circle(c + Vector2(21, 2).rotated(tilt), 4.0, COL.skin.darkened(0.12))


func _cloak_draw(sh: Vector2, lean: float) -> void:
	var spread := float(p.spread)
	if spread > 0.3 and _tex.has("cloak_open"):
		_part_tex("cloak_open", sh, -PI * 0.5, 150.0, 1.0)
		return
	var a := float(p.cloak) * (1.0 - spread) + spread * 1.45
	var len := lerpf(62.0, 88.0, spread)
	var back := Vector2(0, 1).rotated(lean + a)
	var tip := sh + back * len
	var mid := sh + back * len * 0.55 + Vector2(-6, 0)
	var w := lerpf(16.0, 30.0, spread)
	var flutter := sin(t * 11.0) * (3.0 + spread * 5.0)
	var side: Vector2 = back.orthogonal()
	var pts := PackedVector2Array([sh + side * 10.0, mid + side * w, tip + side * (w * 0.8) + back * flutter,
		tip - side * (w * 0.6), mid - side * (w * 0.6), sh - side * 8.0])
	draw_colored_polygon(pts, OUTLINE)
	var cen := (sh + tip) * 0.5
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(cen + (q - cen) * 0.88)
	draw_colored_polygon(inner, COL.cloak)
	draw_line(tip + side * (w * 0.7), tip - side * (w * 0.5), COL.trim, 4.0)
