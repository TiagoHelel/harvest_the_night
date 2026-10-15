class_name GuardianView
extends Node2D

## **The porch guardian** (task 0131): the old scarecrow by the farmhouse, who
## wakes at the reality switch to be the player at night.
##
## **A view-only prop.** It is not an occupant and not in the state, so no
## hash can see it. It stands at a fixed offset from `House.porch` - the front
## corner of the house's own footprint, a cell nothing can ever be built on,
## clear of the door and the lit windows - and `_task_0131_guardian` checks
## that `Farm.buildable` says no there on a new farm.
##
## Four states, A003's art since task 0145: `day` (still), `wake` (played
## once when the night begins), `night` (an idle loop with the eyes lit) and
## `point` (0133 plays it when a defence goes down), on 32x48 with the post's
## foot on (16,44). The eyes are emission points - `light` / `lights` on every
## lit frame, measured on each - that `lighting.gd` puts a small warm glow on,
## following the frame that is up.

## From `House.porch` to the guardian's cell: the footprint's front-left
## corner, three cells left of the door and one up.
const OFFSET := Vector2i(-3, -1)

var _state: Dictionary = {}
var _playing: StringName = &""
var _elapsed := 0.0
var _was_day := true
var _textures: Dictionary = {}

## Where A003 delivers it, and the group `lighting.gd` finds it by.
const DIR := "res://sprites/props/"
const GROUP := &"porch_guardian"


func _ready() -> void:
	add_to_group(GROUP)


## The runtime path of one frame of one of its states.
static func path_of(name: StringName, index: int) -> String:
	return "%s%s_%d.png" % [DIR, name, index]


## How many frames a state has: as many as A003 drew.
static func frames_of(name: StringName) -> int:
	var count := 0
	while PlaceholderArt.has_frame(path_of(name, count)):
		count += 1
	return count


## The cell it stands on, or (-1, -1) on a farm with no house.
static func cell_of(state: Dictionary) -> Vector2i:
	var porch := House.porch(state)
	return Vector2i(-1, -1) if porch.x < 0 else porch + OFFSET


## Where its feet are, in world pixels: the bottom middle of its cell.
static func feet_of(state: Dictionary) -> Vector2:
	var at := cell_of(state)
	return (Vector2(at) + Vector2(0.5, 1.0)) * float(GameData.TILE_SIZE)


## Its lit eyes in world pixels, for `lighting.gd`: the points of the frame
## that is up (`shown`) - none on an unlit one - else the night idle's
## first; from the build step to the morning, and none by day.
static func eyes(state: Dictionary, shown := "") -> Array[Vector2]:
	var points: Array[Vector2] = []
	if state.is_empty() or int(state.get("phase", Phases.DAY)) == Phases.DAY \
			or cell_of(state).x < 0:
		return points
	var shape := PlaceholderArt.frame(shown if shown != "" else path_of(&"guardian_night", 0))
	var pivot := Vector2(shape.get("pivot", Vector2i(16, 44)))
	for point in shape.get("lights", []):
		points.append(feet_of(state) + Vector2(point) - pivot + Vector2(0.5, 0.5))
	return points


func show_state(state: Dictionary) -> void:
	if not is_same(state, _state):
		# A run loaded at night has no switch to watch: it is already awake.
		_was_day = int(state.get("phase", Phases.DAY)) == Phases.DAY
		_playing = &""
	_state = state


func _process(delta: float) -> void:
	if _state.is_empty():
		return
	var at := cell_of(_state)
	visible = at.x >= 0
	if not visible:
		return
	# **One pixel lower, drawn one pixel higher**: its feet are on the house's
	# own ground line, and y-sorting a tie would put it behind the wall.
	position = feet_of(_state) + Vector2(0.0, 1.0)
	var day := int(_state["phase"]) == Phases.DAY
	var wanted := _playing
	if day:
		wanted = &"guardian_day"
	elif _was_day:
		wanted = &"guardian_wake"
	elif _playing == &"" or _playing == &"guardian_day":
		wanted = &"guardian_night"
	elif _playing == &"guardian_wake" or _playing == &"guardian_point":
		if _elapsed >= _length(_playing):
			wanted = &"guardian_night"
	_was_day = day
	if wanted != _playing:
		_playing = wanted
		_elapsed = 0.0
		queue_redraw()
		return
	var before := frame()
	_elapsed += maxf(delta, 0.0)
	if frame() != before:
		queue_redraw()


## Play the point once, then back to the night idle. 0133 calls it.
func point() -> void:
	if _playing != &"guardian_day" and _playing != &"":
		_playing = &"guardian_point"
		_elapsed = 0.0
		queue_redraw()


## Which animation is up - for the tests.
func playing() -> StringName:
	return _playing


## Which frame of it: a loop goes round, a one-shot holds its last.
func frame() -> int:
	var frames := frames_of(_playing) if _playing != &"" else 0
	if frames <= 0:
		return 0
	var shape := PlaceholderArt.frame(path_of(_playing, 0))
	var each := maxf(float(shape.get("seconds", 0.1)), 0.01)
	var at := int(_elapsed / each)
	return at % frames if bool(shape.get("loop", false)) else mini(at, frames - 1)


## The frame that is up, by its runtime path - "" before the first - for
## `lighting.gd`'s eyes and the tests.
func shown() -> String:
	return "" if _playing == &"" else path_of(_playing, frame())


func _length(name: StringName) -> float:
	return frames_of(name) * float(PlaceholderArt.frame(path_of(name, 0)).get("seconds", 0.0))


func _draw() -> void:
	if _playing == &"":
		return
	var path := shown()
	var shape := PlaceholderArt.frame(path)
	var origin := -Vector2(shape.get("pivot", Vector2i(16, 44))) - Vector2(0.0, 1.0)
	# Held here: a texture loaded inside `_draw` and let go is freed before
	# the frame renders.
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	if _textures[path] != null:
		draw_texture(_textures[path], origin)
