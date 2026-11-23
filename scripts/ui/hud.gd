extends CanvasLayer
## The in-level HUD, exactly as sheet_screen_hud_v1.png (its own layer, apart from the scene):
##   top-left      hearts bar, and the lens charge bar under it
##   top-centre    the two keys: blue = past, orange = present (dim until found)
##   top-right     coin bar, purple pause button
##   bottom-left   joystick
##   bottom-right  three action buttons: jump (green, winged boot), lens (blue clock), shoot (gold
##                 bow); and three tool slots (Pilo's lantern, the guide map, the carried thing)
## Pieces: assets/art/p9_ui/cut/hud_* (cut from the design by tools/art/cut_ui.py), positions from
## data/ui_layout.json. Numbers are drawn as text (Persian digits), never baked in a picture.

signal pause_pressed
signal hint_pressed
signal tool_pressed(slot: int)

const S := "hud"
## The tools shown in the three slots (p3 icons): Pilo's lantern, the guide map, the mirror.
const SLOT_TOOLS := ["lantern", "map", "mirror"]
const TOOL_ICON := "res://assets/art/p3_tools/p3_tool_%s_icon_l1.png"
const CARRY_ICON := {"glow_mushroom": "res://assets/art/p7_living/p7_living_ch01_glow_mushroom_f1.png"}
const JOY_DEAD := 0.12          ## docs/26: dead zone 12%
const JOY_CURVE := 1.4
const JOY_SMOOTH := 0.05        ## seconds of input smoothing
const JOY_ZONE_W := 0.45        ## floating stick: left 45% of the screen
const JOY_ZONE_TOP := 0.25

var _root: Control
var _hearts: TextureProgressBar
var _lens: TextureProgressBar
var _countdown: Label
var _key_past: TextureRect
var _key_present: TextureRect
var _coins: Label
var _pause: TextureButton
var _joy_base: TextureRect
var _joy_knob: TextureRect
var _joy_center := Vector2.ZERO
var _joy_radius := 80.0
var _joy_touch := -2
var _joy_home := Vector2.INF
var _joy_target := Vector2.ZERO
var _joy_value := Vector2.ZERO
var _joy_driving := false
var floating := true             ## false = a fixed ring (settings)
var _buttons := {}
var _slots: Array = []
var _slot_icons: Array = []
var _controls: Array = []
var _flash: ColorRect
var _boss: Label
var _boss_hearts: HBoxContainer
var _clues_label: Label
var carry_id := ""
var _lens_charge := 1.0
var _return_left := -1.0
var _held := {}


func _process(delta: float) -> void:
	if _joy_base != null and _joy_base.visible:
		_process_joystick(delta)


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)
	_build_top()
	_build_controls()


func _bar(name: String, corner: String) -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.texture_under = DesignUI.tex(DesignUI.piece_path(S, name, "_empty"))
	bar.texture_progress = DesignUI.tex(DesignUI.piece_path(S, name))
	bar.nine_patch_stretch = true
	var r := DesignUI.rect(S, name)
	bar.position = r.position
	bar.size = r.size
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.value = 1.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the bar fills from its icon's edge: the icon (left 22%) is always drawn in full
	var left := int(bar.texture_progress.get_width() * 0.2) if bar.texture_progress else 0
	bar.radial_initial_angle = 0
	bar.set_meta("icon_px", left)
	_root.add_child(bar)
	DesignUI.anchor(bar, corner)
	return bar


