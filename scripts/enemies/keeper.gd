class_name Keeper
extends CharacterBody2D
## «پاسدار» (T6): every normal level has one. A keeper holds one of the two time keys and has a
## secret: until the hero understands it, it cannot be beaten. Nothing is killed: when its hits
## run out (or its secret is solved) the keeper is released (light, butterflies, happy pose) and
## lets go of the key. After three failures in a row it gives a free hint (8-15 year olds).
##
## Subclasses (scripts/enemies/keepers/k01..k12) decide when a hit counts (`can_be_hurt`) and add
## their own behaviour (`keeper_process`). Hits come from a stomp, a shot, Pilo or a dash
## (`receive_hit`), so weapons and companions work on keepers like on any creature.
## Origin = middle of the feet.

signal hit(hits_left: int)
signal exposed
signal defeated(key_drop: Node)

const GRAVITY := 2000.0
const FAILS_FOR_HINT := 3

var type := "K1"
var keeper_id := ""
var game: Node
var hits_needed := 3              ## chapters 1-2: three hits (content/06 §4)
var hits := 0
var freed := false
var fails := 0
var hint_shown := false
var hint_key := ""                ## strings_fa.json key of the free hint
var held_key: Node = null         ## the TimeKey this keeper guards
var body_size := Vector2(96, 120)
var art_height := 170.0
var facing := -1.0
## state -> texture path; subclasses fill it ("idle", "alert", "tell", "attack", "vulnerable",
## "hurt", "released", ...). A missing state falls back to "idle".
var art := {}
var state := "idle"
var params: Dictionary = {}       ## the level's keeper entry (extra fields per type)

var _sprite: Sprite2D
var _textures := {}
var _hurtbox: Area2D
var _flash := 0.0
var _invulnerable := 0.0
var _state_time := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 3
	add_to_group("enemy")
	add_to_group("keeper")
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
	hit_rect.size = body_size - Vector2(10, 6)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(0, -body_size.y * 0.5)
	_hurtbox.add_child(hit_shape)
	add_child(_hurtbox)
	# a soft round shadow under the feet (drawn here, never in the picture)
	var shadow := Shadow.new()
	shadow.width = body_size.x * 1.1
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.centered = true
	add_child(_sprite)
	setup()
	set_state(state)
	if held_key:
		held_key.held_by = self


## Override: textures, sizes, starting state.
func setup() -> void:
	pass


## Override: does this hit count? `how` = "stomp", "shot", "pilo", "dash".
func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return true


## Override: behaviour every physics step (while not freed).
func keeper_process(_delta: float) -> void:
	pass


## Override: called when a hit was refused (e.g. a shot on the shield).
func on_blocked(_how: String, _from: Vector2) -> void:
	register_fail()
	AudioManager.play_sfx("bump", 1.3, -4.0)


func set_state(new_state: String) -> void:
	state = new_state
	_state_time = 0.0
	var path: String = art.get(new_state, art.get("idle", ""))
	if path == "":
		return
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	var tex: Texture2D = _textures[path]
	if tex == null:
		return
	_sprite.texture = tex
	var s := art_height / float(tex.get_height())
	_sprite.scale = Vector2(s * (-1.0 if facing < 0 else 1.0) * art_flip(), s)
	_sprite.position = Vector2(0, -art_height * 0.5 + 4.0)


## Pictures face right; facing left flips them (1 = keep, -1 = the art faces left).
func art_flip() -> float:
	return 1.0


func _physics_process(delta: float) -> void:
	if freed:
		return
	_state_time += delta
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_flash = maxf(0.0, _flash - delta * 3.0)
	_sprite.modulate = Color(1.0 + _flash, 1.0 + _flash, 1.0 + _flash)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1000.0)
	keeper_process(delta)
	move_and_slide()
	if _sprite.texture:
		var s := absf(_sprite.scale.y)
		_sprite.scale.x = s * (-1.0 if facing < 0 else 1.0) * art_flip()
	for body in _hurtbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			touch_player(body)


func top_y() -> float:
	return global_position.y - body_size.y


func hero() -> Node2D:
	return game.player if game and is_instance_valid(game.get("player")) else null


func touch_player(player: Node) -> void:
	if freed:
		return
	if player.is_stomping(top_y()):
		player.stomp_bounce()
		receive_hit("stomp", player.global_position)
	elif player.dashing > 0.0:
		receive_hit("dash", player.global_position)
	elif harmful():
		player.take_hit(global_position.x)
		register_fail()


## Override: touching it hurts (most keepers; a sleeping one does not).
func harmful() -> bool:
	return true


## Pilo, companions and blocks call defeat() on every creature: for a keeper it is one hit.
func defeat(how := "stomp") -> void:
	var from := hero().global_position if hero() else global_position
	receive_hit(how, from)


## A hit from the hero's side. Returns true when it counted.
func receive_hit(how: String, from: Vector2) -> bool:
	if freed or _invulnerable > 0.0:
		return false
	if not can_be_hurt(how, from):
		on_blocked(how, from)
		return false
	hits += 1
	fails = 0
	_invulnerable = 0.6
	_flash = 1.0
	AudioManager.play_sfx("stomp", 0.8)
	hit.emit(hits_needed - hits)
	if game and game.has_method("on_keeper_hit"):
		game.on_keeper_hit(self)
	if hits >= hits_needed:
		release()
	else:
		set_state("hurt")
	return true


## One more failure in a row; the third gives the free hint.
func register_fail() -> void:
	fails += 1
	if fails >= FAILS_FOR_HINT and not hint_shown:
		reveal_hint()


func reveal_hint() -> void:
	hint_shown = true
	if game and game.has_method("on_keeper_hint"):
		game.on_keeper_hint(self)


## Released: the shadow lifts, it smiles, the key it held is free.
func release() -> void:
	if freed:
		return
	freed = true
	collision_layer = 0
	_hurtbox.set_deferred("monitoring", false)
	set_state("released")
	ReleaseFX.spawn(get_parent(), global_position + Vector2(0, -body_size.y * 0.6), 7)
	AudioManager.play_sfx("free")
	var key := held_key
	if key and is_instance_valid(key):
		key.held_by = null
		# the key floats out in front of the keeper, where the hero can take it
		var tween := key.create_tween()
		tween.tween_property(key, "global_position", global_position + Vector2(-facing * 90.0, -60.0), 0.5).set_ease(Tween.EASE_OUT)
	defeated.emit(key)
	if game and game.has_method("on_keeper_released"):
		game.on_keeper_released(self)
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)


## Sends the keeper toward x at `speed` (walking on the floor), facing that way.
func walk_toward(x: float, speed: float) -> void:
	var d := x - global_position.x
	if absf(d) < 6.0:
		velocity.x = 0.0
		return
	facing = signf(d)
	velocity.x = facing * speed


## Distance to the hero (INF if there is none).
func hero_distance() -> float:
	return global_position.distance_to(hero().global_position) if hero() else INF


class Shadow extends Node2D:
	var width := 100.0

	func _ready() -> void:
		z_index = -1
		show_behind_parent = true

	func _draw() -> void:
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, width * 0.5, Color(0, 0, 0, 0.28))
