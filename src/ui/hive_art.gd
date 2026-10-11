class_name HiveArt
extends RefCounted

## **The bee swarm** (task 0226): A038's tiny looping cloud, hung on whatever
## a hive has stung for as long as the sting lasts - three frames on its 8x8
## canvas round (4,4), five bees of two pixels each, a gold body with an ink
## stripe east of it, shuffling a pixel or two a frame and never leaving x 1..6
## and y 1..6.
##
## **Drawn in code until 0237 integrates A038** (`PlaceholderArt.is_drawn`):
## made into a texture once a frame, named for the runtime path it stands for,
## as `DecoyArt` does the decoy. The hive itself is a stand-in texture - the
## mortar in honey - and needs nothing here. View only: the sting is
## `Combat`'s.

## Where the bees are in each frame (A038's `cloud_a`, `cloud_b`, `cloud_c`):
## the gold pixel of each, its stripe one to the east.
const BEES := [
	[Vector2i(1, 2), Vector2i(4, 1), Vector2i(2, 5), Vector2i(5, 3), Vector2i(4, 6)],
	[Vector2i(2, 1), Vector2i(5, 2), Vector2i(1, 4), Vector2i(4, 4), Vector2i(3, 6)],
	[Vector2i(3, 1), Vector2i(1, 3), Vector2i(4, 2), Vector2i(5, 4), Vector2i(2, 6)],
]

static var _made: Dictionary = {}


## The swarm's frame `index`: A038's when it has landed, the drawing until
## then.
static func swarm(index: int) -> Texture2D:
	var at := posmod(index, BEES.size())
	var path := path_of(at)
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(at):
		var made := ImageTexture.create_from_image(drawing(at))
		made.resource_name = path
		_made[at] = made
	return _made[at]


## Where A038 delivers a frame of the swarm.
static func path_of(index: int) -> String:
	return PlaceholderArt.art_path(&"bee_swarm", index)


## The frame to show `seconds` into the loop: A038's tenth of a second each,
## round and round, the last leading back to the first.
static func frame_at(seconds: float) -> int:
	var entry := PlaceholderArt.art(&"bee_swarm")
	var each := maxf(float(entry.get("seconds", 0.1)), 0.01)
	return int(floorf(maxf(seconds, 0.0) / each)) % BEES.size()


## One frame, drawn on A038's canvas.
static func drawing(index: int) -> Image:
	var frame := PlaceholderArt.frame(path_of(index))
	var size: Vector2i = frame.get("canvas", Vector2i(8, 8))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for bee in BEES[posmod(index, BEES.size())]:
		var at: Vector2i = bee
		image.set_pixel(at.x, at.y, PaletteData.COLOURS[&"gold_light"])
		image.set_pixel(at.x + 1, at.y, PaletteData.COLOURS[&"ink"])
	return image
