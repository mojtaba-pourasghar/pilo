class_name Collectible
extends Area2D
## Things to pick up, all drawn in code: coins (spin), diamonds (rare, mostly in hidden
## places), hearts and the time key that unlocks the exit gate. Spilled coins (dropped
## when Nima is hurt) bounce around and can be caught again before they fade.

enum Kind { COIN, DIAMOND, HEART, TIME_KEY }

const OUTLINE := Color("3b2418")
const GOLD := Color("ffc928")
const GOLD_DARK := Color("e08a10")
const GOLD_LIGHT := Color("fff1a8")

var kind: int = Kind.COIN
var index := -1             ## diamonds: which diamond of the level (remembered when found)
var game: Node
var spill := false
var velocity := Vector2.ZERO
var taken := false

var _t := 0.0
var _life := 6.0
var _rise := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 3
	add_to_group("collectible")
	_t = randf() * TAU
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0 if kind == Kind.COIN else 26.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	if spill:
		monitoring = false
		get_tree().create_timer(0.45).timeout.connect(func(): monitoring = true)


## A collectible that pops out of a block and floats up into place.
func pop_up(distance := 64.0) -> void:
	monitoring = false
	var target := position.y - distance
	var tween := create_tween()
	tween.tween_property(self, "position:y", target, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func(): monitoring = true)


func _process(delta: float) -> void:
	_t += delta
	if spill:
		_life -= delta
		velocity.y += 1500.0 * delta
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(global_position, global_position + velocity * delta + Vector2(0, 16 * signf(velocity.y)), 1)
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			if absf(hit.normal.y) > 0.5:
				velocity.y = -absf(velocity.y) * 0.55 if hit.normal.y < 0.0 else absf(velocity.y) * 0.3
				velocity.x *= 0.8
			else:
				velocity.x = -velocity.x * 0.6
		else:
			position += velocity * delta
		modulate.a = 1.0 if _life > 1.5 else float(int(_life * 10.0) % 2)
		if _life <= 0.0:
			queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()


func collect() -> void:
	if taken:
		return
	taken = true
	set_deferred("monitoring", false)
	if game and game.has_method("on_collect"):
		game.on_collect(self)
	var tween := create_tween()
	tween.tween_property(self, "_rise", 1.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


## Pilo fetches it: it flies to Nima and is collected there.
func fetch_to(target: Node2D) -> void:
	if taken:
		return
	spill = false
	monitoring = false
	var tween := create_tween()
	tween.tween_method(func(k: float): global_position = global_position.lerp(target.global_position + Vector2(0, -20), k), 0.0, 1.0, 0.45)
	tween.tween_callback(collect)


func _draw() -> void:
	var offset := Vector2(0, sin(_t * 3.0) * 4.0 - _rise * 30.0) if not spill else Vector2.ZERO
	match kind:
		Kind.COIN:
			draw_coin(self, offset, 1.0, _t)
		Kind.DIAMOND:
			draw_diamond(self, offset, 1.0, _t)
		Kind.HEART:
			draw_heart(self, offset, 1.0 + sin(_t * 6.0) * 0.06)
		Kind.TIME_KEY:
			_draw_key(offset)


static func draw_coin(canvas: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var w := (3.0 + 13.0 * absf(cos(t * 3.2))) * s
	var h := 17.0 * s
	var edge := cos(t * 3.2) < 0.0
	canvas.draw_colored_polygon(_oval(c, Vector2(w + 2.5, h + 2.5)), OUTLINE)
	canvas.draw_colored_polygon(_oval(c, Vector2(w, h)), GOLD_DARK if edge else GOLD)
	if w > 6.0 * s:
		canvas.draw_colored_polygon(_oval(c, Vector2(w * 0.68, h * 0.7)), GOLD_DARK)
		canvas.draw_colored_polygon(_oval(c + Vector2(-w * 0.05, -h * 0.05), Vector2(w * 0.55, h * 0.58)), GOLD)
		canvas.draw_line(c + Vector2(0, -h * 0.35), c + Vector2(0, h * 0.35), GOLD_DARK, 3.0 * s * (w / (16.0 * s)))
	canvas.draw_line(c + Vector2(-w * 0.5, -h * 0.55), c + Vector2(-w * 0.2, -h * 0.75), GOLD_LIGHT, 2.5 * s)


static func draw_diamond(canvas: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var top := [c + Vector2(-17, -6) * s, c + Vector2(-9, -16) * s, c + Vector2(9, -16) * s, c + Vector2(17, -6) * s]
	var bottom := c + Vector2(0, 19) * s
	var outline := PackedVector2Array(top + [bottom])
	var thick := outline.duplicate()
	thick.append(outline[0])
	canvas.draw_polyline(thick, OUTLINE, 5.0 * s, true)
	canvas.draw_colored_polygon(outline, Color("39b6ff"))
	canvas.draw_colored_polygon(PackedVector2Array([top[0], top[1], top[2], top[3]]), Color("8fe0ff"))
	canvas.draw_colored_polygon(PackedVector2Array([top[0], c + Vector2(-5, -6) * s, bottom]), Color("1f8fe0"))
	canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(5, -6) * s, top[3], bottom]), Color("62ccff"))
	canvas.draw_line(top[0], top[3], Color("d8f6ff"), 2.0 * s)
	var twinkle := maxf(0.0, sin(t * 2.5)) * s
	if twinkle > 0.1:
		var star := c + Vector2(9, -12) * s
		canvas.draw_line(star - Vector2(9, 0) * twinkle, star + Vector2(9, 0) * twinkle, Color.WHITE, 2.0)
		canvas.draw_line(star - Vector2(0, 9) * twinkle, star + Vector2(0, 9) * twinkle, Color.WHITE, 2.0)


static func draw_heart(canvas: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * 1.15 * s)
	var big := PackedVector2Array()
	for point in pts:
		big.append(c + (point - c) * 1.14)
	canvas.draw_colored_polygon(big, OUTLINE)
	canvas.draw_colored_polygon(pts, Color("ff4d6d"))
	canvas.draw_circle(c + Vector2(-8, -7) * s, 4.0 * s, Color(1, 1, 1, 0.6))


func _draw_key(c: Vector2) -> void:
	# the time key: a golden key whose bow is a little clock
	draw_circle(c + Vector2(0, 0), 26.0, Color(1, 0.85, 0.3, 0.18 + sin(_t * 4.0) * 0.08))
	draw_rect(Rect2(c + Vector2(-4, 6), Vector2(8, 26)), OUTLINE)
	draw_rect(Rect2(c + Vector2(-2, 6), Vector2(4, 24)), GOLD)
	for y in [20.0, 27.0]:
		draw_rect(Rect2(c + Vector2(2, y - 2), Vector2(9, 6)), OUTLINE)
		draw_rect(Rect2(c + Vector2(2, y), Vector2(7, 3)), GOLD_DARK)
	draw_circle(c + Vector2(0, -8), 16.0, OUTLINE)
	draw_circle(c + Vector2(0, -8), 13.0, GOLD)
	draw_circle(c + Vector2(0, -8), 9.5, Color("fff8e1"))
	var hand := _t * 2.0
	draw_line(c + Vector2(0, -8), c + Vector2(0, -8) + Vector2(sin(hand), -cos(hand)) * 7.0, OUTLINE, 2.0)
	draw_line(c + Vector2(0, -8), c + Vector2(0, -8) + Vector2(sin(hand / 12.0), -cos(hand / 12.0)) * 5.0, OUTLINE, 2.5)


static func _oval(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
