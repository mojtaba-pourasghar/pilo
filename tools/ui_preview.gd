extends Node
## Dev helper: shows one piece of UI on its own for a screenshot.
##   godot --path . res://tools/ui_preview.tscn -- --show=nima|pilo|complete --out=/tmp/ui.png

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	UIKit.ensure_theme(get_tree())
	RenderingServer.set_default_clear_color(Color("7fc8f0"))
	match String(args.get("show", "nima")):
		"complete":
			var popup: CanvasLayer = load("res://scripts/ui/level_complete.gd").new()
			popup.level_id = 1
			popup.stars_found = 2
			popup.coins = 57
			popup.diamonds_found = 3
			popup.diamonds_total = 8
			popup.freed = 9
			popup.first_time = true
			add_child(popup)
		var who:
			var box: CanvasLayer = load("res://scripts/ui/dialogue_box.gd").new()
			add_child(box)
			box.play([{"who": who, "text": "سلام! این یک جملهٔ آزمایشی است."}])
	await get_tree().create_timer(float(args.get("wait", "1.5"))).timeout
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://ui.png"))
	get_tree().quit()
