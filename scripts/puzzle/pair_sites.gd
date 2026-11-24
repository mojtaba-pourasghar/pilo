class_name PairSites
extends RefCounted
## The "deed sites" of pair 1 (docs/33 §3): things the grandfather does in the old level that the
## new level remembers. Built from the level's `objects` list (positions in tiles; y = the ground the
## object stands on):
##   egg    the glowing egg lying in the dirt nest; touch it to pick it up (carried: speed x0.7)
##   nest   the high branch nest; carry the egg here (deed egg_saved)
##   seed   a gap with a sapling spot; the tool button plants a seed, roots grow into a bridge (bridge_planted)
##   shrine the stone shrine with the mirror; the tool button lights the lantern, the door opens (shrine_lit)
##   door   a gate that opens when the shrine is lit (data "opens" = id)
## Each deed site shows the golden hourglass (dim / lit / done) and plays the clock ring when done.

const ART := "res://assets/art/pair1/bg_old/p0_bg_old_setpieces/p0_bg_old_setpieces_%s.png"
const TILE := 64.0
const REACH := 110.0


static func tex(cell: String) -> Texture2D:
	var path := ART % cell
	return load(path) if ResourceLoader.exists(path) else null


## Builds every object of the level; returns the nodes (the level keeps them in `info.sites`).
static func build_all(objects: Array, root: Node2D, game: Node) -> Array:
	var made: Array = []
	for obj in objects:
		if not RouteParts.wanted(obj, game):
			continue
		var site := _make(obj)
		if site == null:
			continue
		site.game = game
		site.position = Vector2(float(obj.x) * TILE + TILE * 0.5, float(obj.y) * TILE)
		site.setup(obj)
		root.add_child(site)
		made.append(site)
	return made


static func _make(obj: Dictionary) -> Site:
	match String(obj.get("type", "")):
		"egg":
			return EggSite.new()
		"nest":
			return NestSite.new()
		"seed":
			return SeedSite.new()
		"bridge":
			return ReadyBridge.new()
		"shrine":
			return ShrineSite.new()
		"door":
			return DoorSite.new()
	return null


## Base: something at a spot that may react to the hero standing near it.
class Site extends Node2D:
	var game: Node
	var data: Dictionary = {}
	var done := false
	var reach := 110.0
	var deed := ""
	var _sprite: Sprite2D
	var _marker: Sprite2D
	var _t := 0.0

	func setup(obj: Dictionary) -> void:
		data = obj
		deed = String(obj.get("deed", ""))
		add_to_group("pair_site")
		z_index = 2
		_build_art()
		if deed != "":
			_make_marker()

	func _build_art() -> void:
		pass

	func player() -> Node2D:
		return game.player if game and game.get("player") else null

	func near(extra := 0.0) -> bool:
		var p := player()
		return p != null and p.global_position.distance_to(global_position + Vector2(0, -40)) < reach + extra

	## The tool button was pressed near this site; true = handled.
	func act() -> bool:
		return false

	func _make_marker() -> void:
		_marker = Sprite2D.new()
		_marker.texture = PairSites.tex("r02_c00")
		_marker.centered = true
		var k := 56.0 / maxf(1.0, _marker.texture.get_height()) if _marker.texture else 1.0
		_marker.scale = Vector2(k, k)
		_marker.position = Vector2(0, -150)
		_marker.z_index = 3
		add_child(_marker)

	func _marker_state(state: int) -> void:         # 0 dim, 1 lit (you are near), 2 done
		if _marker:
			var t := PairSites.tex("r02_c0%d" % state)
			if t:
				_marker.texture = t

	func complete() -> void:
		if done:
			return
		done = true
		_marker_state(2)
		var fresh := DeedsStore.add(deed) if deed != "" else false
		SpriteFX.play(get_parent(), "deed_ring", global_position + Vector2(0, -90), 1.2)
		AudioManager.play_sfx("pickup", 1.2)
		if game and game.has_method("notify_deed") and deed != "":
			game.notify_deed(deed, fresh)

	func _process(delta: float) -> void:
		_t += delta
		if _marker and not done:
			_marker.position.y = -150.0 + sin(_t * 2.2) * 4.0
			_marker_state(1 if near(60.0) else 0)
		_tick(delta)

	func _tick(_delta: float) -> void:
		pass


