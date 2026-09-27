class_name Resources
extends RefCounted

## What the player has, and the only way it changes.
##
## Every gain and every cost in the game goes through here. Nothing else keeps
## a counter: the moment a second system starts tracking its own wood, the two
## disagree and the bug is a week old before anybody notices.
##
## ## Paying is all or nothing
##
## A cost is a Dictionary - `{WOOD: 4, STONE: 2}` - and `pay()` either takes
## every part of it or none. The obvious implementation, a loop of `spend()`,
## takes the wood, fails on the stone and leaves the player four wood poorer
## with nothing to show for it. `can_afford()` is checked across the whole cost
## first, and only then is anything deducted.
##
## ## A balance cannot go below zero
##
## An attempt clamps to zero and pushes an error. It does **not** behave
## differently in a debug build: the state has to be identical in every build,
## or the determinism guard and the browser-matches-desktop promise both stop
## meaning anything. The error is diagnostics, and `crash.gd` at task 0103 will
## pick it up. The clamp is the rule.

## The keys this subsystem owns. `State.create()` merges them in.
static func initial() -> Dictionary:
	var held := {}
	var gained := {}
	for id in GameData.RESOURCES:
		held[id] = int(GameData.STARTING_RESOURCES.get(id, 0))
		gained[id] = 0
	return {
		"held": held,
		# Everything ever added, never decremented - what the statistics screen
		# of task 0069 reports and what a balance sweep reads to find out where
		# a run's wood actually came from.
		"gained": gained,
	}


## How much of one thing the player has.
static func amount(state: Dictionary, id: StringName) -> int:
	return int((state["held"] as Dictionary).get(id, 0))


## Add to the balance. `n` below zero is a mistake at the call site: spending
## has its own function, and going through `add` with a negative would slip
## past the all-or-nothing rule.
static func add(state: Dictionary, id: StringName, n: int) -> void:
	if not _known(id, "add"):
		return
	if n < 0:
		push_error("Resources.add(%s, %d): use spend() to take things away"
			% [id, n])
		return
	var held: Dictionary = state["held"]
	held[id] = int(held.get(id, 0)) + n
	var gained: Dictionary = state["gained"]
	gained[id] = int(gained.get(id, 0)) + n


## Add several at once - a gathering yield, a recipe output, a night's reward.
static func gain(state: Dictionary, amounts: Dictionary) -> void:
	for id in _sorted(amounts):
		add(state, id, int(amounts[id]))


## Take one thing. False and no change when there is not enough.
static func spend(state: Dictionary, id: StringName, n: int) -> bool:
	if not _known(id, "spend"):
		return false
	if n < 0:
		push_error("Resources.spend(%s, %d): use add() to give things" % [id, n])
		return false
	var held: Dictionary = state["held"]
	var have := int(held.get(id, 0))
	if have < n:
		return false
	held[id] = have - n
	return true


## Whether the whole cost can be paid. Checked across every line before any of
## it is taken, which is what makes `pay()` atomic.
static func can_afford(state: Dictionary, cost: Dictionary) -> bool:
	var held: Dictionary = state["held"]
	for id in _sorted(cost):
		if not GameData.RESOURCES.has(id):
			push_error("Resources.can_afford: unknown '%s'" % id)
			return false
		if int(held.get(id, 0)) < int(cost[id]):
			return false
	return true


## Pay a whole cost, or nothing at all.
static func pay(state: Dictionary, cost: Dictionary) -> bool:
	if not can_afford(state, cost):
		return false
	var held: Dictionary = state["held"]
	for id in _sorted(cost):
		held[id] = int(held[id]) - int(cost[id])
	return true


## What a cost is short by, for the tooltip that says why a button is greyed.
static func missing(state: Dictionary, cost: Dictionary) -> Dictionary:
	var short := {}
	var held: Dictionary = state["held"]
	for id in _sorted(cost):
		var gap := int(cost[id]) - int(held.get(id, 0))
		if gap > 0:
			short[id] = gap
	return short


## Sorted keys, every time a Dictionary is walked.
##
## Iteration follows insertion order, so two costs holding the same things
## built in different orders would otherwise take them in different orders.
## Nothing here depends on the order today - but `add` writes to `gained`, and
## the day something in this file draws from the RNG the hash would start
## depending on how a literal was typed.
static func _sorted(d: Dictionary) -> Array:
	var keys := GameData.sorted_names(d.keys())
	return keys


static func _known(id: StringName, where: String) -> bool:
	if GameData.RESOURCES.has(id):
		return true
	push_error("Resources.%s: unknown resource '%s'" % [where, id])
	return false
