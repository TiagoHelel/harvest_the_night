shader_type canvas_item;

// Deform the existing art gently; source pixels and ground contacts are kept.
uniform float motion_time = 0.0;
uniform float phase = 0.0;
uniform int species = 0; // 0 canopy, 1 chicken, 2 cow
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 sample_uv = UV;
	float t = motion_time + phase;
	if (species == 0) {
		float crown = 1.0 - smoothstep(0.62, 0.84, UV.y);
		sample_uv.x -= sin(t * 1.5) * 1.6 * TEXTURE_PIXEL_SIZE.x * crown;
	} else if (species == 1) {
		float head = (1.0 - smoothstep(0.50, 0.67, UV.x)) * (1.0 - smoothstep(0.68, 0.86, UV.y));
		float beat = mod(t, 4.7);
		float peck = beat < 1.1 ? pow(sin(beat * 5.712), 2.0) : 0.0;
		sample_uv.y -= peck * 2.0 * TEXTURE_PIXEL_SIZE.y * head;
	} else {
		float head = (1.0 - smoothstep(0.28, 0.44, UV.x)) * (1.0 - smoothstep(0.72, 0.88, UV.y));
		float tail = smoothstep(0.72, 0.88, UV.x) * (1.0 - smoothstep(0.66, 0.84, UV.y));
		sample_uv.y -= (0.5 + 0.5 * sin(t * 2.1)) * 1.6 * TEXTURE_PIXEL_SIZE.y * head;
		sample_uv.x -= sin(t * 3.0) * 1.3 * TEXTURE_PIXEL_SIZE.x * tail;
	}
	COLOR = sprite_tint * texture(TEXTURE, sample_uv);
}
