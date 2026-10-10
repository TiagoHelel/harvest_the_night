class_name Stats
extends RefCounted

## What the player did: this run, and every run.
##
## `design.md` wants a number that goes up as its own reason to play another
## night, and the cheapest honest version of that is a tally nobody has to
## trust - counted where the thing happens, kept where it survives.
##
## ## It reads; it does not keep a second ledger
##
## Almost every number below is already on the state. `Combat` counts the
## kills and counts them by kind, `Resources` counts the haul in `gained`,
## `Run` counts the rubble, `Phases` counts the nights won. `of_run()` reads
## those. A statistics module that counted them again would be a second
## opinion about the same facts, and the two would disagree the first time
## somebody changed one of them.
##
## The **one** tally this file adds is how many things the player put up.
## `Building` already counts `placed_tonight`, but it clears that every
## morning - it exists to cap barricades - so there was nothing that knew how
## many walls a run had built.
##
## ## Banked, so that a crash costs nothing
##
## The lifetime totals live in the profile, and the requirement is that they
## are "written with the profile, not at the end of a run" - a player who
## crashes on night nine should not lose nine nights of statistics.
##
## So `fold()` can be called as often as the game likes. The state remembers
## what has already gone into the profile under `stats.banked`, and each fold
## adds only the difference. Folding the same run twice in a row adds nothing
## the second time, which is what makes it safe to call from an autosave.


## The per-run keys this file owns. Everything else it reports is read from
## the module that already counts it.
static func initial() -> Dictionary:
	return {
		"stats": {
			# How many things the player has put up this run, and of what.
			"built": 0,
			"built_by_kind": {},
			# What of the above has already been added to the profile's
			# lifetime totals. See the note on banking at the top.
			"banked": {},
		},
	}


# ------------------------------------------------------------------- counting

## One more thing went up. Called from `Building.place()`, on the line that
## already counts tonight's barricades, for the reason `Combat._kill()` gives:
## one place, so that everything hanging off it agrees.
static func built(state: Dictionary, id: StringName) -> void:
	var mine: Dictionary = state["stats"]
	mine["built"] = int(mine.get("built", 0)) + 1
	var by_kind: Dictionary = mine["built_by_kind"]
	by_kind[id] = int(by_kind.get(id, 0)) + 1


# -------------------------------------------------------------------- reading

## This run, as a record. Every line is a lookup somewhere else.
##
## `nights` is nights **survived** rather than nights reached: losing one
## costs a day and not the run (task 0065), so a player can have seen night
## five three times and survived four.
static func of_run(state: Dictionary) -> Dictionary:
	var mine: Dictionary = state.get("stats", {})
	return {
		"nights": Phases.nights_won(state),
		"best_night": Phases.nights_won(state),
		"killed": int(state.get("killed_all_run", 0)),
		"killed_by_kind":
			(state.get("killed_by_kind_all_run", {}) as Dictionary).duplicate(),
		"gathered": _haul(state),
		"built": int(mine.get("built", 0)),
		"built_by_kind": (mine.get("built_by_kind", {}) as Dictionary).duplicate(),
		"lost": Run.structures_lost(state),
		# **The fish book** (task 0182): how many of each species this run
		# has landed, off `Fishing`'s book.
		"fish_book": _caught(state),
	}


## Every run ever, as the same record, read off a profile.
##
## A profile that has never been folded into answers zeroes rather than
## nothing, so the screen has something to draw on a first launch.
static func lifetime(profile: Dictionary) -> Dictionary:
	var stats: Dictionary = profile.get("stats", {})
	var life: Dictionary = stats.get("lifetime", {})
	return {
		"nights": int(life.get("nights", 0)),
		"best_night": int(profile.get("best_night", 0)),
		"killed": int(life.get("killed", 0)),
		"killed_by_kind": (life.get("killed_by_kind", {}) as Dictionary).duplicate(),
		"gathered": (life.get("gathered", {}) as Dictionary).duplicate(),
		"built": int(life.get("built", 0)),
		"built_by_kind": (life.get("built_by_kind", {}) as Dictionary).duplicate(),
		"lost": int(life.get("lost", 0)),
		"fish_book": (life.get("fish_book", {}) as Dictionary).duplicate(),
		"runs_started": int(profile.get("runs_started", 0)),
		"runs_won": int(profile.get("runs_won", 0)),
	}


