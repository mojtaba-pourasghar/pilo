extends Node2D
## One playable level: builds the map, wires the events of every piece (blocks, coins,
## diamonds, shadow creatures, hazards, pipes, the time lens) and keeps the level's score.
## Hearts: a hit costs one and spills a few coins; a fall costs one and returns the hero to the
## last flag. With no hearts left the hero simply starts again from the flag with full hearts —
## there is no game over.

const PLAYER_SCENE := preload("res://scenes/characters/player.tscn")
const PILO_SCENE := preload("res://scenes/characters/pilo.tscn")
const HUD := preload("res://scripts/ui/hud.gd")
const DIALOGUE := preload("res://scripts/ui/dialogue_box.gd")
const PAUSE_MENU := preload("res://scripts/ui/pause_menu.gd")
const LEVEL_COMPLETE := preload("res://scripts/ui/level_complete.gd")

const SHIFT_COOLDOWN := 0.35
const PAST_TINT := Color(1.0, 0.88, 0.7)
const DARK_TINT := Color(0.28, 0.25, 0.4)
## Lens rings: blue into the past, orange back to the present (same colours as the ghost layers).
const PAST_RING := Color(0.45, 0.75, 1.0)
const PRESENT_RING := Color(1.0, 0.66, 0.3)
## Failed attempts before the hint button starts to glow, per hint setting.
const HINT_AFTER := {"more": 2, "less": 4}

var level_id := 1
var data: Dictionary = {}
var world: Dictionary = {}
var info: Dictionary = {}
var player: CharacterBody2D
var pilo: Node2D
var hud: CanvasLayer
var dialogue: CanvasLayer
var respawn_point := Vector2.ZERO
var stars_collected: Array = []
var keys := 0
var friend_rescued := true
var fails := 0
var lens_enabled := true
var finished := false
var coins := 0
var diamonds_found: Array = []
var has_time_key := false
## Format 4 (T5): two keys, one per time, at seeded places; the gate has two locks.
var two_keys := false
var has_past_key := false
var has_present_key := false
var key_placement := {}
var key_seed := 0
var clues: Array = []
var keeper: Keeper
var time_keys := {}
## The thing being carried from one time to the other (K12), "" when none.
var carrying := ""
## The chapter guardian of a boss level (format 4, kind "boss").
var guardian: ChapterBoss
var _armour_hits := 0
var enemies_freed := 0
var hearts_lost := 0
var _play_time := 0.0

var _busy := false
var _respawning := false
var _shift_cooldown := 0.0
var _notice_cooldown := 0.0
var _world_root: Node2D
var _modulate: CanvasModulate
var _background: CanvasLayer
var _camera: GameCamera
var _dark := false
var _follower: Node2D
var weather: Weather
var rival: GhostRival
var _tint_tween: Tween
var _grade: TimeGrade
var _return_wait_told := false


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	add_to_group("game")
	level_id = LevelManager.current_level
	world = LevelManager.world_of(level_id)
	data = LevelManager.load_level(level_id)
	if data.is_empty():
		push_error("Level %d has no data" % level_id)
		LevelManager.goto_map()
		return
	lens_enabled = bool(data.get("lens", true))
	var palette := LevelBuilder.make_palette(world.palette)
	palette["theme"] = String(world.id)

	_modulate = CanvasModulate.new()
	add_child(_modulate)
	_world_root = Node2D.new()
	add_child(_world_root)

	info = LevelBuilder.build(data, _world_root, self, palette)
	# chapter 1 (format 4): the five-layer scenery from the approved p6 art; older worlds keep theirs
	var layered: CanvasLayer = ForestParallax.new() if String(data.get("chapter", "")) == "ch01" else LayeredBackground.new()
	layered.level_size = info.size
	layered.world_id = String(world.id)
	_background = layered
	add_child(_background)
	move_child(_background, 0)
	friend_rescued = not info.needs_rescue
	if info.exit:
		info.exit.set_locked(not friend_rescued or info.time_key)

	player = PLAYER_SCENE.instantiate()
	player.position = info.start
	_world_root.add_child(player)
	respawn_point = info.start
	player.jumped.connect(func(): AudioManager.play_sfx("jump"))
	player.landed.connect(func(): AudioManager.play_sfx("land"))
	_camera = GameCamera.new()
	_camera.name = "Camera2D"
	_camera.target = player
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(info.size.x)
	_camera.limit_bottom = int(info.size.y)
	player.add_child(_camera)
	_camera.make_current()
	# phones and tablets: keep the screen awake while playing
	DisplayServer.screen_set_keep_on(true)

	pilo = PILO_SCENE.instantiate()
	pilo.target = player
	pilo.position = info.start + Vector2(-64, -80)
	_world_root.add_child(pilo)
	pilo.apply_color(String(SaveManager.data.get("pilo_color", "classic")))
	_apply_loadout()
	if bool(data.get("dark", false)):
		_make_dark()

	hud = HUD.new()
	add_child(hud)
	hud.setup(LevelManager.level_title(level_id), info.stars, info.keys > 0 or info.time_key, lens_enabled)
	hud.set_hearts(player.hearts, player.max_hearts)
	hud.set_weapon(Weapons.current())
	hud.set_companion(Loadout.companion())
	hud.set_coins(0)
	hud.set_diamonds(0, info.diamonds)
	if info.boss:
		hud.show_boss(info.boss.display_name(), info.boss.hp, info.boss.max_hp)
	if int(data.get("format", 2)) >= 4:
		_setup_keys()
		_spawn_guardian()
		_setup_memory()
	hud.pause_pressed.connect(open_pause)
	hud.tool_pressed.connect(use_tool)
	hud.hint_pressed.connect(request_hint)
	dialogue = DIALOGUE.new()
	add_child(dialogue)

	_grade = TimeGrade.new()
	add_child(_grade)
	TimeShift.time_changed.connect(_on_time_changed)
	TimeShift.charge_changed.connect(func(v: float): hud.set_lens_charge(v / TimeShift.MAX_CHARGE))
	TimeShift.return_countdown.connect(func(left: float): hud.set_return_countdown(left))
	TimeShift.auto_return_due.connect(_auto_return)
	TimeShift.register_layers(info.layer_past, info.layer_present)
	# every level starts in the present; the past is the lens's choice (v4 rule)
	TimeShift.reset(TimeShift.PRESENT)
	tree_exiting.connect(func():
		if TimeShift.layer_past == info.layer_past:
			TimeShift.stop())
	AudioManager.play_music("boss" if data.has("boss") else world.music)
	AudioManager.play_ambient(String(world.get("ambient", "")))
	weather = Weather.for_level(String(world.id), level_id, int(world.first))
	_world_root.add_child(weather)
	weather.set_light(String(SaveManager.data.settings.get("quality", "high")) == "low")
	layered.set_sway(weather.sway_material())
	Analytics.log_event("level_start", level_id)
	_start_story()


