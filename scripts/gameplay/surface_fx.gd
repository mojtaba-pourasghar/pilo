class_name SurfaceFX
extends RefCounted
## Material feedback of actions (docs/40 §8.1): every step, landing, slide and hit makes the effect of the
## surface under it (dust, sand cloud, snow powder, water splash, leaves, stone chips) and, for hits,
## a short flash of light. Effects come from the cut art (data/fx_pair1.json) and cost particle budget.

## surface -> [landing sequence, step sequence, slide sequence, hit sequence]
const TABLE := {
	"grass": ["dust_soil", "foot_soil", "leaf_scatter", "leaf_scatter"],
	"soil": ["dust_soil", "foot_soil", "dust_soil", "dust_soil"],
	"sand": ["dust_sand", "foot_sand", "dust_sand", "dust_sand"],
	"snow": ["snow_powder", "foot_snow", "ice_trail", "snow_powder"],
	"stone": ["stone_chips", "foot_soil", "stone_chips", "stone_chips"],
	"wood": ["stone_chips", "foot_soil", "stone_chips", "stone_chips"],
	"water": ["splash_big", "water_ripple", "water_ripple", "splash_big"],
}


static func _name(surface: String, kind: int) -> String:
	return String(TABLE.get(surface, TABLE.grass)[kind])


static func land(parent: Node, pos: Vector2, surface: String, strength := 1.0) -> void:
	SpriteFX.play(parent, _name(surface, 0), pos + Vector2(0, -6), strength)
	if surface == "snow" or surface == "water":
		return
	if strength > 0.9:
		SpriteFX.play(parent, "shock_ring", pos + Vector2(0, -4), 0.8)


static func step(parent: Node, pos: Vector2, surface: String, facing: float) -> void:
	SpriteFX.play(parent, _name(surface, 1), pos + Vector2(-facing * 14.0, -4), 1.0, facing < 0.0)


static func slide(parent: Node, pos: Vector2, surface: String, facing: float) -> void:
	SpriteFX.play(parent, _name(surface, 2), pos + Vector2(-facing * 18.0, -4), 0.9, facing < 0.0)


## A hit on something of `surface`: the material's burst plus a quick flash of light.
static func hit(parent: Node, pos: Vector2, surface: String) -> void:
	SpriteFX.play(parent, _name(surface, 3), pos, 0.9)
	SpriteFX.play(parent, "hit_flash", pos, 0.6)
