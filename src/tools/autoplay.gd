class_name Autoplay
extends RefCounted

## A robot that plays the year, so balance is measured rather than guessed at.
##
## **It is a measuring instrument, not an AI.** Every policy below is a list
## of things to want, in order, and the day is "do the next thing worth doing
## until bedtime". Nothing here looks ahead, reacts, or is clever, because a
## clever robot measures the robot.
##
## ## A player's road, and nothing else (task 0276)
##
## Since task 0276 it plays 1.0 the way a player does, through the same doors:
## - **on foot**: the farmer walks every step through the `move` intent, a
##   tick at a time, by the shortest road over the ground he can walk -
##   `PLAYER_SPEED` decides how long a trip takes, and the tiles walked are
##   counted. On an 80x65 farm with an eight-minute day, "walking is free"
##   was no longer close to a player;
## - **the verbs** through the `interact` intent, facing what he works:
##   tilling, planting, watering, harvesting, chopping, mining, collecting
##   from a coop's door, and the cast - the fish landed through the bar's
##   presses (task 0180), each one made when the marker is over the green, as
##   a player watching it would;
## - **the panels** through what their buttons call, once the verb has
##   opened them: packets, animals and tool upgrades from the peddler in his
##   hours, goods into the shipping bin, recipes into a station's queue, the
##   tree, the house's next tier;
## - **the night** through the cursor's intents: `build_cell` with
##   `build_place` and `build_upgrade`, `repair_cell`, and `ability_cell` with
##   `ability` and `power` (0135, 0232) when a power fires;
## - **the night's loot** picked up underfoot the morning after (0221).
## Nothing is granted by writing `state`.
##
## ## The calendar, not a count of nights
##
## `play(seed, policy, days)` plays dates: calm nights, Full Moons, a winter
## with nothing growing, and a boss night repeated until the boss falls - the
## rules hold the date, the robot only keeps playing - with a cap so a tool
## run always ends, reported when it is hit. A lost night moves the calendar
## on as the rules say.
##
## ## What it reports
##
## Per night: its date, whether it held, what the house had left, the essence
## and the money, how far the farmer walked. Per run, per season: the nights
## lost and the boss nights played again. `tools/autoplay.py` runs many and
## says which night kills each policy, and whether one of them wins everything
## - the dominant-strategy alarm - per season for a year.

## When a policy goes to bed if it does not say: half past one, the pass-out
## warning's minute, half an hour before he would collapse.
const DEFAULT_BED_MINUTE := 25 * 60 + 30


## The four ways to play.
##
## `gather` is what the day goes looking for when the plan wants nothing,
## `build` is what it puts up when it can afford to - production buildings by
## day, defences in the build step - and `tech` is the branch it walks down.
## Since task 0276 each also has:
## - `day`, **its earners in order**: the day goes round them, a turn each,
##   the first first - `crops` (the season's, never in winter), `fishing`,
##   `animals`, `machines`, `mining`, `chopping`;
## - `buys`: the animals it keeps, the tools it upgrades, whether it raises
##   the house a tier;
## - `night`, **its night plan**: whether the cursor mends, upgrades and keeps
##   building during the waves, and when each power fires;
## - `bed_minute`, its bedtime (task 0142).
## **`balanced` is the average player** that task 0277 balances the year
## against.
const POLICIES: Dictionary = {
	&"towers": {
		"note": "everything into guns",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"auto_crossbow", &"gun_tower", &"mortar",
			&"auto_crossbow", &"generator"],
		"tech": [&"true sights", &"long barrels", &"oiled works",
			&"a standing order"],
		"day": [&"mining", &"chopping", &"crops", &"fishing"],
		"buys": {"animals": [], "tools": [&"pickaxe", &"axe"], "house": false},
		"night": {"repair": true, "upgrade": true, "during_waves": true,
			"powers": {&"flare": &"crowd", &"farm_bell": &"house",
				&"call_dog": &"near", &"emergency_repair": &"hurt"}},
	},
	&"walls": {
		"note": "a maze, and just enough to shoot with",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"stone", &"wood", &"iron"],
		"build": [&"gun_tower", &"wall", &"wall", &"fence", &"wall",
			&"auto_crossbow", &"wall", &"fence"],
		"tech": [&"stout timbers", &"a full larder", &"spare stakes",
			&"a second flare", &"a farm bell"],
		"day": [&"mining", &"chopping", &"crops", &"fishing"],
		"buys": {"animals": [], "tools": [&"pickaxe", &"axe"], "house": true},
		"night": {"repair": true, "upgrade": true, "during_waves": true,
			"powers": {&"flare": &"crowd", &"farm_bell": &"house",
				&"call_dog": &"near", &"emergency_repair": &"hurt"}},
	},
	&"economy": {
		"note": "the farm first, the guns later",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"stone", &"iron"],
		# **Two towers before anything else**, in every plan. The old night
		# two's note said "one tower is not enough" (spring 2 is made from its
		# template since task 0271), and this plan used to spend its second
		# and third slots on a press and a kitchen and meet that night with one.
		# It died on night two on every seed. The design was doing exactly
		# what it says it does; the plan was not reading it.
		"build": [&"gun_tower", &"gun_tower", &"coop", &"press", &"keg",
			&"generator", &"gun_tower", &"barn", &"preserves_jar",
			&"auto_crossbow", &"kitchen"],
		"tech": [&"sharp tools", &"full cans", &"steady hands",
			&"a name at market"],
		"day": [&"crops", &"animals", &"machines", &"fishing", &"mining", &"chopping"],
		"buys": {"animals": [&"chicken", &"cow", &"sheep"], "tools": [&"can", &"hoe", &"rod"],
			"house": true},
		"night": {"repair": true, "upgrade": false, "during_waves": false,
			"powers": {&"flare": &"crowd"}},
	},
	&"balanced": {
		# No dash in a note: `tools/balance.py` reads a policy's name off the line
		# its note is printed on, and the line is words, spaces and commas.
		"note": "a bit of each, which is what a player actually does, and the average player 0277 balances against",
		"bed_minute": DEFAULT_BED_MINUTE,
		"gather": [&"wood", &"iron", &"stone"],
		"build": [&"gun_tower", &"gun_tower", &"generator", &"coop",
			&"auto_crossbow", &"wall", &"keg", &"mortar", &"wall", &"auto_crossbow"],
		"tech": [&"true sights", &"stout timbers", &"long barrels",
			&"sharp tools", &"a farm bell"],
		"day": [&"crops", &"fishing", &"animals", &"machines", &"mining", &"chopping"],
		"buys": {"animals": [&"chicken"], "tools": [&"can", &"pickaxe", &"rod"],
			"house": true},
		"night": {"repair": true, "upgrade": true, "during_waves": true,
			"powers": {&"flare": &"crowd", &"farm_bell": &"house",
				&"emergency_repair": &"hurt"}},
	},
}

## The earners a day plan can name, in no particular order.
const EARNERS: Array = [&"crops", &"fishing", &"animals", &"machines", &"mining", &"chopping"]

## The machines the `machines` earner keeps working, in the order it visits
## them: what turns the farm's produce into goods worth more.
const MACHINES: Array = [&"keg", &"preserves_jar", &"dairy", &"loom", &"mill"]

