class_name BossRig
extends EnemyRig
## The nine world guardians, drawn in code (facing left; the boss flips it). Shadow colours
## while cursed, their real colours once freed. `state` drives the pose, `flash` glows white
## when a move is coming or a hit lands, `anger` speeds the idle motion.


var kind := "forest"
var size := Vector2(150, 130)
var anger := 1.0
var flash := 0.0


func _process(delta: float) -> void:
	super(delta)
	flash = maxf(0.0, flash - delta * 2.5)
	modulate = Color(1, 1, 1).lerp(Color(2.0, 1.6, 1.6), flash)
	if state == "free":
		modulate = Color.WHITE


func target_pose(delta: float) -> Dictionary:
	phase += delta * (4.0 + anger * 3.0) * (2.0 if state == "charge" else 1.0)
	var crouch := 0.0
	match state:
		"windup":
			crouch = 0.12
		"stunned":
			crouch = 0.2
	return {"swing": sin(phase), "bob": absf(sin(phase)) * 4.0, "crouch": crouch}


func col(shadow: Color, real: Color) -> Color:
	return shadow.lerp(real, freed_amount)


func _draw() -> void:
	var w := size.x
	var h := size.y * (1.0 - p("crouch"))
	var sw := p("swing")
	var bob := -p("bob")
	match kind:
		"forest":
			_bear(w, h, sw, bob)
		"coral_beach":
			_octopus(w, h, sw, bob)
		"golden_desert":
			_worm(w, h, sw, bob)
		"snow_mountain":
			_giant(w, h, sw, bob)
		"sky_islands":
			_eagle(w, h, sw, bob)
		"crystal_caves":
			_spider(w, h, sw, bob)
		"clock_factory":
			_machine(w, h, sw, bob)
		"shadow_castle":
			_king(w, h, sw, bob, false)
		_:
			_king(w, h, sw, bob, true)
	if state == "stunned":
		for i in 3:
			var a := t * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 30.0, -h - 18 + sin(a) * 8.0), 6.0, Color("ffe46b"))
	draw_wisps(Vector2(0, -h - 10), w * 0.3)


func _eyes(a: Vector2, b: Vector2, r: float) -> void:
	angry_eyes(a, b, r)


func _bear(w: float, h: float, sw: float, bob: float) -> void:
	var fur := col(Color("3a2a52"), Color("8a5a34"))
	var belly := col(Color("5a4a7a"), Color("d9b48a"))
	for side in [-1.0, 1.0]:
		capsule(Vector2(side * 30, -h * 0.3), Vector2(side * 30 + sw * side * 10, -6), 34.0, fur)
	ellipse(Vector2(0, -h * 0.5 + bob), Vector2(w * 0.42, h * 0.38), fur)
	ellipse(Vector2(-6, -h * 0.45 + bob), Vector2(w * 0.25, h * 0.24), belly)
	capsule(Vector2(-40, -h * 0.55 + bob), Vector2(-62 - sw * 8, -h * 0.25 + bob), 26.0, fur)
	var head := Vector2(-34, -h * 0.86 + bob)
	for e in [Vector2(-26, -30), Vector2(22, -30)]:
		ellipse(head + e, Vector2(14, 14), fur)
	ellipse(head, Vector2(42, 36), fur)
	ellipse(head + Vector2(-18, 10), Vector2(20, 15), belly)
	draw_circle(head + Vector2(-30, 4), 7.0, Color("2b1a14"))
	_eyes(head + Vector2(-14, -10), head + Vector2(4, -10), 7.0)
	for i in 5:
		draw_circle(Vector2(-10 + i * 14, -h * 0.82 + bob - 10 + absf(i - 2) * 4), 9.0, col(Color("4a6a4a"), Color("6cc24a")))
	shape(PackedVector2Array([head + Vector2(-26, -30), head + Vector2(-14, -50), head + Vector2(0, -36), head + Vector2(14, -52), head + Vector2(24, -30)]), col(Color("6a6a7a"), Color("b8b2a6")))


func _octopus(w: float, h: float, sw: float, bob: float) -> void:
	var skin_c := col(Color("4a2a62"), Color("e8604a"))
	for i in 6:
		var x := -w * 0.4 + i * w * 0.16
		var pts: Array = []
		for k in 5:
			pts.append(Vector2(x + sin(t * 3.0 + i + k * 0.8) * 10.0 + k * (i - 2.5) * 3.0, -h * 0.35 + k * h * 0.08))
		for k in 4:
			capsule(pts[k], pts[k + 1], 22.0 - k * 4.0, skin_c)
	ellipse(Vector2(0, -h * 0.62 + bob), Vector2(w * 0.4, h * 0.42), skin_c)
	for spot in [Vector2(-20, -h * 0.8), Vector2(18, -h * 0.72), Vector2(4, -h * 0.9)]:
		draw_circle(spot + Vector2(0, bob), 9.0, skin_c.lightened(0.25))
	_eyes(Vector2(-26, -h * 0.55 + bob), Vector2(2, -h * 0.55 + bob), 10.0)


