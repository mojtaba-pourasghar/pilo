class_name Flashback
extends CanvasLayer
## A guardian's memory in the middle of phase 2 (about 8 s): a story panel with a slow camera
## move, a warm old-photo tint and one line read by the narrator. The game waits; a tap after
## two seconds skips it. Panels: assets/art/p11_story/panels.

signal finished

const LENGTH := 8.0

var panel_path := ""
var text_key := ""
var _t := 0.0
var _pic: TextureRect
var _done := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.07, 0.04, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	create_tween().tween_property(shade, "color:a", 0.85, 0.4)
	_pic = TextureRect.new()
	_pic.texture = load(panel_path) if ResourceLoader.exists(panel_path) else null
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pic.offset_top = 40
	_pic.offset_bottom = -120
	_pic.pivot_offset = Vector2(640, 300)
	_pic.modulate = Color(1.0, 0.9, 0.75, 0.0)
	add_child(_pic)
	create_tween().tween_property(_pic, "modulate:a", 1.0, 0.6)
	if text_key != "":
		var label := UIKit.make_label(Strings.t(text_key), 30, Color("fff4dc"), 8, Color(0.15, 0.1, 0.05, 0.9))
		label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		label.position = Vector2(-520, -110)
		label.size = Vector2(1040, 90)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(label)


func _process(delta: float) -> void:
	_t += delta
	_pic.scale = Vector2.ONE * (1.0 + _t * 0.012)
	if _t >= LENGTH:
		_end()


func _input(event: InputEvent) -> void:
	if _t > 2.0 and (event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed or event.is_action_pressed("jump")):
		get_viewport().set_input_as_handled()
		_end()


func _end() -> void:
	if _done:
		return
	_done = true
	get_tree().paused = false
	finished.emit()
	queue_free()
