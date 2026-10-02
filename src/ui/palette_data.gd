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
	&"cloth": Color8(49, 90, 140),
	&"cloth_dark": Color8(32, 56, 89),
	&"cloth_light": Color8(78, 127, 177),
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
	&"skin": Color8(228, 155, 104),
	&"skin_dark": Color8(181, 107, 75),
	&"skin_light": Color8(243, 197, 141),
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

## The dawn ramp: what the same pixels look like after dark.
const DAWN_TINT := Color(0.920, 0.900, 1.020)
const DAWN_LIFT := Color(0.020, 0.020, 0.050)
const DAWN_SATURATION := 0.920
## Legacy brightness threshold; 1 disables all material exemptions.
## Actual fire/window cores use semantic emission layers.
const DAWN_WARM_KEEP := 1.000
## How wide that threshold is, so a flame has no hard
## outline where the exemption stops.
const DAWN_WARM_EDGE := 0.060

## The day ramp: what the same pixels look like by day.
const DAY_TINT := Color(1.020, 1.000, 0.960)
const DAY_LIFT := Color(0.000, 0.000, 0.000)
const DAY_SATURATION := 1.000
## Legacy brightness threshold; 1 disables all material exemptions.
## Actual fire/window cores use semantic emission layers.
const DAY_WARM_KEEP := 1.000
## How wide that threshold is, so a flame has no hard
## outline where the exemption stops.
const DAY_WARM_EDGE := 0.060

## The dusk ramp: what the same pixels look like after dark.
const DUSK_TINT := Color(1.060, 0.880, 0.800)
const DUSK_LIFT := Color(0.050, 0.020, 0.000)
const DUSK_SATURATION := 0.950
## Legacy brightness threshold; 1 disables all material exemptions.
## Actual fire/window cores use semantic emission layers.
const DUSK_WARM_KEEP := 1.000
## How wide that threshold is, so a flame has no hard
## outline where the exemption stops.
const DUSK_WARM_EDGE := 0.060

## The night ramp: what the same pixels look like after dark.
const NIGHT_TINT := Color(0.360, 0.400, 0.820)
const NIGHT_LIFT := Color(0.040, 0.035, 0.105)
const NIGHT_SATURATION := 0.760
## Legacy brightness threshold; 1 disables all material exemptions.
## Actual fire/window cores use semantic emission layers.
const NIGHT_WARM_KEEP := 1.000
## How wide that threshold is, so a flame has no hard
## outline where the exemption stops.
const NIGHT_WARM_EDGE := 0.060
