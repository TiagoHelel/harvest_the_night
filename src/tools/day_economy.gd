extends SceneTree

## **A day of each way of earning, played** (task 0194): the day sweep of
## `tools/balance.py`, headless and outside the suite.
##
## Each strategy is played through the rules on the farm `GameData.DAY_FARM`
## describes, in a spring and a summer:
## - the cliff's nodes struck and the trees felled;
## - the pond's fish drawn and landed;
## - the field sown, watered and harvested;
## - the herd fed, collected and its truffles dug;
## - the machines filled and emptied.
##
## Beside each, it prints `Economy`'s computed day and the season's band,
## and it prints the computed day of every season, autumn and winter too.
##
## **A worker who teleports**, as the autoplayer is. Every action goes
## through the rules and costs its ticks, and the walking is the allowance
## the computed day takes (`walk_to_node`, `walk_to_tree`). What the rules
## decide is real: what regrows when, which fish bites and when, which plots
## ripen, what a hen lays, when a batch is done.
##
## **How long each is played**, and its money is then by the day:
## - the crops across their season, and the machines for as many days as
##   their batches take to all come round together, because one day of
##   either is all or nothing;
## - the cliff from 06:00 to dusk;
## - the pond the same, over `FISHING_DAYS`, because its bites are drawn;
## - the animals from their morning feed to bedtime, over `ANIMAL_DAYS`,
##   because their clocks carry over from one day to the next.
##
##     godot --headless --path . --script res://src/tools/day_economy.gd

const PLAYED := [&"spring", &"summer"]
const SEED := 1940
const FISHING_DAYS := 3
const ANIMAL_DAYS := 4


func _initialize() -> void:
	for season in GameData.SEASONS:
		var band: Array = GameData.DAY_TARGETS[season]
		for strategy in Economy.STRATEGIES:
			var computed := Economy.day(strategy, season)
			var played := -1
			if PLAYED.has(season) and computed >= 0:
				played = play(strategy, season)
			print("DAY %s %s computed %d simulated %d target %d-%d" % [season, strategy, computed, played,
				int(band[0]), int(band[1])])
	quit()


## One strategy's day in `season`, played, in money.
func play(strategy: StringName, season: StringName) -> int:
	var state := State.create(SEED)
	state["day"] = GameData.SEASONS.find(season) * GameData.SEASON_DAYS + 1
	Shop.restock(state)
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		state["tools"][String(tool)] = clampi(Economy.tier(season), 0, (GameData.TOOLS[tool] as Array).size() - 1)
	House.leave(state)
	match strategy:
		&"mining":
			return _mining(state, season)
		&"fishing":
			return _fishing(state, season)
		&"crops":
			return _crops(state, season)
		&"animals":
			return _animals(state, season)
		&"artisan":
			return _artisan(state, season)
	return -1


# -------------------------------------------------------------- the strategies

## The cliff's nodes that pay more for the time than a tree
## (`Economy.cliff_kinds`), dearest first, whenever one stands; the trees
## when none does; until dusk.
func _mining(state: Dictionary, season: StringName) -> int:
	var before := _held(state)
	var kinds := Economy.cliff_kinds(season)
	while int(state["day_tick"]) < Economy.work_ticks():
		var cell := _standing(state, kinds)
		var walk := int(GameData.DAY_FARM["walk_to_node"])
		if cell.x < 0:
			cell = _standing(state, [&"tree"])
			walk = int(GameData.DAY_FARM["walk_to_tree"])
			if cell.x < 0:
				break
		Sim.advance(state, walk * Economy.tile_ticks())
		var node: Dictionary = GameData.GATHERING[StringName(Farm.occupant(state, cell)["id"])]
		for _hit in int(node["hits"]):
			Sim.advance(state, Interact.ticks_for(state, cell, &"mine"))
			Gathering.strike(state, cell)
	return _worth(state, before, [GameData.WOOD, GameData.STONE, GameData.IRON, GameData.COPPER,
		GameData.COAL, GameData.GOLD])


## At the season's best water, from its shore, until dusk: cast, wait, and
## press while the marker is on the green.
func _fishing(state: Dictionary, season: StringName) -> int:
	var water := _fishing_spot(state, Economy.best_pond(season))
	if water.x < 0:
		return -1
	var before := _held(state)
	for _day in FISHING_DAYS:
		SuiteKit.stand_the_farmer(state, _shore(state, water))
		while int(state["day_tick"]) < Economy.work_ticks():
			if not Fishing.is_casting(state):
				Fishing.begin(state, water)
				Sim.advance(state, int(Interact.DEFAULT_TICKS[&"fish"]))
				continue
			if Fishing.is_biting(state) and Fishing.in_zone(Fishing.cast_of(state)):
				Fishing.strike(state)
			Sim.advance(state, 1)
		Fishing.give_up(state)
		_sleep(state)
	return _worth(state, before, GameData.group_members(GameData.FISH)) / FISHING_DAYS


