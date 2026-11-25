class_name Companion
extends Node2D
## The companion (docs/47 section 4): Tikkit, the little clock bird, flies beside the hero with a soft delay, flapping.
##   - dew magnet: drops within MAGNET px fly to the hero
##   - guide: when something hidden (a cage, a treasure, the time egg) is near, it flies toward it and glows, then back
##   - strike help: when the hero strikes, it dives at the nearest creature
## Drawn from the painted parts (art/cut/tikkit_parts): 0 body, 1 head happy, 2 head, 3 head sleepy, 5/6 wings, 8 tail.

const MAGNET := 170.0
const GUIDE_RANGE := 620.0

var hero: HeroBody
var level: Node
var _t := 0.0
var _vel := Vector2.ZERO
var _guide: Node2D = null
var _guide_t := 0.0
var _dive: Node2D = null
var _dive_t := 0.0
var _happy := 0.0


func _ready() -> void:
	z_index = 6
	if hero:
		global_position = hero.global_position + Vector2(-80, -170)
		hero.struck.connect(_on_struck)


func _process(delta: float) -> void:
	_t += delta
	_happy = maxf(0.0, _happy - delta)
	if hero == null:
		return
	var goal := hero.global_position + Vector2(-hero.facing * 90.0, -190.0 + sin(_t * 2.2) * 14.0)
	# guide toward a hidden thing now and then
	_guide_t -= delta
	if _guide == null and _guide_t <= 0.0:
		_guide_t = 3.0
		for n in get_tree().get_nodes_in_group("hidden"):
			if is_instance_valid(n) and not n.get("found") and n.global_position.distance_to(hero.global_position) < GUIDE_RANGE:
				_guide = n
				_guide_t = 2.2
				break
	if _guide != null:
		if not is_instance_valid(_guide) or _guide.get("found") or _guide_t <= 0.0:
			_guide = null
			_guide_t = 4.0
		else:
			goal = _guide.global_position + Vector2(0, -90 + sin(_t * 6.0) * 10.0)
	if _dive != null:
		_dive_t -= delta
		if not is_instance_valid(_dive) or _dive_t <= 0.0:
			_dive = null
		else:
			goal = _dive.global_position + Vector2(0, -40)
	# springy follow
	var acc := (goal - global_position) * 22.0 - _vel * 6.5
	_vel += acc * delta
	global_position += _vel * delta
	# dew magnet
	for d in get_tree().get_nodes_in_group("dew"):
		if d.global_position.distance_to(hero.global_position + Vector2(0, -70)) < MAGNET:
			d.call("attract", hero)
	queue_redraw()


func _on_struck(at: Vector2) -> void:
	var best: Node2D = null
	var bd := 380.0
	for n in get_tree().get_nodes_in_group("strikeable"):
		var d: float = n.global_position.distance_to(at)
		if d < bd:
			best = n
			bd = d
	if best:
		_dive = best
		_dive_t = 0.5
		_happy = 1.2


func cheer() -> void:
	_happy = 1.5


func _draw() -> void:
	var face := -1.0 if _vel.x < -30.0 else 1.0
	var bob := sin(_t * 7.0) * 3.0
	var flap := sin(_t * 18.0)
	var s := 0.24
	var body := Kit.tex("tikkit_parts", 0)
	if body == null:
		draw_circle(Vector2(0, bob), 20.0, Color("f6efe0"))
		return
	if _guide != null:
		draw_circle(Vector2(0, bob), 46.0 + sin(_t * 8.0) * 6.0, Color(1, 0.9, 0.5, 0.35))
	draw_set_transform(Vector2(0, bob), _vel.x * 0.0006, Vector2(s * face, s))
	var wing_back := Kit.tex("tikkit_parts", 6)
	var wing := Kit.tex("tikkit_parts", 5)
	var tail := Kit.tex("tikkit_parts", 8)
	# back wing, tail, body, head, front wing
	if wing_back:
		draw_set_transform(Vector2(0, bob), flap * 0.6 - 0.3, Vector2(s * face * 0.9, s * 0.9))
		draw_texture(wing_back, Vector2(-wing_back.get_width() * 0.8, -wing_back.get_height() * 0.9), Color(0.85, 0.85, 0.85))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(s * face, s))
	if tail:
		draw_texture(tail, Vector2(-body.get_width() * 0.62, -tail.get_height() * 0.2))
	draw_texture(body, Vector2(-body.get_width() * 0.5, -body.get_height() * 0.5))
	var head := Kit.tex("tikkit_parts", 1 if _happy > 0.0 or _guide != null else 2)
	if head:
		draw_texture(head, Vector2(-head.get_width() * 0.1, -head.get_height() * 0.95))
	if wing:
		draw_set_transform(Vector2(0, bob), -flap * 0.7 + 0.2, Vector2(s * face, s))
		draw_texture(wing, Vector2(-wing.get_width() * 0.75, -wing.get_height() * 0.8))
	draw_set_transform(Vector2.ZERO)
