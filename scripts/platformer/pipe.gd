class_name Pipe
extends StaticBody2D
## A hollow tree-trunk pipe (two tiles wide), drawn in code. A warp pipe has a destination:
## standing on it and pressing down (or the ↓ touch button that appears) takes Nima there,
## often to a secret room. `cells` = height in tiles; origin = top-left.

const TILE := 64.0
const OUTLINE := Color("3b2418")

var cells := 2
var warp_to := Vector2.ZERO
var is_warp := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 5
	add_to_group("pipe")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE * 2.0, TILE * cells)
	shape.shape = rect
	shape.position = rect.size * 0.5
	add_child(shape)


## Is the player standing on top, near the middle?
func player_on_top(player: CharacterBody2D) -> bool:
	if not player.is_on_floor():
		return false
	var feet := player.global_position.y + player.FEET
	return absf(feet - global_position.y) < 6.0 and absf(player.global_position.x - (global_position.x + TILE)) < TILE * 0.6


func _process(delta: float) -> void:
	_t += delta
	if is_warp:
		queue_redraw()


func _draw() -> void:
	var bark := Color("8c5a2e")
	var bark_light := Color("b07a45")
	var moss := Color("6cc24a")
	var h := TILE * cells
	# trunk
	draw_rect(Rect2(6, 22, TILE * 2.0 - 12, h - 22), OUTLINE)
	draw_rect(Rect2(10, 22, TILE * 2.0 - 20, h - 22), bark)
	for x in [24.0, 50.0, 78.0, 100.0]:
		draw_line(Vector2(x, 30), Vector2(x + 2, h), bark.darkened(0.2), 3.0)
	draw_line(Vector2(16, 26), Vector2(16, h), bark_light, 4.0)
	# rim
	draw_rect(Rect2(0, 0, TILE * 2.0, 28), OUTLINE)
	draw_rect(Rect2(3, 3, TILE * 2.0 - 6, 22), bark_light)
	draw_rect(Rect2(10, 6, TILE * 2.0 - 20, 10), Color("3a2414"))
	draw_circle(Vector2(12, 4), 7.0, moss)
	draw_circle(Vector2(22, 2), 5.0, moss.lightened(0.2))
	draw_circle(Vector2(112, 5), 6.0, moss)
	if is_warp:
		# a soft glow and a bobbing arrow tell the child this one goes somewhere
		var bob := sin(_t * 4.0) * 5.0
		draw_circle(Vector2(TILE, 8), 34.0, Color(1, 0.9, 0.4, 0.12 + sin(_t * 3.0) * 0.05))
		var a := Vector2(TILE, -34 + bob)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-13, -6), a + Vector2(13, -6), a + Vector2(0, 10)]), OUTLINE)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-9, -4), a + Vector2(9, -4), a + Vector2(0, 6)]), Color("ffd34d"))
