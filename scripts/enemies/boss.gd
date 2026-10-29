class_name Boss
extends CharacterBody2D
## The guardian of a world, cursed by the shadow. Stomp on its head (or send Pilo) while it is
## open to a hit; each hit makes it angrier and faster. With no hits left the curse lifts:
## it turns back into its true colours, thanks Nima, and the barred door to the time gate
## opens. Each world's guardian has its own look and moves (KINDS).

const GRAVITY := 2000.0
const KINDS := {
	"forest": {"name": "خرس پیر جنگل", "size": Vector2(150, 132), "hp": 3, "speed": 95.0, "moves": ["slam", "charge"], "flies": false},
	"coral_beach": {"name": "اختاپوس بزرگ", "size": Vector2(160, 130), "hp": 3, "speed": 70.0, "moves": ["throw", "slam", "summon"], "flies": false},
	"golden_desert": {"name": "کرم شنی", "size": Vector2(150, 120), "hp": 3, "speed": 120.0, "moves": ["burrow", "throw"], "flies": false},
	"snow_mountain": {"name": "غول یخی", "size": Vector2(160, 170), "hp": 4, "speed": 80.0, "moves": ["rain", "slam", "charge"], "flies": false},
	"sky_islands": {"name": "عقاب طوفان", "size": Vector2(150, 110), "hp": 4, "speed": 150.0, "moves": ["dive", "throw"], "flies": true},
	"crystal_caves": {"name": "عنکبوت بلورین", "size": Vector2(170, 110), "hp": 4, "speed": 130.0, "moves": ["rain", "charge", "summon"], "flies": false},
	"clock_factory": {"name": "ساعت‌ساز طلسم‌شده", "size": Vector2(150, 170), "hp": 4, "speed": 90.0, "moves": ["throw", "charge", "summon"], "flies": false},
	"shadow_castle": {"name": "شاه‌سایه", "size": Vector2(140, 190), "hp": 5, "speed": 120.0, "moves": ["charge", "throw", "rain", "summon", "slam"], "flies": false},
	"inverted_land": {"name": "زروان", "size": Vector2(120, 170), "hp": 5, "speed": 140.0, "moves": ["throw", "dive", "rain", "summon"], "flies": true},
}

var kind := "forest"
var game: Node
var hp := 3
var max_hp := 3
var facing := -1.0
var state := "intro"           ## intro, walk, windup, charge, jump, stunned, high, dive, under, hurt, free
var is_freed := false
var rig: EnemyRig

var _cfg: Dictionary
var _timer := 1.5
var _move := ""
var _hurtbox: Area2D
var _invulnerable := 0.0
var _home := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


## Pilo looks for "freed" on enemies.
var freed: bool:
	get:
		return is_freed


func _ready() -> void:
	_cfg = KINDS.get(kind, KINDS.forest)
	hp = int(_cfg.hp)
	max_hp = hp
	_home = position
	_rng.seed = hash(kind)
	collision_layer = 4
	collision_mask = 1
	z_index = 3
	add_to_group("enemy")
	add_to_group("boss")
	var size: Vector2 = _cfg.size
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y * 0.5)
	add_child(shape)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 2
	var hit := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = size - Vector2(16, 6)
	hit.shape = hit_rect
	hit.position = Vector2(0, -size.y * 0.5)
	_hurtbox.add_child(hit)
	add_child(_hurtbox)
	if PaintedCreature.available("boss_" + kind):
		# rendered guardian art faces right; the drawn one faces left
		var painted := PaintedCreature.make("boss_" + kind, size.y * 1.25, "boss")
		painted.face_left = true
		rig = painted
	else:
		var drawn := BossRig.new()
		drawn.kind = kind
		drawn.size = size
		rig = drawn
	add_child(rig)


func display_name() -> String:
	return String(_cfg.name)


