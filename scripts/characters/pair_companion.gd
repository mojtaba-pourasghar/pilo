class_name PairCompanion
extends Node2D
## The living companions of pair 1 (docs/40 section 1.2): Embri (the clay-oven beetle) and Tikkit (the time spirit).
## Side-view frame animation (SideRig); they run or fly beside the hero, hop and leap with him, light the way, wait
## and sleep when he stands still, and react to coins and danger.
## The companion button (action "pilo") makes the active one take a TRANSFORMED FORM that helps the hero through
## the place he is in; the swap button changes the active companion like a creature trainer's team (a short
## summon effect). Forms by companion:
##   embri   lantern (a pool of warm light for the dark), cannon (burns tar, nets, dry bushes), rocket (a launch up)
##   tikkit  bubble (a time shield: 2.5 s of no damage), sandbridge (a platform ahead for 4 s), wings (lifts and carries 3 s)
## Forms need a cooldown (6 s); a `form_point` object in the level marks where a form is most useful (a glowing hint).

signal formed(form: String)
signal swapped(id: String)

const FORMS := {
	"embri": ["lantern", "cannon", "rocket"],
	"tikkit": ["bubble", "sandbridge", "wings"],
}
const COOLDOWN := 6.0

var team: Array = ["embri"]
var id := "embri"
var target: Node2D
var game: Node
var form := ""                    ## "" or the form that is active now
var form_left := 0.0
var cooldown := 0.0
var form_index := {}              ## companion id -> index of the form the button uses next

var _rig: SideRig
var _vel := Vector2.ZERO
var _still := 0.0
var _sleeping := false
var _hop := 0.0
var _light: Node2D
var _bridge: StaticBody2D
var _wings_t := 0.0
var _last_target_y := 0.0
var _happy := 0.0


func _ready() -> void:
	z_index = 4
	_build(id)


func _build(who: String) -> void:
	if _rig:
		_rig.queue_free()
	id = who
	_rig = SideRig.make(who)
	add_child(_rig)
	_rig.show_shadow = who != "tikkit"


func flyer() -> bool:
	return id == "tikkit"


