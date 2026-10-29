class_name CompanionRig
extends CharacterRig
## The twelve companions of the village, drawn in code like Nima and Pilo: each one breathes,
## blinks and moves (hop, waddle, flap). Origin = feet on the ground (flyers hover above it),
## facing right. State "idle" or "move".

const FLYERS := ["butterfly", "owl", "spark", "dragon", "lion"]

const LOOK := {
	"squirrel": {"body": Color("c8743a"), "belly": Color("f4d3a2"), "dark": Color("8e4c22")},
	"turtle": {"body": Color("7cc46a"), "belly": Color("f0e2a0"), "dark": Color("3e7d4a")},
	"mole": {"body": Color("6e5a72"), "belly": Color("f2b6c4"), "dark": Color("473a4c")},
	"penguin": {"body": Color("2f3e5c"), "belly": Color("f6f6f2"), "dark": Color("f2a12c")},
	"butterfly": {"body": Color("5a3a7a"), "belly": Color("ff8fc8"), "dark": Color("7ad0ff")},
	"owl": {"body": Color("9a6a42"), "belly": Color("f2dcb0"), "dark": Color("5e3c22")},
	"spark": {"body": Color("ffd84a"), "belly": Color("fff6c0"), "dark": Color("ff9a1e")},
	"hedgehog": {"body": Color("7a5236"), "belly": Color("f2d2a8"), "dark": Color("4a2e1c")},
	"goat": {"body": Color("f4efe4"), "belly": Color("ffffff"), "dark": Color("e8b52c")},
	"cat": {"body": Color("3c3456"), "belly": Color("6e64a0"), "dark": Color("b98cff")},
	"dragon": {"body": Color("e2544a"), "belly": Color("ffd47a"), "dark": Color("9a2e3a")},
	"lion": {"body": Color("f2b23c"), "belly": Color("fff0c4"), "dark": Color("c0662a")},
}

var id := "squirrel"
var show_shadow := true
var _lift := 0.0
var _tilt := 0.0


func target_pose(_delta: float) -> Dictionary:
	var moving := state == "move"
	return {"move": 1.0 if moving else 0.0}


func is_flyer() -> bool:
	return FLYERS.has(id)


func _draw() -> void:
	var look: Dictionary = LOOK.get(id, LOOK.squirrel)
	var move := p("move")
	var breathe := sin(t * 3.0) * 1.5
	# ground creatures hop when they move, flyers bob in the air
	var lift := 0.0
	if is_flyer():
		lift = -46.0 + sin(t * 4.0) * 5.0
	else:
		lift = -absf(sin(t * 9.0)) * 10.0 * move
	# soft shadow on the ground
	draw_set_transform(Vector2.ZERO)
	var shadow_w := 22.0 * (0.7 if is_flyer() else 1.0)
	if show_shadow:
		draw_colored_polygon(ellipse_points(Vector2(0, -1), Vector2(shadow_w, 4.5)), Color(0, 0, 0, 0.18))
	_lift = lift
	_tilt = sin(t * 9.0) * 0.06 * move
	draw_set_transform(Vector2(0, _lift), _tilt)
	call("_draw_" + id, look, breathe, move)
	draw_set_transform(Vector2.ZERO)


# --- Shared parts ---------------------------------------------------------------

func eye(center: Vector2, radius: float, look_dir := Vector2(1, 0)) -> void:
	var open := eyes_open()
	if open < 0.5:
		draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), OUTLINE, 2.4)
		return
	ellipse(center, Vector2(radius, radius * 1.15), Color.WHITE)
	draw_circle(center + look_dir * radius * 0.3, radius * 0.62, Color("2a1a14"))
	draw_circle(center + look_dir * radius * 0.3 + Vector2(-radius * 0.22, -radius * 0.3), radius * 0.24, Color.WHITE)


func cheek(center: Vector2) -> void:
	draw_colored_polygon(ellipse_points(center, Vector2(4.5, 3.0)), Color(1.0, 0.45, 0.45, 0.45))


