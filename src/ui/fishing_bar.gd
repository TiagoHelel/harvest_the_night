class_name FishingBar
extends Control

## **The fishing bar** (task 0180): what a bite looks like. A marker sweeping
## a track, a green on it, and the hits a species needs as pips - a press
## while the marker is over the green counts.
##
## Nothing here is a rule. Where the marker is, how wide the green is and
## what a press does are `Fishing`'s, read off the line every frame; this
## draws them and flashes the last press, hit or miss. The pieces are A023's
## art since task 0206: the frame round the track, the green - a three-patch,
## its two-pixel caps kept and its middle drawn to the zone's width - the
## needle and the two flashes. The pips under the bar stay code.

## Where the bar sits on the 480x270 screen: centred, under the farmer.
const CENTRE := Vector2(240, 184)
## A023's `fishbar_frame` canvas, and the track inside it (`track_xywh`).
const FRAME := Vector2i(100, 16)
const TRACK := Rect2i(5, 5, 90, 6)
## How long a hit or a miss flashes, in seconds: A023's three frames of
## 0.065.
const FLASH_FRAME := 0.065
const FLASH_SECONDS := 3 * FLASH_FRAME
## Where A023 delivers the pieces, and the green's caps (`patch_margins_lrtb`).
const DIR := "res://sprites/ui/"
const ZONE_CAP := 2

var _state: Dictionary = {}
var _flash_left := 0.0
var _flash_hit := false
var _flash_at := 0.0
var _seen_press := []
## The pieces' textures, held for `_draw`.
var _held: Dictionary = {}


func _ready() -> void:
	name = "FishingBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func show_state(state: Dictionary) -> void:
	_state = state


## Whether the bar is up - for the checks.
func shown() -> bool:
	return visible


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var up := int(_state["phase"]) == Phases.DAY and Fishing.is_biting(_state) \
		and not House.inside(_state)
	visible = up
	if not up:
		_seen_press = []
		_flash_left = maxf(_flash_left - delta, 0.0)
		return
	var line := Fishing.cast_of(_state)
	var last: Array = line.get("last", [])
	if not last.is_empty() and last != _seen_press:
		_seen_press = last.duplicate()
		_flash_left = FLASH_SECONDS
		_flash_hit = bool(last[1])
		_flash_at = marker_x()
	_flash_left = maxf(_flash_left - delta, 0.0)
	queue_redraw()


## Where the marker is on the screen, in the bar's pixels - for the checks.
func marker_x() -> float:
	var line := Fishing.cast_of(_state)
	return _x_of(Fishing.marker(line))


## The green on the screen - for the checks.
func zone_rect() -> Rect2:
	var line := Fishing.cast_of(_state)
	var from := _x_of(int(line.get("zone_at", 0)))
	var to := _x_of(int(line.get("zone_at", 0)) + int(line.get("zone", 0)))
	return Rect2(from, _origin().y + TRACK.position.y, to - from, TRACK.size.y)


func _origin() -> Vector2:
	return CENTRE - Vector2(FRAME) / 2.0


## A step of the bar as a screen x on the track.
func _x_of(step: int) -> float:
	var units := float(GameData.FISHING["bar_units"])
	return _origin().x + TRACK.position.x + float(step) * float(TRACK.size.x) / units


func _colour(id: StringName) -> Color:
	return PaletteData.COLOURS.get(id, Color.MAGENTA)


## One of A023's pieces by its runtime name, held.
func _piece(name: String) -> Texture2D:
	if not _held.has(name):
		var path := DIR + name + ".png"
		_held[name] = load(path) if ResourceLoader.exists(path) else null
	return _held[name]


## The flash's frame up now: A023's three, once, over `FLASH_SECONDS`.
func flash_frame() -> int:
	return mini(int((FLASH_SECONDS - _flash_left) / FLASH_FRAME), 2)


func _draw() -> void:
	if _state.is_empty() or not Fishing.is_biting(_state):
		return
	var line := Fishing.cast_of(_state)
	var at := _origin()
	var middle := at.y + float(FRAME.y) / 2.0
	draw_texture(_piece("fishbar_frame"), at)
	# The green: its caps as drawn, its middle to the zone's width.
	var green := zone_rect()
	var zone := _piece("fishbar_zone")
	var inner := zone.get_width() - 2 * ZONE_CAP
	draw_texture_rect_region(zone, Rect2(green.position, Vector2(ZONE_CAP, green.size.y)),
		Rect2(0, 0, ZONE_CAP, zone.get_height()))
	draw_texture_rect_region(zone, Rect2(green.position + Vector2(ZONE_CAP, 0),
		Vector2(maxf(green.size.x - 2 * ZONE_CAP, 0.0), green.size.y)),
		Rect2(ZONE_CAP, 0, inner, zone.get_height()))
	draw_texture_rect_region(zone, Rect2(Vector2(green.end.x - ZONE_CAP, green.position.y),
		Vector2(ZONE_CAP, green.size.y)), Rect2(zone.get_width() - ZONE_CAP, 0, ZONE_CAP, zone.get_height()))
	# The needle, standing on the marker in the frame's middle.
	var needle := _piece("fishbar_marker")
	draw_texture(needle, Vector2(floorf(marker_x()) - 2.0, middle - 6.0))
	# The hits it needs, as pips under the bar: filled for each one landed.
	var needs := int(line.get("needs", 1))
	var hits := int(line.get("hits", 0))
	var pips_from := CENTRE.x - float(needs * 6 - 2) / 2.0
	for i in needs:
		var pip := Rect2(pips_from + i * 6, at.y + FRAME.y + 2, 4, 4)
		draw_rect(pip, _colour(&"ink"))
		draw_rect(pip.grow(-1), _colour(&"gold_light") if i < hits else _colour(&"stone_dark"))
	# The flash of the last press, where the needle was: A023's three frames.
	if _flash_left > 0.0:
		var flash := _piece("fishbar_%s_%d" % ["hit" if _flash_hit else "miss", flash_frame()])
		draw_texture(flash, Vector2(floorf(_flash_at) - 6.0, middle - 6.0))
