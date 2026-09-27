class_name Repair
extends RefCounted

## Putting hit points back, and paying for them out of the ledger.
##
## This is what food is **for**. `design.md`'s resource table calls food the
## night's repair and heal currency, and until this file existed it was a thing
## you cooked and then sold, which made the kitchen a money press with a
## thematic hat on.
##
## ## What this task owns and what task 0053 does not get for free
##
## 0034 owns the **ledger path**: what a hit point costs, whether it can be
## paid for, and taking it. Task 0053 owns the night interaction on top of it -
## standing near the thing, taking time over it, being interrupted, and the
## worse rate for the house. So the functions here are deliberately about
## arithmetic and resources and know nothing about where the player is
## standing.
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

## What putting `hp` hit points back costs.
static func cost_for(hp: int) -> Dictionary:
	var out := {}
	if hp <= 0:
		return out
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		out[res] = int(GameData.REPAIR_COST_PER_HP[res]) * hp
	return out


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


## The most hit points the ledger could pay for right now, whatever is damaged.
static func affordable_hp(state: Dictionary) -> int:
	var most := -1
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		var each := int(GameData.REPAIR_COST_PER_HP[res])
		if each <= 0:
			continue
		var can := Resources.amount(state, res) / each
		most = can if most < 0 else mini(most, can)
	return maxi(most, 0)


## How many hit points could actually go back into this cell: what is missing,
## capped by what can be paid for.
static func max_affordable(state: Dictionary, cell: Vector2i) -> int:
	return mini(damage_at(state, cell), affordable_hp(state))


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
	if not Resources.pay(state, cost_for(doing)):
		return 0

	var on := Farm.occupant(state, cell)
	if StringName(on["id"]) == HOUSE:
		state["house_hp"] = int(state["house_hp"]) + doing
		return doing

	var entry: Dictionary = Building.entry_of(on["id"])
	var full := int(entry.get("hp", 0))
	on["hp"] = mini(int(on.get("hp", full)) + doing, full)
	return doing


## Repair as much of this cell as the ledger will cover. What a held key does.
static func apply_all(state: Dictionary, cell: Vector2i) -> int:
	return apply(state, cell, max_affordable(state, cell))
