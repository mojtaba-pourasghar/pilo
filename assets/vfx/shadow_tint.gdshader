shader_type canvas_item;
// A creature under the shadow spell: its own colours turn to deep purple and indigo, with a
// faint violet glow; `amount` 1 = fully cursed, 0 = its real colours (freed).
uniform float amount = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float lum = dot(c.rgb, vec3(0.3, 0.55, 0.15));
	vec3 shadow = mix(vec3(0.16, 0.09, 0.28), vec3(0.62, 0.45, 0.95), smoothstep(0.15, 0.95, lum));
	COLOR = vec4(mix(c.rgb, shadow, amount * 0.82), c.a);
}
