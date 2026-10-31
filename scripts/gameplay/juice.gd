class_name Juice
extends RefCounted
## How hits feel: every impact shakes the camera (trauma that fades), freezes the game for a
## few hundredths of a second (hit-stop), buzzes the phone (if vibration is on in the
## settings), flashes the screen and leaves an impact star with a shock ring and a sound.
## strength: 0 = a light tap (stomp), 1 = the biggest hit (a guardian's slam, a defeat).

const STAR_POINTS := 8

static var _stop_until := 0


static func hit(node: Node, pos: Vector2, strength: float, sound := "") -> void:
	if node == null or not node.is_inside_tree():
		return
	strength = clampf(strength, 0.0, 1.0)
	shake(node, 0.2 + strength * 0.6)
	if strength >= 0.15:
		freeze(node, 0.025 + strength * 0.075)
	vibrate(int(15 + strength * 70))
	var star := Impact.new()
	star.position = pos
	star.size = 30.0 + strength * 60.0
	var parent := node.get_parent() if node.get_parent() is Node2D else node
	parent.add_child(star)
	star.global_position = pos
	if sound != "":
		AudioManager.play_sfx(sound, randf_range(0.92, 1.08))


## Camera trauma (0..1); the shake grows with its square and dies down by itself.
static func shake(node: Node, trauma: float) -> void:
	var camera := node.get_viewport().get_camera_2d()
	if camera and camera.has_method("add_trauma"):
		camera.call("add_trauma", trauma)


## Hit-stop: the world almost stops for a moment so a hit lands with weight.
static func freeze(node: Node, seconds: float) -> void:
	var now := Time.get_ticks_msec()
	if now < _stop_until:
		return
	_stop_until = now + int(seconds * 1000.0) + 120
	Engine.time_scale = 0.05
	node.get_tree().create_timer(seconds, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


static func vibrate(ms: int) -> void:
	if not bool(SaveManager.data.get("settings", {}).get("vibration", true)):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


## A full-screen flash (white for big hits, red when Nima is hurt).
static func flash(node: Node, color: Color, seconds := 0.25) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	node.get_tree().current_scene.add_child(layer)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, seconds)
	tween.tween_callback(layer.queue_free)


## The star of light where a hit lands, with a shock ring.
class Impact extends Node2D:
	var size := 50.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 12
		rotation = randf() * TAU

	func _process(delta: float) -> void:
		_t += delta / 0.28
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := ease(_t, 0.4)
		var alpha := 1.0 - _t
		var star := PackedVector2Array()
		for i in STAR_POINTS * 2:
			var r := size * (1.0 if i % 2 == 0 else 0.38) * (0.6 + k * 0.6)
			var a := i * PI / STAR_POINTS
			star.append(Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(star, Color(1, 0.95, 0.7, alpha))
		draw_circle(Vector2.ZERO, size * 0.3 * (1.0 - _t), Color(1, 1, 1, alpha))
		draw_arc(Vector2.ZERO, size * (0.4 + k * 1.4), 0.0, TAU, 40, Color(1, 1, 1, alpha * 0.8), 5.0 * (1.0 - _t) + 1.0)
