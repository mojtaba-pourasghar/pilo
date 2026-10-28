class_name Mechanisms
extends Node2D
## Switches, gates and the light puzzle of one level.
##
## Gates open — and stay open, so a child can never be shut in — once every switch in the level
## is on and every light sensor is lit. The light beam is traced on the tile grid: mirrors turn
## it, solid tiles stop it (a rock only in the time it exists, so the lens can bend the light's
## path), crystals let it through and turn into platforms while lit.

const TILE := 64.0
const DIRS := {"right": Vector2i(1, 0), "left": Vector2i(-1, 0), "up": Vector2i(0, -1), "down": Vector2i(0, 1)}

var grid: Array = []
var game: Node
var palette: Dictionary = {}
var levers: Array = []
var gates: Array = []
var sources: Array = []          # [{cell: Vector2i, dir: Vector2i}]
var mirrors: Dictionary = {}     # Vector2i -> Mirror
var sensors: Dictionary = {}     # Vector2i -> LightSensor
var crystals: Dictionary = {}    # Vector2i -> CrystalPlatform
var opened := false

var _beams: Array = []
var _t := 0.0


func _ready() -> void:
	z_index = 2
	TimeShift.time_changed.connect(_on_time_changed)
	refresh.call_deferred()


func has_anything() -> bool:
	return not (levers.is_empty() and gates.is_empty() and sources.is_empty())


func _on_time_changed(_state: int, _instant: bool) -> void:
	refresh()


## Re-traces the light and checks whether the gates may open. Called after anything changes.
func refresh() -> void:
	_trace()
	if not opened and not gates.is_empty() and _all_on():
		opened = true
		for gate in gates:
			gate.open()
		AudioManager.play_sfx("door")
		AudioManager.play_sfx("rescue", 1.2, -6.0)
		_trace()  # an open gate no longer stops the beam
	queue_redraw()


func _all_on() -> bool:
	if levers.is_empty() and sensors.is_empty():
		return false
	for lever in levers:
		if not lever.on:
			return false
	for cell in sensors:
		if not sensors[cell].lit:
			return false
	return true


func _blocked(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= grid.size():
		return true
	var row: String = grid[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return true
	match row[cell.x]:
		"#", "D", "M":
			return true
		"r":
			return TimeShift.state == TimeShift.PAST
		"g":
			return not opened
	return false


func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func _trace() -> void:
	_beams.clear()
	var lit := {}
	for source in sources:
		var cell: Vector2i = source.cell
		var dir: Vector2i = source.dir
		var points := PackedVector2Array([_center(cell)])
		for step in 240:
			cell += dir
			if mirrors.has(cell):
				points.append(_center(cell))
				dir = mirrors[cell].reflect(dir)
				continue
			if sensors.has(cell):
				lit[cell] = true
				points.append(_center(cell))
				break
			if crystals.has(cell):
				lit[cell] = true
				continue
			if _blocked(cell):
				points.append(_center(cell) - Vector2(dir) * TILE * 0.5)
				break
		_beams.append(points)
	for cell in sensors:
		sensors[cell].set_lit(lit.has(cell))
	for cell in crystals:
		crystals[cell].set_lit(lit.has(cell))


func _process(delta: float) -> void:
	if sources.is_empty():
		set_process(false)
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var flicker := 0.85 + sin(_t * 9.0) * 0.08
	for points in _beams:
		if points.size() < 2:
			continue
		draw_polyline(points, Color(1.0, 0.92, 0.55, 0.22 * flicker), 26.0)
		draw_polyline(points, Color(1.0, 0.95, 0.7, 0.55 * flicker), 12.0)
		draw_polyline(points, Color(1, 1, 0.92, 0.95), 4.0)
	for source in sources:
		var center := _center(source.cell)
		draw_circle(center, 26.0, Color(0.35, 0.25, 0.5))
		draw_circle(center, 20.0, Color(1.0, 0.9, 0.5))
		draw_circle(center, 12.0 + sin(_t * 6.0) * 2.0, Color(1, 1, 0.9))
		var tip := center + Vector2(source.dir) * 30.0
		draw_line(center, tip, Color(1, 1, 0.9), 6.0)
