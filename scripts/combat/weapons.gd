class_name Weapons
extends RefCounted
## Nima's shooting tools. The slingshot is his from the start; the others come from the
## village (coins, diamonds, or one bought with real money). They are not in the backpack
## slots: every owned weapon can be picked with the swap button, the fire button shoots it.
##
##   slingshot   acorns in a short arc
##   bubble      a slow bubble that traps a creature and pops it
##   boomerang   flies out and comes back, through every creature on its way
##   fire_staff  a fireball that bounces along the ground and breaks bricks and cracked walls
##   star_blaster  three stars in a fan (bought with real money)

const LIST := {
	"slingshot": {"name": "تیرکمان", "cooldown": 0.32, "speed": 950.0, "gravity": 650.0, "life": 1.2},
	"bubble": {"name": "تفنگ حبابی", "cooldown": 0.55, "speed": 430.0, "gravity": -40.0, "life": 1.8},
	"boomerang": {"name": "بومرنگ", "cooldown": 0.8, "speed": 820.0, "gravity": 0.0, "life": 2.5},
	"fire_staff": {"name": "عصای آتش", "cooldown": 0.45, "speed": 640.0, "gravity": 1400.0, "life": 2.2},
	"star_blaster": {"name": "ستاره‌پران", "cooldown": 0.4, "speed": 1100.0, "gravity": 0.0, "life": 0.9},
}


static func owned() -> Array:
	var out: Array = []
	for id in LIST:
		if id == "slingshot" or Loadout.owns_tool(id):
			out.append(id)
	return out


static func current() -> String:
	var id := String(SaveManager.data.get("weapon", "slingshot"))
	return id if owned().has(id) else "slingshot"


## Picks the next owned weapon; returns it.
static func next() -> String:
	var list := owned()
	var i := list.find(current())
	var id: String = list[(i + 1) % list.size()]
	SaveManager.data.weapon = id
	return id


static func pick(id: String) -> void:
	if owned().has(id):
		SaveManager.data.weapon = id
		SaveManager.save_game()


## Fires the current weapon from `shooter` (the player). Returns false while cooling down.
static func fire(shooter: Node2D, facing: float) -> Array:
	var id := current()
	var cfg: Dictionary = LIST[id]
	var shots: Array = []
	var angles := [0.0] if id != "star_blaster" else [-0.18, 0.0, 0.18]
	for a in angles:
		var shot := Shot.new()
		shot.kind = id
		shot.owner_node = shooter
		var dir := Vector2(facing, 0).rotated(a * facing)
		shot.velocity = dir * float(cfg.speed) + (Vector2(0, -150) if id == "slingshot" else Vector2.ZERO)
		shot.fall = float(cfg.gravity)
		shot.life = float(cfg.life)
		shot.position = shooter.global_position + Vector2(facing * 34.0, -6.0)
		shooter.get_parent().add_child(shot)
		shots.append(shot)
	return shots


