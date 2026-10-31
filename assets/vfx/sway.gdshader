shader_type canvas_item;
// Wind: the top of each drawn picture (trees, bushes) sways, the bottom stays rooted.
uniform float strength = 6.0;
uniform float speed = 1.3;
uniform float gust = 0.0;

void vertex() {
	float top = 1.0 - UV.y;
	float wave = sin(TIME * speed + VERTEX.x * 0.013) + 0.35 * sin(TIME * speed * 2.3 + VERTEX.x * 0.031);
	VERTEX.x += (wave * strength + gust * strength * 2.0) * top * top;
}
