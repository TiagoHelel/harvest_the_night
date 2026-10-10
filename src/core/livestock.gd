class_name Livestock
extends RefCounted

## The cow and the chickens, and the meat that comes off them.
##
## `design.md`'s resource table has meat on it and nothing in the game made
## any. The reference sheet has the answer standing on the grass: a cow and a
## couple of chickens, loose, not penned.
##
## ## A trickle, not a husbandry system
##
## The task is explicit about this and it is worth being explicit back:
## **passive means there is nothing to manage.** No feeding, no water, no
## breeding, no happiness. An animal stands there and
## slowly has something worth taking. That is the whole system, and it is the
## whole system on purpose - a farm sim's animal loop is a game in its own
## right and this is a tower defence with a farm attached.
##
## What the player does have to do is **walk over**, which is the same bargain
## as everything else on this farm: the thing accumulates while you are
## somewhere else, and comes to nothing if you never come back. An animal holds
## only so much (`holds`), so a cow nobody visits stops producing rather than
## banking a fortnight of beef.
##
## ## Homes
##
## Task 0183 (plan section 3.4) gives them homes: the coop and the barn,
## `BUILDINGS` entries with a `capacity`. Until one is built the map's cow and
## chickens stand where `FARM_MAP` put them and work as they always did. The
## first home built takes the loose animals of its kind in (`move_in`): off
## the map as occupants, onto the home's list in `housed` with their produce,
## and collected at its door - the middle of its front row. A home that is
## lost leaves its animals waiting in `unhoused`, alive, for the next home of
## their kind: no animal ever dies.
##
## ## Fed, or nothing
##
## Task 0184: a hen gives eggs and a cow milk, and a housed one eats. Each
## morning (`feed`, from `Phases.begin_day`) every housed animal eats its
## `feed_per_day` of `ANIMAL_FEED` while there is enough; one that goes
## without gives nothing that day and is still there, no worse, the next. An
## animal is fed the day it moves in - day 1 included, before any morning -
## and the map's loose animals graze: they are never fed and never hungry.
##
## ## The pig's truffles
##
## Task 0185. A pig gives nothing at the door. Each morning, after the hay, a
## fed pig marks its `digs` spots on open grass within `DIG_REACH` of its
## barn, beside it or in front - no plot, no path, nothing standing there or
## just south of it, and never behind it, under its roof's drawing - drawn
## from the run's
## RNG; the farmer digs them up (`dig`, the verb `Interact` offers there,
## ahead of the hoe) for `DIG_GIVES`. What is not dug goes with the sun
## (`clear_spots`, from `Phases.begin_preparation`).


static func initial() -> Dictionary:
	return {
		# {animal cell index: {"ready": units waiting, "left": ticks to the
		# next one}}
		"livestock": {},
		# **The cache below, declared rather than invented.** `_animals()`
		# used to create these two the first time it ran, which made them
		# keys a played state had and a new one did not - and task 0104's
		# reconcile, which mends an old save by comparing it against a new
		# game, dropped them both as keys this build no longer has. A state
		# whose shape is not knowable from `State.create()` breaks the
		# premise the save, the hash and the diff all rest on.
		#
		# `-1` is the sentinel `_animals()` already used, so this changes no
		# behaviour: the first call still finds a mismatch and rebuilds.
		"livestock_version": -1,
		"livestock_cells": [],
		# **Who lives where** (task 0183): a home's anchor cell index ->
		# `{"home": coop or barn, "animals": [{"id", "ready", "left",
		# "fed"}]}`, `fed` since task 0184. Its keys come from play
		# (`State.RUN_DATA`).
		"housed": {},
		# Animals whose home was lost, `{"id", "ready", "left"}` each, waiting
		# - producing nothing - for the next home of their kind.
		"unhoused": [],
		# **Where the pigs have dug** (task 0185): cell index -> what digging
		# there gives (`DIG_GIVES`). Keys from play (`State.RUN_DATA`); gone
		# at night.
		"dig_spots": {},
	}


