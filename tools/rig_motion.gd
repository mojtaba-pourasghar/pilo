extends Node2D
## Dev helper: one character's movement, frame by frame, in a strip (checks the cycle flows).
##   godot --path . --fixed-fps 24 res://tools/rig_motion.tscn -- --state=walk --out=/tmp/walk.png [--character=nima]

var _rig: CharacterRig
var _shots: Array = []
var _args := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	RenderingServer.set_default_clear_color(Color("bfe6ff"))
	_rig = PaintedRig.make(String(_args.get("character", "nima")))
	_rig.state = String(_args.get("state", "walk"))
	_rig.speed = 250.0 if _rig.state != "run" else 560.0
	_rig.position = Vector2(640, 520)
	_rig.scale = Vector2(2.4, 2.4)
	add_child(_rig)
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2(0, 520), Vector2(1280, 520)])
	line.width = 2
	add_child(line)


func _process(_delta: float) -> void:
	if Engine.get_process_frames() < 10:
		return
	if Engine.get_process_frames() % 2 == 0:
		var img := get_viewport().get_texture().get_image()
		_shots.append(img.get_region(Rect2i(440, 140, 400, 400)))
	if _shots.size() == 12:
		var strip := Image.create(400 * 6, 800, false, _shots[0].get_format())
		for i in 12:
			strip.blit_rect(_shots[i], Rect2i(0, 0, 400, 400), Vector2i((i % 6) * 400, (i / 6) * 400))
		strip.save_png(String(_args.get("out", "/tmp/motion.png")))
		get_tree().quit()
