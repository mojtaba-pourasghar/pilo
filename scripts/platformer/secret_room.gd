class_name SecretRoom
extends Node2D
## An underground room or a cave under a roof. From outside it looks like solid earth;
## when Nima gets inside (through a pipe or a broken wall) the earth fades away and the
## room stays revealed. The back wall (dark earth, stones, roots) is drawn behind it.

const TILE := 64.0

var cells: Array = []          ## Vector2i grid cells of the room
var palette: Dictionary = {}
var revealed := false

var _cover := 1.0
var _set := {}
var _bounds := Rect2()


func _ready() -> void:
	z_index = 6
	for cell in cells:
		_set[cell] = true
		var r := Rect2(Vector2(cell) * TILE, Vector2(TILE, TILE))
		_bounds = r if _bounds.size == Vector2.ZERO else _bounds.merge(r)
	var back := Backdrop.new()
	back.cells = cells
	back.palette = palette
	back.z_index = -12
	back.z_as_relative = false
	add_child(back)


func _physics_process(_delta: float) -> void:
	if revealed:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not _bounds.grow(8.0).has_point(player.global_position):
		return
	var cell := Vector2i(floori(player.global_position.x / TILE), floori(player.global_position.y / TILE))
	if _set.has(cell) or _set.has(cell + Vector2i(0, 1)):
		revealed = true
		AudioManager.play_sfx("star", 0.8, -6.0)
		var tween := create_tween()
		tween.tween_property(self, "_cover", 0.0, 0.5)
		tween.tween_callback(queue_redraw)


func _process(_delta: float) -> void:
	if _cover > 0.0 and _cover < 1.0:
		queue_redraw()


func _draw() -> void:
	if _cover <= 0.0:
		return
	var dirt: Color = palette.get("dirt", Color("8d5a34"))
	var dark: Color = palette.get("dirt_dark", Color("6e4325"))
	for cell in cells:
		var r := Rect2(Vector2(cell) * TILE, Vector2(TILE, TILE))
		draw_rect(r.grow(0.5), Color(dirt, _cover))
		var seed: int = cell.x * 31 + cell.y * 17
		draw_circle(r.position + Vector2(12 + seed % 40, 14 + (seed * 7) % 36), 6.0, Color(dark, _cover))
		draw_circle(r.position + Vector2(8 + (seed * 3) % 48, 10 + (seed * 11) % 44), 4.0, Color(dark, _cover))


class Backdrop extends Node2D:
	var cells: Array = []
	var palette: Dictionary = {}

	func _draw() -> void:
		var wall := Color("4a3121")
		var wall_dark := Color("38241a")
		for cell in cells:
			var r := Rect2(Vector2(cell) * TILE, Vector2(TILE, TILE))
			draw_rect(r.grow(0.5), wall)
			var seed: int = cell.x * 13 + cell.y * 29
			draw_circle(r.position + Vector2(10 + seed % 44, 12 + (seed * 5) % 40), 9.0, wall_dark)
			draw_circle(r.position + Vector2(6 + (seed * 7) % 50, 8 + (seed * 3) % 48), 5.0, Color("5c3d29"))
			if seed % 5 == 0:
				# a root hanging from the ceiling
				draw_line(r.position + Vector2(20, 0), r.position + Vector2(26, 34), Color("6b4a2e"), 4.0)
				draw_line(r.position + Vector2(24, 20), r.position + Vector2(34, 30), Color("6b4a2e"), 3.0)
