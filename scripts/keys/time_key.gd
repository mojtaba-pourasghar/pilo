class_name TimeKey
extends Area2D
## One of the two keys of a level (T5): the past key (blue) lives in the past layer, the present
## key (orange) in the present layer. It can only be picked up in its own time; in the other time
## it is a ghost like the rest of its layer. Both keys open the two locks of the time gate.

const TEX := {
	TimeShift.PAST: "res://assets/art/p8_fx/p8_fx_key_blue_glow.png",
	TimeShift.PRESENT: "res://assets/art/p8_fx/p8_fx_key_present_glow.png",
}
const SIZE := 84.0

var key_time: int = TimeShift.PRESENT
var game: Node
var taken := false
## A keeper holding this key: the key is only free once the keeper lets go (T6).
var held_by: Node = null

var _t := 0.0
var _texture: Texture2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 2
	add_to_group("time_key")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	add_child(shape)
	_texture = load(TEX[key_time]) if ResourceLoader.exists(TEX[key_time]) else null
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU


## Only in its own time (the ghost of a key cannot be grabbed) and not while a keeper holds it.
func can_take() -> bool:
	return not taken and TimeShift.state == key_time and (held_by == null or not is_instance_valid(held_by))


func time_mask() -> int:
	return 1 if key_time == TimeShift.PAST else 2


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		try_take()


func _physics_process(_delta: float) -> void:
	# standing on it while switching time, or a keeper letting go while the hero waits there
	if not taken and can_take() and has_overlapping_bodies():
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				try_take()
				return


func try_take() -> bool:
	if not can_take():
		return false
	taken = true
	set_deferred("monitoring", false)
	if game and game.has_method("on_time_key"):
		game.on_time_key(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
	return true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 2.4) * 6.0
	var glow := Color(0.45, 0.75, 1.0, 0.35) if key_time == TimeShift.PAST else Color(1.0, 0.65, 0.25, 0.35)
	draw_circle(Vector2(0, bob), 34.0 + sin(_t * 3.0) * 3.0, glow)
	if _texture:
		var s := SIZE / maxf(_texture.get_width(), _texture.get_height())
		var size := _texture.get_size() * s
		draw_texture_rect(_texture, Rect2(Vector2(-size.x * 0.5, -size.y * 0.5 + bob), size), false)
