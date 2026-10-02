shader_type canvas_item;

// Only the measured open firebox changes; the masonry and iron grate stay fixed.
// The viewer supplies cosmetic time so pause freezes the flame too.
uniform float flame_time = 0.0;
varying vec4 sprite_tint;

float tip_noise(float column, float beat) {
	return fract(sin(column * 127.1 + beat * 311.7) * 43758.5453);
}

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec4 source = texture(TEXTURE, UV);
	if (pixel.x >= 17.0 && pixel.x < 31.0 && pixel.y >= 43.0 && pixel.y < 53.0) {
		// Grow individual tongues from a fixed hot base. Columns never slide
		// sideways; independent irregular tips replace the old whole-fire sway.
		if (pixel.y < 50.0) {
			float column = floor(pixel.x / 2.0);
			float beat = flame_time * 4.0 + column * 0.43;
			float weight = smoothstep(0.0, 1.0, fract(beat));
			float height = mix(tip_noise(column, floor(beat)),
				tip_noise(column, floor(beat) + 1.0), weight);
			float stretch = 0.80 + height * 0.38;
			float y = 50.0 - (50.0 - pixel.y) / stretch;
			source = texture(TEXTURE, vec2(pixel.x, clamp(y, 43.5, 49.5)) * TEXTURE_PIXEL_SIZE);
		}
	}
	COLOR = sprite_tint * source;
}
