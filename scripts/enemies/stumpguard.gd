class_name Stumpguard
extends CharacterBody2D
## K1 of the new era: the round tree-trunk guardian of the plain (docs/33 section 5, B8). Two phases:
##   1 ROLL      it telegraphs (0.6 s of red-orange glow), rolls at the hero; after the roll it rests and its weak spot,
##               a glowing thread on its back, shows for 2 s
##   2 POMEGRANATES (after the first hit) it also throws red pomegranates in an arc (telegraphed), then rests, weak spot lit
## Only a shot that lands while the thread glows counts; three hits free it (it becomes a baby Verdlin, thanks him and
## the gate opens). It never kills anything. Drawn here until the animated art arrives (v3_stumpguard_frames).

signal freed_signal

const GRAVITY := 2000.0
var game: Node
var hits_needed := 3
var hits := 0
var freed := false
var is_freed := false
var state := "idle"          ## idle, tell, roll, throw_tell, throw, rest, hurt, freed
var facing := -1.0
var _t := 0.0
var _rot := 0.0
var _home := Vector2.ZERO
var _range := 640.0
var _cool := 0.0
var _flash := 0.0
var _rig: SideEnemy.FrameRig
var _rocks: Array = []        ## thrown pomegranates: [position, velocity]


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 3
	add_to_group("enemy")
	add_to_group("keeper")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(110, 110)
	shape.shape = rect
	shape.position = Vector2(0, -55)
	add_child(shape)
	_home = position
	state = "idle"
	if SideRig._sheet_atlas("v3f_g_stumpguard").size() > 0:
		_rig = SideEnemy.FrameRig.new()
		_rig.sheet = "v3f_g_stumpguard"
		_rig.stand = 150.0
		_rig.fps = 8.0
		_rig.rows = {"idle": 0, "tell": 1, "roll": 2, "throw": 3, "rest": 4, "hurt": 5, "freed": 6, "move": 0}
		_rig.loops = ["idle", "tell", "roll", "rest"]
		add_child(_rig)
	_t = 1.0


func phase() -> int:
	return 1 if hits < 1 else 2


func weak() -> bool:
	return state == "rest"


func receive_hit(_how: String, _from: Vector2) -> bool:
	if freed:
		return true
	if not weak():
		return false                  # bounced off the bark
	hits += 1
	_flash = 0.4
	state = "hurt"
	_t = 0.7
	Juice.hit(self, global_position + Vector2(0, -60), 0.4)
	if hits >= hits_needed:
		_free()
	return true


## The hero's stomp or Pilo also count while the weak spot is lit.
func defeat(how := "stomp") -> void:
	receive_hit(how, global_position)


func _free() -> void:
	freed = true
	is_freed = true
	state = "freed"
	_t = 0.0
	ReleaseFX.spawn(get_parent(), global_position + Vector2(0, -70), 12)
	freed_signal.emit()
	if game != null and game.has_method("on_stumpguard_freed"):
		game.on_stumpguard_freed(self)


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	var p: Node2D = game.player if game and game.get("player") else null
	_t -= delta
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if p != null and absf(p.global_position.x - global_position.x) < _range and _t <= 0.0:
				facing = signf(p.global_position.x - global_position.x)
				state = "tell"
				_t = 0.6
		"tell":
			if _t <= 0.0:
				state = "roll"
				_t = 1.6
				velocity.x = facing * 460.0
		"roll":
			_rot += facing * 460.0 * delta / 55.0
			if is_on_wall() or _t <= 0.0:
				velocity.x = 0.0
				state = "rest"
				_t = 2.0
				SpriteFX.play(get_parent(), "dust_soil", global_position, 0.9)
			elif p != null and _touches(p):
				p.take_hit(global_position.x)
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _t <= 0.0:
				if phase() == 2 and randf() < 0.6:
					state = "throw_tell"
					_t = 0.7
				else:
					state = "idle"
					_t = 0.5
		"throw_tell":
			if p != null:
				facing = signf(p.global_position.x - global_position.x)
			if _t <= 0.0:
				state = "throw"
				_t = 0.3
				if p != null:
					_throw(p)
		"throw":
			if _t <= 0.0:
				state = "rest"
				_t = 2.0
		"hurt":
			velocity.x = 0.0
			if _t <= 0.0:
				state = "idle"
				_t = 0.4
		"freed":
			velocity.x = 0.0
	move_and_slide()
	# pomegranates: arcs that burst on the ground, hurting only on contact
	for r in _rocks.duplicate():
		r[1].y += 1500.0 * delta
		r[0] += r[1] * delta
		if p != null and r[0].distance_to(p.global_position + Vector2(0, -40)) < 36.0 and p.invulnerable <= 0.0:
			p.take_hit(r[0].x)
			_rocks.erase(r)
		elif r[0].y > _home.y + 8.0:
			SpriteFX.play(get_parent(), "pomegranate_splash", r[0], 0.9)
			_rocks.erase(r)
	if _rig != null:
		_sync_rig()
	queue_redraw()


