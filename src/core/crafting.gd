class_name Crafting
extends RefCounted

## Day resources becoming night structures.
##
## **The bridge the whole game rests on.** `design.md` pillar 3 is that a
## resource has two uses, and this is where the second one happens: wood and
## stone stop being things you sell and become a barricade that stands between
## a zombie and your house.
##
## ## Inputs are taken when the job starts
##
## Not when it finishes. Cancelling costs you the materials, which is the whole
## reason cancelling is a decision rather than a free undo - and it means the
## ledger can never be asked for something twice by two stations counting on
## the same wood.
##
## ## A job belongs to a station, not to the game
##
## `state["crafting"]` is keyed by the cell the workshop stands on, so the press
## and the kitchen of tasks 0032 and 0034 need no new machinery, and neither
## does a second workshop. One job per station until task 0037 puts a queue
## behind the same interface.
##
## ## Kits are not resources
##
## A barricade is not wood. It goes into `state["kits"]`, which build mode draws
## from, rather than into the ledger - a structure in the resource table would
## turn up in the shop's sell list and on the HUD, and it is neither of those
## things. A recipe whose output *is* a resource - oil, gunpowder, food - goes
## to the ledger instead, decided by what the output is rather than by which
## recipe made it.


static func initial() -> Dictionary:
	return {
		# {station cell index: {"recipe": id, "left": ticks, "total": ticks}}
		"crafting": {},
		# {structure id: how many are built and waiting to be placed}
		"kits": {},
		# What the workshop makes when you press interact. Task 0037 puts a
		# panel in front of this; until then there is one recipe worth making.
		"selected_recipe": &"barricade_kit",
	}


# ------------------------------------------------------------------- asking

## Every recipe a station can make, in a fixed order.
static func recipes_at(station: StringName) -> Array:
	var out: Array = []
	var ids: Array = GameData.RECIPES.keys()
	ids.sort()
	for id in ids:
		if (GameData.RECIPES[id] as Dictionary)["station"] == station:
			out.append(id)
	return out


## Whether the player could start this now. **A recipe they cannot afford is
## shown and refused, never hidden**: a menu that grows as you get richer is a
## menu that teaches nothing about what to go and get.
static func can_start(state: Dictionary, cell: Vector2i, recipe_id: StringName) -> bool:
	if busy(state, cell):
		return false
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	if recipe == null:
		return false
	var on := Farm.occupant(state, cell)
	if on.is_empty() or on["id"] != (recipe as Dictionary)["station"]:
		return false
	return Resources.can_afford(state, (recipe as Dictionary)["inputs"])


## What is short, for the tooltip that explains a greyed line.
static func missing(state: Dictionary, recipe_id: StringName) -> Dictionary:
	var recipe: Variant = GameData.RECIPES.get(recipe_id, null)
	if recipe == null:
		return {}
	return Resources.missing(state, (recipe as Dictionary)["inputs"])


static func busy(state: Dictionary, cell: Vector2i) -> bool:
	return (state["crafting"] as Dictionary).has(Grid.index(cell))


## The job at a station, or an empty Dictionary.
static func job(state: Dictionary, cell: Vector2i) -> Dictionary:
	return (state["crafting"] as Dictionary).get(Grid.index(cell), {})


## How many of a structure are built and waiting to be placed.
static func kits(state: Dictionary, id: StringName) -> int:
	return int((state["kits"] as Dictionary).get(id, 0))


## Take one off the pile. Build mode calls this; it refuses rather than going
## negative, the same way the ledger does.
static func take_kit(state: Dictionary, id: StringName) -> bool:
	var all: Dictionary = state["kits"]
	var have := int(all.get(id, 0))
	if have <= 0:
		return false
	if have == 1:
		all.erase(id)
	else:
		all[id] = have - 1
	return true


# -------------------------------------------------------------------- doing

## Begin a job. **Takes the inputs now.**
static func start(state: Dictionary, cell: Vector2i, recipe_id: StringName) -> bool:
	if not can_start(state, cell, recipe_id):
		return false
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	if not Resources.pay(state, recipe["inputs"]):
		return false            # all or nothing, as ever
	var ticks := maxi(int(recipe["ticks"]), 1)
	(state["crafting"] as Dictionary)[Grid.index(cell)] = {
		"recipe": recipe_id,
		"left": ticks,
		"total": ticks,
	}
	return true


## Give up on a job. **Nothing comes back** - the inputs went in when it
## started, and that is what makes stopping a choice.
static func cancel(state: Dictionary, cell: Vector2i) -> bool:
	var all: Dictionary = state["crafting"]
	var idx := Grid.index(cell)
	if not all.has(idx):
		return false
	all.erase(idx)
	return true


## One tick of everything on the farm making something. Called from
## `Sim._tick_day()`.
##
## It runs whether or not the player is looking at it - that is the semi-idle
## promise of `design.md` section 13, and it is why the queue of task 0037 is
## worth having.
static func tick(state: Dictionary) -> void:
	var all: Dictionary = state["crafting"]
	if all.is_empty():
		return

	# Sorted, so that two stations finishing on the same tick deliver in the
	# same order every run.
	var done: Array = []
	var keys: Array = all.keys()
	keys.sort()
	for idx in keys:
		var current: Dictionary = all[idx]
		current["left"] = int(current["left"]) - 1
		if int(current["left"]) <= 0:
			done.append(idx)

	for idx in done:
		var recipe_id: StringName = StringName((all[idx] as Dictionary)["recipe"])
		all.erase(idx)
		_deliver(state, recipe_id)


## Put the output where it belongs: a resource in the ledger, a structure on
## the pile of things waiting to be placed.
static func _deliver(state: Dictionary, recipe_id: StringName) -> void:
	var output: Dictionary = (GameData.RECIPES[recipe_id] as Dictionary)["output"]
	var ids: Array = output.keys()
	ids.sort()
	for id in ids:
		var n := int(output[id])
		if GameData.RESOURCES.has(id):
			Resources.add(state, id, n)
		else:
			var all: Dictionary = state["kits"]
			all[id] = int(all.get(id, 0)) + n
