shader_type canvas_item;
// Desert heat: what is behind this layer (the background) shimmers, most near the ground.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.004;

void fragment() {
	float low = smoothstep(0.15, 0.85, SCREEN_UV.y);
	vec2 wobble = vec2(sin(SCREEN_UV.y * 90.0 + TIME * 5.0) + sin(SCREEN_UV.y * 37.0 - TIME * 3.1) * 0.6,
		sin(SCREEN_UV.x * 50.0 + TIME * 4.0) * 0.4) * amount * low;
	COLOR = texture(screen_texture, SCREEN_UV + wobble);
}
