class_name SpriteFX
extends Sprite2D
## A one-shot effect played from cut art frames (data/fx_pair1.json): hit flash, release puff, deed
## ring, arrow hit... Every effect costs "units" from the shared 200-particle budget (FX.take), so
## busy scenes never exceed it; on low quality the glow-only effects are skipped.

const ROOT := "res://assets/art/pair1/"
static var _data: Dictionary = {}
static var _textures: Dictionary = {}

var _frames: Array = []
var _fps := 12.0
var _t := 0.0
var _units := 0


static func _load_data() -> void:
	if not _data.is_empty():
		return
	var file := FileAccess.open("res://data/fx_pair1.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_data = parsed


static func available(name: String) -> bool:
	_load_data()
	return _data.has(name)


static func _frame(sheet: String, cell: String, root := "") -> Texture2D:
	var path := "%s%s/%s_%s.png" % [ROOT, sheet, sheet.get_file(), cell]
	if root == "v3":                       # assets/art/v3/cut/<sheet>/<sheet>_<cell>.png
		path = "res://assets/art/v3/cut/%s/%s_%s.png" % [sheet, sheet, cell]
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## Plays `name` at `pos` (world coordinates inside `parent`). Returns null if skipped (budget/quality).
static func play(parent: Node, name: String, pos: Vector2, scale_mul := 1.0, flip := false) -> SpriteFX:
	_load_data()
	if not _data.has(name) or parent == null:
		return null
	var spec: Dictionary = _data[name]
	var units: int = FX.take(int(spec.get("units", 6)))
	if units <= 0:
		return null
	var fx := SpriteFX.new()
	fx._units = units
	for cell in spec.frames:
		var name_cell := str(cell)
		if spec.has("row"):                # v3 sheets: frames are indices into a row
			name_cell = "r%02d_f%02d" % [int(spec.row), int(cell)]
		var tex := _frame(String(spec.sheet), name_cell, String(spec.get("root", "")))
		if tex:
			fx._frames.append(tex)
	if fx._frames.is_empty():
		FX.give(units)
		return null
	fx._fps = float(spec.get("fps", 12))
	var k := float(spec.get("scale", 1.0)) * scale_mul
	fx.scale = Vector2(-k if flip else k, k)
	fx.position = pos
	fx.z_index = 8
	fx.texture = fx._frames[0]
	if bool(spec.get("additive", false)):
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = mat
	parent.add_child(fx)
	return fx


func _process(delta: float) -> void:
	_t += delta
	var i := int(_t * _fps)
	if i >= _frames.size():
		FX.give(_units)
		queue_free()
		return
	texture = _frames[i]
	modulate.a = 1.0 if i < _frames.size() - 1 else clampf(1.0 - (_t * _fps - i), 0.0, 1.0)
