class_name Phases
extends RefCounted

## The loop the whole game is.
##
##     DAY -> PREPARATION -> NIGHT -> RESULT -> DAY
##
## Owned by the rules rather than by a screen. Every transition is a function
## taking the state, not a signal: a signal would mean the order two listeners
## run in decides what happens, and that is not a thing a deterministic
## simulation can afford.
##
## Each transition **refuses** a move it is not allowed to make and says so,
## rather than half-applying it. A corrupted phase would show up three thousand
## ticks later as a zombie on a sunny afternoon.
##
## What differs between DAY and NIGHT is only which systems `Sim.tick()` runs.
## The tick itself, the rate, the RNG and the state are the same in both, which
## is what makes "the same farm, a different world" true in the code as well as
## in the pitch.

enum { DAY, PREPARATION, NIGHT, RESULT }

const NAMES := ["DAY", "PREPARATION", "NIGHT", "RESULT"]


static func name_of(phase: int) -> String:
	return NAMES[phase] if phase >= 0 and phase < NAMES.size() else "?"


## The keys this machine owns, and what a new game starts them at.
## `State.create()` merges these in.
## How many nights the run has got past. The night to be fought is this plus
## one, which is what makes a lost night one you fight again.
static func nights_won(state: Dictionary) -> int:
	return int(state["nights_won"])


static func initial() -> Dictionary:
	return {
		"phase": DAY,
		"day": 1,
		# The night about to be fought, or 0 before the first one.
		#
		# **It is not the day counter.** It was, until task 0065: `night 3 is
		# the night at the end of day 3` read well and meant that losing
		# night three sent the run on to night four, so a player could lose
		# their way to the Giant without beating anything. The night to fight
		# is the one after the last one won.
		"night": 0,
		# How many nights the run has got past. A lost night does not move
		# it, which is the whole of "the night can be retried".
		"nights_won": 0,
		# Ticks since the current phase began. Every phase uses it, which is
		# why it is here and not in three places.
		"phase_tick": 0,
		# Ticks of DAY elapsed today - the day clock of task 0039 - and ticks
		# of the night so far. They are separate from `phase_tick` because a
		# night that is paused by a RESULT screen and resumed still knows how
		# long it has been going.
		"day_tick": 0,
		"night_tick": 0,
		# Filled in by `enter_result()`, read by the result screen.
		"last_result": {},
	}


## **Going to bed is the reality switch** (task 0127, `docs/PLANO-DO-JOGO.md`
## section 12: when he sleeps, the farm switches reality). The bed in the
## farmhouse and the GO TO BED button both arrive here, through the `sleep`
## intent. DAY only; anything else is refused and says so.
##
## **Sleeping early skips the rest of the day, and the skipped hours are
## neither lived nor credited**: a crafting queue, regrowth, the animals and the
## generator keep the progress they had and carry on from 06:00 - no work is
## lost, and nothing is produced for hours nobody lived. It is what the night
## button always did; `_task_0127_bed` holds it.
static func go_to_bed(state: Dictionary) -> bool:
	if int(state["phase"]) != DAY:
		push_error("go_to_bed from %s" % name_of(int(state["phase"])))
		return false
	return begin_preparation(state)


## DAY -> PREPARATION. The farmer went to bed.
##
## **Every road into the build step leaves him asleep** - the bed, the button,
## 0128's pass-out and the tests' `NightRoad` - because this is the one that
## sets it. Asleep is not inside: the farmhouse room is left as it always was,
## so building and the world view carry on outdoors.
static func begin_preparation(state: Dictionary) -> bool:
	if int(state["phase"]) != DAY:
		push_error("begin_preparation from %s" % name_of(int(state["phase"])))
		return false
	# Whatever was open closes with the day. Standing at the market while the
	# first zombie walks in would be a panel that outlived its reason.
	state["open_panel"] = &""
	House.leave(state)
	(state["house_visit"] as Dictionary)["asleep"] = true
	# The water goes off with the sun: watering is a daily chore, not a job you
	# do once on day one and never again.
	Farming.dry_out(state)
	_enter(state, PREPARATION)
	# **After the phase changes**, because the last line of day one is "send
	# for the night" and the only way to know it was sent for is that it is no
	# longer day. Ticking before the change asked whether the night had
	# started and was told no, every time.
	Tutorial.tick(state)
	return true


## What a whole house is worth tonight, the tree included.
static func house_full(state: Dictionary) -> int:
	return GameData.HOUSE_HP + Tech.bonus(state, "house_hp_bonus", 0)


## PREPARATION -> NIGHT: **the one road into the waves** (task 0118).
##
## `Sim._tick_preparation()` calls it when the build step's time is up; 0136's
## START intent and 0128's pass-out step will be its other callers. Nothing
## outside `src/core/` starts a night any other way - the tools and tests go
## through `NightRoad`, which ends here.
static func start_waves(state: Dictionary) -> bool:
	if int(state["phase"]) != PREPARATION:
		push_error("start_waves from %s" % name_of(int(state["phase"])))
		return false
	return begin_night(state)


## PREPARATION -> NIGHT. The first zombie is now allowed to exist.
##
## The transition itself; `start_waves()` is the door to it.
static func begin_night(state: Dictionary) -> bool:
	if int(state["phase"]) != PREPARATION:
		push_error("begin_night from %s" % name_of(int(state["phase"])))
		return false
	# A new night, a fresh allowance of whatever is limited per night.
	Building.forget_tonight(state)
	Ability.recharge(state)

	# The night to be fought is the one after the last one won, not the
	# number of days that have gone by. See `enter_result()`.
	state["night"] = int(state["nights_won"]) + 1
	state["night_tick"] = 0
	Events.add(state, &"night_began", {"night": int(state["night"])})
	# Everything about what is coming is reset here rather than by whoever
	# happens to look first: a night that inherited last night's wave counter
	# would be a night that started halfway through.
	state["killed"] = 0
	state["killed_by_kind"] = {}
	state["breaches"] = 0
	# Stout timbers, if the tree has them: the roof is mended to whatever it
	# can hold tonight rather than to what the table alone says.
	state["house_hp"] = house_full(state)
	_enter(state, NIGHT)
	Waves.begin(state)
	return true


