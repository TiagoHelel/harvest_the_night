class_name DayTour
extends SceneTree

## **A spring day and a summer day, played** (task 0196, the plan's Phase 3
## checkpoint): a farmer's ninth day of each season, spent the way a player
## spends one, through the rules - and the autoplayer through the same day,
## to compare where the money came from. Headless and outside the suite:
##
##     godot --headless --path . --script res://src/tools/day_tour.gd
##
## **The farm under the day** is played too (`prepare`). Its field is sown
## on the season's first morning and worked every day since; in summer it
## also has a coop and a barn with their animals, two preserves jars on
## spring's strawberries and a keg on melons, bought out of a spring's money.
## Nights pass held, nothing on them: this is about the day.
##
## **The day** (`play`) follows `SCHEDULE`: each block runs to the minute it
## names, or until it has nothing left to do, and costs its actions' ticks
## and the walking between them, as `day_economy.gd`'s worker does - the same
## teleporting worker, with the same allowances. What each block made is its
## change in what the farm holds, at what the stall pays, and its money:
## selling only turns goods into coins, so it makes nothing.
##
## `shot.gd`'s `days` scenario plays the same days to its pictures' minutes.

const SEED := 1960
## The day of the season played: the plan's appendix spring day is the ninth.
const DAY_PLAYED := 9

## The day, block by block: `[until minute, activity]`. The field's minute
## is a cap it never reaches: a player does not leave the field half watered,
## and its round is done by 08:48 in spring and 09:16 in summer.
const SCHEDULE := {
	&"spring": [[10 * 60, &"field"], [11 * 60 + 30, &"cliff"], [16 * 60, &"fish"], [17 * 60, &"sell"]],
	&"summer": [[10 * 60, &"field"], [11 * 60 + 30, &"fish"], [11 * 60 + 45, &"animals"],
		[12 * 60 + 15, &"machines"], [15 * 60 + 30, &"cliff"], [16 * 60, &"animals"], [17 * 60, &"sell"]],
}
## What the field grows, half and half: a regrowing crop for money and a
## quick one, as the plan's appendix farmer does.
const SOWN := {&"spring": [&"strawberry", &"potato"], &"summer": [&"pepper", &"corn"]}
## What a season's machines are fed, kept back from the stall.
const KEPT := {&"summer": [&"strawberry", &"melon", &"sugar"]}


func _initialize() -> void:
	for season in [&"spring", &"summer"]:
		# **The night's batches** count as the day's: the keg and the jars
		# finish on the morning, and the day before filled them.
		var state := evening_before(season)
		var evening := (state["held"] as Dictionary).duplicate()
		_sleep(state)
		var batches := int(gains(state, evening).get("artisan_goods", 0))
		var start := Phases.clock_minute(state)
		var blocks := play(state, season, 18 * 60)
		var total := batches
		print("TOUR %s %d, played from %02d:%02d to dusk:" % [season, DAY_PLAYED, start / 60, start % 60])
		print("  %-9s by 06:00     made $%-5d (artisan_goods %+d)" % ["batches", batches, batches])
		for block in blocks:
			total += int(block["made"])
			print("  %-9s %02d:%02d-%02d:%02d  made $%-5d %s" % [block["activity"], int(block["from"]) / 60,
				int(block["from"]) % 60, int(block["to"]) / 60, int(block["to"]) % 60, int(block["made"]),
				_gains_text(block["gained"])])
		print("  the day made $%d" % total)
		var robot := prepare(season)
		var before := (robot["held"] as Dictionary).duplicate()
		var policy: Dictionary = Autoplay.POLICIES[&"economy"].duplicate(true)
		policy["bed_minute"] = 18 * 60
		Autoplay._a_day(robot, policy)
		print("ROBOT %s %d (economy, to 18:00): made $%d  %s" % [season, DAY_PLAYED, made(robot, before),
			_gains_text(gains(robot, before))])
	quit()


