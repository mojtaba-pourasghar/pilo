class_name NimaRig
extends CharacterRig
## Nima, drawn in code: red slouchy beanie, brown hair, orange T-shirt, blue shorts, brown
## boots and a backpack. Every joint (hips, knees, shoulders, elbows, head) is animated:
## idle breathing and blinking, walk and run cycles with arm swing, jump, fall, dash, skid,
## hurt, stomp and celebrate poses. About 120 px tall; origin = between the feet.

const SKIN := Color("f7c9a3")
const SKIN_SHADE := Color("e5a47e")
const HAIR := Color("6b3a22")
const HAIR_LIGHT := Color("8d5232")
const HAT := Color("e8452c")
const HAT_SHADE := Color("b9301d")
const HAT_LIGHT := Color("ff7a57")
const SHIRT := Color("f27e2e")
const SHIRT_SHADE := Color("c95e19")
const SHORTS := Color("4b88c7")
const SHORTS_SHADE := Color("33679f")
const BOOT := Color("8c522c")
const BOOT_SHADE := Color("5f3519")
const SOLE := Color("3e2416")
const BAG := Color("a8743f")
const BAG_SHADE := Color("7a522b")
const STRAP := Color("5b3a1f")
const EYE := Color("3a2416")

const THIGH := 15.0
const SHIN := 15.0
const UPPER_ARM := 13.0
const FOREARM := 12.0
const HIP_Y := -38.0


func target_pose(_delta: float) -> Dictionary:
	var stride := clampf(absf(speed) / run_speed, 0.0, 1.0)
	match state:
		"walk", "run":
			phase += _delta * lerpf(9.0, 17.0, stride)
			var amp := lerpf(0.5, 0.95, stride)
			var s := sin(phase)
			var c := cos(phase)
			return {
				"lean": lerpf(0.06, 0.2, stride), "bob": -absf(sin(phase)) * lerpf(2.5, 5.0, stride),
				"hipF": s * amp, "hipB": -s * amp,
				"kneeF": 0.15 + maxf(0.0, c) * lerpf(0.8, 1.5, stride),
				"kneeB": 0.15 + maxf(0.0, -c) * lerpf(0.8, 1.5, stride),
				"shF": -s * lerpf(0.55, 1.1, stride), "shB": s * lerpf(0.55, 1.1, stride),
				"elF": lerpf(0.35, 1.3, stride), "elB": lerpf(0.35, 1.3, stride),
				"head": -0.04, "squash": 0.0,
			}
		"jump":
			return {"lean": 0.08, "bob": 0.0, "hipF": 1.0, "hipB": -0.35, "kneeF": 1.7, "kneeB": 0.7,
				"shF": 1.7, "shB": -1.1, "elF": 0.9, "elB": 0.6, "head": -0.12, "squash": 0.0}
		"fall":
			var flap := sin(t * 14.0) * 0.18
			return {"lean": 0.02, "bob": 0.0, "hipF": 0.45, "hipB": -0.25, "kneeF": 0.6, "kneeB": 0.35,
				"shF": 1.9 + flap, "shB": -1.6 - flap, "elF": 0.25, "elB": 0.25, "head": 0.1, "squash": 0.0}
		"glide":
			# holding on to Pilo above: both arms up, legs dangling and swaying
			var sway := sin(t * 4.0) * 0.15
			return {"lean": 0.05, "bob": 0.0, "hipF": 0.3 + sway, "hipB": -0.2 + sway, "kneeF": 0.4, "kneeB": 0.3,
				"shF": 2.9, "shB": 2.7, "elF": 0.1, "elB": 0.1, "head": -0.15, "squash": 0.0}
		"dash":
			return {"lean": 0.42, "bob": 0.0, "hipF": 1.15, "hipB": -1.0, "kneeF": 0.7, "kneeB": 0.5,
				"shF": -1.0, "shB": -1.3, "elF": 0.4, "elB": 0.3, "head": -0.25, "squash": 0.0}
		"skid":
			return {"lean": -0.22, "bob": 0.0, "hipF": 0.75, "hipB": 0.05, "kneeF": 0.0, "kneeB": 0.8,
				"shF": 1.3, "shB": 0.9, "elF": 0.2, "elB": 0.2, "head": 0.1, "squash": 0.0}
		"hurt":
			return {"lean": -0.3, "bob": 0.0, "hipF": 0.6, "hipB": -0.5, "kneeF": 0.5, "kneeB": 0.5,
				"shF": 1.8, "shB": -1.9, "elF": 0.7, "elB": 0.7, "head": 0.2, "squash": 0.0}
		"stomp":
			return {"lean": 0.0, "bob": 0.0, "hipF": 0.25, "hipB": -0.25, "kneeF": 0.3, "kneeB": 0.3,
				"shF": 1.6, "shB": -1.6, "elF": 0.4, "elB": 0.4, "head": -0.1, "squash": 0.0}
		"celebrate":
			var wave := sin(t * 12.0) * 0.35
			return {"lean": -0.05, "bob": -absf(sin(t * 6.0)) * 4.0, "hipF": 0.1, "hipB": -0.1,
				"kneeF": 0.1, "kneeB": 0.1, "shF": 2.9 + wave, "shB": -2.7 - wave, "elF": 0.3, "elB": 0.3,
				"head": -0.1, "squash": 0.0}
		"lens":
			return {"lean": 0.0, "bob": 0.0, "hipF": 0.15, "hipB": -0.15, "kneeF": 0.1, "kneeB": 0.1,
				"shF": 1.6, "shB": 0.2, "elF": 1.2, "elB": 0.3, "head": 0.0, "squash": 0.0}
		_:
			var breath := sin(t * 2.4)
			return {"lean": 0.0, "bob": breath * 0.8, "hipF": 0.08, "hipB": -0.08, "kneeF": 0.05, "kneeB": 0.05,
				"shF": 0.12 + breath * 0.05, "shB": -0.1 - breath * 0.05, "elF": 0.3, "elB": 0.25,
				"head": sin(t * 0.9) * 0.05, "squash": 0.0}


