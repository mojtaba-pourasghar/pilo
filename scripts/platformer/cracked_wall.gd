class_name CrackedWall
extends StaticBody2D
## A mossy stone wall with cracks. A dash into it (or Pilo's attack) breaks it and opens
## the way to a hidden place. `cells` = height in tiles.

const TILE := 64.0
const OUTLINE := Color("3b2418")

var cells := 1
var palette: Dictionary = {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	add_to_group("breakable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE * cells)
	shape.shape = rect
	shape.position = rect.size * 0.5
	add_child(shape)


func smash() -> void:
	if collision_layer == 0:
		return
	collision_layer = 0
	AudioManager.play_sfx("brick")
	AudioManager.play_sfx("rumble", 1.3, -6.0)
	for i in cells:
		FX.debris(get_parent(), global_position + Vector2(TILE * 0.5, TILE * (i + 0.5)), palette.get("rock", Color("9ea3ad")), 5)
	queue_free()


func _draw() -> void:
	var rock: Color = palette.get("rock", Color("9ea3ad"))
	var dark: Color = palette.get("rock_dark", Color("6f7580"))
	for i in cells:
		var r := Rect2(Vector2(1, i * TILE + 1), Vector2(TILE - 2, TILE - 2))
		draw_rect(r, OUTLINE)
		draw_rect(r.grow(-3), rock)
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 8)), rock.lightened(0.2))
		var y := i * TILE
		# cracks
		draw_polyline(PackedVector2Array([Vector2(14, y + 6), Vector2(26, y + 22), Vector2(20, y + 34), Vector2(34, y + 48), Vector2(30, y + 60)]), dark, 3.0)
		draw_polyline(PackedVector2Array([Vector2(26, y + 22), Vector2(44, y + 26), Vector2(54, y + 18)]), dark, 2.5)
		draw_polyline(PackedVector2Array([Vector2(34, y + 48), Vector2(48, y + 44)]), dark, 2.5)
		# moss
		draw_circle(Vector2(10, y + 6), 6.0, Color("6cc24a"))
		draw_circle(Vector2(18, y + 4), 4.5, Color("8fd66a"))
