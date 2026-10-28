class_name PiloRig
extends CharacterRig
## Pilo the little time fox, drawn in code: orange fur, cream chest and tail tip, big ears,
## blue scarf. Four legs gallop, the tail wags and streams, ears twitch, eyes blink.
## States: idle (sitting), run, leap, fly (magic glide), attack, happy, sad.

const BASE_FUR := Color("f08a2a")
const BASE_FUR_SHADE := Color("c9661a")
const BASE_FUR_LIGHT := Color("ffb15e")
const CREAM := Color("fff1dc")
const EAR_IN := Color("ffc9a8")
const SCARF := Color("3e9be0")
const SCARF_SHADE := Color("2a74b3")
const NOSE := Color("2b1a14")

var glow := Color(0.4, 0.9, 1.0)
var fur := BASE_FUR
var fur_shade := BASE_FUR_SHADE
var fur_light := BASE_FUR_LIGHT


## Pilo's coat colour (shop / rewards): rotates the hue of the fur.
func set_hue_shift(shift: float) -> void:
	fur = _shift(BASE_FUR, shift)
	fur_shade = _shift(BASE_FUR_SHADE, shift)
	fur_light = _shift(BASE_FUR_LIGHT, shift)


static func _shift(c: Color, shift: float) -> Color:
	return Color.from_hsv(fposmod(c.h + shift, 1.0), c.s, c.v, c.a)


func blend_rate() -> float:
	return 12.0


func target_pose(delta: float) -> Dictionary:
	match state:
		"run":
			var stride := clampf(absf(speed) / run_speed, 0.3, 1.0)
			phase += delta * lerpf(10.0, 18.0, stride)
			var s := sin(phase)
			return {"body": 0.0, "lift": -absf(sin(phase)) * 6.0 * stride, "tilt": sin(phase) * 0.08,
				"fl": s * 0.9, "fr": s * 0.9 + 0.5, "bl": -s * 0.9, "br": -s * 0.9 + 0.5,
				"tail": 0.6 + sin(phase * 0.5) * 0.25, "ears": -0.15, "head": -0.05, "sit": 0.0}
		"leap", "fly":
			var flow := sin(t * 8.0) * 0.12
			return {"body": -0.15, "lift": 0.0, "tilt": -0.12, "fl": 1.2, "fr": 1.0, "bl": -1.3, "br": -1.1,
				"tail": 0.9 + flow, "ears": -0.4, "head": -0.1, "sit": 0.0}
		"attack":
			return {"body": 0.25, "lift": -4.0, "tilt": 0.2, "fl": 1.4, "fr": 1.3, "bl": -0.8, "br": -0.6,
				"tail": 1.1, "ears": -0.5, "head": 0.15, "sit": 0.0}
		"happy":
			return {"body": 0.0, "lift": -absf(sin(t * 8.0)) * 10.0, "tilt": 0.0, "fl": 0.3, "fr": -0.2,
				"bl": 0.1, "br": -0.1, "tail": 0.3 + sin(t * 18.0) * 0.5, "ears": 0.1, "head": -0.1, "sit": 0.0}
		"sad":
			return {"body": 0.0, "lift": 0.0, "tilt": 0.05, "fl": 0.1, "fr": 0.0, "bl": 0.0, "br": 0.0,
				"tail": -0.3, "ears": 0.7, "head": 0.25, "sit": 1.0}
		_:
			return {"body": 0.0, "lift": 0.0, "tilt": 0.0, "fl": 0.05, "fr": -0.05, "bl": 0.0, "br": 0.0,
				"tail": 0.25 + sin(t * 3.0) * 0.35, "ears": sin(t * 0.7) * 0.06 + (0.25 if fmod(t, 5.0) < 0.15 else 0.0),
				"head": sin(t * 1.3) * 0.06, "sit": 1.0}


func _draw() -> void:
	var sit := p("sit")
	var lift := p("lift")
	var tilt := p("tilt") - sit * 0.35
	var hip := Vector2(-11, -20 + lift + sit * 4.0)
	var chest := hip + Vector2(23, 0).rotated(tilt)
	var body_mid := hip.lerp(chest, 0.5) + Vector2(0, -3)
	if state == "fly" or state == "leap":
		var aura := 1.0 + sin(t * 6.0) * 0.08
		draw_circle(body_mid, 34.0 * aura, Color(glow, 0.12))
		draw_circle(body_mid, 24.0 * aura, Color(glow, 0.16))
	_tail(hip, p("tail"))
	_leg(hip + Vector2(-2, 4), p("bl"), true, sit)
	_leg(chest + Vector2(-2, 6), p("fl"), true, 0.0)
	# body
	var body := ellipse_points(body_mid, Vector2(19, 12), tilt)
	shape(body, fur)
	draw_colored_polygon(ellipse_points(body_mid + Vector2(2, 5).rotated(tilt), Vector2(13, 6), tilt), CREAM)
	draw_colored_polygon(ellipse_points(body_mid + Vector2(-2, -7).rotated(tilt), Vector2(12, 3.5), tilt), fur_light)
	_leg(hip + Vector2(3, 5), p("br"), false, sit)
	_leg(chest + Vector2(2, 7), p("fr"), false, 0.0)
	_head(chest + Vector2(6, -14 - sit * 4.0), p("head") + tilt * 0.4)


