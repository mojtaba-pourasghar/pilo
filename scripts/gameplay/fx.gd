class_name FX
extends RefCounted
## Small reusable effects: sparkle bursts, dust, sweat, breath, fire, splashes, floating words
## and the time-lens ring.

const DOT := preload("res://assets/vfx/dot.png")

static var _soft: Texture2D


## A soft round puff (smoke, dust, steam, flames).
static func soft() -> Texture2D:
	if _soft == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 64
		texture.height = 64
		_soft = texture
	return _soft


static var _flame: Texture2D


## A tongue of flame: a teardrop, hot white-yellow at the base and soft at the edges.
static func flame_texture() -> Texture2D:
	if _flame == null:
		var w := 48
		var h := 96
		var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var v := float(y) / h                       # 0 = tip, 1 = base
			var half := w * 0.5 * pow(sin(clampf(v, 0.0, 1.0) * PI * 0.62 + 0.25), 1.6) * (0.35 + 0.65 * v)
			for x in w:
				var d := absf(x + 0.5 - w * 0.5) / maxf(half, 0.001)
				if d > 1.0:
					continue
				var edge := 1.0 - d * d
				var heat := clampf(v * 1.2 - d * 0.5, 0.0, 1.0)
				var color := Color(1.0, 0.45 + 0.5 * heat, 0.1 + 0.6 * heat * heat)
				image.set_pixel(x, y, Color(color, edge * clampf(v * 3.0, 0.0, 1.0)))
		_flame = ImageTexture.create_from_image(image)
	return _flame


static func _puffs(parent: Node, pos: Vector2, amount: int, lifetime: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = soft()
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.lifetime = lifetime
	particles.position = pos
	particles.z_index = 5
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	particles.scale_amount_curve = curve
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)
	return particles


## Dust (or sand, or snow) thrown sideways along the ground by a heavy landing or a slam.
static func dust_ring(parent: Node, pos: Vector2, size := 1.0, color := Color(0.93, 0.87, 0.76, 0.85)) -> void:
	for side in [-1.0, 1.0]:
		var p := _puffs(parent, pos, int(7 * size) + 3, 0.6)
		p.direction = Vector2(side, -0.25)
		p.spread = 18.0
		p.initial_velocity_min = 90.0 * size
		p.initial_velocity_max = 260.0 * size
		p.damping_min = 250.0
		p.damping_max = 400.0
		p.gravity = Vector2(0, -30)
		p.scale_amount_min = 0.5 * size
		p.scale_amount_max = 1.1 * size
		p.color = color
		p.emitting = true


## A small kick of ground dust behind a running foot.
static func dust_kick(parent: Node, pos: Vector2, back: float, color: Color) -> void:
	var p := _puffs(parent, pos, 3, 0.45)
	p.direction = Vector2(back, -0.6)
	p.spread = 25.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.5
	p.color = color
	p.emitting = true


## Drops of sweat flying off a hot, tired head.
static func sweat(parent: Node, pos: Vector2, facing: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = DOT
	p.amount = 3
	p.one_shot = true
	p.explosiveness = 0.8
	p.lifetime = 0.6
	p.position = pos
	p.z_index = 6
	p.direction = Vector2(-facing, -1.2)
	p.spread = 35.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 170.0
	p.gravity = Vector2(0, 700)
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.3
	p.color = Color(0.75, 0.92, 1.0, 1.0)
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true


## A small cloud of breath in the cold.
static func breath(parent: Node, pos: Vector2, facing: float) -> void:
	var p := _puffs(parent, pos, 6, 1.1)
	p.explosiveness = 0.6
	p.direction = Vector2(facing, -0.3)
	p.spread = 15.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 55.0
	p.gravity = Vector2(0, -25)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.55
	p.color = Color(0.9, 0.94, 1.0, 0.6)
	p.emitting = true


## Flames and smoke clinging to something for a moment (it "catches fire"). Returns the node.
static func flames(target: Node2D, seconds := 1.2, color := Color(1.0, 0.55, 0.15)) -> Node2D:
	var holder := Node2D.new()
	holder.z_index = 7
	var fire := CPUParticles2D.new()
	fire.texture = flame_texture()
	fire.amount = 40
	fire.lifetime = 0.45
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(16, 38)
	fire.position = Vector2(0, -30)
	fire.direction = Vector2.UP
	fire.spread = 15.0
	fire.initial_velocity_min = 80.0
	fire.initial_velocity_max = 180.0
	fire.gravity = Vector2(0, -160)
	fire.scale_amount_min = 0.45
	fire.scale_amount_max = 0.85
	var taper := Curve.new()
	taper.add_point(Vector2(0, 1.0))
	taper.add_point(Vector2(1, 0.15))
	fire.scale_amount_curve = taper
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 0.85, 0.4, 0.75))
	ramp.set_color(1, Color(color.r * 0.8, color.g * 0.25, color.b * 0.2, 0))
	ramp.add_point(0.4, Color(color, 0.65))
	fire.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fire.material = additive
	holder.add_child(fire)
	var smoke := CPUParticles2D.new()
	smoke.texture = soft()
	smoke.amount = 14
	smoke.lifetime = 1.0
	smoke.position = Vector2(0, -90)
	smoke.direction = Vector2.UP
	smoke.spread = 25.0
	smoke.initial_velocity_min = 40.0
	smoke.initial_velocity_max = 80.0
	smoke.gravity = Vector2(0, -40)
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.1
	smoke.color = Color(0.4, 0.38, 0.4, 0.28)
	holder.add_child(smoke)
	var glow := Sprite2D.new()
	glow.texture = soft()
	glow.position = Vector2(0, -40)
	glow.scale = Vector2(3, 3)
	glow.modulate = Color(1, 0.55, 0.15, 0.3)
	glow.material = additive
	holder.add_child(glow)
	glow.create_tween().set_loops().tween_property(glow, "modulate:a", 0.18, 0.12).from(0.32)
	target.add_child(holder)
	# the timers live inside the flames, so they go away with them
	var out := Timer.new()
	out.wait_time = seconds
	out.one_shot = true
	out.autostart = true
	holder.add_child(out)
	out.timeout.connect(func():
		fire.emitting = false
		smoke.emitting = false
		glow.visible = false
		var gone := Timer.new()
		gone.wait_time = 1.0
		gone.one_shot = true
		gone.autostart = true
		gone.timeout.connect(holder.queue_free)
		holder.add_child(gone))
	return holder


