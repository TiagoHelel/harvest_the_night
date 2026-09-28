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


## The whole record for a night: written by a person up to `MVP_NIGHTS`, and
## written by `Endless` past it.
##
## **The seed is optional and that is deliberate.** An authored night does not
## have one, and a tool asking "what does night 25 look like" without naming a
## run is asking a reasonable question - seed 0 is as real a curve as any. The
## functions that have a state to hand pass its seed, so the night a run
## actually fights is the night that run's seed generates.
static func night_of(night: int, seed_value: int = 0) -> Dictionary:
	var nights: Array = GameData.NIGHTS
	if night < 1:
		return {}
	if night <= nights.size():
		return nights[night - 1]
	return Endless.night(seed_value, night)


## The record for the night being fought, generated once and kept.
##
## `Endless.night()` is a pure function and cheap, but not free, and
## `remaining()` is asked for it every tick by the night HUD. Generating a
## fresh one sixty times a second would be sixty wave tables a second for one
## answer - the mistake task 0067 found in `Tutorial` and task 0025 in the
## flow field. So tonight's is built when the night it belongs to arrives and
## put on the state, where it saves, loads and hashes with everything else.
static func tonight(state: Dictionary) -> Dictionary:
	var night := int(state["night"])
	if night <= (GameData.NIGHTS as Array).size():
		return night_of(night)
	var wave: Dictionary = state["wave"]
	var kept: Dictionary = wave.get("tonight", {})
	if int(kept.get("for_night", 0)) != night:
		kept = night_of(night, int(state["seed"]))
		kept["for_night"] = night
		wave["tonight"] = kept
	return kept


## The waves of a night, or an empty list when there is no such night.
static func table(night: int, seed_value: int = 0) -> Array:
	var one := night_of(night, seed_value)
	return [] if one.is_empty() else (one["waves"] as Array)


## The waves of the night being fought, off the kept record.
static func table_tonight(state: Dictionary) -> Array:
	var one := tonight(state)
	return [] if one.is_empty() else (one["waves"] as Array)


## What a night calls itself, for the summary and for task 0060's curve.
static func note_for(night: int, seed_value: int = 0) -> String:
	var one := night_of(night, seed_value)
	return "" if one.is_empty() else str(one.get("note", ""))


## How long a night waits before its `index`-th wave.
##
## **The night's own numbers, with a per-wave override.** The opening delay
## and the gap belong to the night - that is what task 0059 was for - and a
## wave that wants a different pace says so in a fourth entry rather than
## making every other row carry the number.
static func delay_before(night: int, index: int, seed_value: int = 0) -> int:
	return _delay_in(night_of(night, seed_value), index)


## The same question asked of a record already in hand, so the night being
## fought is not regenerated to find out how long the next wave waits.
static func _delay_in(one: Dictionary, index: int) -> int:
	if one.is_empty():
		return 0
	var waves: Array = one["waves"]
	if index < 0 or index >= waves.size():
		return 0
	var row: Array = waves[index]
	if row.size() > 3:
		return int(row[3])
	if index == 0:
		return int(one["opening_ticks"])
	# **`WAVE_GAP_TICKS` is the house pace**, and a night says so only when it
	# wants a different one. Task 0059 moved the gap onto the night's record
	# and wrote all ten of them out longhand, which left the global lever with
	# no reader at all: task 0068's sweep turned it from one end of its range
	# to the other and not one run of eighty changed. A lever nothing reads is
	# a promise to a designer that the code does not keep.
	return int(one.get("gap_ticks", GameData.WAVE_GAP_TICKS))


## Start a night. Called by `Phases.begin_night()`.
static func begin(state: Dictionary) -> void:
	var rows := table_tonight(state)
	var wave: Dictionary = state["wave"]
	wave["index"] = 0
	wave["left"] = 0
	wave["done"] = rows.is_empty()
	wave["wait"] = 0 if rows.is_empty() \
		else _delay_in(tonight(state), 0)


