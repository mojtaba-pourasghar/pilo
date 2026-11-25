class_name GreatClock
extends CanvasLayer
## The great clock between the old and the new level of a pair: exactly the approved design g5v3_clock_v3
## (SCREEN_DESIGNS). The old world (sepia map) on the left, the new world on the right, the golden pocket watch
## in the middle with a swirl of time, and the deed cards below: each deed the grandfather did lights its card
## (egg saved, bridge planted, shrine lit); a deed not done stays grey ("the new world will be harder there").
## The fourth card is the secret of the pair (grey until found). Cards flip in one by one.
## Left round button: back to the old level (try the deeds again); right: on to the new level.

signal chosen(id: String)                ## "old" or "new"

const ART := "res://assets/art/pair1_sheets/g5v3_clock_v3.png"
const SIZE := Vector2(1680, 944)
const CARDS := [Rect2(306, 568, 246, 300), Rect2(586, 568, 246, 300), Rect2(866, 568, 246, 300), Rect2(1146, 568, 246, 300)]
const GREY := "shader_type canvas_item;\nuniform float grey = 1.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat l = dot(c.rgb, vec3(0.3, 0.59, 0.11));\n\tCOLOR = vec4(mix(c.rgb, vec3(l) * 0.85, grey), c.a);\n}\n"

var deeds: Array = ["egg_saved", "bridge_planted", "shrine_lit", "secret"]
var _stage: Control
var _swirl: Node2D


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color("1d2440")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_stage = Control.new()
	_stage.size = SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage)
	var view := root.get_viewport_rect().size
	var k := minf(view.x / SIZE.x, view.y / SIZE.y)
	_stage.scale = Vector2(k, k)
	_stage.position = (view - SIZE * k) * 0.5
	var art: Texture2D = load(ART)
	var bg := TextureRect.new()
	bg.texture = art
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(bg)
	# the painted cards are covered with a card back of the panel's navy, then flip to their face (lit or grey)
	var shader := Shader.new()
	shader.code = GREY
	for i in 4:
		var r: Rect2 = CARDS[i]
		var done := _done(String(deeds[i]))
		var face := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = art
		at.region = r
		face.texture = at
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_SCALE
		face.position = r.position
		face.size = r.size
		face.pivot_offset = r.size * 0.5
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not done or i == 3:
			var m := ShaderMaterial.new()
			m.shader = shader
			m.set_shader_parameter("grey", 0.0 if done else 1.0)
			face.material = m
		face.scale = Vector2(0.0, 1.0)
		_stage.add_child(face)
		var tw := face.create_tween()
		tw.tween_interval(0.6 + i * 0.45)
		tw.tween_callback(func(): AudioManager.play_sfx("star" if done else "creak", 1.0 + i * 0.08, -4.0))
		tw.tween_property(face, "scale", Vector2(1.0, 1.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var key := "clock_done" if done else "clock_not_done"
		var lab := DesignUI.text(_stage, Strings.t(key), Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 40)), 24,
			Color("ffe9a8") if done else Color("c9cde0"), 6)
		lab.modulate.a = 0.0
		lab.create_tween().tween_interval(0.9 + i * 0.45)
		lab.create_tween().tween_property(lab, "modulate:a", 1.0, 0.4).set_delay(0.9 + i * 0.45)
	DesignUI.text(_stage, Strings.t("clock_title"), Rect2(600, 34, 480, 90), 46, Color("fff3d0"), 9, Color("5a1010"))
	# time keeps turning: a soft golden swirl around the watch
	_swirl = Swirl.new()
	_swirl.position = Vector2(840, 330)
	_stage.add_child(_swirl)
	_hot(Rect2(14, 760, 160, 160), func(): _pick("old"))
	_hot(Rect2(1506, 760, 160, 160), func(): _pick("new"))
	DesignUI.text(_stage, Strings.t("clock_back"), Rect2(10, 700, 170, 50), 22, Color.WHITE, 6)
	DesignUI.text(_stage, Strings.t("clock_on"), Rect2(1500, 700, 170, 50), 22, Color.WHITE, 6)


static func _done(deed: String) -> bool:
	if deed == "secret":
		return bool(SaveManager.data.get("pair1_secret", false))
	return DeedsStore.has(deed)


func _hot(r: Rect2, on_press: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.pressed.connect(func():
		UIKit.play_click()
		on_press.call())
	_stage.add_child(b)


func _pick(id: String) -> void:
	chosen.emit(id)
	queue_free()


class Swirl extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var a := _t * (0.9 + i * 0.35) + i * 2.1
			draw_arc(Vector2.ZERO, 250.0 + i * 26.0, a, a + 1.2, 40, Color(1, 0.86, 0.45, 0.32 - i * 0.08), 7.0 - i * 2.0)
		for i in 8:
			var a2 := _t * 1.6 + i * TAU / 8.0
			var p := Vector2(cos(a2), sin(a2) * 0.45) * (270.0 + sin(_t * 2.0 + i) * 12.0)
			draw_circle(p, 3.5, Color(1, 0.95, 0.7, 0.7))
