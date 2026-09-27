class_name Ammo
extends RefCounted

## What the towers are shooting, and what happens when there is none left.
##
## `design.md` pillar 3 in its plainest form: **what you made today decides
## what tonight can do.** A mortar without gunpowder is not a mortar, it is a
## tube; a flamethrower without incendiary rounds is a pilot light.
##
## ## One pool, in the ledger
##
## There is no magazine per tower and there never will be. Ammunition is
## resources - gunpowder, incendiary rounds - held in `state["resources"]` like
## everything else, which gets three things for free and they are all things
## the design document asks for:
##
## - **What is left carries into the next night**, because nothing clears it.
## - **Towers compete for it.** Six mortars drain a pool six times as fast, so
##   how many you build is a decision about supply and not only about money.
## - It shows up in the inventory, the shop and on the HUD without a line of
##   code, because it is a resource and those already know about resources.
##
## ## Out of ammunition is a worse tower, never a dead one
##
## A silent tower is a tower the player stops looking at, and `design.md` does
## not do punishment mechanics. A tower with an empty pool keeps shooting: it
## reloads `EMPTY_RELOAD_PERCENT` slower and hits for `EMPTY_DAMAGE_PERCENT` of
## what it should, with none of what made it special - no burn, no splash. It
## is a slow basic shot, and it is enough to survive an easy night and nowhere
## near enough for a hard one.


## What a tower fires, or an empty Dictionary for one that fires nothing.
static func needed_by(id: StringName) -> Dictionary:
	var entry: Variant = GameData.DEFENCES.get(id, null)
	if entry == null:
		return {}
	return (entry as Dictionary).get("ammo", {})


static func uses_ammo(id: StringName) -> bool:
	return not needed_by(id).is_empty()


## How many more shots the pool holds for this kind of tower. A tower that
## needs nothing answers with a big number rather than zero: it is never short.
static func shots_left(state: Dictionary, id: StringName) -> int:
	var wants := needed_by(id)
	if wants.is_empty():
		return 1 << 30
	var fewest := -1
	for res in GameData.sorted_names(wants.keys()):
		var each := int(wants[res])
		if each <= 0:
			continue
		var can := Resources.amount(state, res) / each
		fewest = can if fewest < 0 else mini(fewest, can)
	return maxi(fewest, 0)


static func has_ammo(state: Dictionary, id: StringName) -> bool:
	return shots_left(state, id) > 0


## Take a round out of the pool. **True means a full shot**, false means the
## tower fires anyway and fires badly.
##
## All or nothing: a round that needs two things and can only be paid for in
## one is not a round, and `Resources.pay` refuses without taking anything.
static func spend(state: Dictionary, id: StringName) -> bool:
	var wants := needed_by(id)
	if wants.is_empty():
		return true             # nothing to spend, so nothing to run out of
	return Resources.pay(state, wants)


# --------------------------------------------------------- the weak shot

## What a shot does when the pool is empty.
static func weak_damage(full: int) -> int:
	return maxi(full * GameData.EMPTY_DAMAGE_PERCENT / 100, 1)


## How long a tower takes to reload when it is out. Longer, never for ever.
static func weak_reload(ticks: int) -> int:
	return maxi(ticks * GameData.EMPTY_RELOAD_PERCENT / 100, ticks)


## Every kind of ammunition in the game, in a fixed order. For the HUD and for
## the inventory of task 0036.
static func kinds() -> Array:
	var out: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		for res in GameData.sorted_names(needed_by(id).keys()):
			if not out.has(res):
				out.append(res)
	out.sort()
	return out


## What is in the pool of every kind, for the line on the HUD.
static func pool(state: Dictionary) -> Dictionary:
	var out := {}
	for res in kinds():
		out[res] = Resources.amount(state, res)
	return out
