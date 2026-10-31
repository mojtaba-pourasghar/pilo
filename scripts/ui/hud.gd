extends CanvasLayer
## In-level overlay: hearts, coins, diamonds, stars, the time key, the time indicator and
## large touch buttons (move, jump, dash, Pilo, time lens; ↓ appears on a warp pipe).

signal pause_pressed
signal hint_pressed

const TOUCH := {
	"left": "move_left",
	"right": "move_right",
	"jump": "jump",
	"dash": "dash",
	"pilo": "pilo",
	"time": "time_shift",
	"down": "down",
	"fire": "fire",
	"swap": "swap_weapon",
}
const PAST_COLOR := Color("e39a2f")
const PRESENT_COLOR := Color("2fa6d9")

var _root: Control
var _star_counter: PanelContainer
var _star_total := 3
var _key_box: PanelContainer
var _key_label: Label
var _hearts: Array = []
var _coin_label: Label
var _diamond_label: Label
var _coin_box: PanelContainer
var _boss_bar: PanelContainer
var _time_panel: PanelContainer
var _time_label: Label
var _hint_button: TextureButton
var _touch_root: Node2D
var _touch: Dictionary = {}
var _weapon_icon: LoadoutIcon
var _weapon_badge: Node2D
var _team_button: Control
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

	# Top bar from the approved design: [pause][star counter] on the right, hint on the left.
	var pause := UIKit.make_round("btn_pause", 84)
	pause.pressed.connect(func(): pause_pressed.emit())
	top.add_child(pause)
	_star_counter = UIKit.make_counter("res://assets/ui/star.png", "0", 32)
	_star_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_star_counter)
	_key_box = UIKit.make_counter("res://assets/ui/key.png", "0", 32)
	_key_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_key_box)
	_key_label = _key_box.find_child("Value", true, false)
	var hearts := PanelContainer.new()
	hearts.add_theme_stylebox_override("panel", UIKit.glass("pill_dark", "pill_s", Vector4(16, 4, 16, 12)))
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hearts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var heart_row := HBoxContainer.new()
	heart_row.add_theme_constant_override("separation", 4)
	heart_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hearts.add_child(heart_row)
	for i in 3:
		var icon := HudIcon.new()
		icon.kind = "heart"
		heart_row.add_child(icon)
		_hearts.append(icon)
	top.add_child(hearts)
	_coin_box = _counter("coin")
	_coin_label = _coin_box.find_child("Value", true, false)
	top.add_child(_coin_box)
	var diamonds := _counter("diamond")
	_diamond_label = diamonds.find_child("Value", true, false)
	top.add_child(diamonds)

	top.add_child(UIKit.spacer())
	_time_panel = PanelContainer.new()
	_time_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_label = UIKit.make_label("", 30, Color.WHITE, 8, Color(0, 0, 0, 0.35))
	_time_panel.add_child(_time_label)
	top.add_child(_time_panel)
	top.add_child(UIKit.spacer())

	# the team button (companion, backpack, weapon) next to the hint
	var team := TextureButton.new()
	team.texture_normal = load("res://assets/ui/backpack.png")
	team.ignore_texture_size = true
	team.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	team.custom_minimum_size = Vector2(78, 78)
	team.focus_mode = Control.FOCUS_NONE
	team.pressed.connect(func():
		UIKit.play_click()
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.open_team())
	top.add_child(team)
	_team_button = team
	_hint_button = UIKit.make_round("btn_hint", 84)
	_hint_button.pressed.connect(func(): hint_pressed.emit())
	top.add_child(_hint_button)

	_title = UIKit.make_title("", 56)
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.modulate.a = 0.0
	_root.add_child(_title)

	_touch_root = Node2D.new()
	add_child(_touch_root)
	for key in TOUCH:
		var button := TouchScreenButton.new()
		var texture: Texture2D = load(UIKit.GLASS + "touch_%s.png" % key)
		button.texture_normal = texture
		button.texture_pressed = texture
		button.action = TOUCH[key]
		button.passby_press = key == "left" or key == "right"
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		button.pressed.connect(func(): button.modulate = Color(0.8, 0.8, 0.8))
		button.released.connect(func(): button.modulate = Color.WHITE)
		_touch_root.add_child(button)
		_touch[key] = button

	# the current weapon, shown on the fire button
	_weapon_badge = Badge.new()
	_touch_root.add_child(_weapon_badge)
	_weapon_icon = LoadoutIcon.make("tool", "slingshot", 58.0)
	_weapon_icon.position = Vector2(-29, -29)
	_weapon_badge.add_child(_weapon_icon)

	get_viewport().size_changed.connect(_layout)
	_layout()


func _counter(kind: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.glass("pill_dark", "pill_s", Vector4(16, 4, 24, 12)))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	var icon := HudIcon.new()
	icon.kind = kind
	row.add_child(icon)
	var label := UIKit.make_label("0", 30, Color.WHITE)
	label.add_theme_font_override("font", UIKit.FONT_BLACK)
	label.name = "Value"
	row.add_child(label)
	return pill


func set_hearts(count: int, total: int) -> void:
	for i in _hearts.size():
		_hearts[i].visible = i < total
		_hearts[i].empty = i >= count
		_hearts[i].queue_redraw()


func set_coins(count: int) -> void:
	_coin_label.text = str(count)
	_coin_box.pivot_offset = _coin_box.size * 0.5
	create_tween().tween_property(_coin_box, "scale", Vector2.ONE, 0.15).from(Vector2(1.12, 1.12))


