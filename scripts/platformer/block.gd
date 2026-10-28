class_name Block
extends StaticBody2D
## Blocks Nima bumps from below, Mario style, drawn in code:
## - QUESTION: golden "?" block; gives its content once (or a coin per bump for "coins");
## - BRICK: breaks into pieces when empty, otherwise gives its content;
## - HIDDEN: invisible until bumped from below — then it appears and gives its content
##   (usually a diamond: one of the secrets of a level);
## - USED: an emptied block.
## Content: "" | "coin" | "coins" (several, one per bump) | "diamond" | "heart".
## Bumping a block also frees any shadow creature standing on it.

enum Kind { QUESTION, BRICK, HIDDEN, USED }

const SIZE := 64.0
const OUTLINE := Color("3b2418")
const MULTI_COINS := 6

var kind: int = Kind.QUESTION
var content := "coin"
var diamond_index := -1
var game: Node

var _shape: CollisionShape2D
var _bump := 0.0
var _t := 0.0
var _left := MULTI_COINS
var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 2
	add_to_group("block")
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE, SIZE)
	_shape.shape = rect
	_shape.position = Vector2(SIZE, SIZE) * 0.5
	_shape.disabled = kind == Kind.HIDDEN
	add_child(_shape)
	_t = randf() * 3.0


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if kind != Kind.HIDDEN or game == null or game.player == null:
		return
	# A hidden block reveals itself when Nima's head comes up into it from below.
	var player: CharacterBody2D = game.player
	if player.velocity.y >= 0.0:
		return
	var head: float = player.global_position.y - player.BODY_SIZE.y * 0.5
	var x := player.global_position.x - global_position.x
	if x > 4.0 and x < SIZE - 4.0 and head < global_position.y + SIZE and head > global_position.y + SIZE * 0.4:
		kind = Kind.QUESTION
		_shape.set_deferred("disabled", false)
		player.global_position.y = global_position.y + SIZE + player.BODY_SIZE.y * 0.5 + 1.0
		player.velocity.y = 80.0
		bump(player)


func _process(delta: float) -> void:
	_t += delta
	if kind != Kind.HIDDEN:
		queue_redraw()


func bump(_by: Node = null) -> void:
	if _cooldown > 0.0 or kind == Kind.HIDDEN:
		return
	_cooldown = 0.2
	var tween := create_tween()
	tween.tween_property(self, "_bump", 1.0, 0.07)
	tween.tween_property(self, "_bump", 0.0, 0.12)
	_free_enemies_on_top()
	if kind == Kind.USED:
		AudioManager.play_sfx("bump")
		return
	if kind == Kind.BRICK and content == "":
		smash()
		return
	AudioManager.play_sfx("bump")
	_give()


func _give() -> void:
	var top := global_position + Vector2(SIZE * 0.5, 0)
	match content:
		"coin", "coins":
			if game:
				game.add_coins(1, top)
			_coin_pop(top)
			if content == "coins":
				_left -= 1
				if _left > 0:
					return
		"diamond", "heart":
			var item := Collectible.new()
			item.kind = Collectible.Kind.DIAMOND if content == "diamond" else Collectible.Kind.HEART
			item.index = diamond_index
			item.game = game
			item.position = position + Vector2(SIZE * 0.5, SIZE * 0.5)
			get_parent().add_child(item)
			item.pop_up(SIZE + 4.0)
			AudioManager.play_sfx("grow", 1.4)
	kind = Kind.USED


## Breaks the brick into pieces (from below, or by Pilo).
func smash() -> void:
	AudioManager.play_sfx("brick")
	FX.debris(get_parent(), global_position + Vector2(SIZE, SIZE) * 0.5, Color("c9773b"), 6)
	_free_enemies_on_top()
	collision_layer = 0
	queue_free()


func _free_enemies_on_top() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var e := enemy as Node2D
		if absf(e.global_position.x - (global_position.x + SIZE * 0.5)) < SIZE * 0.75 and absf(e.global_position.y - global_position.y) < 14.0:
			e.call("defeat")


func _coin_pop(pos: Vector2) -> void:
	var pop := CoinPop.new()
	pop.position = pos - get_parent().global_position
	get_parent().add_child(pop)


func _draw() -> void:
	var o := Vector2(0, -_bump * 12.0)
	var r := Rect2(o + Vector2(2, 2), Vector2(SIZE - 4, SIZE - 4))
	match kind:
		Kind.QUESTION:
			_rounded(r.grow(2), 10.0, OUTLINE)
			_rounded(r, 9.0, Color("e08a10"))
			_rounded(Rect2(r.position + Vector2(4, 3), r.size - Vector2(8, 10)), 7.0, Color("ffc928"))
			_rounded(Rect2(r.position + Vector2(8, 6), Vector2(r.size.x - 16, 10)), 5.0, Color("fff1a8"))
			for c in [Vector2(10, 10), Vector2(SIZE - 10, 10), Vector2(10, SIZE - 12), Vector2(SIZE - 10, SIZE - 12)]:
				draw_circle(o + c, 3.0, Color("b5660a"))
			var font := ThemeDB.fallback_font
			var pulse := 1.0 + sin(_t * 4.0) * 0.06
			var size := int(42 * pulse)
			draw_string_outline(font, o + Vector2(SIZE * 0.5 - size * 0.27, SIZE * 0.5 + size * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, size, 8, OUTLINE)
			draw_string(font, o + Vector2(SIZE * 0.5 - size * 0.27, SIZE * 0.5 + size * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)
			var sweep := fmod(_t * 0.6, 2.0)
			if sweep < 1.0:
				var x := r.position.x + sweep * r.size.x
				draw_line(Vector2(x, r.position.y + 4), Vector2(x - 14, r.end.y - 4), Color(1, 1, 1, 0.35), 6.0)
		Kind.BRICK:
			draw_rect(r.grow(2), OUTLINE)
			draw_rect(r, Color("b8642c"))
			for row in 4:
				var y := r.position.y + row * 15.0
				var shift := 0.0 if row % 2 == 0 else 15.0
				for col in 3:
					var x := r.position.x + shift + col * 30.0 - 15.0
					var brick := Rect2(Vector2(maxf(x + 2, r.position.x + 2), y + 2), Vector2(26, 11)).intersection(r.grow(-2))
					if brick.size.x > 4:
						draw_rect(brick, Color("d9813f"))
						draw_line(brick.position, brick.position + Vector2(brick.size.x, 0), Color("f0a868"), 2.0)
		Kind.USED:
			_rounded(r.grow(2), 10.0, OUTLINE)
			_rounded(r, 9.0, Color("8a6a4a"))
			_rounded(Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), 7.0, Color("a5835f"))
			for c in [Vector2(10, 10), Vector2(SIZE - 10, 10), Vector2(10, SIZE - 12), Vector2(SIZE - 10, SIZE - 12)]:
				draw_circle(o + c, 3.0, Color("6b4f34"))


func _rounded(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	draw_style_box(box, rect)


## A coin that jumps out of a block, spins and vanishes (already counted).
class CoinPop extends Node2D:
	var _t := 0.0

	func _ready() -> void:
		z_index = 6
		AudioManager.play_sfx("coin")
		var tween := create_tween()
		tween.tween_property(self, "position:y", position.y - 90.0, 0.25).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", position.y - 50.0, 0.2).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_t += delta * 3.0
		queue_redraw()

	func _draw() -> void:
		Collectible.draw_coin(self, Vector2.ZERO, 1.0, _t)
