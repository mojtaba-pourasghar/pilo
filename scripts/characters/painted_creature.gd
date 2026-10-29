class_name PaintedCreature
extends EnemyRig
## A creature shown with its generated, rendered pictures (assets/art/<art>_shadow.png and
## <art>_free.png, or a single <art>.png): shadow creatures, the world guardians, companions
## and story characters. The pictures cross-fade from the shadow look to the real one as
## `freed_amount` grows, and the creature moves in code: it bobs and squashes as it walks,
## hovers and tilts when it flies, leans into a charge and glows when a move is coming.
## Origin = feet, facing right (`face_left` for art that is used mirrored).

const ART := "res://assets/art/%s.png"

var art := ""
var height := 60.0          ## height in the game, in pixels
var motion := "walk"        ## "walk", "fly", "roll", "boss", "idle"
var face_left := false
var anger := 1.0            ## bosses: speeds the idle motion
var flash := 0.0            ## bosses: white glow when a move is coming or a hit lands

var _shadow: Sprite2D
var _free: Sprite2D
var _holder: Node2D


## Is there generated art for this name (either the shadow/free pair or a single picture)?
static func available(name: String) -> bool:
	return ResourceLoader.exists(ART % (name + "_shadow")) or ResourceLoader.exists(ART % name)


static func make(name: String, game_height: float, kind_of_motion := "walk") -> PaintedCreature:
	var creature := PaintedCreature.new()
	creature.art = name
	creature.height = game_height
	creature.motion = kind_of_motion
	return creature


func _ready() -> void:
	_holder = Node2D.new()
	add_child(_holder)
	if ResourceLoader.exists(ART % (art + "_shadow")):
		_shadow = _sprite(art + "_shadow")
		var free_name := art + "_free"
		_free = _sprite(free_name if ResourceLoader.exists(ART % free_name) else art + "_shadow")
	else:
		_free = _sprite(art)
		freed_amount = 1.0


func _sprite(name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART % name)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var k := height / float(sprite.texture.get_height())
	sprite.scale = Vector2(k, k)
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	sprite.flip_h = face_left
	_holder.add_child(sprite)
	return sprite


func target_pose(delta: float) -> Dictionary:
	var rate := 9.0
	match motion:
		"fly":
			rate = 6.0
		"boss":
			rate = 3.0 + anger * 2.0
	if state == "charge":
		rate *= 2.0
	phase += delta * rate
	return {}


func _process(delta: float) -> void:
	super(delta)
	flash = maxf(0.0, flash - delta * 2.5)
	if _free == null:
		return
	if _shadow:
		_shadow.modulate.a = 1.0 - freed_amount
		_free.modulate.a = freed_amount
	var bob := 0.0
	var tilt := 0.0
	var stretch := 0.0
	match motion:
		"walk":
			bob = -absf(sin(phase)) * height * 0.06
			stretch = sin(phase * 2.0) * 0.04
			tilt = sin(phase) * 0.05
		"fly":
			bob = -height * 0.15 + sin(phase) * height * 0.1
			tilt = sin(phase * 0.5) * 0.12
			stretch = sin(phase * 3.0) * 0.03
		"roll":
			bob = -absf(sin(phase * 0.5)) * height * 0.04
			tilt = sin(phase * 0.7) * 0.08
		"boss":
			bob = -absf(sin(phase)) * height * 0.03
			stretch = sin(phase * 2.0) * 0.025
			match state:
				"windup":
					stretch = -0.1
				"stunned":
					stretch = -0.14
					tilt = sin(t * 14.0) * 0.08
				"charge":
					tilt = 0.12
		_:
			stretch = sin(t * 2.4) * 0.02
	if state == "freed" or state == "free":
		bob = -absf(sin(t * 8.0)) * height * 0.2
		stretch = 0.0
	_holder.position = Vector2(0, bob)
	_holder.rotation = tilt
	_holder.scale = Vector2(1.0 - stretch, 1.0 + stretch)
	modulate = Color(1, 1, 1).lerp(Color(2.0, 1.6, 1.6), flash)


func _draw() -> void:
	draw_wisps(Vector2(0, -height * 0.6), height * 0.35)
