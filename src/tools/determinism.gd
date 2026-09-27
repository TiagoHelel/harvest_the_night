extends SceneTree

## The scripted scenario behind the hash guards.
##
## Prints two integers and nothing else that looks like one:
##
##     SIM <n>     the state after a fixed scenario of a fixed length
##     DATA <n>    every balance table in GameData, folded
##
## `tools/verify.py` compares each against its baseline file and fails when one
## moved. Moving one on purpose is `python tools/verify.py --accept`, which
## prints the old and the new number so the journal can record both.
##
## **Two numbers because they answer two questions.** SIM asks whether the
## rules still do the same thing from the same seed; DATA asks whether the
## design is still the design. A task that ports code without changing
## behaviour must move neither. A balance pass moves DATA and says so. A new
## system that consumes randomness moves SIM and says so.
##
## The scenario is deliberately boring: create a state from one seed and
## advance it. Every system the backlog adds ticks inside `Sim.tick()`, so each
## one starts being covered the moment it lands, without this file changing.
## When a system needs setting up to be exercised - a farm with crops in it, a
## night with zombies walking - the setup goes here, above the advance.

const SCENARIO_SEED := 424242
const SCENARIO_TICKS := 20000

## Bounded like `headless_check` is, and for the same reason: a tool script
## that errors leaves the SceneTree running rather than exiting.
const WATCHDOG_SECONDS := 10.0

var _finished := false
var _reached_end := false
var _elapsed := 0.0


func _initialize() -> void:
	_run()
	_finish()


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("determinism: watchdog fired after %.0fs" % _elapsed)
	_finish()
	return true


func _run() -> void:
	var state := State.create(SCENARIO_SEED)
	Sim.advance(state, SCENARIO_TICKS)

	print("SIM ", State.hash_of(state))
	print("DATA ", GameData.digest())
	_reached_end = true          # last line: an abandoned run never gets here


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if not _reached_end:
		print("the scenario did not finish - no number above is trustworthy")
		quit(1)
		return
	quit(0)