# ------------------------------------------------------------- the farm

## The farm on the morning of the season's `DAY_PLAYED`th day, its days
## before played.
static func prepare(season: StringName) -> Dictionary:
	var state := evening_before(season)
	_sleep(state)
	return state


## The same farm on the evening before: the days before played, the last
## one's work done, the night not yet slept.
static func evening_before(season: StringName) -> Dictionary:
	var state := State.create(SEED)
	var first := GameData.SEASONS.find(season) * GameData.SEASON_DAYS + 1
	state["day"] = first
	state["nights_won"] = first - 1
	var lessons: Array = []
	for step in Tutorial.steps():
		lessons.append(StringName((step as Dictionary)["id"]))
	((state["tutorial"] as Dictionary)["done"] as Array).assign(lessons)
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		state["tools"][String(tool)] = clampi(Economy.tier(season), 0, (GameData.TOOLS[tool] as Array).size() - 1)
	Shop.restock(state)
	House.leave(state)
	var plots := field(state, int((GameData.DAY_FARM["plots"] as Dictionary)[season]))
	var crops: Array = SOWN[season]
	for i in plots.size():
		var crop: StringName = crops[0] if i < plots.size() / 2 else crops[1]
		Resources.add(state, Farming.packet(crop), 1)
	if season == &"summer":
		_summer_farm(state)
	for day in DAY_PLAYED - 1:
		if day > 0:
			_sleep(state)
		work_field(state, season, 18 * 60)
		if season == &"summer":
			tend_animals(state, 18 * 60)
			tend_machines(state, season, 18 * 60)
		# Sold every evening, as a player sells: what the field and the pond
		# brought in buys the seeds that go back in.
		sell(state, season, 18 * 60)
	return state


## What a spring of money bought by summer: a coop and a barn and their
## animals (the map's moved in, the rest housed), two preserves jars on the
## strawberries spring left and a keg on melons, and the hay for them.
static func _summer_farm(state: Dictionary) -> void:
	Resources.gain(state, {GameData.WOOD: 600, GameData.STONE: 300, GameData.IRON: 40, GameData.MONEY: 1500,
		GameData.STRAWBERRY: 60, GameData.MELON: 30, GameData.HAY: 100})
	for id in [&"coop", &"barn"]:
		Building.place(state, id, _spot(state, id))
	var homes := {&"coop": [&"chicken", &"chicken"], &"barn": [&"sheep", &"sheep"]}
	for home in GameData.sorted_names(homes.keys()):
		var cell: Vector2i = Farm.cells_with(state, home)[0]
		for kind in homes[home]:
			Livestock.house(state, cell, kind)
	for id in [&"preserves_jar", &"preserves_jar", &"keg"]:
		Building.place(state, id, _spot(state, id))


## `count` plots: the starter beds, then grass turned beside them.
static func field(state: Dictionary, count: int) -> Array:
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


# ------------------------------------------------------------- the day

## Play the day's schedule to `until` (a clock minute), block by block.
## Returns each block as `{activity, from, to, made, gained}`.
static func play(state: Dictionary, season: StringName, until: int) -> Array:
	var blocks: Array = []
	for entry in SCHEDULE[season]:
		var to: int = mini(int(entry[0]), until)
		if Phases.clock_minute(state) >= to:
			continue
		var before := (state["held"] as Dictionary).duplicate()
		var from := Phases.clock_minute(state)
		match StringName(entry[1]):
			&"field":
				work_field(state, season, to)
			&"fish":
				go_fishing(state, season, to)
			&"cliff":
				work_cliff(state, season, to)
			&"animals":
				tend_animals(state, to)
			&"machines":
				tend_machines(state, season, to)
			&"sell":
				sell(state, season, to)
		blocks.append({"activity": entry[1], "from": from, "to": Phases.clock_minute(state),
			"made": made(state, before), "gained": gains(state, before)})
		if Phases.clock_minute(state) >= until:
			break
	return blocks


