class_name Ghubarak
extends Node2D
## Ghubarak, the playful dust sprite who scattered the time pieces. Not a villain:
## he giggles, runs off and later helps fix his mistake.

var game: Node
## Chase mode (level "chase": true): he keeps ahead of the hero, never too fast, and waits at
## stop_x (beside the exit) until he is caught. Caught = the level's "friend" is rescued.
var chase := false
var stop_x := 0.0
var _t := 0.0
var _fled := false
var _caught := false
var _hover_y := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _fled or game == null or game.player == null:
		return
	if chase:
		_chase(delta)
		return
	if global_position.distance_to(game.player.global_position) < 300.0:
		flee()


func flee() -> void:
	_fled = true
	AudioManager.play_sfx("giggle")
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2(420, -320), 1.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.4).set_delay(0.4)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_body(self, Vector2(0, sin(_t * 2.5) * 8.0), 1.0, _t)


## Shared drawing so the dialogue portrait matches the in-level character.
static func draw_body(canvas: CanvasItem, center: Vector2, s: float, t: float) -> void:
	var body := Color("b9a7d6")
	var light := Color("dcd0ef")
	var puffs := [Vector2(-22, 6), Vector2(22, 6), Vector2(0, -14), Vector2(-14, -8), Vector2(14, -8), Vector2(0, 12)]
	for i in puffs.size():
		var wobble := sin(t * 3.0 + i) * 2.0
		canvas.draw_circle(center + (puffs[i] + Vector2(0, wobble)) * s, (20.0 + (i % 2) * 4.0) * s, body)
	canvas.draw_circle(center + Vector2(-6, -16) * s, 12.0 * s, light)
	for side in [-1.0, 1.0]:
		var eye: Vector2 = center + Vector2(10.0 * side, -2) * s
		canvas.draw_circle(eye, 8.0 * s, Color.WHITE)
		canvas.draw_circle(eye + Vector2(1.5, 1) * s, 4.5 * s, Color("2d2340"))
		canvas.draw_circle(eye + Vector2(-1, -2) * s, 1.8 * s, Color.WHITE)
	canvas.draw_arc(center + Vector2(0, 10) * s, 7.0 * s, 0.2, PI - 0.2, 12, Color("5d4a80"), 3.0 * s)
	for i in 4:
		var a := t * 1.5 + i * TAU / 4.0
		var p: Vector2 = center + Vector2(cos(a) * 46.0, sin(a) * 30.0) * s
		var r := (3.0 + sin(t * 6.0 + i) * 1.5) * s
		canvas.draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -r * 2), p + Vector2(r * 0.6, 0), p + Vector2(0, r * 2), p + Vector2(-r * 0.6, 0)
		]), Color(1, 0.92, 0.5, 0.9))


func _chase(delta: float) -> void:
	if _caught:
		return
	var hero: Vector2 = game.player.global_position
	if _hover_y == 0.0:
		_hover_y = global_position.y
	var gap := global_position.x - hero.x
	if global_position.x < stop_x and gap < 380.0:
		# run on, a little slower than the hero so a child always catches up
		global_position.x = minf(global_position.x + 250.0 * delta, stop_x)
		if randf() < delta * 1.5:
			AudioManager.play_sfx_once("giggle", 1.5)
	_hover_y = lerpf(_hover_y, hero.y - 110.0, 1.0 - exp(-2.0 * delta))
	global_position.y = _hover_y
	if global_position.x >= stop_x - 1.0 and global_position.distance_to(hero + Vector2(0, -60)) < 110.0:
		_caught = true
		AudioManager.play_sfx("pop")
		game.on_friend_rescued(self)
