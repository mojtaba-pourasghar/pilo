class_name DeedsStore
extends RefCounted
## "Effective deeds" (docs/22 §2.2, docs/33 §3): what the grandfather did in an old level changes the
## new level of the same pair. Stored in SaveManager.data.deeds as {deed_id: true}. The new level asks
## variant(): "full" (every deed), "none" (no deed) or "partial". Never a dead end: all three variants
## are playable, `none` is only harder / longer (docs/33 §5).

## Deeds of pair 1 (chapter 1, old level 1).
const PAIR1 := ["egg_saved", "bridge_planted", "shrine_lit"]


static func _deeds() -> Dictionary:
	if not SaveManager.data.has("deeds") or typeof(SaveManager.data.deeds) != TYPE_DICTIONARY:
		SaveManager.data["deeds"] = {}
	return SaveManager.data.deeds


static func has(id: String) -> bool:
	return bool(_deeds().get(id, false))


## Records a deed. Returns true when it is new (the level then plays the clock-ring effect).
static func add(id: String) -> bool:
	var d := _deeds()
	if bool(d.get(id, false)):
		return false
	d[id] = true
	SaveManager.save_game()
	return true


static func count(ids: Array = PAIR1) -> int:
	var n := 0
	for id in ids:
		if has(String(id)):
			n += 1
	return n


## "full" | "partial" | "none" for the new level of a pair.
static func variant(ids: Array = PAIR1) -> String:
	var n := count(ids)
	if n == ids.size():
		return "full"
	return "none" if n == 0 else "partial"


## Replaying the old level may add deeds but never removes them; a fresh save starts empty.
static func clear(ids: Array = PAIR1) -> void:
	for id in ids:
		_deeds().erase(String(id))
