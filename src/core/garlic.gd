class_name Garlic
extends RefCounted

## **The garlic braid** (task 0228; the plan's sections 3.1 and 5): hung on a
## post, it makes the ground round it somewhere zombies would rather walk
## round, and slows the ones that come through anyway.
##
## ## A cost, and a speed, from one pass
##
## Repelling is a price on the ground, not a wall: every cell within a
## braid's `repel_tiles` costs its `repel_cost` more to enter, in the priced
## field and the open one alike, so a wave - runners too - bends round it
## where the way round is cheaper, and walks through where it is not. The
## ones inside walk at its `repel_speed_percent`. Both come off the pass of
## entry costs `Pathing` already makes (`Pathing._repel`), which also keeps
## the slow as a per-cell array beside the fields: a walker reads one entry,
## never a search.
##
## ## It wears out
##
## Fresh the first night, wilted - at its `wilted_percent` of both - the
## second, spent after: A040's three states, kept on the occupant as the
## nights it has seen begin (`nights`) and moved on at `Phases.begin_night`.
## A braid put down mid-wave is in its first night already. **A spent braid
## does nothing and stays**, drawn spent, until it is sold - for nothing, its
## garlic used up (`Building.refund_for`).

const FRESH := &"fresh"
const WILTED := &"wilted"
const SPENT := &"spent"


## Whether a defence repels: a row with `repel_tiles`.
static func repels(id: StringName) -> bool:
	return int((GameData.DEFENCES.get(id, {}) as Dictionary).get("repel_tiles", 0)) > 0


## The state of one on the farm, by the nights it has seen begin: the first
## fresh - and the build step before it - the second wilted, any after spent.
static func state_of(on: Dictionary) -> StringName:
	var nights := int(on.get("nights", 0))
	if nights <= 1:
		return FRESH
	if nights == 2:
		return WILTED
	return SPENT


## How strong it is, in percent: all of it fresh, its row's `wilted_percent`
## wilted, nothing spent - and nothing for what does not repel.
static func strength(on: Dictionary) -> int:
	var row: Dictionary = GameData.DEFENCES.get(StringName(on.get("id", &"")), {})
	if int(row.get("repel_tiles", 0)) <= 0:
		return 0
	match state_of(on):
		FRESH:
			return 100
		WILTED:
			return int(row.get("wilted_percent", 0))
	return 0


## **Every braid a night older** (task 0228), from `Phases.begin_night`. Its
## strength is part of the path costs, so a night that changes any braid's
## state bumps the grid **once** and the fields rebuild with it; one whose
## state stays - the first night after the build step - touches nothing.
static func wear(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	var changed := false
	for key in keys:
		var on: Dictionary = occupants[key]
		if not repels(StringName(on["id"])):
			continue
		var was := state_of(on)
		on["nights"] = int(on.get("nights", 0)) + 1
		changed = changed or state_of(on) != was
	if changed:
		Farm.touch(state)
