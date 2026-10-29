class_name Shroom
extends Enemy
## «قارچ‌سایه»: a little mushroom under the shadow spell. Walks, turns at walls and ledges.
## Stomp it to free it — then it is a cheerful red mushroom again.


func _init() -> void:
	body_size = Vector2(50, 46)
	speed = 72.0


func make_rig() -> EnemyRig:
	return Rig.new()


func move(delta: float) -> void:
	walk(delta)


class Rig extends EnemyRig:
	const CAP_SHADOW := Color("4a3170")
	const CAP_REAL := Color("e8473a")
	const SPOT_SHADOW := Color("8f78c2")
	const SPOT_REAL := Color("fff3d6")
	const STEM_SHADOW := Color("7d6a99")
	const STEM_REAL := Color("fbe7c8")
	const FOOT := Color("5b3a1f")

	func target_pose(delta: float) -> Dictionary:
		phase += delta * 9.0
		return {"step": sin(phase), "bob": absf(sin(phase)) * 2.0}

	func _draw() -> void:
		if skin != "" and skin != "shroom":
			SkinBook.draw_walker(self, skin, p("step"))
			return
		var step := p("step")
		var bob := -p("bob")
		# feet
		for side in [-1.0, 1.0]:
			var lift := maxf(0.0, step * side) * 5.0
			ellipse(Vector2(side * 11.0 + step * side * 3.0, -5.0 - lift), Vector2(9, 5.5), FOOT)
		# stem / body with the face
		var stem := mixc(STEM_SHADOW, STEM_REAL)
		shape(round_rect_points(Vector2(0, -18 + bob), Vector2(32, 26), 11.0), stem)
		angry_eyes(Vector2(2, -20 + bob), Vector2(13, -20 + bob), 4.6)
		draw_arc(Vector2(8, -11 + bob), 3.0, 0.3 if freed_amount > 0.5 else PI + 0.3, PI - 0.3 if freed_amount > 0.5 else TAU - 0.3, 8, OUTLINE, 2.0)
		# cap
		var cap := mixc(CAP_SHADOW, CAP_REAL)
		var c := Vector2(0, -32 + bob)
		shape(smooth_points([c + Vector2(-30, 6), c + Vector2(-24, -10), c + Vector2(0, -19), c + Vector2(24, -10),
			c + Vector2(30, 6), c + Vector2(0, 9)], 5), cap)
		var spot := mixc(SPOT_SHADOW, SPOT_REAL)
		for s in [[Vector2(-14, -6), 6.0], [Vector2(6, -11), 7.0], [Vector2(20, -1), 4.5], [Vector2(-3, 1), 4.0]]:
			draw_circle(c + s[0], s[1], spot)
		draw_arc(c + Vector2(-6, -6), 14.0, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, 0.35), 3.0)
		draw_wisps(Vector2(0, -50), 18.0)
