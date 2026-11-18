class_name ChapterBoss
extends CharacterBody2D
## «نگهبان فصل» (T7): the guardian at the end of a chapter. It is never killed: its hearts are
## broken one per phase and then it is released. States: intro -> phase1 -> phase2 (+ a short
## flashback halfway) -> phase3 -> released. Every guardian has a reason, a secret and a memory.
## Subclasses give the attacks (`phase_process`) and say when a hit counts (`can_be_hurt`).
## Origin = between the feet.

signal phase_changed(phase: int)
signal released

const GRAVITY := 2000.0
const HITS_PER_HEART := 3

var boss_id := ""
var game: Node
var hearts := 3
var max_hearts := 3
var phase := 0                     ## 0 intro, 1..3, 4 released
var hits_in_heart := 0
var freed := false
var is_freed: bool:
	get:
		return freed
var flashback_played := false
var body_size := Vector2(300, 200)
var facing := -1.0
var params: Dictionary = {}

var _hurtbox: Area2D
var _invulnerable := 0.0
var _phase_time := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 3
	add_to_group("enemy")
	add_to_group("chapter_boss")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y * 0.5)
	add_child(shape)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 2
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = body_size - Vector2(20, 10)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(0, -body_size.y * 0.5)
	_hurtbox.add_child(hit_shape)
	add_child(_hurtbox)
	setup()


func setup() -> void:
	pass


func start() -> void:
	set_phase(1)


func set_phase(p: int) -> void:
	phase = p
	_phase_time = 0.0
	hits_in_heart = 0
	phase_changed.emit(p)
	on_phase(p)


func on_phase(_p: int) -> void:
	pass


func phase_process(_delta: float) -> void:
	pass


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return true


func on_blocked(_how: String, _from: Vector2) -> void:
	AudioManager.play_sfx("bump", 1.2, -4.0)


func harmful() -> bool:
	return phase >= 1 and phase <= 3


func hero() -> Node2D:
	return game.player if game and is_instance_valid(game.get("player")) else null


func _physics_process(delta: float) -> void:
	if freed:
		return
	_phase_time += delta
	_invulnerable = maxf(0.0, _invulnerable - delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	if phase >= 1:
		phase_process(delta)
	move_and_slide()
	for body in _hurtbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			touch_player(body)


func touch_player(player: Node) -> void:
	if player.is_stomping(global_position.y - body_size.y):
		player.stomp_bounce()
		receive_hit("stomp", player.global_position)
	elif harmful():
		player.take_hit(global_position.x)


func defeat(how := "stomp") -> void:
	receive_hit(how, hero().global_position if hero() else global_position)


## Shots on the old Boss interface.
func take_shot(_amount: float) -> void:
	receive_hit("shot", hero().global_position if hero() else global_position)


func receive_hit(how: String, from: Vector2) -> bool:
	if freed or phase < 1 or phase > 3 or _invulnerable > 0.0:
		return false
	if not can_be_hurt(how, from):
		on_blocked(how, from)
		return false
	_invulnerable = 0.5
	hits_in_heart += 1
	on_hit()
	if game and game.has_method("on_chapter_boss_hit"):
		game.on_chapter_boss_hit(self)
	if hits_in_heart >= HITS_PER_HEART:
		hearts -= 1
		if hearts <= 0:
			release()
		else:
			set_phase(phase + 1)
	elif phase == 2 and hits_in_heart == 2 and not flashback_played:
		flashback_played = true
		if game and game.has_method("play_flashback"):
			game.play_flashback(self)
	return true


func on_hit() -> void:
	AudioManager.play_sfx("stomp", 0.7)


func release() -> void:
	if freed:
		return
	freed = true
	phase = 4
	collision_layer = 0
	_hurtbox.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	on_released()
	ReleaseFX.spawn(get_parent(), global_position + Vector2(0, -body_size.y * 0.6), 12)
	AudioManager.play_sfx("free")
	AudioManager.play_sfx("win", 1.0, -4.0)
	released.emit()
	if game and game.has_method("on_chapter_boss_released"):
		game.on_chapter_boss_released(self)


func on_released() -> void:
	pass
