class_name LevelBuilder
extends RefCounted
## Builds a level from its ASCII map (data/levels/<world>/level_XX.json). Every puzzle
## piece is a reusable node, so levels differ only by data. Legend: see README.md.

const TILE := 64
const PAST := 1
const PRESENT := 2
const BOTH := 3

## Tile runs: character -> [TimeBlock kind, times it exists in]
const RUNS := {
	"#": [TimeBlock.Kind.GROUND, BOTH],
	"r": [TimeBlock.Kind.ROCK, PAST],
	"o": [TimeBlock.Kind.PLANK, BOTH],
	"B": [TimeBlock.Kind.BRIDGE, PAST],
	"V": [TimeBlock.Kind.VINE, PRESENT],
}
## Water: character -> times it flows in
const WATERS := {"~": PRESENT, "w": PAST, "a": BOTH}


static func make_palette(hex: Dictionary) -> Dictionary:
	var out := {}
	for key in hex:
		out[key] = Color(String(hex[key]))
	return out


static func normalize(rows: Array) -> Array:
	var width := 0
	for row in rows:
		width = maxi(width, String(row).length())
	var grid: Array = []
	for row in rows:
		grid.append(String(row).rpad(width, "."))
	return grid


static func build(data: Dictionary, root: Node2D, game: Node, palette: Dictionary) -> Dictionary:
	var grid := normalize(data.get("map", []))
	var h := grid.size()
	var w := 0 if h == 0 else String(grid[0]).length()
	var info := {
		"size": Vector2(w * TILE, h * TILE), "start": Vector2(TILE * 2, TILE * 2), "exit": null,
		"hints": [], "stars": 0, "keys": 0, "needs_rescue": false,
	}
	_build_runs(grid, w, h, root, palette)
	_build_water(grid, w, h, root, game, palette)
	var signs: Array = data.get("signs", [])
	var move_range := int(data.get("move_range", 4))
	var sign_index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.get("id", 1)) * 7919
	for y in h:
		var row: String = grid[y]
		for x in w:
			var c := row[x]
			var pos := Vector2(x * TILE, y * TILE)
			match c:
				"P":
					info.start = pos + Vector2(TILE * 0.5, TILE - 42.0)
				"*":
					var star := Pickup.new()
					star.kind = Pickup.Kind.STAR
					star.index = info.stars
					star.game = game
					star.position = pos + Vector2(32, 32)
					root.add_child(star)
					info.stars += 1
				"K":
					var key := Pickup.new()
					key.kind = Pickup.Kind.KEY
					key.game = game
					key.position = pos + Vector2(32, 32)
					root.add_child(key)
					info.keys += 1
				"D":
					if y == 0 or String(grid[y - 1])[x] != "D":
						var door := Door.new()
						door.game = game
						var n := 0
						while y + n < h and String(grid[y + n])[x] == "D":
							n += 1
						door.cells = n
						door.position = pos
						root.add_child(door)
				"M":
					var spring := Spring.new()
					spring.position = pos
					root.add_child(spring)
				"m", "u":
					var platform := MovingPlatform.new()
					platform.axis = Vector2.RIGHT if c == "m" else Vector2.UP
					platform.distance = move_range * TILE
					platform.palette = palette
					platform.position = pos
					root.add_child(platform)
				"C":
					var checkpoint := Checkpoint.new()
					checkpoint.game = game
					checkpoint.position = pos
					root.add_child(checkpoint)
				"E":
					var portal := ExitPortal.new()
					portal.game = game
					portal.position = pos
					root.add_child(portal)
					info.exit = portal
				"R":
					var friend := RescueFriend.new()
					friend.game = game
					friend.position = pos
					root.add_child(friend)
					info.needs_rescue = true
				"i":
					var board := InfoSign.new()
					board.text = signs[sign_index] if sign_index < signs.size() else ""
					board.position = pos
					root.add_child(board)
					sign_index += 1
				"G":
					var dust := Ghubarak.new()
					dust.game = game
					dust.position = pos + Vector2(32, 32)
					root.add_child(dust)
				"f":
					_add_flower(root, pos, palette)
				"?":
					info.hints.append(pos + Vector2(32, 32))
				".":
					# Sprinkle a few flowers on open grass so long runs feel alive.
					if y + 1 < h and String(grid[y + 1])[x] == "#" and rng.randf() < 0.12:
						_add_flower(root, pos, palette)
	info.hints.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	return info


static func _add_flower(root: Node2D, pos: Vector2, palette: Dictionary) -> void:
	var flower := Flower.new()
	flower.palette = palette
	flower.position = pos
	root.add_child(flower)


static func _build_runs(grid: Array, w: int, h: int, root: Node2D, palette: Dictionary) -> void:
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			var c := row[x]
			if not RUNS.has(c):
				x += 1
				continue
			var start := x
			while x < w and row[x] == c:
				x += 1
			var block := TimeBlock.new()
			block.kind = RUNS[c][0]
			block.active_mask = RUNS[c][1]
			block.cells = x - start
			block.palette = palette
			block.position = Vector2(start * TILE, y * TILE)
			if c == "#":
				for i in range(start, x):
					block.caps.append(y == 0 or String(grid[y - 1])[i] != "#")
			root.add_child(block)


static func _build_water(grid: Array, w: int, h: int, root: Node2D, game: Node, palette: Dictionary) -> void:
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			var c := row[x]
			if not WATERS.has(c):
				x += 1
				continue
			var start := x
			while x < w and row[x] == c:
				x += 1
			var water := Water.new()
			water.cells = x - start
			water.active_mask = WATERS[c]
			water.surface = y == 0 or String(grid[y - 1])[start] != c
			water.game = game
			water.palette = palette
			water.position = Vector2(start * TILE, y * TILE)
			root.add_child(water)
