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
## The well joined these at task 0029: it is where the water comes from, and a
## player who sold their own well would have sold the farm's only water north
## of the pond.
const FIXTURES := [&"house", &"shop", &"well", &"shipping_bin"]


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
				# **With the hit points its table declares.** A map-placed
				# occupant used to get none, so anything on the farm at dawn
				# on day one could not be damaged at all - and a breaker
				# standing next to it chewed for ever. Trees and seams have
				# no table entry and stay as they were: `Gathering` owns
				# them and nothing is meant to bite one.
				occupants[idx] = {"id": occupant_id}
				var entry_for: Variant = Building.entry_of(occupant_id)
				if entry_for != null:
					occupants[idx]["hp"] = int((entry_for as Dictionary)
						.get("hp", 1))

	# Map-authored cells share the same owner as player-placed structures.
	# **One anchor per piece, not per id** (task 0156): a farm has one house
	# but four hardwood stumps, and a corner worked out per id put all four
	# under the first one's.
	_anchor_pieces(occupants)
	return {
		"terrain": terrain,
		"occupants": occupants,
		# What was destroyed and where, until the morning sweeps it up. Keyed
		# by cell index, value is what used to stand there.
		"rubble": {},
		# **What stood where a defence was brought down** (task 0277), by
		# cell: `{"id", "level"}`, kept past the morning until it is mended
		# back up or built over. The rubble beside it is still only the
		# night's.
		"ruins": {},
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


## Give every cell of a map-authored thing bigger than one cell the anchor
## of its piece: the top-left of the cells of that id joined to it.
static func _anchor_pieces(occupants: Dictionary) -> void:
	var keys: Array = occupants.keys()
	keys.sort()
	var done := {}
	for idx in keys:
		var id: StringName = occupants[idx]["id"]
		if done.has(idx) or Building.size_of(id) == Vector2i.ONE:
			continue
		var piece: Array = [int(idx)]
		var corner := Grid.cell(int(idx))
		done[idx] = true
		var at := 0
		while at < piece.size():
			var here := Grid.cell(int(piece[at]))
			at += 1
			corner = Vector2i(mini(corner.x, here.x), mini(corner.y, here.y))
			for step in Grid.STEPS:
				var next: Vector2i = here + step
				var n := Grid.index(next)
				if n < 0 or done.has(n) or not occupants.has(n) \
						or StringName(occupants[n]["id"]) != id:
					continue
				done[n] = true
				piece.append(n)
		for part in piece:
			occupants[part]["anchor"] = [corner.x, corner.y]


## **Which pond a cell is in** (task 0156), by name from `GameData.PONDS`:
## a flood fill over the state's own water from the cell, until it meets a
## pond's anchor. Empty on land, and on water that is no named pond. Cheap
## enough to ask once per cast - the biggest body is a few hundred cells -
## and it reads the save's terrain, so a save's pond is still its pond.
static func pond_of(state: Dictionary, cell: Vector2i) -> StringName:
	if not Grid.in_bounds(cell) or terrain_at(state, cell) != Terrain.WATER:
		return &""
	var anchors := {}
	for id in GameData.sorted_names(GameData.PONDS.keys()):
		var pair: Array = GameData.PONDS[id]
		anchors[Grid.index(Vector2i(int(pair[0]), int(pair[1])))] = id
	var seen := {Grid.index(cell): true}
	var frontier: Array = [cell]
	while not frontier.is_empty():
		var here: Vector2i = frontier.pop_back()
		var idx := Grid.index(here)
		if anchors.has(idx):
			return anchors[idx]
		for step in Grid.STEPS:
			var next: Vector2i = here + step
			var n := Grid.index(next)
			if n < 0 or seen.has(n) or terrain_at(state, next) != Terrain.WATER:
				continue
			seen[n] = true
			frontier.append(next)
	return &""


## The middle of the farmhouse, from the occupant table it was built from.
static func _centre_of(occupants: Dictionary) -> Array:
	var sum := Vector2i.ZERO
	var n := 0
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		if (occupants[idx] as Dictionary).get("id", &"") == &"house":
			sum += Grid.cell(int(idx))
			n += 1
	if n == 0:
		return [Grid.WIDTH / 2, Grid.HEIGHT / 2]
	return [sum.x / n, sum.y / n]


static func terrain_at(state: Dictionary, cell: Vector2i) -> int:
	var idx := Grid.index(cell)
	return -1 if idx < 0 else int((state["terrain"] as PackedByteArray)[idx])


## The cells the farmhouse stands on, as one rectangle.
##
## **Grown out from `house_cell`, not scanned for.** Every `buildable()` asks
## for the porch, which asks for this, and the Stardew-sized farm starts with
## six hundred trees and stones on it - a scan of all of them per question was
## most of what placing anything cost. The house is one connected footprint
## around its own centre, so a flood from there finds every part of it. A
## state whose centre is not on the house (one being assembled by hand) gets
## the scan.
static func house_bounds(state: Dictionary) -> Rect2i:
	var occupants: Dictionary = state.get("occupants", {})
	var at: Array = state.get("house_cell", [])
	var start := Grid.index(Vector2i(int(at[0]), int(at[1]))) if at.size() == 2 else -1
	if start < 0 or (occupants.get(start, {}) as Dictionary).get("id", &"") != &"house":
		return _scanned_house_bounds(occupants)
	var seen := {start: true}
	var pending: Array = [Grid.cell(start)]
	var bounds := Rect2i(Grid.cell(start), Vector2i.ONE)
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for step in Grid.STEPS:
			var next: Vector2i = cell + step
			var idx := Grid.index(next)
			if idx < 0 or seen.has(idx):
				continue
			seen[idx] = true
			if (occupants.get(idx, {}) as Dictionary).get("id", &"") == &"house":
				bounds = bounds.merge(Rect2i(next, Vector2i.ONE))
				pending.append(next)
	return bounds


static func _scanned_house_bounds(occupants: Dictionary) -> Rect2i:
	var bounds := Rect2i()
	for idx in occupants:
		if occupants[idx].get("id", &"") == &"house":
			var cell := Grid.cell(int(idx))
			bounds = Rect2i(cell, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.merge(Rect2i(cell, Vector2i.ONE))
	return bounds


## What crossing a tile of this terrain costs somebody walking in. Zero when
## nothing crosses it.
##
## The numbers are `GameData.TERRAIN_COST` and the order is `Terrain`: the
## lever belongs in the table with the other levers and the enum belongs here,
## so this is the one line that knows both.
static func cost_of_terrain(terrain: int) -> int:
	if terrain < 0 or terrain >= GameData.TERRAIN_COST.size():
		return 0
	return int(GameData.TERRAIN_COST[terrain])


## Everything the rest of the game keyed to a cell, undone.
##
## **One place, called from `remove()`**, so that a system which keeps
## something per cell has one door to close rather than every caller of
## `remove()` having to know about it. "Nothing dangles after a structure
## dies" is a promise this function keeps.
static func forget_cell(state: Dictionary, cell: Vector2i) -> void:
	Crafting.forget_cell(state, cell)
	# A home's animals wait for the next one rather than going with it
	# (task 0183).
	Livestock.forget_cell(state, cell)


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
	if cell == House.porch(state):
		return false
	return is_empty(state, cell)


## Why not, for the ghost that turns red under the cursor. An empty Array
## when it is buildable. A key and its arguments - see `Building.why_not`.
static func why_not_buildable(state: Dictionary, cell: Vector2i) -> Array:
	var t := terrain_at(state, cell)
	if t < 0:
		return [&"WHY_OFF_THE_FARM"]
	if cell == House.porch(state):
		return [&"WHY_ON_THE_HOUSE"]
	if t == Terrain.WATER:
		return [&"WHY_IN_THE_WATER"]
	if t == Terrain.ROCK:
		return [&"WHY_ON_THE_ROCK"]
	var on := occupant(state, cell)
	if not on.is_empty():
		if on["id"] == &"house":
			return [&"WHY_ON_THE_HOUSE"]
		return [&"WHY_OCCUPIED", StringName(on["id"])]
	return []


## Whether a person or a zombie can stand here.
##
## Fixtures block; so does anything the player built, which is the whole point
## of a wall. **This stayed a yes or a no** when task 0049 made the flow field
## a cost field: the farmer does not break through their own wall, and a price
## on a cell is a price for somebody who can pay it by biting. The cost lives
## in `Pathing`, which is the one place it means anything.
static func walkable(state: Dictionary, cell: Vector2i) -> bool:
	var t := terrain_at(state, cell)
	if t < 0 or UNWALKABLE.has(t):
		return false
	return is_empty(state, cell)


## Put something on a cell. False and no change when it will not go there.
static func place(state: Dictionary, cell: Vector2i, occupant_data: Dictionary) -> bool:
	if not buildable(state, cell):
		return false
	# **Built over, a ruin is gone** (task 0277), whether it was mended back
	# up or something else went there.
	_ruins(state).erase(Grid.index(cell))
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


## Take hit points off whatever is standing here. Returns what was taken,
## which is never more than it had - so a caller counting damage cannot count
## overkill, the same promise `Combat.hit()` makes about a zombie.
##
## **Destroying it removes it**, which bumps `grid_version` and so rebuilds the
## flow field on the next tick. A hole in a wall is a new way through, and the
## zombies find it because the field is asked, not remembered.
static func damage(state: Dictionary, cell: Vector2i, amount: int) -> int:
	if amount <= 0:
		return 0
	var on := occupant(state, cell)
	if on.is_empty() or FIXTURES.has(StringName(on["id"])):
		return 0
	var left := int(on.get("hp", 0))
	if left <= 0:
		return 0
	var taken := mini(amount, left)
	# **Wrecked, never lost** (task 0186): a coop or a barn takes the bite on
	# its one count of hit points, and at 0 it stands - out of use, no
	# rubble, its animals inside - until it is mended.
	if Building.wrecks(StringName(on["id"])):
		Building.set_shared_hp(state, cell, left - taken)
		if left - taken <= 0:
			_wreck(state, cell, StringName(on["id"]))
		return taken
	on["hp"] = left - taken
	if int(on["hp"]) <= 0:
		var id := StringName(on["id"])
		var level := maxi(int(on.get("level", 1)), 1)
		remove(state, cell)
		_leave_rubble(state, cell, id)
		# **And a defence's ruin** (task 0277), at the level it stood at, to
		# be mended back up.
		if Building.ruins(id):
			_ruins(state)[Grid.index(cell)] = {"id": id, "level": level}
		Events.add(state, &"structure_lost", {
			"id": id, "cell": [cell.x, cell.y], "ruin": Building.ruins(id),
		})
	return taken


## **A building wrecked** (task 0186). It stays an occupant and a wall, but
## nothing comes for it any more: `Pathing.prey_cells` skips 0 HP, and the
## hunt field is cached on `grid_version`, so the farm is touched - without
## it the breakers would stand at a dead barn all night. It counts as a
## structure lost to the run's tally, and the log says wrecked.
static func _wreck(state: Dictionary, cell: Vector2i, id: StringName) -> void:
	touch(state)
	Run.lost_a_structure(state)
	var anchor := Building.anchor_of(state, cell)
	Events.add(state, &"structure_lost", {
		"id": id, "cell": [anchor.x, anchor.y], "wrecked": true,
	})


## What is lying on a cell after something on it was destroyed, or `&""`.
##
## **Not an occupant.** Rubble that occupied its cell would be a wall the
## zombies could not walk through and the player could not build on, which is
## a broken wall doing the job of a whole one. It is a mark on the ground the
## view draws and the morning sweeps up, and nothing else in the game reads
## it.
static func rubble_at(state: Dictionary, cell: Vector2i) -> StringName:
	var idx := Grid.index(cell)
	if idx < 0:
		return &""
	return StringName((state["rubble"] as Dictionary).get(idx, &""))


static func rubble_cells(state: Dictionary) -> Array:
	var out: Array = []
	var rubble: Dictionary = state["rubble"]
	var keys: Array = rubble.keys()
	keys.sort()
	for idx in keys:
		out.append(Grid.cell(int(idx)))
	return out


## Sweep the yard. Called when a day begins: the night's wreckage is part of
## the night, and a farm that never cleared would silt up over ten of them.
## The ruins are not swept (task 0277): they wait to be mended.
static func clear_rubble(state: Dictionary) -> void:
	state["rubble"] = {}


## **The ruin on this cell** (task 0277): `{"id", "level"}` of the defence
## brought down here, with nothing standing on it now; or empty.
static func ruin_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var idx := Grid.index(cell)
	if idx < 0 or not occupant(state, cell).is_empty():
		return {}
	var ruin: Dictionary = _ruins(state).get(idx, {})
	return ruin.duplicate()


## Every cell with a ruin on it, in cell order.
static func ruin_cells(state: Dictionary) -> Array:
	var out: Array = []
	var keys: Array = _ruins(state).keys()
	keys.sort()
	for idx in keys:
		var cell := Grid.cell(int(idx))
		if occupant(state, cell).is_empty():
			out.append(cell)
	return out


## The ruins, made for a save that predates them.
static func _ruins(state: Dictionary) -> Dictionary:
	if not state.has("ruins"):
		state["ruins"] = {}
	return state["ruins"]


static func _leave_rubble(state: Dictionary, cell: Vector2i,
		id: StringName) -> void:
	var idx := Grid.index(cell)
	if idx >= 0:
		(state["rubble"] as Dictionary)[idx] = id
	# **Counted here because the morning sweeps the rubble.** By the end of a
	# run there would be nothing left to count, and "structures lost" is one
	# of the five numbers the run summary is made of.
	if GameData.DEFENCES.has(id) or GameData.BUILDINGS.has(id):
		Run.lost_a_structure(state)


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
	# **Whatever else was keyed to this cell goes with it.** A workshop that
	# falls with a queue running used to leave the queue in the state for ever
	# - the inputs spent, nothing ever delivered, and a new workshop on the
	# same cell inheriting a job it never started.
	forget_cell(state, cell)
	# **Rubble, if it was broken rather than sold.** Set by `damage()`, which
	# is the only caller that means "this was destroyed"; selling a tower
	# leaves a tidy cell.
	occupants.erase(idx)
	_changed(state)
	return true


## Something went up or came down. Anything that caches a fact about the shape
## of the farm watches this number.
## Tell everything that caches against the farm that it has changed.
##
## **For a change that is not a placement or a removal**: an upgraded tower is
## the same occupant on the same cell with a different range, and the
## targeting list and the flow field both hold opinions that are now stale.
static func touch(state: Dictionary) -> void:
	_changed(state)


static func _changed(state: Dictionary) -> void:
	state["grid_version"] = int(state["grid_version"]) + 1


## Every cell holding a given occupant id, in index order.
##
## Sorted by construction: the caller gets the same list in the same order on
## every machine, which matters the moment something iterates trees and draws
## from the RNG.
static func cells_with(state: Dictionary, id: StringName) -> Array:
	# Matched first and sorted after: the farm holds hundreds of trees and
	# stones, and only the few cells asked for need putting in order.
	var found: Array = []
	var occupants: Dictionary = state["occupants"]
	for idx in occupants:
		if (occupants[idx] as Dictionary)["id"] == id:
			found.append(idx)
	found.sort()
	var out: Array = []
	for idx in found:
		out.append(Grid.cell(idx))
	return out


## Every cell of a given terrain, in index order. For farming ground use
## `Farming.field_cells`: turned grass is a plot overlay, not SOIL terrain.
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