## The chapter card the first time a world opens, then the level's lines, then (in a race
## level) the ghost rival sets off.
func _start_story() -> void:
	if not ChapterCard.seen(String(world.id)) and LevelManager.override_level.is_empty():
		_set_busy(true)
		var card := ChapterCard.new()
		card.world_id = String(world.id)
		card.card_path = String(world.get("card", ""))
		card.dialogue = dialogue
		add_child(card)
		await card.play()
		_set_busy(false)
	await _play_lines(data.get("intro", []))
	if not clues.is_empty():
		await _play_lines([{"who": "pilo", "text": Strings.t("app_clues_title") + "\n" + "\n".join(clues.map(func(c): return "• " + String(c)))}])
	if guardian:
		guardian.start()
	if level_id == 1 and not Tutorial.seen() and LevelManager.override_level.is_empty():
		var tutorial := Tutorial.new()
		tutorial.hud = hud
		add_child(tutorial)
		await tutorial.finished
	if String(data.get("race", "")) == "ghost":
		_start_race()


func _start_race() -> void:
	rival = GhostRival.offline(level_id)
	rival.position = info.start + Vector2(70, 40)
	rival.goal_x = info.exit.global_position.x + 32.0 if info.exit else info.size.x - 200.0
	_world_root.add_child(rival)
	rival.arrived.connect(func():
		if not finished:
			_notice(Strings.t("app_race_lost"), UIKit.BLUE, true, "app_race_lost"))
	_notice(Strings.t("app_race_start"), UIKit.BLUE, true, "app_race_start")
	await get_tree().create_timer(0.8).timeout
	rival.running = true


func _physics_process(delta: float) -> void:
	if finished or player == null:
		return
	_play_time += delta
	_shift_cooldown -= delta
	_notice_cooldown -= delta
	if not _busy:
		if Input.is_action_just_pressed("time_shift"):
			try_shift()
		if Input.is_action_just_pressed("pilo"):
			_light_keepers()
			if Loadout.companion() == "" or _follower == null:
				pilo.act(self)
			else:
				_follower.act(self)
		if Input.is_action_just_pressed("swap_companion"):
			cycle_companion()
		if Input.is_action_just_pressed("team"):
			open_team()
		if Input.is_action_just_pressed("swap_weapon"):
			var weapon := Weapons.next()
			hud.set_weapon(weapon)
			AudioManager.play_sfx("click", 1.2)
			_notice(String(Weapons.LIST[weapon].name), UIKit.BLUE, true)
		if Engine.get_physics_frames() % 6 == 0:
			_magnet()
		var pipe := _warp_pipe_under_player()
		hud.show_down(pipe != null)
		if pipe and Input.is_action_pressed("down"):
			enter_pipe(pipe)
		if Input.is_action_just_pressed("hint"):
			request_hint()
		if Input.is_action_just_pressed("pause"):
			open_pause()
	if not _respawning and player.global_position.y > info.size.y + 160.0:
		on_hazard("fall")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		open_pause()


# --- The two time keys (format 4) -------------------------------------------------

func _setup_keys() -> void:
	var slots: Dictionary = data.get("key_slots", {})
	if slots.is_empty():
		return
	two_keys = true
	key_seed = LevelManager.key_seed if LevelManager.key_seed != 0 else KeyPlacer.seed_for(level_id, KeyPlacer.next_run(level_id))
	key_placement = KeyPlacer.place(slots, key_seed)
	for time in ["past", "present"]:
		if not key_placement.has(time):
			continue
		var key := TimeKey.new()
		key.key_time = TimeShift.PAST if time == "past" else TimeShift.PRESENT
		key.game = self
		var cell: Vector2i = key_placement[time]
		key.position = Vector2(cell.x * LevelBuilder.TILE + 32, cell.y * LevelBuilder.TILE + 32)
		key.set_meta("time_layer", true)
		(info.layer_past if time == "past" else info.layer_present).add_child(key)
		time_keys[time] = key
	_spawn_keeper()
	if info.exit:
		info.exit.two_locks = true
		info.exit.set_locked(true)
	hud.set_time_keys(false, false)
	# three clues: near what the past key is, near what the present key is, and the keeper's secret
	var hints: Dictionary = data.get("key_hints", {})
	clues = []
	for time in ["past", "present"]:
		var list: Array = hints.get(time, [])
		var i := int(key_placement.get(time + "_index", 0))
		if i < list.size():
			clues.append(Strings.t(String(list[i])))
	var keeper: Dictionary = data.get("keeper", {}) if data.get("keeper") is Dictionary else {}
	if keeper.has("hint_key"):
		clues.append(Strings.t(String(keeper.hint_key)))
	# the clues are said by Pilo in the dialogue box when the level starts (_start_story)


