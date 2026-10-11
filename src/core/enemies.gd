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
## A **zombie bait** (task 0225) pulls the same way from further off, and is
## walked onto rather than bitten: whoever reaches it stops there to eat until
## it is gone - at its lifetime, or once `eaten_by` have reached it - and then
## the crowd on it walks on.
##
## ## Stunned
##
## An enemy with a `stun` count stands where it is - neither walking nor
## biting - until the count runs out (task 0230). Any source may set it,
## through `stun()`: a bite on an electric fence does (`shock_ticks()`), and
## 0233's farm bell will.
##
## ## Spat at from range
##
## A **spitter** (task 0247) with a tower - anything that shoots - within its
## `spit_range` stands where it is and spits at the nearest, every
## `spit_every_ticks`; with none it walks and bites like a walker. The glob is
## aimed at the tower's cell when it leaves, flies `spit_tiles_per_second`,
## and lands through `Farm.damage` on whatever stands there then - nothing, if
## the tower has gone. The globs in the air are `enemy_shots`, kept apart
## from the towers' `projectiles`, which `Combat.incoming` reads, and moved
## here at the top of the tick, as a tower's shots are at the top of its.
##
## ## In the air
##
## A **crow** (task 0249) `flies`: no wall, mine or field touches it. It flies
## straight - one unit at a time along the dominant axis, as a walker's step
## does - to the nearest plot with a crop on it (Manhattan, the lower cell
## index on a tie), chosen when it takes off and kept until it lands there or
## the crop is gone. Landed, it stands `peck_ticks`, eats the crop
## (`Farming.eat`) and takes off for the next. With nothing growing it flies
## at the house and bites. In the air only a tower that `hits_flying` reaches
## it, and a mine never sees it; landed, it is on the ground like anything
## else.
##
## ## Under ground
##
## A **digger** (task 0250) `burrows`: it walks the burrow field, where a
## `burrowable` barrier - a fence, a barricade, the wire - costs only the
## ground under it, and passes under one rather than biting it. While it is
## on such a cell it is `underground`: nothing that hits reaches it and the
## barrier loses nothing. On open ground it is a walker again, and a wall or
## the house it gnaws and bites as one.
##
## ## Charging
##
## A **charger** (task 0253's Harvester) has `charge_tiles`. Every
## `charge_every_ticks` it spends rolling and gnawing (`charge_in` counts them
## down) it stops and winds up for `telegraph_ticks` - its one tell, the one
## before a gnaw - through `winding_at` and `chew_wait`, so everything that
## shows a wind-up shows this one. The line is fixed when the wind-up starts
## (`charge_from`, `charge_dir`): the row or column from where it stands
## towards the house centre along the dominant axis, ties to the row. Then it
## runs the line at `charge_ticks_per_tile`, ignoring the field
## (`charge_left`). Every structure it enters takes `crush_damage` through
## `Farm.damage`: it carries on through what that brings down and stops at the
## first that holds, at the map's edge, at ground nothing crosses, at what it
## cannot crush (a tree, the stall), after `charge_tiles`, or at the house -
## with a bite, which spends it as any bite does. Then it rolls and gnaws as
## before, its clock started again. The walls it brings down rebuild the
## fields once, at the next `Pathing.refresh`, however many fell.
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
		# **The spit in the air** (task 0247): a record for each glob, in the
		# order they were spat - who spat it and when, where it is (integer
		# sub-tiles), the cell it was aimed at, its flight and how much of it
		# is left, and what it does to a structure.
		"enemy_shots": [],
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


## **A cluster** (task 0248): `count` of a kind at once. The first goes on a
## cell of spawn point `where` from the run's RNG, as `spawn()` puts any one;
## the rest on that cell's walkable, reachable neighbours in `NEIGHBOURS`
## order, round them again past the fourth - bodies may share a cell, as they
## already can - or on the first's own cell when it has none. No draw past
## the first. The ids, or none when the first found nowhere to stand.
static func spawn_cluster(state: Dictionary, kind: StringName, where: int,
		count: int) -> Array:
	var first := spawn(state, kind, where)
	if first == 0:
		return []
	return [first] + _round(state, kind, Entities.cell_of(state, first), count - 1)


