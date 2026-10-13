class_name Waves
extends RefCounted

## What comes, in what order, and when the night is over.
##
## A night is a record - a key night of `GameData.KEY_NIGHTS`, one `Almanac`
## makes from its season's template, or `Endless`'s past the year - and a wave
## is `[enemy, count, spawn point, ticks to wait first]`. Nothing about which
## night is which lives here: the year is data (task 0270) and this file does
## not change for it.
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
			# **The night tick dawn falls on** (task 0137), written by
			# `begin()`. A whole night for a save from before it.
			"dawn_at": GameData.NIGHT_TICKS,
		},
	}


## **The record as written** - where the year comes from (task 0270): a
## day's key night, else the one `Almanac` makes from its season's template,
## for the year's days; the `Endless` curve past them until 0279. Empty for a
## calm date of the year, which has no record of its own (`night_of` answers
## it). The calendar's rules (0152-0154) go on top in `night_of`, never here.
##
## **The seed is optional and that is deliberate.** A key night does not have
## one, and a tool asking "what does day 25 look like" without naming a run
## is asking a reasonable question - seed 0 is as real a year as any. The
## functions that have a state to hand pass its seed, so the night a run
## actually fights is the night that run's seed makes.
static func plain_night(night: int, seed_value: int = 0) -> Dictionary:
	if night < 1:
		return {}
	if night <= Calendar.year_days():
		return Almanac.night(seed_value, night)
	return Endless.night(seed_value, night)


## **The record a night actually fights** (task 0150): `plain_night` with
## the calendar's rules on top. Every pure question below asks this one.
##
## The rules, each added here and nowhere else:
## - **the boss** (task 0153): the season's boss on its last night, and no
##   boss on any other - today's night ten loses its Giant, and `Endless`'s
##   every-fifth-night Giants stop reaching the calendar;
## - **the Full Moon** (task 0152): a bigger horde on `FULL_MOON_DAYS`, over
##   the boss rule, leaving the boss row as it is;
## - **the calm night** (task 0154): the first night of every season but the
##   game's first sends nothing at all, whatever was written for it.
##
## A night no rule touches comes back as written - the key night itself,
## not a copy. **The calm night is asked first** (task 0270): its date has
## no record to start from.
static func night_of(night: int, seed_value: int = 0) -> Dictionary:
	if night >= 1 and Calendar.is_calm(night):
		return _calm()
	var plain := plain_night(night, seed_value)
	if plain.is_empty():
		return plain
	var one := plain
	if Calendar.is_boss_night(night):
		one = _with_the_season_boss(plain, Calendar.boss_of(night))
	elif _has_a_boss(plain):
		one = _without_bosses(plain)
	if Calendar.is_full_moon(night):
		one = _under_a_full_moon(one)
	return one


## Whether a night is anything but its record as written: what
## `tonight()` keeps rather than asks again every frame.
static func _ruled(night: int, seed_value: int) -> bool:
	return Calendar.is_full_moon(night) or Calendar.is_boss_night(night) \
		or Calendar.is_calm(night) or _has_a_boss(plain_night(night, seed_value))


## **The calm night's record** (task 0154): no waves, and the flag that says
## it means it - `check_nights` refuses an empty list anywhere else, and the
## forecast (0158) reads it. The night still happens: the build step opens,
## START starts it, and `begin()`'s empty table wins it on its first tick.
static func _calm() -> Dictionary:
	return {
		"note": "a calm night: the horde regroups after its boss",
		"opening_ticks": 0,
		"waves": [],
		"calm": true,
	}


static func _has_a_boss(one: Dictionary) -> bool:
	for row in _rows_in(one):
		if _is_boss(StringName((row as Array)[0])):
			return true
	return false


static func _is_boss(kind: StringName) -> bool:
	return bool((GameData.ENEMIES.get(kind, {}) as Dictionary).get("is_boss", false))


## **The season's boss night** (task 0153): the night as written with any
## boss of its own taken out and one row of the season's boss put in, third
## from last - where `Endless` put its Giants - from spawn 0, the east,
## which every season keeps open (0157). It carries `"boss"`, which the
## forecast (0158) reads.
static func _with_the_season_boss(plain: Dictionary, boss: StringName) -> Dictionary:
	var one := _without_bosses(plain)
	if boss == &"":
		return one
	var rows: Array = one["waves"]
	rows.insert(maxi(rows.size() - 2, 0), [boss, 1, 0])
	one["boss"] = boss
	one["note"] = "%s - and %s, the season's boss" % [str(plain.get("note", "")), boss]
	return one


