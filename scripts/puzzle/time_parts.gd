class_name TimeParts
extends RefCounted
## Format-4 pieces listed in a level's JSON (docs/03_levels §2: no new map letters).
##   time_tiles    [{"x","y","w","h","kind":"rock|bridge|vine","time":"past|present"}] - e.g. rubble
##                 that only blocks the way in the present, or a gate open only in the past
##   signs_timed   [{"cell":[x,y], "text_key", "time":"past|present"}] - a sign in one time
##   seeds         [{"cell":[x,y], "tree":[x,y,w]}] - plant in the past, a tree to stand on grows in
##                 the present (the butterfly effect: TimeShift.history)
##   memory_marks  [{"cell":[x,y], "time"}] - the three hidden carvings that open the memory room
##   clocks        [[x,y], ...] - little clocks: lens charge

const TILE := 64


static func build(data: Dictionary, root: Node2D, game: Node, palette: Dictionary) -> void:
	for t in data.get("time_tiles", []):
		var mask := 1 if String(t.get("time", "past")) == "past" else 2
		var kind := String(t.get("kind", "rock"))
		for row in int(t.get("h", 1)):
			var block := TimeBlock.new()
			block.kind = {"rock": TimeBlock.Kind.ROCK, "bridge": TimeBlock.Kind.BRIDGE, "vine": TimeBlock.Kind.VINE}.get(kind, TimeBlock.Kind.ROCK)
			block.active_mask = mask
			block.cells = int(t.get("w", 1))
			block.palette = palette
			block.position = Vector2(int(t.x) * TILE, (int(t.y) + row) * TILE)
			root.add_child(block)
	for s in data.get("signs_timed", []):
		var board := InfoSign.new()
		board.text = Strings.t(String(s.text_key))
		board.sign_time = TimeShift.state_from_name(String(s.get("time", "past")))
		board.position = Vector2(int(s.cell[0]) * TILE, int(s.cell[1]) * TILE)
		root.add_child(board)
	for i in data.get("seeds", []).size():
		var s: Dictionary = data.seeds[i]
		var tree := SeedTree.new()
		tree.cells = int(s.tree[2])
		tree.seed_id = "%d_seed_%d" % [int(data.get("id", 0)), i]
		tree.palette = palette
		tree.position = Vector2(int(s.tree[0]) * TILE, int(s.tree[1]) * TILE)
		root.add_child(tree)
		var spot := SeedSpot.new()
		spot.tree = tree
		spot.position = Vector2(int(s.cell[0]) * TILE + 32, int(s.cell[1]) * TILE + 40)
		root.add_child(spot)
	for i in data.get("memory_marks", []).size():
		var m: Dictionary = data.memory_marks[i]
		var mark := MemoryMark.new()
		mark.level_id = int(data.get("id", 0))
		mark.index = i
		mark.mark_time = TimeShift.state_from_name(String(m.get("time", "past")))
		mark.position = Vector2(int(m.cell[0]) * TILE + 32, int(m.cell[1]) * TILE + 32)
		root.add_child(mark)
	for c in data.get("clocks", []):
		var clock := LensClock.new()
		clock.position = Vector2(int(c[0]) * TILE + 32, int(c[1]) * TILE + 32)
		root.add_child(clock)


## Where a seed can be planted: a little mound with a sprout, past only.
class SeedSpot extends Area2D:
	var tree: SeedTree
	var _t := 0.0

	func time_mask() -> int:
		return 1

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 40.0
		shape.shape = c
		add_child(shape)

	func _physics_process(_delta: float) -> void:
		if tree.planted or TimeShift.state != TimeShift.PAST:
			return
		for b in get_overlapping_bodies():
			if b.is_in_group("player"):
				tree.plant()
				AudioManager.play_sfx("grow")
				FX.burst(get_parent(), global_position, Color(0.5, 0.95, 0.4), 14)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2(0, 18), 0.0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 30.0, Color("6e4325"))
		draw_set_transform(Vector2.ZERO)
		if tree and tree.planted:
			draw_line(Vector2(0, 14), Vector2(0, -16), Color("3f8f3a"), 5.0)
			draw_circle(Vector2(-8, -18), 9.0, Color("6cc24a"))
			draw_circle(Vector2(8, -20), 9.0, Color("6cc24a"))
		else:
			var glow := 0.5 + 0.5 * sin(_t * 3.0)
			draw_circle(Vector2(0, 6), 9.0, Color(1.0, 0.9, 0.4, 0.5 + 0.5 * glow))
			draw_circle(Vector2(0, 6), 5.0, Color("8a5a32"))


