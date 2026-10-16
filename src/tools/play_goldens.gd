extends SceneTree

## **A day and a night for every golden** (task 0291).
##
##     godot --headless --path . --script res://src/tools/play_goldens.gd
##
## `headless_check` loads every golden save and plays 600 ticks of it. That
## proves the shape, not the game: a save can load, tick, and still never
## reach a morning - a night that does not resolve on its date, a report
## that cannot be confirmed, a boss the calendar holds for ever. So this
## plays each run golden `Save.verdict` migrates the whole of 0118's road:
## - **to the morning first**, if it was saved over its report;
## - **600 ticks of the day**, then to bed;
## - **START**, and the night runner to dawn;
## - the report confirmed;
##
## and checks it **wakes on the next calendar date, in DAY, with no enemy
## left on the farm**. A golden the rule archives is counted and named, not
## played. Too long for the suite (a night to dawn a golden, a couple of
## dozen goldens), so `tools/verify.py` runs it as its own `goldens` row.

const DIR := "res://tools/goldens/"

## Ticks of the day played before bed: the suite's 600.
const DAY_TICKS := 600

## The night runner's cap, the autoplayer's: a night still going at forty
## thousand ticks is a night that will not end.
const NIGHT_CAP := 40000


func _initialize() -> void:
	var played := 0
	var archived := 0
	var failed := 0
	var names: Array = []
	for name in DirAccess.get_files_at(DIR):
		if String(name).begins_with("run-v") and String(name).ends_with(".sav"):
			names.append(String(name))
	names.sort()
	for name in names:
		var state := Save.read_run_at(DIR + String(name))
		if state.is_empty():
			if Save.trouble() == Save.ARCHIVED:
				archived += 1
				print("  archived  %s" % name)
			else:
				failed += 1
				print("FAIL %s does not load: %s" % [name, Save.trouble_detail()])
			continue
		var said := _a_day_and_a_night(state)
		if said.begins_with("FAIL"):
			failed += 1
			print("%s %s" % [said, name])
		else:
			played += 1
			print("  woke      %s: %s" % [name, said])
	print("%d goldens woke on their next date, %d archived, %d failed"
		% [played, archived, failed])
	quit(1 if failed > 0 or played == 0 else 0)


## One golden's day and night by the road. The line for the log, or one
## starting `FAIL` that says what went wrong.
func _a_day_and_a_night(state: Dictionary) -> String:
	# **To the morning first**: a golden saved over its report confirms it,
	# as a player pressing on would.
	if int(state["phase"]) == Phases.RESULT:
		(state["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(state, 2)
	if int(state["phase"]) != Phases.DAY:
		return "FAIL is in %s, not the day," % Phases.name_of(int(state["phase"]))
	var date := Calendar.date(state)
	Sim.advance(state, DAY_TICKS)
	(state["intent"] as Dictionary)["sleep"] = true
	Sim.advance(state, 1)
	if int(state["phase"]) != Phases.PREPARATION:
		return "FAIL did not go to bed on day %d:" % date
	NightRoad.through_build(state)
	var ticks := NightRoad.run_night(state, NIGHT_CAP)
	if int(state["phase"]) != Phases.RESULT:
		return "FAIL night %d did not end in %d ticks:" % [date, ticks]
	var outcome := "won" if bool((state["last_result"] as Dictionary).get("survived", false)) else "lost"
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(state, 2)
	var woke := Calendar.date(state)
	if int(state["phase"]) != Phases.DAY or woke != date + 1:
		return "FAIL woke on day %d in %s after night %d:" % [woke,
			Phases.name_of(int(state["phase"])), date]
	if Entities.count(state) > 0:
		return "FAIL %d enemies on the farm the morning after night %d:" % [
			Entities.count(state), date]
	return "day %d -> day %d, night %d %s in %d ticks" % [date, woke, date, outcome, ticks]
