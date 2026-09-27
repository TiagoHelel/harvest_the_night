class_name Waves
extends RefCounted

## What comes, in what order, and when the night is over.
##
## A night is a row of `GameData.NIGHTS`; a wave is
## `[enemy, count, spawn point, ticks to wait first]`. Nothing about which
## night is which lives here - task 0060 writes ten of them and this file does
## not change.
##
## ## They arrive one at a time
##
## A wave's count trickles in at `GameData.SPAWN_INTERVAL_TICKS` rather than
## appearing at once. Eight zombies materialising on one tick is a magic trick;
## eight walking out of the dark in a line is a wave, and it gives the towers
## something to do while the player watches.
##
## ## The night ends twice over
##
## Everything has been sent **and** nothing is left alive: that is the win. The
## house falling is the other ending, and `Enemies` owns it because that is
## where the last bite happens.


static func initial() -> Dictionary:
	return {
		"wave": {
			# Which wave of the night is being sent, and what is left of it.
			"index": 0,
			"left": 0,
			# Ticks until the next thing happens - the gap before a wave, or
			# the space between two of its members.
			"wait": 0,
			"done": false,
		},
	}


## The night's table, or an empty list past the last authored one.
static func table(night: int) -> Array:
	var nights: Array = GameData.NIGHTS
	if night < 1 or night > nights.size():
		return []
	return nights[night - 1]


## Start a night. Called by `Phases.begin_night()`.
static func begin(state: Dictionary) -> void:
	var rows := table(int(state["night"]))
	var wave: Dictionary = state["wave"]
	wave["index"] = 0
	wave["left"] = 0
	wave["done"] = rows.is_empty()
	wave["wait"] = 0 if rows.is_empty() else int((rows[0] as Array)[3])


## One tick of things arriving. Called from `Sim._tick_night()`.
static func tick(state: Dictionary) -> void:
	var wave: Dictionary = state["wave"]
	if bool(wave["done"]):
		_test_for_the_end(state)
		return

	if int(wave["wait"]) > 0:
		wave["wait"] = int(wave["wait"]) - 1
		return

	var rows := table(int(state["night"]))
	var index := int(wave["index"])
	if index >= rows.size():
		wave["done"] = true
		return

	var row: Array = rows[index]
	if int(wave["left"]) <= 0:
		wave["left"] = int(row[1])

	Enemies.spawn(state, StringName(row[0]), int(row[2]))
	wave["left"] = int(wave["left"]) - 1

	if int(wave["left"]) > 0:
		wave["wait"] = GameData.SPAWN_INTERVAL_TICKS
		return

	# That wave is all out. Move to the next one and wait its gap.
	wave["index"] = index + 1
	if index + 1 >= rows.size():
		wave["done"] = true
		wave["wait"] = 0
	else:
		wave["wait"] = int((rows[index + 1] as Array)[3])


## Everything sent, nothing left standing: the night is won.
static func _test_for_the_end(state: Dictionary) -> void:
	if Entities.count(state) > 0:
		return
	Rewards.settle(state, true)
	Phases.enter_result(state, true)


# ------------------------------------------------------------------- asking

## Which wave of how many, for the night HUD of task 0056.
static func progress(state: Dictionary) -> Array:
	var rows := table(int(state["night"]))
	var wave: Dictionary = state["wave"]
	var at := mini(int(wave["index"]) + 1, rows.size())
	return [at, rows.size()]


## Ticks until the next wave starts, or zero when one is already coming in or
## the night is done sending.
##
## **The gap before a wave, not the space between two of its members.** The
## same field carries both, so the difference is whether anything is still
## waiting to be sent out of the current one.
static func incoming_in(state: Dictionary) -> int:
	var wave: Dictionary = state["wave"]
	if bool(wave["done"]) or int(wave["left"]) > 0:
		return 0
	return maxi(int(wave["wait"]), 0)


## How many are still to come tonight, counting what is already out there.
static func remaining(state: Dictionary) -> int:
	var rows := table(int(state["night"]))
	var wave: Dictionary = state["wave"]
	var total := Entities.count(state) + int(wave["left"])
	for i in range(int(wave["index"]) + 1, rows.size()):
		total += int((rows[i] as Array)[1])
	return total


## Everything a night will send, before it sends any of it. What task 0059
## needs to print a summary without running one.
static func size_of(night: int) -> int:
	var total := 0
	for row in table(night):
		total += int((row as Array)[1])
	return total
