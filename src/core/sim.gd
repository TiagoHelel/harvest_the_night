class_name Sim
extends RefCounted

## The one clock.
##
## Everything the rules do happens inside `tick()`, exactly `GameData.TICK_HZ`
## times a second, whatever the frame rate is. Crop growth, tower fire, zombie
## walking, the headless tests, the double speed button and skipping a night are
## all this one function called a different number of times.
##
## Nothing in here may read a real clock. `state["tick"]` is the only time that
## exists, and `Time.*` is banned in `src/core/` for the same reason `randi()`
## is: a rule that asks the operating system what time it is cannot be replayed.


## Advance the world by exactly one tick.
static func tick(state: Dictionary) -> void:
	state["tick"] = int(state["tick"]) + 1

	# Systems hang off here as the backlog adds them: farming (0018), crafting
	# (0019), the day clock (0039), enemies (0025), towers (0024), waves
	# (0027). Each is a static function taking the state, called from here in a
	# fixed written order.
	#
	# **The order is part of the rules.** Whether towers fire before or after
	# zombies move decides whether a zombie dies on the tile it entered or the
	# one after, so it is written down here rather than discovered from
	# whatever order a Dictionary happens to iterate in.


## Advance by `ticks`, which is how every caller outside a frame loop uses it:
## the headless tests, the autoplayer, and skipping the rest of a night.
static func advance(state: Dictionary, ticks: int) -> void:
	for _i in maxi(ticks, 0):
		tick(state)


## How many whole ticks a frame of `delta` seconds owes, and what is left over.
##
## Returns `[ticks, remainder]`. The remainder is carried into the next frame,
## which is what makes a partial tick impossible and what makes a 144Hz machine
## and a 30Hz one play the same game.
##
## The cap is `GameData.MAX_CATCH_UP_TICKS`: past it the debt is dropped rather
## than paid, because paying whole seconds of simulation inside one frame makes
## the next frame stall too. This is pure arithmetic and lives in core so the
## headless tests can assert on it without a frame.
static func ticks_for(accumulator: float, delta: float) -> Array:
	var acc := accumulator + maxf(delta, 0.0)
	var ticks := int(acc / GameData.TICK_SECONDS)
	if ticks > GameData.MAX_CATCH_UP_TICKS:
		ticks = GameData.MAX_CATCH_UP_TICKS
		acc = 0.0                      # drop the backlog, do not bank it
	else:
		acc -= float(ticks) * GameData.TICK_SECONDS
	return [ticks, acc]
