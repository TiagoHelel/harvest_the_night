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
		# Keep the affordable starter when new ids sort before carrot (0168).
		"selected_seed": GameData.CARROT,
		# Tiles' worth of water in hand. Filled by standing next to water, spent
		# one tile at a time. Starts empty: the farmer walks out of the house in
		# the morning carrying nothing.
		"water_can": 0,
	}


# ------------------------------------------------------------------- asking

## Every crop in sorted order, including crops outside today's season.
## The views and slot keys use `in_season`; catalogues and fixtures use this.
static func seeds() -> Array:
	return GameData.sorted_names(GameData.CROPS.keys())


## Packet resource for a crop id; selection continues to store the crop.
static func packet(id: StringName) -> StringName:
	return StringName("%s_seed" % id)


## The sorted choices for today's calendar date. Winter offers none.
static func in_season(state: Dictionary) -> Array:
	var season: StringName = GameData.SEASONS[Calendar.season_of(Calendar.date(state))]
	var out: Array = []
	for id in seeds():
		if season in GameData.CROPS[id]["seasons"]:
			out.append(id)
	return out


static func selected_seed(state: Dictionary) -> StringName:
	var ids := in_season(state)
	var chosen := StringName(state["selected_seed"])
	return chosen if chosen in ids else (StringName(ids[0]) if not ids.is_empty() else &"")


## Persist the season's fallback at dawn and when reconciling an old save.
static func refresh_seed(state: Dictionary) -> void:
	state["selected_seed"] = selected_seed(state)


## Choose what the next `plant` puts in the ground. Refuses anything that is
## not an in-season crop rather than failing later at the furrow.
static func select_seed(state: Dictionary, id: StringName) -> bool:
	if id not in in_season(state):
		return false
	state["selected_seed"] = id
	return true


## Pick by position in `in_season()`, which is what the number keys send.
static func select_seed_at(state: Dictionary, index: int) -> bool:
	var ids := in_season(state)
	if index < 0 or index >= ids.size():
		return false
	return select_seed(state, StringName(ids[index]))


# --------------------------------------------------------------- the choice

## What one plot of this crop is worth over one whole season, seed paid for.
##
## Whole harvests in one season, net of their seeds.
static func value_per_season(id: StringName) -> int:
	var data: Dictionary = GameData.CROPS[id]
	var harvests := harvests_per_season(id)
	var seeds := 1 if regrow_days(id) > 0 else harvests
	return int(data["yield"]) * int(GameData.SELL_PRICE[id]) * harvests - int(data["seed_cost"]) * seeds


## Sale value of one harvest less what the seed cost.
static func value_per_harvest(id: StringName) -> int:
	var data: Dictionary = GameData.CROPS[id]
	return int(data["yield"]) * int(GameData.SELL_PRICE[id]) 		- int(data["seed_cost"])


## How many times a watered plot comes round in a season. Also how many times the
## player has to walk back to it, which is the real cost of the fast crops.
static func harvests_per_season(id: StringName) -> int:
	return GameData.crop_harvests(GameData.CROPS[id])


## Watered days between picks; zero means the plant is harvested only once.
## Old plots read their absent regrowth marker as false.
static func regrow_days(id: StringName) -> int:
	return int(GameData.CROPS[id].get("regrow_days", 0))


## Initial growing time in watered days, for the menu.
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


## Initial stages run from 0 to `stages - 1` when ready.
## `stages` is the separate regrowth frame until the plant is ready again.
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
	if bool(here.get("regrowing", false)):
		return stages
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
	return GameData.WATER_CAN_CAPACITY + Tech.bonus(state, "water_can_bonus", 0) \
		+ int(ToolTiers.effects(state, &"can")["capacity_bonus"])


## The eligible cells of one transverse stroke, in spending order. The view
## asks this same rule, including short cans, rather than promising extra work.
## No state is changed: centre, left, right, outer left, outer right.
static func action_cells(state: Dictionary, cell: Vector2i, verb: StringName) -> Array:
	var out: Array = []
	if verb not in [&"water", &"till"] or verb_at(state, cell) != verb:
		return out
	var tool: StringName = &"can" if verb == &"water" else &"hoe"
	var width := int(ToolTiers.effects(state, tool)["area"])
	var forward: Vector2i = NEIGHBOURS[int(state["player"]["facing"])]
	var across := Vector2i(-forward.y, forward.x)
	var limit := water_carried(state) if verb == &"water" else width
	for offset in GameData.TOOL_AREA_OFFSETS[width]:
		var at := cell + across * int(offset)
		if out.size() >= limit:
			break
		if verb_at(state, at) == verb:
			out.append(at)
	return out


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


## The explicit hoe road, separate from SPACE's water/harvest verb.
static func can_clear(state: Dictionary, cell: Vector2i) -> bool:
	return int(state["phase"]) == Phases.DAY and Grid.in_bounds(cell) \
		and Farm.is_empty(state, cell) and crop_on(state, cell) != &""


## Clearing spends the plant and leaves tilled earth; it never pays a harvest.
static func clear_crop(state: Dictionary, cell: Vector2i) -> bool:
	if not can_clear(state, cell):
		return false
	_till_one(state, cell)
	return true


static func _till(state: Dictionary, cell: Vector2i) -> void:
	for at in action_cells(state, cell, &"till"):
		_till_one(state, at)
		# **A worm in the turned earth** (task 0181): one cell in `WORM_IN`,
		# drawn from the run's RNG as each cell is turned - bait for the iron
		# rod. Here and not in `_till_one`, which clearing a crop shares.
		if Rng.chance(state["rng"], 1, GameData.WORM_IN):
			Resources.add(state, GameData.WORM, 1)