# ------------------------------------------------------------------- asking

static func is_animal(id: StringName) -> bool:
	return GameData.LIVESTOCK.has(id)


## Whether this is a building animals live in (task 0183): a `BUILDINGS`
## entry with room - the coop and the barn.
static func is_home(id: StringName) -> bool:
	return capacity(id) > 0


## How many animals a home holds; 0 for anything else.
static func capacity(id: StringName) -> int:
	return int((GameData.BUILDINGS.get(id, {}) as Dictionary).get("capacity", 0))


## The home an animal kind lives in (`LIVESTOCK` `home`).
static func home_of(kind: StringName) -> StringName:
	return StringName((GameData.LIVESTOCK.get(kind, {}) as Dictionary).get("home", &""))


## **A home's door** (task 0183): the middle cell of its front row, where
## its animals are collected - the cell a farmer standing below it faces.
static func door_of(state: Dictionary, cell: Vector2i) -> Vector2i:
	var anchor := Building.anchor_of(state, cell)
	var size := Building.size_of(StringName(Farm.occupant(state, cell).get("id", &"")))
	return anchor + Vector2i(size.x / 2, size.y - 1)


## Who lives in the home on this cell, in the order they moved in:
## `{"id", "ready", "left"}` each. Empty for anything that is not one.
static func residents(state: Dictionary, cell: Vector2i) -> Array:
	var home: Dictionary = (state["housed"] as Dictionary).get(Grid.index(Building.anchor_of(state, cell)), {})
	return home.get("animals", [])


## How much is waiting to be collected from the animal on this cell - or,
## at a home, from everyone who lives there.
static func ready_at(state: Dictionary, cell: Vector2i) -> int:
	if is_home(StringName(Farm.occupant(state, cell).get("id", &""))):
		var waiting := 0
		for animal in residents(state, cell):
			waiting += int((animal as Dictionary)["ready"])
		return waiting
	var pen: Dictionary = state["livestock"]
	var at: Variant = pen.get(Grid.index(cell), null)
	return 0 if at == null else int((at as Dictionary)["ready"])


## What this cell offers. `Interact` asks here, the way soil asks `Farming`:
## a loose animal with something on it, or a home's door with something in.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return &""
	if is_home(on["id"]):
		return &"collect" if cell == door_of(state, cell) and ready_at(state, cell) > 0 else &""
	if not is_animal(on["id"]):
		return &""
	return &"collect" if ready_at(state, cell) > 0 else &""


## How full an animal is, from 0 to its `holds`. For the sprite of task 0080
## and for the tooltip.
static func fullness(state: Dictionary, cell: Vector2i) -> int:
	return ready_at(state, cell)


# -------------------------------------------------------------------- doing

