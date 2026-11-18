extends Node
## «Strings»: every player-facing text, from data/strings_fa.json (key -> Persian, right to left).
## Keys: c{chapter}_l{level}_{nn} for level text, app_* for messages (= their voice line id),
## ui_* for screens. Placeholders: {hero} (the hero's name, Names) and {name}-style values.
## A missing key shows the key itself (and a warning) so it is easy to spot in a test.

const PATH := "res://data/strings_fa.json"

var _table: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	_table = {}
	if FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_table = parsed


func has(key: String) -> bool:
	return _table.has(key)


## The text for `key`, with {hero} and the given values filled in.
func t(key: String, values: Dictionary = {}) -> String:
	if not _table.has(key):
		push_warning("strings_fa.json has no key " + key)
		return key
	var text := String(_table[key])
	for name in values:
		text = text.replace("{%s}" % name, str(values[name]))
	return Names.fmt(text)


## Data loaded from JSON keeps only keys: fills in "text", "title", "goal" and "signs" from
## "text_key", "title_key", "goal_key" and "sign_keys" (recursively), so older code reading
## those fields keeps working.
func resolve(value: Variant) -> Variant:
	if value is Dictionary:
		for field in ["text", "title", "goal", "subtitle"]:
			if value.has(field + "_key"):
				value[field] = t(String(value[field + "_key"]))
		if value.has("sign_keys"):
			value["signs"] = (value["sign_keys"] as Array).map(func(k): return t(String(k)))
		for k in value:
			if value[k] is Dictionary or value[k] is Array:
				resolve(value[k])
	elif value is Array:
		for item in value:
			resolve(item)
	return value
