extends Node
## Screenshot of a v3 overlay screen alone: godot --path . res://tools/preview_ui.tscn -- --ui=result|clock --out=path.png

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	match String(args.get("ui", "result")):
		"clock":
			DeedsStore.clear()
			DeedsStore.add("egg_saved")
			DeedsStore.add("shrine_lit")
			add_child(GreatClock.new())
		_:
			var r := ResultV3.new()
			r.stars = int(args.get("stars", "2"))
			r.coins = 37
			add_child(r)
	await get_tree().create_timer(float(args.get("wait", "3.0"))).timeout
	get_viewport().get_texture().get_image().save_png(String(args.get("out", "user://preview.png")))
	get_tree().quit()
