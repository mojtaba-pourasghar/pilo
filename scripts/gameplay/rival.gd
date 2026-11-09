class_name Rival
extends Node2D
## Kian, Nima's rival, racing him to the time gate (worlds 2, 4 and 6). He runs along the
## ground at a steady pace, hops gaps and climbs onto ledges. Whoever reaches the gate first
## wins; losing costs nothing, winning gives a bag of coins.

signal arrived

const SPEED := 410.0

var goal_x := 0.0
var running := false
var done := false
var _rig: CharacterRig
var _air := 0.0
var _label: Label


func _ready() -> void:
	z_index = 4
	if PaintedRig.available("kian"):
		_rig = PaintedRig.make("kian")
	elif PaintedRig.available("nima"):
		# until Kian has his own pictures: Nima's build in Kian's blue
		_rig = PaintedRig.make("nima")
		modulate = Color(0.62, 0.8, 1.25)
	else:
		_rig = NimaRig.new()
		modulate = Color(0.62, 0.8, 1.25)
	add_child(_rig)
	_label = UIKit.make_label("کیان", 22, Color.WHITE, 6, Color("2f7fd0"))
	_label.size = Vector2(100, 30)
	_label.position = Vector2(-50, -150)
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
	position.x += SPEED * delta
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
	_rig.speed = SPEED
	_rig.state = "run" if _floor else ("jump" if _vy < 0.0 else "fall")
	if global_position.x >= goal_x:
		done = true
		arrived.emit()


## The top of the ground under x, searched downward from y (null over a pit).
func _ground(space: PhysicsDirectSpaceState2D, x: float, from_y: float) -> Variant:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 700.0), 1)
	var hit := space.intersect_ray(query)
	return null if hit.is_empty() else hit.position.y
