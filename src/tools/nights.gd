extends SceneTree

## Print the year's nights, without running one of them.
##
##     python tools/nights.py [from] [to] [seed]
##     python tools/nights.py --years 3
##     python tools/nights.py --sameness [seed]
##     python tools/nights.py --check
##
## **By default the year** (task 0270): days 1 to `Calendar.year_days()` for
## seed 0, a block per season. Each day gives its kinds, sides, count, hit
## points, reward and weather, and is marked `key` (written in
## `GameData.KEY_NIGHTS`), `made` (made by `Almanac` from its season's
## template - in a later year, Year 1's day grown, task 0279) or `calm`, and
## `FULL` and
## `BOSS` on a Full Moon and a boss's night. **When it is all sent** stands
## against the fill line (task 0271, `Waves.fill_line`): a `!` marks a night
## over before it. Then it prints the day each kind is first sent and the
## days as bars of hit points.
## `python tools/nights.py 15 28 3` prints Summer for seed 3, and a range past
## the year prints the later years.
##
## **`--years N`** (task 0279) prints Years 1 to N for seed 0, day by day,
## then a line a season of each year: its nights, hit points, largest night,
## boss and the boss's hit points that year, and its weather.
##
## **`--sameness [seed]`** (task 0280) counts how alike the year's nights are,
## by the rules rather than by eye: per season, the nights that share their
## mix of kinds and sides with another; the longest runs of nights that bring
## nothing new - no enemy, side, weapon, event or boss first met - by day; and
## how often the forecast says the same thing two nights running.
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
	var same := args.find("--sameness")
	if same >= 0:
		_print_sameness(int(str(args[same + 1])) if same + 1 < args.size() and str(args[same + 1]).is_valid_int() else 0)
		quit()
		return
	var at := args.find("--years")
	if at >= 0:
		var years := maxi(int(str(args[at + 1])) if at + 1 < args.size() and str(args[at + 1]).is_valid_int() else 3, 1)
		_print_the_days(1, years * Calendar.year_days(), 0)
		_print_the_years(years, 0)
		quit()
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
	print("  key: written in KEY_NIGHTS   made: from its season's template "
		+ "(a later year's: Year 1's day grown)")
	print(("  FULL: a Full Moon, the horde at %d%%   BOSS: the season's boss comes   "
		+ "calm: nothing comes") % GameData.FULL_MOON_HORDE_PERCENT)
	# **Each night against the night** (task 0137): when its last member is
	# sent, which `check_record` holds `DAWN_MARGIN_TICKS` before dawn - and,
	# since task 0271, after the fill line.
	print("  dawn at %ds; every night is all sent by %ds, and still sending at %ds (the fill line) - ! sent before it"
		% [GameData.NIGHT_TICKS / GameData.SECONDS,
			(GameData.NIGHT_TICKS - GameData.DAWN_MARGIN_TICKS) / GameData.SECONDS,
			Waves.fill_line() / GameData.SECONDS])

	var enemies := 0
	var points := 0
	var money := 0
	var nights := 0
	var filling := 0
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
		if Waves.schedule_ticks(one) >= Waves.fill_line():
			filling += 1
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
	print("  %d of the %d are still sending at the fill line, %ds" % [filling, nights,
		Waves.fill_line() / GameData.SECONDS])

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
	var short := "!" if sent < Waves.fill_line() and not bool(one.get("calm", false)) else " "
	return "  %4d  %-12s %-15s %4d  %6d  $%-5d %-14s %-10s %4ds%s %s" % [day, _date_of(day),
		" ".join(_marks_of(day)), Waves.size_in(one), Waves.hit_points_in(one),
		Waves.reward_in(one), "-" if sides.is_empty() else ",".join(sides),
		"-" if weather.is_empty() else weather, sent / GameData.SECONDS, short, ", ".join(parts)]


## What a day is: `key`, `made` or `calm`, then `FULL` and `BOSS`.
func _marks_of(day: int) -> Array:
	var marks: Array = []
	if Calendar.is_calm(day):
		marks.append("calm")
	elif Almanac.is_key(day):
		marks.append("key")
	else:
		marks.append("made")
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


