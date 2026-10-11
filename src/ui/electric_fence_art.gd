class_name ElectricFenceArt
extends RefCounted

## **The electric fence and its zap** (task 0230): A042's barrier at its
## canvas and pivot - 16x32 standing on (8,28), as the wooden fence does -
## drawn in code until 0241 integrates the pack (`PlaceholderArt.is_drawn`):
## - **three modules**, whole and hurt: a dark iron post with a cap and a
##   white ceramic insulator either side of it at each wire, on x 5-10 and
##   rows 7-19; a span of two taut copper wires with ink undersides across
##   x 0-15, on rows 13 and 17 - rows the wooden fence's span has too, so a
##   mixed run meets it on four; and the north-south run seen from above,
##   two wires down x 7 and 9 on rows 11-27;
## - **the 32 joins composed from them** with the contract's recipe (its
##   section 2.3: N, W, E, S, then the post on top), as A042's `build.py`
##   will compose them;
## - **the wreck**, a low tangle of a fallen post and coiled wire on rows
##   21-27;
## - **the zap**, A042's three 12x12 frames round (6,6): a spark, the arcs at
##   their widest, a few specks fading.
##
## Each is made into a texture once, named for the runtime path it stands for,
## so `ArtPlacement` stands it on that path's pivot like the art it stands in
## for, as `GarlicArt` does the braid. **Dark metal until the zap plays**: no
## glow is drawn into any of it. View only: what the fence does is
## `Enemies`' and `Pathing`'s.

const ID := &"electric_fence"
const WRECK := &"electric_fence_wreck"
const ZAP_PATH := "res://sprites/effects/zap_%d.png"
const ZAP_FRAMES := 3

## The recipe (ART-CONTRACT 2.3): the bit, the module, the slice of it and
## where the slice is pasted, in the order they are pasted - the post last.
const RECIPE := [
	[1, &"vertical", Rect2i(0, 8, 16, 20), Vector2i(0, 0)],
	[8, &"horizontal", Rect2i(0, 0, 8, 32), Vector2i(0, 0)],
	[2, &"horizontal", Rect2i(8, 0, 8, 32), Vector2i(8, 0)],
	[4, &"vertical", Rect2i(0, 8, 16, 20), Vector2i(0, 8)],
]

## The wires' rows on the span, and the post's columns.
const WIRES := [13, 17]
const POST_LEFT := 6
const POST_RIGHT := 9
const POST_TOP := 7
const POST_FOOT := 19

## The zap's pixels by frame: `[x, y, colour]`, round the centre (6,6).
const ZAP := [
	# The spark: small, white at the heart.
	[[6, 6, &"moon"], [5, 6, &"water_light"], [7, 6, &"water_light"], [6, 5, &"water_light"],
		[6, 7, &"water_light"], [4, 4, &"moon"], [8, 8, &"moon"], [8, 4, &"flame_hot"]],
	# The arcs at their widest: four jagged ones out to the corners, three
	# warm specks between them.
	[[6, 6, &"moon"], [5, 5, &"moon"], [5, 4, &"water_light"], [4, 3, &"moon"], [3, 3, &"water_light"],
		[2, 2, &"moon"], [7, 5, &"moon"], [8, 5, &"water_light"], [8, 4, &"moon"], [9, 3, &"water_light"],
		[10, 2, &"moon"], [7, 7, &"moon"], [7, 8, &"water_light"], [8, 9, &"moon"], [9, 9, &"water_light"],
		[10, 10, &"moon"], [5, 7, &"moon"], [4, 7, &"water_light"], [3, 8, &"moon"], [3, 9, &"water_light"],
		[2, 10, &"moon"], [1, 6, &"flame_hot"], [10, 6, &"flame_hot"], [6, 1, &"flame_hot"]],
	# Fading: a few specks where the arcs were.
	[[6, 6, &"water_light"], [3, 3, &"moon"], [9, 3, &"water_light"], [9, 9, &"moon"],
		[3, 9, &"water_light"], [6, 10, &"flame_hot"]],
]

static var _made: Dictionary = {}