func _physics_process(delta: float) -> void:
	if is_freed:
		return
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_timer -= delta
	var player := game.player as CharacterBody2D if game else null
	if player == null:
		return
	var to_player := player.global_position.x - global_position.x
	var anger := 1.0 + float(max_hp - hp) * 0.25
	match state:
		"intro":
			if absf(to_player) < 700.0:
				state = "walk"
				_timer = 1.4
		"walk":
			facing = signf(to_player) if absf(to_player) > 20.0 else facing
			velocity.x = facing * float(_cfg.speed) * anger * (0.5 if bool(_cfg.flies) else 1.0)
			if _timer <= 0.0:
				_start_move(player)
		"windup":
			velocity.x = 0.0
			if _timer <= 0.0:
				_do_move(player)
		"charge":
			velocity.x = facing * float(_cfg.speed) * 3.2 * anger
			if is_on_wall() or _timer <= 0.0:
				_stun(1.4)
				if is_on_wall():
					AudioManager.play_sfx("thud")
		"jump":
			if is_on_floor() and velocity.y >= 0.0 and _timer < 0.4:
				_land_slam()
		"high":
			# flying up and drifting over Nima before a dive
			velocity = Vector2(signf(to_player) * 220.0, (global_position.y - (_home.y - 330.0)) * -2.5)
			if _timer <= 0.0:
				state = "dive"
				velocity = (player.global_position - global_position).normalized() * 900.0
		"dive":
			if is_on_floor() or global_position.y >= _home.y:
				_stun(1.3)
		"under":
			# burrowed: invisible and untouchable, sliding under Nima, then bursting up
			rig.modulate.a = 0.0
			velocity.x = signf(to_player) * 260.0
			if _timer <= 0.0:
				rig.modulate.a = 1.0
				velocity = Vector2(0, -820)
				state = "jump"
				_timer = 0.6
				FX.dust(get_parent(), global_position, 10)
				AudioManager.play_sfx("rumble")
		"stunned", "hurt":
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				state = "walk"
				_timer = _rng.randf_range(1.2, 2.2) / anger
	var flying := bool(_cfg.flies) and state in ["walk", "high", "dive"]
	if not flying:
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	elif state == "walk":
		velocity.y = (_home.y - 160.0 + sin(Time.get_ticks_msec() * 0.003) * 30.0 - global_position.y) * 2.0
	move_and_slide()
	rig.scale.x = -facing
	rig.state = state
	rig.set("anger", anger)
	if state != "under":
		for body in _hurtbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				_touch(body)


func _start_move(player: Node2D) -> void:
	var moves: Array = _cfg.moves
	_move = String(moves[_rng.randi() % moves.size()])
	state = "windup"
	_timer = 0.7
	rig.set("flash", 1.0)
	AudioManager.play_sfx("reject", 0.6, -4.0)


func _do_move(player: Node2D) -> void:
	match _move:
		"charge":
			state = "charge"
			_timer = 1.3
		"slam":
			state = "jump"
			velocity = Vector2(signf(player.global_position.x - global_position.x) * 260.0, -980.0)
			_timer = 1.2
		"throw":
			for i in 3:
				_throw(player, i)
			_stun(1.0)
		"rain":
			for i in 5:
				var drop := Falling.new()
				drop.kind = kind
				drop.position = Vector2(player.global_position.x + (i - 2) * 140.0 + _rng.randf_range(-30, 30), global_position.y - 560.0)
				drop.delay = 0.5 + i * 0.25
				get_parent().add_child(drop)
			_stun(1.2)
		"summon":
			for i in 2:
				var minion := Shroom.new()
				minion.game = game
				minion.skin = SkinBook.walker(kind)
				minion.position = position + Vector2((i * 2 - 1) * 120.0, -40.0)
				get_parent().add_child(minion)
			_stun(0.9)
		"dive":
			state = "high"
			_timer = 1.4
		"burrow":
			state = "under"
			_timer = 1.6
			FX.dust(get_parent(), global_position, 10)
			AudioManager.play_sfx("rumble", 0.8)


func _throw(player: Node2D, i: int) -> void:
	var ball := Projectile.new()
	ball.kind = kind
	ball.position = position + Vector2(facing * 60.0, -float(_cfg.size.y) * 0.8)
	var dx := player.global_position.x - ball.position.x
	ball.velocity = Vector2(clampf(dx * 0.9, -700, 700) + (i - 1) * 110.0, -620.0 - i * 60.0)
	get_parent().add_child(ball)
	AudioManager.play_sfx("cannon", 1.4, -6.0)


func _land_slam() -> void:
	AudioManager.play_sfx("thud")
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(9.0)
	for dir in [-1.0, 1.0]:
		var wave := Shockwave.new()
		wave.dir = dir
		wave.position = position + Vector2(dir * 60.0, 0)
		get_parent().add_child(wave)
	_stun(1.1)


func _stun(time: float) -> void:
	state = "stunned"
	_timer = time
	velocity.x = 0.0


