class_name LoadoutIcon
extends Control
## Icon for a companion (its animated rig) or a tool (drawn in code) in the village screen
## and the backpack slots. No pictures: everything is drawn with outlines like the rigs.

const OUTLINE := Color("3b2418")

var kind := "tool"      ## "tool" or "companion"
var id := ""
var dim := false

var _t := 0.0


static func make(item_kind: String, item_id: String, icon_size := 96.0, dimmed := false) -> LoadoutIcon:
	var icon := LoadoutIcon.new()
	icon.kind = item_kind
	icon.id = item_id
	icon.dim = dimmed
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size = icon.custom_minimum_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _ready() -> void:
	if dim:
		modulate = Color(0.55, 0.55, 0.62)
	if kind == "companion" and id != "" and PaintedCreature.available("companion_" + id):
		var painted := PaintedCreature.make("companion_" + id, custom_minimum_size.y * 0.9, "idle")
		add_child(painted)
		resized.connect(func(): painted.position = Vector2(size.x * 0.5, size.y * 0.95))
		painted.position = Vector2(custom_minimum_size.x * 0.5, custom_minimum_size.y * 0.95)
	elif kind == "companion" and id != "":
		var rig := CompanionRig.new()
		rig.id = id
		rig.show_shadow = not rig.is_flyer()
		add_child(rig)
		resized.connect(_fit.bind(rig))
		_fit(rig)


func _fit(rig: CompanionRig) -> void:
	# companions are ~70 px tall; flyers hover 46 px up, so move them down into the box
	var s := size.y / 80.0
	rig.scale = Vector2(s, s)
	rig.position = Vector2(size.x * 0.5, size.y - 4.0 * s + (40.0 * s if rig.is_flyer() else 0.0))


func _process(delta: float) -> void:
	if kind == "tool":
		_t += delta
		queue_redraw()


func _draw() -> void:
	if kind != "tool" or id == "":
		return
	var rendered := WorldArt.tex("tool", id)
	if rendered:
		# the rendered icon, breathing a little
		var k := 1.0 + sin(_t * 2.0) * 0.03
		var fit := minf(size.x / rendered.get_width(), size.y / rendered.get_height()) * 0.92 * k
		var draw_size := Vector2(rendered.get_width(), rendered.get_height()) * fit
		draw_texture_rect(rendered, Rect2((size - draw_size) * 0.5, draw_size), false)
		return
	var s := size.x / 96.0
	draw_set_transform(size * 0.5, sin(_t * 2.0) * 0.04, Vector2(s, s))
	call("_tool_" + id)
	draw_set_transform(Vector2.ZERO)


# --- Drawing helpers ------------------------------------------------------------

func _poly(points: PackedVector2Array, fill: Color) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, 5.0, true)
	draw_colored_polygon(points, fill)


func _oval(center: Vector2, radius: Vector2, fill: Color, angle := 0.0) -> void:
	var points := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(angle))
	_poly(points, fill)


func _rect(center: Vector2, half: Vector2, fill: Color, angle := 0.0) -> void:
	var points := PackedVector2Array()
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		points.append(center + (c * half).rotated(angle))
	_poly(points, fill)


func _stick(a: Vector2, b: Vector2, width: float, fill: Color) -> void:
	draw_line(a, b, OUTLINE, width + 5.0)
	draw_circle(a, (width + 5.0) * 0.5, OUTLINE)
	draw_circle(b, (width + 5.0) * 0.5, OUTLINE)
	draw_line(a, b, fill, width)
	draw_circle(a, width * 0.5, fill)
	draw_circle(b, width * 0.5, fill)


func _shine(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(-0.5))
	draw_colored_polygon(points, Color(1, 1, 1, 0.45))


func _sparkle(center: Vector2, r: float) -> void:
	var k := 0.6 + sin(_t * 4.0 + center.x) * 0.4
	draw_line(center + Vector2(-r * k, 0), center + Vector2(r * k, 0), Color.WHITE, 3.0)
	draw_line(center + Vector2(0, -r * k), center + Vector2(0, r * k), Color.WHITE, 3.0)


# --- The tools ------------------------------------------------------------------

