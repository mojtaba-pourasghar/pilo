class_name Background
extends CanvasLayer
## Two parallax layers behind the level: the painted world picture (slow) and soft
## procedural hills or clouds (faster), for depth on any screen width.

const FAR_SCROLL := 0.2
const NEAR_SCROLL := 0.45

var texture_path := ""
var hills_color := Color("5aa84a")

var _far: TextureRect
var _near: Hills
var _texture: Texture2D
var _scale := 1.0
var _tween: Tween


func _ready() -> void:
	layer = -10
	_texture = load(texture_path)
	_far = TextureRect.new()
	_far.texture = _texture
	_far.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_far.stretch_mode = TextureRect.STRETCH_TILE
	_far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_far)
	_near = Hills.new()
	_near.color = hills_color
	add_child(_near)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	_scale = view.y * 1.1 / _texture.get_height()
	_far.scale = Vector2(_scale, _scale)
	_far.size = Vector2(view.x / _scale + _texture.get_width() * 2.0, _texture.get_height())
	_near.view = view


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var tile_width := _texture.get_width() * _scale
	_far.position = Vector2(-fposmod(center.x * FAR_SCROLL, tile_width), -_texture.get_height() * _scale * 0.08)
	_near.offset_x = center.x * NEAR_SCROLL
	_near.queue_redraw()


func set_tint(color: Color, instant: bool) -> void:
	if _tween:
		_tween.kill()
	if instant:
		_far.modulate = color
		_near.modulate = color
		return
	_tween = create_tween()
	_tween.tween_property(_far, "modulate", color, 0.4)
	_tween.parallel().tween_property(_near, "modulate", color, 0.4)


class Hills extends Node2D:
	var color := Color.WHITE
	var view := Vector2(1280, 720)
	var offset_x := 0.0

	func _draw() -> void:
		var points := PackedVector2Array()
		var step := 24.0
		var count := int(view.x / step) + 2
		for i in count:
			var x := i * step
			var wx := x + offset_x
			var y := view.y * 0.7 - 40.0 * sin(wx * 0.004) - 22.0 * sin(wx * 0.011 + 1.3)
			points.append(Vector2(x, y))
		points.append(Vector2(view.x + step, view.y))
		points.append(Vector2(0, view.y))
		draw_colored_polygon(points, Color(color, 0.45))
