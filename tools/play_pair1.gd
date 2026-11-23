extends Node
## Dev launcher: opens a pair-1 level directly (the map does not list it yet).
##   godot --path . res://tools/play_pair1.tscn            # old level «دشت صبح»
##   godot --path . res://tools/play_pair1.tscn -- --level=old_01
##   ... -- --shot=/tmp/a.png [--x=40] [--wait=2.5]       # screenshot after loading (x = tile to stand on)
## Keys: arrows/A-D move, Space jump, V shoot, F tool (plant the seed / light the shrine), Esc pause.

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	# stay alive when the scene changes (the screenshot code below runs inside the game)
	await get_tree().process_frame
	reparent(get_tree().root)
	LevelManager.play_pair_level(String(args.get("level", "old_01")))
	if args.has("shot"):
		await get_tree().create_timer(1.0).timeout
		var game := get_tree().get_first_node_in_group("game")
		if game and args.has("x"):
			game.player.global_position = Vector2(float(args.x) * 64.0 + 32.0, 10.0 * 64.0)
			game.player.reset_physics_interpolation()
		await get_tree().create_timer(float(args.get("wait", "2.0"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(String(args.shot))
		get_tree().quit()
