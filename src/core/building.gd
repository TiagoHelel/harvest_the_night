class_name Building
extends RefCounted

## Putting things on the farm, and taking them off again.
##
## ## What a structure costs, and the two ways to pay
##
## `GameData.DEFENCES[id]["cost"]` is the price, full stop. There are two ways
## to pay it:
##
## - **On the spot.** The materials come out of the ledger as it is placed.
## - **In advance.** The workshop turns the same materials into a kit, and
##   placing spends the kit instead.
##
## A kit is that cost already paid, which is why the recipe's inputs and the
## structure's cost are the same numbers and `GameData.validate()` insists on
## it. Banking kits during the day is how a player puts a wall up at night,
## when there is nothing to gather and no time to gather it.
##
## ## The phase decides what may go down
##
## Day and preparation: anything. Night: only what its own entry says may go
## down at night, which is the barricade and nothing else. That is what makes
## the barricade the emergency answer `design.md` section 8 asks for rather
## than a cheaper wall.
##
## ## Build mode is a state
##
## Like the shop panel, it lives in `state["build"]` so that the autoplayer of
## task 0067 can build a farm without a mouse, and so that "what is selected"
## survives a save.


static func initial() -> Dictionary:
	return {
		"build": {
			"active": false,
			"selected": &"",
			# **How many of each thing have gone down tonight.**
			# `{id: count}`, cleared when a night begins.
			#
			# `per_night_limit` has been in `DEFENCES` since the table was
			# written and nothing read it - the barricade could be thrown down
			# as fast as the wood held out, which is a wall you rebuild rather
			# than an emergency answer. Task 0047 is where the number starts
			# meaning something.
			"placed_tonight": {},
		},
	}


# ------------------------------------------------------------------- asking

## Everything that could go on the farm right now, in a fixed order.
##
## **Everything, not only what is affordable.** A palette that grew as you got
## richer would teach nothing about what to go and get; the panel greys what
## cannot be paid for and says why.
static func catalogue(state: Dictionary) -> Array:
	var out: Array = []
	for id in placeable_ids():
		if allowed_in_phase(state, id):
			out.append(id)
	return out


## Everything that can be put on the farm: the defences, and since task 0032
## the production buildings too.
##
## **Two tables and one placer.** A press is not a tower and its entry lives
## with the other buildings, but "can I put this here, can I pay for it, what
## does it cost to take up again" is the same question for both - and the day
## build mode had a second code path for buildings is the day the two answers
## start disagreeing.
static func placeable_ids() -> Array:
	return GameData.sorted_names(GameData.DEFENCES.keys()) \
		+ GameData.sorted_names(GameData.BUILDINGS.keys())


## The entry for anything placeable, from whichever table holds it.
static func entry_of(id: StringName) -> Variant:
	if GameData.DEFENCES.has(id):
		return GameData.DEFENCES[id]
	if GameData.BUILDINGS.has(id):
		return GameData.BUILDINGS[id]
	return null


static func is_placeable(id: StringName) -> bool:
	return entry_of(id) != null


static func cost_of(id: StringName) -> Dictionary:
	var entry: Variant = entry_of(id)
	return {} if entry == null else (entry as Dictionary)["cost"]


## How many tiles it covers. Towers are one; a press is two by two.
static func size_of(id: StringName) -> Vector2i:
	var entry: Variant = entry_of(id)
	if entry == null:
		return Vector2i.ONE
	return (entry as Dictionary).get("size", Vector2i.ONE)


## Every cell a thing of this size would cover, anchored at its top left.
##
## The farmhouse has worked this way since the map was drawn - nine cells each
## holding `{"id": "house"}` - so a multi-tile building is not a new idea here,
## only a placeable one. Each cell also carries the anchor, so that four cells
## of press are one press and not four.
static func footprint(id: StringName, origin: Vector2i) -> Array:
	var size := size_of(id)
	var out: Array = []
	for dy in size.y:
		for dx in size.x:
			out.append(origin + Vector2i(dx, dy))
	return out