## The fields `of_run()` and `lifetime()` both answer, in a fixed order, so
## that a screen can walk them without naming each one twice.
const FIELDS: Array = ["nights", "killed", "gathered", "built", "lost"]


# -------------------------------------------------------------------- banking

## Add whatever of this run has not been banked yet into the profile, and
## remember that it has been. Returns the new profile; the old one is not
## touched.
##
## **Safe to call whenever the game is saved**, which is the point: call it
## twice and the second adds nothing, call it every night and a crash costs
## the player the current night rather than the whole run.
static func fold(profile: Dictionary, state: Dictionary) -> Dictionary:
	var out := profile.duplicate(true)
	var stats: Dictionary = out.get("stats", {})
	var life: Dictionary = stats.get("lifetime", {})
	var mine: Dictionary = state["stats"]
	var banked: Dictionary = mine["banked"]
	var now := of_run(state)

	for field in ["nights", "killed", "built", "lost"]:
		var fresh := int(now[field]) - int(banked.get(field, 0))
		life[field] = int(life.get(field, 0)) + fresh
		banked[field] = int(now[field])

	for field in ["killed_by_kind", "built_by_kind", "gathered", "fish_book"]:
		var into: Dictionary = life.get(field, {})
		var was: Dictionary = banked.get(field, {})
		var has: Dictionary = now[field]
		for key in GameData.sorted_names(has.keys()):
			var fresh := int(has[key]) - int(was.get(key, 0))
			if fresh != 0:
				into[key] = int(into.get(key, 0)) + fresh
		life[field] = into
		banked[field] = has.duplicate()

	stats["lifetime"] = life
	out["stats"] = stats
	return out


## **The book across every run** (task 0182): each species ever landed and
## how many - the profile's banked count plus whatever this run has landed
## since it was last folded, so a fish caught a minute ago is in it before
## the night banks it.
static func fish_known(profile: Dictionary, state: Dictionary) -> Dictionary:
	var out: Dictionary = lifetime(profile)["fish_book"]
	if state.is_empty():
		return out
	var banked: Dictionary = ((state.get("stats", {}) as Dictionary).get("banked", {}) as Dictionary).get("fish_book", {})
	var run := _caught(state)
	for id in GameData.sorted_names(run.keys()):
		var fresh := int(run[id]) - int(banked.get(id, 0))
		if fresh > 0:
			out[id] = int(out.get(id, 0)) + fresh
	return out


## A run is about to be played. Bumps the count of runs started, which is the
## one lifetime number that cannot be folded from a state - by the time there
## is a state to read, it has already begun.
static func begin_run(profile: Dictionary) -> Dictionary:
	var out := profile.duplicate(true)
	out["runs_started"] = int(out.get("runs_started", 0)) + 1
	return out


## Species -> how many landed this run, off the run's fish book.
static func _caught(state: Dictionary) -> Dictionary:
	var out := {}
	var book: Dictionary = state.get("fish_book", {})
	for id in GameData.sorted_names(book.keys()):
		out[id] = int((book[id] as Dictionary).get("caught", 0))
	return out


## Everything gathered this run, minus the things that are not gathered.
##
## The same rule as `Run._worth_gathering()`: money is earned rather than
## gathered, energy is a rate, and technology is a reward - counting any of
## them as a haul would be counting the same work twice.
static func _haul(state: Dictionary) -> Dictionary:
	var out := {}
	var gained: Dictionary = state.get("gained", {})
	for id in GameData.sorted_names(gained.keys()):
		if id == GameData.MONEY or id == GameData.ENERGY \
				or id == GameData.TECH:
			continue
		if int(gained[id]) > 0:
			out[id] = int(gained[id])
	return out