func _touches(p: Node2D) -> bool:
	return p.get("invulnerable") != null and p.invulnerable <= 0.0 \
		and p.global_position.distance_to(global_position + Vector2(0, -50)) < 78.0


func _throw(p: Node2D) -> void:
	var from := global_position + Vector2(facing * 40.0, -90.0)
	var dx := p.global_position.x - from.x
	var vx := clampf(dx * 0.9, -520.0, 520.0)
	_rocks.append([from, Vector2(vx, -620.0)])


func _draw() -> void:
	if _rig != null:
		_draw_rocks_and_glow()
		return
	_draw_placeholder()


func _sync_rig() -> void:
	_rig.scale.x = facing
	_rig.mode = {"throw_tell": "tell"}.get(state, state)
	_rig.modulate = Color(1, 1, 1).lerp(Color(2, 2, 2), _flash * 2.0)


func _draw_rocks_and_glow() -> void:
	if weak():
		var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		var back := Vector2(-facing * 44.0, -60.0)
		draw_line(back + Vector2(0, -30), back + Vector2(0, 26), Color(1.0, 0.8, 0.3, 0.3 + 0.3 * glow), 8.0)
	for r in _rocks:
		var rp: Vector2 = to_local(r[0])
		draw_circle(rp, 11.0, Color("2a1f3d"))
		draw_circle(rp, 9.0, Color("d0453a"))


func _draw_placeholder() -> void:
	var tell := state == "tell" or state == "throw_tell"
	var c := Vector2(0, -55)
	draw_set_transform(c, _rot if state == "roll" else 0.0)
	var body := Color("8a5a2b") if not tell else Color("c76a2a")
	if _flash > 0.0:
		body = body.lerp(Color.WHITE, _flash * 2.0)
	draw_circle(Vector2.ZERO, 58.0, Color("2a1f3d"))
	draw_circle(Vector2.ZERO, 54.0, body)
	for i in 3:
		draw_arc(Vector2.ZERO, 14.0 + i * 14.0, 0.5, 5.4, 18, Color("6b4222"), 3.0)
	draw_set_transform(Vector2.ZERO)
	if state != "roll":
		var eye := Vector2(facing * 16.0, -66.0)
		draw_circle(eye, 8.0, Color("f6efe0"))
		draw_circle(eye + Vector2(facing * 2.0, 1.0), 4.0, Color("2a1f3d"))
		draw_circle(Vector2(facing * 34.0, -52.0), 8.0, Color("f6efe0"))
	# white flowers and red pomegranates on the crown
	for k in 3:
		var fp := Vector2(-22.0 + k * 22.0, -112.0 + abs(k - 1) * 6.0)
		draw_circle(fp, 9.0, Color("f6efe0"))
		draw_circle(fp, 4.0, Color("e9c46a"))
	draw_circle(Vector2(-34, -104), 8.0, Color("c0392b"))
	if weak():
		var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		var back := Vector2(-facing * 44.0, -60.0)
		draw_line(back + Vector2(0, -30), back + Vector2(0, 26), Color(1.0, 0.8, 0.3, 0.4 + 0.4 * glow), 10.0)
		draw_line(back + Vector2(0, -30), back + Vector2(0, 26), Color(1.0, 0.95, 0.7), 4.0)
	if state == "freed":
		var k := clampf(_t + 0.001, 0.0, 1.0)
		draw_circle(Vector2(0, -20), 22.0, Color("2a1f3d"))
		draw_circle(Vector2(0, -20), 19.0, Color("c9b27a"))
		draw_line(Vector2(-10, -38), Vector2(-14, -52), Color("5fb04a"), 4.0)
		draw_line(Vector2(10, -38), Vector2(14, -52), Color("5fb04a"), 4.0)
	for r in _rocks:
		var rp: Vector2 = to_local(r[0])
		draw_circle(rp, 11.0, Color("2a1f3d"))
		draw_circle(rp, 9.0, Color("d0453a"))
