extends SceneTree

## Play a range of the calendar's nights with a scripted build and report
## which ones fell.
##
##     python tools/play_nights.py [from] [to]
##     godot --headless --path . --script res://src/tools/play_nights.gd -- 1 14
##
## **A range of dates** (task 0271): `python tools/play_nights.py 15 28`
## plays summer; one argument plays from day 1 to it, and none plays spring,
## `DEFAULT_DAYS`. Every date is played on its own farm, built out of a purse
## that **starts where a run would be**: what each earlier date paid, held
## with everything killed, and a day's income for each - so summer's first
## night is bought with spring's money whether spring was played or not.
##
## This is the **instrument the nights are authored against** - task 0060's
## ten, and from 0271 the seasons. `tools/nights.py` reads the tables; this
## one runs them, so a curve that looks smooth on paper can be checked against
## a curve that is actually survivable.
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
## **It buys only what the date's season has opened** (task 0234's
## `unlock_season`, `Building.unlocked`), and a price is its money and its
## materials (0234) at what the materials sell for. What it put down is
## checked against the date again, and a night that has anything its season
## has not opened says so in the `locked` column - which should always be 0.
##
## The build is deliberately **not** in `GameData`: it is a test fixture, not
## a lever, and putting it in the tables would be inviting somebody to tune
## the game to suit the robot.

## What a day of farming might be worth, in goods, to the scripted player.
##
## **A guess, and the most important number in this file.** At $300 a day it
## is most of the purse by the end of spring, so the curve this tool reports
## is mostly a report about this constant. Rather than pick one and pretend,
## the run sweeps three: a player who never farms, one who farms a little, one
## who farms hard. A night that falls at every income is too hard and one that
## holds at every income is too easy.
##
## The real number is measured by the autoplayer at task 0067 and the curve
## is settled against it at 0068. This is the instrument, not the verdict.
const INCOMES: Array = [0, 150, 300]

## The dates played when none is given: spring, the season task 0271
## authored against it.
const DEFAULT_DAYS := 14

var _first := 1
var _last := DEFAULT_DAYS

