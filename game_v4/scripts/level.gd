extends Node2D
## v4 sample level (docs/45 section 5): the first two "chunks" of the old meadow plus a glide gap and a hidden cage,
## to try the movement and the finger controls. The ground, layers and props are placeholders drawn by code until the
## painted kit arrives (art/kits, art/bg); then the same layout is dressed with the painted pieces.

const BOTTOM := 1600.0
const ERA_ART := "forest_old"          ## which painted layers (art/layers/<ERA_ART>_*.png)

## The way of the sample level (old meadow): an organic route, no floating blocks.
##  A  rolling meadow, a smoke creature, a bounce mushroom up into the big tree
##  B  wall-run up the trunk, along curved branches through the crown (a cage at the far end)
##  C  vines over the ravine: grab, swing, let go
##  D  a steep bank: slide down along a ribbon of dew, onto sinking lily leaves over the pond
##  E  a petal wind stream up the cliff (glide in it); a hidden cage behind the leaves at the top
##  F  the last run, two creatures, the gate
## Ground runs (smooth curves; each a solid piece): the gaps are the ravine and the pond.
const GROUND := [
	[[-400, 900], [250, 900], [330, 880], [360, 800], [640, 790], [760, 820], [980, 830], [1010, 900], [1350, 900], [1420, 860], [1700, 900], [2300, 900], [2650, 880]],
	[[3750, 760], [3950, 700], [4100, 700], [4350, 820], [4650, 1000], [4900, 1140], [5050, 1180]],
	[[5750, 1180], [5900, 1180], [6050, 1180]],
	[[6050, 560], [6400, 540], [6800, 580], [7200, 560], [7800, 560]],
]
const TRUNKS := [[1850, 300, 900, 130]]                                   ## x, top, bottom, width
const BRANCHES := [
	[[1915, 640], [2100, 620], [2280, 640]],
	[[1785, 470], [1600, 450], [1480, 470]],
	[[1915, 360], [2150, 330], [2400, 350], [2620, 330]],
]
const VINES := [[2900, 240, 290, 0.5], [3250, 220, 300, -0.4], [3600, 250, 280, 0.3]]    ## x, y, length, start angle
const MUSHROOMS := [[1550, 900]]
const PONDS := [[5050, 1190, 700]]
const LEAVES := [[5180, 1180], [5390, 1175], [5600, 1180]]
const WINDS := [[5960, 1180, 170, 760]]                                    ## x, bottom, width, height
const BUSHES := [[6420, 520]]
## Dew ribbons: smooth paths the drops follow (they show the way, like a trail): [points], spacing
const DEW_PATHS := [
	[[[300, 820], [600, 770], [900, 820], [1200, 810]], 60],
	[[[1480, 820], [1520, 600], [1580, 420]], 60],
	[[[1960, 290], [2200, 260], [2450, 280], [2620, 270]], 70],
	[[[2700, 600], [2900, 680], [3080, 600], [3250, 690], [3420, 600], [3600, 680], [3760, 620]], 70],
	[[[4150, 640], [4400, 760], [4650, 930], [4900, 1080]], 60],
	[[[5180, 1100], [5290, 1040], [5390, 1100], [5500, 1040], [5600, 1100]], 55],
	[[[5960, 1050], [5960, 850], [5960, 650], [6060, 480]], 70],
	[[[6600, 480], [6900, 430], [7200, 480], [7400, 470]], 70],
]
const ENEMIES := [[1200, 860], [6700, 520], [7050, 520]]
const CAGES := [[2600, 330], [6420, 545], [5600, 1170]]
const CHECKPOINTS := [[120, 880], [1700, 880], [3850, 700], [5000, 1160], [6150, 540]]
const EXIT := Vector2(7600, 560)

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
var _checkpoint := 0
var _fg: Node2D
var _bar: Control
var hud_dist: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("9fd3f0"))
	_build_background()
	for run in GROUND:
		_ground(run)
	for t in TRUNKS:
		var trunk := PathParts.Trunk.new()
		trunk.position = Vector2(t[0], 0)
		trunk.top = float(t[1])
		trunk.bottom = float(t[2])
		trunk.w = float(t[3])
		add_child(trunk)
	for br in BRANCHES:
		var branch := PathParts.Branch.new()
		branch.points = PathParts.vecs(br)
		add_child(branch)
	for v in VINES:
		var vine := PathParts.Vine.new()
		vine.position = Vector2(v[0], v[1])
		vine.length = float(v[2])
		vine.angle = float(v[3])
		add_child(vine)
	for m in MUSHROOMS:
		var mush := PathParts.Mushroom.new()
		mush.position = Vector2(m[0], m[1])
		add_child(mush)
	for pd in PONDS:
		var pond := PathParts.Pond.new()
		pond.position = Vector2(pd[0], pd[1])
		pond.w = float(pd[2])
		pond.level = self
		add_child(pond)
	for lf in LEAVES:
		var leaf := PathParts.Leaf.new()
		leaf.position = Vector2(lf[0], lf[1])
		add_child(leaf)
	for wd in WINDS:
		var wind := PathParts.Wind.new()
		wind.position = Vector2(wd[0], wd[1])
		wind.size = Vector2(wd[2], wd[3])
		add_child(wind)
	for dp in DEW_PATHS:
		_dew_path(PathParts.vecs(dp[0]), float(dp[1]))
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
	for cp in CHECKPOINTS.slice(1):
		var lantern := Sprite2D.new()
		lantern.texture = Kit.item(19)
		if lantern.texture:
			lantern.scale = Vector2.ONE * 90.0 / lantern.texture.get_height()
			lantern.offset = Vector2(0, -lantern.texture.get_height() * 0.5)
			lantern.position = Vector2(float(cp[0]) - 40.0, float(cp[1]) + 22.0)
			add_child(lantern)
	for bu in BUSHES:
		var bush := PathParts.Bush.new()
		bush.position = Vector2(bu[0], bu[1])
		bush.z_index = 20
		add_child(bush)
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
		respawn()
	if _fg and cam:
		var fw: float = _fg.get_meta("w") if _fg.has_meta("w") else _fg.get("width")
		_fg.position.x = -fposmod(cam.global_position.x * 1.35 * cam.zoom.x, fw)
		_fg.position.y = get_viewport_rect().size.y - 760.0 + 110.0
	if hud_dist:
		hud_dist.text = _fa(maxi(0, int((hero.global_position.x - 120.0) / 100.0)))
		_bar.set("k", clampf((hero.global_position.x - 120.0) / (EXIT.x - 120.0), 0.0, 1.0))
	for i in CHECKPOINTS.size():
		if hero.global_position.x > float(CHECKPOINTS[i][0]) and hero.is_on_floor():
			_checkpoint = maxi(_checkpoint, i)


