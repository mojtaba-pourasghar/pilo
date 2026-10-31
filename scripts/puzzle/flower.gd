class_name Flower
extends Node2D
## Decoration that blooms in the present and is a closed bud in the past.

var palette: Dictionary = {}
var _bloom := 1.0
var _tween: Tween


func _ready() -> void:
	TimeShift.time_changed.connect(_on_time_changed)
	_on_time_changed(TimeShift.state, true)


func _on_time_changed(state: int, instant: bool) -> void:
	var target := 1.0 if state == TimeShift.PRESENT else 0.0
	if _tween:
		_tween.kill()
	if instant:
		_bloom = target
		queue_redraw()
		return
	_tween = create_tween()
	_tween.tween_method(_set_bloom, _bloom, target, 0.4)


func _set_bloom(value: float) -> void:
	_bloom = value
	queue_redraw()


func _draw() -> void:
	if WorldArt.pic("flower_open"):
		# rendered: a closed bud in the past, opening into a flower in the present
		var height := lerpf(30.0, 46.0, _bloom)
		WorldArt.draw(self, "flower_open" if _bloom > 0.5 else "flower_bud", Vector2(32, 66), height)
		return
	var stem := Color("3f8f3a")
	var petal: Color = palette.get("flower", Color("ff8fb1"))
	var height := lerpf(10.0, 22.0, _bloom)
	draw_line(Vector2(32, 64), Vector2(32, 64 - height), stem, 3.0)
	draw_circle(Vector2(26, 64 - height * 0.5), 4.0, stem)
	var head := Vector2(32, 64 - height)
	if _bloom < 0.3:
		draw_circle(head, 5.0, petal.darkened(0.2))
		return
	for i in 5:
		var a := i * TAU / 5.0
		draw_circle(head + Vector2(cos(a), sin(a)) * 6.0 * _bloom, 5.0 * _bloom, petal)
	draw_circle(head, 4.0, Color("ffe066"))
