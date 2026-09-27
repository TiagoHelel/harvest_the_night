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

## Ticks run per real tick owed. 1, 2 or 4 - the speed buttons of task 0055.
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


func start(seed_value: int) -> void:
	state = State.create(seed_value)
	_accumulator = 0.0
	peak_usec = 0


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
