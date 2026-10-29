extends Control
## Pilo's village: pick the companion who comes along and fill the backpack with tools.
## Same visual language as the store (cream glass panel, tabs on the left, white cards with
## glass price buttons). Companions freed in the story join for free; others cost coins and
## diamonds earned in the levels, two (and three tools) are bought behind the parent gate.

const CARD_SIZE := Vector2(196, 262)

var _tab := "companions"
var _tabs: Dictionary = {}
var _grid: GridContainer
var _scroll: ScrollContainer
var _message: Label
var _coins: PanelContainer
var _diamonds: PanelContainer
var _slots: HBoxContainer


func _ready() -> void:
	UIKit.ensure_theme()
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp", 0.25))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1160, 676)
	panel.add_theme_stylebox_override("panel", UIKit.glass("panel_store", "panel", Vector4(36, 22, 36, 28)))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	# Header: title in the middle, wallet and close button in the top-right corner.
	var header := Control.new()
	header.custom_minimum_size = Vector2(0, 70)
	column.add_child(header)
	var title := UIKit.make_label("دهکدهٔ پیلو", 42, Color("5a3414"))
	title.add_theme_font_override("font", UIKit.FONT_BLACK)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(title)
	var corner := HBoxContainer.new()
	corner.add_theme_constant_override("separation", 14)
	corner.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	corner.offset_left = -440
	corner.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(corner)
	_coins = UIKit.make_counter("res://assets/ui/coin.png", "0", 26)
	_diamonds = UIKit.make_counter("res://assets/ui/crystal.png", "0", 26)
	for counter in [_coins, _diamonds]:
		counter.custom_minimum_size.x = 150
		counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		corner.add_child(counter)
	var close := UIKit.make_round("btn_close", 68)
	close.pressed.connect(_close)
	corner.add_child(close)

	# Body: tabs (left) and the cards (right, scrolls).
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var tabs := VBoxContainer.new()
	tabs.add_theme_constant_override("separation", 14)
	body.add_child(tabs)
	_add_tab(tabs, "companions", "همراه‌ها", "companion")
	_add_tab(tabs, "tools", "ابزارها", "tool")
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.layout_direction = Control.LAYOUT_DIRECTION_RTL   # first card on the right, as Persian reads
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_scroll.add_child(_grid)

	# Footer: the backpack (companion + tool slots) and a message line.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	column.add_child(footer)
	var bag := PanelContainer.new()
	bag.add_theme_stylebox_override("panel", UIKit.glass("pill_dark", "pill_s", Vector4(22, 6, 22, 12)))
	footer.add_child(bag)
	_slots = HBoxContainer.new()
	_slots.add_theme_constant_override("separation", 10)
	bag.add_child(_slots)
	_message = UIKit.make_label("راه اصلی هیچ مرحله‌ای به خرید نیاز ندارد.", 20, Color("7a5a3a"))
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_message)
	_refresh()


