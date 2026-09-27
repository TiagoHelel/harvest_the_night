class_name Pathing
extends RefCounted

## How everything finds the farmhouse.
##
## **One flow field, not one A\* per zombie.** A breadth-first sweep out from
## the house fills every walkable cell with its distance from it; a zombie then
## only ever looks at its four neighbours and steps to the smallest number.
## That is four comparisons per zombie per tick against a whole search per
## zombie, and it is why a hundred of them cost nothing.
##
## It also happens to be the right answer for the game rather than only the
## fast one: every zombie agrees about what the shortest way is, so a wall
## reroutes the whole wave at once and the player can see their plan working.
##
## ## When it is rebuilt
##
## Only when the grid changes. `Farm` bumps `state["grid_version"]` on every
## placement and removal, and this rebuilds when the field it holds was built
## for an older one. **A version rather than a hash**: hashing the occupants
## every tick to find out that nothing moved is the cost the field exists to
## avoid, and a counter cannot disagree with itself.
##
## ## The tie-break is written down
##
## `Grid.STEPS` is north, east, south, west, in that order, and a cell with two
## equally short ways out takes the first one. That decides which side of a
## wall a wave flows around, so it is a rule - not whatever order the
## neighbours happened to come back in.

## A cell the house cannot be reached from: walled in, or across the pond.
const UNREACHABLE := 0x7FFFFFFF


static func initial() -> Dictionary:
	return {
		"flow": PackedInt32Array(),
		# Which `grid_version` the field above was built for. -1 is "never".
		"flow_version": -1,
	}


## Make sure the field matches the farm. Cheap when nothing moved.
static func refresh(state: Dictionary) -> void:
	if int(state["flow_version"]) == int(state["grid_version"]) \
			and (state["flow"] as PackedInt32Array).size() == Grid.CELLS:
		return
	state["flow"] = _build(state)
	state["flow_version"] = int(state["grid_version"])


## How far this cell is from the house, in steps. `UNREACHABLE` when there is
## no way at all.
static func distance(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	if idx < 0:
		return UNREACHABLE
	var field: PackedInt32Array = state["flow"]
	if field.size() != Grid.CELLS:
		return UNREACHABLE
	return int(field[idx])


## The next cell on the way to the house, or the same cell when there is
## nowhere to go.
##
## Nowhere to go is a real answer, not a failure: a zombie boxed in by walls
## stands there until task 0049 gives it the idea of breaking one.
static func step_from(state: Dictionary, cell: Vector2i) -> Vector2i:
	# The field is taken once and read four times. Going through `distance()`
	# meant four dictionary lookups, four bounds checks and four size checks
	# for what is four array reads - and this is the hottest line in the night.
	var field: PackedInt32Array = state["flow"]
	if field.size() != Grid.CELLS:
		return cell
	var idx := Grid.index(cell)
	if idx < 0:
		return cell
	var best_distance := int(field[idx])
	if best_distance == UNREACHABLE or best_distance == 0:
		return cell

	var best := cell
	for offset in Grid.STEPS:
		var n: Vector2i = cell + offset
		if n.x < 0 or n.y < 0 or n.x >= Grid.WIDTH or n.y >= Grid.HEIGHT:
			continue
		var d := int(field[n.y * Grid.WIDTH + n.x])
		# `<` rather than `<=`, so the first direction in `Grid.STEPS` wins a
		# tie. Which side of a wall a wave flows around is a rule.
		if d < best_distance:
			best_distance = d
			best = n
	return best


## The route a zombie would take from here, **as if this cell were blocked**.
##
## The whole of "placing shows the path they will take afterwards". The
## alternative is to put the wall down, look, and take it up again - which
## costs the player the stone if they change their mind, and costs the code a
## build-and-undo that has to be exactly reversible.
##
## It builds one throwaway field and throws it away. That is the same few
## milliseconds `refresh()` costs, paid only while somebody is holding a wall
## over a tile and moving the mouse - and it is why the answer is cached
## against the cell being considered.
static func route_if_blocked(state: Dictionary, blocked: Vector2i,
		from: Vector2i, most: int = 200) -> Array:
	var was: Variant = (state["occupants"] as Dictionary).get(
		Grid.index(blocked), null)
	var occupants: Dictionary = state["occupants"]
	var idx := Grid.index(blocked)
	if idx < 0:
		return []

	# Pretend, ask, put it back. Nothing else may run between these two lines,
	# and nothing does: this is a query, not a tick.
	occupants[idx] = {"id": &"wall", "hp": 1}
	var field := _build(state)
	if was == null:
		occupants.erase(idx)
	else:
		occupants[idx] = was

	var out: Array = []
	var at := from
	for _step in most:
		var next := _step_in(field, at)
		if next == at:
			break
		out.append(next)
		at = next
	return out


## One step downhill in a given field. `step_from()` is this against the
## field the game is actually using.
static func _step_in(field: PackedInt32Array, cell: Vector2i) -> Vector2i:
	var idx := Grid.index(cell)
	if idx < 0 or field.size() != Grid.CELLS:
		return cell
	var best := cell
	var best_distance := int(field[idx])
	if best_distance == UNREACHABLE:
		return cell
	for step in Grid.STEPS:
		var at: Vector2i = cell + (step as Vector2i)
		var into := Grid.index(at)
		if into < 0:
			continue
		var distance := int(field[into])
		if distance < best_distance:
			best_distance = distance
			best = at
	return best


## Whether anything can get from this cell to the house at all.
static func reachable(state: Dictionary, cell: Vector2i) -> bool:
	return distance(state, cell) != UNREACHABLE


# ------------------------------------------------------------------ building

static func _build(state: Dictionary) -> PackedInt32Array:
	var field := PackedInt32Array()
	field.resize(Grid.CELLS)
	field.fill(UNREACHABLE)

	# The house is the destination, so it is distance zero and the sweep starts
	# from every cell of it at once.
	var frontier: Array = []
	for cell in Farm.cells_with(state, &"house"):
		var idx := Grid.index(cell)
		field[idx] = 0
		frontier.append(idx)

	# A plain queue rather than a priority one: every step costs the same, so
	# breadth-first already visits cells in distance order. Task 0049 turns
	# this into a cost field, and that is when it needs a heap.
	var read := 0
	while read < frontier.size():
		var idx := int(frontier[read])
		read += 1
		var cell := Grid.cell(idx)
		var next_distance := int(field[idx]) + 1
		for offset in Grid.STEPS:
			var n: Vector2i = cell + offset
			var n_idx := Grid.index(n)
			if n_idx < 0 or int(field[n_idx]) <= next_distance:
				continue
			if not _passable(state, n):
				continue
			field[n_idx] = next_distance
			frontier.append(n_idx)
	return field


## What a zombie may walk over on its way in.
##
## Not `Farm.walkable`: the house itself is the destination, so it has to be
## reachable even though nothing can stand on it. Everything else that is
## occupied blocks, which is what makes a wall a wall.
##
## **Except a trap.** A mine is a thing you step on, and an occupant that
## blocks is an occupant the flow field routes around - so every mine on the
## farm would have been a little wall with a zombie-shaped gap beside it, seen
## and avoided by everything that walks. Task 0048 found it by asking the
## route where it went after a mine was laid on it, and the route had moved.
static func _passable(state: Dictionary, cell: Vector2i) -> bool:
	var terrain := Farm.terrain_at(state, cell)
	if terrain < 0 or Farm.UNWALKABLE.has(terrain):
		return false
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return true
	if Traps.is_trap(StringName(on["id"])):
		return true
	return on["id"] == &"house"
