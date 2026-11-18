class_name KeeperHider
extends Keeper
## K8 «پنهان‌شو» (ماهی‌کش): hides in water, dark or cloud. Hidden it cannot be touched or hit.
## Its secret: light — Pilo's glow (the companion button nearby), the lantern or a mirror — draws
## it out for a few seconds; then it can be hit.

const ART := "res://assets/art/p5_enemies/p5_concept_ch01_shadow_cat_"
const SHOWN_FOR := 6.0

var in_hiding := true
var _shown := 0.0
var _home := Vector2.ZERO


func setup() -> void:
	type = "K8"
	body_size = Vector2(90, 80)
	art_height = 130.0
	art = {"idle": ART + "idle.png", "tell": ART + "attack.png", "attack": ART + "attack.png",
		"hurt": ART + "idle.png", "released": ART + "released.png"}
	add_to_group("keeper_hidden")
	_home = position


func harmful() -> bool:
	return not in_hiding


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return not in_hiding


## Light nearby (Pilo, lantern, mirror): out of hiding.
func light_reveal() -> void:
	if freed:
		return
	if in_hiding:
		exposed.emit()
		AudioManager.play_sfx("pop")
		FX.burst(get_parent(), global_position + Vector2(0, -50), Color(1.0, 0.95, 0.6), 14)
	in_hiding = false
	_shown = SHOWN_FOR


func keeper_process(delta: float) -> void:
	if in_hiding:
		velocity.x = 0.0
		_sprite.modulate.a = 0.14 + 0.06 * sin(Time.get_ticks_msec() * 0.004)
		return
	_sprite.modulate.a = 1.0
	_shown -= delta
	if _shown <= 0.0:
		in_hiding = true
		set_state("idle")
		position.x = _home.x
		return
	match state:
		"tell":
			velocity.x = 0.0
			if _state_time > 0.5:
				set_state("attack")
		"attack":
			velocity.x = facing * 380.0
			if _state_time > 0.5:
				set_state("idle")
		_:
			velocity.x = 0.0
			if hero() and hero_distance() < 300.0 and _state_time > 1.0:
				facing = signf(hero().global_position.x - global_position.x)
				set_state("tell")
