class_name ShadowBee
extends Enemy
## «زنبور سایه»: flies back and forth in a gentle wave around where it was placed.
## Stompable. `span` = how far it flies to each side.

var span := 160.0
var _origin := Vector2.ZERO
var _t := 0.0


func _init() -> void:
	body_size = Vector2(46, 40)
	speed = 0.9


func _ready() -> void:
	super()
	_origin = position
	_t = randf() * TAU


func make_rig() -> EnemyRig:
	return Rig.new()


func move(delta: float) -> void:
	_t += delta * speed
	position = _origin + Vector2(sin(_t) * span, sin(_t * 2.6) * 14.0)
	facing = signf(cos(_t)) if cos(_t) != 0.0 else facing


class Rig extends EnemyRig:
	const BODY_SHADOW := Color("4b3a6e")
	const BODY_REAL := Color("ffcc33")
	const STRIPE := Color("2b1d3a")

	func target_pose(_delta: float) -> Dictionary:
		return {"wing": sin(t * 40.0)}

	func _draw() -> void:
		var c := Vector2(0, -20 + sin(t * 5.0) * 2.0)
		var wing := p("wing")
		# wings behind
		for w in [-1.0, 1.0]:
			var a: float = -0.6 + wing * 0.5 * w
			ellipse(c + Vector2(-4 + w * 3.0, -14), Vector2(11, 6), Color(0.85, 0.95, 1.0, 0.75), a - PI * 0.5 + 0.9)
		# stinger
		shape(PackedVector2Array([c + Vector2(-20, -3), c + Vector2(-31, 1), c + Vector2(-20, 5)]), STRIPE)
		var body := mixc(BODY_SHADOW, BODY_REAL)
		ellipse(c, Vector2(22, 16), body)
		for x in [-9.0, 1.0]:
			draw_colored_polygon(ellipse_points(c + Vector2(x, 0), Vector2(3.5, 14.5)), mixc(Color("241733"), STRIPE))
		angry_eyes(c + Vector2(8, -4), c + Vector2(17, -4), 4.2)
		# antennae
		for x in [6.0, 13.0]:
			draw_line(c + Vector2(x, -14), c + Vector2(x + 4, -24), OUTLINE, 2.0)
			draw_circle(c + Vector2(x + 4, -24), 3.0, body)
		draw_wisps(c + Vector2(0, -16), 14.0)
