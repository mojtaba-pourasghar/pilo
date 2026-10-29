class_name EnemyRig
extends CharacterRig
## Shared drawing state of the shadow creatures: `freed_amount` blends from the shadow
## colours to the creature's real colours, `squash` flattens it for a stomp. Shadow wisps
## rise from them until they are freed.

var freed_amount := 0.0
var squash := 0.0
var skin := ""


func mixc(shadow: Color, real: Color) -> Color:
	return shadow.lerp(real, freed_amount)


func _process(delta: float) -> void:
	super(delta)
	scale.y = 1.0 - squash * 0.55
	if scale.x != 0.0:
		scale.x = signf(scale.x) * (1.0 + squash * 0.35)


func draw_wisps(center: Vector2, spread: float) -> void:
	if freed_amount >= 1.0:
		return
	for i in 4:
		var k := fmod(t * 0.7 + i * 0.25, 1.0)
		var pos := center + Vector2(sin(i * 2.1 + t) * spread, -k * 40.0)
		draw_circle(pos, 5.0 * (1.0 - k), Color(0.35, 0.2, 0.55, 0.45 * (1.0 - k) * (1.0 - freed_amount)))
	if freed_amount > 0.0:
		for i in 6:
			var a := i * TAU / 6.0 + t * 3.0
			draw_circle(center + Vector2(cos(a), sin(a)) * (20.0 + freed_amount * 24.0), 3.0, Color(1, 0.95, 0.5, 1.0 - freed_amount * 0.5))


func angry_eyes(left: Vector2, right: Vector2, r: float) -> void:
	var happy := freed_amount > 0.5
	for c in [left, right]:
		if happy:
			draw_arc(c + Vector2(0, 2), r * 0.8, PI + 0.3, TAU - 0.3, 8, OUTLINE, 2.6)
			continue
		ellipse(c, Vector2(r * 0.8, r * eyes_open()), Color.WHITE)
		if eyes_open() > 0.5:
			draw_circle(c + Vector2(r * 0.25, r * 0.15), r * 0.45, Color("1d100a"))
			draw_circle(c + Vector2(r * 0.05, -r * 0.2), r * 0.16, Color.WHITE)
	if not happy:
		draw_line(left + Vector2(-r, -r * 1.3), left + Vector2(r * 0.8, -r * 0.7), OUTLINE, 2.8)
		draw_line(right + Vector2(r, -r * 1.3), right + Vector2(-r * 0.8, -r * 0.7), OUTLINE, 2.8)
