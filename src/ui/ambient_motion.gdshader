shader_type canvas_item;

// Deform the existing art gently; source pixels and ground contacts are kept.
// **And wear the season** (task 0159): a CanvasItem has one material, and the
// trees' is this one, so the remap the ground wears is included here. Every
// texel is remapped before it is blended, so a leaf mid-sway is a remapped
// leaf and not a blend no table names. `remap` stays off for the animals.
#include "res://src/ui/season.gdshaderinc"
uniform float motion_time = 0.0;
uniform float phase = 0.0;
uniform int species = 0; // 0 canopy, 1 chicken, 2 cow
uniform float wind_speed = 0.8;
uniform float wind_strength = 0.8;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec2 sample_uv = UV;
	float t = motion_time + phase;
	vec4 source = texture(TEXTURE, UV);
	source.rgb = seasonal(source.rgb);
	if (species == 0) {
		// Both 40x48 tree variants expose wood below row 22. Stop the effect
		// above it, including the visible branches, rather than at the roots.
		float crown = 1.0 - smoothstep(13.0, 22.0, UV.y / TEXTURE_PIXEL_SIZE.y);
		float wind = sin(motion_time * wind_speed + phase) * 0.82
			+ sin(motion_time * wind_speed * 0.61 + phase * 0.7) * 0.18;
		sample_uv.x -= wind * wind_strength * TEXTURE_PIXEL_SIZE.x * crown;
		if (crown > 0.0) {
			// Smooth subpixel leaf motion with premultiplied alpha at edges.
			// Wood retains its original nearest-filtered pixels.
			float px = sample_uv.x / TEXTURE_PIXEL_SIZE.x - 0.5;
			vec2 left = vec2((floor(px) + 0.5) * TEXTURE_PIXEL_SIZE.x, sample_uv.y);
			vec4 a = texture(TEXTURE, left);
			vec4 b = texture(TEXTURE, left + vec2(TEXTURE_PIXEL_SIZE.x, 0.0));
			a.rgb = seasonal(a.rgb);
			b.rgb = seasonal(b.rgb);
			float weight = fract(px);
			float alpha = mix(a.a, b.a, weight);
			vec3 rgb = mix(a.rgb * a.a, b.rgb * b.a, weight);
			source = vec4(rgb / max(alpha, 0.0001), alpha);
		}
	} else if (species == 1) {
		float head = (1.0 - smoothstep(0.50, 0.67, UV.x)) * (1.0 - smoothstep(0.68, 0.86, UV.y));
		float beat = mod(t, 4.7);
		float peck = beat < 1.1 ? pow(sin(beat * 5.712), 2.0) : 0.0;
		sample_uv.y -= peck * 2.0 * TEXTURE_PIXEL_SIZE.y * head;
		source = texture(TEXTURE, sample_uv);
	} else {
		float head = (1.0 - smoothstep(0.28, 0.44, UV.x)) * (1.0 - smoothstep(0.72, 0.88, UV.y));
		float tail = smoothstep(0.72, 0.88, UV.x) * (1.0 - smoothstep(0.66, 0.84, UV.y));
		sample_uv.y -= (0.5 + 0.5 * sin(t * 2.1)) * 1.6 * TEXTURE_PIXEL_SIZE.y * head;
		sample_uv.x -= sin(t * 3.0) * 1.3 * TEXTURE_PIXEL_SIZE.x * tail;
		source = texture(TEXTURE, sample_uv);
	}
	COLOR = sprite_tint * source;
}
