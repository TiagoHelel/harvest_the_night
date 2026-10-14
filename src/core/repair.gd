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
## **'A full larder' discounts the house too** (task 0113). Its note says
## mending costs two fifths less, with no exception, and the survival branch
## that sells it is the house's own branch - a discount that skipped the one
## thing the branch exists to keep standing would be a note that lies.
##
## **And so does the house's tier** (task 0191): its `repair_discount` comes
## off what is left after the larder's, so the two compose rather than add.
##
## ## Whole means whole as it is now
##
## A repair puts back what the thing has when it is whole **today**: the house
## up to `Phases.house_full()` once 'stout timbers' has raised it, a tower up
## to its levelled hit points through `Building.entry_at()`. Until task 0113 both
## stopped at the base table's number, so a house of 140 mended to 100 and a
## level three gun tower to a level one's 60. A structure's price is shared
## over that same levelled maximum, so one full mend of anything costs
## `REPAIR_PERCENT` of what building it cost - its own materials, not the
## upgrades': the gunpowder that bought level three is not in its walls.
## **Unless the level rebuilt it** (task 0231): a wall rebuilt in hardwood is
## made of stone and hardwood, and mends in both (`Building.made_of()`).
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
## in hundredths of its own build cost, shared out over its levelled hit
## points. 'A full larder' takes its share off both.
static func per_hp_hundredths(state: Dictionary,
		cell: Vector2i) -> Dictionary:
	var out := {}
	var discount := Tech.bonus(state, "repair_percent", 100)
	if is_house(state, cell):
		var kept := 100 - House.tier_discount(state)
		for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
			out[res] = maxi(int(GameData.REPAIR_COST_PER_HP[res])
				* GameData.HOUSE_REPAIR_PERCENT * discount / 100 * kept / 100, 1)
		return out

	# **A ruin is priced as the thing it was** (task 0277): its id and level.
	var mended := _mended(state, cell)
	var entry := Building.entry_for(mended)
	if entry.is_empty():
		return out
	var full := maxi(int(entry.get("hp", 0)), 1)
	# What it is made of (task 0231): its price, and a rebuilding level's.
	var cost := Building.made_of_one(mended)
	for res in GameData.sorted_names(cost.keys()):
		# `cost * 100 * percent / 100 / full`, with the hundreds cancelled.
		# **At least one hundredth**, so nothing on the farm is free to keep
		# standing - a wall that cost nothing to hold would make a night a
		# contest of patience rather than of resources.
		out[res] = maxi(int(cost[res]) * GameData.REPAIR_PERCENT
			* discount / 100 / full, 1)
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


## How much is missing from whatever is on this cell, against what it has
## when whole today. The house answers for every cell it stands on.
static func damage_at(state: Dictionary, cell: Vector2i) -> int:
	var on := Farm.occupant(state, cell)
	if on.is_empty():
		# **A ruin is all of it missing** (task 0277), while the ground it
		# stood on is still there to raise it on.
		if Farm.ruin_at(state, cell).is_empty() \
				or not Farm.why_not_buildable(state, cell).is_empty():
			return 0
		return full_hp_at(state, cell)
	if StringName(on["id"]) == HOUSE:
		return maxi(Phases.house_full(state) - int(state["house_hp"]), 0)
	var full := full_hp_at(state, cell)
	return maxi(full - int(on.get("hp", full)), 0)


## What the thing on this cell has when it is whole: its levelled hit points,
## or 0 for nothing mendable. Not the house, whose answer is
## `Phases.house_full()`.
static func full_hp_at(state: Dictionary, cell: Vector2i) -> int:
	return int(Building.entry_for(_mended(state, cell)).get("hp", 0))


## **What is mended on this cell** (task 0277): what stands there, or the
## ruin of a defence that stood there - its id and its level - when nothing
## does.
static func _mended(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	return on if not on.is_empty() else Farm.ruin_at(state, cell)


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
	restore(state, cell, doing)
	return doing


## **Put up to `hp` hit points back into this cell, paying nothing** (task
## 0233): never past what it has whole today - the house up to
## `Phases.house_full()`, a structure its levelled hit points - and a wrecked
## coop or barn back on its first one. The one road a hit point comes back by:
## mending puts back what it has paid for through it, and the emergency
## repair puts its share back free. Returns how many went in.
static func restore(state: Dictionary, cell: Vector2i, hp: int) -> int:
	var on := Farm.occupant(state, cell)
	if hp > 0 and on.is_empty():
		return _raise(state, cell, hp)
	if hp <= 0 or on.is_empty():
		return 0
	if StringName(on["id"]) == HOUSE:
		var room := maxi(Phases.house_full(state) - int(state["house_hp"]), 0)
		state["house_hp"] = int(state["house_hp"]) + mini(hp, room)
		return mini(hp, room)

	var full := full_hp_at(state, cell)
	var was := int(on.get("hp", full))
	on["hp"] = mini(was + hp, full)
	# **A wrecked coop or barn comes back with its first hit point** (task
	# 0186): every cell of it at once, and the breakers' hunt field told, so
	# it is something to come for again.
	if Building.wrecks(StringName(on["id"])):
		Building.set_shared_hp(state, cell, int(on["hp"]))
		if was <= 0:
			Farm.touch(state)
	return maxi(int(on["hp"]) - was, 0)


## **A ruin raised** (task 0277): the defence back on its cell at its level,
## with the hit points mended into it - from the first one, as a wrecked coop
## comes back - and the field told, so it is a thing in the way again. Its
## lights, its power and its gun are the ones it had: nothing about it is new.
## Returns how many went in.
static func _raise(state: Dictionary, cell: Vector2i, hp: int) -> int:
	var ruin := Farm.ruin_at(state, cell)
	if ruin.is_empty():
		return 0
	var full := maxi(int(Building.entry_for(ruin).get("hp", 1)), 1)
	var standing := {"id": ruin["id"], "hp": mini(hp, full)}
	if int(ruin["level"]) > 1:
		standing["level"] = int(ruin["level"])
	if not Farm.place(state, cell, standing):
		return 0
	return int(standing["hp"])


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
