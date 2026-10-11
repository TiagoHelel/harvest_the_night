class_name FrostArt
extends RefCounted

## **A frost zombie's ice burst, drawn in code** (task 0251): A050's
## `ice_shatter`, the four frames played where one is killed, on its 24x24
## canvas round (12,12), through 0120's road until 0264 integrates the pack.
## The zombie itself stands in as the walker gone cold (`PlaceholderArt`).
##
## (0) an ice crystal, rimmed and cracked down the middle; (1) the burst at
## its widest - the crystal in four pieces and twelve shards out, wider than
## tall; (2) only the shards' ends, most of them losing their light; (3) a
## few dim chips. Matte: the water's blues with a `moon` tip on each shard,
## nothing that reads as a light. It grows to (1) and shrinks after, inside a
## 1 px clear border.
##
## Each frame is named for the runtime path A050 delivers it to, so the day
## the real art lands these load it and the drawings go. View only: who was
## killed is `Combat`'s, and `PixelEffects` plays it.

## Where A050 delivers it.
const SHATTER_PATH := "res://sprites/effects/ice_shatter_%d.png"
const SHATTER_FRAMES := 4

## What each letter of the maps below is drawn in.
const LEGEND := {
	"k": &"ink_soft", "d": &"water_dark", "w": &"water", "l": &"water_light", "m": &"moon",
}

## Every frame, row by row: what each letter is in `LEGEND`.
const FRAMES := [
	[
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"............k...........",
		"...........kmk..........",
		"..........kmlwk.........",
		"..........kmdwk.........",
		"..........klldk.........",
		"..........kldwk.........",
		"...........kwk..........",
		"............k...........",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
	],
	[
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"............m...........",
		"......m.....l.....m.....",
		".......l....w....l......",
		"........w.......w.......",
		".....m...ml...lm...m....",
		"......lw.lw...wd.wl.....",
		"........................",
		"....mlwd....d....dwlm...",
		"........................",
		".......w.lw...wl.w......",
		".....ml..wd...dw..lm....",
		"........l.......l.......",
		".......m....w....m......",
		"............l...........",
		"............m...........",
		"........................",
		"........................",
		"........................",
		"........................",
	],
	[
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"............m...........",
		"......l.....w.....m.....",
		"........................",
		"........................",
		".....w.............l....",
		"..........w...l.........",
		"........................",
		"....lw.............wl...",
		"........................",
		"..........d...w.........",
		".....l.............m....",
		"........................",
		".......m.........l......",
		"............w...........",
		"............l...........",
		"........................",
		"........................",
		"........................",
		"........................",
	],
	[
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"............w...........",
		"......w...........d.....",
		"........................",
		"........................",
		"........................",
		"........................",
		"........................",
		"....d...............w...",
		"........................",
		"........................",
		"..................w.....",
		"........................",
		"........................",
		"............d...........",
		"........................",
		"........................",
		"........................",
		"........................",
	],
]

static var _made: Dictionary = {}


## The burst's frame for a runtime path: A050's when it has landed, the
## drawing until then. Null for anything that is not the burst.
static func texture_at(path: String) -> Texture2D:
	var index := -1
	for i in SHATTER_FRAMES:
		if path == SHATTER_PATH % i:
			index = i
	if index < 0:
		return null
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(path):
		var made := ImageTexture.create_from_image(drawing(index))
		made.resource_name = path
		_made[path] = made
	return _made[path]


## One frame of the burst, drawn on A050's canvas.
static func drawing(index: int) -> Image:
	var rows: Array = FRAMES[posmod(index, SHATTER_FRAMES)]
	var image := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				image.set_pixel(x, y, PaletteData.COLOURS[LEGEND[row[x]]])
	return image
