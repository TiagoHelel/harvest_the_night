class_name Farming
extends RefCounted

## Till, plant, wait, harvest.
##
## The semi-idle heart of the day, and the clearest version of what `design.md`
## section 13 asks for: do a thing, go away, come back to something better. The
## waiting is the point. A crop that grew while you watched it would just be a
## slow button.
##
## ## A plot is not an occupant
##
## Crops live in `state["plots"]`, keyed by cell, rather than as things standing
## on the cell. Two reasons, and the second is the real one:
##
## - You can walk across your own field. An occupant blocks, and shuffling
##   around your own wheat to reach the pond is nobody's idea of cozy.
## - **At night the field is ground to defend, not furniture.** Zombies walk
##   over the wheat. Making a crop an occupant would have made every planted
##   tile a wall, and the player would have discovered they had accidentally
##   built a maze out of carrots.
##
## ## One verb, four meanings
##
## `Interact` asks this file what a soil tile offers and gets back `till`,
## `plant`, `harvest` or nothing, so the highlight and the tooltip can say what
## the key will actually do rather than "farm".

## What one plot looks like when it has just been turned over.
##
## `soak` is hundredths of a tick of growth banked from watering. See `tick()`
## for why the bonus is carried as a fraction rather than applied as one.
const EMPTY_PLOT := {"crop": &"", "growth": 0, "watered": false, "soak": 0}

## What the well and the pond are, as far as a watering can is concerned.
const WELL := &"well"

## The four cells a farmer can reach from where they stand.
##
## **Spelled out here rather than taken from `Player.FACING_STEPS`.**
## `Player` asks `Interact`, `Interact` asks this file, and this file
## asking `Player` back would close the ring.
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0),
]


static func initial() -> Dictionary:
	return {
		"plots": {},
		# Which seed goes in the ground, chosen from the strip in the day HUD.
		#
		# **Not `"seed"`.** That name is already the run's RNG seed, and the
		# state is one flat namespace: this collided silently and planting did
		# nothing at all until `State.create()` learned to refuse duplicates.
		"selected_seed": seeds()[0],
		# Tiles' worth of water in hand. Filled by standing next to water, spent
		# one tile at a time. Starts empty: the farmer walks out of the house in
		# the morning carrying nothing.
		"water_can": 0,
	}


# ------------------------------------------------------------------- asking

## Every crop there is, in a fixed order, which is the order the seed strip
## draws them and the order the number keys pick them.
##
## **Read off `GameData.CROPS`, sorted.** There is no list of crops anywhere
## else - adding a fourth is one dictionary entry and it appears in the menu, on
## a number key and in the save file without a line of code being written. The
## sort is what makes that safe: Dictionary order in the state is not something
## the determinism hash is allowed to depend on.
static func seeds() -> Array:
	return GameData.sorted_names(GameData.CROPS.keys())


static func selected_seed(state: Dictionary) -> StringName:
	return StringName(state["selected_seed"])


## Choose what the next `plant` puts in the ground. Refuses anything that is
## not a crop rather than storing it and failing later at the furrow.
static func select_seed(state: Dictionary, id: StringName) -> bool:
	if not GameData.CROPS.has(id):
		return false
	state["selected_seed"] = id
	return true


## Pick by position in `seeds()`, which is what the number keys send.
static func select_seed_at(state: Dictionary, index: int) -> bool:
	var ids := seeds()
	if index < 0 or index >= ids.size():
		return false
	return select_seed(state, StringName(ids[index]))


# --------------------------------------------------------------- the choice

## What one plot of this crop is worth over one whole day, seed paid for.
##
## **This is the number the three crops are balanced on**, and the menu shows
## it, because the interesting part of the choice is not visible otherwise: corn
## pays four times what carrot pays per harvest and carrot harvests four times
## as often, so a player comparing the two sale prices is comparing the wrong
## pair of numbers.
##
## Harvests are counted whole. Half a corn at dusk is worth nothing, which is
## exactly why the slow crop wants planting in the morning.
static func value_per_day(id: StringName) -> int:
	return value_per_harvest(id) * harvests_per_day(id)


## Sale value of one harvest less what the seed cost.
static func value_per_harvest(id: StringName) -> int:
	var data: Dictionary = GameData.CROPS[id]
	return int(data["yield"]) * int(GameData.SELL_PRICE[id]) 		- int(data["seed_cost"])


## How many times a plot of this comes round in a day. Also how many times the
## player has to walk back to it, which is the real cost of the fast crops.
static func harvests_per_day(id: StringName) -> int:
	var ticks := int((GameData.CROPS[id] as Dictionary)["growth_ticks"])
	return GameData.DAY_TICKS / maxi(ticks, 1)


