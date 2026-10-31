class_name WorldArt
extends RefCounted
## The generated, rendered environment pictures of each world (assets/art/<world>_<part>.png,
## made by tools/art): the far panorama, trees and bushes for the background, and the soil,
## turf and wood textures for the ground and planks. Returns null when a picture is missing,
## so the code-drawn look stays as the fallback.

const PATH := "res://assets/art/%s_%s.png"

static var _cache := {}


static func tex(world: String, part: String) -> Texture2D:
	var key := world + "_" + part if part != "" else world
	if not _cache.has(key):
		var path := "res://assets/art/%s.png" % key
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


## A rendered picture (assets/art/<name>.png) or null.
static func pic(name: String) -> Texture2D:
	return tex(name.get_slice("_", 0), name.substr(name.find("_") + 1)) if name.contains("_") else tex(name, "")


## Draws a rendered picture standing on `feet` (its bottom centre), `height` tall. Returns
## false when the picture does not exist (the caller then draws its own look).
static func draw(canvas: CanvasItem, name: String, feet: Vector2, height: float, tint := Color.WHITE) -> bool:
	var texture := pic(name)
	if texture == null:
		return false
	var w := texture.get_width() * height / texture.get_height()
	canvas.draw_texture_rect(texture, Rect2(feet - Vector2(w * 0.5, height), Vector2(w, height)), false, tint)
	return true


## Tall background props (trees, towers, chimneys...).
static func trees(world: String) -> Array:
	var names := ["tree_1", "tree_2", "tree_3"]
	if world == "forest":
		names += ["mushroom_1", "mushroom_2", "mushroom_3"]
	return _found(world, names)


## Low background props (bushes, rocks, crates...).
static func bushes(world: String) -> Array:
	var names := ["bush_1", "bush_2", "bush_3"]
	if world == "forest":
		names.append("rocks")
	return _found(world, names)


static func _found(world: String, names: Array) -> Array:
	var out := []
	for part in names:
		var texture := tex(world, part)
		if texture:
			out.append(texture)
	return out
