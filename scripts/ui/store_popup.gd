class_name StorePopup
extends CanvasLayer
## Store panel, laid out as the approved design: cream glass panel, title on top, counter
## pill and close button at the top corner, category tabs on the left and product cards with
## green price buttons on the right. Every purchase passes the parent gate first.

signal closed

const CARD_SIZE := Vector2(190, 214)

var _tab := "packs"
var _tabs: Dictionary = {}
var _grid: GridContainer
var _message: Label
var _counter: PanelContainer


func _ready() -> void:
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
	_add_tab(tabs, "colors", "ظاهر پیلو", "res://assets/characters/pilo.png")
	var grid_holder := CenterContainer.new()
	grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid_holder)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
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
	if _tab == "packs":
		for sku in StoreAdapter.PRODUCTS:
			_grid.add_child(_pack_card(sku))
	else:
		for color_id in StoreAdapter.PILO_COLORS:
			_grid.add_child(_color_card(color_id))


func _card(icon: Control, title: String, button: Button, ribbon := "") -> Control:
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
	label.custom_minimum_size.x = 160
	box.add_child(label)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	if ribbon != "":
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", UIKit.glass("ribbon_red", "pill_s", Vector4(14, 2, 14, 10)))
		tag.add_child(UIKit.make_label(ribbon, 18, Color.WHITE, 4, Color("8a1a1a")))
		tag.position = Vector2(-14, -16)
		tag.rotation = -0.12
		tag.z_index = 2
		var holder := Control.new()
		holder.custom_minimum_size = CARD_SIZE
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
	return _card(UIKit.make_icon(product.icon, 96), product.title, button, ribbon)


func _color_card(color_id: String) -> Control:
	var entry: Dictionary = StoreAdapter.PILO_COLORS[color_id]
	var owned := StoreAdapter.owns(entry.sku)
	var current := String(SaveManager.data.get("pilo_color", "classic")) == color_id
	var preview := UIKit.make_icon("res://assets/characters/pilo.png", 96)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/vfx/hue_shift.gdshader")
	material.set_shader_parameter("hue_shift", float(entry.hue))
	preview.material = material
	var button: Button
	if current:
		button = _price_button("انتخاب شد", UIKit.GREEN, false)
	elif owned:
		button = _price_button("انتخاب", UIKit.BLUE, true)
		button.pressed.connect(func(): _pick(color_id))
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
