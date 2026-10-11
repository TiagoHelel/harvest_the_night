class_name Enemies
extends RefCounted

## Zombies, walking in.
##
## They spawn at the edges, follow the flow field to the farmhouse, and take a
## bite out of it when they arrive. Tasks 0050 to 0052 give them reasons to be
## told apart.
##
## ## A heavy blow is announced before it lands
##
## An enemy with `telegraph_ticks` winds up the first time it swings at
## something, standing there for a second before anything is damaged. Only the
## Giant has one, and it is the difference between a wall vanishing and a wall
## you were given a second to do something about - a flare, a barricade, or
## simply getting out of the way.
##
## **It costs the swing nothing.** The wind-up is the front of the first wait,
## not an extra one: blows land on `ticks_per_tile` as they always did, and
## what the telegraph buys is that the *first* one is seen coming and every
## one after it is visibly imminent. A boss that hit more slowly for having a
## tell would be a boss you would rather it did not have.
##
## ## What they are walking towards
##
## Most of them are walking at the house. A **runner** goes round what you
## built instead of through it (task 0050) and a **breaker** goes at what you
## built instead of at the house (task 0052); each reads a different field out
## of `Pathing`, swept from a different place, and none of them knows how the
## walking works.
##
## A **decoy** (task 0224) turns whoever its row says can be lured - the
## walker, the runner and the tank, never a boss - when it stands within the
## decoy's `lure_tiles` by the lure field: that one walks the lure instead of
## its own field and bites the straw. The decoy's fall rebuilds the lure on
## the spot, and whoever walks after it that tick is back on its own road.
##
## ## Going through rather than around
##
## The field prices a barrier instead of refusing it (see `Pathing`), so the
## cheapest way home can run straight through a wall. When it does, a zombie
## does not walk into the wall - it stands where it is and takes the wall
## apart, which is the same decision expressed as damage instead of movement.
##
## That is what makes a wall worth building **and** worth building well. Before
## task 0049 they only ever broke something when they were sealed in with no
## route at all, so one gap in a line meant the whole wave filed through it and
## the line never lost a hit point.
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
		# And for the whole run, which `begin_night()` does not clear.
		"breaches_all_run": 0,
	}


## Put one on the farm at a spawn point, chosen from the run's RNG.
##
## `where` is an index into `GameData.SPAWNS`, which is what a wave table names.
static func spawn(state: Dictionary, kind: StringName, where: int) -> int:
	var options := spawn_cells(state, where)
	if options.is_empty():
		# Nowhere on the whole farm can reach the house - which the porch,
		# never buildable and always beside the door, makes impossible while
		# there is a house. Loud, because a member lost here is a member lost
		# without a trace, and that is what task 0115 closed.
		if where >= 0 and where < GameData.SPAWNS.size():
			push_error("Enemies.spawn: nowhere to put a %s from spawn %d" % [kind, where])
		return 0
	var cell: Vector2i = options[Rng.int_between(
		state["rng"], 0, options.size() - 1)]
	return Entities.spawn(state, kind, cell)


## The cells a given spawn point can use: the ones in its region that something
## can actually stand on and get to the house from.
##
## ## A spawn line cannot be built shut
##
## Until task 0115 a region with no free cell answered nothing, `spawn()`
## returned 0 and `Waves.tick()` counted the member as sent anyway: ten fences
## along the east line won night 1, every one of its twelve walkers gone. Now a
## sealed region answers **the nearest free ground around it** - ring by ring
## outwards, the first ring with anywhere to stand - and of that ring only the
## cells **farther from the house than the line cell they are beside**, by the
## flow field, when there are any. So a fence across the line is a fence they
## arrive behind and have to come through, not a door they skip, and a ring of
## towers around it is a ring they arrive outside. The search ends at the porch
## at the latest, which is never buildable and is always next to the house.
##
## Only a sealed region does this; a region with one free cell left still
## answers exactly that cell, so the spawn draw - one `Rng` call when somebody
## is placed - is the one it always was.
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
	if out.is_empty():
		return _beside_the_line(state, regions[where] as Array)
	return out


## The free ground nearest a sealed spawn region. See `spawn_cells`.
static func _beside_the_line(state: Dictionary, region: Array) -> Array:
	var line: Array = []
	for entry in region:
		line.append(Vector2i(int(entry[0]), int(entry[1])))
	for radius in range(1, maxi(Grid.WIDTH, Grid.HEIGHT) + 1):
		var seen := {}
		var free: Array = []
		var far: Array = []
		for centre in line:
			# The bar is the line cell this ring is drawn around: a fenced
			# cell still has a field value, the cost of going home from it.
			# One bar for the whole line was measured and is too low - two
			# east cells sit on the road home and let the near side in.
			var bar := Pathing.distance(state, centre) \
				if Pathing.reachable(state, centre) else -1
			for cell in Grid.within(centre, radius):
				if seen.has(cell) or Grid.chebyshev(centre, cell) != radius:
					continue
				seen[cell] = true
				if not Farm.walkable(state, cell) \
						or not Pathing.reachable(state, cell):
					continue
				free.append(cell)
				if bar >= 0 and Pathing.distance(state, cell) > bar:
					far.append(cell)
		if not far.is_empty():
			return far
		if not free.is_empty():
			return free
	return []


