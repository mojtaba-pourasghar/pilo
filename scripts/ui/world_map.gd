extends Control
## "Choose a world" screen, laid out as the approved design: blue glass title ribbon, round
## back button, three framed world cards (green / blue / orange) with a star counter, and
## yellow chevrons that page through the nine worlds three at a time. Tapping a world opens
## its eight levels (six, the secret one and the guardian) in the same visual language.

const FRAMES := ["frame_green", "frame_blue", "frame_orange"]
const CARD_SIZE := Vector2(320, 410)

var _content: Control
var _title: Label
var _world_id := ""
var _cards: Array[Control] = []
var _selected := 0
var _page := 0
const PER_PAGE := 3


func _ready() -> void:
	UIKit.ensure_theme()
	# Left-to-right placement as in the design (back button top-left, first world on the left).
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp", 0.15))
	AudioManager.play_music("forest")
	AudioManager.play_ambient("forest")
	AudioManager.set_past_filter(false)

	var ribbon := PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", UIKit.glass("ribbon_blue", "ribbon", Vector4(70, 10, 70, 22)))
	_title = UIKit.make_label("انتخاب جهان", 44, Color.WHITE, 8, Color("13285c"))
	_title.add_theme_font_override("font", UIKit.FONT_BLACK)
	ribbon.add_child(_title)
	ribbon.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ribbon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ribbon.offset_top = 22
	add_child(ribbon)

	var back := UIKit.make_round("btn_back", 92)
	back.position = Vector2(24, 18)
	back.pressed.connect(_back)
	add_child(back)

	# Pilo's village (companions and tools), top-right across from the back button.
	var village := UIKit.make_button("دهکده", UIKit.ORANGE, 190, 28)
	village.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	village.offset_left = -214
	village.offset_right = -24
	village.offset_top = 26
	village.offset_bottom = 90
	village.pressed.connect(LevelManager.goto_village)
	add_child(village)

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 110
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	var current := LevelManager.world_of(LevelManager.current_level)
	if not current.is_empty():
		_page = (int(current.index) - 1) / PER_PAGE
	if not current.is_empty() and ProgressManager.has_progress() and ProgressManager.is_world_open(current):
		_show_levels(current.id)
	else:
		_show_worlds()


func _back() -> void:
	if _world_id != "":
		_show_worlds()
	else:
		LevelManager.goto_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _clear() -> void:
	for child in _content.get_children():
		child.queue_free()
	_cards.clear()


# --- Worlds ----------------------------------------------------------------

func _show_worlds() -> void:
	_clear()
	_world_id = ""
	_title.text = "انتخاب جهان"
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -30
	_content.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	row.add_child(_chevron("arrow_left", -1))
	var first := _page * PER_PAGE
	for i in range(first, mini(first + PER_PAGE, LevelManager.WORLDS.size())):
		var card := _world_card(LevelManager.WORLDS[i], FRAMES[i % FRAMES.size()])
		row.add_child(card)
		_cards.append(card)
	row.add_child(_chevron("arrow_right", 1))
	_select(0)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dots.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dots.offset_top = -46
	dots.offset_bottom = -20
	var pages := int(ceil(LevelManager.WORLDS.size() / float(PER_PAGE)))
	for i in pages:
		var dot := UIKit.make_label("●" if i == _page else "○", 26, Color.WHITE, 6, Color(0, 0, 0, 0.4))
		dots.add_child(dot)
	_content.add_child(dots)


func _chevron(texture_name: String, step: int) -> TextureButton:
	var button := UIKit.make_round(texture_name, 70)
	button.custom_minimum_size = Vector2(64, 104)
	button.pressed.connect(func():
		var pages := int(ceil(LevelManager.WORLDS.size() / float(PER_PAGE)))
		_page = posmod(_page + step, pages)
		_show_worlds())
	return button


func _select(index: int) -> void:
	_selected = index
	for i in _cards.size():
		var target := Vector2(1.05, 1.05) if i == index else Vector2.ONE
		create_tween().tween_property(_cards[i], "scale", target, 0.15)


