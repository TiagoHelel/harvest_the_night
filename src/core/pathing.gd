class_name Pathing
extends RefCounted

## How everything finds the farmhouse.
##
## **One flow field, not one A\* per zombie.** A sweep out from the house fills
## every cell with what getting home from it costs; a zombie then only ever
## looks at its four neighbours and steps to the cheapest. That is four
## comparisons per zombie per tick against a whole search per zombie, and it is
## why a hundred of them cost nothing.
##
## It also happens to be the right answer for the game rather than only the
## fast one: every zombie agrees about what the cheapest way is, so a wall
## reroutes the whole wave at once and the player can see their plan working.
##
## ## Cost, not blocked
##
## Until task 0049 a wall was impassable and the field was a plain
## breadth-first count of steps. That made a wall a **wall**: a zombie would
## walk the entire length of the farm to get around one, and only ever broke
## something when it was sealed in with no route at all. `design.md` says a
## wall "bloqueia/atrasa" - blocks *and delays* - and a barrier you can always
## walk around does neither for long.
##
## So a barrier is priced instead. Stepping onto a cell costs what the terrain
## costs, plus the structure's `path_cost` if something is standing there -
## which reads as "going through this is worth this many tiles of detour". A
## zombie whose cheapest way home runs through a wall stops and takes the wall
## apart, because that genuinely is the cheapest way home.
##
## **Only a barrier is priced.** A tower or a workshop declares no `path_cost`
## and stays impassable, so a wave flows around the buildings and through the
## walls. That is the distinction the table already drew and it is the one the
## game wants: the player's towers are not a road, and the enemy that goes
## after towers on purpose is task 0052.
##
## ## A zombie cannot oscillate
##
## Every step is onto a cell whose field value is `field[here] - enter(next)`,
## and every `enter` is at least one. So a zombie's field value **strictly
## decreases on every step it takes** and it can never return to a cell it has
## left. That is not a tie-break rule bolted on afterwards, it is the shape of
## the field, and `headless_check` asserts it over a maze.
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
## equally cheap ways out takes the first one. That decides which side of a
## wall a wave flows around, so it is a rule - not whatever order the
## neighbours happened to come back in.

## A cell the house cannot be reached from: walled in, or across the pond.
const UNREACHABLE := 0x7FFFFFFF

## What an impassable cell costs to step onto. Nothing steps onto it, so the
## number is never added to anything - it is a marker, and zero is the one
## value a real cost can never be.
const IMPASSABLE := 0


static func initial() -> Dictionary:
	return {
		"flow": PackedInt32Array(),
		# What stepping onto each cell costs, built with the field above and
		# read beside it. Keeping it means `step_from()` never has to ask the
		# occupant table anything, which is what makes the hot line four array
		# reads instead of four dictionary lookups.
		"flow_cost": PackedInt32Array(),
		# Which `grid_version` the two above were built for. -1 is "never".
		"flow_version": -1,
	}


## Make sure the field matches the farm. Cheap when nothing moved.
static func refresh(state: Dictionary) -> void:
	if int(state["flow_version"]) == int(state["grid_version"]) \
			and (state["flow"] as PackedInt32Array).size() == Grid.CELLS:
		return
	var built := _build(state)
	state["flow"] = built["field"]
	state["flow_cost"] = built["cost"]
	state["flow_version"] = int(state["grid_version"])


