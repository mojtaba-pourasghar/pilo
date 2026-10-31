extends Node2D
## One playable level: builds the map, wires the events of every piece (blocks, coins,
## diamonds, shadow creatures, hazards, pipes, the time lens) and keeps the level's score.
## Hearts: a hit costs one and spills a few coins; a fall costs one and returns Nima to the
## last flag. With no hearts left Nima simply starts again from the flag with full hearts —
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
const PAST_RING := Color(1.0, 0.75, 0.3)
const PRESENT_RING := Color(0.4, 0.9, 1.0)
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
var enemies_freed := 0

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
var rival: Rival
var _tint_tween: Tween


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
	var layered := LayeredBackground.new()
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
	hud.set_coins(0)
	hud.set_diamonds(0, info.diamonds)
	if info.boss:
		hud.show_boss(info.boss.display_name(), info.boss.hp, info.boss.max_hp)
	hud.pause_pressed.connect(open_pause)
	hud.hint_pressed.connect(request_hint)
	dialogue = DIALOGUE.new()
	add_child(dialogue)

	TimeShift.time_changed.connect(_on_time_changed)
	TimeShift.reset(TimeShift.state_from_name(String(data.get("start_time", "present"))))
	AudioManager.play_music("boss" if data.has("boss") else world.music)
	AudioManager.play_ambient(String(world.get("ambient", "")))
	weather = Weather.for_level(String(world.id), level_id, int(world.first))
	_world_root.add_child(weather)
	layered.set_sway(weather.sway_material())
	Analytics.log_event("level_start", level_id)
	_start_story()


## The chapter card the first time a world opens, then the level's lines, then (in a race
## level) Kian sets off.
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
	if level_id == 1 and not Tutorial.seen() and LevelManager.override_level.is_empty():
		var tutorial := Tutorial.new()
		tutorial.hud = hud
		add_child(tutorial)
		await tutorial.finished
	if String(data.get("race", "")) == "kian":
		_start_race()


func _start_race() -> void:
	rival = Rival.new()
	rival.position = info.start + Vector2(70, 40)
	rival.goal_x = info.exit.global_position.x + 32.0 if info.exit else info.size.x - 200.0
	_world_root.add_child(rival)
	rival.arrived.connect(func():
		if not finished:
			_notice("کیان زودتر به دروازه رسید! بازهم می‌شود کلید را پیدا کرد.", UIKit.BLUE, true))
	_notice("مسابقه با کیان! زودتر به دروازه برس.", UIKit.BLUE, true)
	await get_tree().create_timer(0.8).timeout
	rival.running = true


func _physics_process(delta: float) -> void:
	if finished or player == null:
		return
	_shift_cooldown -= delta
	_notice_cooldown -= delta
	if not _busy:
		if Input.is_action_just_pressed("time_shift"):
			try_shift()
		if Input.is_action_just_pressed("pilo"):
			pilo.act(self)
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
			_notice("کلید زمان! حالا دروازه باز می‌شود.", UIKit.GREEN, true)


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
	# every defeated creature drops real coins: they jump out, then fly to Nima (+N floats up)
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


## Nima was hit: update the hearts and spill a few coins that can be caught again.
func on_player_hurt(away: float) -> void:
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
	_notice("اوه! دوباره امتحان کنیم.", UIKit.ORANGE, true)
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
	if c == "owl":
		pilo.sniff_range *= 2.0
	if c == "spark":
		pilo.attack_range *= 2.0
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

## Dark caves and castle halls: the world is dim, Nima carries a small light and Pilo glows.
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
	_notice("%s آزاد شد! دروازه باز است." % boss.display_name(), UIKit.GREEN, true)
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
		_camera.reset_smoothing()
		AudioManager.play_sfx("pipe", 1.2)
		var up := create_tween()
		up.tween_property(player, "global_position:y", target_pipe.global_position.y - player.FEET - 1.0, 0.5)
		await up.finished
	else:
		player.global_position = pipe.warp_to + Vector2(32, 64 - player.FEET - 1.0)
		_camera.reset_smoothing()
		FX.burst(_world_root, player.global_position, UIKit.GOLD, 14)
	player.velocity = Vector2.ZERO
	_set_busy(false)


# --- Time lens -------------------------------------------------------------

func try_shift() -> void:
	if not lens_enabled or _shift_cooldown > 0.0 or _respawning:
		return
	_shift_cooldown = SHIFT_COOLDOWN
	var blocker := TimeShift.find_blocker(player.get_body_rect())
	if blocker:
		AudioManager.play_sfx("reject")
		if blocker.has_method("flash_warning"):
			blocker.flash_warning()
		player.react_surprise()
		pilo.shake()
		_notice("اینجا جای امن نیست!", UIKit.RED, true, "app_unsafe")
		Analytics.log_event("shift_blocked", level_id)
		return
	TimeShift.shift()
	AudioManager.play_sfx("shift")
	var color := PAST_RING if TimeShift.state == TimeShift.PAST else PRESENT_RING
	FX.ring(_world_root, player.global_position, color)
	hud.flash(color)
	Analytics.log_event("shift", level_id)


func _on_time_changed(state: int, instant: bool) -> void:
	var tint := PAST_TINT if state == TimeShift.PAST else Color.WHITE
	if _dark:
		tint *= DARK_TINT
	if _tint_tween:
		_tint_tween.kill()
	if instant:
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
		_notice("کلید کجاست؟", UIKit.ORANGE, false, "app_need_key")


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
	if info.time_key and not has_time_key:
		_notice("دروازه قفل است؛ کلید زمان را پیدا کن!", UIKit.ORANGE, false)
		return
	if not friend_rescued:
		if info.chaser:
			_notice("اول غبارک را بگیر!", UIKit.ORANGE, false, "app_catch_first")
		else:
			_notice("اول دوستمان را نجات بده!", UIKit.ORANGE, false, "app_rescue_first")
		return
	finished = true
	_set_busy(true)
	player.velocity.x = 0.0
	player.celebrate()
	if rival and not rival.done:
		rival.running = false
		add_coins(50, player.global_position, false)
		_notice("تو از کیان زودتر رسیدی! ۵۰ سکه جایزه.", UIKit.GREEN, true)
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
	popup.action.connect(_on_complete_action)
	add_child(popup)


func _on_complete_action(id: String) -> void:
	match id:
		"next":
			LevelManager.play_level(level_id + 1)
		"retry":
			LevelManager.play_level(level_id)
		_:
			LevelManager.goto_map()


## Water or a fall: costs a heart and Nima comes back at the last flag (with full hearts
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
			LevelManager.goto_menu()


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
	FX.float_text(_world_root, player.global_position + Vector2(0, -120), text, color)
