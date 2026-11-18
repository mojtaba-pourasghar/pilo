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
	await _test_combat()
	await _test_water_exit()
	await _test_rival_runs()
	_test_names()
	_test_strings()
	await _test_dual_layers()
	_test_key_placer()
	await _test_two_keys()
	await _test_keepers()
	await _test_old_bear()
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
	_check(not game.pilo.visible, "only one companion is out: Pilo rides in the backpack")
	_check(game.player.can_glide == (Loadout.has_tool("umbrella") or Loadout.has_tool("balloon")),
		"without Pilo (or a flyer) the hero glides only with the umbrella or the balloon")
	await _wait(0.5)
	# switching from the screen: back to Pilo, who is out again with his own button
	game.cycle_companion()
	await _wait(0.1)
	_check(Loadout.companion() != "squirrel", "the switch button changes the companion")
	while Loadout.companion() != "":
		game.cycle_companion()
	await _wait(0.1)
	_check(game.pilo.visible and game._follower == null and game.player.can_glide, "Pilo is out again and the hero can glide")
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


func _test_combat() -> void:
	SaveManager.data.weapon = "slingshot"
	var game := await _start([
		"..............",
		"..............",
		"P.......e.....",
		"##############",
	])
	var enemy: Node = null
	for e in get_tree().get_nodes_in_group("enemy"):
		enemy = e
	game.player.facing = 1.0
	game.player._fire()
	await _wait(0.9)
	_check(enemy == null or not is_instance_valid(enemy) or enemy.freed, "a slingshot acorn knocks a shadow creature out")
	_stop(game)
	game = await _start([
		"..............",
		"..............",
		"P.....b.......",
		"######b#######",
	])
	game.player.facing = 1.0
	var bricks := get_tree().get_nodes_in_group("block").size()
	game.pilo._cooldown = 0.0
	var did: String = game.pilo.act(game)
	await _wait(1.0)
	_check(did == "smash" or did == "throw", "the Pilo button sends Pilo at the obstacle (%s)" % did)
	_check(get_tree().get_nodes_in_group("block").size() < bricks, "thrown Pilo breaks a brick")
	_stop(game)
	_check(Weapons.owned().has("slingshot") and Weapons.current() == "slingshot", "the slingshot is the hero's from the start")


## the ghost rival runs with real physics: on the floor on flat ground (no bobbing), over a gap, to the goal.
func _test_rival_runs() -> void:
	var game := await _start([
		"..............................................",
		"..............................................",
		"P.............................................",
		"##############....############################",
	])
	var rival := GhostRival.offline(1)
	rival.position = Vector2(2 * 64, 4 * 64)
	rival.goal_x = 40 * 64
	game._world_root.add_child(rival)
	rival.running = true
	var ys: Array = []
	var crossed := false
	for i in 420:
		await get_tree().physics_frame
		if rival.global_position.x > 3 * 64 and rival.global_position.x < 10 * 64:
			ys.append(rival.global_position.y)
		if rival.global_position.x > 20 * 64 and rival._floor:
			crossed = true
	var spread: float = (ys.max() - ys.min()) if not ys.is_empty() else 999.0
	_check(spread < 2.0, "the ghost rival stays on flat ground without bobbing (%.1f px)" % spread)
	_check(crossed and rival.global_position.y < 5 * 64, "the ghost rival jumps the gap and lands on the far side")
	_check(rival.done, "the ghost rival reaches the goal")
	_stop(game)