func shine(center: Vector2, radius: Vector2) -> void:
	draw_colored_polygon(ellipse_points(center, radius, -0.5), Color(1, 1, 1, 0.35))


func feet(look: Dictionary, move: float, spread := 9.0, color := Color(0, 0, 0, 0)) -> void:
	var c: Color = look.dark if color.a == 0.0 else color
	var swing := sin(t * 9.0) * 5.0 * move
	ellipse(Vector2(-spread + swing, -4), Vector2(7, 4.5), c)
	ellipse(Vector2(spread - swing, -4), Vector2(7, 4.5), c)


func wing(root: Vector2, length: float, width: float, fill: Color, flap: float) -> void:
	var tip := root + Vector2(-length * 0.7, -length * 0.75).rotated(flap)
	var pts := smooth_points([root, root + (tip - root) * 0.5 + Vector2(-width, width * 0.2).rotated(flap), tip, root + (tip - root) * 0.55 + Vector2(width * 0.5, -width * 0.4).rotated(flap)])
	shape(pts, fill)


# --- The companions -------------------------------------------------------------

func _draw_squirrel(look: Dictionary, b: float, move: float) -> void:
	# big curly tail behind
	var wag := sin(t * 2.5) * 0.12
	shape(smooth_points([Vector2(-10, -12), Vector2(-30, -20), Vector2(-36, -48), Vector2(-24, -66), Vector2(-8, -58), Vector2(-18, -44), Vector2(-14, -26)]).duplicate(), look.body)
	draw_set_transform(Vector2(0, _lift), _tilt + wag)
	draw_colored_polygon(smooth_points([Vector2(-26, -50), Vector2(-20, -60), Vector2(-12, -56), Vector2(-20, -46)]), look.belly)
	draw_set_transform(Vector2(0, _lift), _tilt)
	feet(look, move)
	ellipse(Vector2(0, -20 - b * 0.4), Vector2(15, 16 + b * 0.3), look.body)
	ellipse(Vector2(3, -18), Vector2(9, 11), look.belly, 0.0, false)
	# head
	var h := Vector2(6, -44 - b * 0.5)
	shape(PackedVector2Array([h + Vector2(-10, -8), h + Vector2(-7, -24), h + Vector2(0, -10)]), look.body)
	shape(PackedVector2Array([h + Vector2(4, -10), h + Vector2(9, -25), h + Vector2(13, -8)]), look.body)
	ellipse(h, Vector2(16, 14), look.body)
	ellipse(h + Vector2(8, 5), Vector2(8, 6), look.belly, 0.0, false)
	eye(h + Vector2(5, -3), 4.5)
	draw_circle(h + Vector2(15, 3), 2.6, OUTLINE)
	cheek(h + Vector2(-2, 6))
	shine(h + Vector2(-6, -7), Vector2(5, 3))
	# little paws holding an acorn
	ellipse(h + Vector2(10, 20), Vector2(6, 5), Color("a0602a"))
	draw_colored_polygon(ellipse_points(h + Vector2(10, 16), Vector2(6, 3)), Color("5a3418"))


func _draw_turtle(look: Dictionary, b: float, move: float) -> void:
	var step := sin(t * 7.0) * 3.0 * move
	ellipse(Vector2(-12 + step, -6), Vector2(6, 5), look.body)
	ellipse(Vector2(12 - step, -6), Vector2(6, 5), look.body)
	# head pokes out in front
	var h := Vector2(26, -22 - b * 0.3)
	capsule(Vector2(14, -14), h, 11.0, look.body)
	ellipse(h, Vector2(12, 11), look.body)
	eye(h + Vector2(4, -3), 4.2)
	draw_arc(h + Vector2(5, 4), 4.0, 0.2, 2.6, 8, OUTLINE, 2.0)
	cheek(h + Vector2(-2, 4))
	# shell
	var shell := smooth_points([Vector2(-26, -8), Vector2(-24, -26), Vector2(-6, -38), Vector2(12, -34), Vector2(22, -16), Vector2(18, -8)])
	shape(shell, look.dark)
	for c in [Vector2(-10, -22), Vector2(6, -24), Vector2(-2, -12)]:
		shape(ellipse_points(c, Vector2(7, 6), 0.0, 6), look.body.lightened(0.15))
	draw_line(Vector2(-25, -9), Vector2(19, -9), look.belly, 4.0)
	shine(Vector2(-6, -32), Vector2(9, 3))


