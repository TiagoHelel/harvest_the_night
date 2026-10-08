// **The season, for any canvas shader that draws the farm** (task 0159).
//
// Shared by `season_remap.gdshader` (the terrain, its edges, the roofs and
// the snow caps' stand-ins) and `ambient_motion.gdshader` (the trees, which
// already wear the wind and can wear only one material).
//
// The farm's art is in the palette's own colours, exactly, so a season is a
// table of palette entry -> palette entry: the grass and the foliage
// (`PaletteData.FOLIAGE`) become what `PaletteData.SEASON_REMAP` says. The
// tables are uniforms set once; `season` is the one that switches. The night
// ramp is a screen pass over all of it, so a winter night is still a night.

// 0 spring - today's art - to 3 winter, in `GameData.SEASONS` order.
uniform int season = 0;
// Off for art that already carries its season, and for anything that only
// borrows the wind (the chickens and the cows).
uniform bool remap = false;
// The foliage entries, and what each becomes: eight per season, seasons in
// order.
uniform vec3 season_from[8];
uniform vec3 season_to[32];
uniform int season_count = 0;
// **Snow on the top edge** in winter: how many rows of each column's top
// pixels go white. 0 for none. A roof's, and a snow cap's stand-in.
uniform int snow_rows = 0;
// Draw only that snow - a cap's stand-in is its host drawn through this mask.
uniform bool snow_only = false;
uniform vec3 snow_body = vec3(0.910, 0.878, 0.812);
uniform vec3 snow_light = vec3(0.812, 0.839, 1.0);
uniform vec3 snow_line = vec3(0.141, 0.122, 0.180);

// What this palette colour is in this season.
vec3 seasonal(vec3 colour) {
	if (!remap || season <= 0) {
		return colour;
	}
	for (int i = 0; i < 8; i++) {
		if (i >= season_count) {
			break;
		}
		if (distance(colour, season_from[i]) < 0.008) {
			return season_to[season * 8 + i];
		}
	}
	return colour;
}

// **The snow on a pixel**, once its depth under its column's top edge is
// known (the sampling is the shader's own: a built-in texture cannot be
// handed to a function here). Under an unbroken line: depth 0 is the ink
// line round the art - its own pixel where the art drew one, ink where it
// left a gap - and the `snow_rows` under it are snow. Snow in place of the
// line melts into a snowy field; snow under a gappy line leaves the line's
// pixels floating over it as dots. The body on the first snow row, the cool
// light and the body in turn under it. `depth` -1 is no snow.
vec4 snowed(vec4 source, int depth, float column) {
	if (source.a < 0.5 || depth < 0) {
		return snow_only ? vec4(0.0) : source;
	}
	if (depth == 0) {
		bool lined = dot(source.rgb, vec3(0.299, 0.587, 0.114)) < 0.3;
		return lined ? source : vec4(snow_line, source.a);
	}
	bool cool = depth > 1 && mod(column, 2.0) > 0.5;
	return vec4(cool ? snow_light : snow_body, source.a);
}
