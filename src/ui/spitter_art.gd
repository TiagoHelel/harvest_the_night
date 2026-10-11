class_name SpitterArt
extends RefCounted

## **A spitter's glob in the air and its splat** (task 0247): A046's `spit`
## and `spit_splat`, drawn in code through 0120's road until 0260 integrates
## the pack. The spitter itself stands in as the walker, soured
## (`PlaceholderArt`).
##
## - **The glob** is round, five pixels across on its 8x8 canvas round (4,4):
##   `grass_light` in a `leaf_light` rim, a `gold_light` core and a `bone`
##   glint at the top left - a green that is no tower's shot and no fire. No
##   `ink` rim: under the night's relight an inked glob was a dark pebble.
##   Its second frame squashes the first, six wide and four tall, so it
##   wobbles a tenth of a second a frame.
## - **The splat** is three frames on its 12x12 canvas round (6,6), an
##   impact's box: a small blob, the widest splash with its droplets - ten
##   pixels at most - and the drips that are left, 0.08 s each.
##
## Each is named for the runtime path A046 delivers it to, so the day the
## real art lands these load it and the drawings go. View only: where a glob
## lands is `Enemies`'.

## Where A046 delivers them.
const GLOB_PATH := "res://sprites/effects/spit_%d.png"
const SPLAT_PATH := "res://sprites/effects/spit_splat_%d.png"
const GLOB_FRAMES := 2
const SPLAT_FRAMES := 3

## Each glob frame, row by row: the first and last column of each row. The
## rim is whatever of it touches the outside; the rest is the glob.
const GLOBS := [
	{2: [3, 5], 3: [2, 6], 4: [2, 6], 5: [2, 6], 6: [3, 5]},
	{3: [2, 5], 4: [1, 6], 5: [1, 6], 6: [2, 5]},
]
## Where the glint and the core sit on each.
const GLOB_LIT := [Vector2i(3, 3), Vector2i(2, 4)]
const GLOB_CORE := [Vector2i(4, 4), Vector2i(4, 5)]

## Each splat frame the same way, and its droplets: the blob, the splash and
## what drips from it.
const SPLATS := [
	{5: [5, 6], 6: [4, 7], 7: [5, 6]},
	{3: [5, 6], 4: [4, 7], 5: [3, 8], 6: [3, 8], 7: [4, 7], 8: [5, 6]},
	{5: [5, 6], 6: [5, 6]},
]
const DROPLETS := [
	[],
	[Vector2i(1, 5), Vector2i(10, 6), Vector2i(5, 1), Vector2i(2, 2), Vector2i(9, 2),
		Vector2i(2, 9), Vector2i(9, 9), Vector2i(6, 10)],
	[Vector2i(5, 8), Vector2i(6, 9), Vector2i(4, 9), Vector2i(7, 10)],
]

static var _made: Dictionary = {}


## The glob's frame `index`: A046's when it has landed, the drawing until
## then.
static func glob(index: int) -> Texture2D:
	return _texture(GLOB_PATH % posmod(index, GLOB_FRAMES), false, posmod(index, GLOB_FRAMES))


## The glob's frame `seconds` into its wobble, round and round.
static func frame_at(seconds: float) -> int:
	var each := maxf(float(PlaceholderArt.frame(GLOB_PATH % 0).get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % GLOB_FRAMES


## A frame of the splat: A046's when it has landed, the drawing until then.
## Null past its last frame.
static func splat(index: int) -> Texture2D:
	if index < 0 or index >= SPLAT_FRAMES:
		return null
	return _texture(SPLAT_PATH % index, true, index)


## The glob's and the splat's pivots, and how long a splat frame shows.
static func glob_pivot() -> Vector2i:
	return PlaceholderArt.frame(GLOB_PATH % 0).get("pivot", Vector2i(4, 4))


static func splat_pivot() -> Vector2i:
	return PlaceholderArt.frame(SPLAT_PATH % 0).get("pivot", Vector2i(6, 6))


static func splat_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(SPLAT_PATH % 0).get("seconds", 0.08)), 0.01)


static func _texture(path: String, splat: bool, index: int) -> Texture2D:
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(path):
		var made := ImageTexture.create_from_image(splat_drawing(index) if splat else glob_drawing(index))
		made.resource_name = path
		_made[path] = made
	return _made[path]


## One frame of the glob, drawn on A046's canvas.
static func glob_drawing(index: int) -> Image:
	var at := posmod(index, GLOB_FRAMES)
	var image := _canvas(GLOB_PATH % at, Vector2i(8, 8))
	_fill(image, GLOBS[at], &"leaf_light", &"grass_light")
	image.set_pixelv(GLOB_CORE[at] as Vector2i, PaletteData.COLOURS[&"gold_light"])
	image.set_pixelv(GLOB_LIT[at] as Vector2i, PaletteData.COLOURS[&"bone"])
	return image


## One frame of the splat, drawn on A046's canvas: the body without a rim,
## so it reads as wet on a tower rather than as a second glob.
static func splat_drawing(index: int) -> Image:
	var at := clampi(index, 0, SPLAT_FRAMES - 1)
	var image := _canvas(SPLAT_PATH % at, Vector2i(12, 12))
	_fill(image, SPLATS[at], &"leaf_light", &"grass_light")
	for drop in DROPLETS[at]:
		image.set_pixelv(drop as Vector2i, PaletteData.COLOURS[&"grass_light"])
	if at < 2:
		image.set_pixel(5, 5, PaletteData.COLOURS[&"bone"])
		image.set_pixel(6, 6, PaletteData.COLOURS[&"gold_light"])
	return image


static func _canvas(path: String, fallback: Vector2i) -> Image:
	var size: Vector2i = PlaceholderArt.frame(path).get("canvas", fallback)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


## A shape from its rows: every pixel with a side on the outside in `rim`,
## the rest in `body`.
static func _fill(image: Image, rows: Dictionary, rim: StringName, body: StringName) -> void:
	for y in rows:
		var span: Array = rows[y]
		for x in range(int(span[0]), int(span[1]) + 1):
			var inside := true
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				inside = inside and _in(rows, Vector2i(x, int(y)) + step)
			image.set_pixel(x, int(y), PaletteData.COLOURS[body if inside else rim])


static func _in(rows: Dictionary, cell: Vector2i) -> bool:
	if not rows.has(cell.y):
		return false
	var span: Array = rows[cell.y]
	return cell.x >= int(span[0]) and cell.x <= int(span[1])