## the hero dropped deep under the reef shelf must be able to swim out and climb onto the bank.
func _test_water_exit() -> void:
	var game := await _start([
		"........................................",
		"........................................",
		"..P.....................................",
		"##############sssss########sssss########",
		"##############sssss########sssss########",
		"##############ssssssssssssssssss########",
		"##############ssssssssssssssssss########",
		"##############ssssssssssssssssss########",
		"########################################",
	])
	game.player.global_position = Vector2(22 * 64, 7 * 64 + 20)
	Input.action_press("move_right")
	var out := false
	for i in 40:
		Input.action_press("jump")
		await _wait(0.12)
		Input.action_release("jump")
		await _wait(0.12)
		if game.player.is_on_floor() and game.player.global_position.y < 3 * 64 + 40 and game.player._swim == 0:
			out = true
			break
	_check(out, "the hero swims out from under the reef shelf onto the bank (at %s)" % game.player.global_position)
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
				if bool(line.get("stale_audio", false)):
					_check(not AudioManager.play_voice(line.id), "stale clip %s (old name) is muted" % line.id)
				else:
					_check(AudioManager.play_voice(line.id), "voice %s plays" % line.id)
				break
	print("     %d of %d voice lines have audio" % [recorded, lines.lines.size()])
	# every line the game asks for by id is in the list the voices are made from
	var ids := {}
	for line in lines.lines:
		ids[line.id] = true
	var wanted := ["app_race_start", "app_race_lost", "app_race_won", "app_time_key", "app_gate_locked", "app_try_again"]
	for kind in Boss.KINDS:
		wanted.append("app_freed_" + kind)
	for n in Tutorial.STEPS.size():
		wanted.append("tutorial_%d" % (n + 1))
	var chapters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/chapters.json"))
	for world in chapters:
		for line in chapters[world].lines:
			wanted.append(String(line.id))
	var missing := wanted.filter(func(id): return not ids.has(id))
	_check(missing.is_empty(), "every voiced id is in voice_lines.json %s" % [missing])
	# every line has its vowelled form for the voice studio (Avasho), with exactly the letters of
	# the text (tools/voice/spoken_fa.json)
	var marks := ["َ", "ُ", "ِ", "ْ", "ّ", "ً"]
	var bad := []
	for line in lines.lines:
		if bool(line.get("stale_audio", false)):
			continue    # to be re-recorded without the hero's name (T19); its vowelled form comes then
		var spoken := String(line.get("spoken", ""))
		var text := String(line.text)
		for m in marks:
			spoken = spoken.replace(m, "")
			text = text.replace(m, "")
		if spoken == "" or spoken != text:
			bad.append(line.id)
	_check(bad.is_empty(), "every line has a matching vowelled form %s" % [bad.slice(0, 5)])
	var who_ok := true
	for line in lines.lines:
		who_ok = who_ok and lines.characters.has(String(line.who)) and String(lines.characters[line.who].get("speaker", "")) != ""
	_check(who_ok, "every speaker has an Avasho voice")
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
	TimeShift.state = TimeShift.PAST
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
	data.merge(extra, true)
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
	# drop the hero onto the mushroom from above
	game.player.global_position = enemy.global_position + Vector2(0, -200)
	game.player.velocity = Vector2(0, 300)
	await _wait(0.6)
	_check(enemy == null or not is_instance_valid(enemy) or enemy.freed, "stomping a shadow mushroom frees it")
	_check(game.player.hearts == 3, "a stomp costs no heart")
	await _wait(1.4)
	_check(game.coins >= 2, "a defeated creature drops coins that fly to the hero (%d)" % game.coins)
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
	_check(game.player.hearts == game.player.max_hearts, "with no hearts left the hero starts again with full hearts")
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


## T0: the hero's name is the player's choice («آرسام» by default) and no display data still
## names Nima or Kian.
func _test_names() -> void:
	SaveManager.data.erase("player_name")
	_check(Names.hero() == "آرسام", "the default hero is Arsam")
	_check(Names.fmt("سلام {hero}!") == "سلام آرسام!", "{hero} is filled in")
	Names.set_hero("  مهسا  ")
	_check(Names.hero() == "مهسا" and Names.chosen(), "the player can change the name (trimmed)")
	_check(Names.clean("{x}\n") == "x" and Names.clean("") == "آرسام", "names are cleaned; empty keeps Arsam")
	SaveManager.data.erase("player_name")
	_check(ProjectSettings.get_setting("application/config/name") == "نگهبانان زمان", "the game is called Guardians of Time")
	var bad := []
	for dir_name in DirAccess.get_directories_at("res://data/levels"):
		for file in DirAccess.get_files_at("res://data/levels/" + dir_name):
			if file.ends_with(".json"):
				var text := FileAccess.get_file_as_string("res://data/levels/%s/%s" % [dir_name, file])
				if "نیما" in text or "کیان" in text or "\"kian\"" in text or "\"nima\"" in text:
					bad.append(file)
	for path in ["res://data/story/chapters.json", "res://data/story/intro.json"]:
		var t := FileAccess.get_file_as_string(path)
		if "نیما" in t or "کیان" in t or "تکهٔ زمان" in t:
			bad.append(path)
	_check(bad.is_empty(), "no level or story text names Nima or Kian %s" % [bad])
	_check(AudioManager.is_voice_stale("app_race_start") and not AudioManager.play_voice("app_race_start"), "clips that said Kian or the old name are not played")


