class_name StrongWallArt
extends RefCounted

## **The hardwood wall and the sandbags** (task 0231): A043's two barrier
## families at its canvas and pivot - 16x32 standing on (8,28), as the stone
## wall and the fence do - drawn in code until 0242 integrates the pack
## (`PlaceholderArt.is_drawn`). Each is three modules, whole and hurt,
## composed into its 32 masks with the contract's recipe (`JoinRecipe`), and a
## wreck:
## - **the hardwood wall** (`wall_2`, the stone wall's level two): the stone
##   wall's own modules with heavy hardwood laid over their stone - a cap,
##   two plank bands and an iron strap round the pier, two bolted beams along
##   the span, beams down the north-south run with straps across it - on
##   exactly the stone's pixels, so its silhouette is the stone wall's and a
##   run of the two has no step; its wreck the stone heap with broken beams;
## - **the sandbags** (`sandbag_wall`): plump burlap sacks tied with twine,
##   low - three stacked for the post, two staggered courses for the span, a
##   line of them for the north-south run; hurt, a sack slumped or gone and
##   sand spilled in the pile; the wreck burst sacks lying flat.
##
## Made into a texture once, named for the runtime path it stands for, so
## `ArtPlacement` stands it on that path's pivot like the art it stands in
## for. View only: what the walls do is `Pathing`'s, `Enemies`' and
## `Building`'s.

const HARDWOOD := "wall_2"
const SANDBAGS := "sandbag_wall"
const FAMILIES := [HARDWOOD, SANDBAGS]
const PARTS := [&"post", &"horizontal", &"vertical"]

## The stone the hardwood is laid over: the wall's modules and its wreck.
const STONE_MODULE := "res://sprites/buildings/modules/wall_%s%s.png"
const STONE_WRECK := "res://sprites/buildings/wall_wreck.png"

## **The hardwood over the pier**: a colour for each row it bands, laid on the
## stone's pixels in that row - the cap, two plank bands, the iron strap -
## and the strap's bolt.
const PIER_BANDS := {5: &"wood_light", 6: &"wood", 9: &"wood", 10: &"wood_dark", 12: &"ink",
	15: &"wood", 16: &"wood_dark"}
const PIER_BOLT := Vector2i(8, 12)
## Over the span: two beams, each a lit row on a dark one, and their bolts.
const SPAN_BANDS := {13: &"wood", 14: &"wood_dark", 17: &"wood", 18: &"wood_dark"}
const SPAN_BOLTS := [Vector2i(3, 13), Vector2i(11, 13), Vector2i(7, 17), Vector2i(15, 17)]
## Down the north-south run: a beam each side of its stone, straps across.
const RUN_BEAMS := {7: &"wood", 9: &"wood_dark"}
const RUN_STRAPS := [12, 18, 24]
## The stone's outline - `night` and `ink` - which the hardwood never covers.
const OUTLINE_LUMA := 0.2

## **The sacks**, as rects on the canvas, by module, whole and hurt.
const SACKS := {
	&"post": [Rect2i(3, 16, 5, 4), Rect2i(8, 16, 5, 4), Rect2i(5, 12, 6, 4)],
	&"post_hurt": [Rect2i(3, 16, 5, 4), Rect2i(8, 16, 5, 4), Rect2i(6, 14, 6, 2)],
	&"horizontal": [Rect2i(0, 16, 5, 4), Rect2i(5, 16, 6, 4), Rect2i(11, 16, 5, 4),
		Rect2i(2, 12, 6, 4), Rect2i(8, 12, 6, 4)],
	&"horizontal_hurt": [Rect2i(0, 16, 5, 4), Rect2i(5, 16, 6, 4), Rect2i(11, 16, 5, 4),
		Rect2i(2, 13, 6, 3)],
	&"vertical": [Rect2i(5, 8, 7, 4), Rect2i(5, 12, 7, 4), Rect2i(5, 16, 7, 4),
		Rect2i(5, 20, 7, 4), Rect2i(5, 24, 7, 4)],
	&"vertical_hurt": [Rect2i(5, 8, 7, 4), Rect2i(5, 12, 7, 4), Rect2i(5, 20, 7, 4),
		Rect2i(5, 24, 7, 4)],
}
## Sand spilled in a hurt pile, and the slit a sack burst through.
const SAND := {&"post_hurt": [Vector2i(5, 15), Vector2i(12, 15), Vector2i(13, 19)],
	&"horizontal_hurt": [Vector2i(9, 15), Vector2i(10, 15), Vector2i(12, 15)],
	&"vertical_hurt": [Vector2i(7, 17), Vector2i(8, 18), Vector2i(9, 17)]}
