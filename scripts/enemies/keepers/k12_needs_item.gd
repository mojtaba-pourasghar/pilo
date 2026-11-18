class_name KeeperNeedsItem
extends Keeper
## K12 «وابسته» (قارچ‌شاه): it gives its key only for something that exists in one time — here a
## glowing mushroom that grows only in the past. Pick it there, switch to the present and bring
## it. It cannot be hit; close by it hops and puffs spores (a hit).

const ART := "res://assets/art/p5_enemies/p5_concept_ch01_thorn_mushroom_"

var needs := "glow_mushroom"
var _home := Vector2.ZERO


func setup() -> void:
	type = "K12"
	body_size = Vector2(96, 96)
	art_height = 150.0
	art = {"idle": ART + "idle.png", "tell": ART + "attack.png", "attack": ART + "attack.png",
		"hurt": ART + "idle.png", "released": ART + "released.png"}
	needs = String(params.get("needs", "glow_mushroom"))
	_home = position


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return false


func harmful() -> bool:
	return state == "attack"


func keeper_process(_delta: float) -> void:
	velocity.x = 0.0
	if game and game.get("carrying") == needs and hero_distance() < 170.0:
		game.give_item(needs)
		hits = hits_needed
		release()
		return
	match state:
		"tell":
			if _state_time > 0.6:
				set_state("attack")
				velocity.y = -520.0
		"attack":
			if _state_time > 0.5 and is_on_floor():
				set_state("idle")
		_:
			if hero() and hero_distance() < 200.0 and _state_time > 1.4:
				facing = signf(hero().global_position.x - global_position.x)
				set_state("tell")


## The thing a K12 needs, lying in one time only. Taken in its own time, carried to the other.
class CarryItem extends Area2D:
	const ART := "res://assets/art/p7_living/p7_living_ch01_glow_mushroom_f1.png"
	var id := "glow_mushroom"
	var item_time: int = TimeShift.PAST
	var game: Node
	var _tex: Texture2D
	var _t := 0.0

	func time_mask() -> int:
		return 1 if item_time == TimeShift.PAST else 2

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		add_to_group("carry_item")
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 34.0
		shape.shape = c
		add_child(shape)
		_tex = load(ART) if ResourceLoader.exists(ART) else null
		body_entered.connect(func(b):
			if b.is_in_group("player"):
				_try())

	func _physics_process(_delta: float) -> void:
		for b in get_overlapping_bodies():
			if b.is_in_group("player"):
				_try()

	func _try() -> void:
		if TimeShift.state != item_time or game == null or game.get("carrying") == id:
			return
		game.take_item(id)
		queue_free()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2(0, -6), 34.0 + sin(_t * 3.0) * 4.0, Color(0.6, 1.0, 0.9, 0.3))
		if _tex:
			var s := 70.0 / maxf(_tex.get_width(), _tex.get_height())
			var size := _tex.get_size() * s
			draw_texture_rect(_tex, Rect2(Vector2(-size.x * 0.5, -size.y * 0.5 - 6.0), size), false)