## **A cluster on a cell of the caller's** (task 0248): the first on `at`, the
## rest round it as `spawn_cluster` puts them - what a check or a picture
## lays down where it wants one. The ids.
static func cluster_at(state: Dictionary, kind: StringName, at: Vector2i,
		count: int) -> Array:
	return [Entities.spawn(state, kind, at)] + _round(state, kind, at, count - 1)


## `count` more round `at`: on its walkable, reachable neighbours in
## `NEIGHBOURS` order, round again past the last, or on `at` itself when it
## has none.
static func _round(state: Dictionary, kind: StringName, at: Vector2i,
		count: int) -> Array:
	var out: Array = []
	if count <= 0:
		return out
	var ring: Array = []
	for step in NEIGHBOURS:
		var cell: Vector2i = at + step
		if Grid.in_bounds(cell) and Farm.walkable(state, cell) \
				and Pathing.reachable(state, cell):
			ring.append(cell)
	if ring.is_empty():
		ring.append(at)
	for i in count:
		out.append(Entities.spawn(state, kind, ring[i % ring.size()]))
	return out


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
	# **The spit in the air first** (task 0247), as a tower's shots are: a
	# glob spat this tick has not flown yet, one whose spitter has fallen
	# lands all the same - and before the field is asked, so a tower it
	# brought down is already off the farm the walking reads.
	_advance_spit(state)
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


## What the lure field says of a cell: the walk to the lure that pulls
## hardest from there, plus its head start (`Pathing.distance_lure`), or
## `Pathing.UNREACHABLE`. Pulled while it is above 0 and at most the pull's
## reach. **A farm changed since the tick began is asked again first** - a
## decoy bitten down or a bait eaten up a moment ago is a field rebuilt
## without it, so whoever walks after that, that tick, is back on its own
## road.
static func _lure_away(state: Dictionary, pull: Dictionary, cell: Vector2i) -> int:
	if int(pull["version"]) != int(state["grid_version"]):
		pull["field"] = Pathing.field(state, &"lure")
		pull["version"] = int(state["grid_version"])
	var field: PackedInt32Array = pull["field"]
	var idx := Grid.index(cell)
	if idx < 0 or field.size() != Grid.CELLS:
		return Pathing.UNREACHABLE
	return int(field[idx])


## **One more has reached the bait on this cell** (task 0225), and stops to
## eat. Once `eaten_by` have, it is gone - taken away like an expired
## barricade, with no rubble - and the lure is rebuilt without it.
static func _reached_bait(state: Dictionary, cell: Vector2i) -> void:
	var on := Farm.occupant(state, cell)
	var entry: Dictionary = GameData.DEFENCES.get(StringName(on.get("id", &"")), {})
	var most := int(entry.get("eaten_by", 0))
	if most <= 0:
		return
	on["eaten"] = int(on.get("eaten", 0)) + 1
	if int(on["eaten"]) >= most:
		Farm.remove(state, cell)


