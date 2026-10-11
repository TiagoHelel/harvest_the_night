shader_type canvas_item;

// **Fog** (task 0258): a noise worked out here, with no texture behind it,
// over the whole farm on a foggy night - in whole world pixels and four steps
// of thickness, as a palette would draw it, drifting slowly - and thinner on
// every cell the rules call lit (`Light`), so a searchlight visibly cuts it.
//
// Drawn in the world, under the night's ramp, so the night colours it as it
// colours everything else; the lamps, the night's cues and the HUD are above
// it. `WeatherView` owns the node and every uniform.

// The farm, in world pixels: the rectangle this is drawn over.
uniform vec2 world_size = vec2(1280.0, 720.0);
// A texel a cell, white where the cell is lit (`WeatherView` writes it).
uniform sampler2D lit_mask : filter_linear, repeat_disable;
// 0 none, 1 the whole fog: the light's own fade into the night.
uniform float density = 0.0;
// What the fog is, before the night colours it - a palette entry.
uniform vec3 fog_colour = vec3(0.722, 0.682, 0.604);
// The thickest it gets, as alpha.
uniform float thickest = 0.55;
// What is left of it on a lit cell.
uniform float lit_keep = 0.2;
// World pixels a second it drifts; zero holds it still.
uniform vec2 drift = vec2(3.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Value noise: a hash at each lattice point, eased between them.
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	// Whole world pixels: the fog is pixel art like everything under it.
	vec2 px = floor(UV * world_size);
	vec2 at = (px + floor(drift * TIME)) / 40.0;
	float n = noise(at) * 0.6 + noise(at * 2.3 + 17.0) * 0.3
		+ noise(at * 5.1 + 41.0) * 0.1;
	// Four steps, none to thickest, as a palette would draw it.
	float thick = floor(clamp((n - 0.25) / 0.6, 0.0, 0.999) * 4.0) / 3.0;
	float lit = texture(lit_mask, (px + 0.5) / world_size).r;
	float keep = mix(1.0, lit_keep, smoothstep(0.2, 0.8, lit));
	COLOR = vec4(fog_colour, thick * thickest * keep * density);
}