func _add_tab(parent: VBoxContainer, id: String, text: String, icon_kind: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(230, 86)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): UIKit.play_click())
	button.pressed.connect(func():
		_tab = id
		_scroll.scroll_vertical = 0
		_refresh())
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	row.add_child(LoadoutIcon.make(icon_kind, "squirrel" if icon_kind == "companion" else "hammer", 52))
	var label := UIKit.make_label(text, 28, Color.WHITE)
	label.add_theme_font_override("font", UIKit.FONT_BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.name = "Label"
	row.add_child(label)
	parent.add_child(button)
	_tabs[id] = button


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
	(_coins.find_child("Value", true, false) as Label).text = str(int(SaveManager.data.get("coins", 0)))
	(_diamonds.find_child("Value", true, false) as Label).text = str(int(SaveManager.data.get("diamonds", 0)))
	for child in _grid.get_children():
		child.queue_free()
	if _tab == "companions":
		for id in Loadout.COMPANIONS:
			_grid.add_child(_companion_card(id))
	else:
		for id in Loadout.TOOLS:
			_grid.add_child(_tool_card(id))
	_refresh_slots()


func _refresh_slots() -> void:
	for child in _slots.get_children():
		child.queue_free()
	var title := UIKit.make_label("کوله:", 24, Color.WHITE)
	title.add_theme_font_override("font", UIKit.FONT_BLACK)
	_slots.add_child(title)
	_slots.add_child(_slot("companion", Loadout.companion()))
	var tools: Array = Loadout.equipped().filter(func(t): return Loadout.owns_tool(t))
	for i in Loadout.slots():
		_slots.add_child(_slot("tool", String(tools[i]) if i < tools.size() else ""))


## One round slot in the backpack; tapping a filled one empties it.
func _slot(kind: String, id: String) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(66, 66)
	button.focus_mode = Control.FOCUS_NONE
	var style := UIKit.flat(Color(1, 1, 1, 0.16 if id == "" else 0.3), 33, 4)
	style.border_color = Color(1, 1, 1, 0.55)
	style.set_border_width_all(3)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	if id != "":
		var icon := LoadoutIcon.make(kind, id, 58)
		icon.position = Vector2(4, 4)
		button.add_child(icon)
		button.pressed.connect(func():
			UIKit.play_click()
			if kind == "companion":
				Loadout.pick_companion("")
			else:
				Loadout.toggle_tool(id)
			_refresh())
	else:
		var plus := UIKit.make_label("+", 30, Color(1, 1, 1, 0.6))
		plus.set_anchors_preset(Control.PRESET_FULL_RECT)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(plus)
	return button


# --- Cards ---------------------------------------------------------------------

func _companion_card(id: String) -> Control:
	var entry: Dictionary = Loadout.COMPANIONS[id]
	var owned := Loadout.owns_companion(id)
	var button: Button
	if Loadout.has_companion(id):
		button = _price_button("همراه نیماست", UIKit.GREEN, false)
	elif owned:
		button = _price_button("انتخاب", UIKit.BLUE, true)
		button.pressed.connect(func():
			Loadout.pick_companion(id)
			_message.text = "%s با نیما و پیلو همراه شد!" % entry.name
			_refresh())
	else:
		button = _buy_button("companion", id, entry)
	return _card(LoadoutIcon.make("companion", id, 92, not owned), String(entry.name), String(entry.ability), button, "sku" in entry and not owned)


func _tool_card(id: String) -> Control:
	var entry: Dictionary = Loadout.TOOLS[id]
	var owned := Loadout.owns_tool(id)
	var button: Button
	if id == "toolbox" and owned:
		button = _price_button("جای سوم باز شد", UIKit.GREEN, false)
	elif Loadout.has_tool(id):
		button = _price_button("در کوله", UIKit.GREEN, true)
		button.pressed.connect(func():
			Loadout.toggle_tool(id)
			_refresh())
	elif owned:
		button = _price_button("بگذار در کوله", UIKit.BLUE, true)
		button.pressed.connect(func():
			if not Loadout.toggle_tool(id):
				AudioManager.play_sfx("reject")
				_message.text = "کوله پر است. اول یک ابزار را از کوله بردار."
			_refresh())
	else:
		button = _buy_button("tool", id, entry)
	return _card(LoadoutIcon.make("tool", id, 92, not owned), String(entry.name), String(entry.use), button, "sku" in entry and not owned)


func _buy_button(kind: String, id: String, entry: Dictionary) -> Button:
	var button: Button
	if entry.has("unlock"):
		button = _price_button("قفل", UIKit.GREY, false)
		_tip(button, Loadout.price_text(entry))
	elif entry.has("sku"):
		button = _price_button("خرید", UIKit.PURPLE, true)
		button.pressed.connect(func(): _buy_sku(String(entry.sku)))
	else:
		var affordable := Loadout.can_afford(entry)
		button = _price_button(Loadout.price_text(entry), UIKit.ORANGE if affordable else UIKit.GREY, true)
		button.pressed.connect(func():
			if Loadout.buy_with_wallet(kind, id):
				AudioManager.play_sfx("coin")
				_message.text = "%s مال تو شد!" % entry.name
				if kind == "companion":
					Loadout.pick_companion(id)
				else:
					Loadout.toggle_tool(id)
			else:
				AudioManager.play_sfx("reject")
				_message.text = "سکه یا الماس کافی نیست. در مرحله‌ها بیشتر جمع کن (الماس‌ها در جاهای پنهان‌اند)."
			_refresh())
	return button


func _tip(button: Button, text: String) -> void:
	button.disabled = false
	button.add_theme_stylebox_override("normal", button.get_theme_stylebox("disabled"))
	button.add_theme_stylebox_override("hover", button.get_theme_stylebox("disabled"))
	button.pressed.connect(func():
		AudioManager.play_sfx("reject")
		_message.text = text)


func _price_button(text: String, color: Color, enabled: bool) -> Button:
	var button := UIKit.make_button(text, color, 170, 20)
	button.custom_minimum_size = Vector2(170, 60)
	button.clip_text = true
	button.disabled = not enabled
	return button


func _card(icon: Control, title: String, about: String, button: Button, paid := false) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", UIKit.glass("card_white", "card", Vector4(12, 12, 12, 14)))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var label := UIKit.make_label(title, 23, Color("3a2614"))
	label.add_theme_font_override("font", UIKit.FONT_BLACK)
	box.add_child(label)
	var text := UIKit.make_label(about, 16, Color("7a5a3a"))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(168, 48)
	text.layout_direction = Control.LAYOUT_DIRECTION_RTL
	box.add_child(text)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button)
	if not paid:
		return card
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UIKit.glass("ribbon_red", "pill_s", Vector4(14, 2, 14, 10)))
	tag.add_child(UIKit.make_label("ویژه", 18, Color.WHITE, 4, Color("8a1a1a")))
	tag.position = Vector2(-10, -10)
	tag.rotation = -0.12
	tag.z_index = 2
	var holder := Control.new()
	holder.custom_minimum_size = CARD_SIZE
	holder.add_child(card)
	holder.add_child(tag)
	return holder


func _buy_sku(sku: String) -> void:
	var gate := ParentGate.new()
	add_child(gate)
	var ok: bool = await gate.finished
	if not ok:
		return
	StoreAdapter.purchase(sku)
	var result: Array = await StoreAdapter.purchase_finished
	_message.text = String(result[2])
	_refresh()


func _close() -> void:
	LevelManager.goto_map()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func show_tab(id: String) -> void:
	_tab = id
	_refresh()
