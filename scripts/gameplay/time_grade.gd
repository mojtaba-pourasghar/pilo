class_name TimeGrade
extends CanvasLayer
## The look of the two times over the whole scene (T3). The past and the present share one
## geometry: the scene art is the same, and the present is that same picture through a shader —
## less colour, a light fog and an orange edge. The past is vivid with a faint blue edge.
## The lens itself is a circle that grows from the hero and turns the picture to the other time
## (a shader, not a picture). Sits above the world and below the HUD.

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float present_out = 1.0;   // grade outside the lens circle (1 = present, 0 = past)
uniform float present_in = 1.0;    // grade inside the lens circle
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.0;
uniform float aspect = 1.7778;
uniform float strength = 1.0;

void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	vec2 d = SCREEN_UV - center;
	d.x *= aspect;
	float dist = length(d);
	float inside = 1.0 - smoothstep(radius - 0.035, radius, dist);
	float p = mix(present_out, present_in, inside) * strength;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float past = (1.0 - mix(present_out, present_in, inside)) * strength;
	// present: colour drained, a grey-violet fog (thicker higher up) and an orange edge
	vec3 g = mix(c.rgb, vec3(lum) * vec3(0.98, 0.96, 1.02), 0.62 * p);
	g = mix(g, vec3(0.6, 0.6, 0.68), p * 0.24 * (1.0 - SCREEN_UV.y * 0.5));
	g *= 1.0 - 0.08 * p;
	vec2 e = SCREEN_UV - 0.5;
	float vig = smoothstep(0.32, 0.78, length(e * vec2(1.0, 0.92)));
	g = mix(g, vec3(1.0, 0.52, 0.15), vig * 0.45 * p);
	// past: alive, a little more colour and a faint blue edge
	g = mix(vec3(lum), g, 1.0 + 0.18 * past);
	g = mix(g, vec3(0.35, 0.66, 1.0), vig * 0.2 * past);
	float ring = (1.0 - smoothstep(0.0, 0.028, abs(dist - radius))) * step(0.002, radius) * (1.0 - smoothstep(1.2, 1.5, radius));
	g += mix(vec3(0.55, 0.8, 1.0), vec3(1.0, 0.72, 0.35), present_in) * ring * 0.7;
	COLOR = vec4(g, 1.0);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 6
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_rect.material = _mat
	add_child(_rect)
	set_strength(1.0)


## Players can turn the effect down ("حالت آرام"): 0..1.
func set_strength(value: float) -> void:
	_mat.set_shader_parameter("strength", value)


func grade_of(state: int) -> float:
	return 1.0 if state == TimeShift.PRESENT else 0.0


## Instant look for a state (level start, respawn).
func set_state(state: int) -> void:
	if _tween:
		_tween.kill()
	_mat.set_shader_parameter("present_out", grade_of(state))
	_mat.set_shader_parameter("present_in", grade_of(state))
	_mat.set_shader_parameter("radius", 0.0)


## The lens: a circle grows from `screen_pos` and everything inside it is already `state`.
func wipe(screen_pos: Vector2, state: int, time := 0.45) -> void:
	if _tween:
		_tween.kill()
	var view := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", view.x / maxf(view.y, 1.0))
	_mat.set_shader_parameter("center", screen_pos / view)
	_mat.set_shader_parameter("present_in", grade_of(state))
	_mat.set_shader_parameter("radius", 0.0)
	_tween = create_tween()
	_tween.tween_method(func(r: float): _mat.set_shader_parameter("radius", r), 0.0, 2.2, time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_callback(func():
		_mat.set_shader_parameter("present_out", grade_of(state))
		_mat.set_shader_parameter("radius", 0.0))


func current_radius() -> float:
	return float(_mat.get_shader_parameter("radius"))