## What getting from this cell to the house costs. `UNREACHABLE` when there is
## no way at all.
##
## **It is a cost, not a number of steps.** Two cells the same distance apart
## can differ here, which is the whole point: that is how a zombie knows the
## long way round the wall is cheaper than the short way through it.
static func distance(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	if idx < 0:
		return UNREACHABLE
	var field: PackedInt32Array = state["flow"]
	if field.size() != Grid.CELLS:
		return UNREACHABLE
	return int(field[idx])


## What stepping onto this cell costs, or `IMPASSABLE`.
static func entry_cost(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	if idx < 0:
		return IMPASSABLE
	var cost: PackedInt32Array = state["flow_cost"]
	if cost.size() != Grid.CELLS:
		return IMPASSABLE
	return int(cost[idx])


## The next cell on the way to the house, or the same cell when there is
## nowhere to go.
##
## **The next cell may be one that has to be broken first.** The field prices a
## barrier rather than refusing it, so the cheapest way on can run straight
## through a wall - and it is the caller who decides what to do about that.
## `Enemies` asks `breaks_through()` and bites instead of walking.
##
## Nowhere to go is a real answer, not a failure: it means every neighbour is
## impassable or leads away from home.
static func step_from(state: Dictionary, cell: Vector2i) -> Vector2i:
	# Both arrays are taken once and read four times. Going through
	# `distance()` meant four dictionary lookups, four bounds checks and four
	# size checks for what is eight array reads - and this is the hottest line
	# in the night.
	var field: PackedInt32Array = state["flow"]
	var cost: PackedInt32Array = state["flow_cost"]
	if field.size() != Grid.CELLS or cost.size() != Grid.CELLS:
		return cell
	var idx := Grid.index(cell)
	if idx < 0:
		return cell
	var here := int(field[idx])
	if here == UNREACHABLE or here == 0:
		return cell

	var best := cell
	var best_total := UNREACHABLE
	for offset in Grid.STEPS:
		var n: Vector2i = cell + offset
		if n.x < 0 or n.y < 0 or n.x >= Grid.WIDTH or n.y >= Grid.HEIGHT:
			continue
		var n_idx := n.y * Grid.WIDTH + n.x
		var enter := int(cost[n_idx])
		if enter == IMPASSABLE:
			continue
		var there := int(field[n_idx])
		if there == UNREACHABLE:
			continue
		# **What the step costs, not what the cell is worth.** Comparing raw
		# field values was right while every step cost one and is wrong now: a
		# wall's own field value is small, because the wall is near the house.
		# What makes it expensive is getting into it.
		var total := there + enter
		# `<` rather than `<=`, so the first direction in `Grid.STEPS` wins a
		# tie. Which side of a wall a wave flows around is a rule.
		if total < best_total:
			best_total = total
			best = n
	return best


## Whether the way on runs through something that has to come down first.
##
## The house is where they are going and a trap is something they step on;
## anything else standing on a cell the field chose is a barrier, because a
## structure with no `path_cost` was never passable to begin with.
static func breaks_through(state: Dictionary, cell: Vector2i) -> bool:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return false
	var id := StringName(on["id"])
	if id == &"house" or Traps.is_trap(id):
		return false
	return true


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
	var occupants: Dictionary = state["occupants"]
	var idx := Grid.index(blocked)
	if idx < 0:
		return []
	var was: Variant = occupants.get(idx, null)

	# Pretend, ask, put it back. Nothing else may run between these two lines,
	# and nothing does: this is a query, not a tick.
	occupants[idx] = {"id": &"wall", "hp": 1}
	var built := _build(state)
	if was == null:
		occupants.erase(idx)
	else:
		occupants[idx] = was

	var field: PackedInt32Array = built["field"]
	var cost: PackedInt32Array = built["cost"]
	var out: Array = []
	var at := from
	for _step in most:
		var next := _step_in(field, cost, at)
		if next == at:
			break
		out.append(next)
		at = next
	return out


## One step downhill in a given field. `step_from()` is this against the
## field the game is actually using.
static func _step_in(field: PackedInt32Array, cost: PackedInt32Array,
		cell: Vector2i) -> Vector2i:
	var idx := Grid.index(cell)
	if idx < 0 or field.size() != Grid.CELLS:
		return cell
	if int(field[idx]) == UNREACHABLE or int(field[idx]) == 0:
		return cell
	var best := cell
	var best_total := UNREACHABLE
	for step in Grid.STEPS:
		var at: Vector2i = cell + (step as Vector2i)
		var into := Grid.index(at)
		if into < 0:
			continue
		var enter := int(cost[into])
		if enter == IMPASSABLE or int(field[into]) == UNREACHABLE:
			continue
		var total := int(field[into]) + enter
		if total < best_total:
			best_total = total
			best = at
	return best


## Whether anything can get from this cell to the house at all.
static func reachable(state: Dictionary, cell: Vector2i) -> bool:
	return distance(state, cell) != UNREACHABLE


# ------------------------------------------------------------------ building

## The field and the entry costs it was swept with, built together because the
## second is what the first means.
static func _build(state: Dictionary) -> Dictionary:
	var cost := _entry_costs(state)
	var field := PackedInt32Array()
	field.resize(Grid.CELLS)
	field.fill(UNREACHABLE)

	# **A bucket wheel, not a heap.** Every step costs between one and
	# `WIDEST_STEP`, so the cells to visit can be filed by cost into that many
	# buckets and read back in order - Dial's algorithm. It is the same answer
	# a priority queue gives, in a fraction of the work, and the order inside a
	# bucket is the order things went in, which is one fewer thing that could
	# differ between two machines.
	#
	# Plain `Array` buckets rather than `PackedInt32Array`: a packed array is a
	# value type, so `wheel[i].append(x)` would be appending to a copy.
	var wheel_size := GameData.WIDEST_STEP + 1
	var wheel: Array = []
	for _i in wheel_size:
		wheel.append([])

	var queued := 0
	for cell in Farm.cells_with(state, &"house"):
		var idx := Grid.index(cell)
		if idx < 0 or int(field[idx]) == 0:
			continue
		field[idx] = 0
		(wheel[0] as Array).append(idx)
		queued += 1

	# Nothing is ever filed further ahead than `WIDEST_STEP`, so the bucket
	# being emptied is never one being filled: the wheel can be a ring.
	var d := 0
	while queued > 0:
		var slot := d % wheel_size
		var bucket: Array = wheel[slot]
		if not bucket.is_empty():
			wheel[slot] = []
			for entry in bucket:
				var idx := int(entry)
				queued -= 1
				# A cheaper way here turned up after this one was filed.
				if int(field[idx]) != d:
					continue
				var cell := Grid.cell(idx)
				# **The step costs what entering `cell` costs, not what
				# entering the neighbour costs.** The sweep runs outward from
				# the house and the walking runs inward, so the move being
				# priced here is the neighbour's move *into this cell* - the
				# reverse of the direction being searched.
				#
				# While every cell cost one the two were the same number and
				# the mistake was invisible. With a wall worth twenty-one it
				# is not: the field came out disagreeing with `step_from()`,
				# which then had cells whose cheapest neighbour was worth more
				# than they were, and a zombie walked in a circle for four
				# hundred steps instead of arriving.
				var enter := int(cost[idx])
				for offset in Grid.STEPS:
					var n: Vector2i = cell + offset
					var n_idx := Grid.index(n)
					if n_idx < 0:
						continue
					# Nothing can stand here, so nothing walks in from it.
					if int(cost[n_idx]) == IMPASSABLE:
						continue
					var through := d + enter
					if through >= int(field[n_idx]):
						continue
					field[n_idx] = through
					(wheel[through % wheel_size] as Array).append(n_idx)
					queued += 1
		d += 1
	return {"field": field, "cost": cost}


## What stepping onto each cell costs, `IMPASSABLE` where nothing may.
##
## Built once per rebuild and kept, so the tick never asks the occupant table
## anything. A few hundred microseconds on the tick a wall falls is a price
## worth paying once; it is not a price worth paying per zombie per tick.
##
## **Terrain in one pass, then only the cells with something on them.** The
## first version asked `Farm.occupant()` about every cell on the farm - seven
## hundred dictionary lookups to find the forty that had an answer - and that
## was most of the rebuild.
static func _entry_costs(state: Dictionary) -> PackedInt32Array:
	var cost := PackedInt32Array()
	cost.resize(Grid.CELLS)
	var terrain: PackedByteArray = state["terrain"]
	for idx in Grid.CELLS:
		cost[idx] = Farm.cost_of_terrain(int(terrain[idx]))

	var occupants: Dictionary = state["occupants"]
	# Sorted, though nothing here depends on the order: each entry writes its
	# own cell and no two write the same one. A loop over an unsorted
	# Dictionary in `src/core/` is the kind of thing that is fine until the
	# day somebody makes it matter, so it is sorted and the reason is here.
	var where: Array = occupants.keys()
	where.sort()
	for key in where:
		var idx := int(key)
		if idx < 0 or idx >= Grid.CELLS or int(cost[idx]) == IMPASSABLE:
			continue
		cost[idx] = _through(StringName((occupants[key] as Dictionary)["id"]),
			int(cost[idx]))
	return cost


## What stepping onto a cell with this standing on it costs, given what the
## ground under it costs.
static func _through(id: StringName, ground: int) -> int:
	# The house is the destination, so it has to be reachable even though
	# nothing can stand on it.
	if id == &"house":
		return ground
	# **A mine is walked onto, not walked around.** An occupant that blocks is
	# an occupant the field routes around, and a mine every zombie can see and
	# step past is no mine at all. Task 0048 found that by asking the route
	# where it went after one was laid on it.
	if Traps.is_trap(id):
		return ground

	# **A barrier is priced; everything else is a hole in the map.** A wall
	# declares what getting through it is worth and a tower declares nothing,
	# so a wave flows through the walls and around the buildings.
	var entry: Variant = Building.entry_of(id)
	if entry == null:
		return IMPASSABLE
	var through := int((entry as Dictionary).get("path_cost", 0))
	if through <= 0:
		return IMPASSABLE
	return ground + through
