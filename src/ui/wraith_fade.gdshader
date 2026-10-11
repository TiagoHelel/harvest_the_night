shader_type canvas_item;

// **A wraith, faint outside light** (task 0252). The view decides how much of
// it the eye gets - its presence: 1 where `Light` says its cell is lit,
// `WorldView.WRAITH_FAINT` where it is not, eased between - and hands it over
// in the sprite's alpha. This turns A051's opaque, binary-alpha art into a
// shade at that strength. The art never carries translucency: the pack
// forbids it, and this is where it lives instead.
//
// In the dark it wavers too, each row of the art on its own clock, so a faint
// one reads as something there rather than as a smudge on the ground; in
// light it is still and solid. View only: it reads the alpha it is given and
// the clock, never the rules.

// How far a row wavers at the faintest, as a share of the alpha.
uniform float waver : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	// `COLOR` is the art times the sprite's tints. The art's alpha is 0 or 1,
	// so here it is the presence inside the shade and nothing outside it.
	float presence = COLOR.a;
	if (presence <= 0.0) {
		discard;
	}
	float row = floor(UV.y / TEXTURE_PIXEL_SIZE.y);
	float drift = waver * (1.0 - presence) * sin(TIME * 2.6 + row * 0.7);
	COLOR.a = clamp(presence + drift, 0.0, 1.0);
}
