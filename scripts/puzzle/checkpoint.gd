class_name Checkpoint
extends Area2D
## Flag that moves the respawn point forward. Always placed on ground that exists in both times.

var game: Node
var active := false

var _raise := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 128)
	shape.shape = rect
	shape.position = Vector2(32, 0)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func respawn_position() -> Vector2:
	return global_position + Vector2(32, 64 - 42)


func _on_body_entered(body: Node) -> void:
	if active or not body.is_in_group("player"):
		return
	active = true
	create_tween().tween_property(self, "_raise", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	game.on_checkpoint(self)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# rendered flag: limp and grey until Nima reaches it, then up and waving in the wind
	if WorldArt.pic("checkpoint_on"):
		var sway := sin(_t * 4.0) * 0.04 * _raise
		draw_set_transform(Vector2(31, 64), sway, Vector2(1.0 + sin(_t * 6.0) * 0.03 * _raise, 1.0))
		WorldArt.draw(self, "checkpoint_on" if active else "checkpoint_off", Vector2.ZERO, 126.0)
		draw_set_transform(Vector2.ZERO)
		return
	draw_rect(Rect2(28, -44, 6, 108), Color("6b3f1d"))
	draw_circle(Vector2(31, -46), 6.0, Color("ffd23f"))
	var top := lerpf(30.0, -40.0, _raise)
	var wave := sin(_t * 5.0) * 4.0 * _raise
	var color := Color("f39a2b") if active else Color("b9c4d0")
	draw_colored_polygon(PackedVector2Array([
		Vector2(34, top), Vector2(74, top + 12 + wave), Vector2(34, top + 26)
	]), color)
	draw_circle(Vector2(48, top + 13 + wave * 0.5), 5.0, Color(1, 1, 1, 0.8))
