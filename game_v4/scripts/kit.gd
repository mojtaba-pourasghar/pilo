class_name Kit
extends RefCounted
## The painted pieces (art/cut/<sheet>/pNN.png, cut by tools/cut_v4.py). Each scene/prop asks for its piece here and
## falls back to its own placeholder drawing when the art is not there yet.
##   forest_old_kit: 0,1 rock masses · 2 rock · 3 step · 4 slope · 5 left edge · 6 floating island · 7 right edge · 8 trunk
##     9 branch · 10 curved branch · 11 vine · 12 swing · 14 bounce mushroom · 15 lily leaf · 16 wind vent · 17 arch
##     18 bush · 19 grass · 20 flowers · 21-24 moss strands · 25 small mushrooms · 26 vase
##   items_forest: 0-2 dew (wings) · 3-5 small dew · 6-9 big dew · 10-15 clock spirit · 16 cage · 17 cracking · 18 broken
##     19 lantern (checkpoint) · 20 heart · 21 leaf token
##   enemies_forest_parts: 4 smoke walker · 11 stilt walker · 14 flyer · 22-24 the freed critters

static var _cache := {}
static var era := "forest_old"


static func tex(sheet: String, idx: int) -> Texture2D:
	var key := "%s/%d" % [sheet, idx]
	if not _cache.has(key):
		var path := "res://art/cut/%s/p%02d.png" % [sheet, idx]
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


static func env(idx: int) -> Texture2D:
	return tex(era + "_kit", idx)


static func item(idx: int) -> Texture2D:
	return tex("items_forest", idx)


static func ground(part: String) -> Texture2D:
	var path := "res://art/ground/%s_%s.png" % [era, part]
	return load(path) if ResourceLoader.exists(path) else null


## Draws a texture on `ci` with its bottom-centre at `at`, `h` px tall (keeps the aspect), rotated, flipped.
static func draw_at(ci: CanvasItem, t: Texture2D, at: Vector2, h: float, rot := 0.0, flip := false, mod := Color.WHITE) -> void:
	if t == null:
		return
	var s := h / float(t.get_height())
	ci.draw_set_transform(at, rot, Vector2(-s if flip else s, s))
	ci.draw_texture(t, Vector2(-t.get_width() * 0.5, -t.get_height()), mod)
	ci.draw_set_transform(Vector2.ZERO)


## Draws a texture stretched from a to b (its length along the line, `thick` px across), centred on the line.
static func draw_along(ci: CanvasItem, t: Texture2D, a: Vector2, b: Vector2, thick: float) -> void:
	if t == null:
		return
	var d := b - a
	var sx := d.length() / float(t.get_width())
	var sy := thick / float(t.get_height())
	ci.draw_set_transform(a, d.angle(), Vector2(sx, sy))
	ci.draw_texture(t, Vector2(0, -t.get_height() * 0.5))
	ci.draw_set_transform(Vector2.ZERO)
