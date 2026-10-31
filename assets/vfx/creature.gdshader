shader_type canvas_item;
// Brings a rendered creature picture to life on a grid mesh (PaintedCreature): its feet
// step in turn, its top sways and leans, its sides flap like wings (flyers), its middle
// breathes, and a boss's arms swing and slam. VERTEX is in pixels, origin at the feet.
uniform vec2 size = vec2(100.0, 100.0);
uniform float phase = 0.0;      // walk / flap cycle
uniform float stride = 0.0;     // 0..1 how hard the feet step
uniform float flap = 0.0;       // 0..1 wings
uniform float sway = 0.0;       // top sway (pixels)
uniform float breathe = 0.0;    // 0..1
uniform float arms = 0.0;       // 0..1 boss arms swing
uniform float slam = 0.0;       // 0..1 boss arms raised for a slam
uniform float time_s = 0.0;

void vertex() {
	vec2 uv = UV;
	float side = uv.x < 0.5 ? -1.0 : 1.0;
	float edge = abs(uv.x - 0.5) * 2.0;          // 0 middle .. 1 sides
	// feet: the bottom quarter, left and right halves step in turn
	float leg = smoothstep(0.68, 1.0, uv.y);
	float step_ = sin(phase + (side < 0.0 ? 0.0 : 3.14159));
	VERTEX.x += step_ * stride * size.x * 0.13 * leg;
	VERTEX.y -= max(0.0, step_) * stride * size.y * 0.07 * leg;
	// top: sway and a little lean into the walk
	float top = pow(1.0 - uv.y, 2.0);
	VERTEX.x += (sin(phase * 0.5) * sway + stride * size.x * 0.05) * top;
	// breathing: the middle swells
	float mid = 1.0 - abs(uv.y - 0.5) * 2.0;
	VERTEX.x += (uv.x - 0.5) * size.x * 0.06 * breathe * sin(time_s * 2.6) * mid;
	// wings: the sides flap up and down
	VERTEX.y += sin(phase * 2.0) * flap * size.y * 0.16 * pow(edge, 1.5) * (1.0 - uv.y * 0.6);
	// boss arms: the sides of the upper body swing, or rise high for a slam
	float arm = smoothstep(0.55, 1.0, edge) * smoothstep(0.15, 0.4, uv.y) * (1.0 - smoothstep(0.6, 0.8, uv.y));
	VERTEX.y += (sin(phase + side) * arms * 0.08 - slam * 0.22) * size.y * arm;
	VERTEX.x += side * slam * size.x * 0.05 * arm;
}
