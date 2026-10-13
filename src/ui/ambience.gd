class_name Ambience
extends Node

## The bed under everything, and the things that happen on top of it.
##
## Two continuous beds that crossfade on the same cue the music does, and nine
## one-shots fired at intervals this picks - a bird, a lap of the pond, a gust,
## a cricket, an owl, something out past the fence.
##
## ## Why the touches are one-shots and not part of the bed
##
## Baking the birds into a sixteen-second loop would make them a sixteen-second
## loop, and a bird that calls on the beat is the one thing a player would
## notice. Fired separately they never repeat, and **they get the distance
## falloff for nothing**: a lap of water played at the pond's own cell is
## louder when you are standing next to the pond, through exactly the same
## machinery as a gunshot. That is task 0087's second requirement and it took
## no new code at all.
##
## ## It lives here and not in `src/app/`
##
## The prompt suggested `src/app/ambience.gd`. This reads the phase, the
## terrain and where the farmer is standing - which is game state, and
## `src/app/` is services: nodes, disk, the audio server. `Music` and `Sfx`
## are in `src/ui/` for the same reason and this is their third sibling. What
## *is* in `src/app/` is the part that belongs there: `Audio.duck()`, which
## knows about buses and nothing about farms.

const DAY_BED := &"ambience/day_bed"
const NIGHT_BED := &"ambience/night_bed"

## **The weather's beds and winter's** (task 0286): fog and rain on the nights
## that have them, and wind - no birds, no crickets - through winter's day and
## night. An event night's bed beats the season's; winter's beats the
## ordinary two. The event is 0256's `Weather` answer for the run's seed and
## the date, the one the forecast reads - never drawn here.
const FOG_BED := &"ambience/fog_bed"
const RAIN_BED := &"ambience/rain_bed"
const WINTER_BED := &"ambience/winter_bed"
const EVENT_BEDS := {
	&"fog": FOG_BED,
	&"rain": RAIN_BED,
}

## **An event night's stinger** (task 0286), once, as its build step opens:
## the cue in `assets/music/` (the Music bus) for the same `Weather` answer
## the bed reads, and the Full Moon (0152's `Calendar.is_full_moon`) when the
## night has no weather of its own.
const STINGERS := {
	&"fog": &"music/sting_fog",
	&"rain": &"music/sting_rain",
	&"blood_moon": &"music/sting_blood_moon",
	&"full_moon": &"music/sting_full_moon",
}

## What might happen by day, and how often one of them does.
const DAY_TOUCHES: Array = [
	&"ambience/bird_high",
	&"ambience/bird_low",
	&"ambience/bird_trill",
	&"ambience/breeze",
	&"ambience/water_lap",
]

const NIGHT_TOUCHES: Array = [
	&"ambience/cricket",
	&"ambience/owl",
	&"ambience/wind_gust",
	&"ambience/far_groan",
]

## **Winter's own** (task 0286): no songbird by day and no cricket by night.
## The pond is ice, so its lap is out too, and cracks instead.
const WINTER_DAY_TOUCHES: Array = [
	&"ambience/icicle_drip",
	&"ambience/snow_creak",
	&"ambience/breeze",
]
const WINTER_NIGHT_TOUCHES: Array = [
	&"ambience/ice_crack",
	&"ambience/owl",
	&"ambience/wind_gust",
	&"ambience/far_groan",
]

## **The animals near their homes** (task 0286): by day each kind's call, at
## the door of a coop or barn that has that kind in it (0183's residents),
## through the falloff; at night one sleepy murmur from a home with anyone
## inside (0186). **A wrecked home still murmurs**: 0186 keeps it standing at
## 0 HP with its animals in it, unfed, and hearing them is how a player
## remembers it is waiting to be mended.
const ANIMAL_CALLS := {
	&"chicken": &"ambience/cluck",
	&"cow": &"ambience/moo",
	&"sheep": &"ambience/baa",
	&"pig": &"ambience/oink",
}
const MURMUR := &"ambience/murmur"

