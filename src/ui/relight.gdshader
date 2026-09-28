shader_type canvas_item;

// The two realities, out of one set of sprites. `design.md` section 18.
//
// The farm is drawn once, in the palette's own colours, and lit twice. The
// `CanvasModulate` above this does the tint, because a multiply is free and
// because the rest of the game reads its colour to know what the light is
// doing. This pass does the three things a multiply cannot:
//
//   * **lift** - a multiply can only take light away, and the reference
//     sheet's night is a *purple* one. Purple is not "less" of anything the
//     farm is painted in; it has to be added.
//   * **saturation** - moonlight is not a coloured bulb pointed at a bright
//     afternoon. Pulling the colour out is most of what makes it read as
//     night rather than as a blue filter.
//   * **warm_keep** - fire, a lit window and the moon are the only warm
//     things after dark, and a tint that dims them along with the grass
//     leaves a night that is evenly blue and dead.
//
// The last one needs the colour the pixel had *before* the tint, and all this
// pass can see is the screen after it. So it divides the tint back out. That
// is exact for anything the multiply did not clip, which is everything: the
// tint is per-channel and never zero.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable,
	filter_nearest;

// The `CanvasModulate`'s colour, so the original can be recovered.
uniform vec3 tint = vec3(1.0);
// Added after the tint. This is where the night's purple comes from.
uniform vec3 lift = vec3(0.0);
// 1.0 leaves the palette alone; below that walks it towards grey.
uniform float saturation = 1.0;
// Anything the palette drew brighter than this keeps its own colour. At 1.0
// nothing is exempt, which is what daylight wants.
uniform float warm_keep = 1.0;
// How wide the edge of that threshold is, so a flame does not have a hard
// outline where the exemption stops.
uniform float warm_edge = 0.12;

// Rec. 601 luma. The same weights the rest of the UI uses for "how bright is
// this", so a colour that reads as warm here reads as warm there.
const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
	vec3 lit = texture(screen_tex, SCREEN_UV).rgb;
	// What the palette actually painted, before the tint multiplied it.
	vec3 raw = lit / max(tint, vec3(0.001));

	// Grey is measured on the tinted pixel, not the raw one: desaturating
	// towards the raw grey would undo the tint as a side effect.
	float grey = dot(lit, LUMA);
	vec3 relit = mix(vec3(grey), lit, saturation) + lift;

	// **Judged on the original.** A flame is only obviously a flame before
	// the night tint has been through it; after, it is as dim as the grass.
	float bright = dot(raw, LUMA);
	float keep = smoothstep(warm_keep - warm_edge, warm_keep + warm_edge,
		bright);
	relit = mix(relit, raw, keep);

	COLOR = vec4(clamp(relit, vec3(0.0), vec3(1.0)), 1.0);
}
