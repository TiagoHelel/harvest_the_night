# -*- coding: utf-8 -*-
"""The one palette. Every pixel in the game is a colour from this file.

Sampled from `docs/reference-sheet.png`: warm greens and browns, a cool blue
pond, and a red roof that is the landmark of the whole farm.

**One table, not one per sprite.** A tileset drawn against one green and a
character drawn against another look like two games stapled together, and the
difference is invisible until somebody puts them side by side. Anything that
needs a colour asks here.

The two ramps at the bottom are how `design.md` section 18 gets its two
realities out of one set of sprites: the same pixels, relit. Task 0071 applies
them; they are named here because they are part of the palette, not part of the
shader.
"""

# ---------------------------------------------------------------- the colours

COLOURS = {
    # The line around things. One ink, everywhere, so nothing looks cut out.
    "ink":          (0x24, 0x1f, 0x2e),
    "ink_soft":     (0x3a, 0x33, 0x45),

    # Grass, and the field it surrounds.
    "grass_dark":   (0x4e, 0x7a, 0x35),
    "grass":        (0x6a, 0x96, 0x46),
    "grass_light":  (0x8a, 0xb6, 0x59),

    # Tilled soil. Darker when it has been watered.
    "soil_dark":    (0x5c, 0x42, 0x2a),
    "soil":         (0x7a, 0x58, 0x38),
    "soil_light":   (0x96, 0x70, 0x4a),

    # The pond.
    "water_dark":   (0x2b, 0x54, 0x80),
    "water":        (0x3a, 0x6e, 0xa5),
    "water_light":  (0x5a, 0x8c, 0xc0),

    # The rock face, and anything built out of it.
    "stone_dark":   (0x52, 0x50, 0x5c),
    "stone":        (0x6e, 0x6c, 0x78),
    "stone_light":  (0x8c, 0x8a, 0x96),

    # Cut timber: fences, jetties, floors, the workshop.
    "wood_dark":    (0x6b, 0x4a, 0x2c),
    "wood":         (0x8c, 0x62, 0x39),
    "wood_light":   (0xa8, 0x7c, 0x4e),

    # Living wood: the canopy.
    "leaf_dark":    (0x1d, 0x40, 0x24),
    "leaf":         (0x2e, 0x5e, 0x34),
    "leaf_light":   (0x46, 0x80, 0x4a),

    # The farmhouse roof - the landmark, and the warmest thing on the farm.
    "roof_dark":    (0x8a, 0x2f, 0x2a),
    "roof":         (0xb0, 0x42, 0x3a),
    "roof_light":   (0xc9, 0x63, 0x5a),

    # Ore, coin, and lamplight.
    "gold_dark":    (0xa8, 0x74, 0x2c),
    "gold":         (0xc4, 0x96, 0x46),
    "gold_light":   (0xd6, 0xba, 0x60),

    # Fire.
    "flame":        (0xf2, 0xa0, 0x3c),
    "flame_hot":    (0xf6, 0xd9, 0x7a),

    # Cloth, bone, paper, the moon.
    "bone":         (0xe8, 0xe0, 0xcf),
    "bone_dark":    (0xb8, 0xae, 0x9a),

    # Sprite-loop 0001: the farmer's face and blue overalls need their own
    # short ramps. Keep existing material colours unchanged; these are shared
    # art colours, not simulation/balance data.
    "skin_dark":    (0xb5, 0x6b, 0x4b),
    "skin":         (0xe4, 0x9b, 0x68),
    "skin_light":   (0xf3, 0xc5, 0x8d),
    "cloth_dark":   (0x20, 0x38, 0x59),
    "cloth":        (0x31, 0x5a, 0x8c),
    "cloth_light":  (0x4e, 0x7f, 0xb1),

    # Night sky and the shadows under it.
    "night":        (0x1a, 0x18, 0x30),
    "night_light":  (0x2e, 0x2a, 0x4e),
    "moon":         (0xcf, 0xd6, 0xff),

    # What a zombie is made of.
    "rot_dark":     (0x35, 0x50, 0x38),
    "rot":          (0x55, 0x76, 0x52),
    "blood":        (0x8e, 0x2b, 0x33),
}

# A pixel that is not there. `.` in every map.
TRANSPARENT = None


# ------------------------------------------------------------------ the ramps