## Every runtime name the fence stands under: the sixteen masks whole - mask
## 0 is the bare `electric_fence` - the sixteen hurt, and the wreck.
static func names() -> Array:
	var out: Array = []
	for hurt in ["", "_hurt"]:
		for mask in 16:
			out.append(name_of(mask, hurt == "_hurt"))
	out.append(WRECK)
	return out


## The runtime name of a mask, whole or hurt: what `WorldView._barrier_name()`
## asks for.
static func name_of(mask: int, hurt: bool) -> StringName:
	return StringName(str(ID) + ("_join_%d" % mask if mask > 0 else "") + ("_hurt" if hurt else ""))


## The drawing a runtime name wears while A042 has not landed. Null for a name
## that is not the fence's, and for any once the pack's art is there.
static func texture(id: StringName) -> Texture2D:
	if not str(id).begins_with(str(ID)):
		return null
	var path := path_of(id)
	if not PlaceholderArt.is_drawn(path):
		return null
	if not _made.has(id):
		var made := ImageTexture.create_from_image(drawing(id))
		made.resource_name = path
		_made[id] = made
	return _made[id]


## **The hotbar's picture of it**: a straight run - the post with a span
## either side - which reads as a fence where the bare post reads as a stick.
## Null for anything else.
static func icon(id: StringName) -> Texture2D:
	return texture(name_of(10, false)) if id == ID else null


## Where A042 delivers a runtime name.
static func path_of(id: StringName) -> String:
	return "res://sprites/buildings/%s.png" % id


## One runtime name, drawn on A042's canvas: the wreck, or a mask composed
## from the modules.
static func drawing(id: StringName) -> Image:
	if id == WRECK:
		return _wreck()
	var name := str(id)
	var hurt := name.ends_with("_hurt")
	var mask := 0
	var at := name.find("_join_")
	if at >= 0:
		mask = int(name.substr(at + 6).trim_suffix("_hurt"))
	return compose(mask, hurt)


## **A mask composed with the recipe**: each arm's slice pasted where the
## table says, the post over them.
static func compose(mask: int, hurt: bool) -> Image:
	var image := _blank()
	for step in RECIPE:
		if mask & int(step[0]):
			var part := module(StringName(step[1]), hurt)
			image.blend_rect(part, step[2] as Rect2i, step[3] as Vector2i)
	var post := module(&"post", hurt)
	image.blend_rect(post, Rect2i(Vector2i.ZERO, post.get_size()), Vector2i.ZERO)
	return image


## One module - `post`, `horizontal` or `vertical` - whole or hurt.
static func module(part: StringName, hurt: bool) -> Image:
	var image := _blank()
	match part:
		&"post":
			_post(image, hurt)
		&"horizontal":
			_span(image, hurt)
		&"vertical":
			_run(image, hurt)
	return image


## **The post**: dark iron on x 6-9, a cap on row 7, standing on row 20 - its
## foot on row 19 - ringed by a white ceramic insulator at each wire, inside
## its ink: a white pixel against the snow would be the snow by night. Hurt,
## its top is bent a pixel east, one insulator is cracked and one chipped.
static func _post(image: Image, hurt: bool) -> void:
	for y in range(POST_TOP + 1, POST_FOOT):
		var lean := 1 if hurt and y <= 12 else 0
		_put(image, POST_LEFT + lean, y, &"night")
		_put(image, POST_LEFT + 1 + lean, y, &"stone" if y > POST_TOP + 1 else &"stone_light")
		_put(image, POST_LEFT + 2 + lean, y, &"stone_dark")
		_put(image, POST_RIGHT + lean, y, &"night")
	var cap := 1 if hurt else 0
	_put(image, POST_LEFT + 1 + cap, POST_TOP, &"ink")
	_put(image, POST_LEFT + 2 + cap, POST_TOP, &"ink")
	_put(image, POST_LEFT + 1, POST_FOOT, &"night")
	_put(image, POST_LEFT + 2, POST_FOOT, &"night")
	for y in WIRES:
		_put(image, POST_LEFT + 1, int(y), &"bone")
		_put(image, POST_LEFT + 2, int(y), &"bone_dark")
	if hurt:
		_put(image, POST_LEFT + 2, WIRES[0], &"bone")
		_put(image, POST_LEFT + 1, WIRES[0], &"bone_dark")
		_put(image, POST_LEFT + 2, WIRES[1], &"stone_dark")


