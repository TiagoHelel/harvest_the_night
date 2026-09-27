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
static func initial() -> Dictionary:
	return {
		"phase": DAY,
		"day": 1,
		# The night about to be fought, or 0 before the first one. It follows
		# the day counter rather than counting separately: night 3 is the night
		# at the end of day 3, and two numbers that must agree are one number.
		"night": 0,
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


## DAY -> PREPARATION. The player pressed the night button.
static func begin_preparation(state: Dictionary) -> bool:
	if int(state["phase"]) != DAY:
		push_error("begin_preparation from %s" % name_of(int(state["phase"])))
		return false
	# Whatever was open closes with the day. Standing at the market while the
	# first zombie walks in would be a panel that outlived its reason.
	state["open_panel"] = &""
	# The water goes off with the sun: watering is a daily chore, not a job you
	# do once on day one and never again.
	Farming.dry_out(state)
	_enter(state, PREPARATION)
	return true


## PREPARATION -> NIGHT. The first zombie is now allowed to exist.
##
## Called by the player ending the build step early, and by `Sim.tick()` when
## `GameData.PREPARATION_TICKS` have passed.
static func begin_night(state: Dictionary) -> bool:
	if int(state["phase"]) != PREPARATION:
		push_error("begin_night from %s" % name_of(int(state["phase"])))
		return false
	state["night"] = int(state["day"])
	state["night_tick"] = 0
	# Everything about what is coming is reset here rather than by whoever
	# happens to look first: a night that inherited last night's wave counter
	# would be a night that started halfway through.
	state["killed"] = 0
	state["killed_by_kind"] = {}
	state["breaches"] = 0
	state["house_hp"] = GameData.HOUSE_HP
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
	state["day"] = int(state["day"]) + 1
	_enter(state, RESULT)
	return true


## RESULT -> DAY. The player has read the result and wants the farm back.
static func begin_day(state: Dictionary) -> bool:
	if int(state["phase"]) != RESULT:
		push_error("begin_day from %s" % name_of(int(state["phase"])))
		return false
	state["day_tick"] = 0
	_enter(state, DAY)
	return true


## Past dusk the night button starts asking to be pressed. It never presses
## itself: `design.md` promises the player switches reality when they want to.
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


static func is_dusk(state: Dictionary) -> bool:
	return (int(state["phase"]) == DAY
		and int(state["day_tick"]) >= GameData.DUSK_AT_TICK)


static func _enter(state: Dictionary, phase: int) -> void:
	state["phase"] = phase
	state["phase_tick"] = 0
