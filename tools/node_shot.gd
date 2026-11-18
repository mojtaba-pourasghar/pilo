extends Node2D
## Dev helper: draws one node made from a script (rigs, keepers, effects) and saves a screenshot.
##   godot --path . res://tools/node_shot.tscn -- --script=res://scripts/enemies/bear_rig.gd --out=/tmp/x.png [--set=raise:1;head_mood:angry] [--wait=0.5]

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("6f8fa8"))
	var node: Node2D = load(String(args.get("script"))).new()
	node.position = Vector2(640, 620)
	add_child(node)
	var floor_line := Line2D.new()
	floor_line.points = PackedVector2Array([Vector2(0, 620), Vector2(1280, 620)])
	floor_line.width = 3
	add_child(floor_line)
	if args.has("set"):
		for pair in String(args.set).split(";"):
			var kv := pair.split(":")
			var v: Variant = kv[1]
			if kv[1].is_valid_float():
				v = float(kv[1])
			node.set(kv[0], v)
	await get_tree().create_timer(float(args.get("wait", "0.4"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(args.get("out", "/tmp/node_shot.png")))
	get_tree().quit()
