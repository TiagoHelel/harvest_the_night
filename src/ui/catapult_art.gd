class_name CatapultArt
extends RefCounted

## **The pumpkin in the air and the splat where it lands** (task 0227): A039's
## shot and burst, through 0120's road until 0238 integrates the pack.
##
## - **The shot** is drawn in code (`PlaceholderArt.is_drawn`): a round
##   pumpkin six pixels across on its 8x8 canvas round (4,4), its rind the
##   palette's `flame` lit `flame_hot` at the top left, one `gold_dark` groove
##   down its middle and its stem `wood_dark`, tumbling - the stem at 12, 4
##   and 8 o'clock, a tenth of a second each. Light enough to stay a round
##   thing in the air under the night's relight, which greys it as it greys
##   a mortar's shell.
## - **The splat** stands in as the water's splash, in pumpkin: the same
##   20x16 burst on (10,14), four frames a tenth of a second each, tinted by
##   its `ART` entry.
##
## Each is named for the runtime path A039 delivers it to, so the day the real
## art lands these load it and the stand-ins go. View only: where a pumpkin
## lands is `Towers`'.

## Where A039 delivers them.
const SHOT_PATH := "res://sprites/effects/pumpkin_shot_%d.png"
const SPLAT_PATH := "res://sprites/effects/pumpkin_splat_%d.png"
const SHOT_FRAMES := 3
const SPLAT_FRAMES := 4

## The rind, row by row: the first and last column of each row (y 2..6).
const RIND := {2: [2, 5], 3: [1, 6], 4: [1, 6], 5: [1, 6], 6: [2, 5]}
## The light on the rind, and the groove down its middle.
const LIT := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3)]
const GROOVE := [Vector2i(4, 3), Vector2i(4, 4), Vector2i(4, 5)]
## The stem in each frame: 12, 4 and 8 o'clock round the rind.
const STEMS := [Vector2i(4, 1), Vector2i(6, 6), Vector2i(1, 6)]

static var _made: Dictionary = {}


## The shot's frame `index`: A039's when it has landed, the drawing until then.
static func shot(index: int) -> Texture2D:
	var at := posmod(index, SHOT_FRAMES)
	var path := SHOT_PATH % at
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(at):
		var made := ImageTexture.create_from_image(drawing(at))
		made.resource_name = path
		_made[at] = made
	return _made[at]


## The shot's frame `seconds` into its tumble, round and round.
static func frame_at(seconds: float) -> int:
	var each := maxf(float(PlaceholderArt.frame(SHOT_PATH % 0).get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % SHOT_FRAMES


## One frame of the shot, drawn on A039's canvas.
static func drawing(index: int) -> Image:
	var frame := PlaceholderArt.frame(SHOT_PATH % posmod(index, SHOT_FRAMES))
	var size: Vector2i = frame.get("canvas", Vector2i(8, 8))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in RIND:
		var span: Array = RIND[y]
		for x in range(int(span[0]), int(span[1]) + 1):
			image.set_pixel(x, int(y), PaletteData.COLOURS[&"flame"])
	for lit in LIT:
		image.set_pixel((lit as Vector2i).x, (lit as Vector2i).y, PaletteData.COLOURS[&"flame_hot"])
	for groove in GROOVE:
		image.set_pixel((groove as Vector2i).x, (groove as Vector2i).y, PaletteData.COLOURS[&"gold_dark"])
	var stem: Vector2i = STEMS[posmod(index, SHOT_FRAMES)]
	image.set_pixel(stem.x, stem.y, PaletteData.COLOURS[&"wood_dark"])
	return image


## A frame of the splat: A039's when it has landed, the splash's stand-in
## until then. Null past its last frame.
static func splat(index: int) -> Texture2D:
	if index < 0 or index >= SPLAT_FRAMES:
		return null
	var file := PlaceholderArt.texture_path(SPLAT_PATH % index)
	return load(file) if not file.is_empty() and ResourceLoader.exists(file) else null


## The splat's tint while it stands in (white once A039 has landed), its
## pivot and how long a frame shows.
static func splat_tint() -> Color:
	return PlaceholderArt.art_tint(&"pumpkin_splat")


static func splat_pivot() -> Vector2i:
	return PlaceholderArt.frame(SPLAT_PATH % 0).get("pivot", Vector2i(10, 14))


static func splat_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(SPLAT_PATH % 0).get("seconds", 0.1)), 0.01)
