extends Node
## World / level catalog and scene changes with a soft fade.

const GAME_SCENE := "res://scenes/gameplay/game.tscn"
const MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const MAP_SCENE := "res://scenes/menus/world_map.tscn"
const STORE_SCENE := "res://scenes/menus/store.tscn"
const INTRO_SCENE := "res://scenes/story/intro.tscn"

## The nine worlds (8 levels each: 6 normal, a secret one opened by stars, and the boss).
## The ninth, «سرزمین وارونه», opens with the eight legendary diamonds.
const WORLDS := [
	{
		"id": "forest", "title": "جنگل رنگارستان", "subtitle": "سایه‌ها جنگل را گرفته‌اند", "index": 1,
		"first": 1, "last": 8, "free": true, "available": true, "sku": "",
		"secret_level": 7, "boss_level": 8,
		"card": "res://assets/ui/worlds/forest.png",
		"background": "res://assets/environments/bg_forest.jpg", "music": "forest", "ambient": "forest",
		"palette": {"dirt": "8d5a34", "dirt_dark": "6e4325", "grass": "6cc24a", "grass_light": "a6e070", "rock": "9ea3ad", "rock_dark": "6f7580", "wood": "c08048", "wood_dark": "7c4a24", "vine": "4cb848", "vine_dark": "2f7f34", "flower": "ff8fb1", "water": "3d9be0", "hills": "5aa84a"},
	},
	{
		"id": "coral_beach", "title": "ساحل مرجانی", "subtitle": "اختاپوس بزرگ دریا را تاریک کرده", "index": 2,
		"first": 9, "last": 16, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 15, "boss_level": 16,
		"card": "res://assets/ui/worlds/coral_beach.png",
		"background": "res://assets/environments/bg_sky.jpg", "music": "sky", "ambient": "stream",
		"palette": {"dirt": "e8c98a", "dirt_dark": "c9a35f", "grass": "f4e0a8", "grass_light": "fff3c9", "rock": "d98a7a", "rock_dark": "a85f55", "wood": "b98552", "wood_dark": "7c5330", "vine": "3fc1b0", "vine_dark": "23857a", "flower": "ff7f9f", "water": "2fa7e0", "hills": "58c3d6"},
	},
	{
		"id": "golden_desert", "title": "بیابان طلایی", "subtitle": "کرم شنی زیر تپه‌ها پنهان است", "index": 3,
		"first": 17, "last": 24, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 23, "boss_level": 24,
		"card": "res://assets/ui/worlds/golden_desert.png",
		"background": "res://assets/environments/bg_forest.jpg", "music": "forest", "ambient": "sky",
		"palette": {"dirt": "d9a55a", "dirt_dark": "b07f3a", "grass": "f2c46d", "grass_light": "ffe0a0", "rock": "c98b5a", "rock_dark": "94633b", "wood": "a8743f", "wood_dark": "6e4a25", "vine": "8bb04a", "vine_dark": "5c7a2e", "flower": "ff6f61", "water": "3db8d6", "hills": "e8b36a"},
	},
	{
		"id": "snow_mountain", "title": "کوهستان برفی", "subtitle": "غول یخی قله را بسته", "index": 4,
		"first": 25, "last": 32, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 31, "boss_level": 32,
		"card": "res://assets/ui/worlds/snow_mountain.png",
		"background": "res://assets/environments/bg_sky.jpg", "music": "sky", "ambient": "sky",
		"palette": {"dirt": "8aa3c0", "dirt_dark": "657f9c", "grass": "f4f8ff", "grass_light": "ffffff", "rock": "aab6c8", "rock_dark": "7d899c", "wood": "9c6b44", "wood_dark": "6a4528", "vine": "7fd0e8", "vine_dark": "4b98b3", "flower": "9fd8ff", "water": "6cc0ee", "hills": "dfeaf7"},
	},
	{
		"id": "sky_islands", "title": "جزیره‌های آسمانی", "subtitle": "عقاب طوفان آسمان را آشفته کرده", "index": 5,
		"first": 33, "last": 40, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 39, "boss_level": 40,
		"card": "res://assets/ui/worlds/sky_islands.png",
		"background": "res://assets/environments/bg_sky.jpg", "music": "sky", "ambient": "sky",
		"palette": {"dirt": "a0704a", "dirt_dark": "7d5434", "grass": "7fd65a", "grass_light": "c2f08a", "rock": "c9ced8", "rock_dark": "9097a6", "wood": "d09a5c", "wood_dark": "8a5a2c", "vine": "6fd2c0", "vine_dark": "3a9a8a", "flower": "ffd166", "water": "7cc8f5", "hills": "ffffff"},
	},
	{
		"id": "crystal_caves", "title": "غارهای بلورین", "subtitle": "عنکبوت بلورین در تاریکی کمین کرده", "index": 6,
		"first": 41, "last": 48, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 47, "boss_level": 48,
		"card": "res://assets/ui/worlds/crystal_caves.png",
		"background": "res://assets/environments/bg_cave.jpg", "music": "cave", "ambient": "cave",
		"palette": {"dirt": "5a4a7a", "dirt_dark": "40345c", "grass": "8f7fd6", "grass_light": "c7b8ff", "rock": "a59ccc", "rock_dark": "6f6699", "wood": "a87850", "wood_dark": "6e4a2c", "vine": "5fd0e8", "vine_dark": "2f8aa8", "flower": "7ef0ff", "water": "5a8ae8", "hills": "3a2a5a"},
	},
	{
		"id": "clock_factory", "title": "کارخانهٔ ساعت", "subtitle": "بابابزرگ طلسم شده و دستگاه‌ها دیوانه‌اند", "index": 7,
		"first": 49, "last": 56, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 55, "boss_level": 56,
		"card": "res://assets/ui/worlds/clock_factory.png",
		"background": "res://assets/environments/bg_cave.jpg", "music": "cave", "ambient": "cave",
		"palette": {"dirt": "7a5a44", "dirt_dark": "5a3f2e", "grass": "c98a3a", "grass_light": "f0b860", "rock": "9a8f84", "rock_dark": "6b625a", "wood": "b5793d", "wood_dark": "7a4d22", "vine": "d9a441", "vine_dark": "a6741f", "flower": "ffcf4a", "water": "4a90c0", "hills": "6b4a33"},
	},
	{
		"id": "shadow_castle", "title": "قلعهٔ سایه", "subtitle": "تالار شاه‌سایه آن بالاست", "index": 8,
		"first": 57, "last": 64, "free": false, "available": true, "sku": "worlds_pack",
		"secret_level": 63, "boss_level": 64,
		"card": "res://assets/ui/worlds/shadow_castle.png",
		"background": "res://assets/environments/bg_cave.jpg", "music": "cave", "ambient": "cave",
		"palette": {"dirt": "3a2f4f", "dirt_dark": "271f38", "grass": "6a4fa0", "grass_light": "9d7fe0", "rock": "6f6889", "rock_dark": "4a4460", "wood": "6e5a7a", "wood_dark": "463852", "vine": "8a5fd0", "vine_dark": "5a3a9a", "flower": "d07fff", "water": "5a4ab0", "hills": "2a1f40"},
	},
	{
		"id": "inverted_land", "title": "سرزمین وارونه", "subtitle": "جایی که زروان پنهان شده", "index": 9,
		"first": 65, "last": 72, "free": false, "available": true, "sku": "",
		"secret_level": 71, "boss_level": 72,
		"card": "res://assets/ui/worlds/inverted_land.png",
		"background": "res://assets/environments/bg_sky.jpg", "music": "sky", "ambient": "sky",
		"palette": {"dirt": "4a3a6a", "dirt_dark": "32284a", "grass": "e07fd0", "grass_light": "ffb0f0", "rock": "8a7fb0", "rock_dark": "5f557f", "wood": "8f6a9a", "wood_dark": "5f4468", "vine": "7fe0d0", "vine_dark": "3fa898", "flower": "fff07f", "water": "7f9fff", "hills": "6a4a9a"},
	},
]

