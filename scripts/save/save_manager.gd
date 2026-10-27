extends Node
## Local, versioned save file. Progress never needs the internet.

signal saved

const SAVE_PATH := "user://save.json"
const TMP_PATH := "user://save.tmp"
const CORRUPT_PATH := "user://save_corrupt.json"
const VERSION := 1

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"version": VERSION,
		"levels": {},
		"shards": 0,
		"settings": {"music": 0.7, "sfx": 0.9, "hints": "more"},
		"purchases": [],
		"pilo_color": "classic",
		"analytics": {},
	}


func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is unreadable; keeping a copy and starting fresh.")
		DirAccess.rename_absolute(SAVE_PATH, CORRUPT_PATH)
		return
	data = _merge(default_data(), _migrate(parsed))


## Writes to a temp file first so a crash mid-write never destroys the old save.
func save_game() -> void:
	data.version = VERSION
	var file := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)
	saved.emit()


## Clears level progress but keeps settings and purchases (purchases must never be lost).
func reset_progress() -> void:
	var keep_settings: Dictionary = data.settings
	var keep_purchases: Array = data.purchases
	data = default_data()
	data.settings = keep_settings
	data.purchases = keep_purchases
	save_game()


## Upgrades older save layouts in place. Add one branch per version bump.
func _migrate(old: Dictionary) -> Dictionary:
	var version := int(old.get("version", 0))
	if version < 1:
		old["version"] = 1
	return old


## Fills keys missing from `loaded` with defaults (one level deep for dictionaries).
func _merge(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	for key in defaults:
		if not loaded.has(key):
			loaded[key] = defaults[key]
		elif defaults[key] is Dictionary and loaded[key] is Dictionary:
			for sub in defaults[key]:
				if not loaded[key].has(sub):
					loaded[key][sub] = defaults[key][sub]
	return loaded
