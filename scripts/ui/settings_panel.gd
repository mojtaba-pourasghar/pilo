class_name SettingsPanel
extends CanvasLayer
## Volume, hint level and progress reset (reset is behind the parent gate).

signal closed

var _hint_buttons: Dictionary = {}


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings: Dictionary = SaveManager.data.settings
	var modal := UIKit.make_modal(self, Vector2(680, 0))
	var box: VBoxContainer = modal.box
	box.add_child(UIKit.make_strip_title("تنظیمات", 40))
	box.add_child(_slider_row("موسیقی", "music", float(settings.music)))
	box.add_child(_slider_row("صداها", "sfx", float(settings.sfx)))

	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 12)
	var hint_label := UIKit.make_label("راهنمایی", 30)
	hint_label.custom_minimum_size.x = 150
	hint_row.add_child(hint_label)
	for entry in [["more", "بیشتر"], ["less", "کمتر"]]:
		var id: String = entry[0]
		var button := UIKit.make_button(entry[1], UIKit.GREEN, 180, 28)
		button.pressed.connect(func(): _set_hints(id))
		hint_row.add_child(button)
		_hint_buttons[id] = button
	box.add_child(hint_row)
	_refresh_hints()

	var store := UIKit.make_button("فروشگاه", UIKit.ORANGE, 300, 28)
	store.pressed.connect(func(): add_child(StorePopup.new()))
	box.add_child(store)
	var reset := UIKit.make_button("پاک کردن پیشرفت", UIKit.RED, 300, 24)
	reset.pressed.connect(_on_reset)
	box.add_child(reset)
	var close := UIKit.make_button("بستن", UIKit.BLUE, 300, 28)
	close.pressed.connect(_close)
	box.add_child(close)


func _slider_row(title: String, key: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var label := UIKit.make_label(title, 30)
	label.custom_minimum_size.x = 150
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(380, 50)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float): _on_volume(key, v))
	slider.drag_ended.connect(func(_changed: bool): AudioManager.play_sfx("star"))
	row.add_child(slider)
	return row


func _on_volume(key: String, value: float) -> void:
	SaveManager.data.settings[key] = value
	AudioManager.apply_settings()


func _set_hints(id: String) -> void:
	SaveManager.data.settings.hints = id
	_refresh_hints()


func _refresh_hints() -> void:
	var current: String = SaveManager.data.settings.hints
	for id in _hint_buttons:
		var button: Button = _hint_buttons[id]
		var texture := "pill_green_s" if id == current else "pill_grey_s"
		button.add_theme_stylebox_override("normal", UIKit.glass(texture, "pill_s", Vector4(26, 6, 26, 16)))
		button.add_theme_stylebox_override("hover", UIKit.glass(texture, "pill_s", Vector4(26, 6, 26, 16)))


func _on_reset() -> void:
	var gate := ParentGate.new()
	add_child(gate)
	var ok: bool = await gate.finished
	if ok:
		SaveManager.reset_progress()
		ProgressManager.progress_changed.emit()


func _close() -> void:
	SaveManager.save_game()
	closed.emit()
	queue_free()
