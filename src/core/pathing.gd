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
## ## Two fields, because not everybody agrees about walls
##
## The field above is for somebody who will break through when breaking
## through is cheapest. A **runner** will not: it goes round what you built
## and runs at the house, which is what makes a maze useless against it and a
## tower line the only answer (task 0050).
##
## So there is a second field swept from the same entry costs with every
## barrier taken out of the map - the pre-0049 field, in other words. It is
## one more sweep per grid change and no cost at all per tick, and the
## alternative was to let a runner pick its second-favourite neighbour out of
## the shared field, which is a step uphill and the one thing the shape of
## this field guarantees cannot happen.
##
## A runner with **no** way round falls back to the shared field and breaks
## through like everybody else. A runner that stood still in front of a wall
## would make sealing the farm a win condition.
##
## ## Three fields, because not everybody is going to the same place
##
## The third is swept from every **structure** rather than from the house:
## towers, the workshop, the generator - the things a breaker comes for (task
## 0052). It is the same sweep with different seeds, so a breaker walks
## downhill to the nearest thing you built exactly the way everything else
## walks downhill to the house, and it cannot oscillate for the same reason.
##
## It is skipped entirely when there is nothing built, which is most of night
## one, and a breaker with an empty hunt field falls through to the house.
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
		# The same two again for somebody who will not break anything: every
		# barrier is a hole in the map rather than a door with a price.
		"flow_open": PackedInt32Array(),
		"open_cost": PackedInt32Array(),
		# And again for somebody who has come for the towers rather than for
		# the house. Empty when there is nothing built to come for.
		"flow_hunt": PackedInt32Array(),
		"hunt_cost": PackedInt32Array(),
		# Which `grid_version` the four above were built for. -1 is "never".
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
	state["flow_open"] = built["open_field"]
	state["open_cost"] = built["open_cost"]
	state["flow_hunt"] = built["hunt_field"]
	state["hunt_cost"] = built["hunt_cost"]
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
	return _step_in(state["flow"], state["flow_cost"], cell)


## The next cell on the way to the house **for somebody who will not break
## anything**: the same question against the field with the barriers taken
## out. The same cell back means there is no way round, and the caller falls
## back to `step_from()`.
static func step_around(state: Dictionary, cell: Vector2i) -> Vector2i:
	return _step_in(state["flow_open"], state["open_cost"], cell)


## The next cell on the way to **the nearest thing the player built**. The
## same cell back means there is nothing left standing to go for, and the
## caller falls back to `step_from()`.
static func step_hunt(state: Dictionary, cell: Vector2i) -> Vector2i:
	return _step_in(state["flow_hunt"], state["hunt_cost"], cell)


