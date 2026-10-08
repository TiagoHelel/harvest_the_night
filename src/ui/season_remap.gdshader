shader_type canvas_item;

// **The season on the ground** (task 0159): the terrain, its edges and
// corners, the roofs and the snow caps' stand-ins. Everything it does is in
// `season.gdshaderinc`, which the trees' wind shader shares.
#include "res://src/ui/season.gdshaderinc"

varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	source.rgb = seasonal(source.rgb);
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