func _build_top() -> void:
	_hearts = _bar("heart_bar", "tl")
	_lens = _bar("lens_bar", "tl")
	_countdown = DesignUI.text(_root, "", Rect2(DesignUI.rect(S, "lens_bar").end.x - 70, DesignUI.rect(S, "lens_bar").position.y, 60, DesignUI.rect(S, "lens_bar").size.y), 22, Color.WHITE, 5)
	DesignUI.anchor(_countdown, "tl")
	_key_past = DesignUI.piece(_root, S, "key_past", "_off")
	DesignUI.anchor(_key_past, "tc")
	_key_present = DesignUI.piece(_root, S, "key_present", "_off")
	DesignUI.anchor(_key_present, "tc")
	var coin_bar := DesignUI.piece(_root, S, "coin_bar")
	DesignUI.anchor(coin_bar, "tr")
	_coins = DesignUI.text(_root, "۰", DesignUI.content(S, "coin_bar"), 30, DesignUI.GOLD_TEXT, 6)
	DesignUI.anchor(_coins, "tr")
	_pause = DesignUI.button(_root, DesignUI.piece_path(S, "pause"), DesignUI.rect(S, "pause"), func(): pause_pressed.emit())
	DesignUI.anchor(_pause, "tr")
	# guardian hearts (no design yet for the guardian bar: small hearts under the keys)
	_boss_hearts = HBoxContainer.new()
	_boss_hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	_boss_hearts.position = Vector2(540, 122)
	_boss_hearts.size = Vector2(200, 40)
	_boss_hearts.visible = false
	_boss_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_boss_hearts)
	DesignUI.anchor(_boss_hearts, "tc")


func _build_controls() -> void:
	_joy_base = DesignUI.piece(_root, S, "joystick")
	DesignUI.anchor(_joy_base, "bl")
	_joy_knob = DesignUI.piece(_root, S, "joystick_knob")
	DesignUI.anchor(_joy_knob, "bl")
	_controls.append_array([_joy_base, _joy_knob])
	for pair in [["btn_jump", "jump"], ["btn_lens", "time_shift"], ["btn_shoot", "fire"]]:
		var b := DesignUI.button(_root, DesignUI.piece_path(S, pair[0]), DesignUI.rect(S, pair[0]))
		var action: String = pair[1]
		b.button_down.connect(func(): _press(action, true))
		b.button_up.connect(func(): _press(action, false))
		DesignUI.anchor(b, "br")
		_buttons[action] = b
		_controls.append(b)
	for i in 3:
		var name := "slot_%d" % (i + 1)
		var slot := DesignUI.button(_root, DesignUI.piece_path(S, name), DesignUI.rect(S, name), func(): tool_pressed.emit(i))
		DesignUI.anchor(slot, "br")
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 10
		icon.offset_top = 10
		icon.offset_right = -10
		icon.offset_bottom = -10
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		_slots.append(slot)
		_slot_icons.append(icon)
		_controls.append(slot)
	_refresh_slots()


func _press(action: String, down: bool) -> void:
	if down:
		Input.action_press(action)
		_held[action] = true
	else:
		Input.action_release(action)
		_held.erase(action)


## Joystick (docs/26 §2.1): floating and analog. A touch in the left 45% of the screen puts the ring
## under the finger; the ring follows when the finger leaves it. Dead zone 12%, response x^1.4, the
## value is smoothed over ~0.05 s so a jumpy finger never jerks the hero. down = crouch / pipe.
func _input(event: InputEvent) -> void:
	if not _joy_base.visible:
		return
	var pos := Vector2.ZERO
	var index := -1
	var pressed := false
	var is_touch := false
	if event is InputEventScreenTouch:
		pos = event.position
		index = event.index
		pressed = event.pressed
		is_touch = true
	elif event is InputEventScreenDrag:
		pos = event.position
		index = event.index
		pressed = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		pressed = event.pressed
		is_touch = true
	elif event is InputEventMouseMotion and _joy_touch == -1:
		pos = event.position
		pressed = true
	else:
		return
	var view := get_viewport().get_visible_rect().size
	if _joy_home == Vector2.INF:
		_joy_home = _joy_base.position
	var base := Rect2(_joy_base.global_position, _joy_base.size)
	if is_touch and pressed and _joy_touch == -2:
		var in_zone := pos.x < view.x * JOY_ZONE_W and pos.y > view.y * JOY_ZONE_TOP
		if in_zone or base.grow(30).has_point(pos):
			_joy_touch = index
			_joy_center = pos if floating else base.get_center()
			if floating:
				_place_joystick(_joy_center)
	if _joy_touch == -2 or (index != _joy_touch and not (event is InputEventMouseMotion or event is InputEventMouseButton)):
		return
	if is_touch and not pressed:
		_joy_touch = -2
		_joy_target = Vector2.ZERO
		_joy_base.modulate.a = 0.55
		if floating:
			_joy_base.position = _joy_home
		return
	_joy_radius = _joy_base.size.x * 0.36
	var offset := pos - _joy_center
	if floating and offset.length() > _joy_radius:      # the ring follows the finger
		_joy_center = pos - offset.normalized() * _joy_radius
		_place_joystick(_joy_center)
		offset = pos - _joy_center
	_joy_base.modulate.a = 1.0
	_joy_target = offset / _joy_radius
	get_viewport().set_input_as_handled()


