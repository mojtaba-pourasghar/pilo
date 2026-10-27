class_name Door
extends StaticBody2D
## Walnut door: solid in both times, opens with one key.

var cells := 1
var game: Node
var is_open := false
var size := Vector2(64, 64)

var _open := 0.0
var _shape: CollisionShape2D
var _tween: Tween


func _ready() -> void:
	size = Vector2(64, 64 * cells)
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size * 0.5
	add_child(_shape)
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var sensor_shape := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = size + Vector2(36, 0)
	sensor_shape.shape = sensor_rect
	sensor_shape.position = size * 0.5
	sensor.add_child(sensor_shape)
	add_child(sensor)
	sensor.body_entered.connect(_on_sensor_body_entered)


func _on_sensor_body_entered(body: Node) -> void:
	if not is_open and body.is_in_group("player"):
		game.on_door_touched(self)


func open() -> void:
	is_open = true
	_shape.set_deferred("disabled", true)
	_tween = create_tween()
	_tween.tween_property(self, "_open", 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	if _tween and _tween.is_running():
		queue_redraw()


func _draw() -> void:
	var wood := Color("9a6234")
	var dark := Color("5e3a1c")
	var stone := Color("b8b2a6")
	draw_rect(Rect2(0, 0, 8, size.y), stone)
	draw_rect(Rect2(size.x - 8, 0, 8, size.y), stone)
	draw_set_transform(Vector2(8, 0), 0.0, Vector2(1.0 - _open * 0.8, 1.0))
	var w := size.x - 16
	draw_rect(Rect2(0, 20, w, size.y - 20), wood)
	draw_circle(Vector2(w * 0.5, 24), w * 0.5, wood)
	for i in 4:
		var x := 8.0 + i * (w - 16.0) / 3.0
		draw_line(Vector2(x, 12), Vector2(x, size.y - 4), dark, 3.0)
	draw_circle(Vector2(w * 0.5, size.y * 0.55), 8.0, Color("ffd23f"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.5 - 5, size.y * 0.55), Vector2(w * 0.5 + 5, size.y * 0.55), Vector2(w * 0.5, size.y * 0.55 + 16)
	]), Color("ffd23f"))
	draw_circle(Vector2(w * 0.5, size.y * 0.55), 3.0, dark)
	draw_set_transform(Vector2.ZERO)
