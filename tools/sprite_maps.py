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

    # ---------------------------------------------------- the UI kit, 0079

    # **Nine-slice, and the margin is five.** Every one of these is sixteen by
    # sixteen with a five pixel border and a middle that repeats, so one
    # drawing stretches to a tooltip, a shop panel or the whole tech tree.
    # `UiKit.MARGIN` is the same five on the other side; `headless_check`
    # asserts the two agree rather than trusting them to.

    "ui/panel": dict(size=TILE, legend={
        "k": "ink", "s": "ink_soft", "n": "night", "l": "night_light",
        "g": "gold_dark",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kggggggggggggggk",
        "kgllllllllllllgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kgllllllllllllgk",
        "kggggggggggggggk",
        "kkkkkkkkkkkkkkkk",
    ]),

    # The tooltip is the panel without the brass: quieter, because it appears
    # under the cursor and should not compete with what it is describing.
    "ui/tooltip": dict(size=TILE, legend={
        "k": "ink", "s": "ink_soft", "n": "night", "l": "night_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kssssssssssssssk",
        "kslllllllllllssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kslnnnnnnnnnlssk",
        "kssssssssssssssk",
        "kssssssssssssssk",
        "kkkkkkkkkkkkkkkk",
    ]),

    # **Four states, and they differ in value before they differ in hue.** A
    # player picks a button out at a glance by how light it is; a hover that
    # was only a different colour would be invisible to a good fraction of
    # people and to anybody on a bad screen.
    "ui/button_normal": dict(size=TILE, legend={
        "k": "ink", "s": "ink_soft", "n": "night_light", "l": "stone_dark",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kllllllllllllllk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kssssssssssssssk",
        "kssssssssssssssk",
        "kkkkkkkkkkkkkkkk",
    ]),

    "ui/button_hover": dict(size=TILE, legend={
        "k": "ink", "s": "stone_dark", "n": "stone", "l": "stone_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kllllllllllllllk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kllnnnnnnnnnnssk",
        "kssssssssssssssk",
        "kssssssssssssssk",
        "kkkkkkkkkkkkkkkk",
    ]),

    # Pressed is the same button lit from below instead of above, which is
    # what a pushed-in thing looks like.
    "ui/button_pressed": dict(size=TILE, legend={
        "k": "ink", "s": "gold_dark", "n": "gold", "l": "gold_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kssssssssssssssk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kssnnnnnnnnnnllk",
        "kllllllllllllllk",
        "kllllllllllllllk",
        "kkkkkkkkkkkkkkkk",
    ]),

    "ui/button_disabled": dict(size=TILE, legend={
        "k": "ink", "s": "ink_soft", "n": "ink_soft", "l": "night_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kllllllllllllllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllnnnnnnnnnnllk",
        "kllllllllllllllk",
        "kllllllllllllllk",
        "kkkkkkkkkkkkkkkk",
    ]),

    # A tab is a panel with its bottom edge open, so it reads as joined to
    # whatever is under it.
    "ui/tab": dict(size=TILE, legend={
        "k": "ink", "g": "gold_dark", "n": "night", "l": "night_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kggggggggggggggk",
        "kgllllllllllllgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kglnnnnnnnnnnlgk",
        "kgnnnnnnnnnnnngk",
    ]),

    "ui/slider_track": dict(size=(16, 8), legend={
        "k": "ink", "s": "ink_soft", "n": "night", "g": "gold_dark",
    }, rows=[
        "................",
        "................",
        "kkkkkkkkkkkkkkkk",
        "ksnnnnnnnnnnnnsk",
        "ksnnnnnnnnnnnnsk",
        "kkkkkkkkkkkkkkkk",
        "................",
        "................",
    ]),

    "ui/slider_grab": dict(size=(8, 8), legend={
        "k": "ink", "g": "gold", "d": "gold_dark", "l": "gold_light",
    }, rows=[
        "..kkkk..",
        ".klllgk.",
        "klggggdk",
        "klggggdk",
        "klggggdk",
        "klggggdk",
        ".kdddgk.",
        "..kkkk..",
    ]),

    "ui/checkbox_off": dict(size=(12, 12), legend={
        "k": "ink", "s": "ink_soft", "n": "night",
    }, rows=[
        "kkkkkkkkkkkk",
        "ksssssssssnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "kkkkkkkkkkkk",
    ]),

    "ui/checkbox_on": dict(size=(12, 12), legend={
        "k": "ink", "s": "ink_soft", "n": "night", "g": "gold_light",
    }, rows=[
        "kkkkkkkkkkkk",
        "ksssssssssnk",
        "ksnnnnnnngnk",
        "ksnnnnnnggnk",
        "ksnnnnnggnnk",
        "ksngnnggnnnk",
        "ksnggggnnnnk",
        "ksnnggnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "ksnnnnnnnnnk",
        "kkkkkkkkkkkk",
    ]),

    # ------------------------------------------------ resource icons, 0079

    # **Told apart at sixteen pixels without their labels**, which is the only
    # test task 0079 sets for these. So each one is a different *shape* before
    # it is a different colour: the log lies down, the stalk stands up, the
    # coin stack is round and layered, the bolt is a zigzag. Two brown things
    # of the same outline would be two brown things whatever colour they were.

    "ui/icon_wood": dict(size=TILE, legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
    }, rows=[
        "................",
        "................",
        "....kkkk........",
        "...kwwwwk.......",
        "..kwdwwdwk......",
        "..kwdkkdwk......",
        "..kwwddwwk......",
        "...kwwwwkkkkk...",
        "...kkkkwwwwwwk..",
        "...kwwwwddwwdk..",
        "..kwdwwkkdwwdk..",
        "..kwdkkddwwwdk..",
        "..kwwddwwwwwdk..",
        "...kwwwkkkkkkk..",
        "....kkkk........",
        "................",
    ]),

    "ui/icon_stone": dict(size=TILE, legend={
        "k": "ink", "i": "stone", "s": "stone_dark", "l": "stone_light",
    }, rows=[
        "................",
        "................",
        "......kkkk......",
        ".....klllik.....",
        "....kliiiiik....",
        "...kliiiiiiik...",
        "..kliiiiiiiiik..",
        "..kiiiiiissiik..",
        "..kiiissssssik..",
        "..kissssssssik..",
        "...ksssssssik...",
        "....kkkkkkkk....",
        "................",
        "................",
        "................",
        "................",
    ]),

    # A cast bar. Flat top, angled sides: nothing else here is a trapezoid.
    "ui/icon_iron": dict(size=TILE, legend={
        "k": "ink", "i": "stone", "s": "stone_dark", "l": "stone_light",
    }, rows=[
        "................",
        "................",
        "................",
        "....kkkkkkkk....",
        "...klllllllik...",
        "...kliiiiiiik...",
        "..kkiiiiiiiikk..",
        ".kliiiiiiiiiiik.",
        ".kiiiiiiiiiissk.",
        ".kissssssssssik.",
        ".ksssssssssssik.",
        ".kkkkkkkkkkkkkk.",
        "................",
        "................",
        "................",
        "................",
    ]),

    # A loaf. Round-topped and cut, so it is not the rock.
    "ui/icon_food": dict(size=TILE, legend={
        "k": "ink", "c": "roof", "e": "roof_dark", "l": "roof_light",
        "g": "gold_light", "d": "gold_dark",
    }, rows=[
        "................",
        "................",
        "................",
        "....kkkkkk......",
        "...klggggdk.....",
        "..klgdggggdk....",
        "..kggggdgggk....",
        "..kgdgggggdk....",
        ".kkkkkkkkkkkk...",
        ".klcccccccccdk..",
        ".kceccccccccek..",
        ".kceecccccceek..",
        ".kkeeeeeeeeekk..",
        "..kkkkkkkkkkk...",
        "................",
        "................",
    ]),

    "ui/icon_fish": dict(size=TILE, legend={
        "k": "ink", "w": "water", "d": "water_dark", "l": "water_light",
        "b": "bone", "o": "ink",
    }, rows=[
        "................",
        "................",
        "..........kk....",
        ".....kkkkklwk...",
        "...kkwwwwwwlwk..",
        "..klwwwwwwwwwk..",
        ".kbowwwwwwwwwk..",
        ".kwwwwwwwwwwlk..",
        ".kbowwwwwwwwwk..",
        "..klwwwwwwwwwk..",
        "...kkddddddlwk..",
        ".....kkkkkldk...",
        "..........kk....",
        "................",
        "................",
        "................",
    ]),

    "ui/icon_oil": dict(size=TILE, legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "i": "stone",
        "s": "ink_soft",
    }, rows=[
        "................",
        "................",
        "....kkkkkkk.....",
        "...kwwwwwwwk....",
        "...kiiiiiiik....",
        "..kwwwwwwwwwk...",
        "..kwwsssssswk...",
        "..kwssssssssk...",
        "..kwssssssssk...",
        "..kwwsssssswk...",
        "..kiiiiiiiiik...",
        "...kwwwwwwwk....",
        "....kkkkkkk.....",
        "................",
        "................",
        "................",
    ]),

    # Standing, with grain on a stalk. The only tall thin gold thing.
    "ui/icon_wheat": dict(size=TILE, legend={
        "k": "ink", "g": "gold", "d": "gold_dark", "l": "gold_light",
        "e": "leaf",
    }, rows=[
        "................",
        ".......kk.......",
        "......klgk......",
        ".....kglgdk.....",
        "....kglkgldk....",
        "....kglkgldk....",
        "...kglkkkgldk...",
        "...kglkgkgldk...",
        "....kglkgldk....",
        "....kglkgldk....",
        ".....kglgdk.....",
        "......kgdk......",
        "......keek......",
        ".....kekek......",
        "......kkk.......",
        "................",
    ]),

    # A cob in its husk: fat, vertical, and green at the sides.
    "ui/icon_corn": dict(size=TILE, legend={
        "k": "ink", "g": "gold", "d": "gold_dark", "l": "gold_light",
        "e": "leaf", "f": "leaf_dark",
    }, rows=[
        "................",
        "......kk........",
        ".....kelk.......",
        "....kekglk......",
        "...kekglglk.....",
        "...kekglglk.....",
        "..kfekglglkek...",
        "..kfekglglkek...",
        "..kfekglglkek...",
        "..kfekglglkek...",
        "...kfkglglkek...",
        "....kkglgkfk....",
        ".....kgdkfk.....",
        "......kkk.......",
        "................",
        "................",
    ]),

    "ui/icon_carrot": dict(size=TILE, legend={
        "k": "ink", "o": "flame", "d": "gold_dark", "e": "leaf",
        "f": "leaf_dark",
    }, rows=[
        "................",
        "....k.kek.k.....",
        "....kekekek.....",
        "....kfekefk.....",
        ".....kfefk......",
        "......kek.......",
        ".....kooook.....",
        ".....kooook.....",
        "......koook.....",
        "......kooodk....",
        ".......kood.....",
        ".......kodk.....",
        "........kdk.....",
        "........kk......",
        "................",
        "................",
    ]),

    "ui/icon_meat": dict(size=TILE, legend={
        "k": "ink", "r": "blood", "b": "bone", "n": "bone_dark",
        "l": "roof_light",
    }, rows=[
        "................",
        "................",
        "...kk......kk...",
        "..kbbk....kbbk..",
        "..kbnbkkkkbnbk..",
        "...kbnnnnnnbk...",
        "....kkkbbkkk....",
        "...kkrrrrrrkk...",
        "..krllrrrrrrk...",
        "..krrrrrrrrrk...",
        "..krrrrrrrrk....",
        "...krrrrrrk.....",
        "....kkkkkk......",
        "................",
        "................",
        "................",
    ]),

    # A keg with a fuse. Dark, banded, and the only thing with a spark on it.
    "ui/icon_gunpowder": dict(size=TILE, legend={
        "k": "ink", "s": "ink_soft", "w": "wood_dark", "f": "flame_hot",
        "o": "flame",
    }, rows=[
        "................",
        "...........f....",
        "..........fof...",
        "..........kf....",
        ".....kkkkkk.....",
        "....kwwwwwwk....",
        "...ksssssssk....",
        "...kwwwwwwwk....",
        "...ksssssssk....",
        "...ksssssssk....",
        "...kwwwwwwwk....",
        "...ksssssssk....",
        "....kwwwwwk.....",
        ".....kkkkk......",
        "................",
        "................",
    ]),

    # A bottle with a rag alight. Nothing else is a bottle.
    "ui/icon_incendiary": dict(size=TILE, legend={
        "k": "ink", "g": "leaf", "d": "leaf_dark", "f": "flame_hot",
        "o": "flame", "b": "bone",
    }, rows=[
        "................",
        "......ff........",
        ".....fof........",
        "......f.........",
        "......kk........",
        "......kbk.......",
        ".....kkbkk......",
        "....kgggggk.....",
        "...kgggdgggk....",
        "...kgggdgggk....",
        "...kgggdgggk....",
        "...kdggdgggk....",
        "...kddddddk.....",
        "....kkkkkk......",
        "................",
        "................",
    ]),

    "ui/icon_money": dict(size=TILE, legend={
        "k": "ink", "g": "gold", "d": "gold_dark", "l": "gold_light",
    }, rows=[
        "................",
        "................",
        "....kkkkkk......",
        "...klllgggk.....",
        "..klggkgggdk....",
        "..kgggkggggk....",
        "..kdgggggggk....",
        "...kkkkkkkk.....",
        "..kkkkkkkkkk....",
        ".klllgggggggk...",
        ".kggkgggggggk...",
        ".kdggggggggdk...",
        ".kddddddddddk...",
        "..kkkkkkkkkk....",
        "................",
        "................",
    ]),

    # A bolt. The only zigzag in the set.
    "ui/icon_energy": dict(size=TILE, legend={
        "k": "ink", "f": "flame_hot", "o": "flame", "b": "water_dark",
    }, rows=[
        "................",
        "........kk......",
        ".......kfk......",
        "......kffk......",
        ".....kfffk......",
        "....kfffkk......",
        "...kffffk.......",
        "...kfffffkkk....",
        "...kkkfffffk....",
        "......kfffk.....",
        ".....kfffk......",
        "....kfffk.......",
        "....kffk........",
        "....kfk.........",
        ".....k..........",
        "................",
    ]),

    # A cog. The only round thing with teeth.
    "ui/icon_tech": dict(size=TILE, legend={
        "k": "ink", "i": "stone", "l": "stone_light", "s": "stone_dark",
        "b": "water_light",
    }, rows=[
        "................",
        "....k.kkk.k.....",
        "....kkiiikk.....",
        "...kkiiiiikk....",
        "..kkiillliikk...",
        "..kiiilbliiik...",
        "kkiiilbbbliikk..",
        "kiiiilbkbliiik..",
        "kiiiilbbbliiik..",
        "kkiiiilblliikk..",
        "..kiiillliiik...",
        "..kkiiisssikk...",
        "...kkisssikk....",
        "....kksssk......",
        "....k.kkk.k.....",
        "................",
    ]),

    # ---------------------------------------------- buildings, task 0075

    # **The house is the landmark**, which task 0075 asks for in as many
    # words: the biggest, warmest thing on the farm, by day and by night.
    #
    # Three tiles by three, drawn whole and sliced into nine by
    # `gen_sprites.SLICED`. Drawn whole because a roof line has to meet
    # across three files and the only way to check nine separate maps is to
    # build the house and look at it.
    #
    # **The windows are `flame_hot` and that is the point.** Task 0071's
    # night ramp exempts anything the palette drew brighter than 0.80 and
    # lists what it is for - "firelight, a lit window, the moon". These are
    # the lit windows. They keep their colour after dark while the farm goes
    # blue around them, so the house is the warm thing on a cold field
    # without a single light being placed.
    "buildings/house": dict(size=(48, 48), legend={
        "k": "ink", "r": "roof", "R": "roof_dark", "L": "roof_light",
        "w": "wood", "d": "wood_dark", "l": "wood_light",
        "s": "stone", "S": "stone_dark", "f": "flame_hot", "g": "gold_dark",
        "m": "moon",
    }, rows=[
        "................kkkk............................",
        "................kSSk............................",
        "................kSSk............................",
        "..............kkkSSkkk..........................",
        "..............kSSSSSSk..........................",
        ".....................kkk........................",
        "..................kkkkLLkkk.....................",
        "...............kkkLLLLLLLLLkkk..................",
        "............kkkLLLrrrrrrrrrLLLkkk...............",
        ".........kkkLLLrrrrrrrrrrrrrrrLLLkkk............",
        "......kkkLLLrrrrrrrrrrrrrrrrrrrrrLLLkkk.........",
        "...kkkLLLrrrrrrrrrrrrrrrrrrrrrrrrrrrLLLkkk......",
        "kkkLLLrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrLLLkkk...",
        "kLLrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrLLLk..",
        "kRrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrRk..",
        "kRRrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrRRk..",
        "kkRRRrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrRRRkk..",
        ".kkRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRkk...",
        "..kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk....",
        "...kwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwk.....",
        "...kwlllllllllllllllllllllllllllllllllllllwk....",
        "...kwlkkkkkklwwwwwwwwwwwwwwwwlkkkkkklwwwwwwk....",
        "...kwlkffffkllllllllllllllllllkffffklwwwwwwk....",
        "...kwlkffffkwwwwwwwwwwwwwwwwwwkffffklwwwwwwk....",
        "...kwlkffffkwwwwkkkkkkkkkkwwwwwkffffklwwwwwk....",
        "...kwlkffffkwwwkgggggggggkwwwwwkffffklwwwwwk....",
        "...kwlkkkkkkwwwkgddddddgkkwwwwwkkkkkkkwwwwwk....",
        "...kwwwwwwwwwwwkgdddddddgkwwwwwwwwwwwwwwwwwk....",
        "...kwdddddddddwkgdddffdddgkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkgdddffdddgkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkgdddddddgkwwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkgddddddddgkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkgdddddddddkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkgddddddddgkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwkkgdddddddgkwwwwwwwwwwwwwwwwk....",
        "...kwdddddddddwwkgddddddddkwwwwwwdddddddddwk....",
        "...kwwwwwwwwwwwwkgdddddddgkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwwkkgggggggkkwwwwwwwwwwwwwwwwk....",
        "...kwwwwwwwwwwwwwkkkkkkkkkwwwwwwwwwwwwwwwwwk....",
        "...kkwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwkk....",
        "....kkdddddddddddddddddddddddddddddddddddkk.....",
        ".....kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk......",
        "......kSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSk.......",
        "......kSssssssssssssssssssssssssssssssssk.......",
        "......kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk.......",
        "................................................",
        "................................................",
        "................................................",
    ]),

    # Two tiles by two. A bench, a rack of tools and a chimney: the place
    # things are made rather than the place somebody lives.
    "buildings/workshop": dict(size=(32, 32), legend={
        "k": "ink", "r": "roof", "R": "roof_dark",
        "w": "wood", "d": "wood_dark", "l": "wood_light",
        "s": "stone", "S": "stone_dark", "f": "flame_hot", "i": "stone",
    }, rows=[
        "..........kkkk..................",
        "..........kSSk..................",
        "........kkkSSkkk................",
        "........kSSSSSSk................",
        "....kkkkkkkkkkkkkkkkkkkk........",
        "...krrrrrrrrrrrrrrrrrrrrk.......",
        "...kRrrrrrrrrrrrrrrrrrrRk.......",
        "...kRRRRRRRRRRRRRRRRRRRRk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kwlllllllllllllllllllk.......",
        "...kwlkkkkkkwwwwwwwwwwwlk.......",
        "...kwlkffffkwwkkkkkkkwwlk.......",
        "...kwlkffffkwwkddddkkwwlk.......",
        "...kwlkkkkkkwwkddddkkwwlk.......",
        "...kwwwwwwwwwwkddddkkwwwk.......",
        "...kwwwwwwwwwwkkkkkkkwwwk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kwddwwwwwwwwwwwwwwddwk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "...kllllllllllllllllllllk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kdkkdkkdkkdkkdkkdkkdkk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "....kSSSSSSSSSSSSSSSSSSk........",
        "....kSssssssssssssssssSk........",
        "....kkkkkkkkkkkkkkkkkkkk........",
        "................................",
        "................................",
        "................................",
    ]),

    # Two by two, and the one with the fire in it. The stove glows, which is
    # the other thing on the farm the night ramp leaves warm.
    "buildings/kitchen": dict(size=(32, 32), legend={
        "k": "ink", "r": "roof", "R": "roof_dark",
        "w": "wood", "d": "wood_dark", "l": "wood_light",
        "s": "stone", "S": "stone_dark", "f": "flame_hot", "F": "flame",
    }, rows=[
        "................................",
        "......kkkk......................",
        "......kSSk......................",
        "....kkkSSkkk....................",
        "....kSSSSSSk....................",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "...krrrrrrrrrrrrrrrrrrrrk.......",
        "...kRrrrrrrrrrrrrrrrrrrRk.......",
        "...kRRRRRRRRRRRRRRRRRRRRk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kwlllllllllllllllllllk.......",
        "...kwlkkkkkkkkwwwwwwwwwlk.......",
        "...kwlkSSSSSSkwwkkkkkwwlk.......",
        "...kwlkSffffSkwwkllllkwwk.......",
        "...kwlkSfFFfSkwwkllllkwwk.......",
        "...kwlkSffffSkwwkkkkkkwwk.......",
        "...kwlkSSSSSSkwwwwwwwwwwk.......",
        "...kwwkkkkkkkkwwwwwwwwwwk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kwddwwwwwwwwwwwwwwddwk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "...kllllllllllllllllllllk.......",
        "...kwwwwwwwwwwwwwwwwwwwwk.......",
        "...kdkkdkkdkkdkkdkkdkkdkk.......",
        "...kkkkkkkkkkkkkkkkkkkkkk.......",
        "....kSSSSSSSSSSSSSSSSSSk........",
        "....kSssssssssssssssssSk........",
        "....kkkkkkkkkkkkkkkkkkkk........",
        "................................",
        "................................",
        "................................",
    ]),

    # ----------------------------------------------- defences, task 0075

    # **Sixteen wide and thirty-two tall, standing on the bottom tile.** A
    # tower that fits inside its own tile is a crate with a stick on it; the
    # reference sheet's towers have a post, a platform and something on top,
    # and that needs height. The view bottom-aligns anything taller than a
    # tile onto the cell it occupies, so the feet are on the grid and the rest
    # overhangs upward into the row above - which is where a roof belongs.
    #
    # Rows 18 to 22 of each are a plain length of post with nothing on it.
    # That is the stage `gen_sprites.GROWS` repeats to build levels two and
    # three, so a Torre III is the same tower with more of it.

    # The plain one: a post, a railed platform, a gun on a swivel.
    "buildings/gun_tower": dict(size=(16, 32), legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
        "i": "stone", "s": "stone_dark", "g": "gold", "m": "moon",
    }, rows=[
        "................",
        "................",
        "................",
        "..........kkk...",
        ".......kkkkiikk.",
        "......kiiiiiiik.",
        "......kissssiik.",
        "......kiiiiiik..",
        ".....kkiiiikk...",
        "....kkgggggkk...",
        "...kklllllllkk..",
        "...kwdwdwdwdwk..",
        "...kklllllllkk..",
        "....kkwwwwwkk...",
        ".....kwdwdwk....",
        ".....kwdwdwk....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        ".....kkwdwkk....",
        ".....kwwdwwk....",
        "....kkwwdwwkk...",
        "....kddwwwddk...",
        "...kkddddddkkk..",
        "...kdddddddddk..",
        "...kkkkkkkkkkk..",
        "................",
    ]),

    # A tank on the platform and a short nozzle. Fat where the gun tower is
    # thin, which is the whole of telling them apart in a dark field.
    "buildings/flame_tower": dict(size=(16, 32), legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
        "i": "stone", "s": "stone_dark", "f": "flame", "h": "flame_hot",
        "r": "roof", "m": "moon",
    }, rows=[
        "................",
        "................",
        "...........kk...",
        "..........khhk..",
        ".......kkkkffk..",
        "......krrrrrkk..",
        ".....krrrrrrrk..",
        ".....krsssrrrk..",
        ".....krrrrrrrk..",
        ".....kkrrrrrkk..",
        "...kkklllllkkk..",
        "...kwdwdwdwdwk..",
        "...kklllllllkk..",
        "....kkwwwwwkk...",
        ".....kwdwdwk....",
        ".....kwdwdwk....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        ".....kkwdwkk....",
        ".....kwwdwwk....",
        "....kkwwdwwkk...",
        "....kddwwwddk...",
        "...kkddddddkkk..",
        "...kdddddddddk..",
        "...kkkkkkkkkkk..",
        "................",
    ]),

    # Squat, angled up, and sitting on the ground rather than on a post: a
    # mortar is a tube in a cradle and it is the short one on the skyline.
    "buildings/mortar": dict(size=(16, 32), legend={
        "k": "ink", "w": "wood", "d": "wood_dark",
        "i": "stone", "s": "stone_dark", "g": "gold", "m": "moon",
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
        "..........kkk...",
        ".........kiiik..",
        "........kiiiik..",
        "........kisiik..",
        ".......kiisiik..",
        ".......kiisik...",
        "......kiisiik...",
        "......kiisik....",
        ".....kiisiik....",
        ".....kiisik.....",
        ".....kiisik.....",
        "....kkiisikk....",
        "...kkgiisiigkk..",
        "...kwwiiiiwwwk..",
        "...kwdwwwwwdwk..",
        "..kkwdwwwwwdwkk.",
        "..kwddwwwwwddwk.",
        "..kwddwwwwwddwk.",
        "..kkddddddddkkk.",
        "...kdddddddddk..",
        "...kkkkkkkkkkk..",
        "................",
        "................",
    ]),

    # Wide horizontal limbs on a short post. Nothing else on the farm is
    # wider than it is tall.
    "buildings/auto_crossbow": dict(size=(16, 32), legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
        "i": "stone", "s": "stone_dark", "g": "gold", "m": "moon",
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        "................",
        "kk............kk",
        "kdkk........kkdk",
        ".kdkkkkkkkkkkdk.",
        "..kdddiiiiddddk.",
        "..kkkkisikkkkk..",
        "....kkiisikk....",
        "...kkgiisigkk...",
        "...kwllllllwk...",
        "...kkwwwwwwkk...",
        "....kwdwdwdk....",
        "....kwdwdwdk....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        "......kwdwk.....",
        ".....kkwdwkk....",
        ".....kwwdwwk....",
        "....kkwwdwwkk...",
        "....kddwwwddk...",
        "...kkddddddkkk..",
        "...kdddddddddk..",
        "...kkkkkkkkkkk..",
        "................",
    ]),

    # **The small ones stay inside their tile.** A wall is a thing you walk
    # up to and stop at; giving it a roof would be giving the farm a second
    # skyline that means nothing.
    "buildings/wall": dict(size=(16, 16), legend={
        "k": "ink", "i": "stone", "s": "stone_dark", "l": "stone_light",
    }, rows=[
        "kkkkkkkkkkkkkkkk",
        "kliiikliiiikliik",
        "kiiiikiiiiikiiik",
        "kssssksssssksssk",
        "kkkkkkkkkkkkkkkk",
        "kikliiiikliiiikk",
        "kikiiiiikiiiiikk",
        "ksksssssksssssk.",
        "kkkkkkkkkkkkkkkk",
        "kliiikliiiikliik",
        "kiiiikiiiiikiiik",
        "kssssksssssksssk",
        "kkkkkkkkkkkkkkkk",
        "kikliiiikliiiikk",
        "kikiiiiikiiiiikk",
        "kkkkkkkkkkkkkkkk",
    ]),

    "buildings/fence": dict(size=(16, 16), legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
    }, rows=[
        "................",
        ".k....k....k....",
        "klk..klk..klk...",
        "kwk..kwk..kwk...",
        "kwkkkkwkkkkwkkk.",
        "kwwwwwwwwwwwwwk.",
        "kdkkkkdkkkkdkkk.",
        "kwk..kwk..kwk...",
        "kwk..kwk..kwk...",
        "kwkkkkwkkkkwkkk.",
        "kwwwwwwwwwwwwwk.",
        "kdkkkkdkkkkdkkk.",
        "kwk..kwk..kwk...",
        "kdk..kdk..kdk...",
        "kkk..kkk..kkk...",
        "................",
    ]),

    "buildings/barricade": dict(size=(16, 16), legend={
        "k": "ink", "w": "wood", "d": "wood_dark", "l": "wood_light",
    }, rows=[
        "................",
        "................",
        "..kk........kk..",
        ".klwk......klwk.",
        ".kwwkkkkkkkkwwk.",
        ".kwwwwwwwwwwwwk.",
        ".kddkkkkkkkkddk.",
        ".kwwk......kwwk.",
        ".kwwkkkkkkkkwwk.",
        ".kwwwwwwwwwwwwk.",
        ".kddkkkkkkkkddk.",
        ".kwwk......kwwk.",
        ".kdwk......kdwk.",
        ".kddk......kddk.",
        ".kkkk......kkkk.",
        "................",
    ]),

    # Flat, small, and the only defence that is meant to be missed.
    "buildings/mine": dict(size=(16, 16), legend={
        "k": "ink", "i": "stone", "s": "stone_dark", "b": "blood",
        "g": "gold",
    }, rows=[
        "................",
        "................",
        "................",
        "................",
        ".....kkkkkk.....",
        "....kiiiiiik....",
        "...kiissssiik...",
        "...kisikkisik...",
        "...kisikkisik...",
        "...kiissssiik...",
        "....kiibbiik....",
        ".....kkggkk.....",
        "......kkkk......",
        "................",
        "................",
        "................",
    ]),
    # ------------------------------------------------- enemies, task 0074

    # **Told apart in black before they are told apart in colour.** Task 0074
    # has one test that matters - five silhouettes at 100% zoom in a dark
    # field - so these are shapes first. The walker is upright and average,
    # the runner is thrown forward and thin, the tank is wide with no neck,
    # the breaker carries a slab on one side, and the Giant is none of those
    # and twice the size.
    #
    # `m` is the rim light and it is `moon` on purpose. Task 0071's night ramp
    # exempts anything the palette drew brighter than 0.80 from the tint, and
    # `moon` is 0.849 - so this one line keeps its own colour after dark while
    # the body goes blue with everything else.
    #
    # **It replaces the outline on the lit side rather than sitting outside
    # it.** The first version drew it one pixel clear of the body, which at
    # 100% zoom is not a rim light, it is a glowing stick walking next to a
    # zombie.
    "enemies/walker": dict(size=(24, 32), legend={
        "k": "ink", "r": "rot", "d": "rot_dark",         "o": "bone", "b": "blood", "s": "soil_dark",
    }, rows=[
        "........................",
        "........kkkkkk..........",
        ".......krrrrrr..........",
        "......krrrrrrrr.........",
        "......krokrrokr.........",
        "......krrrrrrrr.........",
        "......krroooorr.........",
        ".......kkrrrrk..........",
        "........kkrrk...........",
        ".....kkkksssskk.........",
        "....ksssssssssss........",
        "...krsssbssssssss.......",
        "...krsssssssssssr.......",
        "...krssssssssssss.......",
        "...krrsssssssssss.......",
        "..kkrkssssssssssk.......",
        "..krrk.kssssssk.kr......",
        "..krrk.kdddddk..kr......",
        "..kkkk.kdddddk..kk......",
        ".......kdddddk..........",
        ".......kddkddk..........",
        ".......kdk.kdk..........",
        ".......kdk.kdk..........",
        ".......kdk.kdk..........",
        ".......kdk.kdk..........",
        "......kkdk.kdkk.........",
        "......krdk.kdrk.........",
        "......kkkk.kkkk.........",
        "........................",
        "........................",
        "........................",
        "........................",
    ]),

    # **Thrown forward, and the only thing on the farm that leans.** The head
    # is out past the front foot, which is what a sprint looks like from the
    # side and what nothing else here does.
    "enemies/runner": dict(size=(24, 32), legend={
        "k": "ink", "r": "rot", "d": "rot_dark",
        "o": "bone", "b": "blood", "s": "soil_dark",
    }, rows=[
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "...............kkkkk....",
        "..............krrrrrk...",
        "..............krokrok...",
        "..............krrrrrk...",
        "..............kroooork..",
        "...........kkkkkrrrkk...",
        "........kkkkssssskkk....",
        "....kkkkksssssssssk.....",
        "..kkrrkssssssbsssssk....",
        "..krrkksssssssssssk.....",
        "..kkkkkkssssssssssk.....",
        "......kkkdddddddddk.....",
        ".........kdddddddk......",
        ".........kdddddkk.......",
        "........kkddddk.........",
        ".......kkdddkk..........",
        "......kkdddk............",
        ".....kkdddk.............",
        ".....kdddk..............",
        "....kkddk......kkkk.....",
        "....kddk......kkddkk....",
        "...kkddk.....kkdddddk...",
        "...krrk......kddddddk...",
        "...kkkk......kkddddkk...",
        "..............kkkkkk....",
        "........................",
        "........................",
    ]),

    # **No neck, and shoulders twice a walker's.** Wide is the whole shape: at
    # a glance it is a door rather than a person.
    "enemies/tank": dict(size=(24, 32), legend={
        "k": "ink", "r": "rot", "d": "rot_dark",         "o": "bone", "b": "blood", "s": "soil_dark",
    }, rows=[
        "........................",
        "........................",
        "........kkkkkk..........",
        ".......krrrrrr..........",
        ".......krokrok..........",
        ".......krrrrrr..........",
        "......kkrooook..........",
        "...kkkkkrrrrkkkkk.......",
        "..ksssssssssssssss......",
        ".kssssssssssssssssss....",
        ".krsssbsssssssssssss....",
        "krrsssssssssssssssss....",
        "krrssssssssssssssssr....",
        "krrsssssbsssssssssss....",
        "krrssssssssssssssssr....",
        "krrksssssssssssssskr....",
        "kkrkkssssssssssskkkr....",
        ".krrk.kdddddddddk.kr....",
        ".krrk.kdddddddddk.kr....",
        ".kkkk.kddddkddddk..kk...",
        "......kdddk.kdddk.......",
        "......kdddk.kdddk.......",
        "......kdddk.kdddk.......",
        ".....kkdddk.kdddkk......",
        ".....krddrk.krddrk......",
        ".....kkkkkk.kkkkkk......",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ]),

    # **It carries the thing it breaks your wall with.** The slab is held out
    # on one side and joined to the body by an arm, so the silhouette is
    # lopsided - which none of the others are. The first version drew it as a
    # block floating clear of the shoulder.
    "enemies/breaker": dict(size=(24, 32), legend={
        "k": "ink", "r": "rot", "d": "rot_dark",         "o": "bone", "b": "blood", "s": "soil_dark",
        "t": "stone", "u": "stone_dark",
    }, rows=[
        "........................",
        "........................",
        "........kkkkk...........",
        ".......krrrrr...........",
        "......krrrrrrr..........",
        "......krokrrok..........",
        "......krrrrrrr..........",
        "......kroooork..........",
        ".......kkrrrk...........",
        "kkkk...kkssskk..........",
        "kuutkkksssssssk.........",
        "kuutkrsssbsssss.........",
        "kuutkrssssssssss........",
        "kuutkrrsssssssss........",
        "kuutkkrsssssssssr.......",
        "kuutk.ksssssssssk.......",
        "kkkkk.kkssssssskk.......",
        "......kkdddddddk........",
        "......kdddddddk.........",
        "......kdddddddk.........",
        "......kddddkddk.........",
        "......kdddk.kdk.........",
        "......kdddk.kdk.........",
        ".....kkdddk.kdkk........",
        ".....krddrk.krdk........",
        ".....kkkkkk.kkkk........",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ]),

    # **The Giant.** Twice the size, hunched, with arms that reach the ground
    # and a head sunk between them. Nothing else on the farm is this shape and
    # nothing else is this big, which is the whole of its silhouette test.
    "enemies/giant": dict(size=(40, 52), legend={
        "k": "ink", "r": "rot", "d": "rot_dark",         "o": "bone", "b": "blood", "s": "soil_dark",
    }, rows=[
        "........................................",
        "........................................",
        "..............kkkkkkkkk.................",
        "............kkrrrrrrrrrk................",
        "...........krrrrrrrrrrrr................",
        "...........krrrrrrrrrrrrr...............",
        "...........krokkrrrrkkokr...............",
        "...........krrrrrrrrrrrrr...............",
        "...........krroooooooorrr...............",
        "...........kkrokokokokrrk...............",
        "............kkrrrrrrrrkk................",
        "..........kkkkkkrrrrkkkkkk..............",
        ".......kkkkssssssssssssssskkk...........",
        "....kkkkssssssssssssssssssssssk.........",
        "...kssssssssssbssssssssssssssss.........",
        "..krssssssssssssssssssssssssssss........",
        "..krrsssssssssssssssssssssssssss........",
        "..krrssssssssssssssssssssssssssr........",
        "..krrsssssssssbbssssssssssssssss........",
        "..krrssssssssssssssssssssssssssr........",
        "..krrkssssssssssssssssssssssssrk........",
        "..krrkkssssssssssssssssssssssskr........",
        "..krrk.kkssssssssssssssssssskkkr........",
        "..krrk...kkddddddddddddddkk...kr........",
        "..krrk.....kdddddddddddddk....kr........",
        "..krrk.....kdddddddddddddk....kr........",
        "..krrk.....kdddddddddddddk....kr........",
        "..kkrk.....kddddddkdddddddk...kr........",
        "...krk.....kdddddk.kdddddk....kr........",
        "...krk.....kdddddk.kdddddk....kr........",
        "...kkkk....kdddddk.kdddddk...kkk........",
        "....krrk...kdddddk.kdddddk..krrk........",
        "....kkkkk..kdddddk.kdddddk..kkkk........",
        ".....krrk..kdddddk.kdddddk..krrk........",
        ".....kkkk..kdddddk.kdddddk..kkkk........",
        "...........kdddddk.kdddddk..............",
        "...........kdddddk.kdddddk..............",
        "...........kdddddk.kdddddk..............",
        "..........kkdddddk.kdddddkk.............",
        "..........krddddrk.krddddrk.............",
        "..........kkkkkkkk.kkkkkkkk.............",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]),


    # **The shadow under the farmer**, because without one a character floats.
    # Drawn flat and wide, the shape a body casts at noon from above, and laid
    # down at a low opacity by `PlayerView` - the palette has no partial alpha
    # in it, so the softness is the sprite's modulate rather than its pixels.
    "actors/shadow": dict(size=(20, 8), legend={"k": "ink"}, rows=[
        "......kkkkkkkk......",
        "....kkkkkkkkkkkk....",
        "..kkkkkkkkkkkkkkkk..",
        ".kkkkkkkkkkkkkkkkkk.",
        ".kkkkkkkkkkkkkkkkkk.",
        "..kkkkkkkkkkkkkkkk..",
        "....kkkkkkkkkkkk....",
        "......kkkkkkkk......",
    ]),

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
