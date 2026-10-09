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
## `Interact` asks this file what a field tile offers and gets back `till`,
## `plant`, `harvest` or nothing, so the highlight and the tooltip can say what
## the key will actually do rather than "farm".

## What one plot looks like when it has just been turned over.
##
## Growth counts watered mornings. `morning_credit` is consumed once at dawn.
const EMPTY_PLOT := {"crop": &"", "growth": 0, "watered": false}

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

## What one plot of this crop is worth over one whole season, seed paid for.
##
## Whole harvests in one season, net of their seeds.
static func value_per_season(id: StringName) -> int:
	return value_per_harvest(id) * harvests_per_season(id)


## Sale value of one harvest less what the seed cost.
static func value_per_harvest(id: StringName) -> int:
	var data: Dictionary = GameData.CROPS[id]
	return int(data["yield"]) * int(GameData.SELL_PRICE[id]) 		- int(data["seed_cost"])


## How many times a watered plot comes round in a season. Also how many times the
## player has to walk back to it, which is the real cost of the fast crops.
static func harvests_per_season(id: StringName) -> int:
	return GameData.SEASON_DAYS / maxi(days_to_grow(id), 1)


## Growing time in watered days, for the menu.
static func days_to_grow(id: StringName) -> int:
	return int((GameData.CROPS[id] as Dictionary)["growth_days"])


## The plot on a cell, or an empty Dictionary when the ground is untouched.
static func plot(state: Dictionary, cell: Vector2i) -> Dictionary:
	var idx := Grid.index(cell)
	if idx < 0:
		return {}
	return (state["plots"] as Dictionary).get(idx, {})


static func is_tilled(state: Dictionary, cell: Vector2i) -> bool:
	return not plot(state, cell).is_empty()


## Starter soil beds and turned grass, in cell-index order. Terrain stays
## untouched: a plot is an overlay, including its original walking cost.
static func field_cells(state: Dictionary) -> Array:
	var cells := Farm.cells_of(state, Farm.Terrain.SOIL)
	var keys: Array = (state["plots"] as Dictionary).keys()
	keys.sort()
	var grass: Array = []
	var terrain: PackedByteArray = state["terrain"]
	for idx in keys:
		if int(terrain[int(idx)]) == Farm.Terrain.GRASS:
			grass.append(Grid.cell(int(idx)))
	# The normal starter field already has its final order. Avoid re-sorting
	# it on every tutorial check when there is no grass to merge.
	if grass.is_empty():
		return cells
	cells.append_array(grass)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Grid.index(a) < Grid.index(b))
	return cells


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
	var needed := int(data["growth_days"])
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
	return int(here["growth"]) >= int((GameData.CROPS[crop] as Dictionary)["growth_days"])


## What pressing interact on this cell would do, or `&""` for nothing.
##
## `Interact` calls this instead of guessing, so that the highlight can say
## "harvest" rather than "farm" and the player is never told a key does
## something it does not.
static func verb_at(state: Dictionary, cell: Vector2i) -> StringName:
	if not Grid.in_bounds(cell):
		return &""
	if not Farm.is_empty(state, cell):
		return &""              # somebody built on the field; that is their call
	if not is_tilled(state, cell):
		var terrain := Farm.terrain_at(state, cell)
		return &"till" if terrain in [Farm.Terrain.GRASS, Farm.Terrain.SOIL] else &""
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
	_worked(state, cell)


## Only grass needs an age. `day` counts real mornings even on a held boss
## date; legacy saved grass plots acquire the field at their first morning.
static func _worked(state: Dictionary, cell: Vector2i) -> void:
	if Farm.terrain_at(state, cell) == Farm.Terrain.GRASS:
		plot(state, cell)["last_worked_morning"] = int(state["day"])


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
	# Something planted where a crop was trampled (task 0155): the mark goes.
	here.erase("trampled")
	_worked(state, cell)


## **The horde walked through it** (task 0155): every crop on these cells is
## lost. The plot stays tilled - turned earth a farmer can plant again - with
## its crop and growth gone and a `trampled` marker naming what was there,
## for the view, until something is planted. Walked in the order given
## (`Pathing.horde_routes` sorts them). Returns how many crops went.
static func trample(state: Dictionary, cells: Array) -> int:
	var plots: Dictionary = state["plots"]
	var lost := 0
	for found in cells:
		var idx := Grid.index(found as Vector2i)
		if not plots.has(idx):
			continue
		var here: Dictionary = plots[idx]
		var crop := StringName(here.get("crop", &""))
		if crop == &"":
			continue
		here["crop"] = &""
		here["growth"] = 0
		here.erase("morning_credit")
		here["trampled"] = crop
		_worked(state, Grid.cell(idx))
		lost += 1
	return lost


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
	_worked(state, cell)


## Record planted, watered plots for tomorrow before drying the field.
static func dry_out(state: Dictionary) -> void:
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		if here["crop"] != &"" and bool(here["watered"]):
			here["morning_credit"] = true
		else:
			here.erase("morning_credit")
		here["watered"] = false


## Take the crop and leave the ground turned over, ready for the next one.
static func _harvest(state: Dictionary, cell: Vector2i) -> void:
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	var crop: StringName = here["crop"]
	var data: Dictionary = GameData.CROPS[crop]
	Resources.add(state, crop, int(data["yield"]))
	here["crop"] = &""
	here["growth"] = 0
	here["watered"] = false
	here.erase("morning_credit")
	_worked(state, cell)


## Credit yesterday's watering once, even when a boss holds the calendar.
## Consuming the flag also makes an extra call or a save/reload harmless.
static func morning(state: Dictionary) -> void:
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		if Farm.terrain_at(state, Grid.cell(int(idx))) == Farm.Terrain.GRASS:
			var last := int(here.get("last_worked_morning", state["day"]))
			here["last_worked_morning"] = last
			if here["crop"] == &"" and int(state["day"]) - last >= GameData.TILLED_GRASS_FADES_DAYS:
				plots.erase(idx)
				continue
		var credit := bool(here.get("morning_credit", false))
		here.erase("morning_credit")
		var crop: StringName = here["crop"]
		if not credit or crop == &"":
			continue
		var needed := days_to_grow(crop)
		if int(here["growth"]) >= needed:
			continue
		here["growth"] = int(here["growth"]) + 1
		if int(here["growth"]) == needed:
			Events.add(state, &"crop_ready", {"crop": crop, "cell": _as_pair(Grid.cell(int(idx)))})


## A cell as the two numbers the state stores everywhere else. Events carry
## plain data, so a `Vector2i` would be the one thing in the record that a
## save file could not round-trip.
static func _as_pair(cell: Vector2i) -> Array:
	return [cell.x, cell.y]


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
