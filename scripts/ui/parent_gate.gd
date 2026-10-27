class_name ParentGate
extends CanvasLayer
## Grown-up check before purchases or destructive settings: a two-digit multiplication
## entered on a keypad, which children aged 5–9 rarely solve by tapping at random.

signal finished(passed: bool)

var _answer := 0
var _typed := ""
var _question: HBoxContainer
var _display: Label
var _done := false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var modal := UIKit.make_modal(self, Vector2(560, 0))
	var box: VBoxContainer = modal.box
	box.add_theme_constant_override("separation", 8)
	box.add_child(UIKit.make_title("بخش بزرگ‌ترها", 40))
	box.add_child(UIKit.make_label("برای ادامه، از یک بزرگ‌تر کمک بگیر.", 26))
	# Separate labels in a left-to-right row keep "a × b = ?" in math order inside RTL text.
	_question = HBoxContainer.new()
	_question.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_question.alignment = BoxContainer.ALIGNMENT_CENTER
	_question.add_theme_constant_override("separation", 14)
	box.add_child(_question)
	_display = UIKit.make_label("", 40, UIKit.TEXT)
	box.add_child(_display)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	box.add_child(pad)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]:
		var label: String = {"C": "پاک", "OK": "تأیید"}.get(key, key)
		var color := UIKit.GREEN if key == "OK" else (UIKit.ORANGE if key == "C" else UIKit.BLUE)
		var button := UIKit.make_button(label, color, 140, 34)
		button.custom_minimum_size = Vector2(130, 58)
		button.pressed.connect(func(): _press(key))
		pad.add_child(button)
	var cancel := UIKit.make_button("انصراف", UIKit.GREY, 300, 26)
	cancel.custom_minimum_size.y = 58
	cancel.pressed.connect(func(): _finish(false))
	box.add_child(cancel)
	_new_question()


func _new_question() -> void:
	var a := randi_range(6, 9)
	var b := randi_range(6, 9)
	_answer = a * b
	for child in _question.get_children():
		child.queue_free()
	for part in [str(a), "×", str(b), "=", "?"]:
		_question.add_child(UIKit.make_label(part, 40, UIKit.BLUE))
	_typed = ""
	_display.text = "_"


func _press(key: String) -> void:
	match key:
		"C":
			_typed = ""
		"OK":
			if _typed != "" and int(_typed) == _answer:
				_finish(true)
				return
			AudioManager.play_sfx("reject")
			_new_question()
			return
		_:
			if _typed.length() < 3:
				_typed += key
	_display.text = _typed if _typed != "" else "_"


func _finish(passed: bool) -> void:
	if _done:
		return
	_done = true
	finished.emit(passed)
	queue_free()
