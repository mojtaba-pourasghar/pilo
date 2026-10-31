class_name Tutorial
extends CanvasLayer
## The first-time guide (level 1, or "راهنمای بازی" in the settings): the screen dims, a
## glowing ring circles one button at a time and a card says what it does, Pilo's button
## most of all. Tap anywhere for the next step. The game is paused meanwhile.

signal finished

## [hud touch key or "team", text]
const STEPS := [
	["left", "با این دو دکمه راه برو. اگر نگه داری، نیما تندتر می‌دود."],
	["jump", "پرش. روی سر سایه‌ها بپر تا شکست بخورند و سکه بدهند. وسط پرش، پرش را نگه دار تا پیلو تو را ببرد و سُر بخوری."],
	["pilo", "دکمهٔ پیلو! نزدیک دشمن: پیلو می‌پرد و آزادش می‌کند. نزدیک آجر یا دیوار ترک‌دار: آن را می‌شکند. نزدیک لانهٔ روباه: کلید زمان یا الماس را بیرون می‌آورد. اگر چیزی نزدیک نباشد، پیلو را مثل گلولهٔ آتش جلو پرتاب می‌کنی."],
	["fire", "شلیک! تیرکمان از اول مال توست. سلاح‌های بیشتر را در دهکده بخر و با دکمهٔ کوچک بالایش عوضشان کن."],
	["dash", "دَش: یک جهش تند به جلو. دیوار ترک‌دار را می‌شکند و از روی سایه‌ها رد می‌شود."],
	["time", "عدسی زمان: بین گذشته و حال جابه‌جا شو. بعضی پل‌ها فقط در گذشته هستند."],
	["down", "پایین: خم شو تا از زیر سقف کوتاه رد شوی. روی لولهٔ درخشان، با این دکمه داخلش برو."],
	["team", "کوله: وسط بازی همراهت (مثل سنجابک)، ابزارهای کوله و سلاح را عوض کن. هر همراه راه تازه‌ای باز می‌کند."],
]

var hud: Node
var _step := -1
var _ring: Ring
var _card: PanelContainer
var _text: Label


static func seen() -> bool:
	return bool(SaveManager.data.get("tutorial_seen", false))


func _ready() -> void:
	layer = 46
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ring = Ring.new()
	add_child(_ring)
	_card = PanelContainer.new()
	var style := UIKit.flat(Color(1, 0.98, 0.92, 0.98), 22, 18)
	style.border_color = Color("f39a2b")
	style.set_border_width_all(5)
	_card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_card.add_child(box)
	_text = UIKit.make_label("", 26)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(640, 0)
	_text.layout_direction = Control.LAYOUT_DIRECTION_RTL
	box.add_child(_text)
	box.add_child(UIKit.make_label("برای ادامه ضربه بزن ▼", 18, Color(0.5, 0.35, 0.2, 0.8)))
	add_child(_card)
	get_tree().paused = true
	_next()


func _next() -> void:
	_step += 1
	if _step >= STEPS.size():
		SaveManager.data.tutorial_seen = true
		SaveManager.save_game()
		get_tree().paused = false
		finished.emit()
		queue_free()
		return
	var key: String = STEPS[_step][0]
	_text.text = STEPS[_step][1]
	var rect: Rect2 = hud.button_rect(key) if hud else Rect2(640, 360, 100, 100)
	_ring.target = rect
	_ring.queue_redraw()
	_card.reset_size()
	await get_tree().process_frame
	var view := get_viewport().get_visible_rect().size
	# the card sits away from the circled button (above it, or below for the top bar)
	var y := rect.position.y - _card.size.y - 30.0 if rect.position.y > view.y * 0.4 else rect.end.y + 30.0
	_card.position = Vector2(clampf(rect.get_center().x - _card.size.x * 0.5, 20.0, view.x - _card.size.x - 20.0), clampf(y, 20.0, view.y - _card.size.y - 20.0))
	UIKit.play_click()


func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) \
		or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept")
	if pressed:
		get_viewport().set_input_as_handled()
		_next()


## Dims everything except a glowing ring around the button being explained.
class Ring extends Node2D:
	var target := Rect2()
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var view := get_viewport().get_visible_rect().size
		var c := target.get_center()
		var r := maxf(target.size.x, target.size.y) * 0.62 + sin(t * 5.0) * 4.0
		# dim the screen with a hole around the button
		var outer := PackedVector2Array([Vector2(0, 0), Vector2(view.x, 0), Vector2(view.x, view.y), Vector2(0, view.y), Vector2(0, 0)])
		var hole := PackedVector2Array()
		for i in 41:
			var a := TAU * i / 40.0
			hole.append(c + Vector2(cos(a), sin(a)) * r)
		var shape := outer + hole
		draw_colored_polygon(shape, Color(0.05, 0.04, 0.1, 0.62))
		draw_arc(c, r, 0.0, TAU, 48, Color(1, 0.8, 0.2, 0.95), 6.0)
		draw_arc(c, r + 10.0, 0.0, TAU, 48, Color(1, 0.8, 0.2, 0.35), 4.0)
