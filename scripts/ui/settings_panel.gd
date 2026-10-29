class_name SettingsPanel
extends CanvasLayer
## Volume of the four sound channels, hint level, the opening story, the store and starting the
## whole game over (behind the parent gate: progress is cleared and the story plays again).

signal closed

var _hint_buttons: Dictionary = {}


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings: Dictionary = SaveManager.data.settings
	var modal := UIKit.make_modal(self, Vector2(680, 0))
	var box: VBoxContainer = modal.box
	box.add_child(UIKit.make_strip_title("تنظیمات", 40))
	box.add_theme_constant_override("separation", 10)
	box.add_child(_slider_row("موسیقی", "music", float(settings.get("music", 0.7))))
	box.add_child(_slider_row("جلوه‌ها", "sfx", float(settings.get("sfx", 0.9))))
	box.add_child(_slider_row("صدای محیط", "ambient", float(settings.get("ambient", 0.8))))
	box.add_child(_slider_row("گوینده", "voice", float(settings.get("voice", 1.0))))

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

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var store := UIKit.make_button("فروشگاه", UIKit.ORANGE, 190, 26)
	store.pressed.connect(func(): add_child(StorePopup.new()))
	actions.add_child(store)
	var story := UIKit.make_button("دیدن داستان", UIKit.PURPLE, 200, 24)
	story.pressed.connect(func():
		get_tree().paused = false
		LevelManager.goto_intro())
	actions.add_child(story)
	var reset := UIKit.make_button("شروع دوباره بازی", UIKit.RED, 240, 22)
	reset.pressed.connect(_on_reset)
	actions.add_child(reset)
	var close := UIKit.make_button("بستن", UIKit.BLUE, 190, 26)
	close.pressed.connect(_close)
	actions.add_child(close)


func _slider_row(title: String, key: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var label := UIKit.make_label(title, 28)
	label.custom_minimum_size.x = 170
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(400, 44)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float): _on_volume(key, v))
	slider.drag_ended.connect(func(_changed: bool): _preview(key))
	row.add_child(slider)
	return row


## A short sample on the channel just changed, so the new level is heard right away.
func _preview(key: String) -> void:
	match key:
		"voice":
			AudioManager.play_voice("app_well_done")
		"ambient":
			pass  # the ambience loop is already playing
		_:
			AudioManager.play_sfx("star")


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
		get_tree().paused = false
		LevelManager.goto_intro()


func _close() -> void:
	SaveManager.save_game()
	closed.emit()
	queue_free()
