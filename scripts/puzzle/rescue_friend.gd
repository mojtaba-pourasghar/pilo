class_name RescueFriend
extends Area2D
## A little forest friend stuck in a time bubble. Touching it frees it and opens the exit.

var game: Node
var rescued := false

var _t := 0.0
var _bubble := 1.0
var _hop := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	shape.position = Vector2(32, 26)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if rescued or not body.is_in_group("player"):
		return
	rescued = true
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "_bubble", 0.0, 0.2)
	tween.tween_property(self, "_hop", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_hop", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_hop", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_hop", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	game.on_friend_rescued(self)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var center := Vector2(32, 34 - _hop * 40.0 + sin(_t * 2.0) * 3.0 * _bubble)
	draw_squirrel(self, center, 1.0, _t)
	if _bubble > 0.01:
		draw_circle(center + Vector2(0, -8), 44.0, Color(0.7, 0.9, 1.0, 0.25 * _bubble))
		draw_arc(center + Vector2(0, -8), 44.0, 0.0, TAU, 48, Color(1, 1, 1, 0.7 * _bubble), 3.0)
		draw_circle(center + Vector2(-18, -30), 7.0, Color(1, 1, 1, 0.6 * _bubble))


## Shared drawing so the dialogue portrait matches the in-level friend.
static func draw_squirrel(canvas: CanvasItem, center: Vector2, s: float, t: float) -> void:
	var fur := Color("b5713a")
	var light := Color("f1d2a8")
	var tail := PackedVector2Array()
	for i in 13:
		var a := -0.6 + i * 0.32
		tail.append(center + Vector2(14 + cos(a) * 18 + sin(t * 3.0) * 2.0, -16 + sin(a) * 24) * s)
	canvas.draw_colored_polygon(tail, fur.darkened(0.1))
	canvas.draw_circle(center + Vector2(-2, 2) * s, 16.0 * s, fur)
	canvas.draw_circle(center + Vector2(-2, 6) * s, 9.0 * s, light)
	canvas.draw_circle(center + Vector2(-6, -18) * s, 13.0 * s, fur)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-16, -26) * s, center + Vector2(-12, -40) * s, center + Vector2(-8, -28) * s
	]), fur)
	canvas.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-4, -28) * s, center + Vector2(2, -40) * s, center + Vector2(4, -26) * s
	]), fur)
	canvas.draw_circle(center + Vector2(-11, -19) * s, 3.0 * s, Color("2a1a10"))
	canvas.draw_circle(center + Vector2(-2, -19) * s, 3.0 * s, Color("2a1a10"))
	canvas.draw_circle(center + Vector2(-6, -13) * s, 2.5 * s, Color("5a2a1a"))
