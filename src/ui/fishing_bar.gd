class_name FishingBar
extends Control

## **The fishing bar** (task 0180): what a bite looks like. A marker sweeping
## a track, a green on it, and the hits a species needs as pips - a press
## while the marker is over the green counts.
##
## Nothing here is a rule. Where the marker is, how wide the green is and
## what a press does are `Fishing`'s, read off the line every frame; this
## draws them and flashes the last press, hit or miss. The pieces are A023's,
## drawn by code through 0120's road until 0206 integrates the pack: the
## frame round the track, the green, the needle and the two flashes, at the
## canvases A023 states.

## Where the bar sits on the 480x270 screen: centred, under the farmer.
const CENTRE := Vector2(240, 184)
## A023's `fishbar_frame` canvas, and the track inside it (`track_xywh`).
const FRAME := Vector2i(100, 16)
const TRACK := Rect2i(5, 5, 90, 6)
## How long a hit or a miss flashes, in seconds (A023: three frames of 0.065).
const FLASH_SECONDS := 0.2

var _state: Dictionary = {}
var _flash_left := 0.0
var _flash_hit := false
var _flash_at := 0.0
var _seen_press := []


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


func _draw() -> void:
	if _state.is_empty() or not Fishing.is_biting(_state):
		return
	var line := Fishing.cast_of(_state)
	var at := _origin()
	# The frame: timber with brass caps round a dark channel.
	draw_rect(Rect2(at, Vector2(FRAME)), _colour(&"ink"))
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(FRAME) - Vector2(2, 2)), _colour(&"wood_dark"))
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(FRAME) - Vector2(4, 4)), _colour(&"wood"))
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(3, FRAME.y - 2)), _colour(&"gold_dark"))
	draw_rect(Rect2(at + Vector2(FRAME.x - 4, 1), Vector2(3, FRAME.y - 2)), _colour(&"gold_dark"))
	var track := Rect2(at + Vector2(TRACK.position), Vector2(TRACK.size))
	draw_rect(track, _colour(&"water_dark"))
	draw_rect(Rect2(track.position, Vector2(track.size.x, 1)), _colour(&"water"))
	# The green: body, light top row, dark bottom row, ink ends.
	var green := zone_rect()
	draw_rect(green, _colour(&"grass"))
	draw_rect(Rect2(green.position, Vector2(green.size.x, 1)), _colour(&"grass_light"))
	draw_rect(Rect2(green.position + Vector2(0, green.size.y - 1), Vector2(green.size.x, 1)), _colour(&"grass_dark"))
	draw_rect(Rect2(green.position, Vector2(1, green.size.y)), _colour(&"ink"))
	draw_rect(Rect2(green.end - Vector2(1, green.size.y), Vector2(1, green.size.y)), _colour(&"ink"))
	# The needle: a triangle head over a stem, centred on the marker.
	var x := floorf(marker_x())
	var top := at.y + 2.0
	draw_rect(Rect2(x - 2, top, 5, 1), _colour(&"ink"))
	draw_rect(Rect2(x - 1, top + 1, 3, 1), _colour(&"bone"))
	draw_rect(Rect2(x, top + 2, 1, 1), _colour(&"bone"))
	draw_rect(Rect2(x - 1, top + 3, 3, FRAME.y - 6), _colour(&"ink"))
	draw_rect(Rect2(x, top + 3, 1, FRAME.y - 6), _colour(&"bone"))
	# The hits it needs, as pips under the bar: filled for each one landed.
	var needs := int(line.get("needs", 1))
	var hits := int(line.get("hits", 0))
	var pips_from := CENTRE.x - float(needs * 6 - 2) / 2.0
	for i in needs:
		var pip := Rect2(pips_from + i * 6, at.y + FRAME.y + 2, 4, 4)
		draw_rect(pip, _colour(&"ink"))
		draw_rect(pip.grow(-1), _colour(&"gold_light") if i < hits else _colour(&"stone_dark"))
	# The flash of the last press: a star for a hit, droplets for a miss.
	if _flash_left > 0.0:
		var y := at.y + FRAME.y / 2.0
		var grow := 1.0 + (FLASH_SECONDS - _flash_left) / FLASH_SECONDS * 4.0
		if _flash_hit:
			draw_rect(Rect2(_flash_at - 1, y - grow - 1, 2, grow * 2 + 2), _colour(&"gold_light"))
			draw_rect(Rect2(_flash_at - grow - 1, y - 1, grow * 2 + 2, 2), _colour(&"gold_light"))
			draw_rect(Rect2(_flash_at - 1, y - 1, 2, 2), _colour(&"flame_hot"))
		else:
			for side in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				draw_rect(Rect2(Vector2(_flash_at, y) + side * grow * 1.5, Vector2(2, 2)), _colour(&"water_light"))
