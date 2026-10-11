class_name DiggerArt
extends RefCounted

## **A digger's mound, drawn in code** (task 0250): A049's `digger_mound` -
## what shows of a digger while it is under a fence, a barricade or the wire -
## on its 64x48 canvas standing on (32,44), through 0120's road until 0263
## integrates the pack. The digger itself stands in as the walker, soil-caked
## (`PlaceholderArt`).
##
## A low heap of soil 17 wide and 6 tall, centred on x=32 with its foot on
## row 43, a short trail of loose clods behind it to the east - it travels
## west as A049 draws it, the view mirroring it - and its crest heaving west
## from frame to frame. Soft soil, the soils only: never a rock's grey.
##
## Each frame is named for the runtime path A049 delivers it to, so the day
## the real art lands these load it and the drawings go. View only: where a
## digger is is `Enemies`'.

## Where A049 delivers it.
const MOUND_PATH := "res://sprites/enemies/digger_mound_%d.png"
const MOUND_FRAMES := 3

## Each frame, row by row: the first and last column of the heap. The top
## edge is `ink_soft`, the body `soil_light`, its crest `bone` - turned earth
## lighter than the ground it heaves under a dark rim, or the night took it
## down to nothing (the first takes).
const HEAPS := [
	{38: [30, 33], 39: [28, 35], 40: [26, 37], 41: [25, 38], 42: [24, 39], 43: [24, 40]},
	{38: [29, 32], 39: [27, 35], 40: [26, 37], 41: [25, 38], 42: [24, 39], 43: [24, 40]},
	{38: [30, 34], 39: [28, 36], 40: [26, 37], 41: [25, 38], 42: [24, 39], 43: [24, 40]},
]
## The crest's light, and the clods trailing east of the heap.
const CRESTS := [[Vector2i(31, 38), Vector2i(32, 38)], [Vector2i(30, 38), Vector2i(31, 38)],
	[Vector2i(32, 38), Vector2i(33, 38)]]
const CLODS := [
	[Vector2i(42, 43), Vector2i(44, 42), Vector2i(46, 43)],
	[Vector2i(41, 42), Vector2i(43, 43), Vector2i(45, 42), Vector2i(47, 43)],
	[Vector2i(42, 42), Vector2i(44, 43), Vector2i(47, 42)],
]

static var _made: Dictionary = {}


## The mound's frame `index`, round and round: A049's when it has landed, the
## drawing until then. Null for anything that is not the mound.
static func texture_at(path: String) -> Texture2D:
	var index := -1
	for i in MOUND_FRAMES:
		if path == MOUND_PATH % i:
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


## One frame of the mound, drawn on A049's canvas.
static func drawing(index: int) -> Image:
	var at := posmod(index, MOUND_FRAMES)
	var size: Vector2i = PlaceholderArt.frame(MOUND_PATH % at).get("canvas", Vector2i(64, 48))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var heap: Dictionary = HEAPS[at]
	for y in heap:
		var span: Array = heap[y]
		for x in range(int(span[0]), int(span[1]) + 1):
			# The top of each column - the heap's outline against the night -
			# in the dark, the rest in the turned earth.
			var top := not heap.has(int(y) - 1) or x < int((heap[int(y) - 1] as Array)[0]) \
				or x > int((heap[int(y) - 1] as Array)[1])
			image.set_pixel(x, int(y), PaletteData.COLOURS[&"ink_soft" if top else &"soil_light"])
	for lit in CRESTS[at]:
		image.set_pixelv(lit as Vector2i, PaletteData.COLOURS[&"bone"])
	for clod in CLODS[at]:
		image.set_pixelv(clod as Vector2i, PaletteData.COLOURS[&"soil_light"])
	return image
