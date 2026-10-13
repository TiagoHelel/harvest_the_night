extends SceneTree

## Run the autoplayer over many seeds and report.
##
##     python tools/autoplay.py [runs] [--nights=1]
##     python tools/autoplay.py --year [seeds]
##
## Four policies, `runs / 4` seeds each, ten nights a run. It prints which
## night kills each one first, how far they get, and **whether one of them
## wins everything** - which is the dominant-strategy alarm task 0067 asks
## for, and the thing a balance pass most needs to be told.
##
## **A run plays on after a loss** since task 0142, as a player does: the
## `nights:` list is still the first night each run lost (or ten), which is
## what `tools/balance.py` reads its win rate from, and `won all` counts the
## nights won over the whole run. Under each policy, how its nights ended.
##
## ## A year, and the `RUN` line (task 0276)
##
## **Every run prints one machine-readable `RUN` line** beside today's table:
##
##     RUN policy=<p> seed=<s> days=<n> nights=<played> losses=<a,b,c,d>
##         repeats=<a,b,c,d> money=<a,b,c,d> essence=<a,b,c,d> capped=<0|1>
##         over=<0|1> walked=<tiles> lost=<date,date,...|-> ms=<wall time>
##
## one line, the four numbers a season each: the nights lost, the boss nights
## the boss lived through (each fought again, unless it was the one the cap
## stopped on), and the money and essence at the season's first morning.
## `tools/balance.py` keeps reading today's table until task 0277 moves its
## parser onto `RUN`. **`--year`** plays every date of the year instead of
## the first ten, and **`--policy=<name>`** and **`--seeds=a,b,...`** narrow
## a process to its share - `tools/autoplay.py --year` runs the shares in
## parallel processes, since the data does not change inside a run set, and
## prints the year's table from their `RUN` lines.

## How many runs in total when nobody says otherwise. Four policies, so
## twenty-five seeds each.
const RUNS := 100

## **A year's seeds a policy** when nobody says (task 0276): 0277's "at least
## eight seeds".
const YEAR_SEEDS := 8

