extends SceneTree

## Play all ten nights with a scripted build and report which ones fell.
##
##     python tools/play_nights.py
##
## This is the **instrument task 0060 authors against**. `tools/nights.py`
## reads the table; this one runs it, so a curve that looks smooth on paper
## can be checked against a curve that is actually survivable.
##
## ## What the scripted player does
##
## It is not the autoplayer of task 0067 - it never farms, never repairs and
## never fires a flare. It builds what the table below says it has by that
## night and then watches, which is the floor: a real player who also mends a
## wall and spends a flare does strictly better. So a night this loses is a
## night that is too hard, and a night this wins comfortably may still be a
## fair fight for somebody playing badly.
##
## The build is deliberately **not** in `GameData`: it is a test fixture, not
## a lever, and putting it in the tables would be inviting somebody to tune
## the game to suit the robot.

## What a day of farming might be worth, in goods, to the scripted player.
##
## **A guess, and the most important number in this file.** At $300 a day it
## is roughly two thirds of the purse by night ten, so the curve this tool
## reports is mostly a report about this constant. Rather than pick one and
## pretend, the run sweeps three: a player who never farms, one who farms a
## little, one who farms hard. A night that falls at every income is too hard
## and one that holds at every income is too easy.
##
## The real number is measured by the autoplayer at task 0067 and the curve
## is settled against it at 0068. This is the instrument, not the verdict.
const INCOMES: Array = [0, 150, 300]

## What the scripted player buys, in the order it buys it, going round again
## until the money runs out. A generator goes in whenever the next tower would
## draw more than the farm supplies, so power is bought rather than given.
const SHOPPING: Array = [
	&"gun_tower", &"auto_crossbow", &"wall", &"mortar",
	&"auto_crossbow", &"gun_tower", &"wall",
]


func _init() -> void:
	var problems := GameData.validate()
	if not problems.is_empty():
		print("the tables do not validate:")
		for line in problems:
			print("  ", line)
		quit(1)
		return

	print("HARVEST THE NIGHT - ten nights, scripted build, no player")

	for income in INCOMES:
		print("")
		print("  a day of farming worth $%d" % int(income))
		print("  night  sent  $reward  $purse  towers  power  result")
		var fell: Array = []
		var purse := 0
		for night in range(1, GameData.MVP_NIGHTS + 1):
			var played := _play(night, purse)
			# What the night paid, for the next one's budget. A night that
			# fell still pays for what was killed before it fell.
			purse += Waves.reward_of(night) + int(income)
			if not bool(played["held"]):
				fell.append(night)
			print("  %5d %5d  %7d %7d %7d %5d%%  %s"
				% [night, Waves.size_of(night), Waves.reward_of(night),
					int(played["budget"]), int(played["towers"]),
					int(played["power"]),
					"held, house %d/%d after %ds"
						% [int(played["house"]), int(played["house_full"]),
							int(played["ticks"]) / GameData.TICK_HZ]
						if bool(played["held"])
						else "FELL after %ds with %d still coming"
							% [int(played["ticks"]) / GameData.TICK_HZ,
								int(played["left"])]])
		if fell.is_empty():
			print("  all ten held")
		else:
			print("  fell: %s" % str(fell))

	_curves()
	quit()


## Print the two curves the done-when asks for as numbers.
func _curves() -> void:
	print("")
	print("  night   sent   $reward   hit points sent")
	var last_sent := 0
	var last_money := 0
	var last_meat := 0
	var bumps: Array = []
	for night in range(1, GameData.MVP_NIGHTS + 1):
		var sent := Waves.size_of(night)
		var money := Waves.reward_of(night)
		var meat := _hit_points_of(night)
		var mark := ""
		if night > 1 and (sent < last_sent or money < last_money
				or meat < last_meat):
			mark = "  <- dips"
			bumps.append(night)
		print("  %5d %6d %9d %17d%s" % [night, sent, money, meat, mark])
		last_sent = sent
		last_money = money
		last_meat = meat
	if bumps.is_empty():
		print("  every curve climbs")
	else:
		print("  dips on %s" % str(bumps))


## Everything a night sends, weighed by hit points: the honest measure of how
## much there is to kill, since a tank is not a walker.
func _hit_points_of(night: int) -> int:
	var total := 0
	for row in Waves.table(night):
		var kind: Dictionary = GameData.ENEMIES[(row as Array)[0]]
		total += int(kind["hp"]) * int((row as Array)[1])
	return total


## How many generators the shopping list will want out of this purse: the
## buying loop below run on numbers alone, buying a plant whenever the next
## thing's draw would outrun the supply - which is what the loop itself did
## in the build step before task 0132 put production buildings on the day.
func _plants_needed(budget: int) -> int:
	var left := budget
	var supply := GameData.BASE_ENERGY
	var draw := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)
		.get("energy_draw", 0))
	var plants := 0
	var plant_price := _price(&"generator")
	var at := 0
	while at < SHOPPING.size() * 12:
		var id: StringName = SHOPPING[at % SHOPPING.size()]
		at += 1
		var price := _price(id)
		var wants := int((Building.entry_of(id) as Dictionary)
			.get("energy_draw", 0))
		while draw + wants > supply and left >= plant_price + price:
			left -= plant_price
			supply += _made()
			plants += 1
		if draw + wants > supply or left < price:
			continue
		left -= price
		draw += wants
	return plants


