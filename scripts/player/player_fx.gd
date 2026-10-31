class_name PlayerFX
extends Node2D
## Nima's body in the world: dust kicked up by his feet (sand, snow... in the colour of the
## ground), a dust ring and a thump on a hard landing, sweat in the desert heat or after a
## long run, panting when he stops tired, his breath steaming in the cold, and catching fire
## for a moment when a guardian's fireball hits him.

const DUST := {
	"forest": Color(0.75, 0.62, 0.45, 0.8), "coral_beach": Color(0.98, 0.92, 0.75, 0.85),
	"golden_desert": Color(0.95, 0.78, 0.45, 0.85), "snow_mountain": Color(1, 1, 1, 0.9),
	"sky_islands": Color(1, 1, 1, 0.85), "crystal_caves": Color(0.7, 0.62, 0.85, 0.75),
	"clock_factory": Color(0.7, 0.66, 0.6, 0.8), "shadow_castle": Color(0.6, 0.55, 0.7, 0.75),
	"inverted_land": Color(1, 0.8, 0.95, 0.8),
}
const HOT := ["golden_desert"]
const COLD := ["snow_mountain"]

var player   ## the player controller (untyped: its constants are read)
var world := "forest"

var _step := -1
var _fall := 0.0
var _was_floor := true
var _run_time := 0.0
var _tired := 0.0
var _sweat_t := 0.0
var _breath_t := 0.0
var _burning := 0.0


func _ready() -> void:
	player = get_parent()
	var game := get_tree().get_first_node_in_group("game")
	if game and game.get("world") is Dictionary:
		world = String(game.world.get("id", "forest"))


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var on_floor: bool = player.is_on_floor()
	var feet: Vector2 = player.global_position + Vector2(0, player.FEET)
	var parent: Node = player.get_parent()
	if not on_floor:
		_fall = maxf(_fall, player.velocity.y)
	elif not _was_floor:
		_land(parent, feet)
	_was_floor = on_floor
	var running: bool = on_floor and absf(player.velocity.x) > 300.0
	# footsteps kick up a little of the ground
	var rig = player.rig
	var step := int(float(rig.phase) / PI)
	if running and step != _step:
		FX.dust_kick(parent, feet + Vector2(-player.facing * 10.0, -4), -player.facing, DUST.get(world, DUST.forest))
	_step = step
	# tiredness grows while running, fades while resting
	if running:
		_run_time += delta
	elif on_floor and absf(player.velocity.x) < 20.0:
		if _run_time > 6.0:
			_tired = 2.5
			AudioManager.play_sfx("pant", randf_range(0.95, 1.1), -4.0)
		_run_time = 0.0
	_tired = maxf(0.0, _tired - delta)
	if rig.get("tired") != null:
		rig.set("tired", _tired > 0.0)
	var head: Vector2 = player.global_position + Vector2(player.facing * 6.0, -86)
	_sweat_t -= delta
	var hot := HOT.has(world)
	if (_tired > 0.0 or (hot and running) or (_run_time > 4.0)) and _sweat_t <= 0.0 and not COLD.has(world):
		FX.sweat(parent, head, player.facing)
		_sweat_t = 0.35 if _tired > 0.0 else 0.7
	_breath_t -= delta
	if COLD.has(world) and _breath_t <= 0.0:
		FX.breath(parent, player.global_position + Vector2(player.facing * 24.0, -58), player.facing)
		_breath_t = 0.6 if (running or _tired > 0.0) else 1.6
	if _burning > 0.0:
		_burning -= delta
		if _burning <= 0.0:
			AudioManager.play_sfx("sizzle", 1.0, -6.0)


func _land(parent: Node, feet: Vector2) -> void:
	var speed := _fall
	_fall = 0.0
	var color: Color = DUST.get(world, DUST.forest)
	if speed > 1100.0:
		FX.dust_ring(parent, feet, 1.3, color)
		Juice.shake(self, 0.25)
		Juice.vibrate(25)
		AudioManager.play_sfx("thud", 1.3, -8.0)
	elif speed > 500.0:
		FX.dust_ring(parent, feet, 0.7, color)


## Nima catches fire for a moment (a guardian's fireball).
func ignite(seconds := 1.2) -> void:
	if _burning > 0.0:
		return
	_burning = seconds
	FX.flames(player, seconds)
	AudioManager.play_sfx("fire")
	Juice.flash(self, Color(1.0, 0.5, 0.1, 0.25), 0.3)
