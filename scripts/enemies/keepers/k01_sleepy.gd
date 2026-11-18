class_name KeeperSleepy
extends Keeper
## K1 «خواب‌آلو» (جوجه‌ریشه): asleep in one time, awake in the other. Asleep it cannot hurt and
## can be hit; awake it rolls at the hero. Its secret: in the time it sleeps, take the key it
## holds without noise (no running or jumping close by). Noise wakes it for a moment.

const K1 := "res://assets/art/p5_enemies/k1/"

var awake_in: int = TimeShift.PAST
var noise_radius := 260.0
var _wake := 0.0
var _home := Vector2.ZERO
var _attack := 0.0


func setup() -> void:
	type = "K1"
	body_size = Vector2(90, 96)
	art_height = 150.0
	art = {
		"sleep": K1 + "k1_idle_sleep.png", "idle": K1 + "k1_alert.png", "alert": K1 + "k1_alert.png",
		"tell": K1 + "k1_tell.png", "attack": K1 + "k1_attack_roll.png", "vulnerable": K1 + "k1_vulnerable.png",
		"hurt": K1 + "k1_hurt.png", "released": K1 + "k1_released.png",
	}
	awake_in = TimeShift.state_from_name(String(params.get("awake_in", "past")))
	_home = position
	state = "sleep" if asleep() else "alert"


func asleep() -> bool:
	return TimeShift.state != awake_in and _wake <= 0.0


func harmful() -> bool:
	return not asleep()


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return asleep()


func keeper_process(delta: float) -> void:
	_wake = maxf(0.0, _wake - delta)
	var h := hero()
	if asleep():
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if state != "sleep" and state != "hurt" or (state == "hurt" and _state_time > 0.5):
			set_state("sleep")
		if held_key and is_instance_valid(held_key):
			held_key.held_by = null
		if h and hero_distance() < noise_radius and _noisy(h):
			_wake = 2.5
			if held_key and is_instance_valid(held_key):
				held_key.held_by = self
			register_fail()
			set_state("alert")
			AudioManager.play_sfx("bump", 0.7, -4.0)
		return
	if held_key and is_instance_valid(held_key):
		held_key.held_by = self
	# awake: watch, wind up, roll at the hero, roll back home
	match state:
		"tell":
			velocity.x = 0.0
			if _state_time > 0.6:
				set_state("attack")
				_attack = 1.0
		"attack":
			_attack -= delta
			velocity.x = facing * 430.0
			if _attack <= 0.0 or is_on_wall():
				set_state("alert")
		_:
			if state != "alert":
				set_state("alert")
			if h and hero_distance() < 340.0 and _state_time > 1.0:
				facing = signf(h.global_position.x - global_position.x)
				set_state("tell")
			else:
				walk_toward(_home.x, 90.0)


## Running, dashing or landing from a jump makes noise; walking softly does not.
func _noisy(h: Node2D) -> bool:
	var v: Vector2 = h.get("velocity") if h.get("velocity") != null else Vector2.ZERO
	return absf(v.x) > 330.0 or h.get("dashing") > 0.0 or (v.y < -200.0)
