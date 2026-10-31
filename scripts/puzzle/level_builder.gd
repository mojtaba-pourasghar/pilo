class_name LevelBuilder
extends RefCounted
## Builds a level from its ASCII map (data/levels/<world>/level_XX.json). Every piece is a
## reusable node, so levels differ only by data. Legend: see README.md.
## Platformer pieces: Q ?-block (coin)  U ?-block (several coins)  J ?-block (diamond)
## H ?-block (heart)  b brick  $ brick with coins  n hidden block (diamond)  c coin
## d diamond  + heart  k time key (opens the exit gate)  e shadow mushroom  y shadow bee
## h shadow hedgehog  F thorn wheel  T stone crusher  t falling raft  A thorns
## N shadow cannon  p pipe (top-left; warps in data "warps")  W cracked wall
## Y fox den with a diamond  X fox den with the time key (only Pilo gets them)

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
	"I": [TimeBlock.Kind.ICE, BOTH],
	"=": [TimeBlock.Kind.BELT, BOTH],
	"_": [TimeBlock.Kind.BELT, BOTH],
}
## Water: character -> times it flows in
const WATERS := {"~": PRESENT, "w": PAST, "a": BOTH}
## Blocks: character -> [kind, content]
const BLOCKS := {
	"Q": [Block.Kind.QUESTION, "coin"], "U": [Block.Kind.QUESTION, "coins"],
	"J": [Block.Kind.QUESTION, "diamond"], "H": [Block.Kind.QUESTION, "heart"],
	"b": [Block.Kind.BRICK, ""], "$": [Block.Kind.BRICK, "coins"], "n": [Block.Kind.HIDDEN, "diamond"],
}
const ENEMIES := {"e": "shroom", "y": "bee", "h": "hog"}
## Wind: character -> direction. Rows of ">"/"<" and columns of "^" become one zone each.
const WINDS := {">": Vector2.RIGHT, "<": Vector2.LEFT, "^": Vector2.UP}
const TIME_MASKS := {"past": PAST, "present": PRESENT, "both": BOTH}


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
		"hints": [], "stars": 0, "keys": 0, "needs_rescue": false, "chaser": null, "mechanisms": null,
		"diamonds": 0, "time_key": false, "enemies": 0, "pipes": {}, "boss": null,
	}
	_build_runs(grid, w, h, root, palette)
	_build_water(grid, w, h, root, game, palette)
	_build_wind(grid, w, h, root, int(TIME_MASKS.get(String(data.get("wind_time", "both")), BOTH)))
	_build_crumble(grid, w, h, root, palette)
	_build_thorns(grid, w, h, root)
	_build_world_pieces(grid, w, h, root, palette)
	var mechanisms := Mechanisms.new()
	mechanisms.grid = grid
	mechanisms.game = game
	mechanisms.palette = palette
	var source_dirs: Array = data.get("source_dirs", [])
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
				"L":
					var lever := WorldParts.Lever.new()
					lever.mechanisms = mechanisms
					lever.palette = palette
					lever.position = pos
					root.add_child(lever)
					mechanisms.levers.append(lever)
				"g":
					if y == 0 or String(grid[y - 1])[x] != "g":
						var gate := WorldParts.Gate.new()
						var n := 0
						while y + n < h and String(grid[y + n])[x] == "g":
							n += 1
						gate.cells = n
						gate.palette = palette
						gate.position = pos
						root.add_child(gate)
						mechanisms.gates.append(gate)
				"S":
					var index := mechanisms.sources.size()
					var dir_name := String(source_dirs[index]) if index < source_dirs.size() else "right"
					mechanisms.sources.append({"cell": Vector2i(x, y), "dir": Mechanisms.DIRS.get(dir_name, Vector2i(1, 0))})
				"/", "\\":
					var mirror := LightParts.Mirror.new()
					mirror.slash = c == "/"
					mirror.mechanisms = mechanisms
					mirror.position = pos
					root.add_child(mirror)
					mechanisms.mirrors[Vector2i(x, y)] = mirror
				"O":
					var sensor := LightParts.LightSensor.new()
					sensor.position = pos
					root.add_child(sensor)
					mechanisms.sensors[Vector2i(x, y)] = sensor
				"x":
					var crystal := LightParts.CrystalPlatform.new()
					crystal.palette = palette
					crystal.position = pos
					root.add_child(crystal)
					mechanisms.crystals[Vector2i(x, y)] = crystal
				"R":
					var friend := RescueFriend.new()
					friend.skin = String(data.get("friend", "squirrel"))
					friend.game = game
					friend.position = pos
					root.add_child(friend)
					info.needs_rescue = true
				"i":
					var board := InfoSign.new()
					board.text = signs[sign_index] if sign_index < signs.size() else ""
					board.voice_id = "l%02d_sign_%d" % [int(data.get("id", 0)), sign_index + 1]
					board.position = pos
					root.add_child(board)
					sign_index += 1
				"G":
					var dust := Ghubarak.new()
					dust.game = game
					dust.position = pos + Vector2(32, 32)
					if bool(data.get("chase", false)):
						# Chase: he stays ahead of the hero and waits by the exit to be caught.
						dust.chase = true
						info.needs_rescue = true
						info.chaser = dust
					root.add_child(dust)
				"Q", "U", "J", "H", "b", "$", "n":
					var block := Block.new()
					block.kind = BLOCKS[c][0]
					block.content = BLOCKS[c][1]
					block.game = game
					if block.content == "diamond":
						block.diamond_index = info.diamonds
						info.diamonds += 1
					block.position = pos
					root.add_child(block)
				"c", "d", "+", "k":
					var item := Collectible.new()
					item.kind = {"c": Collectible.Kind.COIN, "d": Collectible.Kind.DIAMOND, "+": Collectible.Kind.HEART, "k": Collectible.Kind.TIME_KEY}[c]
					item.game = game
					item.position = pos + Vector2(32, 32)
					if c == "d":
						item.index = info.diamonds
						info.diamonds += 1
					elif c == "k":
						info.time_key = true
					root.add_child(item)
				"e", "y", "h":
					var enemy: Enemy
					match ENEMIES[c]:
						"shroom":
							enemy = Shroom.new()
						"bee":
							enemy = ShadowBee.new()
							enemy.span = float(data.get("bee_span", 150))
						_:
							enemy = SpikyHog.new()
					var world_id := String(data.get("world", "forest"))
					enemy.skin = {"e": SkinBook.walker(world_id), "y": SkinBook.flyer(world_id), "h": SkinBook.spiky(world_id)}[c]
					enemy.game = game
					enemy.position = pos + Vector2(32, TILE if c != "y" else 40.0)
					root.add_child(enemy)
					info.enemies += 1
				"F":
					var wheel := ThornWheel.new()
					wheel.length = int(data.get("wheel_length", 4))
					wheel.position = pos + Vector2(32, 32)
					root.add_child(wheel)
				"T":
					var crusher := Crusher.new()
					crusher.position = pos + Vector2(-16, 0)
					root.add_child(crusher)
				"t":
					var raft := FallingPlatform.new()
					raft.palette = palette
					raft.position = pos
					root.add_child(raft)
				"N":
					var cannon := ShadowCannon.new()
					cannon.game = game
					cannon.position = pos
					root.add_child(cannon)
				"W":
					if y == 0 or String(grid[y - 1])[x] != "W":
						var wall := CrackedWall.new()
						var n := 0
						while y + n < h and String(grid[y + n])[x] == "W":
							n += 1
						wall.cells = n
						wall.palette = palette
						wall.position = pos
						root.add_child(wall)
				"Z":
					var cloud := WorldHazards.StormCloud.new()
					cloud.offset = fposmod(x * 0.37, 3.0)
					cloud.position = pos
					root.add_child(cloud)
				"&":
					var boss := Boss.new()
					boss.kind = String(data.get("boss", "forest"))
					boss.game = game
					boss.position = pos + Vector2(32, TILE)
					root.add_child(boss)
					info.boss = boss
				"|":
					if y == 0 or String(grid[y - 1])[x] != "|":
						var door := WorldHazards.BossDoor.new()
						var n := 0
						while y + n < h and String(grid[y + n])[x] == "|":
							n += 1
						door.cells = n
						door.position = pos
						root.add_child(door)
				"Y", "X":
					var den := FoxDen.new()
					den.content = "key" if c == "X" else "diamond"
					den.game = game
					if c == "X":
						info.time_key = true
					else:
						den.diamond_index = info.diamonds
						info.diamonds += 1
					den.position = pos
					root.add_child(den)
				"p":
					var pipe := Pipe.new()
					pipe.theme = String(palette.get("theme", "forest"))
					var n := 1
					while y + n < h and not RUNS.has(String(grid[y + n])[x]):
						n += 1
					pipe.cells = n
					pipe.position = pos
					root.add_child(pipe)
					info.pipes[Vector2i(x, y)] = pipe
				"f":
					_add_flower(root, pos, palette)
				"?":
					info.hints.append(pos + Vector2(32, 32))
				".":
					# Sprinkle a few flowers on open grass so long runs feel alive.
					if y + 1 < h and String(grid[y + 1])[x] == "#" and rng.randf() < 0.12:
						_add_flower(root, pos, palette)
	info.hints.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	for warp in data.get("warps", []):
		var from := Vector2i(int(warp.from[0]), int(warp.from[1]))
		if info.pipes.has(from):
			var pipe: Pipe = info.pipes[from]
			pipe.is_warp = true
			pipe.warp_to = Vector2(int(warp.to[0]) * TILE, int(warp.to[1]) * TILE)
	if info.chaser and info.exit:
		info.chaser.stop_x = info.exit.position.x - 96.0
	root.add_child(mechanisms)
	info.mechanisms = mechanisms
	_build_secret_rooms(grid, w, h, root, palette)
	_build_pit_shade(grid, w, h, root)
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
			if c == "=" or c == "_":
				block.belt = 1.0 if c == "=" else -1.0
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


