class_name GarlicArt
extends RefCounted

## **The garlic braid** (task 0228): a short wooden stake with a crosspiece and
## a braid of bulbs hanging from it, at A040's canvas and pivot - 16x24
## standing on (8,20), the stake's foot on row 19 and centred on x 8 - in its
## three states:
## - **fresh**, six plump bone-white bulbs on a plait of gold stems;
## - **wilted**, four, shrunken and dulled toward grey, the braid sagging;
## - **spent**, a bare plait of dry stems and two shrivelled bulbs - used up,
##   not broken.
##
## **Drawn in code until 0239 integrates A040** (`PlaceholderArt.is_drawn`):
## made into a texture once each, named for the runtime path it stands for so
## `ArtPlacement` stands it on that path's pivot like the art it stands in
## for, as `DecoyArt` does the decoy. View only: what the garlic does is
## `Garlic`'s and `Pathing`'s.

## The states, by runtime name.
const DRAWN := [&"garlic_braid", &"garlic_braid_wilted", &"garlic_braid_spent"]

## Where each state's bulbs sit - the top left of each - and how big they are:
## fresh 3x2, wilted 2x2, spent 2x1.
const BULBS := {
	&"garlic_braid": [Vector2i(9, 7), Vector2i(10, 9), Vector2i(9, 11), Vector2i(10, 13),
		Vector2i(9, 15), Vector2i(10, 17)],
	&"garlic_braid_wilted": [Vector2i(9, 9), Vector2i(10, 11), Vector2i(9, 13), Vector2i(10, 16)],
	&"garlic_braid_spent": [Vector2i(9, 10), Vector2i(10, 14)],
}
const BULB_SIZE := {&"garlic_braid": Vector2i(3, 2), &"garlic_braid_wilted": Vector2i(2, 2),
	&"garlic_braid_spent": Vector2i(2, 1)}
## How far down the plait hangs from the crosspiece in each state.
const PLAIT_TO := {&"garlic_braid": 17, &"garlic_braid_wilted": 17, &"garlic_braid_spent": 16}

static var _made: Dictionary = {}


## The texture a state of the braid wears: A040's when it has landed, the code
## drawing until then. Null for a name that is not one of the braid's.
static func texture(name: StringName) -> Texture2D:
	if not DRAWN.has(name):
		return null
	var path := path_of(name)
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(name):
		var made := ImageTexture.create_from_image(drawing(name))
		made.resource_name = path
		_made[name] = made
	return _made[name]


## Where A040 delivers a state.
static func path_of(name: StringName) -> String:
	return PlaceholderArt.art_path(name, 0)


## One state, drawn on A040's canvas.
static func drawing(name: StringName) -> Image:
	var frame := PlaceholderArt.frame(path_of(name))
	var size: Vector2i = frame.get("canvas", Vector2i(16, 24))
	var foot: Vector2i = frame.get("pivot", Vector2i(8, 20))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var bottom := foot.y - 1
	var top := 5
	# The stake, two wide on the pivot's column, and the crosspiece near its top.
	for y in range(top, bottom + 1):
		_put(image, foot.x - 1, y, &"wood")
		_put(image, foot.x, y, &"wood_dark")
	for x in range(foot.x - 4, foot.x + 4):
		_put(image, x, top + 1, &"wood_light" if x < foot.x + 2 else &"wood")
	# The plait: a stem down from the crosspiece's east end, gold while it is
	# fresh, dry brown once it is spent.
	var spent := name == &"garlic_braid_spent"
	for y in range(top + 2, int(PLAIT_TO.get(name, 17)) + 1):
		_put(image, foot.x + 2 + (y % 2), y,
			(&"wood_light" if y % 2 else &"wood") if spent else (&"gold_light" if y % 2 else &"gold"))
	# The bulbs.
	var bulb: Vector2i = BULB_SIZE.get(name, Vector2i(2, 2))
	for corner in BULBS.get(name, []):
		var at: Vector2i = corner
		for dy in bulb.y:
			for dx in bulb.x:
				var shade := &"bone"
				if name == &"garlic_braid_wilted":
					shade = &"bone_dark" if dy == 0 else &"stone"
				elif spent:
					shade = &"bone_dark"
				elif dy == bulb.y - 1 and (dx == 0 or dx == bulb.x - 1):
					shade = &"bone_dark"
				_put(image, at.x + dx, at.y + dy, shade)
		# A faint streak on a fresh one.
		if name == &"garlic_braid":
			_put(image, at.x + 1, at.y, &"stone_light")
	_outline(image, bottom)
	return image


## A dark line round what is there, never below `bottom`, so the stake stands
## on the pivot's row.
static func _outline(image: Image, bottom: int) -> void:
	var size := image.get_size()
	var edge: Array = []
	for y in mini(bottom + 1, size.y):
		for x in size.x:
			if image.get_pixel(x, y).a > 0.0:
				continue
			for step in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)]:
				var near: Vector2i = Vector2i(x, y) + step
				if near.x >= 0 and near.y >= 0 and near.x < size.x and near.y < size.y \
						and image.get_pixel(near.x, near.y).a > 0.0:
					edge.append(Vector2i(x, y))
					break
	for at in edge:
		_put(image, (at as Vector2i).x, (at as Vector2i).y, &"ink_soft")


static func _put(image: Image, x: int, y: int, colour: StringName) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, PaletteData.COLOURS.get(colour, Color.MAGENTA))
