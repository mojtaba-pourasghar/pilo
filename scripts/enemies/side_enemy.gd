class_name SideEnemy
extends Enemy
## A shadow creature drawn from the painted frame sheets (docs/44, assets/art/v3/cut/v3f_e_*).
## Kinds and behaviours come from data/enemy_anims.json. Rows: move, alert, attack, hit, defeat, freed.
## Behaviours: walk (turns at walls/ledges), fly (gentle wave), hover (bobs on the spot), plant (stays and sways).

const TABLE := "res://data/enemy_anims.json"
static var _table: Dictionary = {}

var kind := "imp"
var span := 150.0
var _def: Dictionary = {}
var _origin := Vector2.ZERO
var _t := 0.0


static func spec(k: String) -> Dictionary:
	if _table.is_empty():
		var f := FileAccess.open(TABLE, FileAccess.READ)
		_table = JSON.parse_string(f.get_as_text()) if f else {}
	return _table.get(k, {})


func _init() -> void:
	body_size = Vector2(50, 50)


func _ready() -> void:
	_def = spec(kind)
	var h := float(_def.get("height", 70))
	body_size = Vector2(float(_def.get("w", h * 0.7)), h * float(_def.get("hit_h", 0.85)))
	speed = float(_def.get("speed", 60))
	stompable = bool(_def.get("stompable", true))
	super()
	_origin = position
	_t = randf() * TAU


func make_rig() -> EnemyRig:
	var r := FrameRig.new()
	r.sheet = String(_def.get("sheet", ""))
	r.stand = float(_def.get("height", 70))
	r.rows = _def.get("rows", {})
	r.fps = float(_def.get("fps", 8))
	return r


func art_name() -> String:
	return "side_" + kind        # no PaintedCreature of that name: our own rig is used


func move(delta: float) -> void:
	_t += delta
	match String(_def.get("behavior", "walk")):
		"fly":
			var s := _t * speed / 60.0
			position = _origin + Vector2(sin(s) * span, sin(s * 2.6) * 14.0)
			facing = signf(cos(s)) if cos(s) != 0.0 else facing
		"hover":
			position = _origin + Vector2(sin(_t * 1.3) * 12.0, sin(_t * 2.1) * 10.0)
		"plant":
			pass
		_:
			walk(delta)
	(rig as FrameRig).mode = "move"


func defeat(how := "stomp") -> void:
	if freed:
		return
	(rig as FrameRig).mode = "freed"
	super(how)


class FrameRig extends EnemyRig:
	var sheet := ""
	var stand := 70.0
	var rows: Dictionary = {}
	var fps := 8.0
	var mode := "move"
	var _sprite: Sprite2D
	var _cache: Dictionary = {}
	var _scale := 1.0
	var _clock := 0.0
	var _last := ""

	func _ready() -> void:
		_sprite = Sprite2D.new()
		_sprite.centered = false
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(_sprite)
		var frames := _frames("move")
		var hs: Array = []
		for fr in frames:
			hs.append(fr.h)
		hs.sort()
		var med: float = hs[hs.size() / 2] if not hs.is_empty() else 100.0
		_scale = stand / maxf(med, 1.0)

	func _frames(st: String) -> Array:
		if not _cache.has(st):
			var row := int(rows.get(st, rows.get("move", 0)))
			var n := int(SideRig._sheet_atlas(sheet).get("rows", [{"frames": []}])[row].frames.size()) if not SideRig._sheet_atlas(sheet).is_empty() else 0
			_cache[st] = SideRig.build_frames({"sheet": sheet, "row": row, "frames": range(n)})
		return _cache[st]

	func _process(delta: float) -> void:
		super(delta)
		if mode != _last:
			_last = mode
			_clock = 0.0
		_clock += delta * fps
		var frames := _frames(mode)
		if frames.is_empty():
			return
		var n := frames.size()
		var idx := int(_clock) % n if mode == "move" or mode == "alert" else mini(int(_clock), n - 1)
		var fr: Dictionary = frames[idx]
		var tex: Texture2D = fr.tex
		if tex == null:
			return
		_sprite.texture = tex
		_sprite.scale = Vector2(_scale, _scale)
		_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() - float(fr.dy))
