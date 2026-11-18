class_name GhostRival
extends Node2D
## «روح رقیب»: in a ghost-race level another traveller's ghost races the hero to the time gate.
## Online (version 2) it is the recorded run of a real player; offline it is a made-up ghost with a
## fixed pace. There is no rival character: the ghost is a translucent traveller whose display
## name comes from a ready list (no free text). Whoever reaches the gate first wins; losing costs
## nothing and never locks the main path, winning gives a bag of coins.

signal arrived

## Ready-made display names (online names are picked from the same kind of list).
const NAMES := ["مسافر تیزپا", "روباه بادپا", "ستارهٔ شب", "شاهین کوچک", "رهگذر زمان", "باد صبا"]
const SPEED := 410.0

var goal_x := 0.0
var running := false
var done := false
var display_name := ""
var speed := SPEED
var _rig: CharacterRig
var _air := 0.0
var _label: Label


## The offline ghost: a name from the list chosen by the level's seed (same ghost every run).
static func offline(level_seed: int) -> GhostRival:
	var ghost := GhostRival.new()
	ghost.display_name = NAMES[absi(level_seed) % NAMES.size()]
	return ghost


func _ready() -> void:
	z_index = 4
	if PaintedRig.available("hero"):
		_rig = PaintedRig.make("hero")
	else:
		_rig = HeroRig.new()
	# a ghost: see-through and pale blue, so it never looks like a person to fight
	modulate = Color(0.7, 0.85, 1.3, 0.55)
	add_child(_rig)
	_label = UIKit.make_label(display_name, 22, Color.WHITE, 6, Color("2f7fd0"))
	_label.size = Vector2(160, 30)
	_label.position = Vector2(-80, -150)
	add_child(_label)


const GRAVITY := 2000.0
const JUMP := 980.0

var _vy := 0.0
var _floor := false
var _placed := false


## Real running: gravity, landing, and a jump only where the ground ends or a ledge rises ahead
## (no snapping to the ground in front, which made him jitter).
func _physics_process(delta: float) -> void:
	if not running or done:
		_rig.state = "idle" if not done else "celebrate"
		_rig.speed = 0.0
		return
	var space := get_world_2d().direct_space_state
	if not _placed:
		# the first frame: stand on the ground under the start point (it may be inside a tile)
		_placed = true
		var start: Variant = _ground(space, global_position.x, global_position.y - 320.0)
		if start != null:
			global_position.y = float(start)
			_floor = true
	var ground_here: Variant
	if _floor:
		var ahead: Variant = _ground(space, global_position.x + 90.0, global_position.y - 260.0)
		if ahead == null or float(ahead) < global_position.y - 12.0:
			# a gap or a step up: jump, a little higher for a higher ledge
			var rise: float = 0.0 if ahead == null else global_position.y - float(ahead)
			_vy = -minf(JUMP + rise * 2.2, 1500.0)
			_floor = false
	_vy = minf(_vy + GRAVITY * delta, 1400.0)
	position.x += speed * delta
	position.y += _vy * delta
	ground_here = _ground(space, global_position.x, global_position.y - 40.0)
	if _vy >= 0.0 and ground_here != null and global_position.y >= float(ground_here) - 2.0:
		if not _floor:
			FX.dust(get_parent(), global_position, 4)
		global_position.y = float(ground_here)
		_vy = 0.0
		_floor = true
	elif ground_here == null or global_position.y < float(ground_here) - 6.0:
		_floor = false
	_rig.speed = speed
	_rig.state = "run" if _floor else ("jump" if _vy < 0.0 else "fall")
	if global_position.x >= goal_x:
		done = true
		arrived.emit()


## The top of the ground under x, searched downward from y (null over a pit).
func _ground(space: PhysicsDirectSpaceState2D, x: float, from_y: float) -> Variant:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 700.0), 1)
	var hit := space.intersect_ray(query)
	return null if hit.is_empty() else hit.position.y
