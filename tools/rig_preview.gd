extends Node2D
## Dev helper: every pose of the code-drawn characters side by side, for visual checks.
##   godot --path . res://tools/rig_preview.tscn -- --out=/tmp/rigs.png [--time=0.4] [--scale=2.2] [--painted]

const NIMA_STATES := ["idle", "walk", "run", "jump", "glide", "dash", "skid", "hurt", "celebrate"]
const PILO_STATES := ["idle", "run", "leap", "fly", "attack", "happy", "sad"]


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("bfe6ff"))
	var s := float(args.get("scale", "1.7"))
	for i in NIMA_STATES.size():
		var rig: CharacterRig = PaintedRig.make("nima") if args.has("painted") else NimaRig.new()
		rig.state = NIMA_STATES[i]
		rig.speed = 260.0 if rig.state == "walk" else 520.0
		rig.position = Vector2(80 + i * 136, 330)
		rig.scale = Vector2(s, s)
		add_child(rig)
		_label(NIMA_STATES[i], rig.position + Vector2(-40, 14))
	for i in PILO_STATES.size():
		var fox: CharacterRig = PaintedRig.make("pilo") if args.has("painted") else PiloRig.new()
		fox.state = PILO_STATES[i]
		fox.speed = 520.0
		fox.position = Vector2(110 + i * 170, 640)
		fox.scale = Vector2(s, s)
		add_child(fox)
		_label(PILO_STATES[i], fox.position + Vector2(-40, 14))
	await get_tree().create_timer(float(args.get("time", "0.6"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://rigs.png"))
	get_tree().quit()


func _label(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color("1d3557"))
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)
