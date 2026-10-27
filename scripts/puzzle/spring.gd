class_name Spring
extends StaticBody2D
## Bouncy mushroom. The player controller bounces when it lands on the "spring" group.

var _squash := 0.0
var _tween: Tween


func _ready() -> void:
	add_to_group("spring")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 52)
	shape.shape = rect
	shape.position = Vector2(32, 38)
	add_child(shape)


func boing() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "_squash", 1.0, 0.06)
	_tween.tween_property(self, "_squash", 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if _tween and _tween.is_running():
		queue_redraw()


func _draw() -> void:
	var squash := _squash * 0.3
	draw_set_transform(Vector2(32, 64), 0.0, Vector2(1.0 + squash, 1.0 - squash))
	draw_rect(Rect2(-12, -34, 24, 34), Color("f6e7c8"))
	draw_rect(Rect2(-12, -6, 24, 6), Color("d9c49e"))
	var cap := PackedVector2Array()
	for i in 17:
		var angle := PI + PI * i / 16.0
		cap.append(Vector2(cos(angle) * 32.0, -30.0 + sin(angle) * 28.0))
	draw_colored_polygon(cap, Color("e5533d"))
	draw_rect(Rect2(-32, -34, 64, 6), Color("b8392a"))
	draw_circle(Vector2(-14, -44), 6.0, Color.WHITE)
	draw_circle(Vector2(8, -50), 5.0, Color.WHITE)
	draw_circle(Vector2(20, -38), 4.0, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