func _on_landed(speed: float) -> void:
	if speed > 500.0:
		_puff(hero.global_position, int(clampf(speed / 90.0, 6.0, 16.0)))
		cam.call("shake", clampf((speed - 900.0) / 1500.0, 0.0, 0.5) * 10.0)


func _puff(at: Vector2, n: int) -> void:
	_dust.global_position = at
	_dust.amount = maxi(n, 2)
	_dust.restart()
	_dust.emitting = true


func respawn() -> void:
	var c: Array = CHECKPOINTS[_checkpoint]
	hero.global_position = Vector2(c[0], c[1])
	hero.velocity = Vector2.ZERO
	if hero.vine:
		hero.vine.call("let_go")
		hero.vine = null
	cam.call("snap")


func add_dew() -> void:
	dew += 1
	hud_dew.text = _fa(dew)


func cage_freed() -> void:
	freed_cages += 1
	hud_cages.text = _fa(freed_cages) + "/" + _fa(CAGES.size())


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
	var look := Scenery.MossTerrain.new()
	look.top = top
	look.depth = BOTTOM + 400.0
	add_child(look)


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


## Drops spaced evenly along a smooth path.
func _dew_path(pts: Array, spacing: float) -> void:
	var line := PathParts.smooth(pts, 8.0)
	var acc := spacing
	var i := 0
	for k in line.size() - 1:
		var seg := line[k].distance_to(line[k + 1])
		while acc <= seg:
			var d := Dew.new()
			d.position = line[k].lerp(line[k + 1], acc / seg)
			d.level = self
			d.phase = i * 0.35
			add_child(d)
			acc += spacing
			i += 1
		acc -= seg


func _dew_arc(a: Vector2, b: Vector2, h: float, n: int) -> void:
	for i in n:
		var k := float(i) / maxf(n - 1, 1)
		var d := Dew.new()
		d.position = a.lerp(b, k) + Vector2(0, -h * 4.0 * k * (1.0 - k)) + Vector2(0, -40)
		d.level = self
		d.phase = i * 0.4
		add_child(d)