static func _walk(state: Dictionary, id: int, pull: Dictionary) -> void:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return
	var data: Dictionary = GameData.ENEMIES[one["kind"]]

	# **Stunned, it stands** (task 0230): neither walking nor biting - its
	# step, its bite's wait and its wind-up held where they are - until the
	# count runs out. A flare's slow runs down all the same: five seconds is
	# five seconds.
	var stunned := int(one.get("stun", 0))
	if stunned > 0:
		one["stun"] = stunned - 1
		var slowed := int(one.get("slow", 0))
		if slowed > 0:
			one["slow"] = slowed - 1
		return

	# **A flyer flies** (task 0249), over everything below it - a stun holds it
	# in the air as it holds a walker on the ground.
	if bool(data.get("flies", false)):
		_fly(state, id, data)
		return

	# **A charger winds up and charges** (task 0253): while either lasts it
	# is all it does, and its clock to the next runs while it rolls and gnaws.
	if int(data.get("charge_tiles", 0)) > 0 and _charging(state, id, data, one):
		return

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

	# **A spitter stands off a tower** (task 0247): within its `spit_range`
	# of one it stays where it is and spits, and with none it walks on like
	# a walker.
	if int(data.get("spit_range", 0)) > 0 and _stood_and_spat(state, id, data, on):
		return

	var base := maxi(int(data["ticks_per_tile"]), 1)
	var per_tile := base
	# **Flared things walk slowly**, and the count runs down whether they are
	# walking or chewing - five seconds is five seconds.
	var slow := int(one.get("slow", 0))
	if slow > 0:
		one["slow"] = slow - 1
		per_tile = Ability.slowed_ticks(base)
	# **So do the ones walking through garlic** (task 0228): the area's share
	# off their speed, one array read for the cell they stand on. With a
	# flare too, the stronger of the two - never both.
	var garlic := Pathing.repelled(state, on)
	if garlic > 0:
		per_tile = maxi(per_tile, Ability.slowed_ticks(base, 100 - garlic))

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
	var lured := false
	if not pull.is_empty() and bool(data.get("lurable", false)):
		var away := _lure_away(state, pull, here)
		# **On a bait, it eats** (task 0225): a lure it can stand on holds it
		# there until the bait is gone - the crowd in one place, for whatever
		# the player laid beside it.
		if away == 0 and Building.walked_over(StringName(Farm.occupant(state, here).get("id", &""))):
			return
		lured = away > 0 and away <= int(pull["reach"])
	# **A lure turns the lurable** (tasks 0224 and 0225). Within its reach by
	# the lure field, one walks that field instead of its own: to a decoy,
	# which is the next cell in the end - `breaks_through()` says so and it
	# bites - or onto a bait. A runner too: it goes round a wall, and not
	# round this.
	if lured:
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
	# **A digger goes under** (task 0250): its own field, where a fence is
	# the ground under it.
	elif bool(data.get("burrows", false)):
		next = Pathing.step_by(state, &"burrow", here)
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
	# Under a fence it goes on, and the fence loses nothing (task 0250).
	if Pathing.breaks_through(state, next) and not (bool(data.get("burrows", false))
			and Pathing.burrowable_at(state, next)):
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
	# **Arrived at a bait** (task 0225): the lure's 0 under a lured foot.
	elif lured and landed != here and _lure_away(state, pull, landed) == 0:
		_reached_bait(state, landed)


## **A spitter's turn** (task 0247). Its spit's wait runs down whatever it
## is doing - a stun holds it, as it holds a bite's. With a tower within
## `spit_range` it stands, its slow running down as a walker's does, and
## spits once the wait is out; true. With none it is spitting at nothing,
## and false: it walks.
static func _stood_and_spat(state: Dictionary, id: int, data: Dictionary,
		here: Vector2i) -> bool:
	var one := Entities.get_one(state, id)
	var wait := int(one.get("spit_wait", 0))
	if wait > 0:
		one["spit_wait"] = wait - 1
	var mark := spit_target(state, here, int(data["spit_range"]))
	if mark.x < 0:
		one.erase("spitting")
		return false
	one["spitting"] = Grid.index(mark)
	var slow := int(one.get("slow", 0))
	if slow > 0:
		one["slow"] = slow - 1
	if int(one.get("spit_wait", 0)) <= 0:
		one["spit_wait"] = maxi(int(data["spit_every_ticks"]), 1)
		_spit(state, id, data, mark)
	return true


## **The tower a spitter spits at** (task 0247): the nearest thing that
## shoots within `reach` of `from`, by Chebyshev distance - a tower's own
## measure of reach - and the lower cell index on a tie, which
## `Towers.cells()` coming in cell order gives for nothing. `(-1, -1)` for
## none.
static func spit_target(state: Dictionary, from: Vector2i, reach: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var nearest := reach + 1
	for cell in Towers.cells(state):
		var apart := Grid.chebyshev(from, cell as Vector2i)
		if apart < nearest:
			nearest = apart
			best = cell
	return best


## The cell a spitter is spitting at, or `(-1, -1)` while it walks. For the
## view, and for the asserts.
static func spitting_at(state: Dictionary, id: int) -> Vector2i:
	var idx := int(Entities.get_one(state, id).get("spitting", -1))
	return Grid.cell(idx) if idx >= 0 else Vector2i(-1, -1)


## **A glob leaves** (task 0247), from where the spitter stands, aimed at the
## tower's cell. Its flight is that cell's middle away by the Chebyshev
## measure the spit range is in, at `spit_tiles_per_second`, rounded up and
## never under a tick: a glob at a tower four tiles off along a diagonal
## lands as soon as one four tiles off along a row.
static func _spit(state: Dictionary, id: int, data: Dictionary, at: Vector2i) -> void:
	var one := Entities.get_one(state, id)
	var from := Vector2i(int(one["pos"][0]), int(one["pos"][1]))
	var to := at * Player.SUBTILE + Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2)
	var speed := maxi(int(data["spit_tiles_per_second"]) * Player.SUBTILE
		/ GameData.TICK_HZ, 1)
	var apart := maxi(absi(to.x - from.x), absi(to.y - from.y))
	var flight := maxi((apart + speed - 1) / speed, 1)
	(state["enemy_shots"] as Array).append({
		"by": id,
		"fired": int(state["tick"]),
		"pos": [from.x, from.y],
		"to": [at.x, at.y],
		"left": flight,
		"flight": flight,
		"damage": int(data["spit_damage"]),
	})


