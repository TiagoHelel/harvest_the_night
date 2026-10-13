class_name Collections
extends RefCounted

## **The four collections and the achievements** (task 0287): the plan's
## reason to start Year 2, kept in the profile across runs.
##
## ## In the shape of `Stats`: it reads, and banks
##
## Every page is a fact another module already counts:
## - **the fish** are 0182's book (`Stats.fish_known`, banked as
##   `lifetime.fish_book` by `Stats.fold`);
## - **the trophies** are the bosses killed, 0246's `killed_by_kind_all_run`
##   for every `is_boss` kind (banked as `lifetime.killed_by_kind`);
## - **the crops** are the harvests `Farming._harvest` counts in
##   `stats.harvested_by_crop` - not `gained`, which a purchase, a gift and
##   the loot land in too;
## - **the year** is a run that saw Winter 14's boss fall (0160) with no night
##   on which the house fell (`stats.nights_lost`; a boss walking off at dawn
##   is not one).
##
## The crops and the years are new to the profile, under `collections`, and
## `fold` adds them the way `Stats.fold` adds the rest: whatever of this run
## has not been banked (`stats.banked`), so folding twice adds nothing. It is
## called from inside `Stats.fold`, so every fold site gets it.
##
## ## The achievements
##
## `GameData.ACHIEVEMENTS`: each a pure test of the lifetime stats, the
## collections and this run's record (`earned`), the ones passed added to
## the profile's `achievements` at each fold and never taken away.


## Every species a page is kept for: the fish group's, in the book's order
## (the same list `FishBook.species` draws - the view's own, which core does
## not reach for).
static func fish_ids() -> Array:
	var out: Array = []
	for id in GameData.group_members(GameData.FISH):
		if GameData.FISH_SPECIES.has(id):
			out.append(StringName(id))
	return out


## Every crop a page is kept for, in the table's order.
static func crop_ids() -> Array:
	return GameData.sorted_names(GameData.CROPS.keys())


## Every boss a trophy is kept for, in the table's order.
static func boss_ids() -> Array:
	var out: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if Combat.is_boss(StringName(kind)):
			out.append(StringName(kind))
	return out


# -------------------------------------------------------------------- reading

## **The fish**, every run's: species -> landed.
static func fish(profile: Dictionary, state: Dictionary) -> Dictionary:
	return Stats.fish_known(profile, state)


## **The crops**, every run's: crop -> harvests - the profile's banked count
## and whatever this run has harvested since it was last folded.
static func crops(profile: Dictionary, state: Dictionary) -> Dictionary:
	var out: Dictionary = ((profile.get("collections", {}) as Dictionary)
		.get("crops", {}) as Dictionary).duplicate()
	if state.is_empty():
		return out
	var mine: Dictionary = state.get("stats", {})
	var was: Dictionary = (mine.get("banked", {}) as Dictionary).get("harvested_by_crop", {})
	var has: Dictionary = mine.get("harvested_by_crop", {})
	for crop in GameData.sorted_names(has.keys()):
		var fresh := int(has[crop]) - int(was.get(crop, 0))
		if fresh > 0:
			out[crop] = int(out.get(crop, 0)) + fresh
	return out


## **The trophies**, every run's: boss -> times it fell.
static func trophies(profile: Dictionary, state: Dictionary) -> Dictionary:
	var life: Dictionary = Stats.lifetime(profile)["killed_by_kind"]
	var was: Dictionary = {}
	var has: Dictionary = {}
	if not state.is_empty():
		was = ((state.get("stats", {}) as Dictionary).get("banked", {}) as Dictionary).get("killed_by_kind", {})
		has = state.get("killed_by_kind_all_run", {})
	var out := {}
	for boss in boss_ids():
		var count := int(life.get(boss, 0)) + maxi(int(has.get(boss, 0)) - int(was.get(boss, 0)), 0)
		if count > 0:
			out[boss] = count
	return out


## **The years** won without losing the house, every run's.
static func years(profile: Dictionary, state: Dictionary) -> int:
	var banked := int((profile.get("collections", {}) as Dictionary).get("years", 0))
	if state.is_empty():
		return banked
	var counted := bool(((state.get("stats", {}) as Dictionary).get("banked", {}) as Dictionary).get("year", false))
	return banked + (1 if year_earned(state) and not counted else 0)


## Whether this run has won the year without losing the house: Winter 14's
## boss down, and no night on which the house fell.
static func year_earned(state: Dictionary) -> bool:
	if state.is_empty() or not Run.beat_the_year(state):
		return false
	return int((state.get("stats", {}) as Dictionary).get("nights_lost", 0)) == 0


