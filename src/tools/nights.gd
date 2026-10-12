extends SceneTree

## Print the year's nights, without running one of them.
##
##     python tools/nights.py [from] [to] [seed]
##     python tools/nights.py --check
##
## **By default the year** (task 0270): days 1 to `Calendar.year_days()` for
## seed 0, a block per season. Each day gives its kinds, sides, count, hit
## points, reward and weather, and is marked `key` (written in
## `GameData.KEY_NIGHTS`), `made` (made by `Almanac` from its season's
## template), `curve` (past the year, `Endless`'s) or `calm`, and `FULL` and
## `BOSS` on a Full Moon and a boss's night. Then it prints the day each kind
## is first sent and the days as bars of hit points.
## `python tools/nights.py 15 28 3` prints Summer for seed 3, and a range past
## the year prints the curve.
##
## **`--check` is a gate** (task 0151), run by `tools/verify.py`: the year's
## tables pass `GameData.check_nights`, and every date of the year, 1 to
## `Calendar.year_days()`, for seeds 0 and 424242, resolves to a record that
## passes `GameData.check_record` - the night length of 0137 included - or it
## exits 1. It prints the year for seed 0 as it goes.
##
## Everything here is read off the tables through `Waves`, so they are the
## only source: a designer who edits a key night or a template sees it here on
## the next run without touching a line of code, which is the whole of tasks
## 0059 and 0270. The seed orders a made night's waves and picks the side it
## opens on, so a day's count, hit points and kinds are the same for every
## seed. Its weather is the seed's.
##
## Without `--check` it is a **reader, not a check**. `GameData.validate()` is
## what fails loudly on a bad table and the suites are what assert the shape;
## this is for looking at the year while you tune it.

## The seeds the year is checked for.
const CHECK_SEEDS: Array = [0, 424242]

## How wide the widest bar is, in characters.
const BAR := 40


func _init() -> void:
	var problems := GameData.validate()
	if not problems.is_empty():
		print("the tables do not validate:")
		for line in problems:
			print("  ", line)
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	if args.has("--check"):
		quit(_check_the_year())
		return

	var numbers: Array = []
	for arg in args:
		if str(arg).is_valid_int():
			numbers.append(int(str(arg)))
	var first := maxi(int(numbers[0]) if numbers.size() > 0 else 1, 1)
	var last := maxi(int(numbers[1]) if numbers.size() > 1 else Calendar.year_days(), first)
	var seed_value := int(numbers[2]) if numbers.size() > 2 else 0
	_print_the_days(first, last, seed_value)
	quit()


## The days `first` to `last` of a run started on `seed_value`: a block per
## season, the totals, the first day each kind is sent, and the bars.
func _print_the_days(first: int, last: int, seed_value: int) -> void:
	print("HARVEST THE NIGHT - days %d to %d, seed %d" % [first, last, seed_value])
	print("  key: written in KEY_NIGHTS   made: from its season's template   "
		+ "curve: Endless, past the year")
	print(("  FULL: a Full Moon, the horde at %d%%   BOSS: the season's boss comes   "
		+ "calm: nothing comes") % GameData.FULL_MOON_HORDE_PERCENT)
	# **Each night against the night** (task 0137): when its last member is
	# sent, which `check_record` holds `DAWN_MARGIN_TICKS` before dawn.
	print("  dawn at %ds; every night is sent %ds before it"
		% [GameData.NIGHT_TICKS / GameData.SECONDS,
			GameData.DAWN_MARGIN_TICKS / GameData.SECONDS])

	var enemies := 0
	var points := 0
	var money := 0
	var nights := 0
	var seen := {}
	var season := -1
	for day in range(first, last + 1):
		var now := (day - 1) / GameData.SEASON_DAYS
		if now != season:
			season = now
			print("")
			print("  %s%s" % [String(Calendar.season_id(day)).to_upper(),
				"" if Calendar.year_of(day) == 1 else ", year %d" % Calendar.year_of(day)])
			print("   day  date         marks           sent      hp  reward  sides          "
				+ "weather     sent by  kinds")
		print(_line_of(day, seed_value))
		var one := Waves.night_of(day, seed_value)
		if (one.get("waves", []) as Array).is_empty():
			continue
		nights += 1
		enemies += Waves.size_in(one)
		points += Waves.hit_points_in(one)
		money += Waves.reward_in(one)
		for id in GameData.sorted_names(Waves.kinds_in(one).keys()):
			if not seen.has(id):
				seen[id] = day

	print("")
	# **Worth, and what a night pays for it** (task 0219): the bounty is
	# `bounty_percent` of the kills' worth.
	print("  %d enemies over %d nights, %d hit points, worth $%d - a bounty of $%d at %d%%"
		% [enemies, nights, points, money,
			money * int(GameData.REWARDS["bounty_percent"]) / 100,
			int(GameData.REWARDS["bounty_percent"])])

	# **What the run pays in technology**, which is the budget task 0063 has
	# to price the tech tree against: the floor is one a night for finishing,
	# the ceiling is every bonus every night.
	var bonuses: Array = []
	for row in GameData.TECH_BONUSES:
		bonuses.append("%s +%d" % [(row as Dictionary)["id"],
			int((row as Dictionary)["points"])])
	print("  technology over the year: %d at worst, %d at best (%d a night, then %s)"
		% [Tech.least_available(), Tech.total_available(),
			int(GameData.REWARDS["tech_points"]), ", ".join(bonuses)])

	# **When each kind is first sent.** `design.md` section 10 wants one new
	# thing a night, and the key nights are where they are met.
	var arrivals: Array = []
	for day in range(first, last + 1):
		for id in GameData.sorted_names(seen.keys()):
			if int(seen[id]) == day:
				arrivals.append("%s on %d" % [id, day])
	print("  first sent: " + ", ".join(arrivals))

	# The year, as a shape rather than as numbers: hit points, the template's
	# own measure.
	print("")
	var widest := 1
	for day in range(first, last + 1):
		widest = maxi(widest, Waves.hit_points_in(Waves.night_of(day, seed_value)))
	for day in range(first, last + 1):
		var one := Waves.night_of(day, seed_value)
		var hp := Waves.hit_points_in(one)
		var bar := "#".repeat(hp * BAR / widest) if hp > 0 else ""
		print("  %3d %-12s %s %6d  %s" % [day, _date_of(day), bar.rpad(BAR), hp,
			" ".join(_marks_of(day))])