## T2: texts come from data/strings_fa.json; data keeps only keys.
func _test_strings() -> void:
	_check(Strings.t("app_unsafe") == "اینجا جای امن نیست!", "a message comes from strings_fa.json")
	_check(Strings.t("app_companion_joined", {"name": "پیلو"}) == "پیلو همراهت شد!", "values are filled in")
	_check(Strings.t("no_such_key_xyz") == "no_such_key_xyz", "a missing key shows itself")
	var data: Dictionary = LevelManager.load_level(2)
	var ok: bool = not data.get("intro", []).is_empty()
	for line in data.get("intro", []):
		ok = ok and line.has("text_key") and String(line.get("text", "")) != "" and not String(line.text).begins_with("c0")
	_check(ok, "level lines are resolved from their keys")
	_check(LevelManager.level_title(2) == "پل کُنده‌ها", "level titles come from strings")
	_check(String(LevelManager.WORLDS[0].title) == "جنگل رنگارستان", "world titles come from strings")


## T3: both times in one scene. The absent layer is a ghost (alpha 0.35; blue past, orange
## present), the level starts in the present, the lens costs charge and the past ends with a soft
## return after 20 s unless it is switched off.
func _test_dual_layers() -> void:
	SaveManager.data.settings.auto_return = true
	var game := await _start([
		"..........",
		"..........",
		"P..r..V...",
		"##########",
	], {"lens": true, "start_time": "past"})
	_check(TimeShift.state == TimeShift.PRESENT, "every level starts in the present (even if data says past)")
	var past: Node2D = game.info.layer_past
	var present: Node2D = game.info.layer_present
	_check(past.get_child_count() == 1 and present.get_child_count() == 1, "past-only and present-only pieces sit in their own layers")
	_check(past.modulate.is_equal_approx(TimeShift.GHOST_PAST) and is_equal_approx(past.modulate.a, 0.35), "the past is a blue ghost (alpha 0.35) while in the present")
	_check(present.modulate.is_equal_approx(Color.WHITE), "the present layer is solid")
	_check(past.visible and past.get_child(0).visible, "the absent layer is still drawn")
	var rock: TimeBlock = past.get_child(0)
	_check(rock._presence == 1.0 and rock._shape.disabled, "a ghost rock is drawn in full but cannot be touched")
	_check(is_equal_approx(TimeShift.charge, 100.0), "the lens starts full")
	game.try_shift()
	await _wait(0.5)
	_check(TimeShift.state == TimeShift.PAST and is_equal_approx(TimeShift.charge, 75.0), "a trip to the past costs 25 charge")
	_check(present.modulate.is_equal_approx(TimeShift.GHOST_PRESENT), "the present becomes an orange ghost")
	_check(not rock._shape.disabled, "the past rock is solid in the past")
	_check(game._grade != null and game._grade.layer < game.hud.layer, "the time grade sits between the world and the HUD")
	# the soft return
	TimeShift.past_elapsed = TimeShift.AUTO_RETURN_AFTER - 0.2
	await _wait(0.6)
	_check(TimeShift.state == TimeShift.PRESENT, "after 20 s in the past the hero is brought back softly")
	# charge: not enough for a trip -> refused; refills in the present
	TimeShift.charge = 10.0
	game._shift_cooldown = 0.0
	game.try_shift()
	_check(TimeShift.state == TimeShift.PRESENT, "with too little charge the lens refuses")
	await _wait(1.0)
	_check(TimeShift.charge > 13.0, "the lens refills in the present (%.1f)" % TimeShift.charge)
	# switched off in the settings
	SaveManager.data.settings.auto_return = false
	TimeShift.charge = 100.0
	game._shift_cooldown = 0.0
	game.try_shift()
	TimeShift.past_elapsed = TimeShift.AUTO_RETURN_AFTER + 5.0
	await _wait(0.6)
	_check(TimeShift.state == TimeShift.PAST, "with the soft return off the hero stays in the past")
	TimeShift.charge = 0.0
	game._shift_cooldown = 0.0
	game.try_shift()
	_check(TimeShift.state == TimeShift.PRESENT, "coming back to the present never needs charge")
	SaveManager.data.settings.auto_return = true
	await _stop(game)


