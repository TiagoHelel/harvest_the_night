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

const DIR := "res://tools/goldens/"

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
	quit(0)


## A run somebody has actually played: sown, built on, and one night older.
func _a_played_farm() -> Dictionary:
	var state := State.create(SEED)
	Resources.gain(state, {GameData.WOOD: 400, GameData.STONE: 400,
		GameData.IRON: 200, GameData.MONEY: 300})

	var sown := 0
	var seeds := Farming.seeds()
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		if sown >= 14:
			break
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, found)
		Farming.act(state, found)
		sown += 1

	var built := 0
	for y in range(4, Grid.HEIGHT - 2):
		for x in range(22, Grid.WIDTH - 2):
			if built >= 6:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				built += 1
	for y in range(3, 12):
		Building.place(state, &"wall", Vector2i(20, y))

	Sim.advance(state, TICKS)

	# **And a night, because a run that has never been at night is half a
	# run.** The wave counter, the events and what the night did to the
	# fences are all state a reconcile must not touch.
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
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
