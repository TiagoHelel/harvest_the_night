class_name SpitterArt
extends RefCounted

## **The spitter's glob and its splat** (task 0247): the glob wobbling in the
## air on its 8x8 round (4,4), two frames a tenth of a second each, and the
## splat it leaves up the tower it was spat at, three frames on 12x12 round
## (6,6), once.
##
## **A046's art since task 0260**. The glob is drawn with `draw_texture`,
## which keeps no reference, so its frames are held here: a texture loaded in
## `_draw` and dropped is freed before the frame renders (task 0238). View
## only: where a glob lands is `Enemies`'.

const GLOB_PATH := "res://sprites/effects/spit_%d.png"
const SPLAT_PATH := "res://sprites/effects/spit_splat_%d.png"
const GLOB_FRAMES := 2
const SPLAT_FRAMES := 3

static var _held: Dictionary = {}


## The glob's frame `index`, wrapped round its wobble.
static func glob(index: int) -> Texture2D:
	return _texture(GLOB_PATH % posmod(index, GLOB_FRAMES))


## The glob's frame `seconds` into its wobble, round and round.
static func frame_at(seconds: float) -> int:
	var each := maxf(float(PlaceholderArt.frame(GLOB_PATH % 0).get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % GLOB_FRAMES


## A frame of the splat. Null past its last frame.
static func splat(index: int) -> Texture2D:
	if index < 0 or index >= SPLAT_FRAMES:
		return null
	return _texture(SPLAT_PATH % index)


## The glob's and the splat's pivots, and how long a splat frame shows.
static func glob_pivot() -> Vector2i:
	return PlaceholderArt.frame(GLOB_PATH % 0).get("pivot", Vector2i(4, 4))


static func splat_pivot() -> Vector2i:
	return PlaceholderArt.frame(SPLAT_PATH % 0).get("pivot", Vector2i(6, 6))


static func splat_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(SPLAT_PATH % 0).get("seconds", 0.08)), 0.01)


static func _texture(path: String) -> Texture2D:
	if not _held.has(path):
		_held[path] = load(path) if ResourceLoader.exists(path) else null
	return _held[path]
