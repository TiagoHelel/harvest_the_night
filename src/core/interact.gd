class_name Interact
extends RefCounted

## What a thing offers when you stand in front of it.
##
## **The player does not know what a tree is.** It asks here what the cell it
## is facing offers, how long that takes, and then tells this file when the
## time is up. That is what lets task 0016 add chopping, 0018 add planting and
## 0030 add fishing without any of them touching `player.gd`.
##
## Two tables and three functions. A new verb is an entry in a table and one
## arm of `complete()`; everything else already works.

## What is standing on a cell decides first. An occupant that offers nothing -
## a wall, a tower - is simply not interactable, and the player's fallback to
## the tile underfoot takes over.
const OCCUPANT_VERBS: Dictionary = {
	&"tree": &"chop",
	&"rock": &"mine",
	&"ore": &"mine",
	&"seam": &"mine",
	&"shop": &"trade",
}

## When nothing is standing there, the ground decides.
const TERRAIN_VERBS: Dictionary = {
	Farm.Terrain.SOIL: &"farm",
	Farm.Terrain.WATER: &"fish",
}

## How long a verb takes when the thing itself does not say. A verb that has a
## `work_ticks` in `GameData.GATHERING` uses that instead.
const DEFAULT_TICKS: Dictionary = {
	&"chop": 3 * GameData.SECONDS,
	&"mine": 4 * GameData.SECONDS,
	&"farm": 1 * GameData.SECONDS,
	&"fish": 1 * GameData.SECONDS,
	&"trade": 1,                    # opening a panel is not work
}


## What this cell offers, or `&""` for nothing.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	if not Grid.in_bounds(cell):
		return &""
	var on := Farm.occupant(state, cell)
	if not on.is_empty():
		return OCCUPANT_VERBS.get(on["id"], &"")
	return TERRAIN_VERBS.get(Farm.terrain_at(state, cell), &"")


## How many ticks one go at it takes.
##
## For anything gatherable that is one **swing**, not the whole job: a tree has
## hit points and `Player` repeats the action while the verb still holds. The
## gathering table is the authority where it has an opinion, so that chopping
## time is a lever next to how much wood a tree gives rather than a number
## hidden in a verb table.
static func ticks_for(state: Dictionary, cell: Vector2i, verb: StringName) -> int:
	var on := Farm.occupant(state, cell)
	if not on.is_empty():
		var node: Variant = GameData.GATHERING.get(on["id"], null)
		if node != null and (node as Dictionary).has("work_ticks"):
			return int((node as Dictionary)["work_ticks"])
	return int(DEFAULT_TICKS.get(verb, GameData.SECONDS))


## The work is finished. Do whatever the verb means.
##
## One arm per verb, and an arm that belongs to a task the backlog has not
## reached yet is deliberately empty - so the wiring can be tested end to end
## before the payload exists, and so adding the payload is one arm rather than
## a hunt through the player.
static func complete(state: Dictionary, cell: Vector2i, verb: StringName) -> void:
	match verb:
		&"chop", &"mine":
			Gathering.strike(state, cell)
		&"farm":
			pass        # task 0018: till, plant, harvest
		&"fish":
			pass        # task 0030
		&"trade":
			pass        # task 0020 opens the shop panel
		_:
			push_error("Interact.complete: nobody implements '%s'" % verb)


## Every verb the tables can produce, for `GameData.validate()` and for the
## tooltip of task 0089.
static func all_verbs() -> Array:
	var verbs: Array = []
	for v in OCCUPANT_VERBS.values() + TERRAIN_VERBS.values():
		if not verbs.has(v):
			verbs.append(v)
	verbs.sort()
	return verbs
