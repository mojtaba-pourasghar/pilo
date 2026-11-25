class_name MapV3
extends Control
## The chapter map of v3, exactly the approved design g5v3_map_v3 (SCREEN_DESIGNS): the painted valley with six
## paired nodes along the golden path (leaf = the OLD level played by the young grandfather, clock = the NEW level
## played by Arsam), the guardian's cave at the top right, the coin / diamond / heart bar on top, back (left) and
## settings (right).
## A pair's old level is open when the pair before it is finished; its new level opens after its old level.
## A finished node gets a gold medal over its padlock with its stars; the open node breathes with light.
## Pairs that are not built yet keep their padlock and say «soon».
## Levels 1 old and 1 new are free and cost no heart (CLAUDE.md rule 6).

const ART := "res://assets/art/pair1_sheets/g5v3_map_v3.png"
const SIZE := Vector2(1680, 944)
## [old node centre, new node centre] of each pair, in path order.
const PAIRS := [
	[Vector2(398, 668), Vector2(512, 668)], [Vector2(441, 336), Vector2(553, 336)], [Vector2(816, 240), Vector2(929, 240)],
	[Vector2(918, 486), Vector2(1031, 486)], [Vector2(1317, 600), Vector2(1429, 600)], [Vector2(1222, 376), Vector2(1335, 376)],
]
## The levels that exist: pair index -> [old level name, new level name, old id, new id]
const LEVELS := {0: ["old_01", "new_01", 101, 102]}
const LOCK_DY := 44.0                 ## the painted padlock sits this far below a node's centre

var _stage: Control


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	var back := ColorRect.new()
	back.color = Color("1d2440")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_stage = Control.new()
	_stage.size = SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_fit()
	get_viewport().size_changed.connect(_fit)
	var bg := TextureRect.new()
	bg.texture = load(ART)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(bg)
	DesignUI.text(_stage, DesignUI.fa_num(Economy.coins()), Rect2(500, 26, 160, 54), 30, DesignUI.GOLD_TEXT, 7)
	DesignUI.text(_stage, DesignUI.fa_num(Economy.gems()), Rect2(808, 26, 150, 54), 30, DesignUI.GOLD_TEXT, 7)
	DesignUI.text(_stage, DesignUI.fa_num(Economy.hearts()) + "/" + DesignUI.fa_num(Economy.MAX_HEARTS), Rect2(1092, 26, 150, 54), 30, DesignUI.GOLD_TEXT, 7)
	_hot(Rect2(20, 740, 160, 160), func(): LevelManager.goto_village())
	_hot(Rect2(1500, 740, 160, 160), func():
		var p := PauseScreen.new()
		p.settings_only = true
		add_child(p))
	_hot(Rect2(1330, 110, 240, 230), func(): ScreenBar.toast(_stage, Strings.t("map_guardian_soon")))
	for i in PAIRS.size():
		for era in 2:
			_node(i, era)
	AudioManager.play_music("menu")


func _fit() -> void:
	var view := get_viewport_rect().size
	var k := minf(view.x / SIZE.x, view.y / SIZE.y)
	_stage.scale = Vector2(k, k)
	_stage.position = (view - SIZE * k) * 0.5


static func level_id(pair: int, era: int) -> int:
	return int(LEVELS[pair][2 + era]) if LEVELS.has(pair) else 0


static func stars(pair: int, era: int) -> int:
	var id := level_id(pair, era)
	return int(SaveManager.data.get("ratings", {}).get(str(id), 0)) if id > 0 else 0


static func done(pair: int, era: int) -> bool:
	return stars(pair, era) > 0


## Old: open when it exists and the previous pair is finished (pair 1 always). New: open after its old level.
static func open(pair: int, era: int) -> bool:
	if not LEVELS.has(pair):
		return false
	if era == 1:
		return done(pair, 0)
	return pair == 0 or (done(pair - 1, 0) and done(pair - 1, 1))


func _node(pair: int, era: int) -> void:
	var c: Vector2 = PAIRS[pair][era]
	if open(pair, era):
		var finished := done(pair, era)
		if not finished:
			var glow := Glow.new()
			glow.position = c
			_stage.add_child(glow)
		# a gold medal over the painted padlock: open (play) or finished (its stars)
		var medal := Medal.new()
		medal.position = c + Vector2(0, LOCK_DY)
		medal.stars = stars(pair, era)
		medal.finished = finished
		_stage.add_child(medal)
	_hot(Rect2(c - Vector2(56, 56), Vector2(112, 130)), func(): _play(pair, era))


func _play(pair: int, era: int) -> void:
	if not LEVELS.has(pair):
		ScreenBar.toast(_stage, Strings.t("map_pair_soon"))
		return
	if not open(pair, era):
		ScreenBar.toast(_stage, Strings.t("map_old_first") if era == 1 else Strings.t("map_pair_locked"))
		return
	LevelManager.play_pair_level(String(LEVELS[pair][era]))


func _hot(r: Rect2, on_press: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.pressed.connect(func():
		UIKit.play_click()
		on_press.call())
	_stage.add_child(b)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		LevelManager.goto_village()


## Breathing light behind the open node (the design's glowing first pair).
class Glow extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.35 + 0.2 * sin(_t * 3.0)
		draw_arc(Vector2.ZERO, 62.0 + sin(_t * 3.0) * 4.0, 0, TAU, 48, Color(1, 0.9, 0.45, a), 7.0)
		draw_arc(Vector2.ZERO, 72.0, 0, TAU, 48, Color(1, 0.95, 0.7, a * 0.45), 3.0)


## A round gold medal drawn over the padlock: a play mark when open, three small stars when finished.
class Medal extends Node2D:
	var stars := 0
	var finished := false

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 22.0, Color("2a1f3d"))
		draw_circle(Vector2.ZERO, 19.0, Color("f2b632"))
		draw_circle(Vector2(-4, -5), 9.0, Color(1, 0.95, 0.7, 0.55))
		if not finished:
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -10), Vector2(11, 0), Vector2(-6, 10)]), Color("7a3d00"))
			return
		for i in 3:
			var p := Vector2(-12 + i * 12, 1)
			var col := Color("fff4c2") if i < stars else Color(0.45, 0.28, 0.05, 0.7)
			var pts := PackedVector2Array()
			for k in 10:
				var r := 6.0 if k % 2 == 0 else 2.6
				var a := -PI * 0.5 + k * PI / 5.0
				pts.append(p + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, col)