func _tool_hammer() -> void:
	_stick(Vector2(-22, 30), Vector2(12, -8), 9.0, Color("b5793e"))
	_rect(Vector2(16, -16), Vector2(24, 12), Color("8e9aae"), 0.78)
	_rect(Vector2(16, -16), Vector2(8, 13), Color("6a768c"), 0.78)
	_shine(Vector2(8, -26), Vector2(8, 3))


func _tool_umbrella() -> void:
	_stick(Vector2(0, -24), Vector2(0, 30), 5.0, Color("7a4a2a"))
	draw_arc(Vector2(-7, 30), 7.0, 0.0, PI, 10, OUTLINE, 9.0)
	draw_arc(Vector2(-7, 30), 7.0, 0.0, PI, 10, Color("7a4a2a"), 5.0)
	var canopy := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		canopy.append(Vector2(cos(a) * 40.0, sin(a) * 32.0 - 4.0))
	for i in 4:
		canopy.append(Vector2(30.0 - i * 20.0, -4.0 + (6.0 if i % 2 == 0 else 0.0)))
	_poly(canopy, Color("ff5a7a"))
	for x in [-20.0, 0.0, 20.0]:
		draw_line(Vector2(x * 0.5, -34), Vector2(x, -4), Color("ffd0dc"), 4.0)
	_shine(Vector2(-16, -24), Vector2(10, 4))


func _tool_magnet() -> void:
	draw_arc(Vector2(0, -2), 26.0, PI, TAU, 20, OUTLINE, 24.0)
	draw_arc(Vector2(0, -2), 26.0, PI, TAU, 20, Color("e5533d"), 16.0)
	_rect(Vector2(-26, 14), Vector2(10, 14), Color("e5533d"))
	_rect(Vector2(26, 14), Vector2(10, 14), Color("e5533d"))
	_rect(Vector2(-26, 26), Vector2(10, 5), Color("d8dde6"))
	_rect(Vector2(26, 26), Vector2(10, 5), Color("d8dde6"))
	for i in 3:
		var a := _t * 3.0 + i * 2.1
		draw_circle(Vector2(cos(a) * 40.0, 34 + sin(a) * 6.0), 5.0, Color("ffc928"))


func _tool_compass() -> void:
	_oval(Vector2(0, 2), Vector2(36, 36), Color("e8b52c"))
	_oval(Vector2(0, 2), Vector2(28, 28), Color("fff6e3"))
	var a := sin(_t * 1.5) * 0.5
	_poly(PackedVector2Array([Vector2(0, -22).rotated(a), Vector2(7, 2).rotated(a), Vector2(-7, 2).rotated(a)]) as PackedVector2Array, Color("e5533d"))
	_poly(PackedVector2Array([Vector2(0, 26).rotated(a), Vector2(7, 2).rotated(a), Vector2(-7, 2).rotated(a)]) as PackedVector2Array, Color("3f8fe0"))
	draw_circle(Vector2(0, 2), 4.0, OUTLINE)
	_oval(Vector2(0, -36), Vector2(7, 5), Color("e8b52c"))
	_shine(Vector2(-12, -12), Vector2(8, 4))


func _tool_shoes() -> void:
	_poly(PackedVector2Array([Vector2(-34, 22), Vector2(-30, -6), Vector2(-10, -10), Vector2(0, 4), Vector2(28, 8), Vector2(36, 22)]), Color("3f8fe0"))
	_rect(Vector2(0, 26), Vector2(36, 5), Color("fff6e3"))
	draw_line(Vector2(-18, -2), Vector2(-6, 8), Color.WHITE, 4.0)
	# little wings: they run fast
	_poly(PackedVector2Array([Vector2(-28, -2), Vector2(-46, -22), Vector2(-40, -4), Vector2(-50, -8), Vector2(-36, 6)]), Color.WHITE)
	for i in 3:
		draw_line(Vector2(40 + i * 4, -6 + i * 10), Vector2(50 + i * 4, -6 + i * 10), Color("3f8fe0", 0.6), 3.0)


