class_name KeeperShield
extends Keeper
## K2 «آینه‌دار» (سنگ‌بالک): its stone shield faces the hero and sends shots back. Its secret:
## hit it from behind or from above (jump over it while it turns slowly).

const ART := "res://assets/art/p5_enemies/p5_concept_ch01_stone_guard_"

var turn_delay := 1.0
var _turn := 0.0
var _home := Vector2.ZERO


func setup() -> void:
	type = "K2"
	body_size = Vector2(96, 120)
	art_height = 165.0
	art = {"idle": ART + "idle.png", "tell": ART + "attack.png", "attack": ART + "attack.png",
		"hurt": ART + "idle.png", "released": ART + "released.png"}
	_home = position


func can_be_hurt(how: String, from: Vector2) -> bool:
	if how == "stomp":
		return true
	# from behind: the hero is on the side the shield does not face
	return signf(from.x - global_position.x) != facing


func on_blocked(how: String, from: Vector2) -> void:
	super.on_blocked(how, from)
	FX.burst(get_parent(), global_position + Vector2(facing * 50.0, -70.0), Color(0.85, 0.9, 1.0), 10)


func keeper_process(delta: float) -> void:
	var h := hero()
	if h == null:
		return
	var want := signf(h.global_position.x - global_position.x)
	if want != 0.0 and want != facing:
		_turn += delta
		if _turn >= turn_delay:
			facing = want
			_turn = 0.0
	else:
		_turn = 0.0
	match state:
		"tell":
			velocity.x = 0.0
			if _state_time > 0.5:
				set_state("attack")
		"attack":
			velocity.x = facing * 360.0
			if _state_time > 0.45 or is_on_wall():
				set_state("idle")
		_:
			if state != "idle" and _state_time > 0.4:
				set_state("idle")
			velocity.x = sin(Time.get_ticks_msec() * 0.0012) * 50.0 if absf(global_position.x - _home.x) < 160.0 else signf(_home.x - global_position.x) * 60.0
			if hero_distance() < 230.0 and want == facing and _state_time > 1.2:
				set_state("tell")
