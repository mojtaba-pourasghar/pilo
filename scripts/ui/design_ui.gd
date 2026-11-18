class_name DesignUI
extends RefCounted
## Builds screens exactly from the approved designs (assets/art/p9_ui/screen_*, sheet_screen_*).
## Positions come from data/ui_layout.json (written by tools/art/cut_ui.py from the same design
## pixels): every piece has a rect in 0..1 of the design. A screen is a 1280x720 "stage" (the
## design's frame) centred in the window; its background covers the whole window. The HUD instead
## anchors each piece to its corner of the screen. Kit pieces (p9_ui_*.png) are NinePatchRects;
## text never comes from a picture: labels use strings_fa.json and the Vazirmatn font.

const BASE := Vector2(1280, 720)
const LAYOUT_PATH := "res://data/ui_layout.json"
const KIT := "res://assets/art/p9_ui/"
const NAVY := Color("0d1b3d")
const GOLD_TEXT := Color("ffe9a8")
const OUTLINE := Color("1a1030")

static var _layout: Dictionary = {}
static var _cache: Dictionary = {}


static func layout(screen: String) -> Dictionary:
	if _layout.is_empty() and FileAccess.file_exists(LAYOUT_PATH):
		_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	return _layout.get(screen, {})


static func tex(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## A piece's rect on the 1280x720 stage.
static func rect(screen: String, piece: String) -> Rect2:
	var p: Dictionary = layout(screen).get("pieces", {}).get(piece, {})
	var r: Array = p.get("rect", [0, 0, 0, 0])
	return Rect2(r[0] * BASE.x, r[1] * BASE.y, r[2] * BASE.x, r[3] * BASE.y)


## An area of the design (where text or a dynamic picture goes).
static func area(screen: String, name: String) -> Rect2:
	var r: Array = layout(screen).get("areas", {}).get(name, [0, 0, 0, 0])
	return Rect2(r[0] * BASE.x, r[1] * BASE.y, r[2] * BASE.x, r[3] * BASE.y)


static func content(screen: String, piece: String) -> Rect2:
	var p: Dictionary = layout(screen).get("pieces", {}).get(piece, {})
	var r: Array = p.get("content", p.get("rect", [0, 0, 0, 0]))
	return Rect2(r[0] * BASE.x, r[1] * BASE.y, r[2] * BASE.x, r[3] * BASE.y)


static func piece_path(screen: String, piece: String, suffix := "") -> String:
	return "res://assets/art/p9_ui/cut/%s_%s%s.png" % [screen, piece, suffix]


## A full-window screen: the background covering the window and a 1280x720 stage in the middle.
## Returns the stage (add the screen's pieces to it).
static func make_stage(parent: Control, background: String) -> Control:
	var bg := TextureRect.new()
	bg.texture = tex(background)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	var stage := Control.new()
	stage.name = "Stage"
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.offset_left = -BASE.x * 0.5
	stage.offset_top = -BASE.y * 0.5
	stage.offset_right = BASE.x * 0.5
	stage.offset_bottom = BASE.y * 0.5
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stage)
	return stage


static func picture(parent: Control, path: String, r: Rect2, keep_aspect := true) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## A cut piece of the design at its own place.
static func piece(parent: Control, screen: String, name: String, suffix := "") -> TextureRect:
	return picture(parent, piece_path(screen, name, suffix), rect(screen, name), false)


## A kit piece stretched with nine-patch margins (NinePatchRect).
static func nine(parent: Control, kit_file: String, r: Rect2, margin := 40) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex(KIT + kit_file)
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n


## A pressable picture: 4% smaller and a little darker while held (03_approval §2 UI).
static func button(parent: Control, path: String, r: Rect2, on_press: Callable = Callable()) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex(path)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = r.position
	b.size = r.size
	b.pivot_offset = r.size * 0.5
	b.button_down.connect(func():
		b.scale = Vector2(0.96, 0.96)
		b.modulate = Color(0.85, 0.85, 0.85))
	b.button_up.connect(func():
		b.scale = Vector2.ONE
		b.modulate = Color.WHITE)
	if on_press.is_valid():
		b.pressed.connect(func():
			UIKit.play_click()
			on_press.call())
	parent.add_child(b)
	return b


## Right-to-left Persian label in a rect (never part of a picture).
static func text(parent: Control, value: String, r: Rect2, size := 28, color := Color.WHITE, outline := 6, outline_color := OUTLINE, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = value
	l.text_direction = Control.TEXT_DIRECTION_RTL
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_color)
	l.position = r.position
	l.size = r.size
	l.clip_text = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## Anchors a control to a corner of its parent, keeping its design position from that corner.
## corner: "tl", "tr", "bl", "br", "tc", "bc".
static func anchor(c: Control, corner: String) -> void:
	var r := Rect2(c.position, c.size)
	var ax := 0.0 if corner[1] == "l" else (1.0 if corner[1] == "r" else 0.5)
	var ay := 0.0 if corner[0] == "t" else 1.0
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = r.position.x - BASE.x * ax
	c.offset_right = r.end.x - BASE.x * ax
	c.offset_top = r.position.y - BASE.y * ay
	c.offset_bottom = r.end.y - BASE.y * ay


## Persian digits for counters.
static func fa_num(n: int) -> String:
	var digits := "۰۱۲۳۴۵۶۷۸۹"
	var s := str(n)
	var out := ""
	for ch in s:
		out += digits[int(ch)] if ch >= "0" and ch <= "9" else ch
	return out
