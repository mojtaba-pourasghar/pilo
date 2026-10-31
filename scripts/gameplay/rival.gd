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


func _physics_process(delta: float) -> void:
	if not running or done:
		_rig.state = "idle" if not done else "celebrate"
		return
	position.x += SPEED * delta
	_rig.speed = SPEED
	# find the ground ahead: he jumps up onto ledges and over gaps
	var query := PhysicsRayQueryParameters2D.create(Vector2(global_position.x + 24.0, global_position.y - 280.0), Vector2(global_position.x + 24.0, global_position.y + 420.0), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		# a gap: a long hop
		_air += delta
		position.y -= cos(clampf(_air * 3.0, 0.0, PI)) * 260.0 * delta
		_rig.state = "jump"
	else:
		_air = 0.0
		var ground: float = hit.position.y
		position.y = lerpf(position.y, ground, 1.0 - exp(-12.0 * delta))
		_rig.state = "run" if absf(position.y - ground) < 20.0 else "jump"
	if global_position.x >= goal_x:
		done = true
		arrived.emit()
