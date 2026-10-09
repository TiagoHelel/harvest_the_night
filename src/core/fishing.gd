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
## - **Cast.** `Interact` hands over a water cell. Everything chance decides is
##   drawn here, once, from the run's RNG: the delay before the bite, the
##   species (task 0179) and where the green sits on the bar (task 0180) - so
##   the same seed and the same presses land the same fish on the same tick.
## - **Bite.** The float goes under and **the bar** opens: a marker sweeping
##   `bar_units` steps back and forth at the species' speed, a green the
##   species and the rod make wide. The water offers `reel`, so the highlight
##   says what the key is for.
## - **Strike, or not.** Each press is judged against the marker on the tick
##   it is spent: over the green it counts, and the species' one to three of
##   them land it. Too many outside, or the bar running out, loses the fish -
##   and nothing else: `design.md` is a cozy game, and a punishment for
##   looking away would make the pond a thing you avoid.
##
## ## A press is an edge, judged here
##
## `water` (task 0029) is on `Interact.INSTANT` and fires off `interact_held`,
## the level - right for a chore done walking. A strike is the `interact`
## **edge**, which `tick()` spends while the bar runs, before `Player` sees it:
## a held key strikes once, and the keyboard, the pad's A and a click (`Main`
## writes the same edge) are one press. Nothing after the cast is chance: the
## marker is a pure function of the ticks since the bite.
##
## ## The rod and the bait
##
## Task 0181. The rod's tier (`TOOLS` rod) shortens the bite range
## (`bite_percent`) and multiplies the weight of every species that is not
## common (`rare_percent`); the iron rod alone has the slot a bait goes in, and
## is the one a legendary takes (`takes_legendary`, 0182's gate). The bait on
## (`fishing_bait`) is spent at the cast and does the same two things by its
## own `BAIT_EFFECTS`; with no bait held, the line goes in plain.

## What one cast looks like before anything has happened to it.
const NOTHING: Dictionary = {}

enum { WAITING, BITING }


static func initial() -> Dictionary:
	return {
		"fishing": {},
		# **The assist** (task 0180): a wider green and a slower marker, a
		# rule and so the run's, written from the `gameplay/fishing_assist`
		# setting through `intent.fishing_assist` - core never reads the
		# setting. A top-level key; it shapes the next cast, not this one.
		"fishing_assist": false,
		# **Which bait is on** (task 0181): `&""` for none, or one of
		# `GameData.BAITS`. A top-level key, like `selected_seed`, chosen
		# from the day HUD through `step_bait`; only a rod with the bait slot
		# spends it, one at each cast.
		"fishing_bait": &"",
	}


# ------------------------------------------------------------------- asking

## The cast in progress, or an empty Dictionary.
static func cast_of(state: Dictionary) -> Dictionary:
	return state["fishing"]


static func is_casting(state: Dictionary) -> bool:
	return not (state["fishing"] as Dictionary).is_empty()


## True while the float is under and the bar is running (task 0180).
static func is_biting(state: Dictionary) -> bool:
	var line: Dictionary = state["fishing"]
	return not line.is_empty() and int(line["stage"]) == BITING


## **Where the marker is** on a line's bar: a triangle sweep across
## `bar_units` steps and back at `speed` steps a second, a pure function of
## the ticks since the bite - nothing about it is drawn after the cast.
static func marker(line: Dictionary) -> int:
	return marker_at(int(line.get("since", 0)), int(line.get("speed", 1)),
		int(GameData.FISHING["bar_units"]))


static func marker_at(since: int, speed: int, units: int) -> int:
	var travelled := since * speed / GameData.TICK_HZ
	var lap := travelled % maxi(2 * units, 1)
	return lap if lap < units else 2 * units - lap


## Which sweep across the bar the marker is on: 0 going right, 1 coming back,
## and so on. **One hit a sweep** - each crosses the green once, and mashing
## through one crossing is still one crossing.
static func pass_of(line: Dictionary) -> int:
	var travelled := int(line.get("since", 0)) * int(line.get("speed", 1)) / GameData.TICK_HZ
	return travelled / maxi(int(GameData.FISHING["bar_units"]), 1)


## Whether a line's marker is over its green right now.
static func in_zone(line: Dictionary) -> bool:
	var at := marker(line)
	return at >= int(line.get("zone_at", 0)) \
		and at < int(line.get("zone_at", 0)) + int(line.get("zone", 0))


## How wide a species' green is, in bar steps, with this farm's rod and its
## assist: the species' own, times the rod tier's `zone_percent`, plus the
## assist's steps - never past the bar.
static func zone_for(state: Dictionary, species: StringName) -> int:
	var table: Dictionary = GameData.FISHING
	var rod := int(ToolTiers.effects(state, &"rod").get("zone_percent", 100))
	var wide := int((GameData.FISH_SPECIES[species] as Dictionary)["zone"]) * rod / 100
	if bool(state.get("fishing_assist", false)):
		wide += int(table["assist_zone"])
	return clampi(wide, 1, int(table["bar_units"]))