class EggSite extends Site:
	func _build_art() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = PairSites.tex("r01_c01")
		if _sprite.texture:
			var k := 70.0 / _sprite.texture.get_height()
			_sprite.scale = Vector2(k, k)
			_sprite.position = Vector2(0, -34)
		add_child(_sprite)

	func _tick(_delta: float) -> void:
		if done or _sprite == null:
			return
		_sprite.position.y = -34.0 + sin(_t * 2.0) * 2.0
		var p := player()
		if p and near(-30.0) and p.get("carrying") == "":
			p.carry("egg")
			done = true
			queue_free()


class NestSite extends Site:
	func _build_art() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = PairSites.tex("r01_c00")
		if _sprite.texture:
			var k := 150.0 / _sprite.texture.get_height()
			_sprite.scale = Vector2(k, k)
			_sprite.position = Vector2(0, -75)
		add_child(_sprite)
		reach = 120.0

	func _tick(_delta: float) -> void:
		if done:
			return
		var p := player()
		if p and near() and p.get("carrying") == "egg":
			p.carry("")
			_sprite.texture = PairSites.tex("r01_c01")
			complete()


class SeedSite extends Site:
	var _bridge: Node2D
	var width := 5

	func _build_art() -> void:
		width = int(data.get("width", 5))
		reach = 150.0

	func act() -> bool:
		if done or not near():
			return false
		_plant()
		return true

	func _plant() -> void:
		# roots weave across the gap: a row of solid tiles that grows in over ~0.8 s
		_bridge = Node2D.new()
		add_child(_bridge)
		for i in width:
			var body := StaticBody2D.new()
			body.collision_layer = 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(TILE, 20)
			shape.shape = rect
			body.add_child(shape)
			body.position = Vector2((i - (width - 1) * 0.5) * TILE, 10)
			var plank := Polygon2D.new()
			plank.polygon = PackedVector2Array([Vector2(-32, -10), Vector2(32, -10), Vector2(32, 10), Vector2(-32, 10)])
			plank.color = Color("5b8c3a")
			body.add_child(plank)
			var edge := Line2D.new()
			edge.points = PackedVector2Array([Vector2(-32, -10), Vector2(32, -10)])
			edge.width = 4.0
			edge.default_color = Color("2a1f3d")
			body.add_child(edge)
			body.scale = Vector2(0.01, 1.0)
			_bridge.add_child(body)
			var tw := body.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.12 * i)
			tw.tween_property(body, "scale:x", 1.0, 0.35)
		complete()


class ShrineSite extends Site:
	func _build_art() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = PairSites.tex("r01_c02")
		if _sprite.texture:
			var k := 190.0 / _sprite.texture.get_height()
			_sprite.scale = Vector2(k, k)
			_sprite.position = Vector2(0, -95)
		add_child(_sprite)
		reach = 130.0

	func act() -> bool:
		if done or not near():
			return false
		var p := player()
		if p and p.get("has_lantern") == false:
			return false
		_sprite.texture = PairSites.tex("r01_c03")
		complete()
		for node in get_tree().get_nodes_in_group("pair_site"):
			if node is DoorSite and String(node.data.get("id", "")) == String(data.get("opens", "")):
				node.open()
		return true


class DoorSite extends Site:
	var _body: StaticBody2D

	func _build_art() -> void:
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE * 0.5, TILE * float(data.get("height", 3)))
		shape.shape = rect
		_body.add_child(shape)
		var slab := Polygon2D.new()
		var h := TILE * float(data.get("height", 3))
		slab.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(16, h), Vector2(-16, h)])
		slab.color = Color("8a8f9a")
		_body.add_child(slab)
		_body.position = Vector2(0, -h * 0.5)
		slab.position = Vector2(0, -h * 0.5)
		add_child(_body)

	func open() -> void:
		if done:
			return
		done = true
		var tw := create_tween()
		tw.tween_property(_body, "position:y", _body.position.y - TILE * 3.2, 0.7)
		tw.tween_callback(func(): _body.get_child(0).set_deferred("disabled", true))


## The living bridge that the old level planted: already there in the new level (no deed to earn).
class ReadyBridge extends SeedSite:
	func setup(obj: Dictionary) -> void:
		super.setup(obj)
		_plant()

	func complete() -> void:
		done = true
