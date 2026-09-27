class_name Rewards
extends RefCounted

## What a night pays, and what losing one costs.
##
## `design.md` section 12. **The payout is computed from the night, not written
## down per night**, so task 0060 can author ten of them without anybody
## maintaining a parallel table of prizes - and so a player can work out roughly
## what tonight is worth before they press the button.
##
## The itemised list is kept rather than only the total, because the result
## screen has to be able to say *why* - "you were paid more because nothing you
## built came down" is a sentence that changes how the next night gets built,
## and "+ $112" is not.
##
## Losing costs a share of the stock and nothing else. `design.md` is explicit
## that a loss costs a day, not the run: money and technology survive, the
## structures that were destroyed stay destroyed, and the farm is still there
## in the morning.


## Work out the payout, hand it over, and leave the itemised list in the state
## for the result screen to read.
static func settle(state: Dictionary, survived: bool) -> Dictionary:
	var lines := _lines(state, survived)
	var summary := {
		"night": int(state["night"]),
		"survived": survived,
		"killed": int(state["killed"]),
		"breaches": int(state["breaches"]),
		"house_hp": int(state["house_hp"]),
		"structures": _standing(state),
		"gained": {},
		"lost": {},
	}

	if survived:
		for id in _sorted(lines):
			Resources.add(state, id, int(lines[id]))
		summary["gained"] = lines
	else:
		for id in _sorted(lines):
			Resources.spend(state, id, int(lines[id]))
		summary["lost"] = lines

	state["payout"] = summary
	return summary


## What the last night paid or cost. Empty before the first one ends.
static func last(state: Dictionary) -> Dictionary:
	return state.get("payout", {})


static func initial() -> Dictionary:
	return {"payout": {}}


# ------------------------------------------------------------------- the sums

## What tonight is worth, before it is paid. The result screen shows this and
## the shop-facing arithmetic of task 0068 measures it.
static func preview(state: Dictionary, survived: bool) -> Dictionary:
	return _lines(state, survived)


static func _lines(state: Dictionary, survived: bool) -> Dictionary:
	if not survived:
		return _loss(state)

	var night := int(state["night"])
	var table: Dictionary = GameData.REWARDS
	var out := {}

	# Money: a flat fee plus a bit more every night, plus what was killed, plus
	# the two bonuses that reward defending well rather than merely surviving.
	var money := int(table["base_money"]) + int(table["money_per_night"]) * night
	for kind in _sorted(state["killed_by_kind"] as Dictionary):
		var data: Variant = GameData.ENEMIES.get(kind, null)
		if data != null:
			money += int((data as Dictionary)["reward"]) \
				* int((state["killed_by_kind"] as Dictionary)[kind])
	money += int(table["intact_structure_bonus"]) * _standing(state)
	if int(state["house_hp"]) >= GameData.HOUSE_HP:
		money += int(table["house_untouched_bonus"])
	out[GameData.MONEY] = money

	# Materials, so that a night pays towards the next one's defences and not
	# only towards the shop.
	for id in _sorted(table["resources"] as Dictionary):
		var base := int((table["resources"] as Dictionary)[id])
		var extra := int((table["resources_per_night"] as Dictionary).get(id, 0))
		out[id] = base + extra * (night - 1)
	return out


## A fraction of everything, rounded down. Money and technology are untouched:
## `design.md` says a loss costs a day, not the run.
static func _loss(state: Dictionary) -> Dictionary:
	var out := {}
	for id in GameData.RESOURCES:
		if id == GameData.MONEY or id == GameData.ENERGY:
			continue
		var held := Resources.amount(state, id)
		var gone := int(floor(float(held) * GameData.DEFEAT_RESOURCE_LOSS))
		if gone > 0:
			out[id] = gone
	return out


## How many of the player's own structures are still standing. What the
## "defended well" bonus is paid on.
static func _standing(state: Dictionary) -> int:
	var n := 0
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		if GameData.DEFENCES.has((occupants[idx] as Dictionary)["id"]):
			n += 1
	return n


static func _sorted(d: Dictionary) -> Array:
	var keys := GameData.sorted_names(d.keys())
	return keys