## **The bait choices** (task 0181), in the order the HUD steps through
## them: none, then `GameData.BAITS`.
static func bait_choices() -> Array:
	var out: Array = [&""]
	for id in GameData.BAITS:
		out.append(StringName(id))
	return out


## Which bait is on: `&""` for none, or one of `GameData.BAITS`.
static func bait_of(state: Dictionary) -> StringName:
	var chosen := StringName(state.get("fishing_bait", &""))
	return chosen if bait_choices().has(chosen) else &""


## Put a bait on, or take it off with `&""`. Refuses anything that is not a
## bait, the way `Farming.select_seed` refuses what is not in season.
static func choose_bait(state: Dictionary, id: StringName) -> bool:
	if not bait_choices().has(id):
		return false
	state["fishing_bait"] = id
	return true


## Step the choice along `bait_choices()` and round again - what the HUD's
## bait button and Q/E or the shoulder buttons at the water send.
static func step_bait(state: Dictionary, step: int) -> StringName:
	var choices := bait_choices()
	var next := StringName(choices[posmod(choices.find(bait_of(state)) + step, choices.size())])
	state["fishing_bait"] = next
	return next


## Whether this farm's rod has the slot a bait goes in: the iron rod's
## `bait_slot` in `TOOLS`.
static func has_bait_slot(state: Dictionary) -> bool:
	return bool(ToolTiers.effects(state, &"rod").get("bait_slot", false))


## **The gate 0182 checks**: whether this farm's rod is one a legendary
## takes - the iron rod's `legendary` in `TOOLS`, and no other.
static func takes_legendary(state: Dictionary) -> bool:
	return bool(ToolTiers.effects(state, &"rod").get("legendary", false))


## The bait the next cast spends: the one on, when the rod has the slot and
## one is held; `&""` otherwise. **No bait is no effect, never a refusal** -
## the line goes in either way.
static func bait_for_cast(state: Dictionary) -> StringName:
	var id := bait_of(state)
	if id == &"" or not has_bait_slot(state) or Resources.amount(state, id) < 1:
		return &""
	return id


## How long the wait is, in percent of `FISHING`'s bite range: the rod tier's
## `bite_percent` times the bait's (`BAIT_EFFECTS`).
static func bite_percent(state: Dictionary, bait: StringName) -> int:
	var rod := int(ToolTiers.effects(state, &"rod").get("bite_percent", 100))
	var on := int((GameData.BAIT_EFFECTS.get(bait, {}) as Dictionary).get("bite_percent", 100))
	return maxi(rod * on / 100, 1)


## How much likelier than its weight anything not common is, in percent: the
## rod tier's `rare_percent` times the bait's.
static func rare_percent(state: Dictionary, bait: StringName) -> int:
	var rod := int(ToolTiers.effects(state, &"rod").get("rare_percent", 100))
	var on := int((GameData.BAIT_EFFECTS.get(bait, {}) as Dictionary).get("rare_percent", 100))
	return maxi(rod * on / 100, 1)


## A species' weight in the draw at a `rare_percent`: its own `weight`, and
## for anything not common, that times the percent. Never below one.
static func weight_of(id: StringName, rare: int,
		species: Dictionary = GameData.FISH_SPECIES) -> int:
	var one: Dictionary = species[id]
	var weight := int(one["weight"])
	if StringName(one.get("tier", &"common")) != &"common":
		weight = weight * rare / 100
	return maxi(weight, 1)