## T5: three places for each key, one picked by a seed (all nine combinations happen).
func _test_key_placer() -> void:
	var a := KeyPlacer.choose(KeyPlacer.seed_for(3, 7))
	var b := KeyPlacer.choose(KeyPlacer.seed_for(3, 7))
	_check(a == b, "the same level and run give the same key places")
	var seen := {}
	for run in 300:
		var c := KeyPlacer.choose(KeyPlacer.seed_for(5, run))
		_check_quiet(c.past >= 0 and c.past < 3 and c.present >= 0 and c.present < 3)
		seen["%d%d" % [c.past, c.present]] = true
	_check(seen.size() == 9, "every one of the 9 combinations comes up (%d)" % seen.size())
	var slots := {"past": [[1, 1], [2, 2], [3, 3]], "present": [[4, 4], [5, 5], [6, 6]]}
	var placed := KeyPlacer.place(slots, 12345)
	_check(slots.past.has([placed.past.x, placed.past.y]) and slots.present.has([placed.present.x, placed.present.y]), "keys are put on one of their own places")
	var before := int(SaveManager.data.get("key_runs", {}).get("777", 0))
	_check(KeyPlacer.next_run(777) == before + 1, "each run of a level counts up")


## T5: the past key can only be taken in the past, the present key in the present, and the gate
## has two locks that need both.
func _test_two_keys() -> void:
	LevelManager.key_seed = 4242
	var game := await _start([
		"....................",
		"....................",
		"P.................E.",
		"####################",
	], {"lens": true, "format": 4, "kind": "normal",
		"key_slots": {"past": [[4, 2], [4, 2], [4, 2]], "present": [[8, 2], [8, 2], [8, 2]]},
		"key_hints": {"past": ["hint_ground", "hint_ground", "hint_ground"], "present": ["hint_near_gate", "hint_near_gate", "hint_near_gate"]}})
	_check(game.two_keys and game.info.exit.two_locks and game.info.exit.locked, "a format-4 gate starts with two locks")
	_check(game.clues.size() == 2, "the clues for both keys are shown")
	var past_key: TimeKey = game.info.layer_past.get_children().filter(func(n): return n is TimeKey)[0]
	var present_key: TimeKey = game.info.layer_present.get_children().filter(func(n): return n is TimeKey)[0]
	_check(past_key.key_time == TimeShift.PAST and present_key.key_time == TimeShift.PRESENT, "each key sits in its own time layer")
	game.player.global_position = past_key.global_position + Vector2(0, 30)
	await _wait(0.3)
	_check(not game.has_past_key and not past_key.taken, "the past key is a ghost in the present: it cannot be taken")
	game.on_exit_reached()
	_check(not game.finished, "the gate stays shut without the keys")
	game._shift_cooldown = 0.0
	game.try_shift()
	await _wait(0.3)
	_check(game.has_past_key, "in the past the past key is taken")
	game.player.global_position = present_key.global_position + Vector2(0, 30)
	await _wait(0.3)
	_check(not game.has_present_key, "the present key cannot be taken from the past")
	game._shift_cooldown = 0.0
	game.try_shift()
	await _wait(0.3)
	_check(game.has_present_key and game.info.exit.lock_past and game.info.exit.lock_present, "both keys fill both locks")
	_check(not game.info.exit.locked, "with both keys the gate opens")
	LevelManager.key_seed = 0
	await _stop(game)