## Growing time in whole seconds, for the menu.
static func seconds_to_grow(id: StringName) -> int:
	return int((GameData.CROPS[id] as Dictionary)["growth_ticks"]) 		/ GameData.TICK_HZ


## The plot on a cell, or an empty Dictionary when the ground is untouched.
static func plot(state: Dictionary, cell: Vector2i) -> Dictionary:
	var idx := Grid.index(cell)
	if idx < 0:
		return {}
	return (state["plots"] as Dictionary).get(idx, {})


static func is_tilled(state: Dictionary, cell: Vector2i) -> bool:
	return not plot(state, cell).is_empty()


static func crop_on(state: Dictionary, cell: Vector2i) -> StringName:
	return plot(state, cell).get("crop", &"")


## How far along, from 0 at planting to `stages - 1` when it is ready. What the
## sprite of task 0029 follows.
static func stage(state: Dictionary, cell: Vector2i) -> int:
	var here := plot(state, cell)
	var crop: StringName = here.get("crop", &"")
	if crop == &"":
		return -1
	var data: Dictionary = GameData.CROPS[crop]
	var stages := int(data["stages"])
	var needed := int(data["growth_ticks"])
	var grown := int(here["growth"])
	if grown >= needed:
		return stages - 1
	# Integer arithmetic throughout: a stage boundary that landed differently
	# on two machines would be a visible desync in something nobody would think
	# to look at.
	return mini(grown * (stages - 1) / maxi(needed, 1), stages - 2)


## Whether this plot has been watered since the last night.
static func is_watered(state: Dictionary, cell: Vector2i) -> bool:
	return bool(plot(state, cell).get("watered", false))


## How many tiles' worth of water is in hand.
static func water_carried(state: Dictionary) -> int:
	return int(state["water_can"])


## Whether a canful can be drawn from this cell. The pond counts by its
## terrain and the well by what is standing on it, so "water comes from the
## pond and the well" is one question with one answer.
## How much the watering can holds, the tree included.
static func can_capacity(state: Dictionary) -> int:
	return GameData.WATER_CAN_CAPACITY 		+ Tech.bonus(state, "water_can_bonus", 0)


static func is_water_source(state: Dictionary, cell: Vector2i) -> bool:
	if not Grid.in_bounds(cell):
		return false
	if Farm.terrain_at(state, cell) == Farm.Terrain.WATER:
		return true
	return Farm.occupant(state, cell).get("id", &"") == WELL


## Top the can up when the farmer is standing next to water.
##
## **No keypress.** Filling a bucket is not a decision - walking to the water
## is, and that is the part the carry limit makes you do. Pressing a key to
## fill would also have to fight the pond for the interact verb, because a
## water tile already offers `fish` (task 0030) and a tile cannot offer two
## things without the player having to guess which.
##
## Called from `Sim._tick_day()` rather than from `tick()`, because it needs
## to know where the player is and `Player` already calls into `Interact`,
## which calls in here - asking the other way round would be a cycle.
static func refill_beside(state: Dictionary, here: Vector2i) -> bool:
	if int(state["water_can"]) >= can_capacity(state):
		return false
	for step in NEIGHBOURS:
		if is_water_source(state, here + step):
			state["water_can"] = can_capacity(state)
			return true
	return false


static func is_ready(state: Dictionary, cell: Vector2i) -> bool:
	var here := plot(state, cell)
	var crop: StringName = here.get("crop", &"")
	if crop == &"":
		return false
	return int(here["growth"]) >= int((GameData.CROPS[crop] as Dictionary)["growth_ticks"])


## What pressing interact on this cell would do, or `&""` for nothing.
##
## `Interact` calls this instead of guessing, so that the highlight can say
## "harvest" rather than "farm" and the player is never told a key does
## something it does not.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	if Farm.terrain_at(state, cell) != Farm.Terrain.SOIL:
		return &""
	if not Farm.is_empty(state, cell):
		return &""              # somebody built on the field; that is their call
	if not is_tilled(state, cell):
		return &"till"
	if crop_on(state, cell) == &"":
		return &"plant"
	if is_ready(state, cell):
		return &"harvest"
	# **The one chore.** A growing crop used to offer nothing at all, which made
	# the middle of a crop's life a place the player had no reason to stand. Dry
	# ground with water in the can offers the can.
	if not is_watered(state, cell) and water_carried(state) > 0:
		return &"water"
	return &""                  # growing, watered: nothing useful to do yet


