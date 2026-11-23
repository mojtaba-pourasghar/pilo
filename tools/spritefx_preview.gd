extends Node2D
## Dev helper: every SpriteFX sequence frame by frame on a dark ground.
##   godot --path . res://tools/spritefx_preview.tscn -- --out=/tmp/fx.png

func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("3a4a6a"))
	SpriteFX._load_data()
	var row := 0
	for name in SpriteFX._data:
		if not SpriteFX._data[name] is Dictionary:
			continue
		var spec: Dictionary = SpriteFX._data[name]
		var col := 0
		for cell in spec.frames:
			var tex := SpriteFX._frame(String(spec.sheet), String(cell))
			if tex == null:
				continue
			var s := Sprite2D.new()
			s.texture = tex
			var k := minf(70.0 / tex.get_height(), 70.0 / tex.get_width())
			s.scale = Vector2(k, k)
			s.position = Vector2(150 + col * 90, 50 + row * 80)
			add_child(s)
			col += 1
		var l := Label.new()
		l.text = name
		l.position = Vector2(8, 38 + row * 80)
		l.add_theme_font_size_override("font_size", 13)
		add_child(l)
		row += 1
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://fx.png"))
	get_tree().quit()
