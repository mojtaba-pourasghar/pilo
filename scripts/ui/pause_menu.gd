class_name PauseScreen
extends CanvasLayer
## Pause and settings, exactly screen_pause_settings_v1: on the left the pause panel under a red
## ribbon with four glossy pill buttons (gold ▶ continue, blue ⟳ restart, blue ⚙ settings, green
## exit); on the right the settings panel: three sliders (sound, music, brightness), two switches
## (vibration; the bell = warnings and the soft return from the past, see DECISION_QUEUE Q7) and the
## language box. Emits `action`: "resume", "restart" or "menu". From the menus (settings_only) the
## left buttons close the screen. The game is paused meanwhile.

signal action(name: String)

const S := "pause"
## slider piece -> [knob piece, setting key, default]
const SLIDERS := {"track_sound": ["knob", "sfx", 0.9], "track_music": ["knob_m", "music", 0.7], "track_light": ["knob_l", "brightness", 1.0]}
## the fill runs between these fractions of the track picture
const SPAN := [0.013, 0.985]

var settings_only := false
var _closing := false
var _stage: Control
var _bars := {}
var _knobs := {}
var _drag := ""
var _toggles := {}


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_stage = DesignUI.make_stage(root, DesignUI.piece_path(S, "bg"))
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	DesignUI.text(_stage, Strings.t("ui_settings") if settings_only else Strings.t("ui_pause"), DesignUI.area(S, "ribbon"), 34, Color.WHITE, 8, Color("5a0a0a"))
	for pair in [["btn_play", "resume"], ["btn_restart", "restart"], ["btn_settings", "settings"], ["btn_exit", "menu"]]:
		var id: String = pair[1]
		var b := DesignUI.button(_stage, DesignUI.piece_path(S, pair[0]), DesignUI.rect(S, pair[0]), func(): _on_pressed(id))
		if settings_only and id in ["restart", "menu"]:
			b.disabled = true
			b.modulate = Color(0.6, 0.6, 0.65)
	for track in SLIDERS:
		_slider(track)
	_toggle("toggle_vib", "vibration")
	_toggle("toggle_bell", "auto_return")
	DesignUI.piece(_stage, S, "lang")
	DesignUI.text(_stage, Strings.t("ui_language_fa"), DesignUI.content(S, "lang"), 28, Color.WHITE, 5)


func _slider(track: String) -> void:
	var r := DesignUI.rect(S, track)
	var bar := TextureProgressBar.new()
	bar.texture_under = DesignUI.tex(DesignUI.piece_path(S, track, "_empty"))
	bar.texture_progress = DesignUI.tex(DesignUI.piece_path(S, track))
	bar.nine_patch_stretch = true
	bar.position = r.position
	bar.size = r.size
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.add_child(bar)
	var spec: Array = SLIDERS[track]
	var knob := DesignUI.piece(_stage, S, spec[0])
	_bars[track] = bar
	_knobs[track] = knob
	bar.gui_input.connect(func(e: InputEvent): _slider_input(track, e))
	_set_slider(track, float(SaveManager.data.settings.get(spec[1], spec[2])), false)


func _slider_input(track: String, e: InputEvent) -> void:
	var bar: TextureProgressBar = _bars[track]
	var x := -1.0
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_drag = track if e.pressed else ""
		x = e.position.x
	elif e is InputEventScreenTouch:
		_drag = track if e.pressed else ""
		x = e.position.x
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _drag == track:
		x = e.position.x
	if x >= 0.0:
		var v := inverse_lerp(SPAN[0] * bar.size.x, SPAN[1] * bar.size.x, x)
		_set_slider(track, clampf(v, 0.0, 1.0), true)


func _set_slider(track: String, v: float, save: bool) -> void:
	var bar: TextureProgressBar = _bars[track]
	bar.value = lerpf(SPAN[0], SPAN[1], v) if v > 0.0 else 0.0
	var knob: TextureRect = _knobs[track]
	var r := DesignUI.rect(S, track)
	var x := r.position.x + lerpf(SPAN[0], SPAN[1], v) * r.size.x
	knob.position = Vector2(x - knob.size.x * 0.5, r.get_center().y - knob.size.y * 0.5)
	if save:
		var key: String = SLIDERS[track][1]
		SaveManager.data.settings[key] = v
		AudioManager.apply_settings()
		LevelManager.apply_brightness()


func _toggle(piece: String, key: String) -> void:
	var r := DesignUI.rect(S, piece)
	var body := DesignUI.button(_stage, DesignUI.piece_path(S, piece), r, func(): _flip(piece, key))
	var knob_size := DesignUI.rect(S, "knob_on").size
	var knob := TextureRect.new()
	knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knob.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the knob sits where the design has it (the right end of the switch); on = cyan, off = dark
	knob.position = DesignUI.rect(S, "knob_on").position - DesignUI.rect(S, "toggle_vib").position
	knob.size = knob_size
	body.add_child(knob)
	_toggles[key] = knob
	_show_toggle(key)


func _flip(_piece: String, key: String) -> void:
	SaveManager.data.settings[key] = not bool(SaveManager.data.settings.get(key, true))
	_show_toggle(key)
	if key == "vibration" and SaveManager.data.settings[key]:
		Juice.vibrate(40)


func _show_toggle(key: String) -> void:
	var on := bool(SaveManager.data.settings.get(key, true))
	_toggles[key].texture = DesignUI.tex(DesignUI.piece_path(S, "knob_on" if on else "knob_off"))


func _on_pressed(id: String) -> void:
	match id:
		"settings":
			var t := create_tween()
			for k in _bars.values():
				t.parallel().tween_property(k, "modulate", Color(1.3, 1.3, 1.3), 0.15)
			for k in _bars.values():
				t.tween_property(k, "modulate", Color.WHITE, 0.25)
		_:
			_close(id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close("resume")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close("resume")


func _close(id: String) -> void:
	if _closing:
		return
	_closing = true
	SaveManager.save_game()
	get_tree().paused = false
	action.emit(id)
	queue_free()