const SLITS := {&"post_hurt": [Vector2i(8, 14), Vector2i(9, 14)],
	&"horizontal_hurt": [Vector2i(4, 14), Vector2i(5, 14)],
	&"vertical_hurt": [Vector2i(7, 13), Vector2i(8, 13)]}

static var _made: Dictionary = {}
static var _stone: Dictionary = {}


## Every runtime name either family stands under: its 32 masks and its wreck.
static func names() -> Array:
	var out: Array = []
	for family in FAMILIES:
		out.append_array(JoinRecipe.names(family))
		out.append(wreck_of(family))
	return out


static func wreck_of(family: String) -> StringName:
	return StringName(family + "_wreck")


## The family a runtime name belongs to, or "".
static func family_of(id: StringName) -> String:
	for family in FAMILIES:
		if str(id) == str(wreck_of(family)) or int(JoinRecipe.parse(family, str(id))[0]) >= 0:
			return family
	return ""


## The drawing a runtime name wears while A043 has not landed. Null for a name
## that is neither family's, and for any once the pack's art is there.
static func texture(id: StringName) -> Texture2D:
	if family_of(id).is_empty():
		return null
	var path := path_of(id)
	if not PlaceholderArt.is_drawn(path):
		return null
	if not _made.has(id):
		var made := ImageTexture.create_from_image(drawing(id))
		made.resource_name = path
		_made[id] = made
	return _made[id]


## **The hotbar's picture of the sandbags**: a straight run, the post with a
## span either side. Null for anything else - the hardwood wall is an upgrade,
## not a slot.
static func icon(id: StringName) -> Texture2D:
	return texture(JoinRecipe.name_of(SANDBAGS, 10, false)) if str(id) == SANDBAGS else null


## Where A043 delivers a runtime name.
static func path_of(id: StringName) -> String:
	return "res://sprites/buildings/%s.png" % id


## One runtime name, drawn on A043's canvas: a wreck, or a mask composed from
## its family's modules.
static func drawing(id: StringName) -> Image:
	var family := family_of(id)
	if str(id) == str(wreck_of(family)):
		return _hardwood_wreck() if family == HARDWOOD else _sandbag_wreck()
	var join := JoinRecipe.parse(family, str(id))
	var hurt := bool(join[1])
	var modules := {}
	for part in PARTS:
		modules[part] = module(family, part, hurt)
	return JoinRecipe.compose(modules, maxi(int(join[0]), 0))


## One module of a family - `post`, `horizontal` or `vertical` - whole or hurt.
static func module(family: String, part: StringName, hurt: bool) -> Image:
	if family == HARDWOOD:
		return _hardwood(part, hurt)
	var image := _blank()
	var key := StringName(str(part) + ("_hurt" if hurt else ""))
	for rect in SACKS.get(key, []):
		_sack(image, rect as Rect2i)
	for slit in SLITS.get(key, []):
		_put(image, (slit as Vector2i).x, (slit as Vector2i).y, &"ink_soft")
	for grain in SAND.get(key, []):
		_put(image, (grain as Vector2i).x, (grain as Vector2i).y, &"gold_light")
	return image