## The season's best money crop on the season's plots, from its first
## morning to its last: harvest, sow - a packet at its price - and water,
## every day, a night between. By the day.
func _crops(state: Dictionary, season: StringName) -> int:
	var crop := Economy.best_crop(season)
	var packet := Farming.packet(crop)
	var plots := _field(state, int((GameData.DAY_FARM["plots"] as Dictionary)[season]))
	Farming.select_seed(state, crop)
	Resources.gain(state, {GameData.MONEY: 5000})
	var before := _held(state)
	for _day in GameData.SEASON_DAYS:
		for plot in plots:
			var verb := Farming.verb_at(state, plot)
			if verb == &"harvest" or verb == &"till":
				Farming.act(state, plot)
				verb = Farming.verb_at(state, plot)
			if verb == &"plant":
				if Resources.amount(state, packet) <= 0:
					Resources.spend(state, GameData.MONEY, Shop.buy_price(packet))
					Resources.add(state, packet, 1)
				Farming.act(state, plot)
		for plot in plots:
			if Farming.crop_on(state, plot) == &"" or Farming.is_watered(state, plot):
				continue
			if Farming.water_carried(state) <= 0:
				Farming.refill_beside(state, Farm.cells_with(state, &"well")[0] + Vector2i.UP)
			Farming.act(state, plot)
		_sleep(state)
	return _worth(state, before, [crop]) / GameData.SEASON_DAYS


## The season's herd in coops and barns, its hay bought for the morning,
## fed, then collected at every home's door and its truffles dug through the
## day, to 01:30.
func _animals(state: Dictionary, season: StringName) -> int:
	var herd: Dictionary = (GameData.DAY_FARM["herd"] as Dictionary)[season]
	Resources.gain(state, {GameData.WOOD: 2000, GameData.STONE: 2000, GameData.MONEY: 5000})
	var homes: Array = []
	for kind in GameData.sorted_names(herd.keys()):
		var wanted := int(herd[kind])
		while _housed(state, kind) < wanted:
			var home := Livestock.home_with_room(state, kind)
			if home.x < 0:
				var id := Livestock.home_of(kind)
				home = _spot(state, id)
				if home.x < 0 or not Building.place(state, id, home):
					return -1
				homes.append(Building.anchor_of(state, home))
				continue
			Livestock.house(state, home, kind)
	var eaters := 0
	for kind in GameData.sorted_names(herd.keys()):
		eaters += int(herd[kind]) * int((GameData.LIVESTOCK[kind] as Dictionary).get("feed_per_day", 0))
	var before := _held(state)
	var bed := Phases.tick_at_minute(int(GameData.DAY_FARM["animal_bed_minute"]))
	for _day in ANIMAL_DAYS:
		var hay := eaters - Resources.amount(state, GameData.ANIMAL_FEED)
		if hay > 0:
			Resources.spend(state, GameData.MONEY, hay * Economy.input_cost(season, GameData.ANIMAL_FEED))
			Resources.add(state, GameData.ANIMAL_FEED, hay)
		_sleep(state)
		while int(state["day_tick"]) < bed:
			Sim.advance(state, mini(10 * GameData.SECONDS, bed - int(state["day_tick"])))
			for anchor in homes:
				Livestock.collect(state, Livestock.door_of(state, anchor))
			for spot in Livestock.spots(state):
				Livestock.dig(state, spot)
	before[GameData.ANIMAL_FEED] = Resources.amount(state, GameData.ANIMAL_FEED)
	return _worth(state, before, [GameData.MILK, GameData.EGG, GameData.WOOL, GameData.TRUFFLE]) / ANIMAL_DAYS


