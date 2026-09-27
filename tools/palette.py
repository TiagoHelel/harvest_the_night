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
# end held back so that fire, lamps and the moon stay the only warm things on
# screen - which is what `design.md` section 18 asks for.
#
# Applied by task 0071 as a shader, so it costs nothing per sprite and can be
# tuned without regenerating a single PNG.
RAMPS = {
    "day": {
        "tint":       (1.02, 1.00, 0.96),
        "lift":       (0.00, 0.00, 0.00),
        "saturation": 1.00,
    },
    "night": {
        "tint":       (0.42, 0.48, 0.86),
        "lift":       (0.06, 0.05, 0.14),
        "saturation": 0.72,
        # Anything above this brightness keeps its own colour: firelight, a lit
        # window, the moon. Without it a night farm is evenly blue and dead.
        "warm_keep":  0.80,
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
