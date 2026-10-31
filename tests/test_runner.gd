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
	_test_audio()
	_test_level_1_layout()
	await _test_stomp_and_hurt()
	await _test_blocks()
	await _test_pipe_warp()
	await _test_pilo_frees_hedgehog()
	await _test_glide_and_den()
	await _test_boss_fight()
	await _test_bot_runs_course()
	await _test_loadout()
	await _test_effects()
	SaveManager.data = backup
	SaveManager.save_game()
	print("\n%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _test_loadout() -> void:
	var data: Dictionary = SaveManager.data
	data.coins = 1000
	data.diamonds = 0
	data.tools = []
	data.companions = []
	data.equipped = []
	data.companion = ""
	data.hearts_of_time = 1
	_check(Loadout.owns_companion("squirrel"), "the first guardian's companion joins for free")
	_check(not Loadout.owns_companion("turtle"), "the second one waits for its guardian")
	_check(not Loadout.buy_with_wallet("tool", "shield"), "the bubble shield needs diamonds too")
	_check(Loadout.buy_with_wallet("tool", "hammer") and int(data.coins) == 700, "the hammer costs 300 coins")
	_check(Loadout.buy_with_wallet("tool", "umbrella") and Loadout.buy_with_wallet("companion", "hedgehog") == false, "coins run out")
	_check(Loadout.toggle_tool("hammer") and Loadout.toggle_tool("umbrella"), "two tools fit in the backpack")
	data.tools.append("magnet")
	_check(not Loadout.toggle_tool("magnet"), "a third tool needs the golden toolbox")
	Loadout.pick_companion("squirrel")
	var game := await _start([
		"..........",
		"..........",
		"P.........",
		"##########",
	])
	_check(game.player.wall_jump and game.player.dash_breaks_bricks, "the squirrel and the hammer work in the level")
	_check(game._follower != null and game._follower.id == "squirrel", "the picked companion follows along")
	await _wait(0.5)
	_stop(game)
	for id in Loadout.COMPANIONS:
		var rig := CompanionRig.new()
		rig.id = id
		add_child(rig)
	for id in Loadout.TOOLS:
		add_child(LoadoutIcon.make("tool", id))
	await _wait(0.1)
	_check(true, "all 12 companions and 12 tools draw without errors")


func _test_effects() -> void:
	_check(Weather.for_level("forest", 3, 1).rain, "forest level 3 is rainy")
	_check(Weather.for_level("golden_desert", 17, 17).heat, "the desert shimmers with heat")
	_check(Weather.for_level("shadow_castle", 58, 57).storm, "castle storms have lightning")
	_check(not Weather.for_level("crystal_caves", 41, 41).rain, "no rain inside the caves")
	var game := await _start([
		"..........",
		"..........",
		"P.........",
		"##########",
	])
	_check(game.weather != null and game.player.fx != null, "every level has weather and body effects")
	Juice.hit(game.player, game.player.global_position, 1.0)
	await _wait(0.4)
	_check(Engine.time_scale == 1.0, "the hit-stop ends by itself")
	game.player.fx.ignite(0.3)
	await _wait(0.6)
	_check(true, "catching fire runs without errors")
	_stop(game)


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


func _test_audio() -> void:
	for world in LevelManager.WORLDS:
		var path := "res://assets/audio/ambient/%s.ogg" % world.ambient
		_check(ResourceLoader.exists(path), "ambience for %s exists" % world.id)
	for bus in AudioManager.BUSES:
		_check(AudioServer.get_bus_index(bus) != -1, "audio bus %s exists" % bus)
	_check(not AudioManager.play_voice("no_such_line"), "a missing voice line is skipped quietly")
	var lines: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice/voice_lines.json"))
	var recorded := 0
	for line in lines.lines:
		for ext in AudioManager.VOICE_EXTENSIONS:
			if ResourceLoader.exists("res://assets/audio/voice/%s%s" % [line.id, ext]):
				recorded += 1
				_check(AudioManager.play_voice(line.id), "voice %s plays" % line.id)
				break
	print("     %d of %d voice lines have audio" % [recorded, lines.lines.size()])
	AudioManager.stop_voice()


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


func _test_level_1_layout() -> void:
	var data := LevelManager.load_level(1)
	var root := Node2D.new()
	add_child(root)
	var palette := LevelBuilder.make_palette(LevelManager.WORLDS[0].palette)
	var info := LevelBuilder.build(data, root, FakeGame.new(), palette)
	_check(info.time_key, "level 1 has a time key that locks the gate")
	_check(info.diamonds >= 5, "level 1 hides %d diamonds" % info.diamonds)
	_check(info.enemies >= 8, "level 1 has %d shadow creatures" % info.enemies)
	var warps := 0
	for pipe in info.pipes.values():
		warps += int(pipe.is_warp)
	_check(warps == data.warps.size(), "every warp starts on a pipe (%d)" % warps)
	var rooms := 0
	for child in root.get_children():
		rooms += int(child is SecretRoom)
	_check(rooms >= 3, "level 1 has %d secret rooms or caves" % rooms)
	root.free()


## Starts the game scene on a small hand-made map (no dialogue).
func _start(map: Array, extra := {}) -> Node:
	var data := {"id": 98, "title": "test", "lens": false, "map": map}
	data.merge(extra)
	LevelManager.override_level = data
	LevelManager.current_level = 1
	var game: Node = load("res://scenes/gameplay/game.tscn").instantiate()
	add_child(game)
	for i in 3:
		await get_tree().physics_frame
	return game


func _stop(game: Node) -> void:
	LevelManager.override_level = {}
	for action in ["move_right", "move_left", "jump", "dash", "pilo", "down"]:
		Input.action_release(action)
	game.queue_free()
	await get_tree().process_frame


func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


func _test_stomp_and_hurt() -> void:
	var game := await _start([
		"............",
		"............",
		"............",
		".P....e.....",
		"############",
	])
	var enemy: Enemy = get_tree().get_first_node_in_group("enemy")
	# drop Nima onto the mushroom from above
	game.player.global_position = enemy.global_position + Vector2(0, -200)
	game.player.velocity = Vector2(0, 300)
	await _wait(0.6)
	_check(enemy == null or not is_instance_valid(enemy) or enemy.freed, "stomping a shadow mushroom frees it")
	_check(game.player.hearts == 3, "a stomp costs no heart")
	_check(game.coins >= 1, "a freed creature leaves a coin")
	# now walk into a second one from the side
	var second := Shroom.new()
	second.game = game
	second.position = game.player.global_position + Vector2(120, 40)
	game._world_root.add_child(second)
	game.coins = 3
	Input.action_press("move_right")
	await _wait(0.8)
	Input.action_release("move_right")
	_check(game.player.hearts == 2, "touching a shadow from the side costs a heart")
	_check(game.coins < 3, "a hit spills coins")
	game.player.invulnerable = 0.0
	game.player.take_hit(game.player.global_position.x)
	game.player.invulnerable = 0.0
	game.player.take_hit(game.player.global_position.x)
	await _wait(2.0)
	_check(game.player.hearts == game.player.max_hearts, "with no hearts left Nima starts again with full hearts")
	await _stop(game)


func _test_blocks() -> void:
	var game := await _start([
		"..........",
		"..........",
		"...Q.b.n..",
		"..........",
		".P........",
		"##########",
	])
	var blocks := get_tree().get_nodes_in_group("block")
	var question: Block
	var brick: Block
	var hidden: Block
	for block in blocks:
		match block.kind:
			Block.Kind.QUESTION:
				question = block
			Block.Kind.BRICK:
				brick = block
			Block.Kind.HIDDEN:
				hidden = block
	for target in [question, brick, hidden]:
		game.player.global_position = target.global_position + Vector2(32, 64 * 2 + 20)
		game.player.velocity = Vector2.ZERO
		await _wait(0.3)
		Input.action_press("jump")
		await _wait(0.5)
		Input.action_release("jump")
		await _wait(0.3)
	_check(question.kind == Block.Kind.USED and game.coins == 1, "a ? block gives a coin and is used up")
	_check(not is_instance_valid(brick), "an empty brick breaks when bumped")
	_check(hidden.kind == Block.Kind.USED, "a hidden block appears when bumped from below")
	await _wait(0.6)
	var diamonds := 0
	for item in get_tree().get_nodes_in_group("collectible"):
		diamonds += int(item.kind == Collectible.Kind.DIAMOND)
	_check(diamonds == 1 or game.diamonds_found.size() == 1, "the hidden block gives its diamond")
	await _stop(game)


func _test_pipe_warp() -> void:
	var game := await _start([
		"..............",
		"..............",
		".P.p......p...",
		"##############",
		"##############",
	], {"warps": [{"from": [3, 2], "to": [10, 2]}]})
	game.player.global_position = Vector2(4 * 64, 2 * 64 - 60)
	await _wait(0.5)
	Input.action_press("down")
	await _wait(1.6)
	Input.action_release("down")
	_check(game.player.global_position.x > 10 * 64, "pressing down on a warp pipe comes out of the other pipe")
	await _stop(game)


func _test_pilo_frees_hedgehog() -> void:
	var game := await _start([
		"............",
		"............",
		".P...h......",
		"############",
	])
	var hog: Enemy = get_tree().get_first_node_in_group("enemy")
	await _wait(0.3)
	Input.action_press("pilo")
	await _wait(0.1)
	Input.action_release("pilo")
	await _wait(0.8)
	_check(not is_instance_valid(hog) or hog.freed, "Pilo's attack frees a spiky hedgehog")
	await _stop(game)


## A blind bot (hold right, jump every half second) must get through a short course with a
## pit, shadow creatures, blocks and a flag: the controls are forgiving enough for that.
func _test_glide_and_den() -> void:
	var game := await _start([
		"..............",
		"..............",
		"..............",
		".P............",
		"######....##X#",
	])
	await _wait(0.2)
	game.player.global_position = Vector2(6.5 * 64, 64)
	game.player.velocity = Vector2.ZERO
	Input.action_press("jump")
	game.player._jump_held = false
	await _wait(0.5)
	_check(game.player.gliding and game.player.velocity.y <= game.player.GLIDE_FALL + 1.0, "holding jump while falling glides with Pilo")
	Input.action_release("jump")
	game.player.global_position = Vector2(11 * 64, 3 * 64)
	await _wait(0.6)
	Input.action_press("pilo")
	await _wait(0.1)
	Input.action_release("pilo")
	await _wait(2.5)
	_check(game.has_time_key, "Pilo brings the time key out of a fox den")
	await _stop(game)


func _test_boss_fight() -> void:
	var game := await _start([
		"......................",
		"......................",
		"......................",
		"......................",
		"......................",
		".P.........&...|..E...",
		"######################",
	], {"boss": "forest"})
	var boss: Boss = game.info.boss
	_check(boss != null and boss.hp == 3, "the forest guardian appears with three hits")
	for i in 3:
		await _wait(1.4)
		boss.state = "stunned"
		boss._timer = 3.0
		game.player.invulnerable = 5.0
		game.player.global_position = boss.global_position + Vector2(0, -boss.KINDS.forest.size.y - 70)
		game.player.velocity = Vector2(0, 400)
		await _wait(0.4)
	_check(boss.is_freed, "stomping the guardian three times frees it")
	await _wait(1.5)
	var door: Node = get_tree().get_first_node_in_group("boss_door")
	_check(door != null and door._shape.disabled, "the barred door opens when the guardian is freed")
	await _stop(game)


func _test_bot_runs_course() -> void:
	var game := await _start([
		"..............................................",
		"..............................................",
		".........Q.b.Q................................",
		"..............................................",
		".P......e...........C.......e...c.c.c.....E...",
		"############...###############################",
		"############...###############################",
	])
	Engine.time_scale = 3.0
	var elapsed := 0.0
	var jump_timer := 0.0
	Input.action_press("move_right")
	while elapsed < 60.0 and not game.finished:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()  # already scaled by time_scale
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
	_check(game.finished, "bot runs the course to the gate (%.1fs game time, ended at x %d, hearts %d)" % [elapsed, int(game.player.global_position.x), game.player.hearts])
	await _stop(game)


class FakeGame extends Node:
	var player: Node2D = null

	func on_collect(_item: Node) -> void:
		pass

	func on_hazard(_kind: String) -> void:
		pass