## The chapter guardian (T7): data "guardian" {"id", "pos", "arena": [left, right], "song_stone"}.
func _spawn_guardian() -> void:
	var entry = data.get("guardian")
	if not entry is Dictionary:
		return
	match String(entry.get("id", "")):
		"old_bear":
			guardian = OldBear.new()
		_:
			push_warning("guardian %s is not built yet" % entry.get("id"))
			return
	var tile := LevelBuilder.TILE
	var arena: Array = entry.get("arena", [0, 0])
	entry["arena_left"] = float(arena[0]) * tile + 64.0
	entry["arena_right"] = float(arena[1]) * tile - 64.0
	guardian.params = entry
	guardian.game = self
	guardian.position = Vector2(int(entry.pos[0]) * tile + 32, (int(entry.pos[1]) + 1) * tile)
	_world_root.add_child(guardian)
	if entry.has("song_stone"):
		var stone := OldBear.SongStone.new()
		stone.game = self
		stone.position = Vector2(int(entry.song_stone[0]) * tile + 32, (int(entry.song_stone[1]) + 1) * tile)
		stone.set_meta("time_layer", true)
		info.layer_past.add_child(stone)
	if info.exit:
		info.exit.set_locked(true)
	hud.show_boss(Strings.t("guardian_%s_name" % guardian.boss_id), guardian.hearts, guardian.max_hearts)


func on_chapter_boss_hit(b: ChapterBoss) -> void:
	_armour_hits = 0
	hud.show_boss(Strings.t("guardian_%s_name" % b.boss_id), b.hearts, b.max_hearts)
	Juice.hit(b, b.global_position + Vector2(0, -150), 0.85, "impact")


## Hits that bounce off the bark armour: after three, Pilo says to try the past.
func on_boss_armour(_b: ChapterBoss) -> void:
	_armour_hits += 1
	if _armour_hits == 3:
		_notice(Strings.t("guardian_old_bear_hint_armour"), UIKit.BLUE, true)
		if pilo.visible:
			pilo.shake()


func play_flashback(b: ChapterBoss) -> void:
	var fb := Flashback.new()
	fb.panel_path = String(b.params.get("flashback_panel", "res://assets/art/p11_story/panels/s07_bear_calm.png"))
	fb.text_key = String(b.params.get("flashback_key", "guardian_%s_flashback" % b.boss_id))
	add_child(fb)


func on_lullaby() -> void:
	if guardian and guardian is OldBear:
		guardian.hear_lullaby()
	_notice(Strings.t("guardian_old_bear_lullaby"), UIKit.GREEN, true)


func on_chapter_boss_released(b: ChapterBoss) -> void:
	hud.show_boss(Strings.t("guardian_%s_name" % b.boss_id), 0, b.max_hearts)
	for door in get_tree().get_nodes_in_group("boss_door"):
		door.open()
	if info.exit:
		info.exit.set_locked(false)
	Juice.flash(self, Color(1, 1, 0.9, 0.7), 0.6)
	SaveManager.data.hearts_of_time = maxi(int(SaveManager.data.get("hearts_of_time", 0)), int(world.index))
	await get_tree().create_timer(1.6).timeout
	await _play_lines(data.get("released", []))
	if String(data.get("chapter", "")) == "ch01" and not ProgressManager.is_done(level_id):
		# the end of chapter 1: the grandfather tells the rest over panels s07-s14
		_set_busy(true)
		var panels := StoryPanels.new()
		panels.dialogue = dialogue
		add_child(panels)
		await panels.play(StoryPanels.CHAPTER1_END)
		panels.queue_free()
		_set_busy(false)


## The memory room (kind "memory"): no keeper; reaching the glowing egg plays the chapter's
## memory (a panel and a few lines) and the egg joins; then the gate opens.
var memory_played := false


func _setup_memory() -> void:
	if String(data.get("kind", "")) != "memory" or not data.get("memory") is Dictionary:
		return
	var mem: Dictionary = data.memory
	var trigger := MemoryEgg.new()
	trigger.game = self
	trigger.egg = String(mem.get("egg", ""))
	trigger.position = Vector2(int(mem.cell[0]) * LevelBuilder.TILE + 32, (int(mem.cell[1]) + 1) * LevelBuilder.TILE)
	_world_root.add_child(trigger)
	if info.exit:
		info.exit.set_locked(true)


func play_memory(egg: String) -> void:
	if memory_played:
		return
	memory_played = true
	_set_busy(true)
	var mem: Dictionary = data.memory
	var fb := Flashback.new()
	fb.panel_path = String(mem.get("panel", ""))
	add_child(fb)
	await fb.finished
	await dialogue.play(Strings.resolve(mem.get("lines", []).duplicate(true)))
	var eggs: Array = SaveManager.data.get("eggs", [])
	if egg != "" and not eggs.has(egg):
		eggs.append(egg)
	SaveManager.data["eggs"] = eggs
	var memories: Array = SaveManager.data.get("memories", [])
	if not memories.has(String(data.get("chapter", ""))):
		memories.append(String(data.get("chapter", "")))
	SaveManager.data["memories"] = memories
	if info.exit:
		info.exit.set_locked(false)
	_set_busy(false)
	_notice(Strings.t("app_egg_found"), UIKit.GREEN, true)