# **Day**: the sprites as drawn, warm and a little brighter than neutral.
# **Night**: the same pixels pushed towards the blue of `night`, with the warm
# fire/window cores supplied by semantic emission layers above the ramp.
# Material brightness alone never makes clothes, skin or crops emissive.
#
# Applied by task 0071 as a shader, so it costs nothing per sprite and can be
# tuned without regenerating a single PNG.
RAMPS = {
    # Noon: the light the farm was drawn under, and the one everything else
    # is measured against.
    "day": {
        "tint":       (1.02, 1.00, 0.96),
        "lift":       (0.00, 0.00, 0.00),
        "saturation": 1.00,
        # Nothing is exempt from daylight, because daylight exempts nothing.
        # 1.0 is "no pixel is brighter than this", which switches the whole
        # warm-keep branch off without the shader needing a flag for it.
        "warm_keep":  1.00,
        "warm_edge":  0.06,
    },
    # **Morning and evening, either side of it.** `design.md` asks for light
    # that warms and then cools across a day, and a farm lit identically from
    # the first tick to the last is a farm where time is a number in a corner.
    # Both are gentle on purpose: this is a cozy half, and a dawn you have to
    # squint through would be a reason to skip it.
    "dawn": {
        "tint":       (0.92, 0.90, 1.02),
        "lift":       (0.02, 0.02, 0.05),
        "saturation": 0.92,
        "warm_keep":  1.00,
        "warm_edge":  0.06,
    },
    "dusk": {
        "tint":       (1.06, 0.88, 0.80),
        "lift":       (0.05, 0.02, 0.00),
        "saturation": 0.95,
        # Evening warmth comes from the tint, not a material exemption.
        "warm_keep":  1.00,
        "warm_edge":  0.06,
    },
    "night": {
        # Green is pulled down hardest. A farm is mostly grass, and a tint that
        # kept green anywhere near blue left the night reading as a dim
        # afternoon rather than as another world.
        #
        # **This is as far as a multiply goes**, and task 0071 is where the
        # rest arrives: the reference sheet's night is *lifted* towards purple
        # and *drained* of colour, and neither is something a multiply can do.
        # `src/ui/relight.gdshader` applies the three below.
        #
        # The three below were tuned against the sheet with a screenshot next
        # to it. The first attempt lifted to (0.10, 0.07, 0.20) and drained to
        # 0.62, and the farm came out **flat**: one mid-purple with the grass,
        # the paths and the jetty all the same value. The sheet's night is not
        # washed out, it is *dark with deep shadows* - so the lift came down
        # until black went back to being nearly black, and the saturation came
        # up until the grass was recognisably grass again.
        #
        # A shade darker than a readable night wants, on purpose. Task 0076
        # hangs real lights on the windows, the braziers and the muzzle
        # flashes, and every one of those *adds* brightness - so a global ramp
        # tuned to read well on its own would be washed out the moment they
        # arrive. The sheet's night is dark with bright things in it, and this
        # is the dark half of that.
        "tint":       (0.36, 0.40, 0.82),
        "lift":       (0.04, 0.035, 0.105),
        "saturation": 0.76,
        # Disable the legacy global brightness exemption. Actual crops,
        # hats and skin share bone/flame_hot with lamps, so colour cannot
        # identify an emitter. Only semantic fire forms/sparks and measured
        # glass cores preserve warm pixels above the ambient shader.
        "warm_keep":  1.00,
        # Retained for the shared ramp/transition interface; inactive at 1.
        "warm_edge":  0.06,
    },
    # **A Full Moon night** (task 0152): the same night, seen further into.
    # The tint keeps the night's shape - green held down, blue on top - and
    # comes up about a third, the lift goes a little more silver than purple,
    # and the colour drains a touch more, because moonlight is bright and
    # grey rather than bright and coloured. Still dark enough that the
    # windows, the braziers and the muzzle flashes are the bright things.
    "full_moon": {
        "tint":       (0.48, 0.54, 0.92),
        "lift":       (0.06, 0.06, 0.12),
        "saturation": 0.70,
        "warm_keep":  1.00,
        "warm_edge":  0.06,
    },
}


def rgb(name):
    """A colour by name. An unknown name is a mistake, not a default."""
    if name not in COLOURS:
        raise KeyError("no colour called %r - see tools/palette.py" % name)
    return COLOURS[name]


def rgba(name, alpha=255):
    if name is None:
        return (0, 0, 0, 0)
    r, g, b = rgb(name)
    return (r, g, b, alpha)