static func _build_wind(grid: Array, w: int, h: int, root: Node2D, mask: int) -> void:
	# sideways wind: one zone per run in a row
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			var c := row[x]
			if c != ">" and c != "<":
				x += 1
				continue
			var start := x
			while x < w and row[x] == c:
				x += 1
			_add_wind(root, WINDS[c], Vector2(start * TILE, y * TILE), Vector2((x - start) * TILE, TILE), mask)
	# updrafts: one zone per run in a column
	for x in w:
		var y := 0
		while y < h:
			if String(grid[y])[x] != "^":
				y += 1
				continue
			var start := y
			while y < h and String(grid[y])[x] == "^":
				y += 1
			_add_wind(root, Vector2.UP, Vector2(x * TILE, start * TILE), Vector2(TILE, (y - start) * TILE), mask)


static func _add_wind(root: Node2D, dir: Vector2, pos: Vector2, size: Vector2, mask: int) -> void:
	var zone := WorldParts.WindZone.new()
	zone.dir = dir
	zone.size = size
	zone.active_mask = mask
	zone.position = pos
	root.add_child(zone)


static func _build_crumble(grid: Array, w: int, h: int, root: Node2D, palette: Dictionary) -> void:
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			if row[x] != "z":
				x += 1
				continue
			var start := x
			while x < w and row[x] == "z":
				x += 1
			var shelf := WorldParts.CrumblePlatform.new()
			shelf.cells = x - start
			shelf.palette = palette
			shelf.position = Vector2(start * TILE, y * TILE)
			root.add_child(shelf)


