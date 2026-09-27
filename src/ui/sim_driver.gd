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

var _accumulator := 0.0


func start(seed_value: int) -> void:
	state = State.create(seed_value)
	_accumulator = 0.0


func _process(delta: float) -> void:
	if not running or state.is_empty():
		return
	var owed: Array = Sim.ticks_for(_accumulator, delta)
	_accumulator = owed[1]
	var ticks: int = int(owed[0]) * maxi(speed, 1)
	if ticks <= 0:
		return
	Sim.advance(state, ticks)
	ticked.emit(state)
