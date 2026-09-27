class_name Repair
extends RefCounted

## Putting hit points back, and paying for them out of the ledger.
##
## This is what food is **for**. `design.md`'s resource table calls food the
## night's repair and heal currency, and until this file existed it was a thing
## you cooked and then sold, which made the kitchen a money press with a
## thematic hat on.
##
## ## The ledger, and then the night
##
## 0034 owned the **ledger path**: what a hit point costs, whether it can be
## paid for, and taking it. Task 0053 added the rest of it - the worse rate for
## the house, and how long a hit point takes.
##
## **Standing near it, taking time and being interrupted are not here**, and
## that is the point. Repair is a verb like chopping: `Interact` offers it on a
## cell that is damaged and can be paid for, `Player` runs it off the same
## action loop as everything else, and walking away stops it because walking
## away stops every job in the game. One hit point per work cycle, so the key
## being held down is what makes the wall come back.
##
## ## A structure is mended in its own materials, at a share of its price
##
## A wall is mended with stone and a tower with iron, at
## `GameData.REPAIR_PERCENT` of what building a new one costs, in proportion
## to how much of it is missing. That is the only rule that works across the
## whole table: task 0057 measured a flat price per hit point and found
## repairing dearer than **rebuilding** for every structure in the game, by
## between seven and fifty-six times.
##
## **The price is kept in hundredths and banked.** Four hundredths of a stone
## a hit point is not a payment, so the debt accumulates and a whole stone
## comes out of the ledger whenever one falls due - the same arrangement
## `Farming` uses for watering, and for the same reason: the rate stays what
## the designer set rather than whatever integer division left of it.
##
## ## The house costs more and takes longer
##
## One lever, `HOUSE_REPAIR_PERCENT`, applied to both. Patching a roof is not
## nailing a plank back onto a fence, and a player who wants the wall up before
## the next wave should be out there rather than indoors.
##
## ## All or nothing, per hit point
##
## `max_affordable()` works out how many hit points the ledger can cover and
## `apply()` never puts back more than that, so there is no way to end up with
## half a hit point paid for. Same rule as `Crafting`: the inputs go when the
## work starts and a refusal changes nothing at all.

## What can be repaired and how the hit points are held.
##
## The house is the odd one out: it is not an occupant with an `hp`, it is
## `state["house_hp"]`, because the night ends when it reaches zero and that is
## a fact about the run rather than about a cell.
const HOUSE := &"house"


# ------------------------------------------------------------------- asking

## What putting `hp` hit points back costs **at the base rate**, before
## anything about which cell it is. The UI shows this; the rules use
## `cost_at()`.
static func cost_for(hp: int) -> Dictionary:
	var out := {}
	if hp <= 0:
		return out
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		out[res] = int(GameData.REPAIR_COST_PER_HP[res]) * hp
	return out


## Whether this cell is the house, which is charged at the worse rate.
static func is_house(state: Dictionary, cell: Vector2i) -> bool:
	return StringName(Farm.occupant(state, cell).get("id", &"")) == HOUSE


## What this cell charges as a percentage of the base rate. Only the house has
## one; a structure is priced off its own build cost instead.
static func percent_at(state: Dictionary, cell: Vector2i) -> int:
	return GameData.HOUSE_REPAIR_PERCENT if is_house(state, cell) else 100


## What one hit point of this cell costs, **in hundredths of each resource**.
##
## The house answers in hundredths of its flat rate; everything else answers
## in hundredths of its own build cost, shared out over its hit points.
static func per_hp_hundredths(state: Dictionary,
		cell: Vector2i) -> Dictionary:
	var out := {}
	if is_house(state, cell):
		for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
			out[res] = int(GameData.REPAIR_COST_PER_HP[res]) \
				* GameData.HOUSE_REPAIR_PERCENT
		return out

	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return out
	var entry: Variant = Building.entry_of(StringName(on["id"]))
	if entry == null:
		return out
	var full := maxi(int((entry as Dictionary).get("hp", 0)), 1)
	var cost: Dictionary = (entry as Dictionary)["cost"]
	for res in GameData.sorted_names(cost.keys()):
		# `cost * 100 * percent / 100 / full`, with the hundreds cancelled.
		# **At least one hundredth**, so nothing on the farm is free to keep
		# standing - a wall that cost nothing to hold would make a night a
		# contest of patience rather than of resources.
		out[res] = maxi(int(cost[res]) * GameData.REPAIR_PERCENT
			* Tech.bonus(state, "repair_percent", 100) / 100 / full, 1)
	return out


## What putting `hp` hit points back into this cell costs in whole resources,
## **ignoring whatever is already banked**. For the tooltip and the tests.
static func cost_at(state: Dictionary, cell: Vector2i, hp: int) -> Dictionary:
	var out := {}
	if hp <= 0:
		return out
	var rates := per_hp_hundredths(state, cell)
	for res in GameData.sorted_names(rates.keys()):
		out[res] = int(rates[res]) * hp / 100
	return out


