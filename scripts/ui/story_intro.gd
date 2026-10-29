extends Control
## The opening story (data/story/intro.json): painted pictures with a slow camera move and
## cross-fades, a narrator reading each line (assets/audio/voice/intro_N.ogg) with subtitles,
## and a touch of mood (night shadows, grey for the stolen colours, golden sparkles for magic).
## Plays on the very first launch, from "new game", and from Settings → "the story".
## Tap to go to the next picture; "skip" ends it.

const STORY := "res://data/story/intro.json"
const ART := "res://assets/story/%s.png"
const FALLBACK := "res://assets/environments/key_art.webp"
const FADE := 0.9
const MIN_TIME := 4.0

var _panels: Array = []
var _index := -1
var _front: TextureRect
var _back: TextureRect
var _mood: ColorRect
var _sparkles: CPUParticles2D
var _wisps: CPUParticles2D
var _subtitle: Label
var _caption: PanelContainer
var _timer := 0.0
var _leaving := false
var _grey: ShaderMaterial


func _ready() -> void:
	UIKit.ensure_theme()
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STORY))
	_panels = data.panels
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	_grey = ShaderMaterial.new()
	_grey.shader = _grey_shader()
	_back = _picture()
	_front = _picture()
	_mood = ColorRect.new()
	_mood.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mood.color = Color(0, 0, 0, 0)
	add_child(_mood)
	_sparkles = _particles(Color(1, 0.9, 0.5), Vector2(0, -40))
	_wisps = _particles(Color(0.35, 0.2, 0.55, 0.7), Vector2(0, -25))

	_caption = PanelContainer.new()
	_caption.add_theme_stylebox_override("panel", UIKit.glass("pill_dark", "pill_s", Vector4(40, 18, 40, 22)))
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.offset_bottom = -30
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_subtitle = UIKit.make_label("", 34, Color.WHITE, 8, Color(0, 0, 0, 0.5))
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.custom_minimum_size = Vector2(980, 0)
	_subtitle.text_direction = Control.TEXT_DIRECTION_RTL
	_caption.add_child(_subtitle)

	var skip := UIKit.make_button("رد شدن", UIKit.CREAM_BUTTON, 170, 26)
	skip.position = Vector2(24, 20)
	skip.pressed.connect(_finish)
	add_child(skip)

	AudioManager.play_music("forest")
	AudioManager.play_ambient("")
	_next()


func _picture() -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	add_child(rect)
	return rect


func _particles(color: Color, gravity: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = preload("res://assets/vfx/dot.png")
	p.amount = 60
	p.lifetime = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 380)
	p.position = Vector2(640, 360)
	p.gravity = gravity
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 30.0
	p.spread = 180.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.7
	p.color = color
	p.emitting = false
	add_child(p)
	return p


func _process(delta: float) -> void:
	if _index < 0 or _leaving:
		return
	_timer += delta
	if _timer > MIN_TIME and not AudioManager.is_voice_playing() and _timer > 1.2:
		_next()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and _timer > 0.6:
		AudioManager.stop_voice()
		_next()


func _next() -> void:
	_index += 1
	if _index >= _panels.size():
		_finish()
		return
	_timer = 0.0
	var panel: Dictionary = _panels[_index]
	var path := ART % panel.image
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else load(FALLBACK)
	# the old front picture becomes the back one and fades out under the new picture
	var old := _front
	_front = _back
	_back = old
	move_child(_front, _back.get_index() + 1)
	_front.texture = texture
	_front.material = _grey if panel.mood == "grey" else null
	_front.pivot_offset = size * 0.5
	_front.scale = Vector2(1.12, 1.12)
	_front.position = Vector2(-30 if _index % 2 == 0 else 30, 0)
	var fade := create_tween().set_parallel(true)
	fade.tween_property(_front, "modulate:a", 1.0, FADE)
	fade.tween_property(_back, "modulate:a", 0.0, FADE)
	var drift := create_tween().set_parallel(true)
	drift.tween_property(_front, "scale", Vector2(1.02, 1.02), 12.0).set_trans(Tween.TRANS_SINE)
	drift.tween_property(_front, "position", Vector2(-_front.position.x, 0), 12.0).set_trans(Tween.TRANS_SINE)
	_set_mood(String(panel.mood))
	_subtitle.text = panel.text
	_caption.modulate.a = 0.0
	create_tween().tween_property(_caption, "modulate:a", 1.0, 0.5).set_delay(0.3)
	if not AudioManager.play_voice(String(panel.voice_id)):
		_timer = -float(String(panel.text).length()) * 0.06   # no recording: give time to read


func _set_mood(mood: String) -> void:
	var tint := Color(0, 0, 0, 0)
	match mood:
		"night":
			tint = Color(0.15, 0.05, 0.3, 0.35)
		"warm":
			tint = Color(1.0, 0.7, 0.3, 0.12)
		"magic":
			tint = Color(1.0, 0.9, 0.5, 0.08)
	create_tween().tween_property(_mood, "color", tint, FADE)
	_sparkles.emitting = mood == "magic" or mood == "bright"
	_wisps.emitting = mood == "night" or mood == "grey"


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	AudioManager.stop_voice()
	SaveManager.data.intro_seen = true
	SaveManager.save_game()
	if LevelManager.after_intro == "level":
		LevelManager.after_intro = "menu"
		LevelManager.play_level(1)
	else:
		LevelManager.goto_menu()


func _grey_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(c.rgb, vec3(g) * vec3(0.92, 0.94, 1.0), 0.85), c.a);
}"""
	return shader
