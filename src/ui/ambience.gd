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


func show_state(state: Dictionary, world: WorldView) -> void:
	_state = state
	_world = world
	_next = GAP_LOW


func _ready() -> void:
	_audio = get_node_or_null(^"/root/Audio")
	# Its own generator, like the pitch jitter's: seeding the globals - which
	# `src/tools/shot.gd` does to make the smoke reproducible - must not also
	# decide when the next bird calls.
	_rng.seed = 87087


func _process(delta: float) -> void:
	if _audio == null or _state.is_empty():
		return
	_audio.play_bed(bed_for(int(_state["phase"])), _fade_seconds())

	_next -= delta
	if _next > 0.0:
		return
	_next = _rng.randf_range(GAP_LOW, GAP_HIGH)
	var choices := touches_for(int(_state["phase"]))
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
static func bed_for(phase: int) -> StringName:
	return DAY_BED if phase == Phases.DAY else NIGHT_BED


static func touches_for(phase: int) -> Array:
	return DAY_TOUCHES if phase == Phases.DAY else NIGHT_TOUCHES


# ----------------------------------------------------------------- the places

## Where a touch comes from.
##
## `NOWHERE` means "around the farmer" - a breeze has no cell, and giving one
## a position would make the wind quieter on the far side of a field.
func _where(id: StringName) -> Vector2:
	if AT_THE_POND.has(id):
		return _nearest(Farm.cells_of(_state, Farm.Terrain.WATER))
	if AT_THE_TREES.has(id):
		return _nearest(Farm.cells_with(_state, &"tree"))
	if OUT_PAST_THE_FENCE.has(id):
		return _off_the_edge()
	return AudioScript.NOWHERE


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