## **The spit in the air, a tick on** (task 0247): each glob carried a share
## of the way left towards its cell's middle, and on its last tick landed
## there through `Farm.damage` - on whatever stands there now. An empty cell,
## or rubble, takes nothing; a tower it brings down leaves rubble and a
## `structure_lost`, as a bite's does.
static func _advance_spit(state: Dictionary) -> void:
	var flying: Array = state["enemy_shots"]
	if flying.is_empty():
		return
	var still: Array = []
	for shot in flying:
		var left := int(shot["left"]) - 1
		shot["left"] = left
		var cell := Vector2i(int(shot["to"][0]), int(shot["to"][1]))
		if left <= 0:
			Farm.damage(state, cell, int(shot["damage"]))
			continue
		var to := cell * Player.SUBTILE + Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2)
		var at := Vector2i(int(shot["pos"][0]), int(shot["pos"][1]))
		shot["pos"][0] = at.x + (to.x - at.x) / (left + 1)
		shot["pos"][1] = at.y + (to.y - at.y) / (left + 1)
		still.append(shot)
	flying.clear()
	flying.append_array(still)


## **Whether this one is under ground now** (task 0250): a burrower standing on
## a `burrowable` barrier's cell. Nothing that hits reaches it there.
static func underground(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty() or not bool((GameData.ENEMIES.get(StringName(one["kind"]), {}) as Dictionary).get("burrows", false)):
		return false
	return Pathing.burrowable_at(state, Vector2i(int(one["pos"][0]) / Player.SUBTILE,
		int(one["pos"][1]) / Player.SUBTILE))


## **Whether anything that hits can reach this one** (tasks 0249 and 0250):
## not under ground, and not in the air for what does not reach it.
static func in_reach(state: Dictionary, id: int, up: bool) -> bool:
	if underground(state, id):
		return false
	return up or not airborne(state, id)


## **Whether a kind can only be aimed at in light** (task 0252): its
## `needs_light`.
static func needs_light(kind: StringName) -> bool:
	return bool((GameData.ENEMIES.get(kind, {}) as Dictionary).get("needs_light", false))


## **Whether a tower can see this one to aim at it** (task 0252): anything but
## a `needs_light` kind on a cell `Light` leaves dark. Aiming asks it; what
## lands on an area never does.
static func in_sight(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return false
	if not needs_light(StringName(one["kind"])):
		return true
	return Light.is_lit(state, Entities.cell_of(state, id))


## Whether a kind flies (task 0249).
static func flies(kind: StringName) -> bool:
	return bool((GameData.ENEMIES.get(kind, {}) as Dictionary).get("flies", false))


## **Whether this one is in the air now** (task 0249): a flyer not standing on
## a plot to eat it. What only a tower that `hits_flying` reaches; a mine, and
## the power that bites from the porch, never see it.
static func airborne(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	return not one.is_empty() and flies(StringName(one["kind"])) and not one.has("peck")


## **The nearest plot with a crop on it** (task 0249): Manhattan from `from`,
## the lower cell index on a tie. `(-1, -1)` when nothing grows.
static func nearest_crop(state: Dictionary, from: Vector2i) -> Vector2i:
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	var best := Vector2i(-1, -1)
	var nearest := 1 << 30
	for idx in keys:
		if StringName((plots[idx] as Dictionary).get("crop", &"")) == &"":
			continue
		var cell := Grid.cell(int(idx))
		var apart := Grid.manhattan(from, cell)
		if apart < nearest:
			nearest = apart
			best = cell
	return best


## **Where a flyer is flying** (task 0249): the crop it took off for while
## there is still a crop there, else the nearest now - kept in `flying_to` -
## else the house (`HOUSE_BOUND`), for good: nothing grows at night.
static func _flight_target(state: Dictionary, one: Dictionary) -> Vector2i:
	var kept := int(one.get("flying_to", -1))
	if kept == HOUSE_BOUND:
		return Farm.house_centre(state)
	if kept >= 0 and Farming.crop_on(state, Grid.cell(kept)) != &"":
		return Grid.cell(kept)
	var here := Vector2i(int(one["pos"][0]) / Player.SUBTILE, int(one["pos"][1]) / Player.SUBTILE)
	var crop := nearest_crop(state, here)
	if crop.x < 0:
		one["flying_to"] = HOUSE_BOUND
		return Farm.house_centre(state)
	one["flying_to"] = Grid.index(crop)
	return crop


## What `flying_to` says of a flyer with nothing left to eat: the house.
const HOUSE_BOUND := -2


## **A flyer's turn** (task 0249). Landed, it pecks: the wait runs down and
## at its end the crop goes and it takes off. In the air it flies straight at
## its target at `ticks_per_tile` - a flare's slow slowing it as it slows a
## walker - landing on a crop's plot and biting the house the moment it is
## over it.
static func _fly(state: Dictionary, id: int, data: Dictionary) -> void:
	var one := Entities.get_one(state, id)
	if one.has("peck"):
		var left := int(one["peck"]) - 1
		if left > 0:
			one["peck"] = left
			return
		one.erase("peck")
		one.erase("flying_to")
		var here := Entities.cell_of(state, id)
		var crop := Farming.eat(state, here)
		if crop != &"":
			Events.add(state, &"crop_eaten", {"crop": crop, "cell": [here.x, here.y]})
		return

	var target := _flight_target(state, one)
	var base := maxi(int(data["ticks_per_tile"]), 1)
	var per_tile := base
	var slow := int(one.get("slow", 0))
	if slow > 0:
		one["slow"] = slow - 1
		per_tile = Ability.slowed_ticks(base)
	var progress := int(one["step"]) + Player.SUBTILE
	var move := progress / per_tile
	one["step"] = progress - move * per_tile

	var at := Vector2i(int(one["pos"][0]), int(one["pos"][1]))
	var goal := target * Player.SUBTILE + Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2)
	for _i in move:
		var delta := goal - at
		if delta == Vector2i.ZERO:
			break
		if absi(delta.x) >= absi(delta.y):
			at.x += signi(delta.x)
		else:
			at.y += signi(delta.y)
	one["pos"][0] = at.x
	one["pos"][1] = at.y

	if int(one.get("flying_to", -1)) == HOUSE_BOUND:
		var over := Vector2i(at.x / Player.SUBTILE, at.y / Player.SUBTILE)
		if Farm.occupant(state, over).get("id", &"") == &"house":
			_bite(state, id, data)
		return
	if at == goal:
		one["peck"] = maxi(int(data["peck_ticks"]), 1)


# ------------------------------------------------------------------ charging

## What a charge meets on a cell (task 0253): nothing it can go on into - the
## map's edge, ground nothing crosses, what it cannot crush; open ground,
## rubble or something walked over; one of the player's structures; the house.
const CHARGE_STOP := 0
const CHARGE_ON := 1
const CHARGE_CRUSH := 2
const CHARGE_HOUSE := 3


## **A charger's turn** (task 0253): true while it winds up or runs its line -
## all it does this tick - and false while it rolls and gnaws, its clock to
## the next wind-up running down. The wind-up ends on its last tick with the
## run's first: `telegraph_ticks` of winding, not one more.
static func _charging(state: Dictionary, id: int, data: Dictionary, one: Dictionary) -> bool:
	if one.has("charge_left"):
		_run_the_charge(state, id, data, one)
		return true
	if one.has("charge_dir"):
		var wait := int(one.get("chew_wait", 0)) - 1
		one["chew_wait"] = maxi(wait, 0)
		if wait > 0:
			return true
		one.erase("winding_at")
		one["charge_left"] = int(data["charge_tiles"])
		_run_the_charge(state, id, data, one)
		return true
	var due := int(one.get("charge_in", int(data["charge_every_ticks"])))
	if due > 1:
		one["charge_in"] = due - 1
		return false
	var here := Vector2i(int(one["pos"][0]) / Player.SUBTILE, int(one["pos"][1]) / Player.SUBTILE)
	var dir := charge_direction(state, here)
	# On the house it bites instead; it charges when it is off it.
	if dir == Vector2i.ZERO or Farm.occupant(state, here).get("id", &"") == &"house":
		one["charge_in"] = 1
		return false
	# **The line, fixed now**: from here, towards the house.
	one.erase("charge_in")
	one["charge_from"] = Grid.index(here)
	one["charge_dir"] = [dir.x, dir.y]
	one["winding_at"] = Grid.index(here + dir)
	one["chew_wait"] = maxi(int(data.get("telegraph_ticks", 0)), 1)
	return true


## **The way a charge from `cell` goes** (task 0253): one step towards the
## house centre along the dominant axis, the row on a tie; nothing from the
## house centre itself.
static func charge_direction(state: Dictionary, cell: Vector2i) -> Vector2i:
	var delta := Farm.house_centre(state) - cell
	if delta == Vector2i.ZERO:
		return Vector2i.ZERO
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


## **What a charge meets on `cell`** (task 0253): `CHARGE_STOP` at the map's
## edge, on ground nothing crosses and at anything it cannot crush - a tree, a
## rock, the stall; `CHARGE_ON` over open ground, rubble or something walked
## over (a mine, a sprinkler, bait); `CHARGE_CRUSH` at one of the player's
## structures; `CHARGE_HOUSE` at the house.
static func charge_meets(state: Dictionary, cell: Vector2i) -> int:
	if not Grid.in_bounds(cell) or Farm.cost_of_terrain(Farm.terrain_at(state, cell)) <= 0:
		return CHARGE_STOP
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return CHARGE_ON
	var kind := StringName(on["id"])
	if kind == &"house":
		return CHARGE_HOUSE
	if Traps.is_trap(kind) or Building.walked_over(kind):
		return CHARGE_ON
	if Building.entry_of(kind) == null or Farm.FIXTURES.has(kind):
		return CHARGE_STOP
	return CHARGE_CRUSH


## **One tick of a charge** (task 0253): along its line at
## `charge_ticks_per_tile`, the remainder carried as a walk carries it, and
## each cell asked before it is entered. A structure there takes
## `crush_damage` and lets it on only if that brought it down; the house takes
## a bite, which spends it; anything else that stops it, or the last of its
## `charge_tiles`, ends the charge where it stands.
static func _run_the_charge(state: Dictionary, id: int, data: Dictionary, one: Dictionary) -> void:
	var dir := Vector2i(int(one["charge_dir"][0]), int(one["charge_dir"][1]))
	var per_tile := maxi(int(data["charge_ticks_per_tile"]), 1)
	var progress := int(one["step"]) + Player.SUBTILE
	var move := progress / per_tile
	one["step"] = progress - move * per_tile
	var at := Vector2i(int(one["pos"][0]), int(one["pos"][1]))
	var over := false
	for _i in move:
		var to := at + dir
		# Off the map's top or left edge: no cell of it.
		if to.x < 0 or to.y < 0:
			over = true
			break
		var here := Vector2i(at.x / Player.SUBTILE, at.y / Player.SUBTILE)
		var into := Vector2i(to.x / Player.SUBTILE, to.y / Player.SUBTILE)
		if into != here:
			if int(one["charge_left"]) <= 0:
				over = true
				break
			var meets := charge_meets(state, into)
			if meets == CHARGE_HOUSE:
				_bite(state, id, data)
				return
			if meets == CHARGE_STOP:
				over = true
				break
			if meets == CHARGE_CRUSH:
				Farm.damage(state, into, int(data["crush_damage"]))
				if not Farm.occupant(state, into).is_empty():
					over = true
					break
			one["charge_left"] = int(one["charge_left"]) - 1
		at = to
	one["pos"][0] = at.x
	one["pos"][1] = at.y
	if over:
		_end_charge(one, data)


## A charge over (task 0253): back to rolling and gnawing, the wind-up's marks
## gone - the next blow winds up afresh - and the clock to the next started.
static func _end_charge(one: Dictionary, data: Dictionary) -> void:
	for key in ["charge_from", "charge_dir", "charge_left", "winding_at", "chew_wait"]:
		one.erase(key)
	one["charge_in"] = int(data["charge_every_ticks"])


## **The cells a charger's line telegraphs** (task 0253), in the order it
## enters them: from where the line was fixed, while it winds up or runs -
## `charge_tiles` long, cut at what stops it, and ending at the house or at
## the first structure that would hold. For the view's strip and the tests;
## empty for anything not charging.
static func charge_line(state: Dictionary, id: int) -> Array:
	var one := Entities.get_one(state, id)
	if one.is_empty() or not one.has("charge_dir"):
		return []
	var data: Dictionary = GameData.ENEMIES[one["kind"]]
	var dir := Vector2i(int(one["charge_dir"][0]), int(one["charge_dir"][1]))
	var at := Grid.cell(int(one["charge_from"]))
	var out: Array = []
	for _i in int(data["charge_tiles"]):
		at += dir
		var meets := charge_meets(state, at)
		if meets == CHARGE_STOP:
			break
		out.append(at)
		if meets == CHARGE_HOUSE or (meets == CHARGE_CRUSH
				and int(Farm.occupant(state, at).get("hp", 0)) > int(data["crush_damage"])):
			break
	return out


## Whether this one is running a charge's line (task 0253).
static func is_charging(state: Dictionary, id: int) -> bool:
	return Entities.get_one(state, id).has("charge_left")


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
	# What it bit, before the bite can bring it down (task 0230).
	var bitten := StringName(Farm.occupant(state, cell).get("id", &""))
	Farm.damage(state, cell, maxi(int(data["damage"]) * percent / 100, 1))
	one["chewing"] = Grid.index(cell)
	# **A live wire bites back** (task 0230): the bite lands all the same, and
	# whoever bit an electric fence stands stunned - the bite that brings it
	# down too, for the wire was live when it was bitten.
	stun(state, id, shock_ticks(state, StringName(one["kind"]), bitten))


## Whether this one is winding up a blow rather than walking. For the view,
## and for the asserts.
static func is_winding(state: Dictionary, id: int) -> bool:
	var one := Entities.get_one(state, id)
	if one.is_empty() or int(one.get("winding_at", -1)) < 0:
		return false
	var telegraph := int((GameData.ENEMIES[one["kind"]] as Dictionary)
		.get("telegraph_ticks", 0))
	return telegraph > 0 and int(one.get("chew_wait", 0)) > 0


## **Stun one for `ticks`** (task 0230): it stands where it is - neither
## walking nor biting - until the count runs out (`_walk()`). Refreshed and
## never stacked: a second shock while the first still holds keeps the
## longer. Any source may call it; an electric fence's bite does, and 0233's
## bell will.
static func stun(state: Dictionary, id: int, ticks: int) -> void:
	var one := Entities.get_one(state, id)
	if one.is_empty() or ticks <= 0:
		return
	one["stun"] = maxi(int(one.get("stun", 0)), ticks)


## Whether this one stands stunned. For the view, and for the asserts.
static func is_stunned(state: Dictionary, id: int) -> bool:
	return int(Entities.get_one(state, id).get("stun", 0)) > 0


## **How long a bite on `bitten` stuns a `kind`** (task 0230): the bitten
## thing's `stun_ticks` - none for anything without - a boss's
## `boss_stun_percent` of it, and on a farm short of power `Power.percent()`
## of that: never less than a tick while there is any stun at all.
static func shock_ticks(state: Dictionary, kind: StringName, bitten: StringName) -> int:
	var row: Dictionary = GameData.DEFENCES.get(bitten, {})
	var ticks := int(row.get("stun_ticks", 0))
	if ticks <= 0:
		return 0
	if bool((GameData.ENEMIES[kind] as Dictionary).get("is_boss", false)):
		var share := int(row.get("boss_stun_percent", 100))
		if share <= 0:
			return 0
		ticks = ticks * share / 100
	return maxi(ticks * Power.percent(state) / 100, 1)


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
## air, the fires, the flare - and the chill a frost zombie left on the
## towers (task 0251). None of those advance by day - only
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
	# The spit in the air too (task 0247): a glob left over would land on a
	# tower at dusk.
	(state["enemy_shots"] as Array).clear()
	(state["burning"] as Dictionary).clear()
	(state["stung"] as Dictionary).clear()
	Ability.put_out(state)
	Towers.thaw(state)
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