## A rain drop splashing on the ground.
static func splash(parent: Node, pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.texture = DOT
	p.amount = 4
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.3
	p.position = pos
	p.z_index = 5
	p.direction = Vector2.UP
	p.spread = 60.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 120.0
	p.gravity = Vector2(0, 600)
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.22
	p.color = Color(0.85, 0.92, 1.0, 0.8)
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true


static func burst(parent: Node, pos: Vector2, color: Color, amount := 16) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = DOT
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 260.0
	particles.gravity = Vector2(0, 420)
	particles.scale_amount_min = 0.25
	particles.scale_amount_max = 0.6
	particles.color = color
	particles.position = pos
	particles.z_index = 8
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Little puff of dust at the feet (skids, landings, dashes).
static func dust(parent: Node, pos: Vector2, amount := 5) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = DOT
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.45
	particles.direction = Vector2.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 110.0
	particles.gravity = Vector2(0, 120)
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.7
	particles.color = Color(0.95, 0.9, 0.8, 0.8)
	particles.position = pos
	particles.z_index = 5
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## Shards flying out of a broken block or wall.
static func debris(parent: Node, pos: Vector2, color: Color, amount := 8) -> void:
	for i in amount:
		var piece := Debris.new()
		piece.color = color.darkened(randf() * 0.3)
		piece.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		piece.velocity = Vector2(randf_range(-260, 260), randf_range(-620, -260))
		piece.spin = randf_range(-12, 12)
		parent.add_child(piece)


static func float_text(parent: Node, pos: Vector2, text: String, color: Color) -> void:
	var label := UIKit.make_label(text, 30, color, 10, Color.WHITE)
	label.size = Vector2(460, 50)
	label.position = pos - Vector2(230, 25)
	label.z_index = 20
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50.0, 1.3)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.6)
	tween.tween_callback(label.queue_free)


static func ring(parent: Node, pos: Vector2, color: Color) -> void:
	var effect := Ring.new()
	effect.color = color
	effect.position = pos
	parent.add_child(effect)


class Ring extends Node2D:
	var color := Color.WHITE
	var radius := 10.0

	func _ready() -> void:
		z_index = 7
		var tween := create_tween()
		tween.tween_property(self, "radius", 900.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
		tween.tween_callback(queue_free)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, color, 14.0)
		draw_arc(Vector2.ZERO, radius * 0.86, 0.0, TAU, 72, Color(color, 0.4), 6.0)


class Debris extends Node2D:
	var color := Color.WHITE
	var velocity := Vector2.ZERO
	var spin := 0.0
	var life := 1.2

	func _ready() -> void:
		z_index = 8

	func _process(delta: float) -> void:
		velocity.y += 1600.0 * delta
		position += velocity * delta
		rotation += spin * delta
		life -= delta
		modulate.a = clampf(life * 2.0, 0.0, 1.0)
		if life <= 0.0:
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(-9, -7, 18, 14), Color("3b2418"))
		draw_rect(Rect2(-7, -5, 14, 10), color)