func _draw_mole(look: Dictionary, b: float, move: float) -> void:
	feet(look, move, 11.0, look.belly)
	ellipse(Vector2(0, -20 - b * 0.4), Vector2(21, 19 + b * 0.3), look.body)
	ellipse(Vector2(3, -14), Vector2(12, 9), look.body.lightened(0.15), 0.0, false)
	# pink snout and digging paws
	ellipse(Vector2(22, -26), Vector2(8, 6), look.belly)
	draw_circle(Vector2(28, -27), 2.5, Color("c04a6a"))
	for side in [-1.0, 1.0]:
		var paw := Vector2(14 + side * 4.0, -10 + sin(t * 10.0 + side) * 2.0 * move)
		ellipse(paw, Vector2(7, 5), look.belly)
		for c in 3:
			draw_line(paw + Vector2(4, -3 + c * 3), paw + Vector2(9, -4 + c * 3.5), OUTLINE, 1.6)
	# tiny eyes and a miner's helmet with a lamp
	eye(Vector2(10, -32), 3.0)
	shape(smooth_points([Vector2(-18, -32), Vector2(-14, -44), Vector2(2, -48), Vector2(16, -42), Vector2(18, -34)]), Color("f2c230"))
	ellipse(Vector2(14, -42), Vector2(4.5, 4.5), Color("fff6b0"))
	draw_colored_polygon(ellipse_points(Vector2(26, -44), Vector2(12, 5), 0.0), Color(1, 0.95, 0.6, 0.25 + sin(t * 4.0) * 0.08))
	cheek(Vector2(14, -22))


func _draw_penguin(look: Dictionary, b: float, move: float) -> void:
	var waddle := sin(t * 8.0) * 0.12 * move
	draw_set_transform(Vector2(0, _lift), _tilt + waddle)
	feet(look, 0.0, 8.0, look.dark)
	ellipse(Vector2(0, -26 - b * 0.4), Vector2(17, 24 + b * 0.3), look.body)
	ellipse(Vector2(4, -22), Vector2(11, 18), look.belly, 0.0, false)
	# flippers
	capsule(Vector2(-12, -32), Vector2(-20, -16 + sin(t * 6.0) * 3.0), 8.0, look.body)
	capsule(Vector2(14, -32), Vector2(20, -18 - sin(t * 6.0) * 3.0), 8.0, look.body)
	eye(Vector2(2, -38), 4.0)
	eye(Vector2(11, -38), 4.0)
	shape(PackedVector2Array([Vector2(8, -32), Vector2(18, -29), Vector2(8, -26)]), look.dark)
	cheek(Vector2(-2, -30))
	# little blue scarf
	draw_line(Vector2(-14, -18 - 10), Vector2(16, -18 - 10), Color("4ab0ff"), 5.0)
	capsule(Vector2(-10, -28), Vector2(-16, -14), 4.0, Color("4ab0ff"))
	shine(Vector2(-8, -42), Vector2(5, 3))
	draw_set_transform(Vector2(0, _lift), _tilt)


