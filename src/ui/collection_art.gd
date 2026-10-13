class_name CollectionArt
extends Control

## **A056's pieces drawn by code** (task 0287) while the pack is a stand-in
## (`PlaceholderArt.is_drawn`): the collection book's cover, an achievement's
## medal, the page ornament and the plaque a boss's trophy hangs on. Each is
## drawn in its entry's box (`PlaceholderArt.ART`), out of the palette, so the
## real art drops into the same place; the leaf that integrates A056 (0288)
## deletes the registry's lines and then this file's use.
##
## **No locked state**: a badge not yet earned is the same medal dimmed by
## `CollectionsScreen`, as the pack's art will be.

enum { COVER, BADGE, ORNAMENT, PLAQUE }

## The emblem on each medal's face, by achievement id - a shape apiece, so no
## two badges look alike even dimmed. An id with no line gets a star.
const EMBLEMS: Dictionary = {
	&"first_night": &"crescent",
	&"hundred_nights": &"star",
	&"slayer": &"swords",
	&"builder": &"wall",
	&"gatherer": &"sheaf",
	&"angler": &"fish",
	&"regular": &"house",
	&"long_haul": &"hourglass",
	&"full_moon": &"full_moon",
	&"legend": &"crown",
	&"arsenal": &"tower",
	&"year_two": &"sprout",
}

var kind := COVER
## Which badge, for its emblem.
var id := &""


## A piece of `kind` in its registered box.
static func make(piece: int, which: StringName = &"") -> CollectionArt:
	var art := CollectionArt.new()
	art.kind = piece
	art.id = which
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := Vector2(BOXES[piece])
	art.custom_minimum_size = box
	art.size = box
	return art


## Each piece's canvas: A056's, as `PlaceholderArt` registers it.
const BOXES: Dictionary = {
	COVER: Vector2i(48, 64),
	BADGE: Vector2i(24, 24),
	ORNAMENT: Vector2i(64, 12),
	PLAQUE: Vector2i(32, 32),
}


func _draw() -> void:
	match kind:
		COVER:
			_cover()
		BADGE:
			_badge()
		ORNAMENT:
			_ornament()
		PLAQUE:
			_plaque()


static func _c(name: StringName) -> Color:
	return PaletteData.COLOURS[name]


## The closed book seen straight on: red-brown leather, a spine, gold corner
## caps and clasp, the pages' edge, and the farmhouse roof under a crescent.
func _cover() -> void:
	draw_rect(Rect2(2, 2, 42, 60), _c(&"wood_dark"))
	draw_rect(Rect2(3, 3, 40, 58), _c(&"roof_dark"))
	draw_rect(Rect2(3, 3, 4, 58), _c(&"wood_dark"))
	draw_rect(Rect2(44, 4, 2, 56), _c(&"bone"))
	draw_rect(Rect2(44, 4, 2, 1), _c(&"bone_dark"))
	draw_rect(Rect2(44, 59, 2, 1), _c(&"bone_dark"))
	for corner in [Vector2(3, 3), Vector2(39, 3), Vector2(3, 57), Vector2(39, 57)]:
		draw_rect(Rect2(corner, Vector2(4, 4)), _c(&"gold_dark"))
	draw_rect(Rect2(41, 28, 5, 8), _c(&"gold_dark"))
	draw_rect(Rect2(42, 29, 3, 6), _c(&"gold"))
	# The emblem: the roof, and the moon over it.
	draw_colored_polygon(PackedVector2Array([Vector2(13, 40), Vector2(25, 29),
		Vector2(37, 40)]), _c(&"roof"))
	draw_colored_polygon(PackedVector2Array([Vector2(16, 40), Vector2(25, 32),
		Vector2(34, 40)]), _c(&"roof_light"))
	draw_rect(Rect2(17, 40, 16, 8), _c(&"bone_dark"))
	draw_rect(Rect2(23, 43, 4, 5), _c(&"wood_dark"))
	draw_circle(Vector2(25, 18), 5.0, _c(&"gold_light"))
	draw_circle(Vector2(27, 16.5), 4.5, _c(&"roof_dark"))


## The medal on its ribbon, the emblem on its face.
func _badge() -> void:
	draw_rect(Rect2(8, 1, 4, 7), _c(&"roof"))
	draw_rect(Rect2(12, 1, 4, 7), _c(&"roof_dark"))
	draw_circle(Vector2(12, 14), 8.5, _c(&"gold_dark"))
	draw_circle(Vector2(12, 14), 7.0, _c(&"gold"))
	draw_circle(Vector2(9.5, 11.5), 1.5, _c(&"gold_light"))
	_emblem(StringName(EMBLEMS.get(id, &"star")), Vector2(12, 14))