## **The field**: harvest what is ripe, sow what is bare - a packet in hand,
## or one paid for - and water what is dry, the can filled at the well.
static func work_field(state: Dictionary, season: StringName, until: int) -> void:
	var plots := field(state, int((GameData.DAY_FARM["plots"] as Dictionary)[season]))
	var crops: Array = SOWN[season]
	var well: Vector2i = Farm.cells_with(state, &"well")[0]
	for i in plots.size():
		if Phases.clock_minute(state) >= until:
			return
		var plot: Vector2i = plots[i]
		# On the plot itself: soil is walkable, and a cell beside it may be
		# a building's.
		SuiteKit.stand_the_farmer(state, plot)
		var verb := Farming.verb_at(state, plot)
		if verb == &"harvest" or verb == &"till":
			Sim.advance(state, int(Interact.DEFAULT_TICKS[verb]))
			Farming.act(state, plot)
			verb = Farming.verb_at(state, plot)
		if verb == &"plant":
			var crop: StringName = crops[0] if i < plots.size() / 2 else crops[1]
			Farming.select_seed(state, crop)
			# A packet in hand, or one paid for. Broke, the plot waits.
			if Resources.amount(state, Farming.packet(crop)) <= 0 \
					and Resources.spend(state, GameData.MONEY, Shop.buy_price(Farming.packet(crop))):
				Resources.add(state, Farming.packet(crop), 1)
			if Resources.amount(state, Farming.packet(crop)) > 0:
				Sim.advance(state, int(Interact.DEFAULT_TICKS[&"plant"]))
				Farming.act(state, plot)
		if Farming.crop_on(state, plot) != &"" and not Farming.is_watered(state, plot):
			if Farming.water_carried(state) <= 0:
				# **To the well and back**, every can's worth.
				Sim.advance(state, 20 * Economy.tile_ticks())
				Farming.refill_beside(state, well + Vector2i.UP)
			Sim.advance(state, 1)
			Farming.act(state, plot)
		Sim.advance(state, Economy.tile_ticks())


## **The pond**: the season's best water, cast after cast, a press while the
## marker is on the green.
static func go_fishing(state: Dictionary, season: StringName, until: int) -> void:
	var water := _fishing_spot(state, Economy.best_pond(season))
	if water.x < 0:
		return
	Sim.advance(state, 30 * Economy.tile_ticks())
	SuiteKit.stand_the_farmer(state, _shore(state, water))
	while Phases.clock_minute(state) < until:
		if not Fishing.is_casting(state):
			Fishing.begin(state, water)
			Sim.advance(state, int(Interact.DEFAULT_TICKS[&"fish"]))
			continue
		if Fishing.is_biting(state) and Fishing.in_zone(Fishing.cast_of(state)):
			Fishing.strike(state)
		Sim.advance(state, 1)
	Fishing.give_up(state)


## **The cliff and the woods**: the nodes that pay more for the time than a
## tree (`Economy.cliff_kinds`), whenever one stands, and the trees between.
static func work_cliff(state: Dictionary, season: StringName, until: int) -> void:
	var kinds := Economy.cliff_kinds(season)
	while Phases.clock_minute(state) < until:
		var cell := _standing(state, kinds)
		var walk := int(GameData.DAY_FARM["walk_to_node"])
		if cell.x < 0:
			cell = _standing(state, [&"tree"])
			walk = int(GameData.DAY_FARM["walk_to_tree"])
			if cell.x < 0:
				return
		Sim.advance(state, walk * Economy.tile_ticks())
		SuiteKit.stand_the_farmer(state, cell + Vector2i.DOWN)
		var node: Dictionary = GameData.GATHERING[StringName(Farm.occupant(state, cell)["id"])]
		for _hit in int(node["hits"]):
			Sim.advance(state, Interact.ticks_for(state, cell, &"mine"))
			Gathering.strike(state, cell)


