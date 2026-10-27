class_name ExitPortal
extends Area2D
## The lost time shard. Touching it finishes the level (once any trapped friend is free).

var game: Node
var locked := false

var _t := 0.0
var _crystal: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 128)
	shape.shape = rect
	shape.position = Vector2(32, 0)
	add_child(shape)
	_crystal = Sprite2D.new()
	_crystal.texture = load("res://assets/ui/crystal.png")
	_crystal.scale = Vector2(1.3, 1.3)
	_crystal.position = Vector2(32, -4)
	add_child(_crystal)
	body_entered.connect(_on_body_entered)
	set_locked(locked)


func set_locked(value: bool) -> void:
	locked = value
	if _crystal:
		_crystal.modulate = Color(0.55, 0.55, 0.6, 0.8) if locked else Color.WHITE


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game.on_exit_reached()


func _process(delta: float) -> void:
	_t += delta
	_crystal.position.y = -4.0 + sin(_t * 2.5) * 8.0
	_crystal.rotation = sin(_t * 1.5) * 0.12
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(6, 44, 52, 20), Color("b8b2a6"))
	draw_rect(Rect2(0, 40, 64, 8), Color("d8d2c6"))
	var center := Vector2(32, -4)
	if locked:
		draw_arc(center, 46.0, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 4.0)
		return
	draw_circle(center, 50.0, Color(0.6, 0.5, 1.0, 0.12))
	for i in 3:
		var start := _t * (1.5 + i * 0.4) + i * 2.1
		draw_arc(center, 40.0 + i * 8.0, start, start + 2.2, 24, Color(0.75, 0.6, 1.0, 0.7 - i * 0.18), 5.0)