## What the scripted player buys, in the order it buys it, going round again
## until the money runs out - what the date's season has opened of it. A
## generator goes in whenever the next tower would draw more than the farm
## supplies, so power is bought rather than given.
##
## **Summer's flamethrower** (task 0272): the rats' answer in summer's
## arsenal (0259's `implementation/MATCHUPS.md`), so a summer night is played
## with what summer opened. Spring's list is what it was: the season filter
## takes it out until then.
const SHOPPING: Array = [
	&"gun_tower", &"auto_crossbow", &"flame_tower", &"wall", &"mortar",
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

	var numbers: Array = []
	for arg in OS.get_cmdline_user_args():
		if str(arg).is_valid_int():
			numbers.append(int(str(arg)))
	if numbers.size() == 1:
		_last = maxi(int(numbers[0]), 1)
	elif numbers.size() > 1:
		_first = maxi(int(numbers[0]), 1)
		_last = maxi(int(numbers[1]), _first)
	print("HARVEST THE NIGHT - days %d to %d, scripted build, no player"
		% [_first, _last])

	for income in INCOMES:
		print("")
		print("  a day of farming worth $%d" % int(income))
		# **Where a run would be** by the first date: every earlier date's
		# pay and a day's income for each.
		var purse := 0
		for night in range(1, _first):
			purse += _paid(night) + int(income)
		if _first > 1:
			print("  the purse at day %d: $%d from days 1-%d" % [_first, purse, _first - 1])
		print("   day  sent  $reward  $purse  towers  locked  power  bones  piles  peak  crows  result")
		var fell: Array = []
		for night in range(_first, _last + 1):
			var played := _play(night, purse)
			# What the night paid, for the next one's budget. A night that
			# fell still pays for what was killed before it fell. Since task
			# 0219 that is the fee and `bounty_percent` of the kills' worth.
			purse += _paid(night) + int(income)
			if not bool(played["held"]):
				fell.append(night)
			print("  %4d %5d  %7d %7d %7d %7d %5d%%  %5d  %5d  %4d  %5d  %s"
				% [night, Waves.size_of(night), Waves.reward_of(night),
					int(played["budget"]), int(played["towers"]),
					int(played["locked"]), int(played["power"]),
					int(played["bones"]), int(played["piles"]),
					int(played["peak"]), int(played["crows"]),
					"held, house %d/%d after %ds"
						% [int(played["house"]), int(played["house_full"]),
							int(played["ticks"]) / GameData.TICK_HZ]
						if bool(played["held"])
						else "FELL after %ds with %d still coming"
							% [int(played["ticks"]) / GameData.TICK_HZ,
								int(played["left"])]])
		if fell.is_empty():
			print("  all %d held" % (_last - _first + 1))
		else:
			print("  fell: %s" % str(fell))

	_curves()
	quit()


## **What a date's night pays the scripted player**, held with everything
## killed: the fee and `bounty_percent` of the kills' worth (task 0219), and
## on a Full Moon the moon's own line on top (0152) - what
## `Rewards._money_from` adds up, less the structure bonuses a build earns.
func _paid(night: int) -> int:
	var table: Dictionary = GameData.REWARDS
	var ordinary := int(table["base_money"]) + int(table["money_per_night"]) * night \
		+ Waves.reward_of(night) * int(table["bounty_percent"]) / 100
	if Calendar.is_full_moon(night):
		ordinary += ordinary * (GameData.FULL_MOON_REWARD_PERCENT - 100) / 100
	return ordinary


## Print the curves the authoring reads, as numbers.
func _curves() -> void:
	print("")
	print("   day   sent   $reward   hit points sent")
	var last_sent := 0
	var last_money := 0
	var last_meat := 0
	var bumps: Array = []
	for night in range(_first, _last + 1):
		var sent := Waves.size_of(night)
		var money := Waves.reward_of(night)
		var meat := Waves.hit_points_in(Waves.night_of(night))
		var mark := ""
		if night > _first and (sent < last_sent or money < last_money
				or meat < last_meat):
			mark = "  <- dips"
			bumps.append(night)
		print("  %4d %6d %9d %17d%s" % [night, sent, money, meat, mark])
		last_sent = sent
		last_money = money
		last_meat = meat
	if bumps.is_empty():
		print("  every curve climbs")
	else:
		print("  dips on %s" % str(bumps))


## The shopping list as the date's season has opened it.
func _shopping(state: Dictionary) -> Array:
	var out: Array = []
	for id in SHOPPING:
		if Building.unlocked(state, StringName(id)):
			out.append(id)
	return out


## How many generators the shopping list will want out of this purse: the
## buying loop below run on numbers alone, buying a plant whenever the next
## thing's draw would outrun the supply - which is what the loop itself did
## in the build step before task 0132 put production buildings on the day.
func _plants_needed(budget: int, shopping: Array) -> int:
	if shopping.is_empty():
		return 0
	var left := budget
	var supply := GameData.BASE_ENERGY
	var draw := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)
		.get("energy_draw", 0))
	var plants := 0
	var plant_price := _price(&"generator")
	var at := 0
	while at < shopping.size() * 12:
		var id: StringName = shopping[at % shopping.size()]
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
	# `night` is the calendar day's since task 0151, so a fixture that picks
	# a night picks its day; the nights behind it are said for the record.
	state["night"] = night
	state["day"] = night
	state["nights_won"] = night - 1
	# Materials and power are not what is being measured: the build is. The
	# money shares come off the ledger (task 0234); the purse below decides.
	Resources.gain(state, {GameData.WOOD: 9000, GameData.STONE: 9000,
		GameData.IRON: 9000, GameData.OIL: 9000, GameData.GUNPOWDER: 9000,
		GameData.INCENDIARY: 9000, GameData.FOOD: 9000, GameData.MONEY: 9000})
	var shopping := _shopping(state)

	# **Power by day, towers by night** (task 0132): a generator goes up by day
	# only, so the ones the shopping list will need are counted first, off the
	# same purse and in the same order, and put up before the build step.
	var plants := _plants_needed(budget, shopping)
	var plant_price := _price(&"generator")
	# **Out of every road's way** (task 0273): a plant needs no sight of the
	# lane, so it goes on the free ground farthest from the date's open
	# sides. 0271 put them on the first free ground from the top of the
	# farm, which is where the north road starts: from autumn the night took
	# every plant and left the towers at the brownout floor.
	var away := _away_from_the_sides(state)
	for _i in plants:
		var plant := _first_free(state, away, &"generator")
		if plant.x < 0 or not Building.place(state, &"generator", plant):
			break
	Phases.begin_preparation(state)

	# **The tutorial's tower.** Night one is meant to be beatable with the one
	# thing the first day buys you, so the scripted player has it before it
	# has a penny - which is what the requirement actually says - and puts it
	# **where the tutorial's line points** (0141, task 0271), the ground a
	# third of the way from the house to the horde.
	var towers := 0
	var nearest := _by_distance(Tutorial._between_house_and_spawn(state))
	var spot := _first_free(state, nearest, &"gun_tower")
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
	while not shopping.is_empty() and at < shopping.size() * 12:
		var id: StringName = shopping[at % shopping.size()]
		at += 1
		var price := _price(id)
		var wants := int((Building.entry_of(id) as Dictionary)
			.get("energy_draw", 0))
		if draw + wants > supply or left < price:
			continue
		# **Round the same ground, nearest first** (task 0271): the purse's
		# defences stand where the tutorial's tower does, on the way in.
		var where := _first_free(state, nearest, id)
		if where.x < 0:
			break
		if Building.place(state, id, where):
			left -= price
			draw += wants
			if id != &"wall":
				towers += 1
	# **Nothing its season has not opened**, asked again of what stands.
	var locked := 0
	var cells: Array = (state["occupants"] as Dictionary).keys()
	cells.sort()
	for idx in cells:
		var on: Dictionary = (state["occupants"] as Dictionary)[idx]
		if GameData.DEFENCES.has(on["id"]) and not Building.unlocked(state, StringName(on["id"])):
			locked += 1
	NightRoad.through_build(state)

	# **The most bodies at once** (task 0272): what a rat night asks of the
	# tick, beside the swarm `perf_check.gd` times (0218, 0248). **And the
	# most crows** (task 0273): the Scarecrow King's flock is his rule's, not
	# the night's rows, so only a night played counts it.
	var ticks := 0
	var peak := 0
	var crows := 0
	for tick in 40000:
		if int(state["phase"]) != Phases.NIGHT:
			ticks = tick
			break
		Sim.advance(state, 1)
		peak = maxi(peak, Entities.count(state))
		crows = maxi(crows, _crows_up(state))
		ticks = tick
	return {
		"held": int(state["house_hp"]) > 0,
		"power": Power.percent(state),
		"house": int(state["house_hp"]),
		"house_full": Phases.house_full(state),
		"ticks": ticks,
		"towers": towers,
		"locked": locked,
		"left": Waves.remaining(state),
		"budget": budget,
		"unspent": left,
		# **What it left lying about** (task 0221): the bones, after every
		# pile's cap, and on how many cells.
		"bones": int(Loot.lying(state).get(GameData.BONES, 0)),
		"piles": Loot.cells_with(state, GameData.BONES).size(),
		"peak": peak,
		"crows": crows,
	}


