class_name Enemies
extends RefCounted

## Zombies, walking in.
##
## They spawn at the edges, follow the flow field to the farmhouse, and take a
## bite out of it when they arrive. That is the whole of it tonight; task 0049
## teaches them to break a wall rather than stand in front of it, and 0050 to
## 0052 give them reasons to be told apart.
##
## ## Movement is integer, and exactly the speed the lever says
##
## An enemy's speed is **ticks to cross one tile**, so it stays an integer and
## two machines cannot disagree about where a zombie is. A naive
## `SUBTILE / ticks_per_tile` would truncate - 64 over 20 is 3, which is 21.3
## ticks a tile rather than 20 - so each one carries the remainder instead. Over
## any number of ticks it has moved exactly the distance the lever promised.
##
## ## Spawning is seeded
##
## Which edge cell a zombie appears on comes out of the run's RNG, so a seed
## replays a night exactly. `Rng` is the only randomness core may touch and
## this is the first thing in the game to use it.


static func initial() -> Dictionary:
	return {
		# How many have reached the house, for the result screen of task 0027.
		"breaches": 0,
	}


## Put one on the farm at a spawn point, chosen from the run's RNG.
##
## `where` is an index into `GameData.SPAWNS`, which is what a wave table names.
static func spawn(state: Dictionary, kind: StringName, where: int) -> int:
	var options := spawn_cells(state, where)
	if options.is_empty():
		return 0
	var cell: Vector2i = options[Rng.int_between(
		state["rng"], 0, options.size() - 1)]
	return Entities.spawn(state, kind, cell)


## The cells a given spawn point can use: the ones in its region that something
## can actually stand on and get to the house from.
static func spawn_cells(state: Dictionary, where: int) -> Array:
	# **The field first.** This asks whether a cell can reach the house, and
	# the field is only rebuilt when something needs it - so the first spawn of
	# a night was asking a field that had never been built, being told nowhere
	# was reachable, and every zombie of wave one vanished silently.
	#
	# The refresh belongs here rather than in `spawn()`, because this is where
	# the question is asked and anything else that asks it wants the same
	# answer.
	Pathing.refresh(state)
	var regions: Array = GameData.SPAWNS
	if where < 0 or where >= regions.size():
		return []
	var out: Array = []
	for entry in (regions[where] as Array):
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		if Farm.walkable(state, cell) and Pathing.reachable(state, cell):
			out.append(cell)
	return out


# ------------------------------------------------------------------ the tick

## One tick of everything walking in. Called from `Sim._tick_night()`.
static func tick(state: Dictionary) -> void:
	Pathing.refresh(state)
	if Entities.count(state) == 0:
		return

	# Sorted by id, so two zombies arriving on the same tick always land in the
	# same order - which decides which of them the last hit point goes to.
	for id in Entities.ids(state):
		_walk(state, id)


