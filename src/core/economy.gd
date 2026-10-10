class_name Economy
extends RefCounted

## **The day's money, computed** (task 0194): what a well-worked day of each
## way of earning brings in at the start of a season, from the tables alone
## and never by playing it (`tools/balance.py` plays the days). The ways are
## the field, the pond, the cliff and the woods, the animals and the
## machines.
##
## The day runs from 06:00 to dusk, and the animals' to bedtime, because
## collecting is a moment. Its money is what the day makes, at what the stall
## pays, less what it has to buy there: an input the season makes for itself
## costs nothing that day. The farm under it is `GameData.DAY_FARM`, and a
## strategy without the means in a season is -1.
##
## Node-free and deterministic like the rest of `src/core/`: integer money,
## tables walked in sorted order.

const STRATEGIES: Array = [&"crops", &"fishing", &"mining", &"animals", &"artisan"]


## A well-worked day of `strategy` at the start of `season`, in money, or -1
## when the season has no means for it.
static func day(strategy: StringName, season: StringName) -> int:
	match strategy:
		&"crops":
			return crops(season)
		&"fishing":
			return fishing(season)
		&"mining":
			return mining(season)
		&"animals":
			return animals(season)
		&"artisan":
			return artisan(season)
	return -1


## The working day: 06:00 to dusk, in ticks.
static func work_ticks() -> int:
	return Phases.tick_at_minute(GameData.DUSK_MINUTE)


## The tier the season's tools have reached.
static func tier(season: StringName) -> int:
	return int((GameData.DAY_FARM["tool_tier"] as Dictionary).get(season, 0))


## A tile's walk, in ticks.
static func tile_ticks() -> int:
	return maxi(Player.SUBTILE / GameData.PLAYER_SPEED, 1)


# ------------------------------------------------------------------ the field

## **The field**: the season's best money crop on the season's plots - a
## season's harvests less its packets, by the day. -1 when nothing is sown
## in the season.
static func crops(season: StringName) -> int:
	var plots := int((GameData.DAY_FARM["plots"] as Dictionary).get(season, 0))
	var crop := best_crop(season)
	if plots <= 0 or crop == &"":
		return -1
	return plot_season_money(crop) * plots / GameData.SEASON_DAYS


## The crop sown in `season` that makes the most on one plot over a season,
## the first by name on a tie.
static func best_crop(season: StringName) -> StringName:
	var best := &""
	for crop in GameData.sorted_names(GameData.CROPS.keys()):
		if not (GameData.CROPS[crop]["seasons"] as Array).has(season):
			continue
		if best == &"" or plot_season_money(crop) > plot_season_money(best):
			best = crop
	return best


## What one plot of `crop` makes in a season sown on its first morning: every
## harvest at what the stall pays, less every packet. A crop that grows back
## is sown once; one that does not is sown again after each harvest, and not
## where it would not ripen before the season ends.
static func plot_season_money(crop: StringName) -> int:
	var entry: Dictionary = GameData.CROPS[crop]
	var grow := int(entry["growth_days"])
	var again := int(entry.get("regrow_days", 0))
	var harvests := 0
	var packets := 0
	var day := 1
	if again > 0:
		packets = 1
		var wait := grow
		while day + wait <= GameData.SEASON_DAYS:
			harvests += 1
			day += wait
			wait = again
	else:
		while day + grow <= GameData.SEASON_DAYS:
			packets += 1
			harvests += 1
			day += grow
	return harvests * int(entry["yield"]) * int(GameData.SELL_PRICE.get(crop, 0)) \
		- packets * int(entry["seed_cost"])


# ------------------------------------------------------------------- the pond

## **The pond**: casts from 06:00 to dusk at the season's best water. Each
## cast takes the mean wait for a bite on the season's rod - which starts
## with the throw, so the throw is inside it - and the landing; each catch is
## worth the mean of what bites there over the day's hours, weighed as
## `Fishing.draw` weighs it.
static func fishing(season: StringName) -> int:
	var rod: Dictionary = GameData.TOOLS[&"rod"][clampi(tier(season), 0, (GameData.TOOLS[&"rod"] as Array).size() - 1)]
	var wait := (int(GameData.FISHING["bite_min_ticks"]) + int(GameData.FISHING["bite_max_ticks"])) / 2 \
		* int(rod["bite_percent"]) / 100
	var cast := maxi(int(Interact.DEFAULT_TICKS[&"fish"]), wait) + int(GameData.DAY_FARM["landing_ticks"])
	return work_ticks() * catch_hundredths(best_pond(season), season, int(rod["rare_percent"])) / (cast * 100)


