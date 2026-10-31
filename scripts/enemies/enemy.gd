class_name Enemy
extends CharacterBody2D
## A shadow creature. Nothing dies in this game: stomping it, a dash, a bumped block or
## Pilo's attack *frees* it — the shadow lifts, it turns back to its real colours, hops
## happily and leaves a coin. Touching it any other way costs Nima a heart.
## Origin = middle of the feet. Each kind draws itself with its own CharacterRig.

const GRAVITY := 2000.0

var game: Node
var body_size := Vector2(48, 44)
var stompable := true
var speed := 70.0
var facing := -1.0
var freed := false
var coins := 1
var skin := ""                  ## the look for this world (SkinBook); "" = the forest look
var rig: EnemyRig

var _hurtbox: Area2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	z_index = 3
	add_to_group("enemy")
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
	hit_rect.size = body_size - Vector2(8, 4)
	hit_shape.shape = hit_rect
	hit_shape.position = Vector2(0, -body_size.y * 0.5)
	_hurtbox.add_child(hit_shape)
	add_child(_hurtbox)
	var art := "enemy_" + art_name()
	if PaintedCreature.available(art):
		rig = PaintedCreature.make(art, body_size.y * 1.35, art_motion())
	else:
		rig = make_rig()
	rig.skin = skin
	add_child(rig)


## Override: the drawing for this kind.
func make_rig() -> EnemyRig:
	return EnemyRig.new()


## The creature's name in the generated art (enemy_<name>_shadow.png / _free.png).
func art_name() -> String:
	return skin if skin != "" else "shroom"


## How the generated picture moves: "walk", "fly" or "roll".
func art_motion() -> String:
	return "walk"


## Override: movement for one physics step.
func move(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if freed:
		return
	move(delta)
	rig.scale.x = facing
	for body in _hurtbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			touch_player(body)


func top_y() -> float:
	return global_position.y - body_size.y


func touch_player(player: Node) -> void:
	if freed:
		return
	if player.is_stomping(top_y()):
		player.stomp_bounce()
		if stompable:
			defeat()
			AudioManager.play_sfx("stomp")
		else:
			player.take_hit(global_position.x)
	elif player.dashing > 0.0 and stompable:
		defeat("dash")
	else:
		player.take_hit(global_position.x)


## Defeats the creature. A stomp flattens it and it vanishes in a puff of smoke; a shot,
## Pilo or a dash knock it over and it tumbles off the screen.
func defeat(how := "stomp") -> void:
	if freed:
		return
	freed = true
	collision_layer = 0
	collision_mask = 0
	_hurtbox.set_deferred("monitoring", false)
	AudioManager.play_sfx("stomp" if how == "stomp" else "impact", randf_range(0.95, 1.1), -2.0 if how == "stomp" else -6.0)
	if game and game.has_method("on_enemy_freed"):
		game.on_enemy_freed(self)
	if how == "stomp":
		var tween := create_tween()
		tween.tween_property(rig, "squash", 1.0, 0.08)
		tween.tween_interval(0.22)
		tween.tween_callback(func():
			FX.dust_ring(get_parent(), global_position, 0.6, Color(0.9, 0.9, 0.95, 0.8))
			FX.burst(get_parent(), global_position + Vector2(0, -16), Color(0.95, 0.95, 1.0), 10))
		tween.tween_property(self, "modulate:a", 0.0, 0.12)
		tween.tween_callback(queue_free)
	else:
		# knocked over: flips, pops up and falls away
		var knock := Knockout.new()
		knock.enemy = self
		knock.velocity = Vector2(signf(global_position.x - (game.player.global_position.x if game and game.player else 0.0)) * 220.0, -620.0)
		add_child(knock)


## Moves a knocked-out creature: it spins upside down and falls out of the level.
class Knockout extends Node:
	var enemy: Node2D
	var velocity := Vector2.ZERO
	var t := 0.0

	func _physics_process(delta: float) -> void:
		t += delta
		velocity.y += 1800.0 * delta
		enemy.position += velocity * delta
		enemy.rotation = lerpf(enemy.rotation, PI, minf(1.0, delta * 8.0))
		enemy.modulate.a = clampf(2.0 - t, 0.0, 1.0)
		if t > 2.0:
			enemy.queue_free()


## Is there floor just ahead of the feet? (walkers turn at ledges)
func ground_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var x := global_position.x + facing * (body_size.x * 0.5 + 6.0)
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 6.0), Vector2(x, global_position.y + 26.0), 1)
	return not space.intersect_ray(query).is_empty()


func walk(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 1000.0)
	velocity.x = facing * speed
	move_and_slide()
	if is_on_wall():
		facing = -facing
	elif is_on_floor() and not ground_ahead():
		facing = -facing
