class_name KeeperFactory
extends RefCounted
## Makes the keeper of a level from its JSON entry {"type": "K1", "id": ..., "holds": "present",
## "hint_key": ..., ...}. Chapter 1 needs K1, K2, K4, K8, K11 and K12; the other types come with
## their chapters (an unknown type is reported and the level plays without a keeper).

const TYPES := {
	"K1": preload("res://scripts/enemies/keepers/k01_sleepy.gd"),
	"K2": preload("res://scripts/enemies/keepers/k02_shield.gd"),
	"K4": preload("res://scripts/enemies/keepers/k04_pattern.gd"),
	"K8": preload("res://scripts/enemies/keepers/k08_hider.gd"),
	"K11": preload("res://scripts/enemies/keepers/k11_riddle.gd"),
	"K12": preload("res://scripts/enemies/keepers/k12_needs_item.gd"),
}


static func make(entry: Dictionary) -> Keeper:
	var type := String(entry.get("type", ""))
	if not TYPES.has(type):
		push_warning("keeper type %s is not built yet" % type)
		return null
	var keeper: Keeper = TYPES[type].new()
	keeper.keeper_id = String(entry.get("id", type))
	keeper.params = entry
	keeper.hint_key = String(entry.get("hint_key", ""))
	keeper.hits_needed = int(entry.get("hp_hits", 3))
	return keeper
