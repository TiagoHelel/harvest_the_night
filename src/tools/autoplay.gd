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
## the rest of the day is advanced so the press runs; watered crops grow the next morning.
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

## When a policy goes to bed if it does not say: half past one, the pass-out
## warning's minute, half an hour before he would collapse.
const DEFAULT_BED_MINUTE := 25 * 60 + 30


## The four ways to play, as lists of wants.
##
## `gather` is what the day goes looking for, `build` is what it puts up when
## it can afford to, `tech` is the branch it walks down. A policy is those
## three lists and the hour it goes to bed (`bed_minute`, task 0142).
const POLICIES: Dictionary = {
	&"towers": {
		"note": "everything into guns",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"auto_crossbow", &"gun_tower", &"mortar",
			&"auto_crossbow", &"generator"],
		"tech": [&"true sights", &"long barrels", &"oiled works",
			&"a standing order"],
	},
	&"walls": {
		"note": "a maze, and just enough to shoot with",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"stone", &"wood", &"iron"],
		"build": [&"gun_tower", &"wall", &"wall", &"fence", &"wall",
			&"auto_crossbow", &"wall", &"fence"],
		"tech": [&"stout timbers", &"a full larder", &"spare stakes",
			&"a second flare"],
	},
	&"economy": {
		"note": "the farm first, the guns later",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"stone", &"iron"],
		# **Two towers before anything else**, in every plan. Night two's own
		# note in `GameData.NIGHTS` reads "the same again from two sides, so
		# one tower is not enough", and this plan used to spend its second and
		# third slots on a press and a kitchen and meet that night with one.
		# It died on night two on every seed. The design was doing exactly
		# what it says it does; the plan was not reading it.
		"build": [&"gun_tower", &"gun_tower", &"press", &"kitchen",
			&"generator", &"gun_tower", &"auto_crossbow"],
		"tech": [&"sharp tools", &"full cans", &"steady hands",
			&"a name at market"],
	},
	&"balanced": {
		"note": "a bit of each, which is what a player actually does",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"gun_tower", &"generator", &"auto_crossbow",
			&"wall", &"mortar", &"wall", &"auto_crossbow"],
		"tech": [&"true sights", &"stout timbers", &"long barrels",
			&"sharp tools"],
	},
}


static func names() -> Array:
	return GameData.sorted_names(POLICIES.keys())


## How many calendar nights a run plays unless told otherwise: the first
## ten, which is what `implementation/BALANCE.md`'s tables were read from.
const DEFAULT_NIGHTS := 10


## Play one seeded run of one policy, the first `nights_wanted` calendar
## nights of it, and report every one.
##
## **A lost night does not end it** (task 0142). The morning comes and the
## robot plays on, the way a player does - so a run is `nights_wanted`
## nights played, not the nights until the first loss. Since task 0151 the
## next night is the next day's: a lost night is not fought again. `died_on`
## is still the first night lost, which is what the win rate per night is
## read from; `nights_won` is how many it won.
##
## `nights_wanted` is the explicit count. The balance sweep wants the first
## ten; the check suite wants one day and one night per policy, which is what
## fits inside its two-minute budget.
static func play(seed_value: int, policy_name: StringName,
		nights_wanted: int = DEFAULT_NIGHTS) -> Dictionary:
	var policy: Dictionary = POLICIES[policy_name]
	var state := State.create(seed_value)
	var nights: Array = []
	var died_on := 0

	for _night in nights_wanted:
		if Run.is_over(state):
			break
		var row := _one_night(state, policy)
		nights.append(row)
		if StringName(row["ended"]) == &"house" and died_on == 0:
			died_on = int(row["night"])
		# A night still running at the cap cannot be confirmed into a
		# morning: there is nothing more this run can play.
		if StringName(row["ended"]) == &"cap":
			break

	return {
		"policy": policy_name,
		"seed": seed_value,
		"nights": nights,
		"died_on": died_on,
		"nights_won": Phases.nights_won(state),
		"won": died_on == 0 and nights.size() >= nights_wanted
			and StringName((nights.back() as Dictionary)["ended"]) != &"cap",
		"killed": int(state["killed_all_run"]),
		"gathered": _worth_of_gathered(state),
	}


