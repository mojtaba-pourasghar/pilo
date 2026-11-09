class_name CompanionFollower
extends Node2D
## The companion that is out (instead of Pilo) walks or flies beside Nima. Its passive ability
## (wall jump, double jump...) is applied by the player; the paw button calls act() below.

var id := "squirrel"
var target: Node2D

var _rig: CharacterRig
var _flyer := false
var _velocity := Vector2.ZERO


func _ready() -> void:
	z_index = 4
	_flyer = CompanionRig.FLYERS.has(id)
	if PaintedCreature.available("companion_" + id):
		_rig = PaintedCreature.make("companion_" + id, 64.0, "fly" if _flyer else "walk")
	else:
		var drawn := CompanionRig.new()
		drawn.id = id
		_rig = drawn
	add_child(_rig)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or busy:
		return
	var facing := 1.0
	if target.get("facing") != null:
		facing = float(target.get("facing"))
	var goal := target.global_position + Vector2(-130.0 * facing, 0.0)
	if not _flyer:
		# walkers stand on the ground under the goal
		var query := PhysicsRayQueryParameters2D.create(goal + Vector2(0, -40), goal + Vector2(0, 400), 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			goal.y = hit.position.y
	var to := goal - global_position
	if to.length() > 900.0:
		# fell too far behind (a pipe, a respawn): catch up at once
		global_position = goal
		_velocity = Vector2.ZERO
		return
	_velocity = _velocity.lerp(to * 4.0, 1.0 - exp(-6.0 * delta))
	global_position += _velocity * delta
	if absf(_velocity.x) > 12.0:
		_rig.scale.x = signf(_velocity.x)
	_rig.state = "move" if _velocity.length() > 40.0 else "idle"


# --- The companion's own button --------------------------------------------------------
# Only one companion is out at a time (Pilo is one of them). The paw button does what the
# companion that is out can do; if there is nothing for that close by, it falls back to
# something useful (an attack, or fetching coins), the way Pilo's button does.

const ACTIONS := {
	"squirrel": "fetch", "turtle": "attack", "mole": "dig", "penguin": "attack",
	"butterfly": "sniff", "owl": "sniff", "spark": "zap", "hedgehog": "smash",
	"goat": "smash", "cat": "attack", "dragon": "fire", "lion": "roar",
}
const COOLDOWN := 0.8

var busy := false
var _cooldown := 0.0


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func act(_game: Node) -> String:
	if busy or _cooldown > 0.0 or target == null:
		return ""
	_cooldown = 4.0 if id == "lion" else COOLDOWN
	var here: Vector2 = target.global_position
	match String(ACTIONS.get(id, "attack")):
		"fetch":
			if _fetch(here, 520.0, 6):
				return "fetch"
		"dig":
			var den := _nearest(get_tree().get_nodes_in_group("fox_den"), here, 260.0, func(n): return not n.empty)
			if den:
				_dash_to(den.global_position + Vector2(32, 44), func(): den.give(target))
				AudioManager.play_sfx("rustle", 1.0)
				return "dig"
			var found := false
			for block in get_tree().get_nodes_in_group("block"):
				if block.kind == Block.Kind.HIDDEN and block.global_position.distance_to(here) < 520.0:
					block.sniffed()
					found = true
			if found:
				FX.burst(get_parent(), global_position, Color(0.9, 0.75, 0.4), 16)
				return "dig"
		"sniff":
			var secret := _nearest(get_tree().get_nodes_in_group("secret"), here, 1100.0, func(_n): return true)
			if secret:
				_mark(secret.global_position)
				return "sniff"
		"smash":
			var wall := _nearest(get_tree().get_nodes_in_group("breakable") + _bricks(), here, 280.0, func(_n): return true)
			if wall:
				_dash_to(wall.global_position + Vector2(32, 32), func(): wall.smash())
				return "smash"
		"zap":
			var far := _nearest(get_tree().get_nodes_in_group("enemy"), here, 640.0, func(n): return not n.freed)
			if far:
				_bolt(far.global_position + Vector2(0, -20))
				far.defeat("pilo")
				return "zap"
		"fire":
			var hit := false
			var facing := float(target.get("facing")) if target.get("facing") != null else 1.0
			for enemy in get_tree().get_nodes_in_group("enemy"):
				var d: Vector2 = enemy.global_position - here
				if not enemy.freed and d.x * facing > 0.0 and absf(d.x) < 460.0 and absf(d.y) < 140.0:
					enemy.defeat("pilo")
					hit = true
			FX.burst(get_parent(), global_position + Vector2(80.0 * facing, -20), Color(1, 0.55, 0.15), 30)
			AudioManager.play_sfx("fire", 1.0)
			if hit:
				return "fire"
		"roar":
			var any := false
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if not enemy.freed and enemy.global_position.distance_to(here) < 360.0:
					enemy.defeat("pilo")
					any = true
			Juice.shake(self, 0.25)
			AudioManager.play_sfx("thunder", 1.6, -6.0)
			FX.dust_ring(get_parent(), global_position)
			if any:
				return "roar"
	# the fall-back: a quick attack on a creature close by, else fetch what is near
	var enemy := _nearest(get_tree().get_nodes_in_group("enemy"), here, 340.0, func(n): return not n.freed)
	if enemy:
		_dash_to(enemy.global_position + Vector2(0, -20), func(): enemy.defeat("pilo"))
		return "attack"
	if _fetch(here, 400.0, 3):
		return "fetch"
	_cooldown = 0.2
	return ""


func _fetch(here: Vector2, reach: float, most: int) -> bool:
	var items: Array = []
	for item in get_tree().get_nodes_in_group("collectible"):
		if not item.taken and item.global_position.distance_to(here) < reach:
			items.append(item)
	items.sort_custom(func(a, b): return a.global_position.distance_to(here) < b.global_position.distance_to(here))
	for i in mini(most, items.size()):
		items[i].fetch_to(target)
	if not items.is_empty():
		AudioManager.play_sfx("star", 1.3, -6.0)
	return not items.is_empty()


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


## Leaps to a point, does the thing there, and comes back to Nima's side.
func _dash_to(where: Vector2, on_hit: Callable) -> void:
	busy = true
	set_physics_process(false)
	_rig.state = "move"
	if where.x != global_position.x:
		_rig.scale.x = signf(where.x - global_position.x)
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
		_velocity = Vector2.ZERO
		set_physics_process(true))


