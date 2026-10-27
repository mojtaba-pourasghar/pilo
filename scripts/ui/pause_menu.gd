extends CanvasLayer
## Pause popup. Emits `action` with "resume" or "menu".

signal action(name: String)

var _closing := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Layout from the approved design: title on a yellow strip, then three glass buttons.
	var modal := UIKit.make_modal(self, Vector2(500, 0))
	var box: VBoxContainer = modal.box
	box.add_theme_constant_override("separation", 18)
	box.add_child(UIKit.make_strip_title("مکث بازی", 40))
	var buttons := [
		["ادامه بازی", UIKit.GREEN, "resume"],
		["تنظیمات", UIKit.BLUE, "settings"],
		["منو اصلی", UIKit.ORANGE, "menu"],
	]
	for entry in buttons:
		var button := UIKit.make_button(entry[0], entry[1], 380, 34)
		var id: String = entry[2]
		button.pressed.connect(func(): _on_pressed(id))
		box.add_child(button)


func _on_pressed(id: String) -> void:
	if id == "settings":
		add_child(SettingsPanel.new())
		return
	_close(id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close("resume")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close("resume")


func _close(id: String) -> void:
	if _closing:
		return
	_closing = true
	get_tree().paused = false
	action.emit(id)
	queue_free()
