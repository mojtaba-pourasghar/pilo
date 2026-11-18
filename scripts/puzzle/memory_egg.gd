class_name MemoryEgg
extends Area2D
## The egg in a chapter's memory room (p2 companion egg art). Touching it plays the memory.

const ART := {"bargak": "res://assets/art/p2_companions/p2_companion_bargak_form0_egg_concept.png"}

var game: Node
var egg := "bargak"
var _tex: Texture2D
var _t := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 110)
	shape.shape = rect
	shape.position = Vector2(0, -55)
	add_child(shape)
	_tex = load(ART.get(egg, "")) if ResourceLoader.exists(ART.get(egg, "")) else null
	body_entered.connect(func(b):
		if b.is_in_group("player") and not _done:
			_done = true
			game.play_memory(egg))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, -50), 60.0 + sin(_t * 2.0) * 6.0, Color(0.7, 1.0, 0.6, 0.25))
	if _tex:
		var s := 110.0 / maxf(_tex.get_width(), _tex.get_height())
		var size := _tex.get_size() * s
		draw_texture_rect(_tex, Rect2(Vector2(-size.x * 0.5, -size.y + sin(_t * 3.0) * 3.0), size), false, Color(1, 1, 1, 0.5 if _done else 1.0))
