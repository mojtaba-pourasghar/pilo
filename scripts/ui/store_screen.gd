extends Control
## Optional packs and Pilo colors. Every purchase passes the parent gate first.
## A note on screen reminds that no level needs a purchase.

var _cards: HBoxContainer
var _colors: HBoxContainer
var _preview: TextureRect
var _message: Label


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp", 0.45))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	header.add_child(UIKit.make_title("فروشگاه", 56))
	header.add_child(UIKit.spacer())
	var restore := UIKit.make_button("بازیابی خریدها", UIKit.BLUE, 240, 26)
	restore.pressed.connect(_on_restore)
	header.add_child(restore)
	header.add_child(UIKit.spacer(Vector2(16, 0), false))
	var back := UIKit.make_button("بازگشت", UIKit.ORANGE, 200, 30)
	back.pressed.connect(LevelManager.goto_menu)
	header.add_child(back)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	center.add_child(body)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 24)
	body.add_child(_cards)

	var wardrobe := PanelContainer.new()
	wardrobe.custom_minimum_size = Vector2(300, 0)
	body.add_child(wardrobe)
	var wardrobe_box := VBoxContainer.new()
	wardrobe_box.alignment = BoxContainer.ALIGNMENT_CENTER
	wardrobe.add_child(wardrobe_box)
	wardrobe_box.add_child(UIKit.make_label("رنگ پیلو", 32))
	_preview = UIKit.make_icon("res://assets/characters/pilo.png", 150)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/vfx/hue_shift.gdshader")
	_preview.material = material
	wardrobe_box.add_child(_preview)
	_colors = HBoxContainer.new()
	_colors.alignment = BoxContainer.ALIGNMENT_CENTER
	wardrobe_box.add_child(_colors)

	_message = UIKit.make_label("هیچ مرحله‌ای به خرید نیاز ندارد. خریدها فقط با اجازهٔ بزرگ‌ترها.", 24, Color.WHITE, 8, UIKit.BROWN)
	column.add_child(_message)
	_refresh()


func _refresh() -> void:
	for child in _cards.get_children():
		child.queue_free()
	for sku in StoreAdapter.PRODUCTS:
		_cards.add_child(_product_card(sku))
	for child in _colors.get_children():
		child.queue_free()
	var current := String(SaveManager.data.get("pilo_color", "classic"))
	for color_id in StoreAdapter.PILO_COLORS:
		var entry: Dictionary = StoreAdapter.PILO_COLORS[color_id]
		var owned := StoreAdapter.owns(entry.sku)
		var button := UIKit.make_button(entry.title, UIKit.GREEN if color_id == current else UIKit.BLUE, 64, 20)
		button.custom_minimum_size = Vector2(64, 56)
		button.disabled = not owned
		button.pressed.connect(func(): _pick_color(color_id))
		_colors.add_child(button)
	_set_preview_hue(current)


func _product_card(sku: String) -> PanelContainer:
	var product: Dictionary = StoreAdapter.PRODUCTS[sku]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(330, 0)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(UIKit.make_icon(product.icon, 96))
	box.add_child(UIKit.make_label(product.title, 30))
	var description := UIKit.make_label(product.description, 22, Color(0.35, 0.25, 0.18))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(280, 0)
	box.add_child(description)
	var button: Button
	if StoreAdapter.owns(sku):
		button = UIKit.make_button("گرفته شد", UIKit.GREEN, 240, 28)
		button.disabled = true
	elif StoreAdapter.is_coming_soon(sku):
		button = UIKit.make_button("به‌زودی", UIKit.PURPLE, 240, 28)
		button.disabled = true
	else:
		box.add_child(UIKit.make_label(StoreAdapter.price_label(sku), 22, UIKit.ORANGE))
		button = UIKit.make_button("خرید", UIKit.ORANGE, 240, 30)
		button.pressed.connect(func(): _buy(sku))
	box.add_child(button)
	return card


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


func _pick_color(color_id: String) -> void:
	SaveManager.data.pilo_color = color_id
	SaveManager.save_game()
	_refresh()


func _set_preview_hue(color_id: String) -> void:
	var entry: Dictionary = StoreAdapter.PILO_COLORS.get(color_id, StoreAdapter.PILO_COLORS.classic)
	(_preview.material as ShaderMaterial).set_shader_parameter("hue_shift", float(entry.hue))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		LevelManager.goto_menu()
