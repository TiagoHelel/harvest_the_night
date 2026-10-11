class_name TarpArt
extends RefCounted

## **The day's tarps** (task 0223): the covers the defences sleep under, at
## A044's three footprints - a weathered khaki canvas mound roped round the
## middle and pegged at the base, a torn one over a hurt defence, and the two
## unveil frames the wake plays over the defence: the canvas yanked up to the
## west, then a bundle flying off.
##
## **Drawn in code until 0243 integrates A044** (`PlaceholderArt.is_drawn`):
## made into a texture once each, at the pack's canvas and pivot, so a sprite
## wears it the way it would wear the art. View only: nothing reads one back.

## Where a tarp is, at the change (`Transition.tarp_stage`): on, the two
## unveil frames, off.
enum { COVERED, YANK, AWAY, OFF }

const DIR := "res://sprites/buildings/"

## The mound each footprint's cover makes, before its outline: A044 wants the
## tower's 22-24 wide and 22-26 tall, the tall one's 11-13 by 22-25, the short
## one's 10-12 by 14-17, with the outline counted.
const MOUNDS := {
	&"tarp_tower": Vector2i(22, 24),
	&"tarp_tall": Vector2i(10, 23),
	&"tarp_short": Vector2i(10, 15),
}

## How far the cover reaches across its first rows, in tenths: the
## rounded top.
const TAPER := [5, 7, 8, 9]

static var _made: Dictionary = {}


## The texture a footprint's tarp wears in a stage - A044's when it has landed,
## the code drawing until then. `hurt` asks for the torn cover. Null for `OFF`.
static func texture(footprint: StringName, stage: int, hurt: bool = false) -> Texture2D:
	if stage == OFF:
		return null
	var path := path_of(footprint, stage, hurt)
	if not PlaceholderArt.is_drawn(path) and ResourceLoader.exists(path):
		return load(path)
	if not _made.has(path):
		_made[path] = ImageTexture.create_from_image(drawing(footprint, stage, hurt))
	return _made[path]


## The runtime path a stage of a footprint's tarp lives at (A044's names).
static func path_of(footprint: StringName, stage: int, hurt: bool = false) -> String:
	match stage:
		YANK:
			return PlaceholderArt.art_path(StringName("%s_unveil" % footprint), 0)
		AWAY:
			return PlaceholderArt.art_path(StringName("%s_unveil" % footprint), 1)
	return PlaceholderArt.art_path(StringName("%s_hurt" % footprint) if hurt else footprint, 0)


## A footprint's canvas and pivot, off its registry entry.
static func canvas(footprint: StringName) -> Vector2i:
	return PlaceholderArt.frame(path_of(footprint, COVERED)).get("canvas", Vector2i(16, 16))


static func pivot(footprint: StringName) -> Vector2i:
	return PlaceholderArt.frame(path_of(footprint, COVERED)).get("pivot", Vector2i(8, 16))


# --------------------------------------------------------------- the drawing

## One stage of one footprint's tarp, drawn: the cover (torn when `hurt`)
## grounded on the pivot's row, or an unveil frame in the air above.
static func drawing(footprint: StringName, stage: int, hurt: bool = false) -> Image:
	var size := canvas(footprint)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var mound: Vector2i = MOUNDS.get(footprint, Vector2i(10, 15))
	var foot := pivot(footprint)
	match stage:
		COVERED:
			_mound(image, foot.x, foot.y - 1, mound)
			if hurt:
				_tear(image, foot.x, foot.y - 1, mound)
		YANK:
			_yank(image, size)
		AWAY:
			_away(image, size)
	_outline(image, foot.y - 1 if stage == COVERED else size.y - 1)
	return image


