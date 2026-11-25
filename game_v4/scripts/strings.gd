class_name Strings
extends RefCounted
## Persian texts (CLAUDE.md rule 11): data/strings_fa.json.

static var _d: Dictionary = {}


static func t(key: String) -> String:
	if _d.is_empty():
		var f := FileAccess.open("res://data/strings_fa.json", FileAccess.READ)
		_d = JSON.parse_string(f.get_as_text()) if f else {}
	return String(_d.get(key, key))
