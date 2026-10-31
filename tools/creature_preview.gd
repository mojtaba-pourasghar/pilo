extends Node2D
## Dev helper: every rendered creature (and a guardian) moving, saved as a few frames.
##   godot --path . res://tools/creature_preview.tscn -- --out=/tmp/cr
const WALK := ["shroom", "crab", "scorpion", "penguin", "beetle", "robot", "knight", "cloudling"]
const FLY := ["bee", "jelly", "vulture", "owl", "stormbird", "bat", "drone", "wraith"]
const ROLL := ["hog", "urchin", "cactus", "iceball", "thunderpuff", "porcupine", "gear", "spikeball"]


func _ready() -> void:
	var out := "user://cr"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
	RenderingServer.set_default_clear_color(Color("bfe6ff"))
	for r in 3:
		var names: Array = [WALK, FLY, ROLL][r]
		for i in names.size():
			var c := PaintedCreature.make("enemy_" + names[i], 70.0, ["walk", "fly", "roll"][r])
			c.position = Vector2(70 + i * 120, 150 + r * 150)
			c.state = "walk"
			if i % 2 == 1:
				c.freed_amount = 1.0
			add_child(c)
	var boss := PaintedCreature.make("boss_forest", 200.0, "boss")
	boss.face_left = true
	boss.position = Vector2(1100, 640)
	boss.state = "walk"
	add_child(boss)
	if OS.get_cmdline_user_args().has("--movie"):
		await get_tree().create_timer(3.0).timeout
		boss.state = "windup"
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()
		return
	for f in 3:
		await get_tree().create_timer(0.17).timeout
		if f == 2:
			boss.state = "windup"
			await get_tree().create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [out, f])
	get_tree().quit()