var _nights_wanted := Autoplay.DEFAULT_NIGHTS
var _year := false
var _only := &""
var _seeds: Array = []


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
		if str(arg).begins_with("--nights="):
			_nights_wanted = maxi(int(str(arg).get_slice("=", 1)), 1)
		if str(arg) == "--year":
			_year = true
			_nights_wanted = Calendar.year_days()
		if str(arg).begins_with("--policy="):
			_only = StringName(str(arg).get_slice("=", 1))
		if str(arg).begins_with("--seeds="):
			for one in str(arg).get_slice("=", 1).split(",", false):
				_seeds.append(int(one))
		if str(arg).is_valid_int():
			wanted = maxi(int(str(arg)), 4)

	# **A year's share** (task 0276): the named policy, or every one, on the
	# named seeds, or the first ones a year run takes - `RUN` lines and each
	# run's wall time, and nothing else to parse.
	if _year:
		# **The data is read** (task 0277): every table is loaded by now, so a
		# sweep waiting on this line may write the next lever's value.
		print("PLAYING")
		var policies_now: Array = [_only] if _only != &"" else Autoplay.names()
		# A count given to a year is its seeds a policy: eight unless said.
		var seeds_now: Array = _seeds
		if seeds_now.is_empty():
			seeds_now = _first_seeds(wanted if wanted != RUNS else YEAR_SEEDS)
		for name in policies_now:
			for seed_value in seeds_now:
				var started_run := Time.get_ticks_msec()
				var out := Autoplay.play(int(seed_value), StringName(name), _nights_wanted)
				print(_run_line(out, Time.get_ticks_msec() - started_run))
		quit()
		return

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

	print("  policy     won  killed by      avg night  avg house  gathered  won all")
	for name in policies:
		var row: Dictionary = report[name]
		print("  %-10s %3d  %-13s %9.1f %10.1f  %8d  %7.1f"
			% [name, int(row["won"]), str(row["killer"]),
				float(row["mean_night"]), float(row["mean_house"]),
				int(row["mean_gathered"]), float(row["mean_won"])])

	print("")
	for name in policies:
		var row: Dictionary = report[name]
		print("  %-10s %s" % [name,
			(Autoplay.POLICIES[name] as Dictionary)["note"]])
		print("             nights: %s" % str(row["reached"]))
		var ends: Dictionary = row["ends"]
		print("             ended: dawn %d, everything dead %d, house down %d%s; %.1f walked off a night"
			% [int(ends.get(&"dawn", 0)), int(ends.get(&"cleared", 0)),
				int(ends.get(&"house", 0)),
				(", still going at the cap %d" % int(ends[&"cap"])) if ends.has(&"cap") else "",
				float(row["mean_walked"])])

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
	var won_all := 0
	var ends: Dictionary = {}
	var walked := 0
	var played := 0
	for i in runs:
		var started_run := Time.get_ticks_msec()
		var out := Autoplay.play(9000 + i * 7, name, _nights_wanted)
		print(_run_line(out, Time.get_ticks_msec() - started_run))
		if _nights_wanted == 1:
			var day: Dictionary = (out["nights"] as Array)[0]
			print("  %s seed %d: day %d ticks, earned %d, net money %+d, night %s"
				% [name, 9000 + i * 7, day["day_ticks"], day["day_earned"], day["day_money"], day["ended"]])
		if bool(out["won"]):
			won += 1
		else:
			var on := int(out["died_on"])
			deaths[on] = int(deaths.get(on, 0)) + 1
		var got := (out["nights"] as Array).size()
		# How far it got before its first loss - the run plays on after one.
		var first_loss := int(out["died_on"])
		var far := first_loss if first_loss > 0 else got
		nights += far
		reached.append(far)
		gathered += int(out["gathered"])
		won_all += int(out["nights_won"])
		var last: Dictionary = (out["nights"] as Array)[got - 1]
		house += int(last["house"])
		for row in (out["nights"] as Array):
			var kind := StringName((row as Dictionary)["ended"])
			ends[kind] = int(ends.get(kind, 0)) + 1
			walked += int((row as Dictionary)["walked"])
			played += 1

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
		"mean_won": float(won_all) / float(maxi(runs, 1)),
		"ends": ends,
		"mean_walked": float(walked) / float(maxi(played, 1)),
	}


## The seeds a run set takes when none are named: 9000 and every seventh
## after it, as the sweep always has.
static func _first_seeds(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(9000 + i * 7)
	return out


## **One run as a `RUN` line** (task 0276), every number a season each in
## `SEASONS` order. A season the run never reached reads -1 for its money and
## essence.
static func _run_line(out: Dictionary, ms: int) -> String:
	var losses: Array = []
	var repeats: Array = []
	var money: Array = []
	var essence: Array = []
	for season in (out["seasons"] as Array):
		var one: Dictionary = season
		losses.append(str(int(one["losses"])))
		repeats.append(str(int(one["repeats"])))
		money.append(str(int(one["money"])))
		essence.append(str(int(one["essence"])))
	# **The dates of the nights lost** (task 0277), each time it was lost - a
	# boss night lost twice is there twice - for the survival per day
	# `tools/balance.py` reads; `-` for none.
	var lost: Array = []
	for row in (out["nights"] as Array):
		if not bool((row as Dictionary)["held"]):
			lost.append(str(int((row as Dictionary)["date"])))
	return "RUN policy=%s seed=%d days=%d nights=%d losses=%s repeats=%s money=%s essence=%s capped=%d over=%d walked=%d lost=%s ms=%d" % [
		out["policy"], int(out["seed"]), (out["nights"] as Array).back()["date"] if not (out["nights"] as Array).is_empty() else 0,
		(out["nights"] as Array).size(), ",".join(losses), ",".join(repeats), ",".join(money), ",".join(essence),
		1 if bool(out["capped"]) else 0, 1 if bool(out["year_over"]) else 0, int(out["walked"]),
		",".join(lost) if not lost.is_empty() else "-", ms]


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