func on_memory_mark(_mark: Node) -> void:
	_notice(Strings.t("app_memory_mark"), Color(0.75, 0.6, 1.0), true)


## The keeper of the level stands on the place of the key it holds (T6).
func _spawn_keeper() -> void:
	var entry = data.get("keeper")
	if not entry is Dictionary:
		return
	keeper = KeeperFactory.make(entry)
	if keeper == null:
		return
	keeper.game = self
	var holds := String(entry.get("holds", "present"))
	var cell: Vector2i
	if key_placement.has(holds):
		cell = key_placement[holds]
	else:
		var pos: Array = entry.get("pos", [10, 10])
		cell = Vector2i(int(pos[0]), int(pos[1]))
	keeper.position = Vector2(cell.x * LevelBuilder.TILE + 32, (cell.y + 1) * LevelBuilder.TILE)
	keeper.held_key = time_keys.get(holds)
	_world_root.add_child(keeper)
	if entry.has("sign_cell"):
		var carving := KeeperPattern.CarvedSign.new()
		carving.pattern = entry.get("pattern", [2, 0, 1])
		carving.position = Vector2(int(entry.sign_cell[0]) * LevelBuilder.TILE + 32, (int(entry.sign_cell[1]) + 1) * LevelBuilder.TILE)
		carving.set_meta("time_layer", true)
		info.layer_past.add_child(carving)
	if entry.has("item_cell"):
		var item := KeeperNeedsItem.CarryItem.new()
		item.id = String(entry.get("needs", "glow_mushroom"))
		item.game = self
		item.position = Vector2(int(entry.item_cell[0]) * LevelBuilder.TILE + 32, int(entry.item_cell[1]) * LevelBuilder.TILE + 32)
		item.set_meta("time_layer", true)
		info.layer_past.add_child(item)


func on_keeper_hit(_k: Keeper) -> void:
	Juice.hit(keeper, keeper.global_position + Vector2(0, -60), 0.4)


## Three failures in a row: Pilo flies to the keeper and tells the secret (free hint).
func on_keeper_hint(k: Keeper) -> void:
	if k.hint_key != "":
		_notice(Strings.t(k.hint_key), UIKit.BLUE, true)
	if pilo.visible:
		pilo.show_hint(k.global_position + Vector2(0, -80))
	Analytics.log_event("keeper_hint", level_id)


func on_keeper_released(k: Keeper) -> void:
	enemies_freed += 1
	var name_key := "keeper_%s_name" % k.keeper_id
	_notice(Strings.t("app_freed_generic_keeper", {"name": Strings.t(name_key) if Strings.has(name_key) else k.type}), UIKit.GREEN, true)
	add_coins(10, k.global_position, false)
	Analytics.log_event("keeper_released", level_id)


## K11: the riddle in the dialogue box (two answers).
func ask_riddle(k: KeeperRiddle) -> void:
	if _busy:
		k.asking = false
		return
	_set_busy(true)
	var answers: Array = k.answer_keys.map(func(key): return Strings.t(String(key)))
	var pick: int = await dialogue.ask({"who": String(k.params.get("who", "leaf_elder")), "text": Strings.t(k.question_key)}, answers)
	await get_tree().physics_frame
	_set_busy(false)
	k.answer(pick)


## K12: carrying something from one time to the other.
func take_item(id: String) -> void:
	carrying = id
	AudioManager.play_sfx("pop")
	_notice(Strings.t("app_item_taken"), UIKit.GREEN, true)
	hud.set_carry(id)


func give_item(_id: String) -> void:
	carrying = ""
	hud.set_carry("")


func on_time_key(key: TimeKey) -> void:
	# K1's secret: the key taken quietly while the keeper sleeps also releases it
	if keeper and is_instance_valid(keeper) and not keeper.freed and keeper.held_key == key:
		keeper.release()
	if key.key_time == TimeShift.PAST:
		has_past_key = true
	else:
		has_present_key = true
	AudioManager.play_sfx("key")
	FX.burst(_world_root, key.global_position, PAST_RING if key.key_time == TimeShift.PAST else PRESENT_RING, 22)
	hud.set_time_keys(has_past_key, has_present_key)
	if info.exit:
		info.exit.set_key_locks(has_past_key, has_present_key)
		if has_past_key and has_present_key and friend_rescued:
			info.exit.set_locked(false)
	_notice(Strings.t("app_both_keys" if has_past_key and has_present_key else ("app_past_key" if key.key_time == TimeShift.PAST else "app_present_key")), UIKit.GREEN, true)
	Analytics.log_event("key_" + ("past" if key.key_time == TimeShift.PAST else "present"), level_id)


# --- Score: coins, diamonds, hearts, creatures --------------------------------

func on_collect(item: Collectible) -> void:
	match item.kind:
		Collectible.Kind.COIN:
			add_coins(1, item.global_position, false)
		Collectible.Kind.DIAMOND:
			if item.index >= 0 and not diamonds_found.has(item.index):
				diamonds_found.append(item.index)
			AudioManager.play_sfx("diamond")
			FX.burst(_world_root, item.global_position, Color("62ccff"), 18)
			hud.set_diamonds(diamonds_found.size(), info.diamonds)
		Collectible.Kind.HEART:
			player.heal(1)
			AudioManager.play_sfx("heart")
			hud.set_hearts(player.hearts, player.max_hearts)
		Collectible.Kind.TIME_KEY:
			has_time_key = true
			AudioManager.play_sfx("key")
			FX.burst(_world_root, item.global_position, UIKit.GOLD, 20)
			hud.set_keys(1)
			if info.exit and friend_rescued:
				info.exit.set_locked(false)
			_notice(Strings.t("app_time_key"), UIKit.GREEN, true, "app_time_key")


