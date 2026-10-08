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
	# **START, an edge** (task 0136): read once and cleared on every tick, so
	# a press by day or at night is gone rather than waiting for a build step.
	var intent: Dictionary = state["intent"]
	var start := bool(intent.get("start_waves", false))
	intent["start_waves"] = false

	match int(state["phase"]):
		Phases.DAY:
			_tick_day(state)
		Phases.PREPARATION:
			_tick_preparation(state, start)
		Phases.NIGHT:
			_tick_night(state)
		Phases.RESULT:
			_tick_result(state)

	# **Task 0109, after whichever phase ran.** A bubble is about something
	# that has already happened, so it is raised at the bottom of the tick
	# and never in the middle of one: a reaction to a crop that comes ready
	# later in the same tick would be a frame early, and nobody would ever
	# work out why.
	#
	# It writes one key, `state["reaction"]`, which `State.hash_of` does not
	# look at. Nothing else in `src/core/` reads it and `headless_check`
	# greps to keep that so - which is what lets a fact about the view live
	# in the state without being part of the game.
	Reactions.tick(state)


## The payout, on screen. **Nothing else moves**: the farm waits while it is
## read, which is the one moment in the game that it does.
static func _tick_result(state: Dictionary) -> void:
	var intent: Dictionary = state["intent"]
	if bool(intent.get("confirm_result", false)):
		intent["confirm_result"] = false
		Phases.begin_day(state)


## The cozy half. Growing, gathering, producing, selling.
static func _tick_day(state: Dictionary) -> void:
	# **Time does not pass in a menu.** Standing at the stall haggling is not
	# an afternoon, and a player who opened the shop to think and came back to
	# a field of dead crops would learn to think somewhere else.
	#
	# This is a *modal* panel - the shop - and not the inventory of task 0036,
	# which deliberately does not set `open_panel` and deliberately does not
	# stop the clock: a glance at your own pockets is not a conversation.
	#
	# `Player.tick()` still runs, because cancel is how you leave.
	if StringName(state["open_panel"]) != &"":
		Player.tick(state)
		return

	# The first morning, and any morning the phase machine did not open. It
	# refuses when the stock is already today's, so this is one comparison.
	Shop.restock(state)

	state["day_tick"] = int(state["day_tick"]) + 1

	# **Asked for last frame, decided here.** The button and the bed write an
	# intent and the rules act on it, so the keyboard, the mouse, the bed and
	# the autoplayer all take the same road into the night: going to bed.
	var intent: Dictionary = state["intent"]
	if bool(intent.get("sleep", false)):
		intent["sleep"] = false
		Phases.go_to_bed(state)
		return

	# **02:00, and he is still up** (task 0128): he passes out where he stands
	# and the night begins anyway, after a short build step. A bedtime asked
	# for on the same tick wins - that is an ordinary night.
	if int(state["day_tick"]) >= GameData.DAY_TICKS:
		Phases.pass_out(state)
		return

	# **First**, so that everything below it runs at the speed the farm can
	# actually manage this tick rather than last tick's.
	Power.tick(state)

	Building.tick(state)
	Farming.tick(state)
	# **Filling the can is a fact about where the player is standing**, so it
	# is asked here where both are in scope rather than from inside `Farming`,
	# which `Player` already reaches through `Interact`.
	if not House.inside(state):
		Farming.refill_beside(state, Player.cell(state))
	# Same reason as the refill above: a line in the water is a fact about
	# where the farmer is standing, and walking off gives it up.
	Fishing.tick(state, Player.cell(state))
	Gathering.tick(state)
	Livestock.tick(state)
	# Watching, never gating: it can only notice that something happened.
	if not House.inside(state):
		Tutorial.tick(state)
	Crafting.tick(state)
	Player.tick(state)

	# Systems hang off here as the backlog adds them, in a fixed written order:
	# farming (0018), crafting and the queue (0019, 0037), the press and the
	# generator (0032, 0033), regrowth (0016). Each is a static function taking
	# the state.


## The build step. The clock does not run and nothing attacks: this is the one
## stretch of the game where the player is not being asked to hurry - and
## since task 0136 **it waits for START**. Only after a pass-out does it end
## by itself, at `PASS_OUT_PREPARATION_TICKS`.
static func _tick_preparation(state: Dictionary, start: bool = false) -> void:
	Building.tick(state)
	# The tutorial's `build` step happens here now (task 0132): defences go
	# down at night. On its own beat, watching, never gating.
	Tutorial.tick(state)
	Player.tick(state)
	var timer := Phases.build_step_ticks(state)
	if start or (timer > 0 and int(state["phase_tick"]) >= timer):
		Phases.start_waves(state)


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
	Power.tick(state)
	Waves.tick(state)
	# **Before anybody moves.** A flare pressed on the tick a crowd arrives
	# should slow that crowd's step, not the one after it.
	Ability.tick(state)
	Enemies.tick(state)
	# **Straight after everybody has moved**, so a mine goes off on the tick a
	# foot lands on it rather than up to a tick later.
	Traps.tick(state)
	Towers.tick(state)
	Combat.tick(state)


# ------------------------------------------------------------- skipping ahead

## Whether the rest of tonight may be run off without watching it.
static func can_skip(state: Dictionary) -> bool:
	return why_not_skip(state).is_empty()


## Why it may not be skipped, for the button's tooltip. An empty Array when
## it may. A key and its arguments - see `Building.why_not`.
static func why_not_skip(state: Dictionary) -> Array:
	if int(state["phase"]) != Phases.NIGHT:
		return [&"WHY_ONLY_AT_NIGHT"]
	# A share of the house the night started with, not of the base 100.
	var left := int(state["house_hp"]) * 100 / maxi(Phases.house_full(state), 1)
	if left < GameData.SKIP_MIN_HOUSE_PERCENT:
		return [&"WHY_HOUSE_LOW", left]
	return []


## Run the rest of the night now.
##
## **It is the same ticks, in the same order, with nothing skipped.** "Skip"
## is the player skipping the watching, not the game skipping the simulating:
## this is `advance()` until the night is over, so a skipped night and a
## watched night from the same state end identically. That is the property the
## whole fixed-tick design exists for, and `headless_check` runs a night both
## ways and compares the hash.
##
## Returns how many ticks it took, or zero when it was refused.
static func skip_night(state: Dictionary) -> int:
	if not can_skip(state):
		return 0
	var ticks := 0
	# A bound rather than a `while true`: a rule that stopped ending nights
	# should hang a test, not the game.
	while ticks < MOST_TICKS_IN_A_NIGHT:
		if int(state["phase"]) != Phases.NIGHT:
			break
		tick(state)
		ticks += 1
	return ticks


## Longer than any night the tables can produce, and short enough that hitting
## it is a bug rather than a wait.
const MOST_TICKS_IN_A_NIGHT := 60 * 60 * GameData.TICK_HZ


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
