class_name ShadowBall
extends Enemy
## Shot by a shadow cannon: flies straight, can be stomped, fades when it hits a wall.

var life := 6.0


func _init() -> void:
	body_size = Vector2(40, 36)
	speed = 250.0
	coins = 0


func make_rig() -> EnemyRig:
	return Rig.new()


func move(delta: float) -> void:
	life -= delta
	var hit := move_and_collide(Vector2(facing * speed * delta, 0))
	if hit or life <= 0.0:
		freed = true
		collision_layer = 0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)


class Rig extends EnemyRig:
	func _draw() -> void:
		var c := Vector2(0, -18)
		for i in 3:
			draw_circle(c + Vector2(-16 - i * 10, sin(t * 20.0 + i) * 3.0), 9.0 - i * 2.5, Color(0.3, 0.2, 0.5, 0.4 - i * 0.1))
		ellipse(c, Vector2(19, 17), mixc(Color("3a2a58"), Color("9fd8ff")))
		draw_arc(c + Vector2(-5, -6), 9.0, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.35), 3.0)
		angry_eyes(c + Vector2(4, -2), c + Vector2(12, -2), 4.0)