func add_coins(amount: int, pos: Vector2, from_block := true) -> void:
	coins += amount
	hud.set_coins(coins)
	if not from_block:
		AudioManager.play_sfx("coin")
		FX.burst(_world_root, pos, UIKit.GOLD, 6)


func on_enemy_freed(enemy: Enemy) -> void:
	enemies_freed += 1
	SaveManager.data.pilo_xp = int(SaveManager.data.get("pilo_xp", 0)) + 1
	FX.burst(_world_root, enemy.global_position + Vector2(0, -30), Color(1, 0.9, 0.5), 14)
	Juice.hit(enemy, enemy.global_position + Vector2(0, -enemy.body_size.y * 0.6), 0.3)
	# every defeated creature drops real coins: they jump out, then fly to the hero (+N floats up)
	var amount: int = maxi(2, enemy.coins + 1)
	for i in amount:
		var coin := Collectible.new()
		coin.kind = Collectible.Kind.COIN
		coin.spill = true
		coin.game = self
		coin.position = enemy.global_position + Vector2(0, -30)
		coin.velocity = Vector2(randf_range(-220, 220), randf_range(-650, -450))
		_world_root.add_child(coin)
		get_tree().create_timer(0.5 + i * 0.08).timeout.connect(func():
			if is_instance_valid(coin) and not coin.taken:
				coin.fetch_to(player))
	FX.float_text(_world_root, enemy.global_position + Vector2(0, -90), "+%d" % amount, UIKit.GOLD)


## the hero was hit: update the hearts and spill a few coins that can be caught again.
func on_player_hurt(away: float) -> void:
	hearts_lost += 1
	hud.set_hearts(player.hearts, player.max_hearts)
	Juice.hit(player, player.global_position + Vector2(0, -20), 0.65, "impact")
	Juice.flash(self, Color(1.0, 0.15, 0.1, 0.28), 0.35)
	var spill := mini(coins, 4)
	coins -= spill
	hud.set_coins(coins)
	for i in spill:
		var coin := Collectible.new()
		coin.kind = Collectible.Kind.COIN
		coin.spill = true
		coin.game = self
		coin.position = player.global_position + Vector2(0, -30)
		coin.velocity = Vector2(away * randf_range(80, 320) * (1 if i % 2 == 0 else -1), randf_range(-700, -450))
		_world_root.add_child(coin)
	if player.hearts <= 0:
		_player_down()


## No hearts left: a short "oh!" and back to the flag with full hearts (no game over).
func _player_down() -> void:
	if _respawning:
		return
	_respawning = true
	fails += 1
	player.controls_enabled = false
	_notice(Strings.t("app_try_again"), UIKit.ORANGE, true, "app_try_again")
	pilo.shake()
	await get_tree().create_timer(0.7).timeout
	AudioManager.play_sfx("respawn")
	await player.respawn(respawn_point)
	player.hearts = player.max_hearts
	player.invulnerable = 1.0
	hud.set_hearts(player.hearts, player.max_hearts)
	player.controls_enabled = not _busy
	_respawning = false


# --- The companion and the tools ---------------------------------------------------

func _apply_loadout() -> void:
	player.apply_loadout()
	var c := Loadout.companion()
	# only one companion is out at a time: Pilo, or the one picked (Pilo then rides in the backpack)
	_set_pilo_out(c == "")
	if Loadout.has_tool("compass"):
		pilo.sniff_range *= 1.5
		for item in get_tree().get_nodes_in_group("collectible"):
			if item.kind == Collectible.Kind.DIAMOND:
				item.add_to_group("secret")
	if Loadout.has_tool("glasses") or c == "mole":
		for block in get_tree().get_nodes_in_group("block"):
			if block.kind == Block.Kind.HIDDEN:
				block.sniffed()
	if Loadout.has_tool("watch"):
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy is Enemy:
				enemy.speed *= 0.7
	if c != "":
		_follower = CompanionFollower.new()
		_follower.id = c
		_follower.target = player
		_follower.position = player.position + Vector2(-120, 0)
		_world_root.add_child(_follower)


## After a change in the team picker: the new companion, tools and weapon take effect at
## once (hearts never go up by switching).
## Button size and graphics quality changed in the settings.
func apply_display_settings() -> void:
	if hud:
		hud._layout()
	if weather:
		weather.set_light(String(SaveManager.data.settings.get("quality", "high")) == "low")


## Pilo out with the hero, or in the backpack while another companion is out.
func _set_pilo_out(out: bool) -> void:
	pilo.visible = out
	pilo.process_mode = Node.PROCESS_MODE_INHERIT if out else Node.PROCESS_MODE_DISABLED
	if out:
		pilo.global_position = player.global_position + Vector2(-80.0 * player.facing, -40.0)


## The next companion (Pilo first, then the ones the hero owns), straight from the screen.
func cycle_companion() -> void:
	if _busy or finished:
		return
	var team: Array = [""]
	for id in Loadout.COMPANIONS:
		if Loadout.owns_companion(id):
			team.append(id)
	if team.size() < 2:
		_notice(Strings.t("app_no_companion"), UIKit.ORANGE, true)
		return
	var next: String = team[(team.find(Loadout.companion()) + 1) % team.size()]
	Loadout.pick_companion(next)
	refresh_loadout()
	var name := Strings.t("companion_pilo") if next == "" else String(Loadout.COMPANIONS[next].name)
	_notice(Strings.t("app_companion_joined", {"name": name}), UIKit.GREEN, true)
	FX.burst(_world_root, player.global_position + Vector2(-80.0 * player.facing, -40.0), Color(1, 0.9, 0.5), 18)
	AudioManager.play_sfx("star", 1.2, -4.0)
	if hud:
		hud.set_companion(next)


