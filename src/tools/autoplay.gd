class_name Autoplay
extends RefCounted

## A robot that plays the ten nights, so balance is measured rather than
## guessed at.
##
## **It is a measuring instrument, not an AI.** Every policy below is a list
## of things to want, in order, and the day is "do the next affordable thing
## until the day runs out". Nothing here looks ahead, reacts, or is clever,
## because a clever robot measures the robot.
##
## ## What a day is, here
##
## A day is `DAY_TICKS` of work. Each action costs what the rules say it costs
## - a tree is `work_ticks`, a recipe is its own time - and the robot spends
## the day's ticks on actions in its policy's order until they run out. Then
## the rest of the day is advanced so the crops grow and the press runs.
##
## **Walking is not counted**, and that is the one thing this instrument is
## kinder than a player about. A real farmer spends a good part of a day
## crossing the farm. So the incomes below are a **ceiling**, and the honest
## reading of a policy that only just survives is that a human playing it
## would not have.
##
## ## What it reports
##
## Per night: whether it held, what the house had left, and what had been
## spent getting there. `tools/autoplay.py` runs a hundred of them and says
## which night kills each policy, and whether one of them wins everything -
## which is the dominant-strategy alarm the task asks for.

## The four ways to play, as lists of wants.
##
## `gather` is what the day goes looking for, `build` is what it puts up when
## it can afford to, `tech` is the branch it walks down. A policy is those
## three lists and nothing else.
const POLICIES: Dictionary = {
	&"towers": {
		"note": "everything into guns",
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"auto_crossbow", &"gun_tower", &"mortar",
			&"auto_crossbow", &"generator"],
		"tech": [&"true sights", &"long barrels", &"oiled works",
			&"a standing order"],
	},
	&"walls": {
		"note": "a maze, and just enough to shoot with",
		"gather": [&"stone", &"wood", &"iron"],
		"build": [&"gun_tower", &"wall", &"wall", &"fence", &"wall",
			&"auto_crossbow", &"wall", &"fence"],
		"tech": [&"stout timbers", &"a full larder", &"spare stakes",
			&"a second flare"],
	},
	&"economy": {
		"note": "the farm first, the guns later",
		"gather": [&"wood", &"stone", &"iron"],
		"build": [&"gun_tower", &"press", &"kitchen", &"generator",
			&"gun_tower", &"auto_crossbow"],
		"tech": [&"sharp tools", &"full cans", &"steady hands",
			&"a name at market"],
	},
	&"balanced": {
		"note": "a bit of each, which is what a player actually does",
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"generator", &"auto_crossbow", &"wall",
			&"mortar", &"wall", &"auto_crossbow"],
		"tech": [&"true sights", &"stout timbers", &"long barrels",
			&"sharp tools"],
	},
}


static func names() -> Array:
	return GameData.sorted_names(POLICIES.keys())