## Which cell of a multi-tile building is the one that owns it. Jobs, hit
## points and selling all key off this, so standing at either half of a press
## is standing at the same press.
static func anchor_of(state: Dictionary, cell: Vector2i) -> Vector2i:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return cell
	var at: Variant = on.get("anchor", null)
	if at == null:
		return cell
	var pair: Array = at
	return Vector2i(int(pair[0]), int(pair[1]))


## How many more of this may go down tonight. A big number for anything with
## no limit, so callers do not have to know which is which.
static func left_tonight(state: Dictionary, id: StringName) -> int:
	var entry: Variant = entry_of(id)
	if entry == null:
		return 0
	var limit := int((entry as Dictionary).get("per_night_limit", 0))
	if limit <= 0:
		return 1 << 30          # no limit declared, so no limit applied
	return maxi(limit - placed_tonight(state, id), 0)


## How many of this have gone down since the night began.
static func placed_tonight(state: Dictionary, id: StringName) -> int:
	return int((((state["build"] as Dictionary)["placed_tonight"])
		as Dictionary).get(id, 0))


## A new night, a fresh allowance. Called from `Phases.begin_night()`.
static func forget_tonight(state: Dictionary) -> void:
	(state["build"] as Dictionary)["placed_tonight"] = {}


## Whether the phase lets this go down at all.
static func allowed_in_phase(state: Dictionary, id: StringName) -> bool:
	var phase := int(state["phase"])
	if phase == Phases.DAY or phase == Phases.PREPARATION:
		return true
	if phase != Phases.NIGHT:
		return false
	# A production building is a day job. Nothing in `BUILDINGS` carries
	# `placeable_at_night`, so this falls out rather than being spelled out.
	var entry: Variant = entry_of(id)
	return entry != null \
		and bool((entry as Dictionary).get("placeable_at_night", false))


## Whether it can be paid for, by kit or by ledger.
static func affordable(state: Dictionary, id: StringName) -> bool:
	if Crafting.kits(state, id) > 0:
		return true
	return Resources.can_afford(state, cost_of(id))


