extends Node
## «TimeShift»: past and present are never separate. Every level is one map with two layers that
## exist at the same time: `layer_past` and `layer_present` (pieces that exist in both times stay
## in the world itself). The current state only decides which layer the hero touches; the other
## layer is always drawn as a ghost (alpha 0.35, blue for the past, orange for the present).
##
## - Every level starts in the present; the past is the playable choice through the lens.
## - The lens has a charge (0..100) for every hero: a trip to the past costs SHIFT_COST and the
##   charge refills while in the present (and from little clocks). Coming back is never refused for
##   lack of charge, so a child is never stuck in the past.
## - Soft return: after AUTO_RETURN_AFTER seconds in the past the hero is brought back softly
##   (countdown on the HUD). It can be switched off in the settings ("auto_return").
## - `blocker_in()` keeps every switch safe: never inside a wall or water.

signal time_changed(state: int, instant: bool)
signal charge_changed(value: float)
## Seconds left before the soft return while in the past (-1 when there is none to show).
signal return_countdown(seconds_left: float)
## The soft return is due: the level brings the hero back as soon as it is safe.
signal auto_return_due

enum { PAST, PRESENT }

const NAMES := ["گذشته", "حال"]
const MAX_CHARGE := 100.0
const SHIFT_COST := 25.0
const RECHARGE_PER_SEC := 5.0
const AUTO_RETURN_AFTER := 20.0
const GHOST_ALPHA := 0.35
## The absent layer: blue when it is the past, orange when it is the present.
const GHOST_PAST := Color(0.55, 0.78, 1.0, GHOST_ALPHA)
const GHOST_PRESENT := Color(1.0, 0.66, 0.32, GHOST_ALPHA)
const BLEND_TIME := 0.3

var state: int = PRESENT
var charge := MAX_CHARGE
var past_elapsed := 0.0
## True while a level is being played (charge and the soft return only tick then).
var running := false
var layer_past: Node2D
var layer_present: Node2D
## The butterfly effect: things done in the past (a seed planted...) that change the present.
var history: Array = []

var _layer_tween: Tween
var _due_sent := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## A new level: always the present (the v4 rule), full charge.
func reset(_start_state: int = PRESENT) -> void:
	state = PRESENT
	charge = MAX_CHARGE
	past_elapsed = 0.0
	history = []
	running = true
	_apply_layers(true)
	time_changed.emit(state, true)
	charge_changed.emit(charge)
	return_countdown.emit(-1.0)


func stop() -> void:
	running = false
	layer_past = null
	layer_present = null


## The two layer nodes of the level; their colours follow the state.
func register_layers(past: Node2D, present: Node2D) -> void:
	layer_past = past
	layer_present = present
	_apply_layers(true)


func target_state() -> int:
	return PAST if state == PRESENT else PRESENT


func auto_return_enabled() -> bool:
	return bool(SaveManager.data.get("settings", {}).get("auto_return", true))


## Enough charge for the switch? Going back to the present is always allowed.
func can_afford() -> bool:
	return target_state() == PRESENT or charge >= SHIFT_COST


## Returns the node that would trap or hurt the hero in `in_state`, or null when safe.
func blocker_in(body_rect: Rect2, in_state: int) -> Node:
	var probe := body_rect.grow(-2.0)
	for node in get_tree().get_nodes_in_group("time_solid"):
		if node.is_solid_in(in_state) and node.get_world_rect().intersects(probe):
			return node
	for node in get_tree().get_nodes_in_group("time_hazard"):
		if node.is_active_in(in_state) and node.get_world_rect().intersects(probe):
			return node
	return null


## Blocker for switching to the other time, or null when the switch is allowed.
func find_blocker(body_rect: Rect2) -> Node:
	return blocker_in(body_rect, target_state())


func shift(soft := false) -> void:
	if target_state() == PAST:
		charge = maxf(0.0, charge - SHIFT_COST)
		charge_changed.emit(charge)
	state = target_state()
	past_elapsed = 0.0
	_due_sent = 0.0
	_apply_layers(false, BLEND_TIME * (2.5 if soft else 1.0))
	time_changed.emit(state, false)
	return_countdown.emit(AUTO_RETURN_AFTER if state == PAST and auto_return_enabled() else -1.0)


## A little clock (pickup) or a time station: more charge.
func add_charge(amount: float) -> void:
	charge = clampf(charge + amount, 0.0, MAX_CHARGE)
	charge_changed.emit(charge)


func record(event_id: String) -> void:
	if not history.has(event_id):
		history.append(event_id)


func has_event(event_id: String) -> bool:
	return history.has(event_id)


func state_from_name(state_name: String) -> int:
	return PAST if state_name == "past" else PRESENT


## The modulate of a layer: full when it is the current time, the ghost colour otherwise.
func layer_color(layer_state: int, current: int) -> Color:
	if layer_state == current:
		return Color.WHITE
	return GHOST_PAST if layer_state == PAST else GHOST_PRESENT


func _apply_layers(instant: bool, time := BLEND_TIME) -> void:
	if _layer_tween:
		_layer_tween.kill()
	var pairs := [[layer_past, PAST], [layer_present, PRESENT]]
	if instant or not is_inside_tree():
		for pair in pairs:
			if is_instance_valid(pair[0]):
				pair[0].modulate = layer_color(pair[1], state)
		return
	_layer_tween = create_tween().set_parallel(true)
	for pair in pairs:
		if is_instance_valid(pair[0]):
			_layer_tween.tween_property(pair[0], "modulate", layer_color(pair[1], state), time)


func _process(delta: float) -> void:
	if not running:
		return
	if state == PRESENT:
		if charge < MAX_CHARGE:
			charge = minf(MAX_CHARGE, charge + RECHARGE_PER_SEC * _recharge_rate() * delta)
			charge_changed.emit(charge)
		return
	past_elapsed += delta
	if not auto_return_enabled():
		return
	var left := AUTO_RETURN_AFTER - past_elapsed
	return_countdown.emit(maxf(left, 0.0))
	if left <= 0.0:
		# repeated every quarter second until the level finds a safe moment to come back
		_due_sent -= delta
		if _due_sent <= 0.0:
			_due_sent = 0.25
			auto_return_due.emit()


## Easy mode refills the lens faster.
func _recharge_rate() -> float:
	return 1.5 if bool(SaveManager.data.get("settings", {}).get("easy", false)) else 1.0