## **One day and one night of the loop as it is now** (task 0142): out of bed
## and the day's work, to bed through the `sleep` intent, the defence in the
## build step through the intent road, START, the night to its end, and the
## morning report confirmed. Returns the night's row:
## `{night, held, ended, house, walked, spent, towers}`, `ended` being
## `&"dawn"`, `&"cleared"` (everything dead first), `&"house"` (lost) or
## `&"cap"` (still running at `NIGHT_TICKS` and a margin).
static func _one_night(state: Dictionary, policy: Dictionary) -> Dictionary:
	var spent_before := _worth_of_stock(state)
	_a_day(state, policy)
	_a_build_step(state, policy)
	_a_night(state)
	var ended := _how_it_ended(state)
	var row := {
		"night": int(state["night"]),
		"held": ended == &"dawn" or ended == &"cleared",
		"ended": ended,
		"house": int(state["house_hp"]),
		"walked": int(Rewards.last(state).get("walked", 0)) if ended != &"cap" else 0,
		"spent": maxi(spent_before - _worth_of_stock(state), 0),
		"towers": _towers_standing(state),
	}
	if int(state["phase"]) == Phases.RESULT:
		(state["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(state, 1)
	return row


## How long a night may run before the robot stops waiting for it: a whole
## night past dawn, for a Giant that holds dawn back (task 0137).
const NIGHT_MARGIN_TICKS := GameData.NIGHT_TICKS


## The night, tick by tick, to its own end - dawn, everything dead, or the
## house - or the cap.
static func _a_night(state: Dictionary) -> int:
	return NightRoad.run_night(state, GameData.NIGHT_TICKS + NIGHT_MARGIN_TICKS)


## How the night ended, read off the state after it.
static func _how_it_ended(state: Dictionary) -> StringName:
	if int(state["phase"]) == Phases.NIGHT:
		return &"cap"
	var result: Dictionary = state["last_result"]
	if not bool(result.get("survived", false)):
		return &"house"
	var dawn := int((state["wave"] as Dictionary).get("dawn_at", GameData.NIGHT_TICKS))
	return &"dawn" if int(result.get("ticks", 0)) >= dawn else &"cleared"


# ---------------------------------------------------------------- the day

## Spend the day on the policy's wants, then go to bed.
##
## **To bed through the `sleep` intent** (task 0142), the road the bed and
## GO TO BED take: at the policy's `bed_minute`, or sooner when the day has
## nothing left worth doing. Never at 02:00 - `bed_minute` is before
## `DAY_END_MINUTE`, so the robot does not pass out by accident. Sleeping
## early is the player's trade too: the hours skipped are neither lived nor
## credited.
static func _a_day(state: Dictionary, policy: Dictionary) -> void:
	# **Out of the door first** (task 0138): every morning after the first
	# starts with him beside his bed, and nothing is built from in there.
	House.leave(state)
	var bed := mini(Phases.tick_at_minute(int(policy.get("bed_minute",
		DEFAULT_BED_MINUTE))), GameData.DAY_TICKS - 1)
	var guard := 0
	while int(state["day_tick"]) < bed and guard < 900:
		guard += 1
		var spent := _one_thing(state, policy)
		if spent <= 0:
			break           # nothing left worth doing today: to bed
		# **Time passes while the work happens.** An earlier version counted
		# the ticks an action cost and then advanced the whole day in one go
		# at the end - so every action happened at tick zero, the ore never
		# regrew, the crops never grew, and the robot spent four hundred and
		# sixty-eight actions waiting for a cliff that could not come back.
		# Never past bedtime: the last thing started is cut short.
		Sim.advance(state, mini(maxi(spent, 1), bed - int(state["day_tick"])))
	(state["intent"] as Dictionary)["sleep"] = true
	Sim.advance(state, 1)


## Do the next thing the policy wants, and say what it cost in ticks.
##
## **In order, and the first one that works wins.** Technology, then what it
## can build, then go and get more of what it is short of.
static func _one_thing(state: Dictionary, policy: Dictionary) -> int:
	for id in (policy["tech"] as Array):
		if Tech.can_buy(state, StringName(id)):
			Tech.buy(state, StringName(id))
			return GameData.SECONDS       # a trip to the workbench

	# **Mend what is hurt before building anything new.**
	#
	# The robot did not, and task 0068 watched its tower count go *backwards*
	# from night seven - eight, then five, then four - as the breakers ate a
	# line nobody was repairing. Tuning the breakers down to suit a robot
	# that ignored the counter the game already has would have been tuning
	# the game to the instrument, which is the one thing an instrument must
	# not do.
	#
	# **By day only the house and the stations** (task 0119): the defence is
	# mended in the build step, with the rest of the defence.
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if _is_defence(state, cell) or Repair.max_affordable(state, cell) <= 0:
			continue
		var put_back := Repair.apply_all(state, cell)
		if put_back > 0:
			return put_back * Repair.ticks_at(state, cell)

	# **The plan is a sequence, walked with a cursor.** It used to be "build
	# the first entry you can afford", and the `walls` policy showed what is
	# wrong with that: its plan opens with a gun tower, but a fence is always
	# affordable, so the robot laid **eighty-nine fences in three days** and
	# never once cut the wood for the tower it said it wanted first. Then it
	# met night one with a maze and nothing to shoot from, and died on night
	# one on every seed. A plan whose first line is never reached is not a
	# plan, and a policy that cannot play its own plan measures nothing.
	# **Ask what it costs before asking where it goes.** Looking for room
	# walks every cell around the house, and this runs a few hundred times a
	# day - so doing it on the days the thing could not be paid for anyway
	# put the whole check suite over its two-minute budget. The price is a
	# dictionary lookup; the ground is a search.
	# **A defence the day can pay for waits for the build step** (task 0119),
	# where `_a_build_step()` puts it up off the same cursor - so the day sets
	# its price aside and saves for the next thing on the plan, the way it
	# used to once the tower was up. Without that the robot paid for its
	# tower by noon, farmed the afternoon, and met night one with the tower
	# and none of the walls its plan named next.
	var ahead := _the_plan_ahead(state, policy)
	var want: StringName = ahead["want"]
	var short := Resources.missing(state, ahead["saving_for"])
	if short.is_empty() and not GameData.DEFENCES.has(want) \
			and int(ahead["ahead"]) == 0:
		var where := _room_for(state, want)
		if where.x < 0:
			_next_step(state)           # nowhere to put it: plan around it
			return GameData.SECONDS
		if Building.place(state, want, where):
			_next_step(state)
			return 2 * GameData.SECONDS   # putting a thing up takes a while
		# Affordable, and there is room, and it still would not go up: a rule
		# says no that no amount of work can answer. Plan around it rather
		# than standing in front of it for the rest of the run.
		_next_step(state)
		return GameData.SECONDS

	# **Keep the stations running.** The press and the workshop are where the
	# farm turns into the defence, and the robot ignored them completely - so
	# it could never make oil, so a generator it built had nothing to burn, so
	# the supply stayed at `BASE_ENERGY` for ten nights while the draw climbed
	# to thirteen. At that point every tower reloads three times slower and
	# seven of them are worth two. The back half of the game read as
	# impossible and what was actually impossible was for this robot to run a
	# press.
	#
	# The rule is the idle-hands one a player uses: if a station is free and
	# something on its list can be made right now, put it on.
	#
	# **It goes here and not at the front of the queue.** At the front, the
	# robot found the workshop the farm starts with and spent day one turning
	# its whole wood pile into fence kits, met night one with nothing built
	# and lost twelve walkers to ten breaches. Crafting is what you do when
	# there is nothing to put up, not instead of putting something up.
	# **And never with what the plan is saving for.** Unguarded, this clause
	# found the workshop the farm starts with and turned all twelve of the
	# starting wood into three fence kits - while the plan's first line was a
	# gun tower wanting ten of that wood. The tower was never built, on any
	# day, and every policy lost night one with nothing standing.
	var saving_for: Dictionary = ahead["saving_for"]
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		var on := Farm.occupant(state, cell)
		if on.is_empty() or not Crafting.is_station(on["id"]):
			continue
		for recipe in Crafting.recipes_at(on["id"]):
			if not Crafting.can_start(state, cell, StringName(recipe)):
				continue
			if _would_raid(saving_for, StringName(recipe)):
				continue
			Crafting.start(state, cell, StringName(recipe))
			return GameData.SECONDS

	# **Go and get what the next thing is short of**, rather than what is
	# first on a list. Working the list in order meant chopping wood for
	# ever, because there is always another tree: two hundred and nineteen
	# wood, three iron, and no tower on night one.
	# **Plan around what cannot be dug up.** The `towers` plan asks for a
	# mortar fourth, a mortar wants gunpowder, and gunpowder is crafted rather
	# than gathered - so the robot stood in front of it from night three to
	# night nine, mining iron it had no plan for. It went into night nine with
	# three towers and **seventy-eight unspent iron**, and that looked exactly
	# like a game whose back half is too hard. It was a robot that had stopped
	# playing.
	#
	# The test is the gathering table, not the map: a seam that is empty this
	# minute comes back tomorrow and is worth waiting for, while a thing no
	# node on the farm yields is worth walking around for ever.
	# **One ingredient nobody can dig makes the whole entry unreachable**, so
	# the test is "is anything on this list impossible", not "is everything".
	# Getting that backwards only half-fixed it: the robot dutifully mined the
	# thirty stone and thirty-five iron a mortar also wants, and only gave up
	# on the mortar once gunpowder was the single thing left missing. That
	# bought back nights seven and eight and still threw away four days.
	for res in GameData.sorted_names(short.keys()):
		if not _can_be_gathered(StringName(res)):
			# Only the entry at the cursor is planned around. One further on,
			# behind defences already paid for, waits until the build step
			# has put those up and it is at the front.
			if int(ahead["ahead"]) == 0:
				_next_step(state)
				return GameData.SECONDS
			short = {}
			break
	for res in GameData.sorted_names(short.keys()):
		var needed := _go_and_get(state, StringName(res))
		if needed > 0:
			return needed

	# **Nothing to swing at, so work the field.** The cliff's seams come back
	# once a day, and what a player does while they wait is farm.
	#
	# The robot did neither until task 0068 - it chopped wood it did not need
	# - and the consequence was not the wood, it was the **food**: no crops
	# meant no food meant the house could never be mended, so its roof went
	# 25, then 5, then gone over nights six to eight while the ledger held
	# four hundred wood.
	#
	# It goes here rather than at the front of the queue because a player
	# plants when there is nothing more urgent. Putting it first was a robot
	# that farmed all day and met night one with no tower.
	var farmed := _work_the_field(state)
	if farmed > 0:
		return farmed

	# Nothing the plan wants is gettable: top up the policy's own preferences,
	# which is what a day with nothing to do looks like.
	for res in (policy["gather"] as Array):
		var cost := _go_and_get(state, StringName(res))
		if cost > 0:
			return cost
	return 0


## The build step: the defence - mended, placed and upgraded off the same plan
## cursor the day saved for - then START.
##
## **Task 0119 split the robot's day in two**: 0132 forbids defences by day,
## so the day gathers, crafts, buys technology and puts up the stations, and
## this is where the towers and walls go up. **Through the intent road**
## since task 0142 - `build_cell` with `build_place` and `build_upgrade`,
## `repair_cell` - a tick a press, as the cursor's clicks go; the build step
## has no clock after a bedtime, so the ticks cost it nothing.
static func _a_build_step(state: Dictionary, policy: Dictionary) -> void:
	for _guard in 200:
		if not _one_defence_thing(state, policy):
			break
	(state["intent"] as Dictionary)["start_waves"] = true
	Sim.advance(state, 1)


## One thing for the defence, in the order the day used to do them: mend,
## then the plan's next defence if it is paid for, then an upgrade. False
## when there is nothing left to do tonight.
static func _one_defence_thing(state: Dictionary, policy: Dictionary) -> bool:
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if not _is_defence(state, cell) or Repair.max_affordable(state, cell) <= 0:
			continue
		var anchor := Building.anchor_of(state, cell)
		var hurt := int(Farm.occupant(state, anchor).get("hp", 0))
		_press(state, &"repair_cell", anchor)
		if int(Farm.occupant(state, anchor).get("hp", 0)) > hurt:
			return true

	var want := _wants(state, policy)
	if GameData.DEFENCES.has(want) \
			and Resources.missing(state, Building.cost_of(want)).is_empty():
		var where := _room_for(state, want)
		if where.x >= 0:
			Building.select(state, want)
			_press(state, &"build_place", where)
		# Placed, or nowhere to put it, or a rule says no: plan around it,
		# exactly as the day did.
		_next_step(state)
		return true

	# **Improve what is already there.** Task 0064 made a tower a thing that
	# grows and the robot was ignoring it entirely - buying the tree node
	# that gates an upgrade and then never upgrading anything.
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if not Building.can_upgrade(state, cell):
			continue
		var level := int(Farm.occupant(state, cell).get("level", 1))
		_press(state, &"build_upgrade", cell)
		if int(Farm.occupant(state, cell).get("level", 1)) > level:
			return true
	return false


## One press through the intent road and the tick that reads it: a cell in
## `build_cell` with `build_place` or `build_upgrade`, or `repair_cell`.
static func _press(state: Dictionary, press: StringName, cell: Vector2i) -> void:
	var intent: Dictionary = state["intent"]
	if press == &"repair_cell":
		intent["repair_cell"] = [cell.x, cell.y]
	else:
		intent["build_cell"] = [cell.x, cell.y]
		intent[press] = true
	Sim.advance(state, 1)


## Whether the thing standing on this cell is part of the defence.
static func _is_defence(state: Dictionary, cell: Vector2i) -> bool:
	return GameData.DEFENCES.has(StringName(Farm.occupant(state, cell).get("id", &"")))


## What the day is saving for: the plan's next entry once every defence the
## stock already covers is set aside for the build step, and the whole bill -
## `{want, ahead, saving_for}`, `ahead` being how many entries were set aside.
static func _the_plan_ahead(state: Dictionary, policy: Dictionary) -> Dictionary:
	var plan: Array = policy["build"]
	var step := int(state.get("autoplay_step", 0))
	var bill := {}
	for ahead in plan.size():
		var want := StringName(plan[(step + ahead) % plan.size()])
		var with_it := _plus(bill, Building.cost_of(want))
		if GameData.DEFENCES.has(want) and Resources.missing(state, with_it).is_empty():
			bill = with_it
			continue
		return {"want": want, "ahead": ahead, "saving_for": with_it}
	# The whole plan is paid for: nothing left to save for today.
	return {"want": _wants(state, policy), "ahead": plan.size(), "saving_for": bill}


## Two bills added together.
static func _plus(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for res in GameData.sorted_names(b.keys()):
		out[res] = int(out.get(res, 0)) + int(b[res])
	return out


## The thing the plan is up to. Once the list runs out it starts again, so a
## policy that has finished its plan keeps growing instead of downing tools.
static func _wants(state: Dictionary, policy: Dictionary) -> StringName:
	var plan: Array = policy["build"]
	var step := int(state.get("autoplay_step", 0))
	return StringName(plan[step % plan.size()])


static func _next_step(state: Dictionary) -> void:
	state["autoplay_step"] = int(state.get("autoplay_step", 0)) + 1


## Whether this recipe eats anything the next thing on the plan needs.
static func _would_raid(saving_for: Dictionary, recipe_id: StringName) -> bool:
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	for res in GameData.sorted_names((recipe["inputs"] as Dictionary).keys()):
		if saving_for.has(res):
			return true
	return false


## Whether anything on the farm yields this at all, ever. Asked of the table
## rather than of the map, so "the seams are empty today" and "no seam yields
## gunpowder" are not the same answer.
static func _can_be_gathered(res: StringName) -> bool:
	for id in GameData.sorted_names(GameData.GATHERING.keys()):
		if ((GameData.GATHERING[id] as Dictionary).get("yield", {})
				as Dictionary).has(res):
			return true
	return false


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

## Till, sow, water or harvest one plot - whichever the field wants next.
## Returns what it cost, or zero when the field wants nothing.
static func _work_the_field(state: Dictionary) -> int:
	# Keep food in the plan while corn takes eight watered mornings to mature.
	var field := _the_field(state)
	for i in field.size():
		var plot: Vector2i = field[i]
		if Farming.crop_on(state, plot) != &"" and not Farming.is_ready(state, plot) \
				and not Farming.is_watered(state, plot) and Farming.water_carried(state) == 0:
			var well: Vector2i = Farm.cells_with(state, &"well")[0]
			Farming.refill_beside(state, well + Vector2i.UP)
			return GameData.SECONDS
		Farming.select_seed(state, &"corn" if i % 3 == 0 else &"carrot")
		var verb := Farming.verb_at(state, plot)
		if verb == &"":
			continue
		Farming.act(state, plot)
		return int(Interact.DEFAULT_TICKS.get(verb, GameData.SECONDS))
	return 0


## The soil, in a fixed order. Cached on the state because the field does not
## move and finding it walks the whole farm.
static func _the_field(state: Dictionary) -> Array:
	if not state.has("autoplay_field"):
		state["autoplay_field"] = Farm.cells_of(state, Farm.Terrain.SOIL)
	return state["autoplay_field"]


## Occupant cells in a fixed order, so two runs of a seed upgrade the same
## tower first. **Not the trees and stones**: nothing here mends, upgrades or
## crafts at one, and the Stardew-sized farm has six hundred of them.
static func _sorted_occupants(state: Dictionary) -> Array:
	var occupants: Dictionary = state["occupants"]
	var keys: Array = []
	for idx in occupants:
		if not GameData.GATHERING.has((occupants[idx] as Dictionary)["id"]):
			keys.append(idx)
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


## Somewhere to put a thing: **on the approach, between the house and where
## they come from.**
##
## Two wrong versions got here first, and both are worth the ink.
##
## The first was "the first clear cell scanning from x=18", which filled one
## column beside the house. It looked obviously wrong and was accidentally
## almost right, because `GameData.SPAWNS` is the east edge and the south, so
## a column at x=18 sits across the east approach.
##
## The second was a ring: "put the next one where the cover is thinnest". That
## is what a player does on a map with four approaches, and this map has two -
## so it dutifully spread towers around the **west** side of the house, behind
## the fight, and every policy died on night one. Spreading cover evenly over
## ground nobody walks on is worse than piling it on ground they do.
##
## So the rule reads the spawn table rather than guessing from the shape of
## the map: take the approaches in turn, and for each, build the cell that
## minimises `2 * (distance to house) + (distance to that approach)`. The
## house is weighted double, which is what keeps the line tight around the
## thing being defended instead of marching out to meet them at the edge.
static func _room_for(state: Dictionary, id: StringName) -> Vector2i:
	# **A workshop is not a tower and does not want a tower's ground.** The
	# `economy` plan builds a press and a kitchen early, and both were landing
	# on the best cells of the east approach - the ones a gun tower wants -
	# pushing its towers to the back and taking a turn of the side counter
	# with them. Two towers at full power that should have held night two
	# killed five of twenty. Sheds go behind the house, which is where a
	# player puts them and why farms look the way they do.
	var size := Building.size_of(id)
	var guns := GameData.DEFENCES.has(id)
	var approaches := _approaches(state)
	var side: Vector2i = approaches[int(state.get("autoplay_side", 0))
		% approaches.size()]
	var best := Vector2i(-1, -1)
	var best_score := 1 << 30
	for cell in _near_the_house(state):
		if not _clear(state, cell, size):
			continue
		# The larger roof has several entry cells. Leave a firing margin so
		# the first gun covers the approaches before enemies reach an edge.
		if guns and not GameData.DEFENCES[id].has("path_cost") \
				and not Traps.is_trap(id) and _house_distance(state, cell) < 2:
			continue
		# A tower wants to be near the house and toward the approach; a shed
		# wants to be near the house and as far from the approach as it can.
		var score := (2 * _house_distance(state, cell)
			+ (_far(cell, side) if guns else -_far(cell, side))) * 32
		# Equally close cells cover the middle of the enlarged frontage first.
		var home := Farm.house_centre(state)
		score += absi(cell.x - home.x) + absi(cell.y - home.y)
		if score < best_score:
			best_score = score
			best = cell
	if best.x >= 0 and guns:
		state["autoplay_side"] = int(state.get("autoplay_side", 0)) + 1
	return best


## The middle of each spawn region tonight's night comes from, read off the
## rules' own table so that moving a spawn moves the robot with it.
##
## **Tonight's sides, not every side** (task 0157): with five regions and
## spring opening one, a robot taking all five in turn would put four towers
## of five where nobody walks. A calm night sends nobody, so it falls back to
## the sides the season has open.
static func _approaches(state: Dictionary) -> Array:
	var date := Phases.night_ahead(state)
	var sides := Waves.spawns_in(Waves.night_of(date, int(state["seed"])))
	if sides.is_empty():
		sides = Calendar.open_sides(date)
	var out: Array = []
	for side in sides:
		var region: Array = GameData.SPAWNS[int(side)]
		var sum := Vector2i.ZERO
		for entry in (region as Array):
			sum += Vector2i(int(entry[0]), int(entry[1]))
		out.append(sum / maxi((region as Array).size(), 1))
	return out


## The cells worth considering: a box around the house, in a fixed order.
## Cached, because it does not change and walking the grid is not free.
static func _near_the_house(state: Dictionary) -> Array:
	if state.has("autoplay_spots"):
		return state["autoplay_spots"]
	var spots: Array = []
	var home := Farm.house_centre(state)
	for x in range(maxi(home.x - REACH, 0), mini(home.x + REACH, Grid.WIDTH)):
		for y in range(maxi(home.y - REACH, 1),
				mini(home.y + REACH, Grid.HEIGHT - 1)):
			spots.append(Vector2i(x, y))
	state["autoplay_spots"] = spots
	return spots


static func _far(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func _house_distance(state: Dictionary, cell: Vector2i) -> int:
	var bounds := Farm.house_bounds(state)
	var closest := Vector2i(clampi(cell.x, bounds.position.x, bounds.end.x - 1),
		clampi(cell.y, bounds.position.y, bounds.end.y - 1))
	return _far(cell, closest)


static func _clear(state: Dictionary, at: Vector2i, size: Vector2i) -> bool:
	for dy in size.y:
		for dx in size.x:
			if not Farm.buildable(state, at + Vector2i(dx, dy)):
				return false
	return true


## The middle of the house, and how far around it the robot is willing to
## build. Both are the instrument's own business rather than rules, so they
## live here and not in `GameData`.
const REACH := 9
