extends Control
## Title screen over the key art: big buttons, very few words.


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp"))
	AudioManager.play_music("forest")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.custom_minimum_size.x = 520
	column.add_theme_constant_override("separation", 10)
	row.add_child(column)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(UIKit.spacer())
	row.add_child(side)

	column.add_child(UIKit.make_title("سفر پیلو", 88))
	var subtitle := PanelContainer.new()
	subtitle.add_theme_stylebox_override("panel", UIKit.flat(Color(1, 0.97, 0.88, 0.92), 30, 10))
	subtitle.add_child(UIKit.make_label("ماجراجویی در رنگارستان", 30, UIKit.BROWN))
	column.add_child(subtitle)

	if ProgressManager.has_progress():
		_add(column, "ادامهٔ ماجرا", UIKit.GREEN, func(): LevelManager.play_level(ProgressManager.continue_level()))
		_add(column, "نقشهٔ مرحله‌ها", UIKit.BLUE, LevelManager.goto_map)
	else:
		_add(column, "شروع ماجرا", UIKit.GREEN, func(): LevelManager.play_level(1))
	_add(column, "فروشگاه", UIKit.ORANGE, LevelManager.goto_store)
	_add(column, "تنظیمات", UIKit.PURPLE, func(): add_child(SettingsPanel.new()))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		_add(column, "خروج", UIKit.RED, func(): get_tree().quit())

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 8)
	stats.add_child(UIKit.make_icon("res://assets/ui/star.png", 40))
	stats.add_child(UIKit.make_label(str(ProgressManager.total_stars()), 30, Color.WHITE, 8, UIKit.BROWN))
	stats.add_child(UIKit.spacer(Vector2(20, 0), false))
	stats.add_child(UIKit.make_icon("res://assets/ui/crystal.png", 40))
	stats.add_child(UIKit.make_label("%d تکهٔ زمان" % int(SaveManager.data.shards), 30, Color.WHITE, 8, UIKit.BROWN))
	side.add_child(stats)


func _add(column: VBoxContainer, text: String, color: Color, callback: Callable) -> void:
	var button := UIKit.make_button(text, color, 420)
	button.custom_minimum_size.y = 72
	button.pressed.connect(callback)
	column.add_child(button)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
