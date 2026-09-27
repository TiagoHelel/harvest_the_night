class_name Livestock
extends RefCounted

## The cow and the chickens, and the meat that comes off them.
##
## `design.md`'s resource table has meat on it and nothing in the game made
## any. The reference sheet has the answer standing on the grass: a cow and a
## couple of chickens, loose, not penned.
##
## ## A trickle, not a husbandry system
##
## The task is explicit about this and it is worth being explicit back:
## **passive means there is nothing to manage.** No feeding, no water, no
## breeding, no happiness, no shelter at night. An animal stands there and
## slowly has something worth taking. That is the whole system, and it is the
## whole system on purpose - a farm sim's animal loop is a game in its own
## right and this is a tower defence with a farm attached.
##
## What the player does have to do is **walk over**, which is the same bargain
## as everything else on this farm: the thing accumulates while you are
## somewhere else, and comes to nothing if you never come back. An animal holds
## only so much (`holds`), so a cow nobody visits stops producing rather than
## banking a fortnight of beef.


static func initial() -> Dictionary:
	return {
		# {animal cell index: {"ready": units waiting, "left": ticks to the
		# next one}}
		"livestock": {},
	}


# ------------------------------------------------------------------- asking

static func is_animal(id: StringName) -> bool:
	return GameData.LIVESTOCK.has(id)


## How much is waiting to be collected from the animal on this cell.
static func ready_at(state: Dictionary, cell: Vector2i) -> int:
	var pen: Dictionary = state["livestock"]
	var at: Variant = pen.get(Grid.index(cell), null)
	return 0 if at == null else int((at as Dictionary)["ready"])


## What this cell offers. `Interact` asks here, the way soil asks `Farming`.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_animal(on["id"]):
		return &""
	return &"collect" if ready_at(state, cell) > 0 else &""


## How full an animal is, from 0 to its `holds`. For the sprite of task 0080
## and for the tooltip.
static func fullness(state: Dictionary, cell: Vector2i) -> int:
	return ready_at(state, cell)


# -------------------------------------------------------------------- doing

## Take what is waiting. Returns what came off it, empty when nothing was.
static func collect(state: Dictionary, cell: Vector2i) -> Dictionary:
	var on := Farm.occupant(state, cell)
	if on.is_empty() or not is_animal(on["id"]):
		return {}
	var waiting := ready_at(state, cell)
	if waiting <= 0:
		return {}

	var entry: Dictionary = GameData.LIVESTOCK[on["id"]]
	var given := {}
	for res in GameData.sorted_names((entry["produces"] as Dictionary).keys()):
		given[res] = int((entry["produces"] as Dictionary)[res]) * waiting
	Resources.gain(state, given)
	((state["livestock"] as Dictionary)[Grid.index(cell)]
		as Dictionary)["ready"] = 0
	return given


# ------------------------------------------------------------------ the tick

## One tick of standing in a field. Called from `Sim._tick_day()` and nowhere
## else: the animals are asleep at night, like everything else on the farm.
static func tick(state: Dictionary) -> void:
	var pen: Dictionary = state["livestock"]
	for cell in _animals(state):
		var idx := Grid.index(cell)
		var id: StringName = Farm.occupant(state, cell)["id"]
		var entry: Dictionary = GameData.LIVESTOCK[id]
		if not pen.has(idx):
			pen[idx] = {"ready": 0, "left": int(entry["every_ticks"])}

		var at: Dictionary = pen[idx]
		# **A full animal stops.** Nothing accumulates off screen for ever:
		# come back or lose the difference, which is what makes coming back a
		# thing you do rather than a thing you schedule.
		if int(at["ready"]) >= int(entry["holds"]):
			continue
		at["left"] = int(at["left"]) - 1
		if int(at["left"]) > 0:
			continue
		at["ready"] = int(at["ready"]) + 1
		at["left"] = int(entry["every_ticks"])


## Every animal on the farm, in cell order.
##
## Cached against `grid_version` for the same reason as `Power`: this runs at
## 30Hz and sorting the whole occupant table every tick is how the test suite
## tripled in task 0033.
static func _animals(state: Dictionary) -> Array:
	var pen: Dictionary = state["livestock"]
	var version := int(state["grid_version"])
	if int(state.get("livestock_version", -1)) != version:
		state["livestock_version"] = version
		var found: Array = []
		var occupants: Dictionary = state["occupants"]
		var keys: Array = occupants.keys()
		keys.sort()
		for idx in keys:
			if is_animal(StringName((occupants[idx] as Dictionary)["id"])):
				found.append(int(idx))
		state["livestock_cells"] = found
		# An animal that is gone takes its half-grown produce with it.
		for idx in pen.keys():
			if not found.has(int(idx)):
				pen.erase(idx)

	var out: Array = []
	for idx in (state["livestock_cells"] as Array):
		out.append(Grid.cell(int(idx)))
	return out