## The three tool slots of the HUD: 0 Pilo's lantern (light: draws hidden keepers out, Pilo
## acts), 1 the guide map (shows both keys for a moment, three times a level), 2 the mirror (light
## too) - or, while carrying something between the times (K12), that thing.
var map_uses := 3


func use_tool(slot: int) -> void:
	if _busy or finished:
		return
	match slot:
		0:
			_light_keepers()
			if pilo.visible:
				pilo.act(self)
		1:
			if map_uses <= 0:
				_notice(Strings.t("app_map_empty"), UIKit.ORANGE, true)
				return
			map_uses -= 1
			for key in time_keys.values():
				if is_instance_valid(key) and not key.taken:
					FX.ring(_world_root, key.global_position, PAST_RING if key.key_time == TimeShift.PAST else PRESENT_RING)
					if pilo.visible:
						pilo.show_hint(key.global_position)
			_notice(Strings.t("app_map_used", {"n": map_uses}), UIKit.BLUE, true)
		2:
			if carrying != "":
				_notice(Strings.t("app_item_taken"), UIKit.GREEN, true)
			else:
				_light_keepers()
				FX.ring(_world_root, player.global_position, Color(0.9, 0.95, 1.0))


## Pilo's glow (and the lantern) draws hidden keepers (K8) out of hiding.
func _light_keepers() -> void:
	for k in get_tree().get_nodes_in_group("keeper_hidden"):
		if k.has_method("light_reveal") and k.global_position.distance_to(player.global_position) < 420.0:
			k.light_reveal()


func refresh_loadout() -> void:
	var hearts: int = player.hearts
	pilo.attack_range = 320.0
	pilo.sniff_range = 230.0
	if _follower:
		_follower.queue_free()
		_follower = null
	_apply_loadout()
	player.hearts = mini(hearts, player.max_hearts)
	hud.set_hearts(player.hearts, player.max_hearts)
	hud.set_weapon(Weapons.current())
	hud.set_companion(Loadout.companion())


func open_team() -> void:
	if _busy or finished or get_tree().paused:
		return
	get_tree().paused = true
	add_child(TeamPicker.new())


func _magnet() -> void:
	if not Loadout.has_tool("magnet"):
		return
	for item in get_tree().get_nodes_in_group("collectible"):
		if item.kind == Collectible.Kind.COIN and not item.taken and item.monitoring and item.global_position.distance_to(player.global_position) < 190.0:
			item.fetch_to(player)


# --- Darkness and the guardian of the world ----------------------------------------

## Dark caves and castle halls: the world is dim, the hero carries a small light and Pilo glows.
func _make_dark() -> void:
	_dark = true
	_modulate.color = DARK_TINT
	for holder in [player, pilo]:
		var light := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 512
		texture.height = 512
		light.texture = texture
		light.texture_scale = (1.6 if holder == player else 1.1) * (1.6 if Loadout.companion() == "owl" else 1.0)
		light.energy = 1.4
		light.color = Color(1.0, 0.92, 0.75) if holder == player else Color(0.6, 0.9, 1.0)
		holder.add_child(light)


func on_boss_hit(boss: Boss) -> void:
	hud.show_boss(boss.display_name(), maxi(boss.hp, 0), boss.max_hp)
	Juice.hit(boss, boss.global_position + Vector2(0, -110), 0.85, "impact")


func on_boss_freed(boss: Boss) -> void:
	hud.show_boss(boss.display_name(), 0, boss.max_hp)
	for door in get_tree().get_nodes_in_group("boss_door"):
		door.open()
	FX.burst(_world_root, boss.global_position + Vector2(0, -80), UIKit.GOLD, 40)
	Juice.hit(boss, boss.global_position + Vector2(0, -80), 1.0, "thunder")
	Juice.flash(self, Color(1, 1, 0.9, 0.7), 0.6)
	_notice(Strings.t("app_freed_generic", {"name": boss.display_name()}), UIKit.GREEN, true, "app_freed_" + boss.kind)
	SaveManager.data.hearts_of_time = maxi(int(SaveManager.data.get("hearts_of_time", 0)), int(world.index))


# --- Pipes -----------------------------------------------------------------------

func _warp_pipe_under_player() -> Pipe:
	if _respawning:
		return null
	for pipe in info.pipes.values():
		if pipe.is_warp and pipe.player_on_top(player):
			return pipe
	return null


## Down the pipe and out at its destination (often a secret room), Mario style.
func enter_pipe(pipe: Pipe) -> void:
	if _busy:
		return
	_set_busy(true)
	hud.show_down(false)
	player.velocity = Vector2.ZERO
	player.z_index = 4
	AudioManager.play_sfx("pipe")
	var down := create_tween()
	down.tween_property(player, "global_position", Vector2(pipe.global_position.x + 64.0, player.global_position.y + 90.0), 0.5)
	await down.finished
	var target_pipe: Pipe = null
	for other in info.pipes.values():
		if other != pipe and other.global_position.distance_to(pipe.warp_to) < 2.0:
			target_pipe = other
	if target_pipe:
		player.global_position = target_pipe.global_position + Vector2(64, 90)
		player.reset_physics_interpolation()
		_camera.reset_smoothing()
		AudioManager.play_sfx("pipe", 1.2)
		var up := create_tween()
		up.tween_property(player, "global_position:y", target_pipe.global_position.y - player.FEET - 1.0, 0.5)
		await up.finished
	else:
		player.global_position = pipe.warp_to + Vector2(32, 64 - player.FEET - 1.0)
		player.reset_physics_interpolation()
		_camera.reset_smoothing()
		FX.burst(_world_root, player.global_position, UIKit.GOLD, 14)
	player.velocity = Vector2.ZERO
	_set_busy(false)


