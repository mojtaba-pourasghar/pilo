extends Node2D
## v4 sample level (docs/45 section 5): the first two "chunks" of the old meadow plus a glide gap and a hidden cage,
## to try the movement and the finger controls. The ground, layers and props are placeholders drawn by code until the
## painted kit arrives (art/kits, art/bg); then the same layout is dressed with the painted pieces.

const BOTTOM := 1600.0

## Ground runs: smooth curves through these points (px). Each run is one solid piece.
const GROUND := [
	[[-400, 900], [0, 900], [500, 880], [900, 820], [1250, 860], [1600, 900], [2000, 900]],
	[[2000, 900], [2300, 900], [2500, 760], [2700, 700], [2900, 700]],
	[[3500, 700], [3800, 640], [4100, 620], [4300, 620]],
	[[5400, 760], [5800, 760], [6200, 720], [6600, 760], [7200, 760], [7600, 740]],
]
## Thin platforms you can jump up through and drop down through: [x, y, width]
const LEDGES := [[1050, 690, 220], [1350, 560, 200], [2420, 560, 160], [3150, 560, 220], [4600, 560, 200], [4950, 460, 180],
	[6100, 560, 260], [6100, 1020, 300]]
## Walls for wall jumps: [x, top y, bottom y, width]
const WALLS := [[2900, 260, 700, 70], [3120, 120, 600, 70]]
## Dew drops in arcs: [x0, y0, x1, y1, height, count]
const DEW_ARCS := [[300, 820, 800, 790, 140, 7], [1080, 640, 1420, 500, 90, 5], [2350, 560, 2700, 640, 120, 6],
	[3300, 520, 3500, 640, 60, 4], [4300, 560, 5400, 700, 260, 12], [6150, 980, 6380, 980, 30, 4], [6700, 700, 7300, 700, 120, 8]]
const ENEMIES := [[1600, 900], [3900, 630], [6800, 760]]
const CAGES := [[1380, 560], [3040, 120], [6250, 1020]]
const EXIT := Vector2(7450, 740)

var hero: HeroBody
var rig: CutoutRig
var control: TouchControl
var cam: Camera2D
var hud_dew: Label
var hud_cages: Label
var dew := 0
var freed_cages := 0
var _trail: Line2D
var _dust: CPUParticles2D
var _finished := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("9fd3f0"))
	_build_background()
	for run in GROUND:
		_ground(run)
	for l in LEDGES:
		_ledge(Vector2(l[0], l[1]), float(l[2]))
	for w in WALLS:
		_wall(float(w[0]), float(w[1]), float(w[2]), float(w[3]))
	for a in DEW_ARCS:
		_dew_arc(Vector2(a[0], a[1]), Vector2(a[2], a[3]), float(a[4]), int(a[5]))
	for e in ENEMIES:
		var m := Murk.new()
		m.position = Vector2(e[0], e[1] - 120)
		m.level = self
		add_child(m)
	for c in CAGES:
		var cage := Cage.new()
		cage.position = Vector2(c[0], c[1])
		cage.level = self
		add_child(cage)
	var gate := ExitGate.new()
	gate.position = EXIT
	gate.level = self
	add_child(gate)
	# the hero
	control = TouchControl.new()
	add_child(control)
	hero = HeroBody.new()
	hero.position = Vector2(120, 880)
	hero.control = control
	hero.z_index = 5
	add_child(hero)
	rig = CutoutRig.new()
	rig.body = hero
	hero.add_child(rig)
	control.hero = hero
	cam = Camera2D.new()
	cam.set_script(load("res://scripts/follow_camera.gd"))
	cam.set("hero", hero)
	add_child(cam)
	control.camera = cam
	hero.landed.connect(_on_landed)
	hero.jumped.connect(func(): _puff(hero.global_position, 6))
	_dust = CPUParticles2D.new()
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 14
	_dust.lifetime = 0.5
	_dust.explosiveness = 0.95
	_dust.direction = Vector2(0, -1)
	_dust.spread = 80.0
	_dust.initial_velocity_min = 80.0
	_dust.initial_velocity_max = 220.0
	_dust.gravity = Vector2(0, 400)
	_dust.scale_amount_min = 4.0
	_dust.scale_amount_max = 9.0
	_dust.color = Color(0.92, 0.85, 0.7, 0.8)
	_dust.z_index = 6
	add_child(_dust)
	_build_hud()