## One day in one line: its date, marks, count, hit points, reward, sides,
## weather, when it is all sent, and what comes.
func _line_of(day: int, seed_value: int) -> String:
	var one := Waves.night_of(day, seed_value)
	var sides: Array = []
	for side in Waves.spawns_in(one):
		sides.append(_side_code(int(side)))
	var weather := String(Weather.event(seed_value, day))
	var parts: Array = []
	var counts := Waves.kinds_in(one)
	for id in GameData.sorted_names(counts.keys()):
		parts.append("%d %s" % [int(counts[id]), id])
	if bool(one.get("calm", false)):
		parts.append("nothing: %s" % str(one.get("note", "")))
	var sent := Waves.schedule_ticks(one)
	return "  %4d  %-12s %-15s %4d  %6d  $%-5d %-14s %-10s %4ds  %s" % [day, _date_of(day),
		" ".join(_marks_of(day)), Waves.size_in(one), Waves.hit_points_in(one),
		Waves.reward_in(one), "-" if sides.is_empty() else ",".join(sides),
		"-" if weather.is_empty() else weather, sent / GameData.SECONDS, ", ".join(parts)]


## What a day is: `key`, `made`, `curve` or `calm`, then `FULL` and `BOSS`.
func _marks_of(day: int) -> Array:
	var marks: Array = []
	if Calendar.is_calm(day):
		marks.append("calm")
	elif Almanac.is_key(day):
		marks.append("key")
	elif Almanac.is_made(day):
		marks.append("made")
	else:
		marks.append("curve")
	if Calendar.is_full_moon(day):
		marks.append("FULL")
	if Calendar.is_boss_night(day):
		marks.append("BOSS")
	return marks


## `spring 7`, and the year past the first.
func _date_of(day: int) -> String:
	var text := "%s %d" % [Calendar.season_id(day), Calendar.day_of_season(day)]
	if Calendar.year_of(day) > 1:
		text += " y%d" % Calendar.year_of(day)
	return text


## A side by the initials of its name: `E`, `SE`, `N`, `W`, `S`.
func _side_code(side: int) -> String:
	if side < 0 or side >= GameData.SPAWN_SIDES.size():
		return "?%d" % side
	var code := ""
	for word in String(GameData.SPAWN_SIDES[side]).split("_"):
		code += word.left(1).to_upper()
	return code


## **The year, as a gate.** The tables pass `check_nights`, and every date
## resolves to a record that passes `check_record`, for each of
## `CHECK_SEEDS`. Returns the exit code: 0 clean, 1 with a line for every
## fault.
func _check_the_year() -> int:
	var days := Calendar.year_days()
	var faults: Array = []
	for line in GameData.check_nights(GameData.SEASON_NIGHTS, GameData.KEY_NIGHTS):
		faults.append("the tables: %s" % line)
	for seed_value in CHECK_SEEDS:
		for date in range(1, days + 1):
			var one := Waves.night_of(date, int(seed_value))
			if one.is_empty():
				faults.append("seed %d: date %d has no night" % [seed_value, date])
				continue
			if int(seed_value) == 0:
				print(_line_of(date, 0))
			for line in GameData.check_record(one, date):
				faults.append("seed %d: %s" % [seed_value, line])
	print("")
	for line in faults:
		print("  FAIL %s" % line)
	print("%d nights a year, seeds %s: %s" % [days, str(CHECK_SEEDS),
		"every one checks" if faults.is_empty() else "%d faults" % faults.size()])
	return 0 if faults.is_empty() else 1
