extends CanvasLayer
## The dialogue box, exactly screen_dialogue_v1 (over the scene, at the bottom): the speaker's
## portrait in the round gold frame (left), the name on the cream ribbon, the line in the navy box
## with the golden arrow (tap / jump for the next line), and - for a question - the two choice
## buttons above it (blue and purple). Text from strings_fa.json; {hero} is the player's name. A
## recorded voice with the line's id plays automatically (never saying the hero's name).

signal advanced
signal chosen(index: int)

const S := "dialogue"
const ART := "res://assets/art/"
## Portraits from the approved art (p1, p2, p5); others use the older pictures in assets/art/.
const PORTRAITS := {
	"hero": "res://assets/art/p1_heroes/p1_hero_arsam_portrait_happy.png",
	"pilo": "res://assets/art/p2_companions/p2_companion_pilo_happy_concept.png",
	"grandpa": "res://assets/art/p1_heroes/p1_npc_grandpa_talk.png",
	"narrator": "res://assets/art/p1_heroes/p1_npc_grandpa_talk.png",
	"grandma": "res://assets/art/p1_heroes/p1_npc_grandma_talk.png",
	"bear": "res://assets/art/p5_enemies/bear/bear_head_calm_p3.png",
	"leaf_elder": "res://assets/art/p5_enemies/p5_concept_ch01_stump_idle.png",
}
const SPEAKERS := {
	"hero": {"name": "{hero}", "color": Color("e5533d"), "texture": ""},
	"pilo": {"name": "پیلو", "color": Color("f39a2b"), "texture": ""},
	"ghubarak": {"name": "غبارک", "color": Color("8e7cc3"), "texture": ["npc_ghubarak.png"]},
	"squirrel": {"name": "سنجابک", "color": Color("a0663a"), "texture": ["companion_squirrel.png"]},
	"grandpa": {"name": "بابابزرگ ساعت‌ساز", "color": Color("7a5a3a"), "texture": ["npc_grandpa.png"]},
	"narrator": {"name": "بابابزرگ ساعت‌ساز", "color": Color("7a5a3a"), "texture": ["npc_grandpa.png"]},
	"zurvan": {"name": "زروان", "color": Color("5a3a9a"), "texture": ["npc_zurvan.png", "boss_inverted_land_free.png"]},
	"masked": {"name": "نقاب‌دار", "color": Color("4a3a6a"), "texture": ["npc_masked.png"]},
	"shadow_king": {"name": "شاه‌سایه", "color": Color("5a3a9a"), "texture": ["npc_shadow_king.png", "boss_shadow_castle_free.png"]},
	"captain": {"name": "ناخدا موج", "color": Color("1f6fd0"), "texture": ["npc_captain.png"]},
	"grandma": {"name": "مادربزرگ کاکتوس", "color": Color("3f8f3a"), "texture": ["npc_grandma.png"]},
	"leaf_elder": {"name": "پیرمرد برگی", "color": Color("3f8f3a"), "texture": []},
	"bear": {"name": "خرس پیر", "color": Color("7a4a26"), "texture": ["boss_forest_free.png"]},
	"octopus": {"name": "اختاپوس بزرگ", "color": Color("e07050"), "texture": ["boss_coral_beach_free.png"]},
	"worm": {"name": "کرم شنی", "color": Color("c9963a"), "texture": ["boss_golden_desert_free.png"]},
	"yeti": {"name": "غول یخی", "color": Color("4b98b3"), "texture": ["boss_snow_mountain_free.png"]},
	"eagle": {"name": "عقاب طوفان", "color": Color("3f8fe0"), "texture": ["boss_sky_islands_free.png"]},
	"spider": {"name": "عنکبوت بلورین", "color": Color("8f7fd6"), "texture": ["boss_crystal_caves_free.png"]},
	"turtle": {"name": "لاکی", "color": Color("3f8f5a"), "texture": ["companion_turtle.png"]},
	"mole": {"name": "خال‌خالی", "color": Color("6e5a72"), "texture": ["companion_mole.png"]},
	"penguin": {"name": "یخک", "color": Color("2f3e5c"), "texture": ["companion_penguin.png"]},
	"butterfly": {"name": "پَرپَری", "color": Color("c0508a"), "texture": ["companion_butterfly.png"]},
	"owl": {"name": "پیچ‌پیچ", "color": Color("9a6a42"), "texture": ["companion_owl.png"]},
	"spark": {"name": "جرقه", "color": Color("e0a020"), "texture": ["companion_spark.png"]},
	"dragon": {"name": "اژدهاک", "color": Color("e2544a"), "texture": ["companion_dragon.png"]},
}

