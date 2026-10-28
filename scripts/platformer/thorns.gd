class_name Thorns
extends Area2D
## A run of shadow brambles on the ground. Touching them costs a heart.

const TILE := 64.0
const OUTLINE := Color("3b2418")

var cells := 1
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(cells * TILE - 12.0, 30.0)
	shape.shape = rect
	shape.position = Vector2(cells * TILE * 0.5, TILE - 15.0)
	add_child(shape)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_hit(body.global_position.x + body.facing * 20.0)
			if body.velocity.y > -300.0:
				body.velocity.y = -620.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var vine := Color("4b2d5e")
	var thorn := Color("2a1838")
	for i in cells:
		var x0 := i * TILE
		# tangled stems
		var a := PackedVector2Array()
		var b := PackedVector2Array()
		for s in 9:
			var x := x0 + s * 8.0
			a.append(Vector2(x, TILE - 12.0 - sin(s * 1.3 + i) * 7.0))
			b.append(Vector2(x, TILE - 18.0 - cos(s * 1.1 + i * 2.0) * 9.0))
		draw_polyline(a, OUTLINE, 9.0)
		draw_polyline(b, OUTLINE, 8.0)
		draw_polyline(a, vine, 5.0)
		draw_polyline(b, vine.lightened(0.15), 4.0)
		# spikes
		for s in 5:
			var base := Vector2(x0 + 6.0 + s * 13.0, TILE - 16.0 - sin(s * 2.0 + i) * 6.0)
			var dir := Vector2(sin(s * 1.7 + i) * 0.5, -1.0).normalized()
			var side := dir.orthogonal() * 5.0
			var tip := base + dir * (16.0 + sin(_t * 2.0 + s) * 1.5)
			draw_colored_polygon(PackedVector2Array([base + side * 1.4, tip + dir * 2.0, base - side * 1.4]), OUTLINE)
			draw_colored_polygon(PackedVector2Array([base + side, tip, base - side]), thorn.lightened(0.25))
		# purple glow of the shadow spell
		draw_circle(Vector2(x0 + 32, TILE - 14), 26.0, Color(0.5, 0.2, 0.7, 0.08 + sin(_t * 3.0 + i) * 0.03))
