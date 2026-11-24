class_name TerrainCurve
extends Node2D
## Curved ground (docs/36 §4): rolling hills with slopes and dips instead of tiles. Built from the
## level's `terrain` data: segments of control points (px) that are smoothed with a Catmull-Rom
## curve. Each segment gets
##   - a solid body (CollisionPolygon2D, layer 1) the hero walks and runs on, slopes up to 35 degrees,
##   - a soil fill (tiled earth picture) down to the bottom of the level,
##   - a grass strip (the approved grass-lip art) that bends along the curve (Line2D, tiled texture).
## `era` picks the old (warm) or new (cool, smoky) look.

const ART := "res://assets/art/v3/cut/%s/%s_%s.png"
const STEP := 18.0               ## sample distance along the curve in px
const MAX_SLOPE_DEG := 38.0

var era := "old"
var bottom_y := 1024.0
var segments: Array = []         ## [[[x, y], ...], ...] control points in px, left to right
var _bodies: Array = []


## Catmull-Rom through the control points, sampled every STEP px.
static func smooth(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	if n < 2:
		return out
	for i in n - 1:
		var p0: Vector2 = _v(points[maxi(i - 1, 0)])
		var p1: Vector2 = _v(points[i])
		var p2: Vector2 = _v(points[i + 1])
		var p3: Vector2 = _v(points[mini(i + 2, n - 1)])
		var steps := maxi(2, int(p1.distance_to(p2) / STEP))
		for s in steps:
			var t := float(s) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(_v(points[n - 1]))
	return out


static func _v(p: Variant) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))


## Surface height at a world x (for placing things on the curve); INF where there is no ground.
func height_at(x: float) -> float:
	for seg in _surfaces:
		if x >= seg[0].x and x <= seg[seg.size() - 1].x:
			for i in seg.size() - 1:
				if x <= seg[i + 1].x:
					var a: Vector2 = seg[i]
					var b: Vector2 = seg[i + 1]
					var t := (x - a.x) / maxf(b.x - a.x, 0.001)
					return lerpf(a.y, b.y, t)
	return INF


var _surfaces: Array = []        ## smoothed point arrays


func _ready() -> void:
	z_index = 1
	var folder := "res://assets/art/v3/cut/v3_terrain_%s/" % era
	var soil: Texture2D = load(folder + "terrain_soil_seamless.png") if ResourceLoader.exists(folder + "terrain_soil_seamless.png") else null
	var lips: Array = []
	for r in ["r00", "r01", "r02"]:
		var path := folder + "terrain_lip_%s.png" % r
		lips.append(load(path) if ResourceLoader.exists(path) else null)
	var k := 0
	for seg in segments:
		var pts := smooth(seg)
		if pts.size() < 2:
			continue
		_surfaces.append(pts)
		_build_body(pts)
		_build_soil(pts, soil)
		_build_lip(pts, lips[k % lips.size()])
		k += 1


func _tex(sheet: String, cell: String) -> Texture2D:
	var path := ART % [sheet, sheet, cell]
	return load(path) if ResourceLoader.exists(path) else null


func _build_body(pts: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var poly := PackedVector2Array(pts)
	poly.append(Vector2(pts[pts.size() - 1].x, bottom_y))
	poly.append(Vector2(pts[0].x, bottom_y))
	var shape := CollisionPolygon2D.new()
	shape.polygon = poly
	body.add_child(shape)
	add_child(body)
	_bodies.append(body)


func _build_soil(pts: PackedVector2Array, soil: Texture2D) -> void:
	var fill := Polygon2D.new()
	var poly := PackedVector2Array(pts)
	poly.append(Vector2(pts[pts.size() - 1].x, bottom_y))
	poly.append(Vector2(pts[0].x, bottom_y))
	fill.polygon = poly
	fill.z_index = -1
	if soil:
		fill.texture = soil
		fill.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		fill.texture_scale = Vector2(0.55, 0.55)
		fill.uv = poly
	else:
		fill.color = Color("8d5a34")
	# the soil gets darker with depth, like the reference scenery
	fill.color = Color(1, 1, 1)
	add_child(fill)
	var shade := Polygon2D.new()
	var depth := PackedVector2Array([Vector2(pts[0].x, bottom_y - 260.0), Vector2(pts[pts.size() - 1].x, bottom_y - 260.0),
		Vector2(pts[pts.size() - 1].x, bottom_y), Vector2(pts[0].x, bottom_y)])
	shade.polygon = depth
	shade.vertex_colors = PackedColorArray([Color(0.1, 0.06, 0.14, 0.0), Color(0.1, 0.06, 0.14, 0.0), Color(0.1, 0.06, 0.14, 0.55), Color(0.1, 0.06, 0.14, 0.55)])
	shade.z_index = -1
	add_child(shade)


func _build_lip(pts: PackedVector2Array, lip: Texture2D) -> void:
	var line := Line2D.new()
	line.points = pts
	line.z_index = 2
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	if lip:
		line.texture = lip
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		# the strip picture is ~13:1; the line is wide enough that the grass blades stand above the ground
		line.width = 78.0
		line.default_color = Color.WHITE
	else:
		line.width = 14.0
		line.default_color = Color("6cc24a")
	# the strip is drawn centred on the curve: lift it so the soil edge of the picture sits just under the surface
	line.position = Vector2(0, 26.0)
	add_child(line)
