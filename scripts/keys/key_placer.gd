class_name KeyPlacer
extends RefCounted
## Where the two time keys are this run (T5). Every level lists three possible places for the
## past key and three for the present key ("key_slots"); one of each is picked with a seed made
## from the level and the run counter, so every run differs but a run is reproducible. Daily and
## online modes pass a shared seed so every player (and the rival's ghost) gets the same keys.

const SLOTS_PER_KEY := 3


static func seed_for(level_id: int, run_counter: int) -> int:
	return hash([level_id, run_counter])


## {"past": index, "present": index} for this seed (each 0..2).
static func choose(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var past := rng.randi_range(0, SLOTS_PER_KEY - 1)
	var present := rng.randi_range(0, SLOTS_PER_KEY - 1)
	return {"past": past, "present": present}


## The chosen cells: {"past": Vector2i, "present": Vector2i, "past_index": i, "present_index": j}.
static func place(key_slots: Dictionary, seed_value: int) -> Dictionary:
	var pick := choose(seed_value)
	var out := {}
	for time in ["past", "present"]:
		var slots: Array = key_slots.get(time, [])
		if slots.is_empty():
			continue
		var i: int = mini(int(pick[time]), slots.size() - 1)
		out[time] = Vector2i(int(slots[i][0]), int(slots[i][1]))
		out[time + "_index"] = i
	return out


## The next run of a level: a new counter value, saved.
static func next_run(level_id: int) -> int:
	var runs: Dictionary = SaveManager.data.get("key_runs", {})
	var n := int(runs.get(str(level_id), 0)) + 1
	runs[str(level_id)] = n
	SaveManager.data["key_runs"] = runs
	return n
