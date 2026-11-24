class_name SideRig
extends CharacterRig
## A character drawn in side view (profile), animated frame by frame from the cut sheets in
## assets/art/v3/cut (docs/36, docs/37; table: data/side_anims.json). Same states and API as the other
## rigs (state, speed, run_speed, expression) plus the hero extras: holding ("egg"...), aiming /
## aim_angle / draw_amount (bow), aim_pulse(), play_once(name). Origin = middle of the feet, facing
## right; the owner flips it with scale.x. The feet stay on the row's ground line, so a run cycle
## never bobs by accident, and the walk/run frame rate follows the real speed.

const SHEETS := "res://assets/art/v3/cut/%s/%s"

static var _table: Dictionary = {}
static var _atlas: Dictionary = {}
static var _tex: Dictionary = {}

@export var character := "arsam"

var holding := ""
var aiming := false
var aim_angle := 0.0
var draw_amount := 0.0
var squash := Vector2.ONE
var show_shadow := true
var play_speed := 1.0
var hang := ""                 ## "rope" | "vine": hanging on something
var lock_anim := ""            ## preview/cutscenes: force one animation

var _sprite: Sprite2D
var _anim := ""
var _frame_time := 0.0
var _scale := 1.0
var _once := ""
var _once_left := 0.0
var _loose_left := 0.0
var _last_state := ""
var _anim_def: Dictionary = {}
var _frames: Array = []
var _anim_k := 1.0