## A glowing ring over a secret, for a few seconds.
func _mark(where: Vector2) -> void:
	var ring := Node2D.new()
	ring.global_position = where
	ring.z_index = 6
	ring.draw.connect(func(): ring.draw_arc(Vector2.ZERO, 46.0, 0.0, TAU, 40, Color(1, 0.9, 0.4, 0.9), 5.0, true))
	get_parent().add_child(ring)
	ring.queue_redraw()
	var tween := ring.create_tween().set_loops(4)
	tween.tween_property(ring, "scale", Vector2(1.25, 1.25), 0.35)
	tween.tween_property(ring, "scale", Vector2.ONE, 0.35)
	get_tree().create_timer(3.0).timeout.connect(ring.queue_free)
	AudioManager.play_sfx("star", 1.5, -4.0)


## A crackling bolt from the companion to the creature.
func _bolt(to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(0.7, 0.9, 1.0)
	line.z_index = 6
	var from := global_position + Vector2(0, -20)
	for i in 9:
		var k := i / 8.0
		line.add_point(from.lerp(to, k) + (Vector2(0, randf_range(-14, 14)) if i % 8 != 0 else Vector2.ZERO))
	get_parent().add_child(line)
	line.create_tween().tween_property(line, "modulate:a", 0.0, 0.35).finished.connect(line.queue_free)
	AudioManager.play_sfx("impact", 1.6, -4.0)
