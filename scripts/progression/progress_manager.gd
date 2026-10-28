extends Node
## Which levels are finished, which stars were found and what is unlocked.
## The main path of every level is completable without stars or purchases.

signal progress_changed

## Cosmetics earned by finishing a level (never sold): level id -> reward id.
const REWARDS := {30: "reward_rangarestan"}


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


## Diamonds already found in a level (each diamond counts once, however often it is replayed).
func diamonds_of(level_id: int) -> Array:
	var entry: Dictionary = _levels().get(str(level_id), {})
	var found: Array = []
	for value in entry.get("diamonds", []):
		found.append(int(value))
	return found


## Records a finished run: stars and diamonds merge with earlier runs, coins go to the
## wallet (spent in the village shop), new diamonds go to the diamond wallet.
## Returns {"first_time": bool, "reward": String ("" when none), "new_diamonds": int}.
func complete_level(level_id: int, collected: Array, coins := 0, diamonds: Array = []) -> Dictionary:
	var key := str(level_id)
	var first_time := not is_done(level_id)
	var stars := stars_of(level_id)
	for index in collected:
		if not stars.has(int(index)):
			stars.append(int(index))
	var found := diamonds_of(level_id)
	var new_diamonds := 0
	for index in diamonds:
		if not found.has(int(index)):
			found.append(int(index))
			new_diamonds += 1
	_levels()[key] = {"done": true, "stars": stars, "diamonds": found}
	SaveManager.data.coins = int(SaveManager.data.get("coins", 0)) + coins
	SaveManager.data.diamonds = int(SaveManager.data.get("diamonds", 0)) + new_diamonds
	var reward := ""
	if first_time:
		SaveManager.data.shards = int(SaveManager.data.shards) + 1
		if REWARDS.has(level_id) and not SaveManager.data.rewards.has(REWARDS[level_id]):
			SaveManager.data.rewards.append(REWARDS[level_id])
			reward = REWARDS[level_id]
	SaveManager.save_game()
	progress_changed.emit()
	return {"first_time": first_time, "reward": reward, "new_diamonds": new_diamonds}