## Take what is waiting. Returns what came off it, empty when nothing was.
## At a home's door (task 0183) it is everyone inside, each by its own kind.
static func collect(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if not on.is_empty() and is_home(on["id"]):
		return _collect_home(state, cell)
	if on.is_empty() or not is_animal(on["id"]):
		return {}
	var waiting := ready_at(state, cell)
	if waiting <= 0:
		return {}

	var entry: Dictionary = GameData.LIVESTOCK[on["id"]]
	var given := {}
	for res in GameData.sorted_names((entry["produces"] as Dictionary).keys()):
		given[res] = int((entry["produces"] as Dictionary)[res]) * waiting
	Resources.gain(state, given)
	((state["livestock"] as Dictionary)[Grid.index(cell)]
		as Dictionary)["ready"] = 0
	return given


static func _collect_home(state: Dictionary, cell: Vector2i) -> Dictionary:
	if cell != door_of(state, cell):
		return {}
	var given := {}
	for animal in residents(state, cell):
		var one: Dictionary = animal
		var waiting := int(one["ready"])
		if waiting <= 0:
			continue
		var makes: Dictionary = (GameData.LIVESTOCK[one["id"]] as Dictionary)["produces"]
		for res in GameData.sorted_names(makes.keys()):
			given[res] = int(given.get(res, 0)) + int(makes[res]) * waiting
		one["ready"] = 0
	Resources.gain(state, given)
	return given


## **Move one in** (task 0183): an animal of `kind` into the home on this
## cell, with what it had waiting and its timer. False, and nothing changes,
## when the home is not its kind's or is full. The map's loose animals and the
## stall (0190) both come in through here.
static func house(state: Dictionary, cell: Vector2i, kind: StringName,
		ready: int = 0, left: int = 0) -> bool:
	var id := StringName(Farm.occupant(state, cell).get("id", &""))
	if not is_home(id) or not is_animal(kind) or home_of(kind) != id:
		return false
	var homes: Dictionary = state["housed"]
	var idx := Grid.index(Building.anchor_of(state, cell))
	if not homes.has(idx):
		homes[idx] = {"home": id, "animals": []}
	var animals: Array = (homes[idx] as Dictionary)["animals"]
	if animals.size() >= capacity(id):
		return false
	var every := int((GameData.LIVESTOCK[kind] as Dictionary)["every_ticks"])
	# **Fed the day it moves in** (task 0184): a hen off the grass has grazed,
	# and one bought (0190) comes fed. Tomorrow's morning asks for hay.
	animals.append({"id": kind, "ready": maxi(ready, 0), "left": left if left > 0 else every,
		"fed": true})
	return true


## **The morning's hay** (task 0184), from `Phases.begin_day`: every housed
## animal eats its `feed_per_day` of `ANIMAL_FEED` - home by home in cell
## order, each in the order it moved in - while there is enough. One that
## goes without gives nothing today, and is still there tomorrow: no animal
## dies or sickens. How many went without.
static func feed(state: Dictionary) -> int:
	var hungry := 0
	var homes: Dictionary = state["housed"]
	var anchors: Array = homes.keys()
	anchors.sort()
	for idx in anchors:
		for animal in ((homes[idx] as Dictionary)["animals"] as Array):
			var one: Dictionary = animal
			var eats := int((GameData.LIVESTOCK[one["id"]] as Dictionary).get("feed_per_day", 0))
			one["fed"] = eats <= 0 or Resources.spend(state, GameData.ANIMAL_FEED, eats)
			if not bool(one["fed"]):
				hungry += 1
	return hungry


## **The pigs dig** (task 0185), from `Phases.begin_day` after the hay: every
## fed pig, home by home in cell order, marks its `digs` spots on open grass
## within `DIG_REACH` of its barn's walls, each drawn from the run's RNG
## among the cells still free, in index order. How many were marked.
static func mark_spots(state: Dictionary) -> int:
	var marked := 0
	var spots: Dictionary = state["dig_spots"]
	var homes: Dictionary = state["housed"]
	var anchors: Array = homes.keys()
	anchors.sort()
	for idx in anchors:
		var anchor := Grid.cell(int(idx))
		for animal in ((homes[idx] as Dictionary)["animals"] as Array):
			var one: Dictionary = animal
			var digs := int((GameData.LIVESTOCK[one["id"]] as Dictionary).get("digs", 0))
			if digs <= 0 or not bool(one.get("fed", true)):
				continue
			for _i in digs:
				var free := diggable_near(state, anchor)
				if free.is_empty():
					break
				var at: Vector2i = free[Rng.int_between(state["rng"], 0, free.size() - 1)]
				spots[Grid.index(at)] = GameData.DIG_GIVES.duplicate()
				marked += 1
	return marked


## The cells a pig of the home on `anchor` could dig today: open grass within
## `DIG_REACH` of its walls - not a plot, not a path, nothing standing there,
## no spot already - in index order. **Beside it and in front, never behind**:
## a spot north of the barn would be under its roof's drawing, where nobody
## could see it or point at it - and for the same reason never just north of
## anything standing (`_in_sight`), a tree's canopy or a building's wall.
static func diggable_near(state: Dictionary, anchor: Vector2i) -> Array:
	var size := Building.size_of(StringName(Farm.occupant(state, anchor).get("id", &"")))
	var reach := GameData.DIG_REACH
	var out: Array = []
	for y in range(anchor.y, anchor.y + size.y + reach):
		for x in range(anchor.x - reach, anchor.x + size.x + reach):
			var cell := Vector2i(x, y)
			if _diggable(state, cell) and not (state["dig_spots"] as Dictionary).has(Grid.index(cell)):
				out.append(cell)
	return out


static func _diggable(state: Dictionary, cell: Vector2i) -> bool:
	return Grid.in_bounds(cell) and Farm.terrain_at(state, cell) == Farm.Terrain.GRASS \
		and Farm.is_empty(state, cell) and not Farming.is_tilled(state, cell) \
		and cell != House.porch(state) and _in_sight(state, cell)


## Whether a spot here could be seen: nothing standing in the two cells south
## of it, which is what would be drawn over it - a tree's canopy, a wall.
static func _in_sight(state: Dictionary, cell: Vector2i) -> bool:
	for step in [Vector2i(0, 1), Vector2i(0, 2)]:
		var below: Vector2i = cell + step
		if Grid.in_bounds(below) and not Farm.is_empty(state, below):
			return false
	return true


## What digging this cell gives, or empty when there is no spot - nor one
## that a building or a plot has since covered.
static func spot_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	var spot: Dictionary = (state.get("dig_spots", {}) as Dictionary).get(Grid.index(cell), {})
	if spot.is_empty() or not _diggable(state, cell):
		return {}
	return spot


## Every spot waiting, in index order: for the view and the checks.
static func spots(state: Dictionary) -> Array:
	var keys: Array = (state.get("dig_spots", {}) as Dictionary).keys()
	keys.sort()
	var out: Array = []
	for idx in keys:
		if not spot_at(state, Grid.cell(int(idx))).is_empty():
			out.append(Grid.cell(int(idx)))
	return out


## **Dig it up** (task 0185): `Interact.complete`'s `dig`. What came out,
## empty when there was nothing there.
static func dig(state: Dictionary, cell: Vector2i) -> Dictionary:
	var gives := spot_at(state, cell)
	if gives.is_empty():
		return {}
	Resources.gain(state, gives)
	(state["dig_spots"] as Dictionary).erase(Grid.index(cell))
	return gives


## The spots go with the sun (task 0185): `Phases.begin_preparation`.
static func clear_spots(state: Dictionary) -> void:
	(state["dig_spots"] as Dictionary).clear()


## Whether the animal at `index` in the home on this cell ate this morning.
static func is_fed(state: Dictionary, cell: Vector2i, index: int) -> bool:
	var animals := residents(state, cell)
	return index >= 0 and index < animals.size() and bool((animals[index] as Dictionary).get("fed", true))


## **A new home takes its kind in** (task 0183), called by `Building.place`:
## the loose animals on the map that live in it - in cell order, each taken
## off the map with what it had waiting - then any whose home was lost, as
## many as it has room for. **One `Farm.touch`** for every animal that left
## the map, not one apiece. How many moved in.
static func move_in(state: Dictionary, cell: Vector2i) -> int:
	var id := StringName(Farm.occupant(state, cell).get("id", &""))
	if not is_home(id):
		return 0
	var moved := 0
	var left_the_map := false
	var occupants: Dictionary = state["occupants"]
	var pen: Dictionary = state["livestock"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var kind := StringName((occupants[idx] as Dictionary)["id"])
		if not is_animal(kind) or home_of(kind) != id:
			continue
		var was: Dictionary = pen.get(idx, {})
		if not house(state, cell, kind, int(was.get("ready", 0)), int(was.get("left", 0))):
			break
		occupants.erase(idx)
		pen.erase(idx)
		left_the_map = true
		moved += 1
	var still: Array = []
	for animal in (state["unhoused"] as Array):
		var one: Dictionary = animal
		if house(state, cell, StringName(one["id"]), int(one["ready"]), int(one["left"])):
			moved += 1
		else:
			still.append(one)
	state["unhoused"] = still
	if left_the_map:
		Farm.touch(state)
	return moved


## **A home is gone** (task 0183): `Farm.forget_cell` calls this for every
## cell it clears. When it is a home's anchor, the animals that lived there
## wait in `unhoused` - alive, producing nothing - for the next home of their
## kind; none is ever lost with its building.
static func forget_cell(state: Dictionary, cell: Vector2i) -> void:
	var homes: Dictionary = state.get("housed", {})
	var idx := Grid.index(cell)
	if not homes.has(idx):
		return
	for animal in ((homes[idx] as Dictionary)["animals"] as Array):
		(state["unhoused"] as Array).append(animal)
	homes.erase(idx)


# ------------------------------------------------------------------ the tick

## One tick of standing in a field. Called from `Sim._tick_day()` and nowhere
## else: the animals are asleep at night, like everything else on the farm.
static func tick(state: Dictionary) -> void:
	var pen: Dictionary = state["livestock"]
	for cell in _animals(state):
		var idx := Grid.index(cell)
		var id: StringName = Farm.occupant(state, cell)["id"]
		var entry: Dictionary = GameData.LIVESTOCK[id]
		if not pen.has(idx):
			pen[idx] = {"ready": 0, "left": int(entry["every_ticks"])}

		_produce(pen[idx], entry)
	# **And the housed** (task 0183), home by home in cell order, each in the
	# order it moved in: the same clock as on the grass.
	var homes: Dictionary = state["housed"]
	var anchors: Array = homes.keys()
	anchors.sort()
	for idx in anchors:
		for animal in ((homes[idx] as Dictionary)["animals"] as Array):
			# **Unfed gives nothing today** (task 0184); what it had waiting
			# stays there to be collected.
			if not bool((animal as Dictionary).get("fed", true)):
				continue
			var entry: Dictionary = GameData.LIVESTOCK[(animal as Dictionary)["id"]]
			# A pig's keep is its spots, not a clock (task 0185).
			if (entry["produces"] as Dictionary).is_empty():
				continue
			_produce(animal, entry)


## One tick of one animal's clock.
static func _produce(at: Dictionary, entry: Dictionary) -> void:
	# **A full animal stops.** Nothing accumulates off screen for ever:
	# come back or lose the difference, which is what makes coming back a
	# thing you do rather than a thing you schedule.
	if int(at["ready"]) >= int(entry["holds"]):
		return
	at["left"] = int(at["left"]) - 1
	if int(at["left"]) > 0:
		return
	at["ready"] = int(at["ready"]) + 1
	at["left"] = int(entry["every_ticks"])


## Every animal on the farm, in cell order.
##
## Cached against `grid_version` for the same reason as `Power`: this runs at
## 30Hz and sorting the whole occupant table every tick is how the test suite
## tripled in task 0033.
static func _animals(state: Dictionary) -> Array:
	var pen: Dictionary = state["livestock"]
	var version := int(state["grid_version"])
	if int(state.get("livestock_version", -1)) != version:
		state["livestock_version"] = version
		var found: Array = []
		var occupants: Dictionary = state["occupants"]
		var keys: Array = occupants.keys()
		keys.sort()
		for idx in keys:
			if is_animal(StringName((occupants[idx] as Dictionary)["id"])):
				found.append(int(idx))
		state["livestock_cells"] = found
		# An animal that is gone takes its half-grown produce with it.
		for idx in pen.keys():
			if not found.has(int(idx)):
				pen.erase(idx)

	var out: Array = []
	for idx in (state["livestock_cells"] as Array):
		out.append(Grid.cell(int(idx)))
	return out
