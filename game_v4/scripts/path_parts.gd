class_name PathParts
extends RefCounted
## The organic path pieces of v4 (docs/45 section 5), the pattern of the reference game, our own design:
## no floating blocks or planks; the way goes over hills, up tree trunks and along branches, swings on vines,
## bounces off mushrooms, slides down steep banks, hops over sinking lily leaves and rides wind streams.
## Placeholders drawn by code until the painted kit (CLAUDE.md rule 10).

const OUTLINE := Color("3b2416")


static func smooth(pts: Array, step := 22.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		var steps := int(maxf(3.0, p1.distance_to(p2) / step))
		for s in steps:
			var t := float(s) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


static func vecs(arr: Array) -> Array:
	var out: Array = []
	for q in arr:
		out.append(Vector2(q[0], q[1]))
	return out


## A big tree trunk: solid, its bark can be run up (wall-run), its crown hangs above.
class Trunk extends StaticBody2D:
	var w := 120.0
	var top := 300.0
	var bottom := 900.0

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(w, bottom - top)
		shape.shape = r
		shape.position = Vector2(0, (top + bottom) * 0.5)
		add_child(shape)

	func _draw() -> void:
		var bark := Kit.env(8)
		if bark:
			# the painted trunk repeated up, a crown of big bushes on top, roots at the foot
			# one long trunk: the bark picture stretched up, mirrored halves so no seam shows
			var full := bottom + 30.0 - (top - 60.0)
			var half := full * 0.5
			draw_texture_rect(bark, Rect2(-w * 0.62, top - 60.0 + half, w * 1.25, half), false)
			draw_set_transform(Vector2(0, top - 60.0 + half), 0.0, Vector2(1, -1))
			draw_texture_rect(bark, Rect2(-w * 0.62, 0, w * 1.25, half), false)
			draw_set_transform(Vector2.ZERO)
			var bush := Kit.env(18)
			for k in 7:
				var a := -PI * 0.5 + (k - 3) * 0.42
				Kit.draw_at(self, bush, Vector2(0, top + 60) + Vector2.from_angle(a) * 150.0 + Vector2(0, 90), 240.0, 0.0, k % 2 == 0,
					Color(0.82, 0.92, 0.82))
			Kit.draw_at(self, bush, Vector2(0, top + 40), 300.0)
			return
		var pts := PackedVector2Array([Vector2(-w * 0.5 - 40, bottom + 10), Vector2(-w * 0.5, bottom - 80), Vector2(-w * 0.45, top),
			Vector2(w * 0.45, top), Vector2(w * 0.5, bottom - 80), Vector2(w * 0.5 + 46, bottom + 10)])
		draw_colored_polygon(pts, OUTLINE)
		var inner := PackedVector2Array()
		var c := Vector2(0, (top + bottom) * 0.5)
		for q in pts:
			inner.append(c + (q - c) * Vector2(0.92, 0.99))
		draw_colored_polygon(inner, Color("7a4e2c"))
		for k in 7:
			var x := -w * 0.35 + k * w * 0.11
			draw_line(Vector2(x, top + 20), Vector2(x + sin(k) * 10.0, bottom - 20), Color("5e3a1f"), 4.0)
		draw_rect(Rect2(-w * 0.42, top, 14, bottom - top), Color(1, 0.9, 0.7, 0.12))
		# the crown
		for k in 6:
			var a := -PI * 0.5 + (k - 2.5) * 0.45
			draw_circle(Vector2(0, top - 40) + Vector2.from_angle(a) * 150.0, 110.0, Color("3f7f3a").lerp(Color("5aa845"), k / 6.0))
		draw_circle(Vector2(0, top - 90), 140.0, Color("4f9a45"))


## A branch growing out of a trunk: a curved one-way walkway (jump up through it, tap below to drop).
class Branch extends StaticBody2D:
	var points: Array = []          ## Vector2 path in level space
	var _line: PackedVector2Array

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 0
		_line = PathParts.smooth(points)
		for i in _line.size() - 1:
			var seg := CollisionShape2D.new()
			var s := SegmentShape2D.new()
			s.a = _line[i]
			s.b = _line[i + 1]
			seg.shape = s
			seg.one_way_collision = true
			seg.one_way_collision_margin = 12.0
			add_child(seg)

	func _draw() -> void:
		var piece := Kit.env(10 if absf(points[0].y - points[points.size() - 1].y) > 20.0 else 9)
		if piece:
			var a: Vector2 = points[0]
			var b: Vector2 = points[points.size() - 1]
			var flip := b.x < a.x
			if flip:
				Kit.draw_along(self, piece, b + Vector2(0, 14), a + Vector2(0, 14), 74.0)
			else:
				Kit.draw_along(self, piece, a + Vector2(0, 14), b + Vector2(0, 14), 74.0)
			return
		var n := _line.size()
		for i in n - 1:
			var k := float(i) / n
			var wdt := lerpf(34.0, 16.0, k)
			draw_line(_line[i] + Vector2(0, 12), _line[i + 1] + Vector2(0, 12), OUTLINE, wdt + 6.0)
			draw_line(_line[i] + Vector2(0, 12), _line[i + 1] + Vector2(0, 12), Color("8a5a34"), wdt)
			draw_line(_line[i] + Vector2(0, 6), _line[i + 1] + Vector2(0, 6), Color("a8744a"), wdt * 0.3)
		for i in range(2, n, 5):
			draw_circle(_line[i] + Vector2(0, -8), 16.0, Color("4f9a45"))
			draw_circle(_line[i] + Vector2(10, -16), 11.0, Color("6cbf55"))


## A vine hanging from a branch: jump into it to grab; it swings like a pendulum; the hero's push pumps it; a flick
## lets go with its speed.
class Vine extends Node2D:
	var length := 300.0
	var angle := 0.4
	var _vel := 0.0
	var _hero: HeroBody
	var _held := false

	func _ready() -> void:
		_vel = 0.6

	func _physics_process(delta: float) -> void:
		var g := 2600.0
		_vel += (-g / length * sin(angle) - 0.25 * _vel) * delta
		angle += _vel * delta
		if not _held and absf(_vel) < 0.3 and absf(angle) < 0.05:
			_vel = 0.6
		if _hero == null:
			_hero = get_tree().get_first_node_in_group("hero") as HeroBody
		if not _held and _hero and _hero.can_grab() and _hero.global_position.distance_to(grip_point()) < 70.0:
			_held = true
			_hero.vine = self
			_vel += clampf(_hero.velocity.x / length, -2.5, 2.5)
		queue_redraw()

	func tip() -> Vector2:
		return global_position + Vector2(sin(angle), cos(angle)) * length

	func grip_point() -> Vector2:
		return tip() + Vector2(0, 120)          # hands at the tip, feet below

	func release_velocity() -> Vector2:
		return Vector2(cos(angle), -sin(angle)) * (_vel * length)

	func pump(run: float, delta: float) -> void:
		if run != 0.0 and signf(run) == signf(_vel):
			_vel += run * 1.8 * delta

	func let_go() -> void:
		_held = false

	func _draw() -> void:
		var tp := Vector2(sin(angle), cos(angle)) * length
		var vt := Kit.env(11)
		if vt:
			var sc := length / float(vt.get_height())
			draw_set_transform(Vector2.ZERO, -angle, Vector2(sc * 1.4, sc))
			draw_texture(vt, Vector2(-vt.get_width() * 0.5, 0))
			draw_set_transform(Vector2.ZERO)
			return
		var mid := tp * 0.5 + Vector2(cos(angle), -sin(angle)) * (_vel * 6.0)
		var pts := PathParts.smooth([Vector2.ZERO, mid, tp], 14.0)
		draw_polyline(pts, OUTLINE, 11.0)
		draw_polyline(pts, Color("4f9a3e"), 7.0)
		for i in range(2, pts.size(), 3):
			var side := 1.0 if i % 2 == 0 else -1.0
			draw_circle(pts[i] + Vector2(side * 8.0, 0), 6.0, Color("6cbf55"))
		draw_circle(tp, 14.0, OUTLINE)
		draw_circle(tp, 11.0, Color("f28fb0"))
		draw_circle(tp, 4.0, Color("f6e27a"))


## A bounce mushroom: landing on its cap throws the hero high (with a squash of the cap).
class Mushroom extends Area2D:
	var power := 1650.0
	var _squash := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(130, 30)
		s.shape = r
		s.position = Vector2(0, -70)
		add_child(s)
		body_entered.connect(func(b):
			if b is HeroBody and b.velocity.y > -100.0:
				b.bounce(power)
				_squash = 1.0)

	func _process(delta: float) -> void:
		_squash = maxf(0.0, _squash - delta * 4.0)
		queue_redraw()

	func _draw() -> void:
		var sq := sin(_squash * PI) * 0.35
		var mt := Kit.env(14)
		if mt:
			var s := 150.0 / mt.get_height()
			draw_set_transform(Vector2(0, 8), 0.0, Vector2(s * (1.0 + sq), s * (1.0 - sq)))
			draw_texture(mt, Vector2(-mt.get_width() * 0.5, -mt.get_height()))
			draw_set_transform(Vector2.ZERO)
			return
		draw_rect(Rect2(-18, -62, 36, 62), OUTLINE)
		draw_rect(Rect2(-14, -60, 28, 60), Color("f6efe0"))
		draw_set_transform(Vector2(0, -66), 0.0, Vector2(1.0 + sq, 1.0 - sq))
		draw_colored_polygon(PathParts._cap(78.0, 44.0), OUTLINE)
		draw_colored_polygon(PathParts._cap(72.0, 39.0), Color("d0453a"))
		for d in [Vector2(-34, -14), Vector2(0, -28), Vector2(32, -12), Vector2(-12, -6)]:
			draw_circle(d, 8.0, Color("fff3d6"))
		draw_set_transform(Vector2.ZERO)


static func _cap(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	pts.append(Vector2(rx * 0.9, 8))
	pts.append(Vector2(-rx * 0.9, 8))
	return pts


## Water of a pond: falling in sends the hero back to the last checkpoint (no heart in the sample).
class Pond extends Area2D:
	var w := 700.0
	var level: Node
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(w, 300)
		s.shape = r
		s.position = Vector2(w * 0.5, 190)
		add_child(s)
		body_entered.connect(func(b):
			if b is HeroBody:
				level.call("respawn"))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# painterly water: deep teal fading down, a light band under the surface, ripples and drifting glints
		for i in 10:
			var c := Color("6fc2b5").lerp(Color("1f4f52"), i / 9.0)
			c.a = 0.88
			draw_rect(Rect2(0, i * 40.0, w, 41.0), c)
		draw_rect(Rect2(0, 0, w, 10), Color(0.85, 1.0, 0.95, 0.35))
		var pts := PackedVector2Array()
		for i in int(w / 16.0) + 1:
			pts.append(Vector2(i * 16.0, sin(_t * 2.0 + i * 0.5) * 4.0))
		draw_polyline(pts, Color(0.85, 0.95, 1.0, 0.9), 5.0)
		for i in 5:
			var x := fmod(_t * 30.0 + i * 160.0, w)
			draw_line(Vector2(x, 30 + i * 12), Vector2(x + 40, 30 + i * 12), Color(1, 1, 1, 0.25), 3.0)


## A lily leaf floating on the pond: it sinks while stood on, rises back afterwards.
class Leaf extends AnimatableBody2D:
	var _home := 0.0
	var _sink := 0.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 0
		sync_to_physics = false
		_home = position.y
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(150, 14)
		s.shape = r
		s.one_way_collision = true
		add_child(s)

	func _physics_process(delta: float) -> void:
		_t += delta
		var hero := get_tree().get_first_node_in_group("hero") as HeroBody
		var on := hero != null and hero.is_on_floor() and absf(hero.global_position.x - global_position.x) < 85.0 \
			and absf(hero.global_position.y - global_position.y) < 30.0
		_sink = move_toward(_sink, 60.0 if on else 0.0, (55.0 if on else 30.0) * delta)
		position.y = _home + _sink + sin(_t * 2.0 + _home) * 3.0
		queue_redraw()

	func _draw() -> void:
		var lt := Kit.env(15)
		if lt:
			Kit.draw_at(self, lt, Vector2(0, 22), 70.0, 0.0, false, Color(1, 1, 1) if _sink < 40.0 else Color(0.8, 0.85, 0.8))
			return
		draw_colored_polygon(PathParts._leaf(84.0, 18.0), OUTLINE)
		draw_colored_polygon(PathParts._leaf(80.0, 15.0), Color("4f9a3e") if _sink < 40.0 else Color("3d7a32"))
		draw_line(Vector2(-60, 0), Vector2(60, 0), Color("6cbf55"), 3.0)
		draw_circle(Vector2(30, -8), 9.0, Color("f28fb0"))


static func _leaf(rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		if i == 6:
			pts.append(Vector2(0, -ry * 0.2))
			continue
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## A wind stream of petals rising from a crack: inside it the hero is lifted (strongly while gliding).
class Wind extends Area2D:
	var size := Vector2(190, 700)
	var lift := 4200.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = size
		s.shape = r
		s.position = Vector2(0, -size.y * 0.5)
		add_child(s)

	func _physics_process(delta: float) -> void:
		_t += delta
		for b in get_overlapping_bodies():
			if b is HeroBody:
				b.wind_lift = lift
		queue_redraw()

	func _draw() -> void:
		Kit.draw_at(self, Kit.env(16), Vector2(0, 12), 110.0)
		for i in 26:
			var k := fmod(_t * 0.7 + i * 0.137, 1.0)
			var x := sin(i * 2.3 + _t * 2.0) * size.x * 0.4
			var p := Vector2(x, -k * size.y)
			draw_circle(p, 6.0 * (1.0 - k * 0.5), Color(1, 0.85, 0.9, 0.75 * (1.0 - k)))
		for i in 4:
			var x2 := -size.x * 0.3 + i * size.x * 0.2
			draw_line(Vector2(x2, 0), Vector2(x2 + sin(_t * 3.0 + i) * 10.0, -size.y * 0.8), Color(1, 1, 1, 0.08), 8.0)


## Foreground leaves in front of the camera; they fade when the hero is behind them (a hidden corner).
class Bush extends Node2D:
	var radius := 220.0

	func _process(_delta: float) -> void:
		var hero := get_tree().get_first_node_in_group("hero") as Node2D
		var near := hero != null and hero.global_position.distance_to(global_position) < radius
		modulate.a = lerpf(modulate.a, 0.25 if near else 1.0, 0.12)

	func _draw() -> void:
		var bt := Kit.env(18)
		if bt:
			for k in 3:
				Kit.draw_at(self, bt, Vector2((k - 1) * radius * 0.6, radius * 0.6), radius * 1.3, 0.0, k == 1, Color(0.45, 0.6, 0.5))
			return
		for k in 9:
			var a := -PI + k * PI / 8.0
			var c := Vector2.from_angle(a) * radius * 0.55 + Vector2(0, 40)
			draw_circle(c, radius * 0.5, Color("2f6a2c").lerp(Color("3f8a38"), k / 9.0))
		draw_circle(Vector2(0, 20), radius * 0.6, Color("356f30"))
		for k in 6:
			draw_circle(Vector2(-radius * 0.5 + k * radius * 0.2, -radius * 0.2 + (k % 2) * 30.0), 14.0, Color("f28fb0"))
