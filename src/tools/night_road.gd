class_name NightRoad
extends RefCounted

## The road from the day into the waves, for every test and tool.
##
## Until task 0118 some sixty-five places in the suites and tools started a
## night the same way, by hand: `Phases.begin_preparation()`, then
## `Sim.advance()` by `GameData.PREPARATION_TICKS`. Phase 10 changes how the
## build step ends twice - 0136's START and 0137's dawn - and every one of
## those lines would have had to change both times. Now they ask this, and
## those tasks change it once.
##
## **START, not a clock** (task 0136). The build step waits for the player, so
## `through_build()` presses START (`intent.start_waves`) and steps the one
## tick it lands on. A test that wants to stay in the build step simply does
## not go through it; one that waited the old twenty seconds out waits for
## nothing now.
##
## The rules have their own single road: `Phases.start_waves()`, which START
## and a pass-out's short timer call. Nothing outside `src/core/` calls
## `Phases.begin_night()`; `_task_0118_road` in `headless_v1` reads the code
## to keep it so.


## Into the build step: the night button, without the button.
static func into_build(state: Dictionary) -> bool:
	return Phases.begin_preparation(state)


## Into the build step if it is still day; a no-op if the build step is
## already open. **Where a defence goes down** (task 0119): 0132 forbids them
## by day, so a fixture that arms the farm calls this first and the
## `to_night()` after it carries on from wherever it is.
static func to_build(state: Dictionary) -> bool:
	if int(state["phase"]) == Phases.DAY:
		return into_build(state)
	return int(state["phase"]) == Phases.PREPARATION


## Press START, without the button (task 0136).
static func press_start(state: Dictionary) -> void:
	(state["intent"] as Dictionary)["start_waves"] = true


## How many ticks the road takes to leave the build step once START is
## pressed: the one it lands on. Zero outside it.
static func build_ticks_left(state: Dictionary) -> int:
	return 1 if int(state["phase"]) == Phases.PREPARATION else 0


## Through the build step to the first tick of the night: START, and the tick
## it lands on.
static func through_build(state: Dictionary) -> void:
	if int(state["phase"]) != Phases.PREPARATION:
		return
	press_start(state)
	Sim.advance(state, 1)


## Both: from the day - or from a build step already open, where the farm was
## armed - to the first tick of the night.
static func to_night(state: Dictionary) -> bool:
	if not to_build(state):
		return false
	through_build(state)
	return true


## Step the night until it is over - won, lost, or whatever later tasks add -
## or `cap` ticks have gone by. Returns the ticks it took.
##
## The cap is the autoplayer's: forty thousand ticks is twenty-two minutes of
## night, so a night still running at the cap is a night that will not end.
static func run_night(state: Dictionary, cap: int = 40000) -> int:
	var ticks := 0
	while int(state["phase"]) == Phases.NIGHT and ticks < cap:
		Sim.tick(state)
		ticks += 1
	return ticks


## Stop the night sending anything, and stop it deciding it is finished - for
## a check that wants a night with nobody in it but its own fixtures.
##
## **This is also where dawn will be held back.** Task 0137 makes the night
## end at 06:00 whatever is left of it, and a parked night must not end under
## a test that is still using it; that task adds its hold here. No state key
## for it now: any new key moves SIM.
static func park(state: Dictionary) -> void:
	var wave: Dictionary = state["wave"]
	wave["done"] = false
	wave["index"] = 0
	wave["left"] = 0
	wave["wait"] = 1 << 30