## How long one hit point takes to put back into this cell.
static func ticks_at(state: Dictionary, cell: Vector2i) -> int:
	return maxi(GameData.REPAIR_TICKS_PER_HP * percent_at(state, cell) / 100, 1)


## Whether there is something here to mend **and** the means to mend it.
##
## Both halves matter: `Interact` offers the verb off this, and a cell that
## offered "repair" with an empty larder would be the game telling the player a
## key does something it does not.
static func can_mend(state: Dictionary, cell: Vector2i) -> bool:
	return max_affordable(state, cell) > 0


## How much is missing from whatever is on this cell. The house answers for
## every cell it stands on.
static func damage_at(state: Dictionary, cell: Vector2i) -> int:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		return 0
	if StringName(on["id"]) == HOUSE:
		return maxi(GameData.HOUSE_HP - int(state["house_hp"]), 0)
	var entry: Variant = Building.entry_of(on["id"])
	if entry == null:
		return 0
	var full := int((entry as Dictionary).get("hp", 0))
	return maxi(full - int(on.get("hp", full)), 0)


## Whether there is anything here worth spending food on.
static func needs_repair(state: Dictionary, cell: Vector2i) -> bool:
	return damage_at(state, cell) > 0


## The most hit points the ledger could pay for at this cell's rate, counting
## what is already banked against it.
static func affordable_hp_at(state: Dictionary, cell: Vector2i) -> int:
	var rates := per_hp_hundredths(state, cell)
	if rates.is_empty():
		return 0
	var owing: Dictionary = state["repair_debt"]
	var most := -1
	for res in GameData.sorted_names(rates.keys()):
		var each := int(rates[res])
		if each <= 0:
			continue
		var purse := Resources.amount(state, res) * 100 \
			- int(owing.get(res, 0))
		var can := maxi(purse, 0) / each
		most = can if most < 0 else mini(most, can)
	return maxi(most, 0)


## The flat-rate question, which is now only the house's.
static func affordable_hp(state: Dictionary, percent: int = 100) -> int:
	var most := -1
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		var each := maxi(int(GameData.REPAIR_COST_PER_HP[res]) * percent / 100,
			1)
		if each <= 0:
			continue
		var can := Resources.amount(state, res) / each
		most = can if most < 0 else mini(most, can)
	return maxi(most, 0)


## How many hit points could actually go back into this cell: what is missing,
## capped by what can be paid for at this cell's rate.
static func max_affordable(state: Dictionary, cell: Vector2i) -> int:
	return mini(damage_at(state, cell), affordable_hp_at(state, cell))


# -------------------------------------------------------------------- doing

## Put hit points back and pay for them. Returns how many went in.
##
## **Nothing is put back that was not paid for**, and a refusal changes
## nothing: `Resources.pay` is all or nothing, and the amount is worked out
## before anything is spent.
static func apply(state: Dictionary, cell: Vector2i, hp: int) -> int:
	var doing := mini(hp, max_affordable(state, cell))
	if doing <= 0:
		return 0
	if not _charge(state, cell, doing):
		return 0

	var on := Farm.occupant(state, cell)
	if StringName(on["id"]) == HOUSE:
		state["house_hp"] = int(state["house_hp"]) + doing
		return doing

	var entry: Dictionary = Building.entry_of(on["id"])
	var full := int(entry.get("hp", 0))
	on["hp"] = mini(int(on.get("hp", full)) + doing, full)
	return doing


## Put `hp` hit points on the slate and take whatever whole resources fall
## due. False, and nothing charged, when the ledger will not cover them.
static func _charge(state: Dictionary, cell: Vector2i, hp: int) -> bool:
	var rates := per_hp_hundredths(state, cell)
	if rates.is_empty():
		return false
	var owing: Dictionary = state["repair_debt"]

	# The whole bill first: `Resources.pay()` is all or nothing, and a
	# half-paid repair would be hit points nobody paid for.
	var owed := {}
	var left := {}
	for res in GameData.sorted_names(rates.keys()):
		var debt := int(owing.get(res, 0)) + int(rates[res]) * hp
		owed[res] = debt / 100
		left[res] = debt % 100
	if not Resources.pay(state, owed):
		return false
	for res in GameData.sorted_names(left.keys()):
		owing[res] = int(left[res])
	return true


## What is owed in part-resources, by resource. For the tests, and for the
## tooltip of task 0089.
static func banked(state: Dictionary) -> Dictionary:
	return state["repair_debt"]


static func initial() -> Dictionary:
	return {
		# Hundredths of each resource owed but not yet worth taking. See the
		# note at the top of this file about banking.
		"repair_debt": {},
	}


## Repair as much of this cell as the ledger will cover. What a held key does.
static func apply_all(state: Dictionary, cell: Vector2i) -> int:
	return apply(state, cell, max_affordable(state, cell))