## A shot in flight.
class Shot extends Area2D:
	var kind := "slingshot"
	var velocity := Vector2.ZERO
	var fall := 0.0
	var life := 1.2
	var owner_node: Node2D
	var _t := 0.0
	var _bounces := 0
	var _returning := false
	var _hit: Array = []
	var _trapped: Node2D

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1 | 4
		z_index = 6
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0 if kind != "bubble" else 22.0
		shape.shape = circle
		add_child(shape)
		body_entered.connect(_on_body)
		if kind == "fire_staff" or kind == "star_blaster":
			var trail := CPUParticles2D.new()
			trail.texture = FX.soft()
			trail.amount = 18
			trail.lifetime = 0.3
			trail.local_coords = false
			trail.scale_amount_min = 0.3
			trail.scale_amount_max = 0.6
			trail.color = Color(1, 0.6, 0.2, 0.7) if kind == "fire_staff" else Color(1, 0.95, 0.5, 0.7)
			var add := CanvasItemMaterial.new()
			add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			trail.material = add
			add_child(trail)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _trapped:
			# a trapped creature floats up in the bubble, then it pops
			_trapped.global_position = global_position + Vector2(0, 20)
			position.y -= 60.0 * delta
			if _t > 0.6:
				_pop_trap()
			queue_redraw()
			return
		if kind == "boomerang":
			if not _returning and _t > 0.45:
				_returning = true
			if _returning and is_instance_valid(owner_node):
				var to := owner_node.global_position + Vector2(0, -30) - global_position
				velocity = velocity.lerp(to.normalized() * 900.0, 1.0 - exp(-8.0 * delta))
				if to.length() < 40.0:
					queue_free()
					return
		else:
			velocity.y += fall * delta
		if kind == "fire_staff":
			# bounce along the ground
			var space := get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 18), 1)
			if velocity.y > 0.0 and not space.intersect_ray(query).is_empty():
				velocity.y = -520.0
				_bounces += 1
				if _bounces > 4:
					_burst()
					return
		position += velocity * delta
		if _t > life:
			_burst()
			return
		queue_redraw()

	func _on_body(body: Node) -> void:
		if body == owner_node or _hit.has(body):
			return
		if body is Enemy:
			if body.freed:
				return
			_hit.append(body)
			if kind == "bubble":
				_trap(body)
				return
			body.defeat("shot")
			Juice.hit(body, global_position, 0.25)
			if kind != "boomerang" and kind != "star_blaster":
				_burst()
			return
		if body is Boss:
			_hit.append(body)
			body.take_shot(0.5 if kind == "fire_staff" else 0.34)
			_burst()
			return
		if kind == "fire_staff":
			if body is Block and body.kind == Block.Kind.BRICK:
				body.smash()
				_burst()
				return
			if body.is_in_group("breakable") and body.has_method("smash"):
				body.smash()
				_burst()
				return
		if kind == "boomerang":
			_returning = true
			return
		if kind == "fire_staff":
			# the floor only bounces it; a wall in front puts it out
			var space := get_world_2d().direct_space_state
			var ahead := Vector2(signf(velocity.x) * 22.0, 0)
			var query := PhysicsRayQueryParameters2D.create(global_position, global_position + ahead, 1)
			if space.intersect_ray(query).is_empty():
				return
		_burst()

	func _trap(enemy: Node2D) -> void:
		_trapped = enemy
		_t = 0.0
		enemy.set_physics_process(false)
		velocity = Vector2.ZERO
		AudioManager.play_sfx("pop", 0.8)

	func _pop_trap() -> void:
		if is_instance_valid(_trapped):
			_trapped.set_physics_process(true)
			_trapped.defeat("shot")
		AudioManager.play_sfx("pop", 1.3)
		FX.burst(get_parent(), global_position, Color(0.75, 0.92, 1.0), 12)
		queue_free()

	func _burst() -> void:
		var color := {"slingshot": Color("b07a45"), "bubble": Color(0.75, 0.92, 1.0), "boomerang": Color("f39a2b"),
			"fire_staff": Color(1.0, 0.55, 0.15), "star_blaster": Color(1, 0.9, 0.4)}
		FX.burst(get_parent(), global_position, color.get(kind, Color.WHITE), 6)
		queue_free()

	func _draw() -> void:
		match kind:
			"slingshot":
				# an acorn
				draw_circle(Vector2.ZERO, 9.0, Color("3b2418"))
				draw_circle(Vector2.ZERO, 7.0, Color("b07a45"))
				draw_rect(Rect2(-8, -11, 16, 6), Color("6b4a2e"))
				draw_circle(Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.5))
			"bubble":
				var r := 22.0 + sin(_t * 9.0) * 1.5
				draw_circle(Vector2.ZERO, r, Color(0.7, 0.9, 1.0, 0.25))
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.85, 0.97, 1.0, 0.9), 2.5)
				draw_circle(Vector2(-8, -8), 5.0, Color(1, 1, 1, 0.8))
			"boomerang":
				draw_set_transform(Vector2.ZERO, _t * 22.0)
				for s in [-1.0, 1.0]:
					var pts := PackedVector2Array([Vector2(0, 0), Vector2(s * 22, -10), Vector2(s * 24, -4), Vector2(s * 6, 6)])
					draw_colored_polygon(pts, Color("f39a2b"))
					draw_polyline(pts + PackedVector2Array([pts[0]]), Color("7a3a10"), 2.0)
				draw_set_transform(Vector2.ZERO)
			"fire_staff":
				var flicker := 1.0 + sin(_t * 40.0) * 0.1
				draw_circle(Vector2.ZERO, 18.0 * flicker, Color(1, 0.5, 0.1, 0.35))
				draw_circle(Vector2.ZERO, 12.0 * flicker, Color(1, 0.6, 0.15))
				draw_circle(Vector2.ZERO, 6.0, Color(1, 0.95, 0.7))
			"star_blaster":
				var star := PackedVector2Array()
				for i in 10:
					var rr := 14.0 if i % 2 == 0 else 6.0
					var a := i * PI / 5.0 + _t * 12.0
					star.append(Vector2(cos(a), sin(a)) * rr)
				draw_colored_polygon(star, Color(1, 0.9, 0.35))