func set_diamonds(count: int, total: int) -> void:
	_diamond_label.text = "%d/%d" % [count, total]


## The guardian's name and hits left, under the top bar (boss levels).
func show_boss(boss_name: String, hits: int, total: int) -> void:
	if _boss_bar == null:
		_boss_bar = PanelContainer.new()
		_boss_bar.add_theme_stylebox_override("panel", UIKit.glass("pill_dark", "pill_s", Vector4(30, 6, 30, 14)))
		_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_boss_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_boss_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_boss_bar.offset_top = 118
		var label := UIKit.make_label("", 28, Color.WHITE)
		label.name = "Value"
		_boss_bar.add_child(label)
		_root.add_child(_boss_bar)
	var text := boss_name + "   "
	for i in total:
		text += "●" if i < hits else "○"
	(_boss_bar.find_child("Value", true, false) as Label).text = text if hits > 0 else boss_name + " آزاد شد!"


## Where a button is on the screen (the tutorial circles it).
func button_rect(key: String) -> Rect2:
	if key == "team" and _team_button:
		return _team_button.get_global_rect()
	if _touch.has(key):
		var button: TouchScreenButton = _touch[key]
		var size := button.texture_normal.get_size() * button.scale
		var rect := Rect2(button.position, size)
		if key == "left":
			rect = rect.merge(Rect2(_touch.right.position, size))
		return rect
	return Rect2(Vector2(600, 320), Vector2(80, 80))


func set_weapon(id: String) -> void:
	if _weapon_icon:
		_weapon_icon.id = id
		_weapon_icon.queue_redraw()
	_touch.swap.visible = Weapons.owned().size() > 1


## The down button is always there (crouch); on a warp pipe it glows to say "go in".
func show_down(value: bool) -> void:
	_touch.down.modulate = Color(1.3, 1.15, 0.6) if value else Color.WHITE


func setup(title: String, star_total: int, has_keys: bool, lens_enabled: bool) -> void:
	_star_total = star_total
	set_stars([])
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
	# touch buttons: bigger on small phone screens, a little smaller on big tablets, and the
	# player's own choice in the settings on top (UIKit.touch_scale)
	var k := UIKit.touch_scale(get_viewport())
	var y: float = view.y - bottom - 160.0 * k
	var lx := func(x: float) -> float: return left + x * k
	var rx := func(x: float) -> float: return view.x - right - x * k
	var place := func(key: String, pos: Vector2, size: float) -> void:
		_touch[key].scale = Vector2(size, size) * k
		_touch[key].position = pos
	place.call("left", Vector2(lx.call(0.0), y), 0.9)
	place.call("right", Vector2(lx.call(160.0), y), 0.9)
	place.call("down", Vector2(lx.call(100.0), y - 130.0 * k), 0.7)
	# right hand: big jump in the corner, dash beside it, Pilo and the lens above
	place.call("jump", Vector2(rx.call(160.0), y - 10.0 * k), 1.0)
	place.call("dash", Vector2(rx.call(300.0), y + 22.0 * k), 0.75)
	place.call("pilo", Vector2(rx.call(140.0), y - 140.0 * k), 0.75)
	place.call("time", Vector2(rx.call(300.0), y - 108.0 * k), 0.75)
	# fire beside the dash, the weapon swap small above it
	place.call("fire", Vector2(rx.call(430.0), y + 22.0 * k), 0.75)
	place.call("swap", Vector2(rx.call(415.0), y - 82.0 * k), 0.55)
	if _weapon_badge:
		# the current weapon in a round badge on the fire button's upper corner
		_weapon_badge.scale = Vector2(k, k)
		_weapon_badge.position = _touch.fire.position + Vector2(110, 6) * k


func set_stars(collected: Array) -> void:
	var label := _star_counter.find_child("Value", true, false) as Label
	label.text = "%d/%d" % [collected.size(), _star_total]
	if not collected.is_empty():
		_star_counter.pivot_offset = _star_counter.size * 0.5
		create_tween().tween_property(_star_counter, "scale", Vector2.ONE, 0.3).from(Vector2(1.3, 1.3)).set_trans(Tween.TRANS_BACK)


func set_keys(count: int) -> void:
	_key_label.text = str(count)


func set_time(state: int) -> void:
	var past := state == TimeShift.PAST
	_time_label.text = "زمان: " + TimeShift.NAMES[state]
	_time_panel.add_theme_stylebox_override("panel", UIKit.glass("pill_orange_s" if past else "pill_blue_s", "pill_s", Vector4(26, 4, 26, 14)))


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


## Small icons drawn in code for the top bar (same drawings as in the level).
class HudIcon extends Control:
	var kind := "coin"
	var empty := false
	var _t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(40, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		if kind != "heart":
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"heart":
				if empty:
					modulate = Color(0.3, 0.3, 0.35, 0.8)
				else:
					modulate = Color.WHITE
				Collectible.draw_heart(self, c + Vector2(0, 2), 0.95)
			"coin":
				Collectible.draw_coin(self, c, 1.1, _t * 0.6)
			"diamond":
				Collectible.draw_diamond(self, c, 0.95, _t)


## Round badge behind the current weapon's icon.
class Badge extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 34.0, Color(0.12, 0.13, 0.2, 0.85))
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 40, Color(1, 0.85, 0.35), 4.0)
