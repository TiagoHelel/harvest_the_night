extends SceneTree

## Print the ten nights, without running one of them.
##
## `python tools/nights.py`, or by hand:
##
##     godot --headless --script src/tools/nights.gd
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

	print("HARVEST THE NIGHT - the %d nights" % GameData.MVP_NIGHTS)
	print("")

	var enemies := 0
	var money := 0
	var seen: Dictionary = {}
	for night in range(1, GameData.MVP_NIGHTS + 1):
		print("  " + Waves.summary_of(night))
		enemies += Waves.size_of(night)
		money += Waves.reward_of(night)
		for id in GameData.sorted_names(Waves.kinds_of(night).keys()):
			if not seen.has(id):
				seen[id] = night

	print("")
	print("  %d enemies over %d nights, worth $%d"
		% [enemies, GameData.MVP_NIGHTS, money])

	# **When each kind first turns up.** `design.md` section 10 wants one new
	# thing a night, and this is the line that shows whether it got one.
	var arrivals: Array = []
	for id in GameData.sorted_names(seen.keys()):
		arrivals.append("%s on %d" % [id, int(seen[id])])
	print("  first seen: " + ", ".join(arrivals))

	# The curve, as a shape rather than as numbers.
	print("")
	var widest := 1
	for night in range(1, GameData.MVP_NIGHTS + 1):
		widest = maxi(widest, Waves.size_of(night))
	for night in range(1, GameData.MVP_NIGHTS + 1):
		var count := Waves.size_of(night)
		var bar := "#".repeat(maxi(count * 40 / widest, 1))
		print("  %2d %-41s %3d" % [night, bar, count])

	quit()
