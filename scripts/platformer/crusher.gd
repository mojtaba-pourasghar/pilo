class_name Crusher
extends AnimatableBody2D
## «سنگ‌کوب»: a grumpy stone face hanging in the air. When Nima walks underneath it drops,
## rests a moment (you can stand on it) and slowly rises again. Being under it as it
## lands costs a heart. Size: 1.5 x 1.5 tiles; origin = top-left of its resting cell.

const SIZE := Vector2(96, 96)
const OUTLINE := Color("3b2418")
const FALL_ACCEL := 3200.0
const RISE_SPEED := 130.0

enum Phase { WAIT, FALL, REST, RISE }

var phase: int = Phase.WAIT
var _home := Vector2.ZERO
var _vel := 0.0
var _timer := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	z_index = 2
	_home = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = SIZE * 0.5
	add_child(shape)


func _physics_process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	match phase:
		Phase.WAIT:
			if player and absf(player.global_position.x - (global_position.x + SIZE.x * 0.5)) < SIZE.x * 0.9 \
					and player.global_position.y > global_position.y and player.global_position.y - global_position.y < 700.0:
				_timer += delta
				if _timer > 0.25:
					phase = Phase.FALL
					_vel = 0.0
			else:
				_timer = 0.0
		Phase.FALL:
			_vel = minf(_vel + FALL_ACCEL * delta, 1400.0)
			var step := _vel * delta
			var ground := _ground_distance(step + 4.0)
			if ground >= 0.0:
				position.y += ground
				_land(player)
			else:
				position.y += step
				if player and _player_underneath(player):
					var feet: float = player.global_position.y + player.FEET
					if feet > global_position.y + SIZE.y - 6.0 and player.global_position.y - player.BODY_SIZE.y * 0.5 < global_position.y + SIZE.y + 4.0:
						player.take_hit(player.global_position.x - player.facing * 10.0)
		Phase.REST:
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.RISE
		Phase.RISE:
			position.y = maxf(_home.y, position.y - RISE_SPEED * delta)
			if position.y <= _home.y:
				phase = Phase.WAIT
				_timer = -0.6
	queue_redraw()


func _land(player: CharacterBody2D) -> void:
	phase = Phase.REST
	_timer = 1.0
	AudioManager.play_sfx("thud")
	FX.dust(get_parent(), global_position + Vector2(10, SIZE.y), 6)
	FX.dust(get_parent(), global_position + Vector2(SIZE.x - 10, SIZE.y), 6)
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0)
	if player and _player_underneath(player) and player.is_on_floor():
		player.take_hit(player.global_position.x - player.facing * 10.0)


func _player_underneath(player: Node2D) -> bool:
	return absf(player.global_position.x - (global_position.x + SIZE.x * 0.5)) < SIZE.x * 0.5 + 14.0 \
		and player.global_position.y > global_position.y + SIZE.y * 0.5


## Distance to solid ground below within `reach`, or -1 when none.
func _ground_distance(reach: float) -> float:
	var space := get_world_2d().direct_space_state
	var best := -1.0
	for x in [6.0, SIZE.x * 0.5, SIZE.x - 6.0]:
		var from := global_position + Vector2(x, SIZE.y - 1.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, reach), 1, [get_rid()])
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			var d: float = hit.position.y - from.y - 1.0
			best = d if best < 0.0 else minf(best, d)
	return best


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, SIZE)
	draw_rect(r, OUTLINE)
	draw_rect(r.grow(-4), Color("8d929c"))
	draw_rect(Rect2(4, 4, SIZE.x - 8, 14), Color("b3b8c2"))
	draw_rect(Rect2(4, SIZE.y - 16, SIZE.x - 8, 12), Color("6f7580"))
	# stone teeth along the bottom
	for i in 5:
		var x := 8.0 + i * 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, SIZE.y - 4), Vector2(x + 8, SIZE.y + 8), Vector2(x + 16, SIZE.y - 4)]), OUTLINE)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 3, SIZE.y - 4), Vector2(x + 8, SIZE.y + 4), Vector2(x + 13, SIZE.y - 4)]), Color("c9ced8"))
	# face: watching eyes, grumpy brows, clenched mouth
	var angry := phase == Phase.FALL or phase == Phase.REST
	var look := 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		look = clampf((player.global_position.x - global_position.x - SIZE.x * 0.5) / 200.0, -1.0, 1.0) * 4.0
	for x in [30.0, 66.0]:
		draw_circle(Vector2(x, 42), 11.0, OUTLINE)
		draw_circle(Vector2(x, 42), 8.5, Color.WHITE)
		draw_circle(Vector2(x + look, 44 if angry else 43), 4.5, OUTLINE)
	draw_line(Vector2(18, 26 if angry else 28), Vector2(40, 32), OUTLINE, 5.0)
	draw_line(Vector2(78, 26 if angry else 28), Vector2(56, 32), OUTLINE, 5.0)
	draw_rect(Rect2(32, 62, 32, 10), OUTLINE)
	for i in 4:
		draw_line(Vector2(36 + i * 8, 63), Vector2(36 + i * 8, 71), Color("c9ced8"), 2.0)
