class_name StorePopup
extends CanvasLayer
## Store panel, laid out as the approved design: cream glass panel, title on top, counter
## pill and close button at the top corner, category tabs on the left and product cards with
## green price buttons on the right. Every purchase passes the parent gate first.

signal closed

const CARD_SIZE := Vector2(196, 262)
## The products in each tab ("colors" is Pilo's look). Companions and tools show their own picture.
const TABS := {
	"packs": ["worlds_pack", "pilo_colors"],
	"companions": ["companion_dragon", "companion_lion"],
	"tools": ["tool_skateboard", "tool_balloon", "tool_toolbox", "tool_starblaster"],
}
## sku -> [loadout kind, id] for the picture
const PICTURE := {
	"companion_dragon": ["companion", "dragon"], "companion_lion": ["companion", "lion"],
	"tool_skateboard": ["tool", "skateboard"], "tool_balloon": ["tool", "balloon"],
	"tool_toolbox": ["tool", "toolbox"], "tool_starblaster": ["tool", "star_blaster"],
}

var _tab := "packs"   ## (STORE_TAB in the environment opens another tab; for screenshots)
var _tabs: Dictionary = {}
var _grid: GridContainer
var _message: Label
var _counter: PanelContainer
var _scroll: ScrollContainer
var _drag_from := -1.0


func _ready() -> void:
	if OS.has_environment("STORE_TAB"):
		_tab = OS.get_environment("STORE_TAB")
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Placement as in the design: close button top-right, tabs on the left.
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 560)
	panel.add_theme_stylebox_override("panel", UIKit.glass("panel_store", "panel", Vector4(40, 26, 40, 34)))
	center.add_child(panel)
	panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
	root.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.88, 0.88)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	# Header: title centered, [counter][close] in the top-right corner.
	var header := Control.new()
	header.custom_minimum_size = Vector2(0, 76)
	column.add_child(header)
	var title := UIKit.make_label("فروشگاه", 42, Color("5a3414"))
	title.add_theme_font_override("font", UIKit.FONT_BLACK)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(title)
	var corner := HBoxContainer.new()
	corner.add_theme_constant_override("separation", 18)
	corner.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	corner.offset_left = -300
	corner.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(corner)
	_counter = UIKit.make_counter("res://assets/ui/crystal.png", str(int(SaveManager.data.shards)), 28)
	_counter.custom_minimum_size.x = 150
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	corner.add_child(_counter)
	var close := UIKit.make_round("btn_close", 72)
	close.pressed.connect(_close)
	corner.add_child(close)

	# Body: category tabs (left) and product grid (right).
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 14)
	body.add_child(tabs)
	_add_tab(tabs, "packs", "بسته‌ها", "res://assets/ui/crystal.png")
	_add_tab(tabs, "companions", "همراه‌ها", "companion:dragon")
	_add_tab(tabs, "tools", "ابزارها", "tool:skateboard")
	_add_tab(tabs, "colors", "ظاهر پیلو", "pilo")
	# the products scroll (finger drag on phones, the wheel on a computer)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 360)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = 12
	body.add_child(_scroll)
	var grid_holder := CenterContainer.new()
	grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(grid_holder)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	grid_holder.add_child(_grid)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	_message = UIKit.make_label("هیچ مرحله‌ای به خرید نیاز ندارد. خرید فقط با اجازهٔ بزرگ‌ترها.", 20, Color("7a5a3a"))
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var restore := UIKit.make_button("بازیابی خریدها", UIKit.CREAM_BUTTON, 200, 20)
	restore.pressed.connect(_on_restore)
	footer.add_child(restore)
	footer.add_child(_message)
	_refresh()


func _add_tab(parent: VBoxContainer, id: String, text: String, icon: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(230, 86)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): UIKit.play_click())
	button.pressed.connect(func(): _set_tab(id))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var label := UIKit.make_label(text, 28, Color.WHITE)
	label.add_theme_font_override("font", UIKit.FONT_BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.name = "Label"
	if icon == "pilo":
		row.add_child(RigIcon.make("pilo", 48))
	elif icon.contains(":"):
		row.add_child(LoadoutIcon.make(icon.get_slice(":", 0), icon.get_slice(":", 1), 48))
	else:
		row.add_child(UIKit.make_icon(icon, 48))
	row.add_child(label)
	parent.add_child(button)
	_tabs[id] = button


func _set_tab(id: String) -> void:
	_tab = id
	_refresh()


func _refresh() -> void:
	for id in _tabs:
		var button: Button = _tabs[id]
		var selected: bool = id == _tab
		var style := UIKit.glass("tab_green" if selected else "tab_cream", "tab")
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, style)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var label := button.find_child("Label", true, false) as Label
		label.add_theme_color_override("font_color", Color.WHITE if selected else UIKit.NAVY)
		label.add_theme_constant_override("outline_size", 8 if selected else 0)
		label.add_theme_color_override("font_outline_color", Color("1f6e22"))
	for child in _grid.get_children():
		child.queue_free()
	(_counter.find_child("Value", true, false) as Label).text = str(int(SaveManager.data.shards))
	if _tab == "colors":
		for color_id in StoreAdapter.PILO_COLORS:
			_grid.add_child(_color_card(color_id))
	else:
		for sku in TABS.get(_tab, []):
			if StoreAdapter.PRODUCTS.has(sku):
				_grid.add_child(_pack_card(sku))
	_scroll.scroll_vertical = 0
	_pass_drags(_grid)