func _process(_delta: float) -> void:
	# a soft light trail under the finger
	_trail.clear_points()
	for q in control.trail:
		_trail.add_point(q)
	if hero.global_position.y > BOTTOM:
		_respawn()


func _on_landed(speed: float) -> void:
	if speed > 500.0:
		_puff(hero.global_position, int(clampf(speed / 90.0, 6.0, 16.0)))
		cam.call("shake", clampf((speed - 900.0) / 1500.0, 0.0, 0.5) * 10.0)


func _puff(at: Vector2, n: int) -> void:
	_dust.global_position = at
	_dust.amount = maxi(n, 2)
	_dust.restart()
	_dust.emitting = true


func _respawn() -> void:
	hero.global_position = Vector2(120, 880)
	hero.velocity = Vector2.ZERO
	cam.call("snap")


func add_dew() -> void:
	dew += 1
	hud_dew.text = _fa(dew)


func cage_freed() -> void:
	freed_cages += 1
	hud_cages.text = _fa(freed_cages) + " / " + _fa(CAGES.size())


func finish() -> void:
	if _finished:
		return
	_finished = true
	var l := _label(Strings.t("v4_done") + "\n" + Strings.t("v4_dew") + " " + _fa(dew) + "   " + Strings.t("v4_cages") + " " + _fa(freed_cages), 46)
	l.position = Vector2(340, 250)
	l.size = Vector2(600, 200)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# ---------------------------------------------------------------- building (placeholders until the painted kit)

func _smooth(points: Array) -> PackedVector2Array:
	var pts: Array = []
	for q in points:
		pts.append(Vector2(q[0], q[1]))
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		var steps := int(maxf(4.0, p1.distance_to(p2) / 24.0))
		for s in steps:
			var tt := float(s) / steps
			var t2 := tt * tt
			var t3 := t2 * tt
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * tt + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


func _ground(run: Array) -> void:
	var top := _smooth(run)
	var poly := top.duplicate()
	poly.append(Vector2(top[top.size() - 1].x, BOTTOM + 400.0))
	poly.append(Vector2(top[0].x, BOTTOM + 400.0))
	var body := StaticBody2D.new()
	var col := CollisionPolygon2D.new()
	col.polygon = poly
	body.add_child(col)
	add_child(body)
	# soil: warm earth, darker with depth (vertex colours), a rounded cliff at each end
	var soil := Polygon2D.new()
	soil.polygon = poly
	var cols := PackedColorArray()
	for q in poly:
		cols.append(Color("8a5a34").lerp(Color("4a2c1a"), clampf((q.y - 700.0) / 700.0, 0.0, 1.0)))
	soil.vertex_colors = cols
	add_child(soil)
	var edge := Line2D.new()
	edge.points = top
	edge.width = 30.0
	edge.default_color = Color("3f8f3e")
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(edge)
	var light := Line2D.new()
	var up := PackedVector2Array()
	for q in top:
		up.append(q + Vector2(0, -8))
	light.points = up
	light.width = 12.0
	light.default_color = Color("7cc95a")
	light.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(light)
	# tufts and flowers along the top
	var deco := Deco.new()
	deco.top = top
	add_child(deco)


func _ledge(at: Vector2, w: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 20)
	shape.shape = rect
	shape.one_way_collision = true
	shape.position = Vector2(0, 10)
	body.add_child(shape)
	body.position = at
	add_child(body)
	var plank := Log.new()
	plank.w = w
	body.add_child(plank)


func _wall(x: float, top: float, bottom: float, w: float) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, bottom - top)
	shape.shape = rect
	body.position = Vector2(x, (top + bottom) * 0.5)
	body.add_child(shape)
	add_child(body)
	var stone := Pillar.new()
	stone.size = rect.size
	body.add_child(stone)


func _dew_arc(a: Vector2, b: Vector2, h: float, n: int) -> void:
	for i in n:
		var k := float(i) / maxf(n - 1, 1)
		var d := Dew.new()
		d.position = a.lerp(b, k) + Vector2(0, -h * 4.0 * k * (1.0 - k)) + Vector2(0, -40)
		d.level = self
		d.phase = i * 0.4
		add_child(d)