## Analog value of a raw stick vector: dead zone then the x^1.4 response (docs/26).
static func stick_curve(v: Vector2) -> Vector2:
	var m := minf(v.length(), 1.0)
	if m <= JOY_DEAD:
		return Vector2.ZERO
	var k := pow((m - JOY_DEAD) / (1.0 - JOY_DEAD), JOY_CURVE)
	return v.normalized() * k


func _place_joystick(center: Vector2) -> void:
	_joy_base.global_position = center - _joy_base.size * 0.5


func _process_joystick(delta: float) -> void:
	# Only drive the actions while the stick is in use, so the keyboard (and bots) still work.
	if _joy_touch == -2 and _joy_value == Vector2.ZERO and not _joy_driving:
		return
	var smooth := 1.0 - exp(-delta / JOY_SMOOTH)
	_joy_value = _joy_value.lerp(stick_curve(_joy_target), smooth)
	if _joy_value.length() < 0.004 and _joy_target == Vector2.ZERO:
		_joy_value = Vector2.ZERO
	_joy_driving = _joy_value != Vector2.ZERO or _joy_touch != -2
	_set_stick(_joy_value, true)


func _set_stick(v: Vector2, analog := false) -> void:
	if v.length() > 1.0:
		v = v.normalized()
	if not analog:                                    # direct call (hide controls): reset everything
		_joy_target = v
		_joy_value = v
	_joy_knob.position = _joy_base.position + (_joy_base.size - _joy_knob.size) * 0.5 + v * _joy_radius
	var strengths := {"move_left": maxf(-v.x, 0.0), "move_right": maxf(v.x, 0.0)}
	for action in strengths:
		if strengths[action] > 0.001:
			Input.action_press(action, strengths[action])
		else:
			Input.action_release(action)
	if v.y > 0.6:
		Input.action_press("down", 1.0)
	else:
		Input.action_release("down")


# --- the game's calls ----------------------------------------------------------------

func setup(_title: String, _star_total: int, _has_keys: bool, lens_enabled: bool) -> void:
	_buttons.time_shift.visible = lens_enabled
	_lens.visible = lens_enabled


## The bars fill only between the icon and the end cap (fractions of the cut picture).
const FILL := {"heart_bar": [0.2, 0.944], "lens_bar": [0.198, 0.94]}


func _fill(bar: TextureProgressBar, name: String, v: float) -> void:
	var span: Array = FILL[name]
	bar.value = 0.0 if v <= 0.0 else lerpf(float(span[0]), float(span[1]), clampf(v, 0.0, 1.0))


func set_hearts(count: int, total: int) -> void:
	_fill(_hearts, "heart_bar", float(count) / maxf(1.0, float(total)))


func set_coins(count: int) -> void:
	_coins.text = DesignUI.fa_num(count)


func set_lens_charge(value: float) -> void:
	_lens_charge = clampf(value, 0.0, 1.0)
	_fill(_lens, "lens_bar", _lens_charge)


## Seconds before the soft return while in the past (-1: none), shown at the end of the lens bar.
func set_return_countdown(left: float) -> void:
	_return_left = left
	_countdown.text = DesignUI.fa_num(int(ceil(left))) if left >= 0.0 else ""


