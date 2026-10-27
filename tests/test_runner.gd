extends Node
## Headless tests. Run:  godot --headless --path . res://tests/test_runner.tscn
## Exit code 0 = all passed. Covers level building, time-shift safety, save merging
## and a scripted bot that plays level 1 from start to finish.

var _failures := 0
var _checks := 0


func _ready() -> void:
	await get_tree().process_frame
	var backup: Dictionary = SaveManager.data.duplicate(true)
	_test_save_merge()
	await _test_levels_build()
	await _test_time_shift_safety()
	await _test_bot_plays_level_1()
	SaveManager.data = backup
	SaveManager.save_game()
	print("\n%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
	else:
		print("ok   ", what)


func _test_save_merge() -> void:
	var merged := SaveManager._merge(SaveManager.default_data(), {"settings": {"music": 0.2}, "version": 1})
	_check(merged.settings.music == 0.2, "save merge keeps stored values")
	_check(merged.settings.has("hints") and merged.has("purchases"), "save merge fills missing keys")


func _test_levels_build() -> void:
	for world in LevelManager.WORLDS:
		if not world.available:
			continue
		var palette := LevelBuilder.make_palette(world.palette)
		for level_id in range(world.first, world.last + 1):
			var data := LevelManager.load_level(level_id)
			_check(not data.is_empty(), "level %d loads" % level_id)
			if data.is_empty():
				continue
			var root := Node2D.new()
			add_child(root)
			var info := LevelBuilder.build(data, root, FakeGame.new(), palette)
			_check(info.exit != null, "level %d has an exit" % level_id)
			_check(info.stars == 3, "level %d has 3 stars" % level_id)
			await get_tree().physics_frame
			root.queue_free()
			await get_tree().process_frame


func _test_time_shift_safety() -> void:
	var root := Node2D.new()
	add_child(root)
	var data := {"id": 99, "map": [
		"..........",
		"..........",
		"...r..~...",
		"##########",
	]}
	var palette := LevelBuilder.make_palette(LevelManager.WORLDS[0].palette)
	LevelBuilder.build(data, root, FakeGame.new(), palette)
	TimeShift.reset(TimeShift.PRESENT)
	await get_tree().physics_frame
	var size := Vector2(40, 84)
	var at_rock := Rect2(Vector2(3 * 64 + 12, 3 * 64 - 84), size)
	var at_water := Rect2(Vector2(6 * 64 + 12, 3 * 64 - 84), size)
	var clear := Rect2(Vector2(1 * 64 + 12, 3 * 64 - 84), size)
	_check(TimeShift.find_blocker(at_rock) != null, "shift to past is refused inside a past-only rock")
	_check(TimeShift.find_blocker(clear) == null, "shift is allowed on open ground")
	TimeShift.reset(TimeShift.PAST)
	_check(TimeShift.find_blocker(at_water) != null, "shift to present is refused inside present-only water")
	_check(TimeShift.find_blocker(at_rock) == null, "shift away from the rock's time is allowed")
	root.queue_free()
	await get_tree().process_frame


func _test_bot_plays_level_1() -> void:
	LevelManager.current_level = 1
	var game: Node = load("res://scenes/gameplay/game.tscn").instantiate()
	add_child(game)
	Engine.time_scale = 3.0
	var elapsed := 0.0
	var jump_timer := 0.0
	Input.action_press("move_right")
	while elapsed < 60.0 and not game.finished:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time() * Engine.time_scale
		elapsed += delta
		jump_timer += delta
		if game._busy:
			game.dialogue.advanced.emit()
			continue
		if jump_timer > 0.55:
			jump_timer = 0.0
			Input.action_press("jump")
		elif jump_timer > 0.3:
			Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_release("jump")
	Engine.time_scale = 1.0
	_check(game.finished, "bot finishes level 1 (%.1fs game time)" % elapsed)
	game.queue_free()
	await get_tree().process_frame


class FakeGame extends Node:
	var player: Node2D = null

	func on_hazard(_kind: String) -> void:
		pass
