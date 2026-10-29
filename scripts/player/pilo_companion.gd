extends Node2D
## Pilo, the active companion (drawn in code by PiloRig). He runs beside Nima on the ground
## and glides with a magic glow when Nima jumps or falls. The Pilo button makes him act,
## in this order:
##   1. a shadow creature nearby → he pounces on it and frees it;
##   2. a cracked wall or brick nearby → he breaks it;
##   3. a fox den (a hole only he fits through) nearby → he goes in and brings out what is inside;
##   4. coins or diamonds nearby → he fetches them (up to three at once);
##   otherwise he shakes his head.
## When Nima glides, Pilo flies above him and carries him. His nose finds secrets: near a hidden
## block, a cracked wall or a den he runs over, points with an "!" and sniffs.
## He still glows in the colour of the current time and flies to hint spots.

const PAST_GLOW := Color(1.0, 0.72, 0.3)
const PRESENT_GLOW := Color(0.4, 0.9, 1.0)
const HINT_TIME := 4.0
var attack_range := 320.0
const SMASH_RANGE := 220.0
const FETCH_RANGE := 380.0
const COOLDOWN := 0.8
var sniff_range := 230.0

var target: Node2D
var busy := false

var _t := 0.0
var _hint_pos := Vector2.ZERO
var _hint_left := 0.0
var _cooldown := 0.0
var _last_pos := Vector2.ZERO
var _sniffed := {}
var _sniff_target: Node2D
var _sniff_left := 0.0
var _bubble: Label

@onready var rig: CharacterRig = $Rig


func _ready() -> void:
	z_index = 6
	if PaintedRig.available("pilo"):
		var painted := PaintedRig.make("pilo")
		painted.name = "Rig"
		rig.replace_by(painted)
		rig.queue_free()
		rig = painted
	_last_pos = global_position
	_bubble = UIKit.make_label("!", 40, UIKit.ORANGE, 10, Color.WHITE)
	_bubble.size = Vector2(60, 50)
	_bubble.position = Vector2(-30, -110)
	_bubble.visible = false
	add_child(_bubble)


func _process(delta: float) -> void:
	_t += delta
	_cooldown -= delta
	if busy:
		return
	var goal := global_position
	var flying := true
	_sniff(delta)
	if target and target.gliding:
		# carrying Nima: right above his raised hands
		goal = target.global_position + Vector2(0, -target.BODY_SIZE.y * 0.5 - 52.0)
		global_position = global_position.lerp(goal, 1.0 - exp(-25.0 * delta))
		rig.state = "fly"
		rig.scale.x = target.facing
		_last_pos = global_position
		return
	if _sniff_left > 0.0 and is_instance_valid(_sniff_target):
		_sniff_left -= delta
		goal = _sniff_target.global_position + Vector2(-40, 20)
		flying = true
	elif _hint_left > 0.0:
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


## Pilo's nose: the first time a secret comes near, he runs to it and points it out.
func _sniff(delta: float) -> void:
	if target == null or _sniff_left > 0.0:
		return
	var here: Vector2 = target.global_position
	for node in get_tree().get_nodes_in_group("secret"):
		if _sniffed.has(node) or not is_instance_valid(node):
			continue
		var at: Vector2 = node.global_position + Vector2(32, 32)
		if at.distance_to(here) < sniff_range and (not node.has_method("is_secret") or node.is_secret()):
			_sniffed[node] = true
			_sniff_target = node
			_sniff_left = 1.6
			_bubble.visible = true
			_bubble.modulate.a = 1.0
			var tween := create_tween()
			tween.tween_property(_bubble, "position:y", -130.0, 0.2).from(-100.0)
			tween.tween_interval(1.2)
			tween.tween_property(_bubble, "modulate:a", 0.0, 0.3)
			tween.tween_callback(func(): _bubble.visible = false)
			AudioManager.play_sfx("chatter", 1.3, -6.0)
			if node.has_method("sniffed"):
				node.sniffed()
			return


## The Pilo button. Returns what he did ("attack", "smash", "den", "fetch" or "").
func act(game: Node) -> String:
	if busy or _cooldown > 0.0 or target == null:
		return ""
	_cooldown = COOLDOWN
	var here: Vector2 = target.global_position
	var enemy := _nearest(get_tree().get_nodes_in_group("enemy"), here, attack_range, func(n): return not n.freed)
	if enemy:
		_pounce(enemy.global_position + Vector2(0, -20), func(): enemy.defeat())
		return "attack"
	var wall := _nearest(get_tree().get_nodes_in_group("breakable") + _bricks(), here, SMASH_RANGE, func(_n): return true)
	if wall:
		var center: Vector2 = wall.global_position + Vector2(32, 32)
		_pounce(center, func(): wall.smash())
		return "smash"
	var den := _nearest(get_tree().get_nodes_in_group("fox_den"), here, SMASH_RANGE, func(n): return not n.empty)
	if den:
		busy = true
		rig.state = "run"
		var start := global_position
		var tween := create_tween()
		tween.tween_property(self, "global_position", den.global_position + Vector2(32, 44), 0.35)
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_interval(0.6)
		tween.tween_callback(func(): den.give(target))
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
		tween.tween_property(self, "global_position", start, 0.35)
		tween.tween_callback(func():
			busy = false
			_last_pos = global_position
			_happy(0.6))
		AudioManager.play_sfx("rustle", 1.2)
		return "den"
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
