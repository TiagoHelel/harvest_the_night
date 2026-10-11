class_name Transition
extends Node2D

## The moment the game is named after.
##
## `WorldView` already drains the light from warm to cold across the whole
## farm at once, and has since task 0039 - that is the change itself and it is
## not moved here. What this adds is the **theatre**: a band of light crossing
## the farm while it happens, the day's animals going home, and the night's
## machines waking up.
##
## ## It never blocks anything
##
## Not one line of this is waited on. The tick runs through the change at the
## same rate it runs through everything else, which is why skipping lands in
## exactly the same state as watching - there is no state to land in that the
## simulation was not going to reach anyway. `input_check` asserts it by
## playing the same night twice and comparing `State.hash_of()`.
##
## ## Both directions, and the morning is the better one
##
## Dusk sweeps a cold band across a warm farm; dawn sweeps a warm one across a
## cold farm and is the half that is a reward. They are the same code with the
## colour and the direction turned round, because they are the same event
## viewed from either end.
##
## ## Over the night ramp
##
## For task 0076's reason: the ramp is a screen-space pass, so a warm band
## drawn under it is a warm band the night tints blue. This is a layer over
## it, positioned by hand through `get_canvas_transform()`.

## The colour of the band in each direction. Warm out of the night, cold into
## it, and both well clear of the ramp - they are drawn over it.
const INTO_NIGHT := Color(0.42, 0.44, 0.86)
const INTO_DAY := Color(1.00, 0.86, 0.52)

## How wide the band is, as a fraction of the farm. Wide enough to read as
## light moving and narrow enough that it is over before it is boring.
const BAND := 0.35

## How strong it is at its middle. **Low.** At 0.55 the seven strips read as a
## striped screen-wipe rather than as light crossing a field - the hard edges
## were doing the opposite of the job they were picked for.
const STRENGTH := 0.30

var _state: Dictionary = {}
var _view: WorldView
## Sprites of the things that only belong to the day. Collected when the farm
## is redrawn, which is rarely.
var _day_actors: Array = []
## And the things that come on when it gets dark.
var _wakers: Array = []
var _last_seen := -1
var _occupants_layer: Node


func _ready() -> void:
	material = CanvasItemMaterial.new()
	(material as CanvasItemMaterial).blend_mode = \
		CanvasItemMaterial.BLEND_MODE_ADD


func show_state(state: Dictionary, view: WorldView) -> void:
	_state = state
	_view = view


func _process(_delta: float) -> void:
	if _state.is_empty() or _view == null:
		return
	_find_day_actors()
	_dress_the_actors()
	queue_redraw()


# ------------------------------------------------------------- the actors

## The things that come on when the sun goes down. They flare as the change
## passes and settle, which is the "night structures wake" half of what task
## 0078 asks for - a farm where only the light changed would be a farm that
## had not woken up.
const WAKES := [&"gun_tower", &"flame_tower", &"mortar", &"auto_crossbow",
	&"generator", &"beehive", &"catapult", &"searchlight"]


## **The defences that sleep under a tarp by day** (task 0223), and the
## cover each wears (A044's footprints): one list, so a later defence joins
## by being listed. The towers, which stand on the farm all day looking like
## guns, and since task 0234 the seasons' new families: the hive, the
## catapult and the searchlight under the tower's cover, the decoy under the
## tall one and the garlic braid under the short one. Never a barrier, a mine
## or a trap - a covered wall is still a wall, and a covered mine is a lie -
## so not the sandbags, the wire or the bait. The generator still wakes in
## `WAKES`, without one; so do the three new towers, which flare at the wake.
const TARPS := {
	&"gun_tower": &"tarp_tower",
	&"auto_crossbow": &"tarp_tower",
	&"flame_tower": &"tarp_tower",
	&"mortar": &"tarp_tower",
	&"beehive": &"tarp_tower",
	&"catapult": &"tarp_tower",
	&"searchlight": &"tarp_tower",
	&"decoy": &"tarp_tall",
	&"garlic_braid": &"tarp_short",
}

## How long each of A044's two unveil frames shows.
const UNVEIL_SECONDS := 0.12


## **Where the tarps are in the change** (task 0223): on in the light, off
## in the dark, and the two unveil frames at the wake - the middle of the
## change, where the guns flare - `UNVEIL_SECONDS` each. Dawn plays them
## backwards and the cover goes back on. `seconds` is the change's length.
static func tarp_stage(going_dark: bool, transitioning: bool, progress: float,
		seconds: float) -> int:
	if not transitioning:
		return TarpArt.OFF if going_dark else TarpArt.COVERED
	var share := UNVEIL_SECONDS / maxf(seconds, 0.05)
	var past := progress - 0.5
	if going_dark:
		if past < 0.0:
			return TarpArt.COVERED
		if past < share:
			return TarpArt.YANK
		return TarpArt.AWAY if past < share * 2.0 else TarpArt.OFF
	if past < 0.0:
		return TarpArt.OFF
	if past < share:
		return TarpArt.AWAY
	return TarpArt.YANK if past < share * 2.0 else TarpArt.COVERED


