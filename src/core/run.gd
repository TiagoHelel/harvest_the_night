class_name Run
extends RefCounted

## When a run is over, and what it was.
##
## **The MVP ends here.** Ten nights and the Giant, and then a summary that
## answers the only question `design.md` asks of the whole thing: was the loop
## worth going round again.
##
## ## Over, rather than lost
##
## A run ends one way in the MVP: the tenth night survived. Losing costs a day
## and never the run (task 0065), so there is no losing end - `is_over()` asks
## whether the last night has been beaten and nothing else.
##
## ## Carrying on
##
## Beating it offers two doors: a new run, or **endless**, which is task
## 0070's. This file sets the flag and stops; what night eleven is made of is
## that task's problem, and `Waves.table()` already answers an empty list past
## the authored ten, so an endless run that arrives before 0070 does is a
## quiet farm rather than a crash.
##
## ## The summary is read, not kept
##
## Every number in it is already somewhere in the state - days lived, what was
## killed, what was gathered, what fell - so there is no second ledger to
## disagree with the first. The only thing this file adds to the state is the
## count of structures lost, because rubble is swept every morning and the
## number would be gone by the end.


static func initial() -> Dictionary:
	return {
		# How many things the player built have come down this run. Counted
		# here because `Farm` sweeps the rubble every morning and nothing
		# else remembers.
		"structures_lost": 0,
		# Set when the player chooses to carry on past the authored nights.
		# Task 0070 is what makes night eleven worth playing.
		"endless": false,
	}


# ------------------------------------------------------------------- asking

## Whether the run has been beaten. The tenth night survived, and no other way.
static func is_over(state: Dictionary) -> bool:
	return Phases.nights_won(state) >= GameData.MVP_NIGHTS \
		and not bool(state["endless"])


## Whether this is the last authored night about to be fought.
static func is_final_night(state: Dictionary) -> bool:
	return int(state["night"]) == GameData.MVP_NIGHTS


static func is_endless(state: Dictionary) -> bool:
	return bool(state["endless"])


static func structures_lost(state: Dictionary) -> int:
	return int(state["structures_lost"])


## One more thing the player built has come down. Called from `Farm`.
static func lost_a_structure(state: Dictionary) -> void:
	state["structures_lost"] = int(state.get("structures_lost", 0)) + 1


# ------------------------------------------------------------- the summary

## What the run was, read off the state.
##
## Every line is a lookup. The build that won is the farm as it stands, which
## is the honest answer to "what beat it" - a list of what was standing when
## the Giant went down rather than a history of everything ever placed.
static func summary(state: Dictionary) -> Dictionary:
	return {
		"days": int(state["day"]),
		"nights_won": Phases.nights_won(state),
		# **The run's tallies, not the night's.** `killed` and `breaches` are
		# cleared when a night begins, so a summary built from them would
		# report the last night and call it a run.
		"killed": int(state["killed_all_run"]),
		"killed_by_kind":
			(state["killed_by_kind_all_run"] as Dictionary).duplicate(),
		"breaches": int(state["breaches_all_run"]),
		"gathered": _worth_gathering(state),
		"structures_lost": structures_lost(state),
		"build": standing(state),
		"technology": Tech.owned(state).duplicate(),
		"money": Resources.amount(state, GameData.MONEY),
		"house_hp": int(state["house_hp"]),
		"flares": Ability.flares_used(state),
		"traps": Traps.sprung(state),
		"bosses": Combat.bosses_down(state),
	}


## What is standing at the end, by kind and level. **The build that won.**
static func standing(state: Dictionary) -> Dictionary:
	var out := {}
	var occupants: Dictionary = state["occupants"]
	var keys: Array = occupants.keys()
	keys.sort()
	for idx in keys:
		var on: Dictionary = occupants[idx]
		var id: StringName = on["id"]
		if not GameData.DEFENCES.has(id):
			continue
		var level := maxi(int(on.get("level", 1)), 1)
		var name := id if level <= 1 else StringName("%s %s"
			% [id, "II" if level == 2 else "III"])
		out[name] = int(out.get(name, 0)) + 1
	return out


## Everything gathered this run, minus the things that are not gathered.
##
## Money is earned rather than gathered and energy is a rate; counting either
## as a haul would be counting the same work twice.
static func _worth_gathering(state: Dictionary) -> Dictionary:
	var out := {}
	var gained: Dictionary = state["gained"]
	for id in GameData.sorted_names(gained.keys()):
		if id == GameData.MONEY or id == GameData.ENERGY \
				or id == GameData.TECH:
			continue
		if int(gained[id]) > 0:
			out[id] = int(gained[id])
	return out


# -------------------------------------------------------------------- doing

## Carry on past the authored nights. Task 0070 makes night eleven worth
## playing; this is the switch that lets a player ask for it.
static func go_endless(state: Dictionary) -> bool:
	if Phases.nights_won(state) < GameData.MVP_NIGHTS:
		return false
	state["endless"] = true
	return true


## Write what this run was to the profile, and hand back the profile.
##
## **The profile is the thing that survives a run**, so this is where a win
## stops being a fact about a `State` and becomes a fact about the player.
## The lifetime tallies are `Stats`'; this writes the three lines only the end
## of a run knows.
static func record(state: Dictionary, profile: Dictionary) -> Dictionary:
	# **The lifetime totals go through `Stats`**, which is the only thing that
	# adds to them, and which banks what it has already counted. A run that
	# has been folded in at the end of every night - which is what task 0069
	# wants, so that a crash costs a night rather than a run - is not counted
	# a second time here.
	var out := Stats.fold(profile, state)
	out["runs_won"] = int(out.get("runs_won", 0)) + (1 if is_over(state) else 0)
	out["best_night"] = maxi(int(out.get("best_night", 0)),
		Phases.nights_won(state))
	var stats: Dictionary = out.get("stats", {})
	stats["last_run"] = summary(state)
	out["stats"] = stats
	return out
