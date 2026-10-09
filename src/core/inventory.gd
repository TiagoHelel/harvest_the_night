class_name Inventory
extends RefCounted

## Everything you own, in the inventory categories of the 1.0 plan.
##
## **This file holds nothing.** Every function here is a question about
## `state["resources"]` answered on the spot - there is no inventory in the
## state, no cached list, no second copy of any number. A panel that kept its
## own totals would be a panel that could disagree with the ledger, and the one
## the player believes is the one on screen.
##
## ## Why it is in `src/core/` at all
##
## Because *what* is shown and *in what order* is a rule, not a decoration: it
## has to be the same on every machine and it has to be derived from
## `GameData` rather than typed into a panel. The panel draws what this returns
## and makes no decisions of its own, which is also what makes "adding a
## resource makes it appear with no UI edit" true rather than hopeful.


## One row: a resource, how much of it there is, and what it fetches.
static func row(state: Dictionary, id: StringName) -> Dictionary:
	return {
		"id": id,
		"held": Resources.amount(state, id),
		"price": int(GameData.SELL_PRICE.get(id, 0)),
		"sellable": GameData.SELL_PRICE.has(id),
	}


## Every group, in order, each with its rows.
##
## Nothing is listed twice; empty categories are omitted. GROUP_OTHER only
## exposes invalid tables during development: GameData.validate refuses them.
static func groups(state: Dictionary) -> Array:
	var out: Array = []
	var placed: Dictionary = {}

	for entry in GameData.RESOURCE_GROUPS:
		var group: Dictionary = entry
		var rows: Array = []
		for id in (group["members"] as Array):
			if not GameData.RESOURCES.has(id):
				continue        # named in a group, taken out of the game
			if placed.has(id):
				continue        # named in two groups; the first one wins
			placed[id] = true
			rows.append(row(state, id))
		if not rows.is_empty():
			out.append({"name": StringName(group["name"]), "rows": rows})

	# The strays, in the order `RESOURCES` lists them.
	var rest: Array = []
	for id in GameData.RESOURCES:
		if not placed.has(id):
			rest.append(row(state, id))
	if not rest.is_empty():
		out.append({"name": GameData.GROUP_OTHER, "rows": rest})
	return out


## Every row, flat, in the order the panel draws them. For the asserts and for
## anything that wants the whole list without the headings.
static func rows(state: Dictionary) -> Array:
	var out: Array = []
	for group in groups(state):
		for r in ((group as Dictionary)["rows"] as Array):
			out.append(r)
	return out


## What the whole larder would fetch at the stall. The number the shop panel
## of task 0040 shows against what you are about to spend.
static func worth(state: Dictionary) -> int:
	var total := 0
	for r in rows(state):
		var line: Dictionary = r
		total += int(line["held"]) * int(line["price"])
	return total


## How many different things are actually held. For "your farm is empty" and
## for the statistics of task 0069.
static func kinds_held(state: Dictionary) -> int:
	var n := 0
	for r in rows(state):
		if int((r as Dictionary)["held"]) > 0:
			n += 1
	return n