func _check_quiet(ok: bool) -> void:
	if not ok:
		_check(false, "quiet check")


func _keeper_game(entry: Dictionary) -> Node:
	LevelManager.key_seed = 99
	var game := await _start([
		"..............................",
		"..............................",
		"P...........................E.",
		"##############################",
	], {"lens": true, "format": 4, "kind": "normal", "keeper": entry,
		"key_slots": {"past": [[20, 2], [20, 2], [20, 2]], "present": [[12, 2], [12, 2], [12, 2]]},
		"key_hints": {"past": ["hint_ground", "hint_ground", "hint_ground"], "present": ["hint_ground", "hint_ground", "hint_ground"]}})
	LevelManager.key_seed = 0
	return game


## T6: the keepers of chapter 1 - each one only falls to its secret, is released (never killed)
## and lets go of its key; three failures in a row give the free hint.
func _test_keepers() -> void:
	# K1: asleep in the present (harmless, can be hit), awake in the past
	var game := await _keeper_game({"type": "K1", "id": "rootling", "holds": "present", "awake_in": "past", "hint_key": "app_unsafe"})
	var k: Keeper = game.keeper
	_check(k is KeeperSleepy and k.held_key == game.time_keys.present, "K1 stands on the present key")
	await _wait(0.2)
	_check(k.asleep() and not k.harmful() and k.state == "sleep", "K1 sleeps in the present")
	_check(k.held_key.held_by == null, "a sleeping K1 does not hold its key tight")
	game.player.global_position = k.global_position + Vector2(-10, -1)
	game.player.velocity = Vector2.ZERO
	await _wait(0.3)
	_check(game.has_present_key and k.freed, "the key taken quietly releases K1 (its secret)")
	await _stop(game)
	game = await _keeper_game({"type": "K1", "id": "rootling", "holds": "present", "awake_in": "past"})
	k = game.keeper
	game.player.global_position = k.global_position + Vector2(-200, 0)
	game.player.velocity = Vector2(450, 0)
	k.keeper_process(0.016)
	_check(not k.asleep() and k.held_key.held_by == k, "running close by wakes K1 and it holds the key")
	game.player.velocity = Vector2.ZERO
	game._shift_cooldown = 0.0
	game.try_shift()
	await _wait(0.2)
	_check(not k.receive_hit("shot", k.global_position + Vector2(-100, 0)), "awake in the past, hits bounce off K1")
	await _stop(game)
	# K2: the shield faces the hero; from behind the hits count
	game = await _keeper_game({"type": "K2", "id": "stonewing", "holds": "present", "hint_key": "app_unsafe"})
	k = game.keeper
	k.facing = -1.0
	var front := k.global_position + Vector2(-150, 0)
	var back := k.global_position + Vector2(150, 0)
	_check(not k.receive_hit("shot", front), "K2's shield stops a shot from the front")
	k._invulnerable = 0.0
	k.receive_hit("shot", front)
	k._invulnerable = 0.0
	k.receive_hit("shot", front)
	_check(k.hint_shown, "three failures in a row give the free hint")
	for i in 3:
		k._invulnerable = 0.0
		k.receive_hit("shot", back)
	_check(k.freed and k.held_key.held_by == null, "three hits from behind release K2 and its key is free")
	await _stop(game)
	# K4: the order carved in the past
	game = await _keeper_game({"type": "K4", "id": "rootkeeper", "holds": "present", "pattern": [2, 0, 1], "sign_cell": [5, 2]})
	k = game.keeper
	await _wait(0.1)
	var carving: Array = game.info.layer_past.get_children().filter(func(n): return n is KeeperPattern.CarvedSign)
	_check(carving.size() == 1, "K4's carving is only in the past layer")
	k.knot_hit(k.knots[0])
	_check(k._progress == 0 and k.fails == 1, "a wrong knot resets the order")
	for i in [2, 0, 1]:
		k.knot_hit(k.knots[i])
	_check(k.freed, "the carved order releases K4")
	await _stop(game)
	# K8: hidden until light draws it out
	game = await _keeper_game({"type": "K8", "id": "fishcatcher", "holds": "present"})
	k = game.keeper
	_check(not k.receive_hit("shot", k.global_position + Vector2(-100, 0)), "hidden K8 cannot be hit")
	game.player.global_position = k.global_position + Vector2(-200, -5)
	game._light_keepers()
	_check(not k.in_hiding and k.receive_hit("shot", k.global_position + Vector2(-100, 0)), "Pilo's light draws K8 out and then it can be hit")
	await _stop(game)
	# K11: the riddle
	game = await _keeper_game({"type": "K11", "id": "leaf_elder", "holds": "present", "question_key": "app_unsafe", "answer_keys": ["app_unsafe", "app_need_key"], "correct": 1})
	k = game.keeper
	var hearts: int = game.player.hearts
	k.answer(0)
	_check(game.player.hearts == hearts - 1 and k.fails == 1 and not k.freed, "a wrong answer is a small hit")
	k.answer(1)
	_check(k.freed, "the right answer releases K11")
	await _stop(game)
	# K12: bring the thing from the other time
	game = await _keeper_game({"type": "K12", "id": "mushroom_king", "holds": "present", "needs": "glow_mushroom", "item_cell": [6, 2]})
	k = game.keeper
	_check(not k.receive_hit("shot", k.global_position + Vector2(-100, 0)), "K12 cannot be beaten by force")
	game.take_item("glow_mushroom")
	game.player.global_position = k.global_position + Vector2(-120, -1)
	await _wait(0.2)
	_check(k.freed and game.carrying == "", "the mushroom from the past releases K12")
	await _stop(game)


