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
## **Same ticks as before.** `through_build()` runs off what is *left* of the
## build step, which on a fresh one is exactly `PREPARATION_TICKS` - so a test
## routed through here steps the same ticks it always did, and the hashes do
## not move.
##
## The rules have their own single road: `Phases.start_waves()`, which the
## build step's timer calls. Nothing outside `src/core/` calls
## `Phases.begin_night()`; `_task_0118_road` in `headless_v1` reads the code
## to keep it so.


## Into the build step: the night button, without the button.
static func into_build(state: Dictionary) -> bool:
	return Phases.begin_preparation(state)


## How many ticks of the build step are still to run. Zero outside it.
static func build_ticks_left(state: Dictionary) -> int:
	if int(state["phase"]) != Phases.PREPARATION:
		return 0
	return maxi(GameData.PREPARATION_TICKS - int(state["phase_tick"]), 0)


## Through the rest of the build step, to the tick the waves start on.
static func through_build(state: Dictionary) -> void:
	var left := build_ticks_left(state)
	if left > 0:
		Sim.advance(state, left)


## Both: from the day to the first tick of the night.
static func to_night(state: Dictionary) -> bool:
	if not into_build(state):
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