static func _build_thorns(grid: Array, w: int, h: int, root: Node2D) -> void:
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			if row[x] != "A":
				x += 1
				continue
			var start := x
			while x < w and row[x] == "A":
				x += 1
			var thorns := Thorns.new()
			thorns.cells = x - start
			thorns.position = Vector2(start * TILE, y * TILE)
			root.add_child(thorns)


## Open cells under the ground (some "#" above them in the same column) become secret rooms:
## covered with earth until Nima gets inside. One room per connected group of cells.
static func _build_secret_rooms(grid: Array, w: int, h: int, root: Node2D, palette: Dictionary) -> void:
	var covered := {}
	for x in w:
		var roof := false
		for y in h:
			var c := String(grid[y])[x]
			if c == "#":
				roof = true
			elif roof and not RUNS.has(c) and c != "W":
				covered[Vector2i(x, y)] = true
	var seen := {}
	for start in covered:
		if seen.has(start):
			continue
		var cells: Array = []
		var stack: Array = [start]
		seen[start] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			cells.append(cell)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var next: Vector2i = cell + d
				if covered.has(next) and not seen.has(next):
					seen[next] = true
					stack.append(next)
		var room := SecretRoom.new()
		room.cells = cells
		room.palette = palette
		root.add_child(room)


## Bottomless pits fade to dark so a child can see there is no ground down there.
static func _build_pit_shade(grid: Array, w: int, h: int, root: Node2D) -> void:
	var shade := PitShade.new()
	var x := 0
	while x < w:
		var c := String(grid[h - 1])[x]
		if RUNS.has(c) or WATERS.has(c):
			x += 1
			continue
		var top := h - 1
		while top > 0 and not RUNS.has(String(grid[top - 1])[x]) and not WATERS.has(String(grid[top - 1])[x]):
			top -= 1
		# only real pits: the gap must cut through the ground next to it
		var left_ground := x > 0 and RUNS.has(String(grid[h - 1])[x - 1])
		var right_ground := x + 1 < w and RUNS.has(String(grid[h - 1])[x + 1])
		var near := left_ground or right_ground or shade.columns.has(x - 1)
		if near:
			var surface := h - 1
			for nx in [x - 1, x + 1]:
				if nx >= 0 and nx < w:
					for y in h:
						if String(grid[y])[nx] == "#":
							surface = mini(surface, y)
							break
			shade.columns[x] = surface
		x += 1
	shade.level_height = h * TILE
	root.add_child(shade)


