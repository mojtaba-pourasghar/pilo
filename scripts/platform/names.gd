extends Node
## «Names»: the hero's name. «آرسام» by default; the player may change it at the start of the
## game. It is only shown on screen (dialogue, messages): it is never spoken in a recording, so
## voice lines never contain it. Text uses the placeholder {hero}, filled in by fmt().

signal changed(name: String)

const DEFAULT_HERO := "آرسام"
const MAX_LENGTH := 14


func hero() -> String:
	var n := String(SaveManager.data.get("player_name", ""))
	return n if n.strip_edges() != "" else DEFAULT_HERO


## A clean name: trimmed, no braces or new lines, at most MAX_LENGTH letters; empty -> default.
static func clean(raw: String) -> String:
	var n := raw.strip_edges().replace("\n", " ").replace("{", "").replace("}", "")
	if n.length() > MAX_LENGTH:
		n = n.substr(0, MAX_LENGTH).strip_edges()
	return n if n != "" else DEFAULT_HERO


func set_hero(raw: String) -> void:
	SaveManager.data["player_name"] = clean(raw)
	SaveManager.data["name_chosen"] = true
	SaveManager.save_game()
	changed.emit(hero())


func chosen() -> bool:
	return bool(SaveManager.data.get("name_chosen", false))


## "{hero}" -> the hero's name.
func fmt(text: String) -> String:
	return text.replace("{hero}", hero())