## How many casts a day the `fishing` earner makes before it gives the pond a
## rest: the attention a player spends on it in a working day.
const CASTS_A_DAY := 6

## How much of each machine input the bin leaves in the bag at night, so the
## machines have something to work the next morning.
const KEEP_FOR_MACHINES := 9

## The money a policy keeps back besides what its plan is saving for before
## it buys an animal or a tool.
const SPARE_MONEY := 20

## How many times a boss night may be played again before a run stops: a
## tool run always ends, and the report says when this was why.
const BOSS_REPEAT_CAP := 6


static func names() -> Array:
	return GameData.sorted_names(POLICIES.keys())


## How many calendar days a run plays unless told otherwise: the first
## ten, which is what `implementation/BALANCE.md`'s tables were read from.
const DEFAULT_NIGHTS := 10


## Play one seeded run of one policy from the first date to `days_wanted`,
## and report every night it fought.
##
## **The calendar, not a count** (task 0276): a boss night the boss walked
## off is played again on the same date - the rules hold it - until he falls
## or `BOSS_REPEAT_CAP` repeats, which ends the run and says so (`capped`).
## **A lost night does not end it** (task 0142): the morning comes and the
## robot plays on. `died_on` is the date of the first night lost, what the
## win rate per night is read from; `nights_won` is how many it won.
##
## `days_wanted` is the last date it plays. The balance sweep wants the
## first ten; the check suite one day and one night per policy; a year is
## `Calendar.year_days()`.
static func play(seed_value: int, policy_name: StringName,
		days_wanted: int = DEFAULT_NIGHTS, bed_minute: int = -1) -> Dictionary:
	var policy: Dictionary = POLICIES[policy_name].duplicate(true)
	if bed_minute >= 0:
		policy["bed_minute"] = bed_minute
	var state := State.create(seed_value)
	var nights: Array = []
	var died_on := 0
	var repeats := 0
	var capped := false
	var seasons: Array = []
	for _season in GameData.SEASONS.size():
		seasons.append({"losses": 0, "repeats": 0, "money": -1, "essence": -1})

	while Calendar.date(state) <= days_wanted:
		if Run.is_over(state):
			break
		var date := Calendar.date(state)
		var season: Dictionary = seasons[Calendar.season_of(date) % seasons.size()]
		if int(season["money"]) < 0:
			season["money"] = Resources.amount(state, GameData.MONEY)
			season["essence"] = Tech.held(state)
		var row := _one_night(state, policy)
		nights.append(row)
		if not bool(row["held"]):
			season["losses"] = int(season["losses"]) + 1
			if died_on == 0:
				died_on = int(row["date"])
		# **The boss night again** when the date did not move: the boss is up.
		if Calendar.date(state) == date and Calendar.is_boss_night(date):
			repeats += 1
			season["repeats"] = int(season["repeats"]) + 1
			row["repeat"] = true
			if int(season["repeats"]) > BOSS_REPEAT_CAP:
				capped = true
				break
		# A night still running at the cap cannot be confirmed into a
		# morning: there is nothing more this run can play.
		if StringName(row["ended"]) == &"cap":
			capped = true
			break

	var walked := 0
	for row in nights:
		walked += int((row as Dictionary)["steps"])
	return {
		"policy": policy_name,
		"seed": seed_value,
		"nights": nights,
		"died_on": died_on,
		"nights_won": Phases.nights_won(state),
		"won": died_on == 0 and not capped and not nights.is_empty()
			and Calendar.date(state) > days_wanted,
		"killed": int(state["killed_all_run"]),
		"gathered": _worth_of_gathered(state),
		"seasons": seasons,
		"repeats": repeats,
		"capped": capped,
		"year_over": Run.is_over(state),
		"walked": walked,
		"money": Resources.amount(state, GameData.MONEY),
		"essence": Tech.held(state),
	}


