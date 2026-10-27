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
const NAVY := Color("2b3354")
const CREAM_BUTTON := Color("fffffe")

const GLASS := "res://assets/ui/glass/"
## Nine-patch margins (left, top, right, bottom) of each glass texture family.
const GLASS_MARGINS := {
	"pill": Vector4(42, 30, 42, 46),
	"pill_s": Vector4(34, 24, 34, 36),
	"tile": Vector4(34, 34, 34, 40),
	"tab": Vector4(34, 30, 34, 40),
	"panel": Vector4(60, 60, 60, 64),
	"card": Vector4(40, 40, 40, 44),
	"strip": Vector4(44, 40, 44, 44),
	"ribbon": Vector4(40, 36, 40, 50),
	"frame": Vector4(54, 54, 54, 60),
}


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


## Glass panel (cream with a navy border, as in the approved design).
static func panel_style(_color := CREAM) -> StyleBox:
	return glass("panel_cream", "panel", Vector4(44, 40, 44, 46))


## Stretchable glass texture from assets/ui/glass (see tools/ui_art.py).
static func glass(texture_name: String, family: String, content := Vector4(-1, -1, -1, -1)) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(GLASS + texture_name + ".png")
	var m: Vector4 = GLASS_MARGINS[family]
	style.texture_margin_left = m.x
	style.texture_margin_top = m.y
	style.texture_margin_right = m.z
	style.texture_margin_bottom = m.w
	if content.x >= 0.0:
		style.content_margin_left = content.x
		style.content_margin_top = content.y
		style.content_margin_right = content.z
		style.content_margin_bottom = content.w
	return style


static func color_name(color: Color) -> String:
	if color == GREEN:
		return "green"
	if color == BLUE:
		return "blue"
	if color == ORANGE:
		return "orange"
	if color == PURPLE:
		return "purple"
	if color == RED:
		return "red"
	if color == CREAM_BUTTON:
		return "cream"
	return "grey"


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


## Glossy glass button. `color` picks the texture (GREEN, BLUE, ORANGE, PURPLE, RED,
## GREY or CREAM_BUTTON); small buttons (font < 30) use the slimmer 64px pill.
static func make_button(text: String, color := GREEN, min_width := 300.0, font_size := 34) -> Button:
	var button := Button.new()
	var small := font_size < 30
	var family := "pill_s" if small else "pill"
	var tex := "pill_%s%s" % [color_name(color), "_s" if small else ""]
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 64 if small else 80)
	button.focus_mode = Control.FOCUS_NONE
	var content := Vector4(26, 6, 26, 16) if small else Vector4(30, 8, 30, 20)
	var normal := glass(tex, family, content)
	var pressed := glass(tex, family, content + Vector4(0, 3, 0, -3))
	pressed.modulate_color = Color(0.86, 0.86, 0.86)
	var hover := glass(tex, family, content)
	hover.modulate_color = Color(1.06, 1.06, 1.06)
	var disabled := glass("pill_grey" + ("_s" if small else ""), family, content)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var on_cream := color == CREAM_BUTTON
	var text_color := NAVY if on_cream else Color.WHITE
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, text_color)
	if not on_cream:
		button.add_theme_color_override("font_outline_color", color.darkened(0.5) if color != GREY else Color("6e727c"))
		button.add_theme_constant_override("outline_size", 8)
	button.add_theme_font_override("font", FONT_BLACK)
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(func(): UIKit.play_click())
	return button


## Round glossy icon button (play, gear, back, pause, hint, close).
static func make_round(texture_name: String, diameter := 88.0) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(GLASS + texture_name + ".png")
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.focus_mode = Control.FOCUS_NONE
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.button_down.connect(func(): button.scale = Vector2(0.92, 0.92))
	button.button_up.connect(func(): button.scale = Vector2.ONE)
	button.pressed.connect(func(): UIKit.play_click())
	return button


## A dark smoky pill with an icon and a number (star / coin counters in the design).
static func make_counter(icon_path: String, text: String, font_size := 30) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", glass("pill_dark", "pill_s", Vector4(16, 4, 24, 12)))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	row.add_child(make_icon(icon_path, 44))
	var label := make_label(text, font_size, Color.WHITE)
	label.add_theme_font_override("font", FONT_BLACK)
	label.name = "Value"
	row.add_child(label)
	return pill


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
	dim.color = Color(0.1, 0.06, 0.15, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", panel_style())
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
	var tween := root.create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return {"root": root, "panel": panel, "box": box}


## Title on a pale-yellow glass strip, as at the top of the pause panel in the design.
static func make_strip_title(text: String, font_size := 40) -> PanelContainer:
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", glass("title_strip", "strip", Vector4(40, 8, 40, 14)))
	var label := make_label(text, font_size, NAVY)
	label.add_theme_font_override("font", FONT_BLACK)
	strip.add_child(label)
	return strip


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
