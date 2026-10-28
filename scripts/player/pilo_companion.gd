extends Node2D
## Pilo, the active companion (drawn in code by PiloRig). He runs beside Nima on the ground
## and glides with a magic glow when Nima jumps or falls. The Pilo button makes him act,
## in this order:
##   1. a shadow creature nearby → he pounces on it and frees it;
##   2. a cracked wall or brick nearby → he breaks it;
##   3. coins or diamonds nearby → he fetches them (up to three at once);
##   otherwise he shakes his head.
## He still glows in the colour of the current time and flies to hint spots.

const PAST_GLOW := Color(1.0, 0.72, 0.3)
const PRESENT_GLOW := Color(0.4, 0.9, 1.0)
const HINT_TIME := 4.0
const ATTACK_RANGE := 320.0
const SMASH_RANGE := 220.0
const FETCH_RANGE := 380.0
const COOLDOWN := 0.8

var target: Node2D
var busy := false

var _t := 0.0
var _hint_pos := Vector2.ZERO
var _hint_left := 0.0
var _cooldown := 0.0
var _last_pos := Vector2.ZERO

@onready var rig: PiloRig = $Rig


func _ready() -> void:
	z_index = 6
	_last_pos = global_position


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if busy:
		return
	var goal := global_position
	var flying := true
	if _hint_left > 0.0:
		_hint_left -= delta
		goal = _hint_pos + Vector2(0, 10.0 + sin(_t * 7.0) * 10.0)
	elif target:
		var facing: float = target.facing
		var feet: Vector2 = target.global_position + Vector2(0, target.FEET)
		goal = feet + Vector2(-70.0 * facing, 0)
		flying = not target.is_on_floor() or absf(global_position.y - feet.y) > 40.0
		if flying:
			goal.y -= 46.0 + sin(_t * 3.0) * 6.0
	var k := 1.0 - exp(-(9.0 if not flying else 5.0) * delta)
	global_position = global_position.lerp(goal, k)
	if not flying and target:
		global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-20.0 * delta))
	var moved := (global_position - _last_pos) / maxf(delta, 0.001)
	_last_pos = global_position
	if absf(moved.x) > 12.0:
		rig.scale.x = signf(moved.x)
	elif target and _hint_left <= 0.0:
		rig.scale.x = target.facing
	if flying:
		rig.state = "fly"
	elif absf(moved.x) > 40.0:
		rig.state = "run"
	else:
		rig.state = "idle"
	rig.speed = moved.x
	rig.run_speed = 470.0


## The Pilo button. Returns what he did ("attack", "smash", "fetch" or "").
func act(game: Node) -> String:
	if busy or _cooldown > 0.0 or target == null:
		return ""
	_cooldown = COOLDOWN
	var here: Vector2 = target.global_position
	var enemy := _nearest(get_tree().get_nodes_in_group("enemy"), here, ATTACK_RANGE, func(n): return not n.freed)
	if enemy:
		_pounce(enemy.global_position + Vector2(0, -20), func(): enemy.defeat())
		return "attack"
	var wall := _nearest(get_tree().get_nodes_in_group("breakable") + _bricks(), here, SMASH_RANGE, func(_n): return true)
	if wall:
		var center: Vector2 = wall.global_position + Vector2(32, 32)
		_pounce(center, func(): wall.smash())
		return "smash"
	var items: Array = []
	for item in get_tree().get_nodes_in_group("collectible"):
		if not item.taken and item.global_position.distance_to(here) < FETCH_RANGE:
			items.append(item)
	items.sort_custom(func(a, b): return a.global_position.distance_to(here) < b.global_position.distance_to(here))
	if not items.is_empty():
		for i in mini(3, items.size()):
			items[i].fetch_to(target)
		_happy(0.8)
		AudioManager.play_sfx("star", 1.3, -6.0)
		return "fetch"
	shake()
	if game and game.has_method("_notice"):
		game._notice("اینجا کاری از پیلو برنمی‌آید.", UIKit.ORANGE)
	return ""


func _bricks() -> Array:
	var out: Array = []
	for block in get_tree().get_nodes_in_group("block"):
		if block.kind == Block.Kind.BRICK and block.content == "":
			out.append(block)
	return out


func _nearest(nodes: Array, from: Vector2, reach: float, ok: Callable) -> Node2D:
	var best: Node2D = null
	var best_d := reach
	for node in nodes:
		if not is_instance_valid(node) or not ok.call(node):
			continue
		var d: float = (node as Node2D).global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = node
	return best


func _pounce(where: Vector2, on_hit: Callable) -> void:
	busy = true
	rig.state = "attack"
	rig.scale.x = signf(where.x - global_position.x) if where.x != global_position.x else rig.scale.x
	AudioManager.play_sfx("dash", 1.3)
	var start := global_position
	var tween := create_tween()
	tween.tween_method(func(k: float): global_position = start.lerp(where, k) + Vector2(0, -sin(k * PI) * 60.0), 0.0, 1.0, 0.28)
	tween.tween_callback(func():
		on_hit.call()
		FX.burst(get_parent(), where, Color(1, 0.9, 0.4), 12))
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		busy = false
		_last_pos = global_position
		_happy(0.6))


func _happy(time: float) -> void:
	rig.state = "happy"
	busy = true
	await get_tree().create_timer(time).timeout
	busy = false


func on_time_changed(state: int, instant: bool) -> void:
	rig.glow = PAST_GLOW if state == TimeShift.PAST else PRESENT_GLOW
	if instant:
		return
	var tween := create_tween()
	tween.tween_property(rig, "rotation", TAU, 0.45).from(0.0)
	tween.tween_callback(func(): rig.rotation = 0.0)


## Head shake: "not here".
func shake() -> void:
	rig.state = "sad"
	var tween := create_tween()
	for angle in [-0.25, 0.25, -0.15, 0.15, 0.0]:
		tween.tween_property(rig, "rotation", angle, 0.07)


func show_hint(pos: Vector2) -> void:
	_hint_pos = pos
	_hint_left = HINT_TIME
	AudioManager.play_sfx("star", 1.4)


func apply_color(color_id: String) -> void:
	var entry: Dictionary = StoreAdapter.PILO_COLORS.get(color_id, StoreAdapter.PILO_COLORS.classic)
	rig.set_hue_shift(float(entry.hue))
