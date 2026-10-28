class_name InfoSign
extends Area2D
## Wooden sign that shows a short tip when the hero stands near it.

var text := ""
var voice_id := ""

var _bubble: PanelContainer


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(220, 128)
	shape.shape = rect
	shape.position = Vector2(32, 0)
	add_child(shape)
	_bubble = PanelContainer.new()
	var style := UIKit.flat(Color(1, 0.98, 0.92, 0.96), 22, 14)
	style.border_color = Color("c8945a")
	style.set_border_width_all(4)
	_bubble.add_theme_stylebox_override("panel", style)
	var label := UIKit.make_label(text, 24)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(340, 0)
	_bubble.add_child(label)
	_bubble.z_index = 30
	_bubble.modulate.a = 0.0
	_bubble.visible = false
	add_child(_bubble)
	_bubble.resized.connect(func(): _bubble.position = Vector2(32 - _bubble.size.x * 0.5, -50 - _bubble.size.y))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and text != "":
		if not _bubble.visible and voice_id != "":
			AudioManager.play_voice(voice_id)
		_bubble.visible = true
		create_tween().tween_property(_bubble, "modulate:a", 1.0, 0.2)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var tween := create_tween()
		tween.tween_property(_bubble, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func(): _bubble.visible = false)


func _draw() -> void:
	draw_rect(Rect2(28, 20, 8, 44), Color("6b3f1d"))
	draw_rect(Rect2(6, -4, 52, 32), Color("c8945a"))
	draw_rect(Rect2(6, 22, 52, 6), Color("8a5a2c"))
	draw_circle(Vector2(32, 11), 9.0, Color("fff6e3"))
	draw_rect(Rect2(30, 4, 4, 9), Color("6b3f1d"))
	draw_circle(Vector2(32, 16), 2.0, Color("6b3f1d"))