# ------------------------------------------------------------------ the tick

## One tick of everything walking in. Called from `Sim._tick_night()`.
static func tick(state: Dictionary) -> void:
	Pathing.refresh(state)
	if Entities.count(state) == 0:
		return

	# **The lure, asked once a tick** (task 0224), and nothing more than
	# whether it is empty while no decoy stands.
	var pull := _pull(state)
	# Sorted by id, so two zombies arriving on the same tick always land in the
	# same order - which decides which of them the last hit point goes to.
	for id in Entities.ids(state):
		_walk(state, id, pull)


## **What a decoy pulls with**, as the walking reads it (task 0224): the lure
## field, how far it reaches and the farm it was built for. Empty when no
## decoy stands - every night until one goes down.
static func _pull(state: Dictionary) -> Dictionary:
	var field := Pathing.field(state, &"lure")
	if field.is_empty():
		return {}
	return {"field": field, "reach": Pathing.lure_reach(),
		"version": int(state["grid_version"])}


## Whether a decoy has this one: the lure field says the nearest is within its
## reach, and it is not standing on the straw. **A farm changed since the tick
## began is asked again first** - a decoy bitten down a moment ago is a field
## rebuilt without it, so whoever walks after the bite that tick is back on
## its own road.
static func _lured(state: Dictionary, pull: Dictionary, here: Vector2i) -> bool:
	if int(pull["version"]) != int(state["grid_version"]):
		pull["field"] = Pathing.field(state, &"lure")
		pull["version"] = int(state["grid_version"])
	var field: PackedInt32Array = pull["field"]
	var idx := Grid.index(here)
	if idx < 0 or field.size() != Grid.CELLS:
		return false
	var away := int(field[idx])
	return away > 0 and away <= int(pull["reach"])


static func _walk(state: Dictionary, id: int, pull: Dictionary) -> void:
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
		# **The house is announced too.** Something that takes forty hit
		# points off the roof in one blow does not get to do it on the tick
		# it arrives.
		if not _swung_at_the_house(state, id, data, on):
			return
		_bite(state, id, data)
		return

	var per_tile := maxi(int(data["ticks_per_tile"]), 1)
	# **Flared things walk slowly**, and the count runs down whether they are
	# walking or chewing - five seconds is five seconds.
	var slow := int(one.get("slow", 0))
	if slow > 0:
		one["slow"] = slow - 1
		per_tile = Ability.slowed_ticks(per_tile)

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
	var next := here
	# **A decoy turns the lurable** (task 0224). Within its reach by the lure
	# field, one walks that field instead of its own, and the straw is the
	# next cell in the end: `breaks_through()` says so and it bites. A runner
	# too - it goes round a wall, and not round this.
	if not pull.is_empty() and bool(data.get("lurable", false)) \
			and _lured(state, pull, here):
		next = Pathing.step_lure(state, here)
	# **A runner goes round what you built.** It asks the field with the
	# barriers taken out of it, and only falls back to the one everybody else
	# uses when that field has no answer - which means there is no way round
	# at all, and standing still in front of a wall would turn sealing the
	# farm into a win condition.
	elif bool(data.get("ignores_structures", false)):
		next = Pathing.step_around(state, here)
	# **A breaker has come for the towers.** It walks the field swept from
	# everything the player built, and falls through to the house only when
	# there is nothing left standing to go for. Nearest by what the walk
	# costs, which is a better answer than "nearest in a straight line" and
	# is ordered and deterministic because the field is.
	elif bool(data.get("targets_structures", false)):
		next = Pathing.step_hunt(state, here)
	if next == here:
		next = Pathing.step_from(state, here)
	if next == here and Pathing.distance(state, here) == Pathing.UNREACHABLE:
		# A sealed row of towers can be several cells away. Approach it before
		# chewing; checking only adjacent structures strands distant spawns.
		next = Pathing.step_hunt(state, here)
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
	if Pathing.breaks_through(state, next):
		# **The cheapest way home is through this.** Not the nearest structure
		# and not the one lowest in reading order: the one the field picked,
		# which is the one actually in the way.
		_gnaw(state, id, data, next)
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


## Whether a telegraphing enemy has finished winding up at the house. True at
## once for everything that does not telegraph.
static func _swung_at_the_house(state: Dictionary, id: int,
		data: Dictionary, cell: Vector2i) -> bool:
	var telegraph := int(data.get("telegraph_ticks", 0))
	if telegraph <= 0:
		return true
	var one := Entities.get_one(state, id)
	if int(one.get("winding_at", -1)) != Grid.index(cell):
		one["winding_at"] = Grid.index(cell)
		one["chew_wait"] = telegraph
		return false
	var wait := int(one.get("chew_wait", 0))
	if wait > 0:
		one["chew_wait"] = wait - 1
		return false
	return true