static func _walk(state: Dictionary, id: int) -> void:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return
	var data: Dictionary = GameData.ENEMIES[one["kind"]]

	# **Standing on it counts.** The flow field says distance zero at the house
	# and "stay where you are" everywhere distance cannot improve, so a zombie
	# that ended up on the house would have stood on the porch for ever. Found
	# by a test that spawned one there.
	var on := Vector2i(int(one["pos"][0]) / Player.SUBTILE,
		int(one["pos"][1]) / Player.SUBTILE)
	if Farm.occupant(state, on).get("id", &"") == &"house":
		_bite(state, id, data)
		return

	var per_tile := maxi(int(data["ticks_per_tile"]), 1)

	# The remainder is carried, so the speed is exactly what the lever says
	# rather than whatever integer division left behind.
	var progress := int(one["step"]) + Player.SUBTILE
	var move := progress / per_tile
	one["step"] = progress - move * per_tile
	if move <= 0:
		return

	# **The flow is read once a tick, not once per sub-unit.** A zombie moves
	# three of sixty-four units in a tick and every one of them is inside the
	# same cell, so asking the field three times is asking it twice for
	# nothing - and with fifty of them that was most of the tick.
	var at := Vector2i(int(one["pos"][0]), int(one["pos"][1]))
	var here := Vector2i(at.x / Player.SUBTILE, at.y / Player.SUBTILE)
	var next := Pathing.step_from(state, here)
	if next == here:
		# **Nowhere to go means chew.** A wall that sealed the farm used to
		# make the whole wave stand still for ever - a player who walled
		# themselves in won the night by doing nothing, which is not a tower
		# defence, it is a puzzle with one answer.
		#
		# `design.md` is explicit that a wall buys time rather than safety, so
		# a zombie with no path takes the nearest thing in its way apart.
		_chew(state, id, data, here)
		return

	var aim := Vector2i(next.x * Player.SUBTILE + Player.SUBTILE / 2,
		next.y * Player.SUBTILE + Player.SUBTILE / 2)
	for _i in move:
		var delta := aim - at
		if delta == Vector2i.ZERO:
			break
		# One unit at a time along the dominant axis, which on a four-way field
		# is always a straight line anyway.
		if absi(delta.x) >= absi(delta.y):
			at.x += signi(delta.x)
		else:
			at.y += signi(delta.y)

	one["pos"][0] = at.x
	one["pos"][1] = at.y

	# Only the cell it ended the tick in can be the house: nothing in the table
	# crosses a whole cell in a single tick.
	var landed := Vector2i(at.x / Player.SUBTILE, at.y / Player.SUBTILE)
	if landed != here and Farm.occupant(state, landed).get("id", &"") == &"house":
		_bite(state, id, data)


## Reaching the house costs the house and costs the zombie: it is spent.
## No way through, so take the way through apart.
##
## Looks at the four neighbours and bites whichever structure is nearest the
## house - the one actually in the way, rather than whatever happens to be
## first in reading order. With nothing adjacent at all it simply waits, which
## only happens when a zombie is walled into a pocket it never walked into.
static func _chew(state: Dictionary, id: int, data: Dictionary,
		here: Vector2i) -> void:
	var best := Vector2i(-1, -1)
	var best_distance := 1 << 30
	for step in NEIGHBOURS:
		var at: Vector2i = here + step
		if not Grid.in_bounds(at):
			continue
		var on := Farm.occupant(state, at)
		if on.is_empty() or Farm.FIXTURES.has(StringName(on["id"])):
			continue
		if int(on.get("hp", 0)) <= 0:
			continue
		# Nearest the house wins, so a wave eats through the line rather than
		# nibbling the far side of it.
		var apart := Grid.manhattan(at, Farm.house_centre(state))
		if apart < best_distance:
			best_distance = apart
			best = at
	if best.x < 0:
		return

	# **One bite per tile's worth of time.** `_walk()` gates this on `move`,
	# which is *sub-units* rather than tiles - a walker covers three of
	# sixty-four in a tick - so biting on every one of those was twenty
	# damage in two ticks and a barricade that bought nothing at all.
	#
	# A bite costs what crossing a tile costs, so a fast zombie chews fast and
	# `ticks_per_tile` means one thing in both places.
	var one := Entities.get_one(state, id)
	var wait := int(one.get("chew_wait", 0))
	if wait > 0:
		one["chew_wait"] = wait - 1
		return
	one["chew_wait"] = maxi(int(data["ticks_per_tile"]), 1)
	Farm.damage(state, best, int(data["damage"]))
	one["chewing"] = Grid.index(best)


## The four cells around a cell, in a fixed order.
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0),
]


static func _bite(state: Dictionary, id: int, data: Dictionary) -> void:
	state["house_hp"] = maxi(int(state["house_hp"]) - int(data["damage"]), 0)
	state["breaches"] = int(state["breaches"]) + 1
	Entities.remove(state, id)

	if int(state["house_hp"]) <= 0:
		# The night is lost the moment the house falls.
		Rewards.settle(state, false)
		Phases.enter_result(state, false)


## What is left of the farmhouse, as a fraction, for the night HUD.
static func house_fraction(state: Dictionary) -> float:
	return float(state["house_hp"]) / float(maxi(GameData.HOUSE_HP, 1))