func _draw() -> void:
	var lean := p("lean")
	var hip := Vector2(0, HIP_Y + p("bob"))
	var up := Vector2(sin(lean), -cos(lean))
	var right := Vector2(cos(lean), sin(lean))
	var shoulder := hip + up * 25.0
	var head_center := hip + up * 47.0
	var head_rot := lean * 0.6 + p("head")

	_arm(shoulder - right * 3.0, p("shB"), p("elB"), true)
	_leg(hip - right * 4.0, p("hipB"), p("kneeB"), true)
	_leg(hip + right * 4.0, p("hipF"), p("kneeF"), false)
	_backpack(hip, up, right, lean)
	_torso(hip, up, right, lean)
	_head(head_center, head_rot)
	_arm(shoulder + right * 3.0, p("shF"), p("elF"), false)


func _leg(top: Vector2, hip_angle: float, knee: float, back: bool) -> void:
	var dim := 0.86 if back else 1.0
	var knee_pos := bone(top, THIGH, hip_angle)
	var foot := bone(knee_pos, SHIN, hip_angle - knee)
	capsule(top, knee_pos, 10.0, SKIN * dim)
	capsule(knee_pos, foot, 9.0, SKIN * dim, Color(SKIN_SHADE * dim, 0.6))
	# boot: toe points forward, tilts a little with the shin
	var tilt := clampf((hip_angle - knee) * 0.35, -0.5, 0.6)
	var boot_center := foot + Vector2(3.5, 1.0).rotated(tilt)
	shape(round_rect_points(boot_center, Vector2(19, 11), 5.0, tilt), BOOT * dim)
	draw_colored_polygon(round_rect_points(boot_center + Vector2(0, 4).rotated(tilt), Vector2(18, 3.5), 1.5, tilt), SOLE)
	draw_colored_polygon(round_rect_points(boot_center + Vector2(-1, -3.5).rotated(tilt), Vector2(14, 3), 1.5, tilt), BOOT_SHADE * dim)