## Clearing an existing crop stays a deliberate single-cell action (0172).
static func _till_one(state: Dictionary, cell: Vector2i) -> void:
	(state["plots"] as Dictionary)[Grid.index(cell)] = EMPTY_PLOT.duplicate()
	_worked(state, cell)


## Only grass needs an age. `day` counts real mornings even on a held boss
## date; legacy saved grass plots acquire the field at their first morning.
static func _worked(state: Dictionary, cell: Vector2i) -> void:
	if Farm.terrain_at(state, cell) == Farm.Terrain.GRASS:
		plot(state, cell)["last_worked_morning"] = int(state["day"])


## Put one held packet in the ground. Money changes only at the stall.
static func _plant(state: Dictionary, cell: Vector2i) -> void:
	if Calendar.season_id(Calendar.date(state)) in GameData.NO_GROWTH_SEASONS:
		return
	var seed_id := selected_seed(state)
	if seed_id == &"" or not Resources.spend(state, packet(seed_id), 1):
		return
	state["selected_seed"] = seed_id
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	here["crop"] = seed_id
	here["growth"] = 0
	# Something planted where a crop was trampled (task 0155): the mark goes.
	here.erase("trampled")
	here.erase("withered")
	here.erase("regrowing")
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
		here.erase("regrowing")
		here["trampled"] = crop
		_worked(state, Grid.cell(idx))
		lost += 1
	return lost


## One unit per eligible plot, including a partial stroke from a short can.
static func _water(state: Dictionary, cell: Vector2i) -> void:
	for at in action_cells(state, cell, &"water"):
		plot(state, at)["watered"] = true
		state["water_can"] = int(state["water_can"]) - 1
		_worked(state, at)


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


## Pick once, keeping repeat-bearing plants short of readiness for regrowth.
static func _harvest(state: Dictionary, cell: Vector2i) -> void:
	var here: Dictionary = (state["plots"] as Dictionary)[Grid.index(cell)]
	var crop: StringName = here["crop"]
	var data: Dictionary = GameData.CROPS[crop]
	Resources.add(state, crop, int(data["yield"]))
	var regrow := regrow_days(crop)
	if regrow > 0:
		here["regrowing"] = true
		here["growth"] = days_to_grow(crop) - regrow
	else:
		here["crop"] = &""
		here["growth"] = 0
		here["watered"] = false
		here.erase("regrowing")
	here.erase("morning_credit")
	_worked(state, cell)


## At a season boundary, wither crops that do not belong to the new season.
## Credit yesterday's watering once outside dormant seasons, even on a held date.
## Consuming the flag also makes an extra call or a save/reload harmless.
static func morning(state: Dictionary) -> void:
	refresh_seed(state)
	var date := Calendar.date(state)
	var season := Calendar.season_id(date)
	var boundary := date > 1 and Calendar.day_of_season(date) == 1
	var dormant := season in GameData.NO_GROWTH_SEASONS
	var plots: Dictionary = state["plots"]
	var keys: Array = plots.keys()
	keys.sort()
	for idx in keys:
		var here: Dictionary = plots[idx]
		var planted := StringName(here["crop"])
		if boundary and planted != &"" and season not in GameData.CROPS[planted]["seasons"]:
			here["withered"] = planted
			here["crop"] = &""
			here["growth"] = 0
			here["watered"] = false
			here.erase("morning_credit")
			here.erase("trampled")
			here.erase("regrowing")
			_worked(state, Grid.cell(int(idx)))
		if Farm.terrain_at(state, Grid.cell(int(idx))) == Farm.Terrain.GRASS:
			var last := int(here.get("last_worked_morning", state["day"]))
			here["last_worked_morning"] = last
			if here["crop"] == &"" and int(state["day"]) - last >= GameData.TILLED_GRASS_FADES_DAYS:
				plots.erase(idx)
				continue
		var credit := bool(here.get("morning_credit", false))
		here.erase("morning_credit")
		var crop: StringName = here["crop"]
		if dormant or not credit or crop == &"":
			continue
		var needed := days_to_grow(crop)
		if int(here["growth"]) >= needed:
			continue
		here["growth"] = int(here["growth"]) + 1
		if int(here["growth"]) == needed:
			Events.add(state, &"crop_ready", {"crop": crop, "cell": _as_pair(Grid.cell(int(idx)))})


## **The sprinklers' morning** (task 0178). After the growth credit, every
## sprinkler marks the plots of its pattern watered for the new day - in
## sorted cell order, sprinklers and cells alike - and they dry at night like
## any plot. Turned earth with nothing in it is wetted too, so a seed sown
## there later that day grows; the farmer working the bed is what keeps
## turned lawn from fading (0167), and the spray is not him.
static func sprinkle(state: Dictionary) -> void:
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var id := StringName((occupants[idx] as Dictionary)["id"])
		if not Building.sprays(id):
			continue
		for cell in sprayed_by(id, Grid.cell(int(idx))):
			var here := plot(state, cell)
			if not here.is_empty() and Farm.is_empty(state, cell):
				here["watered"] = true


## The cells a sprinkler of this id standing on `at` waters, in index order:
## its four neighbours for a cross, every cell within `spray_reach` of it for a
## square - never its own, and never off the farm.
static func sprayed_by(id: StringName, at: Vector2i) -> Array:
	var entry: Dictionary = GameData.BUILDINGS.get(id, {})
	var reach := int(entry.get("spray_reach", 0))
	var square := StringName(entry.get("spray", &"")) == &"square"
	var out: Array = []
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			if (dx == 0 and dy == 0) or (not square and absi(dx) + absi(dy) > reach):
				continue
			var cell := at + Vector2i(dx, dy)
			if Grid.in_bounds(cell):
				out.append(cell)
	return out


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