func _worm(w: float, h: float, sw: float, bob: float) -> void:
	var body := col(Color("4a3a62"), Color("d99a5a"))
	for i in 6:
		var k := float(i) / 5.0
		var p := Vector2(w * 0.35 - k * w * 0.6 + sin(t * 3.0 + i) * 6.0, -k * h * 0.85 - 10.0)
		ellipse(p, Vector2(34 - k * 6, 30 - k * 4), body if i % 2 == 0 else body.darkened(0.12))
	var head := Vector2(-w * 0.28, -h * 0.85)
	ellipse(head, Vector2(40, 34), body)
	shape(PackedVector2Array([head + Vector2(-40, -6), head + Vector2(-20, 14), head + Vector2(-40, 20)]), Color("5a1a1a"))
	for i in 3:
		shape(PackedVector2Array([head + Vector2(-38 + i * 6, -2), head + Vector2(-34 + i * 6, 6), head + Vector2(-30 + i * 6, -2)]), Color.WHITE)
	_eyes(head + Vector2(-8, -16), head + Vector2(10, -16), 7.0)


func _giant(w: float, h: float, sw: float, bob: float) -> void:
	var ice := col(Color("3a3a62"), Color("9fd8ff"))
	var light := col(Color("5a5a8a"), Color("e8f6ff"))
	for side in [-1.0, 1.0]:
		capsule(Vector2(side * 28, -h * 0.3), Vector2(side * 30 + sw * side * 8, -8), 34.0, ice)
	shape(round_rect_points(Vector2(0, -h * 0.55 + bob), Vector2(w * 0.8, h * 0.5), 30.0), ice)
	shape(round_rect_points(Vector2(-4, -h * 0.5 + bob), Vector2(w * 0.4, h * 0.3), 20.0), light)
	capsule(Vector2(-50, -h * 0.65 + bob), Vector2(-70 - sw * 10, -h * 0.3 + bob), 30.0, ice)
	var head := Vector2(-10, -h * 0.9 + bob)
	ellipse(head, Vector2(36, 30), ice)
	for x in [-26.0, 20.0]:
		shape(PackedVector2Array([head + Vector2(x - 6, -20), head + Vector2(x, -52), head + Vector2(x + 8, -22)]), light)
	_eyes(head + Vector2(-16, -4), head + Vector2(4, -4), 7.0)


func _eagle(w: float, h: float, sw: float, bob: float) -> void:
	var feather := col(Color("2e2a52"), Color("4a7fd0"))
	var light := col(Color("5a5a8a"), Color("ffe9b0"))
	var flap := sin(t * (10.0 if state != "high" else 6.0))
	for side in [-1.0, 1.0]:
		var base := Vector2(side * 10, -h * 0.6)
		shape(PackedVector2Array([base, base + Vector2(side * w * 0.6, -h * 0.4 + flap * 40.0), base + Vector2(side * w * 0.5, -h * 0.05 + flap * 30.0), base + Vector2(side * 20, h * 0.1)]), feather)
	ellipse(Vector2(0, -h * 0.5 + bob), Vector2(w * 0.28, h * 0.34), feather)
	ellipse(Vector2(-4, -h * 0.45 + bob), Vector2(w * 0.16, h * 0.22), light)
	var head := Vector2(-22, -h * 0.85 + bob)
	ellipse(head, Vector2(26, 22), light)
	shape(PackedVector2Array([head + Vector2(-22, -2), head + Vector2(-44, 8), head + Vector2(-22, 10)]), Color("ffb347"))
	_eyes(head + Vector2(-10, -6), head + Vector2(4, -6), 6.0)
	for side in [-1.0, 1.0]:
		capsule(Vector2(side * 12, -h * 0.2), Vector2(side * 14, -4), 8.0, Color("ffb347"))