func _tool_shield() -> void:
	draw_circle(Vector2.ZERO, 40.0, Color(0.5, 0.85, 1.0, 0.25))
	_oval(Vector2.ZERO, Vector2(38, 38), Color(0.55, 0.85, 1.0, 0.55))
	draw_arc(Vector2.ZERO, 30.0, -2.6, -1.4, 10, Color(1, 1, 1, 0.8), 5.0)
	_shine(Vector2(-14, -16), Vector2(9, 5))
	draw_arc(Vector2.ZERO, 38.0 + sin(_t * 3.0) * 3.0, 0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)


func _tool_springs() -> void:
	_poly(PackedVector2Array([Vector2(-30, -10), Vector2(-24, -32), Vector2(-4, -34), Vector2(4, -20), Vector2(28, -16), Vector2(32, -4), Vector2(-30, -4)]), Color("4cb84a"))
	var squash := 1.0 + sin(_t * 5.0) * 0.15
	for i in 4:
		var y := -2.0 + i * 9.0 * squash
		draw_arc(Vector2(0, y + 4), 16.0, 0.0, PI, 10, OUTLINE, 8.0)
		draw_arc(Vector2(0, y + 4), 16.0, 0.0, PI, 10, Color("d8dde6"), 4.0)
	_rect(Vector2(0, 36 * squash), Vector2(22, 4), Color("8e9aae"))


func _tool_glasses() -> void:
	_stick(Vector2(-12, -6), Vector2(12, -6), 4.0, Color("9b5de5"))
	_oval(Vector2(-22, 0), Vector2(16, 14), Color("9b5de5"))
	_oval(Vector2(22, 0), Vector2(16, 14), Color("9b5de5"))
	_oval(Vector2(-22, 0), Vector2(11, 9), Color(0.75, 0.95, 1.0))
	_oval(Vector2(22, 0), Vector2(11, 9), Color(0.75, 0.95, 1.0))
	_shine(Vector2(-26, -4), Vector2(5, 3))
	_shine(Vector2(18, -4), Vector2(5, 3))
	_sparkle(Vector2(34, -24), 8.0)


func _tool_watch() -> void:
	_rect(Vector2(0, -32), Vector2(12, 10), Color("7a4a2a"))
	_rect(Vector2(0, 32), Vector2(12, 10), Color("7a4a2a"))
	_oval(Vector2.ZERO, Vector2(30, 30), Color("c0c8d6"))
	_oval(Vector2.ZERO, Vector2(23, 23), Color("e8f6ff"))
	var slow := _t * 0.6
	draw_line(Vector2.ZERO, Vector2(0, -16).rotated(slow), OUTLINE, 4.0)
	draw_line(Vector2.ZERO, Vector2(0, -10).rotated(slow * 0.1), OUTLINE, 4.0)
	draw_circle(Vector2.ZERO, 3.5, Color("e5533d"))
	_shine(Vector2(-9, -10), Vector2(7, 3))


func _tool_skateboard() -> void:
	_poly(PackedVector2Array([Vector2(-40, 0), Vector2(-34, -10), Vector2(34, -10), Vector2(40, 0), Vector2(34, 6), Vector2(-34, 6)]), Color("f39a2b"))
	for x in [-24.0, 24.0]:
		_oval(Vector2(x, 14), Vector2(7, 7), Color("2b3354"))
	# the little rocket
	_rect(Vector2(-6, -18), Vector2(14, 6), Color("d8dde6"))
	_poly(PackedVector2Array([Vector2(8, -24), Vector2(18, -18), Vector2(8, -12)]), Color("e5533d"))
	var flame := 8.0 + sin(_t * 20.0) * 4.0
	_poly(PackedVector2Array([Vector2(-20, -22), Vector2(-20 - flame * 2.0, -18), Vector2(-20, -14)]), Color("ffd23f"))


func _tool_balloon() -> void:
	draw_line(Vector2(0, 14), Vector2(0, 30), OUTLINE, 3.0)
	_rect(Vector2(0, 34), Vector2(10, 7), Color("b5793e"))
	var colors := [Color("e5533d"), Color("f39a2b"), Color("ffd23f"), Color("4cb84a"), Color("3f8fe0"), Color("9b5de5")]
	_oval(Vector2(0, -12), Vector2(30, 32), colors[0])
	for i in range(1, colors.size()):
		var w := 30.0 * (1.0 - i / 6.0)
		var points := PackedVector2Array()
		for k in 20:
			var a := TAU * k / 20.0
			points.append(Vector2(cos(a) * w, sin(a) * 31.0 - 12.0))
		draw_colored_polygon(points, colors[i])
	draw_arc(Vector2(0, -12), 30.0, 0, TAU, 32, OUTLINE, 3.0)
	_shine(Vector2(-12, -30), Vector2(7, 4))