func _touch(player: Node) -> void:
	var top := global_position.y - float(_cfg.size.y) + 14.0    # a big head: a little more forgiving
	if player.is_stomping(top):
		player.stomp_bounce()
		player.velocity.y = -980.0
		take_hit()
	elif player.dashing > 0.0 and state == "stunned":
		take_hit()
	else:
		player.take_hit(global_position.x)


## A stomp, or Pilo's pounce (he calls defeat on enemies).
func defeat() -> void:
	take_hit()


func take_hit() -> void:
	if is_freed or _invulnerable > 0.0 or state == "under":
		return
	hp -= 1
	_invulnerable = 1.2
	AudioManager.play_sfx("stomp", 0.7)
	rig.set("flash", 1.0)
	if game and game.has_method("on_boss_hit"):
		game.on_boss_hit(self)
	if hp <= 0:
		_free()
		return
	state = "hurt"
	_timer = 0.9
	velocity = Vector2(-facing * 300.0, -400.0)


func _free() -> void:
	is_freed = true
	state = "free"
	rig.state = "free"
	collision_layer = 0
	_hurtbox.set_deferred("monitoring", false)
	AudioManager.play_sfx("free")
	AudioManager.play_sfx("win", 1.0, -4.0)
	var tween := create_tween()
	tween.tween_property(rig, "freed_amount", 1.0, 1.4)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != self and enemy.has_method("defeat"):
			enemy.defeat()
	if game and game.has_method("on_boss_freed"):
		game.on_boss_freed(self)


## Thrown things: an arc that hurts on touch and breaks on the ground.
class Projectile extends Area2D:
	var kind := "forest"
	var velocity := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 3
		z_index = 5
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		add_child(shape)
		body_entered.connect(_hit)

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += 1300.0 * delta
		position += velocity * delta
		rotation += delta * 8.0
		if _t > 4.0:
			queue_free()
		queue_redraw()

	func _hit(body: Node) -> void:
		if body.is_in_group("player"):
			body.take_hit(global_position.x)
		FX.burst(get_parent(), global_position, SkinBook.accent(kind), 8)
		queue_free()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 20.0, Color("3b2418"))
		draw_circle(Vector2.ZERO, 17.0, SkinBook.accent(kind))
		draw_circle(Vector2(-5, -6), 5.0, Color(1, 1, 1, 0.5))


## Things falling from the sky (icicles, crystals, coconuts): a shadow warns first.
class Falling extends Area2D:
	var kind := "forest"
	var delay := 0.5
	var _v := 0.0
	var _ground := 0.0
	var _armed := false

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 3
		z_index = 5
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(26, 40)
		shape.shape = rect
		add_child(shape)
		body_entered.connect(_hit)
		var space := get_world_2d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 1600), 1))
		_ground = hit.position.y if not hit.is_empty() else global_position.y + 900.0

	func _physics_process(delta: float) -> void:
		delay -= delta
		if delay <= 0.0:
			_armed = true
			_v += 2400.0 * delta
			position.y += _v * delta
			if global_position.y >= _ground - 20.0:
				FX.debris(get_parent(), global_position, SkinBook.accent(kind), 4)
				AudioManager.play_sfx_once("brick", 0.2, 1.3, -6.0)
				queue_free()
		queue_redraw()

	func _hit(body: Node) -> void:
		if _armed and body.is_in_group("player"):
			body.take_hit(global_position.x)

	func _draw() -> void:
		var shadow_y := _ground - global_position.y
		draw_circle(Vector2(0, shadow_y), 22.0 * (0.4 + 0.6 * clampf(1.0 - delay, 0.0, 1.0)), Color(0, 0, 0, 0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(0, 26)]), Color("3b2418"))
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -19), Vector2(10, -19), Vector2(0, 19)]), SkinBook.accent(kind))


## The ground wave after a slam: jump over it.
class Shockwave extends Area2D:
	var dir := 1.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		z_index = 5
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 30)
		shape.shape = rect
		shape.position = Vector2(0, -15)
		add_child(shape)
		body_entered.connect(func(b): if b.is_in_group("player"): b.take_hit(global_position.x - dir * 10.0))

	func _physics_process(delta: float) -> void:
		_t += delta
		position.x += dir * 520.0 * delta
		if _t > 1.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var x := -dir * i * 14.0
			draw_arc(Vector2(x, 0), 24.0 - i * 5.0, PI, TAU, 10, Color(1, 0.85, 0.5, 0.8 - i * 0.25), 6.0)