func _build_background() -> void:
	var pb := ParallaxBackground.new()
	add_child(pb)
	var layers := [["sky", 0.0, Color("9fd3f0")], ["far", 0.12, Color("8ea6cf")], ["mid", 0.3, Color("7fb36a")], ["near", 0.55, Color("4f8f45")]]
	for L in layers:
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(float(L[1]), 0.0 if L[0] == "sky" else 0.75 + float(L[1]) * 0.3)
		pb.add_child(pl)
		var path := "res://art/bg/meadow_old_%s.png" % L[0]
		if ResourceLoader.exists(path):
			var spr := Sprite2D.new()
			spr.texture = load(path)
			spr.centered = false
			var sc := 1100.0 / spr.texture.get_height()
			spr.scale = Vector2(sc, sc)
			spr.position = Vector2(0, -60)
			pl.motion_mirroring = Vector2(spr.texture.get_width() * sc, 0)
			pl.add_child(spr)
		else:
			var hills := Hills.new()
			hills.kind = String(L[0])
			hills.col = L[2]
			pl.add_child(hills)
			pl.motion_mirroring = Vector2(2560, 0)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_trail = Line2D.new()
	_trail.width = 14.0
	_trail.default_color = Color(1, 0.95, 0.7, 0.45)
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	layer.add_child(_trail)
	var drop_icon := Dew.new()
	drop_icon.position = Vector2(48, 50)
	drop_icon.icon = true
	layer.add_child(drop_icon)
	hud_dew = _label("۰", 34)
	hud_dew.position = Vector2(76, 26)
	var cage_icon := Cage.new()
	cage_icon.icon = true
	cage_icon.position = Vector2(220, 74)
	cage_icon.scale = Vector2(0.4, 0.4)
	layer.add_child(cage_icon)
	hud_cages = _label("۰ / " + _fa(CAGES.size()), 34)
	hud_cages.position = Vector2(250, 26)
	var help := _label(Strings.t("v4_help"), 19)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(900, 0)
	help.size = Vector2(900, 90)
	help.position = Vector2(190, 610)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.create_tween().tween_property(help, "modulate:a", 0.0, 1.5).set_delay(9.0)


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("fff6dc"))
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color("3b2416"))
	var layer: CanvasLayer = null
	for c in get_children():
		if c is CanvasLayer and c.layer == 20:
			layer = c
	if layer:
		layer.add_child(l)
	else:
		add_child(l)
	return l


static func _fa(n: int) -> String:
	var digits := "۰۱۲۳۴۵۶۷۸۹"
	var s := str(n)
	var out := ""
	for ch in s:
		out += digits[int(ch)] if ch >= "0" and ch <= "9" else ch
	return out


# ---------------------------------------------------------------- pieces

class Deco extends Node2D:
	var top: PackedVector2Array

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(top[0].x)
		for i in range(0, top.size(), 2):
			var q: Vector2 = top[i]
			var r := rng.randf()
			if r < 0.35:
				for k in 3:
					var a := -PI * 0.5 + (k - 1) * 0.35 + rng.randf_range(-0.1, 0.1)
					draw_line(q + Vector2(0, -6), q + Vector2(0, -6) + Vector2.from_angle(a) * rng.randf_range(14, 26), Color("5aa845"), 4.0)
			elif r < 0.5:
				var fc: Color = [Color("f6e27a"), Color("f28fb0"), Color("ffffff"), Color("b58cf0")][rng.randi() % 4]
				draw_line(q + Vector2(0, -6), q + Vector2(0, -22), Color("3f8f3e"), 3.0)
				draw_circle(q + Vector2(0, -24), 6.0, fc)
				draw_circle(q + Vector2(0, -24), 2.5, Color("f2b632"))


class Log extends Node2D:
	var w := 200.0

	func _draw() -> void:
		var r := Rect2(-w * 0.5, 0, w, 24)
		draw_rect(Rect2(r.position - Vector2(3, 3), r.size + Vector2(6, 6)), Color("3b2416"))
		draw_rect(r, Color("a8743f"))
		draw_rect(Rect2(r.position, Vector2(w, 7)), Color("c99a5e"))
		for k in int(w / 60.0):
			var x := -w * 0.5 + 30.0 + k * 60.0
			draw_line(Vector2(x, 3), Vector2(x, 21), Color("7a522b"), 3.0)
		draw_rect(Rect2(-w * 0.5 + 6, -6, w - 12, 8), Color("5aa845"))


