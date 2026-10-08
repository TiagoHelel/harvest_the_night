class_name CalendarMark
extends Control

## **One calendar mark** (task 0158): a season, a Full Moon, a boss night or a
## calm night - A010's `icon_<id>` (16x16) or its `hud_<id>` cut (10x10).
##
## Until 0161 integrates A010 the marks are **drawn by code** in the pack's own
## box (`PlaceholderArt.is_drawn`), with the pack's own rule kept: the seasons
## told apart by shape, not only by colour - a sprout, a sun, a leaf, a
## snowflake - and the three night marks never one another: a whole moon, a
## horned skull, a thin crescent with a star. The day the raster lands this
## draws the texture instead, and 0161 deletes the shapes with the entries.

## The two boxes, in native pixels.
const ICON := 16
const HUD := 10

## The marks there are: the four seasons, then the three nights.
const MARKS: Array = [&"spring", &"summer", &"autumn", &"winter", &"full_moon",
	&"boss_night", &"calm_night"]

var mark: StringName = &""
var compact := false
var _texture: Texture2D


## Show `which`, in the 10x10 cut when `small`.
func setup(which: StringName, small: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mark = which
	compact = small
	var side := float(HUD if compact else ICON)
	size = Vector2(side, side)
	custom_minimum_size = size
	var path := file_of(mark, compact)
	_texture = null
	if not PlaceholderArt.is_drawn(path) and ResourceLoader.exists(path):
		_texture = load(path)
	queue_redraw()


## Where A010 delivers a mark.
static func file_of(which: StringName, small: bool) -> String:
	return "res://sprites/ui/%s_%s.png" % ["hud" if small else "icon", which]


## Whether this mark is the code-drawn stand-in rather than A010's art.
func is_stand_in() -> bool:
	return _texture == null


func _draw() -> void:
	if mark == &"":
		return
	if _texture != null:
		draw_texture(_texture, Vector2.ZERO)
		return
	var s := size.x
	var c := size * 0.5
	match mark:
		&"spring":
			_spring(s, c)
		&"summer":
			_summer(s, c)
		&"autumn":
			_autumn(s, c)
		&"winter":
			_winter(s, c)
		&"full_moon":
			_full_moon(s, c)
		&"boss_night":
			_boss_night(s, c)
		&"calm_night":
			_calm_night(s, c)


# ------------------------------------------------------- the stand-in shapes

static func _ink(key: StringName) -> Color:
	return PaletteData.COLOURS.get(key, Color.WHITE)


## A young sprout: a stem, two round leaves and a bud.
func _spring(s: float, c: Vector2) -> void:
	var foot := Vector2(c.x, s * 0.92)
	var top := Vector2(c.x, s * 0.36)
	draw_line(foot, top, _ink(&"grass_dark"), maxf(s / 8.0, 1.0))
	draw_circle(Vector2(c.x - s * 0.2, s * 0.5), s * 0.19, _ink(&"grass"), true, -1.0, false)
	draw_circle(Vector2(c.x + s * 0.2, s * 0.42), s * 0.19, _ink(&"grass_light"), true, -1.0, false)
	draw_circle(Vector2(c.x, s * 0.24), s * 0.12, _ink(&"bone"), true, -1.0, false)


## A sun: a disc and eight chunky rays.
func _summer(s: float, c: Vector2) -> void:
	var ray := maxf(s / 8.0, 1.0)
	for i in 8:
		var turn := TAU * float(i) / 8.0
		var tip := c + Vector2(cos(turn), sin(turn)) * s * 0.46
		draw_line(c, tip, _ink(&"flame_hot"), ray)
	draw_circle(c, s * 0.3, _ink(&"gold_dark"), true, -1.0, false)
	draw_circle(c - Vector2(s, s) * 0.04, s * 0.26, _ink(&"gold_light"), true, -1.0, false)


## One maple-like leaf, tilted, on a short stem.
func _autumn(s: float, c: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var turn := TAU * float(i) / 10.0 - PI * 0.6
		var reach := s * (0.44 if i % 2 == 0 else 0.22)
		points.append(c + Vector2(cos(turn), sin(turn)) * reach - Vector2(0, s * 0.04))
	draw_colored_polygon(points, _ink(&"roof"))
	draw_circle(c - Vector2(0, s * 0.04), s * 0.14, _ink(&"flame"), true, -1.0, false)
	draw_line(c + Vector2(0, s * 0.1), c + Vector2(s * 0.18, s * 0.46), _ink(&"wood"),
		maxf(s / 10.0, 1.0))


## A chunky six-armed snowflake.
func _winter(s: float, c: Vector2) -> void:
	var arm := maxf(s / 8.0, 1.0)
	for i in 3:
		var turn := PI * float(i) / 3.0 + PI / 2.0
		var reach := Vector2(cos(turn), sin(turn)) * s * 0.44
		draw_line(c - reach, c + reach, _ink(&"bone"), arm)
	draw_circle(c, s * 0.14, _ink(&"water_light"), true, -1.0, false)


## A whole round moon with two craters, lit upper left.
func _full_moon(s: float, c: Vector2) -> void:
	draw_circle(c, s * 0.44, _ink(&"ink"), true, -1.0, false)
	draw_circle(c, s * 0.38, _ink(&"moon"), true, -1.0, false)
	draw_circle(c - Vector2(s, s) * 0.12, s * 0.14, _ink(&"bone"), true, -1.0, false)
	draw_circle(c + Vector2(s * 0.14, s * 0.06), s * 0.09, _ink(&"stone_light"), true, -1.0, false)
	draw_circle(c + Vector2(-s * 0.08, s * 0.2), s * 0.06, _ink(&"stone_light"), true, -1.0, false)


## A horned skull: two short horns, a round head, dark eyes.
func _boss_night(s: float, c: Vector2) -> void:
	var horn := maxf(s / 8.0, 1.0)
	draw_line(c + Vector2(-s * 0.24, -s * 0.1), c + Vector2(-s * 0.42, -s * 0.42),
		_ink(&"bone_dark"), horn + 1.0)
	draw_line(c + Vector2(s * 0.24, -s * 0.1), c + Vector2(s * 0.42, -s * 0.42),
		_ink(&"bone_dark"), horn + 1.0)
	draw_circle(c + Vector2(0, -s * 0.02), s * 0.34, _ink(&"ink"), true, -1.0, false)
	draw_circle(c + Vector2(0, -s * 0.02), s * 0.28, _ink(&"bone"), true, -1.0, false)
	draw_rect(Rect2(c + Vector2(-s * 0.16, s * 0.16), Vector2(s * 0.32, s * 0.22)),
		_ink(&"bone_dark"))
	var eye := Vector2(maxf(s * 0.14, 2.0), maxf(s * 0.14, 2.0))
	draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.08), eye), _ink(&"ink"))
	draw_rect(Rect2(c + Vector2(s * 0.06, -s * 0.08), eye), _ink(&"ink"))


## A thin crescent opening to the right, and a small four-point star.
func _calm_night(s: float, c: Vector2) -> void:
	var centre := c - Vector2(s * 0.08, 0)
	draw_arc(centre, s * 0.3, PI * 0.42, PI * 1.58, 16, _ink(&"moon"),
		maxf(s * 0.18, 2.0), false)
	var star := c + Vector2(s * 0.28, -s * 0.22)
	var arm := maxf(s * 0.12, 1.0)
	draw_line(star - Vector2(arm, 0), star + Vector2(arm, 0), _ink(&"bone"), 1.0)
	draw_line(star - Vector2(0, arm), star + Vector2(0, arm), _ink(&"bone"), 1.0)