static func _load_table() -> void:
	if not _table.is_empty():
		return
	var file := FileAccess.open("res://data/side_anims.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_table = parsed


static func available(name: String) -> bool:
	_load_table()
	if not _table.has(name):
		return false
	var anims: Dictionary = _table[name].anims
	for a in anims.values():
		return FileAccess.file_exists(SHEETS % [a.sheet, a.sheet + ".atlas.json"])
	return false


static func make(name: String) -> SideRig:
	var rig := SideRig.new()
	rig.character = name
	return rig


static func _sheet_atlas(sheet: String) -> Dictionary:
	if not _atlas.has(sheet):
		var f := FileAccess.open(SHEETS % [sheet, sheet + ".atlas.json"], FileAccess.READ)
		_atlas[sheet] = JSON.parse_string(f.get_as_text()) if f else {}
	return _atlas[sheet]


static func _texture(sheet: String, file: String) -> Texture2D:
	var key := sheet + "/" + file
	if not _tex.has(key):
		var path := SHEETS % [sheet, file]
		_tex[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex[key]


## Frame data of one animation: [{tex, dx, dy}] in sheet pixels (dx = 0: centred on the picture, dy above the ground line).
static func build_frames(def: Dictionary) -> Array:
	var atlas := _sheet_atlas(String(def.sheet))
	if atlas.is_empty():
		return []
	var row: Dictionary = atlas.rows[int(def.row)]
	# every frame is centred on its own bounding box (the frames lie side by side on the sheet, so the
	# sheet position says nothing about where the body is)
	var out: Array = []
	for i in def.frames:
		if int(i) >= row.frames.size():
			continue
		var fr: Dictionary = row.frames[int(i)]
		out.append({"tex": _texture(String(def.sheet), String(fr.file)), "dx": 0.0,
			"dy": float(row.base) - float(fr.box[3]), "h": float(fr.box[3] - fr.box[1])})
	return out


func _ready() -> void:
	_load_table()
	var spec: Dictionary = _table.get(character, {})
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)
	# one scale for the whole character: the standing height (idle frames) becomes `height` game px
	var idle := spec.anims.get("idle", spec.anims.values()[0]) as Dictionary
	var hs: Array = []
	for fr in build_frames(idle):
		hs.append(fr.h)
	hs.sort()
	var stand: float = hs[hs.size() / 2] if not hs.is_empty() else 200.0
	_scale = float(spec.get("height", 120)) / maxf(stand, 1.0)
	_set_anim("idle")


func _process(delta: float) -> void:
	super._process(delta)
	_pick_animation()
	_advance(delta)
	_apply_frame()


func _draw() -> void:
	if show_shadow:
		draw_colored_polygon(ellipse_points(Vector2(0, -2), Vector2(26, 6)), Color(0, 0, 0, 0.2))


func blend_rate() -> float:
	return 16.0


## Plays one animation once (planting, placing the egg, the sling...) then returns to the state's own.
func play_once(name: String, seconds := -1.0) -> void:
	var spec: Dictionary = _table.get(character, {})
	if not spec.anims.has(name):
		return
	_once = name
	var def: Dictionary = spec.anims[name]
	_once_left = seconds if seconds > 0.0 else float(def.frames.size()) / maxf(float(def.fps), 0.1)


## A short bow shot after firing (the player calls it): the release frames play, then back to normal.
func aim_pulse(seconds := 0.3, _angle := 0.0) -> void:
	_loose_left = seconds


func _pick_animation() -> void:
	var spec: Dictionary = _table.get(character, {})
	var anims: Dictionary = spec.anims
	if lock_anim != "" and anims.has(lock_anim):
		if lock_anim != _anim:
			_set_anim(lock_anim)
		return
	var want := "idle"
	if hang != "" and anims.has(hang):
		if hang != _anim:
			_set_anim(hang)
		return
	var stride := clampf(absf(speed) / maxf(run_speed, 1.0), 0.0, 1.0)
	if _once != "" and _once_left > 0.0:
		want = _once
	elif state == "hurt" and anims.has("hurt"):
		want = "hurt"
	elif state == "celebrate":
		want = "celebrate" if anims.has("celebrate") else "idle"
	elif _loose_left > 0.0 and anims.has("bow_loose"):
		want = "bow_loose"
	elif aiming and anims.has("bow_draw"):
		want = "bow_draw"
	elif state == "glide":
		want = "glide" if anims.has("glide") else "fall"
	elif state == "dash" and anims.has("dash"):
		want = "dash"
	elif state == "jump":
		want = "jump"
	elif state == "fall":
		want = "fall"
	elif state == "skid" and anims.has("skid"):
		want = "skid"
	elif state == "crouch" or state == "crawl":
		want = "crouch" if anims.has("crouch") else "idle"
	elif state == "walk" or state == "run":
		if holding == "egg" and anims.has("carry"):
			want = "carry"
		else:
			want = "run" if (state == "run" or stride > 0.62) else "walk"
	elif holding == "egg" and anims.has("carry"):
		want = "carry"
	if not anims.has(want):
		want = "idle"
	if want != _anim:
		_set_anim(want)


func _set_anim(name: String) -> void:
	var spec: Dictionary = _table.get(character, {})
	_anim = name
	_anim_def = spec.anims.get(name, {})
	_anim_k = float(spec.get("sheet_scale", {}).get(String(_anim_def.get("sheet", "")), 1.0))
	_frames = build_frames(_anim_def)
	_frame_time = 0.0


func _advance(delta: float) -> void:
	if _once_left > 0.0:
		_once_left -= delta
		if _once_left <= 0.0:
			_once = ""
	if _loose_left > 0.0:
		_loose_left -= delta
	if _frames.is_empty():
		return
	var fps := float(_anim_def.get("fps", 8)) * play_speed
	if _anim == "run" or _anim == "walk" or _anim == "carry":
		fps *= clampf(0.55 + 0.75 * absf(speed) / maxf(run_speed, 1.0), 0.5, 1.5)
	_frame_time += delta * fps


func _apply_frame() -> void:
	if _frames.is_empty():
		return
	var n := _frames.size()
	var idx: int
	if _anim == "bow_draw":
		idx = clampi(int(draw_amount * n), 0, n - 1)           # the string follows the draw
	elif bool(_anim_def.get("loop", true)):
		idx = int(_frame_time) % n
	else:
		idx = mini(int(_frame_time), n - 1)
	var fr: Dictionary = _frames[idx]
	var tex: Texture2D = fr.tex
	if tex == null:
		return
	_sprite.texture = tex
	_sprite.scale = Vector2(_scale * _anim_k * squash.x, _scale * _anim_k * squash.y)
	# the picture's bottom edge sits `dy` above the ground line; x is relative to the row's median centre
	_sprite.offset = Vector2(-tex.get_width() * 0.5 + fr.dx, -tex.get_height() - fr.dy)

