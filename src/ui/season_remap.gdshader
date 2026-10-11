shader_type canvas_item;

// **The season on the ground** (task 0159): the terrain, its edges and
// corners, the roofs and the snow caps' stand-ins. Everything it does is in
// `season.gdshaderinc`, which the trees' wind shader shares.
#include "res://src/ui/season.gdshaderinc"

varying vec4 sprite_tint;

// **Mud** (task 0258): on a rainy night the ground - the palette entries in
// `mud_from`, the grass and the soil - darkens toward wet earth by `mud`, 0
// dry. Only the ground's material sets it, so a roof never goes muddy; water,
// rock and the path's stones are not in the list.
uniform float mud = 0.0;
uniform vec3 mud_tint = vec3(0.72, 0.6, 0.5);
uniform vec3 mud_from[6];

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 drawn = source.rgb;
	source.rgb = seasonal(source.rgb);
	if (mud > 0.0) {
		for (int i = 0; i < 6; i++) {
			if (distance(drawn, mud_from[i]) < 0.008) {
				source.rgb = mix(source.rgb, source.rgb * mud_tint, mud);
				break;
			}
		}
	}
	// How far under its column's top edge this pixel is - one row more than
	// the snow, for the line it lies under - or -1 for deeper, or no snow.
	int depth = -1;
	if (season == 3 && snow_rows > 0 && source.a >= 0.5) {
		for (int k = 1; k <= 5; k++) {
			if (k > snow_rows + 1) {
				break;
			}
			vec2 above = UV - vec2(0.0, float(k) * TEXTURE_PIXEL_SIZE.y);
			if (above.y < 0.0 || texture(TEXTURE, above).a < 0.5) {
				depth = k - 1;
				break;
			}
		}
	}
	source = snowed(source, depth, floor(UV.x / TEXTURE_PIXEL_SIZE.x));
	COLOR = sprite_tint * source;
}
