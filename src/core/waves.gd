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
## The whole record for a night, or an empty Dictionary past the last one.
static func night_of(night: int) -> Dictionary:
	var nights: Array = GameData.NIGHTS
	if night < 1 or night > nights.size():
		return {}
	return nights[night - 1]


## The waves of a night, or an empty list past the last authored one.
static func table(night: int) -> Array:
	var one := night_of(night)
	return [] if one.is_empty() else (one["waves"] as Array)


## What a night calls itself, for the summary and for task 0060's curve.
static func note_for(night: int) -> String:
	var one := night_of(night)
	return "" if one.is_empty() else str(one.get("note", ""))


## How long a night waits before its `index`-th wave.
##
## **The night's own numbers, with a per-wave override.** The opening delay
## and the gap belong to the night - that is what task 0059 was for - and a
## wave that wants a different pace says so in a fourth entry rather than
## making every other row carry the number.
static func delay_before(night: int, index: int) -> int:
	var one := night_of(night)
	if one.is_empty():
		return 0
	var waves: Array = one["waves"]
	if index < 0 or index >= waves.size():
		return 0
	var row: Array = waves[index]
	if row.size() > 3:
		return int(row[3])
	return int(one["opening_ticks"]) if index == 0 \
		else int(one["gap_ticks"])


## Start a night. Called by `Phases.begin_night()`.
static func begin(state: Dictionary) -> void:
	var rows := table(int(state["night"]))
	var wave: Dictionary = state["wave"]
	wave["index"] = 0
	wave["left"] = 0
	wave["done"] = rows.is_empty()
	wave["wait"] = 0 if rows.is_empty() \
		else delay_before(int(state["night"]), 0)


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
		wave["wait"] = delay_before(int(state["night"]), index + 1)


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


## Everything a night will send, before it sends any of it.
static func size_of(night: int) -> int:
	var total := 0
	for row in table(night):
		total += int((row as Array)[1])
	return total


## What killing all of it would pay, before any of it is sent.
##
## **Computable without running the night**, which is the requirement and is
## what task 0060 needs to plot a reward curve and task 0068 to sweep one.
static func reward_of(night: int) -> int:
	var total := 0
	for row in table(night):
		var kind: Variant = GameData.ENEMIES.get((row as Array)[0], null)
		if kind == null:
			continue
		total += int((kind as Dictionary)["reward"]) * int((row as Array)[1])
	return total


## How many of each kind a night sends, for the summary.
static func kinds_of(night: int) -> Dictionary:
	var out := {}
	for row in table(night):
		var id: StringName = StringName((row as Array)[0])
		out[id] = int(out.get(id, 0)) + int((row as Array)[1])
	return out


## Which spawn points a night comes from, in order.
static func spawns_of(night: int) -> Array:
	var out: Array = []
	for row in table(night):
		var where := int((row as Array)[2])
		if not out.has(where):
			out.append(where)
	out.sort()
	return out


## The whole of one night in one line, for `tools/nights.py` and the journal.
static func summary_of(night: int) -> String:
	var one := night_of(night)
	if one.is_empty():
		return "night %d: nothing authored" % night
	var parts: Array = []
	var counts := kinds_of(night)
	for id in GameData.sorted_names(counts.keys()):
		parts.append("%d %s" % [int(counts[id]), id])
	return ("night %2d  %2d waves  %3d enemies  $%-4d  from %s  %s"
		+ "  - %s") % [night, table(night).size(), size_of(night),
			reward_of(night), str(spawns_of(night)), ", ".join(parts),
			note_for(night)]