## The tree a seed becomes in the present: a branch to stand on (one-way), only once planted.
class SeedTree extends StaticBody2D:
	var cells := 3
	var seed_id := ""
	var planted := false
	var palette: Dictionary = {}
	var _shape: CollisionShape2D
	var _grow := 0.0

	func time_mask() -> int:
		return 2

	func _ready() -> void:
		collision_layer = 1
		collision_mask = 0
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(cells * 64, 20)
		_shape.shape = rect
		_shape.position = Vector2(cells * 32, 10)
		_shape.one_way_collision = true
		add_child(_shape)
		planted = TimeShift.has_event(seed_id)
		_grow = 1.0 if planted else 0.0
		TimeShift.time_changed.connect(func(_s, _i): _refresh())
		_refresh()

	func plant() -> void:
		if planted:
			return
		planted = true
		TimeShift.record(seed_id)
		create_tween().tween_property(self, "_grow", 1.0, 0.8)
		_refresh()

	func _refresh() -> void:
		_shape.set_deferred("disabled", not (planted and TimeShift.state == TimeShift.PRESENT))
		queue_redraw()

	func _process(_delta: float) -> void:
		if _grow > 0.0 and _grow < 1.0:
			queue_redraw()

	func _draw() -> void:
		if _grow <= 0.01:
			# not planted yet: a faint dotted outline of the tree that could be
			draw_dashed_line(Vector2(0, 8), Vector2(cells * 64, 8), Color(1, 1, 1, 0.35), 3.0, 10.0)
			return
		var w := cells * 64.0
		var trunk_h := 400.0 * _grow
		draw_rect(Rect2(w * 0.5 - 22, 18, 44, trunk_h), Color("7c4a24"))
		draw_rect(Rect2(w * 0.5 - 14, 18, 10, trunk_h), Color("9a6a3e"))
		draw_rect(Rect2(0, 2, w * _grow, 18), Color("7c4a24"))
		for k in int(cells * 2 * _grow):
			draw_circle(Vector2(18 + k * 32, -6), 22.0, Color("4cb848"))
			draw_circle(Vector2(18 + k * 32, -12), 12.0, Color("8fe07a"))


## One of the three hidden carvings of a level (they open the chapter's memory room).
class MemoryMark extends Area2D:
	var level_id := 0
	var index := 0
	var mark_time: int = TimeShift.PAST
	var _t := 0.0
	var _taken := false

	func time_mask() -> int:
		return 1 if mark_time == TimeShift.PAST else 2

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 30.0
		shape.shape = c
		add_child(shape)
		_taken = MemoryMark.found(level_id, index)

	static func found(level: int, i: int) -> bool:
		return (SaveManager.data.get("memory_marks", {}).get(str(level), []) as Array).has(i)

	func _physics_process(_delta: float) -> void:
		if _taken or TimeShift.state != mark_time:
			return
		for b in get_overlapping_bodies():
			if b.is_in_group("player"):
				_taken = true
				var marks: Dictionary = SaveManager.data.get("memory_marks", {})
				var list: Array = marks.get(str(level_id), [])
				if not list.has(index):
					list.append(index)
				marks[str(level_id)] = list
				SaveManager.data["memory_marks"] = marks
				AudioManager.play_sfx("diamond", 0.8)
				FX.burst(get_parent(), global_position, Color(0.9, 0.8, 1.0), 16)
				var game := get_tree().get_first_node_in_group("game")
				if game and game.has_method("on_memory_mark"):
					game.on_memory_mark(self)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.25 if _taken else 0.85
		draw_circle(Vector2.ZERO, 24.0 + sin(_t * 2.0) * 2.0, Color(0.75, 0.6, 1.0, 0.25 * a))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.6, a), 3.0)
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color(1.0, 0.92, 0.6, a), 3.0)
		draw_line(Vector2(0, -8), Vector2(0, 8), Color(1.0, 0.92, 0.6, a), 3.0)


## «ساعت کوچک»: refills the lens a little.
class LensClock extends Area2D:
	const ART := "res://assets/art/p3_tools/p3_tool_pocketwatch_icon_l1.png"
	var _tex: Texture2D
	var _t := 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 2
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 26.0
		shape.shape = c
		add_child(shape)
		_tex = load(ART) if ResourceLoader.exists(ART) else null
		body_entered.connect(func(b):
			if b.is_in_group("player"):
				TimeShift.add_charge(50.0)
				AudioManager.play_sfx("coin", 0.8)
				FX.burst(get_parent(), global_position, Color(0.5, 0.8, 1.0), 12)
				queue_free())

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _tex:
			var s := 56.0 / maxf(_tex.get_width(), _tex.get_height())
			var size := _tex.get_size() * s
			draw_texture_rect(_tex, Rect2(-size * 0.5 + Vector2(0, sin(_t * 2.5) * 5.0), size), false)