## The water that pays the most in `season` on the season's rod, the first by
## name on a tie.
static func best_pond(season: StringName) -> StringName:
	var rod: Dictionary = GameData.TOOLS[&"rod"][clampi(tier(season), 0, (GameData.TOOLS[&"rod"] as Array).size() - 1)]
	var best := &""
	for pond in GameData.sorted_names(GameData.PONDS.keys()):
		if best == &"" or catch_hundredths(pond, season, int(rod["rare_percent"])) \
				> catch_hundredths(best, season, int(rod["rare_percent"])):
			best = pond
	return best


## What a catch at `pond` in `season` is worth on average, in hundredths of
## money, over the working day's hours: `Fishing.catchable` at each hour,
## each species weighed by `Fishing.weight_of` at the rod's `rare`.
static func catch_hundredths(pond: StringName, season: StringName, rare: int) -> int:
	var total := 0
	var hours := 0
	for minute in range(GameData.DAY_START_MINUTE, GameData.DUSK_MINUTE, 60):
		var weight := 0
		var worth := 0
		for id in Fishing.catchable(pond, season, minute):
			var each := Fishing.weight_of(id, rare)
			weight += each
			worth += each * int(GameData.SELL_PRICE.get(id, 0))
		if weight > 0:
			total += worth * 100 / weight
			hours += 1
	return total / maxi(hours, 1)


# ------------------------------------------------------- the cliff and the woods

## **The cliff and the woods** (plan section 3.3, "mine and cut"): the
## worker takes whatever pays more for the time. The cliff's nodes that pay
## more a tick than a tree (`cliff_kinds`) are taken as often as they come
## back between 06:00 and dusk, walked to, and the rest of the day goes to
## the trees.
static func mining(season: StringName) -> int:
	var work := work_ticks()
	var money := 0
	var used := 0
	for node in cliff_kinds(season):
		var entry: Dictionary = GameData.GATHERING[node]
		var swings := swing_ticks(entry, &"pickaxe", season) * int(entry["hits"])
		var harvests := 1 + maxi(work - swings, 0) / (int(entry["regrow_ticks"]) + swings)
		money += map_count(node) * harvests * gathered_worth(entry)
		used += map_count(node) * harvests * harvest_ticks(entry, &"pickaxe", season)
	var tree: Dictionary = GameData.GATHERING[&"tree"]
	money += maxi(work - used, 0) / harvest_ticks(tree, &"axe", season) * gathered_worth(tree)
	return money


## **The cliff's nodes worth leaving the trees for** in `season`: those that
## come back, are open by then and the season's pickaxe can work, and pay
## more a tick than a tree, walked to - dearest a tick first, then by name.
static func cliff_kinds(season: StringName) -> Array:
	var tree: Dictionary = GameData.GATHERING[&"tree"]
	var tree_worth := gathered_worth(tree)
	var tree_ticks := harvest_ticks(tree, &"axe", season)
	var by := GameData.SEASONS.find(season)
	var kinds: Array = []
	for node in GameData.sorted_names(GameData.GATHERING.keys()):
		var entry: Dictionary = GameData.GATHERING[node]
		if StringName(entry.get("tool", &"")) != &"pickaxe" or int(entry.get("regrow_ticks", 0)) <= 0:
			continue
		if GameData.SEASONS.find(StringName(entry.get("first_season", GameData.SEASONS[0]))) > by \
				or int(entry.get("min_tier", 0)) > tier(season):
			continue
		if gathered_worth(entry) * tree_ticks > tree_worth * harvest_ticks(entry, &"pickaxe", season):
			kinds.append(node)
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool:
		var rate_a := gathered_worth(GameData.GATHERING[a]) * harvest_ticks(GameData.GATHERING[b], &"pickaxe", season)
		var rate_b := gathered_worth(GameData.GATHERING[b]) * harvest_ticks(GameData.GATHERING[a], &"pickaxe", season)
		return rate_a > rate_b or (rate_a == rate_b and String(a) < String(b)))
	return kinds


## What one harvest of a node is worth at the stall.
static func gathered_worth(entry: Dictionary) -> int:
	var worth := 0
	for res in GameData.sorted_names((entry["yield"] as Dictionary).keys()):
		worth += int(entry["yield"][res]) * int(GameData.SELL_PRICE.get(res, 0))
	return worth