## Cards and their insides let a finger drag through to the scroll list (a drag that starts on
## a card still scrolls; a tap still presses the button).
func _pass_drags(node: Node) -> void:
	await get_tree().process_frame
	for child in node.find_children("*", "Control", true, false):
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS if child is Container else Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	# touch scrolling that works whatever is under the finger
	if _scroll == null or not _scroll.get_global_rect().has_point(_pointer(event)):
		if event is InputEventScreenTouch and not event.pressed:
			_drag_from = -1.0
		return
	if event is InputEventScreenTouch:
		_drag_from = event.position.y if event.pressed else -1.0
	elif event is InputEventScreenDrag and _drag_from >= 0.0:
		_scroll.scroll_vertical -= int(event.relative.y)


func _pointer(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse:
		return event.position
	return Vector2(-1, -1)


func _card(icon: Control, title: String, button: Button, ribbon := "", note := "") -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", UIKit.glass("card_white", "card", Vector4(14, 14, 14, 16)))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var label := UIKit.make_label(title, 24, Color("3a2614"))
	label.add_theme_font_override("font", UIKit.FONT_BLACK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 170
	box.add_child(label)
	if note != "":
		var small := UIKit.make_label(note, 16, Color("8a6a4a"))
		small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		small.custom_minimum_size = Vector2(170, 0)
		small.max_lines_visible = 3
		box.add_child(small)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	if ribbon != "":
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", UIKit.glass("ribbon_red", "pill_s", Vector4(14, 2, 14, 10)))
		tag.add_child(UIKit.make_label(ribbon, 18, Color.WHITE, 4, Color("8a1a1a")))
		# the ribbon hangs over the card's corner, inside the scroll area (so it is never cut off)
		tag.position = Vector2(-2, 0)
		tag.rotation = -0.12
		tag.z_index = 2
		var holder := Control.new()
		holder.custom_minimum_size = CARD_SIZE + Vector2(0, 18)
		card.position = Vector2(0, 18)
		holder.add_child(card)
		holder.add_child(tag)
		return holder
	return card


func _price_button(text: String, color: Color, enabled: bool) -> Button:
	var button := UIKit.make_button(text, color, 160, 22)
	button.custom_minimum_size = Vector2(160, 64)
	button.disabled = not enabled
	return button


func _pack_card(sku: String) -> Control:
	var product: Dictionary = StoreAdapter.PRODUCTS[sku]
	var button: Button
	if StoreAdapter.owns(sku):
		button = _price_button("گرفته شد", UIKit.GREEN, false)
	elif StoreAdapter.is_coming_soon(sku):
		button = _price_button("به‌زودی", UIKit.GREY, false)
	else:
		button = _price_button(StoreAdapter.price_label(sku).trim_prefix("قیمت: "), UIKit.GREEN, true)
		button.text = "خرید"
		button.pressed.connect(func(): _buy(sku))
	var ribbon := "ویژه" if sku == "pilo_colors" and not StoreAdapter.owns(sku) else ""
	var picture: Control
	if PICTURE.has(sku):
		picture = LoadoutIcon.make(PICTURE[sku][0], PICTURE[sku][1], 96)
	elif sku == "pilo_colors":
		picture = RigIcon.make("pilo", 96, 0.33, "happy")
	else:
		picture = UIKit.make_icon(product.icon, 96)
	return _card(picture, product.title, button, ribbon, String(product.get("description", "")))


func _color_card(color_id: String) -> Control:
	var entry: Dictionary = StoreAdapter.PILO_COLORS[color_id]
	var owned := StoreAdapter.owns(entry.sku)
	var current := String(SaveManager.data.get("pilo_color", "classic")) == color_id
	var preview := RigIcon.make("pilo", 96, float(entry.hue), "happy" if current else "idle")
	var button: Button
	if current:
		button = _price_button("انتخاب شد", UIKit.GREEN, false)
	elif owned:
		button = _price_button("انتخاب", UIKit.BLUE, true)
		button.pressed.connect(func(): _pick(color_id))
	elif String(entry.sku).begins_with("reward_"):
		button = _price_button("جایزهٔ پایان بازی", UIKit.GREY, false)
	else:
		button = _price_button("قفل", UIKit.GREY, true)
		button.pressed.connect(func(): _set_tab("packs"))
	return _card(preview, entry.title, button)


func _buy(sku: String) -> void:
	var gate := ParentGate.new()
	add_child(gate)
	var ok: bool = await gate.finished
	if not ok:
		return
	StoreAdapter.purchase(sku)
	var result: Array = await StoreAdapter.purchase_finished
	_message.text = String(result[2])
	_refresh()


func _on_restore() -> void:
	StoreAdapter.restore()
	_message.text = "خریدهای قبلی بازیابی شد."
	_refresh()


func _pick(color_id: String) -> void:
	SaveManager.data.pilo_color = color_id
	SaveManager.save_game()
	_refresh()


func _close() -> void:
	closed.emit()
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()
