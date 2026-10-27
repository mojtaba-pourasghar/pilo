extends Control
## Loading screen: applies the theme, warms up heavy resources, then opens the menu.

const WARM_UP := [
	"res://scenes/gameplay/game.tscn",
	"res://assets/environments/bg_forest.jpg",
	"res://assets/characters/hero.png",
	"res://assets/characters/pilo.png",
]

var _bar: ProgressBar
var _shown := 0.0
var _done := false


func _ready() -> void:
	UIKit.ensure_theme()
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp"))
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.add_child(UIKit.spacer())
	var title := UIKit.make_title("سفر پیلو", 120)
	column.add_child(title)
	column.add_child(UIKit.spacer())
	column.add_child(UIKit.make_label("در حال بارگذاری...", 28, Color.WHITE, 8, UIKit.BROWN))
	var center := CenterContainer.new()
	column.add_child(center)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(560, 36)
	_bar.show_percentage = false
	center.add_child(_bar)
	column.add_child(UIKit.spacer(Vector2(0, 50), false))
	for path in WARM_UP:
		ResourceLoader.load_threaded_request(path)


func _process(delta: float) -> void:
	var total := 0.0
	for path in WARM_UP:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not progress.is_empty():
			total += float(progress[0])
		else:
			total += 1.0
	_shown = move_toward(_shown, total / WARM_UP.size(), delta * 1.4)
	_bar.value = _shown * 100.0
	if _shown >= 1.0 and not _done:
		_done = true
		for path in WARM_UP:
			ResourceLoader.load_threaded_get(path)
		LevelManager.goto_menu()
