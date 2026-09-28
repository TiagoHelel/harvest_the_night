extends SceneTree

## Print the ten nights, without running one of them.
##
##     python tools/nights.py [how many nights] [seed]
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
## It is a **reader, not a check**. `GameData.validate()` is what fails loudly
## on a bad table and `headless_check` is what asserts the shape; this is for
## looking at the curve while you tune it, and task 0060 will be looking at it
## a great deal.


func _init() -> void:
	var problems := GameData.validate()
	if not problems.is_empty():
		print("the tables do not validate:")
		for line in problems:
			print("  ", line)
		quit(1)
		return

	var last := GameData.MVP_NIGHTS
	var seed_value := 0
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and str(args[0]).is_valid_int():
		last = maxi(int(str(args[0])), 1)
	if args.size() > 1 and str(args[1]).is_valid_int():
		seed_value = int(str(args[1]))

	print("HARVEST THE NIGHT - the %d nights%s" % [last,
		"" if last <= GameData.MVP_NIGHTS
		else " (%d authored, the rest generated from seed %d)"
			% [GameData.MVP_NIGHTS, seed_value]])
	print("")

	var enemies := 0
	var money := 0
	var seen: Dictionary = {}
	for night in range(1, last + 1):
		print("  " + Waves.summary_of(night, seed_value))
		enemies += Waves.size_of(night, seed_value)
		money += Waves.reward_of(night, seed_value)
		for id in GameData.sorted_names(Waves.kinds_of(night,
				seed_value).keys()):
			if not seen.has(id):
				seen[id] = night

	print("")
	print("  %d enemies over %d nights, worth $%d" % [enemies, last, money])

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
