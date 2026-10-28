extends Node
## World / level catalog and scene changes with a soft fade.

const GAME_SCENE := "res://scenes/gameplay/game.tscn"
const MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const MAP_SCENE := "res://scenes/menus/world_map.tscn"
const STORE_SCENE := "res://scenes/menus/store.tscn"

const WORLDS := [
	{
		"id": "forest", "title": "جنگل جوانه‌ها", "subtitle": "آموزش و اکتشاف",
		"first": 1, "last": 10, "free": true, "available": true, "sku": "",
		"background": "res://assets/environments/bg_forest.jpg", "music": "forest", "ambient": "forest",
		"palette": {
			"dirt": "8d5a34", "dirt_dark": "6e4325", "grass": "6cc24a", "grass_light": "a6e070",
			"rock": "9ea3ad", "rock_dark": "6f7580", "wood": "c08048", "wood_dark": "7c4a24",
			"vine": "4cb848", "vine_dark": "2f7f34", "flower": "ff8fb1", "water": "3d9be0",
			"hills": "5aa84a",
		},
	},
	{
		"id": "sky_islands", "title": "جزیره‌های ابری", "subtitle": "ترکیب مکانیک‌ها",
		"first": 11, "last": 20, "free": false, "available": false, "sku": "worlds_pack",
		"background": "res://assets/environments/bg_sky.jpg", "music": "sky", "ambient": "sky",
		"palette": {
			"dirt": "a0704a", "dirt_dark": "7d5434", "grass": "7fd65a", "grass_light": "c2f08a",
			"rock": "c9ced8", "rock_dark": "9097a6", "wood": "d09a5c", "wood_dark": "8a5a2c",
			"vine": "6fd2c0", "vine_dark": "3a9a8a", "flower": "ffd166", "water": "7cc8f5",
			"hills": "ffffff",
		},
	},
	{
		"id": "crystal_caves", "title": "غارهای بلورین", "subtitle": "چالش و جمع‌بندی",
		"first": 21, "last": 30, "free": false, "available": false, "sku": "worlds_pack",
		"background": "res://assets/environments/bg_cave.jpg", "music": "cave", "ambient": "cave",
		"palette": {
			"dirt": "5a4a7a", "dirt_dark": "40345c", "grass": "8f7fd6", "grass_light": "c7b8ff",
			"rock": "a59ccc", "rock_dark": "6f6699", "wood": "a87850", "wood_dark": "6e4a2c",
			"vine": "5fd0e8", "vine_dark": "2f8aa8", "flower": "7ef0ff", "water": "5a8ae8",
			"hills": "3a2a5a",
		},
	},
]

const LEVEL_TITLES := [
	"سلام، پیلو!", "پرش روی قارچ‌ها", "پل دو زمانه", "بذر گمشده", "درِ گردویی",
	"راه پنهان", "آبراه کوچک", "سکوهای بازیگوش", "نجات سنجابک", "جشن جنگل",
	"به‌سوی ابرها", "باد از کدام طرف؟", "ابر پل‌ساز", "آسیاب آسمانی", "فنرهای رنگی",
	"جزیره گمشده", "باد و زمان", "تعقیب غبارک", "دوست ابری", "دروازه آسمان",
	"غار درخشان", "آینه کوچک", "بلورهای خاموش", "درِ دو زمان", "سکوی ناپایدار",
	"سه پرتو نور", "مسیر بلورین", "آخرین تکه زمان", "غبارک گرفتار", "جشن رنگارستان",
]

var current_level := 1
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(1.0, 0.96, 0.88, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func world_of(level_id: int) -> Dictionary:
	for world in WORLDS:
		if level_id >= world.first and level_id <= world.last:
			return world
	return {}


func world_by_id(world_id: String) -> Dictionary:
	for world in WORLDS:
		if world.id == world_id:
			return world
	return {}


func level_title(level_id: int) -> String:
	if level_id < 1 or level_id > LEVEL_TITLES.size():
		return ""
	return LEVEL_TITLES[level_id - 1]


func level_path(level_id: int) -> String:
	var world := world_of(level_id)
	if world.is_empty():
		return ""
	return "res://data/levels/%s/level_%02d.json" % [world.id, level_id]


func has_level(level_id: int) -> bool:
	var world := world_of(level_id)
	return not world.is_empty() and world.available and FileAccess.file_exists(level_path(level_id))


func load_level(level_id: int) -> Dictionary:
	if not has_level(level_id):
		return {}
	var file := FileAccess.open(level_path(level_id), FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func play_level(level_id: int) -> void:
	current_level = level_id
	change_scene(GAME_SCENE)


func goto_menu() -> void:
	change_scene(MENU_SCENE)


func goto_map() -> void:
	change_scene(MAP_SCENE)


func goto_store() -> void:
	change_scene(STORE_SCENE)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.3)
	await tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
