extends CanvasLayer
## In-level overlay: stars, keys, the time indicator and large touch buttons.

signal pause_pressed
signal hint_pressed

const TOUCH := {
	"left": "move_left",
	"right": "move_right",
	"jump": "jump",
	"time": "time_shift",
}
const PAST_COLOR := Color("e39a2f")
const PRESENT_COLOR := Color("2fa6d9")

var _root: Control
var _stars: Array[TextureRect] = []
var _star_box: HBoxContainer
var _key_box: HBoxContainer
var _key_label: Label
var _time_panel: PanelContainer
var _time_label: Label
var _hint_button: TextureButton
var _touch_root: Node2D
var _touch: Dictionary = {}
var _hint_tween: Tween
var _flash: ColorRect
var _title: Label
var _top: HBoxContainer


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	add_child(_root)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_root.add_child(_flash)

	var top := HBoxContainer.new()
	_top = top
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 16)
	_root.add_child(top)

	_star_box = HBoxContainer.new()
	_star_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_star_box)

	_key_box = HBoxContainer.new()
	_key_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_box.add_child(UIKit.make_icon("res://assets/ui/key.png", 46))
	_key_label = UIKit.make_label("۰", 34, Color.WHITE, 8, UIKit.BROWN)
	_key_box.add_child(_key_label)
	top.add_child(_key_box)

	top.add_child(UIKit.spacer())
	_time_panel = PanelContainer.new()
	_time_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label = UIKit.make_label("", 30, Color.WHITE, 8, Color(0, 0, 0, 0.35))
	_time_panel.add_child(_time_label)
	top.add_child(_time_panel)
	top.add_child(UIKit.spacer())

	_hint_button = _texture_button("res://assets/ui/btn_hint.png")
	_hint_button.pressed.connect(func(): hint_pressed.emit())
	top.add_child(_hint_button)
	var pause := _texture_button("res://assets/ui/btn_pause.png")
	pause.pressed.connect(func(): pause_pressed.emit())
	top.add_child(pause)

	_title = UIKit.make_title("", 56)
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.modulate.a = 0.0
	_root.add_child(_title)

	_touch_root = Node2D.new()
	_touch_root.modulate = Color(1, 1, 1, 0.82)
	add_child(_touch_root)
	for key in TOUCH:
		var button := TouchScreenButton.new()
		var texture: Texture2D = load("res://assets/ui/btn_%s.png" % key)
		button.texture_normal = texture
		button.texture_pressed = texture
		button.action = TOUCH[key]
		button.passby_press = key == "left" or key == "right"
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		button.pressed.connect(func(): button.modulate = Color(0.8, 0.8, 0.8))
		button.released.connect(func(): button.modulate = Color.WHITE)
		_touch_root.add_child(button)
		_touch[key] = button

	get_viewport().size_changed.connect(_layout)
	_layout()


func setup(title: String, star_total: int, has_keys: bool, lens_enabled: bool) -> void:
	for i in star_total:
		var star := UIKit.make_icon("res://assets/ui/star.png", 46)
		star.modulate = Color(0.2, 0.2, 0.3, 0.45)
		_star_box.add_child(star)
		_stars.append(star)
	_key_box.visible = has_keys
	_time_panel.visible = lens_enabled
	_touch["time"].visible = lens_enabled
	_title.text = title
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.8)
	tween.tween_property(_title, "modulate:a", 0.0, 0.6)


func _texture_button(path: String) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(path)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(92, 92)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): UIKit.play_click())
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	return button


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var safe := UIKit.safe_margins(get_viewport())
	var left: float = 28.0 + safe.left
	var right: float = 28.0 + safe.right
	var bottom: float = 24.0 + safe.bottom
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_left = left
	_top.offset_right = -right
	_top.offset_top = 18.0 + safe.top
	_top.offset_bottom = _top.offset_top + 92.0
	_title.position = Vector2(view.x * 0.5 - _title.size.x * 0.5, 130)
	var y: float = view.y - bottom - 160.0
	_touch.left.position = Vector2(left, y)
	_touch.right.position = Vector2(left + 175.0, y)
	_touch.left.scale = Vector2(0.9, 0.9)
	_touch.right.scale = Vector2(0.9, 0.9)
	_touch.right.position = Vector2(left + 160.0, y)
	_touch.time.scale = Vector2(0.9, 0.9)
	_touch.jump.position = Vector2(view.x - right - 160.0, y - 10.0)
	_touch.time.position = Vector2(view.x - right - 160.0 - 165.0, y + 6.0)


func set_stars(collected: Array) -> void:
	for i in _stars.size():
		var on := collected.has(i)
		var star := _stars[i]
		if on and star.modulate != Color.WHITE:
			star.modulate = Color.WHITE
			star.pivot_offset = star.size * 0.5
			create_tween().tween_property(star, "scale", Vector2.ONE, 0.3).from(Vector2(1.8, 1.8)).set_trans(Tween.TRANS_BACK)


func set_keys(count: int) -> void:
	_key_label.text = str(count)


func set_time(state: int) -> void:
	var past := state == TimeShift.PAST
	_time_label.text = "زمان: " + TimeShift.NAMES[state]
	_time_panel.add_theme_stylebox_override("panel", UIKit.flat(PAST_COLOR if past else PRESENT_COLOR, 26, 12))


func flash(color: Color) -> void:
	_flash.color = Color(color, 0.45)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.45)


func set_controls_visible(value: bool) -> void:
	_touch_root.visible = value


func pulse_hint() -> void:
	if _hint_tween and _hint_tween.is_running():
		return
	_hint_tween = create_tween().set_loops(6)
	_hint_tween.tween_property(_hint_button, "scale", Vector2(1.25, 1.25), 0.3)
	_hint_tween.tween_property(_hint_button, "scale", Vector2.ONE, 0.3)


func stop_hint_pulse() -> void:
	if _hint_tween:
		_hint_tween.kill()
	_hint_button.scale = Vector2.ONE
