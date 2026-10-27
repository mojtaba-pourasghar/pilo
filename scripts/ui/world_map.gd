extends Control
## Map of Rangarestan: three world cards, then the level grid of the chosen world.

var _content: Control
var _title: Label
var _world_id := ""


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp", 0.35))
	AudioManager.play_music("forest")
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title = UIKit.make_title("نقشهٔ رنگارستان", 56)
	header.add_child(_title)
	header.add_child(UIKit.spacer())
	var stars := HBoxContainer.new()
	stars.add_child(UIKit.make_icon("res://assets/ui/star.png", 44))
	stars.add_child(UIKit.make_label(str(ProgressManager.total_stars()), 32, Color.WHITE, 8, UIKit.BROWN))
	header.add_child(stars)
	header.add_child(UIKit.spacer(Vector2(24, 0), false))
	var back := UIKit.make_button("بازگشت", UIKit.ORANGE, 200, 30)
	back.pressed.connect(_back)
	header.add_child(back)
	_content = CenterContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_content)
	var current := LevelManager.world_of(LevelManager.current_level)
	if not current.is_empty() and ProgressManager.has_progress():
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


func _show_worlds() -> void:
	_clear()
	_world_id = ""
	_title.text = "نقشهٔ رنگارستان"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	_content.add_child(row)
	for world in LevelManager.WORLDS:
		row.add_child(_world_card(world))


func _world_card(world: Dictionary) -> Button:
	var open := ProgressManager.is_world_open(world)
	var card := Button.new()
	card.custom_minimum_size = Vector2(340, 400)
	card.focus_mode = Control.FOCUS_NONE
	var color := UIKit.GREEN if open else UIKit.GREY
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := UIKit.panel_style(Color("fff6e3") if open else Color("e9e4dc"))
		style.border_color = color if state != "hover" else color.lightened(0.2)
		card.add_theme_stylebox_override(state, style)
	card.pressed.connect(func(): _on_world_pressed(world))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_right = -18
	box.offset_top = 18
	box.offset_bottom = -18
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var picture := TextureRect.new()
	# Backgrounds are a picture plus its mirror (for seamless scrolling); show the first half.
	var full: Texture2D = load(world.background)
	var half := AtlasTexture.new()
	half.atlas = full
	half.region = Rect2(0, 0, full.get_width() * 0.5, full.get_height())
	picture.texture = half
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size = Vector2(300, 220)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not open:
		picture.modulate = Color(0.6, 0.6, 0.65)
	box.add_child(picture)
	box.add_child(UIKit.make_label(world.title, 34, UIKit.TEXT))
	if world.available:
		var total: int = (world.last - world.first + 1) * 3
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.add_child(UIKit.make_icon("res://assets/ui/star.png", 34))
		stars.add_child(UIKit.make_label("%d / %d" % [ProgressManager.total_stars(world.id), total], 28))
		box.add_child(stars)
	else:
		box.add_child(UIKit.make_label("به‌زودی", 28, UIKit.PURPLE))
	return card


func _on_world_pressed(world: Dictionary) -> void:
	if ProgressManager.is_world_open(world):
		_show_levels(world.id)
	else:
		AudioManager.play_sfx("reject")


func _show_levels(world_id: String) -> void:
	_clear()
	_world_id = world_id
	var world := LevelManager.world_by_id(world_id)
	_title.text = world.title
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	_content.add_child(grid)
	for level_id in range(world.first, world.last + 1):
		grid.add_child(_level_button(level_id))


func _level_button(level_id: int) -> Button:
	var unlocked := ProgressManager.is_unlocked(level_id) and LevelManager.has_level(level_id)
	var done := ProgressManager.is_done(level_id)
	var color := UIKit.GREEN if done else (UIKit.BLUE if unlocked else UIKit.GREY)
	var button := UIKit.make_button("", color, 200)
	button.custom_minimum_size = Vector2(200, 190)
	button.disabled = not unlocked
	button.pressed.connect(func(): LevelManager.play_level(level_id))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	if unlocked:
		box.add_child(UIKit.make_label(str(level_id), 54, Color.WHITE, 10, color.darkened(0.45)))
	else:
		var lock := UIKit.make_icon("res://assets/ui/key.png", 56)
		lock.modulate = Color(1, 1, 1, 0.6)
		box.add_child(lock)
	var title := UIKit.make_label(LevelManager.level_title(level_id), 20, Color.WHITE, 6, color.darkened(0.45))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 180
	box.add_child(title)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var found := ProgressManager.stars_of(level_id).size()
	for i in 3:
		var star := UIKit.make_icon("res://assets/ui/star.png", 30)
		star.modulate = Color.WHITE if i < found else Color(0, 0, 0, 0.3)
		stars.add_child(star)
	box.add_child(stars)
	return button
