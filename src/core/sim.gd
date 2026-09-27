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
##
## Which systems run is decided by the phase, and by nothing else. That is what
## makes "crops do not grow at night" and "no zombie spawns in the afternoon"
## structural facts rather than conditions somebody has to remember to write in
## fifteen different places.
static func tick(state: Dictionary) -> void:
	state["tick"] = int(state["tick"]) + 1
	state["phase_tick"] = int(state["phase_tick"]) + 1

	match int(state["phase"]):
		Phases.DAY:
			_tick_day(state)
		Phases.PREPARATION:
			_tick_preparation(state)
		Phases.NIGHT:
			_tick_night(state)
		Phases.RESULT:
			pass        # nothing moves while the player reads the payout


## The cozy half. Growing, gathering, producing, selling.
static func _tick_day(state: Dictionary) -> void:
	state["day_tick"] = int(state["day_tick"]) + 1

	# **Asked for last frame, decided here.** The button writes an intent and
	# the rules act on it, so the keyboard, the mouse and the autoplayer all
	# take the same road into the night.
	var intent: Dictionary = state["intent"]
	if bool(intent.get("begin_night", false)):
		intent["begin_night"] = false
		Phases.begin_preparation(state)
		return

	Building.tick(state)
	Farming.tick(state)
	Gathering.tick(state)
	Crafting.tick(state)
	Player.tick(state)

	# Systems hang off here as the backlog adds them, in a fixed written order:
	# farming (0018), crafting and the queue (0019, 0037), the press and the
	# generator (0032, 0033), regrowth (0016). Each is a static function taking
	# the state.


## The build step. The clock does not run and nothing attacks: this is the one
## stretch of the game where the player is not being asked to hurry.
static func _tick_preparation(state: Dictionary) -> void:
	Building.tick(state)
	Player.tick(state)
	if int(state["phase_tick"]) >= GameData.PREPARATION_TICKS:
		Phases.begin_night(state)


## The dangerous half. Spawning, walking, shooting, dying.
##
## **The order is part of the rules.** Whether towers fire before or after
## zombies move decides whether a zombie dies on the tile it entered or the one
## after, so it is written down here rather than discovered from whatever order
## a Dictionary happens to iterate in.
static func _tick_night(state: Dictionary) -> void:
	state["night_tick"] = int(state["night_tick"]) + 1

	# The player is on the farm after dark too - `design.md` section 8 has them
	# repairing, aiming and dropping barricades. What they can *do* out there is
	# decided by `Interact`, which puts the daylight verbs away at dusk.
	Building.tick(state)
	Player.tick(state)

	# The order below **is** the rules. Enemies move before towers fire, so a
	# zombie that stepped into range this tick can be shot this tick rather
	# than next - which is what makes a range circle mean what it looks like.
	#
	# Waves spawn (0027), enemies move (0025), towers acquire and fire, shots
	# in the air advance and land, and only then is the end of the night
	# tested (0027).
	Enemies.tick(state)
	Towers.tick(state)
	Combat.tick(state)


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
