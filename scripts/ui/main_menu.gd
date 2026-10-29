extends Control
## Title screen, laid out exactly as the approved design (assets/reference/ui_menus_design.webp):
## gear top-left, wooden logo sign with ribbon, big round play button and four white glass
## options (continue, new game, settings, exit) over the key art.

const COLUMN_CENTER := 0.6  # horizontal center of logo / buttons, as a share of screen width


func _ready() -> void:
	UIKit.ensure_theme()
	# Positions follow the design literally (gear top-left), so no RTL mirroring here;
	# Persian labels still shape right-to-left on their own.
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp"))
	AudioManager.play_music("forest")
	AudioManager.play_ambient("forest")
	AudioManager.set_past_filter(false)

	var gear := UIKit.make_round("btn_gear", 92)
	gear.position = Vector2(24, 20)
	gear.pressed.connect(func(): add_child(SettingsPanel.new()))
	add_child(gear)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	column.add_child(_logo())
	var play := UIKit.make_round("btn_play", 170)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_on_play)
	column.add_child(play)
	column.add_child(UIKit.spacer(Vector2(0, 6), false))

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 4)
	options.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(options)
	_option(options, "ادامه بازی", _on_continue)
	_option(options, "شروع جدید", func(): LevelManager.goto_intro("level"))
	_option(options, "تنظیمات", func(): add_child(SettingsPanel.new()))
	_option(options, "خروج", func(): get_tree().quit())

	var place := func():
		column.size = column.get_combined_minimum_size()
		column.position = Vector2(size.x * COLUMN_CENTER - column.size.x * 0.5, maxf(8.0, (size.y - column.size.y) * 0.5 - 8.0))
	resized.connect(place)
	column.resized.connect(place)
	place.call_deferred()


func _logo() -> Control:
	var logo := Control.new()
	logo.custom_minimum_size = Vector2(560, 226)
	var board := TextureRect.new()
	board.texture = load(UIKit.GLASS + "logo_sign.png")
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	board.set_anchors_preset(Control.PRESET_TOP_WIDE)
	board.offset_bottom = 196
	logo.add_child(board)
	var title := UIKit.make_title("سفر پیلو", 100)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 14
	title.offset_bottom = 164
	logo.add_child(title)
	var ribbon := PanelContainer.new()
	var style := UIKit.flat(Color("fff4dc"), 22, 6)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.border_color = Color("8a5a2c")
	style.set_border_width_all(4)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	ribbon.add_theme_stylebox_override("panel", style)
	var subtitle := UIKit.make_label("ماجراجویی کوچک، دنیاهای بزرگ", 26, UIKit.BROWN)
	subtitle.add_theme_font_override("font", UIKit.FONT_BLACK)
	ribbon.add_child(subtitle)
	ribbon.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ribbon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ribbon.offset_top = -52
	ribbon.offset_bottom = -4
	logo.add_child(ribbon)
	return logo


func _option(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := UIKit.make_button(text, UIKit.CREAM_BUTTON, 290, 28)
	button.custom_minimum_size = Vector2(290, 60)
	button.pressed.connect(callback)
	parent.add_child(button)


## Big play button: pick a world (as in the design flow).
func _on_play() -> void:
	LevelManager.goto_map()


func _on_continue() -> void:
	if ProgressManager.has_progress():
		LevelManager.play_level(ProgressManager.continue_level())
	else:
		LevelManager.play_level(1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