## Reaching the house costs the house and costs the zombie: it is spent.
## No way through, so take the way through apart.
##
## This is the **sealed-in** case only: no neighbour improves at all, which
## after task 0049 means the way out is blocked by something with no way
## through it - a ring of towers, or a pocket between the rocks and the pond.
## A zombie with a wall in front of it is not here; the field sent it into the
## wall and `_walk()` turned that into a bite.
##
## Looks at the four neighbours and bites whichever structure is nearest the
## house - the one actually in the way, rather than whatever happens to be
## first in reading order. Distant reachable structures are approached through
## the hunt field first; with no target or path at all the zombie waits.
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
	_gnaw(state, id, data, best)


## One bite out of a named cell.
##
## **One bite per tile's worth of time.** `_walk()` gates this on `move`, which
## is *sub-units* rather than tiles - a walker covers three of sixty-four in a
## tick - so biting on every one of those was twenty damage in two ticks and a
## barricade that bought nothing at all.
##
## A bite costs what crossing a tile costs, so a fast zombie chews fast and
## `ticks_per_tile` means one thing in both places. It is also what makes
## `path_cost` an honest number: going through a wall really does cost about
## the time that walking `hp / damage` tiles would.
static func _gnaw(state: Dictionary, id: int, data: Dictionary,
		cell: Vector2i) -> void:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return
	# **The wind-up, once per target.** Turning to something new is what a
	# player sees; from then on the wait itself is the tell.
	var telegraph := int(data.get("telegraph_ticks", 0))
	if telegraph > 0 and int(one.get("winding_at", -1)) != Grid.index(cell):
		one["winding_at"] = Grid.index(cell)
		one["chew_wait"] = telegraph
		return
	var wait := int(one.get("chew_wait", 0))
	if wait > 0:
		one["chew_wait"] = wait - 1
		return
	one["chew_wait"] = maxi(int(data["ticks_per_tile"]), 1)
	# **What it does to a thing is not what it does to the house.** A breaker
	# is three hundred percent here and five at the door; a giant is four
	# hundred. Everything else declares nothing and gets a hundred, so the
	# multiply is free for them and the table says which is which.
	var percent := int(data.get("structure_damage_percent", 100))
	Farm.damage(state, cell, maxi(int(data["damage"]) * percent / 100, 1))
	one["chewing"] = Grid.index(cell)


## Whether this one is winding up a blow rather than walking. For the view,
## and for the asserts.
static func is_winding(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty() or int(one.get("winding_at", -1)) < 0:
		return false
	var telegraph := int((GameData.ENEMIES[one["kind"]] as Dictionary)
		.get("telegraph_ticks", 0))
	return telegraph > 0 and int(one.get("chew_wait", 0)) > 0


## The cell a wind-up is aimed at, or `(-1, -1)`.
static func winding_at(state: Dictionary, id: int) -> Vector2i:
	var one := Entities.get_one(state, id)
	var idx := int(one.get("winding_at", -1))
	return Grid.cell(idx) if idx >= 0 and is_winding(state, id) \
		else Vector2i(-1, -1)


## The four cells around a cell, in a fixed order.
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0),
]


static func _bite(state: Dictionary, id: int, data: Dictionary) -> void:
	state["house_hp"] = maxi(int(state["house_hp"]) - int(data["damage"]), 0)
	Events.add(state, &"house_hit", {
		"damage": int(data["damage"]), "left": int(state["house_hp"]),
	})
	state["breaches"] = int(state["breaches"]) + 1
	state["breaches_all_run"] = int(state.get("breaches_all_run", 0)) + 1
	Entities.remove(state, id)

	if int(state["house_hp"]) <= 0:
		# The night is lost the moment the house falls.
		Rewards.settle(state, false)
		Phases.enter_result(state, false)


# ------------------------------------------------------------------- dawn

## Whoever the night left standing goes back where it came from. Returns how
## many went. Called from `Phases.begin_day()`.
##
## **Everything that was only about them goes too**: the shots still in the
## air, the fires, the flare. None of those advance by day - only
## `Sim._tick_night()` moves them - so one left over would hang over the farm
## all afternoon and land on whatever walked under it the next night.
##
## The rules take them off the farm in one tick; walking off is the view's
## (`EnemyRetreats`), which is why there is nothing to wait for here.
static func withdraw(state: Dictionary) -> int:
	var gone := Entities.count(state)
	for id in Entities.ids(state):
		Entities.remove(state, int(id))
	(state["projectiles"] as Array).clear()
	(state["burning"] as Dictionary).clear()
	Ability.put_out(state)
	return gone


## The same, for a farm that is in daylight with a zombie on it - which only
## a save written before dawn sent them home can be. Returns how many went.
## Called from `State.reconcile()`.
static func withdraw_in_daylight(state: Dictionary) -> int:
	var phase := int(state.get("phase", Phases.DAY))
	if phase != Phases.DAY and phase != Phases.PREPARATION:
		return 0
	if Entities.count(state) == 0:
		return 0
	return withdraw(state)


## What is left of the farmhouse, as a fraction of the house the night
## started with ('stout timbers' included, task 0114), for the night HUD.
static func house_fraction(state: Dictionary) -> float:
	return float(state["house_hp"]) / float(maxi(Phases.house_full(state), 1))
