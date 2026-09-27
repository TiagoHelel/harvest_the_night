class_name PaletteData
extends RefCounted

## The palette, generated from `tools/palette.py` by
## `tools/gen_sprites.py`. **Do not edit.**
##
## The sprites are drawn against these colours and the night ramp is
## applied over them at runtime, so the two have to be the same numbers.
## `python tools/gen_sprites.py --check` fails when this file and the
## palette disagree.

const COLOURS := {
	&"blood": Color8(142, 43, 51),
	&"bone": Color8(232, 224, 207),
	&"bone_dark": Color8(184, 174, 154),
	&"flame": Color8(242, 160, 60),
	&"flame_hot": Color8(246, 217, 122),
	&"gold": Color8(196, 150, 70),
	&"gold_dark": Color8(168, 116, 44),
	&"gold_light": Color8(214, 186, 96),
	&"grass": Color8(106, 150, 70),
	&"grass_dark": Color8(78, 122, 53),
	&"grass_light": Color8(138, 182, 89),
	&"ink": Color8(36, 31, 46),
	&"ink_soft": Color8(58, 51, 69),
	&"leaf": Color8(46, 94, 52),
	&"leaf_dark": Color8(29, 64, 36),
	&"leaf_light": Color8(70, 128, 74),
	&"moon": Color8(207, 214, 255),
	&"night": Color8(26, 24, 48),
	&"night_light": Color8(46, 42, 78),
	&"roof": Color8(176, 66, 58),
	&"roof_dark": Color8(138, 47, 42),
	&"roof_light": Color8(201, 99, 90),
	&"rot": Color8(85, 118, 82),
	&"rot_dark": Color8(53, 80, 56),
	&"soil": Color8(122, 88, 56),
	&"soil_dark": Color8(92, 66, 42),
	&"soil_light": Color8(150, 112, 74),
	&"stone": Color8(110, 108, 120),
	&"stone_dark": Color8(82, 80, 92),
	&"stone_light": Color8(140, 138, 150),
	&"water": Color8(58, 110, 165),
	&"water_dark": Color8(43, 84, 128),
	&"water_light": Color8(90, 140, 192),
	&"wood": Color8(140, 98, 57),
	&"wood_dark": Color8(107, 74, 44),
	&"wood_light": Color8(168, 124, 78),
}

## The day ramp: what the same pixels look like by day.
const DAY_TINT := Color(1.020, 1.000, 0.960)
const DAY_LIFT := Color(0.000, 0.000, 0.000)
const DAY_SATURATION := 1.000

## The night ramp: what the same pixels look like after dark.
const NIGHT_TINT := Color(0.340, 0.360, 0.900)
const NIGHT_LIFT := Color(0.060, 0.050, 0.140)
const NIGHT_SATURATION := 0.720
## Anything brighter than this keeps its own colour:
## firelight, a lit window, the moon.
const NIGHT_WARM_KEEP := 0.800