class Pillar extends Node2D:
	var size := Vector2(70, 400)

	func _draw() -> void:
		var r := Rect2(-size * 0.5, size)
		draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color("3b2416"))
		draw_rect(r, Color("b9a58a"))
		var n := int(size.y / 60.0)
		for k in n:
			var y: float = r.position.y + k * 60.0
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("8c7a63"), 3.0)
		draw_rect(Rect2(r.position + Vector2(8, 0), Vector2(10, r.size.y)), Color(1, 1, 1, 0.15))
		for k in 3:
			draw_line(Vector2(r.position.x + 6, r.position.y + 30 + k * 120), Vector2(r.position.x - 10, r.position.y + 80 + k * 120), Color("4f9a3e"), 5.0)


class Hills extends Node2D:
	var kind := "far"
	var col := Color.WHITE

	func _draw() -> void:
		if kind == "sky":
			for i in 12:
				var c := Color("cfe9f7").lerp(Color("8cc6ec"), i / 11.0)
				draw_rect(Rect2(-200, -200 + i * 80, 3000, 82), c.lerp(Color("ffe6b0"), 0.25 if i > 8 else 0.0))
			for i in 5:
				var c2 := Vector2(300 + i * 520, 140 + (i % 2) * 60)
				for k in 4:
					draw_circle(c2 + Vector2(k * 40 - 60, -abs(k - 1.5) * 10), 42.0, Color(1, 1, 1, 0.85))
			return
		var base: float = {"far": 620.0, "mid": 700.0, "near": 820.0}[kind]
		var amp: float = {"far": 140.0, "mid": 90.0, "near": 70.0}[kind]
		var pts := PackedVector2Array()
		for i in 65:
			var x := i * 40.0
			pts.append(Vector2(x, base - amp * (0.5 + 0.5 * sin(x * 0.004 + base) * cos(x * 0.0023))))
		pts.append(Vector2(2560, 1600))
		pts.append(Vector2(0, 1600))
		draw_colored_polygon(pts, col)
		if kind == "near":
			for i in 9:
				var x := 140.0 + i * 290.0
				var y: float = base - 40.0
				draw_line(Vector2(x, y + 60), Vector2(x, y - 60), Color("4a3020"), 16.0)
				draw_circle(Vector2(x, y - 90), 70.0, Color("3f7f3a"))
				draw_circle(Vector2(x - 40, y - 60), 50.0, Color("478c40"))


class Dew extends Area2D:
	var level: Node
	var phase := 0.0
	var icon := false
	var _t := 0.0
	var _taken := false

	func _ready() -> void:
		if icon:
			return
		collision_layer = 0
		collision_mask = 1
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 26.0
		s.shape = c
		add_child(s)
		body_entered.connect(func(b):
			if b is HeroBody and not _taken:
				_taken = true
				level.add_dew()
				var tw := create_tween()
				tw.tween_property(self, "position:y", position.y - 50.0, 0.25)
				tw.parallel().tween_property(self, "scale", Vector2(1.6, 1.6), 0.25)
				tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
				tw.tween_callback(queue_free))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var bob := sin(_t * 3.0 + phase) * 4.0
		var c := Vector2(0, bob)
		draw_circle(c, 15.0 + sin(_t * 5.0 + phase) * 1.5, Color(1, 0.85, 0.3, 0.25))
		var pts := PackedVector2Array([c + Vector2(0, -15), c + Vector2(8, -3), c + Vector2(9, 5), c + Vector2(0, 11), c + Vector2(-9, 5), c + Vector2(-8, -3)])
		draw_colored_polygon(pts, Color("f2b632"))
		draw_circle(c + Vector2(-3, -1), 3.5, Color(1, 1, 0.9, 0.9))


