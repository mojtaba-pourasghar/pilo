extends Node
## Dev helper for store screenshots and visual checks. Example:
##   godot --path . res://tools/screenshot.tscn -- --scene=game --level=3 --wait=2.5 --out=/tmp/shot.png [--shift] [--right=1.5]

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	UIKit.ensure_theme(get_tree())
	LevelManager.current_level = int(args.get("level", "1"))
	var scenes := {"menu": LevelManager.MENU_SCENE, "map": LevelManager.MAP_SCENE,
		"store": LevelManager.STORE_SCENE, "game": LevelManager.GAME_SCENE, "boot": "res://scenes/boot/boot.tscn"}
	var scene: Node = load(scenes.get(args.get("scene", "menu"), LevelManager.MENU_SCENE)).instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().create_timer(0.3).timeout
	if args.has("skip") and scene.get("dialogue"):
		for i in 8:
			scene.dialogue.advanced.emit()
			await get_tree().create_timer(0.3).timeout
	if args.has("right"):
		Input.action_press("move_right")
		await get_tree().create_timer(float(args.right)).timeout
		Input.action_release("move_right")
	if args.has("shift"):
		scene.try_shift()
	if args.has("popup"):
		match args.popup:
			"pause":
				scene.open_pause()
			"settings":
				scene.add_child(SettingsPanel.new())
			"gate":
				scene.add_child(ParentGate.new())
			"complete":
				scene.on_exit_reached()
	await get_tree().create_timer(float(args.get("wait", "1.0"))).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(args.get("out", "user://shot.png"))
	get_tree().quit()