func _draw_butterfly(look: Dictionary, b: float, _move: float) -> void:
	var flap := absf(sin(t * 10.0))
	for side in [-1.0, 1.0]:
		var sx := 1.0 - flap * 0.6
		var up := smooth_points([Vector2(0, -2), Vector2(side * 22 * sx, -26), Vector2(side * 34 * sx, -14), Vector2(side * 20 * sx, 2)])
		var low := smooth_points([Vector2(0, 2), Vector2(side * 22 * sx, 6), Vector2(side * 18 * sx, 20), Vector2(side * 6 * sx, 14)])
		shape(up, look.belly)
		shape(low, look.dark)
		draw_circle(Vector2(side * 18 * sx, -12), 4.5, Color.WHITE)
		draw_circle(Vector2(side * 12 * sx, 10), 3.0, Color("fff27a"))
	capsule(Vector2(0, -10), Vector2(0, 14), 7.0, look.body)
	ellipse(Vector2(0, -16 + b * 0.3), Vector2(8, 8), look.body)
	eye(Vector2(3, -17), 2.6)
	draw_line(Vector2(0, -23), Vector2(-5, -34), OUTLINE, 1.8)
	draw_line(Vector2(2, -23), Vector2(8, -34), OUTLINE, 1.8)
	draw_circle(Vector2(-5, -34), 2.2, look.belly)
	draw_circle(Vector2(8, -34), 2.2, look.belly)


func _draw_owl(look: Dictionary, b: float, _move: float) -> void:
	var flap := sin(t * 9.0) * 0.5
	wing(Vector2(-12, -14), 30.0, 10.0, look.dark, flap)
	ellipse(Vector2(0, -12 - b * 0.3), Vector2(18, 21), look.body)
	ellipse(Vector2(2, -6), Vector2(12, 13), look.belly, 0.0, false)
	for r in 3:
		draw_arc(Vector2(2, -10 + r * 6), 4.0, 0.3, 2.8, 6, look.dark, 1.6)
	# ear tufts and the big round eyes
	shape(PackedVector2Array([Vector2(-14, -26), Vector2(-16, -40), Vector2(-4, -30)]), look.body)
	shape(PackedVector2Array([Vector2(16, -26), Vector2(20, -40), Vector2(6, -30)]), look.body)
	ellipse(Vector2(-4, -22), Vector2(9, 9), look.belly)
	ellipse(Vector2(12, -22), Vector2(9, 9), look.belly)
	eye(Vector2(-4, -22), 6.0)
	eye(Vector2(12, -22), 6.0)
	shape(PackedVector2Array([Vector2(2, -17), Vector2(8, -17), Vector2(5, -10)]), Color("f2a12c"))
	wing(Vector2(14, -14), 30.0, 10.0, look.dark, -flap + PI * 0.5)
	# a soft lantern glow around him
	draw_circle(Vector2(0, -14), 46.0, Color(1, 0.9, 0.5, 0.06 + sin(t * 2.0) * 0.02))


func _draw_spark(look: Dictionary, b: float, _move: float) -> void:
	# a little star-sprite trailing sparks
	for i in 6:
		var a := t * 3.0 + i * TAU / 6.0
		var d := 26.0 + sin(t * 5.0 + i) * 4.0
		draw_circle(Vector2(cos(a), sin(a)) * d + Vector2(0, -6), 2.4, Color(1, 0.9, 0.4, 0.8))
	draw_circle(Vector2(0, -6), 30.0, Color(1, 0.85, 0.3, 0.12))
	var star := PackedVector2Array()
	for i in 10:
		var r := 22.0 + b if i % 2 == 0 else 10.0
		var a := -PI * 0.5 + i * PI / 5.0 + sin(t * 2.0) * 0.1
		star.append(Vector2(cos(a), sin(a)) * r + Vector2(0, -6))
	shape(star, look.body)
	draw_colored_polygon(ellipse_points(Vector2(-2, -8), Vector2(9, 8)), look.belly)
	eye(Vector2(-3, -8), 3.4)
	eye(Vector2(6, -8), 3.4)
	draw_arc(Vector2(2, -2), 3.5, 0.3, 2.8, 8, OUTLINE, 1.8)