## **The animals**: round the homes' doors to collect, and any truffle spot
## dug, walking between them.
static func tend_animals(state: Dictionary, until: int) -> void:
	var homes: Dictionary = state["housed"]
	var keys: Array = homes.keys()
	# Cell indices, so integers: a plain sort is cell order.
	keys.sort()
	for idx in keys:
		if Phases.clock_minute(state) >= until:
			return
		var door := Livestock.door_of(state, Grid.cell(int(idx)))
		Sim.advance(state, 10 * Economy.tile_ticks())
		SuiteKit.stand_the_farmer(state, door + Vector2i.DOWN)
		Sim.advance(state, int(Interact.DEFAULT_TICKS[&"collect"]))
		Livestock.collect(state, door)
	for spot in Livestock.spots(state):
		Sim.advance(state, 4 * Economy.tile_ticks() + int(Interact.DEFAULT_TICKS[&"dig"]))
		Livestock.dig(state, spot)


## **The machines**: each one done is filled again - the farm's own goods,
## or what only the stall sells (the jelly's sugar) at its price.
static func tend_machines(state: Dictionary, season: StringName, until: int) -> void:
	var recipes := {&"preserves_jar": &"make_jelly", &"keg": &"make_juice"}
	for station in GameData.sorted_names(recipes.keys()):
		for cell in Farm.cells_with(state, station):
			if Phases.clock_minute(state) >= until:
				return
			if Building.anchor_of(state, cell) != cell or Crafting.busy(state, cell):
				continue
			var id: StringName = recipes[station]
			var inputs: Dictionary = GameData.RECIPES[id]["inputs"]
			if not Resources.can_afford(state, inputs):
				for res in GameData.sorted_names(inputs.keys()):
					var short := int(inputs[res]) - Resources.amount(state, res)
					if short > 0 and Economy.input_cost(season, res) > 0 \
							and Resources.spend(state, GameData.MONEY, short * Shop.buy_price(res)):
						Resources.add(state, res, short)
				if not Resources.can_afford(state, inputs):
					continue
			Sim.advance(state, 6 * Economy.tile_ticks() + int(Interact.DEFAULT_TICKS[&"craft"]))
			SuiteKit.stand_the_farmer(state, cell + Vector2i(0, Building.size_of(station).y))
			state["player"]["facing"] = Player.NORTH
			Crafting.start(state, cell, id)


## **Selling** at the stall: the crops, the fish, the animals' and the
## machines' goods - all but what the machines are fed (`KEPT`). The
## materials are kept for building. Turning goods into coins makes nothing.
static func sell(state: Dictionary, season: StringName, until: int) -> void:
	var kept: Array = KEPT.get(season, [])
	Sim.advance(state, 20 * Economy.tile_ticks())
	# At the bin by the stall, where the day ends.
	SuiteKit.stand_the_farmer(state, Farm.cells_with(state, Shipping.BIN)[0] + Vector2i.RIGHT)
	state["player"]["facing"] = Player.WEST
	var groups := [&"crops", GameData.FISH, &"animal_goods", &"artisan_goods"]
	for group in groups:
		for id in GameData.group_members(group):
			var n := Resources.amount(state, id)
			if n > 0 and id != GameData.FOOD and not kept.has(id):
				Shop.sell(state, id, n)
	if Phases.clock_minute(state) < until:
		Sim.advance(state, Phases.tick_at_minute(until) - int(state["day_tick"]))


# ------------------------------------------------------------- the sums

## What the farm made since `before`, at what the stall pays, and its money.
static func made(state: Dictionary, before: Dictionary) -> int:
	var money := Resources.amount(state, GameData.MONEY) - int(before.get(GameData.MONEY, 0))
	for id in GameData.RESOURCES:
		if id == GameData.MONEY:
			continue
		money += (Resources.amount(state, id) - int(before.get(id, 0))) * int(GameData.SELL_PRICE.get(id, 0))
	return money


