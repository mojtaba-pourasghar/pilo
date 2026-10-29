class_name SpikyHog
extends Enemy
## «خارپشت سایه»: its shadow spikes hurt from above and from the side, so neither a stomp
## nor a dash works. Free it with Pilo's attack or by bumping the block it stands on.
## Teaches the child to use Pilo.


func _init() -> void:
	body_size = Vector2(54, 40)
	speed = 55.0
	stompable = false
	coins = 2


func make_rig() -> EnemyRig:
	return Rig.new()


func move(delta: float) -> void:
	walk(delta)


func touch_player(player: Node) -> void:
	if freed:
		return
	if player.dashing > 0.0 and player.dash_frees_spiky:
		defeat()
		AudioManager.play_sfx("stomp", 1.2)
		return
	if player.is_stomping(top_y()):
		player.stomp_bounce()
	player.take_hit(global_position.x)


class Rig extends EnemyRig:
	const BODY_SHADOW := Color("4d3a62")
	const BODY_REAL := Color("b9824f")
	const SPIKE_SHADOW := Color("2a1c3c")
	const SPIKE_REAL := Color("7a4e2c")
	const FACE := Color("f1d3ae")

	func target_pose(delta: float) -> Dictionary:
		phase += delta * 8.0
		return {"step": sin(phase)}

	func _draw() -> void:
		if skin != "" and skin != "hog":
			SkinBook.draw_spiky(self, skin, p("step"))
			return
		var step := p("step")
		for side in [-1.0, 1.0]:
			var lift := maxf(0.0, step * side) * 4.0
			ellipse(Vector2(side * 13.0, -4.0 - lift), Vector2(7, 4.5), Color("4a2e1a"))
		var spike := mixc(SPIKE_SHADOW, SPIKE_REAL)
		var c := Vector2(-4, -20)
		# spikes fan over the back
		for i in 9:
			var a := PI + 0.15 + i * (PI * 0.9 / 8.0)
			var dir := Vector2(cos(a), sin(a))
			var base := c + dir * 18.0
			var tip := c + dir * (32.0 + (3.0 if i % 2 == 0 else 0.0))
			shape(PackedVector2Array([base + dir.orthogonal() * 7.0, tip, base - dir.orthogonal() * 7.0]), spike)
		ellipse(c, Vector2(26, 19), mixc(BODY_SHADOW, BODY_REAL))
		# face
		ellipse(c + Vector2(18, 4), Vector2(14, 12), FACE)
		draw_circle(c + Vector2(31, 3), 4.0, OUTLINE)
		angry_eyes(c + Vector2(17, -1), c + Vector2(25, -1), 3.6)
		draw_wisps(c + Vector2(0, -26), 20.0)
