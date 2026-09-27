class_name Farm
extends RefCounted

## The farm: what every cell is made of, and what is standing on it.
##
## **One grid, both realities.** `design.md` pillar 1 is that there is a single
## farm and it is the whole world; pillar 2 is that the night is the same tiles
## doing a different job. So there is one terrain array and one occupant table,
## and the day screen and the night screen are two views of them. A second copy
## for the night would be a second thing to keep in step, and it would drift the
## first week.
##
## Terrain is a `PackedByteArray` of `Grid.CELLS`: compact, copied deeply by
## `State.copy()`, and hashed as one string rather than 720.
##
## Occupants are sparse - most of the farm is empty - so they live in a
## Dictionary keyed by flat index. An occupant is plain data: `{"id": &"tree",
## ...}` plus whatever its kind needs. At most one per cell, which is what makes
## `place()` able to refuse rather than stack.

enum Terrain { GRASS, SOIL, WATER, ROCK, PATH, FLOOR }

## Terrain nothing can be built on, whatever is or is not standing there.
const UNBUILDABLE := [Terrain.WATER, Terrain.ROCK]

## Terrain nothing can walk across.
const UNWALKABLE := [Terrain.WATER, Terrain.ROCK]

## Occupants that were there when the farm was made and are part of it.
## The house can never be built on, sold, or walked through.
const FIXTURES := [&"house", &"shop"]


## The keys this subsystem owns. `State.create()` merges them in.
static func initial() -> Dictionary:
	var terrain := PackedByteArray()
	terrain.resize(Grid.CELLS)
	var occupants := {}

	for y in Grid.HEIGHT:
		var row: String = GameData.FARM_MAP[y]
		for x in Grid.WIDTH:
			var ch := row[x]
			var entry: Array = GameData.MAP_LEGEND[ch]
			var idx := Grid.index(Vector2i(x, y))
			terrain[idx] = int(entry[0])
			var occupant_id: StringName = entry[1]
			if occupant_id != &"":
				occupants[idx] = {"id": occupant_id}

	return {
		"terrain": terrain,
		"occupants": occupants,
		# **Bumped by every placement and removal.** `Pathing` rebuilds its
		# flow field when the one it holds was built for an older number - a
		# counter rather than a hash of the occupants, because hashing them
		# every tick to find out nothing moved is the cost the field exists to
		# avoid.
		"grid_version": 1,
		# What the farmhouse can take. A lever, and the night ends when it
		# reaches zero.
		"house_hp": GameData.HOUSE_HP,
		# **Worked out once.** The house is a fixture and never moves, and
		# `house_centre()` was scanning and sorting every occupant on the farm -
		# once per tower per tick, which with a wave on the ground was most of
		# what targeting cost.
		"house_cell": _centre_of(occupants),
	}


## The middle of the 3x3 farmhouse, from the occupant table it was built from.
static func _centre_of(occupants: Dictionary) -> Array:
	var sum := Vector2i.ZERO
	var n := 0
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		if (occupants[idx] as Dictionary)["id"] == &"house":
			sum += Grid.cell(int(idx))
			n += 1
	if n == 0:
		return [Grid.WIDTH / 2, Grid.HEIGHT / 2]
	return [sum.x / n, sum.y / n]


