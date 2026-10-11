class_name WeatherArt
extends RefCounted

## **The night's weather marks, drawn in code** (task 0256): A055's fog, rain
## and - since task 0257 - Blood Moon at both of its boxes, `icon_<id>` 16x16
## on (8,8) and `hud_<id>` 10x10 on (5,5), in the forecast's event slot,
## through 0120's road until 0269 integrates the pack.
##
## - **Fog**: three bands of mist staggered left, right and left - pale on
##   top, `ink_soft` beneath.
## - **Rain**: a grey cloud, lit on top and dark underneath, with three
##   `water_light` drops falling to the lower left.
## - **Blood Moon** (task 0257): a disc in the `roof` ramp, lit at its upper
##   left, outlined in `ink`, with `blood` craters and one drip hanging from
##   its lower edge - the drip, not only the red, is what tells it from
##   A010's Full Moon.
##
## Each is named for the runtime path A055 delivers it to, so the day the real
## art lands these load it and the drawings go. View only: which night is
## foggy is `Weather`'s.

## What each letter of the maps below is drawn in.
const LEGEND := {
	"b": &"bone_dark", "l": &"stone_light", "u": &"ink_soft",
	"s": &"stone", "d": &"stone_dark", "w": &"water_light",
	"o": &"ink", "h": &"roof_light", "r": &"roof", "k": &"roof_dark", "x": &"blood",
}

## Every mark, row by row, by its runtime name.
const MAPS := {
	&"icon_fog": [
		"................",
		"................",
		"................",
		"....bbbbbbb.....",
		"...lllllllll....",
		"....uuuuuuu.....",
		"................",
		".......bbbbbbb..",
		"......lllllllll.",
		".......uuuuuuu..",
		"................",
		"...bbbbbbb......",
		"..lllllllll.....",
		"...uuuuuuu......",
		"................",
		"................",
	],
	&"hud_fog": [
		"..........",
		".bbbbbb...",
		"..uuuu....",
		"..........",
		"...bbbbbb.",
		"....uuuu..",
		"..........",
		".bbbbbb...",
		"..uuuu....",
		"..........",
	],
	&"icon_rain": [
		"................",
		"................",
		"................",
		"......llll......",
		"....llllssss....",
		"...llsssssssd...",
		"..lssssssssssd..",
		"..ssssssssssdd..",
		"...dddddddddd...",
		"................",
		".....w...w...w..",
		"....w...w...w...",
		"...w...w...w....",
		"................",
		"................",
		"................",
	],
	&"hud_rain": [
		"..........",
		"....ll....",
		"..llssss..",
		".lsssssdd.",
		"..dddddd..",
		"..........",
		"...w..w...",
		"..w..w..w.",
		".......w..",
		"..........",
	],
	&"icon_blood_moon": [
		"................",
		"......oooo......",
		"....oohhhroo....",
		"...ohhhhrrrro...",
		"...ohhhrrrrro...",
		"..ohhhrrrxrrro..",
		"..ohhrrrrrxrko..",
		"..ohrrrrrrrkko..",
		"..orrrxrrrkkko..",
		"...orrrrrkkko...",
		"...orrrrkkkko...",
		"....oorkkkoo....",
		"......oxxo......",
		".......xx.......",
		"........x.......",
		"................",
	],
	&"hud_blood_moon": [
		"..........",
		"...oooo...",
		"..ohhrro..",
		"..ohrxro..",
		"..orrrko..",
		"..orrkko..",
		"...oxxo...",
		".....x....",
		".....x....",
		"..........",
	],
}

static var _made: Dictionary = {}


## The mark at a runtime path - `res://sprites/ui/icon_fog.png` and the rest -
## A055's once it has landed, the drawing until then; null for any other path.
static func texture_at(path: String) -> Texture2D:
	var name := StringName(path.get_file().get_basename())
	if not MAPS.has(name) or path.get_base_dir() != "res://sprites/ui":
		return null
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(name):
		var made := ImageTexture.create_from_image(_paint(MAPS[name]))
		made.resource_name = path
		_made[name] = made
	return _made[name]


static func _paint(rows: Array) -> Image:
	var image := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				image.set_pixel(x, y, PaletteData.COLOURS[LEGEND[row[x]]])
	return image