func _arm(shoulder: Vector2, angle: float, elbow: float, back: bool) -> void:
	var dim := 0.86 if back else 1.0
	var elbow_pos := bone(shoulder, UPPER_ARM, angle)
	var hand := bone(elbow_pos, FOREARM, angle + elbow)
	capsule(shoulder, elbow_pos, 8.0, SKIN * dim)
	capsule(elbow_pos, hand, 7.5, SKIN * dim, Color(SKIN_SHADE * dim, 0.5))
	# short sleeve over the top of the arm
	capsule(shoulder, shoulder.lerp(elbow_pos, 0.55), 12.0, SHIRT * dim)
	draw_circle(hand, 5.6 + OUTLINE_W, OUTLINE)
	draw_circle(hand, 5.6, SKIN * dim)


func _backpack(hip: Vector2, up: Vector2, right: Vector2, lean: float) -> void:
	var center := hip + up * 16.0 - right * 15.0
	shape(round_rect_points(center, Vector2(16, 26), 6.0, lean), BAG)
	draw_colored_polygon(round_rect_points(center + up * 6.0 - right * 1.0, Vector2(15, 11), 5.0, lean), BAG_SHADE)
	draw_circle(center + up * 1.0 - right * 1.0, 2.2, Color("e9c46a"))


func _torso(hip: Vector2, up: Vector2, right: Vector2, lean: float) -> void:
	# shorts
	shape(round_rect_points(hip + up * 1.0, Vector2(27, 14), 6.0, lean), SHORTS)
	draw_line(hip - up * 4.0 - right * 11.0, hip - up * 4.0 + right * 11.0, SHORTS_SHADE, 2.0)
	# shirt
	var chest := hip + up * 14.0
	shape(round_rect_points(chest, Vector2(25, 24), 9.0, lean), SHIRT)
	draw_colored_polygon(round_rect_points(chest - up * 7.0 - right * 1.0, Vector2(22, 7), 3.0, lean), SHIRT_SHADE)
	# backpack strap across the chest and a small badge
	draw_line(chest + up * 11.0 - right * 4.0, chest - up * 9.0 + right * 7.0, STRAP, 3.5)
	draw_circle(chest + right * 3.0 + up * 2.0, 2.4, Color("ffd34d"))


func _head(c: Vector2, r: float) -> void:
	var hp := func(v: Vector2) -> Vector2: return c + v.rotated(r)
	# hair behind the head
	shape(_pts(hp, [Vector2(-21, -4), Vector2(-23, 8), Vector2(-16, 17), Vector2(-5, 15), Vector2(-2, 0), Vector2(-8, -12)]), HAIR)
	# face
	ellipse(c, Vector2(21, 20), SKIN, r)
	draw_colored_polygon(ellipse_points(hp.call(Vector2(-6, 7)), Vector2(12, 9), r), Color(SKIN_SHADE, 0.3))
	# ear
	ellipse(hp.call(Vector2(-9, 3)), Vector2(5, 6.5), SKIN, r)
	draw_circle(hp.call(Vector2(-9, 3.5)), 2.2, SKIN_SHADE)
	# fringe under the beanie
	shape(_pts(hp, [Vector2(-16, -9), Vector2(-4, -14), Vector2(10, -14), Vector2(21, -8), Vector2(19, -3),
		Vector2(13, -6), Vector2(7, -2), Vector2(2, -6), Vector2(-5, -2), Vector2(-11, -6)]), HAIR)
	draw_line(hp.call(Vector2(-2, -11)), hp.call(Vector2(9, -11)), HAIR_LIGHT, 2.0)
	_hat(hp)
	_face(hp)


