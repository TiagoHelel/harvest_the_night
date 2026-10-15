class_name CatapultArt
extends RefCounted

## **The pumpkin in the air and the splat where it lands** (task 0227): A039's
## shot and burst, the art since task 0238.
##
## - **The shot** tumbles on its 8x8 canvas round (4,4), three frames a tenth
##   of a second each, round and round.
## - **The splat** bursts on its 20x16 canvas on (10,14), four frames a tenth
##   of a second each, once.
##
## View only: where a pumpkin lands is `Towers`'.

## Where A039 delivers them.
const SHOT_PATH := "res://sprites/effects/pumpkin_shot_%d.png"
const SPLAT_PATH := "res://sprites/effects/pumpkin_splat_%d.png"
const SHOT_FRAMES := 3
const SPLAT_FRAMES := 4


## The shot's frames once loaded. **Held here, not only loaded**: the view
## draws the shot with `draw_texture`, which keeps no reference, so a texture
## loaded in `_draw` and dropped when it returns is freed before the frame
## renders - and draws as a white square (task 0238).
static var _shots: Dictionary = {}


## The shot's frame `index`, wrapped round its tumble.
static func shot(index: int) -> Texture2D:
	var at := posmod(index, SHOT_FRAMES)
	if not _shots.has(at):
		var path := SHOT_PATH % at
		_shots[at] = load(path) if ResourceLoader.exists(path) else null
	return _shots[at]


## The shot's frame `seconds` into its tumble, round and round.
static func frame_at(seconds: float) -> int:
	var each := maxf(float(PlaceholderArt.frame(SHOT_PATH % 0).get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % SHOT_FRAMES


## A frame of the splat. Null past its last frame.
static func splat(index: int) -> Texture2D:
	if index < 0 or index >= SPLAT_FRAMES:
		return null
	var path := SPLAT_PATH % index
	return load(path) if ResourceLoader.exists(path) else null


## The splat's pivot and how long a frame shows.
static func splat_pivot() -> Vector2i:
	return PlaceholderArt.frame(SPLAT_PATH % 0).get("pivot", Vector2i(10, 14))


static func splat_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(SPLAT_PATH % 0).get("seconds", 0.1)), 0.01)