## **One day and one night of the loop** (task 0142, 0276): out of bed and the
## day's work, to bed through the `sleep` intent, the defence in the build
## step through the intent road, START, the night to its end with the
## cursor's help, and the morning report confirmed. Returns the night's row:
## `{night, date, held, ended, house, walked, steps, spent, towers, essence,
## money, ...}`, `ended` being `&"dawn"`, `&"cleared"` (everything dead
## first), `&"house"` (lost) or `&"cap"` (still running at `NIGHT_TICKS` and a
## margin), `walked` the zombies that walked off at dawn and `steps` the
## tiles the farmer walked that day.
static func _one_night(state: Dictionary, policy: Dictionary) -> Dictionary:
	var spent_before := _worth_of_stock(state)
	var money_before := Resources.amount(state, GameData.MONEY)
	var earned_before := int(state["gained"][GameData.MONEY])
	var date := Calendar.date(state)
	state["autoplay_steps"] = 0
	state["autoplay_did"] = {}
	_a_day(state, policy)
	var day_money := Resources.amount(state, GameData.MONEY) - money_before
	var day_ticks := int(state["day_tick"])
	var day_earned := int(state["gained"][GameData.MONEY]) - earned_before
	_a_build_step(state, policy)
	_a_night(state, policy)
	var ended := _how_it_ended(state)
	var row := {
		"night": int(state["night"]),
		"date": date,
		"held": ended == &"dawn" or ended == &"cleared",
		"ended": ended,
		"house": int(state["house_hp"]),
		"walked": int(Rewards.last(state).get("walked", 0)) if ended != &"cap" else 0,
		"steps": int(state.get("autoplay_steps", 0)),
		"spent": maxi(spent_before - _worth_of_stock(state), 0),
		"towers": _towers_standing(state),
		"day_money": day_money,
		"day_earned": day_earned,
		"day_ticks": day_ticks,
		"did": (state["autoplay_did"] as Dictionary).duplicate(),
		"repeat": false,
	}
	if int(state["phase"]) == Phases.RESULT:
		(state["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(state, 1)
	row["essence"] = Tech.held(state)
	row["money"] = Resources.amount(state, GameData.MONEY)
	return row


## How long a night may run before the robot stops waiting for it: a whole
## night past dawn, for a Giant that holds dawn back (task 0137).
const NIGHT_MARGIN_TICKS := GameData.NIGHT_TICKS

## How often the cursor looks at the night, in ticks: what needs mending,
## what power to fire. A player glances, not stares.
const NIGHT_LOOK_TICKS := 15


## The night, tick by tick, to its own end - dawn, everything dead, or the
## house - or the cap. **The cursor is busy while it runs** (task 0276): every
## `NIGHT_LOOK_TICKS` it mends, builds and fires what the policy's night plan
## says. Without a policy it only watches, as before.
static func _a_night(state: Dictionary, policy: Dictionary = {}) -> int:
	var cap := GameData.NIGHT_TICKS + NIGHT_MARGIN_TICKS
	var ticks := 0
	while int(state["phase"]) == Phases.NIGHT and ticks < cap:
		if not policy.is_empty() and ticks % NIGHT_LOOK_TICKS == 0:
			_the_cursor_at_night(state, policy)
		Sim.tick(state)
		ticks += 1
	return ticks


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
##
## **The morning picks up the night's loot** and **the evening fills the
## bin** (task 0276), both on foot.
static func _a_day(state: Dictionary, policy: Dictionary) -> void:
	# **Out of the door first** (task 0138): every morning after the first
	# starts with him beside his bed, and nothing is built from in there.
	House.leave(state)
	var bed := _bedtime(policy)
	_pick_up_the_loot(state, bed)
	# Each action advances at least one tick. Bound stalled fixtures without
	# truncating a longer day after the old fixed 900-action limit.
	var guard := 0
	while int(state["day_tick"]) < bed - _SHIPPING_TIME and guard <= bed:
		guard += 1
		var before := int(state["day_tick"])
		var spent := _one_thing(state, policy)
		if spent <= 0:
			break           # nothing left worth doing today: to bed
		# **Time passes while the work happens.** A thing done on foot has
		# spent its own ticks walking and working; a panel's button has not,
		# and is charged what it said it costs. Never past bedtime.
		if int(state["day_tick"]) == before:
			Sim.advance(state, mini(maxi(spent, 1), maxi(bed - int(state["day_tick"]), 1)))
	_halt(state)
	_close_any_panel(state)
	_ship_the_day(state, policy, bed)
	_halt(state)
	_close_any_panel(state)
	(state["intent"] as Dictionary)["sleep"] = true
	Sim.advance(state, 1)


## The tick the policy goes to bed on.
static func _bedtime(policy: Dictionary) -> int:
	return mini(Phases.tick_at_minute(int(policy.get("bed_minute",
		DEFAULT_BED_MINUTE))), GameData.DAY_TICKS - 1)


## What the evening's walk to the bin is given before bedtime: a quarter of
## an hour of game time.
const _SHIPPING_TIME := 15 * 14


## Do the next thing the policy wants, and say what it cost in ticks.
##
## **In order, and the first one that works wins.** Technology, the house and
## the stations mended, what the plan can put up by day, what the plan is
## short of, then the day plan's earners a turn each.
static func _one_thing(state: Dictionary, policy: Dictionary) -> int:
	for id in (policy["tech"] as Array):
		if Tech.can_buy(state, StringName(id)):
			Tech.buy(state, StringName(id))     # the tree's panel
			_did(state, &"tech")
			return GameData.SECONDS

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
	# mended in the build step, with the rest of the defence. **On foot, with
	# the `repair` verb** (task 0276), held while it mends.
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if _is_defence(state, cell) or not Repair.can_mend(state, cell):
			continue
		if Repair.max_affordable(state, cell) <= 0:
			continue
		var ticks := _use(state, cell)
		if ticks > 0:
			_did(state, &"mended")
			return ticks

	# **The plan is a sequence, walked with a cursor.** It used to be "build
	# the first entry you can afford", and the `walls` policy showed what is
	# wrong with that: its plan opens with a gun tower, but a fence is always
	# affordable, so the robot laid **eighty-nine fences in three days** and
	# never once cut the wood for the tower it said it wanted first. Then it
	# met night one with a maze and nothing to shoot from, and died on night
	# one on every seed. A plan whose first line is never reached is not a
	# plan, and a policy that cannot play its own plan measures nothing.
	# **A defence the day can pay for waits for the build step** (task 0119),
	# where `_a_build_step()` puts it up off the same cursor - so the day sets
	# its price aside and saves for the next thing on the plan.
	var ahead := _the_plan_ahead(state, policy)
	var want: StringName = ahead["want"]
	# **Not before its season** (task 0234): a defence the calendar has not
	# opened is planned around, as a rule's refusal is. The mortar of the
	# spring plans waits for the autumn the cursor comes round to it in.
	if GameData.DEFENCES.has(want) and int(ahead["ahead"]) == 0 \
			and not Building.unlocked(state, want):
		_next_step(state)
		return GameData.SECONDS
	var short := Resources.missing(state, ahead["saving_for"])
	if short.is_empty() and not GameData.DEFENCES.has(want) \
			and int(ahead["ahead"]) == 0:
		var where := _room_for(state, want)
		if where.x < 0:
			_next_step(state)           # nowhere to put it: plan around it
			return GameData.SECONDS
		# **By the cursor** (task 0276): build mode with the thing picked,
		# and a press on the cell - what a player's click is.
		Building.select(state, want)
		_press(state, &"build_place", where)
		Building.set_active(state, false)
		_next_step(state)
		if Farm.occupant(state, where).get("id", &"") == want:
			_did(state, &"built")
			return 2 * GameData.SECONDS   # putting a thing up takes a while
		# Affordable, and there is room, and it still would not go up: a rule
		# says no that no amount of work can answer. Plan around it rather
		# than standing in front of it for the rest of the run.
		return GameData.SECONDS

	# **The bench works for the plan.** The press and the workshop are where
	# the farm turns into the defence: the idle-hands rule a player uses - a
	# station free, and something on its list can be made right now and is
	# not made of what the plan is saving for - put it on. Not the machines,
	# which are the day plan's `machines` earner.
	var saving_for: Dictionary = ahead["saving_for"]
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		var on := Farm.occupant(state, cell)
		if on.is_empty() or not Crafting.is_station(on["id"]) or MACHINES.has(StringName(on["id"])):
			continue
		if Building.anchor_of(state, cell) != cell:
			continue
		var ticks := _queue_at(state, cell, saving_for, false)
		if ticks > 0:
			return ticks

	# **Go and get what the next thing is short of**, rather than what is
	# first on a list. Working the list in order meant chopping wood for
	# ever, because there is always another tree: two hundred and nineteen
	# wood, three iron, and no tower on night one.
	# **Plan around what cannot be dug up.** One ingredient nobody can dig -
	# the mortar's gunpowder - makes the whole entry unreachable, and a robot
	# that mined the rest of it and stood in front of the powder threw away
	# four days. The test is the gathering table, not the map.
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
	# **And from the peddler when the cliff is spent** (task 0276): the
	# materials his stall carries, with what money the plan does not need -
	# a player's road to a tower the seams cannot finish today.
	for res in GameData.sorted_names(short.keys()):
		if StringName(res) == GameData.MONEY or not Shop.can_buy(state, StringName(res), 1):
			continue
		var bought_short := _buy_at_the_stall(state, StringName(res), int(short[res]),
			int(saving_for.get(GameData.MONEY, 0)))
		if bought_short > 0:
			return bought_short

	# **What the house and the tools want**, from the peddler and the
	# workshop, once the plan's money is set aside.
	var bought := _the_shopping(state, policy, saving_for)
	if bought > 0:
		return bought

	# **The day plan's earners, a turn each** (task 0276), the policy's
	# order: the first that has something to do does it, and the next call
	# starts at the one after.
	var plan: Array = policy.get("day", [&"crops", &"mining", &"chopping"])
	var turn := int(state.get("autoplay_turn", 0))
	for k in plan.size():
		var earner := StringName(plan[(turn + k) % plan.size()])
		var ticks := _earn(state, policy, earner, int(saving_for.get(GameData.MONEY, 0)))
		if ticks > 0:
			state["autoplay_turn"] = (turn + k + 1) % plan.size()
			return ticks

	# Nothing the plan wants is gettable: top up the policy's own preferences,
	# which is what a day with nothing to do looks like.
	for res in (policy["gather"] as Array):
		var cost := _go_and_get(state, StringName(res))
		if cost > 0:
			return cost
	return 0


## **One turn of an earner** (task 0276). Returns the ticks it took, or zero
## when it has nothing to do today.
static func _earn(state: Dictionary, policy: Dictionary, earner: StringName, keep: int) -> int:
	match earner:
		&"crops":
			return _work_the_field(state, keep)
		&"fishing":
			return _go_fishing(state)
		&"animals":
			return _tend_the_animals(state, policy, keep)
		&"machines":
			return _work_the_machines(state)
		&"mining":
			return _work_nearest(state, &"mine")
		&"chopping":
			return _work_nearest(state, &"chop")
	return 0


## **The nearest node offering `verb`, worked on foot** (task 0276): what the
## `mining` and `chopping` earners do - a rock or a seam, a tree or a stump -
## whatever it yields. Returns the ticks, or zero when none is standing.
static func _work_nearest(state: Dictionary, verb: StringName) -> int:
	var here := Player.cell(state)
	var best := Vector2i(-1, -1)
	var best_far := 1 << 30
	for id in GameData.sorted_names(GameData.GATHERING.keys()):
		if Interact.OCCUPANT_VERBS.get(StringName(id), &"") != verb:
			continue
		for cell in Farm.cells_with(state, StringName(id)):
			var at: Vector2i = cell
			if Interact.verb_at(state, at) != verb or not Interact.why_not(state, at).is_empty():
				continue
			var far := absi(at.x - here.x) + absi(at.y - here.y)
			if far < best_far:
				best_far = far
				best = at
	if best.x < 0:
		return 0
	var ticks := _use(state, best)
	if ticks > 0:
		_did(state, &"gathered")
	return ticks


# ------------------------------------------------------------- the build step

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
## then the plan's next defence if it is paid for, then an upgrade - as the
## night plan allows. False when there is nothing left to do tonight.
static func _one_defence_thing(state: Dictionary, policy: Dictionary) -> bool:
	var night: Dictionary = policy.get("night", {"repair": true, "upgrade": true})
	if bool(night.get("repair", true)) and _mend_one(state):
		return true

	# **What the nights took, put back first** (task 0276): a player who lost
	# three towers rebuilds them before buying the plan's next thing.
	for lost in _lost_defences(state):
		if Resources.missing(state, Building.cost_of(StringName(lost))).is_empty():
			var again := _room_for(state, StringName(lost))
			if again.x >= 0 and _place_by_cursor(state, StringName(lost), again):
				_did(state, &"rebuilt")
				return true
		break

	var want := _wants(state, policy)
	if GameData.DEFENCES.has(want) and Building.unlocked(state, want) \
			and Resources.missing(state, Building.cost_of(want)).is_empty():
		var where := _room_for(state, want)
		if where.x >= 0 and _place_by_cursor(state, want, where):
			_did(state, &"placed")
		# Placed, or nowhere to put it, or a rule says no: plan around it,
		# exactly as the day did.
		_next_step(state)
		return true

	# **Improve what is already there.** Task 0064 made a tower a thing that
	# grows and the robot was ignoring it entirely - buying the tree node
	# that gates an upgrade and then never upgrading anything.
	if not bool(night.get("upgrade", true)):
		return false
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if not Building.can_upgrade(state, cell):
			continue
		var level := int(Farm.occupant(state, cell).get("level", 1))
		_press(state, &"build_upgrade", cell)
		if int(Farm.occupant(state, cell).get("level", 1)) > level:
			_did(state, &"upgraded")
			return true
	return false


## **A defence put down by the cursor**: build mode with it picked and a
## press on the cell, and what the robot has put down remembered - so what a
## night takes can be put back (`_lost_defences`). True when it stands.
static func _place_by_cursor(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	Building.select(state, id)
	_press(state, &"build_place", cell)
	if StringName(Farm.occupant(state, cell).get("id", &"")) != id:
		return false
	if not state.has("autoplay_placed"):
		state["autoplay_placed"] = {}
	var placed: Dictionary = state["autoplay_placed"]
	placed[id] = int(placed.get(id, 0)) + 1
	return true


## **What the nights took** (task 0276): every defence the robot put down
## that no longer stands, one entry each - a wall line breached twice is two
## walls - **the cheapest first** (`Building.price_of`, ties in name order):
## a player with three towers down puts back the one the purse can buy
## tonight, not the dearest. Kits and traps that are spent by being used are
## not counted: a mine that went off did its job.
static func _lost_defences(state: Dictionary) -> Array:
	var placed: Dictionary = state.get("autoplay_placed", {})
	var out: Array = []
	for id in GameData.sorted_names(placed.keys()):
		var entry: Dictionary = GameData.DEFENCES.get(StringName(id), {})
		if Traps.is_trap(StringName(id)) or Building.kit_only(StringName(id)) \
				or entry.has("lifetime_ticks"):
			continue
		var standing := Farm.cells_with(state, StringName(id)).size()
		for _i in maxi(int(placed[id]) - standing, 0):
			out.append(StringName(id))
	out.sort_custom(func(a: StringName, b: StringName) -> bool:
		var pa := Building.price_of(a)
		var pb := Building.price_of(b)
		return pa < pb if pa != pb else String(a) < String(b))
	return out


## The most hurt defence the ledger can mend, mended a press's worth through
## `repair_cell`. False when nothing is.
static func _mend_one(state: Dictionary) -> bool:
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if not _is_defence(state, cell) or Repair.max_affordable(state, cell) <= 0:
			continue
		var anchor := Building.anchor_of(state, cell)
		var hurt := int(Farm.occupant(state, anchor).get("hp", 0))
		_press(state, &"repair_cell", anchor)
		if int(Farm.occupant(state, anchor).get("hp", 0)) > hurt:
			_did(state, &"mended")
			return true
	return false


## **The cursor during the waves** (task 0276), what the night plan says: a
## defence mended, the plan's next one put down, and the powers it fires -
## each through the intents a player's night HUD writes.
static func _the_cursor_at_night(state: Dictionary, policy: Dictionary) -> void:
	var night: Dictionary = policy.get("night", {})
	if bool(night.get("during_waves", false)):
		if bool(night.get("repair", false)):
			_mend_one(state)
		var want := _wants(state, policy)
		if GameData.DEFENCES.has(want) and Building.unlocked(state, want) \
				and Resources.missing(state, Building.cost_of(want)).is_empty():
			var where := _room_for(state, want)
			if where.x >= 0 and _place_by_cursor(state, want, where):
				_did(state, &"placed")
			_next_step(state)
	var powers: Dictionary = night.get("powers", {})
	for id in GameData.sorted_names(powers.keys()):
		_maybe_fire(state, StringName(id), StringName(powers[id]))


## **When a power fires** (task 0276), by its trigger in the night plan:
## - `crowd`: three or more zombies within three tiles of the one nearest
##   the house, at that one;
## - `house`: a zombie within two tiles of the house;
## - `near`: a zombie within eight tiles of the house, at the nearest;
## - `hurt`: a defence under two fifths of its hit points, at it.
## Fired through `ability_cell` and the power's press - `ability` for the
## flare, `power` for the rest - when it is unlocked and ready.
static func _maybe_fire(state: Dictionary, id: StringName, trigger: StringName) -> void:
	if not Ability.unlocked(state, id) or not Ability.ready(state, id):
		return
	var aim := Vector2i(-1, -1)
	var home := Farm.house_centre(state)
	var nearest := _nearest_zombie(state, home)
	match trigger:
		&"crowd":
			if nearest.x >= 0 and _house_distance(state, nearest) <= 8 \
					and _zombies_within(state, nearest, 3) >= 3:
				aim = nearest
		&"house":
			if nearest.x >= 0 and _house_distance(state, nearest) <= 2:
				aim = nearest
		&"near":
			if nearest.x >= 0 and _house_distance(state, nearest) <= 8:
				aim = nearest
		&"hurt":
			aim = _most_hurt_defence(state)
	if aim.x < 0 or not Ability.can_target(state, id, aim):
		return
	var intent: Dictionary = state["intent"]
	intent["ability_cell"] = [aim.x, aim.y]
	if id == Ability.FLARE:
		intent["ability"] = true
	else:
		intent["power"] = id
	var used := Ability.used(state, id)
	Sim.advance(state, 1)
	if Ability.used(state, id) > used:
		_did(state, StringName("power_%s" % id))


## The cell of the zombie nearest `to`, or `(-1, -1)`.
static func _nearest_zombie(state: Dictionary, to: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_far := 1 << 30
	for id in Entities.ids(state):
		var at := Entities.cell_of(state, int(id))
		var far := _far(at, to)
		if far < best_far:
			best_far = far
			best = at
	return best


## How many zombies stand within `reach` tiles of `cell`.
static func _zombies_within(state: Dictionary, cell: Vector2i, reach: int) -> int:
	var n := 0
	for id in Entities.ids(state):
		if _far(Entities.cell_of(state, int(id)), cell) <= reach:
			n += 1
	return n


## The anchor of the defence with the smallest share of its hit points left,
## under two fifths, or `(-1, -1)`.
static func _most_hurt_defence(state: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_share := 40
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		if not _is_defence(state, cell) or Building.anchor_of(state, cell) != cell:
			continue
		var full := maxi(int(Building.entry_at(state, cell).get("hp", 1)), 1)
		var share := int(Farm.occupant(state, cell).get("hp", full)) * 100 / full
		if share < best_share:
			best_share = share
			best = cell
	return best


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


## What the day is saving for: **what the nights took, first** (task 0276),
## then the plan's next entry once every defence the stock already covers is
## set aside for the build step, and the whole bill - `{want, ahead,
## saving_for}`, `ahead` being how many entries were set aside.
static func _the_plan_ahead(state: Dictionary, policy: Dictionary) -> Dictionary:
	var plan: Array = policy["build"]
	var step := int(state.get("autoplay_step", 0))
	var bill := {}
	for lost in _lost_defences(state):
		var with_lost := _plus(bill, Building.cost_of(StringName(lost)))
		if not Resources.missing(state, with_lost).is_empty():
			return {"want": StringName(lost), "ahead": 0, "saving_for": with_lost, "rebuild": true}
		bill = with_lost
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
	# **Money comes in by itself** (task 0234): the night's purse pays it, so
	# a defence short of its money share is waited for. Planned around, the
	# robot would skip every tower whose money it had not yet been paid.
	if res == GameData.MONEY:
		return true
	for id in GameData.sorted_names(GameData.GATHERING.keys()):
		if ((GameData.GATHERING[id] as Dictionary).get("yield", {})
				as Dictionary).has(res):
			return true
	return false


## **Work one node of the kind that yields this resource, on foot** (task
## 0276): the nearest standing one the farmer can reach and work today,
## chopped or mined to the end with the verb held. Returns what it cost.
static func _go_and_get(state: Dictionary, res: StringName) -> int:
	var here := Player.cell(state)
	var best := Vector2i(-1, -1)
	var best_far := 1 << 30
	for id in GameData.sorted_names(GameData.GATHERING.keys()):
		var node: Dictionary = GameData.GATHERING[id]
		if not (node.get("yield", {}) as Dictionary).has(res):
			continue
		for cell in Farm.cells_with(state, id):
			var at: Vector2i = cell
			if Interact.verb_at(state, at) == &"" or not Interact.why_not(state, at).is_empty():
				continue
			var far := absi(at.x - here.x) + absi(at.y - here.y)
			if far < best_far:
				best_far = far
				best = at
	if best.x < 0:
		return 0
	var ticks := _use(state, best)
	if ticks > 0:
		_did(state, &"gathered")
	return ticks


# --------------------------------------------------------------- the earners

## **Till, sow, water or harvest one plot - on foot** (task 0276), whichever
## the field wants next; refill the can at the well, and buy the season's
## packets from the peddler in his hours. Returns what it cost, or zero when
## the field wants nothing - and in winter, when nothing grows outdoors, it
## never does. **Never with the money the plan is saving for** (task 0234): a
## packet is bought only out of what is left over `keep`.
static func _work_the_field(state: Dictionary, keep: int = 0) -> int:
	var choices := Farming.in_season(state)
	var crop := _best_crop(choices)
	var field := _the_field(state)
	var wants_seed := 0
	for plot in field:
		if Farming.verb_at(state, plot) == &"plant":
			wants_seed += 1
	for i in field.size():
		var plot: Vector2i = field[i]
		var verb := Farming.verb_at(state, plot)
		if verb == &"":
			# Dry, growing, and the can is empty: to the well first.
			if Farming.crop_on(state, plot) != &"" and not Farming.is_ready(state, plot) \
					and not Farming.is_watered(state, plot) and Farming.water_carried(state) == 0:
				return _fill_the_can(state)
			continue
		if verb == &"plant":
			if crop == &"" or not Interact.why_not(state, plot).is_empty():
				continue
			Farming.select_seed(state, crop)
			if Resources.amount(state, Farming.packet(crop)) == 0:
				var bought := _buy_at_the_stall(state, Farming.packet(crop), wants_seed, keep)
				if bought > 0:
					return bought
				continue
		var ticks := _use(state, plot)
		if ticks > 0:
			_did(state, StringName(verb))
			return ticks
	return 0


## The in-season crop worth most a growing day, or `&""` for none.
static func _best_crop(choices: Array) -> StringName:
	var best := &""
	var best_worth := -1
	for id in GameData.sorted_names(choices):
		var crop: Dictionary = GameData.CROPS[id]
		var worth := int(GameData.SELL_PRICE.get(StringName(id), 1)) * 100 \
			/ maxi(int(crop.get("growth_days", 1)), 1)
		if worth > best_worth:
			best_worth = worth
			best = StringName(id)
	return best


## **To the well**, where standing beside it fills the can (`Farming`).
static func _fill_the_can(state: Dictionary) -> int:
	var wells := Farm.cells_with(state, &"well")
	if wells.is_empty():
		return 0
	var before := int(state["day_tick"])
	if not _walk_to(state, _sides_of(state, wells[0])):
		return 0
	Sim.advance(state, 1)
	return maxi(int(state["day_tick"]) - before, 1)


## The field, in a fixed order. Cache the starter beds to avoid scanning the
## terrain every action; turned grass follows the current plots.
static func _the_field(state: Dictionary) -> Array:
	if not state.has("autoplay_field"):
		state["autoplay_field"] = Farming.field_cells(state)
	var cells: Array = []
	for cell in state["autoplay_field"]:
		if Farm.terrain_at(state, cell) == Farm.Terrain.SOIL:
			cells.append(cell)
	var keys: Array = (state["plots"] as Dictionary).keys()
	keys.sort()
	for idx in keys:
		var cell := Grid.cell(int(idx))
		if Farm.terrain_at(state, cell) == Farm.Terrain.GRASS:
			cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Grid.index(a) < Grid.index(b))
	return cells


## **A cast and the bar** (task 0276): on foot to the water nearest the
## farmer, the cast through `interact`, the wait, and each press through the
## same intent when the marker is over the green and this sweep has not
## scored - what a player watching it does. `CASTS_A_DAY` a day. Returns the
## ticks it took, or zero when the pond has had its turn or none will bite.
static func _go_fishing(state: Dictionary) -> int:
	var did: Dictionary = state.get("autoplay_did", {})
	if int(did.get(&"cast", 0)) >= CASTS_A_DAY:
		return 0
	var water := _nearest_water(state)
	if water.x < 0:
		return 0
	var before := int(state["day_tick"])
	var stand := _sides_of(state, water)
	if not _walk_to(state, stand):
		return 0
	_face(state, water)
	if Interact.verb_at(state, water) != &"fish":
		return 0
	_did(state, &"cast")
	_press_interact(state)
	var guard := 0
	while Player.is_busy(state) and guard < 200:
		Sim.advance(state, 1)
		guard += 1
	guard = 0
	while Fishing.is_casting(state) and not Fishing.is_biting(state) and guard < 4000:
		Sim.advance(state, 1)
		guard += 1
	guard = 0
	while Fishing.is_biting(state) and guard < 4000:
		var line: Dictionary = Fishing.cast_of(state)
		if Fishing.in_zone(line) and int(line.get("struck", -1)) != Fishing.pass_of(line):
			(state["intent"] as Dictionary)["interact"] = true
		Sim.advance(state, 1)
		guard += 1
	if _landed(state):
		_did(state, &"fish")
	return maxi(int(state["day_tick"]) - before, 1)


## Whether the last cast put a fish in the bag: the run's book grew.
static func _landed(state: Dictionary) -> bool:
	var count := 0
	for page in Fishing.book_of(state).values():
		count += int((page as Dictionary).get("caught", 0))
	var was := int(state.get("autoplay_fish_count", 0))
	state["autoplay_fish_count"] = count
	return count > was


## The water cell nearest the farmer that a line can go into from a cell he
## can stand on, or `(-1, -1)`.
static func _nearest_water(state: Dictionary) -> Vector2i:
	if not state.has("autoplay_water"):
		var edge: Array = []
		for y in Grid.HEIGHT:
			for x in Grid.WIDTH:
				var cell := Vector2i(x, y)
				if Farm.terrain_at(state, cell) != Farm.Terrain.WATER:
					continue
				for step in Grid.STEPS:
					var side: Vector2i = cell + step
					if Grid.in_bounds(side) and Farm.walkable(state, side):
						edge.append(cell)
						break
		state["autoplay_water"] = edge
	var here := Player.cell(state)
	var best := Vector2i(-1, -1)
	var best_far := 1 << 30
	for cell in state["autoplay_water"]:
		var at: Vector2i = cell
		if Fishing.verb_at(state, at) != &"fish":
			continue
		var far := absi(at.x - here.x) + absi(at.y - here.y)
		if far < best_far:
			best_far = far
			best = at
	return best


## **The animals** (task 0276): what is waiting at a home's door collected,
## a pig's spot dug, and the plan's animals bought from the peddler into a
## home with room, in his hours. Returns the ticks it took.
static func _tend_the_animals(state: Dictionary, policy: Dictionary, keep: int) -> int:
	for idx in _sorted_occupants(state):
		var cell := Grid.cell(int(idx))
		var on := Farm.occupant(state, cell)
		if on.is_empty() or not Livestock.is_home(StringName(on["id"])):
			continue
		var door := Livestock.door_of(state, cell)
		if door != cell or Livestock.verb_at(state, door) != &"collect":
			continue
		var ticks := _use(state, door)
		if ticks > 0:
			_did(state, &"collected")
			return ticks
	for spot in Livestock.spots(state):
		var at: Vector2i = spot if spot is Vector2i else Grid.cell(int(spot))
		if Interact.verb_at(state, at) == &"dig":
			var dug := _use(state, at)
			if dug > 0:
				_did(state, &"dug")
				return dug
	for kind in ((policy.get("buys", {}) as Dictionary).get("animals", []) as Array):
		if Livestock.room_for(state, StringName(kind)) <= 0:
			continue
		var bought := _buy_at_the_stall(state, StringName(kind), 1, keep)
		if bought > 0:
			return bought
	return 0


## **The machines** (task 0276): each standing one, on foot, with its queue
## topped up from what the farm made - the grapes into the keg, the milk into
## the dairy. Returns the ticks it took.
static func _work_the_machines(state: Dictionary) -> int:
	for machine in MACHINES:
		for cell in Farm.cells_with(state, StringName(machine)):
			var at: Vector2i = cell
			if Building.anchor_of(state, at) != at:
				continue
			var ticks := _queue_at(state, at, {}, true)
			if ticks > 0:
				return ticks
	return 0


## **A station's queue topped up, on foot**: to its side, the `craft` verb,
## and recipes through the queue's panel while it has room - never made of
## what `saving_for` names. Returns the ticks, or zero when nothing could go
## on. `machine` says whether this is the day plan's machines or the bench.
static func _queue_at(state: Dictionary, cell: Vector2i, saving_for: Dictionary, machine: bool) -> int:
	var id := StringName(Farm.occupant(state, cell).get("id", &""))
	var can := false
	for recipe in Crafting.recipes_at(id):
		if Crafting.can_queue(state, cell, StringName(recipe)) \
				and not _would_raid(saving_for, StringName(recipe)) \
				and not GameData.is_tool_upgrade(StringName(recipe)):
			can = true
			break
	if not can:
		return 0
	var before := int(state["day_tick"])
	if not _walk_to(state, _sides_of(state, cell)):
		return 0
	var put := 0
	for _slot in GameData.QUEUE_LENGTH:
		var queued := false
		for recipe in Crafting.recipes_at(id):
			if GameData.is_tool_upgrade(StringName(recipe)) or _would_raid(saving_for, StringName(recipe)):
				continue
			if Crafting.enqueue(state, cell, StringName(recipe)):
				queued = true
				put += 1
				break
		if not queued:
			break
	if put > 0:
		_did(state, &"machine_queued" if machine else &"crafted")
	return maxi(int(state["day_tick"]) - before, GameData.SECONDS)


# --------------------------------------------------------------- the panels

## **The peddler's stall in his hours** (task 0190, 0276): on foot to it, the
## `trade` verb that opens it, `n` of `id` bought through its button, and the
## panel shut. Packets and animals are bought here; zero when he is shut, the
## purse is short of `keep` and the price, or nothing would go.
static func _buy_at_the_stall(state: Dictionary, id: StringName, n: int, keep: int) -> int:
	if not Shop.open_hours(state):
		return 0
	var price := Shop.buy_price(id)
	var most := (Resources.amount(state, GameData.MONEY) - keep - SPARE_MONEY) / maxi(price, 1)
	n = mini(n, most)
	if n <= 0 or not Shop.can_buy(state, id, 1):
		return 0
	var stalls := Farm.cells_with(state, &"shop")
	if stalls.is_empty():
		return 0
	var before := int(state["day_tick"])
	if not _open_at(state, stalls, &"shop"):
		return 0
	var got := 0
	while got < n and Shop.buy(state, id, 1):
		got += 1
	_close_any_panel(state)
	if got > 0:
		_did(state, StringName("bought_%s" % id))
	return maxi(int(state["day_tick"]) - before, 1) if got > 0 else 0


## **What the policy upgrades**, once a day: the next tier of each tool it
## names from the peddler's pack (its workshop recipe, ordered at the stall)
## and the house's next tier at the workshop, each when the money over the
## plan's and `SPARE_MONEY` pays for it - **and never with what the plan is
## saving for**, as a recipe never raids it: an upgrade's iron is a tower's.
## Returns the ticks it took.
static func _the_shopping(state: Dictionary, policy: Dictionary, saving_for: Dictionary) -> int:
	var did: Dictionary = state.get("autoplay_did", {})
	if int(did.get(&"shopped", 0)) > 0:
		return 0
	var keep := int(saving_for.get(GameData.MONEY, 0))
	var buys: Dictionary = policy.get("buys", {})
	for tool in (buys.get("tools", []) as Array):
		var next := _next_tool(state, StringName(tool))
		if next == &"" or not ToolTiers.why_not(state, next).is_empty() \
				or _would_raid(saving_for, next):
			continue
		var money := int(Shop.cost_of(next).get(GameData.MONEY, 0))
		if Resources.amount(state, GameData.MONEY) - keep - SPARE_MONEY < money:
			continue
		_did(state, &"shopped")
		var ticks := _buy_at_the_stall(state, next, 1, keep)
		if ticks > 0:
			return ticks
	if bool(buys.get("house", false)) and House.why_not_tier(state).is_empty():
		var cost: Dictionary = House.next_cost(state)
		var raids := false
		for res in cost:
			raids = raids or (res != GameData.MONEY and saving_for.has(res))
		if not raids and Resources.amount(state, GameData.MONEY) - keep - SPARE_MONEY >= int(cost.get(GameData.MONEY, 0)):
			var benches := Farm.cells_with(state, &"workshop")
			if not benches.is_empty():
				_did(state, &"shopped")
				var before := int(state["day_tick"])
				if _walk_to(state, _sides_of(state, Building.anchor_of(state, benches[0]))):
					if House.buy_tier(state):        # the workshop panel's row
						_did(state, &"house_tier")
					return maxi(int(state["day_tick"]) - before, 1)
	return 0


## The workshop recipe that takes `tool` up one tier, or `&""`.
static func _next_tool(state: Dictionary, tool: StringName) -> StringName:
	var next := ToolTiers.tier(state, tool) + 1
	for id in GameData.tool_upgrades():
		var output: Dictionary = (GameData.RECIPES[id] as Dictionary)["output"]
		var target := GameData.tool_output(StringName(output.keys()[0]))
		if StringName(target.get("tool", &"")) == tool and int(target.get("tier", 0)) == next:
			return StringName(id)
	return &""


## **The evening's walk to the bin** (task 0189, 0276): what the farm made
## today - crops, fish, animal products, artisan goods - into the shipping bin
## through its panel, paid in the morning. A machine's input keeps
## `KEEP_FOR_MACHINES` back; the materials the plan builds with stay home.
static func _ship_the_day(state: Dictionary, policy: Dictionary, bed: int) -> void:
	var goods: Array = []
	for id in _goods():
		var keep := KEEP_FOR_MACHINES if _machine_inputs().has(id) else 0
		if Resources.amount(state, StringName(id)) > keep:
			goods.append(id)
	if goods.is_empty():
		return
	var bins := Farm.cells_with(state, &"shipping_bin")
	if bins.is_empty():
		return
	if not _open_at(state, bins, Shipping.PANEL):
		return
	var shipped := false
	for id in goods:
		var keep := KEEP_FOR_MACHINES if _machine_inputs().has(id) else 0
		var n := Resources.amount(state, StringName(id)) - keep
		if n > 0 and Shipping.put(state, StringName(id), n):
			shipped = true
	_close_any_panel(state)
	if shipped:
		_did(state, &"shipped")


## Every resource the bin is meant for: crops, fish, what animals give and
## what the machines make.
static func _goods() -> Array:
	var out: Array = []
	for id in GameData.sorted_names(GameData.CROPS.keys()):
		out.append(StringName(id))
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		out.append(StringName(id))
	for kind in GameData.sorted_names(GameData.LIVESTOCK.keys()):
		for res in GameData.sorted_names(((GameData.LIVESTOCK[kind] as Dictionary).get("produces", {}) as Dictionary).keys()):
			if not out.has(StringName(res)):
				out.append(StringName(res))
	for recipe in GameData.sorted_names(GameData.RECIPES.keys()):
		var row: Dictionary = GameData.RECIPES[recipe]
		if not MACHINES.has(StringName(row["station"])):
			continue
		for res in GameData.sorted_names((row["output"] as Dictionary).keys()):
			if not out.has(StringName(res)):
				out.append(StringName(res))
	var sold: Array = []
	for id in out:
		if Shipping.takes(StringName(id)) and GameData.RESOURCES.has(StringName(id)):
			sold.append(id)
	return sold


## What the machines are fed.
static func _machine_inputs() -> Array:
	var out: Array = []
	for recipe in GameData.sorted_names(GameData.RECIPES.keys()):
		var row: Dictionary = GameData.RECIPES[recipe]
		if not MACHINES.has(StringName(row["station"])):
			continue
		for res in GameData.sorted_names((row["inputs"] as Dictionary).keys()):
			if not out.has(StringName(res)):
				out.append(StringName(res))
	return out


## **The night's leftovers** (task 0221), picked up on foot: every pile the
## farmer can walk onto, nearest first, before `bed`.
static func _pick_up_the_loot(state: Dictionary, bed: int) -> void:
	for _guard in 40:
		if int(state["day_tick"]) >= bed:
			return
		var piles := Loot.cells(state)
		if piles.is_empty():
			return
		var here := Player.cell(state)
		var best := Vector2i(-1, -1)
		var best_far := 1 << 30
		for pile in piles:
			var at: Vector2i = pile
			if not Farm.walkable(state, at):
				continue
			var far := absi(at.x - here.x) + absi(at.y - here.y)
			if far < best_far:
				best_far = far
				best = at
		if best.x < 0 or not _walk_to(state, [best]):
			return
		_did(state, &"loot")


## On foot to a side of the first of `cells` and the verb that opens `panel`.
static func _open_at(state: Dictionary, cells: Array, panel: StringName) -> bool:
	for cell in cells:
		var at: Vector2i = cell
		var sides := _sides_of(state, at)
		if sides.is_empty():
			continue
		if not _walk_to(state, sides):
			continue
		_face(state, at)
		_press_interact(state)
		var guard := 0
		while StringName(state["open_panel"]) != panel and Player.is_busy(state) and guard < 60:
			Sim.advance(state, 1)
			guard += 1
		if StringName(state["open_panel"]) == panel:
			return true
	return false


## Shut whatever panel is open, through `cancel`.
static func _close_any_panel(state: Dictionary) -> void:
	if StringName(state["open_panel"]) == &"":
		return
	(state["intent"] as Dictionary)["cancel"] = true
	Sim.advance(state, 1)


# ------------------------------------------------------------------ on foot

## **Use a cell on foot** (task 0276): walk to its side - or onto it, for a
## plot - face it, press `interact`, and wait while the job runs (a tree is
## chopped to the stump, a held verb repeating). Returns the ticks it took,
## or zero when he could not get there or it offered nothing.
static func _use(state: Dictionary, cell: Vector2i) -> int:
	var before := int(state["day_tick"])
	var sides := _sides_of(state, cell)
	if sides.is_empty() or not _walk_to(state, sides):
		return 0
	_face(state, cell)
	if Player.target(state) != cell or Interact.verb_at(state, cell) == &"":
		return 0
	_press_interact(state)
	var guard := 0
	while Player.is_busy(state) and guard < 4000:
		Sim.advance(state, 1)
		guard += 1
	return maxi(int(state["day_tick"]) - before, 1)


## The `interact` edge, and the tick that reads it.
static func _press_interact(state: Dictionary) -> void:
	(state["intent"] as Dictionary)["interact"] = true
	Sim.advance(state, 1)


## The cells beside `cell` the farmer can stand on, north, east, south, west.
static func _sides_of(state: Dictionary, cell: Vector2i) -> Array:
	var out: Array = []
	for step in Grid.STEPS:
		var side: Vector2i = cell + step
		if Grid.in_bounds(side) and Farm.walkable(state, side) \
				and Farm.occupant(state, side).is_empty():
			out.append(side)
	return out


## **Walk to the nearest of `goals`** (task 0276), the shortest road over
## walkable ground found first and then walked a tick at a time through the
## `move` intent, toward each cell's middle in turn. False when there is no
## road or he stops being able to move. The tiles walked add to the night's
## `steps`.
static func _walk_to(state: Dictionary, goals: Array) -> bool:
	if goals.is_empty():
		return false
	var road := _road_to(state, goals)
	if not bool(road["found"]):
		return false
	for cell in (road["path"] as Array):
		if not _step_into(state, cell):
			_halt(state)
			return false
		state["autoplay_steps"] = int(state.get("autoplay_steps", 0)) + 1
	_settle(state)
	_halt(state)
	return true


## The shortest road from the farmer's cell to any of `goals`, four ways
## round, in `Grid.STEPS` order: `{found, path}`, the path the cells after
## his own.
static func _road_to(state: Dictionary, goals: Array) -> Dictionary:
	var start := Player.cell(state)
	var wanted := {}
	for goal in goals:
		wanted[Grid.index(goal as Vector2i)] = true
	if wanted.has(Grid.index(start)):
		return {"found": true, "path": []}
	var came := {Grid.index(start): -1}
	var queue: Array = [start]
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step in Grid.STEPS:
			var next: Vector2i = at + step
			if not Grid.in_bounds(next):
				continue
			var idx := Grid.index(next)
			if came.has(idx) or not Farm.walkable(state, next):
				continue
			came[idx] = Grid.index(at)
			if wanted.has(idx):
				var path: Array = []
				var back := idx
				while back != Grid.index(start):
					path.push_front(Grid.cell(back))
					back = int(came[back])
				return {"found": true, "path": path}
			queue.append(next)
	return {"found": false, "path": []}


## Toward the middle of `cell`, a tick at a time, until he stands in it. False
## when he stops moving.
static func _step_into(state: Dictionary, cell: Vector2i) -> bool:
	var half := Player.SUBTILE / 2
	var centre := Vector2i(cell.x * Player.SUBTILE + half, cell.y * Player.SUBTILE + half)
	var near := GameData.PLAYER_SPEED
	var still := 0
	for _tick in 200:
		var pos := Player.position(state)
		if Player.cell(state) == cell and absi(centre.x - pos.x) <= half - near \
				and absi(centre.y - pos.y) <= half - near:
			return true
		var dx := 0 if absi(centre.x - pos.x) <= near / 2 else signi(centre.x - pos.x)
		var dy := 0 if absi(centre.y - pos.y) <= near / 2 else signi(centre.y - pos.y)
		(state["intent"] as Dictionary)["move"] = [dx, dy]
		Sim.advance(state, 1)
		if Player.position(state) == pos:
			still += 1
			if still > 6:
				return false
		else:
			still = 0
	return false


## The last few steps to the middle of the cell he stands in, so a turn to
## face a neighbour cannot carry him over its edge.
static func _settle(state: Dictionary) -> void:
	var here := Player.cell(state)
	var half := Player.SUBTILE / 2
	var centre := Vector2i(here.x * Player.SUBTILE + half, here.y * Player.SUBTILE + half)
	for _tick in 12:
		var pos := Player.position(state)
		var dx := 0 if absi(centre.x - pos.x) <= GameData.PLAYER_SPEED / 2 else signi(centre.x - pos.x)
		var dy := 0 if absi(centre.y - pos.y) <= GameData.PLAYER_SPEED / 2 else signi(centre.y - pos.y)
		if dx == 0 and dy == 0:
			return
		(state["intent"] as Dictionary)["move"] = [dx, dy]
		Sim.advance(state, 1)


## Turn to face a neighbouring cell: one tick's lean toward it. Into what he
## cannot walk on he does not move; onto what he can he moves less than a
## tile's half, from the middle of his own.
static func _face(state: Dictionary, cell: Vector2i) -> void:
	var here := Player.cell(state)
	if cell == here:
		return
	var dx := signi(cell.x - here.x)
	var dy := signi(cell.y - here.y)
	(state["intent"] as Dictionary)["move"] = [dx, dy]
	Sim.advance(state, 1)
	_halt(state)


## Stand still: the `move` level let go.
static func _halt(state: Dictionary) -> void:
	(state["intent"] as Dictionary)["move"] = [0, 0]


## Mark one more of a kind of thing done today, for the night's row.
static func _did(state: Dictionary, what: StringName) -> void:
	if not state.has("autoplay_did"):
		state["autoplay_did"] = {}
	var did: Dictionary = state["autoplay_did"]
	did[what] = int(did.get(what, 0)) + 1


# --------------------------------------------------------------- the sums

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
	# with them. Sheds go behind the house, which is where a player puts them
	# and why farms look the way they do.
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
