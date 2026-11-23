extends Node2D
## Dev helper: the side-view heroes in the states the game uses.
##   godot --path . res://tools/side_preview.tscn -- --out=/tmp/side.png

const STATES := ["idle", "walk", "run", "jump", "fall", "glide", "dash", "skid", "hurt", "celebrate", "crouch", "aim", "egg"]


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("bfe6ff"))
	get_window().size = Vector2i(1400, 600)
	var y := 200.0
	for who in ["arsam", "grandfather"]:
		for i in STATES.size():
			var rig := SideRig.make(who)
			rig.position = Vector2(70 + i * 105, y)
			var st: String = STATES[i]
			rig.state = st
			rig.speed = 200.0 if st == "walk" else 520.0
			if st == "aim":
				rig.state = "idle"
				rig.aiming = true
				rig.draw_amount = 0.7
			elif st == "egg":
				rig.state = "walk"
				rig.holding = "egg"
				rig.speed = 200.0
			add_child(rig)
			var label := Label.new()
			label.text = st
			label.position = rig.position + Vector2(-26, 8)
			label.add_theme_color_override("font_color", Color("1d3557"))
			add_child(label)
		y += 250.0
	var run_rig := SideRig.make("embri")
	run_rig.position = Vector2(100, 560)
	run_rig.state = "run"
	run_rig.speed = 400.0
	add_child(run_rig)
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://side.png"))
	get_tree().quit()