## Seconds between one touch and the next, picked afresh each time.
##
## **Wide, and deliberately.** A gap that is always the same is a metronome,
## and the done-when is that standing still for a minute is pleasant. Four to
## eleven seconds means a farm is never silent for long and never busy.
const GAP_LOW := 4.0
const GAP_HIGH := 11.0

## The touches that come from somewhere in particular rather than from the
## air around the farmer.
const AT_THE_POND: Array = [&"ambience/water_lap"]
const AT_THE_TREES: Array = [
	&"ambience/bird_high", &"ambience/bird_low", &"ambience/bird_trill",
]
const OUT_PAST_THE_FENCE: Array = [&"ambience/far_groan"]

const AudioScript := preload("res://src/app/audio.gd")

var _state: Dictionary = {}
var _world: WorldView = null
var _audio: Node = null

var _next := 0.0
var _rng := RandomNumberGenerator.new()

## The phase last frame, so a build step opening is an edge (task 0286).
var _phase := -1


func show_state(state: Dictionary, world: WorldView) -> void:
	_state = state
	_world = world
	_next = GAP_LOW
	_phase = -1


func _ready() -> void:
	_audio = get_node_or_null(^"/root/Audio")
	# Its own generator, like the pitch jitter's: seeding the globals - which
	# `src/tools/shot.gd` does to make the smoke reproducible - must not also
	# decide when the next bird calls.
	_rng.seed = 87087


func _process(delta: float) -> void:
	if _audio == null or _state.is_empty():
		return
	var phase := int(_state["phase"])
	var date := Calendar.date(_state)
	var season := Calendar.season_id(date)
	var event := Weather.tonight(_state)
	_audio.play_bed(bed_for(phase, season, event), _fade_seconds())
	# **The stinger, once, as the build step opens** (task 0286).
	if _phase >= 0 and _phase != phase and phase == Phases.PREPARATION:
		var cue := stinger_for(event, Calendar.is_full_moon(date))
		if cue != &"":
			_audio.play(cue, AudioScript.NOWHERE, 1)
	_phase = phase

	_next -= delta
	if _next > 0.0:
		return
	_next = _rng.randf_range(GAP_LOW, GAP_HIGH)
	var choices := touches_for(phase, season) + animal_touches(_state, phase)
	if choices.is_empty():
		return
	var id: StringName = choices[_rng.randi_range(0, choices.size() - 1)]
	_audio.play(id, _where(id), 1)


## The crossfade is the transition's, exactly as the music's is: the bed has
## to turn over with the sky, not before or after it.
func _fade_seconds() -> float:
	if _world != null:
		return _world.transition_seconds()
	return GameData.TRANSITION_SECONDS


# -------------------------------------------------------------- the decisions

## Which bed belongs to a phase. Static so a check can ask it directly.
##
## Since task 0286 it takes the season (0149's id) and tonight's event (0256's
## `Weather` answer): from the build step to the morning report an event night
## with a bed of its own has it, and winter has the wind by day and night.
## The event and the season do not change inside a night, so neither does
## the bed.
static func bed_for(phase: int, season: StringName = &"spring",
		event: StringName = &"") -> StringName:
	if phase != Phases.DAY and EVENT_BEDS.has(event):
		return EVENT_BEDS[event]
	if season == &"winter":
		return WINTER_BED
	return DAY_BED if phase == Phases.DAY else NIGHT_BED


static func touches_for(phase: int, season: StringName = &"spring") -> Array:
	if season == &"winter":
		return WINTER_DAY_TOUCHES if phase == Phases.DAY else WINTER_NIGHT_TOUCHES
	return DAY_TOUCHES if phase == Phases.DAY else NIGHT_TOUCHES