# --- Time lens -------------------------------------------------------------

func try_shift() -> void:
	if not lens_enabled or _shift_cooldown > 0.0 or _respawning:
		return
	_shift_cooldown = SHIFT_COOLDOWN
	if not TimeShift.can_afford():
		AudioManager.play_sfx("reject")
		hud.flash_lens_empty()
		_notice(Strings.t("app_lens_empty"), UIKit.BLUE, true)
		return
	var blocker := TimeShift.find_blocker(player.get_body_rect())
	if blocker:
		AudioManager.play_sfx("reject")
		if blocker.has_method("flash_warning"):
			blocker.flash_warning()
		player.react_surprise()
		pilo.shake()
		_notice(Strings.t("app_unsafe"), UIKit.RED, true, "app_unsafe")
		Analytics.log_event("shift_blocked", level_id)
		return
	_do_shift(false)
	Analytics.log_event("shift", level_id)


func _do_shift(soft: bool) -> void:
	TimeShift.shift(soft)
	_return_wait_told = false
	AudioManager.play_sfx("shift", 0.85 if soft else 1.0)
	var color := PAST_RING if TimeShift.state == TimeShift.PAST else PRESENT_RING
	FX.ring(_world_root, player.global_position, color)
	_grade.wipe(player.get_global_transform_with_canvas().origin + Vector2(0, -40), TimeShift.state, 0.8 if soft else 0.45)
	hud.flash(color)


## Soft return (20 s in the past, unless switched off): back to the present as soon as it is safe.
func _auto_return() -> void:
	if finished or _respawning or TimeShift.state != TimeShift.PAST:
		return
	if TimeShift.find_blocker(player.get_body_rect()) != null:
		if not _return_wait_told:
			_return_wait_told = true
			_notice(Strings.t("app_return_wait"), UIKit.BLUE, true)
		return
	_do_shift(true)
	_notice(Strings.t("app_soft_return"), UIKit.ORANGE, true)
	Analytics.log_event("soft_return", level_id)


func _on_time_changed(state: int, instant: bool) -> void:
	# the look of each time comes from TimeGrade (same geometry, a shader for the present)
	var tint := Color.WHITE
	if _dark:
		tint *= DARK_TINT
	if _tint_tween:
		_tint_tween.kill()
	if instant:
		_grade.set_state(state)
		_modulate.color = tint
	else:
		_tint_tween = create_tween()
		_tint_tween.tween_property(_modulate, "color", tint, 0.4)
	_background.set_tint(tint, instant)
	AudioManager.set_past_filter(state == TimeShift.PAST)
	hud.set_time(state)
	pilo.on_time_changed(state, instant)


# --- Hints -----------------------------------------------------------------

## Pilo flies to the next clue ahead of the hero. With "more" hints the time pieces
## around that clue also pulse. The answer itself is never spelled out.
func request_hint() -> void:
	if _busy or finished:
		return
	var points: Array = info.hints
	hud.stop_hint_pulse()
	if points.is_empty():
		pilo.shake()
		return
	var best: Vector2 = points[points.size() - 1]
	for point in points:
		if point.x > player.global_position.x - 32.0:
			best = point
			break
	if not pilo.visible and _follower:
		_follower._mark(best)      # Pilo is in the backpack: the companion that is out shows it
	else:
		pilo.show_hint(best)
	if SaveManager.data.settings.hints == "more":
		get_tree().call_group("time_visual", "hint_flash", best, 420.0)
	Analytics.log_event("hint", level_id)


# --- Puzzle events (called by puzzle nodes) --------------------------------

func on_star_collected(index: int, pos: Vector2) -> void:
	stars_collected.append(index)
	AudioManager.play_sfx("star")
	FX.burst(_world_root, pos, UIKit.GOLD)
	hud.set_stars(stars_collected)


func on_key_collected(pos: Vector2) -> void:
	keys += 1
	AudioManager.play_sfx("key")
	FX.burst(_world_root, pos, UIKit.GOLD, 10)
	hud.set_keys(keys)


func on_door_touched(door: Door) -> void:
	if keys > 0:
		keys -= 1
		door.open()
		AudioManager.play_sfx("door")
		hud.set_keys(keys)
	else:
		pilo.shake()
		_notice(Strings.t("app_need_key"), UIKit.ORANGE, false, "app_need_key")


func on_checkpoint(checkpoint: Checkpoint) -> void:
	respawn_point = checkpoint.respawn_position()
	AudioManager.play_sfx("flag")
	AudioManager.play_sfx("star", 0.8, -6.0)
	FX.burst(_world_root, checkpoint.global_position + Vector2(48, -30), UIKit.ORANGE, 12)


func on_friend_rescued(_friend: Node) -> void:
	friend_rescued = true
	AudioManager.play_sfx("rescue")
	AudioManager.play_sfx("pop")
	AudioManager.play_sfx("chatter")
	if info.exit:
		info.exit.set_locked(false)
	await _play_lines(data.get("rescue", []))
	if info.exit and info.exit.overlaps_body(player):
		on_exit_reached()


