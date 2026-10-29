class_name FoxDen
extends Node2D
## «لانهٔ روباه»: a small burrow in the ground or a wall, far too small for Nima. Only Pilo fits:
## with the Pilo button he goes in and brings out what is inside (a diamond, or even the time
## key). Pilo's nose points dens out. Origin = top-left of its cell (the hole sits at the bottom).

const OUTLINE := Color("3b2418")

var content := "diamond"       ## "diamond" | "key" | "heart" | "coins"
var diamond_index := -1
var game: Node
var empty := false
var _t := 0.0


func _ready() -> void:
	z_index = 1
	add_to_group("fox_den")
	add_to_group("secret")


func is_secret() -> bool:
	return not empty


func give(player: Node2D) -> void:
	if empty:
		return
	empty = true
	var item := Collectible.new()
	match content:
		"key":
			item.kind = Collectible.Kind.TIME_KEY
		"heart":
			item.kind = Collectible.Kind.HEART
		"coins":
			item.kind = Collectible.Kind.COIN
		_:
			item.kind = Collectible.Kind.DIAMOND
			item.index = diamond_index
	item.game = game
	item.position = position + Vector2(32, 44)
	get_parent().add_child(item)
	item.fetch_to(player)
	FX.burst(get_parent(), global_position + Vector2(32, 44), Color(1, 0.9, 0.5), 12)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# mound of earth with an arched burrow opening, roots and a paw print sign
	var c := Vector2(32, 64)
	draw_circle(c + Vector2(0, 4), 34.0, OUTLINE)
	draw_circle(c + Vector2(0, 4), 31.0, Color("8d5a34"))
	draw_circle(c + Vector2(-12, -14), 9.0, Color("a5703f"))
	draw_circle(c + Vector2(0, 2), 19.0, OUTLINE)
	draw_circle(c + Vector2(0, 2), 16.0, Color("1c120c"))
	draw_line(c + Vector2(-26, -10), c + Vector2(-34, -24), Color("6b4a2e"), 3.0)
	draw_line(c + Vector2(22, -12), c + Vector2(30, -26), Color("6b4a2e"), 3.0)
	draw_circle(c + Vector2(22, -26), 5.0, Color("6cc24a"))
	if not empty:
		# eyes of the treasure glinting inside
		var glint := 0.5 + 0.5 * sin(_t * 3.0)
		draw_circle(c + Vector2(-4, 4), 2.5, Color(1, 0.95, 0.5, glint))
		draw_circle(c + Vector2(5, 6), 2.0, Color(0.6, 0.9, 1.0, glint))
