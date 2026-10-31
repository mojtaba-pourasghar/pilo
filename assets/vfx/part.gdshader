shader_type canvas_item;
// One part of a cut-up creature (PaintedCreature): its inner edges fade out softly so the
// parts blend into each other at the joints instead of showing straight cut lines.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);   // x0, y0, x1, y1 in texture UV
uniform vec4 fade = vec4(0.0);                      // left, top, right, bottom widths (UV)

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float a = 1.0;
	if (fade.x > 0.0) a *= smoothstep(region.x, region.x + fade.x, UV.x);
	if (fade.y > 0.0) a *= smoothstep(region.y, region.y + fade.y, UV.y);
	if (fade.z > 0.0) a *= 1.0 - smoothstep(region.z - fade.z, region.z, UV.x);
	if (fade.w > 0.0) a *= 1.0 - smoothstep(region.w - fade.w, region.w, UV.y);
	COLOR = vec4(c.rgb, c.a * a);
}
