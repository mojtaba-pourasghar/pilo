class_name CompanionFollower
extends Node2D
## The companion picked in the village walks (or flies) behind Pilo through the level.
## It is only company and a reminder of its ability; the ability itself is applied by the game.

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
	if target == null or not is_instance_valid(target):
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