## How many crows are up: the night's and any the Scarecrow King called.
func _crows_up(state: Dictionary) -> int:
	var out := 0
	for one in (state["entities"] as Dictionary).values():
		if StringName((one as Dictionary).get("kind", &"")) == &"crow":
			out += 1
	return out


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
##
## **Moved with the farmstead** (`SuiteKit.moved`, found in task 0271): the
## old yard's column 18 is the far west of the farm since 2026-10-06, and for
## five days this tool built every defence there and lost every night it
## played with nothing killed.
func _room(state: Dictionary, size: Vector2i) -> Vector2i:
	var start := SuiteKit.moved(Vector2i(18, 2))
	for x in range(start.x, Grid.WIDTH - size.x):
		for y in range(start.y, Grid.HEIGHT - size.y - 1):
			var clear := true
			for dy in size.y:
				for dx in size.x:
					if not Farm.buildable(state, Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				return Vector2i(x, y)
	# Nothing left on the approach: take whatever is going.
	return _anywhere(state, size)


## Every cell of the farm by how far it is from `want`, nearest first - ties
## in reading order - so a build can take the first that will have it.
func _by_distance(want: Vector2i) -> Array:
	var rings: Array = []
	for _i in Grid.WIDTH + Grid.HEIGHT:
		rings.append([])
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var apart := absi(x - want.x) + absi(y - want.y)
			(rings[mini(apart, rings.size() - 1)] as Array).append(Vector2i(x, y))
	var out: Array = []
	for ring in rings:
		out.append_array(ring)
	return out


## Every cell of the farm, farthest from the date's open spawns first - by
## the nearest of them, ties in reading order: ground no road crosses
## (task 0273).
func _away_from_the_sides(state: Dictionary) -> Array:
	var starts: Array = []
	for side in Calendar.open_sides(Calendar.date(state)):
		starts.append_array(Enemies.spawn_cells(state, int(side)))
	var cells: Array = []
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			var nearest := Grid.WIDTH + Grid.HEIGHT
			for start in starts:
				nearest = mini(nearest, absi(x - (start as Vector2i).x) + absi(y - (start as Vector2i).y))
			cells.append([nearest, y, x])
	cells.sort_custom(func(a: Array, b: Array) -> bool:
		if int(a[0]) != int(b[0]):
			return int(a[0]) > int(b[0])
		if int(a[1]) != int(b[1]):
			return int(a[1]) < int(b[1])
		return int(a[2]) < int(b[2]))
	var out: Array = []
	for one in cells:
		out.append(Vector2i(int(one[2]), int(one[1])))
	return out


## The first of `order` that `id` can go on, `(-1, -1)` when none can: how a
## player answers a pointer to a patch of ground.
func _first_free(state: Dictionary, order: Array, id: StringName) -> Vector2i:
	for cell in order:
		if Building.can_place(state, id, cell):
			return cell
	return Vector2i(-1, -1)


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
