extends CanvasLayer
## Short story lines with a portrait. Tap, click or jump to continue.
## Text is always shown, so the game works without sound. Lines may carry an "id";
## a recorded voice file with that id in assets/audio/voice/ plays automatically.

signal advanced

const SPEAKERS := {
	"nima": {"name": "نیما", "color": Color("e5533d"), "texture": "res://assets/characters/hero.png"},
	"pilo": {"name": "پیلو", "color": Color("f39a2b"), "texture": "res://assets/characters/pilo.png"},
	"ghubarak": {"name": "غبارک", "color": Color("8e7cc3"), "texture": ""},
	"squirrel": {"name": "سنجابک", "color": Color("a0663a"), "texture": ""},
}

var _root: Control
var _portrait: Portrait
var _name: Label
var _text: Label
var _typing: Tween
var _last_advance := 0.0


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 120)
	margin.add_theme_constant_override("margin_bottom", 30)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	column.add_child(UIKit.spacer())
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(150, 150)
	row.add_child(_portrait)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	# Under RTL layout Godot mirrors LEFT/RIGHT: LEFT is the reading start (right side).
	_name = UIKit.make_label("", 32)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texts.add_child(_name)
	_text = UIKit.make_label("", 32)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(600, 96)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(_text)
	var more := UIKit.make_label("ضربه بزن ▼", 20, Color(0.45, 0.3, 0.2, 0.7))
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	texts.add_child(more)


func play(lines: Array) -> void:
	_root.visible = true
	for line in lines:
		_show(line)
		await advanced
		AudioManager.stop_voice()
	_root.visible = false


func _show(line: Dictionary) -> void:
	var speaker: Dictionary = SPEAKERS.get(String(line.get("who", "pilo")), SPEAKERS.pilo)
	_name.text = speaker.name
	_name.add_theme_color_override("font_color", speaker.color)
	_portrait.speaker = String(line.get("who", "pilo"))
	_portrait.texture = load(speaker.texture) if speaker.texture != "" else null
	_text.text = String(line.get("text", ""))
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(_text.text.length() * 0.03, 0.3, 1.6))
	if line.has("id"):
		# Text appears at the voice's pace when a recording exists.
		if AudioManager.play_voice(String(line.id)) and _typing:
			_typing.set_speed_scale(0.8)


func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		pressed = true
	if pressed:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_advance < 0.25:
		return
	_last_advance = now
	if _text.visible_ratio < 1.0:
		if _typing:
			_typing.kill()
		_text.visible_ratio = 1.0
		return
	UIKit.play_click()
	advanced.emit()


class Portrait extends Control:
	var texture: Texture2D
	var speaker := ""
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, size.x * 0.5, Color("ffe7b8"))
		draw_arc(center, size.x * 0.5 - 3.0, 0.0, TAU, 48, Color("e2b877"), 6.0)
		if texture:
			# Show the head and shoulders: the top part of the character picture.
			var tex_size := texture.get_size()
			var region := Rect2(0, 0, tex_size.x, tex_size.x) if tex_size.y > tex_size.x * 1.4 else Rect2(Vector2.ZERO, tex_size)
			var fit := (size.x - 24.0) / maxf(region.size.x, region.size.y)
			var draw_size := region.size * fit
			draw_texture_rect_region(texture, Rect2(center - draw_size * 0.5, draw_size), region)
		elif speaker == "ghubarak":
			Ghubarak.draw_body(self, center, 1.3, t)
		elif speaker == "squirrel":
			RescueFriend.draw_squirrel(self, center + Vector2(4, 22), 1.8, t)