func _spider(w: float, h: float, sw: float, bob: float) -> void:
	var shell := col(Color("3a2a5a"), Color("8a6fd0"))
	var crystal := col(Color("6a5a9a"), Color("c7f0ff"))
	for i in 4:
		for side in [-1.0, 1.0]:
			var base := Vector2(side * (10 + i * 10), -h * 0.45)
			var knee := base + Vector2(side * (34 + i * 6), -26 + sin(t * 6.0 + i + side) * 6.0)
			capsule(base, knee, 9.0, shell)
			capsule(knee, knee + Vector2(side * 14, h * 0.45 + 10), 7.0, shell)
	ellipse(Vector2(18, -h * 0.55 + bob), Vector2(w * 0.25, h * 0.3), shell)
	for k in 3:
		shape(PackedVector2Array([Vector2(8 + k * 12, -h * 0.75 + bob), Vector2(14 + k * 12, -h * 0.98 + bob), Vector2(20 + k * 12, -h * 0.75 + bob)]), crystal)
	var head := Vector2(-30, -h * 0.5 + bob)
	ellipse(head, Vector2(28, 24), shell)
	for e in [Vector2(-14, -8), Vector2(-2, -10), Vector2(-20, 2), Vector2(-8, 2)]:
		draw_circle(head + e, 4.0, col(Color("ff6bff"), Color("2b1a14")))


func _machine(w: float, h: float, sw: float, bob: float) -> void:
	var metal := col(Color("4a4460"), Color("c9a24a"))
	for side in [-1.0, 1.0]:
		capsule(Vector2(side * 30, -h * 0.25), Vector2(side * 32 + sw * side * 6, -6), 26.0, metal.darkened(0.2))
	shape(round_rect_points(Vector2(0, -h * 0.48 + bob), Vector2(w * 0.8, h * 0.46), 18.0), metal)
	var face := Vector2(0, -h * 0.48 + bob)
	draw_circle(face, 34.0, OUTLINE)
	draw_circle(face, 30.0, Color("fff8e1"))
	draw_line(face, face + Vector2(sin(t * 3.0), -cos(t * 3.0)) * 24.0, OUTLINE, 3.0)
	draw_line(face, face + Vector2(sin(t * 0.5), -cos(t * 0.5)) * 16.0, OUTLINE, 4.0)
	# grandpa riding on top, enchanted (purple glasses) until freed
	var head := Vector2(-6, -h * 0.82 + bob)
	ellipse(head, Vector2(24, 22), Color("f7c9a3"))
	shape(PackedVector2Array([head + Vector2(-20, 6), head + Vector2(0, 34), head + Vector2(20, 6)]), Color.WHITE)
	for x in [-9.0, 9.0]:
		draw_arc(head + Vector2(x, -4), 7.0, 0.0, TAU, 12, OUTLINE, 2.5)
		draw_circle(head + Vector2(x, -4), 5.0, col(Color("b05cff"), Color("dfefff")))
	capsule(Vector2(w * 0.4, -h * 0.6 + bob), Vector2(w * 0.55, -h * 0.75 + bob + sw * 10), 12.0, metal)


func _king(w: float, h: float, sw: float, bob: float, masked: bool) -> void:
	var cloak := col(Color("1e1530"), Color("4a3a8a") if not masked else Color("6a4a3a"))
	var trim := col(Color("6a4a9a"), Color("ffd166"))
	var flow := sin(t * 2.0) * 10.0
	shape(PackedVector2Array([Vector2(-w * 0.12, -h * 0.82 + bob), Vector2(w * 0.12, -h * 0.82 + bob),
		Vector2(w * 0.45 + flow, 0), Vector2(0, -10), Vector2(-w * 0.45 - flow, 0)]), cloak)
	draw_line(Vector2(-w * 0.45 - flow, -2), Vector2(w * 0.45 + flow, -2), trim, 5.0)
	var head := Vector2(-4, -h * 0.88 + bob)
	ellipse(head, Vector2(24, 26), cloak.darkened(0.3))
	if masked:
		shape(round_rect_points(head + Vector2(-2, 0), Vector2(34, 22), 8.0), Color("e0d7c0"))
		capsule(Vector2(w * 0.3, -h * 0.75 + bob), Vector2(w * 0.38, -6), 6.0, trim)
		draw_circle(Vector2(w * 0.3, -h * 0.78 + bob), 12.0, trim)
	# the broken crown
	shape(PackedVector2Array([head + Vector2(-20, -18), head + Vector2(-14, -42), head + Vector2(-4, -26), head + Vector2(4, -46), head + Vector2(12, -24), head + Vector2(20, -18)]), trim)
	draw_circle(head + Vector2(-8, 2), 5.0, col(Color("ff4dff"), Color("6cc8ff")))
	draw_circle(head + Vector2(8, 2), 5.0, col(Color("ff4dff"), Color("6cc8ff")))
	for side in [-1.0, 1.0]:
		capsule(Vector2(side * 16, -h * 0.66 + bob), Vector2(side * (40 + sw * 10), -h * 0.45 + bob), 12.0, cloak)