func _build_background() -> void:
	RenderingServer.set_default_clear_color(Scenery.PAL.sky_low)
	var pb := ParallaxBackground.new()
	add_child(pb)
	# [kind, motion x, motion y, painted file]
	var layers := [["sky", 0.0, 0.0, "sky"], ["far", 0.15, 0.35, "far"], ["mid", 0.35, 0.55, "mid"], ["back", 0.7, 0.85, "near"], ["shafts", 0.5, 0.6, ""]]
	for L in layers:
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(float(L[1]), float(L[2]))
		pb.add_child(pl)
		var path := "res://art/layers/%s_%s.png" % [ERA_ART, L[3]]
		if L[3] != "" and ResourceLoader.exists(path):
			# painted layer: [height, top y] in parallax space, so its foot sits where the placeholder's did
			var fit: Array = {"sky": [1900.0, -750.0], "far": [1150.0, -150.0], "mid": [1450.0, -380.0], "near": [1050.0, 160.0]}[L[3]]
			var spr := Sprite2D.new()
			spr.texture = load(path)
			spr.centered = false
			var sc: float = float(fit[0]) / spr.texture.get_height()
			spr.scale = Vector2(sc, sc)
			spr.position = Vector2(0, float(fit[1]))
			pl.motion_mirroring = Vector2(spr.texture.get_width() * sc, 0)
			pl.add_child(spr)
			if L[3] == "sky":
				var spr2 := Sprite2D.new()
				spr2.texture = spr.texture
				spr2.centered = false
				spr2.scale = Vector2(-sc, sc)
				spr2.position = Vector2(spr.texture.get_width() * sc * 2.0, float(fit[1]))
				pl.add_child(spr2)
				pl.motion_mirroring = Vector2(spr.texture.get_width() * sc * 2.0, 0)
		else:
			var f := Scenery.ForestLayer.new()
			f.kind = String(L[0])
			pl.add_child(f)
			pl.motion_mirroring = Vector2(f.width, 0)
	# the dark foreground at the frame's bottom edge, sliding faster than the path
	var fg_layer := CanvasLayer.new()
	fg_layer.layer = 5
	add_child(fg_layer)
	_fg = Scenery.Foreground.new()
	fg_layer.add_child(_fg)
	var front := "res://art/layers/%s_front.png" % ERA_ART
	if ResourceLoader.exists(front):
		# the painted foreground replaces the placeholder clumps (two copies side by side for the loop)
		_fg.set_script(null)
		_fg = Node2D.new()
		fg_layer.add_child(_fg)
		var tex: Texture2D = load(front)
		var sc := 760.0 / tex.get_height()
		for i in 2:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.scale = Vector2(sc, sc)
			spr.position = Vector2(i * tex.get_width() * sc, 0)
			_fg.add_child(spr)
		_fg.set_meta("w", tex.get_width() * sc)
	else:
		var fg2 := Scenery.Foreground.new()
		fg2.position.x = _fg.width
		_fg.add_child(fg2)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_trail = Line2D.new()
	_trail.width = 14.0
	_trail.default_color = Color(1, 0.95, 0.7, 0.45)
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	layer.add_child(_trail)
	var view := get_viewport_rect().size
	hud_dist = _label("۰", 40)
	hud_dist.position = Vector2(view.x * 0.5 - 150, 10)
	hud_dist.size = Vector2(110, 50)
	hud_dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bar = HudBar.new()
	_bar.position = Vector2(view.x * 0.5 - 30, 24)
	layer.add_child(_bar)
	var retry := RoundButton.new()
	retry.kind = "retry"
	retry.position = Vector2(54, 50)
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	layer.add_child(retry)
	var pause := RoundButton.new()
	pause.kind = "pause"
	pause.position = Vector2(view.x - 54, 50)
	pause.pressed.connect(func(): get_tree().paused = not get_tree().paused)
	layer.add_child(pause)
	var drop_icon := Dew.new()
	drop_icon.position = Vector2(view.x - 250, 52)
	drop_icon.icon = true
	layer.add_child(drop_icon)
	hud_dew = _label("۰", 30)
	hud_dew.position = Vector2(view.x - 228, 30)
	var cage_icon := Cage.new()
	cage_icon.icon = true
	cage_icon.position = Vector2(view.x - 150, 70)
	cage_icon.scale = Vector2(0.32, 0.32)
	layer.add_child(cage_icon)
	hud_cages = _label("۰/" + _fa(CAGES.size()), 30)
	hud_cages.position = Vector2(view.x - 126, 30)
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
		var ft := Kit.item(int(_t * 10.0 + phase * 3.0) % 3)
		if ft:
			draw_circle(c, 22.0 + sin(_t * 5.0 + phase) * 2.0, Color(1, 0.85, 0.3, 0.18))
			Kit.draw_at(self, ft, c + Vector2(0, 22), 46.0 if not icon else 40.0)
			return
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
		var et := Kit.tex("enemies_forest_parts", 4 if not freed else 22)
		if et:
			var s := 96.0 / et.get_height()
			draw_set_transform(Vector2(0, 6), sin(_t * 8.0) * 0.06, Vector2(s * -dir * (1.0 + sq * 0.01), s * (1.0 - sq * 0.012)))
			draw_texture(et, Vector2(-et.get_width() * 0.5, -et.get_height()))
			draw_set_transform(Vector2.ZERO)
			return
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
		var ct := Kit.item(16 if not opened else 18)
		if ct:
			Kit.draw_at(self, ct, Vector2(0, 10), 150.0 if not icon else 150.0, sin(_t * 1.5) * 0.04)
			var sp := Kit.item(10 if not opened else 11 + int(_t * 4.0) % 2 * 4)
			var fly := 0.0 if not opened else minf(_t, 3.0) * 70.0
			Kit.draw_at(self, sp, Vector2(sin(_t * 3.0) * 6.0, -40.0 - fly + sin(_t * 5.0) * 4.0), 70.0)
			return
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
		var arch := Kit.env(17)
		if arch:
			draw_circle(Vector2(0, -110), 70.0 + sin(_t * 3.0) * 6.0, Color(1, 0.9, 0.5, 0.3))
			for i in 3:
				var st := _t * (1.5 + i * 0.4) + i * 2.0
				draw_arc(Vector2(0, -105), 16.0 + i * 14.0, st, st + 3.5, 20, Color(1, 0.95, 0.75, 0.85 - i * 0.2), 5.0)
			Kit.draw_at(self, arch, Vector2(0, 16), 250.0)
			return
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(side * 70 - 18, -230, 36, 230), Color("3b2416"))
			draw_rect(Rect2(side * 70 - 14, -226, 28, 226), Color("d8c39a"))
		draw_arc(Vector2(0, -230), 70.0, PI, TAU, 24, Color("3b2416"), 20.0)
		draw_arc(Vector2(0, -230), 70.0, PI, TAU, 24, Color("2a9d8f"), 12.0)
		draw_circle(Vector2(0, -120), 48.0 + sin(_t * 3.0) * 4.0, Color(1, 0.9, 0.5, 0.35))
		for i in 3:
			var st := _t * (1.5 + i * 0.4) + i * 2.0
			draw_arc(Vector2(0, -120), 14.0 + i * 12.0, st, st + 3.5, 20, Color(1, 0.95, 0.75, 0.8 - i * 0.2), 5.0)


