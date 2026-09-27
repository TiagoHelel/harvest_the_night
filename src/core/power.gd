class_name Power
extends RefCounted

## Energy: a rate, not a stockpile.
##
## `design.md` puts energy on the resource sheet, and it is the odd one out -
## everything else on that sheet is a number you have. **Energy is a number you
## can sustain.** There is no energy in the ledger and there never will be: a
## generator does not fill a tank, it supplies so much per tick, and the
## structures on the farm draw so much per tick while they run.
##
## ## Degraded, never dead
##
## Draw more than you supply and **everything slows down together**, in
## proportion. A tower reloads more slowly, the press takes longer over a batch.
## Nothing switches off and nothing has to be chosen between - which is the
## whole difference between a system that teaches you to plan and one that
## punishes you for building.
##
## The floor is `GameData.UNPOWERED_PERCENT`: with no supply at all, the farm
## still runs, at a quarter speed. A night that stopped dead because a generator
## ran out of oil would be a night the player watches rather than plays, and
## `design.md` is explicit that a bad night is a setback and not an ending.
##
## ## The farm has a trickle of its own
##
## `GameData.BASE_ENERGY` is what the place produces without a generator -
## enough for the press and a tower or two. Without it the first press would run
## at a quarter speed until the player built a generator, which needs oil, which
## needs the press: not a deadlock, but a miserable first hour. The generator is
## for when the farm grows past its own means, which is when it should be.
##
## ## Integer arithmetic, like everything else in here
##
## Power is a **percentage**, and a duration under it is `ticks * 100 / percent`.
## At full power that is exactly `ticks`, so nothing that was measured before
## this file existed moved by a tick.


static func initial() -> Dictionary:
	return {
		"power": {
			# {generator anchor cell index: ticks until the next fuel goes in}
			"burning": {},
			"supply": GameData.BASE_ENERGY,
			"draw": 0,
			"percent": 100,
			# What the two cached lists below were worked out for. The farm's
			# draw only changes when something goes up or comes down, which is
			# exactly what `grid_version` counts.
			"for_version": -1,
			# Generator anchors, as cell indices, in sorted order.
			"plants": [],
		},
	}


# ------------------------------------------------------------------- asking

## What the farm can supply per tick, generators included.
static func supply(state: Dictionary) -> int:
	return int((state["power"] as Dictionary)["supply"])


## What everything standing on the farm wants per tick.
static func draw(state: Dictionary) -> int:
	return int((state["power"] as Dictionary)["draw"])


## How well supplied the farm is, as a percentage, floored so that nothing ever
## reaches zero. 100 means everything runs at the speed its own table says.
static func percent(state: Dictionary) -> int:
	return int((state["power"] as Dictionary)["percent"])


static func is_short(state: Dictionary) -> bool:
	return percent(state) < 100


## How long something takes on this farm right now.
##
## **The one function the rest of the game calls.** A tower asks it how long to
## reload and the press asks it how long a batch takes; neither knows what a
## generator is. At full power it hands back exactly what it was given.
static func scaled_ticks(state: Dictionary, ticks: int) -> int:
	var p := percent(state)
	if p >= 100:
		return ticks
	return maxi(ticks * 100 / maxi(p, 1), ticks)


## Whether this generator is turning. For the HUD and for the asserts.
static func is_running(state: Dictionary, anchor: Vector2i) -> bool:
	return (((state["power"] as Dictionary)["burning"]) as Dictionary) \
		.has(Grid.index(anchor))


## Every generator on the farm, by its anchor cell, in a fixed order.
##
## Off the cache, which is rebuilt only when the farm changes shape. **This
## used to scan and sort the whole occupant table every tick**, along with
## `_total_draw` doing the same - and since `tick()` runs at 30Hz through every
## day and every night, it tripled the run time of the whole test suite the
## hour it was written. Same fix, and same reason, as the flow field in task
## 0025: ask what changed, not what is.
static func generators(state: Dictionary) -> Array:
	_refresh(state)
	var out: Array = []
	for idx in ((state["power"] as Dictionary)["plants"] as Array):
		out.append(Grid.cell(int(idx)))
	return out


## Rebuild the cached draw and generator list, if the farm has changed since
## they were built.
static func _refresh(state: Dictionary) -> void:
	var power: Dictionary = state["power"]
	var version := int(state["grid_version"])
	if int(power["for_version"]) == version:
		return
	power["for_version"] = version
	power["draw"] = _total_draw(state)
	power["plants"] = _find_generators(state)


static func _find_generators(state: Dictionary) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		if StringName(on["id"]) != GENERATOR:
			continue
		var anchor := Building.anchor_of(state, Grid.cell(int(idx)))
		var at := Grid.index(anchor)
		if seen.has(at):
			continue        # four cells of one generator are one generator
		seen[at] = true
		out.append(at)
	return out


const GENERATOR := &"generator"


# ------------------------------------------------------------------ the tick

## One tick of the farm's electricity.
##
## `burn` is false during the build phase, where the clock does not run: a
## generator quietly eating oil while the player decides where to put a wall
## would be a cost with no time attached to it.
static func tick(state: Dictionary, burn: bool = true) -> void:
	var power: Dictionary = state["power"]
	_refresh(state)
	var wanted := int(power["draw"])

	var made := GameData.BASE_ENERGY
	for anchor in generators(state):
		if _run(state, anchor, wanted, burn):
			made += int((GameData.BUILDINGS[GENERATOR]
				as Dictionary)["energy_output"])

	power["supply"] = made
	power["percent"] = 100 if wanted <= 0 \
		else clampi(made * 100 / wanted, GameData.UNPOWERED_PERCENT, 100)


## One generator. Returns whether it is turning this tick.
##
## **It only burns when something is drawing.** A generator running flat out to
## power an empty farm would be the player paying oil for nothing, and there is
## no tank for the energy to go into.
static func _run(state: Dictionary, anchor: Vector2i, wanted: int,
		burn: bool) -> bool:
	var burning: Dictionary = (state["power"] as Dictionary)["burning"]
	var idx := Grid.index(anchor)
	if wanted <= 0:
		burning.erase(idx)
		return false
	if not burn:
		return burning.has(idx)

	var entry: Dictionary = GameData.BUILDINGS[GENERATOR]
	var left := int(burning.get(idx, 0))
	if left > 0:
		burning[idx] = left - 1
		return true

	# A fresh tankful, if there is one to be had. No fuel, no supply - and the
	# farm drops to whatever it makes on its own, which is not nothing.
	if not Resources.pay(state, entry["fuel"]):
		burning.erase(idx)
		return false
	burning[idx] = int(entry["fuel_every_ticks"]) - 1
	return true


## What every structure on the farm wants, added up. Sorted, because this is
## folded into the determinism hash by way of everything it slows down.
static func _total_draw(state: Dictionary) -> int:
	var total := 0
	var counted: Dictionary = {}
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		var entry: Variant = Building.entry_of(id)
		if entry == null:
			continue        # a tree is not wired in
		# A generator supplies rather than draws, and four cells of one press
		# are one press.
		if id == GENERATOR:
			continue
		var anchor := Building.anchor_of(state, Grid.cell(int(idx)))
		var at := Grid.index(anchor)
		if counted.has(at):
			continue
		counted[at] = true
		total += int((entry as Dictionary).get("energy_draw", 0))
	return total