func _hat(hp: Callable) -> void:
	# slouchy beanie: dome with the tip flopping backward
	var sway := sin(t * 3.0) * 1.5 + clampf(speed / run_speed, -1.0, 1.0) * -2.0
	shape(_pts(hp, [Vector2(-20, -10), Vector2(-25 + sway, -19), Vector2(-28 + sway, -28), Vector2(-17, -30),
		Vector2(-2, -29), Vector2(12, -25), Vector2(19, -17), Vector2(18, -12), Vector2(0, -14)]), HAT)
	draw_colored_polygon(_pts(hp, [Vector2(-6, -27), Vector2(7, -25), Vector2(3, -21), Vector2(-8, -22)]), HAT_LIGHT)
	draw_colored_polygon(_pts(hp, [Vector2(-26 + sway, -26), Vector2(-23 + sway, -19), Vector2(-19, -22), Vector2(-20, -28)]), HAT_SHADE)
	# folded brim
	shape(_pts(hp, [Vector2(-22, -11), Vector2(-2, -18), Vector2(20, -17), Vector2(22, -11), Vector2(0, -11), Vector2(-21, -5)]), HAT_SHADE)
	draw_line(hp.call(Vector2(-17, -9)), hp.call(Vector2(18, -14)), HAT_LIGHT, 1.6)


func _face(hp: Callable) -> void:
	var open := eyes_open()
	match expression:
		"hurt":
			for x in [3.0, 14.0]:
				draw_line(hp.call(Vector2(x - 3.5, -1)), hp.call(Vector2(x + 3.5, 2)), EYE, 2.6)
				draw_line(hp.call(Vector2(x - 3.5, 5)), hp.call(Vector2(x + 3.5, 2)), EYE, 2.6)
		"happy":
			for x in [3.0, 14.0]:
				draw_arc(hp.call(Vector2(x, 4)), 4.0, PI + 0.3, TAU - 0.3, 8, EYE, 2.6)
		_:
			_eye(hp.call(Vector2(3, 2)), Vector2(5.8, 7.2), open, hp)
			_eye(hp.call(Vector2(14.5, 2)), Vector2(4.6, 6.8), open, hp)
	# eyebrows
	draw_line(hp.call(Vector2(-2, -6)), hp.call(Vector2(6, -7)), HAIR, 2.2)
	draw_line(hp.call(Vector2(11, -7)), hp.call(Vector2(18, -6)), HAIR, 2.2)
	# nose and cheeks
	draw_circle(hp.call(Vector2(20, 7)), 2.4, SKIN_SHADE)
	draw_circle(hp.call(Vector2(-2, 10)), 3.8, Color(1, 0.55, 0.55, 0.45))
	draw_circle(hp.call(Vector2(17, 11)), 2.8, Color(1, 0.55, 0.55, 0.4))
	# mouth
	if expression == "happy" or state == "celebrate" or state == "jump":
		draw_colored_polygon(_pts(hp, [Vector2(5, 11), Vector2(14, 11), Vector2(12, 16), Vector2(7, 16)]), Color("8e2b2b"))
		draw_circle(hp.call(Vector2(9.5, 14.5)), 2.0, Color("ff7d7d"))
	elif expression == "hurt" or state == "hurt":
		ellipse(hp.call(Vector2(10, 13)), Vector2(2.6, 3.2), Color("8e2b2b"))
	else:
		draw_arc(hp.call(Vector2(10, 9)), 4.5, 0.4, PI - 0.4, 10, Color("8e2b2b"), 2.0)


func _eye(center: Vector2, size: Vector2, open: float, hp: Callable) -> void:
	var r: float = (hp.call(Vector2(1, 0)) - hp.call(Vector2.ZERO)).angle()
	ellipse(center, Vector2(size.x, size.y * open), Color.WHITE, r)
	if open > 0.5:
		var iris := center + Vector2(size.x * 0.25, size.y * 0.1).rotated(r)
		draw_colored_polygon(ellipse_points(iris, Vector2(size.x * 0.7, size.y * 0.72), r), Color("4a2a17"))
		draw_colored_polygon(ellipse_points(iris, Vector2(size.x * 0.4, size.y * 0.45), r), Color("1d100a"))
		draw_circle(iris + Vector2(-size.x * 0.25, -size.y * 0.35).rotated(r), size.x * 0.28, Color.WHITE)


func _pts(hp: Callable, local: Array) -> PackedVector2Array:
	var world: Array = []
	for v in local:
		world.append(hp.call(v))
	return smooth_points(world, 4)
