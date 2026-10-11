class_name RatArt
extends RefCounted

## **A rat, drawn in code** (task 0248): A047's master, scurry, bite and death
## on its 24x16 canvas standing on (12,14), and its forecast head, through
## 0120's road until 0261 integrates the pack.
##
## Grey-brown fur (`soil_light`, `bone_dark` along the back, `soil` under), a
## rot patch, a pink-grey ear and tail (`skin_dark`), a pale eye (`bone`) and
## dark legs, facing west as A047 draws it - the view mirrors it to face east.
## Brown, not grey: the night's relight turns a grey rat the blue of the
## field's stones, and a cluster of them read as a heap of rocks. Every frame stands its feet on row 13 with a pixel
## clear all round; standing it is 9 tall and 20 long, the tail included, and
## lying dead 6 tall. Six of them side by side read as a crowd of rats.
##
## Each frame is named for the runtime path A047 delivers it to, so the day
## the real art lands these load it and the drawings go. View only: where a
## rat is is `Enemies`'.

## Where A047 delivers them.
const DIR := "res://sprites/enemies/"
const HEAD_PATH := "res://sprites/ui/head_rat.png"

## What each letter of the maps below is drawn in.
const LEGEND := {
	"o": &"ink", "s": &"soil_light", "d": &"soil", "l": &"bone_dark",
	"g": &"rot", "p": &"skin_dark", "e": &"bone", "r": &"blood",
}

## The body, standing and facing west: rows 5-11, without its legs and tail,
## which each pose adds.
const BODY := [
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"......o....oooo.........",
	".....opo..ollllo........",
	"....oppooolllllsso......",
	"...osessssssssssdo......",
	"..opssssssggssssdo......",
	"...oosssssggsssddo......",
	".....oooooooooooo.......",
	"........................",
	"........................",
	"........................",
	"........................",
]

## Dead: rolled onto its side, and on its back with its legs up.
const SIDE := [
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........oooooooo........",
	"......oolllllllsoo......",
	"...ooessssggssssdo......",
	"..oppsssssggssssdo.p....",
	"...oooddddddddddoopp....",
	".....ooo.oo.ooooo.......",
	"........................",
	"........................",
]
const BACK := [
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"......o.o....o.o........",
	"......o.o....o.o........",
	".....oooooooooooo.......",
	"...oossssggsssssdo.pp...",
	"..opsesssggssssddoop....",
	"...ooooooooooooooo......",
	"........................",
	"........................",
]

## The forecast head: a bust facing west, ears up, cut flat at row 14.
const HEAD := [
	"................",
	"................",
	"......o.........",
	".....opo........",
	"....oppooooo....",
	"...osssllllso...",
	"..oseessssssdo..",
	".opsssssssssdo..",
	"..oosssggssdo...",
	"....ossggssso...",
	"....osssssssso..",
	"....ossssssddo..",
	"....odsssssddo..",
	"....oopo..oopo..",
	"....oooo..oooo..",
	"................",
]

## The tail, three ways: level, up, down - in the pixels after the body.
const TAIL_LEVEL := [Vector2i(18, 10), Vector2i(19, 10), Vector2i(20, 9), Vector2i(21, 8)]
const TAIL_UP := [Vector2i(18, 9), Vector2i(19, 8), Vector2i(20, 7), Vector2i(21, 7)]
const TAIL_DOWN := [Vector2i(18, 10), Vector2i(19, 11), Vector2i(20, 11), Vector2i(21, 10)]