func _draw_hedgehog(look: Dictionary, b: float, move: float) -> void:
	feet(look, move, 10.0)
	# spikes in rows
	for row in 2:
		for i in 8:
			var a := PI * (0.95 + i * 0.13) + row * 0.06
			var base := Vector2(cos(a) * 18.0, sin(a) * 16.0) + Vector2(-2, -22)
			var tip := base + Vector2(cos(a), sin(a)) * (14.0 - row * 3.0)
			shape(PackedVector2Array([base + Vector2(cos(a + 1.6), sin(a + 1.6)) * 4.0, tip, base - Vector2(cos(a + 1.6), sin(a + 1.6)) * 4.0]), look.dark if row == 0 else look.body)
	ellipse(Vector2(0, -20 - b * 0.4), Vector2(20, 16), look.body)
	ellipse(Vector2(10, -16), Vector2(12, 10), look.belly, 0.0, false)
	ellipse(Vector2(18, -18), Vector2(10, 7), look.belly)
	draw_circle(Vector2(27, -19), 3.0, OUTLINE)
	eye(Vector2(13, -25), 3.6)
	cheek(Vector2(10, -16))
	shine(Vector2(-6, -30), Vector2(6, 3))


func _draw_goat(look: Dictionary, b: float, move: float) -> void:
	var step := sin(t * 9.0) * 0.4 * move
	for leg in [[-10.0, step], [12.0, -step]]:
		var top := Vector2(leg[0], -18)
		capsule(top, CharacterRig.bone(top, 16.0, leg[1]), 6.0, look.body)
		ellipse(CharacterRig.bone(top, 17.0, leg[1]), Vector2(4.5, 3), Color("6a4a3a"))
	ellipse(Vector2(0, -28 - b * 0.4), Vector2(22, 14), look.body)
	for c in 4:
		draw_circle(Vector2(-14 + c * 9, -36 - b * 0.4), 6.0, look.belly)
	var h := Vector2(22, -44 - b * 0.5)
	ellipse(h, Vector2(11, 12), look.body)
	ellipse(h + Vector2(7, 6), Vector2(6, 5), Color("f2c8c0"))
	# golden curled horns and a little beard
	draw_arc(h + Vector2(-6, -10), 8.0, PI * 0.9, PI * 2.2, 12, OUTLINE, 7.0)
	draw_arc(h + Vector2(-6, -10), 8.0, PI * 0.9, PI * 2.2, 12, look.dark, 4.0)
	shape(PackedVector2Array([h + Vector2(2, 10), h + Vector2(8, 22), h + Vector2(10, 10)]), look.belly)
	eye(h + Vector2(3, -2), 3.8)
	shape(PackedVector2Array([h + Vector2(-10, -4), h + Vector2(-20, 2), h + Vector2(-9, 3)]), look.body)
	cheek(h + Vector2(-2, 5))


func _draw_cat(look: Dictionary, b: float, move: float) -> void:
	var tail := sin(t * 2.0) * 8.0
	draw_polyline(PackedVector2Array([Vector2(-18, -14), Vector2(-30, -22), Vector2(-32 + tail * 0.3, -40), Vector2(-26 + tail, -50)]), OUTLINE, 9.0, true)
	draw_polyline(PackedVector2Array([Vector2(-18, -14), Vector2(-30, -22), Vector2(-32 + tail * 0.3, -40), Vector2(-26 + tail, -50)]), look.body, 5.0, true)
	feet(look, move, 9.0, look.body)
	ellipse(Vector2(0, -18 - b * 0.4), Vector2(18, 14), look.body)
	var h := Vector2(10, -38 - b * 0.5)
	shape(PackedVector2Array([h + Vector2(-12, -4), h + Vector2(-10, -22), h + Vector2(-1, -10)]), look.body)
	shape(PackedVector2Array([h + Vector2(3, -10), h + Vector2(12, -22), h + Vector2(13, -2)]), look.body)
	ellipse(h, Vector2(14, 12), look.body)
	# glowing violet eyes: the shadow is her friend
	draw_circle(h + Vector2(-2, -1), 8.0, Color(look.dark, 0.25))
	draw_circle(h + Vector2(8, -1), 8.0, Color(look.dark, 0.25))
	ellipse(h + Vector2(-2, -1), Vector2(4, 4.5), look.dark)
	ellipse(h + Vector2(8, -1), Vector2(4, 4.5), look.dark)
	if eyes_open() > 0.5:
		draw_line(h + Vector2(-2, -4), h + Vector2(-2, 2), OUTLINE, 1.8)
		draw_line(h + Vector2(8, -4), h + Vector2(8, 2), OUTLINE, 1.8)
	shape(PackedVector2Array([h + Vector2(2, 4), h + Vector2(5, 4), h + Vector2(3.5, 6)]), Color("ff9ac0"), false)
	for s in [-1.0, 1.0]:
		draw_line(h + Vector2(3 + s * 6, 6), h + Vector2(3 + s * 16, 4 + s), look.belly, 1.2)
	shine(h + Vector2(-6, -6), Vector2(4, 2.5))