func _leg(top: Vector2, angle: float, back: bool, sit: float) -> void:
	var dim := 0.82 if back else 1.0
	if sit > 0.5 and top.x < 0.0:
		# folded hind leg while sitting
		ellipse(top + Vector2(2, 6), Vector2(9, 7), fur * dim)
		ellipse(top + Vector2(8, 13), Vector2(6, 3.5), CREAM * dim)
		return
	var knee := bone(top, 9.0, angle)
	var paw := bone(knee, 9.0, angle * 0.4)
	capsule(top, knee, 7.5, fur * dim)
	capsule(knee, paw, 6.0, fur_shade * dim)
	draw_circle(paw + Vector2(1.5, 0), 4.8, OUTLINE)
	draw_circle(paw + Vector2(1.5, 0), 3.2, CREAM * dim)


func _tail(base: Vector2, lift: float) -> void:
	var dir := Vector2(-1, 0).rotated(lift)
	var side := dir.orthogonal()
	var wave := sin(t * 5.0) * 3.0
	var tip := base + dir * 30.0 + side * (8.0 + wave) + Vector2(0, -6)
	var mid := base + dir * 16.0 + side * (2.0 + wave * 0.5)
	var outline := smooth_points([base + side * 5.0, mid + side * 11.0, tip + side * 6.0, tip + dir * 7.0,
		tip - side * 6.0, mid - side * 9.0, base - side * 5.0], 5)
	shape(outline, fur)
	var white := smooth_points([tip + side * 5.5 - dir * 6.0, tip + dir * 6.0, tip - side * 5.5 - dir * 6.0,
		tip - dir * 9.0], 4)
	draw_colored_polygon(white, CREAM)
	draw_line(mid + side * 4.0, tip + side * 1.0 - dir * 8.0, fur_light, 2.5)


func _head(c: Vector2, r: float) -> void:
	var hp := func(v: Vector2) -> Vector2: return c + v.rotated(r)
	var ear := p("ears")
	# ears (back ear first)
	_ear(hp, Vector2(-6, -8), -0.35 + ear, 0.85)
	# scarf knot behind the head
	shape(_pts(hp, [Vector2(-8, 10), Vector2(6, 13), Vector2(12, 9), Vector2(4, 20), Vector2(-4, 16)]), SCARF)
	# head
	shape(_pts(hp, [Vector2(-13, -2), Vector2(-9, -12), Vector2(3, -14), Vector2(12, -8), Vector2(24, -1),
		Vector2(25, 4), Vector2(16, 9), Vector2(2, 11), Vector2(-11, 7)]), fur)
	# cheek fluff and muzzle
	draw_colored_polygon(_pts(hp, [Vector2(0, 3), Vector2(14, 1), Vector2(24, 2), Vector2(22, 7), Vector2(10, 10),
		Vector2(-6, 9), Vector2(-9, 5)]), CREAM)
	draw_circle(hp.call(Vector2(25, 1.5)), 3.4, NOSE)
	draw_circle(hp.call(Vector2(24.2, 0.4)), 1.0, Color(1, 1, 1, 0.8))
	_ear(hp, Vector2(3, -10), 0.2 + ear, 1.0)
	# eye
	var open := eyes_open()
	if state == "happy":
		draw_arc(hp.call(Vector2(11, -2)), 4.0, PI + 0.3, TAU - 0.3, 8, NOSE, 2.6)
	else:
		var eye: Vector2 = hp.call(Vector2(11, -3))
		ellipse(eye, Vector2(4.6, 5.6 * open), Color("2a1a14"), r)
		if open > 0.5:
			draw_colored_polygon(ellipse_points(eye + Vector2(0.8, 1.2), Vector2(2.6, 3.0), r), Color("3c6fb0"))
			draw_circle(eye + Vector2(-1.5, -2.2), 1.6, Color.WHITE)
	# mouth
	if state == "happy" or state == "attack":
		draw_colored_polygon(_pts(hp, [Vector2(16, 5), Vector2(22, 5), Vector2(19, 9)]), Color("b33a3a"))
	else:
		draw_arc(hp.call(Vector2(19, 5)), 3.0, 0.3, PI - 0.3, 8, NOSE, 1.6)
	draw_circle(hp.call(Vector2(6, 4)), 3.0, Color(1, 0.5, 0.5, 0.45))
	# scarf band and its medal
	shape(_pts(hp, [Vector2(-9, 8), Vector2(4, 12), Vector2(14, 9), Vector2(13, 14), Vector2(2, 17), Vector2(-9, 13)]), SCARF)
	draw_line(hp.call(Vector2(-6, 12)), hp.call(Vector2(10, 12)), SCARF_SHADE, 1.6)
	draw_circle(hp.call(Vector2(6, 16)), 3.4, OUTLINE)
	draw_circle(hp.call(Vector2(6, 16)), 2.4, Color("ffd34d"))


func _ear(hp: Callable, base: Vector2, angle: float, s: float) -> void:
	var dir := Vector2(0, -1).rotated(angle)
	var side := dir.orthogonal()
	var tip := base + dir * 15.0 * s
	var outer: Array = [hp.call(base - side * 6.5 * s), hp.call(tip), hp.call(base + side * 6.5 * s)]
	shape(PackedVector2Array(outer), fur if s >= 1.0 else fur_shade)
	var inner: Array = [hp.call(base - side * 3.5 * s + dir * 2.0), hp.call(base + dir * 11.0 * s), hp.call(base + side * 3.5 * s + dir * 2.0)]
	draw_colored_polygon(PackedVector2Array(inner), EAR_IN)


func _pts(hp: Callable, local: Array) -> PackedVector2Array:
	var world: Array = []
	for v in local:
		world.append(hp.call(v))
	return smooth_points(world, 4)
