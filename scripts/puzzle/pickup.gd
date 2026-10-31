class_name Pickup
extends Area2D
## Star (optional reward) or key (opens a walnut door).

enum Kind { STAR, KEY }

var kind: int = Kind.STAR
var index := 0
var game: Node

var _sprite: Sprite2D
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_t = randf() * TAU
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	add_child(shape)
	# a soft golden glow behind the rendered star (or key)
	var glow := Sprite2D.new()
	glow.texture = FX.soft()
	glow.scale = Vector2(2.2, 2.2)
	glow.modulate = Color(1, 0.85, 0.35, 0.45)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	add_child(glow)
	_sprite = Sprite2D.new()
	var rendered := WorldArt.tex("item", "star" if kind == Kind.STAR else "key")
	if rendered:
		_sprite.texture = rendered
		var k := (64.0 if kind == Kind.STAR else 58.0) / rendered.get_height()
		_sprite.scale = Vector2(k, k)
		_sprite.set_meta("base", _sprite.scale)
	else:
		_sprite.texture = load("res://assets/ui/star.png" if kind == Kind.STAR else "res://assets/ui/key.png")
	add_child(_sprite)
	z_index = 3
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 3.0) * 6.0
	_sprite.rotation = sin(_t * 2.0) * (0.15 if kind == Kind.STAR else 0.3)


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	if kind == Kind.STAR:
		game.on_star_collected(index, global_position)
	else:
		game.on_key_collected(global_position)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", _sprite.scale * 1.8, 0.18)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