func on_exit_reached() -> void:
	if finished:
		return
	if two_keys and not (has_past_key and has_present_key):
		_notice(Strings.t("app_need_both_keys"), UIKit.ORANGE, false)
		return
	if info.time_key and not has_time_key:
		_notice(Strings.t("app_gate_locked"), UIKit.ORANGE, false, "app_gate_locked")
		return
	if not friend_rescued:
		if info.chaser:
			_notice(Strings.t("app_catch_first"), UIKit.ORANGE, false, "app_catch_first")
		else:
			_notice(Strings.t("app_rescue_first"), UIKit.ORANGE, false, "app_rescue_first")
		return
	finished = true
	_set_busy(true)
	player.velocity.x = 0.0
	player.celebrate()
	if rival and not rival.done:
		rival.running = false
		add_coins(50, player.global_position, false)
		_notice(Strings.t("app_race_won"), UIKit.GREEN, true, "app_race_won")
	AudioManager.play_sfx("win")
	var result := ProgressManager.complete_level(level_id, stars_collected, coins, diamonds_found)
	Analytics.log_event("level_complete", level_id)
	await get_tree().create_timer(1.1).timeout
	var outro: Array = data.get("outro", [])
	if not outro.is_empty():
		await dialogue.play(outro)
	var popup := LEVEL_COMPLETE.new()
	popup.level_id = level_id
	popup.stars_found = stars_collected.size()
	popup.stars_total = info.stars
	popup.first_time = result.first_time
	popup.reward = String(result.get("reward", ""))
	popup.coins = coins
	popup.diamonds_found = diamonds_found.size()
	popup.diamonds_total = info.diamonds
	popup.freed = enemies_freed
	popup.rating = rating()
	popup.boss = String(data.get("kind", "")) == "boss"
	popup.keys = int(has_past_key) + int(has_present_key)
	Economy.on_win(popup.rating)
	var best: Dictionary = SaveManager.data.get("ratings", {})
	best[str(level_id)] = maxi(int(best.get(str(level_id), 0)), popup.rating)
	SaveManager.data["ratings"] = best
	SaveManager.save_game()
	popup.action.connect(_on_complete_action)
	add_child(popup)


## 1 star: finished; 2: no heart lost or a treasure found; 3: also a good time (40 s per 64
## columns) and no free hint from the keeper. Easy mode never gives the third (DECISIONS).
func rating() -> int:
	var r := 1
	if hearts_lost == 0 or not diamonds_found.is_empty():
		r = 2
	var par: float = 40.0 * info.size.x / (64.0 * LevelBuilder.TILE)
	var hint_used: bool = keeper != null and is_instance_valid(keeper) and keeper.hint_shown
	if r == 2 and _play_time <= par and not hint_used and not bool(SaveManager.data.settings.get("easy", false)):
		r = 3
	return r


func _on_complete_action(id: String) -> void:
	match id:
		"next":
			if String(data.get("chapter", "")) == "ch01":
				# the next level on the chapter map (it checks what is open and pays the entry)
				if level_id >= 8:
					LevelManager.goto_village()
				else:
					_next_or_map()
				return
			LevelManager.play_level(level_id + 1)
		"retry":
			if Economy.enter(level_id):
				LevelManager.play_level(level_id)
			else:
				LevelManager.goto_map()
		_:
			LevelManager.goto_map()


## Water or a fall: costs a heart and the hero comes back at the last flag (with full hearts
## when that was the last one).
func on_hazard(kind: String) -> void:
	if _respawning or finished:
		return
	_respawning = true
	fails += 1
	player.hearts -= 1
	if player.hearts <= 0:
		player.hearts = player.max_hearts
	hud.set_hearts(player.hearts, player.max_hearts)
	Analytics.log_event("respawn", level_id)
	AudioManager.play_sfx("splash" if kind == "water" else "respawn")
	player.controls_enabled = false
	await player.respawn(respawn_point)
	# A checkpoint always stands on ground; if the current time is unsafe there, switch back.
	if TimeShift.blocker_in(player.get_body_rect(), TimeShift.state) != null:
		TimeShift.shift()
	player.controls_enabled = not _busy
	_respawning = false
	if fails >= int(HINT_AFTER.get(SaveManager.data.settings.hints, 3)):
		hud.pulse_hint()


# --- Flow helpers ----------------------------------------------------------

func open_pause() -> void:
	if _busy or finished or get_tree().paused:
		return
	get_tree().paused = true
	var menu := PAUSE_MENU.new()
	menu.action.connect(_on_pause_action)
	add_child(menu)


func _on_pause_action(id: String) -> void:
	match id:
		"restart":
			LevelManager.play_level(level_id)
		"menu":
			LevelManager.goto_map()


func _play_lines(lines: Array) -> void:
	if lines.is_empty():
		return
	_set_busy(true)
	await dialogue.play(lines)
	# Wait one frame so the tap that closed the dialogue does not also make the hero jump.
	await get_tree().physics_frame
	_set_busy(false)


func _set_busy(value: bool) -> void:
	_busy = value
	if player:
		player.controls_enabled = not value and not finished
	hud.set_controls_visible(not value)


## Floating message over the hero; Pilo also says it when a recording exists (voice_id).
func _notice(text: String, color: Color = UIKit.ORANGE, force := false, voice_id := "") -> void:
	if _notice_cooldown > 0.0 and not force:
		return
	_notice_cooldown = 1.5
	if voice_id != "" and not AudioManager.is_voice_playing():
		AudioManager.play_voice(voice_id)
	FX.float_text(_world_root, player.global_position + Vector2(0, -120), Names.fmt(text), color)


func _next_or_map() -> void:
	var next := level_id + 1
	if next == 7 and WorldMapScreen.marks() < 3:
		next = 8
	if WorldMapScreen.unlocked(next) and Economy.enter(next):
		LevelManager.play_level(next)
	else:
		LevelManager.goto_map()
