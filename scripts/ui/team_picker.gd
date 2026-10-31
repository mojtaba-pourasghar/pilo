class_name TeamPicker
extends CanvasLayer
## In the middle of a level: pick who comes along (one companion), what is in the backpack
## (tools, as many as there are slots) and which weapon Nima holds. The game is paused while
## it is open; every change takes effect at once. Only what is owned is shown; the rest is
## bought in the village.

signal closed

var _rows: VBoxContainer
var _message: Label


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	var modal := UIKit.make_modal(self, Vector2(980, 0))
	var box: VBoxContainer = modal.box
	box.add_child(UIKit.make_strip_title("همراه، ابزار و سلاح", 36))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	box.add_child(_rows)
	_message = UIKit.make_label("یک همراه، ابزارهای کوله و یک سلاح را انتخاب کن.", 20, Color("7a5a3a"))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = 900
	box.add_child(_message)
	var close := UIKit.make_button("ادامهٔ بازی", UIKit.GREEN, 260, 28)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close)
	box.add_child(close)
	_refresh()


func _refresh() -> void:
	for child in _rows.get_children():
		child.queue_free()
	# companions (and "none")
	var companions: Array = [""]
	for id in Loadout.COMPANIONS:
		if Loadout.owns_companion(id):
			companions.append(id)
	_rows.add_child(_row("همراه", companions, "companion", func(id): return Loadout.companion() == id))
	var tools: Array = []
	var weapons: Array = []
	for id in Loadout.TOOLS:
		if not Loadout.owns_tool(id) or id == "toolbox":
			continue
		(weapons if Loadout.is_weapon(id) else tools).append(id)
	_rows.add_child(_row("کوله (%d جا)" % Loadout.slots(), tools, "tool", func(id): return Loadout.has_tool(id)))
	_rows.add_child(_row("سلاح", weapons, "weapon", func(id): return Weapons.current() == id))


func _row(title: String, ids: Array, kind: String, chosen: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := UIKit.make_label(title, 24)
	label.custom_minimum_size.x = 150
	row.add_child(label)
	if ids.is_empty():
		row.add_child(UIKit.make_label("هنوز چیزی نداری؛ در دهکده بخر.", 20, Color("9a7a5a")))
		return row
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 104)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 8)
	scroll.add_child(items)
	for id in ids:
		var on: bool = chosen.call(id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 96)
		button.focus_mode = Control.FOCUS_NONE
		var style := UIKit.flat(Color("fff6e3") if not on else Color("c9f0b0"), 18, 4)
		style.border_color = Color("4cb84a") if on else Color("d8c4a0")
		style.set_border_width_all(4 if on else 2)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, style)
		if id == "":
			var none := UIKit.make_label("هیچ", 22, Color("7a5a3a"))
			none.set_anchors_preset(Control.PRESET_FULL_RECT)
			none.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(none)
		else:
			var icon := LoadoutIcon.make("companion" if kind == "companion" else "tool", id, 80)
			icon.position = Vector2(8, 8)
			button.add_child(icon)
		button.pressed.connect(func(): _pick(kind, id))
		items.add_child(button)
	return row


func _pick(kind: String, id: String) -> void:
	UIKit.play_click()
	match kind:
		"companion":
			Loadout.pick_companion(id)
			_message.text = "بدون همراه." if id == "" else "%s: %s" % [Loadout.COMPANIONS[id].name, Loadout.COMPANIONS[id].ability]
		"tool":
			if not Loadout.toggle_tool(id):
				AudioManager.play_sfx("reject")
				_message.text = "کوله پر است؛ اول یک ابزار را بردار."
			else:
				_message.text = "%s: %s" % [Loadout.TOOLS[id].name, Loadout.TOOLS[id].use]
		"weapon":
			Weapons.pick(id)
			_message.text = "%s در دست نیماست." % Loadout.TOOLS[id].name
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("refresh_loadout"):
		game.refresh_loadout()
	_refresh()


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()