## A night with its boss rows taken out, for every date that is not a boss
## night: the boss comes on the season's last night and on no other.
static func _without_bosses(plain: Dictionary) -> Dictionary:
	var one := plain.duplicate(true)
	var kept: Array = []
	var dropped := false
	for row in (one["waves"] as Array):
		if _is_boss(StringName((row as Array)[0])):
			dropped = true
		else:
			kept.append(row)
	one["waves"] = kept
	if dropped:
		one["note"] = "%s (its boss kept for the season's last night)" \
			% str(plain.get("note", ""))
	return one


## **Whether tonight's boss went down** (task 0153): every `is_boss` body
## tonight's record sends has been killed, read off `killed_by_kind`. True
## on a night with no boss in it.
static func boss_fell(state: Dictionary) -> bool:
	var killed: Dictionary = state.get("killed_by_kind", {})
	var sent := {}
	for row in table_tonight(state):
		var kind := StringName((row as Array)[0])
		if _is_boss(kind):
			sent[kind] = int(sent.get(kind, 0)) + int((row as Array)[1])
	for kind in GameData.sorted_names(sent.keys()):
		if int(killed.get(kind, 0)) < int(sent[kind]):
			return false
	return true


## **A Full Moon's record** (task 0152): every ordinary wave sends
## `FULL_MOON_HORDE_PERCENT` of its count - integer arithmetic, never fewer
## than written - and a boss row is left alone. It carries `"full_moon"`,
## which the forecast (0158) reads. No RNG: the same night is the same Full
## Moon on every seed it was written for.
static func _under_a_full_moon(plain: Dictionary) -> Dictionary:
	var one := plain.duplicate(true)
	for row in (one["waves"] as Array):
		var wave: Array = row
		if _is_boss(StringName(wave[0])):
			continue
		wave[1] = maxi(int(wave[1]) * GameData.FULL_MOON_HORDE_PERCENT / 100,
			int(wave[1]))
	one["full_moon"] = true
	_fit_inside_the_night(one)
	return one


## **A bigger horde still fits the night** (0137): when the scaled record
## would be sending within `DAWN_MARGIN_TICKS` of dawn, it tightens its own
## pace - the gaps between its waves first, a quarter at a time, then the
## spacing of their members as `Endless` does. Never the check.
static func _fit_inside_the_night(one: Dictionary) -> void:
	var budget := GameData.NIGHT_TICKS - GameData.DAWN_MARGIN_TICKS
	for _step in 32:
		if schedule_ticks(one) <= budget:
			return
		one["gap_ticks"] = int(one.get("gap_ticks", GameData.WAVE_GAP_TICKS)) * 3 / 4
		for row in (one["waves"] as Array):
			if (row as Array).size() > 3:
				(row as Array)[3] = int((row as Array)[3]) * 3 / 4
	Endless._fit_before_dawn(one)


## The record for the night being fought, generated once and kept.
##
## A made night (`Almanac`, `Endless`) is a pure function and cheap, but not
## free, and `remaining()` is asked for it every tick by the night HUD.
## Making a fresh one sixty times a second would be sixty wave tables a
## second for one answer - the mistake task 0067 found in `Tutorial` and task
## 0025 in the flow field. So tonight's is built when the night it belongs to
## arrives and put on the state, where it saves, loads and hashes with
## everything else.
##
## **A record a calendar rule changed is kept the same way** (task 0152), and
## only that one: a key night no rule touches is still the record itself,
## so day 1 puts nothing new in its state.
static func tonight(state: Dictionary) -> Dictionary:
	var night := int(state["night"])
	if Almanac.is_key(night) and not _ruled(night, int(state["seed"])):
		return night_of(night, int(state["seed"]))
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


## **How long a night takes to send everything** (task 0137): ticks from the
## night's first to the tick its last member is sent, counted exactly as
## `tick()` spends them - a wave's delay, then a release every
## `SPAWN_INTERVAL_TICKS` + 1: a body, or a cluster of a kind that comes
## several at once (task 0248). What `check_nights` holds inside the night.
static func schedule_ticks(one: Dictionary) -> int:
	if one.is_empty():
		return 0
	var rows: Array = one["waves"]
	var ticks := 0
	for i in rows.size():
		ticks += _delay_in(one, i) + 1
		ticks += (releases_of(rows[i] as Array) - 1) * (interval_in(one) + 1)
	return ticks


## **The fill line** (task 0271, after 0148): the night's tick a night's last
## send comes no sooner than - `NIGHT_FILL_TICKS` before the dawn margin - so
## a night is still coming when it passes, not over a minute in.
## `schedule_ticks` is held between it and the margin.
static func fill_line() -> int:
	return GameData.NIGHT_TICKS - GameData.DAWN_MARGIN_TICKS - GameData.NIGHT_FILL_TICKS


## **How many come out at once** of a kind (task 0248): its `cluster`, one
## for every kind that does not say.
static func cluster_of(kind: StringName) -> int:
	return maxi(int((GameData.ENEMIES.get(kind, {}) as Dictionary).get("cluster", 1)), 1)


