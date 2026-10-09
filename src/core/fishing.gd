class_name Fishing
extends RefCounted

## The pond, and the one thing on the farm you pay for with attention.

## `design.md` wants the day to have something in it that is not a resource
## loop, and the pond is it: a cast costs nothing, a miss costs nothing, and
## landing one is worth more per action than anything else the farm can do. The
## price is that you have to be looking at it.
##
## ## One line at a time
##
## The whole of fishing is `state["fishing"]`: empty when nobody is fishing, and
## otherwise one cast. Not a list, because a farmer has one rod and the moment
## there are two lines in the water the player is doing something else while
## they wait, which is exactly the attention the mechanic is charging for.
##
## ## Three moments
##
## - **Cast.** `Interact` hands over a water cell. The delay before the bite is
##   drawn here, once, from the run's RNG - so the same seed gives the same
##   wait and a replay lands the same fish on the same tick.
## - **Bite.** The float goes under and there are `window_ticks` to react. The
##   water offers `reel` instead of `fish`, so the highlight and the tooltip say
##   what the key will do rather than the player having to know.
## - **Reel, or not.** Reeling in the window pays. Letting it go pays nothing
##   and costs nothing - `design.md` is a cozy game, and a punishment for
##   looking away would make the pond a thing you avoid.
##
## ## Why reeling is not instant
##
## `water` (task 0029) is on `Interact.INSTANT` and fires off `interact_held`,
## the level - which is right for a chore you do while walking. Reeling takes
## the `interact` **edge** instead, through the ordinary action path, because a
## player holding the key down while they wait would land every fish without
## ever reacting to one, and the window is the entire mechanic.

## What one cast looks like before anything has happened to it.
const NOTHING: Dictionary = {}

enum { WAITING, BITING }


static func initial() -> Dictionary:
	return {"fishing": {}}


# ------------------------------------------------------------------- asking

## The cast in progress, or an empty Dictionary.
static func cast_of(state: Dictionary) -> Dictionary:
	return state["fishing"]


static func is_casting(state: Dictionary) -> bool:
	return not (state["fishing"] as Dictionary).is_empty()


## True while the float is under and the window is open.
static func is_biting(state: Dictionary) -> bool:
	var line: Dictionary = state["fishing"]
	return not line.is_empty() and int(line["stage"]) == BITING


## Where the line is, or off the farm when there is not one.
static func line_cell(state: Dictionary) -> Vector2i:
	var line: Dictionary = state["fishing"]
	if line.is_empty():
		return Vector2i(-1, -1)
	return Vector2i(int(line["cell"][0]), int(line["cell"][1]))


## How many ticks are left in whatever the line is doing. For the float in the
## water (task 0078) and for the tooltip.
static func ticks_left(state: Dictionary) -> int:
	var line: Dictionary = state["fishing"]
	return 0 if line.is_empty() else int(line["left"])


## What this water cell offers. `Interact` asks here rather than answering from
## a table, the same way soil asks `Farming`, so the highlight can say "reel"
## at the one moment it matters.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	if Farm.terrain_at(state, cell) != Farm.Terrain.WATER:
		return &""
	if not is_casting(state):
		return &"fish"
	if line_cell(state) != cell:
		return &""              # somebody else's water; one rod, one cell
	return &"reel" if is_biting(state) else &""


# -------------------------------------------------------------------- doing

## Put a line in. Called by `Interact.complete()` when a cast finishes.
##
## **The wait is drawn now, not counted down from a guess.** One draw per cast,
## here, is what makes the run replayable: a delay that came from anywhere else
## would be a fish that landed on a different tick the second time through.
static func begin(state: Dictionary, cell: Vector2i) -> bool:
	if is_casting(state):
		return false
	if Farm.terrain_at(state, cell) != Farm.Terrain.WATER:
		return false
	var table: Dictionary = GameData.FISHING
	var left := Rng.int_between(state["rng"], int(table["bite_min_ticks"]),
		int(table["bite_max_ticks"]))
	state["fishing"] = {
		"cell": [cell.x, cell.y],
		"stage": WAITING,
		"left": left,
		# **Decided at the cast, not at the reel.** Drawing it when the player
		# reels would mean a fast hand changed what was on the hook, and the
		# rare one would be a reflex prize rather than a lever. Since task
		# 0179 it is the species: this pond, this season, this hour.
		"species": draw(state, catchable(Farm.pond_of(state, cell),
			Calendar.season_id(Calendar.date(state)), Phases.clock_minute(state))),
	}
	return true


