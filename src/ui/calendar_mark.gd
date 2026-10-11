class_name CalendarMark
extends Control

## **One calendar mark** (task 0158): a season, a Full Moon, a boss night or a
## calm night - A010's `icon_<id>` (16x16) or its `hud_<id>` cut (10x10),
## drawn at its native size.
##
## The pack's art since task 0161, which deleted the code-drawn stand-ins:
## the seasons told apart by shape, not only by colour - a sprout, a sun, a
## leaf, a snowflake - and the three night marks never one another: a whole
## moon, a horned skull, a crescent with a star. The HUD is never relit, so a
## mark keeps its colours at night.
##
## **Or a night's weather** (task 0256): A055's `fog` and `rain`, at the same
## two boxes, drawn in code (`WeatherArt`) until 0269 integrates the pack.

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
	var file := file_of(mark, compact)
	if PlaceholderArt.is_drawn(file):
		_texture = WeatherArt.texture_at(file)
	else:
		var path := PlaceholderArt.texture_path(file)
		_texture = load(path) if path != "" and ResourceLoader.exists(path) else null
	queue_redraw()


## Where A010 delivers a mark, and A055 a night's weather.
static func file_of(which: StringName, small: bool) -> String:
	return "res://sprites/ui/%s_%s.png" % ["hud" if small else "icon", which]


## The texture the mark draws - for `headless_v1`.
func texture() -> Texture2D:
	return _texture


func _draw() -> void:
	if mark != &"" and _texture != null:
		draw_texture(_texture, Vector2.ZERO)
