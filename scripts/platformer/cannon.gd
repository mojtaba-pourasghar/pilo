class_name ShadowCannon
extends StaticBody2D
## A hollow shadow log that puffs shadow balls toward Nima every few seconds while he is
## near. The balls can be stomped. Solid, one tile.

const TILE := 64.0
const OUTLINE := Color("3b2418")
const PERIOD := 3.0
const RANGE := 900.0

var game: Node
var _timer := 1.5
var _recoil := 0.0
var _facing := -1.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TILE, TILE)
	shape.shape = rect
	shape.position = rect.size * 0.5
	add_child(shape)


func _physics_process(delta: float) -> void:
	_recoil = maxf(0.0, _recoil - delta * 3.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var dx := player.global_position.x - (global_position.x + TILE * 0.5)
	if absf(dx) > 40.0:
		_facing = signf(dx)
	if absf(dx) > RANGE or absf(player.global_position.y - global_position.y) > 400.0:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = PERIOD
		_fire()
	queue_redraw()


func _fire() -> void:
	var ball := ShadowBall.new()
	ball.game = game
	ball.facing = _facing
	ball.position = position + Vector2(TILE * 0.5 + _facing * 40.0, TILE * 0.5 + 18.0)
	get_parent().add_child(ball)
	_recoil = 1.0
	AudioManager.play_sfx("cannon", 1.0, -3.0)
	FX.dust(get_parent(), global_position + Vector2(TILE * 0.5 + _facing * 36.0, TILE * 0.5), 6)


func _draw() -> void:
	var c := Vector2(TILE * 0.5, TILE * 0.5)
	# stump base
	draw_rect(Rect2(6, 30, 52, 34), OUTLINE)
	draw_rect(Rect2(9, 33, 46, 28), Color("7a4a26"))
	# hollow log barrel pointing at the hero
	var tip := c + Vector2(_facing * (26.0 - _recoil * 6.0), -4)
	var tail := c + Vector2(-_facing * 18.0, -2)
	draw_line(tail, tip, OUTLINE, 38.0)
	draw_line(tail, tip, Color("8c5a2e"), 32.0)
	draw_line(tail + Vector2(0, -9), tip + Vector2(0, -9), Color("b07a45"), 6.0)
	draw_circle(tip, 19.0, OUTLINE)
	draw_circle(tip, 16.0, Color("c99a62"))
	draw_circle(tip, 10.0, Color("2a1838"))
	draw_circle(tip, 14.0 + sin(Time.get_ticks_msec() * 0.006) * 2.0, Color(0.5, 0.25, 0.75, 0.25))
