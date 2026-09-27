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
##
## Soil and water are the exceptions: what a field offers depends on what is in
## it and what the pond offers depends on whether there is a line in it, so
## they ask `Farming` and `Fishing` rather than answering from a table. That is
## why the highlight can say "harvest" instead of "farm" and "reel" at the one
## moment reeling does anything, and why the player is never told a key does
## something it does not.
const TERRAIN_VERBS: Dictionary = {}

## How long a verb takes when the thing itself does not say. A verb that has a
## `work_ticks` in `GameData.GATHERING` uses that instead.
const DEFAULT_TICKS: Dictionary = {
	&"chop": 3 * GameData.SECONDS,
	&"mine": 4 * GameData.SECONDS,
	# Turning earth is work; dropping a seed in and pulling a crop out are not.
	&"till": 1 * GameData.SECONDS,          # LEVER: ticks, 15-60
	&"plant": GameData.SECONDS / 3,         # LEVER: ticks, 5-30
	&"harvest": GameData.SECONDS / 3,       # LEVER: ticks, 5-30
	&"water": 1,                    # instant; see INSTANT below
	&"fish": 1 * GameData.SECONDS,
	# The cast is the moment; the wait afterwards is `Fishing`, not the
	# player's action. Reeling is a single tick because the window is what
	# makes it hard, not the pulling.
	&"reel": 1,
	&"trade": 1,                    # opening a panel is not work
	# Starting a job is a moment. The job itself takes as long as the recipe
	# says, and the player is free to walk away while it runs.
	&"craft": GameData.SECONDS / 3,         # LEVER: ticks, 5-30
}


## Verbs that belong to the daylight.
##
## **The farm is asleep after dark.** Chopping a tree while a wave is coming in
## would be the one thing on the night map that was not about the night - and
## the systems behind these do not tick then anyway, so a verb that still
## worked would be a verb that lied.
##
## Repairing (task 0053) and dropping a barricade (task 0047) are the night's
## own verbs, and they go on their own list when they arrive.
const DAY_ONLY: Array = [
	&"chop", &"mine", &"till", &"plant", &"harvest", &"fish", &"trade", &"craft",
	&"water", &"reel",
]


## Verbs that finish on the tick they start, moving or not.
##
## **Watering a row has to be one held key and a walk down it.** Every other
## verb here stops the moment the player steps, which is right for chopping -
## half a tree does not stay half chopped - and wrong for a watering can. A
## verb on this list skips the action state entirely: `Player` completes it
## where it stands, and a tile that has already been watered stops offering it,
## so holding the key across a row waters each tile exactly once.
const INSTANT: Array = [&"water"]


static func is_instant(verb: StringName) -> bool:
	return INSTANT.has(verb)


## What this cell offers, or `&""` for nothing.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	if not Grid.in_bounds(cell):
		return &""
	var verb := _offered(state, cell)
	if int(state["phase"]) != Phases.DAY and DAY_ONLY.has(verb):
		return &""
	return verb


static func _offered(state: Dictionary, cell: Vector2i) -> StringName:
	var on := Farm.occupant(state, cell)
	if not on.is_empty():
		# **Any station with a recipe offers to make it.** This was a table
		# entry naming the workshop, which is why the press and the kitchen
		# could be built and then stood next to uselessly. A fourth station is
		# a `BUILDINGS` entry and some recipes, and nothing here changes.
		if Crafting.is_station(on["id"]):
			return &"craft"
		return OCCUPANT_VERBS.get(on["id"], &"")
	var terrain := Farm.terrain_at(state, cell)
	if terrain == Farm.Terrain.SOIL:
		return Farming.verb_at(state, cell)
	if terrain == Farm.Terrain.WATER:
		return Fishing.verb_at(state, cell)
	return TERRAIN_VERBS.get(terrain, &"")


## What the cell would offer if the sun were up. Split out so that the day-only
## rule is in one place rather than repeated in every branch.


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


## Whether holding the key keeps doing it.
##
## **True for work, false for anything that opens something.** Chopping a tree
## should be one held key rather than four presses, so `Player` restarts the
## action while the cell still offers the same verb. Opening the stall through
## that loop meant the panel reopened on the tick after the player closed it -
## escape worked, and then a tick later it had not. Found by input_check.
static func repeats(verb: StringName) -> bool:
	return not ONE_SHOT.has(verb)


## Verbs that happen once per press. They do not change what the cell offers,
## so without this they would happen for ever.
## **Reeling is here and watering is not**, which is the whole difference
## between the two. Watering repeats off `interact_held`, the level, so one
## held key does a row. A held key that reeled would land every fish without
## the player ever reacting to one, and reacting is the mechanic - so reeling
## takes the press, once, and the cast it belongs to is gone afterwards anyway.
const ONE_SHOT: Array = [&"trade", &"craft", &"reel"]


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
		&"till", &"plant", &"harvest", &"water":
			Farming.act(state, cell)
		&"fish":
			Fishing.begin(state, cell)
		&"reel":
			Fishing.reel(state)
		&"craft":
			Crafting.start_at(state, cell)
		&"trade":
			Shop.open(state)
		_:
			push_error("Interact.complete: nobody implements '%s'" % verb)


## Every verb the tables can produce, for `GameData.validate()` and for the
## tooltip of task 0089.
static func all_verbs() -> Array:
	var verbs: Array = []
	for v in OCCUPANT_VERBS.values() + TERRAIN_VERBS.values() \
			+ [&"till", &"plant", &"harvest", &"water", &"fish", &"reel",
				&"craft"]:
		if not verbs.has(v):
			verbs.append(v)
	verbs = GameData.sorted_names(verbs)
	return verbs