## **The stinger an event night opens with** (task 0286): its weather's, or the
## Full Moon's when it has none; `&""` for a plain night.
static func stinger_for(event: StringName, full_moon: bool) -> StringName:
	if STINGERS.has(event):
		return STINGERS[event]
	return STINGERS[&"full_moon"] if full_moon else &""


## **Which animals are home** (task 0286): kind -> the anchor cells of the
## coops and barns standing with that kind inside, in cell order.
static func animal_homes(state: Dictionary) -> Dictionary:
	var out := {}
	var housed: Dictionary = state.get("housed", {})
	var keys: Array = housed.keys()
	keys.sort()             # anchor cell indices, integers
	for idx in keys:
		var cell := Grid.cell(int(idx))
		if not Livestock.is_home(StringName(Farm.occupant(state, cell).get("id", &""))):
			continue
		for one in Livestock.residents(state, cell):
			var kind := StringName((one as Dictionary).get("id", &""))
			if not out.has(kind):
				out[kind] = []
			if not (out[kind] as Array).has(cell):
				(out[kind] as Array).append(cell)
	return out


## The animal touches on offer now (task 0286): each kind's call by day where
## its home stands with it inside, the murmur at night where any home does.
static func animal_touches(state: Dictionary, phase: int) -> Array:
	var homes := animal_homes(state)
	var out: Array = []
	if phase == Phases.DAY:
		for kind in GameData.sorted_names(homes.keys()):
			if ANIMAL_CALLS.has(kind):
				out.append(ANIMAL_CALLS[kind])
	elif not homes.is_empty():
		out.append(MURMUR)
	return out


# ----------------------------------------------------------------- the places

## Where a touch comes from.
##
## `NOWHERE` means "around the farmer" - a breeze has no cell, and giving one
## a position would make the wind quieter on the far side of a field.
func _where(id: StringName) -> Vector2:
	# An animal at the door of the nearest home it lives in; the murmur at
	# the nearest home with anyone inside.
	var homes := animal_homes(_state)
	for kind in GameData.sorted_names(homes.keys()):
		if ANIMAL_CALLS.get(kind, &"") == id:
			return _nearest_doors(homes[kind])
	if id == MURMUR:
		var all: Array = []
		for kind in GameData.sorted_names(homes.keys()):
			all.append_array(homes[kind])
		return _nearest_doors(all)
	if AT_THE_POND.has(id):
		return _nearest(Farm.cells_of(_state, Farm.Terrain.WATER))
	if AT_THE_TREES.has(id):
		return _nearest(Farm.cells_with(_state, &"tree"))
	if OUT_PAST_THE_FENCE.has(id):
		return _off_the_edge()
	return AudioScript.NOWHERE


## The nearest of these homes' doors, in pixels.
func _nearest_doors(homes: Array) -> Vector2:
	var doors: Array = []
	for cell in homes:
		doors.append(Livestock.door_of(_state, cell as Vector2i))
	return _nearest(doors)


## The closest of a set of cells, in pixels, or nowhere when there are none.
func _nearest(cells: Array) -> Vector2:
	if cells.is_empty():
		return AudioScript.NOWHERE
	var ears := _middle_of(Player.cell(_state))
	var best := AudioScript.NOWHERE
	var closest := INF
	for cell in cells:
		var at := _middle_of(cell as Vector2i)
		var how_far := ears.distance_to(at)
		if how_far < closest:
			closest = how_far
			best = at
	return best


## A long way off, on the side of the farm the player is not on - so that
## something groaning out past the fence is always distant.
func _off_the_edge() -> Vector2:
	var here := Player.cell(_state)
	var far_x := 0 if here.x > GameData.GRID_WIDTH / 2 else \
		GameData.GRID_WIDTH - 1
	return _middle_of(Vector2i(far_x, here.y))


func _middle_of(cell: Vector2i) -> Vector2:
	var size := float(GameData.TILE_SIZE)
	return Vector2(cell.x * size + size * 0.5, cell.y * size + size * 0.5)