static func can_place(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	return why_not(state, id, cell).is_empty()


## Why it will not go there, in words, for the red ghost and the tooltip.
## Empty when it will.
static func why_not(state: Dictionary, id: StringName, cell: Vector2i) -> String:
	if not is_placeable(id):
		return "nothing selected"
	if not allowed_in_phase(state, id):
		return "not at night"
	# **The allowance, before the money.** Being told "you have used your five"
	# is a different sentence from "you are short two wood", and the first one
	# is the one that is true.
	if left_tonight(state, id) <= 0:
		return "%d a night, and that was the last" % int(
			(entry_of(id) as Dictionary).get("per_night_limit", 0))
	# **Every cell it would cover**, not only the one under the cursor. A press
	# hanging half off the farm is the bug this stops.
	for at in footprint(id, cell):
		var terrain_reason := Farm.why_not_buildable(state, at)
		if not terrain_reason.is_empty():
			return terrain_reason
	if not affordable(state, id):
		var short := Resources.missing(state, cost_of(id))
		var parts: Array = []
		var keys := GameData.sorted_names(short.keys())
		for res in keys:
			parts.append("%d %s" % [short[res], res])
		return "short " + ", ".join(parts)
	return ""


## What selling the thing on this cell would give back. Empty when there is
## nothing there, or when it is not the player's to sell.
static func refund_for(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_placeable(on["id"]):
		return {}
	return refund_for_cost(cost_of(on["id"]))


## What a given price gives back. Separate from the cell so that the rule can
## be checked against every structure at once rather than one at a time.
static func refund_for_cost(cost: Dictionary) -> Dictionary:
	var back := {}
	var keys := GameData.sorted_names(cost.keys())
	for res in keys:
		# **Rounded down**, so the round trip is always a loss. Rounding up on
		# a cheap structure would make place-and-sell a money printer, which is
		# the sort of thing nobody finds until somebody does.
		var n := int(floor(float(cost[res]) * GameData.SELL_BACK_FRACTION))
		if n > 0:
			back[res] = n
	return back


# -------------------------------------------------------------------- doing

## Put it down. Pays with a kit if there is one, and out of the ledger if not.
static func place(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	if not can_place(state, id, cell):
		return false

	# The kit first: it is the cost already paid, and a player who banked one
	# during the day meant to use it.
	if not Crafting.take_kit(state, id):
		if not Resources.pay(state, cost_of(id)):
			return false

	var entry: Dictionary = entry_of(id)
	var occupant := {"id": id, "hp": int(entry.get("hp", 1))}
	if entry.has("lifetime_ticks"):
		occupant["expires"] = int(state["tick"]) + int(entry["lifetime_ticks"])

	# Counted the moment it goes down, not when it comes up: a barricade that
	# was chewed through still used one of tonight's five.
	var tally: Dictionary = (state["build"] as Dictionary)["placed_tonight"]
	tally[id] = int(tally.get(id, 0)) + 1

	var cells := footprint(id, cell)
	if cells.size() > 1:
		occupant["anchor"] = [cell.x, cell.y]
	for at in cells:
		if not Farm.place(state, at, occupant):
			# Half a press is worse than none. Take back whatever went down.
			for done in cells:
				if done == at:
					break
				Farm.remove(state, done)
			Resources.gain(state, cost_of(id))
			return false
	return true


## Take it back up for a fraction of what it cost. Returns what came back.
static func sell(state: Dictionary, cell: Vector2i) -> Dictionary:
	var id: StringName = Farm.occupant(state, cell).get("id", &"")
	if not is_placeable(id):
		return {}
	var back := refund_for(state, cell)
	# Selling any tile of a building sells the building, and takes every tile
	# of it with it.
	var at := anchor_of(state, cell)
	var removed := false
	for part in footprint(id, at):
		if Farm.occupant(state, part).get("id", &"") == id:
			removed = Farm.remove(state, part) or removed
	if not removed:
		return {}
	Resources.gain(state, back)
	return back


# ------------------------------------------------------------------ the mode

static func is_active(state: Dictionary) -> bool:
	return bool((state["build"] as Dictionary)["active"])


static func selected(state: Dictionary) -> StringName:
	return StringName((state["build"] as Dictionary)["selected"])


static func set_active(state: Dictionary, active: bool) -> void:
	var build: Dictionary = state["build"]
	build["active"] = active
	if not active:
		build["selected"] = &""
	elif build["selected"] == &"":
		var options := catalogue(state)
		build["selected"] = options[0] if not options.is_empty() else &""


## One tick of build mode. Called from every phase that allows building.
##
## The UI writes where the player is pointing and what they asked for; this
## decides. Same road as every other input, so the autoplayer of task 0067
## builds a farm by writing three fields.
static func tick(state: Dictionary) -> void:
	expire(state)

	var intent: Dictionary = state["intent"]
	var place_asked := bool(intent.get("build_place", false))
	var sell_asked := bool(intent.get("build_sell", false))
	intent["build_place"] = false
	intent["build_sell"] = false
	if not (place_asked or sell_asked):
		return

	var at: Array = intent.get("build_cell", [-1, -1])
	var cell := Vector2i(int(at[0]), int(at[1]))
	if not Grid.in_bounds(cell):
		return

	if sell_asked:
		sell(state, cell)
		return
	if is_active(state):
		place(state, selected(state), cell)


## Anything with a lifetime takes itself away when it runs out.
##
## The barricade is the only one today, and it is what stops it quietly
## becoming a cheaper wall.
static func expire(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	var now := int(state["tick"])
	var gone: Array = []
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		if on.has("expires") and now >= int(on["expires"]):
			gone.append(idx)
	for idx in gone:
		occupants.erase(idx)
	if not gone.is_empty():
		state["grid_version"] = int(state["grid_version"]) + 1


static func select(state: Dictionary, id: StringName) -> void:
	if not is_placeable(id):
		return
	var build: Dictionary = state["build"]
	build["selected"] = id
	build["active"] = true
