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
	var ids := GameData.sorted_names(GameData.DEFENCES.keys())
	for id in ids:
		if allowed_in_phase(state, id):
			out.append(id)
	return out


static func cost_of(id: StringName) -> Dictionary:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	return {} if entry == null else (entry as Dictionary)["cost"]


## Whether the phase lets this go down at all.
static func allowed_in_phase(state: Dictionary, id: StringName) -> bool:
	var phase := int(state["phase"])
	if phase == Phases.DAY or phase == Phases.PREPARATION:
		return true
	if phase != Phases.NIGHT:
		return false
	var entry: Variant = GameData.DEFENCES.get(id, null)
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
	if not GameData.DEFENCES.has(id):
		return "nothing selected"
	if not allowed_in_phase(state, id):
		return "not at night"
	var terrain_reason := Farm.why_not_buildable(state, cell)
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
	if on.is_empty() or not GameData.DEFENCES.has(on["id"]):
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

	var entry: Dictionary = GameData.DEFENCES[id]
	var occupant := {"id": id, "hp": int(entry.get("hp", 1))}
	if entry.has("lifetime_ticks"):
		occupant["expires"] = int(state["tick"]) + int(entry["lifetime_ticks"])
	return Farm.place(state, cell, occupant)


## Take it back up for a fraction of what it cost. Returns what came back.
static func sell(state: Dictionary, cell: Vector2i) -> Dictionary:
	var back := refund_for(state, cell)
	if back.is_empty() and Farm.occupant(state, cell).is_empty():
		return {}
	if not GameData.DEFENCES.has(Farm.occupant(state, cell).get("id", &"")):
		return {}
	if not Farm.remove(state, cell):
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
	if not GameData.DEFENCES.has(id):
		return
	var build: Dictionary = state["build"]
	build["selected"] = id
	build["active"] = true