## **How alike the year's nights are** (task 0280), for `seed_value`'s
## weather:
## - **a mix shared**: a night's kinds and sides, as a set each, the same as
##   another night's of its season;
## - **nothing new**: a night that meets no kind, side or event (fog, rain,
##   a Blood Moon, a Full Moon) for the first time this year, opens no weapon
##   (the season's arsenal on its first day) and brings no boss; the longest
##   runs of them, by day;
## - **the forecast again**: two nights running whose forecast says the same
##   thing - its sides, its kinds, its weather, its moon and its boss - the
##   counts aside.
func _print_sameness(seed_value: int) -> void:
	var year := Calendar.year_days()
	print("HARVEST THE NIGHT - how alike the year's nights are, seed %d" % seed_value)
	var seen_kinds := {}
	var seen_sides := {}
	var seen_events := {}
	var weapons := {}
	var plain_days: Array = []
	var forecast_again: Dictionary = {}
	var previous := ""
	var by_season := {}
	for day in range(1, year + 1):
		var one := Waves.night_of(day, seed_value)
		var season := Calendar.season_id(day)
		var kinds := GameData.sorted_names(Waves.kinds_in(one).keys())
		var sides: Array = []
		for side in Waves.spawns_in(one):
			if not sides.has(int(side)):
				sides.append(int(side))
		sides.sort()
		var event := Weather.event(seed_value, day)
		var moon := Calendar.is_full_moon(day)
		var calm := bool(one.get("calm", false))
		var mix := "%s|%s" % [",".join(kinds), str(sides)]
		if not calm:
			var rows: Array = by_season.get(season, [])
			rows.append(mix)
			by_season[season] = rows
		# What this night meets for the first time.
		var news: Array = []
		for kind in kinds:
			if not seen_kinds.has(kind):
				seen_kinds[kind] = day
				news.append(String(kind))
		for side in sides:
			if not seen_sides.has(side):
				seen_sides[side] = day
				news.append("side %d" % side)
		for mark in [String(event), "full moon" if moon else ""]:
			if mark != "" and not seen_events.has(mark):
				seen_events[mark] = day
				news.append(mark)
		if Calendar.day_of_season(day) == 1:
			for id in GameData.sorted_names(GameData.DEFENCES.keys()):
				if Building.season_of(id) == Calendar.season_of(day) and not weapons.has(id):
					weapons[id] = day
					news.append(String(id))
		if Calendar.is_boss_night(day):
			news.append(String(Calendar.boss_of(day)))
		if news.is_empty() and not calm:
			plain_days.append(day)
		var said := "%s|%s|%s|%s|%s" % [str(sides), ",".join(kinds), event, moon, Calendar.boss_of(day) if Calendar.is_boss_night(day) else &""]
		if not calm and said == previous:
			forecast_again[season] = int(forecast_again.get(season, 0)) + 1
		previous = said if not calm else ""

	print("")
	print("  season   nights   distinct mixes   nights sharing a mix   forecast the same two nights running")
	for season in GameData.SEASONS:
		var rows: Array = by_season.get(season, [])
		var counts := {}
		for mix in rows:
			counts[mix] = int(counts.get(mix, 0)) + 1
		var sharing := 0
		for mix in counts:
			if int(counts[mix]) > 1:
				sharing += int(counts[mix])
		print("  %-7s  %6d   %14d   %20d   %d" % [season, rows.size(), counts.size(), sharing,
			int(forecast_again.get(season, 0))])

	# The runs of nights with nothing new, longest first.
	var runs: Array = []
	var start := -1
	var last := -10
	for day in plain_days:
		if int(day) == last + 1 or (int(day) == last + 2 and Calendar.is_calm(last + 1)):
			last = int(day)
			continue
		if start >= 0:
			runs.append([start, last])
		start = int(day)
		last = int(day)
	if start >= 0:
		runs.append([start, last])
	runs.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[1]) - int(a[0]) > int(b[1]) - int(b[0]) or (int(a[1]) - int(a[0]) == int(b[1]) - int(b[0]) and int(a[0]) < int(b[0])))
	print("")
	print("  %d of the year's nights bring nothing new; the longest runs of them:" % plain_days.size())
	for run in runs.slice(0, 6):
		var nights := 0
		for day in range(int(run[0]), int(run[1]) + 1):
			if plain_days.has(day):
				nights += 1
		print("    %d nights, days %d-%d (%s to %s)" % [nights, int(run[0]), int(run[1]), _date_of(int(run[0])), _date_of(int(run[1]))])
	print("")
	print("  first met: %s" % ", ".join(_firsts(seen_kinds) + _firsts(seen_sides) + _firsts(seen_events) + _firsts(weapons)))


## `name on day`, a dictionary of first days in day order.
func _firsts(found: Dictionary) -> Array:
	var keys: Array = found.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(found[a]) < int(found[b]) or (int(found[a]) == int(found[b]) and str(a) < str(b)))
	var out: Array = []
	for key in keys:
		out.append("%s %d" % [("side %d" % int(key)) if typeof(key) == TYPE_INT else str(key), int(found[key])])
	return out


## **The years, a season a line** (task 0279): each year's seasons with
## their nights, their hit points and largest night, their boss and the
## boss's hit points that year (`Almanac.boss_hp`), and their weather - the
## heavier-each-year the calendar promises, read at a glance.
func _print_the_years(years: int, seed_value: int) -> void:
	print("")
	print("  THE YEARS, a season a line (seed %d)" % seed_value)
	print("   year  season   nights   hit points   largest   boss              its hp   fog  rain  blood")
	for year in range(1, years + 1):
		for s in GameData.SEASONS.size():
			var first := (year - 1) * Calendar.year_days() + s * GameData.SEASON_DAYS + 1
			var nights := 0
			var points := 0
			var largest := 0
			var weather := {}
			for day in range(first, first + GameData.SEASON_DAYS):
				var one := Waves.night_of(day, seed_value)
				if (one.get("waves", []) as Array).is_empty():
					continue
				nights += 1
				var hp := Waves.hit_points_in(one)
				points += hp
				largest = maxi(largest, hp)
				var event := Weather.event(seed_value, day)
				weather[event] = int(weather.get(event, 0)) + 1
			var last := first + GameData.SEASON_DAYS - 1
			var boss := Calendar.boss_of(last)
			var boss_hp := Almanac.boss_hp(int((GameData.ENEMIES.get(boss, {}) as Dictionary).get("hp", 0)), last)
			print("   %4d  %-7s  %6d   %10d   %7d   %-15s %8d  %4d  %4d  %5d" % [year, GameData.SEASONS[s],
				nights, points, largest, boss, boss_hp, int(weather.get(Weather.FOG, 0)),
				int(weather.get(Weather.RAIN, 0)), int(weather.get(Weather.BLOOD_MOON, 0))])


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