## The season's machines on its recipes for a week: refilled each morning a
## batch is done - the farm's own goods for nothing, what the stall alone
## sells at its price - and emptied by the morning. By the day.
func _artisan(state: Dictionary, season: StringName) -> int:
	var machines: Dictionary = (GameData.DAY_FARM["machines"] as Dictionary)[season]
	Resources.gain(state, {GameData.WOOD: 3000, GameData.STONE: 3000, GameData.IRON: 300, GameData.MONEY: 5000})
	var placed: Array = []
	var outputs: Array = []
	for id in GameData.sorted_names(machines.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		for res in GameData.sorted_names((recipe["output"] as Dictionary).keys()):
			if not outputs.has(res):
				outputs.append(res)
		for _i in int(machines[id]):
			var at := _spot(state, StringName(recipe["station"]))
			if at.x < 0 or not Building.place(state, StringName(recipe["station"]), at):
				return -1
			placed.append([Building.anchor_of(state, at), id])
	# **Until every machine's batches come round together**: the least
	# common multiple of their days, so a keg of four is not caught half
	# way through its second.
	var days := 1
	for id in GameData.sorted_names(machines.keys()):
		var batch := maxi(Crafting.days_of(id), 1)
		var common := days
		while common % batch != 0:
			common += days
		days = common
	var before := _held(state)
	for _day in days:
		for one in placed:
			var cell: Vector2i = one[0]
			var id: StringName = one[1]
			if Crafting.busy(state, cell):
				continue
			var inputs: Dictionary = GameData.RECIPES[id]["inputs"]
			for res in GameData.sorted_names(inputs.keys()):
				var cost := Economy.input_cost(season, res)
				if cost > 0:
					Resources.spend(state, GameData.MONEY, cost * int(inputs[res]))
				Resources.add(state, res, int(inputs[res]))
			Crafting.start(state, cell, id)
		_sleep(state)
	return _worth(state, before, outputs) / days


# ------------------------------------------------------------------- helpers

## The first standing node of `kinds`, in that order, that the tools in hand
## can work now - or (-1, -1).
func _standing(state: Dictionary, kinds: Array) -> Vector2i:
	for kind in kinds:
		for cell in Farm.cells_with(state, kind):
			if Gathering.why_not(state, cell).is_empty():
				return cell
	return Vector2i(-1, -1)


## A cell of `pond`'s water with dry ground beside it, nearest the pond's
## listed cell - or (-1, -1).
func _fishing_spot(state: Dictionary, pond: StringName) -> Vector2i:
	var at: Array = GameData.PONDS[pond]
	var centre := Vector2i(int(at[0]), int(at[1]))
	for radius in 16:
		for cell in Grid.within(centre, radius):
			if Grid.in_bounds(cell) and Farm.terrain_at(state, cell) == Farm.Terrain.WATER \
					and Farm.pond_of(state, cell) == pond and _shore(state, cell).x >= 0:
				return cell
	return Vector2i(-1, -1)


## Dry, walkable ground beside a water cell - or (-1, -1).
func _shore(state: Dictionary, water: Vector2i) -> Vector2i:
	for step in Grid.STEPS:
		var cell: Vector2i = water + step
		if Grid.in_bounds(cell) and Farm.terrain_at(state, cell) != Farm.Terrain.WATER and Farm.walkable(state, cell):
			return cell
	return Vector2i(-1, -1)


## `count` plots: the starter beds, then grass turned beside them.
func _field(state: Dictionary, count: int) -> Array:
	var plots: Array = []
	for cell in Farming.field_cells(state):
		if plots.size() < count:
			plots.append(cell)
	var at := 0
	while plots.size() < count and at < plots.size():
		for step in Grid.STEPS:
			var cell: Vector2i = plots[at] + step
			if plots.size() < count and not plots.has(cell) and Farming.verb_at(state, cell) == &"till":
				plots.append(cell)
		at += 1
	return plots


## The first place a building of `id` fits, in cell order - or (-1, -1).
func _spot(state: Dictionary, id: StringName) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Building.can_place(state, id, cell):
			return cell
	return Vector2i(-1, -1)


## To bed and up again with nothing in the night: the morning grows the
## crops, feeds the animals and finishes the batches.
func _sleep(state: Dictionary) -> void:
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	House.leave(state)


## How many of `kind` live in the farm's homes.
func _housed(state: Dictionary, kind: StringName) -> int:
	var count := 0
	var homes: Dictionary = state["housed"]
	var keys: Array = homes.keys()
	keys.sort()
	for idx in keys:
		for animal in ((homes[idx] as Dictionary)["animals"] as Array):
			if StringName((animal as Dictionary)["id"]) == kind:
				count += 1
	return count


func _held(state: Dictionary) -> Dictionary:
	return (state["held"] as Dictionary).duplicate()


## What the play made of `ids` since `before`, at what the stall pays, and
## the money it spent or took.
func _worth(state: Dictionary, before: Dictionary, ids: Array) -> int:
	var money := Resources.amount(state, GameData.MONEY) - int(before.get(GameData.MONEY, 0))
	for id in ids:
		money += (Resources.amount(state, id) - int(before.get(id, 0))) * int(GameData.SELL_PRICE.get(id, 0))
	return money