class PitShade extends Node2D:
	var columns := {}          ## column -> row where the ground surface is beside it
	var level_height := 0.0

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for x in columns:
			var top: float = (float(columns[x]) + 0.3) * TILE
			var deep := top + TILE * 2.5
			var bottom := level_height + 240.0
			var clear := Color(0.06, 0.08, 0.16, 0.0)
			var dark := Color(0.06, 0.08, 0.16, 0.9)
			var x0: float = x * TILE
			var x1: float = (x + 1) * TILE
			draw_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, deep), Vector2(x0, deep)]),
				PackedColorArray([clear, clear, dark, dark]))
			draw_rect(Rect2(x0, deep, TILE, bottom - deep), dark)


## Deep water (s), quicksand (q) and vanishing platforms (v): one piece per run in a row.
static func _build_world_pieces(grid: Array, w: int, h: int, root: Node2D, palette: Dictionary) -> void:
	for y in h:
		var row: String = grid[y]
		var x := 0
		while x < w:
			var c := row[x]
			if c != "s" and c != "q" and c != "v":
				x += 1
				continue
			var start := x
			while x < w and row[x] == c:
				x += 1
			var pos := Vector2(start * TILE, y * TILE)
			match c:
				"s":
					var water := WorldHazards.SwimWater.new()
					water.size = Vector2((x - start) * TILE, TILE)
					water.surface = y == 0 or String(grid[y - 1])[start] != "s"
					water.palette = palette
					water.position = pos
					root.add_child(water)
				"q":
					var sand := WorldHazards.Quicksand.new()
					sand.cells = x - start
					sand.palette = palette
					sand.position = pos
					root.add_child(sand)
				"v":
					var stone := WorldHazards.VanishPlatform.new()
					stone.cells = x - start
					stone.offset = fposmod(start * 0.9, WorldHazards.VanishPlatform.CYCLE)
					stone.position = pos
					root.add_child(stone)
