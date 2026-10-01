shader_type canvas_item;

// The committed reaction PNG includes body and glyph. Draw its glyph once in
// a separate region sprite, allowing viewport clipping without moving the feet.
uniform vec4 bubble_box = vec4(0.0);

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	if (all(greaterThanEqual(pixel, bubble_box.xy)) &&
		all(lessThan(pixel, bubble_box.xy + bubble_box.zw))) {
		discard;
	}
}