func set_time_keys(past: bool, present: bool) -> void:
	_key_past.texture = DesignUI.tex(DesignUI.piece_path(S, "key_past", "" if past else "_off"))
	_key_present.texture = DesignUI.tex(DesignUI.piece_path(S, "key_present", "" if present else "_off"))
	for pair in [[_key_past, past], [_key_present, present]]:
		if pair[1] and pair[0].get_meta("lit", false) == false:
			pair[0].set_meta("lit", true)
			pair[0].pivot_offset = pair[0].size * 0.5
			var t := create_tween()
			t.tween_property(pair[0], "scale", Vector2(1.25, 1.25), 0.12)
			t.tween_property(pair[0], "scale", Vector2.ONE, 0.2)


## Older levels with one key: the present keyhole lights up.
func set_keys(count: int) -> void:
	if count > 0 and not _key_present.get_meta("lit", false):
		set_time_keys(_key_past.get_meta("lit", false), true)


func show_boss(boss_name: String, hits: int, total: int) -> void:
	_boss_hearts.visible = total > 0
	for c in _boss_hearts.get_children():
		c.queue_free()
	var heart := DesignUI.tex("res://assets/art/p8_fx/p8_fx_ui_heart.png")
	for i in total:
		var t := TextureRect.new()
		t.texture = heart
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(40, 40)
		t.modulate = Color.WHITE if i < hits else Color(0.3, 0.3, 0.35, 0.7)
		_boss_hearts.add_child(t)
	_boss_hearts.tooltip_text = boss_name


func set_carry(id: String) -> void:
	carry_id = id
	_refresh_slots()


func _refresh_slots() -> void:
	for i in 3:
		var path := TOOL_ICON % SLOT_TOOLS[i]
		if i == 2 and carry_id != "":
			path = CARRY_ICON.get(carry_id, path)
		_slot_icons[i].texture = DesignUI.tex(path)


## The three clues of a level (also said by Pilo in the dialogue box at the start).
func show_clues(lines: Array) -> void:
	if _clues_label == null:
		_clues_label = DesignUI.text(_root, "", Rect2(340, 150, 600, 110), 24, Color.WHITE, 6)
		_clues_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DesignUI.anchor(_clues_label, "tc")
	_clues_label.text = "\n".join(lines.map(func(l): return "• " + String(l)))
	_clues_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(_clues_label, "modulate:a", 0.0, 0.8)


func flash(color: Color) -> void:
	_flash.color = Color(color, 0.35)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.35)


func flash_lens_empty() -> void:
	var t := create_tween()
	t.tween_property(_lens, "modulate", Color(1.6, 0.6, 0.6), 0.1)
	t.tween_property(_lens, "modulate", Color.WHITE, 0.3)


func set_controls_visible(value: bool) -> void:
	for c in _controls:
		c.visible = value
	if not value:
		_set_stick(Vector2.ZERO)
		_joy_touch = -2
		for action in _held.keys():
			Input.action_release(action)
		_held.clear()


## Where a control is on the screen (the first-time guide circles it).
func button_rect(key: String) -> Rect2:
	var c: Control = {"move": _joy_base, "left": _joy_base, "right": _joy_base, "jump": _buttons.get("jump"),
		"time": _buttons.get("time_shift"), "fire": _buttons.get("fire"), "tools": _slots[0] if _slots.size() > 0 else null,
		"pause": _pause}.get(key)
	if c == null:
		return Rect2(640, 360, 100, 100)
	return Rect2(c.global_position, c.size)


# Old HUD calls that the new design has no place for (kept so older code keeps working).
func set_weapon(_id: String) -> void:
	pass


func set_companion(_id: String) -> void:
	pass


func set_diamonds(_count: int, _total: int) -> void:
	pass


func set_stars(_collected: Array) -> void:
	pass


func set_time(_state: int) -> void:
	pass


func show_down(_value: bool) -> void:
	pass


func pulse_hint() -> void:
	pass


func stop_hint_pulse() -> void:
	pass


func _layout() -> void:
	pass


## Small coin / diamond / heart icon (used by the old result popup until it is replaced).
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