## What one generator makes.
func _made() -> int:
	return int((GameData.BUILDINGS[&"generator"] as Dictionary)["energy_output"])


## One night, on a farm built out of a budget.
func _play(night: int, budget: int) -> Dictionary:
	var state := State.create(5000 + night)
	# `night` follows `nights_won` since task 0065, so a fixture that picks a
	# night has to say which nights are behind it.
	state["night"] = night
	state["day"] = night
	state["nights_won"] = night - 1
	# Materials and power are not what is being measured: the build is.
	Resources.gain(state, {GameData.WOOD: 9000, GameData.STONE: 9000,
		GameData.IRON: 9000, GameData.OIL: 9000, GameData.GUNPOWDER: 9000,
		GameData.FOOD: 9000})

	# **Power by day, towers by night** (task 0132): a generator goes up by day
	# only, so the ones the shopping list will need are counted first, off the
	# same purse and in the same order, and put up before the build step.
	var plants := _plants_needed(budget)
	var plant_price := _price(&"generator")
	for _i in plants:
		var plant := _room(state, Building.size_of(&"generator"))
		if plant.x < 0 or not Building.place(state, &"generator", plant):
			break
	Phases.begin_preparation(state)

	# **The tutorial's tower.** Night one is meant to be beatable with the one
	# thing the first day buys you, so the scripted player has it before it
	# has a penny - which is what the requirement actually says.
	var towers := 0
	var spot := _room(state, Building.size_of(&"gun_tower"))
	if spot.x >= 0 and Building.place(state, &"gun_tower", spot):
		towers += 1

	# **Spend the purse, in order, until it will not stretch.**
	#
	# Supply and draw are counted here rather than asked of `Power`, which
	# only recomputes on a tick: an earlier version asked it mid-shop, never
	# saw the draw it had just added, and bought a crossbow line that ran at
	# the twenty-five percent floor all ten nights.
	var left := budget - plants * plant_price
	var supply := GameData.BASE_ENERGY + plants * _made()
	var draw := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)
		.get("energy_draw", 0))
	var at := 0
	while at < SHOPPING.size() * 12:
		var id: StringName = SHOPPING[at % SHOPPING.size()]
		at += 1
		var price := _price(id)
		var wants := int((Building.entry_of(id) as Dictionary)
			.get("energy_draw", 0))
		if draw + wants > supply or left < price:
			continue
		var where := _room(state, Building.size_of(id))
		if where.x < 0:
			break
		if Building.place(state, id, where):
			left -= price
			draw += wants
			if id != &"wall":
				towers += 1
	NightRoad.through_build(state)

	var ticks := 0
	for tick in 40000:
		if int(state["phase"]) != Phases.NIGHT:
			ticks = tick
			break
		Sim.advance(state, 1)
		ticks = tick
	return {
		"held": int(state["house_hp"]) > 0,
		"power": Power.percent(state),
		"house": int(state["house_hp"]),
		"house_full": Phases.house_full(state),
		"ticks": ticks,
		"towers": towers,
		"left": Waves.remaining(state),
		"budget": budget,
		"unspent": left,
	}


## What a thing is worth in goods, which is what the scripted purse counts in.
func _price(id: StringName) -> int:
	var total := 0
	var cost := Building.cost_of(id)
	for res in GameData.sorted_names(cost.keys()):
		total += int(cost[res]) * int(GameData.SELL_PRICE.get(res, 1))
	return total


## Somewhere to put a tower **where it can see the way in**.
##
## The first version of this scanned from (0, 0) and put the whole build in
## the top-left corner of the farm, nowhere near the lane: night one fell with
## a tower that never fired. A player puts towers on the approach, so this
## starts at the house and works east, which is where they come from.
func _room(state: Dictionary, size: Vector2i) -> Vector2i:
	for x in range(18, Grid.WIDTH - size.x):
		for y in range(2, Grid.HEIGHT - size.y - 1):
			var clear := true
			for dy in size.y:
				for dx in size.x:
					if not Farm.buildable(state, Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				return Vector2i(x, y)
	# Nothing left on the approach: take whatever is going.
	return _anywhere(state, size)


func _anywhere(state: Dictionary, size: Vector2i) -> Vector2i:
	for y in range(Grid.HEIGHT - size.y):
		for x in range(Grid.WIDTH - size.x):
			var clear := true
			for dy in size.y:
				for dx in size.x:
					if not Farm.buildable(state, Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				return Vector2i(x, y)
	return Vector2i(-1, -1)