# -------------------------------------------------------------------- doing

## Do whatever the cell offers. Called by `Interact.complete()`.
static func act(state: Dictionary, cell: Vector2i) -> void:
	match verb_at(state, cell):
		&"till":
			_till(state, cell)
		&"plant":
			_plant(state, cell)
		&"harvest":
			_harvest(state, cell)
		&"water":
			_water(state, cell)


static func _till(state: Dictionary, cell: Vector2i) -> void:
	(state["plots"] as Dictionary)[Grid.index(cell)] = EMPTY_PLOT.duplicate()


## Put the chosen seed in the ground, and pay for it.
##
## **Seeds are money, not an inventory item.** Buying a packet and then planting
## from it would be two steps and a number to manage, for a decision the player
## has already made by walking to the field. Task 0040 may revisit that when the
## shop grows; if it does, this is the one function that changes.
static func _plant(state: Dictionary, cell: Vector2i) -> void:
	var seed_id: StringName = state["selected_seed"]
	var data: Dictionary = GameData.CROPS[seed_id]
	if not Resources.pay(state, {GameData.MONEY: int(data["seed_cost"])}):
		return                  # no money, no seed, and no half-planted tile
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	here["crop"] = seed_id
	here["growth"] = 0


## One tile off the can. **Never fatal and never wasted**: a tile that is
## already wet does not offer the verb, so holding the key down the row spends
## exactly one per tile.
static func _water(state: Dictionary, cell: Vector2i) -> void:
	if int(state["water_can"]) <= 0:
		return
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	if bool(here["watered"]):
		return
	here["watered"] = true
	state["water_can"] = int(state["water_can"]) - 1


## The water goes off with the sun. Called when the night begins.
##
## `design.md` makes the farm and the fortress the same ground at different
## hours; watering is a day thing, and a plot that stayed wet through the night
## would make the chore a once-per-run job rather than a daily one.
static func dry_out(state: Dictionary) -> void:
	if not GameData.WATER_LASTS_UNTIL_NIGHT:
		return                  # the lever says watering is permanent
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		here["watered"] = false
		here["soak"] = 0


## Take the crop and leave the ground turned over, ready for the next one.
static func _harvest(state: Dictionary, cell: Vector2i) -> void:
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	var crop: StringName = here["crop"]
	var data: Dictionary = GameData.CROPS[crop]
	Resources.add(state, crop, int(data["yield"]))
	here["crop"] = &""
	here["growth"] = 0
	here["watered"] = false


# ------------------------------------------------------------------ the tick

## One tick of things growing. Called from `Sim._tick_day()` and from nowhere
## else, which is the whole of "crops do not grow at night".
##
## A planted tile keeps its growth across a night untouched and picks up the
## next morning exactly where it was - it is plain data in the state, so that
## falls out of not being ticked rather than having to be arranged.
static func tick(state: Dictionary) -> void:
	var plots: Dictionary = state["plots"]
	if plots.is_empty():
		return
	# Sorted, so that the order plots were tilled in cannot matter. Nothing
	# here draws from the RNG yet; the weather of a later game would.
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		var crop: StringName = here["crop"]
		if crop == &"":
			continue
		var needed := int((GameData.CROPS[crop] as Dictionary)["growth_ticks"])
		if int(here["growth"]) >= needed:
			continue
		here["growth"] = int(here["growth"]) + 1

		# **The bonus is banked, not rounded.** Fifty percent of a tick is not a
		# number a plot can hold, and rounding it to one or to zero every tick
		# would be a 100% bonus or none at all. So the percentage accumulates in
		# hundredths and pays out a whole tick whenever it has one - exact,
		# integer throughout, and any percentage works, which is what makes
		# WATER_GROWTH_BONUS a lever rather than a choice between two numbers.
		if not bool(here["watered"]):
			continue
		here["soak"] = int(here["soak"]) + GameData.WATER_GROWTH_BONUS
		while int(here["soak"]) >= 100 and int(here["growth"]) < needed:
			here["soak"] = int(here["soak"]) - 100
			here["growth"] = int(here["growth"]) + 1


## How many plots are tilled, and how many of those are carrying something.
## For the debug overlay and the statistics of task 0069.
static func counts(state: Dictionary) -> Dictionary:
	var tilled := 0
	var planted := 0
	var ready := 0
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		tilled += 1
		if (plots[idx] as Dictionary)["crop"] != &"":
			planted += 1
			if is_ready(state, Grid.cell(int(idx))):
				ready += 1
	return {"tilled": tilled, "planted": planted, "ready": ready}
