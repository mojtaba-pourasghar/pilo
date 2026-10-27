extends CanvasLayer
## End-of-level popup: stars found, time-shard reward and what to do next.

signal action(name: String)

var level_id := 1
var stars_found := 0
var stars_total := 3
var first_time := false


func _ready() -> void:
	layer = 40
	var modal := UIKit.make_modal(self, Vector2(640, 0))
	var box: VBoxContainer = modal.box
	box.add_child(UIKit.make_strip_title("آفرین!", 48))
	box.add_child(UIKit.make_label(LevelManager.level_title(level_id), 32))

	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 14)
	box.add_child(stars)
	for i in stars_total:
		var star := UIKit.make_icon("res://assets/ui/star.png", 84)
		star.modulate = Color.WHITE if i < stars_found else Color(0.2, 0.2, 0.3, 0.35)
		stars.add_child(star)
		if i < stars_found:
			star.scale = Vector2.ZERO
			star.resized.connect(func(): star.pivot_offset = star.size * 0.5)
			var tween := create_tween()
			tween.tween_interval(0.25 + i * 0.25)
			tween.tween_callback(func(): AudioManager.play_sfx("star", 1.0 + i * 0.12))
			tween.tween_property(star, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if first_time:
		var reward := HBoxContainer.new()
		reward.alignment = BoxContainer.ALIGNMENT_CENTER
		reward.add_child(UIKit.make_icon("res://assets/ui/crystal.png", 52))
		reward.add_child(UIKit.make_label("یک تکهٔ زمان پیدا کردی!", 28, UIKit.PURPLE))
		box.add_child(reward)

	var next_id := level_id + 1
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	if LevelManager.has_level(next_id) and ProgressManager.is_unlocked(next_id):
		_add(row, "مرحلهٔ بعد", UIKit.GREEN, "next")
	elif not LevelManager.world_of(next_id).is_empty():
		box.add_child(UIKit.make_label("دنیای بعدی: «%s» به‌زودی!" % LevelManager.world_of(next_id).title, 26, UIKit.BLUE))
	_add(row, "دوباره", UIKit.BLUE, "retry")
	_add(row, "نقشه", UIKit.ORANGE, "map")


func _add(row: HBoxContainer, text: String, color: Color, id: String) -> void:
	var button := UIKit.make_button(text, color, 180, 30)
	button.pressed.connect(func(): action.emit(id))
	row.add_child(button)
