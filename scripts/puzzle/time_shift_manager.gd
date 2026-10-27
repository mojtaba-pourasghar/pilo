extends Node
## Owns the single "past / present" state of the current level and decides whether a
## shift is safe: the hero must never appear inside a wall or inside water.

signal time_changed(state: int, instant: bool)

enum { PAST, PRESENT }

const NAMES := ["گذشته", "حال"]

var state: int = PRESENT


func reset(start_state: int) -> void:
	state = start_state
	time_changed.emit(state, true)


func target_state() -> int:
	return PAST if state == PRESENT else PRESENT


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


func shift() -> void:
	state = target_state()
	time_changed.emit(state, false)


func state_from_name(state_name: String) -> int:
	return PAST if state_name == "past" else PRESENT