## **A stone module rebuilt in hardwood**: the hardwood laid over the stone's
## own pixels, so its shape is the stone's. Hurt, the stone's hurt module,
## a plank band split, the strap sprung and a beam broken.
static func _hardwood(part: StringName, hurt: bool) -> Image:
	var image := _stone_image(STONE_MODULE % [part, "_hurt" if hurt else ""])
	match part:
		&"post":
			for y in PIER_BANDS:
				for x in image.get_width():
					var split := hurt and int(y) in [9, 10] and x in [7, 8]
					var sprung := hurt and int(y) == 12 and x > 7
					if not split and not sprung:
						_paint(image, x, int(y), PIER_BANDS[y])
			if not hurt:
				_paint(image, PIER_BOLT.x, PIER_BOLT.y, &"stone_light")
		&"horizontal":
			for y in SPAN_BANDS:
				for x in image.get_width():
					if not (hurt and int(y) in [13, 14] and x >= 6 and x <= 9):
						_paint(image, x, int(y), SPAN_BANDS[y])
			for bolt in SPAN_BOLTS:
				if not (hurt and (bolt as Vector2i).y == 13):
					_paint(image, (bolt as Vector2i).x, (bolt as Vector2i).y, &"stone_light")
		&"vertical":
			for x in RUN_BEAMS:
				for y in image.get_height():
					if not (hurt and int(x) == 9 and y >= 15 and y <= 20):
						_paint(image, int(x), y, RUN_BEAMS[x])
			for y in RUN_STRAPS:
				if hurt and int(y) == 18:
					continue
				for x in image.get_width():
					_paint(image, x, int(y), &"ink")
				_paint(image, 8, int(y), &"stone_light")
	return image


## **The hardwood wall's wreck**: the stone wall's heap with two broken beams
## lying in it.
static func _hardwood_wreck() -> Image:
	var image := _stone_image(STONE_WRECK)
	for piece in [Vector2i(3, 22), Vector2i(4, 22), Vector2i(5, 23), Vector2i(6, 23)]:
		_put(image, (piece as Vector2i).x, (piece as Vector2i).y, &"wood_dark")
	for piece in [Vector2i(9, 22), Vector2i(10, 22), Vector2i(11, 22), Vector2i(12, 23)]:
		_put(image, (piece as Vector2i).x, (piece as Vector2i).y, &"wood")
	return image


## **The sandbags' wreck**: two burst sacks lying flat on the cell, sand
## spilled from them - rows 24-27.
static func _sandbag_wreck() -> Image:
	var image := _blank()
	_sack(image, Rect2i(1, 24, 6, 3))
	_sack(image, Rect2i(6, 25, 8, 3))
	for slit in [Vector2i(9, 26), Vector2i(10, 26), Vector2i(3, 25)]:
		_put(image, (slit as Vector2i).x, (slit as Vector2i).y, &"ink_soft")
	for grain in [Vector2i(11, 24), Vector2i(12, 24), Vector2i(5, 27), Vector2i(13, 27)]:
		_put(image, (grain as Vector2i).x, (grain as Vector2i).y, &"gold_light")
	return image


## **One sack** filling `rect`: its corners rounded off, a dark burlap edge, the
## top lit and the bottom shaded, and its twine at the top's middle.
static func _sack(image: Image, rect: Rect2i) -> void:
	var last := rect.end - Vector2i.ONE
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var corner := (x == rect.position.x or x == last.x) and (y == rect.position.y or y == last.y)
			if corner:
				continue
			var edge := x == rect.position.x or x == last.x or y == rect.position.y or y == last.y
			var colour := &"soil_dark" if edge else (&"soil" if y == last.y - 1 else &"soil_light")
			if not edge and y == rect.position.y + 1 and x <= rect.position.x + 2:
				colour = &"wood_light"
			_put(image, x, y, colour)
	_put(image, rect.position.x + rect.size.x / 2, rect.position.y, &"bone_dark")


## A stone drawing as an editable image, loaded once.
static func _stone_image(path: String) -> Image:
	if not _stone.has(path):
		var texture: Texture2D = load(path)
		var image := texture.get_image()
		image.convert(Image.FORMAT_RGBA8)
		_stone[path] = image
	return (_stone[path] as Image).duplicate()


static func _blank() -> Image:
	var size: Vector2i = PlaceholderArt.frame(path_of(StringName(SANDBAGS))).get("canvas", Vector2i(16, 32))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


## A colour on a pixel the stone already has, and nowhere else - never on its
## dark outline, so the hardwood sits inside the stone's edge.
static func _paint(image: Image, x: int, y: int, colour: StringName) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var there := image.get_pixel(x, y)
	if there.a > 0.0 and there.get_luminance() >= OUTLINE_LUMA:
		image.set_pixel(x, y, PaletteData.COLOURS[colour])


static func _put(image: Image, x: int, y: int, colour: StringName) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, PaletteData.COLOURS[colour])