## **The day's animals, and only them.** A cow is a thing you keep; it is not
## a thing that stands in a field while zombies walk past it. They fade out as
## the light goes and come back with it, which is the cheapest possible way to
## say "this is somewhere else now" without touching a rule.
const DAY_ONLY := [&"cow", &"chicken", &"sheep", &"pig"]


func _find_day_actors() -> void:
	var occupants: Dictionary = _state["occupants"]
	# **And whenever what was found has been freed.** `WorldView._refresh()`
	# throws its sprites away and builds new ones, and it does that for
	# reasons that have nothing to do with the number of occupants - so a
	# cache keyed only on that count holds freed objects, and casting one of
	# those is an error rather than a null.
	# **And whenever the drawings changed** (task 0183): an animal at home
	# is a drawing with no occupant under it, so a hen moving in changes
	# what is drawn and not what stands on the farm.
	if _occupants_layer == null or not is_instance_valid(_occupants_layer):
		_occupants_layer = _view.find_child("Occupants", true, false)
	var world := _occupants_layer
	var seen := occupants.size() * 100000 + (world.get_child_count() if world != null else 0)
	if seen == _last_seen and _actors_are_alive():
		return
	_last_seen = seen
	_day_actors.clear()
	_wakers.clear()
	if world == null:
		return
	# Source-owned drawings sit at ground pivots. Their logical-cell metadata
	# identifies the occupant, including a grouped station and taller animals.
	for child in world.get_children():
		var sprite := child as Sprite2D
		if sprite == null:
			continue
		if bool(sprite.get_meta("day_only", false)):
			_day_actors.append(sprite)
			continue
		var cells: Array = sprite.get_meta("logical_cells",[])
		if cells.is_empty():
			continue
		var on: Dictionary = occupants.get(int(cells[0]),{})
		var id: StringName = on.get("id",&"")
		if DAY_ONLY.has(id):
			_day_actors.append(sprite)
		elif WAKES.has(id):
			_wakers.append(sprite)


func _dress_the_actors() -> void:
	# 1 in full daylight, 0 in the dark, and on the way between during the
	# change - which is the whole animation.
	var day := 1.0 - _nightness()
	for sprite in _day_actors:
		# **Valid first, cast second.** The other way round is an error on a
		# freed object rather than a null to skip over.
		if not is_instance_valid(sprite):
			continue
		var actor := sprite as Sprite2D
		if actor == null:
			continue
		actor.modulate.a = clampf(day, 0.0, 1.0)

	# The guns come on. A short flare at the moment the world flips, and back
	# to normal once it has - so it is an event and not a permanent glow.
	var flare := _bell(_view.transition_progress()) 		if _view.is_transitioning() and _view.going_dark() else 0.0
	for sprite in _wakers:
		if not is_instance_valid(sprite):
			continue
		var tower := sprite as Sprite2D
		if tower == null:
			continue
		var lit := 1.0 + flare * 0.45
		tower.modulate = Color(lit, lit * 0.94, lit * 0.78)


func _actors_are_alive() -> bool:
	for sprite in _day_actors:
		if not is_instance_valid(sprite):
			return false
	for sprite in _wakers:
		if not is_instance_valid(sprite):
			return false
	return true


## How far into the night the world is, counting the change itself.
func _nightness() -> float:
	return _view.visual_nightness()


# -------------------------------------------------------------- the sweep

func _draw() -> void:
	if _state.is_empty() or _view == null or not _view.is_transitioning():
		return
	var through := _view.transition_progress()
	var into_night := _view.going_dark()
	var colour := INTO_NIGHT if into_night else INTO_DAY

	# The band crosses the screen once, left to right going dark and right to
	# left coming back - so the morning does not read as a repeat of the
	# evening played again.
	var screen := Vector2(get_viewport_rect().size)
	var band := screen.x * BAND
	var travel := screen.x + band * 2.0
	var middle := (-band + travel * through) if into_night \
		else (screen.x + band - travel * through)

	# Drawn as a handful of hard-edged strips rather than a gradient: this is
	# a pixel-art game and a smooth ramp of alpha across four hundred pixels
	# is the one thing that would look like it came from somewhere else.
	# More, narrower strips: still hard-edged, because this is a pixel-art
	# game, but close enough together to read as one moving wash.
	var steps := 13
	for step in steps:
		var away := absf(float(step) - float(steps - 1) * 0.5) \
			/ (float(steps - 1) * 0.5)
		var lit := colour
		lit.a = STRENGTH * (1.0 - away) * _bell(through)
		var wide := band / float(steps)
		var x := middle - band * 0.5 + wide * float(step)
		draw_rect(Rect2(x, 0.0, wide + 1.0, screen.y), lit, true)


## Up and down again, so the band arrives and leaves rather than appearing at
## full strength and being cut off at the end.
func _bell(through: float) -> float:
	return sin(clampf(through, 0.0, 1.0) * PI)
