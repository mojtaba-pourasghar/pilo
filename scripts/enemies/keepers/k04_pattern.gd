class_name KeeperPattern
extends Keeper
## K4 «نقش‌دار» (ریشه‌دار): three root knots with signs (sun, moon, leaf) stand around it. The
## order is carved on a trunk that only exists in the past; in the present the knots must be hit
## in that order. A wrong knot resets them. The right order releases the keeper.

const ART := "res://assets/art/p5_enemies/p5_concept_ch01_stump_"
const SYMBOLS := ["sun", "moon", "leaf"]

var pattern: Array = [0, 1, 2]
var knots: Array = []
var _progress := 0
var sign_node: Node2D


func setup() -> void:
	type = "K4"
	body_size = Vector2(100, 130)
	art_height = 175.0
	art = {"idle": ART + "idle.png", "tell": ART + "attack.png", "attack": ART + "attack.png",
		"hurt": ART + "idle.png", "released": ART + "released.png"}
	pattern = params.get("pattern", [2, 0, 1])
	hits_needed = 1
	# the three knots float in an arc over its crown (so they fit wherever the keeper stands)
	var offsets := [Vector2(-150, -150), Vector2(0, -235), Vector2(150, -150)]
	for i in 3:
		var knot := Knot.new()
		knot.symbol = i
		knot.keeper = self
		knot.position = position + offsets[i]
		knots.append(knot)
		get_parent().add_child.call_deferred(knot)


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return false


func harmful() -> bool:
	return false


## A knot was hit: the next in the carved order lights up; a wrong one resets all of them.
func knot_hit(knot: Node) -> void:
	if freed:
		return
	if int(pattern[_progress]) == knot.symbol:
		_progress += 1
		knot.lit = true
		AudioManager.play_sfx("star", 1.0 + _progress * 0.15, -4.0)
		if _progress >= pattern.size():
			hits = hits_needed
			release()
			for k in knots:
				k.release()
	else:
		_progress = 0
		for k in knots:
			k.lit = false
		register_fail()
		set_state("tell")
		AudioManager.play_sfx("reject")


func keeper_process(_delta: float) -> void:
	velocity.x = 0.0
	if state == "tell" and _state_time > 0.6:
		set_state("idle")


## A root knot with a sign. Shots, stomps and Pilo hit it.
class Knot extends StaticBody2D:
	var symbol := 0
	var keeper: Node
	var lit := false
	var freed := false
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		add_to_group("enemy")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(56, 56)
		shape.shape = rect
		shape.position = Vector2(0, -28)
		add_child(shape)

	func receive_hit(_how: String, _from: Vector2) -> bool:
		if freed or lit:
			return false
		keeper.knot_hit(self)
		return true

	func defeat(how := "stomp") -> void:
		receive_hit(how, global_position)

	func release() -> void:
		freed = true
		collision_layer = 0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var glow := 0.6 + 0.4 * sin(_t * 4.0) if lit else 0.0
		draw_circle(Vector2(0, -28), 30.0, Color("5a3a22"))
		draw_circle(Vector2(0, -28), 25.0, Color("8a5a32"))
		if lit:
			draw_circle(Vector2(0, -28), 34.0, Color(1.0, 0.85, 0.3, 0.35 * glow))
		KeeperPattern.draw_symbol(self, Vector2(0, -28), symbol, 15.0, Color("ffe08a") if lit else Color("f3e6c8"))


## The sun, the moon and the leaf (drawn; final art: comms/ART_REQUESTS.md).
static func draw_symbol(ci: CanvasItem, c: Vector2, symbol: int, r: float, color: Color) -> void:
	match symbol:
		0:
			ci.draw_circle(c, r * 0.55, color)
			for k in 8:
				var a := k * TAU / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.75, c + Vector2(cos(a), sin(a)) * r * 1.1, color, 3.0)
		1:
			ci.draw_circle(c, r * 0.8, color)
			ci.draw_circle(c + Vector2(r * 0.35, -r * 0.2), r * 0.7, Color("8a5a32"))
		_:
			var pts := PackedVector2Array()
			for k in 13:
				var t := k / 12.0
				pts.append(c + Vector2(lerpf(-r, r, t), -sin(t * PI) * r * 0.6))
			for k in range(12, -1, -1):
				var t := k / 12.0
				pts.append(c + Vector2(lerpf(-r, r, t), sin(t * PI) * r * 0.6))
			ci.draw_colored_polygon(pts, color)


## The carving on the old trunk (past only): the order of the three signs.
class CarvedSign extends Node2D:
	var pattern: Array = [0, 1, 2]

	func time_mask() -> int:
		return 1

	func _draw() -> void:
		draw_rect(Rect2(-90, -150, 180, 150), Color("6e4325"))
		draw_rect(Rect2(-82, -142, 164, 134), Color("9a6a3e"))
		for i in pattern.size():
			var c := Vector2(-55 + i * 55, -90)
			draw_circle(c, 22.0, Color("5a3a22"))
			KeeperPattern.draw_symbol(self, c, int(pattern[i]), 14.0, Color("ffe08a"))
			if i < pattern.size() - 1:
				draw_line(c + Vector2(24, 0), c + Vector2(31, 0), Color("ffe08a"), 3.0)
