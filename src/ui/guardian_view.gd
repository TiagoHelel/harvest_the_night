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
## Four states, A003's (`PlaceholderArt.ART`): `day` (still), `wake` (played
## once when the night begins), `night` (an idle loop with the eyes lit) and
## `point` (0133 plays it when a defence goes down). The eyes are emission
## points - `light` / `lights` on every lit frame - that `lighting.gd` puts a
## small warm glow on. Until A003 lands it is drawn by code in A003's box:
## 32x48 with the post's foot on (16,44).

## From `House.porch` to the guardian's cell: the footprint's front-left
## corner, three cells left of the door and one up.
const OFFSET := Vector2i(-3, -1)

var _state: Dictionary = {}
var _playing: StringName = &""
var _elapsed := 0.0
var _was_day := true
var _textures: Dictionary = {}


## The cell it stands on, or (-1, -1) on a farm with no house.
static func cell_of(state: Dictionary) -> Vector2i:
	var porch := House.porch(state)
	return Vector2i(-1, -1) if porch.x < 0 else porch + OFFSET


## Where its feet are, in world pixels: the bottom middle of its cell.
static func feet_of(state: Dictionary) -> Vector2:
	var at := cell_of(state)
	return (Vector2(at) + Vector2(0.5, 1.0)) * float(GameData.TILE_SIZE)


## Its lit eyes in world pixels, for `lighting.gd`: the night frame's points,
## from the build step to the morning, and none by day.
static func eyes(state: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if state.is_empty() or int(state.get("phase", Phases.DAY)) == Phases.DAY \
			or cell_of(state).x < 0:
		return points
	var shape := PlaceholderArt.frame(PlaceholderArt.art_path(&"guardian_night", 0))
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
	var entry := PlaceholderArt.art(_playing)
	if entry.is_empty():
		return 0
	var frames := maxi(int(entry["frames"]), 1)
	var each := maxf(float(entry["seconds"]), 0.01)
	var at := int(_elapsed / each)
	return at % frames if bool(entry["loop"]) else mini(at, frames - 1)


func _length(name: StringName) -> float:
	var entry := PlaceholderArt.art(name)
	return 0.0 if entry.is_empty() else int(entry["frames"]) * float(entry["seconds"])


func _draw() -> void:
	if _playing == &"":
		return
	var path := PlaceholderArt.art_path(_playing, frame())
	var shape := PlaceholderArt.frame(path)
	var origin := -Vector2(shape.get("pivot", Vector2i(16, 44))) - Vector2(0.0, 1.0)
	if not PlaceholderArt.is_drawn(path):
		if not _textures.has(path):
			_textures[path] = load(path) if ResourceLoader.exists(path) else null
		if _textures[path] != null:
			draw_texture(_textures[path], origin)
		return
	_draw_stand_in(origin, frame(), shape.has("lights"))


# ------------------------------------------------------------- the stand-in

## A003's scarecrow in code: hat, burlap head, blue shirt on a crossbar, one
## post. Its parts move a pixel between frames the way the pack describes.
func _draw_stand_in(origin: Vector2, at: int, lit: bool) -> void:
	var bow := 0          # the head bowed by day
	var sway := 0         # tufts and tails in the wind at night
	var arm_up := false   # the point
	match _playing:
		&"guardian_day":
			bow = 1
		&"guardian_wake":
			bow = 1 if at == 0 else 0
		&"guardian_night":
			# The head holds still, so the eyes stay on their points.
			sway = [0, -1, 0, 1][at % 4]
		&"guardian_point":
			arm_up = at >= 1
	# The post and the crossbar.
	_rect(origin, 15, 15, 2, 29, &"wood")
	_rect(origin, 17, 15, 1, 29, &"wood_dark")
	_rect(origin, 4, 15, 24, 2, &"wood")
	# The shirt over the crossbar, its tails blowing.
	_rect(origin, 11, 15, 10, 11, &"cloth")
	_rect(origin, 11 + sway, 26, 10, 2, &"cloth_dark")
	_rect(origin, 14, 18, 3, 3, &"roof")
	# The sleeves along the bar, or the left one up for the point.
	_rect(origin, 21, 14, 6, 3, &"cloth")
	_rect(origin, 27, 14 + sway, 1, 3, &"gold")
	if arm_up:
		for step in 6:
			_rect(origin, 10 - step, 14 - step, 2, 2, &"cloth")
		_rect(origin, 3, 7, 2, 2, &"gold")
	else:
		_rect(origin, 5, 14, 6, 3, &"cloth")
		_rect(origin, 4, 14 + sway, 1, 3, &"gold")
	# Straw at the neck.
	_rect(origin, 13 + sway, 14, 6, 1, &"gold")
	# The burlap head, the hat and its band.
	var head := bow
	_rect(origin, 12, 9 + head, 8, 5, &"bone_dark")
	_rect(origin, 12, 13 + head, 8, 1, &"soil_light")
	_rect(origin, 9, 8 + head, 14, 1, &"gold")
	_rect(origin, 12, 6 + head, 8, 2, &"gold_light")
	_rect(origin, 12, 7 + head, 8, 1, &"wood_dark")
	# The eyes: stitches by day, two warm points at night (A003's lights).
	if lit:
		for eye in PlaceholderArt.GUARDIAN_EYES:
			_rect(origin, eye.x, eye.y + head, 1, 1, &"flame_hot")
	else:
		_rect(origin, 13, 11 + head, 2, 1, &"ink")
		_rect(origin, 17, 11 + head, 2, 1, &"ink")
	_rect(origin, 14, 13 + head, 4, 1, &"ink")


func _rect(origin: Vector2, x: int, y: int, w: int, h: int, colour: StringName) -> void:
	draw_rect(Rect2(origin + Vector2(x, y), Vector2(w, h)), PaletteData.COLOURS[colour])