## **The span**: two taut copper wires the width of the cell, ink under each,
## a glint on each. Hurt, the upper one is snapped either side of the post and
## its ends hang - outside the post, so the break shows.
static func _span(image: Image, hurt: bool) -> void:
	for y in WIRES:
		for x in 16:
			if hurt and int(y) == WIRES[0] and x >= 4 and x <= 11:
				continue
			_put(image, x, int(y), &"skin_dark")
			_put(image, x, int(y) + 1, &"night")
	_put(image, 2, WIRES[0], &"skin")
	_put(image, 13, WIRES[1], &"skin")
	if hurt:
		for hang in [Vector2i(4, 14), Vector2i(4, 15), Vector2i(5, 16), Vector2i(11, 14), Vector2i(11, 15)]:
			_put(image, (hang as Vector2i).x, (hang as Vector2i).y, &"skin_dark")


## **The north-south run** seen from above: two copper wires down x 7 and 9,
## ink between them, rows 11-27. Hurt, the east one is snapped and its ends
## spring out.
static func _run(image: Image, hurt: bool) -> void:
	for y in range(11, 28):
		_put(image, 7, y, &"skin_dark")
		_put(image, 8, y, &"night")
		if not (hurt and y >= 16 and y <= 21):
			_put(image, 9, y, &"skin_dark")
	_put(image, 7, 14, &"skin")
	if hurt:
		_put(image, 10, 16, &"skin_dark")
		_put(image, 10, 21, &"skin_dark")


## **The wreck**: a fallen post across the cell, coiled wire over it and a
## broken insulator - rows 21-27, x 2-13.
static func _wreck() -> Image:
	var image := _blank()
	for x in range(2, 13):
		_put(image, x, 24, &"stone_dark" if x % 3 else &"stone")
		_put(image, x, 25, &"night")
	for coil in [Vector2i(6, 21), Vector2i(7, 21), Vector2i(5, 22), Vector2i(8, 22), Vector2i(4, 23),
			Vector2i(6, 23), Vector2i(7, 23), Vector2i(9, 23), Vector2i(3, 26), Vector2i(5, 26),
			Vector2i(10, 26), Vector2i(12, 26), Vector2i(2, 27), Vector2i(3, 27), Vector2i(7, 27),
			Vector2i(8, 27), Vector2i(12, 27), Vector2i(13, 27)]:
		_put(image, (coil as Vector2i).x, (coil as Vector2i).y, &"skin_dark")
	_put(image, 11, 22, &"bone")
	_put(image, 12, 23, &"bone_dark")
	return image


## The zap's frame `index` - A042's once it has landed, the drawing until
## then - or null past its last.
static func zap(index: int) -> Texture2D:
	if index < 0 or index >= ZAP_FRAMES:
		return null
	var path := ZAP_PATH % index
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	var key := StringName("zap_%d" % index)
	if not _made.has(key):
		var made := ImageTexture.create_from_image(zap_drawing(index))
		made.resource_name = path
		_made[key] = made
	return _made[key]


## One frame of the zap, drawn on A042's canvas.
static func zap_drawing(index: int) -> Image:
	var frame := PlaceholderArt.frame(ZAP_PATH % clampi(index, 0, ZAP_FRAMES - 1))
	var size: Vector2i = frame.get("canvas", Vector2i(12, 12))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for dot in ZAP[clampi(index, 0, ZAP_FRAMES - 1)]:
		_put(image, int(dot[0]), int(dot[1]), StringName(dot[2]))
	return image


## How long a zap frame shows, and where it is held.
static func zap_seconds() -> float:
	return maxf(float(PlaceholderArt.frame(ZAP_PATH % 0).get("seconds", 0.065)), 0.01)


static func zap_pivot() -> Vector2i:
	return PlaceholderArt.frame(ZAP_PATH % 0).get("pivot", Vector2i(6, 6))


static func _blank() -> Image:
	var size: Vector2i = PlaceholderArt.frame(path_of(ID)).get("canvas", Vector2i(16, 32))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


static func _put(image: Image, x: int, y: int, colour: StringName) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, PaletteData.COLOURS[colour])
