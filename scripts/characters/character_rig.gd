class_name CharacterRig
extends Node2D
## Base for characters drawn entirely in code (no pictures): a pose made of joint angles is
## blended toward a target pose every frame, then every body part is drawn with a dark
## outline, a flat fill and a soft highlight. Origin = feet on the ground, facing right
## (flip with scale.x = -1).

const OUTLINE := Color("3b2418")
const OUTLINE_W := 2.6

var state := "idle"
var speed := 0.0          ## horizontal speed in px/s (drives the run cycle)
var run_speed := 520.0    ## speed at which the run cycle is at full stride
var expression := "normal"

var t := 0.0
var phase := 0.0
var pose: Dictionary = {}
var _blink := 0.0
var _next_blink := 2.0


func _process(delta: float) -> void:
	t += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.0, 4.5)
	_blink = maxf(0.0, _blink - delta)
	var target := target_pose(delta)
	var k := 1.0 - exp(-blend_rate() * delta)
	for key in target:
		pose[key] = lerpf(float(pose.get(key, target[key])), float(target[key]), k)
	queue_redraw()


## Override: returns {joint: value} for the current state.
func target_pose(_delta: float) -> Dictionary:
	return {}


func blend_rate() -> float:
	return 16.0


func p(key: String) -> float:
	return float(pose.get(key, 0.0))


func eyes_open() -> float:
	return 0.12 if _blink > 0.0 else 1.0


# --- Drawing helpers -------------------------------------------------------

## A limb segment with round ends, outlined.
func capsule(a: Vector2, b: Vector2, width: float, fill: Color, shade := Color(0, 0, 0, 0)) -> void:
	var ow := width + OUTLINE_W * 2.0
	draw_line(a, b, OUTLINE, ow)
	draw_circle(a, ow * 0.5, OUTLINE)
	draw_circle(b, ow * 0.5, OUTLINE)
	draw_line(a, b, fill, width)
	draw_circle(a, width * 0.5, fill)
	draw_circle(b, width * 0.5, fill)
	if shade.a > 0.0:
		var side := (b - a).orthogonal().normalized() * width * 0.22
		draw_line(a + side, b + side, shade, width * 0.4)


## Filled polygon with an outline and an optional inner highlight polygon.
func shape(points: PackedVector2Array, fill: Color, outline := true) -> void:
	if outline:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, OUTLINE, OUTLINE_W * 2.0, true)
		for point in points:
			draw_circle(point, OUTLINE_W, OUTLINE)
	draw_colored_polygon(points, fill)


func ellipse_points(center: Vector2, radius: Vector2, rotation_angle := 0.0, segments := 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(rotation_angle))
	return points


func ellipse(center: Vector2, radius: Vector2, fill: Color, rotation_angle := 0.0, outline := true) -> void:
	shape(ellipse_points(center, radius, rotation_angle), fill, outline)


## Rounded rectangle centred on `center`, rotated.
func round_rect_points(center: Vector2, size: Vector2, radius: float, rotation_angle := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := size * 0.5 - Vector2(radius, radius)
	var corners := [Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y), Vector2(half.x, -half.y)]
	for c in 4:
		var base := PI * 0.5 * c
		for i in 5:
			var a := base + PI * 0.5 * i / 4.0
			points.append(center + (corners[c] + Vector2(cos(a), sin(a)) * radius).rotated(rotation_angle))
	return points


## Smooth closed curve through control points (Catmull-Rom), for hair, tails, caps.
func smooth_points(controls: Array, steps := 6) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := controls.size()
	for i in n:
		var p0: Vector2 = controls[(i - 1 + n) % n]
		var p1: Vector2 = controls[i]
		var p2: Vector2 = controls[(i + 1) % n]
		var p3: Vector2 = controls[(i + 2) % n]
		for s in steps:
			var u := float(s) / steps
			var u2 := u * u
			var u3 := u2 * u
			points.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3))
	return points


## Point at the end of a bone that starts at `from`, `length` long, `angle` from straight down
## (positive = forward, i.e. toward +x).
static func bone(from: Vector2, length: float, angle: float) -> Vector2:
	return from + Vector2(sin(angle), cos(angle)) * length
