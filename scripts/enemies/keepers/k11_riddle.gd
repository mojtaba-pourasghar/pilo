class_name KeeperRiddle
extends Keeper
## K11 «معمایی» (پیرمرد برگی): asks a riddle when the hero comes close; the answer is on the signs
## of the past. Two answers (the two choice buttons of the dialogue design). A wrong answer is a
## small hit; the right one releases him. He cannot be hit.

const ART := "res://assets/art/p5_enemies/p5_concept_ch01_stump_"

var question_key := ""
var answer_keys: Array = []
var correct := 0
var _cooldown := 0.0
var asking := false


func setup() -> void:
	type = "K11"
	body_size = Vector2(100, 130)
	art_height = 180.0
	art = {"idle": ART + "idle.png", "tell": ART + "attack.png", "hurt": ART + "idle.png", "released": ART + "released.png"}
	question_key = String(params.get("question_key", ""))
	answer_keys = params.get("answer_keys", [])
	correct = int(params.get("correct", 0))
	modulate = Color(0.9, 1.08, 0.85)    # greener than the K4 stump until his own art comes


func harmful() -> bool:
	return false


func can_be_hurt(_how: String, _from: Vector2) -> bool:
	return false


func keeper_process(delta: float) -> void:
	velocity.x = 0.0
	_cooldown = maxf(0.0, _cooldown - delta)
	if asking or _cooldown > 0.0 or hero() == null:
		return
	if hero_distance() < 190.0 and game and game.has_method("ask_riddle"):
		asking = true
		facing = signf(hero().global_position.x - global_position.x)
		game.ask_riddle(self)


## The hero picked answer `index`.
func answer(index: int) -> void:
	asking = false
	if index == correct:
		hits = hits_needed
		release()
		return
	_cooldown = 3.0
	set_state("tell")
	register_fail()
	if hero():
		hero().take_hit(global_position.x)
