class_name ResultV3
extends CanvasLayer
## The result screen of the v3 levels, exactly the approved design g5v3_result_v3 (SCREEN_DESIGNS): the wooden sign
## with the title, three stars over the panel (they pop in one by one; unearned ones stay as dark outlines), the
## memory photo, the gold plate with the coins, and three buttons: again, next, and the video ticket (doubles the
## coins of this run, optional, at most the daily video limit).
## Emits `action` with "retry" or "next" (the same contract as LevelComplete).

signal action(id: String)

const ART := "res://assets/art/pair1_sheets/g5v3_result_v3.png"
const SIZE := Vector2(1680, 944)
const STAR_AT := [Vector2(652, 288), Vector2(840, 246), Vector2(1016, 290)]

var stars := 1
var coins := 0
var title_key := "result_title"
var _stage: Control
var _coins_label: Label
var _doubled := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color("1d2440")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_stage = Control.new()
	_stage.size = SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage)
	var view := root.get_viewport_rect().size
	var k := minf(view.x / SIZE.x, view.y / SIZE.y)
	_stage.scale = Vector2(k, k)
	_stage.position = (view - SIZE * k) * 0.5
	_pic(ART, Rect2(Vector2.ZERO, SIZE))
	# stars: the first two painted stars are lit, the third is an empty outline. An earned star pops in over its
	# own painted place (its own cut-out); a star not earned is covered by the empty outline.
	var dark_tex: Texture2D = load("res://assets/art/pair1_sheets/g5v3_result_star_empty.png")
	var lit_own: Array = [load("res://assets/art/pair1_sheets/g5v3_result_star_lit.png"),
		load("res://assets/art/pair1_sheets/g5v3_result_star_lit2.png"), load("res://assets/art/pair1_sheets/g5v3_result_star_lit.png")]
	for i in 3:
		if i < 2 and i >= stars:
			# hide the painted lit star until it is earned (it pops in), or for good
			var cover_size := 200.0
			_tex_rect(dark_tex, Rect2(STAR_AT[i] - Vector2(cover_size, cover_size) * 0.5, Vector2(cover_size, cover_size)))
		if i >= stars:
			continue
		var sz := 150.0 if i < 2 else 168.0
		var s := _tex_rect(lit_own[i], Rect2(STAR_AT[i] - Vector2(sz, sz) * 0.5, Vector2(sz, sz)))
		s.pivot_offset = Vector2(sz, sz) * 0.5
		# the third grows out of its outline; the painted two get a bright pop
		s.scale = Vector2.ZERO if i == 2 else Vector2.ONE
		var tw := s.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35 + i * 0.35)
		tw.tween_callback(func(): AudioManager.play_sfx("star", 1.0 + i * 0.1))
		if i == 2:
			tw.tween_property(s, "scale", Vector2.ONE, 0.35)
		else:
			tw.tween_property(s, "scale", Vector2(1.25, 1.25), 0.15)
			tw.tween_property(s, "scale", Vector2.ONE, 0.25)
	DesignUI.text(_stage, Strings.t(title_key), Rect2(520, 46, 640, 120), 58, Color("fff3d0"), 10, Color("4a2410"))
	_coins_label = DesignUI.text(_stage, "", Rect2(930, 478, 300, 104), 44, Color("5a3000"), 0)
	_set_coins(coins)
	_hot(Rect2(520, 700, 170, 170), func(): _done("retry"))
	_hot(Rect2(755, 700, 170, 170), func(): _done("next"))
	_hot(Rect2(985, 735, 205, 120), _video)


func _pic(path: String, r: Rect2) -> TextureRect:
	return _tex_rect(load(path), r)


func _tex_rect(tex: Texture2D, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(t)
	return t


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


func _set_coins(n: int) -> void:
	_coins_label.text = "+" + DesignUI.fa_num(n) + " " + Strings.t("result_coins")


## The video ticket: optional, doubles this run's coins once.
func _video() -> void:
	if _doubled or coins <= 0:
		return
	if Economy.watch_ad_for("none"):
		_doubled = true
		Economy.add_coins(coins)
		_set_coins(coins * 2)
		AudioManager.play_sfx("pickup", 1.2)


func _done(id: String) -> void:
	action.emit(id)
	queue_free()
