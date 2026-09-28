# -*- coding: utf-8 -*-
"""Every sprite in the game, as a picture you can read in a text editor.

A sprite is a legend and a list of rows. Each character is one pixel; `.` is
transparent. The legend maps a character to a colour name in `tools/palette.py`
- never to a literal colour, so that changing the game's green is one edit in
one file rather than a search through forty maps.

**This is the source.** There are no hand-authored PNGs in this repository and
there must not be: `tools/gen_sprites.py` turns what is below into
`sprites/**.png`, and a PNG that did not come from here has no way to follow the
palette when the palette moves.

Sizes are checked by the generator, so a row typed one character short is a
message rather than a sprite that is subtly wrong down one edge.

    16x16   tiles and props
    16x24   actors - the extra eight pixels are head-room above the tile they
            stand on, which is what makes a three-quarter view read
"""

# 16x16 unless a sprite says otherwise.
TILE = (16, 16)
ACTOR = (16, 24)


SPRITES = {

    # ------------------------------------------------- terrain, task 0072

    # **Three more grasses, so a field is not one tile repeated.** A farm is
    # mostly grass and the eye finds a 16-pixel grid in a flat one within a
    # second. The specks move; the green does not, so four of these side by
    # side still read as one meadow rather than as four patches.
    "terrain/grass_b": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark", "l": "grass_light",
    }, rows=[
        "gggggggglgggggdg",
        "gggggggggggggggg",
        "gdgggggggggggggg",
        "gggggggggggglggg",
        "ggggglgggggggggg",
        "gggggggggggggggg",
        "ggggggggdggggggg",
        "gdgggggggggggglg",
        "gggggggggggggggg",
        "gggglggggggggggg",
        "gggggggggdgggggg",
        "gggggggggggggggg",
        "gglgggggggggdggg",
        "gggggggggggggggg",
        "ggggggdggggggggg",
        "ggggggggggglgggg",
    ]),
    "terrain/grass_c": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark", "l": "grass_light",
    }, rows=[
        "gggggggggggggggg",
        "gglggggggdgggggg",
        "gggggggggggggggg",
        "ggggggggggggggdg",
        "gdgggggglggggggg",
        "gggggggggggggggg",
        "ggggggggggggglgg",
        "gggggggggggggggg",
        "ggglgggdgggggggg",
        "gggggggggggggggg",
        "ggggggggggggggdg",
        "glgggggggggggggg",
        "gggggggggggggggg",
        "gggggdgggglggggg",
        "gggggggggggggggg",
        "ggggggggdggggggg",
    ]),
    # This one carries a flower, which is the only thing on the farm that is
    # there for no reason at all. One tile in a few dozen: enough to notice on
    # a second look and not enough to read as a crop somebody forgot.
    "terrain/grass_d": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark", "l": "grass_light",
        "f": "gold_light", "s": "grass_dark",
    }, rows=[
        "gggggggggggggggg",
        "ggggdggggggggggg",
        "gggggggggggglggg",
        "gggggggggggggggg",
        "ggggggggggggggdg",
        "gglggggggggggggg",
        "gggggggggggggggg",
        "ggggggggggdggggg",
        "gggffggggggggggg",
        "gggfsgggggggglgg",
        "ggggsggggggggggg",
        "gdggsggggggggggg",
        "gggggggggggggggg",
        "ggggggggglggggdg",
        "gggggggggggggggg",
        "ggggdggggggggggg",
    ]),

    # **Two more water frames.** A pond that never moves is a painted pond.
    # The ripples shift by a pixel or two and nothing else does, so the
    # animation reads as water rather than as a flicker.
    "terrain/water_b": dict(size=TILE, legend={
        "w": "water", "d": "water_dark", "l": "water_light",
    }, rows=[
        "wwwwwwwwwwwwwwww",
        "wwwwwlwwwwwwwwww",
        "wwwwwwwwwwwwdwww",
        "wwwwwwwwwwwwwwww",
        "wwdwwwwwwwwwwwww",
        "wwwwwwwwwlwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwwwwlw",
        "wwwwwwwdwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wlwwwwwwwwwwwwww",
        "wwwwwwwwwwwdwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwlwwwwwwww",
        "wwwdwwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
    ]),
    "terrain/water_c": dict(size=TILE, legend={
        "w": "water", "d": "water_dark", "l": "water_light",
    }, rows=[
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwlwwww",
        "wdwwwwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwwwdww",
        "wwwwlwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwdwwwww",
        "wwwwwwwwwwwwwwww",
        "wwlwwwwwwwwwwwww",
        "wwwwwwwwwwwwwwlw",
        "wwwwwwwdwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwlwwwwdwwwww",
        "wwwwwwwwwwwwwwww",
    ]),

    # **The four sides of an edge, from which sixteen are built.**
    #
    # Autotiling normally means drawing a forty-seven tile blob set by hand.
    # These are four, and `gen_sprites.py` composites them: a cell with grass
    # to the north and the west gets `edge_n` and `edge_w` laid over each
    # other, which is a corner without anyone drawing a corner. Sixteen
    # combinations, four maps, and a fifth side is a fifth map rather than a
    # new twenty-three.
    #
    # They are grass encroaching *into* the cell, so they are drawn on the
    # soil, path, rock or floor tile that meets grass - the patch has a soft
    # edge and the meadow does not have a hole cut in it.
    "terrain/edge_n": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark",
    }, rows=[
        "gggggggggggggggg",
        "gggggggggggggggg",
        "ddgd.ddg.dd.gddd",
        "..g...d...g..d..",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),
    "terrain/edge_s": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark",
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "..d...g...d..g..",
        "gdd.gddd.gg.dddg",
        "gggggggggggggggg",
        "gggggggggggggggg",
    ]),
    "terrain/edge_w": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark",
    }, rows=[
        "ggd.............",
        "ggdg............",
        "ggd.............",
        "ggg.............",
        "ggdd............",
        "ggd.............",
        "gggg............",
        "ggd.............",
        "ggdg............",
        "ggd.............",
        "ggg.............",
        "ggdd............",
        "ggd.............",
        "gggg............",
        "ggd.............",
        "ggdg............",
    ]),
    "terrain/edge_e": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark",
    }, rows=[
        ".............dgg",
        "............gdgg",
        ".............dgg",
        ".............ggg",
        "............ddgg",
        ".............dgg",
        "............gggg",
        ".............dgg",
        "............gdgg",
        ".............dgg",
        ".............ggg",
        "............ddgg",
        ".............dgg",
        "............gggg",
        ".............dgg",
        "............gdgg",
    ]),

    # **The shoreline**, on the water side. Pale where the water meets
    # anything that is not water, which is what a bank looks like from above
    # and what stops the pond reading as a hole cut in the farm.
    "terrain/shore_n": dict(size=TILE, legend={
        "l": "water_light", "w": "water",
    }, rows=[
        "llllllllllllllll",
        "lwllwlllwlllwlll",
        "..l...w...l...w.",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),
    "terrain/shore_s": dict(size=TILE, legend={
        "l": "water_light", "w": "water",
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "...w...l...w...l",
        "lwllwlllwlllwlll",
        "llllllllllllllll",
    ]),
    "terrain/shore_w": dict(size=TILE, legend={
        "l": "water_light", "w": "water",
    }, rows=[
        "ll..............",
        "llw.............",
        "ll..............",
        "lll.............",
        "ll..............",
        "llw.............",
        "ll..............",
        "lll.............",
        "ll..............",
        "llw.............",
        "ll..............",
        "lll.............",
        "ll..............",
        "llw.............",
        "ll..............",
        "lll.............",
    ]),
    "terrain/shore_e": dict(size=TILE, legend={
        "l": "water_light", "w": "water",
    }, rows=[
        "..............ll",
        ".............wll",
        "..............ll",
        ".............lll",
        "..............ll",
        ".............wll",
        "..............ll",
        ".............lll",
        "..............ll",
        ".............wll",
        "..............ll",
        ".............lll",
        "..............ll",
        ".............wll",
        "..............ll",
        ".............lll",
    ]),

    # ------------------------------------------------------------- terrain

    # Grass with enough specks to stop a field of it looking like paper, and
    # not so many that a tower placed on it stops being the thing you look at.
    "terrain/grass": dict(size=TILE, legend={
        "g": "grass", "d": "grass_dark", "l": "grass_light",
    }, rows=[
        "gggggggggggggggg",
        "gggdggggggggglgg",
        "gggggggggggggggg",
        "gdggggggggglgggg",
        "gggggggggggggggg",
        "ggggggdggggggggg",
        "gglgggggggggggdg",
        "gggggggggggggggg",
        "gggggggggglggggg",
        "ggdggggggggggggg",
        "gggggggggggggggg",
        "gggggglgggdggggg",
        "gggggggggggggggg",
        "gdgggggggggggggg",
        "gggggggggggggglg",
        "gggggggggggggggg",
    ]),

    # Tilled earth. The furrows run across, so a planted field reads as rows
    # rather than as a brown rectangle.
    "terrain/soil": dict(size=TILE, legend={
        "s": "soil", "d": "soil_dark", "l": "soil_light",
    }, rows=[
        "ssssssssssssssss",
        "llllllllllllllll",
        "ssssssssssssssss",
        "dddddddddddddddd",
        "ssssssssssssssss",
        "llllllllllllllll",
        "ssssssssssssssss",
        "dddddddddddddddd",
        "ssssssssssssssss",
        "llllllllllllllll",
        "ssssssssssssssss",
        "dddddddddddddddd",
        "ssssssssssssssss",
        "llllllllllllllll",
        "ssssssssssssssss",
        "dddddddddddddddd",
    ]),

    # The pond. Two frames of this animate at task 0072; one is enough to see
    # that the ripples are the readable part.
    "terrain/water": dict(size=TILE, legend={
        "w": "water", "d": "water_dark", "l": "water_light",
    }, rows=[
        "wwwwwwwwwwwwwwww",
        "wwlllwwwwwwwwwww",
        "wwwwwwwwwwlllwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwdddwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wlllwwwwwwwwwwww",
        "wwwwwwwwwwwwwwdd",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwlllwwwww",
        "wwwwwwwwwwwwwwww",
        "wwdddwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwlllww",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwwwwww",
    ]),

    # The rock face. Blocky on purpose: it should read as something you mine
    # rather than something you walk on.
    "terrain/rock": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
    }, rows=[
        "llllllltddddddtl",
        "lttttttttttttttd",
        "ltttttttttttttdd",
        "lttttdttttttttdd",
        "dddddddttttttttd",
        "ltttttdttttttttd",
        "ltttttdtttdddddd",
        "ltttttdtttttttdd",
        "ltttttdtttttttdd",
        "lddddddddtttttdd",
        "lttttttttdttttdd",
        "lttttttttdttttdd",
        "lttttttttdttttdd",
        "lttttttttdttttdd",
        "ltttttttttttttdd",
        "dddddddddddddddd",
    ]),

    # A trodden path. Pale dirt with the stones that come up through it.
    "terrain/path": dict(size=TILE, legend={
        "p": "soil_light", "d": "soil", "k": "bone_dark",
    }, rows=[
        "pppppppppppppppp",
        "ppppkppppppppppp",
        "pppppppppppdpppp",
        "ppppppppppppppkp",
        "ppdppppppppppppp",
        "pppppppkpppppppp",
        "pppppppppppppppp",
        "ppppppppppdppppp",
        "pkpppppppppppppp",
        "pppppppppppppppp",
        "ppppppdpppppkppp",
        "pppppppppppppppp",
        "ppppppppppppppdp",
        "ppkppppppppppppp",
        "pppppppppppppppp",
        "pppppppppppppppp",
    ]),

    # Board floor: the jetty, the porch, the inside of anything built.
    "terrain/floor": dict(size=TILE, legend={
        "w": "wood", "d": "wood_dark", "l": "wood_light",
    }, rows=[
        "wwwwwwwwwwwwwwww",
        "wwwlwwwwwwwwwwww",
        "wwwwwwwwwwwlwwww",
        "dddddddddddddddd",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwlwwwwwwww",
        "wlwwwwwwwwwwwwww",
        "dddddddddddddddd",
        "wwwwwwwwwwwwwwww",
        "wwwwwwwwwwwlwwww",
        "wwwlwwwwwwwwwwww",
        "dddddddddddddddd",
        "wwwwwwwwwwwwwwww",
        "wwwwwlwwwwwwwwww",
        "wwwwwwwwwwwwwlww",
        "dddddddddddddddd",
    ]),

    # ----------------------------------------------------------------- crops

    # Wet earth. The same furrows as `crops/tilled`, darker and without the
    # dry crumb, so a watered row reads from across the farm - which is the
    # whole point of a chore you do a row at a time.
    "crops/tilled_wet": dict(size=TILE, legend={
        "d": "soil_dark", "s": "soil", "i": "ink", ".": None,
    }, rows=[
        "iiiiiiiiiiiiiiii",
        "iddiddiddiddiddi",
        "iddiddiddiddiddi",
        "iiiiiiiiiiiiiiii",
        "ddiddiddiddiddid",
        "ddiddiddiddiddid",
        "iiiiiiiiiiiiiiii",
        "iddiddiddiddiddi",
        "iddiddiddiddiddi",
        "iiiiiiiiiiiiiiii",
        "ddiddiddiddiddid",
        "ddiddiddiddiddid",
        "iiiiiiiiiiiiiiii",
        "iddiddiddiddiddi",
        "iddiddiddiddiddi",
        "iiiiiiiiiiiiiiii",
    ]),

    # Corn, just in. Two mounds rather than wheat's four: corn is planted
    # wide, and it is the silhouette that has to say which crop this is from
    # the other side of the field.
    "crops/corn_0": dict(size=TILE, legend={
        "d": "soil_dark", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "....dd....dd....",
        "...dddd..dddd...",
        "....dd....dd....",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Sprouted: a single blade each, already taller than wheat at the same
    # stage.
    "crops/corn_1": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "...l.......l....",
        "...gl......gl...",
        "....g.......g...",
        "....g.......g...",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Full stalks, leaves out, no cobs yet.
    "crops/corn_2": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", "L": "leaf_light", ".": None,
    }, rows=[
        "................",
        "....L.......L...",
        "...Lg......Lg...",
        "..LlgL....LlgL..",
        "...lgl.....lgl..",
        "..Llgl....Llgl..",
        "...lgl.....lgl..",
        "....g.......g...",
        "....g.......g...",
        "....g.......g...",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Ready: the cob is gold and it is on the outside, where it can be seen.
    "crops/corn_3": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", "L": "leaf_light",
        "c": "gold", "C": "gold_light", ".": None,
    }, rows=[
        "................",
        "....L.......L...",
        "...Lg.C....Lg.C.",
        "..LlgLCC..LlgLCC",
        "...lglCc...lglCc",
        "..LlglCc..LlglCc",
        "...lgl.c...lgl.c",
        "....g.......g...",
        "....g.......g...",
        "....g.......g...",
        "....g.......g...",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Carrot, just in. Four small mounds, close together - carrot is the
    # crowded crop, which is part of why it pays per plot.
    "crops/carrot_0": dict(size=TILE, legend={
        "d": "soil_dark", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "..dd..dd..dd....",
        "..dd..dd..dd....",
        "................",
        "................",
        "................",
        "..dd..dd..dd....",
        "..dd..dd..dd....",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Sprouted: feathery tops, low to the ground.
    "crops/carrot_1": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", ".": None,
    }, rows=[
        "................",
        "................",
        "..l....l....l...",
        "..gl...gl...gl..",
        "..g....g....g...",
        "................",
        "................",
        "................",
        "..l....l....l...",
        "..gl...gl...gl..",
        "..g....g....g...",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Tops out, nothing showing above the soil yet.
    "crops/carrot_2": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", "L": "leaf_light", ".": None,
    }, rows=[
        "................",
        "..L.l..L.l..L.l.",
        ".lLgl.lLgl.lLgl.",
        "..lgl..lgl..lgl.",
        "..ggg..ggg..ggg.",
        "................",
        "................",
        "..L.l..L.l..L.l.",
        ".lLgl.lLgl.lLgl.",
        "..lgl..lgl..lgl.",
        "..ggg..ggg..ggg.",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Ready: the orange shoulder is up out of the ground. That is the whole
    # read - a field of carrots goes from green to orange the moment it can
    # be pulled.
    "crops/carrot_3": dict(size=TILE, legend={
        "g": "leaf_dark", "l": "leaf", "L": "leaf_light",
        "o": "flame", "d": "gold_dark", ".": None,
    }, rows=[
        "................",
        "..L.l..L.l..L.l.",
        ".lLgl.lLgl.lLgl.",
        "..lgl..lgl..lgl.",
        "..ooo..ooo..ooo.",
        "..odo..odo..odo.",
        "................",
        "..L.l..L.l..L.l.",
        ".lLgl.lLgl.lLgl.",
        "..lgl..lgl..lgl.",
        "..ooo..ooo..ooo.",
        "..odo..odo..odo.",
        "................",
        "................",
        "................",
        "................",
    ]),


    # Turned earth waiting for a seed. Darker and rougher than the field it
    # sits on, so a tilled row reads from across the farm.
    "crops/tilled": dict(size=TILE, legend={
        "d": "soil_dark", "s": "soil", "i": "ink", ".": None,
    }, rows=[
        "dddddddddddddddd",
        "dssdssdssdssdssd",
        "dssdssdssdssdssd",
        "dddddddddddddddd",
        "ssdssdssdssdssds",
        "ssdssdssdssdssds",
        "dddddddddddddddd",
        "dssdssdssdssdssd",
        "dssdssdssdssdssd",
        "dddddddddddddddd",
        "ssdssdssdssdssds",
        "ssdssdssdssdssds",
        "dddddddddddddddd",
        "dssdssdssdssdssd",
        "dssdssdssdssdssd",
        "dddddddddddddddd",
    ]),

    # Wheat, just in. Four seed mounds and nothing showing.
    "crops/wheat_0": dict(size=TILE, legend={
        "d": "soil_dark", "g": "grass_dark", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "...dd......dd...",
        "..dddd....dddd..",
        "...dd......dd...",
        "................",
        "................",
        "................",
        "...dd......dd...",
        "..dddd....dddd..",
        "...dd......dd...",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Sprouted.
    "crops/wheat_1": dict(size=TILE, legend={
        "g": "grass_dark", "l": "grass", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "....g......g....",
        "...glg....glg...",
        "....g......g....",
        "................",
        "................",
        "................",
        "....g......g....",
        "...glg....glg...",
        "....g......g....",
        "................",
        "................",
        "................",
        "................",
    ]),

    # Growing: taller, still green.
    "crops/wheat_2": dict(size=TILE, legend={
        "g": "grass_dark", "l": "grass", "L": "grass_light", ".": None,
    }, rows=[
        "................",
        "................",
        "....L......L....",
        "...gLg....gLg...",
        "...glg....glg...",
        "...glg....glg...",
        "....g......g....",
        "................",
        "....L......L....",
        "...gLg....gLg...",
        "...glg....glg...",
        "...glg....glg...",
        "....g......g....",
        "................",
        "................",
        "................",
    ]),

    # Ready: heavy ears, gold rather than green.
    "crops/wheat_3": dict(size=TILE, legend={
        "g": "gold_dark", "l": "gold", "L": "gold_light",
        "s": "grass_dark", ".": None,
    }, rows=[
        "................",
        "...L.L....L.L...",
        "..LlLlL..LlLlL..",
        "..LlllL..LlllL..",
        "...glg....glg...",
        "...sgs....sgs...",
        "....s......s....",
        "................",
        "...L.L....L.L...",
        "..LlLlL..LlLlL..",
        "..LlllL..LlllL..",
        "...glg....glg...",
        "...sgs....sgs...",
        "....s......s....",
        "................",
        "................",
    ]),

    # ---------------------------------------------------------------- props

    # The well. Stone ring, a roof on two posts and water down the shaft - the
    # only water north of the pond, and it has to read as water from a screen
    # away or nobody will walk to it.
    "props/well": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "r": "roof", "R": "roof_light", "w": "wood_dark",
        "a": "water", "A": "water_light", "i": "ink", ".": None,
    }, rows=[
        "......iiii......",
        "....iiRRRRii....",
        "...iRRrrrrRRi...",
        "..iRrrrrrrrrRi..",
        ".irrrrrrrrrrrri.",
        "iiiiiwiiiiwiiiii",
        "....iwi..iwi....",
        "....iwi..iwi....",
        "...iltiiiitli...",
        "..iltaAAAAatli..",
        "..itaaAAAAaati..",
        "..itaaaaaaaati..",
        "..idttttttttdi..",
        "..iddddddddddi..",
        "...iiiiiiiiii...",
        "................",
    ]),

    # The oil press, in four quarters. Two by two: a stone base, a timber
    # frame and a screw coming down on the hopper. Corn goes in the top and
    # oil comes out of the spout at the bottom right, which is the only part
    # of it a player has to read.
    "props/press_0_0": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "....iiiiiiiiiiii",
        "...iwwwwwwwwwwww",
        "...iwlllllllllll",
        "...iwlWWWWWWWWWW",
        "...iwlWWWWWWWWWW",
        "...iwwWWWWWWWWWW",
        "...iiiiiiiiiiiii",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli.........",
        "...iwli..iiiiiii",
    ]),
    "props/press_1_0": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "iiiiiiiiiiii....",
        "wwwwwwwwwwwwi...",
        "lllllllllllwi...",
        "WWWWWWWWWWlwi...",
        "WWWWWWWWWWlwi...",
        "WWWWWWWWWWwwi...",
        "iiiiiiiiiiiii...",
        "...iiii..ilwi...",
        "..itttti.ilwi...",
        "..itlllti.lwi...",
        "..itttti.ilwi...",
        "...itti..ilwi...",
        "...itti..ilwi...",
        "...itti..ilwi...",
        "..iitti..ilwi...",
        "iiitttiiiilwi...",
    ]),
    "props/press_0_1": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "...iwli..iWWWWWW",
        "...iwli..iWlllll",
        "...iwwiiiiWlWWWW",
        "...iiiiiiiWlWWWW",
        "..iittttttlWWWWW",
        "..itlllllllWWWWW",
        "..itlttttttttttt",
        "..itlttttttttttt",
        "..itlttttttttttt",
        "..itlttttttttttt",
        "..itdttttttttttt",
        "..itddtttttttttt",
        "..itdddddddddddd",
        "..iddddddddddddd",
        "..iidddddddddddd",
        "...iiiiiiiiiiiii",
    ]),
    "props/press_1_1": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "WWWWWWWWWilwi...",
        "lllllllWWilwi...",
        "WWWWWWlWWiiwwi..",
        "WWWWWWlWWiiiiii.",
        "WWWWWWlWWtttttii",
        "WWWWWWlWWlllllti",
        "ttttttttttttttti",
        "tttttttttttttdti",
        "tttttttttttttdti",
        "ttttttttttttddti",
        "tttttttttttdddti",
        "ttttttttttddddti",
        "dddddddddddddgti",
        "dddddddddddddogi",
        "ddddddddddddiooi",
        "iiiiiiiiiiiii.i.",
    ]),

    # The generator, in four quarters. A stone housing with a burner
    # glowing in the middle of it, a stack on top and a cable running
    # off to the right - the burner is the part that has to read,
    # because a generator with no oil is a generator that is not lit.
    "props/generator_0_0": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "O": "flame_hot", "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "................",
        "...........iiii.",
        "..........iddddi",
        "..........idlldi",
        "..........idlldi",
        "....iiiiiiidlldi",
        "...iwwwwwwwwwwww",
        "...iwlllllllllll",
        "...iwlWWWWWWWWWW",
        "...iwlWttttttttt",
        "...iwlWtdddddddd",
        "...iwlWtdlllllll",
        "...iwlWtdltttttt",
        "...iwlWtdltooooo",
        "...iwlWtdltoOOOO",
        "...iwlWtdltoOOOO",
    ]),
    "props/generator_1_0": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "O": "flame_hot", "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "................",
        "iiiiiiii........",
        "wwwwwwwwi.......",
        "lllllllwi.......",
        "WWWWWWlwi.......",
        "ttttttlwi.......",
        "ddddttlwi.......",
        "llldttlwi.......",
        "tttdttlwi.......",
        "oltdttlwi.......",
        "oltdttlwi.......",
        "oltdttlwi.......",
    ]),
    "props/generator_0_1": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "O": "flame_hot", "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "...iwlWtdltoOOOO",
        "...iwlWtdltooooo",
        "...iwlWtdltttttt",
        "...iwlWtddllllll",
        "...iwlWttddddddd",
        "...iwlWttttttttt",
        "...iwlWWWWWWWWWW",
        "...iwlllllllllll",
        "...iwwwwwwwwwwww",
        "...iiiiiiiiiiiii",
        "...idddddddddddd",
        "...idlllllllllll",
        "...idltttttttttt",
        "...idddddddddddd",
        "....iiiiiiiiiiii",
        "................",
    ]),
    "props/generator_1_1": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "w": "wood_dark", "W": "wood", "o": "flame",
        "O": "flame_hot", "g": "gold_dark", "i": "ink", ".": None,
    }, rows=[
        "oltdttlwi.......",
        "oltdttlwi.......",
        "ttldttlwi.......",
        "lldttlwiii......",
        "dddttlwiggi.....",
        "ttttlwiigogi....",
        "WWWWlwiigogi....",
        "lllllwiigogi....",
        "wwwwwwiigogi....",
        "iiiiiiiigogi....",
        "ddddddiigogi....",
        "lllllditgogi....",
        "ttttldiigogi....",
        "ddddddiiggi.....",
        "iiiiii..ii......",
        "................",
    ]),

    # The cow from the reference sheet: white with black patches, side on,
    # head to the left. Sixteen pixels is not much of a cow, so the read is
    # the silhouette and the patches, not the face.
    "props/cow": dict(size=TILE, legend={
        "b": "bone", "d": "bone_dark", "k": "ink_soft", "i": "ink",
        "r": "roof_light", ".": None,
    }, rows=[
        "................",
        "................",
        "..ii........ii..",
        ".ikki......ikki.",
        ".ikkkiiiiiikkki.",
        "ibbbkkkkkkkkbbbi",
        "iribbkkkkkkbbbbi",
        "iibbbbbbbbkkkbbi",
        ".ibkkkbbbbkkkbbi",
        ".ibkkkbbbbbbbbi.",
        ".ibbbbbbbbbbbbi.",
        "..iiiiiiiiiiii..",
        "..ii.ii..ii.ii..",
        "..ik.ik..ik.ik..",
        "..ii.ii..ii.ii..",
        "................",
    ]),

    # A chicken. Smaller, rounder, a red comb and a gold beak - the two bits
    # of colour are what tell it apart from a rock at this size.
    "props/chicken": dict(size=TILE, legend={
        "b": "bone", "d": "bone_dark", "i": "ink",
        "r": "roof", "g": "gold_light", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        ".....irri.......",
        "....ibbbi.......",
        "...igbibi.......",
        "...ibbbbiiii....",
        "....ibbbbbbdi...",
        "....ibbbbbbbdi..",
        "....ibbbbbbbdi..",
        "....idbbbbbddi..",
        ".....iiddddii...",
        "......ii..ii....",
        "......ig..ig....",
        "......ii..ii....",
        "................",
    ]),

    # A tree. The canopy overhangs the trunk, so a row of them reads as a wood
    # rather than as lollipops.
    "props/tree": dict(size=TILE, legend={
        "L": "leaf_light", "l": "leaf", "d": "leaf_dark",
        "w": "wood_dark", "W": "wood", "i": "ink", ".": None,
    }, rows=[
        "......iiii......",
        "....iilLLlii....",
        "...ilLLLLLLli...",
        "..ilLLLlLLLLli..",
        ".idlLLlllLLLLdi.",
        ".idLLlllllLLLdi.",
        "idLLlllddlllLLdi",
        "idLlllddddlllLdi",
        "idlllddddddllldi",
        ".idllddddddlldi.",
        "..iddlddddlddi..",
        "...iidddddii....",
        ".....iWwWi......",
        ".....iWwWi......",
        ".....iWwwi......",
        "....iiwwwii.....",
    ]),

    # A loose boulder. Something you break for stone and then it is gone.
    "props/rock": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "i": "ink", ".": None,
    }, rows=[
        "................",
        "................",
        "......iiii......",
        "....iilllti.....",
        "...illlltttii...",
        "..illlttttttti..",
        ".illltttttttdti.",
        ".ilttttttttdddi.",
        ".itttttttddddti.",
        ".ittttddddddtti.",
        "..idttdddddtti..",
        "...iddddddtii...",
        "....iidddii.....",
        "......iiii......",
        "................",
        "................",
    ]),

    # A stone seam in the rock face: layered, so it reads as something cut out
    # of the cliff rather than a boulder someone left there.
    "props/seam": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "i": "ink", ".": None,
    }, rows=[
        "................",
        "..iiiiiiiiiiii..",
        ".illlllllllllti.",
        ".ilttttttttttti.",
        ".idddddddddddti.",
        ".iltttttttttlti.",
        ".ilttttttttttti.",
        ".iddddddddddddi.",
        ".iltttttttttlti.",
        ".ilttttttttttti.",
        ".idddddddddddti.",
        ".ilttttttttttti.",
        ".ilttttttttttti.",
        ".iddddddddddddi.",
        "..iiiiiiiiiiii..",
        "................",
    ]),

    # Iron ore in the rock face. The gold flecks are the whole point: it has to
    # be tellable from a boulder at a glance, because one is a tower and the
    # other is a wall.
    "props/ore": dict(size=TILE, legend={
        "t": "stone", "d": "stone_dark", "l": "stone_light",
        "g": "gold", "G": "gold_light", "i": "ink", ".": None,
    }, rows=[
        "................",
        ".....iiiii......",
        "...iilltttii....",
        "..illtgGgtttii..",
        ".illtggGgttttti.",
        ".ilttgGggtttdti.",
        ".ittttggttddddi.",
        ".itttttttdGgddi.",
        ".ittdttttdGggdi.",
        ".itdddttdddggdi.",
        "..iddgGgdddtti..",
        "...idggGgdtii...",
        "....iidggdii....",
        "......iiii......",
        "................",
        "................",
    ]),

    # The shop stall: a striped awning and a counter.
    "props/shop": dict(size=TILE, legend={
        "b": "bone", "r": "roof", "w": "wood", "d": "wood_dark",
        "l": "wood_light", "g": "gold_light", "i": "ink", ".": None,
    }, rows=[
        "................",
        "..iiiiiiiiiiii..",
        ".ibbrrbbrrbbrri.",
        ".ibbrrbbrrbbrri.",
        ".iiiiiiiiiiiiii.",
        "..i..........i..",
        "..i...gggg...i..",
        "..i..gggggg..i..",
        "..i...gggg...i..",
        "..i..........i..",
        ".illlllllllllli.",
        ".iwwwwwwwwwwwwi.",
        ".idwwwwwwwwwwdi.",
        ".id..........di.",
        ".id..........di.",
        "..i..........i..",
    ]),

    # What a felled tree leaves until it grows back. Low and pale, so a wood
    # half chopped reads at a glance as a wood half chopped.
    "props/stump": dict(size=TILE, legend={
        "w": "wood", "d": "wood_dark", "l": "wood_light",
        "i": "ink", ".": None,
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        ".....iiiiii.....",
        "....illlllli....",
        "...ilwwwwwwli...",
        "...idwwddwwdi...",
        "...idwwwwwwdi...",
        "....iddddddi....",
        ".....iiiiii.....",
    ]),

    # ---------------------------------------------------------------- actors

    # A placeholder body at actor size, to prove 16x24 works end to end. Task
    # 0073 replaces it with the farmer and their verbs.
    "actors/placeholder": dict(size=ACTOR, legend={
        "s": "bone", "h": "wood_dark", "c": "roof", "t": "wood",
        "i": "ink", ".": None,
    }, rows=[
        "................",
        "................",
        ".....iiiiii.....",
        "....ihhhhhhi....",
        "...ihhhhhhhhi...",
        "...ihssssssHi...".replace("H", "h"),
        "...isisssssi....",
        "...issssssi.....",
        "....isssssi.....",
        ".....iiiii......",
        "....icccci......",
        "...icccccci.....",
        "..icccccccci....",
        "..icccccccci....",
        "..icccccccci....",
        "...icccccci.....",
        "....icccci......",
        "....itiiti......",
        "....itiiti......",
        "....itiiti......",
        "....itiiti......",
        "...iitiitii.....",
        "...ihhiihhi.....",
        "....iiiiii......",
    ]),
}
