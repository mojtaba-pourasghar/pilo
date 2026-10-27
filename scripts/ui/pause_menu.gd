extends CanvasLayer
## Pause popup. Emits `action` with "resume", "restart" or "map".

signal action(name: String)

var _closing := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var modal := UIKit.make_modal(self, Vector2(560, 0))
	var box: VBoxContainer = modal.box
	box.add_child(UIKit.make_title("مکث", 60))
	var buttons := [
		["ادامه", UIKit.GREEN, "resume"],
		["شروع دوباره", UIKit.BLUE, "restart"],
		["تنظیمات", UIKit.PURPLE, "settings"],
		["نقشهٔ مرحله‌ها", UIKit.ORANGE, "map"],
	]
	for entry in buttons:
		var button := UIKit.make_button(entry[0], entry[1], 420)
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