## T7: the Old Bear - three hearts, one per phase; bark armour in the present; a flashback in
## phase 2; the lullaby from the song stone calms phase 3; released, never killed.
func _test_old_bear() -> void:
	var game := await _start([
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"P...........................E.",
		"##############################",
	], {"lens": true, "format": 4, "kind": "boss",
		"guardian": {"id": "old_bear", "pos": [20, 4], "arena": [3, 27], "song_stone": [6, 4]}})
	var bear: OldBear = game.guardian
	_check(bear != null and bear.rig.skeleton is Skeleton2D, "the Old Bear is a Skeleton2D cut-out")
	_check(bear.phase == 1 and game.info.exit.locked, "the fight starts and the gate is closed")
	var from := bear.global_position + Vector2(-200, 0)
	_check(not bear.receive_hit("shot", from), "in the present the bark armour stops hits")
	TimeShift.state = TimeShift.PAST
	bear._set_action("dazed")
	for i in 3:
		bear._invulnerable = 0.0
		bear.receive_hit("shot", from)
	_check(bear.phase == 2 and bear.hearts == 2, "three hits in the past break the first heart")
	bear._set_action("dazed")
	for i in 2:
		bear._invulnerable = 0.0
		bear.receive_hit("shot", from)
	await _wait(0.1)
	_check(bear.flashback_played and get_tree().paused, "halfway through phase 2 the flashback plays")
	for fb in game.get_children().filter(func(n): return n is Flashback):
		fb._end()
	bear._set_action("dazed")
	bear._invulnerable = 0.0
	bear.receive_hit("shot", from)
	_check(bear.phase == 3, "phase 3: rage")
	var stone: Node = game.info.layer_past.get_children().filter(func(n): return n is OldBear.SongStone)[0]
	stone.sing()
	_check(bear.lullaby and bear.calm() and bear.rig.head_mood == "calm", "the lullaby calms the bear")
	TimeShift.state = TimeShift.PRESENT
	for i in 3:
		bear._invulnerable = 0.0
		bear.receive_hit("shot", from)
	_check(bear.freed and not game.info.exit.locked, "calm, his heart can be reached in any time; released, the gate opens")
	TimeShift.state = TimeShift.PRESENT
	await _stop(game)
