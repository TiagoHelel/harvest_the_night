extends SceneTree

## Write the golden saves, and refuse to overwrite one.
##
##     godot --headless --script res://src/tools/make_goldens.gd
##
## ## A golden is only worth anything because nobody regenerated it
##
## The point of a file in `tools/goldens/` is that it was written by a build
## that is not this one, and every run of this script makes that less true.
## So it **never overwrites**: a golden that exists is left exactly as it is,
## and the only thing this can do is add one that is missing. When
## `State.VERSION` moves to 2, somebody runs this once on the last build that
## still said 1, checks in `run-v1.sav`, and never touches it again.
##
## ## Two of them are shapes rather than builds, and say so
##
## `run-v1.sav` is a real save, written by this build, of a run that has been
## played for a while. The other two are that same run with keys taken out
## and keys put in - they stand for a build that predates something and a
## build that has since dropped something. No such build ever existed, which
## is exactly why they have to be made rather than found: the shapes they
## test are the ones the next four years will actually produce, and waiting
## for a real one means the machinery is unexercised until the day it matters.
##
## ## And three are the 0.1 prototype's, declared (task 0291)
##
## `run-v4.sav` is the real 0.1 golden: written by the MVP commit `bea89a88`
## (state 4, BuildInfo 0.1.0) at task 0151. A player who played the prototype
## to its end, or past it, had a run of that shape further on - so two more
## are made from its raw payload, read underneath `Save.read_run_at` with no
## migration and no reconcile, its counters moved the way the MVP moved them
## (`Phases.enter_result` then: a day every night, `nights_won` and the tech
## point's `nights_paid` on a win, the Giant on night ten):
## - `run-v4-endless.sav`: **carried on past night ten** - eleven nights won
##   after the golden's one loss, the Giant down, `endless` true, in DAY on
##   day 13 with the night's last body gone;
## - `run-v4-finished.sav`: **the prototype won** - ten nights won, the Giant
##   down, `endless` false, in RESULT on day 12 with the report that says
##   `run_over`.
##
## And `profile-v1.sav`, a 0.1 profile as `Run.record` and `Stats.fold` left
## one: the four keys the prototype had (`runs_started`, `runs_won`,
## `best_night`, `stats`) and its `unlocks`, nothing 1.0 added.

const DIR := "res://tools/goldens/"

## The real 0.1 golden the declared 0.1 shapes are made from (task 0291).
const V4_GOLDEN := "res://tools/goldens/run-v4.sav"

## The MVP's phases, as `bea89a88` numbered them: DAY 0, RESULT 3.
const V4_DAY := 0
const V4_RESULT := 3

## The MVP's house, `GameData.HOUSE_HP` at `bea89a88`.
const V4_HOUSE_HP := 100

## The run every golden is made from. Written down like every other seed here.
const SEED := 104104

## How far it is played before it is saved.
##
## **A farm, not a lawn.** The first version of this advanced the clock 5400
## ticks and saved the result: day one, nothing built, a hundred and six
## occupants - which is the starting farm, and a golden of a fresh game
## passes every check while proving nothing. The run below is sown, built on
## and taken through a night, so the keys the reconcile has to leave alone
## have something in them.
const TICKS := 600

## What a build that predates this one would not have written.
##
## `events` arrived at task 0090, `tutorial` at 0101, oil is a resource and
## `flares` a field on an existing structure. Between them they cover every
## shape of addition there is: a new top-level key, a new row in a table
## keyed by `GameData`, and a new field on a structure.
const DROPPED_TOP: Array = ["events", "tutorial"]
const DROPPED_IN: Array = [["held", "oil"], ["gained", "oil"],
	["ability", "flares"]]

## And what a build that has since dropped something would have left behind.
const ADDED_TOP := "moon_phase"
const ADDED_IN: Array = [["held", "unobtainium"]]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(DIR))

	var state := _a_played_farm()
	print("a run at tick %d, day %d, night %d won, %d things standing,"
		% [int(state["tick"]), int(state["day"]),
			int(state["nights_won"]), (state["occupants"] as Dictionary).size()]
		+ " %d sown, %d wood" % [int(Farming.counts(state)["planted"]),
			int(Resources.amount(state, GameData.WOOD))])

	_write("run-v%d.sav" % State.VERSION, state)
	_write("run-v%d-older.sav" % State.VERSION, _as_older(state))
	_write("run-v%d-newer.sav" % State.VERSION, _as_newer(state))

	# **The 0.1 shapes** (task 0291), from the real 0.1 golden's payload.
	var v4 := _raw_state_of(V4_GOLDEN)
	if v4.is_empty() or int(v4.get("version", 0)) != 4:
		print("  FAILED   %s is not a state 4 run - no 0.1 shapes" % V4_GOLDEN)
	else:
		_write("run-v4-endless.sav", _v4_carried_on(v4))
		_write("run-v4-finished.sav", _v4_won(v4))
	_write_profile("profile-v1.sav", _a_0_1_profile())
	quit(0)