## One emblem, about seven pixels across, centred on `at`.
func _emblem(shape: StringName, at: Vector2) -> void:
	var ink := _c(&"ink")
	match shape:
		&"crescent":
			draw_circle(at, 4.0, _c(&"moon"))
			draw_circle(at + Vector2(1.6, -1.2), 3.4, _c(&"gold"))
		&"full_moon":
			draw_circle(at, 4.0, _c(&"moon"))
			draw_rect(Rect2(at + Vector2(-5, 3), Vector2(10, 2)), _c(&"stone_dark"))
		&"star":
			var points := PackedVector2Array()
			for i in 10:
				var r := 4.5 if i % 2 == 0 else 2.0
				var a := -PI / 2.0 + i * PI / 5.0
				points.append(at + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(points, _c(&"bone"))
		&"swords":
			draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), _c(&"stone_light"), 1.5)
			draw_line(at + Vector2(4, -4), at + Vector2(-4, 4), _c(&"stone_light"), 1.5)
			draw_rect(Rect2(at + Vector2(-5, 3), Vector2(3, 2)), _c(&"wood_dark"))
			draw_rect(Rect2(at + Vector2(2, 3), Vector2(3, 2)), _c(&"wood_dark"))
		&"wall":
			for row in 3:
				var shift := 0.0 if row % 2 == 0 else 2.0
				for col in 2:
					draw_rect(Rect2(at + Vector2(-5 + shift + col * 4, -4 + row * 3),
						Vector2(3, 2)), _c(&"stone_light"))
		&"sheaf":
			for dx in [-2.5, 0.0, 2.5]:
				draw_line(at + Vector2(dx * 0.4, 4), at + Vector2(dx, -3), _c(&"wood_dark"), 1.0)
				draw_circle(at + Vector2(dx, -3.5), 1.4, _c(&"gold_light"))
			draw_rect(Rect2(at + Vector2(-2, 1), Vector2(4, 1)), _c(&"roof_dark"))
		&"fish":
			draw_circle(at + Vector2(-1, 0), 2.6, _c(&"water_light"))
			draw_circle(at + Vector2(1, 0), 2.2, _c(&"water_light"))
			draw_colored_polygon(PackedVector2Array([at + Vector2(3, 0),
				at + Vector2(5.5, -2.5), at + Vector2(5.5, 2.5)]), _c(&"water"))
			draw_rect(Rect2(at + Vector2(-3, -1), Vector2(1, 1)), ink)
		&"house":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 0),
				at + Vector2(0, -5), at + Vector2(5, 0)]), _c(&"roof"))
			draw_rect(Rect2(at + Vector2(-3.5, 0), Vector2(7, 4.5)), _c(&"bone"))
			draw_rect(Rect2(at + Vector2(-1, 1.5), Vector2(2, 3)), _c(&"wood_dark"))
		&"hourglass":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-3.5, -4.5),
				at + Vector2(3.5, -4.5), at]), _c(&"bone"))
			draw_colored_polygon(PackedVector2Array([at, at + Vector2(3.5, 4.5),
				at + Vector2(-3.5, 4.5)]), _c(&"soil_light"))
			draw_rect(Rect2(at + Vector2(-4.5, -5.5), Vector2(9, 1)), _c(&"wood_dark"))
			draw_rect(Rect2(at + Vector2(-4.5, 4.5), Vector2(9, 1)), _c(&"wood_dark"))
		&"crown":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 3),
				at + Vector2(-5, -3), at + Vector2(-2.5, 0), at + Vector2(0, -4),
				at + Vector2(2.5, 0), at + Vector2(5, -3), at + Vector2(5, 3)]),
				_c(&"flame_hot"))
			draw_rect(Rect2(at + Vector2(-5, 2), Vector2(10, 1)), _c(&"roof_dark"))
		&"tower":
			draw_rect(Rect2(at + Vector2(-3, -2), Vector2(6, 7)), _c(&"stone_light"))
			for col in 3:
				draw_rect(Rect2(at + Vector2(-4 + col * 3, -5), Vector2(2, 3)), _c(&"stone_light"))
			draw_rect(Rect2(at + Vector2(-1, 1), Vector2(2, 2)), ink)
		&"sprout":
			draw_line(at + Vector2(0, 5), at + Vector2(0, -1), _c(&"leaf"), 1.0)
			draw_circle(at + Vector2(-2.5, -1.5), 2.2, _c(&"grass_light"))
			draw_circle(at + Vector2(2.5, -2.5), 2.2, _c(&"grass_light"))
			draw_rect(Rect2(at + Vector2(-3, 4), Vector2(6, 1)), _c(&"soil_dark"))


## A thin vine end to end, wheat ears and leaves along it, a crescent at the
## middle. Symmetric.
func _ornament() -> void:
	draw_rect(Rect2(1, 6, 62, 1), _c(&"gold_dark"))
	for x in [8.0, 55.0]:
		draw_circle(Vector2(x, 4.5), 1.6, _c(&"gold"))
		draw_circle(Vector2(x + (2.0 if x < 32 else -2.0), 3.5), 1.3, _c(&"gold_light"))
	for x in [17.0, 24.0, 40.0, 47.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 6), Vector2(x, 3.5),
			Vector2(x + 2, 6), Vector2(x, 8.5)]), _c(&"grass_light"))
	draw_circle(Vector2(32, 5), 3.5, _c(&"gold_light"))
	draw_circle(Vector2(33.5, 4), 3.0, _c(&"night"))


## The shield-shaped plaque a trophy hangs on: dark wood, a gold rim, a nail.
func _plaque() -> void:
	var shape := PackedVector2Array([Vector2(3, 3), Vector2(29, 3), Vector2(29, 20),
		Vector2(16, 30), Vector2(3, 20)])
	draw_colored_polygon(shape, _c(&"gold_dark"))
	var inner := PackedVector2Array([Vector2(5, 5), Vector2(27, 5), Vector2(27, 19),
		Vector2(16, 27.5), Vector2(5, 19)])
	draw_colored_polygon(inner, _c(&"wood_dark"))
	draw_rect(Rect2(7, 7, 18, 2), _c(&"wood"))
	draw_circle(Vector2(16, 6), 1.5, _c(&"gold_light"))