const LEVEL_TITLES := [
	"راه سنجابک",
	"پل کُنده‌ها",
	"آبشار قدیمی",
	"تونل ریشه‌ها",
	"درخت هزارساله",
	"درهٔ قارچ‌ها",
	"باغ پنهان",
	"لانهٔ خرس پیر",
	"صدف‌های آوازخوان",
	"باغ مرجان",
	"جزر و مد",
	"کشتی غرق‌شده",
	"غار مروارید",
	"فانوس دریایی",
	"تالاب پنهان",
	"خانهٔ اختاپوس",
	"تپه‌های روان",
	"واحهٔ نخل",
	"طوفان شن",
	"هرم فراموش‌شده",
	"کاروان گمشده",
	"درهٔ عقرب‌ها",
	"گنج زیر شن",
	"لانهٔ کرم شنی",
	"سُرسُرهٔ یخی",
	"غار قندیل",
	"پل طناب",
	"دهکدهٔ پنگوئن‌ها",
	"بهمن!",
	"قلهٔ باد",
	"دریاچهٔ یخ‌زده",
	"تخت غول یخی",
	"پلکان ابری",
	"باغ بادبادک",
	"جزیرهٔ معلق",
	"آسیاب‌های باد",
	"دروازهٔ رنگین‌کمان",
	"ابرهای رعدی",
	"جزیرهٔ گمشده",
	"برج طوفان",
	"تونل کرم‌شب‌تاب",
	"دریاچهٔ زیرزمینی",
	"تالار آینه‌ها",
	"معدن رنگی",
	"پل بلورین",
	"تاریکی ژرف",
	"رگهٔ الماس",
	"تار عنکبوت بلورین",
	"تسمهٔ بی‌پایان",
	"برج آونگ",
	"اتاق فنرها",
	"کارگاه چرخ‌دنده",
	"پرس‌های بزرگ",
	"لیزرها",
	"انبار مخفی",
	"قلب کارخانه",
	"دروازهٔ شب",
	"راهروی پژواک",
	"باغ سایه‌ها",
	"پل ناپیدا",
	"کتابخانهٔ تاریک",
	"برج‌های دوقلو",
	"تالار آینهٔ سیاه",
	"تالار شاه‌سایه",
	"آسمان پایین",
	"آبشار وارونه",
	"جنگل معکوس",
	"ساعت‌های شناور",
	"پلکان زمان",
	"شهر وارونه",
	"قلب وارونه",
	"ساعت وارونه",
]

var current_level := 1
## Tests can play a hand-made map: when set, load_level returns it instead of the file.
var override_level: Dictionary = {}
## Where the opening story goes when it ends: "menu" or "level" (level 1, for a new game).
var after_intro := "menu"
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
	if not override_level.is_empty():
		return override_level
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


func goto_intro(then := "menu") -> void:
	after_intro = then
	change_scene(INTRO_SCENE)


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
