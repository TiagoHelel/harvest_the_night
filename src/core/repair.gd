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


## What this cell charges, as a percentage of the base rate.
static func percent_at(state: Dictionary, cell: Vector2i) -> int:
	return GameData.HOUSE_REPAIR_PERCENT if is_house(state, cell) else 100


## What putting `hp` hit points back into **this cell** costs.
static func cost_at(state: Dictionary, cell: Vector2i, hp: int) -> Dictionary:
	var percent := percent_at(state, cell)
	var out := {}
	for res in GameData.sorted_names(cost_for(hp).keys()):
		# Never free because the arithmetic rounded down: a hit point that
		# was being paid for at all is paid for.
		out[res] = maxi(int(cost_for(hp)[res]) * percent / 100, 1)
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


## The most hit points the ledger could pay for right now at a given rate.
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
	return mini(damage_at(state, cell),
		affordable_hp(state, percent_at(state, cell)))


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
	if not Resources.pay(state, cost_at(state, cell, doing)):
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
