extends Node
## Dev helper: plays the impact, weather and body effects on a small test field and saves a
## picture of each at its strongest moment, for visual checks.
##   godot --path . res://tools/fx_demo.tscn -- --out=/tmp/fx [--only=impact]

const MAP := [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"P.............................",
	"######################........",
	"######################........",
]

var _out := "user://fx"


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	_out = String(args.get("out", _out))
	await get_tree().process_frame
	SaveManager.data.intro_seen = true
	var only := String(args.get("only", ""))
	for shot in ["impact", "fire", "sweat", "breath", "storm", "land"]:
		if only == "" or only == shot:
			await call("_" + shot)
	get_tree().quit()


func _game(level_id: int, extra := {}) -> Node:
	var data := {"id": 99, "title": "fx", "lens": false, "map": MAP}
	data.merge(extra)
	LevelManager.override_level = data
	LevelManager.current_level = level_id
	var game: Node = load("res://scenes/gameplay/game.tscn").instantiate()
	get_tree().root.add_child(game)
	for i in 30:
		await get_tree().process_frame
	if game.dialogue:
		game.dialogue.visible = false
	game.player.global_position = Vector2(8 * 64, 7 * 64 + 24)
	return game


func _snap(game: Node, name: String, wait := 0.0) -> void:
	if wait > 0.0:
		await get_tree().create_timer(wait, true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_out, name])
	LevelManager.override_level = {}
	game.queue_free()
	Engine.time_scale = 1.0
	await get_tree().process_frame


func _impact() -> void:
	var game := await _game(1)
	var at: Vector2 = game.player.global_position + Vector2(90, -30)
	Juice.hit(game.player, at, 0.8, "impact")
	FX.burst(game._world_root, at, Color(1, 0.9, 0.5), 14)
	await _snap(game, "impact", 0.05)


func _fire() -> void:
	var game := await _game(17)
	game.player.fx.ignite(3.0)
	await _snap(game, "fire", 0.5)


func _sweat() -> void:
	var game := await _game(18)
	game.player.fx._tired = 2.0
	for i in 6:
		game.player.fx._sweat_t = 0.0
		await get_tree().create_timer(0.08).timeout
	await _snap(game, "sweat", 0.1)


func _breath() -> void:
	var game := await _game(25)
	for i in 3:
		game.player.fx._breath_t = 0.0
		await get_tree().create_timer(0.25).timeout
	await _snap(game, "breath", 0.15)


func _storm() -> void:
	var game := await _game(58)
	game.weather._strike()
	await _snap(game, "storm", 0.05)


func _land() -> void:
	var game := await _game(9)
	game.player.global_position.y -= 700.0
	while not game.player.is_on_floor():
		await get_tree().physics_frame
	await _snap(game, "land", 0.1)
