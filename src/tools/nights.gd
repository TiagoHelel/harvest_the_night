extends SceneTree

## Print the nights, without running one of them.
##
##     python tools/nights.py [how many nights] [seed]
##     python tools/nights.py --check
##
## **`--check` is a gate** (task 0151), run by `tools/verify.py`: every date of
## the year, 1 to `Calendar.year_days()`, for seeds 0 and 424242, resolves to
## a record and passes `GameData.check_nights` - the night length of 0137
## included - or it exits 1. It prints the year for seed 0 as it goes.
##
## Past the tenth it prints what `Endless` generates, which is how task 0070's
## curve was looked at while it was being written - `python tools/nights.py 40`
## shows where the Giants land and whether the mix is still varied at night
## forty. The seed only changes the order the waves arrive in, so a summary
## line looks the same for every seed; it is there so the tool can be pointed
## at a particular run.
##
## Everything here is read off `GameData.NIGHTS` through `Waves`, so the table
## is the only source: a designer who edits a wave sees it here on the next
## run without touching a line of code, which is the whole of task 0059.
##
## Without `--check` it is a **reader, not a check**. `GameData.validate()` is
## what fails loudly on a bad table and `headless_check` is what asserts the
## shape; this is for looking at the curve while you tune it, and task 0060
## will be looking at it a great deal.

## The seeds the year is checked for.
const CHECK_SEEDS: Array = [0, 424242]


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

	var authored := Waves.authored_count()
	var last := authored
	var seed_value := 0
	if args.size() > 0 and str(args[0]).is_valid_int():
		last = maxi(int(str(args[0])), 1)
	if args.size() > 1 and str(args[1]).is_valid_int():
		seed_value = int(str(args[1]))

	print("HARVEST THE NIGHT - the %d nights%s" % [last,
		"" if last <= authored
		else " (%d authored, the rest generated from seed %d)"
			% [authored, seed_value]])
	print("")

	var enemies := 0
	var money := 0
	var seen: Dictionary = {}
	# **Each night against the night** (task 0137): when its last member is
	# sent, and how long that leaves before dawn - which `check_nights` holds
	# at `DAWN_MARGIN_TICKS` or more.
	print("  dawn at %ds; every night must be sent %ds before it"
		% [GameData.NIGHT_TICKS / GameData.SECONDS,
			GameData.DAWN_MARGIN_TICKS / GameData.SECONDS])
	print("")
	for night in range(1, last + 1):
		var sent := Waves.schedule_ticks(Waves.night_of(night, seed_value))
		print("  %s   sent by %ds, %ds before dawn" % [Waves.summary_of(night, seed_value),
			sent / GameData.SECONDS, (GameData.NIGHT_TICKS - sent) / GameData.SECONDS])
		enemies += Waves.size_of(night, seed_value)
		money += Waves.reward_of(night, seed_value)
		for id in GameData.sorted_names(Waves.kinds_of(night,
				seed_value).keys()):
			if not seen.has(id):
				seen[id] = night

	print("")
	# **Worth, and what a night pays for it** (task 0219): the bounty is
	# `bounty_percent` of the kills' worth.
	print("  %d enemies over %d nights, worth $%d - a bounty of $%d at %d%%" % [enemies, last,
		money, money * int(GameData.REWARDS["bounty_percent"]) / 100,
		int(GameData.REWARDS["bounty_percent"])])

	# **What the run pays in technology**, which is the budget task 0063 has
	# to price the tech tree against: the floor is one a night for finishing,
	# the ceiling is every bonus every night.
	var bonuses: Array = []
	for row in GameData.TECH_BONUSES:
		bonuses.append("%s +%d" % [(row as Dictionary)["id"],
			int((row as Dictionary)["points"])])
	print("  technology: %d at worst, %d at best (%d a night, then %s)"
		% [Tech.least_available(), Tech.total_available(),
			int(GameData.REWARDS["tech_points"]), ", ".join(bonuses)])

	# **When each kind first turns up.** `design.md` section 10 wants one new
	# thing a night, and this is the line that shows whether it got one.
	var arrivals: Array = []
	for id in GameData.sorted_names(seen.keys()):
		arrivals.append("%s on %d" % [id, int(seen[id])])
	print("  first seen: " + ", ".join(arrivals))

	# The curve, as a shape rather than as numbers.
	print("")
	var widest := 1
	for night in range(1, last + 1):
		widest = maxi(widest, Waves.size_of(night, seed_value))
	for night in range(1, last + 1):
		var count := Waves.size_of(night, seed_value)
		var bar := "#".repeat(maxi(count * 40 / widest, 1))
		print("  %2d %-41s %3d%s" % [night, bar, count,
			"  <- %d Giant(s)" % Endless.giants_on(night)
			if Endless.giants_on(night) > 0 else ""])

	quit()


## **The year, as a gate.** Every date resolves to a record and the year's
## records pass `check_nights`, for each of `CHECK_SEEDS`. Returns the exit
## code: 0 clean, 1 with a line for every fault.
func _check_the_year() -> int:
	var days := Calendar.year_days()
	var faults: Array = []
	for seed_value in CHECK_SEEDS:
		var year: Array = []
		for date in range(1, days + 1):
			var one := Waves.night_of(date, int(seed_value))
			if one.is_empty():
				faults.append("seed %d: date %d has no night" % [seed_value, date])
			year.append(one)
			if int(seed_value) == 0:
				var sent := Waves.schedule_ticks(one)
				print("  %s   sent by %ds" % [Waves.summary_of(date, 0),
					sent / GameData.SECONDS])
		for line in GameData.check_nights(year):
			faults.append("seed %d: %s" % [seed_value, line])
	print("")
	for line in faults:
		print("  FAIL %s" % line)
	print("%d nights a year, seeds %s: %s" % [days, str(CHECK_SEEDS),
		"every one checks" if faults.is_empty() else "%d faults" % faults.size()])
	return 0 if faults.is_empty() else 1
