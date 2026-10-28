class_name FX
extends RefCounted
## Small reusable effects: sparkle bursts, floating words and the time-lens ring.

const DOT := preload("res://assets/vfx/dot.png")


static func burst(parent: Node, pos: Vector2, color: Color, amount := 16) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = DOT
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 260.0
	particles.gravity = Vector2(0, 420)
	particles.scale_amount_min = 0.25
	particles.scale_amount_max = 0.6
	particles.color = color
	particles.position = pos
	particles.z_index = 8
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Little puff of dust at the feet (skids, landings, dashes).
static func dust(parent: Node, pos: Vector2, amount := 5) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = DOT
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.45
	particles.direction = Vector2.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 110.0
	particles.gravity = Vector2(0, 120)
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.7
	particles.color = Color(0.95, 0.9, 0.8, 0.8)
	particles.position = pos
	particles.z_index = 5
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Shards flying out of a broken block or wall.
static func debris(parent: Node, pos: Vector2, color: Color, amount := 8) -> void:
	for i in amount:
		var piece := Debris.new()
		piece.color = color.darkened(randf() * 0.3)
		piece.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		piece.velocity = Vector2(randf_range(-260, 260), randf_range(-620, -260))
		piece.spin = randf_range(-12, 12)
		parent.add_child(piece)


static func float_text(parent: Node, pos: Vector2, text: String, color: Color) -> void:
	var label := UIKit.make_label(text, 30, color, 10, Color.WHITE)
	label.size = Vector2(460, 50)
	label.position = pos - Vector2(230, 25)
	label.z_index = 20
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50.0, 1.3)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.6)
	tween.tween_callback(label.queue_free)


static func ring(parent: Node, pos: Vector2, color: Color) -> void:
	var effect := Ring.new()
	effect.color = color
	effect.position = pos
	parent.add_child(effect)


class Ring extends Node2D:
	var color := Color.WHITE
	var radius := 10.0

	func _ready() -> void:
		z_index = 7
		var tween := create_tween()
		tween.tween_property(self, "radius", 900.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
		tween.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, color, 14.0)
		draw_arc(Vector2.ZERO, radius * 0.86, 0.0, TAU, 72, Color(color, 0.4), 6.0)


class Debris extends Node2D:
	var color := Color.WHITE
	var velocity := Vector2.ZERO
	var spin := 0.0
	var life := 1.2

	func _ready() -> void:
		z_index = 8

	func _process(delta: float) -> void:
		velocity.y += 1600.0 * delta
		position += velocity * delta
		rotation += spin * delta
		life -= delta
		modulate.a = clampf(life * 2.0, 0.0, 1.0)
		if life <= 0.0:
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(-9, -7, 18, 14), Color("3b2418"))
		draw_rect(Rect2(-7, -5, 14, 10), color)
