extends Node
## Minimal, local-only play statistics (counts per level) used to spot levels that are too hard.
## Nothing leaves the device: no network, no device identifiers, no advertising IDs.
## Any future upload must be opt-in, aggregate-only and covered by the privacy policy.


func log_event(event_name: String, level_id := 0) -> void:
	var stats: Dictionary = SaveManager.data.analytics
	var key := _key(event_name, level_id)
	stats[key] = int(stats.get(key, 0)) + 1


func get_count(event_name: String, level_id := 0) -> int:
	return int(SaveManager.data.analytics.get(_key(event_name, level_id), 0))


func _key(event_name: String, level_id: int) -> String:
	return event_name if level_id == 0 else "%s:%d" % [event_name, level_id]
