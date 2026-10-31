class_name WorldArt
extends RefCounted
## The generated, rendered environment pictures of each world (assets/art/<world>_<part>.png,
## made by tools/art): the far panorama, trees and bushes for the background, and the soil,
## turf and wood textures for the ground and planks. Returns null when a picture is missing,
## so the code-drawn look stays as the fallback.

const PATH := "res://assets/art/%s_%s.png"

static var _cache := {}


static func tex(world: String, part: String) -> Texture2D:
	var key := world + "_" + part
	if not _cache.has(key):
		var path := PATH % [world, part]
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]


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
