class_name ChapterCard
extends CanvasLayer
## The chapter that opens a world (data/story/chapters.json): the world's card picture over
## the whole screen, the chapter title, then its story lines in the dialogue box. Shown the
## first time a world is entered (SaveManager "chapters"); replayed from the world map.

signal finished

const DATA := "res://data/story/chapters.json"

var world_id := "forest"
var card_path := ""
var dialogue: Node


static func lines_for(world: String) -> Dictionary:
	var file := FileAccess.open(DATA, FileAccess.READ)
	if file == null:
		return {}
	var all: Dictionary = JSON.parse_string(file.get_as_text())
	return all.get(world, {})


static func seen(world: String) -> bool:
	return SaveManager.data.get("chapters", []).has(world)


static func mark_seen(world: String) -> void:
	var list: Array = SaveManager.data.get("chapters", [])
	if not list.has(world):
		list.append(world)
	SaveManager.data.chapters = list
	SaveManager.save_game()


func play() -> void:
	var chapter := lines_for(world_id)
	if chapter.is_empty():
		finished.emit()
		return
	layer = 19
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.1, 0.92)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	if card_path != "" and ResourceLoader.exists(card_path):
		var picture := TextureRect.new()
		picture.texture = load(card_path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		picture.offset_top = 90
		picture.offset_bottom = -230
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(picture)
		picture.pivot_offset = Vector2(640, 200)
		picture.create_tween().tween_property(picture, "scale", Vector2(1.06, 1.06), 8.0).from(Vector2.ONE)
	var title := UIKit.make_title(String(chapter.get("title", "")), 54)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 18
	root.add_child(title)
	root.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(root, "modulate:a", 1.0, 0.5)
	await fade.finished
	AudioManager.play_sfx("shift", 0.8, -6.0)
	if dialogue:
		await dialogue.play(chapter.get("lines", []))
	var out := create_tween()
	out.tween_property(root, "modulate:a", 0.0, 0.4)
	await out.finished
	mark_seen(world_id)
	finished.emit()
	queue_free()
