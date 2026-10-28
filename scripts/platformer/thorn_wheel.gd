class_name ThornWheel
extends Node2D
## «چرخ خار»: a chain of shadow thistle balls turning around a stone hub (the forest's
## version of Mario's fire bar). Every ball hurts; the hub is solid.

const TILE := 64.0
const OUTLINE := Color("3b2418")

var length := 4
var speed := 1.6
var _angle := 0.0
var _t := 0.0


func _ready() -> void:
	z_index = 3
	var hub := StaticBody2D.new()
	hub.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	hub.add_child(shape)
	add_child(hub)
	_angle = randf() * TAU


func _physics_process(delta: float) -> void:
	_angle += speed * delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var rect: Rect2 = player.get_body_rect().grow(-4.0)
	for i in range(1, length + 1):
		var ball := global_position + Vector2(cos(_angle), sin(_angle)) * (i * 30.0 + 6.0)
		var closest := Vector2(clampf(ball.x, rect.position.x, rect.end.x), clampf(ball.y, rect.position.y, rect.end.y))
		if closest.distance_to(ball) < 13.0:
			player.take_hit(ball.x)
			return


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# hub
	draw_rect(Rect2(-30, -30, 60, 60), OUTLINE)
	draw_rect(Rect2(-27, -27, 54, 54), Color("8d929c"))
	draw_rect(Rect2(-27, -27, 54, 10), Color("b3b8c2"))
	draw_circle(Vector2.ZERO, 12.0, OUTLINE)
	draw_circle(Vector2.ZERO, 9.0, Color("5b3f8a"))
	for i in range(1, length + 1):
		var pos := Vector2(cos(_angle), sin(_angle)) * (i * 30.0 + 6.0)
		draw_circle(pos, 19.0, Color(0.55, 0.25, 0.8, 0.12))
		for k in 8:
			var a := k * TAU / 8.0 + _t * 3.0
			var dir := Vector2(cos(a), sin(a))
			draw_colored_polygon(PackedVector2Array([pos + dir.orthogonal() * 5.0, pos + dir * 17.0, pos - dir.orthogonal() * 5.0]), OUTLINE)
			draw_colored_polygon(PackedVector2Array([pos + dir.orthogonal() * 3.0, pos + dir * 14.0, pos - dir.orthogonal() * 3.0]), Color("7a4fa8"))
		draw_circle(pos, 11.0, OUTLINE)
		draw_circle(pos, 8.5, Color("4a2d6e"))
		draw_circle(pos + Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.35))