## How many releases a wave row takes: its bodies, a cluster at a time.
static func releases_of(row: Array) -> int:
	var each := cluster_of(StringName(row[0]))
	return (int(row[1]) + each - 1) / each


## The ticks between two members of a wave: the house pace, or a night's own
## (`interval_ticks`) - which a generated night sets so it fits before dawn.
static func interval_in(one: Dictionary) -> int:
	return int(one.get("interval_ticks", GameData.SPAWN_INTERVAL_TICKS))


## Start a night. Called by `Phases.begin_night()`.
static func begin(state: Dictionary) -> void:
	var rows := table_tonight(state)
	var wave: Dictionary = state["wave"]
	wave["index"] = 0
	wave["left"] = 0
	wave["done"] = rows.is_empty()
	wave["wait"] = 0 if rows.is_empty() \
		else _delay_in(tonight(state), 0)
	# Dawn, counted on `night_tick` from this night's first.
	wave["dawn_at"] = GameData.NIGHT_TICKS


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
		# Any boss, by what it is rather than by name (task 0153).
		if _is_boss(StringName(row[0])):
			Events.add(state, &"boss_arrived", {"enemy": StringName(row[0])})

	# **A cluster at a time** (task 0248): a kind that comes `cluster` at once
	# sends that many on this tick, round the first, and the wave counts them
	# all - so what is left and what the forecast promised stay bodies.
	var sent := mini(cluster_of(StringName(row[0])), int(wave["left"]))
	Enemies.spawn_cluster(state, StringName(row[0]), int(row[2]), sent)
	wave["left"] = int(wave["left"]) - sent

	if int(wave["left"]) > 0:
		wave["wait"] = interval_in(tonight(state))
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
	return size_in(night_of(night, seed_value))


## The same count off a record already in hand: `Endless` sizes its curve
## from Spring 14's key night as written, never as the calendar changes it.
static func size_in(one: Dictionary) -> int:
	var total := 0
	for row in _rows_in(one):
		total += int((row as Array)[1])
	return total


## **What a record has to kill**, in hit points as written (task 0270): the
## honest measure of a night's size, since three tanks are not three walkers -
## what 0060 authored by and `SEASON_NIGHTS` sizes its templates in.
static func hit_points_in(one: Dictionary) -> int:
	var total := 0
	for row in _rows_in(one):
		var kind: Variant = GameData.ENEMIES.get((row as Array)[0], null)
		if kind != null:
			total += int((kind as Dictionary)["hp"]) * int((row as Array)[1])
	return total


## A record's waves, or none for an empty record.
static func _rows_in(one: Dictionary) -> Array:
	return [] if one.is_empty() else (one["waves"] as Array)


## What killing all of it would pay, before any of it is sent.
##
## **Computable without running the night**, which is the requirement and is
## what task 0060 needs to plot a reward curve and task 0068 to sweep one.
static func reward_of(night: int, seed_value: int = 0) -> int:
	return reward_in(night_of(night, seed_value))


## The purse off a record already in hand (task 0150), so the authored
## curve's tests can weigh a night as written.
static func reward_in(one: Dictionary) -> int:
	var total := 0
	for row in _rows_in(one):
		var kind: Variant = GameData.ENEMIES.get((row as Array)[0], null)
		if kind == null:
			continue
		total += int((kind as Dictionary)["reward"]) * int((row as Array)[1])
	return total


## How many of each kind a night sends, for the summary.
static func kinds_of(night: int, seed_value: int = 0) -> Dictionary:
	return kinds_in(night_of(night, seed_value))


## The same tally off a record already in hand.
static func kinds_in(one: Dictionary) -> Dictionary:
	var out := {}
	for row in _rows_in(one):
		var id: StringName = StringName((row as Array)[0])
		out[id] = int(out.get(id, 0)) + int((row as Array)[1])
	return out


## Which spawn points a night comes from, in order.
static func spawns_of(night: int, seed_value: int = 0) -> Array:
	return spawns_in(night_of(night, seed_value))


## The same sides off a record already in hand.
static func spawns_in(one: Dictionary) -> Array:
	var out: Array = []
	for row in _rows_in(one):
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
	if bool(one.get("calm", false)):
		return "night %2d  calm  - %s" % [night, str(one.get("note", ""))]
	var parts: Array = []
	var counts := kinds_of(night, seed_value)
	for id in GameData.sorted_names(counts.keys()):
		parts.append("%d %s" % [int(counts[id]), id])
	return ("night %2d  %2d waves  %3d enemies  $%-4d  from %s  %s"
		+ "  - %s") % [night, table(night, seed_value).size(),
			size_of(night, seed_value), reward_of(night, seed_value),
			str(spawns_of(night, seed_value)), ", ".join(parts),
			note_for(night, seed_value)]
