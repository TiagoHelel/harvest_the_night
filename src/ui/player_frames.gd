class_name PlayerFrames
extends RefCounted

## What `tools/cut_sheet.py` cut out of `docs/sprites_sem_fundo.png`.
## **Do not edit.** `python tools/cut_sheet.py --check` fails when
## this file and the sheet disagree.

## The canvas every frame is drawn on, and where the feet sit on it.
## The character is about 44 pixels tall on it - two tiles wide and
## three tall over an unchanged 16 pixel grid, which is task 0073's
## answer to a painted sheet meeting a pixel-art game.
const CANVAS := Vector2i(48, 52)
const FEET := Vector2i(24, 50)

## How many frames each animation has.
const COUNT := {
	&"carry": 2,
	&"chop": 4,
	&"craft": 1,
	&"fish": 1,
	&"harvest": 1,
	&"idle_north": 3,
	&"idle_south": 3,
	&"idle_west": 3,
	&"mine": 2,
	&"plant": 3,
	&"till": 3,
	&"walk_north": 4,
	&"walk_south": 4,
	&"walk_west": 4,
	&"water": 4,
}
