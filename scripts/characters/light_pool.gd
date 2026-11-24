extends Node2D
## A soft pool of warm light (Embri's lantern form). In dark levels the game's darkness mask reads `pools` in
## group "light_pool"; in every level it also lights the area with an additive glow so it looks right.

var radius := 300.0
var _t := 0.0


func _ready() -> void:
	add_to_group("light_pool")
	z_index = 6
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var flick := 1.0 + sin(_t * 17.0) * 0.03 + sin(_t * 5.3) * 0.04
	var steps := 9
	for i in steps:
		var k := float(i + 1) / steps
		var a := 0.07 * (1.0 - k) + 0.01
		draw_circle(Vector2.ZERO, radius * k * flick, Color(1.0, 0.82, 0.45, a))
