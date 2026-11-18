class_name StoryPanels
extends CanvasLayer
## Storyboard panels (assets/art/p11_story/panels/s01..s14) told by the grandfather: each panel
## fills the middle of the screen with a slow camera drift and a soft cross-fade, a blurred copy of
## it fills the rest, and the line is read in the dialogue box (screen_dialogue_v1). Tap for the
## next panel. Used by the opening story and by the chapter card / chapter end.

signal finished

const DIR := "res://assets/art/p11_story/panels/"
## panel -> narration key (strings_fa.json); the voice id is the same key.
const PANELS := {
	"s01_broken_clock": "story_s01", "s02_lens_gift": "story_s02", "s03_ghost_past_layer": "story_s03",
	"s04_bridge_waterfall": "story_s04", "s05_keeper_wakes": "story_s05", "s06_bear_shadow": "story_s06",
	"s07_bear_calm": "story_s07", "s08_village_return": "story_s08", "s09_key_in_gears": "story_s09",
	"s10_tower_awakens": "story_s10", "s11_rival_silhouette": "story_s11", "s12_map_next_region": "story_s12",
	"s13_night_camp": "story_s13", "s14_door_to_chapter2": "story_s14",
}
const OPENING := ["s01_broken_clock", "s02_lens_gift", "s03_ghost_past_layer"]
const CHAPTER1_CARD := ["s04_bridge_waterfall", "s05_keeper_wakes", "s06_bear_shadow"]
const CHAPTER1_END := ["s07_bear_calm", "s08_village_return", "s09_key_in_gears", "s10_tower_awakens",
	"s11_rival_silhouette", "s12_map_next_region", "s13_night_camp", "s14_door_to_chapter2"]

var dialogue: Node
var _blur: TextureRect
var _front: TextureRect
var _back: TextureRect
var _t := 0.0


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("0d1b3d")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	_blur = TextureRect.new()
	_blur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blur.modulate = Color(0.45, 0.45, 0.6, 0.85)
	var blur := ShaderMaterial.new()
	blur.shader = Shader.new()
	blur.shader.code = "shader_type canvas_item;\nuniform float k = 3.5;\nvoid fragment(){ vec4 c = vec4(0.0); for (int i=-3;i<=3;i++){ for (int j=-3;j<=3;j++){ c += texture(TEXTURE, UV + vec2(float(i), float(j)) * TEXTURE_PIXEL_SIZE * k * 4.0);} } COLOR = c / 49.0 * COLOR; }"
	_blur.material = blur
	root.add_child(_blur)
	_back = _panel(root)
	_front = _panel(root)
	if dialogue == null:
		dialogue = load("res://scripts/ui/dialogue_box.gd").new()
		add_child(dialogue)
	dialogue.layer = 21


func _panel(root: Control) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.offset_top = 16
	t.offset_bottom = -230
	t.pivot_offset = Vector2(640, 240)
	t.modulate.a = 0.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(t)
	return t


func _process(delta: float) -> void:
	_t += delta
	# a slow drift: the panel grows a little and moves up while it is read
	_front.scale = Vector2.ONE * (1.0 + _t * 0.012)
	_front.position.y = -_t * 2.0
	_front.pivot_offset = _front.size * 0.5


## Plays the given panels with their lines; returns when the last one has been tapped away.
func play(names: Array) -> void:
	for n in names:
		var tex: Texture2D = DesignUI.tex(DIR + n + ".png")
		_back.texture = _front.texture
		_back.modulate.a = _front.modulate.a
		_back.scale = _front.scale
		_front.texture = tex
		_blur.texture = tex
		_front.modulate.a = 0.0
		_t = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_front, "modulate:a", 1.0, 0.9)
		tw.tween_property(_back, "modulate:a", 0.0, 0.9)
		var key: String = PANELS.get(n, "")
		await dialogue.play([{"who": "narrator", "text": Strings.t(key), "id": key}])
	var out := create_tween()
	out.tween_property(_front, "modulate:a", 0.0, 0.5)
	await out.finished
	finished.emit()
