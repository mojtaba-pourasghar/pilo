extends Node
## Which levels are finished, which stars were found and what is unlocked.
## The main path of every level is completable without stars or purchases.

signal progress_changed


func _levels() -> Dictionary:
	return SaveManager.data.levels


func is_done(level_id: int) -> bool:
	var entry: Dictionary = _levels().get(str(level_id), {})
	return bool(entry.get("done", false))


## Indices of the stars found in a level (best run, merged across plays).
func stars_of(level_id: int) -> Array:
	var entry: Dictionary = _levels().get(str(level_id), {})
	var stars: Array = []
	for value in entry.get("stars", []):
		stars.append(int(value))
	return stars


func total_stars(world_id := "") -> int:
	var total := 0
	for key in _levels():
		var level_id := int(key)
		if world_id == "" or LevelManager.world_of(level_id).get("id", "") == world_id:
			total += stars_of(level_id).size()
	return total


func is_world_open(world: Dictionary) -> bool:
	if world.is_empty() or not world.available:
		return false
	return world.free or StoreAdapter.owns(world.sku)


func is_unlocked(level_id: int) -> bool:
	if not is_world_open(LevelManager.world_of(level_id)):
		return false
	return level_id == 1 or is_done(level_id - 1)


func has_progress() -> bool:
	return not _levels().is_empty()


## First unlocked level that is not finished yet; falls back to the last finished one.
func continue_level() -> int:
	var last_done := 1
	for world in LevelManager.WORLDS:
		for level_id in range(world.first, world.last + 1):
			if not LevelManager.has_level(level_id):
				continue
			if not is_done(level_id) and is_unlocked(level_id):
				return level_id
			if is_done(level_id):
				last_done = level_id
	return last_done


## Records a finished run. Returns {"first_time": bool}.
func complete_level(level_id: int, collected: Array) -> Dictionary:
	var key := str(level_id)
	var first_time := not is_done(level_id)
	var stars := stars_of(level_id)
	for index in collected:
		if not stars.has(int(index)):
			stars.append(int(index))
	_levels()[key] = {"done": true, "stars": stars}
	if first_time:
		SaveManager.data.shards = int(SaveManager.data.shards) + 1
	SaveManager.save_game()
	progress_changed.emit()
	return {"first_time": first_time}
