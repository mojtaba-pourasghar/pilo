extends Node
## Screenshot of the v4 level: godot --path game_v4 res://tools/shot.tscn -- --x=1200 --wait=2 --out=a.png [--run=1]
## --run=R makes the hero run (R = -1..1) for the whole wait; --jump=T jumps after T seconds.

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var level: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	await get_tree().process_frame
	await get_tree().process_frame
	if args.has("x"):
		level.hero.global_position = Vector2(float(args.x), float(args.get("y", "500")))
		level.cam.call("snap")
	var wait := float(args.get("wait", "1.5"))
	var t := 0.0
	var jumped := false
	while t < wait:
		if args.has("run"):
			level.control._dir = signf(float(args.run))
			level.control._activity = absf(float(args.run))
		if args.has("jump") and not jumped and t >= float(args.jump):
			jumped = true
			level.control.jump_power = 1.0
			level.control.holding = true
		await get_tree().process_frame
		t += get_process_delta_time()
	get_viewport().get_texture().get_image().save_png(String(args.get("out", "user://v4.png")))
	get_tree().quit()