## NIGHT -> RESULT.
##
## **The only place the day counter moves.** The payout itself is task 0061;
## what is recorded here is the outcome it will be computed from, so that the
## result screen reads one dictionary rather than interrogating the world after
## the fact.
static func enter_result(state: Dictionary, survived: bool) -> bool:
	if int(state["phase"]) != NIGHT:
		push_error("enter_result from %s" % name_of(int(state["phase"])))
		return false
	state["last_result"] = {
		"night": int(state["night"]),
		"survived": survived,
		"ticks": int(state["night_tick"]),
	}
	Events.add(state, &"night_won" if survived else &"night_lost",
		{"night": int(state["night"])})
	# **A day passes either way; a night is only got past by surviving it.**
	#
	# These used to be the same number - `begin_night()` set the night from
	# the day - so losing night three moved the run on to night four, and a
	# player could lose their way to the Giant without ever beating anything.
	# `design.md` and task 0065 both say a loss costs **a day**, so the day
	# advances and the night does not: you get another morning to prepare and
	# the same night comes back.
	state["day"] = int(state["day"]) + 1
	if survived:
		state["nights_won"] = int(state["nights_won"]) + 1
		# **The run can end here.** Ten nights and the Giant is the MVP, and
		# `Run.is_over()` is what the result screen asks to know whether it
		# is showing a night or an ending.
		if Run.is_over(state):
			state["last_result"]["run_over"] = true
	_enter(state, RESULT)
	return true


## RESULT -> DAY. The player has read the result and wants the farm back.
static func begin_day(state: Dictionary) -> bool:
	if int(state["phase"]) != RESULT:
		push_error("begin_day from %s" % name_of(int(state["phase"])))
		return false
	state["day_tick"] = 0
	# Up at 06:00 - wherever he is until 0138 wakes him in his bed - and a
	# bedtime asked for after dark is not carried into the morning.
	(state["house_visit"] as Dictionary)["asleep"] = false
	(state["intent"] as Dictionary)["sleep"] = false
	# **The yard is swept first.** The night's wreckage belongs to the
	# night, and a farm that never cleared would silt up over ten of them.
	Farm.clear_rubble(state)
	# **And whoever the night left standing goes with it.** A won night
	# ends only when nothing is left alive, but the house can fall with
	# half a wave in the yard - and nothing ever told them to leave. They
	# stood in the sun all day, and were already at the door when the same
	# night came back.
	Enemies.withdraw(state)
	# A new day, a new stall. It refuses if it has already been out today, so
	# calling it here and on the first tick costs nothing.
	Shop.restock(state)
	_enter(state, DAY)
	return true


## How far through the day it is, as a percentage. Past a hundred once the day
## has run over, which it is allowed to do.
##
## **The one number the light and the clock both read.** Keeping it here rather
## than in the HUD means the autoplayer and the tests can ask the same question
## the sun is answering.
static func day_percent(state: Dictionary) -> int:
	if int(state["phase"]) != DAY:
		return 100
	return int(state["day_tick"]) * 100 / maxi(GameData.DAY_TICKS, 1)


## How far past dusk, as a percentage of the day. Zero before dusk.
static func overtime_percent(state: Dictionary) -> int:
	if int(state["phase"]) != DAY:
		return 0
	var over := int(state["day_tick"]) - GameData.DUSK_AT_TICK
	if over <= 0:
		return 0
	return over * 100 / maxi(GameData.DAY_TICKS - GameData.DUSK_AT_TICK, 1)


## Whether the clock has passed dusk (18:00 by default). Outside the day it
## answers for the moment the day ended.
##
## Past dusk the night button starts asking to be pressed. It never presses
## itself: `design.md` promises the player switches reality when they want to.
static func is_dusk(state: Dictionary) -> bool:
	return clock_minute(state) >= GameData.DUSK_MINUTE


# ------------------------------------------------------------------- the clock

## The time of day, in minutes since the midnight the day began (task 0126):
## `DAY_START_MINUTE` (360, 06:00) at `day_tick` 0 and `DAY_END_MINUTE` (1560,
## 02:00 the next morning) at `DAY_TICKS`. Integer, and a whole number of ticks
## per minute (`GameData.check_clock`), so every minute is shown exactly once.
##
## `day_tick` stops when the day does and starts again at dawn, so outside the
## day this answers for the moment the day ended. Until task 0128 sends the
## farmer to bed at 02:00, a day that runs over keeps counting past it.
static func clock_minute(state: Dictionary) -> int:
	return GameData.DAY_START_MINUTE + int(state["day_tick"]) \
		* (GameData.DAY_END_MINUTE - GameData.DAY_START_MINUTE) \
		/ maxi(GameData.DAY_TICKS, 1)


## The `day_tick` a given minute of the clock falls on - the inverse of
## `clock_minute()` on minute boundaries. For tests and tools.
static func tick_at_minute(minute: int) -> int:
	return (minute - GameData.DAY_START_MINUTE) * GameData.DAY_TICKS \
		/ maxi(GameData.DAY_END_MINUTE - GameData.DAY_START_MINUTE, 1)


static func _enter(state: Dictionary, phase: int) -> void:
	state["phase"] = phase
	state["phase_tick"] = 0