## A smoke creature («دودک»): walks, a strike or a jump on its head frees it (it never dies).
class Murk extends CharacterBody2D:
	var level: Node
	var dir := -1.0
	var freed := false
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 8
		collision_mask = 1
		add_to_group("strikeable")
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 30.0
		s.shape = c
		s.position = Vector2(0, -32)
		add_child(s)

	func _physics_process(delta: float) -> void:
		_t += delta
		if freed:
			return
		velocity.y += 2600.0 * delta
		velocity.x = dir * 90.0
		move_and_slide()
		if is_on_wall():
			dir = -dir
		var hero: HeroBody = level.hero
		if hero and hero.global_position.distance_to(global_position + Vector2(0, -30)) < 60.0:
			if hero.velocity.y > 100.0 and hero.global_position.y < global_position.y - 30.0:
				hero.velocity.y = -800.0
				hit(hero)
			else:
				hero.velocity = Vector2(signf(hero.global_position.x - global_position.x) * 600.0, -500.0)
		queue_redraw()

	func hit(_by: Node) -> void:
		if freed:
			return
		freed = true
		remove_from_group("strikeable")
		collision_layer = 0
		var tw := create_tween()
		tw.tween_property(self, "position:y", position.y - 90.0, 0.4).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "modulate", Color(1.5, 1.4, 1.0, 0.0), 0.6)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var sq := sin(_t * 8.0) * 3.0
		var c := Vector2(0, -30 - sq)
		draw_circle(c, 33.0, Color("2a1f3d"))
		draw_circle(c, 30.0, Color("5b3f8a") if not freed else Color("f6c94a"))
		for k in 4:
			var a := _t * 2.0 + k * 1.6
			draw_circle(c + Vector2(cos(a) * 26.0, sin(a) * 10.0 - 22.0), 9.0, Color(0.5, 0.35, 0.75, 0.6))
		draw_circle(c + Vector2(dir * 10.0, -6), 8.0, Color.WHITE)
		draw_circle(c + Vector2(dir * 13.0, -5), 4.0, Color("1d100a"))
		draw_line(c + Vector2(dir * 2.0, -16), c + Vector2(dir * 18.0, -12), Color("1d100a"), 3.0)


## A smoke cage with a little clock spirit («ساعتک») inside: a strike opens it and the spirit flies off happily.
class Cage extends Area2D:
	var level: Node
	var icon := false
	var opened := false
	var _t := 0.0

	func _ready() -> void:
		if not icon:
			add_to_group("strikeable")

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func hit(_by: Node) -> void:
		if opened:
			return
		opened = true
		remove_from_group("strikeable")
		level.cage_freed()
		var tw := create_tween()
		tw.tween_property(self, "_t", _t + 2.0, 1.0)

	func _draw() -> void:
		var c := Vector2(0, -60)
		if not opened:
			draw_circle(c, 52.0, Color(0.3, 0.2, 0.45, 0.35))
			for k in 7:
				var x := -40.0 + k * 13.3
				draw_line(c + Vector2(x, -50), c + Vector2(x, 50), Color("3b2a55"), 5.0)
			draw_arc(c + Vector2(0, -50), 42.0, PI, TAU, 16, Color("3b2a55"), 6.0)
			draw_line(c + Vector2(-46, 50), c + Vector2(46, 50), Color("3b2a55"), 8.0)
		var fly := 0.0 if not opened else minf(_t, 3.0) * 60.0
		var sp := c + Vector2(sin(_t * 3.0) * 4.0, -fly + sin(_t * 5.0) * 3.0)
		draw_circle(sp, 20.0, Color("2a1f3d"))
		draw_circle(sp, 17.0, Color("f6efe0"))
		draw_line(sp, sp + Vector2(0, -11), Color("2a1f3d"), 2.5)
		draw_line(sp, sp + Vector2(cos(_t * 2.0) * 8.0, sin(_t * 2.0) * 8.0), Color("c0392b"), 2.0)
		for side in [-1.0, 1.0]:
			var wa := sin(_t * 18.0) * 0.5
			draw_colored_polygon(PackedVector2Array([sp + Vector2(side * 14, -4), sp + Vector2(side * 34, -16 + wa * 10.0), sp + Vector2(side * 30, 4)]), Color(0.8, 0.95, 1.0, 0.8))


class ExitGate extends Area2D:
	var level: Node
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(80, 200)
		s.shape = r
		s.position = Vector2(0, -100)
		add_child(s)
		body_entered.connect(func(b):
			if b is HeroBody:
				level.finish())

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(side * 70 - 18, -230, 36, 230), Color("3b2416"))
			draw_rect(Rect2(side * 70 - 14, -226, 28, 226), Color("d8c39a"))
		draw_arc(Vector2(0, -230), 70.0, PI, TAU, 24, Color("3b2416"), 20.0)
		draw_arc(Vector2(0, -230), 70.0, PI, TAU, 24, Color("2a9d8f"), 12.0)
		draw_circle(Vector2(0, -120), 48.0 + sin(_t * 3.0) * 4.0, Color(1, 0.9, 0.5, 0.35))
		for i in 3:
			var st := _t * (1.5 + i * 0.4) + i * 2.0
			draw_arc(Vector2(0, -120), 14.0 + i * 12.0, st, st + 3.5, 20, Color(1, 0.95, 0.75, 0.8 - i * 0.2), 5.0)