static func terrain_at(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	return -1 if idx < 0 else int((state["terrain"] as PackedByteArray)[idx])


## What is standing on a cell, or an empty Dictionary. **The only way to ask.**
static func occupant(state: Dictionary, cell: Vector2i) -> Dictionary:
	var idx := Grid.index(cell)
	if idx < 0:
		return {}
	return (state["occupants"] as Dictionary).get(idx, {})


static func is_empty(state: Dictionary, cell: Vector2i) -> bool:
	return occupant(state, cell).is_empty()


## Whether something may be placed here. **The only way to ask.**
##
## Water and the rock face are out because of what they are; anything already
## occupied is out because a cell holds one thing; the house is out because it
## is the thing being defended, and a player who walls in their own front door
## has not made an interesting decision.
static func buildable(state: Dictionary, cell: Vector2i) -> bool:
	var t := terrain_at(state, cell)
	if t < 0 or UNBUILDABLE.has(t):
		return false
	return is_empty(state, cell)


## Why not, in words, for the ghost that turns red under the cursor.
## Empty when it is buildable.
static func why_not_buildable(state: Dictionary, cell: Vector2i) -> String:
	var t := terrain_at(state, cell)
	if t < 0:
		return "off the farm"
	if t == Terrain.WATER:
		return "in the water"
	if t == Terrain.ROCK:
		return "on the rock face"
	var on := occupant(state, cell)
	if not on.is_empty():
		if on["id"] == &"house":
			return "on the house"
		return "already occupied by a %s" % on["id"]
	return ""


## Whether a person or a zombie can stand here.
##
## Fixtures block; so does anything the player built, which is the whole point
## of a wall. Task 0049 turns this into a cost rather than a yes or no, so that
## a zombie prefers the open lane and breaks through when it must.
static func walkable(state: Dictionary, cell: Vector2i) -> bool:
	var t := terrain_at(state, cell)
	if t < 0 or UNWALKABLE.has(t):
		return false
	return is_empty(state, cell)


## Put something on a cell. False and no change when it will not go there.
static func place(state: Dictionary, cell: Vector2i, occupant_data: Dictionary) -> bool:
	if not buildable(state, cell):
		return false
	var occupants: Dictionary = state["occupants"]
	occupants[Grid.index(cell)] = occupant_data.duplicate(true)
	_changed(state)
	return true


## Put something back that the farm owns, wherever it belongs.
##
## **Not `place()`**, and the difference matters: `place()` asks whether the
## *player* may build there, and the rock face is not buildable. Ore and stone
## seams live in the rock face, so regrowth going through `place()` meant they
## were quietly never coming back - a bug that survived task 0016 because the
## only thing tested for regrowth was a tree, and trees stand on grass.
##
## This asks only that the cell is on the farm and empty.
static func restore(state: Dictionary, cell: Vector2i, occupant_data: Dictionary) -> bool:
	var idx := Grid.index(cell)
	if idx < 0 or not is_empty(state, cell):
		return false
	(state["occupants"] as Dictionary)[idx] = occupant_data.duplicate(true)
	_changed(state)
	return true


## Take whatever is on a cell off it. False when there was nothing, or when it
## is part of the farm rather than something put there.
static func remove(state: Dictionary, cell: Vector2i) -> bool:
	var idx := Grid.index(cell)
	if idx < 0:
		return false
	var occupants: Dictionary = state["occupants"]
	if not occupants.has(idx):
		return false
	if FIXTURES.has((occupants[idx] as Dictionary)["id"]):
		return false
	occupants.erase(idx)
	_changed(state)
	return true


## Something went up or came down. Anything that caches a fact about the shape
## of the farm watches this number.
static func _changed(state: Dictionary) -> void:
	state["grid_version"] = int(state["grid_version"]) + 1


## Every cell holding a given occupant id, in index order.
##
## Sorted by construction: the caller gets the same list in the same order on
## every machine, which matters the moment something iterates trees and draws
## from the RNG.
static func cells_with(state: Dictionary, id: StringName) -> Array:
	var out: Array = []
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		if (occupants[idx] as Dictionary)["id"] == id:
			out.append(Grid.cell(idx))
	return out


## Every cell of a given terrain, in index order. The field is
## `cells_of(state, Farm.Terrain.SOIL)`; the pond is the WATER one.
static func cells_of(state: Dictionary, terrain: int) -> Array:
	var out: Array = []
	var bytes: PackedByteArray = state["terrain"]
	for idx in Grid.CELLS:
		if int(bytes[idx]) == terrain:
			out.append(Grid.cell(idx))
	return out


## Where the farmhouse is - the centre of its 3x3, which is what the flow field
## of task 0025 aims at and what the camera frames.
static func house_centre(state: Dictionary) -> Vector2i:
	var at: Array = state["house_cell"]
	return Vector2i(int(at[0]), int(at[1]))
