class_name FallingPlatform
extends AnimatableBody2D
## A log raft that shakes when stood on, then falls; it comes back a few seconds later.
## Two tiles wide, one-way (you can jump up through it).

const WIDTH := 128.0
const THICK := 22.0
const OUTLINE := Color("3b2418")

var palette: Dictionary = {}
var _home := Vector2.ZERO
var _shake := 0.0
var _falling := false
var _vel := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	z_index = 1
	_home = position
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, THICK)
	_shape.shape = rect
	_shape.position = Vector2(WIDTH * 0.5, THICK * 0.5)
	_shape.one_way_collision = true
	add_child(_shape)


func stood_on(_player: Node) -> void:
	if _shake > 0.0 or _falling:
		return
	_shake = 0.55
	AudioManager.play_sfx("creak", 1.3, -4.0)


func _physics_process(delta: float) -> void:
	if _shake > 0.0:
		_shake -= delta
		if _shake <= 0.0:
			_falling = true
			_vel = 0.0
	if _falling:
		_vel = minf(_vel + 1800.0 * delta, 1000.0)
		position.y += _vel * delta
		if position.y > _home.y + 900.0:
			_falling = false
			_shape.set_deferred("disabled", true)
			visible = false
			await get_tree().create_timer(2.5).timeout
			position = _home
			visible = true
			modulate.a = 0.0
			create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
			_shape.set_deferred("disabled", false)
	queue_redraw()


func _draw() -> void:
	var wood: Color = palette.get("wood", Color("c08048"))
	var jitter := Vector2(sin(_shake * 90.0) * 3.0, 0) if _shake > 0.0 else Vector2.ZERO
	var raft := WorldArt.pic("falling_platform")
	if raft:
		draw_texture_rect(raft, Rect2(jitter + Vector2(-6, -10), Vector2(WIDTH + 12, THICK + 22)), false)
		return
	for i in 4:
		var r := Rect2(jitter + Vector2(i * 32.0 + 1.0, 0), Vector2(30, THICK))
		draw_rect(r, OUTLINE)
		draw_rect(r.grow(-3), wood)
		draw_line(r.position + Vector2(5, 6), r.position + Vector2(25, 6), wood.lightened(0.25), 2.0)
		draw_circle(r.position + Vector2(15, 15), 3.0, wood.darkened(0.3))
	# rope ties
	draw_line(jitter + Vector2(30, -2), jitter + Vector2(34, THICK + 2), Color("e9d29b"), 3.0)
	draw_line(jitter + Vector2(94, -2), jitter + Vector2(98, THICK + 2), Color("e9d29b"), 3.0)