## Play one seeded run of one policy, and report every night of it.
static func play(seed_value: int, policy_name: StringName) -> Dictionary:
	var policy: Dictionary = POLICIES[policy_name]
	var state := State.create(seed_value)
	var nights: Array = []
	var died_on := 0

	for night in range(1, GameData.MVP_NIGHTS + 1):
		var spent_before := _worth_of_stock(state)
		_a_day(state, policy)

		Phases.begin_preparation(state)
		Sim.advance(state, GameData.PREPARATION_TICKS)
		for _tick in 40000:
			if int(state["phase"]) != Phases.NIGHT:
				break
			Sim.advance(state, 1)

		var held := int(state["house_hp"]) > 0
		nights.append({
			"night": night,
			"held": held,
			"house": int(state["house_hp"]),
			"spent": maxi(spent_before - _worth_of_stock(state), 0),
			"towers": _towers_standing(state),
		})
		if not held:
			died_on = night
			break
		(state["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(state, 2)

	return {
		"policy": policy_name,
		"seed": seed_value,
		"nights": nights,
		"died_on": died_on,
		"won": died_on == 0,
		"killed": int(state["killed_all_run"]),
		"gathered": _worth_of_gathered(state),
	}


# ---------------------------------------------------------------- the day

## Spend a day's worth of work on the policy's wants, then let the day run.
static func _a_day(state: Dictionary, policy: Dictionary) -> void:
	var left := GameData.DAY_TICKS
	var guard := 0
	while left > 0 and guard < 900:
		guard += 1
		var spent := _one_thing(state, policy)
		if spent <= 0:
			break           # nothing left worth doing today
		left -= spent
	# The rest of the day: crops grow, the press runs, the animals fill up.
	Sim.advance(state, maxi(left, 1))


## Do the next thing the policy wants, and say what it cost in ticks.
##
## **In order, and the first one that works wins.** Technology, then what it
## can build, then go and get more of what it is short of.
static func _one_thing(state: Dictionary, policy: Dictionary) -> int:
	for id in (policy["tech"] as Array):
		if Tech.can_buy(state, StringName(id)):
			Tech.buy(state, StringName(id))
			return GameData.SECONDS       # a trip to the workbench

	for id in (policy["build"] as Array):
		var where := _room_for(state, Building.size_of(StringName(id)))
		if where.x >= 0 and Building.place(state, StringName(id), where):
			return 2 * GameData.SECONDS   # putting a thing up takes a while

	# **Improve what is already there.** Task 0064 made a tower a thing that
	# grows and the robot was ignoring it entirely - buying the tree node
	# that gates an upgrade and then never upgrading anything.
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if Building.can_upgrade(state, cell):
			Building.upgrade(state, cell)
			return 2 * GameData.SECONDS

	# **Go and get what the next thing is short of**, rather than what is
	# first on a list. Working the list in order meant chopping wood for
	# ever, because there is always another tree: two hundred and nineteen
	# wood, three iron, and no tower on night one.
	for id in (policy["build"] as Array):
		var short := Resources.missing(state,
			Building.cost_of(StringName(id)))
		if short.is_empty():
			continue
		for res in GameData.sorted_names(short.keys()):
			var needed := _go_and_get(state, StringName(res))
			if needed > 0:
				return needed
		# **Nothing to swing at, so wait.** The cliff has eight seams and
		# they come back once a day; a robot that filled the gap by chopping
		# wood it did not need finished day one with a hundred and
		# twenty-nine wood, eight iron and no tower. Waiting for the ore is
		# what a player does, and it is what the day is for.
		Sim.advance(state, GameData.SECONDS)
		return GameData.SECONDS

	# Nothing on the list wants anything gettable: top up the policy's own
	# preferences, which is what a day with nothing to do looks like.
	for res in (policy["gather"] as Array):
		var cost := _go_and_get(state, StringName(res))
		if cost > 0:
			return cost
	return 0


## Work one node of the kind that yields this resource. Returns what it cost.
static func _go_and_get(state: Dictionary, res: StringName) -> int:
	for id in GameData.sorted_names(GameData.GATHERING.keys()):
		var node: Dictionary = GameData.GATHERING[id]
		if not (node.get("yield", {}) as Dictionary).has(res):
			continue
		for cell in Farm.cells_with(state, id):
			# **Through the rules' own door.** `strike()` is what a held key
			# arrives at, so what the robot gets is what a player gets.
			Gathering.strike(state, cell)
			return int(node.get("work_ticks", GameData.SECONDS))
	return 0


# --------------------------------------------------------------- the sums

## Occupant cells in a fixed order, so two runs of a seed upgrade the same
## tower first.
static func _sorted_occupants(state: Dictionary) -> Array:
	var keys: Array = (state["occupants"] as Dictionary).keys()
	keys.sort()
	return keys


static func _worth_of_stock(state: Dictionary) -> int:
	var total := 0
	for res in GameData.RESOURCES:
		if res == GameData.ENERGY or res == GameData.TECH:
			continue
		total += Resources.amount(state, res) \
			* int(GameData.SELL_PRICE.get(res, 1))
	return total


static func _worth_of_gathered(state: Dictionary) -> int:
	var total := 0
	var gained: Dictionary = state["gained"]
	for res in GameData.sorted_names(gained.keys()):
		if res == GameData.ENERGY or res == GameData.TECH \
				or res == GameData.MONEY:
			continue
		total += int(gained[res]) * int(GameData.SELL_PRICE.get(res, 1))
	return total


static func _towers_standing(state: Dictionary) -> int:
	var n := 0
	for idx in (state["occupants"] as Dictionary):
		var id: StringName = ((state["occupants"] as Dictionary)[idx]
			as Dictionary)["id"]
		if GameData.DEFENCES.has(id) and not (GameData.DEFENCES[id]
			as Dictionary).has("path_cost"):
			n += 1
	return n


## Somewhere to put a thing, on the approach where it can do some good.
static func _room_for(state: Dictionary, size: Vector2i) -> Vector2i:
	for x in range(18, Grid.WIDTH - size.x):
		for y in range(2, Grid.HEIGHT - size.y - 1):
			var clear := true
			for dy in size.y:
				for dx in size.x:
					if not Farm.buildable(state, Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				return Vector2i(x, y)
	return Vector2i(-1, -1)
