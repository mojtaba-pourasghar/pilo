class_name Critter
extends Node2D
## A small living thing of the scenery (docs/40 §8.2): a squirrel running along the ground, a snail
## creeping, a frog hopping, a bird or butterfly flying past. Frame-by-frame art (v3_critters_forest);
## walkers follow the terrain curve, flyers drift on a gentle sine path. They turn at the ends of their
## range and pause now and then, so the scene is never still.

## kind -> {row, frames, fps, height (game px), speed, mode: walk | fly | hop, pause}
const KINDS := {
	"squirrel": {"row": 0, "n": 7, "fps": 12, "height": 40, "speed": 95.0, "mode": "walk", "pause": 2.5},
	"lizard": {"row": 2, "n": 8, "fps": 10, "height": 22, "speed": 70.0, "mode": "walk", "pause": 3.0},
	"snail": {"row": 3, "n": 5, "fps": 5, "height": 24, "speed": 10.0, "mode": "walk", "pause": 4.0},
	"ladybug": {"row": 4, "n": 5, "fps": 8, "height": 16, "speed": 22.0, "mode": "walk", "pause": 2.0},
	"frog": {"row": 11, "n": 9, "fps": 8, "height": 30, "speed": 40.0, "mode": "hop", "pause": 1.5},
	"bird": {"row": 5, "n": 8, "fps": 14, "height": 36, "speed": 150.0, "mode": "fly", "pause": 0.0},
	"dragonfly": {"row": 7, "n": 6, "fps": 18, "height": 30, "speed": 70.0, "mode": "fly", "pause": 0.0},
	"butterfly": {"row": 8, "n": 6, "fps": 12, "height": 30, "speed": 40.0, "mode": "fly", "pause": 0.0},
	"bee": {"row": 9, "n": 6, "fps": 20, "height": 24, "speed": 60.0, "mode": "fly", "pause": 0.0},
	"moth": {"row": 10, "n": 6, "fps": 14, "height": 28, "speed": 35.0, "mode": "fly", "pause": 0.0},
}
const SHEET := "v3_critters_forest"

var kind := "squirrel"
var x_min := 0.0
var x_max := 1000.0
var terrain: Node          ## TerrainCurve (height_at) or null
var base_y := 0.0          ## ground y when there is no terrain; flyers hover this far above the ground
var lift := 0.0

var _sprite: Sprite2D
var _frames: Array = []
var _spec: Dictionary = {}
var _t := 0.0
var _dir := 1.0
var _pause := 0.0
var _phase := 0.0
var _scale := 1.0
var _hop := 0.0


func _ready() -> void:
	_spec = KINDS.get(kind, KINDS.squirrel)
	_frames = SideRig.build_frames({"sheet": SHEET, "row": _spec.row, "frames": range(_spec.n)})
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	var hs: Array = []
	for fr in _frames:
		hs.append(fr.h)
	hs.sort()
	var stand: float = hs[hs.size() / 2] if not hs.is_empty() else 100.0
	_scale = float(_spec.height) / maxf(stand, 1.0)
	_phase = randf() * TAU
	_t = randf() * 3.0
	_dir = 1.0 if randf() < 0.5 else -1.0
	z_index = 1
	position.x = randf_range(x_min, x_max)


func _ground_y(x: float) -> float:
	if terrain != null and terrain.has_method("height_at"):
		var h: float = terrain.height_at(x)
		if h != INF:
			return h
	return base_y


func _process(delta: float) -> void:
	if _frames.is_empty():
		return
	_t += delta
	var moving := true
	if _pause > 0.0:
		_pause -= delta
		moving = false
	elif _spec.mode != "fly" and randf() < delta * 0.25:
		_pause = randf_range(0.6, float(_spec.pause))
		moving = false
	if moving:
		var speed := float(_spec.speed)
		if _spec.mode == "hop":
			_hop += delta * 1.6
			speed *= maxf(0.0, sin(_hop * PI))      # moves only while in the air
		position.x += _dir * speed * delta
		if position.x < x_min:
			position.x = x_min
			_dir = 1.0
		elif position.x > x_max:
			position.x = x_max
			_dir = -1.0
	var y := _ground_y(position.x)
	if _spec.mode == "fly":
		y = _ground_y(position.x) - lift - 80.0 - sin(_t * 1.3 + _phase) * 40.0
		position.x += cos(_t * 0.9 + _phase) * 0.0
	position.y = y
	var n := _frames.size()
	var fps := float(_spec.fps)
	var idx := int(_t * fps) % n
	if _spec.mode == "walk" and not moving:
		idx = 0
	var fr: Dictionary = _frames[idx]
	var tex: Texture2D = fr.tex
	if tex == null:
		return
	_sprite.texture = tex
	_sprite.scale = Vector2(_scale * _dir, _scale)
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() - fr.dy)
	if _spec.mode == "walk" and terrain != null and terrain.has_method("height_at"):
		# lean with the slope: nose down when the ground falls away ahead
		var h2: float = terrain.height_at(position.x + 24.0 * _dir)
		var h1: float = terrain.height_at(position.x)
		if h1 != INF and h2 != INF:
			rotation = lerp_angle(rotation, atan2(h2 - h1, 24.0) * _dir, 0.12)
