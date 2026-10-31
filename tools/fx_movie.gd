extends Node
## Dev helper: plays a level hands-free (run right, jump now and then, a dash) so a short
## video of the effects can be recorded with Godot's movie writer:
##   godot --path . --write-movie /tmp/clip.avi --fixed-fps 30 res://tools/fx_movie.tscn -- --level=3 --seconds=6


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	await get_tree().process_frame
	SaveManager.data.intro_seen = true
	SaveManager.data.tutorial_seen = true
	SaveManager.data.chapters = LevelManager.WORLDS.map(func(w): return w.id)
	LevelManager.current_level = int(args.get("level", "3"))
	var game: Node = load("res://scenes/gameplay/game.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().create_timer(0.3).timeout
	for i in 20:
		if game.dialogue:
			game.dialogue.advanced.emit()
		await get_tree().create_timer(0.3).timeout
	if args.has("fire"):
		game.player.fx.ignite(2.5)
	Input.action_press("move_right")
	var seconds := float(args.get("seconds", "6"))
	var t := 0.0
	var jumped := 0.0
	while t < seconds:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		jumped += dt
		if jumped > 1.3:
			jumped = 0.0
			Input.action_press("jump")
			await get_tree().create_timer(0.35).timeout
			Input.action_release("jump")
		if absf(t - seconds * 0.5) < dt:
			Input.action_press("dash")
			await get_tree().process_frame
			Input.action_release("dash")
			Juice.hit(game.player, game.player.global_position + Vector2(60, -40), 0.7, "impact")
	get_tree().quit()