## The level's progress bar next to the distance (top centre).
class HudBar extends Control:
	var k := 0.0:
		set(v):
			k = v
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(0, 0, 200, 22)
		draw_rect(r.grow(4), Color(0.05, 0.12, 0.1, 0.55))
		draw_rect(r, Color(1, 1, 1, 0.85), false, 3.0)
		draw_rect(Rect2(4, 4, 192 * k, 14), Color("8fe0f0"))


## A round glass button of the HUD (retry / pause), placeholder until the UI art.
class RoundButton extends Button:
	var kind := "retry"

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		size = Vector2(76, 76)
		position -= size * 0.5
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 34.0, Color(0.05, 0.15, 0.12, 0.45))
		draw_arc(c, 34.0, 0, TAU, 32, Color(1, 1, 1, 0.85), 3.0)
		if kind == "pause":
			draw_rect(Rect2(c + Vector2(-11, -13), Vector2(8, 26)), Color.WHITE)
			draw_rect(Rect2(c + Vector2(3, -13), Vector2(8, 26)), Color.WHITE)
		else:
			draw_arc(c, 15.0, -PI * 0.2, PI * 1.4, 20, Color.WHITE, 5.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(13, -16), c + Vector2(20, -2), c + Vector2(6, -4)]), Color.WHITE)