## **The species that can bite** (task 0179) in a pond, in a season, at a
## minute of the day's clock, in `FISH_SPECIES`' sorted order.
static func catchable(pond: StringName, season: StringName, minute: int,
		species: Dictionary = GameData.FISH_SPECIES) -> Array:
	var out: Array = []
	for id in GameData.sorted_names(species.keys()):
		var one: Dictionary = species[id]
		var hours: Array = one["hours"]
		if (one["ponds"] as Array).has(pond) and (one["seasons"] as Array).has(season) \
				and minute >= int(hours[0]) and minute <= int(hours[1]):
			out.append(id)
	return out


## One of them, from the run's RNG, weighted by `weight`. One draw, and only
## when there is a choice to make; the commonest of the pond's year when the
## water names no pond at all.
static func draw(state: Dictionary, ids: Array,
		species: Dictionary = GameData.FISH_SPECIES) -> StringName:
	if ids.is_empty():
		return GameData.CARP
	var total := 0
	for id in ids:
		total += int((species[id] as Dictionary)["weight"])
	var roll := Rng.int_between(state["rng"], 0, total - 1)
	for id in ids:
		roll -= int((species[id] as Dictionary)["weight"])
		if roll < 0:
			return StringName(id)
	return StringName(ids.back())


## Pull it in. Pays only inside the window; outside it there is nothing on the
## hook to pay for. The species drawn at the cast, one of it.
static func reel(state: Dictionary) -> Dictionary:
	if not is_biting(state):
		return {}
	var species := StringName((state["fishing"] as Dictionary).get("species", GameData.CARP))
	var caught := {species: 1}
	Resources.gain(state, caught)
	state["fishing"] = {}
	state["last_catch"] = {"species": species, "yield": caught.duplicate()}
	return caught


## Reel in nothing, on purpose. Walking away does this, and so does the cancel
## key: a line nobody is watching is a line that would still be there at dusk.
static func give_up(state: Dictionary) -> void:
	state["fishing"] = {}


## What came out of the water last, for the HUD. Empty before the first one.
static func last_catch(state: Dictionary) -> Dictionary:
	return state.get("last_catch", {})


# ------------------------------------------------------------------ the tick

## One tick of a line in the water. Called from `Sim._tick_day()`, which is the
## whole of "you cannot fish during a wave".
##
## `here` is where the farmer is standing. **Walking away gives up the cast** -
## the same rule as every other job on the farm, and without it a player could
## cast, go mining, and come back to a fish that had been waiting all day,
## which is the opposite of what the pond is charging for.
static func tick(state: Dictionary, here: Vector2i) -> void:
	var line: Dictionary = state["fishing"]
	if line.is_empty():
		return

	var cell := line_cell(state)
	if _away_from(here, cell):
		give_up(state)
		return

	line["left"] = int(line["left"]) - 1
	if int(line["left"]) > 0:
		return

	if int(line["stage"]) == WAITING:
		# The float goes under. From here the player has the window and no
		# more, and missing it is free.
		line["stage"] = BITING
		line["left"] = int((GameData.FISHING as Dictionary)["window_ticks"])
		return

	# The window closed. Nothing lost but the time, which is the point.
	give_up(state)


## Whether the farmer has left the water they were fishing. Orthogonal
## neighbours only: you fish from the tile you are standing on, facing in.
static func _away_from(here: Vector2i, cell: Vector2i) -> bool:
	var apart := (cell - here).abs()
	return apart.x + apart.y > 1