func _draw_dragon(look: Dictionary, b: float, _move: float) -> void:
	var flap := sin(t * 7.0) * 0.6
	wing(Vector2(-6, -18), 36.0, 14.0, look.dark, flap)
	# tail with an arrow tip
	var tip := Vector2(-34, -2 + sin(t * 3.0) * 4.0)
	draw_polyline(PackedVector2Array([Vector2(-10, -8), Vector2(-24, -2), tip]), OUTLINE, 10.0, true)
	draw_polyline(PackedVector2Array([Vector2(-10, -8), Vector2(-24, -2), tip]), look.body, 6.0, true)
	shape(PackedVector2Array([tip + Vector2(2, -6), tip + Vector2(-10, 0), tip + Vector2(2, 6)]), look.dark)
	ellipse(Vector2(0, -14 - b * 0.3), Vector2(18, 15), look.body)
	ellipse(Vector2(4, -10), Vector2(11, 10), look.belly, 0.0, false)
	var h := Vector2(16, -34 - b * 0.4)
	shape(PackedVector2Array([h + Vector2(-8, -8), h + Vector2(-14, -22), h + Vector2(-2, -12)]), look.belly)
	shape(PackedVector2Array([h + Vector2(2, -10), h + Vector2(2, -24), h + Vector2(8, -10)]), look.belly)
	ellipse(h, Vector2(14, 12), look.body)
	ellipse(h + Vector2(10, 4), Vector2(8, 6), look.body)
	draw_circle(h + Vector2(15, 2), 1.6, OUTLINE)
	eye(h + Vector2(2, -3), 4.4)
	cheek(h + Vector2(-4, 5))
	wing(Vector2(6, -20), 36.0, 14.0, look.dark.lightened(0.2), -flap * 0.8 + 0.3)
	# a little puff of warm smoke now and then
	var puff := fmod(t, 3.0)
	if puff < 0.8:
		draw_circle(h + Vector2(24 + puff * 20.0, 2 - puff * 8.0), 4.0 + puff * 5.0, Color(1, 0.7, 0.4, 0.5 * (1.0 - puff / 0.8)))


func _draw_lion(look: Dictionary, b: float, _move: float) -> void:
	var flap := sin(t * 7.0) * 0.5
	wing(Vector2(-8, -16), 32.0, 12.0, Color("ffffff"), flap)
	ellipse(Vector2(-2, -12 - b * 0.3), Vector2(20, 13), look.body)
	capsule(Vector2(-20, -12), Vector2(-30, -22 + sin(t * 3.0) * 3.0), 4.0, look.body)
	draw_circle(Vector2(-30, -22 + sin(t * 3.0) * 3.0), 5.0, look.dark)
	var h := Vector2(14, -28 - b * 0.4)
	# the mane: a ring of rounded tufts
	for i in 12:
		var a := i * TAU / 12.0 + sin(t * 2.0) * 0.05
		ellipse(h + Vector2(cos(a), sin(a)) * 14.0, Vector2(8, 7), look.dark, a)
	ellipse(h, Vector2(13, 12), look.body)
	ellipse(h + Vector2(4, 5), Vector2(7, 5), look.belly, 0.0, false)
	draw_circle(h + Vector2(6, 2), 2.6, Color("7a3a2a"))
	eye(h + Vector2(-2, -3), 3.6)
	eye(h + Vector2(8, -3), 3.6)
	cheek(h + Vector2(-6, 5))
	wing(Vector2(2, -18), 32.0, 12.0, Color("f0f4ff"), -flap * 0.8 + 0.3)
