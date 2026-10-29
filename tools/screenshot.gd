extends Node
## Dev helper for store screenshots and visual checks. Example:
##   godot --path . res://tools/screenshot.tscn -- --scene=game --level=3 --wait=2.5 --out=/tmp/shot.png [--shift] [--right=1.5]
##   [--at=60,9] puts Nima at that tile first

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	UIKit.ensure_theme(get_tree())
	LevelManager.current_level = int(args.get("level", "1"))
	var scenes := {"menu": LevelManager.MENU_SCENE, "map": LevelManager.MAP_SCENE,
		"store": LevelManager.STORE_SCENE, "game": LevelManager.GAME_SCENE, "boot": "res://scenes/boot/boot.tscn",
		"intro": LevelManager.INTRO_SCENE, "village": LevelManager.VILLAGE_SCENE}
	if args.has("save"):
		# --save=coins:2500;companion:owl;tools:hammer|magnet - temporary save values (not written)
		for pair in String(args.save).split(";"):
			var kv := pair.split(":")
			var value: Variant = kv[1]
			if kv[1].contains("|"):
				value = Array(kv[1].split("|"))
			elif kv[1].is_valid_int():
				value = int(kv[1])
			SaveManager.data[kv[0]] = value
	var scene: Node = load(scenes.get(args.get("scene", "menu"), LevelManager.MENU_SCENE)).instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().create_timer(0.3).timeout
	if args.has("skip") and scene.get("dialogue"):
		for i in 8:
			scene.dialogue.advanced.emit()
			await get_tree().create_timer(0.3).timeout
	if args.has("call"):
		# --call=method: call a method on the scene first (e.g. _show_worlds on the map)
		# --call=method:arg passes one string argument
		var call_parts := String(args.call).split(":")
		if call_parts.size() > 1:
			scene.call(call_parts[0], call_parts[1])
		else:
			scene.call(call_parts[0])
		await get_tree().create_timer(0.3).timeout
	if args.has("at"):
		# --at=x,y in tiles: put Nima there (feet on the bottom of that cell)
		var cell := String(args.at).split(",")
		scene.player.global_position = Vector2(float(cell[0]) * 64.0 + 32.0, float(cell[1]) * 64.0 + 23.0)
		scene.player.get_node("Camera2D").reset_smoothing()
		await get_tree().create_timer(0.4).timeout
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
				scene.has_time_key = true
				scene.coins = 57
				scene.diamonds_found = [0, 2, 3]
				scene.enemies_freed = 9
				scene.on_exit_reached()
	await get_tree().create_timer(float(args.get("wait", "1.0"))).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(args.get("out", "user://shot.png"))
	get_tree().quit()
