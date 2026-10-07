class_name SimDriver
extends Node

## Turns frames into ticks.
##
## **The only place in the game that touches `delta`.** It accumulates real
## seconds and calls `Sim.tick()` a whole number of times, carrying the
## remainder into the next frame. Everything else - every rule, every system,
## every test - counts in ticks and never asks how long a tick took.
##
## It lives in `src/ui/` because it is the boundary: `src/core/` must not know
## that frames exist.

## Emitted after a frame's ticks have all run, not once per tick: a view that
## redraws per tick would redraw eight times on a frame catching up.
signal ticked(state: Dictionary)

## Read-only work observers bracket the same fixed ticks. This keeps instant
## gestures observable at 4x/catch-up without making every view redraw per tick.
signal stepping(state: Dictionary)
signal stepped(state: Dictionary)

## The game. Empty until `start()`.
var state: Dictionary = {}

## Ticks run per real tick owed: one of `GameData.SPEEDS`.
##
## **Ticks per frame, not a changed tick rate.** At 4x this runs four ticks
## where it would have run one; every rule still sees the same fixed tick. That
## is why a night watched at 4x and a night skipped outright end in the same
## state, and why the speed button is not part of the simulation.
##
## It is remembered in `Settings` rather than here, so it survives a restart as
## well as a night.
##
## **Set it with `set_speed()`**, which snaps it to the table and remembers it.
## It is a plain field rather than a property with a setter because a setter
## that assigns to its own property recurses until the stack runs out - which
## it duly did, and took twenty seconds of watchdog to say so.
var speed := 1

## False while paused or in a menu. A paused game banks nothing: the
## accumulator is not advanced, so five minutes paused does not fast-forward
## five minutes of farm on resume (task 0096 tests exactly that).
var running := true

## What the last frame cost, for the debug overlay of task 0012 and the
## performance budget of task 0102. Measured here because this is the only
## place that knows how many ticks a frame actually ran - and measured with a
## real clock, which is fine because this file is not a rule.
var last_ticks := 0
var last_usec := 0
var peak_usec := 0

var _accumulator := 0.0

## Seconds of hit stop left to serve.
##
## **Held, not slowed.** `TICK_HZ` is never touched and neither is
## `Engine.time_scale`: the ticks that were going to run still run, at the
## same fixed rate, a fraction of a second later. What a hold costs is real
## time, and the simulation does not measure itself in real time - which is
## why task 0088 can prove with the determinism hash that hit stop changes
## nothing at all about the game.
##
## The accumulator is deliberately **not** advanced while held, for the same
## reason pausing does not bank time: coming out of a hold and immediately
## running four ticks to catch up would undo the whole point of stopping.
var _hold := 0.0


## The remembered speed, or the one the game ships with - and, since the
## options page writes the same setting (2026-10-07), whatever it is changed
## to while a run is up.
func _take_speed() -> void:
	var settings := _settings()
	if settings != null:
		set_speed(int(settings.get_int(&"gameplay/night_speed")))
		if not settings.changed.is_connected(_on_setting):
			settings.changed.connect(_on_setting)


func _on_setting(key: StringName) -> void:
	if key != &"gameplay/night_speed":
		return
	var settings := _settings()
	if settings != null:
		set_speed(int(settings.get_int(&"gameplay/night_speed")))


## How much of a second of real time counts as a second of game.
func _slowness() -> float:
	var settings := _settings()
	if settings == null:
		return 1.0
	return A11y.nearest(float(settings.get_float(&"a11y/slow")), A11y.SLOWS)


## `Settings`, asked of the engine rather than of this node.
##
## **`get_node_or_null("/root/Settings")` errors from a node that is not in a
## tree yet**, which is every node a `SceneTree` check builds during
## `_initialize()` - and this is the one thing task 0096 has to drive by hand
## to measure what a pause does to the accumulator. The same answer at every
## point of a node's life, and no autoload named at parse time.
func _settings() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	return loop.root.get_node_or_null(^"Settings")


## Set the speed, snapped to one the table offers, and remember it.
func set_speed(value: int) -> void:
	var wanted := 1
	for offered in GameData.SPEEDS:
		if int(offered) == value:
			wanted = value
	speed = wanted
	var settings := _settings()
	if settings != null:
		settings.set_value(&"gameplay/night_speed", wanted)


## The next speed in the table, wrapping. What one button does.
func cycle_speed() -> int:
	var speeds: Array = GameData.SPEEDS
	var at := speeds.find(speed)
	set_speed(int(speeds[(at + 1) % speeds.size()]))
	return speed


## Run the rest of the night now. Returns the ticks it took, or zero when the
## rules refused - the house being too low is the only reason.
func skip_night() -> int:
	if state.is_empty():
		return 0
	var ticks := Sim.skip_night(state)
	if ticks > 0:
		ticked.emit(state)
	return ticks


func start(seed_value: int) -> void:
	state = State.create(seed_value)
	_accumulator = 0.0
	peak_usec = 0
	_take_speed()


## Carry on from a game that was already going: a save file, read back.
##
## **The accumulator starts at nothing**, the same as a new run. A resumed
## game owes no ticks: whatever real time passed between quitting and coming
## back is not time the farm spent growing.
func resume(saved: Dictionary) -> void:
	if saved.is_empty() or not saved.has("tick"):
		push_warning("SimDriver: nothing to resume")
		return
	state = saved
	_accumulator = 0.0
	peak_usec = 0
	_take_speed()


func _process(delta: float) -> void:
	if not running or state.is_empty():
		return
	if _hold > 0.0:
		_hold = maxf(_hold - delta, 0.0)
		last_ticks = 0
		last_usec = 0
		return
	# **The budget is scaled, never the rate.** `a11y/slow` says how much of
	# a second of real time counts as a second of game; the ticks that run
	# are the same ticks in the same order, there are just fewer of them a
	# second. Which is why the determinism hash cannot tell.
	var owed: Array = Sim.ticks_for(_accumulator, delta * _slowness())
	_accumulator = owed[1]
	var ticks: int = int(owed[0]) * maxi(speed, 1)
	last_ticks = ticks
	if ticks <= 0:
		last_usec = 0
		return
	var started := Time.get_ticks_usec()
	for _i in ticks:
		stepping.emit(state)
		Sim.tick(state)
		stepped.emit(state)
	last_usec = Time.get_ticks_usec() - started
	peak_usec = maxi(peak_usec, last_usec)
	ticked.emit(state)


## Stop the world for a moment. Asking again while one is running keeps the
## longer of the two rather than adding them up, so a mortar landing on six
## zombies is one held beat and not six.
func hold(seconds: float) -> void:
	_hold = maxf(_hold, seconds)


## True while the world is stopped, which is what the checks watch.
func holding() -> bool:
	return _hold > 0.0


## Microseconds per tick on the last frame, which is the number that has to
## stay inside the budget when night 10 is full of zombies.
func usec_per_tick() -> float:
	return float(last_usec) / float(last_ticks) if last_ticks > 0 else 0.0