## What reaching the nearest structure costs from here. `UNREACHABLE` when
## there is nothing to reach.
static func distance_hunt(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	if idx < 0:
		return UNREACHABLE
	var field: PackedInt32Array = state["flow_hunt"]
	if field.size() != Grid.CELLS:
		return UNREACHABLE
	return int(field[idx])


## Whether this is a thing a breaker has come for: something the player built
## that is not a barrier, a trap or part of the farm.
##
## **The same predicate `_cost_of()` uses to say "no way through".** A wall is
## a door with a price on it and a tower is not a door at all, so the things
## with no way through them are exactly the things worth coming for. One rule,
## read two ways.
static func is_prey(id: StringName) -> bool:
	if id == &"house" or Farm.FIXTURES.has(id) or Traps.is_trap(id):
		return false
	var entry: Variant = Building.entry_of(id)
	if entry == null:
		return false        # a tree or a seam: part of the farm, not built
	return int((entry as Dictionary).get("path_cost", 0)) <= 0


## Every cell with something on it a breaker has come for.
static func prey_cells(state: Dictionary) -> Array:
	var out: Array = []
	var occupants: Dictionary = state["occupants"]
	var where: Array = occupants.keys()
	where.sort()
	for key in where:
		var idx := int(key)
		if idx < 0 or idx >= Grid.CELLS:
			continue
		var on: Dictionary = occupants[key]
		if not is_prey(StringName(on["id"])):
			continue
		# **Nothing that cannot be hurt is worth coming for.** A prey cell
		# with no hit points is a breaker standing in front of it for the
		# rest of the night, which is how task 0060 found a workshop that
		# had none. Belt as well as braces: the workshop has hit points now,
		# and if anything else ever turns up without them the hunt field
		# will simply not lead anybody to it.
		if int(on.get("hp", 0)) <= 0:
			continue
		out.append(Grid.cell(idx))
	return out


## What getting home costs somebody who will not break anything.
static func distance_around(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	if idx < 0:
		return UNREACHABLE
	var field: PackedInt32Array = state["flow_open"]
	if field.size() != Grid.CELLS:
		return UNREACHABLE
	return int(field[idx])


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
	return routes_if_blocked(state, blocked, [from], most)


## **The same, from several places at once** (task 0157): the build step
## shows a route from every side open tonight. One field is built and every
## start walks it, so five sides cost one sweep; the routes come back one
## after another in a single list of cells, the way the dotted line draws.
static func routes_if_blocked(state: Dictionary, blocked: Vector2i,
		froms: Array, most: int = 200) -> Array:
	var occupants: Dictionary = state["occupants"]
	var idx := Grid.index(blocked)
	if idx < 0:
		return []
	var was: Variant = occupants.get(idx, null)

	# Pretend, ask, put it back. Nothing else may run between these two lines,
	# and nothing does: this is a query, not a tick.
	occupants[idx] = {"id": &"wall", "hp": 1}
	var built := _build(state)
	# The preview is about where a wall sends them, so it reads the field
	# everything walks by - not the one a breaker hunts by.
	if was == null:
		occupants.erase(idx)
	else:
		occupants[idx] = was

	var field: PackedInt32Array = built["field"]
	var cost: PackedInt32Array = built["cost"]
	var out: Array = []
	for start in froms:
		var at: Vector2i = start
		for _step in most:
			var next := _step_in(field, cost, at)
			if next == at:
				break
			out.append(next)
			at = next
	return out


## One step downhill in a given field, and **the hottest line in the night**.
##
## The two arrays are taken once and read four times. Going through
## `distance()` meant four dictionary lookups, four bounds checks and four
## size checks for what is eight array reads.
static func _step_in(field: PackedInt32Array, cost: PackedInt32Array,
		cell: Vector2i) -> Vector2i:
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


## **The cells the horde walked to the house** (task 0155), for trampling:
## from every spawn cell of `regions` (`Waves.spawns_in` of tonight), the flow
## field's steps down to the house; every cell an enemy stands on now; and
## `reach` tiles either side of all of them. Cells, never randomness - two
## farms in the same state get the same answer - and sorted by index.
static func horde_routes(state: Dictionary, regions: Array, reach: int = 0) -> Array:
	refresh(state)
	var walked := {}
	for where in regions:
		for start in Enemies.spawn_cells(state, int(where)):
			var cell: Vector2i = start
			# A field value strictly falls on every step, so this ends; the
			# bound is only a guard against a field that is not built.
			for _step in Grid.CELLS:
				walked[Grid.index(cell)] = true
				var next := step_from(state, cell)
				if next == cell:
					break
				cell = next
	for id in Entities.ids(state):
		var at := Grid.index(Entities.cell_of(state, int(id)))
		if at >= 0:
			walked[at] = true
	var out := {}
	var keys: Array = walked.keys()
	keys.sort()
	for idx in keys:
		var here := Grid.cell(int(idx))
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var near := here + Vector2i(dx, dy)
				if Grid.in_bounds(near):
					out[Grid.index(near)] = true
	var cells: Array = out.keys()
	cells.sort()
	var result: Array = []
	for idx in cells:
		result.append(Grid.cell(int(idx)))
	return result


## Whether anything can get from this cell to the house at all.
static func reachable(state: Dictionary, cell: Vector2i) -> bool:
	return distance(state, cell) != UNREACHABLE


# ------------------------------------------------------------------ building

## Both fields and both sets of entry costs, built together because they come
## off the same one pass over the farm.
static func _build(state: Dictionary) -> Dictionary:
	var costs := _entry_costs(state)
	var home := Farm.cells_with(state, &"house")

	# **Skipped when there is nothing to hunt.** Most of night one has nothing
	# built on the farm at all, and a sweep of seven hundred cells to find out
	# that the answer is "nowhere" is a sweep worth not doing.
	var prey := prey_cells(state)
	var hunt_cost: PackedInt32Array = costs["cost"]
	var hunt_field := PackedInt32Array()
	if not prey.is_empty():
		# A tower is impassable in the field everything else reads, which is
		# what makes a wave flow around it. The sweep has to be able to leave
		# one, so here they cost what the ground under them costs.
		hunt_cost = costs["cost"].duplicate()
		for cell in prey:
			hunt_cost[Grid.index(cell)] = Farm.cost_of_terrain(
				Farm.terrain_at(state, cell))
		hunt_field = _sweep(state, hunt_cost, prey)

	return {
		"cost": costs["cost"],
		"field": _sweep(state, costs["cost"], home),
		"open_cost": costs["open"],
		"open_field": _sweep(state, costs["open"], home),
		"hunt_cost": hunt_cost,
		"hunt_field": hunt_field,
	}


## One field, swept out from a set of seed cells against one set of entry
## costs. The seeds are wherever whoever reads this field is trying to get to.
static func _sweep(state: Dictionary, cost: PackedInt32Array,
		seeds: Array) -> PackedInt32Array:
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
	for cell in seeds:
		var idx := Grid.index(cell)
		if idx < 0 or int(field[idx]) == 0:
			continue
		field[idx] = 0
		(wheel[0] as Array).append(idx)
		queued += 1

	# Nothing is ever filed further ahead than `WIDEST_STEP`, so the bucket
	# being emptied is never one being filled: the wheel can be a ring.
	#
	# **Flat indices, no vectors.** Since the farm became Stardew-sized - 5,200
	# cells, not 1,125 - this loop is most of a path rebuild, so it walks the
	# neighbours as index arithmetic in `Grid.STEPS` order (north, east, south,
	# west) instead of building a `Vector2i` per step. Same visits, same order,
	# same field.
	var width := Grid.WIDTH
	var last_row := Grid.CELLS - width
	var d := 0
	while queued > 0:
		var slot := d % wheel_size
		var bucket: Array = wheel[slot]
		if not bucket.is_empty():
			wheel[slot] = []
			for entry in bucket:
				var idx: int = entry
				queued -= 1
				# A cheaper way here turned up after this one was filed.
				if field[idx] != d:
					continue
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
				var through: int = d + cost[idx]
				# Never this bucket: every step costs at least one and at most
				# `WIDEST_STEP`, less than the wheel.
				var into: Array = wheel[through % wheel_size]
				var x := idx % width
				# Nothing can stand on an impassable neighbour, so nothing
				# walks in from it.
				if idx >= width:
					var n_idx := idx - width
					if cost[n_idx] != IMPASSABLE and through < field[n_idx]:
						field[n_idx] = through
						into.append(n_idx)
						queued += 1
				if x < width - 1:
					var n_idx := idx + 1
					if cost[n_idx] != IMPASSABLE and through < field[n_idx]:
						field[n_idx] = through
						into.append(n_idx)
						queued += 1
				if idx < last_row:
					var n_idx := idx + width
					if cost[n_idx] != IMPASSABLE and through < field[n_idx]:
						field[n_idx] = through
						into.append(n_idx)
						queued += 1
				if x > 0:
					var n_idx := idx - 1
					if cost[n_idx] != IMPASSABLE and through < field[n_idx]:
						field[n_idx] = through
						into.append(n_idx)
						queued += 1
		d += 1
	return field


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
static func _entry_costs(state: Dictionary) -> Dictionary:
	var cost := PackedInt32Array()
	cost.resize(Grid.CELLS)
	var terrain: PackedByteArray = state["terrain"]
	# One lookup per terrain byte, then one array read per cell.
	var by_terrain := PackedInt32Array()
	by_terrain.resize(256)
	for kind in 256:
		by_terrain[kind] = Farm.cost_of_terrain(kind)
	for idx in Grid.CELLS:
		cost[idx] = by_terrain[terrain[idx]]
	# The two are the same everywhere nobody has built anything, which is most
	# of the farm.
	var open := cost.duplicate()

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
		var ground := int(cost[idx])
		var priced := _through(StringName((occupants[key] as Dictionary)["id"]),
			ground)
		cost[idx] = priced
		# A barrier - something that cost more to enter than the ground under
		# it - is a door in one field and a wall in the other.
		open[idx] = IMPASSABLE if priced != ground else priced
	return {"cost": cost, "open": open}


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