## The counts the screen's tabs carry: `{fish, crops, trophies, achievements}`
## as `[have, of]`, and `year` as the years won.
static func counts(profile: Dictionary, state: Dictionary) -> Dictionary:
	var landed := 0
	var book := fish(profile, state)
	for id in fish_ids():
		if int(book.get(id, 0)) > 0:
			landed += 1
	var grown := 0
	var field := crops(profile, state)
	for crop in crop_ids():
		if int(field.get(crop, 0)) > 0:
			grown += 1
	return {
		"fish": [landed, fish_ids().size()],
		"crops": [grown, crop_ids().size()],
		"trophies": [trophies(profile, state).size(), boss_ids().size()],
		"year": years(profile, state),
		"achievements": [(profile.get("achievements", {}) as Dictionary).size(),
			GameData.ACHIEVEMENTS.size()],
	}


# -------------------------------------------------------------------- banking

## Bank this run's crops and its year into the profile, and add every
## achievement passed. Called from `Stats.fold` on the profile it has just
## folded; returns it.
static func fold(profile: Dictionary, state: Dictionary) -> Dictionary:
	var out := profile
	var mine: Dictionary = state["stats"]
	var banked: Dictionary = mine["banked"]
	var shelf: Dictionary = (out.get("collections", {}) as Dictionary).duplicate(true)
	var field: Dictionary = shelf.get("crops", {})
	var was: Dictionary = banked.get("harvested_by_crop", {})
	var has: Dictionary = mine.get("harvested_by_crop", {})
	for crop in GameData.sorted_names(has.keys()):
		var fresh := int(has[crop]) - int(was.get(crop, 0))
		if fresh != 0:
			field[crop] = int(field.get(crop, 0)) + fresh
	banked["harvested_by_crop"] = has.duplicate()
	shelf["crops"] = field
	if year_earned(state) and not bool(banked.get("year", false)):
		shelf["years"] = int(shelf.get("years", 0)) + 1
		banked["year"] = true
	out["collections"] = shelf

	var badges: Dictionary = (out.get("achievements", {}) as Dictionary).duplicate()
	for id in earned(out, state):
		badges[id] = true
	out["achievements"] = badges
	return out


# ----------------------------------------------------------- the achievements

## **Which achievements this profile and run pass** (task 0287), in the
## table's order. `profile` is a folded one - its lifetime includes this run
## - and `state` is the run, for its own record.
static func earned(profile: Dictionary, state: Dictionary,
		table: Dictionary = GameData.ACHIEVEMENTS) -> Array:
	var out: Array = []
	for id in GameData.sorted_names(table.keys()):
		if passes(profile, state, table[id]):
			out.append(StringName(id))
	return out


## Whether one achievement's test holds.
static func passes(profile: Dictionary, state: Dictionary, one: Dictionary) -> bool:
	var n := int(one.get("n", 1))
	match StringName(one.get("kind", &"")):
		&"lifetime":
			return lifetime_number(profile, state, String(one.get("field", ""))) >= n
		&"run":
			if state.is_empty():
				return false
			return int(Stats.of_run(state).get(String(one.get("field", "")), 0)) >= n
		&"full_moon_held":
			var last: Dictionary = state.get("last_result", {})
			return not last.is_empty() and bool(last.get("survived", false)) \
				and Calendar.is_full_moon(int(last.get("night", 0)))
		&"legendary_landed":
			var book := fish(profile, state)
			for id in GameData.sorted_names(book.keys()):
				if int(book[id]) > 0 and Fishing.is_legendary(StringName(id)):
					return true
			return false
		&"built_every_defence":
			var built: Dictionary = Stats.lifetime(profile)["built_by_kind"]
			for id in GameData.sorted_names(GameData.DEFENCES.keys()):
				if int(built.get(id, 0)) <= 0:
					return false
			return true
		&"year_reached":
			return not state.is_empty() and Calendar.year_of(Calendar.date(state)) >= n
	return false


## One of the lifetime numbers an achievement may read.
static func lifetime_number(profile: Dictionary, state: Dictionary, field: String) -> int:
	var life := Stats.lifetime(profile)
	match field:
		"gathered":
			var sum := 0
			for id in GameData.sorted_names((life["gathered"] as Dictionary).keys()):
				sum += int(life["gathered"][id])
			return sum
		"fish":
			var landed := 0
			var book := fish(profile, state)
			for id in GameData.sorted_names(book.keys()):
				landed += int(book[id])
			return landed
		"runs_started":
			return int(life["runs_started"])
	return int(life.get(field, 0))
