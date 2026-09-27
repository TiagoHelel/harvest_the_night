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
## and "+ $112" is not. **The money is itemised too**, into the fee, the
## bounty, and the two bonuses, so the screen can show the arithmetic rather
## than the answer.
##
## ## Intact, not merely upright
##
## The structure bonus is paid per thing that came through **without a
## scratch**. A wall at one hit point held the line and is worth the smaller
## standing bonus; the player who never let it be touched is the one being
## paid more, which is what "defending well pays more than barely holding"
## has to mean if it is to mean anything.
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
		"intact": _intact(state),
		# Where the money came from, for the screen. Empty on a loss.
		"money_from": {} if not survived else _money_from(state),
		"gained": {},
		"lost": {},
	}

	if survived:
		# **Technology first**, so that the points are in the ledger before
		# the itemised list is built from it - and so a night that has
		# already paid its technology says so in the same breath as paying
		# the money for the one being replayed.
		var points := Tech.award(state, int(state["night"]))
		for id in _sorted(lines):
			Resources.add(state, id, int(lines[id]))
		if points > 0:
			lines[GameData.TECH] = points
		summary["gained"] = lines
		summary["tech"] = points
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

	# Money, itemised in `_money_from()` and added up here, so that the total
	# and the breakdown cannot drift apart: there is one place that knows.
	var money := 0
	var from := _money_from(state)
	for line in _sorted(from):
		money += int(from[line])
	out[GameData.MONEY] = money

	# Materials, so that a night pays towards the next one's defences and not
	# only towards the shop.
	for id in _sorted(table["resources"] as Dictionary):
		var base := int((table["resources"] as Dictionary)[id])
		var extra := int((table["resources_per_night"] as Dictionary).get(id, 0))
		out[id] = base + extra * (night - 1)
	return out


## Where the money came from. **The one place that knows**, so the total on
## the ledger and the lines on the screen are the same arithmetic.
static func _money_from(state: Dictionary) -> Dictionary:
	var table: Dictionary = GameData.REWARDS
	var night := int(state["night"])
	var out := {
		"for the night": int(table["base_money"])
			+ int(table["money_per_night"]) * night,
		"bounty": 0,
		"nothing touched": 0,
		"still standing": 0,
		"the house untouched": 0,
	}
	for kind in _sorted(state["killed_by_kind"] as Dictionary):
		var data: Variant = GameData.ENEMIES.get(kind, null)
		if data != null:
			out["bounty"] = int(out["bounty"]) 				+ int((data as Dictionary)["reward"]) 				* int((state["killed_by_kind"] as Dictionary)[kind])

	var intact := _intact(state)
	out["nothing touched"] = int(table["intact_structure_bonus"]) * intact
	out["still standing"] = int(table["standing_structure_bonus"]) \
		* maxi(_standing(state) - intact, 0)
	if int(state["house_hp"]) >= GameData.HOUSE_HP:
		out["the house untouched"] = int(table["house_untouched_bonus"])
	return out


## A share of everything, rounded down. **What it spares is a lever**:
## `design.md` says a loss costs a day, not the run, and which of money and
## technology that protects is the table's business rather than this
## function's. Both were declared and read by nothing until task 0061.
static func _loss(state: Dictionary) -> Dictionary:
	var out := {}
	for id in GameData.RESOURCES:
		if id == GameData.ENERGY:
			continue        # a rate, not a stock: there is nothing to take
		if id == GameData.MONEY and GameData.DEFEAT_KEEPS_MONEY:
			continue
		if GameData.DEFEAT_KEEPS_TECH and _is_tech(id):
			continue
		var held := Resources.amount(state, id)
		var gone := held * GameData.DEFEAT_LOSS_PERCENT / 100
		if gone > 0:
			out[id] = gone
	return out


## Whether this is the technology currency.
##
## **It does not exist yet** - task 0062 adds it - so this answers by name
## against whatever is in the resource table rather than against a constant
## that is not there. `DEFEAT_KEEPS_TECH` was declared with the table and read
## by nothing; when 0062 lands, this is already waiting for it.
static func _is_tech(id: StringName) -> bool:
	return id == &"tech"


## How many of the player's own structures came through without a scratch.
static func _intact(state: Dictionary) -> int:
	var n := 0
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var entry: Variant = GameData.DEFENCES.get(on["id"], null)
		if entry == null:
			continue
		if int(on.get("hp", 0)) >= int((entry as Dictionary).get("hp", 0)):
			n += 1
	return n


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