## How fast a species' marker runs, in steps a second, under the assist's
## pace when it is on.
static func speed_for(state: Dictionary, species: StringName) -> int:
	var speed := int((GameData.FISH_SPECIES[species] as Dictionary)["speed"])
	if bool(state.get("fishing_assist", false)):
		speed = speed * int(GameData.FISHING["assist_speed_percent"]) / 100
	return maxi(speed, 1)


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
	# **The bait goes on the hook as the line goes in** (task 0181): spent
	# here, once, by a rod with the slot - and with the rod it shortens the
	# wait and brings the rarer fish.
	var bait := bait_for_cast(state)
	if bait != &"":
		Resources.spend(state, bait, 1)
	var sooner := bite_percent(state, bait)
	var left := Rng.int_between(state["rng"],
		maxi(int(table["bite_min_ticks"]) * sooner / 100, 1),
		maxi(int(table["bite_max_ticks"]) * sooner / 100, 1))
	# **Decided at the cast, not at the reel.** Drawing it when the player
	# reels would mean a fast hand changed what was on the hook, and the rare
	# one would be a reflex prize rather than a lever. Since task 0179 it is
	# the species: this pond, this season, this hour.
	var species := draw(state, catchable(Farm.pond_of(state, cell),
		Calendar.season_id(Calendar.date(state)), Phases.clock_minute(state)),
		GameData.FISH_SPECIES, rare_percent(state, bait))
	# **And the bar** (task 0180): how wide its green is, how fast its marker,
	# how many hits - and where the green sits, the last draw a cast makes.
	var zone := zone_for(state, species)
	state["fishing"] = {
		"cell": [cell.x, cell.y],
		"stage": WAITING,
		"left": left,
		"species": species,
		"zone": zone,
		"zone_at": Rng.int_between(state["rng"], 0, int(table["bar_units"]) - zone),
		"speed": speed_for(state, species),
		"needs": int((GameData.FISH_SPECIES[species] as Dictionary)["hits"]),
		# What went on the hook, `&""` for nothing - for the HUD and the checks.
		"bait": bait,
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


## One of them, from the run's RNG, weighted by `weight` - and anything not
## common by `rare` percent of it (`weight_of`, task 0181). One draw, and only
## when there is a choice to make; the commonest of the pond's year when the
## water names no pond at all.
static func draw(state: Dictionary, ids: Array,
		species: Dictionary = GameData.FISH_SPECIES, rare: int = 100) -> StringName:
	if ids.is_empty():
		return GameData.CARP
	var total := 0
	for id in ids:
		total += weight_of(StringName(id), rare, species)
	var roll := Rng.int_between(state["rng"], 0, total - 1)
	for id in ids:
		roll -= weight_of(StringName(id), rare, species)
		if roll < 0:
			return StringName(id)
	return StringName(ids.back())


## **Land it.** One of the species drawn at the cast. Only while the bar runs;
## outside it there is nothing on the hook. `strike` calls it on the hit that
## completes the species' count.
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


## **One press while the bar runs** (task 0180), judged against where the
## marker is on this tick. Over the green it is a hit, and the species'
## `needs` of them land it; outside it is a miss, and one more than
## `misses_allowed` loses the fish. True for a hit. The line keeps
## `[tick since the bite, hit]` of the last press, for the view's flash.
static func strike(state: Dictionary) -> bool:
	if not is_biting(state):
		return false
	var line: Dictionary = state["fishing"]
	var hit := in_zone(line)
	# A second press on the sweep that already scored is spent and counts
	# for nothing: it waits for the next crossing.
	if hit and int(line.get("struck", -1)) == pass_of(line):
		return false
	line["last"] = [int(line.get("since", 0)), hit]
	if hit:
		line["struck"] = pass_of(line)
		line["hits"] = int(line.get("hits", 0)) + 1
		if int(line["hits"]) >= int(line.get("needs", 1)):
			reel(state)
		return true
	line["misses"] = int(line.get("misses", 0)) + 1
	if int(line["misses"]) > int(GameData.FISHING["misses_allowed"]):
		give_up(state)
	return false


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
	# **The assist follows its intent** (task 0180), the setting's level as
	# the UI writes it every frame; it shapes the next cast.
	var asked: Variant = (state["intent"] as Dictionary).get("fishing_assist", null)
	if asked != null:
		state["fishing_assist"] = bool(asked)
	var line: Dictionary = state["fishing"]
	if line.is_empty():
		return

	var cell := line_cell(state)
	if _away_from(here, cell):
		give_up(state)
		return

	if int(line["stage"]) == WAITING:
		line["left"] = int(line["left"]) - 1
		if int(line["left"]) > 0:
			return
		# The float goes under and the bar opens (task 0180), its marker at
		# the left end, `bar_ticks` to land the fish in.
		line["stage"] = BITING
		line["since"] = 0
		line["hits"] = 0
		line["misses"] = 0
		line["left"] = int((GameData.FISHING as Dictionary)["bar_ticks"])
		return

	# **A press on this tick is judged where the marker is now**, before it
	# moves on - which is where the view drew it - and spent here, so
	# `Player` never sees it: a strike starts no other job.
	var intent: Dictionary = state["intent"]
	if bool(intent.get("interact", false)):
		intent["interact"] = false
		strike(state)
		if not is_biting(state):
			return
	line["since"] = int(line.get("since", 0)) + 1
	line["left"] = int(line["left"]) - 1
	# The bar ran out. The fish is gone, and nothing else.
	if int(line["left"]) <= 0:
		give_up(state)


## Whether the farmer has left the water they were fishing. Orthogonal
## neighbours only: you fish from the tile you are standing on, facing in.
static func _away_from(here: Vector2i, cell: Vector2i) -> bool:
	var apart := (cell - here).abs()
	return apart.x + apart.y > 1
