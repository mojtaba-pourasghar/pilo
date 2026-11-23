extends Node2D
## Dev helper: every state of the skeleton-rigged heroes side by side.
##   godot --path . res://tools/skel_preview.tscn -- --out=/tmp/skel.png [--time=0.7] [--scale=1.6]

const ARSAM := ["idle", "walk", "run", "jump", "fall", "hurt", "celebrate", "crouch", "aim", "aim_draw"]
const GRAND := ["idle", "walk", "run", "jump", "egg", "staff", "sling", "lantern", "hurt", "celebrate"]


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("bfe6ff"))
	var s := float(args.get("scale", "1.6"))
	_row("arsam", ARSAM, 260.0, s)
	_row("grandfather", GRAND, 640.0, s)
	await get_tree().create_timer(float(args.get("time", "0.8"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://skel.png"))
	get_tree().quit()


func _row(who: String, states: Array, y: float, s: float) -> void:
	for i in states.size():
		var rig := SkeletonRig.make(who)
		var st: String = states[i]
		rig.state = st
		rig.speed = 260.0 if st == "walk" else 520.0
		match st:
			"aim":
				rig.state = "idle"
				rig.aiming = true
				rig.aim_angle = 0.15
			"aim_draw":
				rig.state = "idle"
				rig.aiming = true
				rig.aim_angle = 0.15
				rig.draw_amount = 0.9
			"egg", "staff", "sling", "lantern":
				rig.state = "idle"
				rig.holding = st
		rig.position = Vector2(90 + i * 125, y)
		rig.scale = Vector2(s, s)
		add_child(rig)
		var label := Label.new()
		label.text = st
		label.position = rig.position + Vector2(-30, 12)
		label.add_theme_color_override("font_color", Color("1d3557"))
		add_child(label)
