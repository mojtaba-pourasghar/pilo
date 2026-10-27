class_name MovingPlatform
extends AnimatableBody2D
## Leaf raft that glides back and forth with soft easing so timing stays forgiving.

const WIDTH := 128.0
const THICK := 20.0

var axis := Vector2.RIGHT
var distance := 256.0
var period := 4.5
var palette: Dictionary = {}

var _origin := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	_origin = position
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, THICK)
	shape.shape = rect
	shape.position = Vector2(WIDTH * 0.5, THICK * 0.5)
	shape.one_way_collision = true
	add_child(shape)


func _physics_process(delta: float) -> void:
	_t += delta
	position = _origin + axis * distance * (0.5 - 0.5 * cos(_t * TAU / period))


func _draw() -> void:
	var wood: Color = palette.get("wood", Color("c08048"))
	var leaf: Color = palette.get("vine", Color("4cb848"))
	draw_rect(Rect2(8, 2, WIDTH - 16, 16), wood)
	draw_circle(Vector2(8, 10), 8.0, wood)
	draw_circle(Vector2(WIDTH - 8, 10), 8.0, wood)
	draw_rect(Rect2(4, 14, WIDTH - 8, 5), wood.darkened(0.35))
	for x in [18.0, 52.0, 86.0, 112.0]:
		draw_circle(Vector2(x, 2), 7.0, leaf)
	if axis == Vector2.UP:
		draw_line(Vector2(20, 0), Vector2(20, -600), Color(leaf.darkened(0.3), 0.5), 3.0)
		draw_line(Vector2(WIDTH - 20, 0), Vector2(WIDTH - 20, -600), Color(leaf.darkened(0.3), 0.5), 3.0)
