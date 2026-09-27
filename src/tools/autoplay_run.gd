extends SceneTree

## Run the autoplayer over many seeds and report.
##
##     python tools/autoplay.py [runs]
##
## Four policies, `runs / 4` seeds each. It prints which night kills each one,
## how far they get, and **whether one of them wins everything** - which is
## the dominant-strategy alarm task 0067 asks for, and the thing a balance
## pass most needs to be told.

## How many runs in total when nobody says otherwise. Four policies, so
## twenty-five seeds each.
const RUNS := 100


func _init() -> void:
	var problems := GameData.validate()
	if not problems.is_empty():
		print("the tables do not validate:")
		for line in problems:
			print("  ", line)
		quit(1)
		return

	var wanted := RUNS
	for arg in OS.get_cmdline_user_args():
		if str(arg).is_valid_int():
			wanted = maxi(int(str(arg)), 4)

	var policies := Autoplay.names()
	var each := maxi(wanted / policies.size(), 1)
	print("HARVEST THE NIGHT - %d runs, %d seeds of each policy"
		% [each * policies.size(), each])
	print("")

	var started := Time.get_ticks_usec()
	var report: Dictionary = {}
	for name in policies:
		report[name] = _sweep(StringName(name), each)
	var spent := float(Time.get_ticks_usec() - started) / 1000000.0

	print("  policy     won  killed by      avg night  avg house  gathered")
	for name in policies:
		var row: Dictionary = report[name]
		print("  %-10s %3d  %-13s %9.1f %10.1f  %8d"
			% [name, int(row["won"]), str(row["killer"]),
				float(row["mean_night"]), float(row["mean_house"]),
				int(row["mean_gathered"])])

	print("")
	for name in policies:
		var row: Dictionary = report[name]
		print("  %-10s %s" % [name,
			(Autoplay.POLICIES[name] as Dictionary)["note"]])
		print("             nights: %s" % str(row["reached"]))

	_alarm(report, policies, each)
	print("")
	print("  %d runs in %.1f s" % [each * policies.size(), spent])
	quit()


## One policy, many seeds.
func _sweep(name: StringName, runs: int) -> Dictionary:
	var won := 0
	var deaths: Dictionary = {}
	var reached: Array = []
	var nights := 0
	var house := 0
	var gathered := 0
	for i in runs:
		var out := Autoplay.play(9000 + i * 7, name)
		if bool(out["won"]):
			won += 1
		else:
			var on := int(out["died_on"])
			deaths[on] = int(deaths.get(on, 0)) + 1
		var got := (out["nights"] as Array).size()
		nights += got
		reached.append(got)
		gathered += int(out["gathered"])
		var last: Dictionary = (out["nights"] as Array)[got - 1]
		house += int(last["house"])

	# **The night that kills it most often**, which is what the report is for.
	var killer := "nothing - it wins"
	var worst := 0
	for night in deaths:
		if int(deaths[night]) > worst:
			worst = int(deaths[night])
			killer = "night %d (%dx)" % [int(night), worst]
	return {
		"won": won,
		"killer": killer,
		"reached": reached,
		"mean_night": float(nights) / float(maxi(runs, 1)),
		"mean_house": float(house) / float(maxi(runs, 1)),
		"mean_gathered": gathered / maxi(runs, 1),
	}


## **The dominant-strategy alarm.** One policy winning everything while the
## others die is a game with one answer, which is the thing a balance pass
## exists to catch.
func _alarm(report: Dictionary, policies: Array, each: int) -> void:
	print("")
	var best := ""
	var best_won := -1
	var second := 0
	for name in policies:
		var won := int((report[name] as Dictionary)["won"])
		if won > best_won:
			second = best_won
			best_won = won
			best = str(name)
		elif won > second:
			second = won

	if best_won <= 0:
		print("  ALARM: no policy won a single run - the ten nights are "
			+ "unbeatable by anything this robot knows how to do")
		return
	if second <= 0:
		print("  ALARM: '%s' is the only policy that wins at all (%d of %d). "
			% [best, best_won, each] + "A game with one answer is a game "
			+ "with no decisions in it")
		return
	if best_won >= second * 2 and best_won >= each / 2:
		print("  ALARM: '%s' wins %d where the next best wins %d - twice "
			% [best, best_won, second] + "over is a dominant strategy")
		return
	print("  no dominant strategy: best is '%s' at %d of %d, next at %d"
		% [best, best_won, each, second])