## Where the companion wants to be: a little ahead of or behind the hero, walking on the ground or hovering.
func _goal() -> Vector2:
	var facing := float(target.get("facing")) if target.get("facing") != null else 1.0
	var lead := -86.0 * facing
	var goal := target.global_position + Vector2(lead, 0.0)
	if flyer():
		goal.y = target.global_position.y - 70.0 + sin(Time.get_ticks_msec() * 0.003) * 12.0
		goal.x = target.global_position.x + lead * 0.8
		return goal
	var query := PhysicsRayQueryParameters2D.create(goal + Vector2(0, -80), goal + Vector2(0, 500), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	goal.y = hit.position.y if not hit.is_empty() else target.global_position.y + 40.0
	return goal


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	cooldown = maxf(0.0, cooldown - delta)
	_happy = maxf(0.0, _happy - delta)
	if form_left > 0.0:
		form_left -= delta
		_tick_form(delta)
		if form_left <= 0.0:
			_end_form()
	var goal := _goal()
	var to := goal - global_position
	if to.length() > 800.0:
		global_position = goal
		_vel = Vector2.ZERO
	var accel := 7.5 if flyer() else 6.0
	_vel = _vel.lerp(to * 4.0, 1.0 - exp(-accel * delta))
	if not flyer():
		# walkers hop up ledges: a hop when the hero is clearly higher
		if to.y < -50.0 and absf(_vel.y) < 30.0 and _hop <= 0.0:
			_vel.y = -520.0
			_hop = 0.5
		_hop = maxf(0.0, _hop - delta)
	global_position += _vel * delta
	if absf(_vel.x) > 16.0:
		_rig.scale.x = signf(_vel.x)
	var moving := _vel.length() > 36.0
	# rest: after 8 s of standing still the companion curls up and sleeps; any move wakes it
	var hero_still: bool = absf(float(target.get("velocity").x) if target.get("velocity") != null else 0.0) < 8.0
	_still = _still + delta if (hero_still and not moving) else 0.0
	_sleeping = _still > 8.0
	_rig.speed = _vel.x
	_rig.run_speed = 360.0
	if form != "":
		_rig.state = "idle"
	elif _sleeping:
		_rig.lock_anim = "sleep"
	elif _happy > 0.0:
		_rig.lock_anim = "happy"
	else:
		_rig.lock_anim = ""
		if flyer():
			_rig.lock_anim = "fly"
		else:
			var air := absf(_vel.y) > 120.0
			_rig.state = "run" if (moving and not air) else "idle"
			if air:
				_rig.lock_anim = "hop" if _vel.y < 0.0 else "leap"
			elif moving:
				_rig.lock_anim = ""


## Called by the game when the hero picks up a coin: a tiny happy hop.
func cheer() -> void:
	_happy = 0.8
	_still = 0.0


# --- forms ----------------------------------------------------------------------------

func form_name() -> String:
	var list: Array = FORMS.get(id, [])
	if list.is_empty():
		return ""
	return String(list[int(form_index.get(id, 0)) % list.size()])


## The companion button. Returns what happened ("" = on cooldown).
func act(_game: Node) -> String:
	if cooldown > 0.0 or form != "":
		return ""
	var name := _best_form()
	form = name
	cooldown = Upgrades.companion_cooldown(id, COOLDOWN)
	_still = 0.0
	_begin_form(name)
	formed.emit(name)
	return name


## The form that suits the place: a marked form_point near the hero wins, else the one the hero needs most.
func _best_form() -> String:
	var list: Array = FORMS.get(id, [])
	for fp in get_tree().get_nodes_in_group("form_point"):
		if fp.global_position.distance_to(target.global_position) < 360.0 and list.has(String(fp.get("form"))):
			return String(fp.get("form"))
	# nothing marked: cycle through the companion's forms
	var i := int(form_index.get(id, 0))
	form_index[id] = (i + 1) % list.size()
	return String(list[i % list.size()])


func _begin_form(name: String) -> void:
	var fxparent: Node = get_parent()
	SpriteFX.play(fxparent, "tikkit_sandburst" if id == "tikkit" else "shock_ring", global_position, 0.9)
	match name:
		"lantern":
			form_left = 8.0
			_light = Node2D.new()
			add_child(_light)
			_light.set_script(load("res://scripts/characters/light_pool.gd"))
			_light.radius = 320.0
		"cannon":
			form_left = 1.2
			_burn_nearby()
		"rocket":
			form_left = 0.8
			if target.global_position.distance_to(global_position) < 260.0:
				target.velocity = Vector2(target.velocity.x * 0.4, -1180.0)
				SpriteFX.play(fxparent, "dust_soil", target.global_position + Vector2(0, 40), 1.1)
		"bubble":
			form_left = 2.5
			target.invulnerable = maxf(float(target.invulnerable), 2.5)
		"sandbridge":
			form_left = 4.0
			_make_bridge()
		"wings":
			form_left = 3.0
			_wings_t = 3.0


func _tick_form(delta: float) -> void:
	match form:
		"wings":
			# the companion carries the hero: a slow fall, a little lift when he holds jump
			if target.velocity.y > 40.0:
				target.velocity.y = 40.0
			if Input.is_action_pressed("jump"):
				target.velocity.y = minf(target.velocity.y, -140.0)
		"lantern":
			if _light:
				_light.position = Vector2(0, -20)
		"bubble":
			target.invulnerable = maxf(float(target.invulnerable), 0.1)


func _end_form() -> void:
	if _light:
		_light.queue_free()
		_light = null
	if _bridge:
		_bridge.queue_free()
		_bridge = null
	form = ""


func _burn_nearby() -> void:
	var here := global_position
	var burned := 0
	for node in get_tree().get_nodes_in_group("route_part"):
		var t := String(node.data.get("type", "")) if node.get("data") != null else ""
		if t in ["tar", "net"] and node.global_position.distance_to(here) < 340.0:
			burned += 1
			if t == "net":
				node._stuck = false
				node._torn = 8.0
			else:
				node.queue_free()
			SpriteFX.play(get_parent(), "brass_spark", node.global_position + Vector2(0, -30), 1.0)
	for node in get_tree().get_nodes_in_group("breakable"):
		if node is Node2D and node.global_position.distance_to(here) < 300.0 and node.has_method("smash"):
			node.smash()
			burned += 1
	SpriteFX.play(get_parent(), "warn_ring", here + Vector2(_rig.scale.x * 80.0, -20.0), 0.9)


func _make_bridge() -> void:
	# a platform of four tiles ahead of the hero (one-way: he can jump up through it)
	var facing := float(target.get("facing")) if target.get("facing") != null else 1.0
	_bridge = StaticBody2D.new()
	_bridge.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(256, 14)
	shape.shape = rect
	shape.one_way_collision = true
	_bridge.add_child(shape)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2(-128, -7), Vector2(128, -7), Vector2(128, 7), Vector2(-128, 7)])
	vis.color = Color(1.0, 0.86, 0.45, 0.8)
	_bridge.add_child(vis)
	get_parent().add_child(_bridge)
	_bridge.global_position = target.global_position + Vector2(facing * 190.0, 36.0)
	var tw := _bridge.create_tween()
	tw.tween_property(vis, "modulate:a", 0.4, 0.4).set_delay(3.0)


## Change the active companion (the team is `team`); a summon burst on both sides.
func swap() -> void:
	if team.size() < 2:
		return
	var i := team.find(id)
	var next := String(team[(i + 1) % team.size()])
	SpriteFX.play(get_parent(), "tikkit_sandburst" if id == "tikkit" else "shock_ring", global_position, 0.8)
	if form != "":
		form_left = 0.0
		_end_form()
	_build(next)
	cooldown = 0.0
	SpriteFX.play(get_parent(), "tikkit_sandburst" if next == "tikkit" else "shock_ring", global_position, 0.9)
	swapped.emit(next)


## Compatibility with the old follower API the game calls.
func _mark(_pos: Vector2) -> void:
	pass