## What it gained and spent since `before`, by kind: `{group: money}`, the
## money itself as `money`.
static func gains(state: Dictionary, before: Dictionary) -> Dictionary:
	var out := {}
	for id in GameData.RESOURCES:
		var delta := Resources.amount(state, id) - int(before.get(id, 0))
		if delta == 0:
			continue
		var group := "money" if id == GameData.MONEY else String(_group_of(id))
		var worth := delta if id == GameData.MONEY else delta * int(GameData.SELL_PRICE.get(id, 0))
		out[group] = int(out.get(group, 0)) + worth
	return out


## The inventory group a resource is in.
static func _group_of(id: StringName) -> StringName:
	for entry in GameData.RESOURCE_GROUPS:
		if ((entry as Dictionary)["members"] as Array).has(id):
			return StringName((entry as Dictionary)["name"])
	return &"other"


static func _gains_text(gained: Dictionary) -> String:
	var parts: Array = []
	for group in GameData.sorted_names(gained.keys()):
		if int(gained[group]) != 0:
			parts.append("%s %+d" % [group, int(gained[group])])
	return "(" + ", ".join(parts) + ")"


# ------------------------------------------------------------- helpers

static func _standing(state: Dictionary, kinds: Array) -> Vector2i:
	for kind in kinds:
		for cell in Farm.cells_with(state, kind):
			if Gathering.why_not(state, cell).is_empty():
				return cell
	return Vector2i(-1, -1)


static func _fishing_spot(state: Dictionary, pond: StringName) -> Vector2i:
	var at: Array = GameData.PONDS[pond]
	var centre := Vector2i(int(at[0]), int(at[1]))
	for radius in 16:
		for cell in Grid.within(centre, radius):
			if Grid.in_bounds(cell) and Farm.terrain_at(state, cell) == Farm.Terrain.WATER \
					and Farm.pond_of(state, cell) == pond and _shore(state, cell).x >= 0:
				return cell
	return Vector2i(-1, -1)


static func _shore(state: Dictionary, water: Vector2i) -> Vector2i:
	for step in Grid.STEPS:
		var cell: Vector2i = water + step
		if Grid.in_bounds(cell) and Farm.terrain_at(state, cell) != Farm.Terrain.WATER and Farm.walkable(state, cell):
			return cell
	return Vector2i(-1, -1)


## Where a player puts a shed: the open grass nearest the house, off the
## beds and with a cell to walk round it - or, with none, the first free cell.
## (The autoplayer's `_room_for` puts the barn on the starter beds.)
static func _spot(state: Dictionary, id: StringName) -> Vector2i:
	var size := Building.size_of(id)
	var beds := {}
	for cell in Farming.field_cells(state):
		beds[cell] = true
	var home := Farm.house_centre(state)
	var best := Vector2i(-1, -1)
	var best_far := 1 << 30
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		var far := absi(cell.x - home.x) + absi(cell.y - home.y)
		if far < best_far and _open_grass(state, cell, size, beds) and Building.can_place(state, id, cell):
			best = cell
			best_far = far
	if best.x >= 0:
		return best
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Building.can_place(state, id, cell):
			return cell
	return Vector2i(-1, -1)


## Whether `size` cells from `at`, and the ring of cells round them, are all
## open grass off the beds.
static func _open_grass(state: Dictionary, at: Vector2i, size: Vector2i, beds: Dictionary) -> bool:
	for dy in range(-1, size.y + 1):
		for dx in range(-1, size.x + 1):
			var cell := at + Vector2i(dx, dy)
			if not Grid.in_bounds(cell) or beds.has(cell) or not Farm.buildable(state, cell) \
					or Farm.terrain_at(state, cell) != Farm.Terrain.GRASS:
				return false
	return true


static func _sleep(state: Dictionary) -> void:
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	House.leave(state)