## The ticks one harvest of a node takes with the season's tool: every
## swing, and the walk to it - a node on the cliff, or the next tree.
static func harvest_ticks(entry: Dictionary, tool: StringName, season: StringName) -> int:
	var walk := int(GameData.DAY_FARM["walk_to_tree" if tool == &"axe" else "walk_to_node"])
	return swing_ticks(entry, tool, season) * int(entry["hits"]) + walk * tile_ticks()


## One swing at a node with the season's tool, as `Interact.ticks_for` times
## it (without the tech tree, which is the night's to pay for).
static func swing_ticks(entry: Dictionary, tool: StringName, season: StringName) -> int:
	var ladder: Array = GameData.TOOLS[tool]
	var percent := int((ladder[clampi(tier(season), 0, ladder.size() - 1)] as Dictionary).get("gather_percent", 100))
	return maxi(int(entry["work_ticks"]) * 100 / maxi(percent, 1), 1)


## How many cells of the farm map a node stands on.
static func map_count(id: StringName) -> int:
	var count := 0
	for row in GameData.FARM_MAP:
		for at in String(row).length():
			var key := String(row)[at]
			if GameData.MAP_LEGEND.has(key) and StringName(GameData.MAP_LEGEND[key][1]) == id:
				count += 1
	return count


# ---------------------------------------------------------------- the animals

## **The animals**: the season's herd, collected promptly from its morning
## feed to bedtime (`animal_bed_minute`). Each animal's clock runs only by
## day, so a cow gives a pail every `every_ticks` of the day lived - nearly
## three, a hen nearly four and a half eggs, a sheep most of a fleece - and a
## fed pig its spots dug. Less its hay, at the stall's price while the stall
## is where the season's hay comes from (`input_cost`). -1 without a herd.
static func animals(season: StringName) -> int:
	var herd: Dictionary = (GameData.DAY_FARM["herd"] as Dictionary).get(season, {})
	if herd.is_empty():
		return -1
	var lived := Phases.tick_at_minute(int(GameData.DAY_FARM["animal_bed_minute"]))
	var hay := input_cost(season, GameData.ANIMAL_FEED)
	var hundredths := 0
	for kind in GameData.sorted_names(herd.keys()):
		var entry: Dictionary = GameData.LIVESTOCK[kind]
		var each := 0
		for res in GameData.sorted_names((entry["produces"] as Dictionary).keys()):
			each += lived * 100 / int(entry["every_ticks"]) * int(entry["produces"][res]) \
				* int(GameData.SELL_PRICE.get(res, 0))
		for res in GameData.sorted_names(GameData.DIG_GIVES.keys()):
			each += 100 * int(entry.get("digs", 0)) * int(GameData.DIG_GIVES[res]) * int(GameData.SELL_PRICE.get(res, 0))
		each -= 100 * int(entry.get("feed_per_day", 0)) * hay
		hundredths += int(herd[kind]) * each
	return hundredths / 100


# --------------------------------------------------------------- the machines

## **The machines**: each of the season's runs its recipe without a break on
## the farm's own goods, its batches by the morning (`Crafting.days_of`),
## sold - less any input the stall is the season's only source of, such as
## sugar before the autumn's beets. -1 without machines.
static func artisan(season: StringName) -> int:
	var machines: Dictionary = (GameData.DAY_FARM["machines"] as Dictionary).get(season, {})
	if machines.is_empty():
		return -1
	var hundredths := 0
	for id in GameData.sorted_names(machines.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		var batch := 0
		for res in GameData.sorted_names((recipe["output"] as Dictionary).keys()):
			batch += int(recipe["output"][res]) * int(GameData.SELL_PRICE.get(res, 0))
		for res in GameData.sorted_names((recipe["inputs"] as Dictionary).keys()):
			batch -= int(recipe["inputs"][res]) * input_cost(season, res)
		hundredths += int(machines[id]) * batch * 100 / maxi(Crafting.days_of(id), 1)
	return hundredths / 100


## **What an input costs the day** (task 0194): nothing when the season makes
## it without the stall (0193's `seasonal_supply`, with the stall's shelves
## empty) - it is the farm's own - and the stall's price when the stall is
## the only place the season gets it.
static func input_cost(season: StringName, res: StringName) -> int:
	if GameData.seasonal_supply(season, GameData.RECIPES, {}, {}).has(res):
		return 0
	return Shop.buy_price(res)
