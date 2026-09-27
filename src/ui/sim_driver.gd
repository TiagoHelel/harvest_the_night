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


## Set the speed, snapped to one the table offers, and remember it.
func set_speed(value: int) -> void:
	var wanted := 1
	for offered in GameData.SPEEDS:
		if int(offered) == value:
			wanted = value
	speed = wanted
	# `get_node_or_null`, because `--check-only` and the headless tools run
	# with no autoloads registered and a missing setting is not a crash.
	var settings := get_node_or_null("/root/Settings")
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
	var settings := get_node_or_null("/root/Settings")
	if settings != null:
		set_speed(int(settings.get_int(&"gameplay/night_speed")))


func _process(delta: float) -> void:
	if not running or state.is_empty():
		return
	var owed: Array = Sim.ticks_for(_accumulator, delta)
	_accumulator = owed[1]
	var ticks: int = int(owed[0]) * maxi(speed, 1)
	last_ticks = ticks
	if ticks <= 0:
		last_usec = 0
		return
	var started := Time.get_ticks_usec()
	Sim.advance(state, ticks)
	last_usec = Time.get_ticks_usec() - started
	peak_usec = maxi(peak_usec, last_usec)
	ticked.emit(state)


## Microseconds per tick on the last frame, which is the number that has to
## stay inside the budget when night 10 is full of zombies.
func usec_per_tick() -> float:
	return float(last_usec) / float(last_ticks) if last_ticks > 0 else 0.0