## Every pose: the map it starts from, its legs - a column each, from the row
## given down to the feet on row 13 - its tail, a shift of the whole body and
## any odd pixels. The scurry: front legs reaching, gathered, back legs
## pushing, gathered; the bite: crouched back, lunging with the jaws open,
## recovered; the death: a jolt, on its side, on its back.
const POSES := {
	&"rat": {"legs": [6, 8, 13, 15], "tail": TAIL_LEVEL},
	&"rat_walk_0": {"legs": [5, 7, 13, 15], "tail": TAIL_UP},
	&"rat_walk_1": {"legs": [7, 9, 12, 14], "tail": TAIL_LEVEL},
	&"rat_walk_2": {"legs": [6, 8, 14, 16], "tail": TAIL_DOWN},
	&"rat_walk_3": {"legs": [7, 8, 13, 14], "tail": TAIL_LEVEL, "odd": [[21, 9, "p"]]},
	&"rat_attack_0": {"legs": [7, 9, 14, 16], "tail": TAIL_UP, "shift": Vector2i(1, 0)},
	&"rat_attack_1": {"legs": [5, 7, 13, 15], "tail": TAIL_UP, "shift": Vector2i(-1, 0),
		"odd": [[1, 10, "r"], [2, 10, "o"]]},
	&"rat_attack_2": {"legs": [6, 8, 13, 15],
		"tail": [Vector2i(18, 10), Vector2i(19, 9), Vector2i(20, 9), Vector2i(21, 9)]},
	&"rat_death_0": {"legs": [5, 8, 13, 16], "leg_tops": [11, 12, 12, 11], "tail": TAIL_UP,
		"shift": Vector2i(0, -1)},
	&"rat_death_1": {"map": "side"},
	&"rat_death_2": {"map": "back"},
}

static var _made: Dictionary = {}


## A rat's pose `name` - `rat`, `rat_walk_N`, `rat_attack_N`, `rat_death_N` -
## A047's when it has landed, the drawing until then; null for anything else.
static func texture(name: StringName) -> Texture2D:
	return texture_at(DIR + str(name) + ".png")


## The same by the runtime path, the forecast head's included.
static func texture_at(path: String) -> Texture2D:
	var name := StringName(path.get_file().get_basename())
	if not (path == HEAD_PATH or (POSES.has(name) and path.get_base_dir() + "/" == DIR)):
		return null
	if not PlaceholderArt.is_drawn(path):
		return load(path) if ResourceLoader.exists(path) else null
	if not _made.has(path):
		var made := ImageTexture.create_from_image(head_drawing() if path == HEAD_PATH else drawing(name))
		made.resource_name = path
		_made[path] = made
	return _made[path]


## One pose, drawn on A047's canvas.
static func drawing(name: StringName) -> Image:
	var pose: Dictionary = POSES.get(name, POSES[&"rat"])
	match String(pose.get("map", "")):
		"side":
			return _paint(SIDE)
		"back":
			return _paint(BACK)
	var rows: Array = []
	var shift: Vector2i = pose.get("shift", Vector2i.ZERO)
	for _y in BODY.size():
		rows.append(".".repeat(24))
	for y in BODY.size():
		var row: String = BODY[y]
		for x in row.length():
			var at := Vector2i(x, y) + shift
			if row[x] != "." and at.x >= 0 and at.x < 24 and at.y >= 0 and at.y < 16:
				rows[at.y] = _put(rows[at.y], at.x, row[x])
	var legs: Array = pose["legs"]
	var tops: Array = pose.get("leg_tops", [12, 12, 12, 12])
	for i in legs.size():
		for y in range(int(tops[i]), 14):
			rows[y] = _put(rows[y], int(legs[i]), "o")
	for at in pose["tail"]:
		rows[(at as Vector2i).y] = _put(rows[(at as Vector2i).y], (at as Vector2i).x, "p")
	for odd in pose.get("odd", []):
		rows[int(odd[1])] = _put(rows[int(odd[1])], int(odd[0]), str(odd[2]))
	return _paint(rows)


## The forecast head, on A011's 16x16 box.
static func head_drawing() -> Image:
	return _paint(HEAD)


static func _put(row: String, x: int, letter: String) -> String:
	return row.substr(0, x) + letter + row.substr(x + 1)


static func _paint(rows: Array) -> Image:
	var image := Image.create((rows[0] as String).length(), rows.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				image.set_pixel(x, y, PaletteData.COLOURS[LEGEND[row[x]]])
	return image
