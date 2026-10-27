class_name UIKit
extends RefCounted
## Shared look for menus and popups: big rounded buttons, soft panels, few words.

const FONT := preload("res://assets/fonts/Vazirmatn-FD-Bold.ttf")
const FONT_BLACK := preload("res://assets/fonts/Vazirmatn-FD-Black.ttf")

const TEXT := Color("4a2f1a")
const CREAM := Color("fff6e3")
const GREEN := Color("4cb84a")
const BLUE := Color("3f8fe0")
const ORANGE := Color("f39a2b")
const PURPLE := Color("9b5de5")
const RED := Color("e5533d")
const GREY := Color("a8a29a")
const GOLD := Color("ffd23f")
const BROWN := Color("6b3f1d")


static var _theme_ready := false


## Merges the game look into Godot's default theme, so controls under CanvasLayers
## (HUD, popups) get it too; a Window theme does not reach them.
static func ensure_theme(_tree: SceneTree = null) -> void:
	if _theme_ready:
		return
	_theme_ready = true
	ThemeDB.get_default_theme().merge_with(make_theme())


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 30
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style(CREAM))
	theme.set_stylebox("slider", "HSlider", flat(Color("e8d8bd"), 10, 7))
	theme.set_stylebox("grabber_area", "HSlider", flat(ORANGE, 10, 7))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat(ORANGE.lightened(0.1), 10, 7))
	var grabber := circle_texture(40, ORANGE.darkened(0.25))
	theme.set_icon("grabber", "HSlider", grabber)
	theme.set_icon("grabber_highlight", "HSlider", grabber)
	theme.set_stylebox("background", "ProgressBar", flat(Color(1, 1, 1, 0.85), 18, 0))
	theme.set_stylebox("fill", "ProgressBar", flat(ORANGE, 18, 0))
	return theme


static func flat(color: Color, radius := 24, margin := 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style


static func panel_style(color := CREAM) -> StyleBoxFlat:
	var style := flat(color, 36, 30)
	style.border_color = Color("e2b877")
	style.set_border_width_all(6)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	return style


static func button_style(color: Color) -> StyleBoxFlat:
	var style := flat(color, 30, 12)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.border_width_bottom = 7
	style.border_color = color.darkened(0.3)
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	return style


static func make_button(text: String, color := GREEN, min_width := 300.0, font_size := 34) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 80)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", button_style(color))
	button.add_theme_stylebox_override("hover", button_style(color.lightened(0.12)))
	var pressed := button_style(color.darkened(0.1))
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 17
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", button_style(GREY))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_color_override("font_outline_color", color.darkened(0.45))
	button.add_theme_constant_override("outline_size", 8)
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(func(): UIKit.play_click())
	return button


static func make_label(text: String, font_size := 30, color := TEXT, outline := 0, outline_color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", outline_color)
	return label


## Game-logo style text: golden letters with a thick brown outline.
static func make_title(text: String, font_size := 64) -> Label:
	var label := make_label(text, font_size, GOLD, int(font_size * 0.22), BROWN)
	label.add_theme_font_override("font", FONT_BLACK)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	label.add_theme_constant_override("shadow_offset_y", int(font_size * 0.08))
	return label


static func make_icon(path: String, icon_size := 48.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(icon_size, icon_size)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Full-screen picture that keeps its aspect ratio and fills the screen.
static func make_cover(path: String, dim := 0.0) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.color = Color(0.12, 0.08, 0.2, dim)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(shade)
	return root


## A dimmed full-screen modal with a centered panel. Returns {"root", "panel", "box"}.
static func make_modal(parent: Node, min_size := Vector2(620, 0)) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.15, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
	var tween := root.create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return {"root": root, "panel": panel, "box": box}


static func spacer(min_size := Vector2.ZERO, expand := true) -> Control:
	var control := Control.new()
	control.custom_minimum_size = min_size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return control


## Extra margins for notches / rounded corners on phones, in viewport units.
static func safe_margins(viewport: Viewport) -> Dictionary:
	var out := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	if not OS.has_feature("mobile"):
		return out
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0:
		return out
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var scale := viewport.get_visible_rect().size / window_size
	out.left = maxf(0.0, safe.position.x) * scale.x
	out.top = maxf(0.0, safe.position.y) * scale.y
	out.right = maxf(0.0, window_size.x - safe.end.x) * scale.x
	out.bottom = maxf(0.0, window_size.y - safe.end.y) * scale.y
	return out


static func circle_texture(diameter: int, color: Color) -> ImageTexture:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var radius := diameter * 0.5
	for y in diameter:
		for x in diameter:
			var d := Vector2(x + 0.5 - radius, y + 0.5 - radius).length()
			var alpha := clampf(radius - d, 0.0, 1.0)
			var shade := color.lightened(0.35) if d < radius * 0.45 else color
			image.set_pixel(x, y, Color(shade, alpha))
	return ImageTexture.create_from_image(image)


static func play_click() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var audio := tree.root.get_node_or_null("AudioManager")
	if audio:
		audio.play_sfx("click")