## A lumpy cover: rounded over its top rows, draped straight, a skirt pegged
## out at the base; lit from the upper left, folds down it, a rope round it.
static func _mound(image: Image, centre: int, bottom: int, mound: Vector2i) -> void:
	var top := bottom - mound.y + 1
	var half := mound.x / 2
	var rope := top + mound.y * 9 / 20
	for y in range(top, bottom + 1):
		var row := y - top
		var reach := half
		if row < 4:
			reach = half * int(TAPER[row]) / 10
		elif y >= bottom - 1:
			reach = half + 1
		elif absi(y - rope) <= 1:
			# Cinched where the rope pulls it in.
			reach = half - 1
		for x in range(centre - reach, centre + reach):
			var across := float(x - (centre - reach)) / float(maxi(reach * 2 - 1, 1))
			var colour := &"bone_dark"
			if across > 0.85:
				colour = &"soil_light"
			elif across > 0.62:
				colour = &"wood_light"
			elif x == centre - reach or row == 0:
				# Lit along its upper left edge only: a calm prop, under the
				# farmer and the house in contrast.
				colour = &"bone"
			# Folds hanging from the shoulders.
			if row > 4 and y < bottom - 1 and (x == centre - half / 3 or x == centre + half / 3):
				colour = &"soil_light" if across > 0.5 else &"wood_light"
			if y >= bottom - 1:
				colour = &"soil_dark" if y == bottom else &"wood_light"
			if y == rope:
				colour = &"gold_dark"
			_put(image, x, y, colour)
	# The knot, and a peg either side of the skirt.
	_put(image, centre - 1, rope - 1, &"gold")
	_put(image, centre, rope + 1, &"gold_dark")
	for side in [centre - half - 2, centre + half + 1]:
		for y in range(bottom - 2, bottom + 1):
			_put(image, side, y, &"wood_dark")


## The cover torn: a dark hole where the canvas gave, low on its left under
## the rope - clear of the smoke a hurt defence sends up from its top - a flap
## hanging from it, and the rope snapped beside it: the shadow beneath, never
## the defence.
static func _tear(image: Image, centre: int, bottom: int, mound: Vector2i) -> void:
	var top := bottom - mound.y + 1
	var rope := top + mound.y * 9 / 20
	var wide := maxi(mound.x / 6, 2)
	var deep := maxi(mound.y / 6, 2)
	var hole := Vector2i(centre - mound.x / 4, rope + 2)
	for y in range(hole.y, hole.y + deep):
		for x in range(hole.x, hole.x + wide + (1 if y > hole.y else 0)):
			_put(image, x, y, &"ink")
	# The flap, narrowing as it hangs.
	for step in 3:
		for x in range(hole.x + step / 2, hole.x + wide - step / 2):
			_put(image, x, hole.y + deep + step, &"wood_light")
	# The rope snapped left of the knot, its end hanging over the hole.
	for x in range(centre - mound.x / 2, centre - 1):
		_put(image, x, rope, &"bone_dark" if x > centre - mound.x / 2 else &"bone")
	for y in range(rope, rope + 2):
		_put(image, centre - 2, y, &"gold_dark")


## Unveil, first frame: the canvas whipped up and to the west, bunched in the
## air above where the defence's top is, the lower half gone.
static func _yank(image: Image, size: Vector2i) -> void:
	var right := size.x * 3 / 4
	for x in range(1, right):
		var from := 1 + x * 4 / maxi(right, 1)
		var thick := 4 + (right - x) * 3 / maxi(right, 1)
		for y in range(from, mini(from + thick, size.y - 1)):
			var colour := &"bone" if y == from else (&"wood_light" if (x + y) % 4 == 0 else &"bone_dark")
			_put(image, x, y, colour)
	# The rope trailing from its corner.
	for step in 3:
		_put(image, right + step, 6 + step, &"gold_dark")


## Unveil, second frame: a small crumpled bundle flying off at the upper left.
static func _away(image: Image, size: Vector2i) -> void:
	var middle := Vector2i(mini(5, size.x / 3), 4)
	for y in range(middle.y - 3, middle.y + 3):
		for x in range(middle.x - 3, middle.x + 3):
			var off := Vector2i(x, y) - middle
			if off.x * off.x + off.y * off.y > 9:
				continue
			var colour := &"wood_light" if off.x + off.y > 1 else &"bone_dark"
			_put(image, x, y, colour)
	_put(image, middle.x - 1, middle.y - 1, &"bone")
	_put(image, middle.x + 1, middle.y, &"gold_dark")


## A dark line round what is there, never below `bottom`, so a cover stands
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
