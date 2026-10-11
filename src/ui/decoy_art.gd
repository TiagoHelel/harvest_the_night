class_name DecoyArt
extends RefCounted

## **The decoy** (task 0224): a straw dummy lashed to a wooden T-stake, at
## A037's canvas and pivot - 16x32 standing on (8,28), the stake's foot on row
## 27 and centred on x 8 - whole; hurt, the shirt torn and straw spilling, the
## head slumped and an arm hanging off the crossbar; and wrecked, the stake
## snapped over a heap of straw with the sack head rolled off it. **And the
## zombie bait** (task 0225), A037's other drawing: a fish rotting belly-up on
## the ground, 16x16 lying on (8,14).
##
## **Drawn in code until 0236 integrates A037** (`PlaceholderArt.is_drawn`):
## made into a texture once each, named for the runtime path it stands for so
## `ArtPlacement` stands it on that path's pivot like the art it stands in for.
## No hat, no lit eyes and none of the farmer's blue: a cheap target, not the
## porch guardian. View only, like the lean it makes when it is struck.

## The decoy's states, by runtime name.
const STATES := [&"decoy", &"decoy_hurt", &"decoy_wreck"]

## Everything here, the bait with them.
const DRAWN := [&"decoy", &"decoy_hurt", &"decoy_wreck", &"zombie_bait"]

## **The sway when it is struck**: A037's three poses as how far the top of
## the straw leans, in pixels - two west, one back east, one west - a tenth of
## a second each, whoever bit it; then upright. Until A037's strips land the
## view leans the whole drawing that far about the stake's foot.
const SWAY_TOPS := [-2.0, 1.0, -1.0]
const SWAY_SECONDS := 0.1

## How far the top of the straw stands over the stake's foot, for the lean.
const HEIGHT := 24.0

static var _made: Dictionary = {}


## The texture a state of the decoy wears: A037's when it has landed, the code
## drawing until then. Null for a name that is not one of the decoy's.
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


## Where A037 delivers a state.
static func path_of(name: StringName) -> String:
	return PlaceholderArt.art_path(name, 0)


## How far the top leans `age` seconds after a bite, in pixels: west is
## negative. Upright before the first pose's time is up and after the last.
static func lean(age: float) -> float:
	if age < 0.0 or age >= SWAY_SECONDS * SWAY_TOPS.size():
		return 0.0
	return float(SWAY_TOPS[mini(int(age / SWAY_SECONDS), SWAY_TOPS.size() - 1)])


## The skew that leans the top that far, the stake's foot staying put: a
## sprite's skew moves a point `-sin(skew)` pixels per pixel above its origin.
static func skew_for(top: float) -> float:
	return asin(clampf(top / HEIGHT, -1.0, 1.0))


# --------------------------------------------------------------- the drawing

## One state, drawn on A037's canvas.
static func drawing(name: StringName) -> Image:
	var frame := PlaceholderArt.frame(path_of(name))
	var size: Vector2i = frame.get("canvas", Vector2i(16, 32))
	var foot: Vector2i = frame.get("pivot", Vector2i(8, 28))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var bottom := foot.y - 1
	match name:
		&"decoy_hurt":
			_hurt(image, foot.x, bottom)
		&"decoy_wreck":
			_wreck(image, foot.x, bottom)
		&"zombie_bait":
			_bait(image, foot.x, bottom)
		_:
			_whole(image, foot.x, bottom)
	_outline(image, bottom)
	return image


## Standing: the stake, the shirt on the crossbar with straw at the cuffs, the
## collar and the waist, and the sack head with its stitched face.
static func _whole(image: Image, centre: int, bottom: int) -> void:
	_stake(image, centre, bottom - 7, bottom)
	_shirt(image, centre, bottom - 16)
	_sleeve(image, centre - 4, bottom - 16, false)
	_sleeve(image, centre + 2, bottom - 16, false)
	_waist(image, centre, bottom - 8)
	_head(image, centre, bottom - 23)


## Hurt: the shirt torn with straw coming out of it and down to the ground,
## the head slumped a pixel east and down, the west sleeve off the crossbar
## and hanging, the bare end of the bar where it was.
static func _hurt(image: Image, centre: int, bottom: int) -> void:
	_stake(image, centre, bottom - 7, bottom)
	_shirt(image, centre, bottom - 16)
	_sleeve(image, centre + 2, bottom - 16, false)
	# The bar's end, bare, and the sleeve hanging under it.
	_put(image, centre - 5, bottom - 16, &"wood_dark")
	_put(image, centre - 4, bottom - 16, &"wood")
	_sleeve(image, centre - 5, bottom - 15, true)
	_waist(image, centre, bottom - 8)
	# Torn, and the straw spilling out of the tear and down the stake.
	_put(image, centre - 1, bottom - 13, &"ink")
	_put(image, centre, bottom - 12, &"ink")
	_put(image, centre + 1, bottom - 14, &"ink")
	_put(image, centre, bottom - 11, &"gold_light")
	_put(image, centre + 1, bottom - 11, &"gold")
	_put(image, centre + 2, bottom - 4, &"gold")
	_put(image, centre + 2, bottom - 1, &"gold_dark")
	_put(image, centre + 3, bottom, &"gold")
	_put(image, centre - 3, bottom, &"gold_dark")
	_head(image, centre + 1, bottom - 22)


