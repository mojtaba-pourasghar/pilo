extends Node2D
## Dev helper: the pair-1 scenery from three camera positions, old and new, for visual checks.
##   godot --path . res://tools/parallax_preview.tscn -- --out=/tmp/par.png [--era=new] [--variant=full]

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	get_window().size = Vector2i(1280, 720)
	var bg := Pair1Parallax.new()
	bg.level_size = Vector2(9000, 1408)
	bg.era = String(args.get("era", "new"))
	bg.variant = String(args.get("variant", "full"))
	add_child(bg)
	var cam := Camera2D.new()
	cam.position = Vector2(float(args.get("x", "1200")), float(args.get("y", "1000")))
	add_child(cam)
	cam.make_current()
	await get_tree().create_timer(float(args.get("time", "1.0"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://par.png"))
	get_tree().quit()