func _tool_slingshot() -> void:
	_stick(Vector2(0, 34), Vector2(0, 4), 9.0, Color("8a5a2e"))
	_stick(Vector2(0, 6), Vector2(-20, -30), 8.0, Color("8a5a2e"))
	_stick(Vector2(0, 6), Vector2(20, -30), 8.0, Color("8a5a2e"))
	var pull := sin(_t * 3.0) * 4.0
	draw_polyline(PackedVector2Array([Vector2(-20, -30), Vector2(0, -12 + pull), Vector2(20, -30)]), Color("e5533d"), 4.0)
	_oval(Vector2(0, -14 + pull), Vector2(8, 7), Color("b07a45"))


func _tool_bubble() -> void:
	_rect(Vector2(-10, 10), Vector2(22, 10), Color("3f8fe0"))
	_rect(Vector2(-26, 22), Vector2(6, 14), Color("2b3354"))
	_rect(Vector2(16, 10), Vector2(8, 6), Color("8fd0ff"))
	for i in 3:
		var k := fmod(_t * 0.7 + i * 0.33, 1.0)
		var p := Vector2(28 + k * 14.0, -6 - k * 36.0)
		draw_arc(p, 6.0 + k * 6.0, 0.0, TAU, 20, Color(0.8, 0.95, 1.0, 1.0 - k), 2.5)


func _tool_boomerang() -> void:
	draw_set_transform(size * 0.5, sin(_t * 2.0) * 0.3, Vector2(size.x / 96.0, size.x / 96.0))
	for s in [-1.0, 1.0]:
		_poly(PackedVector2Array([Vector2(0, 8), Vector2(s * 36, -18), Vector2(s * 38, -8), Vector2(s * 8, 18)]), Color("f39a2b"))
	_shine(Vector2(-18, -6), Vector2(8, 3))


func _tool_fire_staff() -> void:
	_stick(Vector2(-14, 38), Vector2(8, -12), 7.0, Color("7a4a2a"))
	_oval(Vector2(10, -20), Vector2(12, 12), Color("e5533d"))
	var flicker := 1.0 + sin(_t * 12.0) * 0.12
	draw_circle(Vector2(10, -26), 16.0 * flicker, Color(1, 0.6, 0.15, 0.45))
	draw_circle(Vector2(10, -26), 8.0 * flicker, Color(1, 0.95, 0.6))


func _tool_star_blaster() -> void:
	_rect(Vector2(-6, 12), Vector2(26, 11), Color("9b5de5"))
	_rect(Vector2(-22, 26), Vector2(6, 12), Color("2b3354"))
	for i in 3:
		var a := -0.5 + i * 0.5
		var p := Vector2(30, 6) + Vector2(cos(a), sin(a)) * (14.0 + fmod(_t * 30.0, 14.0))
		var star := PackedVector2Array()
		for k in 10:
			var r := 7.0 if k % 2 == 0 else 3.0
			star.append(p + Vector2(cos(k * PI / 5.0), sin(k * PI / 5.0)) * r)
		draw_colored_polygon(star, Color(1, 0.9, 0.35))


func _tool_toolbox() -> void:
	draw_arc(Vector2(0, -16), 14.0, PI, TAU, 12, OUTLINE, 9.0)
	draw_arc(Vector2(0, -16), 14.0, PI, TAU, 12, Color("c08a20"), 5.0)
	_rect(Vector2(0, 8), Vector2(38, 24), Color("ffc928"))
	_rect(Vector2(0, -12), Vector2(38, 5), Color("e8a51c"))
	_rect(Vector2(0, 4), Vector2(7, 6), Color("c0c8d6"))
	_shine(Vector2(-22, 0), Vector2(10, 4))
	_sparkle(Vector2(30, -26), 9.0)
