shader_type canvas_item;

// Only the measured open firebox changes; the masonry and iron grate stay fixed.
// The viewer supplies cosmetic time so pause freezes the flame too.
uniform float flame_time = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec4 source = texture(TEXTURE, UV);
	if (pixel.x >= 17.0 && pixel.x < 31.0 && pixel.y >= 43.0 && pixel.y < 53.0) {
		float sway = sin(flame_time * 6.0 + pixel.y * 0.58) * 1.15;
		float rise = sin(flame_time * 8.5 + pixel.x * 0.37) * 1.7;
		vec2 at = clamp(pixel + vec2(sway, rise), vec2(17.5, 43.5), vec2(30.5, 52.5));
		source = texture(TEXTURE, at * TEXTURE_PIXEL_SIZE);
	}
	COLOR = sprite_tint * source;
}