## Wrecked: the stake snapped to a stump in a heap of straw, a rag of the
## shirt in it and the sack head rolled off to the east - low on the cell,
## eight rows at most.
static func _wreck(image: Image, centre: int, bottom: int) -> void:
	# The stump, jagged where it broke.
	_put(image, centre - 1, bottom - 5, &"wood_light")
	for y in range(bottom - 4, bottom + 1):
		_put(image, centre - 1, y, &"wood_light")
		_put(image, centre, y, &"wood_dark")
	# The heap, widening to the ground, lit from the upper left.
	var rows := [[3, 2], [4, 3], [5, 4], [5, 5]]
	for step in rows.size():
		var y: int = bottom - 3 + step
		var left: int = centre - int(rows[step][0])
		var right: int = centre + int(rows[step][1])
		for x in range(left, right):
			var colour := &"gold"
			if step == 0 or x == left:
				colour = &"gold_light"
			elif x >= right - 2 or step == rows.size() - 1:
				colour = &"gold_dark"
			elif (x + y) % 3 == 0:
				colour = &"bone_dark"
			_put(image, x, y, colour)
	# A rag of the red shirt in the straw.
	_put(image, centre - 4, bottom - 1, &"roof_dark")
	_put(image, centre - 3, bottom - 1, &"roof")
	_put(image, centre - 3, bottom, &"roof_dark")
	# The sack head on its side, its stitched eye up.
	for y in range(bottom - 3, bottom):
		for x in range(centre + 2, centre + 5):
			_put(image, x, y, &"soil_light" if x == centre + 4 or y == bottom - 1 else &"bone_dark")
	_put(image, centre + 3, bottom - 2, &"ink")


## The bait: a fish rotting belly-up on the ground, in the rot the walkers
## wear and darker underneath, its ribs through the torn top, a dull eye and
## a gaping mouth, the tail's lower lobe bitten off - twelve wide with its
## outline, on x 2..13, lying on the pivot's row.
static func _bait(image: Image, centre: int, bottom: int) -> void:
	for x in range(centre - 4, centre + 3):
		_put(image, x, bottom - 3, &"rot")
		_put(image, x, bottom - 2, &"rot_dark" if x % 2 == 0 else &"rot")
	for x in range(centre - 3, centre + 2):
		_put(image, x, bottom - 4, &"bone" if x % 2 == 0 else &"rot")
		_put(image, x, bottom - 1, &"rot_dark")
	_put(image, centre - 5, bottom - 2, &"rot_dark")
	_put(image, centre - 4, bottom - 3, &"ink")
	_put(image, centre + 3, bottom - 3, &"rot_dark")
	_put(image, centre + 3, bottom - 2, &"rot_dark")
	_put(image, centre + 4, bottom - 4, &"rot")


## The stake, two pixels wide and centred on the pivot: lit on its west side.
static func _stake(image: Image, centre: int, top: int, bottom: int) -> void:
	for y in range(top, bottom + 1):
		_put(image, centre - 1, y, &"wood_dark" if y == bottom else &"wood_light")
		_put(image, centre, y, &"wood_dark")


## The shirt's body under the collar: faded red, its east side in shadow and a
## fold down its middle.
static func _shirt(image: Image, centre: int, top: int) -> void:
	for y in range(top, top + 8):
		for x in range(centre - 3, centre + 3):
			var colour := &"roof"
			if x >= centre + 1:
				colour = &"roof_dark"
			elif x == centre - 3 and y < top + 3:
				colour = &"roof_light"
			if x == centre and y > top + 1:
				colour = &"roof_dark"
			_put(image, x, y, colour)


## A sleeve along the crossbar from `left`, two pixels tall, with straw out of
## its cuff - or, `hanging`, the same sleeve fallen and hanging straight down.
static func _sleeve(image: Image, left: int, top: int, hanging: bool) -> void:
	if hanging:
		for y in range(top, top + 5):
			_put(image, left, y, &"roof")
			_put(image, left + 1, y, &"roof_dark")
		_put(image, left, top + 5, &"gold")
		_put(image, left + 1, top + 5, &"gold_dark")
		_put(image, left, top + 6, &"gold_dark")
		return
	for x in range(left, left + 2):
		_put(image, x, top, &"roof")
		_put(image, x, top + 1, &"roof_dark")
	# Straw out of the cuff, on whichever end is outermost.
	var cuff := left - 1 if left < 8 else left + 2
	_put(image, cuff, top, &"gold_light")
	_put(image, cuff, top + 1, &"gold")
	_put(image, cuff, top + 2, &"gold_dark")


## Straw bursting out round the waist, over the top of the stake.
static func _waist(image: Image, centre: int, y: int) -> void:
	for x in range(centre - 3, centre + 3):
		_put(image, x, y, &"gold_light" if x % 2 == 0 else &"gold")
	for x in [centre - 3, centre - 2, centre + 1, centre + 2]:
		_put(image, x, y + 1, &"gold_dark" if x < centre else &"gold")


## The sack head: rounded, tied off at the neck with twine, straw at the
## collar, two stitched eyes and a stitched mouth - and nothing lit.
static func _head(image: Image, centre: int, top: int) -> void:
	for y in range(top, top + 6):
		var reach := 2 if y == top or y == top + 5 else 3
		for x in range(centre - reach, centre + reach):
			var colour := &"bone_dark"
			if x == centre + reach - 1 or y == top + 5:
				colour = &"soil_light"
			elif y == top and x < centre:
				colour = &"bone"
			_put(image, x, y, colour)
	_put(image, centre - 2, top + 2, &"ink")
	_put(image, centre + 1, top + 2, &"ink")
	for x in range(centre - 2, centre + 2):
		_put(image, x, top + 4, &"ink" if x % 2 == 0 else &"soil_light")
	# The twine round the neck, and straw out of the collar either side.
	for x in range(centre - 2, centre + 2):
		_put(image, x, top + 6, &"gold_dark")
	_put(image, centre - 3, top + 6, &"gold_light")
	_put(image, centre + 2, top + 6, &"gold_light")


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
