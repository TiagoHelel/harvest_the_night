class_name Gathering
extends RefCounted

## Taking things out of the farm, and the farm putting them back.
##
## One implementation for everything you hit with a tool. A tree, a boulder and
## an ore seam differ only in their row of `GameData.GATHERING`: how long a
## swing takes, how many swings it takes, what it gives, what it leaves behind,
## and how long until it comes back. Task 0017 adds stone and task 0031 adds
## iron **without adding any code here** - that is the test of whether this was
## written generally enough, and the journal for 0017 should say whether it was.
##
## ## Nothing can be exhausted for good
##
## Every node that is used up schedules its own return. A player who chopped
## the whole wood on day 1 has a farm again on day 2, because a farm you can
## strip-mine into uselessness is a farm you stop playing on. The pending
## returns live in `state["regrowing"]` as a flat, sorted list - flat because it
## has to survive a save, and sorted because two runs of the same seed have to
## bring the same tree back on the same tick.
##
## ## Swings, not clicks
##
## A node has hit points measured in swings. The yield arrives when the last
## one lands rather than a little at a time: the totals are what the economy of
## task 0003 was balanced on, and dribbling them out would make "a day's mining
## buys one tower" depend on where the player stopped. Per-swing feedback is a
## job for the particles of task 0077, not for the ledger.

## One entry: `[cell index, ticks left, what comes back]`.
const PENDING_CELL := 0
const PENDING_TICKS := 1
const PENDING_ID := 2


static func initial() -> Dictionary:
	return {"regrowing": []}


## Is this something you can hit?
static func is_node(id: StringName) -> bool:
	return GameData.GATHERING.has(id)


## How many swings are left in it. Full when nobody has touched it.
static func swings_left(state: Dictionary, cell: Vector2i) -> int:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_node(on["id"]):
		return 0
	if on.has("hp"):
		return int(on["hp"])
	return int((GameData.GATHERING[on["id"]] as Dictionary)["hits"])


## One completed swing. Returns what it gave, which is nothing until the last.
##
## Called by `Interact.complete()`, so the player never has to know that a tree
## has hit points.
static func strike(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_node(on["id"]):
		return {}

	var id: StringName = on["id"]
	var node: Dictionary = GameData.GATHERING[id]

	var left := int(on.get("hp", int(node["hits"]))) - 1
	if left > 0:
		on["hp"] = left
		return {}

	# The last swing. It gives up everything it had and schedules its return.
	Farm.remove(state, cell)
	var leaves: StringName = node.get("leaves", &"")
	if leaves != &"":
		Farm.place(state, cell, {"id": leaves})

	_schedule(state, cell, id, int(node["regrow_ticks"]))

	var gained: Dictionary = node["yield"]
	Resources.gain(state, gained)
	return gained


## One tick of the farm growing back. Called from `Sim._tick_day()`.
##
## The night does not heal the wood: `design.md` is a game about a farm that is
## asleep after dark, and a tree quietly regrowing behind a firefight would be
## the one thing on the night map that was not about the night.
static func tick(state: Dictionary) -> void:
	var pending: Array = state["regrowing"]
	if pending.is_empty():
		return

	var ready: Array = []
	for entry in pending:
		entry[PENDING_TICKS] = int(entry[PENDING_TICKS]) - 1
		if int(entry[PENDING_TICKS]) <= 0:
			ready.append(entry)

	for entry in ready:
		pending.erase(entry)
		var cell := Grid.cell(int(entry[PENDING_CELL]))
		# Whatever was left behind - a stump - goes, and the real thing takes
		# its place. If the player built something on the cell in the meantime
		# they keep it, and the farm quietly gives up on that one.
		var on := Farm.occupant(state, cell)
		if not on.is_empty():
			if not _is_leftover(on["id"]):
				continue
			Farm.remove(state, cell)
		Farm.place(state, cell, {"id": StringName(entry[PENDING_ID])})


## How many things are waiting to come back, for the debug overlay and for the
## statistics of task 0069.
static func regrowing(state: Dictionary) -> int:
	return (state["regrowing"] as Array).size()


static func _schedule(state: Dictionary, cell: Vector2i, id: StringName,
		ticks: int) -> void:
	var pending: Array = state["regrowing"]
	var index := Grid.index(cell)
	for entry in pending:
		if int(entry[PENDING_CELL]) == index:
			return          # already coming back; do not queue it twice
	pending.append([index, maxi(ticks, 1), str(id)])
	# **Sorted by cell.** The list is walked every tick and appended to in
	# whatever order the player happens to chop things, and two runs of the
	# same seed have to bring the same tree back on the same tick.
	pending.sort_custom(func(a, b): return int(a[PENDING_CELL]) < int(b[PENDING_CELL]))


## A stump is the farm's, not the player's: it may be cleared away when the
## tree comes back. A tower on the same cell is not.
static func _is_leftover(id: StringName) -> bool:
	for node_id in GameData.GATHERING:
		if (GameData.GATHERING[node_id] as Dictionary).get("leaves", &"") == id:
			return true
	return false