var _root: Control
var _stage: Control
var _portrait: TextureRect
var _name: Label
var _text: Label
var _choices: Array = []
var _typing: Tween
var _last_advance := 0.0
var _asking := false


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	_stage = Control.new()
	_stage.size = DesignUI.BASE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stage)
	DesignUI.anchor(_stage, "bc")
	DesignUI.piece(_stage, S, "box")
	# the portrait sits inside the ring: a circle mask over the picture
	var pr := DesignUI.area(S, "portrait_in")
	var mask := CircleMask.new()
	mask.position = pr.position
	mask.size = pr.size
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_stage.add_child(mask)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.add_child(_portrait)
	_name = DesignUI.text(_stage, "", DesignUI.area(S, "name"), 26, Color("3a1a04"), 0)
	_text = DesignUI.text(_stage, "", DesignUI.area(S, "text"), 30, Color.WHITE, 4, Color("0a1430"), HORIZONTAL_ALIGNMENT_RIGHT)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in 2:
		var piece := "choice_a" if i == 0 else "choice_b"
		var b := DesignUI.button(_stage, DesignUI.piece_path(S, piece), DesignUI.rect(S, piece), func(): chosen.emit(i))
		var label := DesignUI.text(b, "", Rect2(Vector2.ZERO, DesignUI.rect(S, piece).size), 28, Color.WHITE, 6, Color("101030"))
		b.set_meta("label", label)
		b.visible = false
		_choices.append(b)


func play(lines: Array) -> void:
	_root.visible = true
	for line in lines:
		_show(line)
		await advanced
		AudioManager.stop_voice()
	_root.visible = false


## A question with two answers (K11 riddles, the name at the start): returns the index picked.
func ask(line: Dictionary, choices: Array) -> int:
	_root.visible = true
	_asking = true
	_show(line)
	_text.visible_ratio = 1.0
	for i in 2:
		_choices[i].visible = i < choices.size()
		if i < choices.size():
			_choices[i].get_meta("label").text = Names.fmt(String(choices[i]))
	var index: int = await chosen
	for b in _choices:
		b.visible = false
	_asking = false
	AudioManager.stop_voice()
	_root.visible = false
	return index


func _show(line: Dictionary) -> void:
	var who := String(line.get("who", "pilo"))
	var speaker: Dictionary = SPEAKERS.get(who, SPEAKERS.pilo)
	_name.text = Names.fmt(String(speaker.name))
	_portrait.texture = null
	if PORTRAITS.has(who):
		_portrait.texture = DesignUI.tex(PORTRAITS[who])
	elif speaker.texture is Array:
		for file in speaker.texture:
			if ResourceLoader.exists(ART + file):
				_portrait.texture = load(ART + file)
				break
	_text.text = Names.fmt(String(line.get("text", "")))
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(_text.text.length() * 0.03, 0.3, 1.6))
	if line.has("id"):
		if AudioManager.play_voice(String(line.id)) and _typing:
			_typing.set_speed_scale(0.8)


func _input(event: InputEvent) -> void:
	if not _root.visible or _asking:
		return
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		pressed = true
	if pressed:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_advance < 0.25:
		return
	_last_advance = now
	if _text.visible_ratio < 1.0:
		if _typing:
			_typing.kill()
		_text.visible_ratio = 1.0
		return
	UIKit.play_click()
	advanced.emit()


class CircleMask extends Control:
	func _draw() -> void:
		draw_circle(size * 0.5, size.x * 0.5, Color.WHITE)