func _world_card(world: Dictionary, frame_name: String) -> Control:
	var open := ProgressManager.is_world_open(world)
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		card.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.resized.connect(func(): card.pivot_offset = card.size * 0.5)
	card.pressed.connect(func(): UIKit.play_click())
	card.pressed.connect(func(): _on_world_pressed(world))

	var picture := TextureRect.new()
	picture.texture = load(world.card)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = 22
	picture.offset_top = 22
	picture.offset_right = -22
	picture.offset_bottom = -30
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not open:
		picture.modulate = Color(0.72, 0.72, 0.78)
	card.add_child(picture)

	var frame := NinePatchRect.new()
	frame.texture = load(UIKit.GLASS + frame_name + ".png")
	var m: Vector4 = UIKit.GLASS_MARGINS.frame
	frame.patch_margin_left = int(m.x)
	frame.patch_margin_top = int(m.y)
	frame.patch_margin_right = int(m.z)
	frame.patch_margin_bottom = int(m.w)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)

	var info := VBoxContainer.new()
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -146
	info.offset_bottom = -44
	info.add_theme_constant_override("separation", 8)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(info)
	var name_label := UIKit.make_label(world.title, 34, Color.WHITE, 12, Color(0.1, 0.08, 0.15, 0.9))
	name_label.add_theme_font_override("font", UIKit.FONT_BLACK)
	info.add_child(name_label)
	var counter_text := "%d/%d" % [ProgressManager.total_stars(world.id), (world.last - world.first + 1) * 3]
	var icon := "res://assets/ui/star.png"
	if int(world.index) == 9 and not open:
		counter_text = "%d/8" % ProgressManager.legendary_count()
		icon = "res://assets/ui/crystal.png"
	var counter := UIKit.make_counter(icon, counter_text, 26)
	counter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info.add_child(counter)
	return card


func _on_world_pressed(world: Dictionary) -> void:
	if ProgressManager.is_world_open(world):
		_show_levels(world.id)
	elif int(world.index) == 9:
		AudioManager.play_sfx("reject")
		FX.float_text(self, get_viewport().get_visible_rect().size * 0.5, "۸ الماس افسانه‌ای لازم است (یکی در مرحلهٔ مخفی هر جهان)", UIKit.PURPLE)
	elif world.available:
		# A locked world is sold in the worlds pack: open the store right here.
		var store := StorePopup.new()
		store.closed.connect(func(): _show_worlds())
		add_child(store)
	else:
		AudioManager.play_sfx("reject")


# --- Levels of one world ---------------------------------------------------

func _show_levels(world_id: String) -> void:
	_clear()
	_world_id = world_id
	var world := LevelManager.world_by_id(world_id)
	_title.text = world.title
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -40
	_content.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	center.add_child(grid)
	for level_id in range(world.first, world.last + 1):
		grid.add_child(_level_tile(level_id))


func _level_tile(level_id: int) -> Button:
	var unlocked := ProgressManager.is_unlocked(level_id) and LevelManager.has_level(level_id)
	var done := ProgressManager.is_done(level_id)
	var world := LevelManager.world_of(level_id)
	var special := level_id == int(world.secret_level) or level_id == int(world.boss_level)
	var color_name := "green" if done else ("blue" if unlocked else "grey")
	if unlocked and not done and special:
		color_name = "orange"
	var button := Button.new()
	button.custom_minimum_size = Vector2(196, 176)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not unlocked
	var normal := UIKit.glass("tile_" + color_name, "tile")
	var pressed := UIKit.glass("tile_" + color_name, "tile")
	pressed.modulate_color = Color(0.86, 0.86, 0.86)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func(): UIKit.play_click())
	button.pressed.connect(func(): LevelManager.play_level(level_id))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_bottom = -10
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var outline := Color("1f3f7a") if color_name == "blue" else (Color("1f5a22") if done else Color("5c606a"))
	if unlocked:
		var number := UIKit.make_label(str(level_id - int(world.first) + 1), 56, Color.WHITE, 12, outline)
		number.add_theme_font_override("font", UIKit.FONT_BLACK)
		box.add_child(number)
	else:
		var lock := UIKit.make_icon("res://assets/ui/key.png", 60)
		lock.modulate = Color(1, 1, 1, 0.75)
		box.add_child(lock)
	var label := LevelManager.level_title(level_id)
	if level_id == int(world.secret_level):
		label = "✦ " + label
	elif level_id == int(world.boss_level):
		label = "☠ " + label
	var title := UIKit.make_label(label, 20, Color.WHITE, 6, outline)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 170
	box.add_child(title)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var found := ProgressManager.stars_of(level_id).size()
	for i in 3:
		var star := UIKit.make_icon("res://assets/ui/star.png", 32)
		star.modulate = Color.WHITE if i < found else Color(0, 0, 0, 0.3)
		stars.add_child(star)
	box.add_child(stars)
	return button