## One tick of things arriving. Called from `Sim._tick_night()`.
static func tick(state: Dictionary) -> void:
	var wave: Dictionary = state["wave"]
	if bool(wave["done"]):
		_test_for_the_end(state)
		return

	if int(wave["wait"]) > 0:
		wave["wait"] = int(wave["wait"]) - 1
		return

	var rows := table_tonight(state)
	var index := int(wave["index"])
	if index >= rows.size():
		wave["done"] = true
		return

	var row: Array = rows[index]
	if int(wave["left"]) <= 0:
		wave["left"] = int(row[1])
		# **On the first of a wave, not on every body in it.** A wave of
		# fourteen walkers is one thing arriving, and a log that said so
		# fourteen times would be a log nobody read.
		# **`enemy`, not `kind`.** `Events.add` writes the event's own kind
		# into the record, so a field called `kind` here would be quietly
		# overwritten and every wave line would name the event instead of
		# what was in it.
		Events.add(state, &"wave_began", {
			"wave": index + 1,
			"waves": rows.size(),
			"enemy": StringName(row[0]),
			"count": int(row[1]),
		})
		if StringName(row[0]) == &"giant":
			Events.add(state, &"boss_arrived", {"enemy": StringName(row[0])})

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
		wave["wait"] = _delay_in(tonight(state), index + 1)


## Everything sent, nothing left standing: the night is won.
static func _test_for_the_end(state: Dictionary) -> void:
	if Entities.count(state) > 0:
		return
	Rewards.settle(state, true)
	Phases.enter_result(state, true)


# ------------------------------------------------------------------- asking

## Which wave of how many, for the night HUD of task 0056.
static func progress(state: Dictionary) -> Array:
	var rows := table_tonight(state)
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
	var rows := table_tonight(state)
	var wave: Dictionary = state["wave"]
	var total := Entities.count(state) + int(wave["left"])
	for i in range(int(wave["index"]) + 1, rows.size()):
		total += int((rows[i] as Array)[1])
	return total


## Everything a night will send, before it sends any of it.
static func size_of(night: int, seed_value: int = 0) -> int:
	var total := 0
	for row in table(night, seed_value):
		total += int((row as Array)[1])
	return total


## What killing all of it would pay, before any of it is sent.
##
## **Computable without running the night**, which is the requirement and is
## what task 0060 needs to plot a reward curve and task 0068 to sweep one.
static func reward_of(night: int, seed_value: int = 0) -> int:
	var total := 0
	for row in table(night, seed_value):
		var kind: Variant = GameData.ENEMIES.get((row as Array)[0], null)
		if kind == null:
			continue
		total += int((kind as Dictionary)["reward"]) * int((row as Array)[1])
	return total


## How many of each kind a night sends, for the summary.
static func kinds_of(night: int, seed_value: int = 0) -> Dictionary:
	var out := {}
	for row in table(night, seed_value):
		var id: StringName = StringName((row as Array)[0])
		out[id] = int(out.get(id, 0)) + int((row as Array)[1])
	return out


## Which spawn points a night comes from, in order.
static func spawns_of(night: int, seed_value: int = 0) -> Array:
	var out: Array = []
	for row in table(night, seed_value):
		var where := int((row as Array)[2])
		if not out.has(where):
			out.append(where)
	out.sort()
	return out


## The whole of one night in one line, for `tools/nights.py` and the journal.
static func summary_of(night: int, seed_value: int = 0) -> String:
	var one := night_of(night, seed_value)
	if one.is_empty():
		return "night %d: nothing authored" % night
	var parts: Array = []
	var counts := kinds_of(night, seed_value)
	for id in GameData.sorted_names(counts.keys()):
		parts.append("%d %s" % [int(counts[id]), id])
	return ("night %2d  %2d waves  %3d enemies  $%-4d  from %s  %s"
		+ "  - %s") % [night, table(night, seed_value).size(),
			size_of(night, seed_value), reward_of(night, seed_value),
			str(spawns_of(night, seed_value)), ", ".join(parts),
			note_for(night, seed_value)]