## A run somebody has actually played: sown, built on, and one night older.
func _a_played_farm() -> Dictionary:
	var state := State.create(SEED)
	Resources.gain(state, {GameData.WOOD: 400, GameData.STONE: 400,
		GameData.IRON: 200, GameData.MONEY: 300})

	var sown := 0
	var seeds := Farming.seeds()
	for found in Farming.field_cells(state):
		if sown >= 14:
			break
		SuiteKit.crop_supplies(state, StringName(seeds[sown % seeds.size()]))
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, found)
		Farming.act(state, found)
		sown += 1

	# **A day farm with its defence standing**, which went up in last night's
	# build step: 0132 forbids defences by day (task 0119).
	SuiteKit.built_last_night(state, func() -> void:
		var built := 0
		for y in range(4, Grid.HEIGHT - 2):
			for x in range(22, Grid.WIDTH - 2):
				if built >= 6:
					break
				if Building.place(state, &"gun_tower", Vector2i(x, y)):
					built += 1
		for y in range(3, 12):
			Building.place(state, &"wall", Vector2i(20, y)))

	SuiteKit.watered_mornings(state, 2)
	for plot in state["plots"].values():
		plot["watered"] = true
	Sim.advance(state, TICKS)

	# **And a night, because a run that has never been at night is half a
	# run.** The wave counter, the events and what the night did to the
	# fences are all state a reconcile must not touch.
	NightRoad.to_night(state)
	for _i in 200:
		Sim.advance(state, 30)
		if int(state["phase"]) != Phases.NIGHT:
			break
	Sim.advance(state, 120)
	return state


func _write(name: String, state: Dictionary) -> void:
	var path := DIR + name
	if FileAccess.file_exists(path):
		print("  kept     %s - a golden is not regenerated" % name)
		return
	if Save.write_run_at(path, state):
		print("  written  %s" % name)
	else:
		print("  FAILED   %s" % name)


## The same run as a build that predates four things would have written it.
func _as_older(state: Dictionary) -> Dictionary:
	var older: Dictionary = state.duplicate(true)
	for key in DROPPED_TOP:
		older.erase(key)
	for pair in DROPPED_IN:
		var inner: Dictionary = older[pair[0]]
		inner.erase(pair[1])
	return older


## And as a build with two things in it that this one has never heard of.
func _as_newer(state: Dictionary) -> Dictionary:
	var newer: Dictionary = state.duplicate(true)
	newer[ADDED_TOP] = 3
	for pair in ADDED_IN:
		var inner: Dictionary = newer[pair[0]]
		inner[pair[1]] = 7
	return newer


## A save's state with nothing done to it - no migration, no reconcile - as
## `headless_check`'s `_payload_of` reads one.
func _raw_state_of(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_bytes(path)
	if raw.size() < 16:
		return {}
	var value: Variant = bytes_to_var(raw.slice(16))
	if not value is Dictionary:
		return {}
	return ((value as Dictionary).get("state", {}) as Dictionary).duplicate(true)


## The 0.1 run `wins` more nights on from the golden, as the MVP counted
## them: a day each, `nights_won` and `nights_paid` on each win, the Giant
## down on night ten - his kill in the run's tallies too.
func _v4_winning_on(v4: Dictionary, wins: int) -> Dictionary:
	var state := v4.duplicate(true)
	var won := int(state["nights_won"])
	var paid: Array = state["nights_paid"]
	for _night in wins:
		won += 1
		state["day"] = int(state["day"]) + 1
		paid.append(won)
	state["nights_won"] = won
	state["night"] = won
	state["bosses_down"] = 1
	state["killed_all_run"] = int(state.get("killed_all_run", 0)) + 1
	var ever: Dictionary = state["killed_by_kind_all_run"]
	ever[&"giant"] = int(ever.get(&"giant", 0)) + 1
	# **A won night ends with nobody left** and the house standing.
	state["entities"] = {}
	state["house_hp"] = V4_HOUSE_HP
	state["last_result"] = {"night": won, "survived": true,
		"ticks": int((v4["last_result"] as Dictionary).get("ticks", 0))}
	return state


## Carried on past night ten: eleven won, `endless`, the morning after.
func _v4_carried_on(v4: Dictionary) -> Dictionary:
	var state := _v4_winning_on(v4, 11)
	state["endless"] = true
	state["phase"] = V4_DAY
	state["phase_tick"] = 0
	state["day_tick"] = 0
	return state


## The prototype won: night ten's report, which ends the run.
func _v4_won(v4: Dictionary) -> Dictionary:
	var state := _v4_winning_on(v4, 10)
	state["endless"] = false
	state["phase"] = V4_RESULT
	(state["last_result"] as Dictionary)["run_over"] = true
	return state


## A 0.1 profile: three runs started, the prototype won once, ten nights won
## in one run, and the lifetime tallies `Stats.fold` kept then - the haul's
## one `fish` among them, as the prototype had it.
func _a_0_1_profile() -> Dictionary:
	return {
		"version": 1,
		"runs_started": 3,
		"runs_won": 1,
		"best_night": 10,
		"unlocks": [],
		"stats": {
			"lifetime": {
				"nights": 17,
				"killed": 1240,
				"built": 96,
				"lost": 14,
				"killed_by_kind": {&"walker": 610, &"runner": 380, &"tank": 140,
					&"breaker": 109, &"giant": 1},
				"built_by_kind": {&"gun_tower": 22, &"wall": 64, &"mine": 10},
				"gathered": {&"wood": 2100, &"stone": 900, &"iron": 260,
					&"carrot": 140, &"fish": 9},
			},
			"last_run": {"days": 12, "nights_won": 10, "killed": 702,
				"bosses": 1, "structures_lost": 6},
		},
	}


func _write_profile(name: String, profile: Dictionary) -> void:
	var path := DIR + name
	if FileAccess.file_exists(path):
		print("  kept     %s - a golden is not regenerated" % name)
		return
	if Save.write_profile_at(path, profile):
		print("  written  %s" % name)
	else:
		print("  FAILED   %s" % name)
