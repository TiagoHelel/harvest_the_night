extends SceneTree

## The rules of version 1.0, asserted with no window.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N asserts, M failed`, and it exits non-zero when M is not zero.
##
## **Every group from task 0112 on lives here.** `headless_check` holds the
## MVP's 103 groups (tasks 0002-0111) and was already spending some 74 of the
## 120 seconds verify gives a script when the 1.0 backlog was queued, with
## some 180 tasks still to come. Nothing moved across: the old groups stay
## where they are and this file starts empty, so a new rule never has to choose
## between being tested and the suite finishing.
##
## A plain helper a group here needs is **moved into `SuiteKit`**
## (`src/tools/suite_kit.gd`), never copied out of `headless_check`, so the two
## halves keep one idea of each fixture.
##
## **Defences are put down by night.** From task 0132 the rules refuse to
## place, upgrade or sell a defence by day; a group that needs one handles it
## in PREPARATION (`Phases.begin_preparation`) - the way task 0119 moves the
## old suites - never by day.
##
## ## Failing rather than hanging
##
## The same three guards as `headless_check`, for the same reason - GDScript
## has no exceptions, so a group that dies half way returns to its caller and
## the file would otherwise reach the end with a clean `0 failed`:
##
## 1. Each group increments `_completed` **as its last statement**, and
##    `_finish()` fails when fewer groups finished than `GROUPS` says exist.
## 2. `_process()` is a watchdog for an `_initialize()` that never returned.
## 3. `verify.py` bounds the whole run with a timeout.

## How long to wait before deciding `_initialize()` is never coming back.
const WATCHDOG_SECONDS := 5.0

## How many `_task_NNNN_*` groups `_run()` is expected to finish.
## **Adding a group means bumping this.**
const GROUPS := 53

const ActionsScript := preload("res://src/app/input_actions.gd")

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
var _elapsed := 0.0


func _initialize() -> void:
	_run()
	_finish()


## Reached only when `_initialize()` did not return - which in practice means a
## parse error in a script this one depends on, so `_run()` never started.
func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed < WATCHDOG_SECONDS:
		return false
	push_error("headless_v1: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: _initialize() never returned. Something it depends on ",
		"failed to parse - run: godot --headless --path . --check-only ",
		"--script res://src/tools/headless_v1.gd")
	_finish()
	return true


func _run() -> void:
	_task_0112_digest()
	_task_0113_repairs()
	_task_0114_untouched()
	_task_0115_spawn_room()
	_task_0116_ammo()
	_task_0118_road()
	_task_0120_placeholders()
	_task_0121_pad()
	_task_0126_clock()
	_task_0127_bed()
	_task_0128_pass_out()
	_task_0129_asleep()
	_task_0131_guardian()
	_task_0132_night_build()
	_task_0134_cursor_repair()
	_task_0135_aimed_flare()
	_task_0136_start()
	_task_0137_dawn()
	_task_0138_morning()
	_task_0140_bedtime()
	_task_0141_tutorial()
	_task_0149_calendar()
	_task_0150_lookup()
	_task_0151_migration()
	_task_0152_full_moon()
	_task_0153_boss_nights()
	_task_0154_calm()
	_task_0155_losing()
	_task_0156_map_v1()
	_task_0157_sides()
	_task_0158_forecast()
	_task_0159_palette()
	_task_0160_year_end()
	_task_0165_days()
	_task_0166_long_day()
	_task_0167_till_grass()
	_task_0168_crops()
	_task_0169_inventory()
	_task_0170_seasons()
	_task_0171_winter()
	_task_0172_regrow()
	_task_0173_tools()
	_task_0174_area()
	_task_0175_swings()
	_task_0176_ores()
	_followup_0176_review()
	_task_0177_hardwood()
	_task_0178_sprinklers()
	_task_0179_species()
	_task_0180_minigame()
	_task_0181_rods()
	_task_0182_legendary()
	_task_0183_barns()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _completed < GROUPS:
		failed += 1
		print("  FAIL  a check group did not finish   %d of %d completed"
			% [_completed, GROUPS])
	print("%d asserts, %d failed" % [passed + failed, failed])
	quit(1 if failed > 0 else 0)


## One assertion. A failure prints the values, because "false" on its own has
## never once been enough to fix anything.
func expect(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL  ", what, "  ", detail)


# ------------------------------------------------------------------ the groups

## 0112 - every table in `GameData` is either in the data hash or says why not.
func _task_0112_digest() -> void:
	# **The DATA guard only sees what `digest()` names.** A table added to
	# `game_data.gd` and not to the digest can be rebalanced with the guard
	# perfectly quiet - which is the one thing it exists to stop, and the
	# 1.0 backlog adds dozens of tables. So the file is read as text, every
	# top-level `const` whose value is an Array or Dictionary literal is
	# collected, and each one must be named in `digest()` or exempted here
	# with a reason. Scalar consts are not this group's business.
	var exempt := {
		"TARGETING": "derived enum list: the names DEFENCES entries pick from",
		"SHAPES": "derived enum list: the names DEFENCES entries pick from",
		"AIMS": "derived enum list: the names DEFENCES entries pick from",
		"DAMAGE_TYPES": "derived enum list: the names DEFENCES entries pick from",
		"NEIGHBOUR_STEPS": "geometry helper: the four steps of a grid, not design",
	}
	var source := FileAccess.get_file_as_string("res://src/core/game_data.gd")
	var at := source.find("\nstatic func digest()")
	expect(not source.is_empty(), "game_data.gd is there to read")
	expect(at >= 0, "and it has a digest()")
	if source.is_empty() or at < 0:
		_completed += 1
		return

	# The body of `digest()`: everything indented under it, comments cut,
	# because "they are not in `NIGHTS`" is not `NIGHTS` being hashed.
	var body := ""
	for line in source.substr(at + 1).split("\n").slice(1):
		if not line.is_empty() and not line.begins_with("\t") \
				and not line.begins_with(" "):
			break
		var comment := line.find("#")
		body += (line.substr(0, comment) if comment >= 0 else line) + "\n"

	var table := RegEx.create_from_string(
		"^const\\s+([A-Z][A-Z0-9_]*)\\s*(?::[^=]*)?=\\s*[\\[{]")
	var tables: Array = []
	for line in source.split("\n"):
		var m := table.search(line)
		if m != null:
			tables.append(m.get_string(1))
	# The reader itself, checked on tables it must find: an untyped
	# Dictionary, an untyped Array and a typed one.
	for known in ["CROPS", "NIGHTS", "NEIGHBOUR_STEPS"]:
		expect(tables.has(known), "the reader finds %s" % known, str(tables))

	var missing: Array = []
	for name in tables:
		if exempt.has(name):
			continue
		var named := RegEx.create_from_string("\\b%s\\b" % name)
		if named.search(body) == null:
			missing.append(name)
	expect(missing.is_empty(),
		"every table const is in GameData.digest() or exempted with a reason",
		"not hashed: %s" % ", ".join(missing))

	# And the exemptions do not rot: each still names a table, and one that
	# has since joined the digest has no business being excused from it.
	for name in exempt:
		expect(tables.has(name), "exemption %s still names a table" % name)
		expect(RegEx.create_from_string("\\b%s\\b" % name).search(body) == null,
			"exemption %s is not also in the digest" % name)
	_completed += 1


## 0113 - a repair puts back what the thing really has when it is whole.
func _task_0113_repairs() -> void:
	# **The house, raised by 'stout timbers'.** It used to mend to the base
	# 100 and stop, so forty of its hit points could only ever be lost.
	var state := State.create(113113)
	var house: Vector2i = Farm.cells_with(state, &"house")[0]
	(state["tech_owned"] as Array).append(&"stout timbers")
	var full := Phases.house_full(state)
	expect(full == GameData.HOUSE_HP + 40, "stout timbers makes the house 140",
		str(full))
	Resources.gain(state, {GameData.FOOD: 500, GameData.WOOD: 500})
	state["house_hp"] = GameData.HOUSE_HP
	expect(Repair.needs_repair(state, house),
		"a house at its old 100 of 140 is a house that wants mending")
	expect(Interact.verb_at(state, house) == &"repair",
		"and the farmer is offered the verb, which follows by itself",
		str(Interact.verb_at(state, house)))
	state["house_hp"] = full - 50
	var back := Repair.apply_all(state, house)
	expect(back == 50, "90 of 140 mends by exactly 50", str(back))
	expect(int(state["house_hp"]) == full, "back to 140, not 100",
		str(state["house_hp"]))
	expect(not Repair.needs_repair(state, house), "and then wants nothing")
	expect(Interact.verb_at(state, house) != &"repair",
		"and stops offering to be mended")

	# **A level three gun tower.** Placed and upgraded twice in PREPARATION,
	# the way 0132 will still allow it, with the defence branch owned.
	var towers := State.create(113114)
	(towers["tech_owned"] as Array).append_array(
		[&"true sights", &"oiled works"])
	Resources.gain(towers, {GameData.WOOD: 500, GameData.STONE: 500,
		GameData.IRON: 500, GameData.GUNPOWDER: 500, GameData.FOOD: 500})
	Phases.begin_preparation(towers)
	var top := SuiteKit.any_buildable(towers)
	expect(Building.place(towers, &"gun_tower", top), "a gun tower goes down",
		str(top))
	expect(Building.upgrade(towers, top) and Building.upgrade(towers, top),
		"and goes up twice", str(Building.level_at(towers, top)))
	var low := SuiteKit.any_buildable(towers)
	expect(Building.place(towers, &"gun_tower", low), "a level one beside it",
		str(low))
	var top_full := Repair.full_hp_at(towers, top)
	var base_hp := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])
	expect(top_full == 120 and base_hp == 60,
		"level three has 120 to the table's 60", "%d, %d" % [top_full, base_hp])
	var on := Farm.occupant(towers, top)
	on["hp"] = top_full / 2
	expect(Repair.damage_at(towers, top) == top_full / 2,
		"60 of 120 is 60 missing, not none", str(Repair.damage_at(towers, top)))
	expect(Repair.apply_all(towers, top) == top_full / 2
		and int(on["hp"]) == top_full, "and it is mended to 120",
		str(on["hp"]))
	var plain := Farm.occupant(towers, low)
	plain["hp"] = base_hp / 2
	Repair.apply_all(towers, low)
	expect(int(plain["hp"]) == base_hp, "a level one still stops at its 60",
		str(plain["hp"]))

	# **One full mend costs REPAIR_PERCENT of the build, at any level.** The
	# price is shared over the levelled maximum, so a level three's hit point
	# is cheaper and the whole of it costs the same - its own wood and iron,
	# not the gunpowder that bought the level.
	var build: Dictionary = (GameData.DEFENCES[&"gun_tower"] as Dictionary)["cost"]
	for cell in [top, low]:
		var bill := Repair.cost_at(towers, cell, Repair.full_hp_at(towers, cell))
		for res in GameData.sorted_names(build.keys()):
			var fair := int(build[res]) * GameData.REPAIR_PERCENT / 100
			expect(int(bill.get(res, 0)) <= fair and int(bill.get(res, 0)) >= fair - 1,
				"a full mend at level %d costs %d%% of the build in %s"
				% [Building.level_at(towers, cell), GameData.REPAIR_PERCENT, res],
				"%d against %d" % [int(bill.get(res, 0)), fair])
		expect(not bill.has(GameData.GUNPOWDER), "and no gunpowder", str(bill))

	# **'A full larder' discounts the house too.** Its note promises mending
	# two fifths cheaper, with no exception, and it is on the house's branch.
	var larder := State.create(113115)
	var door: Vector2i = Farm.cells_with(larder, &"house")[0]
	var plain_rate := Repair.per_hp_hundredths(larder, door)
	(larder["tech_owned"] as Array).append(&"a full larder")
	var cheap_rate := Repair.per_hp_hundredths(larder, door)
	var pct := Tech.bonus(larder, "repair_percent", 100)
	expect(pct == 60, "the larder's lever is 60 percent", str(pct))
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		var base := int(GameData.REPAIR_COST_PER_HP[res]) \
			* GameData.HOUSE_REPAIR_PERCENT
		expect(int(plain_rate[res]) == base,
			"without the larder the house pays its full rate in %s" % res,
			str(plain_rate))
		expect(int(cheap_rate[res]) == base * pct / 100,
			"with it, two fifths less in %s" % res, str(cheap_rate))
	var note := ""
	for row in GameData.TECH_TREE:
		if StringName((row as Dictionary)["id"]) == &"a full larder":
			note = String((row as Dictionary).get("note", ""))
	expect(note.contains("mending") and not note.contains("house"),
		"and the note promises every mend, the house's included", note)
	_completed += 1


## 0114 - "how whole is the house" is asked of the house the night started
## with, not of the base 100.
func _task_0114_untouched() -> void:
	# **Only two places may name the base number.** `Phases.house_full()` is
	# the answer and `Farm.initial()` is a new run's house, before any tree;
	# everything else asks `house_full`, or 'stout timbers' quietly stops
	# counting somewhere. Read as text, the way `_task_0095_controls` scans
	# for raw keys.
	var allowed := ["res://src/core/phases.gd", "res://src/core/farm.gd"]
	var base := RegEx.create_from_string("\\bHOUSE_HP\\b")
	var naming: Array = []
	for folder in ["res://src/core", "res://src/ui"]:
		for file in DirAccess.get_files_at(folder):
			if not String(file).ends_with(".gd") or file == "game_data.gd":
				continue
			var path: String = String(folder).path_join(file)
			for line in SuiteKit.code_lines_of(path).split("\n"):
				var code := String(line)
				var comment := code.find("#")
				if comment >= 0:
					code = code.substr(0, comment)
				if base.search(code) != null:
					naming.append(path)
					break
	for path in allowed:
		expect(naming.has(path), "the scan still sees %s" % path, str(naming))
	var stray: Array = naming.filter(func(p: String) -> bool:
		return not allowed.has(p))
	expect(stray.is_empty(),
		"no rule or screen measures the house against the base HOUSE_HP",
		str(stray))

	# **The untouched bonus, both halves.** With 'stout timbers' a night that
	# ends at 120 of 140 lost twenty: no money for it and no tech point.
	for row in [[120, false], [140, true]]:
		var night := State.create(114114)
		(night["tech_owned"] as Array).append(&"stout timbers")
		var full := Phases.house_full(night)
		expect(full == 140, "stout timbers makes the house 140", str(full))
		night["house_hp"] = int(row[0])
		var tech := Tech.would_pay(night, int(night["night"]))
		var paid := Rewards.settle(night, true)
		var money := int((paid["money_from"] as Dictionary)["the house untouched"])
		var want := bool(row[1])
		expect((money == int(GameData.REWARDS["house_untouched_bonus"])) == want
			and (money == 0) != want,
			"%d of 140 %s the 'house untouched' money"
				% [int(row[0]), "pays" if want else "does not pay"], str(money))
		expect(tech.has(&"house untouched") == want,
			"and %s the 'house untouched' tech point"
				% ("earns" if want else "does not earn"), str(tech))

	# **The skip refusal reads the same share.** 75 of 140 is 53 percent, over
	# `SKIP_MIN_HOUSE_PERCENT`; 65 of 140 is 46, under it - and the refusal
	# says 46, which against the base 100 it would have called 65.
	var skip := State.create(114115)
	(skip["tech_owned"] as Array).append(&"stout timbers")
	skip["phase"] = Phases.NIGHT
	skip["house_hp"] = 75
	expect(Sim.why_not_skip(skip).is_empty(), "75 of 140 may be skipped",
		str(Sim.why_not_skip(skip)))
	skip["house_hp"] = 65
	expect(Sim.why_not_skip(skip) == [&"WHY_HOUSE_LOW", 46],
		"65 of 140 is refused at 46 percent", str(Sim.why_not_skip(skip)))

	# And the HUD's fraction comes off the same number.
	skip["house_hp"] = 70
	expect(is_equal_approx(Enemies.house_fraction(skip), 0.5),
		"70 of 140 is half a house", str(Enemies.house_fraction(skip)))
	_completed += 1


## 0115 - a spawn line cannot be built shut.
func _task_0115_spawn_room() -> void:
	# **The suspicion, measured before the fix**: ten fences on the east line
	# and night 1 sent none of its twelve walkers - `Enemies.spawn` found no
	# free cell, returned 0, and `Waves.tick` counted them as sent anyway.
	var seed_value := 115
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 5000, GameData.STONE: 5000})
	Phases.begin_preparation(state)
	var east := _spawn_line(0)
	var fenced := 0
	for cell in east:
		if Building.place(state, &"fence", cell):
			fenced += 1
	expect(fenced == east.size(), "the whole east line fences over in PREPARATION",
		"%d of %d" % [fenced, east.size()])

	# A sealed line answers the free ground beyond it, never the line itself
	# and never a cell nearer the house than the line cell it is beside.
	# A copy: the stream is an Array, held by reference.
	var rng_before: Array = (state["rng"] as Array).duplicate()
	var options := Enemies.spawn_cells(state, 0)
	expect(state["rng"] == rng_before, "asking where draws nothing from the run")
	expect(not options.is_empty(), "a sealed line still has somewhere to stand",
		str(options))
	var beyond := true
	for cell in options:
		var c: Vector2i = cell
		var nearest := 1 << 30
		for line_cell in east:
			if Grid.chebyshev(c, line_cell) <= 1:
				nearest = mini(nearest, Pathing.distance(state, line_cell))
		if east.has(c) or not Farm.walkable(state, c) \
				or not Pathing.reachable(state, c) \
				or Pathing.distance(state, c) <= nearest:
			beyond = false
	expect(beyond, "every one of them free, reachable and beyond the fence",
		str(options))

	# **The night accounts for every member** and ends: killed, breached,
	# alive or still to come adds up to the night's size.
	var guard := 0
	while int(state["phase"]) != Phases.NIGHT and guard < 2000:
		# The build step waits for START since task 0136.
		if int(state["phase"]) == Phases.PREPARATION:
			NightRoad.press_start(state)
		Sim.tick(state)
		guard += 1
	expect(int(state["phase"]) == Phases.NIGHT, "night falls")
	state["house_hp"] = 100000      # so the night is won, and ends by the rule
	var size := Waves.size_of(1, seed_value)
	var limit := 20000
	var ticks := 0
	while int(state["phase"]) == Phases.NIGHT and ticks < limit:
		Sim.tick(state)
		ticks += 1
	expect(int(state["phase"]) != Phases.NIGHT,
		"and ends within %d ticks" % limit, str(ticks))
	var to_come := Waves.remaining(state) - Entities.count(state)
	var counted := int(state["killed"]) + int(state["breaches"]) \
		+ Entities.count(state) + to_come
	expect(counted == size, "killed + breached + alive + to come = the night",
		"%d + %d + %d + %d against %d" % [int(state["killed"]),
			int(state["breaches"]), Entities.count(state), to_come, size])
	expect(int(state["next_entity_id"]) - 1 == size,
		"and every member was actually placed", str(int(state["next_entity_id"]) - 1))

	# **The south east line too**, seven cells.
	var south := State.create(1151)
	Resources.gain(south, {GameData.WOOD: 5000, GameData.STONE: 5000})
	Phases.begin_preparation(south)
	var line := _spawn_line(1)
	var sealed := 0
	for cell in line:
		if Building.place(south, &"fence", cell):
			sealed += 1
	var there := Enemies.spawn_cells(south, 1)
	expect(sealed == line.size() and not there.is_empty()
		and there.all(func(c: Vector2i) -> bool: return not line.has(c)),
		"a sealed south east line answers the ground beside it",
		"%d sealed, %s" % [sealed, str(there)])

	# **Part blocked is not sealed.** Nine of ten fenced: only the tenth.
	var part := State.create(1152)
	Resources.gain(part, {GameData.WOOD: 5000, GameData.STONE: 5000})
	Phases.begin_preparation(part)
	for cell in east.slice(0, east.size() - 1):
		Building.place(part, &"fence", cell)
	var last: Vector2i = east[east.size() - 1]
	var left := Enemies.spawn_cells(part, 0)
	expect(left == [last], "nine fenced leaves exactly the tenth to stand on",
		str(left))

	# **A save with a region already sealed** answers by the same rule: the
	# rule is in the code, not in a key.
	var loaded: Dictionary = bytes_to_var(var_to_bytes(state))
	var fresh := State.create(seed_value)
	Resources.gain(fresh, {GameData.WOOD: 5000, GameData.STONE: 5000})
	Phases.begin_preparation(fresh)
	for cell in east:
		Building.place(fresh, &"fence", cell)
	var saved: Dictionary = bytes_to_var(var_to_bytes(fresh))
	expect(Enemies.spawn_cells(saved, 0) == Enemies.spawn_cells(fresh, 0)
		and State.reconcile(loaded).is_empty(),
		"a saved sealed farm spawns where the live one does")
	_completed += 1


## The cells of one `GameData.SPAWNS` region.
func _spawn_line(where: int) -> Array:
	var out: Array = []
	for entry in (GameData.SPAWNS[where] as Array):
		out.append(Vector2i(int(entry[0]), int(entry[1])))
	return out


## 0116 - the mortar and the flamethrower, empty and upgraded.
func _task_0116_ammo() -> void:
	# **An empty mortar throws a rock at somebody.** Through `Towers.tick`,
	# the real path: placed in PREPARATION, the powder gone, a walker standing
	# beyond `min_range`. It used to land on its cell with nobody to hit.
	var empty := _tower_night(1161, &"mortar", [])
	var mortar: Dictionary = GameData.DEFENCES[&"mortar"]
	Resources.spend(empty["state"], GameData.GUNPOWDER,
		Resources.amount(empty["state"], GameData.GUNPOWDER))
	var at: Vector2i = empty["tower"]
	var one := Entities.spawn(empty["state"], &"walker", at + Vector2i(6, 0))
	var two := Entities.spawn(empty["state"], &"walker", at + Vector2i(6, 1))
	# Which one it throws at is the tower's own rule (nearest the house);
	# the other stands one tile off the aimed cell.
	var walker := Towers.target_of(empty["state"], at)
	var beside := two if walker == one else one
	expect(walker == one or walker == two, "the mortar picks one of them",
		str(walker))
	var hp := int(Entities.get_one(empty["state"], walker)["hp"])
	var fired := false
	for _i in 300:
		Towers.tick(empty["state"])
		if Towers.shots_fired(empty["state"]) > 0:
			fired = true
		if fired and Towers.in_flight(empty["state"]) == 0:
			break
	var weak := Ammo.weak_damage(int(mortar["damage"]))
	expect(weak == 12, "an empty mortar's rock is 40 -> 12 at 30 percent",
		str(weak))
	var took := hp - int(Entities.get_one(empty["state"], walker).get("hp", 0))
	expect(fired and took == weak, "and it takes 12 off the walker it was thrown at",
		"took %d, fired %s" % [took, fired])
	expect(int(Entities.get_one(empty["state"], beside)["hp"]) == hp,
		"and nothing off the one beside it - a rock does not splash")

	# **The cone reaches what 'long barrels' lets it aim at.** With the tree
	# the tower picks a target at range + 1; the cone used to stop at range,
	# spend the round and burn nobody.
	var far := _tower_night(1162, &"flame_tower", [&"true sights", &"long barrels"])
	var flame: Dictionary = GameData.DEFENCES[&"flame_tower"]
	var reach := Towers.reach_of(far["state"], flame)
	expect(reach == int(flame["range"]) + 1, "long barrels: one tile further",
		str(reach))
	var out_there := Entities.spawn(far["state"], &"walker",
		(far["tower"] as Vector2i) + Vector2i(reach, 0))
	Towers.tick(far["state"])
	expect(int(Entities.get_one(far["state"], out_there)["hp"]) == hp
		- Towers.damage_of(far["state"], flame),
		"the cone burns a walker at range + 1",
		str(Entities.get_one(far["state"], out_there)["hp"]))

	# **And hits as hard as 'true sights' says**: on the level-3 row, 5 -> 6.
	# Level one's 3 is 3.6, which integer arithmetic rounds back to 3.
	var hot := _tower_night(1163, &"flame_tower", [&"true sights"])
	var cell: Vector2i = hot["tower"]
	Farm.occupant(hot["state"], cell)["level"] = 3
	var top := Building.entry_at(hot["state"], cell)
	var tough := Entities.spawn(hot["state"], &"walker", cell + Vector2i(1, 0))
	Entities.get_one(hot["state"], tough)["hp"] = 1000
	Towers.tick(hot["state"])
	expect(int(top["damage"]) == 5 and Towers.damage_of(hot["state"], top) == 6,
		"level three's 5 is 6 with true sights", str(top["damage"]))
	expect(1000 - int(Entities.get_one(hot["state"], tough)["hp"]) == 6,
		"and the cone deals the 6",
		str(1000 - int(Entities.get_one(hot["state"], tough)["hp"])))
	var alight: Dictionary = (hot["state"]["burning"] as Dictionary).get(tough, {})
	expect(int(alight.get("damage", -1)) == int(top["burn_damage"]),
		"the burn is the fire's own number, not scaled by the tree",
		"%s against %d" % [str(alight), int(top["burn_damage"])])
	expect(Towers.damage_of(hot["state"], flame) == 3,
		"level one's 3 rounds back to 3")

	# **A round per two seconds of flame, not per cone.** Ten seconds of
	# firing on a full pool: five rounds, where it used to be one a shot.
	var long := _tower_night(1164, &"flame_tower", [])
	var pool := Resources.amount(long["state"], GameData.INCENDIARY)
	var held := Entities.spawn(long["state"], &"walker",
		(long["tower"] as Vector2i) + Vector2i(1, 0))
	Entities.get_one(long["state"], held)["hp"] = 1000000
	var version := int(long["state"]["grid_version"])
	var lit_key := false
	for i in 10 * GameData.TICK_HZ:
		Towers.tick(long["state"])
		if i == 0:
			lit_key = Farm.occupant(long["state"], long["tower"]).has("ammo_lit")
	var spent := pool - Resources.amount(long["state"], GameData.INCENDIARY)
	var every := int(flame["ammo_every_ticks"])
	expect(spent == 10 * GameData.TICK_HZ / every,
		"ten seconds of flame burn five rounds, not twenty",
		"%d rounds for %d shots" % [spent, Towers.shots_fired(long["state"])])
	expect(Towers.shots_fired(long["state"]) > spent * 3,
		"while the cone still goes off twice a second",
		str(Towers.shots_fired(long["state"])))
	expect(lit_key and int(long["state"]["grid_version"]) == version,
		"the countdown is on the occupant and never touches the farm")

	# **An old save has no countdown** and simply lights its next round.
	var old := _tower_night(1165, &"flame_tower", [])
	var target := Entities.spawn(old["state"], &"walker",
		(old["tower"] as Vector2i) + Vector2i(1, 0))
	Entities.get_one(old["state"], target)["hp"] = 1000000
	var before := Resources.amount(old["state"], GameData.INCENDIARY)
	Towers.tick(old["state"])
	Farm.occupant(old["state"], old["tower"]).erase("ammo_lit")
	Farm.occupant(old["state"], old["tower"])["reload"] = 0
	Towers.tick(old["state"])
	expect(before - Resources.amount(old["state"], GameData.INCENDIARY) == 2,
		"a tower loaded without the key pays for a fresh round",
		str(before - Resources.amount(old["state"], GameData.INCENDIARY)))

	# **The table is checked at boot.** A cadence with no rounds, or shorter
	# than a reload, is refused; the real table passes.
	var no_rounds := GameData.check_defences({&"test_tower": {"cost": {},
		"damage": 1, "range": 2, "reload_ticks": 15, "ammo_every_ticks": 60}})
	var too_quick := GameData.check_defences({&"test_tower": {"cost": {},
		"damage": 1, "range": 2, "reload_ticks": 15, "ammo_every_ticks": 10,
		"ammo": {GameData.INCENDIARY: 1}}})
	expect(str(no_rounds).contains("fires no rounds"),
		"a round-cadence on a tower without rounds is refused", str(no_rounds))
	expect(str(too_quick).contains("sooner than it fires"),
		"and one quicker than its reload", str(too_quick))
	expect(GameData.check_defences(GameData.DEFENCES).is_empty(),
		"while the real table passes", str(GameData.check_defences(GameData.DEFENCES)))
	_completed += 1


## A tower of `id` put down in PREPARATION with the given tree, its pools full.
## Returns the state and the tower's cell.
func _tower_night(seed_value: int, id: StringName, techs: Array) -> Dictionary:
	var state := State.create(seed_value)
	(state["tech_owned"] as Array).append_array(techs)
	Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900,
		GameData.IRON: 900, GameData.OIL: 900, GameData.GUNPOWDER: 900,
		GameData.INCENDIARY: 100})
	Phases.begin_preparation(state)
	var cell := SuiteKit.any_buildable(state)
	expect(Building.place(state, id, cell), "a %s goes down" % id, str(cell))
	return {"state": state, "tower": cell}


## 0118 - one road into the waves.
func _task_0118_road() -> void:
	# **Read the code, not the hope.** The build step's length and the door
	# into the night may only be named by `NightRoad` and the core; a test
	# that starts a night by hand would be one more line for 0136 and 0137 to
	# find. The needles are built in pieces so this file is not one of them.
	var timer := "PREPARATION" + "_TICKS"
	var door := "Phases.begin" + "_night("
	var lever := RegEx.create_from_string("\\b" + timer + "\\b")
	# **Allowed nowhere** since task 0136: the build step waits for START,
	# and its lever left `GameData`.
	var allowed := {}
	var timers: Array = []
	var doors: Array = []
	var seen := {}
	for folder in ["res://src/tools", "res://src/ui"]:
		for file in DirAccess.get_files_at(folder):
			if not String(file).ends_with(".gd"):
				continue
			var path: String = String(folder).path_join(file)
			var where := ""
			for line in SuiteKit.code_lines_of(path).split("\n"):
				var code := String(line)
				if code.begins_with("func "):
					where = code.trim_prefix("func ").get_slice("(", 0)
				var comment := code.find("#")
				if comment >= 0:
					code = code.substr(0, comment)
				# A whole word: PASS_OUT_PREPARATION_TICKS (0128) is not the lever.
				if lever.search(code) != null:
					if allowed.has(path) or allowed.has(path + ":" + where):
						seen[path] = true
					else:
						timers.append("%s:%s" % [path, where])
				if code.contains(door):
					doors.append("%s:%s" % [path, where])
	expect(not FileAccess.get_file_as_string("res://src/core/game_data.gd")
		.contains("const " + timer), "the build step's lever is gone from GameData")
	expect(seen.is_empty(), "and nothing is allowed to name it", str(seen.keys()))
	expect(timers.is_empty(),
		"nothing in src/tools or src/ui names the build step's length but the road",
		str(timers))
	expect(doors.is_empty(),
		"and nothing outside src/core opens the night by hand", str(doors))

	# **The door refuses every other phase, and changes nothing doing it.**
	var day := State.create(1181)
	var before := State.hash_of(day)
	expect(not Phases.start_waves(day) and State.hash_of(day) == before,
		"start_waves from the day is refused and leaves the day alone")
	var night := State.create(1182)
	expect(NightRoad.to_night(night) and int(night["phase"]) == Phases.NIGHT,
		"the road leads into the night")
	var during := State.hash_of(night)
	expect(not Phases.start_waves(night) and State.hash_of(night) == during,
		"and start_waves during it is refused and leaves it alone")

	# **The road is START** (task 0136): on a fresh build step it presses it
	# and steps the tick it lands on - the same as doing it by hand.
	var counted := State.create(1183)
	Phases.begin_preparation(counted)
	(counted["intent"] as Dictionary)["start_waves"] = true
	Sim.tick(counted)
	var by_hand := 1
	var fresh := State.create(1183)
	NightRoad.into_build(fresh)
	var tick := int(fresh["tick"])
	var left := NightRoad.build_ticks_left(fresh)
	NightRoad.through_build(fresh)
	expect(int(fresh["tick"]) - tick == left and left == by_hand
		and int(fresh["phase"]) == Phases.NIGHT
		and State.hash_of(fresh) == State.hash_of(counted),
		"a fresh build step is START and one tick, ending in the night",
		"%d ticks, %d left at the start" % [int(fresh["tick"]) - tick, left])
	expect(NightRoad.build_ticks_left(fresh) == 0, "and nothing is left of it")

	# The night runner stops when the night does, and the park holds one open.
	var parked := State.create(1184)
	NightRoad.to_night(parked)
	NightRoad.park(parked)
	expect(NightRoad.run_night(parked, 300) == 300
		and int(parked["phase"]) == Phases.NIGHT,
		"a parked night is still a night when the runner's cap comes")
	_completed += 1


## 0120 - one road for art that has not arrived.
func _task_0120_placeholders() -> void:
	# **Every entry resolves through the lookup** to a texture whose size and
	# pivot are the entry's: the stand-in sits in the box the real art will.
	var wrong: Array = []
	var resolved := 0
	for name in GameData.sorted_names(PlaceholderArt.POSES.keys()):
		var entry: Dictionary = PlaceholderArt.POSES[name]
		var shape: Dictionary = entry["geometry"]
		for i in int(entry["frames"]):
			var path := "%s%s_%d.png" % [PlaceholderArt.DIR, name, i]
			var answer := PlaceholderArt.frame(path)
			var file := PlaceholderArt.texture_path(path)
			var texture: Texture2D = load(file) if ResourceLoader.exists(file) else null
			var real: Dictionary = RasterArt.FRAMES.get(file, {})
			if answer.is_empty() or texture == null \
					or Vector2i(texture.get_size()) != shape["canvas"] \
					or answer["pivot"] != shape["pivot"] \
					or real.get("pivot", Vector2i(-1, -1)) != shape["pivot"] \
					or not is_equal_approx(float(real.get("draw_scale", 1.0)),
						float(shape["draw_scale"])):
				wrong.append(path)
			else:
				resolved += 1
	expect(resolved > 0 and wrong.is_empty(),
		"every stand-in frame loads at its entry's canvas, pivot and scale",
		"%d resolved, wrong: %s" % [resolved, str(wrong.slice(0, 4))])
	expect(PlaceholderArt.frame("res://sprites/actors/walk_south_0.png")
		== RasterArt.FRAMES["res://sprites/actors/walk_south_0.png"],
		"real art answers from RasterArt first")
	expect(PlaceholderArt.frame("res://sprites/actors/nobody_0.png").is_empty()
		and not PlaceholderArt.has_frame("res://sprites/actors/run_south_8.png"),
		"and a path nobody knows answers nothing")

	# **The farmer's road** answers a registered name the way PlayerFrames
	# answers a real one.
	var sleep := PlayerArt.animation(&"bed_sleep")
	expect(int(sleep.get("frames", 0)) == 2
		and is_equal_approx(float(sleep.get("seconds", 0.0)), 0.8),
		"bed_sleep: two frames at 0.8 s, from the registry", str(sleep))
	expect(PlayerArt.texture_path(&"bed_sleep", 0)
		== PlayerArt.texture_path(&"idle_south", 0),
		"and its frame 0 is the idle's texture", PlayerArt.texture_path(&"bed_sleep", 0))
	# **Retired by the owner on 2026-10-08**: A006's run (the farmer does not
	# run) and A001's waking and collapse. Nothing registers them now.
	var retired: Array = []
	for name in [&"run_south", &"run_north_east", &"bed_wake", &"pass_out_south",
			&"pass_out_east"]:
		if not PlayerArt.animation(name).is_empty() or PlaceholderArt.has_pose(name):
			retired.append(name)
	expect(retired.is_empty(), "the run, the waking and the collapse are retired",
		str(retired))
	var walk := PlayerArt.animation(&"walk_south")
	expect(int(walk.get("frames", 0)) == int(PlayerFrames.COUNT[&"walk_south"]),
		"a real animation still answers from PlayerFrames", str(walk))
	expect(PlayerArt.animation(&"nobody").is_empty(), "and an unknown one, nothing")
	# Nothing asks for the stand-ins yet: the run is still the walk, faster.
	var running := PlayerArt.pose(Player.SOUTH, true, &"", true)
	expect(running["name"] == &"walk_south"
		and is_equal_approx(float(running["seconds"]), PlayerArt.RUN_FRAME_SECONDS),
		"the run key plays walk_<dir>, faster - there is no run art", str(running))
	var chopping := PlayerArt.pose(Player.WEST, false, &"chop")
	expect(chopping["name"] == &"chop" and int(chopping["frames"]) == 4,
		"and the legacy <verb> strips for work", str(chopping))

	# **One lookup.** No file in src/ui/ but the registry reads the generated
	# table directly.
	var readers: Array = []
	for file in DirAccess.get_files_at("res://src/ui"):
		if not String(file).ends_with(".gd") or file == "placeholder_art.gd":
			continue
		var code := SuiteKit.code_lines_of("res://src/ui".path_join(file))
		if code.contains("RasterArt.FRAMES"):
			readers.append(file)
	expect(readers.is_empty(), "only the lookup reads RasterArt.FRAMES in src/ui",
		str(readers))
	_completed += 1


## 0121 - a controller for every action.
func _task_0121_pad() -> void:
	# **Every action has a pad event in project.godot**, but the ones named
	# here, each with why.
	var no_pad := {
		&"slot_1": "seeds by day, the hotbar's slots at night: the bumpers cycle the hotbar on a pad (task 0133)",
		&"slot_2": "the seed slots: see slot_1",
		&"slot_3": "the seed slots: see slot_1",
		&"slot_4": "the seed slots: see slot_1",
		&"slot_5": "the seed slots: see slot_1",
		&"slot_6": "the seed slots: see slot_1",
		&"slot_7": "the hotbar's slots: see slot_1",
		&"slot_8": "the hotbar's slots: see slot_1",
		&"place": "A confirms at the cursor at night (task 0133): RT went to the flare",
		&"run": "presentation only - the farmer walks the same - and LT went to upgrade (task 0133)",
		&"speed": "a night bar button: Back puts the pad on the bar and A presses it (task 0139)",
		&"skip_night": "a night bar button, like speed",
		&"stats": "a read-only screen no play depends on, and no button left over",
		&"log": "a read-only screen, like stats",
		&"tech": "L3 went to START (task 0136); a screen reached by its key - the night bar has no TECH, the tree only changes by day",
	}
	var project := FileAccess.get_file_as_string("res://project.godot")
	var section := project.substr(project.find("\n[input]\n"))
	section = section.substr(0, section.find("\n[", 2))
	var shared := {}
	var missing: Array = []
	var stale: Array = []
	for action in ActionsScript.names():
		var at := section.find("\n%s={" % action)
		var block := section.substr(at, section.find("\n}", at) - at) if at >= 0 else ""
		var has_pad := block.contains("InputEventJoypad")
		if not has_pad and not no_pad.has(action):
			missing.append(action)
		if has_pad and no_pad.has(action):
			stale.append(action)
		# What each pad event is, so two actions cannot ship on one button.
		for piece in block.split("Object(InputEventJoypad").slice(1):
			var head := String(piece).get_slice(",\"script\"", 0)
			var mark := head.get_slice("\"device\":-1,", 1)
			shared[mark] = (shared.get(mark, []) as Array) + [action]
	expect(missing.is_empty(), "every action has a pad event, or is named with why",
		str(missing))
	expect(stale.is_empty(), "and no named exception has one after all", str(stale))
	var doubled: Array = []
	for mark in shared:
		if (shared[mark] as Array).size() > 1:
			doubled.append(shared[mark])
	expect(not shared.is_empty() and doubled.is_empty(),
		"no two actions ship on one pad input", str(doubled))

	# **Every pad name label_of can say is in the table**, in both languages.
	var table := FileAccess.get_file_as_string("res://assets/locale/strings.csv")
	var keys: Array = ActionsScript.PAD_NAMES.values() + ActionsScript.AXIS_NAMES.values()
	keys.append(&"ACT_PAD_OTHER")
	var absent: Array = []
	for key in keys:
		if not table.contains("\n%s," % key):
			absent.append(key)
	expect(absent.is_empty(), "every ACT_PAD_* name is in the strings table", str(absent))
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = 1.0
	expect(ActionsScript.label_of(a) == I18n.t(&"ACT_PAD_A")
		and ActionsScript.label_of(trigger) == I18n.t(&"ACT_PAD_LT"),
		"and label_of reads them", "%s, %s" % [ActionsScript.label_of(a),
			ActionsScript.label_of(trigger)])

	# **A pad binding is written and read back like a key.**
	expect(ActionsScript.as_text(a) == "joy:0" and ActionsScript.as_text(trigger) == "axis:4:1",
		"pad events are written joy: and axis:",
		"%s, %s" % [ActionsScript.as_text(a), ActionsScript.as_text(trigger)])
	expect(ActionsScript.same_event(ActionsScript.from_text("joy:0"), a)
		and ActionsScript.same_event(ActionsScript.from_text("axis:4:1"), trigger),
		"and read back the same")
	expect(ActionsScript.from_text("axis:4:3") == null and ActionsScript.from_text("joy:x") == null,
		"a malformed pad binding reads as nothing")
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.2
	expect(ActionsScript.is_bindable(a) and ActionsScript.is_bindable(trigger)
		and not ActionsScript.is_bindable(drift),
		"pad buttons and pushed sticks can be bound, a drifting stick cannot")

	# **No screen names a pad button by its constant**: they read actions.
	var raw: Array = []
	for file in DirAccess.get_files_at("res://src/ui"):
		if not String(file).ends_with(".gd"):
			continue
		var code := SuiteKit.code_lines_of("res://src/ui".path_join(file))
		if code.contains("JOY_"):
			raw.append(file)
	expect(raw.is_empty(), "no code line in src/ui names a JOY_ constant", str(raw))
	_completed += 1


## 0126 - the clock: 06:00 to 02:00.
func _task_0126_clock() -> void:
	var state := State.create(1261)
	var at := func(day_tick: int) -> int:
		state["day_tick"] = day_tick
		return Phases.clock_minute(state)
	expect(at.call(0) == 6 * 60, "06:00 at tick 0", str(at.call(0)))
	expect(at.call(GameData.DAY_TICKS / 2) == 16 * 60, "16:00 half way",
		str(at.call(GameData.DAY_TICKS / 2)))
	expect(at.call(GameData.DUSK_AT_TICK) == 18 * 60, "18:00 at dusk",
		str(at.call(GameData.DUSK_AT_TICK)))
	expect(at.call(GameData.DAY_TICKS) == 26 * 60, "02:00 at the end of the day",
		str(at.call(GameData.DAY_TICKS)))

	# The inverse holds on every minute boundary, and each minute is the same
	# whole number of ticks.
	var span := GameData.DAY_END_MINUTE - GameData.DAY_START_MINUTE
	var per := GameData.DAY_TICKS / span
	var drift: Array = []
	for t in range(0, GameData.DAY_TICKS + 1, per):
		if Phases.tick_at_minute(at.call(t)) != t:
			drift.append(t)
	expect(per * span == GameData.DAY_TICKS and drift.is_empty(),
		"tick_at_minute undoes clock_minute on every minute",
		"%d per minute, off at %s" % [per, str(drift.slice(0, 4))])

	# Dusk reads the hour, and the old tick still agrees with it.
	state["phase"] = Phases.DAY
	state["day_tick"] = GameData.DUSK_AT_TICK - 1
	var before := Phases.is_dusk(state)
	state["day_tick"] = GameData.DUSK_AT_TICK
	expect(not before and Phases.is_dusk(state), "dusk falls on the dusk minute")
	expect(GameData.DUSK_AT_TICK == Phases.tick_at_minute(GameData.DUSK_MINUTE),
		"and DUSK_AT_TICK is derived from it", str(GameData.DUSK_AT_TICK))

	# **The check refuses a clock that is not a clock.**
	expect(GameData.check_clock(GameData.DAY_START_MINUTE, GameData.DUSK_MINUTE,
		GameData.DAY_END_MINUTE, GameData.DAY_TICKS).is_empty(), "today's clock passes")
	expect(not GameData.check_clock(6 * 60, 27 * 60, 26 * 60, GameData.DAY_TICKS).is_empty(),
		"a dusk after the end of the day is refused")
	expect(not GameData.check_clock(6 * 60, 18 * 60, 26 * 60, GameData.DAY_TICKS + 1).is_empty(),
		"and so is a day that is not a whole number of ticks per minute")

	# **The HUD line is 24-hour HH:MM, wrapping after midnight.**
	var late := 25 * 60 + 30
	var line := I18n.f(&"DHUD_CLOCK", [(late / 60) % 24, late % 60])
	expect(line.contains("01:30") and not line.contains("25:30"),
		"01:30, never 25:30", line)
	var morning := I18n.f(&"DHUD_CLOCK", [6, 0])
	expect(morning.contains("06:00"), "and 06:00 with its zero", morning)
	_completed += 1


## 0127 - going to bed starts the night.
func _task_0127_bed() -> void:
	# **The intent**: the GO TO BED button's road.
	var by_button := State.create(1271)
	(by_button["intent"] as Dictionary)["sleep"] = true
	Sim.advance(by_button, 1)
	expect(int(by_button["phase"]) == Phases.PREPARATION
		and House.asleep(by_button) and not House.inside(by_button),
		"the sleep intent lands in the build step, asleep and not inside",
		Phases.name_of(int(by_button["phase"])))

	# **The bed**: indoors, beside it, interact.
	var by_bed := State.create(1272)
	SuiteKit.stand_the_farmer(by_bed, House.porch(by_bed))
	expect(House.enter(by_bed), "the farmer walks into the house")
	var side := Vector2i(-1, -1)
	for y in range(3, House.ROOM.y - 1):
		for x in range(1, House.ROOM.x - 1):
			if side.x < 0 and House.bedside(Vector2i(x, y)):
				side = Vector2i(x, y)
	expect(side.x >= 0, "there is floor beside the bed", str(side))
	SuiteKit.stand_the_farmer(by_bed, side)
	expect(House.can_sleep(by_bed), "and standing there offers bed")
	(by_bed["intent"] as Dictionary)["interact"] = true
	Sim.advance(by_bed, 2)
	expect(int(by_bed["phase"]) == Phases.PREPARATION
		and House.asleep(by_bed) and not House.inside(by_bed),
		"interact by the bed lands in the build step, asleep and not inside",
		Phases.name_of(int(by_bed["phase"])))
	var far := State.create(1273)
	SuiteKit.stand_the_farmer(far, House.porch(far))
	House.enter(far)
	SuiteKit.stand_the_farmer(far, House.SPAWN + Vector2i(-3, -1))
	expect(not House.can_sleep(far), "but not from across the room")

	# **Refused in PREPARATION, NIGHT and RESULT**, both roads, nothing changed.
	print("  (the ERROR lines below are deliberate - refused bedtimes)")
	var late := State.create(1274)
	NightRoad.into_build(late)
	for phase in [Phases.PREPARATION, Phases.NIGHT, Phases.RESULT]:
		if phase == Phases.NIGHT:
			NightRoad.through_build(late)
			NightRoad.park(late)
		elif phase == Phases.RESULT:
			Phases.enter_result(late, true)
		var hash_before := State.hash_of(late)
		var refused := not Phases.go_to_bed(late)
		expect(refused and State.hash_of(late) == hash_before
			and int(late["phase"]) == phase,
			"going to bed is refused in %s and changes nothing" % Phases.name_of(phase))
		(late["intent"] as Dictionary)["sleep"] = true
		expect(not House.can_sleep(late), "and the bed offers nothing in %s"
			% Phases.name_of(phase))
	Phases.begin_day(late)
	expect(int(late["phase"]) == Phases.DAY and not House.asleep(late)
		and not bool((late["intent"] as Dictionary)["sleep"]),
		"the morning wakes him and forgets a bedtime asked for after dark")

	# **The early-sleep rule**: the skipped hours are neither lived nor
	# credited. A queue started at 09:00 and slept on keeps its progress and
	# is not finished overnight.
	var early := State.create(1275)
	SuiteKit.reach_day_tick(early, Phases.tick_at_minute(9 * 60))
	Resources.gain(early, {GameData.WOOD: 20})
	var bench := Building.anchor_of(early, Farm.cells_with(early, &"workshop")[0])
	expect(Crafting.start(early, bench, &"fence_kit"), "a fence kit goes on at 09:00")
	Sim.advance(early, 60)
	var kits := Crafting.kits(early, &"fence")
	var left := int(Crafting.progress_at(early, bench)[0])
	(early["intent"] as Dictionary)["sleep"] = true
	Sim.advance(early, 1)
	NightRoad.through_build(early)
	Phases.enter_result(early, true)
	Phases.begin_day(early)
	expect(int(Crafting.progress_at(early, bench)[0]) == left and left > 0,
		"slept on, the job keeps the progress it had", "%d against %d"
			% [int(Crafting.progress_at(early, bench)[0]), left])
	expect(Crafting.kits(early, &"fence") == kits,
		"and nothing was made overnight", str(Crafting.kits(early, &"fence")))
	_completed += 1


## 0128 - passing out at 02:00.
func _task_0128_pass_out() -> void:
	# **Written near the end rather than played.** Still the day one tick
	# before 02:00; asleep and passed out on it.
	var late := State.create(1281)
	late["day_tick"] = GameData.DAY_TICKS - 2
	var tree: Vector2i = Farm.cells_with(late, &"tree")[0]
	(late["player"] as Dictionary)["action"] = {"verb": &"chop",
		"cell": [tree.x, tree.y], "left": 30, "total": 60}
	Sim.advance(late, 1)
	expect(int(late["phase"]) == Phases.DAY and int(late["day_tick"]) == GameData.DAY_TICKS - 1,
		"still the day at DAY_TICKS - 1", Phases.name_of(int(late["phase"])))
	Sim.advance(late, 1)
	var visit: Dictionary = late["house_visit"]
	expect(int(late["phase"]) == Phases.PREPARATION and bool(visit["asleep"])
		and bool(visit["passed_out"]),
		"at 02:00 he passes out into the build step", str(visit))
	expect(not Player.is_busy(late), "whatever he was doing stops")
	var logged := false
	for event in (late["events"] as Array):
		if StringName((event as Dictionary).get("kind", &"")) == &"passed_out":
			logged = true
	expect(logged, "and the log says why the build step is short")
	expect(Phases.clock_minute(late) == GameData.DAY_END_MINUTE,
		"the clock stopped at 02:00", str(Phases.clock_minute(late)))

	# **The short build step**, then the waves through the one door.
	Sim.advance(late, GameData.PASS_OUT_PREPARATION_TICKS - 1)
	expect(int(late["phase"]) == Phases.PREPARATION,
		"one tick short of the pass-out build step it is still building")
	Sim.advance(late, 1)
	expect(int(late["phase"]) == Phases.NIGHT,
		"and after exactly PASS_OUT_PREPARATION_TICKS it is night",
		Phases.name_of(int(late["phase"])))

	# **Indoors too.**
	var indoors := State.create(1282)
	SuiteKit.stand_the_farmer(indoors, House.porch(indoors))
	House.enter(indoors)
	indoors["day_tick"] = GameData.DAY_TICKS - 1
	Sim.advance(indoors, 1)
	expect(int(indoors["phase"]) == Phases.PREPARATION and not House.inside(indoors)
		and bool((indoors["house_visit"] as Dictionary)["passed_out"]),
		"a farmer indoors at 02:00 passes out too")

	# **Going to bed at 01:59 is an ordinary night.**
	var bedtime := State.create(1283)
	bedtime["day_tick"] = GameData.DAY_TICKS - 1
	(bedtime["intent"] as Dictionary)["sleep"] = true
	Sim.advance(bedtime, 1)
	expect(int(bedtime["phase"]) == Phases.PREPARATION
		and not bool((bedtime["house_visit"] as Dictionary)["passed_out"])
		and Phases.build_step_ticks(bedtime) == 0,
		"going to bed at 01:59 is an ordinary night, whose build step waits for START")

	# **The clock and the overtime stop at 02:00.**
	var clamp := State.create(1284)
	clamp["day_tick"] = GameData.DAY_TICKS + 900
	expect(Phases.clock_minute(clamp) == GameData.DAY_END_MINUTE
		and Phases.overtime_percent(clamp) == 100,
		"no day runs past 02:00, on the clock or in the overtime",
		"%d, %d%%" % [Phases.clock_minute(clamp), Phases.overtime_percent(clamp)])

	# The morning clears it.
	NightRoad.park(late)
	Phases.enter_result(late, true)
	Phases.begin_day(late)
	expect(not bool((late["house_visit"] as Dictionary)["passed_out"])
		and not House.asleep(late), "and the morning clears both")
	_completed += 1


## 0129 - he stays in bed all night.
func _task_0129_asleep() -> void:
	# **Move and interact held for 600 ticks of the build step**, then START,
	# then 600 ticks of the night (parked, so nothing bites): nothing about
	# him changes. The build step waits for START since task 0136.
	var state := State.create(1291)
	NightRoad.into_build(state)
	var before: Array = (state["player"]["pos"] as Array).duplicate()
	var facing := Player.facing(state)
	var intent: Dictionary = state["intent"]
	var phases_seen := {}
	for leg in 2:
		if leg == 1:
			NightRoad.through_build(state)
			NightRoad.park(state)
		for _tick in 600:
			phases_seen[int(state["phase"])] = true
			(intent["move"] as Array)[0] = 1
			(intent["move"] as Array)[1] = -1
			intent["interact"] = true
			intent["interact_held"] = true
			intent["cancel"] = true
			Sim.advance(state, 1)
		var after: Array = state["player"]["pos"]
		expect(after == before and Player.facing(state) == facing
			and not Player.is_busy(state),
			"%s: 600 ticks of move and interact leave him where he lay"
				% ["the build step", "the night"][leg],
			"%s to %s, facing %d to %d" % [before, after, facing, Player.facing(state)])
	expect(phases_seen.has(Phases.PREPARATION) and phases_seen.has(Phases.NIGHT)
		and int(state["phase"]) == Phases.NIGHT,
		"and that was the build step and the night", str(phases_seen.keys()))
	expect(not bool(intent["interact"]) and not bool(intent["cancel"]),
		"the edges are consumed, not left for the morning")

	# **The flare goes off without him, where it is aimed** (task 0135; 0129
	# put it on the house centre until the cursor could aim it).
	expect(Ability.ready(state), "the flare is charged at night")
	var house := Farm.house_centre(state) + Vector2i(2, 3)
	intent["ability_cell"] = [house.x, house.y]
	intent["ability"] = true
	Sim.advance(state, 1)
	expect(Ability.flare_at(state) == [house.x, house.y],
		"a flare lands on the aimed cell", str(Ability.flare_at(state)))

	# **REPAIR without him**: `repair_cell` on the house, in the build step.
	var mend := State.create(1292)
	NightRoad.into_build(mend)
	house = Farm.house_centre(mend)
	mend["house_hp"] = Phases.house_full(mend) - 40
	Resources.gain(mend, {GameData.FOOD: 400, GameData.WOOD: 400,
		GameData.STONE: 400, GameData.IRON: 400})
	var hurt := int(mend["house_hp"])
	var will := Repair.max_affordable(mend, house)
	var bill := Repair.cost_at(mend, house, will)
	var held: Dictionary = (mend["held"] as Dictionary).duplicate()
	(mend["intent"] as Dictionary)["repair_cell"] = [house.x, house.y]
	Sim.advance(mend, 1)
	expect(will > 0 and int(mend["house_hp"]) == hurt + will,
		"repair_cell on a damaged house mends it",
		"%d + %d, now %d" % [hurt, will, int(mend["house_hp"])])
	var charged := {}
	for id in GameData.sorted_names(held.keys()):
		var spent := int(held[id]) - Resources.amount(mend, id)
		if spent != 0:
			charged[id] = spent
	var billed := {}
	for id in GameData.sorted_names(bill.keys()):
		if int(bill[id]) != 0:
			billed[id] = int(bill[id])
	expect(charged == billed and not billed.is_empty(),
		"and charges what Repair.cost_at says", "%s against %s" % [charged, billed])
	expect((mend["intent"] as Dictionary)["repair_cell"] == [-1, -1],
		"the edge is consumed")

	# **Broke**: nothing at all changes.
	var broke := State.create(1293)
	NightRoad.into_build(broke)
	NightRoad.through_build(broke)
	NightRoad.park(broke)
	house = Farm.house_centre(broke)
	broke["house_hp"] = Phases.house_full(broke) - 40
	for id in GameData.sorted_names((broke["held"] as Dictionary).keys()):
		(broke["held"] as Dictionary)[id] = 0
	var hp_broke := int(broke["house_hp"])
	var debt: Dictionary = (Repair.banked(broke) as Dictionary).duplicate()
	(broke["intent"] as Dictionary)["repair_cell"] = [house.x, house.y]
	Sim.advance(broke, 1)
	expect(int(broke["house_hp"]) == hp_broke and Repair.banked(broke) == debt,
		"and changes nothing when the ledger cannot pay",
		"%d to %d" % [hp_broke, int(broke["house_hp"])])

	# **By day it is not his to use**: the edge is a night control.
	var day := State.create(1294)
	house = Farm.house_centre(day)
	day["house_hp"] = Phases.house_full(day) - 40
	Resources.gain(day, {GameData.FOOD: 400, GameData.WOOD: 400})
	var hp_day := int(day["house_hp"])
	(day["intent"] as Dictionary)["repair_cell"] = [house.x, house.y]
	Sim.advance(day, 1)
	expect(int(day["house_hp"]) == hp_day
		and (day["intent"] as Dictionary)["repair_cell"] == [-1, -1],
		"by day repair_cell is dropped unread")
	_completed += 1


## 0131 - the porch guardian and the cursor's registry.
func _task_0131_guardian() -> void:
	# **The guardian's cell is never buildable** on a new farm, by day or in
	# the build step, with the means to build anything.
	for seed_value in [1311, 1312, 1313]:
		var state := State.create(seed_value)
		var cell := GuardianView.cell_of(state)
		var house := Farm.house_bounds(state)
		expect(Grid.in_bounds(cell) and house.has_point(cell) and cell != House.porch(state),
			"seed %d: the guardian stands in the house's footprint, beside the door" % seed_value,
			"%s in %s" % [cell, house])
		expect(not Farm.buildable(state, cell),
			"seed %d: the guardian's cell is never buildable" % seed_value, str(cell))
		Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900,
			GameData.IRON: 900, GameData.GUNPOWDER: 900})
		NightRoad.into_build(state)
		var refused := 0
		for id in GameData.sorted_names(GameData.DEFENCES.keys()):
			if not Building.why_not(state, id, cell).is_empty():
				refused += 1
		expect(refused == GameData.DEFENCES.size(),
			"seed %d: and nothing can be built there in the build step" % seed_value,
			"%d of %d refused" % [refused, GameData.DEFENCES.size()])

	# **Its eyes**: none by day, two at night, on its own lit frames' points.
	var watch := State.create(1314)
	expect(GuardianView.eyes(watch).is_empty(), "by day the guardian's eyes are shut")
	NightRoad.into_build(watch)
	var eyes := GuardianView.eyes(watch)
	var feet := GuardianView.feet_of(watch)
	expect(eyes.size() == 2 and eyes[0].x < eyes[1].x
		and eyes[0].y < feet.y and eyes[0].distance_to(feet) < 48.0,
		"at night two lit eyes, in its head", "%s, feet %s" % [str(eyes), feet])

	# **The registry** (0120's road): the four guardian states and the seven
	# cursor looks, drawn by code in their packs' boxes; lit frames carry the
	# emission points and the unlit ones do not.
	var wrong: Array = []
	var mine := 0
	for name in GameData.sorted_names(PlaceholderArt.ART.keys()):
		var entry: Dictionary = PlaceholderArt.ART[name]
		if not ["A003", "A004"].has(entry["pack"]):
			continue       # A005's icons are 0133's to check
		mine += 1
		var shape: Dictionary = entry["geometry"]
		for i in int(entry["frames"]):
			var path := PlaceholderArt.art_path(name, i)
			var answer := PlaceholderArt.frame(path)
			var lit := entry.has("lights") and i >= int(entry.get("lit_from", 0))
			if not PlaceholderArt.has_frame(path) or not PlaceholderArt.is_drawn(path) \
					or answer.get("canvas") != shape["canvas"] \
					or answer.get("pivot") != shape["pivot"] \
					or answer.has("lights") != lit:
				wrong.append(path)
	expect(mine == 11 and wrong.is_empty(),
		"the guardian's four states and the cursor's seven looks are registered",
		"%d entries, wrong: %s" % [mine, str(wrong.slice(0, 4))])
	for look in GuardianCursor.LOOKS:
		expect(PlaceholderArt.ART.has(StringName("cursor_%s" % look)),
			"the cursor's '%s' look is registered" % look)
	expect(PlaceholderArt.frame(PlaceholderArt.art_path(&"guardian_day", 0)).get("lights", []).is_empty()
		and not PlaceholderArt.frame(PlaceholderArt.art_path(&"guardian_wake", 0)).has("lights")
		and PlaceholderArt.frame(PlaceholderArt.art_path(&"guardian_wake", 1)).has("lights"),
		"the eyes light on the second frame of the wake, not before")
	expect(GameData.CURSOR_REPEAT_RATE > 0.0
		and GameData.CURSOR_REPEAT_RATE < GameData.CURSOR_REPEAT_DELAY,
		"a held cursor repeats faster than it waits to start")

	# **What the cursor says**, read-only: open ground, a wall, an enemy.
	var said := State.create(1315)
	NightRoad.into_build(said)
	var before := State.hash_of(said)
	var ground := SuiteKit.any_buildable(said)
	expect(Describe.under_cursor(said, ground) == I18n.t(&"CURSOR_GROUND"),
		"over an empty cell it says open ground", Describe.under_cursor(said, ground))
	Resources.gain(said, {GameData.WOOD: 400, GameData.STONE: 400})
	Building.place(said, &"wall", ground)
	Farm.damage(said, ground, 7)
	var full := Repair.full_hp_at(said, ground)
	var wall_text := Describe.under_cursor(said, ground)
	expect(wall_text.contains(Names.of(&"wall").to_upper())
		and wall_text.contains("%d/%d" % [full - 7, full]),
		"over a wall it says the wall and its hit points against its maximum", wall_text)
	var near := ground + Vector2i(0, 1) if Grid.in_bounds(ground + Vector2i(0, 1)) else ground - Vector2i(0, 1)
	var one := Entities.spawn(said, &"walker", near)
	var walker_text := Describe.under_cursor(said, near)
	expect(walker_text.contains(Names.of(&"walker").to_upper())
		and walker_text.contains(str(int(Entities.get_one(said, one)["hp"]))),
		"over an enemy it says the enemy and its hit points", walker_text)
	var house_text := Describe.under_cursor(said, Farm.house_centre(said))
	expect(house_text.contains(I18n.t(&"CURSOR_HOUSE")),
		"and over the farmhouse, the farmhouse", house_text)
	var again := State.hash_of(said)
	Describe.under_cursor(said, ground)
	GuardianView.eyes(said)
	expect(State.hash_of(said) == again and before != 0,
		"asking what is under the cursor changes nothing")
	_completed += 1


## 0132 - defences go down only at night, buildings only by day.
func _task_0132_night_build() -> void:
	# **Every defence: refused by day with the night's reason, taken in the
	# build step and the night. Every building the other way round.** A
	# fresh, rich farm per phase, and a clear spot sized to the thing.
	var plenty := {GameData.WOOD: 9000, GameData.STONE: 9000, GameData.IRON: 9000,
		GameData.OIL: 9000, GameData.GUNPOWDER: 9000, GameData.MONEY: 9000,
		GameData.FOOD: 9000, GameData.COPPER: 9000, GameData.GOLD: 9000}
	var phases := {}
	for phase in [Phases.DAY, Phases.PREPARATION, Phases.NIGHT]:
		var state := State.create(1320)
		Resources.gain(state, plenty)
		if phase != Phases.DAY:
			NightRoad.into_build(state)
		if phase == Phases.NIGHT:
			NightRoad.through_build(state)
			NightRoad.park(state)
		phases[phase] = state
	var wrong: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		for phase in phases:
			var state: Dictionary = phases[phase]
			var reason := Building.why_not(state, id, _clear_for(state, id))
			var ok: bool = reason.is_empty() if phase != Phases.DAY \
				else (not reason.is_empty() and reason[0] == &"WHY_ONLY_AT_NIGHT")
			if not ok:
				wrong.append("%s in %s: %s" % [id, Phases.name_of(phase), str(reason)])
	for id in GameData.sorted_names(GameData.BUILDINGS.keys()):
		for phase in phases:
			var state: Dictionary = phases[phase]
			var reason := Building.why_not(state, id, _clear_for(state, id))
			var ok: bool = reason.is_empty() if phase == Phases.DAY \
				else (not reason.is_empty() and reason[0] == &"WHY_NOT_AT_NIGHT")
			if not ok:
				wrong.append("%s in %s: %s" % [id, Phases.name_of(phase), str(reason)])
	expect(wrong.is_empty(),
		"every defence only at night and every building only by day, with the reason",
		str(wrong.slice(0, 4)))
	expect(Building.catalogue(phases[Phases.DAY]) == GameData.sorted_names(GameData.BUILDINGS.keys())
		and Building.catalogue(phases[Phases.NIGHT]) == GameData.sorted_names(GameData.DEFENCES.keys()),
		"by day the palette holds the buildings, at night the defences",
		"%s / %s" % [Building.catalogue(phases[Phases.DAY]), Building.catalogue(phases[Phases.NIGHT])])

	# **Upgrade and sell follow**, and a tower goes up a level mid-wave -
	# through the intent the guardian's cursor writes.
	var fight := State.create(1321)
	Resources.gain(fight, plenty)
	Resources.gain(fight, {GameData.TECH: 40})
	Tech.buy(fight, &"true sights")
	NightRoad.into_build(fight)
	var tower := _clear_for(fight, &"gun_tower")
	expect(Building.place(fight, &"gun_tower", tower), "a gun tower goes down in the build step")
	NightRoad.through_build(fight)
	NightRoad.park(fight)
	var intent: Dictionary = fight["intent"]
	intent["build_cell"] = [tower.x, tower.y]
	intent["build_upgrade"] = true
	Sim.advance(fight, 1)
	expect(int(fight["phase"]) == Phases.NIGHT and Building.level_at(fight, tower) == 2,
		"and goes up a level mid-wave, through build_upgrade at the cursor",
		str(Building.level_at(fight, tower)))
	var bench := Building.anchor_of(fight, Farm.cells_with(fight, &"workshop")[0])
	expect(Building.why_not_sell(fight, bench) == [&"WHY_NOT_AT_NIGHT"]
		and Building.sell(fight, bench).is_empty(),
		"a workshop is not sold after dark", str(Building.why_not_sell(fight, bench)))
	Phases.enter_result(fight, true)
	Phases.begin_day(fight)
	expect(Building.why_not_upgrade(fight, tower) == [&"WHY_ONLY_AT_NIGHT"],
		"by day the tower goes up no level", str(Building.why_not_upgrade(fight, tower)))
	intent["build_cell"] = [tower.x, tower.y]
	intent["build_sell"] = true
	Sim.advance(fight, 1)
	expect(StringName(Farm.occupant(fight, tower).get("id", &"")) == &"gun_tower"
		and Building.why_not_sell(fight, tower) == [&"WHY_ONLY_AT_NIGHT"],
		"and is not sold by day", str(Building.why_not_sell(fight, tower)))
	expect(Building.why_not_sell(fight, bench).is_empty(), "while the workshop could be")

	# **The barricade**: still limited per night, and a build-step one counts
	# against tonight's limit; its lifetime starts with the waves.
	var bar: Dictionary = GameData.DEFENCES[&"barricade"]
	var limit := int(bar["per_night_limit"])
	var life := int(bar["lifetime_ticks"])
	var cheap := State.create(1322)
	Resources.gain(cheap, plenty)
	NightRoad.into_build(cheap)
	var first := _clear_for(cheap, &"barricade")
	expect(Building.place(cheap, &"barricade", first), "a barricade goes down in the build step")
	expect(Building.left_tonight(cheap, &"barricade") == limit - 1,
		"and counts against tonight's limit", str(Building.left_tonight(cheap, &"barricade")))
	# Longer than its lifetime: the build step has no clock (task 0136).
	Sim.advance(cheap, life + 30)
	expect(int(cheap["phase"]) == Phases.PREPARATION
		and StringName(Farm.occupant(cheap, first).get("id", &"")) == &"barricade",
		"it does not rot while the build step lasts")
	NightRoad.through_build(cheap)
	NightRoad.park(cheap)
	expect(Building.left_tonight(cheap, &"barricade") == limit - 1,
		"the waves do not hand the allowance back", str(Building.left_tonight(cheap, &"barricade")))
	var placed := 1
	for _i in limit + 2:
		if Building.place(cheap, &"barricade", _clear_for(cheap, &"barricade")):
			placed += 1
	expect(placed == limit, "exactly the limit, build step and night together", str(placed))
	Sim.advance(cheap, life - 2)
	expect(StringName(Farm.occupant(cheap, first).get("id", &"")) == &"barricade",
		"the build-step barricade stands for its lifetime after the waves begin")
	Sim.advance(cheap, 4)
	expect(Farm.occupant(cheap, first).is_empty(), "and then takes itself away",
		str(Farm.occupant(cheap, first)))
	_completed += 1


## The first spot on the farm where `id`'s whole footprint is clear ground,
## counting from the middle out so it is near the action.
func _clear_for(state: Dictionary, id: StringName) -> Vector2i:
	var middle := Vector2i(GameData.GRID_WIDTH / 2, GameData.GRID_HEIGHT / 2)
	for radius in maxi(GameData.GRID_WIDTH, GameData.GRID_HEIGHT):
		for cell in Grid.within(middle, radius):
			var clear := true
			for at in Building.footprint(id, cell):
				if not Farm.why_not_buildable(state, at).is_empty():
					clear = false
					break
			if clear:
				return cell
	return Vector2i(-1, -1)


## 0134 - repairs at night by the cursor, and the farmer's verb off defences.
func _task_0134_cursor_repair() -> void:
	var plenty := {GameData.WOOD: 900, GameData.STONE: 900, GameData.IRON: 900,
		GameData.GUNPOWDER: 900, GameData.FOOD: 900}
	# **A damaged gun tower, mended through `repair_cell` at night, costs
	# exactly `Repair.cost_at`.**
	var night := State.create(1340)
	Resources.gain(night, plenty)
	NightRoad.into_build(night)
	var tower := _clear_for(night, &"gun_tower")
	expect(Building.place(night, &"gun_tower", tower), "a gun tower goes down")
	NightRoad.through_build(night)
	NightRoad.park(night)
	Farm.damage(night, tower, 30)
	var hurt := int(Farm.occupant(night, tower)["hp"])
	var will := Repair.max_affordable(night, tower)
	var bill := Repair.cost_at(night, tower, will)
	var held: Dictionary = (night["held"] as Dictionary).duplicate()
	(night["intent"] as Dictionary)["repair_cell"] = [tower.x, tower.y]
	Sim.advance(night, 1)
	expect(will == 30 and int(Farm.occupant(night, tower)["hp"]) == hurt + will,
		"repair_cell mends the tower all the way", "%d + %d" % [hurt, will])
	var charged := {}
	for id in GameData.sorted_names(held.keys()):
		var spent := int(held[id]) - Resources.amount(night, id)
		if spent != 0:
			charged[id] = spent
	var billed := {}
	for id in GameData.sorted_names(bill.keys()):
		if int(bill[id]) != 0:
			billed[id] = int(bill[id])
	expect(charged == billed, "and costs exactly Repair.cost_at",
		"%s against %s" % [charged, billed])

	# **Refused, changing nothing, when the ledger cannot pay.**
	Farm.damage(night, tower, 30)
	for id in GameData.sorted_names((night["held"] as Dictionary).keys()):
		(night["held"] as Dictionary)[id] = 0
	var before := State.hash_of(night)
	var hp := int(Farm.occupant(night, tower)["hp"])
	var slate: Dictionary = (Repair.banked(night) as Dictionary).duplicate()
	(night["intent"] as Dictionary)["repair_cell"] = [tower.x, tower.y]
	Building.tick(night)
	expect(int(Farm.occupant(night, tower)["hp"]) == hp and Repair.banked(night) == slate
		and not Repair.can_mend(night, tower),
		"broke, it is refused and nothing changes")
	expect(before != 0, "the state was read")

	# **By day a damaged wall offers the farmer nothing; the house still does.**
	var day := State.create(1341)
	Resources.gain(day, plenty)
	var wall := _clear_for(day, &"wall")
	SuiteKit.built_last_night(day, func() -> bool:
		return Building.place(day, &"wall", wall))
	Farm.damage(day, wall, 50)
	expect(Repair.can_mend(day, wall) and Interact.verb_at(day, wall) == &"",
		"a damaged wall by day offers no verb - it waits for the night",
		str(Interact.verb_at(day, wall)))
	day["house_hp"] = Phases.house_full(day) - 20
	var house := Farm.house_centre(day)
	expect(Interact.verb_at(day, house) == &"repair",
		"the house by day still does", str(Interact.verb_at(day, house)))
	var bench := Building.anchor_of(day, Farm.cells_with(day, &"workshop")[0])
	Farm.damage(day, bench, 20)
	expect(Interact.verb_at(day, bench) == &"repair",
		"and so does a hurt workshop", str(Interact.verb_at(day, bench)))
	_completed += 1


## 0135 - the flare goes where it is aimed.
func _task_0135_aimed_flare() -> void:
	# **One zombie by the aimed cell and one by the house**: only the first
	# is hit and slowed.
	var state := State.create(1350)
	NightRoad.to_night(state)
	NightRoad.park(state)
	var house := Farm.house_centre(state)
	var radius := int(GameData.ABILITY["radius_tiles"])
	var aim := house + Vector2i(radius * 3, radius * 2)
	if not Grid.in_bounds(aim):
		aim = house - Vector2i(radius * 3, radius * 2)
	var near := Entities.spawn(state, &"walker", aim + Vector2i(1, 0))
	# Off the walls - a walker that reaches the house bites and is gone.
	var home := Entities.spawn(state, &"walker", house + Vector2i(0, 4))
	Entities.set_hp(state, near, 500)
	Entities.set_hp(state, home, 500)
	var intent: Dictionary = state["intent"]
	intent["ability_cell"] = [aim.x, aim.y]
	intent["ability"] = true
	Sim.advance(state, 1)
	expect(Ability.flare_at(state) == [aim.x, aim.y], "the flare goes off on the aimed cell",
		str(Ability.flare_at(state)))
	expect(int(Entities.get_one(state, near).get("hp", -1)) in range(1, 500) and Ability.is_slowed(state, near),
		"the zombie by the aimed cell is hit and slowed")
	expect(int(Entities.get_one(state, home).get("hp", -1)) == 500 and not Ability.is_slowed(state, home),
		"and the one by the house is not touched")

	# **Nowhere is refused, and keeps its charge**: `[-1, -1]` and off the farm.
	for nowhere in [[-1, -1], [GameData.GRID_WIDTH + 3, 2]]:
		var dark := State.create(1351)
		NightRoad.to_night(dark)
		NightRoad.park(dark)
		var dark_intent: Dictionary = dark["intent"]
		dark_intent["ability_cell"] = nowhere
		dark_intent["ability"] = true
		Sim.advance(dark, 1)
		expect(Ability.flares_used(dark) == 0 and Ability.ready(dark)
			and Ability.charge_percent(dark) == 100 and Ability.flare_at(dark).is_empty(),
			"a flare at %s is refused and keeps its charge" % str(nowhere),
			"used %d, ready %s" % [Ability.flares_used(dark), Ability.ready(dark)])
		expect(not bool(dark_intent["ability"]), "and the press is consumed all the same")

	# **An old save is filled in**: `ability_cell` is nowhere until a cursor
	# says otherwise.
	var old := State.create(1352)
	(old["intent"] as Dictionary).erase("ability_cell")
	State.reconcile(old)
	expect((old["intent"] as Dictionary).get("ability_cell", null) == [-1, -1],
		"reconcile fills in ability_cell as nowhere", str((old["intent"] as Dictionary).get("ability_cell")))
	_completed += 1


## 0136 - the build step waits for START.
func _task_0136_start() -> void:
	# **Two minutes of build step stay the build step** - past the old twenty
	# seconds and the thirty of a pass-out.
	var waiting := State.create(1360)
	NightRoad.into_build(waiting)
	Sim.advance(waiting, 120 * GameData.SECONDS)
	expect(int(waiting["phase"]) == Phases.PREPARATION,
		"two minutes in, it is still the build step", Phases.name_of(int(waiting["phase"])))
	expect(Phases.build_step_ticks(waiting) == 0, "it has no clock")
	# **START begins the night on the next tick.**
	(waiting["intent"] as Dictionary)["start_waves"] = true
	Sim.advance(waiting, 1)
	expect(int(waiting["phase"]) == Phases.NIGHT, "START begins the night on the next tick",
		Phases.name_of(int(waiting["phase"])))

	# **START by day or at night changes nothing** - the same tick as a twin
	# that never pressed it, and the edge is gone.
	for setting in ["day", "night"]:
		var pressed := State.create(1361)
		var twin := State.create(1361)
		if setting == "night":
			for one in [pressed, twin]:
				NightRoad.to_night(one)
				NightRoad.park(one)
		(pressed["intent"] as Dictionary)["start_waves"] = true
		Sim.advance(pressed, 1)
		Sim.advance(twin, 1)
		expect(State.hash_of(pressed) == State.hash_of(twin)
			and not bool((pressed["intent"] as Dictionary)["start_waves"]),
			"START %s changes nothing, and is dropped" % ("by day" if setting == "day" else "at night"))

	# **After a pass-out**: the night begins at exactly the short timer, or
	# sooner on START.
	var late := State.create(1362)
	late["day_tick"] = GameData.DAY_TICKS - 1
	Sim.advance(late, 1)
	expect(House.passed_out(late) and int(late["phase"]) == Phases.PREPARATION,
		"02:00 passes him out into the build step")
	Sim.advance(late, GameData.PASS_OUT_PREPARATION_TICKS - 1)
	expect(int(late["phase"]) == Phases.PREPARATION, "one tick short, still building")
	Sim.advance(late, 1)
	expect(int(late["phase"]) == Phases.NIGHT,
		"and at exactly PASS_OUT_PREPARATION_TICKS the night begins by itself")
	var early := State.create(1363)
	early["day_tick"] = GameData.DAY_TICKS - 1
	Sim.advance(early, 1)
	Sim.advance(early, 60)
	(early["intent"] as Dictionary)["start_waves"] = true
	Sim.advance(early, 1)
	expect(int(early["phase"]) == Phases.NIGHT and int(early["night_tick"]) <= 1,
		"or sooner, on START", str(early["night_tick"]))
	_completed += 1


## 0137 - the night ends at 06:00. A near `dawn_at` is written into each
## state rather than playing four minutes.
func _task_0137_dawn() -> void:
	# **A horde that cannot reach the house: the night ends at exactly dawn,
	# won, and whoever is left walks off with the morning.**
	var held := _a_night_near_dawn(1370, 45)
	var far: Vector2i = Enemies.spawn_cells(held, 0)[0]
	for _i in 3:
		Entities.set_hp(held, Entities.spawn(held, &"walker", far), 9999)
	var dawn := int((held["wave"] as Dictionary)["dawn_at"])
	var guard := 0
	while int(held["phase"]) == Phases.NIGHT and guard < 200:
		Sim.advance(held, 1)
		guard += 1
	var result: Dictionary = held["last_result"]
	expect(int(held["phase"]) == Phases.RESULT and int(held["night_tick"]) == dawn
		and bool(result.get("survived", false)),
		"the night ends at exactly dawn_at, won",
		"%s at %d against %d" % [Phases.name_of(int(held["phase"])), int(held["night_tick"]), dawn])
	expect(Entities.count(held) == 3, "with its survivors still on the farm",
		str(Entities.count(held)))
	var logged := false
	for event in (held["events"] as Array):
		if StringName((event as Dictionary).get("kind", &"")) == &"dawn":
			logged = int((event as Dictionary).get("walked", -1)) == 3
	expect(logged, "and the log says dawn came, and how many walked off")
	Phases.begin_day(held)
	expect(Entities.count(held) == 0, "and the morning sends them off",
		str(Entities.count(held)))

	# **Killing everything ends it sooner.**
	var cleared := _a_night_near_dawn(1371, 600)
	(cleared["wave"] as Dictionary)["done"] = true
	Sim.advance(cleared, 1)
	expect(int(cleared["phase"]) == Phases.RESULT
		and int(cleared["night_tick"]) < int((cleared["wave"] as Dictionary)["dawn_at"])
		and bool((cleared["last_result"] as Dictionary)["survived"]),
		"everything dead before dawn is a won night, sooner")

	# **A house at 0 before dawn still loses.**
	var lost := _a_night_near_dawn(1372, 600)
	lost["house_hp"] = 1
	Entities.spawn(lost, &"walker", House.porch(lost))
	guard = 0
	while int(lost["phase"]) == Phases.NIGHT and guard < 600:
		Sim.advance(lost, 1)
		guard += 1
	expect(int(lost["phase"]) == Phases.RESULT
		and not bool((lost["last_result"] as Dictionary)["survived"]),
		"a house at 0 before dawn loses", str(lost["last_result"]))

	# **A boss alive at dawn escapes** (task 0153; until then the night waited
	# for it). Spring 14, the boss on the farm, dawn brought close: the night
	# ends at dawn, neither won nor lost.
	var giant := _a_boss_night_near_dawn(1373, 5)
	Entities.spawn(giant, Calendar.boss_of(14), Enemies.spawn_cells(giant, 0)[0])
	Sim.advance(giant, 30)
	expect(int(giant["phase"]) == Phases.RESULT
		and bool((giant["last_result"] as Dictionary).get("escaped", false)),
		"dawn ends a boss night too, the boss escaping",
		"%s %s" % [Phases.name_of(int(giant["phase"])), str(giant["last_result"])])

	# **Skip runs to dawn at the latest**, from the middle of a real night.
	var skipping := State.create(1374)
	NightRoad.to_night(skipping)
	skipping["house_hp"] = 1 << 20
	Sim.advance(skipping, 200)
	var left := Phases.ticks_to_dawn(skipping)
	var took := Sim.skip_night(skipping)
	expect(took > 0 and took <= left and int(skipping["phase"]) == Phases.RESULT,
		"Sim.skip_night takes at most the ticks left to dawn and lands in RESULT",
		"%d of %d left" % [took, left])

	# **The schedule check**: a night that is still sending at dawn is refused.
	var long: Dictionary = (GameData.NIGHTS[0] as Dictionary).duplicate(true)
	long["waves"] = [[&"walker", GameData.NIGHT_TICKS / GameData.SPAWN_INTERVAL_TICKS + 5, 0]]
	expect(not GameData.check_nights([long]).is_empty(),
		"check_nights refuses a schedule longer than the night",
		str(GameData.check_nights([long])))
	expect(GameData.check_nights(GameData.NIGHTS).is_empty(),
		"and the ten shipped nights are all inside it", str(GameData.check_nights(GameData.NIGHTS)))
	# The endless curve against the same rule, from the schedule alone.
	var outside: Array = []
	for night in range(11, 41):
		for seed_value in [0, 1, 7]:
			var sent := Waves.schedule_ticks(Waves.night_of(night, seed_value))
			if sent + GameData.DAWN_MARGIN_TICKS > GameData.NIGHT_TICKS:
				outside.append("%d/%d:%d" % [night, seed_value, sent])
	expect(outside.is_empty(), "endless nights 11-40 are all sent a margin before dawn",
		str(outside.slice(0, 4)))
	_completed += 1


## A night with nothing scheduled and dawn `ticks` away.
func _a_night_near_dawn(seed_value: int, ticks: int) -> Dictionary:
	var state := State.create(seed_value)
	NightRoad.to_night(state)
	NightRoad.park(state)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + ticks
	return state


## 0138 - waking up: every night, won or lost, ends with him getting out of
## his own bed at 06:00 - and the morning report has the night's numbers.
func _task_0138_morning() -> void:
	# **A won night**, with a wall lost in it: cleared, it is won, and the
	# payout knows what came down and that nobody was left to walk off.
	var won := _a_night_near_dawn(1380, 600)
	var doomed := SuiteKit.any_buildable(won)
	Farm.place(won, doomed, {"id": &"wall", "hp": 30})
	Farm.damage(won, doomed, 999)
	(won["wave"] as Dictionary)["done"] = true
	Sim.advance(won, 1)
	var paid := Rewards.last(won)
	expect(int(won["phase"]) == Phases.RESULT
		and bool((won["last_result"] as Dictionary).get("survived", false)),
		"a cleared night is won", Phases.name_of(int(won["phase"])))
	expect(int(paid.get("structures_lost", -1)) == 1 and int(paid.get("walked", -1)) == 0,
		"and the payout counts the wall that came down, with nobody left to walk off",
		str(paid))
	_wakes_in_bed(won, "after a won night")

	# **Dawn**: whoever is still on the farm is in the payout.
	var held := _a_night_near_dawn(1381, 20)
	var far: Vector2i = Enemies.spawn_cells(held, 0)[0]
	for _i in 2:
		Entities.set_hp(held, Entities.spawn(held, &"walker", far), 9999)
	var guard := 0
	while int(held["phase"]) == Phases.NIGHT and guard < 100:
		Sim.advance(held, 1)
		guard += 1
	expect(int(Rewards.last(held).get("walked", -1)) == 2,
		"a night that ends at dawn says two walked off", str(Rewards.last(held)))
	_wakes_in_bed(held, "after dawn")

	# **A lost night** wakes him in the same bed.
	var lost := _a_night_near_dawn(1382, 600)
	lost["house_hp"] = 1
	Entities.spawn(lost, &"walker", House.porch(lost))
	guard = 0
	while int(lost["phase"]) == Phases.NIGHT and guard < 600:
		Sim.advance(lost, 1)
		guard += 1
	expect(int(lost["phase"]) == Phases.RESULT
		and not bool((lost["last_result"] as Dictionary)["survived"]),
		"a house at 0 is a lost night", str(lost["last_result"]))
	expect(int(Rewards.last(lost).get("walked", -1)) == Entities.count(lost),
		"and the payout counts who was still there", str(Rewards.last(lost)))
	_wakes_in_bed(lost, "after a lost night")

	# **Passed out in a field at 02:00**: the report can say so, and he still
	# wakes in his bed.
	var fell := State.create(1383)
	Phases.pass_out(fell)
	NightRoad.through_build(fell)
	NightRoad.park(fell)
	(fell["wave"] as Dictionary)["done"] = true
	Sim.advance(fell, 1)
	expect(int(fell["phase"]) == Phases.RESULT and House.passed_out(fell),
		"a night that began with a pass-out still says so on the report",
		Phases.name_of(int(fell["phase"])))
	_wakes_in_bed(fell, "after passing out")

	# **Saved and loaded on the report**, it confirms into the same morning.
	var kept := _a_night_near_dawn(1384, 600)
	(kept["wave"] as Dictionary)["done"] = true
	Sim.advance(kept, 1)
	var path := "user://task_0138_morning.sav"
	expect(Save.write_run_at(path, kept), "the morning report saves")
	var loaded := Save.read_run_at(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	expect(not loaded.is_empty() and int(loaded["phase"]) == Phases.RESULT,
		"and loads on the report", str(loaded.get("phase", "nothing")))
	if not loaded.is_empty():
		var twin := State.copy(loaded)
		for one in [kept, twin]:
			((one as Dictionary)["intent"] as Dictionary)["confirm_result"] = true
			Sim.tick(one)
		expect(State.hash_of(twin) == State.hash_of(kept),
			"into the same morning as the run that never left",
			"%d against %d" % [State.hash_of(twin), State.hash_of(kept)])
		_wakes_in_bed(loaded, "after a load")
	_completed += 1


## Confirm the morning report and check where it leaves him: inside, awake,
## on the floor beside the bed at 06:00 - and out of the door onto the porch.
func _wakes_in_bed(state: Dictionary, after: String) -> void:
	(state["intent"] as Dictionary)["confirm_result"] = true
	Sim.tick(state)
	var cell := Player.cell(state)
	expect(int(state["phase"]) == Phases.DAY and House.inside(state)
		and not House.asleep(state) and not House.passed_out(state),
		"confirming the report %s has him inside and awake" % after,
		"%s, inside %s, asleep %s" % [Phases.name_of(int(state["phase"])),
			House.inside(state), House.asleep(state)])
	expect(House.bedside(cell) and cell == House.wake_cell(),
		"on the floor beside his bed %s" % after, str(cell))
	expect(int(state["day_tick"]) == 0
		and Phases.clock_minute(state) == GameData.DAY_START_MINUTE,
		"at day_tick 0, 06:00, %s" % after,
		"tick %d, minute %d" % [int(state["day_tick"]), Phases.clock_minute(state)])
	House.leave(state)
	expect(not House.inside(state) and Player.cell(state) == House.porch(state),
		"and the door lets him out onto the porch %s" % after, str(Player.cell(state)))


## 0140 - bedtime on the day HUD: two view thresholds, held in their order.
func _task_0140_bedtime() -> void:
	expect(GameData.check_bedtime(GameData.DUSK_MINUTE, GameData.BEDTIME_REMINDER_MINUTE,
		GameData.PASS_OUT_WARNING_MINUTE, GameData.DAY_END_MINUTE).is_empty(),
		"the shipped reminder and warning sit between dusk and the end of the day")
	expect(not GameData.check_bedtime(18 * 60, 17 * 60, 25 * 60, 26 * 60).is_empty(),
		"a reminder before dusk is refused")
	expect(not GameData.check_bedtime(18 * 60, 22 * 60, 21 * 60, 26 * 60).is_empty(),
		"so is a warning before the reminder")
	expect(not GameData.check_bedtime(18 * 60, 22 * 60, 26 * 60, 26 * 60).is_empty(),
		"and a warning no earlier than the pass-out itself")
	_completed += 1


## 0141 - day one teaches the new night: to bed, the build step, START,
## dawn - by watching the state, never by gating it. Spans are jumped (a
## near `dawn_at`), not played.
func _task_0141_tutorial() -> void:
	var every: Array = []
	for entry in Tutorial.steps():
		every.append(StringName((entry as Dictionary)["id"]))
	expect(every.size() == GameData.MAX_TUTORIAL_LINES
		and GameData.check_tutorial(Tutorial.steps()).is_empty(),
		"nine steps, which the lever now allows, passing their own check",
		str(every))

	# **A scripted first day and night completes every step, in order.** The
	# same script runs a second farm whose player read nothing: every line
	# already out of the way before the day starts.
	var taught := State.create(1410)
	var ignored := State.create(1410)
	((ignored["tutorial"] as Dictionary)["done"] as Array).assign(every.duplicate())
	for farm in [taught, ignored]:
		_first_day_and_night(farm as Dictionary, 0)
	expect(((taught["tutorial"] as Dictionary)["done"] as Array)
		== every.slice(0, every.size() - 1),
		"every step up to START completes, in the order the lines come",
		str((taught["tutorial"] as Dictionary)["done"]))
	expect(int(taught["phase"]) == Phases.NIGHT and _same_but_the_lesson(taught, ignored),
		"and the night it reaches is the same night, but for the tutorial",
		Phases.name_of(int(taught["phase"])))
	for farm in [taught, ignored]:
		_first_day_and_night(farm as Dictionary, 1)
	expect(((taught["tutorial"] as Dictionary)["done"] as Array) == every
		and Tutorial.is_finished(taught) and int(taught["day"]) == 2
		and _same_but_the_lesson(taught, ignored),
		"held till dawn, the last line goes, and the morning is the same morning",
		str((taught["tutorial"] as Dictionary)["done"]))

	# **Each night line is taught in its own part of the day.**
	var here := State.create(1411)
	((here["tutorial"] as Dictionary)["done"] as Array).assign(
		[&"chop", &"plant", &"water", &"sell", &"craft"])
	expect(Tutorial.current_here(here).get("id", &"") == &"bed"
		and Tutorial.anchor_of(here) == &"cell"
		and Tutorial.points_at(here) == House.porch(here),
		"by day, after the day's five, the bed's line sits on the farmhouse door",
		str(Tutorial.points_at(here)))
	House.enter(here)
	var bed := House.bed()
	expect(Tutorial.anchor_of(here) == &"room"
		and Tutorial.points_at(here) == Vector2i(bed.position.x + bed.size.x / 2,
			bed.position.y),
		"and in the house, on the bed", str(Tutorial.points_at(here)))
	House.leave(here)
	NightRoad.into_build(here)
	((here["tutorial"] as Dictionary)["done"] as Array).append(&"bed")
	var aim := Tutorial.points_at(here)
	var house := Farm.house_centre(here)
	expect(Tutorial.current_here(here).get("id", &"") == &"build"
		and Farm.buildable(here, aim) and aim != house,
		"in the build step the build line sits on open ground off the house",
		str(aim))
	((here["tutorial"] as Dictionary)["done"] as Array).append(&"build")
	expect(Tutorial.anchor_of(here) == &"start", "then START's line sits on START")
	NightRoad.through_build(here)
	((here["tutorial"] as Dictionary)["done"] as Array).append(&"start")
	expect(Tutorial.anchor_of(here) == &"dawn",
		"and in the night dawn's sits on the countdown")
	_completed += 1


## The scripted first day (`part` 0) - the day's five, to bed, a wall in the
## build step, START - or the rest of it (`part` 1): the night held to a near
## dawn, the morning confirmed, and out of the door.
func _first_day_and_night(farm: Dictionary, part: int) -> void:
	var beat := GameData.TUTORIAL_CHECK_TICKS
	if part == 0:
		Resources.gain(farm, {GameData.WOOD: 5})
		Sim.advance(farm, beat)
		var plot: Vector2i = Farming.field_cells(farm)[0]
		Farming.act(farm, plot)
		Farming.act(farm, plot)
		Sim.advance(farm, beat)
		farm["water_can"] = 2
		Sim.advance(farm, beat)
		Resources.gain(farm, {GameData.MONEY: 100})
		Sim.advance(farm, beat)
		Resources.gain(farm, {GameData.WOOD: 100, GameData.STONE: 100, GameData.IRON: 100})
		var bench := Building.anchor_of(farm, Farm.cells_with(farm, &"workshop")[0])
		Crafting.enqueue(farm, bench, &"wall_kit")
		Sim.advance(farm, beat)
		(farm["intent"] as Dictionary)["sleep"] = true
		Sim.advance(farm, beat)
		Building.place(farm, &"wall", SuiteKit.any_buildable(farm))
		Sim.advance(farm, beat)
		NightRoad.press_start(farm)
		Sim.advance(farm, beat)
		return
	NightRoad.park(farm)
	(farm["wave"] as Dictionary)["dawn_at"] = int(farm["night_tick"]) + 3
	Sim.advance(farm, 10)
	(farm["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(farm, 1)
	House.leave(farm)
	Sim.advance(farm, beat)


## Whether two farms are the same farm but for what the tutorial has seen.
func _same_but_the_lesson(a: Dictionary, b: Dictionary) -> bool:
	var left := State.copy(a)
	var right := State.copy(b)
	left["tutorial"] = {}
	right["tutorial"] = {}
	return State.hash_of(left) == State.hash_of(right)


## 0149 - the calendar: a day becomes a date through one set of pure helpers,
## and asking them changes nothing.
func _task_0149_calendar() -> void:
	# **The five mappings**: [day, year, season, day of season].
	var named := {0: &"spring", 1: &"summer", 2: &"autumn", 3: &"winter"}
	for row in [[1, 1, 0, 1], [14, 1, 0, 14], [15, 1, 1, 1], [56, 1, 3, 14],
			[57, 2, 0, 1]]:
		var day: int = row[0]
		var got := [Calendar.year_of(day), Calendar.season_of(day),
			Calendar.day_of_season(day)]
		expect(got == [row[1], row[2], row[3]] and Calendar.season_id(day) == named[row[2]],
			"day %d is %s %d of year %d" % [day, named[row[2]], row[3], row[1]],
			"%s, %s" % [got, Calendar.season_id(day)])
	expect(Calendar.year_days() == 56 and GameData.SEASON_DAYS == 14
		and GameData.SEASONS == [&"spring", &"summer", &"autumn", &"winter"],
		"a year is four seasons of fourteen days, 56 in all",
		str(Calendar.year_days()))

	# **A seven-day season**, through the optional argument, not the lever.
	expect(Calendar.year_days(7) == 28 and Calendar.season_of(7, 7) == 0
		and Calendar.season_of(8, 7) == 1 and Calendar.day_of_season(8, 7) == 1
		and Calendar.day_of_season(28, 7) == 7 and Calendar.season_of(28, 7) == 3
		and Calendar.year_of(28, 7) == 1 and Calendar.year_of(29, 7) == 2,
		"seven-day seasons: day 8 is Summer 1, day 28 Winter 7, day 29 Year 2")

	# **The date is the day the run keeps**, and asking never moves a hash.
	var state := State.create(1490)
	state["day"] = 20
	var before := State.hash_of(state)
	var today := Calendar.date(state)
	var asked := [Calendar.year_days(), Calendar.year_of(today),
		Calendar.season_of(today), Calendar.day_of_season(today),
		Calendar.season_id(today), Calendar.year_of(today, 7)]
	expect(today == 20 and asked[2] == 1 and asked[3] == 6,
		"the date is state.day: day 20 is Summer 6", str(asked))
	expect(State.hash_of(state) == before, "and asking every helper leaves the hash alone")

	# **The shape is checked.**
	expect(GameData.check_calendar(GameData.SEASONS, GameData.SEASON_DAYS).is_empty(),
		"the shipped calendar passes its check")
	expect(not GameData.check_calendar([&"spring", &"summer", &"autumn"], 14).is_empty(),
		"three seasons are refused")
	var twice := [&"spring", &"spring", &"autumn", &"winter"]
	expect(not GameData.check_calendar(twice, 14).is_empty(), "so is a season named twice")
	expect(not GameData.check_calendar(GameData.SEASONS, 1).is_empty(),
		"and a season of one day")
	_completed += 1


## 0150 - every question about which night is which goes through one lookup:
## `plain_night` as written, `night_of` as fought, and the run's end and its
## technology asked of `Run.final_night()`.
func _task_0150_lookup() -> void:
	# **Every day of two years resolves**, for two seeds.
	var empty: Array = []
	var differ: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, 2 * Calendar.year_days() + 1):
			var fought := Waves.night_of(day, seed_value)
			# A calm night (task 0154) sends nothing and says so.
			if fought.is_empty() or (fought.get("waves", []) as Array).is_empty() \
					and not bool(fought.get("calm", false)):
				empty.append([seed_value, day])
			# Where no calendar rule applies - since 0152 not on a Full Moon,
			# and since 0153 not where a boss is put in or taken out - what is
			# fought is what is written.
			var ruled := Waves._ruled(day, seed_value)
			if not ruled and str(fought) != str(Waves.plain_night(day, seed_value)):
				differ.append([seed_value, day])
	expect(empty.is_empty(), "every day 1-112 has a night for seeds 0 and 424242",
		str(empty))
	expect(differ.is_empty(), "and where no calendar rule applies it is the night as written",
		str(differ))

	# **The authored row itself, not a copy**: 0152-0154 add their rules on
	# top, and until they do nothing is built per question.
	expect(is_same(Waves.night_of(1), GameData.NIGHTS[0])
		and is_same(Waves.plain_night(1), GameData.NIGHTS[0]),
		"night_of(1) is GameData.NIGHTS[0], the same object")
	expect(Waves.authored_count() == GameData.NIGHTS.size()
		and Endless.is_generated(Waves.authored_count() + 1)
		and not Endless.is_generated(Waves.authored_count()),
		"the curve takes over the night after the last authored one")

	# **The run's last night, asked in one place**: the year's last day since
	# task 0151.
	expect(Run.final_night() == Calendar.year_days(),
		"Run.final_night() is the year's last night", str(Run.final_night()))
	expect(Tech.least_available() == int(GameData.REWARDS["tech_points"]) * Run.final_night(),
		"and the least technology a run pays is a point for each of its nights",
		str(Tech.least_available()))
	var state := State.create(1500)
	state["night"] = 7
	expect(Rewards.night_step(state) == 7, "Rewards.night_step reads the night",
		str(Rewards.night_step(state)))
	_completed += 1


## 0151 - the night is the calendar day. A version 4 run saved in each of
## the four phases comes up to version 5 and fights the date's night next;
## no date pays twice; `endless` keeps its meaning past the year; and every
## golden loads and plays.
func _task_0151_migration() -> void:
	# Version 5 brought this step; later versions step on from it (0156: 6).
	expect(State.VERSION >= 5 and Save.migrations().has(4),
		"state version 5 or later, with a step up from 4", str(State.VERSION))
	var names := {Phases.DAY: "DAY", Phases.PREPARATION: "PREPARATION",
		Phases.NIGHT: "NIGHT", Phases.RESULT: "RESULT"}
	for phase in [Phases.DAY, Phases.PREPARATION, Phases.NIGHT, Phases.RESULT]:
		var what: String = names[phase]
		var old := _a_v4_run(1510 + int(phase), int(phase))
		var was := {"day": int(old["day"]), "night": int(old["night"]),
			"paid": (old["nights_paid"] as Array).duplicate()}
		var run := _through_a_save(old, "v4_%s" % what)
		expect(int(run.get("version", 0)) == State.VERSION and int(run["phase"]) == int(phase)
			and int(run["day"]) == int(was["day"]) and int(run["night"]) == int(was["night"])
			and run["nights_paid"] == was["paid"],
			"a v4 run saved in %s loads as today's version with its day, night and paid list" % what,
			"v%d, %s, day %d, night %d, paid %s" % [int(run.get("version", 0)),
				Phases.name_of(int(run["phase"])), int(run["day"]), int(run["night"]),
				str(run["nights_paid"])])

		# **To its next night**, by the road and the bed, never a day played.
		if int(run["phase"]) == Phases.NIGHT:
			# A night in progress keeps its number until it ends.
			expect(int(run["night"]) == 4,
				"the night in progress is still the v4 night 4", str(run["night"]))
			_win_at_dawn(run)
		if int(run["phase"]) == Phases.RESULT:
			(run["intent"] as Dictionary)["confirm_result"] = true
			Sim.advance(run, 2)
		if int(run["phase"]) == Phases.DAY:
			(run["intent"] as Dictionary)["sleep"] = true
			Sim.advance(run, 1)
		NightRoad.through_build(run)
		var date := Calendar.date(run)
		expect(int(run["phase"]) == Phases.NIGHT and int(run["night"]) == date,
			"from %s the next night is the date's, %d - not v4's night 4" % [what, date],
			"%s, night %d on day %d" % [Phases.name_of(int(run["phase"])),
				int(run["night"]), date])
		_win_at_dawn(run)
		var paid: Array = run["nights_paid"]
		var once: Dictionary = {}
		for night in paid:
			once[int(night)] = true
		expect(once.size() == paid.size() and paid.back() == date,
			"and winning it pays date %d, with no date paid twice" % date, str(paid))

	# **Endless means past the year now.** A v4 run that was endless and is
	# already past Winter 14 stays so; one that was endless before it goes
	# back to the year; and 0160 now reads a date past Winter 14 as a completed year.
	var long_gone := _a_v4_run(1520, Phases.DAY)
	long_gone["day"] = Calendar.year_days() + 4
	long_gone["endless"] = true
	var kept := _through_a_save(long_gone, "v4_endless")
	expect(Run.is_endless(kept) and not Run.is_over(kept),
		"an endless v4 run past day 56 stays endless, and is not over")
	var early := _a_v4_run(1521, Phases.DAY)
	early["endless"] = true
	expect(not Run.is_endless(_through_a_save(early, "v4_early_endless")),
		"one that went endless after the MVP's ten goes back to the year")
	var not_endless := _a_v4_run(1522, Phases.DAY)
	not_endless["day"] = Calendar.year_days() + 4
	expect(Run.is_over(_through_a_save(not_endless, "v4_past_the_year")),
		"0160 reads the released date; legacy past-year reconciliation belongs to 0291")

	# **Every golden loads and plays**: v1, v4 and v5.
	var versions: Dictionary = {}
	for name in DirAccess.get_files_at("res://tools/goldens"):
		if not String(name).ends_with(".sav"):
			continue
		var loaded := Save.read_run_at("res://tools/goldens/" + String(name))
		expect(not loaded.is_empty() and int(loaded.get("version", 0)) == State.VERSION,
			"%s loads as version %d" % [name, State.VERSION], String(Save.trouble()))
		if loaded.is_empty():
			continue
		versions[String(name).get_slice("-", 1).get_basename()] = true
		var at := int(loaded["tick"])
		Sim.advance(loaded, 300)
		expect(int(loaded["tick"]) == at + 300
			and Phases.night_ahead(loaded) == Calendar.date(loaded),
			"%s plays on, its next night the date's" % name,
			"night ahead %d, date %d" % [Phases.night_ahead(loaded), Calendar.date(loaded)])
	expect(versions.has("v1") and versions.has("v4") and versions.has("v5"),
		"there are goldens of v1, v4 and v5", str(versions.keys()))
	_completed += 1


## A run as a version 4 build left it, in `phase`: day 6, three nights won
## and paid - so v4's next night was 4, two having been lost - and, in NIGHT
## or RESULT, v4's night 4 under way or just lost.
func _a_v4_run(seed_value: int, phase: int) -> Dictionary:
	var state := State.create(seed_value)
	state["nights_won"] = 3
	(state["nights_paid"] as Array).assign([1, 2, 3])
	Resources.gain(state, {GameData.WOOD: 300, GameData.STONE: 300,
		GameData.IRON: 300, GameData.FOOD: 100})
	if phase == Phases.DAY:
		state["day"] = 6
	elif phase == Phases.PREPARATION:
		state["day"] = 6
		NightRoad.into_build(state)
	else:
		# Night 4 begun the way v4 numbered it - on a day 4 - and the day then
		# put where v4 had it, two lost nights on.
		state["day"] = 4
		NightRoad.to_night(state)
		state["day"] = 6
		if phase == Phases.RESULT:
			state["house_hp"] = 0
			Rewards.settle(state, false)
			Phases.enter_result(state, false)
	state["version"] = 4
	return state


## Write a state with the real writer and read it back with the real reader:
## the migrations and the reconcile a player's save goes through.
func _through_a_save(state: Dictionary, name: String) -> Dictionary:
	var path := "user://%s.sav" % name
	Save.write_run_at(path, state)
	var back := Save.read_run_at(path)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	return back


## Bring dawn close and let the night end there: a night won with the house
## standing, the way the rules pay one.
func _win_at_dawn(state: Dictionary) -> void:
	if int(state["phase"]) != Phases.NIGHT:
		return
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
	state["house_hp"] = Phases.house_full(state)
	for _t in 60:
		if int(state["phase"]) != Phases.NIGHT:
			break
		Sim.advance(state, 1)


## 0152 - Full Moon nights: the dates, the bigger horde over the night as
## written, the pay, the kept record, and the year still fitting its nights.
func _task_0152_full_moon() -> void:
	# **Which dates.**
	var moons: Array = []
	for day in [6, 7, 8, 14, 15, 21, 56]:
		if Calendar.is_full_moon(day):
			moons.append(day)
	expect(moons == [7, 14, 21, 56], "days 7, 14, 21 and 56 are Full Moons and 6, 8, 15 not",
		str(moons))
	var counts := [Calendar.days_to_full_moon(3), Calendar.days_to_full_moon(6),
		Calendar.days_to_full_moon(7), Calendar.days_to_full_moon(8),
		Calendar.days_to_full_moon(15)]
	expect(counts == [4, 1, 0, 6, 6], "the Full Moon is 4 days off on day 3, 1 on day 6, "
		+ "tonight on day 7, 6 on days 8 and 15", str(counts))

	# **A bigger horde, the boss as written**: every Full Moon of two years,
	# authored and generated, against its plain record.
	var wrong: Array = []
	var bosses := 0
	for day in range(1, 2 * Calendar.year_days() + 1):
		if not Calendar.is_full_moon(day):
			if Waves.night_of(day, 7).has("full_moon"):
				wrong.append("%d flagged" % day)
			continue
		# The Full Moon goes over the boss rule (0153): the night as that
		# rule leaves it is what the moon scales.
		var plain := Waves.plain_night(day, 7)
		if Calendar.is_boss_night(day):
			plain = Waves._with_the_season_boss(plain, Calendar.boss_of(day))
		elif Waves._has_a_boss(plain):
			plain = Waves._without_bosses(plain)
		var moon := Waves.night_of(day, 7)
		if not bool(moon.get("full_moon", false)):
			wrong.append("%d not flagged" % day)
		var was: Array = plain["waves"]
		var now: Array = moon["waves"]
		if was.size() != now.size():
			wrong.append("%d has %d waves, not %d" % [day, now.size(), was.size()])
			continue
		for i in was.size():
			var a: Array = was[i]
			var b: Array = now[i]
			var boss := bool((GameData.ENEMIES[StringName(a[0])] as Dictionary).get("is_boss", false))
			var want := int(a[1]) if boss else maxi(int(a[1])
				* GameData.FULL_MOON_HORDE_PERCENT / 100, int(a[1]))
			if boss:
				bosses += 1
			if b[0] != a[0] or int(b[2]) != int(a[2]) or int(b[1]) != want:
				wrong.append("%d wave %d: %s against %s" % [day, i, str(b), str(a)])
	expect(wrong.is_empty() and bosses > 0,
		"a Full Moon sends %d%% of every ordinary wave and its bosses as written"
			% GameData.FULL_MOON_HORDE_PERCENT,
		"%s; %d boss rows met" % [str(wrong.slice(0, 4)), bosses])
	expect(is_same(Waves.night_of(6), GameData.NIGHTS[5])
		and not is_same(Waves.night_of(7), GameData.NIGHTS[6])
		and not (GameData.NIGHTS[6] as Dictionary).has("full_moon"),
		"an ordinary night is still the authored row, and a Full Moon leaves it untouched")

	# **Every Full Moon of the year fits the night** (0137), for both seeds
	# `tools/nights.py --check` reads - asked of the whole year, since 0157's
	# side rule reads each record's date off its place in the table.
	var faults: Array = []
	for seed_value in [0, 424242]:
		var year: Array = []
		for day in range(1, Calendar.year_days() + 1):
			year.append(Waves.night_of(day, seed_value))
		faults.append_array(GameData.check_nights(year))
	expect(faults.is_empty(), "and every Full Moon of the year still checks", str(faults))

	# **Paid the lever's percent**: the same state and kills, under the moon
	# and under an ordinary sky.
	var state := State.create(1520)
	state["night"] = 7
	state["day"] = 7
	(state["killed_by_kind"] as Dictionary)[&"walker"] = 6
	(state["killed_by_kind"] as Dictionary)[&"runner"] = 2
	var lit := Rewards._lines(state, true)
	var dark := Rewards._lines(state, true, 100)
	var from := Rewards._money_from(state)
	var plain_money := int(dark[GameData.MONEY])
	var bonus := int(from.get("full moon", 0))
	expect(Rewards.moon_percent(state) == GameData.FULL_MOON_REWARD_PERCENT
		and bonus == plain_money * (GameData.FULL_MOON_REWARD_PERCENT - 100) / 100
		and int(lit[GameData.MONEY]) == plain_money + bonus,
		"a won Full Moon pays %d%% of its money, the difference on its own line"
			% GameData.FULL_MOON_REWARD_PERCENT,
		"%d = %d + %d" % [int(lit[GameData.MONEY]), plain_money, bonus])
	var materials_off: Array = []
	for id in GameData.sorted_names(dark.keys()):
		if id == GameData.MONEY:
			continue
		if int(lit[id]) != int(dark[id]) * GameData.FULL_MOON_REWARD_PERCENT / 100:
			materials_off.append(id)
	expect(materials_off.is_empty() and dark.size() > 1,
		"and the same percent of its materials", str(materials_off))
	state["night"] = 8
	expect(Rewards.moon_percent(state) == 100
		and not Rewards._money_from(state).has("full moon"),
		"an ordinary night pays as it always did, with no moon line")

	# **Kept while it is fought**: the night HUD asks every frame.
	var fought := State.create(1521)
	fought["day"] = 7
	NightRoad.to_night(fought)
	var first := Waves.tonight(fought)
	var same := true
	for _t in 100:
		Sim.tick(fought)
		if int(fought["phase"]) != Phases.NIGHT:
			break
		if not is_same(Waves.tonight(fought), first):
			same = false
	expect(bool(first.get("full_moon", false)) and same,
		"Waves.tonight hands back the same Full Moon record over 100 ticks")
	var one := State.create(1522)
	NightRoad.to_night(one)
	expect(is_same(Waves.tonight(one), GameData.NIGHTS[0])
		and not (one["wave"] as Dictionary).has("tonight"),
		"while night 1 is still the authored row, with nothing kept for it")

	# **The calendar's check.**
	expect(not GameData.check_calendar(GameData.SEASONS, 14, [7, 15]).is_empty()
		and not GameData.check_calendar(GameData.SEASONS, 14, [7], 90).is_empty()
		and not GameData.check_calendar(GameData.SEASONS, 14, [7], 150, 50).is_empty(),
		"a Full Moon outside the season, or a horde or pay under 100%, is refused")
	_completed += 1


## A boss night - Spring 14 - begun through `NightRoad`, parked, and its dawn
## brought `ticks` close.
func _a_boss_night_near_dawn(seed_value: int, ticks: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = GameData.SEASON_DAYS
	state["nights_won"] = GameData.SEASON_DAYS - 1
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200,
		GameData.MONEY: 100})
	NightRoad.to_night(state)
	NightRoad.park(state)
	(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + ticks
	return state


## 0153 - boss nights: the season's boss on its last night and on no other,
## and the season held until it falls.
func _task_0153_boss_nights() -> void:
	# **Only on 14, 28, 42, 56, ... once each, the season's boss.**
	var bossy: Array = []
	var wrong: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, 2 * Calendar.year_days() + 1):
			var rows: Array = []
			for row in Waves.table(day, seed_value):
				if Waves._is_boss(StringName((row as Array)[0])):
					rows.append(row)
			if rows.is_empty():
				continue
			if seed_value == 0:
				bossy.append(day)
			if rows.size() != 1 or int((rows[0] as Array)[1]) != 1 \
					or StringName((rows[0] as Array)[0]) != Calendar.boss_of(day):
				wrong.append([seed_value, day, rows])
	expect(bossy == [14, 28, 42, 56, 70, 84, 98, 112] and wrong.is_empty(),
		"bosses come on dates 14, 28, ... 112 only, one row each, the season's",
		"%s %s" % [str(bossy), str(wrong.slice(0, 3))])
	expect(not Waves.kinds_of(10).has(&"giant") and Waves.kinds_of(14).has(&"giant")
		and StringName(Waves.night_of(14).get("boss", &"")) == &"giant",
		"night 10 has lost its Giant to Spring 14, which carries the boss flag")
	var year: Array = []
	for day in range(1, Calendar.year_days() + 1):
		year.append(Waves.night_of(day, 0))
	expect(GameData.check_nights(year).is_empty(),
		"and the year still checks with the boss rows in", str(GameData.check_nights(year)))
	expect(GameData.check_calendar(GameData.SEASONS, 14, [7, 14], 150, 200,
		[&"giant", &"walker", &"giant", &"giant"]).size() == 1,
		"a season boss that is not a boss is refused")

	# **Alive at dawn: it escapes.** Nothing taken, nothing paid, the day
	# moves, the date holds, the stall restocks, and tonight is the boss again.
	var escaped := _a_boss_night_near_dawn(1530, 3)
	Entities.spawn(escaped, Calendar.boss_of(14), Enemies.spawn_cells(escaped, 0)[0])
	var held: Dictionary = (escaped["held"] as Dictionary).duplicate()
	var won_before := Phases.nights_won(escaped)
	for _t in 30:
		if int(escaped["phase"]) != Phases.NIGHT:
			break
		Sim.advance(escaped, 1)
	var paid := Rewards.last(escaped)
	expect(int(escaped["phase"]) == Phases.RESULT
		and bool((escaped["last_result"] as Dictionary).get("escaped", false))
		and bool(paid.get("escaped", false)) and StringName(paid.get("boss", &"")) == &"giant",
		"a boss alive at dawn escapes, and the payout says which", str(paid))
	expect(escaped["held"] == held and (paid["gained"] as Dictionary).is_empty()
		and (paid["lost"] as Dictionary).is_empty() and not Tech.already_paid(escaped, 14),
		"nothing is taken and nothing paid - no technology either")
	expect(Phases.nights_won(escaped) == won_before and int(escaped["day"]) == 15
		and Calendar.date(escaped) == 14 and int(escaped["days_held"]) == 1,
		"nights_won stays, day moves to 15, and the date holds on 14",
		"won %d, day %d, date %d" % [Phases.nights_won(escaped), int(escaped["day"]),
			Calendar.date(escaped)])
	(escaped["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(escaped, 2)
	var stall: Dictionary = escaped["stall"]
	expect(int(escaped["phase"]) == Phases.DAY and Entities.count(escaped) == 0
		and int(stall["day"]) == 15,
		"the boss walks off with the rest, and the stall restocks on day 15",
		"%d on the farm, stall stocked on day %d" % [Entities.count(escaped), int(stall["day"])])
	NightRoad.to_night(escaped)
	expect(int(escaped["night"]) == 14 and Waves.table_tonight(escaped).size() > 0
		and StringName(Waves.tonight(escaped).get("boss", &"")) == &"giant",
		"and tonight is the boss night again", str(escaped["night"]))

	# **Killed: the season moves on.**
	var killed := _a_boss_night_near_dawn(1531, 3)
	(killed["killed_by_kind"] as Dictionary)[Calendar.boss_of(14)] = 1
	for _t in 30:
		if int(killed["phase"]) != Phases.NIGHT:
			break
		Sim.advance(killed, 1)
	expect(bool((killed["last_result"] as Dictionary).get("survived", false))
		and Calendar.date(killed) == 15 and Tech.already_paid(killed, 14),
		"a boss put down: the night is won, paid once, and the next date is 15",
		"date %d, %s" % [Calendar.date(killed), str(killed["last_result"])])

	# **The house down**: the loss either way, and the hold only with the boss
	# alive.
	var fell_alive := _a_boss_night_near_dawn(1532, 600)
	fell_alive["house_hp"] = 1
	Entities.spawn(fell_alive, &"walker", House.porch(fell_alive))
	for _t in 600:
		if int(fell_alive["phase"]) != Phases.NIGHT:
			break
		Sim.advance(fell_alive, 1)
	expect(not bool((fell_alive["last_result"] as Dictionary).get("survived", true))
		and not bool((fell_alive["last_result"] as Dictionary).get("escaped", true))
		and not (Rewards.last(fell_alive)["lost"] as Dictionary).is_empty()
		and Calendar.date(fell_alive) == 14,
		"the house down with the boss alive: lost, and the season holds",
		"date %d, %s" % [Calendar.date(fell_alive), str(fell_alive["last_result"])])
	var fell_after := _a_boss_night_near_dawn(1533, 600)
	(fell_after["killed_by_kind"] as Dictionary)[Calendar.boss_of(14)] = 1
	fell_after["house_hp"] = 1
	Entities.spawn(fell_after, &"walker", House.porch(fell_after))
	for _t in 600:
		if int(fell_after["phase"]) != Phases.NIGHT:
			break
		Sim.advance(fell_after, 1)
	expect(not bool((fell_after["last_result"] as Dictionary).get("survived", true))
		and Calendar.date(fell_after) == 15,
		"the house down after the boss fell: lost, and no hold",
		"date %d" % Calendar.date(fell_after))

	# **`boss_arrived` by what it is**, and `waves.gd` names no enemy.
	var arrives := State.create(1534)
	arrives["day"] = GameData.SEASON_DAYS
	NightRoad.to_night(arrives)
	arrives["house_hp"] = 1 << 20
	var announced := false
	for _t in 6000:
		if int(arrives["phase"]) != Phases.NIGHT:
			break
		Sim.advance(arrives, 1)
		for event in (arrives["events"] as Array):
			if StringName((event as Dictionary).get("kind", &"")) == &"boss_arrived" \
					and StringName((event as Dictionary).get("enemy", &"")) == &"giant":
				announced = true
		if announced:
			break
	var code := SuiteKit.code_lines_of("res://src/core/waves.gd")
	expect(announced and not code.contains("&\"giant\""),
		"boss_arrived is raised for the Giant through is_boss, and waves.gd names no enemy")
	_completed += 1


## 0154 - the calm night after a boss: the first night of a season, but not
## the game's first, sends nothing, is won on its first tick, and pays only
## the gift on the porch.
func _task_0154_calm() -> void:
	var calm: Array = []
	for day in [1, 14, 15, 16, 29, 43, 57]:
		if Calendar.is_calm(day):
			calm.append(day)
	expect(calm == [15, 29, 43, 57], "dates 15, 29, 43 and 57 are calm, and 1, 14, 16 not",
		str(calm))
	var record := Waves.night_of(29, 3)
	expect(bool(record.get("calm", false)) and (record["waves"] as Array).is_empty()
		and int(record["opening_ticks"]) == 0 and GameData.check_nights([record]).is_empty()
		and not GameData.check_nights([{"note": "x", "opening_ticks": 0, "waves": []}]).is_empty(),
		"a calm record sends nothing, says so, and is the only empty record the check allows")
	expect(Waves.summary_of(15).contains("calm"), "and the summary prints it as calm",
		Waves.summary_of(15))
	expect(GameData.check_gift({GameData.MONEY: 5}).size() == 1
		and GameData.check_gift({GameData.TECH: 1}).size() == 1
		and GameData.check_gift({&"unobtainium": 1}).size() == 1
		and GameData.check_gift(GameData.CALM_NIGHT_GIFT).is_empty(),
		"the gift may not be money, technology or something unknown")

	# **The night still happens**: the build step, START, and a night with
	# nothing in it - won on its first tick, nobody spawned.
	var state := State.create(1540)
	state["day"] = 15
	state["nights_won"] = 14
	(state["nights_paid"] as Array).assign([14])
	var held: Dictionary = (state["held"] as Dictionary).duplicate()
	NightRoad.into_build(state)
	expect(int(state["phase"]) == Phases.PREPARATION, "the build step opens as on any night")
	NightRoad.through_build(state)
	expect(int(state["phase"]) == Phases.NIGHT and int(state["night"]) == 15,
		"START begins night 15", str(state["night"]))
	Sim.tick(state)
	expect(int(state["phase"]) == Phases.RESULT
		and bool((state["last_result"] as Dictionary).get("survived", false))
		and int(state["killed"]) == 0 and Entities.count(state) == 0,
		"and it is won on its first tick, with nobody spawned",
		Phases.name_of(int(state["phase"])))

	# **It pays exactly the gift**, no technology, and the date is paid.
	var moved: Dictionary = {}
	for id in GameData.sorted_names(GameData.RESOURCES):
		var by := int((state["held"] as Dictionary).get(id, 0)) - int(held.get(id, 0))
		if by != 0:
			moved[id] = by
	expect(moved == GameData.CALM_NIGHT_GIFT and Tech.already_paid(state, 15)
		and int(Rewards.last(state).get("tech", -1)) == 0
		and bool(Rewards.last(state).get("calm", false)),
		"it pays exactly the gift, no technology, and the date is written down as paid",
		"%s against %s" % [str(moved), str(GameData.CALM_NIGHT_GIFT)])
	_completed += 1


## 0155 - losing costs what the plan says and nothing more: the calendar moves
## on (a boss night excepted), a quarter of the stock, the crops on the
## horde's routes, and what it broke stays broken.
func _task_0155_losing() -> void:
	# **The calendar moves on**, beside 0153's exception.
	var ordinary := _a_planted_route(1550, 5)
	_lose_now(ordinary)
	(ordinary["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(ordinary, 2)
	NightRoad.to_night(ordinary)
	expect(int(ordinary["night"]) == 6, "a lost night on day 5 leads to night 6",
		str(ordinary["night"]))
	var boss := _a_boss_night_near_dawn(1551, 600)
	_lose_now(boss)
	expect(Calendar.date(boss) == GameData.SEASON_DAYS,
		"and a lost Spring 14 with the boss alive leads to Spring 14 again",
		str(Calendar.date(boss)))

	# **A quarter of each stock, as before** (`_loss`, untouched).
	var taxed := _a_planted_route(1552, 3)
	var held: Dictionary = (taxed["held"] as Dictionary).duplicate()
	_lose_now(taxed)
	var off: Array = []
	for id in GameData.sorted_names(held.keys()):
		var keep: bool = id == GameData.ENERGY or (id == GameData.MONEY and GameData.DEFEAT_KEEPS_MONEY) \
			or (id == GameData.TECH and GameData.DEFEAT_KEEPS_TECH)
		var want: int = int(held[id]) if keep \
			else int(held[id]) - int(held[id]) * GameData.DEFEAT_LOSS_PERCENT / 100
		if int((taxed["held"] as Dictionary)[id]) != want:
			off.append(id)
	expect(off.is_empty(), "a quarter of each stock is taken, money and technology kept",
		str(off))

	# **Trampled on the route, and only there**: the east route worked out
	# here the way the rules do - down the flow field from every spawn cell
	# - with nobody on the farm to add a cell.
	var farm := _a_planted_route(1553, 1)
	var route := _route_cells(farm, [0])
	_lose_now(farm)
	var wrong: Array = []
	var trampled := 0
	var spared := 0
	var plotted: Array = (farm["plots"] as Dictionary).keys()
	plotted.sort()
	for idx in plotted:
		var here: Dictionary = (farm["plots"] as Dictionary)[idx]
		var on := route.has(int(idx))
		if on and (StringName(here["crop"]) != &"" or StringName(here.get("trampled", &"")) != &"carrot"):
			wrong.append(["kept", Grid.cell(int(idx))])
		elif not on and StringName(here["crop"]) != &"carrot":
			wrong.append(["lost", Grid.cell(int(idx))])
		if on:
			trampled += 1
		else:
			spared += 1
	expect(wrong.is_empty() and trampled > 0 and spared > 0
		and int(Rewards.last(farm).get("trampled", -1)) == trampled,
		"every plot on the east route is trampled (%d) and none beside it (%d)"
			% [trampled, spared], str(wrong.slice(0, 4)))
	var flat := -1
	for idx in route.keys():
		if (farm["plots"] as Dictionary).has(int(idx)):
			flat = int(idx)
			break
	expect(flat >= 0 and Farming.is_tilled(farm, Grid.cell(flat))
		and Farming.crop_on(farm, Grid.cell(flat)) == &"",
		"a trampled plot is still tilled, empty ground, ready to plant again")

	# **Two copies, the same cells.**
	var one := _a_planted_route(1554, 1)
	var two: Dictionary = one.duplicate(true)
	_lose_now(one)
	_lose_now(two)
	expect(str(one["plots"]) == str(two["plots"]), "two copies of a state trample the same cells")

	# **A won night tramples nothing.**
	var won := _a_planted_route(1555, 1)
	var before := str(won["plots"])
	Rewards.settle(won, true)
	Phases.enter_result(won, true)
	expect(str(won["plots"]) == before, "a won night tramples nothing")

	# **What it broke stays broken**: a wall destroyed in the night is gone
	# in the morning - the rubble swept, nothing refunded.
	var walled := _a_planted_route(1556, 2)
	var spot := SuiteKit.any_buildable(walled)
	Farm.place(walled, spot, {"id": &"wall", "hp": 30})
	Farm.damage(walled, spot, 999)
	var wood := Resources.amount(walled, GameData.WOOD)
	_lose_now(walled)
	(walled["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(walled, 2)
	expect(int(walled["phase"]) == Phases.DAY and Farm.occupant(walled, spot).is_empty()
		and Farm.rubble_at(walled, spot) == &""
		and Resources.amount(walled, GameData.WOOD) <= wood,
		"a wall destroyed in the night is still gone the next morning, unrefunded")

	expect(GameData.TRAMPLE_REACH >= 0 and GameData.TRAMPLE_REACH <= 2,
		"TRAMPLE_REACH is inside 0-2", str(GameData.TRAMPLE_REACH))
	_completed += 1


## A night begun through `NightRoad` on `day`, parked with nobody on the farm,
## and carrots planted on every cell of the east route and on every cell
## beside it.
func _a_planted_route(seed_value: int, day: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = day
	state["nights_won"] = day - 1
	Resources.gain(state, {GameData.WOOD: 100, GameData.STONE: 80,
		GameData.IRON: 40, GameData.FOOD: 40, GameData.MONEY: 60})
	NightRoad.to_night(state)
	NightRoad.park(state)
	var plots: Dictionary = state["plots"]
	var route := _route_cells(state, [0])
	var beside := {}
	for idx in route.keys():
		var c := Grid.cell(int(idx))
		for step in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var n: Vector2i = c + step
			if Grid.in_bounds(n) and not route.has(Grid.index(n)):
				beside[Grid.index(n)] = true
	for idx in route.keys() + beside.keys():
		if Farm.is_empty(state, Grid.cell(int(idx))):
			plots[int(idx)] = {"crop": &"carrot", "growth": 30, "watered": false}
	return state


## The east route as the rules work it out: down the flow field from every
## spawn cell of the regions, to the house. A set of cell indices.
func _route_cells(state: Dictionary, regions: Array) -> Dictionary:
	Pathing.refresh(state)
	var out := {}
	for where in regions:
		for start in Enemies.spawn_cells(state, int(where)):
			var c: Vector2i = start
			for _i in Grid.CELLS:
				out[Grid.index(c)] = true
				var next := Pathing.step_from(state, c)
				if next == c:
					break
				c = next
	return out


## The house down, now: the loss, through the rules' own road.
func _lose_now(state: Dictionary) -> void:
	state["house_hp"] = 0
	Rewards.settle(state, false)
	Phases.enter_result(state, false)


## 0156 - the 1.0 farm map: spawn ground, the new nodes and stumps, named
## ponds, kept sites, and a version 5 save brought onto it without moving
## anything on it.
func _task_0156_map_v1() -> void:
	expect(GameData.validate().is_empty(), "the tables validate on the 1.0 map",
		str(GameData.validate()))
	var farm := State.create(1560)
	Pathing.refresh(farm)

	# **Spawn ground**: every band cell walkable, empty and reachable.
	var bad: Array = []
	for side in GameData.sorted_names(GameData.SPAWN_BANDS.keys()):
		for pair in (GameData.SPAWN_BANDS[side] as Array):
			var cell := Vector2i(int(pair[0]), int(pair[1]))
			if not Farm.walkable(farm, cell) or not Farm.is_empty(farm, cell) \
					or not Pathing.reachable(farm, cell):
				bad.append([side, cell])
	expect(bad.is_empty() and GameData.SPAWN_BANDS.size() == 3,
		"the north, west and south bands are clear, walkable and reach the house", str(bad))

	# **The new nodes, under their final ids**, inert and stood beside.
	var missing: Array = []
	for id in GameData.UNGATHERED_NODES:
		var cells := Farm.cells_with(farm, id)
		if cells.is_empty():
			missing.append(id)
		for found in cells:
			var cell: Vector2i = found
			if (not Gathering.is_node(id) and Interact.verb_at(farm, cell) != &"") or Farm.walkable(farm, cell):
				missing.append("%s at %s is not inert" % [id, cell])
	expect(missing.is_empty(), "all reserved nodes are on the map and impassable; unlanded ones stay inert",
		str(missing))
	var pieces := {}
	for found in Farm.cells_with(farm, &"hardwood_stump"):
		var at: Array = Farm.occupant(farm, found as Vector2i)["anchor"]
		pieces[str(at)] = int(pieces.get(str(at), 0)) + 1
	var whole := true
	for key in pieces:
		if int(pieces[key]) != 4:
			whole = false
	expect(pieces.size() == 4 and whole and Building.size_of(&"hardwood_stump") == Vector2i(2, 2),
		"four stumps, each one thing over its 2x2 with its own anchor", str(pieces))

	# **The ponds by name**, and nothing on land.
	var named: Array = []
	for id in GameData.sorted_names(GameData.PONDS.keys()):
		var pair: Array = GameData.PONDS[id]
		named.append(Farm.pond_of(farm, Vector2i(int(pair[0]), int(pair[1]))))
	expect(named == GameData.sorted_names(GameData.PONDS.keys()) and named.size() == 3
		and Farm.pond_of(farm, Vector2i(5, 14)) == &"north_west_pond"
		and Farm.pond_of(farm, Farm.house_centre(farm)) == &""
		and Farm.pond_of(farm, Vector2i(39, 40)) == &"",
		"Farm.pond_of names three ponds from any of their water, and nothing on land",
		str(named))

	# **The sites are clear.**
	var taken: Array = []
	for id in GameData.sorted_names(GameData.MAP_SITES.keys()):
		var box: Array = GameData.MAP_SITES[id]
		for y in range(int(box[1]), int(box[1]) + int(box[3])):
			for x in range(int(box[0]), int(box[0]) + int(box[2])):
				if not Farm.is_empty(farm, Vector2i(x, y)):
					taken.append([id, Vector2i(x, y)])
	expect(taken.is_empty(), "the coop's, the barn's and the bin's room is clear", str(taken))

	# **The v5 golden comes up to v6 without moving anything on it.**
	var raw: Dictionary = Save._read("res://tools/goldens/run-v5.sav")
	var old: Dictionary = raw.get("state", {})
	var now := Save.step_up(old, 5, 6, Save.migrations())
	expect(int(old.get("version", 0)) == 5 and int(now.get("version", 0)) == 6,
		"the v5 map migration reaches version 6", "%s to %s" % [old.get("version"), now.get("version")])
	var moved: Array = []
	var cleared := {}
	for idx in Save._ground_the_1_0_farm_clears():
		cleared[int(idx)] = true
	var was: Dictionary = old.get("occupants", {})
	var is_now: Dictionary = now.get("occupants", {})
	for idx in was.keys():
		var before: Dictionary = was[idx]
		var gone_on_purpose := cleared.has(int(idx)) and not before.has("hp") \
			and StringName(before["id"]) in [&"tree", &"rock"]
		if gone_on_purpose:
			continue
		if not is_now.has(idx) or str(is_now[idx]) != str(before):
			moved.append(["occupant", Grid.cell(int(idx))])
	var old_plots: Dictionary = old.get("plots", {})
	for idx in old_plots.keys():
		if str((now.get("plots", {}) as Dictionary).get(idx, {})) != str(old_plots[idx]):
			moved.append(["plot", Grid.cell(int(idx))])
	var landed: Array = []
	for idx in is_now.keys():
		if was.has(idx):
			continue
		var id := StringName((is_now[idx] as Dictionary)["id"])
		if not id in GameData.UNGATHERED_NODES or old_plots.has(idx):
			landed.append([id, Grid.cell(int(idx))])
	expect(moved.is_empty(), "every plot and every occupant the save had is where it was",
		str(moved.slice(0, 4)))
	expect(landed.is_empty(), "and only the new nodes were laid, on cells that were empty",
		str(landed.slice(0, 4)))
	var at := int(now["tick"])
	Sim.advance(now, 600)
	expect(int(now["tick"]) == at + 600, "and it plays 600 ticks")

	# **A save's touched tree stays; an untouched one leaves the band.**
	var v5 := State.create(1561)
	var band: Array = GameData.SPAWN_BANDS[&"north"][1]
	var band_cell := Vector2i(int(band[0]), int(band[1]))
	(v5["occupants"] as Dictionary)[Grid.index(band_cell)] = {"id": &"tree"}
	var west_band: Array = GameData.SPAWN_BANDS[&"west"][8]
	var hurt_cell := Vector2i(int(west_band[0]), int(west_band[1]))
	(v5["occupants"] as Dictionary)[Grid.index(hurt_cell)] = {"id": &"tree", "hp": 2}
	(v5["regrowing"] as Array).append([Grid.index(band_cell + Vector2i(1, 0)), 50, "tree"])
	v5["version"] = 5
	var stepped := Save._farm_v1_0_from_v5(v5)
	expect(Farm.is_empty(stepped, band_cell)
		and StringName(Farm.occupant(stepped, hurt_cell).get("id", &"")) == &"tree"
		and (stepped["regrowing"] as Array).is_empty(),
		"an untouched map tree leaves a band, a chopped-at one stays, and nothing regrows there")

	# **Every golden loads.**
	var golden_trouble: Array = []
	for name in DirAccess.get_files_at("res://tools/goldens"):
		if String(name).ends_with(".sav") \
				and Save.read_run_at("res://tools/goldens/" + String(name)).is_empty():
			golden_trouble.append(name)
	expect(golden_trouble.is_empty(), "every golden loads", str(golden_trouble))
	_completed += 1


## 0157 - a new side every season: the table, the generated nights dealt
## from open sides only, a spawn for every region, and 0115's guarantee on
## the three new ones.
func _task_0157_sides() -> void:
	# **The open sides are the table's.**
	var firsts := [Calendar.open_sides(1), Calendar.open_sides(15),
		Calendar.open_sides(29), Calendar.open_sides(43)]
	expect(firsts == GameData.SIDES_BY_SEASON and firsts == [[0], [0, 1], [0, 1, 2],
		[0, 1, 2, 3, 4]],
		"Spring 1, Summer 1, Autumn 1 and Winter 1 open the table's sides", str(firsts))
	expect(GameData.SPAWNS.size() == 5 and GameData.SPAWN_SIDES.size() == 5
		and GameData.SPAWN_SIDES[2] == &"north" and GameData.SPAWN_SIDES[4] == &"south",
		"five regions, named east, south east, north, west and south")
	expect(GameData.check_sides(GameData.SPAWNS, GameData.SPAWN_SIDES,
		[[0], [1], [0, 1, 2], [0, 1, 2, 3, 4]]).size() > 0
		and GameData.check_sides(GameData.SPAWNS, GameData.SPAWN_SIDES,
			[[0], [0, 1], [0, 9], [0, 1, 2, 3, 4]]).size() > 0,
		"a season that closes a side, or opens one that is not there, is refused")

	# **Every generated wave from an open side**, dates 11-56, two seeds.
	var stray: Array = []
	for seed_value in [5, 424242]:
		for day in range(11, Calendar.year_days() + 1):
			if not Endless.is_generated(day):
				continue
			var open := Calendar.open_sides(day)
			for row in (Waves.plain_night(day, seed_value).get("waves", []) as Array):
				if not open.has(int((row as Array)[2])):
					stray.append([seed_value, day, row])
	expect(stray.is_empty(), "every generated wave of dates 11-56 comes from a side open that day",
		str(stray.slice(0, 3)))
	var a_side_rule := [{"note": "x", "opening_ticks": 0, "waves": [[&"walker", 3, 4]]}]
	expect(not GameData.check_nights(a_side_rule).is_empty(),
		"and check_nights refuses a spring night from the south")

	# **Every region has somewhere to stand** on a fresh farm.
	var farm := State.create(1570)
	var empty: Array = []
	for region in GameData.SPAWNS.size():
		if Enemies.spawn_cells(farm, region).is_empty():
			empty.append(region)
	expect(empty.is_empty(), "every region has spawn cells on a fresh farm", str(empty))

	# **0115's guarantee, for regions 2-4**: each built over as far as the
	# rules allow, a few walkers from it all accounted for, and the night
	# over in bounded ticks.
	for region in [2, 3, 4]:
		var state := State.create(1571 + region)
		state["day"] = 30
		state["nights_won"] = 29
		Resources.gain(state, {GameData.WOOD: 5000, GameData.STONE: 5000})
		Phases.begin_preparation(state)
		var fenced := 0
		for pair in (GameData.SPAWNS[region] as Array):
			if Building.place(state, &"fence", Vector2i(int(pair[0]), int(pair[1]))):
				fenced += 1
		var record := {"note": "four walkers from one side", "opening_ticks": 0,
			"waves": [[&"walker", 4, region]], "for_night": 30}
		(state["wave"] as Dictionary)["tonight"] = record
		NightRoad.through_build(state)
		state["house_hp"] = 100000
		var ticks := 0
		while int(state["phase"]) == Phases.NIGHT and ticks < 6000:
			Sim.tick(state)
			ticks += 1
		var to_come := Waves.remaining(state) - Entities.count(state)
		var counted := int(state["killed"]) + int(state["breaches"]) \
			+ Entities.count(state) + to_come
		expect(fenced > 0 and int(state["phase"]) != Phases.NIGHT and counted == 4,
			"region %d fenced over (%d cells): four walkers accounted for, the night over in %d ticks"
				% [region, fenced, ticks],
			"%d counted, %s" % [counted, Phases.name_of(int(state["phase"]))])

	# **The preview's routes** (`Pathing.routes_if_blocked`): one field, every
	# start walked on it - the same cells, in order, as asking of each start
	# alone. On Winter 2 that is five starts, each a route of its own.
	var winter := State.create(1577)
	winter["day"] = 3 * GameData.SEASON_DAYS + 2
	var starts: Array = []
	for side in Calendar.open_sides(int(winter["day"])):
		starts.append(Enemies.spawn_cells(winter, int(side))[0])
	var blocked := Vector2i(-1, -1)
	for radius in 6:
		for candidate in Grid.within(Farm.house_centre(winter) + Vector2i(0, 4), radius):
			if blocked.x < 0 and Farm.buildable(winter, candidate):
				blocked = candidate
	var together := Pathing.routes_if_blocked(winter, blocked, starts, 120)
	var one_by_one: Array = []
	var each_moves := true
	for start in starts:
		var alone := Pathing.route_if_blocked(winter, blocked, start, 120)
		each_moves = each_moves and not alone.is_empty()
		one_by_one.append_array(alone)
	expect(starts.size() == 5 and blocked.x >= 0 and each_moves and together == one_by_one,
		"on Winter 2 the preview walks one field from five starts, each a route of its own",
		"%d starts, %d cells against %d" % [starts.size(), together.size(), one_by_one.size()])
	_completed += 1


## 0158 - the forecast: what it says is what the night sends, a boss date
## names the season's boss, and asking it a thousand times moves nothing.
func _task_0158_forecast() -> void:
	# **What it says is what comes.** A plain authored night from the south
	# east, a generated Full Moon from two sides and a calm night, each sent
	# through the real road - `Waves.tick` and `Enemies.spawn` - with the gaps
	# skipped and every arrival counted and taken off where it lands, until
	# the last wave is out.
	var where := {}
	for region in GameData.SPAWNS.size():
		for pair in (GameData.SPAWNS[region] as Array):
			where[Vector2i(int(pair[0]), int(pair[1]))] = region
	for date in [3, GameData.SEASON_DAYS + 7, GameData.SEASON_DAYS + 1]:
		var state := State.create(1580)
		state["day"] = date
		state["nights_won"] = date - 1
		var said := Forecast.tonight(state)
		NightRoad.to_night(state)
		var sent := {}
		var order: Array = []
		var sides: Array = []
		var lost := 0
		var ticks := 0
		var wave: Dictionary = state["wave"]
		while int(state["phase"]) == Phases.NIGHT and not bool(wave["done"]) 				and ticks < 4000:
			wave["wait"] = 0
			Sim.tick(state)
			ticks += 1
			for id in Entities.ids(state):
				var one := Entities.get_one(state, id)
				var kind := StringName(one.get("kind", &""))
				if not sent.has(kind):
					sent[kind] = 0
					order.append(kind)
				sent[kind] = int(sent[kind]) + 1
				var side := int(where.get(Entities.cell_of(state, id), -1))
				if side < 0:
					lost += 1
				elif not sides.has(Forecast.side_id(side)):
					sides.append(Forecast.side_id(side))
				Entities.remove(state, id)
		var came: Array = []
		var total := 0
		for kind in order:
			came.append([kind, int(sent[kind])])
			total += int(sent[kind])
		var named: Array = []
		for side in GameData.SPAWN_SIDES:
			if sides.has(side):
				named.append(side)
		expect(said["kinds"] == came and int(said["count"]) == total
			and said["sides"] == named and lost == 0 and bool(wave["done"]),
			"date %d: the forecast's kinds, count and sides are what the night sent (%d ticks)"
				% [date, ticks],
			"said %s %d %s, sent %s %d %s" % [said["kinds"], said["count"], said["sides"],
				came, total, named])
		expect(int(said["date"]) == date and said["season"] == Calendar.season_id(date)
			and int(said["day_of_season"]) == Calendar.day_of_season(date)
			and said["event"] == &"",
			"date %d: its date, season and day, and no event yet" % date, str(said))
	var moon := Forecast.of(1580, GameData.SEASON_DAYS + 7)
	var calm := Forecast.of(1580, GameData.SEASON_DAYS + 1)
	expect(bool(moon["full_moon"]) and not bool(moon["calm"]) and int(moon["waves"]) > 0
		and bool(calm["calm"]) and int(calm["count"]) == 0 and int(calm["waves"]) == 0
		and (calm["sides"] as Array).is_empty(),
		"Summer 7 forecasts a Full Moon, Summer 1 a calm night with nothing in it")

	# **A boss date names the season's boss**, every season of the year.
	var bosses: Array = []
	for season in GameData.SEASONS.size():
		var date := (season + 1) * GameData.SEASON_DAYS
		var one := Forecast.of(77, date)
		var has := false
		for pair in (one["kinds"] as Array):
			if StringName((pair as Array)[0]) == StringName(one["boss"]):
				has = true
		if StringName(one["boss"]) == &"" or StringName(one["boss"]) != Calendar.boss_of(date) 				or not has or not bool(one["full_moon"]):
			bosses.append([date, one["boss"]])
	expect(bosses.is_empty(),
		"each season's last night forecasts its boss, among its kinds, under a Full Moon",
		str(bosses))
	expect((Forecast.of(77, 4 * GameData.SEASON_DAYS)["sides"] as Array).size()
		== GameData.SPAWN_SIDES.size(), "and Winter 14 comes from every side")

	# **Asking moves nothing**: the run's stream and the whole state.
	var asked := State.create(1581)
	asked["day"] = GameData.SEASON_DAYS + 3
	var rng_before: Array = (asked["rng"] as Array).duplicate()
	var hash_before := State.hash_of(asked)
	var first := Forecast.tonight(asked)
	var same := true
	for _i in 1000:
		same = same and Forecast.tonight(asked) == first
	expect(asked["rng"] == rng_before and State.hash_of(asked) == hash_before and same,
		"a thousand forecasts leave the run's stream and the state hash as they were")
	_completed += 1


## 0159 - the seasons' tables: every grass or foliage colour the terrain and
## the trees use has a mapping in every season, onto the palette's own
## entries - and a table missing one is caught; the season on screen follows
## the date and holds the night's under the morning report; the seasonal
## lookups the art packs will fill.
func _task_0159_palette() -> void:
	var used := _foliage_in(["res://sprites/terrain/", "res://sprites/props/tree.png",
		"res://sprites/props/tree_b.png"])
	expect(used.has(&"grass") and used.has(&"leaf") and used.has(&"grass_dark"),
		"the terrain and the trees are drawn in grass and foliage", str(used))
	expect(SeasonView.unmapped(PaletteData.SEASON_REMAP, used).is_empty(),
		"every one of them has a mapping in every season",
		str(SeasonView.unmapped(PaletteData.SEASON_REMAP, used)))
	var scratch: Dictionary = PaletteData.SEASON_REMAP.duplicate(true)
	(scratch[&"autumn"] as Dictionary).erase(&"grass")
	expect(SeasonView.unmapped(scratch, used) == ["autumn: grass"],
		"and a scratch autumn without its grass is caught",
		str(SeasonView.unmapped(scratch, used)))
	var stray: Array = []
	var pale := [&"bone", &"bone_dark", &"moon", &"stone_light"]
	for season_id in GameData.SEASONS:
		var table: Dictionary = PaletteData.SEASON_REMAP[season_id]
		for colour in PaletteData.FOLIAGE:
			var to: StringName = table.get(colour, colour)
			if not PaletteData.COLOURS.has(to) \
					or (season_id == &"spring" and to != colour) \
					or (season_id == &"winter" and not pale.has(to)):
				stray.append("%s: %s -> %s" % [season_id, colour, to])
	expect(stray.is_empty(),
		"onto palette entries only: spring is today's art and winter the pale colours",
		str(stray))

	# **The season on screen**, and the morning report keeps the night's.
	var state := State.create(1590)
	var seen: Array = []
	for day in [3, 17, 31, 45, Calendar.year_days() + 1]:
		state["day"] = day
		seen.append(SeasonView.season_on_screen(state))
	expect(seen == [0, 1, 2, 3, 0], "the date's season: spring, summer, autumn, winter, spring",
		str(seen))
	state["day"] = GameData.SEASON_DAYS + 1
	state["night"] = GameData.SEASON_DAYS
	state["phase"] = Phases.RESULT
	var under_report := SeasonView.season_on_screen(state)
	state["phase"] = Phases.DAY
	expect(under_report == 0 and SeasonView.season_on_screen(state) == 1,
		"under Spring 14's morning report it is still spring; summer comes with the day",
		"%d, then %d" % [under_report, SeasonView.season_on_screen(state)])

	# **The lookups the packs fill in**: stand-ins today, the base frame
	# where a season has none, and the caps by host.
	expect(SeasonView.frame_for("props/tree", 0) == "props/tree_spring"
		and SeasonView.frame_for("props/tree_b", 3) == "props/tree_b_winter"
		and SeasonView.frame_for("props/tree", 1) == "props/tree"
		and SeasonView.stand_in("props/tree_b_winter")
		and not SeasonView.carries_season("props/tree", 3)
		and SeasonView.texture_file("props/tree_winter") == "res://sprites/props/tree.png",
		"a tree's season is A013's stand-in, drawn as today's tree; summer is today's")
	expect(SeasonView.frame_for("terrain/atlas", 3) == "terrain/atlas_winter"
		and SeasonView.stand_in("terrain/atlas_winter")
		and SeasonView.frame_for("terrain/atlas", 2) == "terrain/atlas"
		and SeasonView.frame_for("crops/tilled", 3) == "crops/tilled_winter",
		"the winter ground is A012's stand-in, and autumn has none")
	expect(SeasonView.cap_for(&"rock_b", false) == "props/rock_b_snow"
		and SeasonView.cap_for(&"copper_ore", false) == "props/snow_cap"
		and SeasonView.cap_for(&"hardwood_stump", true) == "props/snow_cap_2x2",
		"a node's snow cap is its own, or the generic one")
	_completed += 1


## The grass and foliage colours (`PaletteData.FOLIAGE`) drawn in these files
## - a folder's every PNG, or one file.
func _foliage_in(paths: Array) -> Array:
	var names := {}
	for name in PaletteData.COLOURS:
		names[(PaletteData.COLOURS[name] as Color).to_rgba32()] = StringName(name)
	var files: Array = []
	for path in paths:
		if str(path).ends_with(".png"):
			files.append(path)
			continue
		for file in DirAccess.get_files_at(path):
			if file.ends_with(".png"):
				files.append(str(path) + file)
	var found: Array = []
	for file in files:
		var image := Image.load_from_file(ProjectSettings.globalize_path(file))
		if image == null:
			continue
		for y in image.get_height():
			for x in image.get_width():
				var colour := image.get_pixel(x, y)
				if colour.a < 0.5:
					continue
				colour.a = 1.0
				var name: StringName = names.get(colour.to_rgba32(), &"")
				if PaletteData.FOLIAGE.has(name) and not found.has(name):
					found.append(name)
	found.sort()
	return found


## 0160 - Winter 14 ends the year only after its boss falls, including a
## house lost afterwards. Fixtures cross the actual night and morning road.
func _task_0160_year_end() -> void:
	for outcome in ["won", "escaped", "lost", "lost_after_boss"]:
		var state := State.create(1600)
		state["day"] = Calendar.year_days() + 3
		state["days_held"] = 3
		NightRoad.to_night(state)
		NightRoad.park(state)
		var down: bool = outcome in ["won", "lost_after_boss"]
		if down:
			(state["killed_by_kind"] as Dictionary)[Calendar.boss_of(Run.final_night())] = 1
		if outcome.begins_with("lost"):
			state["house_hp"] = 0
		(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 2
		Sim.advance(state, 4)
		expect(int(state["phase"]) == Phases.RESULT and Run.is_over(state) == down,
			"Winter 14 %s: only the fallen boss ends the year" % outcome)
		expect(bool((state["last_result"] as Dictionary).get("run_over", false)) == down,
			"the result records the ending, even after a house loss (%s)" % outcome)
		expect(Calendar.date(state) == (57 if down else 56),
			"the date leaves winter only with the boss down (%s)" % outcome)
		var profile := Run.record(state, Save.default_profile())
		expect(int(profile["runs_won"]) == (1 if down else 0),
			"record counts completed years (%s)" % outcome)
		expect(Run.go_endless(state) == down and not Run.is_over(state),
			"carry on opens only after the year is beaten (%s)" % outcome)
		if down:
			(state["intent"] as Dictionary)["confirm_result"] = true
			Sim.advance(state, 2)
			expect(Calendar.year_of(Calendar.date(state)) == 2
				and Calendar.season_of(Calendar.date(state)) == 0
				and Calendar.day_of_season(Calendar.date(state)) == 1,
				"carry on wakes on Year 2 Spring 1")
			NightRoad.to_night(state)
			expect(int(state["night"]) == 57 and Calendar.is_calm(int(state["night"])),
				"the next night is date 57 and calm")
			Sim.advance(state, 2)
			expect(not Run.is_over(state) and bool(Rewards.last(state).get("calm", false)),
				"the calm night resolves and endless does not end again")
	_completed += 1


## 0165 - watered mornings, missed chores, held dates and old saves.
func _task_0165_days() -> void:
	var state := State.create(1650)
	SuiteKit.crop_supplies(state, GameData.CARROT)
	var cells := Farming.field_cells(state)
	for cell in [cells[0], cells[1]]:
		Farming.act(state, cell)
		Farming.act(state, cell)
	state["water_can"] = 2
	Farming.act(state, cells[0])
	Sim.advance(state, 60)
	expect(int(Farming.plot(state, cells[0])["growth"]) == 0,
		"even watered crops do not grow per tick")
	Farming.dry_out(state)
	Farming.morning(state)
	expect(int(Farming.plot(state, cells[0])["growth"]) == 1
		and int(Farming.plot(state, cells[1])["growth"]) == 0,
		"watered and dry carrots differ by one day after the first morning")
	Farming.morning(state)
	expect(int(Farming.plot(state, cells[0])["growth"]) == 1,
		"the same morning cannot credit a plot twice")
	for day in [2, 3]:
		state["water_can"] = 1
		Farming.act(state, cells[0])
		Farming.dry_out(state)
		Farming.morning(state)
		expect(Farming.is_ready(state, cells[0]) == (day == 3),
			"carrot ripens on its third watered morning")
	expect(Farming.crop_on(state, cells[1]) == &"carrot"
		and int(Farming.plot(state, cells[1])["growth"]) == 0,
		"three missed chores leave the dry carrot alive and unchanged")
	var ready_events := 0
	for event in Events.since(state, 0):
		if event["kind"] == &"crop_ready":
			ready_events += 1
	expect(ready_events == 1, "ripening emits exactly one crop_ready event")

	for collapse in [false, true]:
		var overnight := State.create(1651)
		var cell: Vector2i = Farming.field_cells(overnight)[0]
		Farming.act(overnight, cell)
		Farming.act(overnight, cell)
		overnight["water_can"] = 1
		Farming.act(overnight, cell)
		overnight["day"] = 14 # A living boss holds the date, but not crop growth.
		if collapse:
			Phases.pass_out(overnight)
		else:
			Phases.go_to_bed(overnight)
		Phases.start_waves(overnight)
		Phases.enter_result(overnight, false)
		Phases.begin_day(overnight)
		expect(Calendar.date(overnight) == 14
			and int(Farming.plot(overnight, cell)["growth"]) == 1,
			"bed and pass-out both credit a morning even on a held boss date")

	# A real v6 golden supplies the saved farm; only its crop ages are varied.
	var legacy: Dictionary = Save._read("res://tools/goldens/run-v6.sav")["state"]
	var idx := Grid.index(cells[0])
	legacy["plots"][idx] = {"crop": &"wheat", "growth": 1350, "watered": true, "soak": 99}
	var ready_idx := Grid.index(cells[1])
	legacy["plots"][ready_idx] = {"crop": &"carrot", "growth": 1800, "watered": false, "soak": 0}
	var path := "user://task0165-legacy.sav"
	expect(Save.write_run_at(path, legacy), "the half-grown legacy golden writes")
	var loaded := Save.read_run_at(path)
	expect(int(loaded["plots"][idx]["growth"]) == 2
		and not loaded["plots"][idx].has("soak"), "half-grown wheat becomes two days without a soak bank")
	expect(Farming.is_ready(loaded, cells[1]), "a ready legacy carrot stays ready")
	legacy["plots"][idx]["growth"] = 1349
	var floored := Save.step_up(legacy, 6, 7, Save.migrations())
	expect(int(floored["plots"][idx]["growth"]) == 1, "fractional legacy days round down")
	Save._remove(path)
	Save._remove(path + ".bak")

	# A saved pending credit survives load, but is consumed only once.
	Farming.dry_out(loaded)
	expect(Save.write_run_at(path, loaded), "a pending morning can be saved")
	loaded = Save.read_run_at(path)
	Farming.morning(loaded)
	Farming.morning(loaded)
	expect(int(loaded["plots"][idx]["growth"]) == 3, "reload preserves one pending credit")
	Save._remove(path)
	Save._remove(path + ".bak")
	_completed += 1


## 0166 - a longer clock preserves daily production capacity.
func _task_0166_long_day() -> void:
	var state := State.create(1660)
	expect(GameData.DAY_TICKS == 16800 and GameData.DAY_TICKS / GameData.TICK_HZ == 560,
		"a day lasts nine minutes and twenty seconds")
	for boundary in [[0, 360], [GameData.DUSK_AT_TICK, 1080], [GameData.DAY_TICKS, 1560]]:
		state["day_tick"] = boundary[0]
		expect(Phases.clock_minute(state) == int(boundary[1]),
			"long-day clock maps boundary %d to minute %d" % boundary)
		expect(Phases.tick_at_minute(int(boundary[1])) == int(boundary[0]),
			"the clock inverse preserves that boundary")
	expect(GameData.check_clock(360, 1080, 1560, GameData.DAY_TICKS).is_empty(),
		"the long day has whole ticks per game minute")
	# Nominal steady-state capacity: unlimited inputs, full power, no travel.
	# A fresh morning loses its last production tick to pass-out, so exact
	# divisors can deliver one batch fewer. Both limits are in the journal.
	var batches := {&"barricade_kit": 40, &"fence_kit": 48, &"mine_kit": 30,
		&"wall_kit": 24, &"press_oil": 12, &"press_fish_oil": 9,
		&"make_incendiary": 24, &"make_gunpowder": 16,
		&"cook_meal": 20, &"cook_fish": 16, &"cook_roast": 13, &"make_bait": 48}
	var units := {&"barricade_kit": 40, &"fence_kit": 48, &"mine_kit": 30,
		&"wall_kit": 24, &"press_oil": 12, &"press_fish_oil": 9,
		&"make_incendiary": 96, &"make_gunpowder": 32,
		&"cook_meal": 40, &"cook_fish": 48, &"cook_roast": 52, &"make_bait": 192}
	var ordinary := 0
	for id in GameData.RECIPES:
		if GameData.tool_output(GameData.RECIPES[id]["output"].keys()[0]).is_empty():
			ordinary += 1
	expect(batches.size() == ordinary, "every repeatable recipe has a daily budget; permanent upgrades are once per tier")
	for id in GameData.sorted_names(batches.keys()):
		var ticks := int(GameData.RECIPES[id]["ticks"])
		var per_batch := 0
		for amount in (GameData.RECIPES[id]["output"] as Dictionary).values():
			per_batch += int(amount)
		expect((GameData.DAY_TICKS / ticks) * per_batch == int(units[id]),
			"%s yields %d units/day nominal" % [id, units[id]])
		expect(GameData.DAY_TICKS / ticks == int(batches[id]),
			"%s: %d batches/day nominal" % [id, batches[id]])
		expect((GameData.DAY_TICKS - 1) / ticks >= int(batches[id]) - 1,
			"%s loses at most one batch at the pass-out boundary" % id)
	for id in [&"tree", &"ore", &"seam"]:
		var entry: Dictionary = GameData.GATHERING[id]
		var work := int(entry["work_ticks"]) * int(entry["hits"])
		var harvests := 1 + (GameData.DAY_TICKS - 1 - work) / (int(entry["regrow_ticks"]) + work)
		expect(harvests == (3 if id == &"seam" else 2),
			"%s gives its initial harvest and returns within the daily budget" % id)
	expect(int(GameData.GATHERING[&"rock"]["regrow_ticks"]) == 0,
		"cleared boulders remain cleared")
	for id in [&"cow", &"chicken"]:
		var ticks := int(GameData.LIVESTOCK[id]["every_ticks"])
		expect((GameData.DAY_TICKS - 1) / ticks == (2 if id == &"cow" else 4),
			"%s: collected promptly, 2 cow or 4 chicken meat before pass-out" % id)
	var bite_mean := (int(GameData.FISHING["bite_min_ticks"])
		+ int(GameData.FISHING["bite_max_ticks"])) / 2
	expect(GameData.DAY_TICKS / bite_mean == 40,
		"fishing retains forty mean waits per day before reaction and travel")
	# The 1.5-second window became the bar at task 0180: its run is seconds
	# of the wall clock, not a fraction of the longer day.
	expect(int(GameData.FISHING["bar_ticks"]) == 10 * GameData.SECONDS,
		"the bar a bite opens runs ten seconds")
	var fuel := int(GameData.BUILDINGS[&"generator"]["fuel_every_ticks"])
	expect((GameData.DAY_TICKS - 2) / fuel + 1 == 4,
		"a continuously loaded generator consumes four oil before pass-out")
	expect(GameData.DAILY_STOCK[GameData.WOOD] == 15 and GameData.DAILY_STOCK[GameData.STONE] == 12 and GameData.DAILY_STOCK[GameData.IRON] == 8 and GameData.DAILY_STOCK[GameData.WHEAT] == 10 and GameData.DAILY_STOCK[GameData.CORN] == 8 and GameData.DAILY_STOCK[GameData.CARROT] == 12,
		"daily stock stays per day rather than scaling with real time")
	state["day_tick"] = 4200
	# 7 or later: 0179 bumped it to 8 for the fish, not for the clock.
	expect(Phases.clock_minute(state) == 11 * 60 and State.VERSION >= 7,
		"a saved 4200 ticks now reads 11:00; ticks and save version retain their meaning")
	_completed += 1


## 0167 - plots are overlays; only idle empty grass returns to lawn.
func _task_0167_till_grass() -> void:
	var state := State.create(1670)
	SuiteKit.crop_supplies(state, GameData.CARROT)
	var beds := Farm.cells_of(state, Farm.Terrain.SOIL)
	expect(Farming.field_cells(state) == beds, "untouched field preserves the starter-bed order")
	var cell := Vector2i(35, 20)
	expect(Farm.terrain_at(state, cell) == Farm.Terrain.GRASS and Farm.is_empty(state, cell),
		"the grass fixture is an empty lawn")
	Pathing.refresh(state)
	var version := int(state["grid_version"])
	var flow := int(state["flow_version"])
	var cost := Pathing.entry_cost(state, cell)
	var bytes: PackedByteArray = state["terrain"].duplicate()
	expect(Interact.verb_at(state, cell) == &"till", "bare grass offers the hoe")
	Farming.act(state, cell)
	Pathing.refresh(state)
	expect(Farming.is_tilled(state, cell) and state["terrain"] == bytes,
		"the hoe makes a plot without changing any terrain byte")
	expect(int(state["grid_version"]) == version and int(state["flow_version"]) == flow
		and Pathing.entry_cost(state, cell) == cost, "hoeing preserves grass cost and cached flow fields")
	var fields := Farming.field_cells(state)
	expect(fields.size() == beds.size() + 1 and fields.has(cell), "turned grass joins the field")
	for i in range(1, fields.size()):
		expect(Grid.index(fields[i - 1]) < Grid.index(fields[i]), "field cells remain in index order")
	Farming.act(state, beds[0])
	expect(Farming.plot(state, beds[0]) == Farming.EMPTY_PLOT,
		"soil keeps its old plot shape without a fade-age field")
	var planted := cell + Vector2i.RIGHT
	Farming.act(state, planted)
	Farming.act(state, planted)
	expect(Farming.crop_on(state, planted) != &"", "grass can be planted")
	var dawn := int(state["day"])
	for morning in range(1, GameData.TILLED_GRASS_FADES_DAYS + 1):
		state["day"] = dawn + morning
		Farming.morning(state)
		expect(Farming.is_tilled(state, cell) == (morning < GameData.TILLED_GRASS_FADES_DAYS),
			"empty lawn expires exactly at morning %d" % morning)
		expect(Farming.is_tilled(state, planted) and Farming.is_tilled(state, beds[0]),
			"planted grass and starter soil never fade")
	expect(not Farming.field_cells(state).has(cell), "faded grass leaves the field")
	# A legacy grass plot gets its missing age once, not a fresh age every dawn.
	Farming.act(state, cell)
	Farming.plot(state, cell).erase("last_worked_morning")
	Farming.morning(state)
	var legacy := int(state["day"])
	Farming.morning(state)
	expect(int(Farming.plot(state, cell)["last_worked_morning"]) == legacy,
		"a repeated morning and legacy default do not renew empty grass")
	state["day"] = legacy + GameData.TILLED_GRASS_FADES_DAYS
	Farming.morning(state)
	expect(not Farming.is_tilled(state, cell), "legacy grass fades from its first loaded morning")
	# Working a long-lived crop renews the eventual empty ground's age.
	state["water_can"] = 1
	Farming.act(state, planted)
	expect(Farming.is_watered(state, planted)
		and int(Farming.plot(state, planted)["last_worked_morning"]) == int(state["day"]),
		"successful watering records the real morning")
	Farming.plot(state, planted)["growth"] = Farming.days_to_grow(Farming.crop_on(state, planted))
	state["day"] = int(state["day"]) + 1
	Farming.act(state, planted)
	expect(Farming.crop_on(state, planted) == &""
		and int(Farming.plot(state, planted)["last_worked_morning"]) == int(state["day"]),
		"harvesting restarts the empty plot's fade age")
	state["day"] = int(state["day"]) + GameData.TILLED_GRASS_FADES_DAYS - 1
	Farming.morning(state)
	expect(Farming.is_tilled(state, planted), "a recently harvested plot gets the full grace period")
	Farming.act(state, planted)
	state["day"] = int(state["day"]) + 10
	Farming.trample(state, [planted])
	expect(int(Farming.plot(state, planted)["last_worked_morning"]) == int(state["day"]),
		"trampled grass gets time to be replanted after the loss")
	for terrain in [Farm.Terrain.PATH, Farm.Terrain.FLOOR, Farm.Terrain.WATER, Farm.Terrain.ROCK]:
		state["terrain"][Grid.index(cell)] = terrain
		Farming.act(state, cell)
		expect(not Farming.is_tilled(state, cell) and Farming.verb_at(state, cell) == &"",
			"terrain %d refuses the hoe" % terrain)
	state["terrain"][Grid.index(cell)] = Farm.Terrain.GRASS
	state["occupants"][Grid.index(cell)] = {"id": &"tree"}
	expect(Farming.verb_at(state, cell) == &"", "occupied grass refuses farming")
	state["occupants"].erase(Grid.index(cell))
	# Faced-only hoe, including the off-farm boundary; existing plots retain fallback.
	var who: Dictionary = state["player"]
	who["pos"] = [cell.x * Player.SUBTILE + Player.SUBTILE / 2,
		cell.y * Player.SUBTILE + Player.SUBTILE / 2]
	who["facing"] = Player.NORTH
	var ahead := cell + Vector2i.UP
	state["terrain"][Grid.index(ahead)] = Farm.Terrain.PATH
	expect(Player.target(state) == ahead and Interact.verb_at(state, Player.target(state)) == &"",
		"facing a path never hoes the grass underfoot")
	Farming.act(state, cell)
	expect(Player.target(state) == cell, "a turned grass plot retains underfoot planting")
	state["terrain"][Grid.index(cell)] = Farm.Terrain.PATH
	expect(Interact.verb_at(state, cell) == &"plant", "an existing plot works regardless of its terrain")
	who["pos"] = [Player.SUBTILE / 2, Player.SUBTILE / 2]
	state["terrain"][0] = Farm.Terrain.GRASS
	state["occupants"].erase(0)
	expect(Player.target(state) == Vector2i(0, -1), "the farm edge also refuses the bare-lawn fallback")
	# All side masks and a concave corner use today's terrain geometry.
	var border := State.create(1671)
	var middle := Vector2i(35, 20)
	for at in Grid.within(middle, 1):
		border["terrain"][Grid.index(at)] = Farm.Terrain.GRASS
		border["occupants"].erase(Grid.index(at))
	for mask in 16:
		border["plots"].clear()
		Farming.act(border, middle)
		for bit in 4:
			if not (mask & (1 << bit)):
				Farming.act(border, middle + Grid.STEPS[bit])
		expect(WorldView.tilled_edge_mask(border, middle) == mask, "turf side mask %d" % mask)
	border["plots"].clear()
	for at in Grid.within(middle, 1):
		if at != middle + Vector2i(-1, -1):
			Farming.act(border, at)
	expect(WorldView.tilled_corner_mask(border, middle) == 1, "a concave NW diagonal takes its corner cap")
	border["terrain"][Grid.index(middle + Vector2i(-1, -1))] = Farm.Terrain.SOIL
	expect(WorldView.tilled_corner_mask(border, middle) == 0, "starter soil joins without a turf seam")
	_completed += 1


## 0168 - all twelve crops earn their ready stage in watered mornings.
func _task_0168_crops() -> void:
	var days := {&"carrot": 3, &"wheat": 4, &"corn": 8, &"potato": 5,
		&"garlic": 4, &"strawberry": 8, &"pepper": 5, &"sunflower": 7,
		&"melon": 10, &"pumpkin": 10, &"grape": 8, &"beet": 6}
	expect(GameData.CROPS.size() == 12 and GameData.check_crops(GameData.CROPS).is_empty(),
		"all twelve crops validate without dominating another crop")
	var language := I18n.locale()
	var view := WorldView.new()
	for id in Farming.seeds():
		var data: Dictionary = GameData.CROPS[id]
		expect(int(data["growth_days"]) == int(days[id]) and int(data["stages"]) == 4,
			"%s has its plan days and four stages" % id)
		expect(data.has("seasons") and not data.has("regrowth"),
			"seasons are assigned and regrowth is a later rule for %s" % id)
		expect(GameData.SELL_PRICE.has(id) and GameData.RESOURCES.has(id),
			"%s is a priced ledger resource" % id)
		var grouped := false
		for group in GameData.RESOURCE_GROUPS:
			if group["name"] == &"crops" and id in group["members"]:
				grouped = true
		expect(grouped, "%s belongs to the crops group" % id)
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			expect(Names.KEYS.has(id) and not Names.of(id).is_empty()
				and Names.of(id) != str(Names.KEYS.get(id, &"")),
				"%s has a name in %s" % [id, locale])
		var state := State.create(1680)
		var cell: Vector2i = Farming.field_cells(state)[0]
		SuiteKit.crop_supplies(state, id)
		Farming.select_seed(state, id)
		Farming.act(state, cell)
		Farming.act(state, cell)
		for morning in range(1, int(days[id]) + 1):
			state["water_can"] = 1
			Farming.act(state, cell)
			Farming.dry_out(state)
			Farming.morning(state)
			expect(Farming.is_ready(state, cell) == (morning == int(days[id])),
				"%s ready only on watered morning %d" % [id, int(days[id])])
		for stage in 4:
			var path := "res://sprites/crops/%s_%d.png" % [id, stage]
			var shape := PlaceholderArt.frame(path)
			var tall: bool = id in [&"sunflower", &"grape"]
			expect(shape.get("canvas") == Vector2i(16, 32 if tall else (24 if id == &"corn" else 16))
				and shape.get("pivot") == Vector2i(8, 30 if tall else (22 if id == &"corn" else 14)),
				"%s stage %d uses its final crop geometry" % [id, stage])
			var texture := view._crop_texture("%s_%d" % [id, stage])
			expect(texture != null and Vector2i(texture.get_size()) == shape["canvas"],
				"%s stage %d draws on its final canvas without resizing pixels" % [id, stage])
			expect(ResourceLoader.exists(PlaceholderArt.texture_path(path)),
				"%s stage %d resolves to approved existing art" % [id, stage])
	view.free()
	I18n.use(language)
	_completed += 1


## 0169 - every tangible resource is priced, grouped, named and translated.
func _task_0169_inventory() -> void:
	var resources: Array = GameData.RESOURCES.duplicate()
	resources.append(&"unpriced_probe")
	var errors := GameData.check_resource_prices(resources, GameData.SELL_PRICE)
	expect(str(errors).contains("unpriced_probe") and str(errors).contains("sale price"),
		"an unpriced resource is rejected by name")
	resources = GameData.RESOURCES.duplicate()
	resources.append(&"ungrouped_probe")
	errors = GameData.check_groups(GameData.RESOURCE_GROUPS, resources)
	expect(str(errors).contains("ungrouped_probe") and str(errors).contains("inventory group"),
		"an ungrouped resource is rejected by name")
	var language := I18n.locale()
	var state := State.create(1690)
	for id in GameData.RESOURCES:
		expect(id in [GameData.MONEY, GameData.ENERGY, GameData.TECH] or GameData.SELL_PRICE.has(id),
			"%s declares a sale price or the explicit currency exception" % id)
		var matches := 0
		for group in GameData.RESOURCE_GROUPS:
			if id in group["members"] and group["name"] != GameData.GROUP_OTHER:
				matches += 1
		expect(matches == 1, "%s belongs to one real category" % id)
		expect(Names.KEYS.has(id) and str(Names.KEYS.get(id, &"")).begins_with("ITEM_"),
			"%s declares an ITEM translation key" % id)
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			expect(Names.of(id) != str(Names.KEYS.get(id, &"")) and not Names.of(id).is_empty(),
				"%s has its ITEM row in %s" % [id, locale])
		expect(UiKit.icon(id, true) != null, "%s has a nonblank compact icon" % id)
	for group in GameData.RESOURCE_GROUPS:
		expect(Names.GROUP_KEYS.has(group["name"]), "every declared category has a literal name key")
		for locale in ["en", "pt_BR"]:
			I18n.use(locale)
			expect(Names.group_of(group["name"]) != str(Names.GROUP_KEYS.get(group["name"], &"")),
				"every category is translated in %s" % locale)
	I18n.use(language)
	expect(UiKit.icon(&"not_drawn_yet", true) == UiKit.icon(GameData.WOOD, true),
		"an undrawn item's icon resolves to the existing art stand-in")
	var before := State.hash_of(state)
	var groups := Inventory.groups(state)
	for group in groups:
		expect(not group["rows"].is_empty() and group["name"] != GameData.GROUP_OTHER,
			"only populated, declared categories appear")
	var many: Array = []
	for i in 70:
		many.append({"id": StringName("probe_%d" % i), "held": 999, "price": 1, "sellable": true})
	var pages := InventoryPanel.pages_for([{"name": &"materials", "rows": many}])
	var count := 0
	for page in pages:
		count += page["rows"].size()
		expect(page["rows"].size() <= InventoryPanel.ROWS_PER_PAGE,
			"seventy items never exceed the height-derived row limit")
	expect(count == 70, "bounded pages retain all seventy rows")
	expect(State.hash_of(state) == before, "grouping and paging do not write state")
	expect(DayHud.SHOWN == [[GameData.WOOD, GameData.STONE, GameData.IRON],
		[GameData.FOOD, GameData.MONEY, GameData.TECH]], "six HUD numbers prioritize food, money and essence")
	_completed += 1


## 0170 - season filtering and held seed packets use the real ledger/stall.
func _task_0170_seasons() -> void:
	var state := State.create(1700)
	expect(Farming.selected_seed(state) == GameData.CARROT and Farming.in_season(state) == [&"carrot", &"garlic", &"potato", &"strawberry"], "a new farm selects a spring crop")
	var cell: Vector2i = Farming.field_cells(state)[0]
	var money := Resources.amount(state, GameData.MONEY)
	var packets := Resources.amount(state, GameData.CARROT_SEED)
	Farming.act(state, cell)
	Farming.act(state, cell)
	expect(Farming.crop_on(state, cell) == GameData.CARROT, "a held carrot packet plants")
	expect(Resources.amount(state, GameData.CARROT_SEED) == packets - 1 and Resources.amount(state, GameData.MONEY) == money, "sowing spends one packet and no money")
	state["held"][GameData.CARROT_SEED] = 0
	var empty: Vector2i = Farming.field_cells(state)[1]
	Farming.act(state, empty)
	Farming.act(state, empty)
	expect(Farming.crop_on(state, empty) == &"", "no packet plants nothing")
	expect(not Farming.select_seed(state, GameData.CORN), "spring cannot select corn")
	Resources.add(state, GameData.CORN_SEED, 1)
	state["selected_seed"] = GameData.CORN
	Farming.act(state, empty)
	expect(Farming.crop_on(state, empty) != GameData.CORN, "an outdated selection cannot sow an off-season crop")
	state["day"] = GameData.SEASON_DAYS + 1
	state["selected_seed"] = GameData.CARROT
	Farming.morning(state)
	expect(Farming.in_season(state) == [&"corn", &"melon", &"pepper", &"sunflower"] and Farming.selected_seed(state) == GameData.CORN, "summer offers only summer crops")
	state["day"] = GameData.SEASON_DAYS * 3 + 1
	Farming.morning(state)
	expect(Farming.in_season(state).is_empty() and Farming.selected_seed(state) == &"" and state["selected_seed"] == &"", "winter clears the selection")
	expect(not Farming.select_seed_at(state, 0), "winter has no numbered sowing slot")
	Farming.act(state, empty)
	expect(Farming.crop_on(state, empty) == &"", "winter cannot plant")
	expect(Shop.buy_price(GameData.CARROT_SEED) == 2 and Shop.sell_price(GameData.CARROT_SEED) == 1, "carrot packets cost $2 and resell for $1")
	for id in Farming.seeds():
		var packet := Farming.packet(id)
		expect(packet in Shop.buyable() and Shop.stock_of(state, packet) > 0, "%s is stocked all year" % packet)
		expect(Shop.buy_price(packet) == int(GameData.CROPS[id]["seed_cost"]) and Shop.buy_price(packet) > Shop.sell_price(packet), "%s uses the balanced price and loses on resale" % packet)
		for season in [[], [&"winter"], [&"unknown"]]:
			var rigged := GameData.CROPS.duplicate(true)
			rigged[id]["seasons"] = season
			expect(not GameData.check_crops(rigged).is_empty(), "%s refuses invalid sowing seasons" % id)
	var old := State.create(1701)
	for id in Farming.seeds():
		old["held"].erase(Farming.packet(id))
		old["gained"].erase(Farming.packet(id))
		old["stall"]["stock"].erase(Farming.packet(id))
	old["stall"]["stock"][GameData.WOOD] = 0
	State.reconcile(old)
	expect(Shop.buy(old, GameData.CARROT_SEED, 1) and Shop.stock_of(old, GameData.WOOD) == 0, "old saves can buy a new packet without refilling old shelves")
	Resources.spend(old, GameData.CARROT_SEED, 1)
	expect(int(old["version"]) == State.VERSION and Resources.amount(old, GameData.CARROT_SEED) == 0, "old saves receive zero packets without a version bump")
	_completed += 1


## 0171 - the boundary clears old crops; winter leaves other work running.
func _task_0171_winter() -> void:
	var state := State.create(1710)
	var beds := Farming.field_cells(state)
	var corn: Vector2i = beds[0]
	var wheat: Vector2i = beds[1]
	SuiteKit.crop_supplies(state, GameData.CORN)
	Farming.select_seed(state, GameData.CORN)
	Farming.act(state, corn)
	Farming.act(state, corn)
	Farming.plot(state, corn)["watered"] = true
	Farming.dry_out(state)
	state["day"] = GameData.SEASON_DAYS * 2 + 1
	SuiteKit.crop_supplies(state, GameData.WHEAT)
	Farming.select_seed(state, GameData.WHEAT)
	Farming.act(state, wheat)
	Farming.act(state, wheat)
	Farming.morning(state)
	expect(Farming.crop_on(state, corn) == &"" and Farming.is_tilled(state, corn), "Autumn 1 leaves the corn bed tilled and empty")
	expect(Farming.plot(state, corn).get("withered") == GameData.CORN and Farming.plot(state, corn)["growth"] == 0 and not Farming.plot(state, corn).has("morning_credit"), "withering names the old crop and discards growth and watering credit")
	expect(Farming.crop_on(state, wheat) == GameData.WHEAT, "wheat planted on Autumn 1 survives that morning")
	Farming.act(state, corn)
	expect(Farming.crop_on(state, corn) == GameData.WHEAT and not Farming.plot(state, corn).has("withered"), "replanting clears the withered mark")
	# Fixtures may contain any old crop on winter's first morning.
	state["plots"].clear()
	var ids := Farming.seeds()
	for i in ids.size():
		state["plots"][Grid.index(beds[i])] = {"crop": ids[i], "growth": 2, "watered": true, "morning_credit": true}
	state["day"] = GameData.SEASON_DAYS * 3 + 1
	Farming.morning(state)
	for i in ids.size():
		expect(Farming.crop_on(state, beds[i]) == &"" and Farming.plot(state, beds[i]).get("withered") == ids[i], "Winter 1 withers %s" % ids[i])
	state["day"] += 1
	var here := Farming.plot(state, corn)
	here["crop"] = GameData.CORN
	here["growth"] = 2
	here["watered"] = true
	Farming.dry_out(state)
	Farming.morning(state)
	expect(here["growth"] == 2 and not here.has("morning_credit"), "a rigged winter crop consumes watering credit without growing")
	state["day"] = GameData.SEASON_DAYS * 4 + 2
	Farming.morning(state)
	expect(here["growth"] == 2, "winter watering cannot be banked for spring")
	state["day"] = GameData.SEASON_DAYS * 3 + 2
	expect(Interact.why_not(state, wheat) == [&"WHY_NO_OUTDOOR_GROWTH"], "winter sowing offers a localized refusal")
	var before := State.hash_of(state)
	Interact.complete(state, wheat, &"plant")
	expect(State.hash_of(state) == before, "refused winter sowing spends nothing")
	expect(GameData.check_no_growth_seasons([&"winter"]).is_empty() and not GameData.check_no_growth_seasons([&"missing"]).is_empty(), "the growth lever refuses unknown seasons")
	var wet: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	expect(Fishing.begin(state, wet), "winter accepts a cast")
	while not Fishing.is_biting(state):
		Fishing.tick(state, wet + Vector2i.RIGHT)
	expect(not Fishing.reel(state).is_empty(), "winter fishing pays a catch")
	var seam: Vector2i = Farm.cells_with(state, &"seam")[0]
	var stone := Resources.amount(state, GameData.STONE)
	for hit in int(GameData.GATHERING[&"seam"]["hits"]):
		Gathering.strike(state, seam)
	expect(Resources.amount(state, GameData.STONE) > stone, "winter mining produces stone")
	for tick in int(GameData.GATHERING[&"seam"]["regrow_ticks"]):
		Gathering.tick(state)
	expect(Farm.occupant(state, seam).get("id") == &"seam", "winter seams regrow")
	var press := Vector2i(26, 25)
	Farm.remove(state, press)
	Farm.restore(state, press, {"id": &"press"})
	Resources.add(state, GameData.CORN, 8)
	var oil := Resources.amount(state, GameData.OIL)
	expect(Crafting.enqueue(state, press, &"press_oil") and Crafting.enqueue(state, press, &"press_oil"), "winter accepts a press queue")
	while Crafting.busy(state, press):
		Crafting.tick(state)
	expect(Resources.amount(state, GameData.OIL) == oil + 2, "both press jobs finish in winter")
	var cow: Vector2i = Farm.cells_with(state, &"cow")[0]
	for tick in int(GameData.LIVESTOCK[&"cow"]["every_ticks"]):
		Livestock.tick(state)
	expect(Livestock.ready_at(state, cow) > 0 and not Livestock.collect(state, cow).is_empty(), "a winter cow produces and can be collected")
	_completed += 1


## 0172 - a picked plant keeps the seed, needs water, and withers at the seam.
func _task_0172_regrow() -> void:
	for id in [&"strawberry", &"corn", &"pepper", &"grape"]:
		var state := State.create(1720)
		SuiteKit.crop_supplies(state, id)
		Farming.select_seed(state, id)
		var cell: Vector2i = Farming.field_cells(state)[0]
		Farming.act(state, cell)
		Farming.act(state, cell)
		Farming.plot(state, cell)["growth"] = Farming.days_to_grow(id)
		var packets := Resources.amount(state, Farming.packet(id))
		var before := Resources.amount(state, id)
		Farming.act(state, cell)
		expect(Farming.crop_on(state, cell) == id and not Farming.is_ready(state, cell), "%s remains planted after picking" % id)
		expect(Farming.stage(state, cell) == int(GameData.CROPS[id]["stages"]), "%s has a distinct regrowing stage" % id)
		var growth := int(Farming.plot(state, cell)["growth"])
		_0172_morning(state, cell, false)
		expect(int(Farming.plot(state, cell)["growth"]) == growth, "%s waits through a dry morning" % id)
		for day in range(1, Farming.regrow_days(id) + 1):
			_0172_morning(state, cell, true)
			expect(Farming.is_ready(state, cell) == (day == Farming.regrow_days(id)), "%s is ready at exactly regrowth morning %d" % [id, day])
		Farming.act(state, cell)
		expect(Resources.amount(state, id) - before == 2 * int(GameData.CROPS[id]["yield"]) and Resources.amount(state, Farming.packet(id)) == packets, "%s pays twice without another packet" % id)
		var path := "user://task0172-regrow.sav"
		expect(Save.write_run_at(path, state), "a regrowing %s save writes" % id)
		var loaded := Save.read_run_at(path)
		expect(bool(Farming.plot(loaded, cell).get("regrowing", false)) and int(loaded["version"]) == State.VERSION and State.VERSION >= 7, "%s round-trips without changing growth units or version" % id)
		Save._remove(path)
		Save._remove(path + ".bak")
		# The existing hoe resets all plot fields, with no harvest payout.
		var held := Resources.amount(state, id)
		expect(Farming.clear_crop(loaded, cell) and Farming.plot(loaded, cell) == Farming.EMPTY_PLOT, "the hoe clears %s and its regrowth marker" % id)
		expect(Resources.amount(loaded, id) == held, "clearing pays no %s" % id)
		# A planted regrowing crop is subject to the same season seam as a new one.
		state["day"] = (GameData.SEASONS.find(GameData.CROPS[id]["seasons"][0]) + 1) * GameData.SEASON_DAYS + 1
		state["days_held"] = 0
		state["phase"] = Phases.RESULT
		expect(Phases.begin_day(state), "the next season begins after %s" % id)
		expect(Farming.crop_on(state, cell) == &"" and Farming.plot(state, cell).get("withered") == id and not Farming.plot(state, cell).has("regrowing"), "%s also withers while regrowing" % id)
	var carrot := State.create(1721)
	var cell: Vector2i = Farming.field_cells(carrot)[0]
	Farming.act(carrot, cell)
	Farming.act(carrot, cell)
	Farming.plot(carrot, cell)["growth"] = Farming.days_to_grow(GameData.CARROT)
	expect(not Farming.plot(carrot, cell).has("regrowing") and Farming.is_ready(carrot, cell), "an old plot without regrowth retains its original growth meaning")
	Farming.act(carrot, cell)
	expect(Farming.crop_on(carrot, cell) == &"" and Farming.plot(carrot, cell)["growth"] == 0, "a picked carrot leaves an empty plot")
	for id in Farming.seeds():
		var offer := GameData._crop_offer(GameData.CROPS, id)
		expect(offer["visits"] == Farming.harvests_per_season(id) and offer["value"] == Farming.value_per_season(id), "%s balance and HUD agree on regrowth" % id)
	for days in [-1, 99]:
		var rigged := GameData.CROPS.duplicate(true)
		rigged[&"corn"]["regrow_days"] = days
		expect(not GameData.check_crops(rigged).is_empty(), "bad regrowth duration is refused")
	var dominant := GameData.CROPS.duplicate(true)
	dominant[&"strawberry"]["seed_cost"] = 3
	dominant[&"strawberry"]["regrow_days"] = 8
	expect(not GameData.check_crops(dominant).is_empty(), "the balance guard counts regrowth before refusing dominance")
	expect(GameData.check_crops(GameData.CROPS).is_empty(), "the four repeating crops do not dominate their season")
	_completed += 1


## Cross the actual bedtime, result and morning road, with or without water.
func _0172_morning(state: Dictionary, cell: Vector2i, watered: bool) -> void:
	Farming.plot(state, cell)["watered"] = watered
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, false)
	Phases.begin_day(state)


## 0173 - paid workshop upgrades keep the old tool until the following dawn.
func _task_0173_tools() -> void:
	var state := State.create(1730)
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	state["held"][GameData.MONEY] = 1000
	state["held"][GameData.IRON] = 88
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		expect(ToolTiers.tier(state, tool) == 0 and tool not in GameData.RESOURCES, "%s starts at tier zero outside the ledger" % tool)
	expect(ToolTiers.why_not(state, &"upgrade_axe_gold") == [&"WHY_TOOL_PREVIOUS"], "a basic axe cannot skip iron for gold")
	expect(ToolTiers.why_not(state, &"upgrade_rod_iron") == [&"WHY_TOOL_PREVIOUS"], "a bamboo rod cannot skip fibre")
	expect(Crafting.enqueue(state, bench, &"upgrade_axe_iron"), "money and iron buy an axe order")
	expect(not Crafting.enqueue(state, bench, &"upgrade_axe_iron"), "a queued upgrade cannot be ordered twice")
	Sim.advance(state, int(GameData.RECIPES[&"upgrade_axe_iron"]["ticks"]) + 1)
	expect(ToolTiers.tier(state, &"axe") == 0 and state["tools"]["pending"]["axe"]["tier"] == 1, "a completed axe stays basic pending tomorrow")
	expect(Resources.amount(state, GameData.IRON) == 80 and Resources.amount(state, GameData.MONEY) == 850, "the workshop charges exactly eight iron and $150")
	var path := "user://task0173-tools.sav"
	expect(Save.write_run_at(path, state), "a pending upgrade saves")
	var loaded := Save.read_run_at(path)
	expect(loaded["tools"] == state["tools"], "the old tool and pending upgrade round-trip")
	Save._remove(path)
	Save._remove(path + ".bak")
	Phases.go_to_bed(state)
	expect(ToolTiers.tier(state, &"axe") == 0, "the axe is still basic that evening")
	Phases.start_waves(state)
	Rewards.settle(state, false)
	Phases.enter_result(state, false)
	expect(Resources.amount(state, GameData.IRON) == 60 and state["tools"]["pending"].has("axe"), "a lost night takes 25 percent of iron and no pending tool")
	expect(Phases.begin_day(state) and ToolTiers.tier(state, &"axe") == 1 and state["tools"]["pending"].is_empty(), "the next morning hands over the iron axe")
	var tools: Dictionary = state["tools"].duplicate(true)
	Rewards.settle(state, false)
	expect(state["tools"] == tools, "a later loss cannot take an owned tool")
	for recipe in [&"upgrade_hoe_iron", &"upgrade_can_iron", &"upgrade_pickaxe_iron", &"upgrade_rod_fibre", &"upgrade_rod_iron"]:
		state["held"][GameData.MONEY] = 1000
		state["held"][GameData.IRON] = 100
		expect(Crafting.enqueue(state, bench, recipe), "%s can be ordered in ladder order" % recipe)
		Sim.advance(state, int(GameData.RECIPES[recipe]["ticks"]) + 1)
		Phases.go_to_bed(state)
		Phases.start_waves(state)
		Phases.enter_result(state, false)
		Phases.begin_day(state)
		var target := GameData.tool_output(GameData.RECIPES[recipe]["output"].keys()[0])
		expect(ToolTiers.tier(state, target["tool"]) == target["tier"], "%s arrives at dawn" % recipe)
	var before := State.hash_of(state)
	var view := PlayerWork.new()
	expect(view.head_material(state, &"chop").get_shader_parameter("head_mid") == PlayerWork.HEAD_RAMPS[&"iron"][1], "chopping reads the iron head ramp")
	expect(view.head_material(state, &"plant") == null and State.hash_of(state) == before, "tool tinting never writes simulation state")
	view._head_materials.clear()
	var old := State.create(1731)
	old.erase("tools")
	State.reconcile(old)
	expect(old["tools"] == ToolTiers.initial()["tools"], "an old save receives all five basic tools")
	var bad := GameData.TOOLS.duplicate(true)
	bad[&"axe"][1]["cost"][&"imaginary_ore"] = 1
	expect(not GameData.check_tools(bad).is_empty(), "an unknown ore cost is refused")
	bad = GameData.TOOLS.duplicate(true)
	bad[&"axe"].pop_back()
	expect(not GameData.check_tools(bad).is_empty(), "an incomplete ladder is refused")
	expect(GameData.check_tools(GameData.TOOLS).is_empty(), "all five ladders validate")
	_completed += 1


## 0174 - one timed hoe stroke; one unit of water per eligible transverse plot.
func _task_0174_area() -> void:
	var state := State.create(1740)
	var centre := Vector2i(32, 20)
	for y in range(18, 23):
		for x in range(29, 36):
			var at := Vector2i(x, y)
			state["terrain"][Grid.index(at)] = Farm.Terrain.GRASS
			state["occupants"].erase(Grid.index(at))
			state["plots"].erase(Grid.index(at))
	for dx in range(-2, 3):
		var at := centre + Vector2i(dx, 0)
		Farming.act(state, at)
		Farming.plot(state, at)["crop"] = GameData.CARROT
	state["tools"]["can"] = 1
	state["water_can"] = 8
	SuiteKit.stand_the_farmer(state, centre + Vector2i.UP)
	state["player"]["facing"] = Player.SOUTH
	var expected: Array = [centre, centre + Vector2i.RIGHT, centre + Vector2i.LEFT]
	expect(Farming.action_cells(state, centre, &"water") == expected, "an iron stroke visits centre, farmer's left, then right")
	state["intent"]["interact"] = true
	Sim.advance(state, 1)
	for at in expected:
		expect(Farming.is_watered(state, at), "one press waters all three iron plots")
	expect(Farming.water_carried(state) == 5 and not Farming.is_watered(state, centre + Vector2i(2, 0)), "one iron press spends three and stops at its width")
	for dx in range(-2, 3):
		Farming.plot(state, centre + Vector2i(dx, 0))["watered"] = false
	state["tools"]["can"] = 2
	state["water_can"] = 2
	expect(Farming.action_cells(state, centre, &"water") == expected.slice(0, 2), "a short gold can previews only its two affordable plots")
	Farming.act(state, centre)
	expect(Farming.water_carried(state) == 0 and Farming.is_watered(state, centre) and Farming.is_watered(state, centre + Vector2i.RIGHT) and not Farming.is_watered(state, centre + Vector2i.LEFT), "a short can follows fixed spending order and never underflows")
	state["water_can"] = 5
	Farming.plot(state, centre)["watered"] = false
	Farming.plot(state, centre + Vector2i.RIGHT)["growth"] = Farming.days_to_grow(GameData.CARROT)
	state["occupants"][Grid.index(centre + Vector2i.LEFT)] = {"id": &"tree", "hp": 1}
	expect(Farming.action_cells(state, centre, &"water") == [centre, centre + Vector2i(2, 0), centre + Vector2i(-2, 0)], "water skips ripe crops and occupied plots without wasting a unit")
	state["occupants"].erase(Grid.index(centre + Vector2i.LEFT))
	for dx in range(-2, 3):
		var plot := Farming.plot(state, centre + Vector2i(dx, 0))
		plot["watered"] = false
		plot["growth"] = 0
	Farming.act(state, centre)
	expect(Farming.water_carried(state) == 0, "a full gold stroke spends five units")
	for dx in range(-2, 3):
		expect(Farming.is_watered(state, centre + Vector2i(dx, 0)), "a gold can waters all five plots")
	state["tools"]["hoe"] = 2
	var hoed := centre + Vector2i(0, 2)
	SuiteKit.stand_the_farmer(state, hoed + Vector2i.UP)
	state["player"]["facing"] = Player.SOUTH
	var bytes: PackedByteArray = state["terrain"].duplicate()
	state["intent"]["interact"] = true
	var ticks := Interact.ticks_for(state, hoed, &"till")
	Sim.advance(state, ticks - 1)
	expect(not Farming.is_tilled(state, hoed), "a gold hoe still takes one full hoe work cycle")
	Sim.advance(state, 1)
	for dx in range(-2, 3):
		expect(Farming.is_tilled(state, hoed + Vector2i(dx, 0)), "one gold hoe cycle tills all five grass cells")
	expect(state["terrain"] == bytes, "area hoeing preserves terrain bytes")
	for dx in range(-2, 3):
		state["plots"].erase(Grid.index(hoed + Vector2i(dx, 0)))
	var path := hoed + Vector2i.RIGHT
	state["terrain"][Grid.index(path)] = Farm.Terrain.PATH
	Farming.act(state, hoed)
	expect(not Farming.is_tilled(state, path) and Farming.is_tilled(state, hoed + Vector2i(2, 0)), "a gold hoe skips a path and reaches the grass beyond it")
	Farming.plot(state, hoed)["crop"] = GameData.CARROT
	Farming.plot(state, hoed + Vector2i.LEFT)["crop"] = GameData.WHEAT
	Farming.clear_crop(state, hoed)
	expect(Farming.crop_on(state, hoed + Vector2i.LEFT) == GameData.WHEAT, "REMOVE remains single-cell and preserves the neighbouring crop")
	for facing in range(4):
		state["player"]["facing"] = facing
		var forward: Vector2i = Farming.NEIGHBOURS[facing]
		var across := Vector2i(-forward.y, forward.x)
		for offset in GameData.TOOL_AREA_OFFSETS[5]:
			state["plots"].erase(Grid.index(centre + across * int(offset)))
		var cells: Array = Farming.action_cells(state, centre, &"till")
		expect(cells == [centre, centre - across, centre + across, centre - across * 2, centre + across * 2], "every facing rotates the same centre-first five-cell footprint")
		var edge := Vector2i.ZERO
		state["terrain"][Grid.index(edge)] = Farm.Terrain.GRASS
		state["occupants"].erase(Grid.index(edge))
		state["plots"].erase(Grid.index(edge))
		for at in Farming.action_cells(state, edge, &"till"):
			expect(Grid.in_bounds(at), "every facing clips its stroke at the map boundary")
	state["tools"]["can"] = 1
	state["tech_owned"].append(&"full cans")
	state["water_can"] = 4
	expect(Farming.can_capacity(state) == 14, "iron capacity and full cans stack to fourteen")
	var well: Vector2i = Farm.cells_with(state, &"well")[0]
	for level in range(3):
		state["tools"]["can"] = level
		state["water_can"] = 0
		expect(Farming.refill_beside(state, well + Vector2i.UP) and Farming.water_carried(state) == 10 + level * 4, "each tier refills to its capacity plus full cans")
	state["tools"]["can"] = 1
	state["water_can"] = 4
	var hud := DayHud.new()
	hud._ready()
	hud.show_state(state)
	expect(hud._water.text == I18n.f(&"DHUD_WATER", [4, Farming.can_capacity(state)]), "the HUD uses the actual capacity with full cans bought")
	hud.free()
	state["player"]["facing"] = Player.SOUTH
	for dx in range(-1, 2):
		state["plots"][Grid.index(centre + Vector2i(dx, 0))] = {"crop": GameData.CARROT, "growth": 0, "watered": false}
	var view := WorldView.new()
	view._state = state
	var before := State.hash_of(state)
	view.highlight(centre)
	expect(view.highlighted_cells() == Farming.action_cells(state, centre, &"water") and State.hash_of(state) == before, "the area highlight reads the core footprint without changing state")
	state["water_can"] = 1
	view.highlight(centre)
	expect(view.highlighted_cells() == [centre], "the highlight updates a short can even when its centre did not move")
	view.free()
	var bad := GameData.TOOL_AREA_OFFSETS.duplicate(true)
	bad[3] = [0, 1, 1]
	expect(not GameData.check_tool_areas(bad).is_empty(), "duplicate footprint offsets are rejected")
	expect(GameData.check_tool_areas(GameData.TOOL_AREA_OFFSETS).is_empty(), "all transverse footprints validate")
	_completed += 1


## 0175 - tool speed composes with tech; a future tier gate refuses before work.
func _task_0175_swings() -> void:
	var fell_ticks: Array = []
	for sharp in [false, true]:
		for level in range(3):
			var state := State.create(1750)
			state["tools"]["axe"] = level
			if sharp:
				state["tech_owned"].append(&"sharp tools")
			var tree: Vector2i = Farm.cells_with(state, &"tree")[0]
			SuiteKit.stand_the_farmer(state, tree + Vector2i.DOWN)
			state["player"]["facing"] = Player.NORTH
			var before := Resources.amount(state, GameData.WOOD)
			var percent := int(GameData.TOOLS[&"axe"][level]["gather_percent"])
			var tech := Tech.bonus(state, "gather_percent", 100)
			var swing := int(GameData.GATHERING[&"tree"]["work_ticks"]) * 10000 / (percent * tech)
			var total := swing * int(GameData.GATHERING[&"tree"]["hits"])
			expect(Interact.ticks_for(state, tree, &"chop") == swing, "axe tier %d and sharp %s compose with one integer rounding" % [level, sharp])
			state["intent"]["interact"] = true
			Sim.advance(state, total - 1)
			expect(Farm.occupant(state, tree).get("id", &"") == &"tree" and Resources.amount(state, GameData.WOOD) == before, "the tree and its yield stay until the exact last tick")
			Sim.advance(state, 1)
			expect(Farm.occupant(state, tree).get("id", &"") == &"stump" and Resources.amount(state, GameData.WOOD) == before + 3, "the last tick fells it once without changing the yield")
			fell_ticks.append(total)
	expect(fell_ticks == [90, 60, 45, 81, 54, 39], "basic/iron/gold take 90/60/45 ticks, or 81/54/39 with sharp tools", str(fell_ticks))
	var state := State.create(1751)
	for id in [&"rock", &"seam", &"ore"]:
		var cell: Vector2i = Farm.cells_with(state, id)[0]
		state["tools"]["pickaxe"] = 1
		var base := int(GameData.GATHERING[id]["work_ticks"])
		expect(Interact.ticks_for(state, cell, &"mine") == base * 100 / 150, "iron pickaxe scales %s mining too" % id)
		state["tools"]["axe"] = 2
		expect(Interact.ticks_for(state, cell, &"mine") == base * 100 / 150, "a gold axe cannot accelerate mining")
	var ore: Vector2i = Farm.cells_with(state, &"ore")[0]
	var rigged := GameData.GATHERING.duplicate(true)
	rigged[&"ore"]["min_tier"] = 1
	state["tools"]["pickaxe"] = 0
	var reason := Gathering.why_not(state, ore, rigged)
	expect(reason == [&"WHY_GATHER_TOOL", &"pickaxe_iron"] and Interact.verb_at(state, ore) == &"mine", "a rigged tier gate keeps its offered verb and names the required iron pickaxe")
	var before := State.hash_of(state)
	expect(Gathering.strike(state, ore, rigged).is_empty() and State.hash_of(state) == before, "a refused direct strike changes neither hp nor resources nor regrowth")
	state["tools"]["pickaxe"] = 1
	expect(Gathering.why_not(state, ore, rigged).is_empty(), "an iron pickaxe clears the same gate")
	var iron := Resources.amount(state, GameData.IRON)
	for hit in int(rigged[&"ore"]["hits"]):
		Gathering.strike(state, ore, rigged)
	expect(Farm.occupant(state, ore).is_empty() and Resources.amount(state, GameData.IRON) == iron + 1, "the allowed rigged ore yields exactly once")
	for minimum in [-1, 3, 1.5]:
		rigged[&"ore"]["min_tier"] = minimum
		expect(not GameData.check_gathering(rigged).is_empty(), "the validator refuses an out-of-ladder or noninteger minimum tier")
	rigged[&"ore"]["min_tier"] = 1
	rigged[&"ore"]["tool"] = &"rod"
	expect(not GameData.check_gathering(rigged).is_empty(), "a gathering node cannot demand a rod")
	expect(GameData.check_gathering(GameData.GATHERING).is_empty(), "all actual gathering tools and minimum tiers validate")
	expect(GameData.check_iron(GameData.GATHERING, GameData.FARM_MAP).is_empty(), "tool metadata preserves iron's economy")
	expect(GameData.check_reachable(GameData.GATHERING, GameData.FARM_MAP).is_empty(), "all resource nodes remain reachable")
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		for tool in [&"axe", &"pickaxe"]:
			for level in [1, 2]:
				var text := Names.refusal([&"WHY_GATHER_TOOL", ToolTiers.item(tool, level)])
				expect(text.contains(Names.of(ToolTiers.item(tool, level))) and UiKit.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= 224, "the fully expanded %s tier refusal fits in %s" % [tool, locale])
	I18n.use("en")
	_completed += 1


## 0176 - quarry resources, permanent autumn gate, fuel and gold delivery.
func _task_0176_ores() -> void:
	var state := State.create(1760)
	state["day"] = GameData.SEASON_DAYS * 2 + 1
	state["tools"]["pickaxe"] = 1
	for id in [&"copper_ore", &"coal_seam", &"gold_ore"]:
		var cell: Vector2i = Farm.cells_with(state, id)[0]
		var node: Dictionary = GameData.GATHERING[id]
		var resource: StringName = node["yield"].keys()[0]
		var before := Resources.amount(state, resource)
		expect(Interact.verb_at(state, cell) == &"mine", "%s offers mining on Autumn 1" % id)
		for hit in int(node["hits"]) - 1:
			expect(Gathering.strike(state, cell).is_empty(), "quarry yield waits for the final hit")
		expect(Gathering.strike(state, cell) == node["yield"] and Farm.occupant(state, cell).is_empty(), "%s gives its exact yield and leaves an empty cell" % id)
		expect(Resources.amount(state, resource) == before + int(node["yield"][resource]), "the ledger holds the new resource")
		for tick in int(node["regrow_ticks"]) - 1:
			Gathering.tick(state)
		expect(Farm.occupant(state, cell).is_empty(), "regrowth waits for its exact tick")
		Gathering.tick(state)
		expect(Farm.occupant(state, cell).get("id", &"") == id and Gathering.swings_left(state, cell) == int(node["hits"]), "%s returns whole on its exact tick" % id)
	var gold: Vector2i = Farm.cells_with(state, &"gold_ore")[0]
	for date in [1, GameData.SEASON_DAYS * 2]:
		state["day"] = date
		var before := State.hash_of(state)
		expect(Interact.verb_at(state, gold) == &"" and Gathering.strike(state, gold).is_empty() and State.hash_of(state) == before, "gold cannot be offered or struck before the first autumn")
	state["day"] = GameData.SEASON_DAYS * 2 + 1
	state["days_held"] = 1
	expect(not Gathering.is_available(state, &"gold_ore"), "a held boss day cannot open gold by the run's day counter")
	state["days_held"] = 0
	state["tools"]["pickaxe"] = 0
	expect(Interact.verb_at(state, gold) == &"mine" and Interact.why_not(state, gold) == [&"WHY_GATHER_TOOL", &"pickaxe_iron"], "Autumn 1 offers gold but explains its iron-pickaxe gate")
	var before := State.hash_of(state)
	Interact.complete(state, gold, &"mine")
	expect(State.hash_of(state) == before, "completing a refused action does not alter the gold")
	state["tools"]["pickaxe"] = 1
	expect(Interact.why_not(state, gold).is_empty(), "iron clears the real gold gate")
	for date in [GameData.SEASON_DAYS * 3 + 1, Calendar.year_days() + 1]:
		state["day"] = date
		expect(Interact.verb_at(state, gold) == &"mine", "gold stays open in winter and the next spring")
	var bench: Vector2i = Farm.cells_with(state, &"workshop")[0]
	state["tools"]["hoe"] = 1
	state["held"][GameData.MONEY] = 1000
	state["held"][GameData.GOLD] = 20
	expect(Crafting.enqueue(state, bench, &"upgrade_hoe_gold"), "an iron hoe can order its enabled gold tier")
	expect(Resources.amount(state, GameData.MONEY) == 700 and Resources.amount(state, GameData.GOLD) == 15, "the gold hoe costs its exact $300 and five gold")
	Sim.advance(state, int(GameData.RECIPES[&"upgrade_hoe_gold"]["ticks"]) + 1)
	expect(ToolTiers.tier(state, &"hoe") == 1 and state["tools"]["pending"]["hoe"]["tier"] == 2, "the completed order keeps iron until tomorrow")
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, false)
	expect(Phases.begin_day(state) and ToolTiers.tier(state, &"hoe") == 2, "the gold hoe arrives next morning even after a loss")
	for tool in [&"hoe", &"can", &"axe", &"pickaxe"]:
		expect(GameData.TOOLS[tool][2]["enabled"] and GameData.TOOLS[tool][2]["cost"].has(GameData.GOLD), "each gold tool is enabled and paid with gold")
	var plant := State.create(1761)
	var spot := Vector2i(30, 35)
	Farm.restore(plant, spot, {"id": &"generator", "anchor": [spot.x, spot.y]})
	plant["held"][GameData.OIL] = 1
	plant["held"][GameData.COAL] = 2
	expect(Power._run(plant, spot, 1, true) and Resources.amount(plant, GameData.OIL) == 0 and Resources.amount(plant, GameData.COAL) == 2, "a fresh tank prefers one oil and leaves coal")
	plant["power"]["burning"].clear()
	expect(Power._run(plant, spot, 1, true) and Resources.amount(plant, GameData.COAL) == 1, "one coal starts the same tank when oil is empty")
	expect(plant["power"]["burning"][Grid.index(spot)] == int(GameData.BUILDINGS[&"generator"]["fuel_every_ticks"]) - 1, "coal lasts exactly as long as oil")
	var fuel := Resources.amount(plant, GameData.COAL)
	Power._run(plant, spot, 1, false)
	expect(Resources.amount(plant, GameData.COAL) == fuel, "build preparation never consumes fuel")
	plant["power"]["burning"].clear()
	plant["held"][GameData.COAL] = 0
	expect(not Power._run(plant, spot, 1, true), "with neither fuel a new tank cannot run")
	for resource in [GameData.COPPER, GameData.COAL, GameData.GOLD]:
		expect(GameData.SELL_PRICE.has(resource) and resource in GameData.RESOURCE_GROUPS[0]["members"] and Names.KEYS.has(resource), "each mineral has its price, material group and localized name")
		expect(UiKit.icon(resource) != null and UiKit.icon(resource, true) != null, "both icon sizes resolve through A020 stand-ins")
	var bad := GameData.GATHERING.duplicate(true)
	bad[&"gold_ore"]["work_ticks"] = GameData.GATHERING[&"seam"]["work_ticks"]
	expect(not GameData.check_iron(bad, GameData.FARM_MAP).is_empty(), "quarry scarcity rejects gold as fast as stone")
	bad[&"gold_ore"]["first_season"] = &"missing"
	expect(not GameData.check_gathering(bad).is_empty(), "an unknown opening season is rejected")
	expect(GameData.validate().is_empty(), "all quarry metadata, prices, costs, fuel and reachability validate")
	_completed += 1


## Follow-up to the review of 0160-0176 (2026-10-09). SPACE keeps the bed
## underfoot when the faced crop has nothing for it - 0172 had pointed it at
## any faced crop, for REMOVE's sake; REMOVE asks its own target, and is spent
## outside build mode even when it cleared nothing, so it never falls through
## to selling the building under a stale build cursor; and a season's harvest
## estimate counts the thirteen mornings a crop sown on its first day gets.
func _followup_0176_review() -> void:
	var state := State.create(1769)
	SuiteKit.crop_supplies(state, GameData.CARROT)
	Farming.select_seed(state, GameData.CARROT)
	var field := Farming.field_cells(state)
	var bed := Vector2i(-1, -1)
	for at in field:
		if field.has(at + Vector2i.RIGHT):
			bed = at
			break
	var ahead := bed + Vector2i.RIGHT
	for at in [bed, ahead]:
		for _step in 3:
			if Farming.verb_at(state, at) == &"plant":
				break
			Farming.act(state, at)
	Farming.act(state, ahead)
	Farming.plot(state, ahead)["watered"] = true
	SuiteKit.stand_the_farmer(state, bed)
	state["player"]["facing"] = Player.EAST
	expect(Farming.verb_at(state, ahead) == &"" and Farming.verb_at(state, bed) == &"plant",
		"fixture: a watered carrot ahead, an empty bed underfoot",
		"%s / %s" % [Farming.verb_at(state, ahead), Farming.verb_at(state, bed)])
	expect(Player.target(state) == bed and Player.clear_target(state) == ahead,
		"SPACE keeps the bed underfoot, REMOVE reaches the faced carrot",
		"%s, %s" % [Player.target(state), Player.clear_target(state)])
	state["intent"]["interact"] = true
	Sim.advance(state, Interact.ticks_for(state, bed, &"plant") + 1)
	expect(Farming.crop_on(state, bed) == GameData.CARROT
		and Farming.crop_on(state, ahead) == GameData.CARROT,
		"a press plants the bed and leaves the carrot ahead alone")
	state["intent"]["build_sell"] = true
	Sim.advance(state, 1)
	expect(Farming.crop_on(state, ahead) == &"" and Farming.crop_on(state, bed) == GameData.CARROT,
		"REMOVE clears the faced carrot, not the one underfoot")

	# **A REMOVE that clears nothing is spent**, not left for `Building.tick`
	# to sell whatever the build cursor last pointed at.
	var bench := Building.anchor_of(state, Farm.cells_with(state, &"workshop")[0])
	expect(not Building.is_active(state) and Building.why_not_sell(state, bench).is_empty()
		and Player.clear_target(state) == Vector2i(-1, -1),
		"fixture: by day, out of build mode, a sellable workshop, nothing to clear")
	state["intent"]["build_cell"] = [bench.x, bench.y]
	state["intent"]["build_sell"] = true
	Sim.advance(state, 1)
	expect(StringName(Farm.occupant(state, bench).get("id", &"")) == &"workshop"
		and not bool(state["intent"]["build_sell"]) and Farming.crop_on(state, bed) == GameData.CARROT,
		"and a REMOVE with no crop to clear sells nothing", str(Farm.occupant(state, bench)))

	# **A bed's grass edge stops at turned lawn** (review of 0167): the rule
	# the view lays its edges by, asked directly.
	var bytes: PackedByteArray = state["terrain"]
	var edged := 0
	var cleared := 0
	for at in Farm.cells_of(state, Farm.Terrain.SOIL):
		for side in WorldView.EDGE_NEIGHBOURS.size():
			var next: Vector2i = at + WorldView.EDGE_NEIGHBOURS[side]
			if not Grid.in_bounds(next) or Farm.terrain_at(state, next) != Farm.Terrain.GRASS:
				continue
			edged += 1
			var turned := {Grid.index(next): true}
			var before := maxi(WorldView._edge_tile(bytes, at, Farm.Terrain.SOIL).x, 0)
			var after := maxi(WorldView._edge_tile(bytes, at, Farm.Terrain.SOIL, turned).x, 0)
			if before & (1 << side) and not (after & (1 << side)):
				cleared += 1
	expect(edged > 0 and cleared == edged,
		"every bed side on lawn draws grass, and none once that lawn is turned",
		"%d of %d" % [cleared, edged])

	# **Thirteen growing mornings in a season.**
	expect(GameData.crop_harvests({"growth_days": 13}) == 1
		and GameData.crop_harvests({"growth_days": 14}) == 0
		and GameData.crop_harvests({"growth_days": 7}) == 1
		and GameData.crop_harvests({"growth_days": 4, "regrow_days": 3}) == 4,
		"a season holds thirteen growing mornings")
	var wrong: Array = []
	for id in Farming.seeds():
		var got := _followup_season_of(id)
		if got != Farming.harvests_per_season(id):
			wrong.append("%s: %d picked, %d estimated" % [id, got, Farming.harvests_per_season(id)])
	expect(wrong.is_empty(), "every crop's estimate is what a watered season really picks", str(wrong))
	expect(GameData.check_crops(GameData.CROPS).is_empty(), "and no crop dominates on the true counts",
		str(GameData.check_crops(GameData.CROPS)))
	_completed += 1


## Sow on the first day of a crop's season, water it every day, pick it the
## morning it is ready and sow again: the harvests that season really gives.
func _followup_season_of(id: StringName) -> int:
	var state := State.create(1768)
	SuiteKit.crop_supplies(state, id)
	Farming.select_seed(state, id)
	var cell: Vector2i = Farming.field_cells(state)[0]
	var picked := 0
	for _day in GameData.SEASON_DAYS:
		if Farming.is_ready(state, cell):
			Farming.act(state, cell)
			picked += 1
		for _step in 3:
			if Farming.crop_on(state, cell) != &"":
				break
			Farming.act(state, cell)
		Farming.plot(state, cell)["watered"] = true
		Farming.dry_out(state)
		state["day"] = int(state["day"]) + 1
		Farming.morning(state)
	return picked


## 0177 - the big stumps: one thing over four cells. A basic axe is refused;
## an iron axe fells it in the levers' swings, from any of its four cells, for
## the levers' hardwood; it leaves all four cells with one entry in
## `regrowing`, the anchor's, and comes back whole after its regrowth - and
## not while one of its cells is built on.
func _task_0177_hardwood() -> void:
	var node: Dictionary = GameData.GATHERING[&"hardwood_stump"]
	var tree: Dictionary = GameData.GATHERING[&"tree"]
	var hits := int(node["hits"])
	var materials: Array = []
	for group in GameData.RESOURCE_GROUPS:
		if (group as Dictionary)["name"] == &"materials":
			materials = (group as Dictionary)["members"]
	expect(node["tool"] == &"axe" and int(node["min_tier"]) == 1 and hits > int(tree["hits"])
		and int(node["regrow_ticks"]) > 0 and node["yield"].has(GameData.HARDWOOD)
		and Interact.OCCUPANT_VERBS.get(&"hardwood_stump") == &"chop",
		"the big stump is an iron axe's node, more swings than a tree, back again, chopped")
	expect(GameData.RESOURCES.has(GameData.HARDWOOD) and int(GameData.SELL_PRICE.get(GameData.HARDWOOD, 0)) > 0
		and materials.has(GameData.HARDWOOD),
		"hardwood is a material with a price")
	var name_en := Names.of(GameData.HARDWOOD)
	I18n.use("pt_BR")
	var name_pt := Names.of(GameData.HARDWOOD)
	I18n.use("en")
	expect(name_en == "hardwood" and name_pt == "madeira de lei", "named in both languages",
		"%s / %s" % [name_en, name_pt])

	var state := State.create(1771)
	var anchor := Building.anchor_of(state, Farm.cells_with(state, &"hardwood_stump")[0])
	var cells: Array = Building.footprint(&"hardwood_stump", anchor)
	var whole := cells.size() == 4
	for cell in cells:
		whole = whole and StringName(Farm.occupant(state, cell).get("id", &"")) == &"hardwood_stump" \
			and Building.anchor_of(state, cell) == anchor
	expect(whole, "fixture: one stump over four cells, every one carrying its anchor", str(cells))

	# **A basic axe is refused**, before anything moves.
	var hash_before := State.hash_of(state)
	var corner: Vector2i = cells[3]
	expect(Gathering.why_not(state, corner) == [&"WHY_GATHER_TOOL", ToolTiers.item(&"axe", 1)]
		and Gathering.strike(state, corner).is_empty() and State.hash_of(state) == hash_before,
		"a basic axe is refused at the big stump and changes nothing",
		str(Gathering.why_not(state, corner)))

	# **An iron axe fells it, a swing at each of its cells in turn.**
	state["tools"]["axe"] = 1
	var before := Resources.amount(state, GameData.HARDWOOD)
	var waiting := Gathering.regrowing(state)
	var counted: Array = []
	var gained := {}
	for swing in hits:
		gained = Gathering.strike(state, cells[swing % 4])
		if swing < hits - 1:
			counted.append(Gathering.swings_left(state, cells[(swing + 1) % 4]))
	var expected_counts: Array = []
	for left in range(hits - 1, 0, -1):
		expected_counts.append(left)
	expect(counted == expected_counts, "every swing counts on the one stump, whichever cell it lands on",
		"%s against %s" % [counted, expected_counts])
	expect(gained == node["yield"] and Resources.amount(state, GameData.HARDWOOD) == before + int(node["yield"][GameData.HARDWOOD]),
		"the last swing gives the levers' hardwood", str(gained))
	var gone := true
	for cell in cells:
		gone = gone and Farm.is_empty(state, cell)
	var pending: Array = state["regrowing"]
	var entry: Array = []
	for one in pending:
		if int(one[Gathering.PENDING_CELL]) == Grid.index(anchor):
			entry = one
	expect(gone and Gathering.regrowing(state) == waiting + 1 and not entry.is_empty()
		and StringName(entry[Gathering.PENDING_ID]) == &"hardwood_stump",
		"it leaves all four cells, with one entry in regrowing: the anchor's", str(pending))

	# **Back whole after its regrowth.**
	SuiteKit.regrow_after(state, int(node["regrow_ticks"]))
	var back := true
	for cell in cells:
		back = back and StringName(Farm.occupant(state, cell).get("id", &"")) == &"hardwood_stump" \
			and Building.anchor_of(state, cell) == anchor
	expect(back and Gathering.swings_left(state, corner) == hits and Gathering.regrowing(state) == waiting,
		"after regrow_ticks it is back on all four cells, whole, anchored as the map laid it")

	# **Not while one of its cells is built on**, and then as soon as it is clear.
	for swing in hits:
		Gathering.strike(state, anchor)
	expect(Farm.place(state, cells[1], {"id": &"fence", "hp": 10}), "fixture: a fence on one of its cells")
	SuiteKit.regrow_after(state, int(node["regrow_ticks"]))
	var none := true
	for cell in cells:
		none = none and StringName(Farm.occupant(state, cell).get("id", &"")) != &"hardwood_stump"
	expect(none and StringName(Farm.occupant(state, cells[1])["id"]) == &"fence"
		and Gathering.regrowing(state) == waiting + 1,
		"while a fence stands on one cell the stump waits - on none of the four, still pending")
	var saved: Dictionary = bytes_to_var(var_to_bytes(state))
	expect(State.hash_of(saved) == State.hash_of(state), "a waiting stump survives a save")
	Farm.remove(state, cells[1])
	Gathering.tick(state)
	var whole_again := true
	for cell in cells:
		whole_again = whole_again and StringName(Farm.occupant(state, cell).get("id", &"")) == &"hardwood_stump"
	expect(whole_again and Gathering.regrowing(state) == waiting, "and the tick its cells are clear, it is back")

	# **Stood beside, and walked round like a tree.**
	expect(GameData.check_reachable(GameData.GATHERING, GameData.FARM_MAP).is_empty(),
		"every big stump has a cell to stand on beside it")
	expect(Pathing._through(&"hardwood_stump", 1) == Pathing._through(&"tree", 1)
		and not Pathing.is_prey(&"hardwood_stump"),
		"the flow field treats it like a tree: no way through, nothing to come for")
	_completed += 1


## 0178 - sprinklers. A copper one waters its four neighbours on a morning
## and they grow the next; iron the 3x3 and gold the 5x5; the flow field
## crosses one at its ground's cost and no breaker hunts it; it is no plot,
## goes on no crop, and the tables say how it sprays.
func _task_0178_sprinklers() -> void:
	var state := State.create(1780)
	SuiteKit.crop_supplies(state, GameData.CARROT)
	Farming.select_seed(state, GameData.CARROT)
	Resources.gain(state, {GameData.MONEY: 1000, GameData.COPPER: 10, GameData.IRON: 20, GameData.GOLD: 10})
	var at := Vector2i(34, 30)
	var around: Array = Farming.sprayed_by(&"copper_sprinkler", at)
	expect(around == [at + Vector2i.UP, at + Vector2i.LEFT, at + Vector2i.RIGHT, at + Vector2i.DOWN],
		"a copper sprinkler's pattern is its four neighbours, in cell order", str(around))
	expect(Farming.sprayed_by(&"iron_sprinkler", at).size() == 8
		and Farming.sprayed_by(&"gold_sprinkler", at).size() == 24
		and Farming.sprayed_by(&"gold_sprinkler", Vector2i.ZERO).size() == 8,
		"iron waters the 3x3 round it, gold the 5x5, and none off the farm")
	for cell in around + [at, Vector2i(37, 30)]:
		for _step in 3:
			if Farming.verb_at(state, cell) == &"plant":
				break
			Farming.act(state, cell)
	for cell in around + [Vector2i(37, 30)]:
		Farming.act(state, cell)
		Farming.plot(state, cell)["watered"] = false
	expect(Farming.crop_on(state, at) == &"" and Farming.is_tilled(state, at),
		"fixture: four carrots round turned earth, and one more out of reach")

	# **It goes on no crop, and the cell it takes is no plot.**
	expect(Building.why_not(state, &"copper_sprinkler", around[0]) == [&"WHY_ON_A_CROP"],
		"a sprinkler is not put down on a carrot", str(Building.why_not(state, &"copper_sprinkler", around[0])))
	expect(Building.place(state, &"copper_sprinkler", at)
		and StringName(Farm.occupant(state, at).get("id", &"")) == &"copper_sprinkler",
		"by day it goes down on the turned earth", str(Building.why_not(state, &"copper_sprinkler", at)))
	expect(Farming.plot(state, at).is_empty() and Farming.verb_at(state, at) == &"",
		"and its cell is no plot: nothing tills or plants it")

	# **A morning waters the four; the next, they have grown.**
	var growth: Array = []
	for cell in around:
		growth.append(int(Farming.plot(state, cell)["growth"]))
	_followup_night(state)
	var wet := true
	for cell in around:
		wet = wet and Farming.is_watered(state, cell)
	expect(wet and not Farming.is_watered(state, Vector2i(37, 30)),
		"the morning after, its four neighbours are watered and the plot out of reach is not")
	_followup_night(state)
	var grew := true
	for i in around.size():
		grew = grew and int(Farming.plot(state, around[i])["growth"]) == int(growth[i]) + 1
	expect(grew and int(Farming.plot(state, Vector2i(37, 30))["growth"]) == 0,
		"and the next morning they have grown a day, the dry one not")

	# **Walked over, never a wall.**
	Pathing.refresh(state)
	var bare := Vector2i(32, 32)
	expect(Farm.is_empty(state, bare) and Pathing.entry_cost(state, at) == Pathing.entry_cost(state, bare)
		and Farm.terrain_at(state, bare) == Farm.Terrain.SOIL and Pathing._through(&"copper_sprinkler", 7) == 7,
		"the flow field crosses its cell at the ground's cost",
		"%d against %d" % [Pathing.entry_cost(state, at), Pathing.entry_cost(state, bare)])
	expect(not Pathing.is_prey(&"gold_sprinkler") and not Pathing.prey_cells(state).has(at)
		and not Pathing.breaks_through(state, at) and not Farm.walkable(state, at),
		"no breaker hunts it or bites it; the farmer walks round it")

	# **The tables say how it sprays**, and a wrong word is caught.
	var rigged := GameData.BUILDINGS.duplicate(true)
	rigged[&"iron_sprinkler"]["spray"] = &"circle"
	rigged[&"gold_sprinkler"]["walked_over"] = false
	expect(GameData.check_buildings(rigged).size() == 2 and GameData.check_buildings(GameData.BUILDINGS).is_empty(),
		"an unknown spray and a solid sprinkler are refused", str(GameData.check_buildings(rigged)))
	_completed += 1


## Bed, a night held, and the next morning - for a check about mornings.
func _followup_night(state: Dictionary) -> void:
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Phases.enter_result(state, true)
	Phases.begin_day(state)


## 0179 - fish by pond, season and hour. The same seed casts the same
## species; a summer species never bites in spring; two ponds yield different
## sets; a recipe that takes fish takes the cheapest species held; and a
## version 7 save's fish arrive as carp, the commonest.
func _task_0179_species() -> void:
	expect(GameData.check_fishing(GameData.FISHING).is_empty() and GameData.validate().is_empty(),
		"the twelve species and the pond pass their checks", str(GameData.check_fishing(GameData.FISHING)))
	# Twelve, and since task 0182 the four legendaries beside them.
	expect(GameData.group_members(GameData.FISH).size() == 16 and not GameData.RESOURCES.has(GameData.FISH)
		and GameData.FISH_SPECIES.size() == 16,
		"twelve species and four legendaries in the fish group, and no plain fish left")

	# **Every pond's water is that pond's**, and every pond has a catch.
	var state := State.create(1790)
	var anchors: Dictionary = {}
	for pond in GameData.sorted_names(GameData.PONDS.keys()):
		var pair: Array = GameData.PONDS[pond]
		anchors[pond] = Vector2i(int(pair[0]), int(pair[1]))
		expect(Farm.pond_of(state, anchors[pond]) == pond, "%s is water that knows its name" % pond)

	# **The same seed casts the same species.**
	var first := _casts(1791, anchors[&"north_west_pond"], 3, 8 * 60, 40)
	var again := _casts(1791, anchors[&"north_west_pond"], 3, 8 * 60, 40)
	var other := _casts(1792, anchors[&"north_west_pond"], 3, 8 * 60, 40)
	expect(first == again and first != other, "the same seed casts the same species, another seed others",
		str(first.slice(0, 6)))

	# **A summer species never bites in spring**, at any minute, in any pond.
	var summer_only: Array = []
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		if GameData.FISH_SPECIES[id]["seasons"] == [&"summer"]:
			summer_only.append(id)
	var leaked: Array = []
	for pond in anchors:
		for minute in range(GameData.DAY_START_MINUTE, GameData.DAY_END_MINUTE + 1, 30):
			for id in Fishing.catchable(pond, &"spring", minute):
				if summer_only.has(id):
					leaked.append("%s %s %d" % [pond, id, minute])
	var spring_lake := _casts(1793, anchors[&"south_east_lake"], 3, 12 * 60, 200)
	var summer_lake := _casts(1793, anchors[&"south_east_lake"], GameData.SEASON_DAYS + 3, 12 * 60, 200)
	var in_spring := false
	var in_summer := false
	for id in summer_only:
		in_spring = in_spring or spring_lake.has(id)
		in_summer = in_summer or summer_lake.has(id)
	expect(summer_only.has(GameData.DORADO) and leaked.is_empty() and not in_spring and in_summer,
		"a summer species never bites in spring, and does in summer", str(leaked))

	# **Two ponds, two sets.**
	var north := {}
	var south := {}
	for id in _casts(1794, anchors[&"north_west_pond"], 3, 8 * 60, 200):
		north[id] = true
	for id in _casts(1794, anchors[&"south_east_lake"], 3, 8 * 60, 200):
		south[id] = true
	expect(north.keys().size() > 1 and south.keys().size() > 1 and north.has(GameData.CARP)
		and not south.has(GameData.CARP) and north.has(GameData.TROUT) and not south.has(GameData.TROUT),
		"the north-west pond and the south-east lake yield different sets",
		"%s against %s" % [str(north.keys()), str(south.keys())])

	# **A cast's catch is the species on the hook, by name.**
	var line := State.create(1795)
	Fishing.begin(line, anchors[&"forest_pond"])
	var hooked := StringName(Fishing.cast_of(line)["species"])
	line["fishing"]["stage"] = Fishing.BITING
	var caught := Fishing.reel(line)
	expect(caught == {hooked: 1} and Resources.amount(line, hooked) == 1
		and Fishing.last_catch(line)["species"] == hooked and Resources.amount(line, GameData.FISH) == 1,
		"reeling gives the species drawn at the cast, and the last catch names it", str(caught))

	# **cook_fish takes the cheapest species held; the press, three in order.**
	var cook := State.create(1796)
	cook["held"][GameData.STURGEON] = 2
	cook["held"][GameData.PERCH] = 1
	cook["held"][GameData.CARP] = 2
	cook["held"][GameData.CARROT] = 5
	var order := GameData.pay_order(GameData.FISH)
	expect(order[0] == GameData.CARP and order.back() == GameData.STURGEON,
		"fish are paid cheapest first, then by name", str(order))
	expect(Resources.pay(cook, GameData.RECIPES[&"cook_fish"]["inputs"])
		and int(cook["held"][GameData.CARP]) == 1 and int(cook["held"][GameData.STURGEON]) == 2,
		"cook_fish takes a carp, not the sturgeon", str(cook["held"]))
	expect(Resources.pay(cook, GameData.RECIPES[&"press_fish_oil"]["inputs"])
		and int(cook["held"][GameData.CARP]) == 0 and int(cook["held"][GameData.PERCH]) == 0
		and int(cook["held"][GameData.STURGEON]) == 1,
		"the press takes the last carp, then the perch, then one sturgeon", str(cook["held"]))
	expect(not Resources.can_afford(cook, {GameData.FISH: 2})
		and Resources.missing(cook, {GameData.FISH: 3}) == {GameData.FISH: 2},
		"and a cost of fish counts every species together", str(Resources.missing(cook, {GameData.FISH: 3})))
	expect(GameData._worth({GameData.FISH: 3}) == 3 * int(GameData.SELL_PRICE[order[0]])
		and GameData.check_recipes(GameData.RECIPES).is_empty() and GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE).is_empty(),
		"recipes name the fish group, valued at the cheapest member")
	expect(Crafting.recipes_at(&"kitchen").has(&"cook_fish") and Crafting.recipes_at(&"press").has(&"press_fish_oil"),
		"cook_fish is the kitchen's and press_fish_oil the press's")

	# **A version 7 save's fish arrive as carp, the commonest.**
	var heaviest: StringName = GameData.CARP
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		if int(GameData.FISH_SPECIES[id]["weight"]) > int(GameData.FISH_SPECIES[heaviest]["weight"]):
			heaviest = id
	var legacy: Dictionary = Save._read("res://tools/goldens/run-v7.sav")["state"]
	legacy["held"][&"fish"] = 7
	legacy["gained"][&"fish"] = 9
	var path := "user://task0179-legacy.sav"
	expect(Save.write_run_at(path, legacy), "a version 7 golden with fish in it writes")
	var loaded := Save.read_run_at(path)
	expect(heaviest == GameData.CARP and int(loaded["version"]) == 8
		and Resources.amount(loaded, GameData.CARP) == 7 and int(loaded["gained"][GameData.CARP]) == 9
		and not (loaded["held"] as Dictionary).has(&"fish") and not (loaded["held"] as Dictionary).has("fish"),
		"its seven fish arrive as seven carp, nine gained, and the plain fish is gone",
		str(loaded.get("held", {}).get(GameData.CARP, -1)))
	Save._remove(path)
	Save._remove(path + ".bak")
	var current := Save.read_run_at("res://tools/goldens/run-v8.sav")
	expect(not current.is_empty() and int(current["version"]) == 8 and State.VERSION == 8,
		"and the version 8 golden reads back at version 8")
	_completed += 1


## `casts` casts into `water` on `seed_value`, on `day` at `minute`: the species
## on each hook, given up before the next.
func _casts(seed_value: int, water: Vector2i, day: int, minute: int, casts: int) -> Array:
	var state := State.create(seed_value)
	state["day"] = day
	state["days_held"] = 0
	state["day_tick"] = Phases.tick_at_minute(minute)
	var out: Array = []
	for _i in casts:
		Fishing.begin(state, water)
		out.append(StringName(Fishing.cast_of(state)["species"]))
		Fishing.give_up(state)
	return out


## 0180 - the fishing bar. A press on a tick inside the green counts and one
## a tick outside does not; one hit a sweep; a three-hit species needs three;
## the assist widens the green and slows the marker, through its intent; the
## bar running out or too many misses loses the fish and nothing else; and a
## replay with the same presses lands the same fish - nothing after the cast
## is chance.
func _task_0180_minigame() -> void:
	expect(GameData.check_fishing(GameData.FISHING).is_empty(), "the bar's levers pass their check",
		str(GameData.check_fishing(GameData.FISHING)))
	var rigged: Dictionary = GameData.FISH_SPECIES.duplicate(true)
	rigged[GameData.STURGEON]["hits"] = 4
	rigged[GameData.CARP]["zone"] = 99
	var short: Dictionary = GameData.FISHING.duplicate(true)
	short["bar_ticks"] = GameData.SECONDS
	expect(GameData.check_fishing(GameData.FISHING, rigged).size() >= 2
		and not GameData.check_fishing(short).is_empty(),
		"four hits, a green wider than the bar and a bar too short to land a rare fish are refused")

	# **Inside counts; a tick outside does not.**
	var anchors := {}
	for pond in GameData.PONDS:
		anchors[pond] = Vector2i(int(GameData.PONDS[pond][0]), int(GameData.PONDS[pond][1]))
	var state := _bar_line(1800, anchors[&"north_west_pond"], GameData.CARP)
	var line: Dictionary = state["fishing"]
	line["zone_at"] = maxi(int(line["zone_at"]), 10)
	var first_in := -1
	for t in 400:
		var m := Fishing.marker_at(t, int(line["speed"]), int(GameData.FISHING["bar_units"]))
		if m >= int(line["zone_at"]) and m < int(line["zone_at"]) + int(line["zone"]):
			first_in = t
			break
	expect(first_in > 0, "fixture: the green is not where the marker starts", str(line))
	line["since"] = first_in - 1
	state["intent"]["interact"] = true
	Fishing.tick(state, _beside_line(state))
	expect(int(line["misses"]) == 1 and int(line["hits"]) == 0 and not bool(state["intent"]["interact"])
		and not Player.is_busy(state),
		"a press a tick before the green is a miss, spent by the bar and nobody else", str(line))
	state["intent"]["interact"] = true
	Fishing.tick(state, _beside_line(state))
	expect(not Fishing.is_casting(state) and Fishing.last_catch(state)["species"] == GameData.CARP,
		"and the next tick, over the green, the carp's one hit lands it")

	# **One hit a sweep; a three-hit species needs three.**
	var rare := _bar_line(1801, anchors[&"south_east_lake"], GameData.STURGEON)
	var hits_seen: Array = []
	var landed_at := -1
	for t in int(GameData.FISHING["bar_ticks"]):
		var now: Dictionary = rare["fishing"]
		if now.is_empty():
			landed_at = t
			break
		if Fishing.in_zone(now):
			rare["intent"]["interact"] = true
		Fishing.tick(rare, _beside_line(rare))
		if not rare["fishing"].is_empty():
			hits_seen.append(int(rare["fishing"]["hits"]))
	expect(int(GameData.FISH_SPECIES[GameData.STURGEON]["hits"]) == 3 and hits_seen.has(1) and hits_seen.has(2)
		and not hits_seen.has(3) and landed_at > 0 and Fishing.last_catch(rare)["species"] == GameData.STURGEON,
		"pressing every tick over the green scores once a sweep, and the sturgeon's third lands it",
		"landed at %d" % landed_at)

	# **The assist**, through its intent, widens the next cast's green and
	# slows its marker.
	var plain := State.create(1802)
	var helped := State.create(1802)
	helped["intent"]["fishing_assist"] = true
	Fishing.tick(helped, Vector2i.ZERO)
	expect(bool(helped["fishing_assist"]) and not bool(plain["fishing_assist"])
		and Fishing.zone_for(helped, GameData.TROUT) > Fishing.zone_for(plain, GameData.TROUT)
		and Fishing.speed_for(helped, GameData.TROUT) < Fishing.speed_for(plain, GameData.TROUT),
		"the assist's intent sets the run's flag, and the green widens and the marker slows")
	helped["tools"]["rod"] = 2
	expect(Fishing.zone_for(helped, GameData.TROUT) > Fishing.zone_for(plain, GameData.TROUT) + int(GameData.FISHING["assist_zone"]),
		"and the iron rod widens it again")

	# **Running out, or missing too often, loses the fish and nothing else.**
	var idle := _bar_line(1803, anchors[&"forest_pond"], GameData.CARP)
	var held_before: Dictionary = idle["held"].duplicate()
	for _i in int(GameData.FISHING["bar_ticks"]):
		Fishing.tick(idle, _beside_line(idle))
	expect(not Fishing.is_casting(idle) and idle["held"] == held_before and Fishing.last_catch(idle).is_empty(),
		"a bar nobody strikes at runs out, and nothing is taken")
	var clumsy := _bar_line(1804, anchors[&"forest_pond"], GameData.CARP)
	var cline: Dictionary = clumsy["fishing"]
	cline["zone_at"] = 50
	cline["zone"] = 10
	for _i in int(GameData.FISHING["misses_allowed"]) + 1:
		clumsy["intent"]["interact"] = true
		Fishing.tick(clumsy, _beside_line(clumsy))
	expect(not Fishing.is_casting(clumsy) and Fishing.last_catch(clumsy).is_empty(),
		"one miss more than allowed loses it")

	# **The same presses, the same fish**; and nothing after the cast is chance.
	var one := _bar_replay(1805, anchors[&"north_west_pond"])
	var two := _bar_replay(1805, anchors[&"north_west_pond"])
	expect(one == two and not (one["catch"] as Dictionary).is_empty(),
		"a replay with the same presses lands the same fish on the same tick", str(one))
	expect(bool(one["rng_still"]), "and the RNG is not touched between the bite and the catch")
	_completed += 1


## Task 0181: the rod's tiers and the bait. Fibre waits less and draws the
## rarer fish more, by its levers; iron has the bait slot and is 0182's
## legendary gate; a bait on an iron rod is spent at the cast and not on a
## bamboo one; and the hoe turns up worms at the rate `WORM_IN` claims.
func _task_0181_rods() -> void:
	expect(GameData.check_bait(GameData.BAIT_EFFECTS).is_empty() and GameData.validate().is_empty(),
		"the rods, the baits and the worm's rate pass their checks",
		str(GameData.check_bait(GameData.BAIT_EFFECTS)))
	var slower: Dictionary = GameData.BAIT_EFFECTS.duplicate(true)
	slower[GameData.WORM]["bite_percent"] = 150
	var starving: Dictionary = GameData.TOOLS.duplicate(true)
	starving[&"rod"][1]["rare_percent"] = 50
	var untiered: Dictionary = GameData.FISH_SPECIES.duplicate(true)
	(untiered[GameData.TROUT] as Dictionary).erase("tier")
	expect(not GameData.check_bait(slower).is_empty()
		and not GameData.check_bait(GameData.BAIT_EFFECTS, starving).is_empty()
		and not GameData.check_bait(GameData.BAIT_EFFECTS, GameData.TOOLS, 1).is_empty()
		and not GameData.check_bait(GameData.BAIT_EFFECTS, GameData.TOOLS, GameData.WORM_IN, untiered).is_empty(),
		"a bait that lengthens the wait, a rod that starves the rare fish, a worm in every cell and a fish with no rarity are refused")
	expect(GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE).is_empty()
		and GameData.RECIPES[&"make_bait"]["station"] == &"workshop"
		and (GameData.RECIPES[&"make_bait"]["inputs"] as Dictionary).has(GameData.FISH)
		and Names.KEYS.has(&"make_bait") and Names.KEYS.has(GameData.WORM) and Names.KEYS.has(GameData.BAIT)
		and Names.GROUP_KEYS.has(&"bait") and GameData.SELL_PRICE.has(GameData.WORM)
		and GameData.SELL_PRICE.has(GameData.BAIT),
		"fish bait is a workshop recipe the chain passes, and the worm and the bait are priced and named")

	# **Bait is its own group, never a fish**: a recipe that takes any fish
	# cannot be paid with one, and cutting bait takes the cheapest fish.
	var larder := State.create(1810)
	for member in GameData.group_members(GameData.FISH):
		larder["held"][member] = 0
	Resources.add(larder, GameData.STURGEON, 1)
	Resources.add(larder, GameData.CARP, 1)
	Resources.add(larder, GameData.BAIT, 5)
	Resources.add(larder, GameData.WORM, 5)
	expect(Resources.amount(larder, GameData.FISH) == 2 and not GameData.group_members(GameData.FISH).has(GameData.WORM)
		and GameData.group_members(&"bait") == [GameData.WORM, GameData.BAIT],
		"worms and bait are counted apart from the fish")
	expect(Resources.pay(larder, GameData.RECIPES[&"make_bait"]["inputs"])
		and Resources.amount(larder, GameData.CARP) == 0 and Resources.amount(larder, GameData.STURGEON) == 1,
		"cutting bait takes the cheapest fish first")
	var tabs: Array = []
	for group in Inventory.groups(larder):
		tabs.append(StringName((group as Dictionary)["name"]))
	expect(tabs.has(&"bait") and tabs.find(&"bait") == tabs.find(GameData.FISH) + 1,
		"the inventory has a bait tab, after the fish", str(tabs))

	# **Fibre and iron wait less, by their levers.** The same seed, two
	# thousand casts a rod into the north-west pond on a spring morning.
	var water := Vector2i(int(GameData.PONDS[&"north_west_pond"][0]), int(GameData.PONDS[&"north_west_pond"][1]))
	var bamboo := _waits(1811, water, 0, &"", 2000)
	var fibre := _waits(1811, water, 1, &"", 2000)
	var iron := _waits(1811, water, 2, &"", 2000)
	var wormed := _waits(1811, water, 2, GameData.WORM, 2000)
	var fibre_lever := int(GameData.TOOLS[&"rod"][1]["bite_percent"])
	var iron_lever := int(GameData.TOOLS[&"rod"][2]["bite_percent"])
	var worm_lever := iron_lever * int(GameData.BAIT_EFFECTS[GameData.WORM]["bite_percent"]) / 100
	var ratios := "fibre %.1f%%, iron %.1f%%, iron and worm %.1f%% of bamboo's %.1f ticks" % [
		float(fibre["mean"]) / float(bamboo["mean"]) * 100.0, float(iron["mean"]) / float(bamboo["mean"]) * 100.0,
		float(wormed["mean"]) / float(bamboo["mean"]) * 100.0, float(bamboo["mean"])]
	expect(fibre_lever < 100 and absf(float(fibre["mean"]) / float(bamboo["mean"]) * 100.0 - fibre_lever) <= 4.0,
		"the fibre rod's mean wait is bamboo's times its bite_percent", ratios)
	expect(absf(float(iron["mean"]) / float(bamboo["mean"]) * 100.0 - iron_lever) <= 4.0
		and absf(float(wormed["mean"]) / float(bamboo["mean"]) * 100.0 - worm_lever) <= 4.0,
		"the iron rod's is its own, and a worm on it shortens it again", ratios)
	expect(int(bamboo["longest"]) <= int(GameData.FISHING["bite_max_ticks"])
		and int(fibre["longest"]) <= int(GameData.FISHING["bite_max_ticks"]) * fibre_lever / 100
		and int(fibre["shortest"]) >= int(GameData.FISHING["bite_min_ticks"]) * fibre_lever / 100,
		"and every fibre wait is inside the bite range scaled by it",
		"%d-%d" % [int(fibre["shortest"]), int(fibre["longest"])])

	# **And draw the rarer fish more.** The trout is the morning's uncommon
	# here: its weight times the rod's `rare_percent`, the commons untouched.
	var rod_state := State.create(1812)
	var trout := int(GameData.FISH_SPECIES[GameData.TROUT]["weight"])
	var carp := int(GameData.FISH_SPECIES[GameData.CARP]["weight"])
	var weights: Array = []
	for tier in 3:
		rod_state["tools"]["rod"] = tier
		var rare := Fishing.rare_percent(rod_state, &"")
		weights.append([Fishing.weight_of(GameData.TROUT, rare), Fishing.weight_of(GameData.CARP, rare)])
	expect(weights[0] == [trout, carp]
		and weights[1] == [trout * int(GameData.TOOLS[&"rod"][1]["rare_percent"]) / 100, carp]
		and int(weights[2][0]) > int(weights[1][0]) and int(weights[2][1]) == carp,
		"each rod raises the trout's weight by its rare_percent and leaves the carp's", str(weights))
	# Cast for cast, the trout comes up as often as those weights say -
	# within four standard deviations of two thousand draws - and each rod,
	# then fish bait on the iron one, says more often.
	var baited := _waits(1811, water, 2, GameData.BAIT, 2000)
	var shares: Array = []
	var off: Array = []
	var morning := Fishing.catchable(&"north_west_pond", &"spring", 8 * 60)
	for run in [[bamboo, 0, &""], [fibre, 1, &""], [iron, 2, &""], [baited, 2, GameData.BAIT]]:
		rod_state["tools"]["rod"] = int(run[1])
		var rare := Fishing.rare_percent(rod_state, StringName(run[2]))
		var total := 0
		for id in morning:
			total += Fishing.weight_of(StringName(id), rare)
		var p := float(Fishing.weight_of(GameData.TROUT, rare)) / float(total)
		shares.append(p)
		var seen := int((run[0] as Dictionary)["uncommon"])
		if absf(float(seen) - p * 2000.0) > 4.0 * sqrt(2000.0 * p * (1.0 - p)):
			off.append("%d trout against %.0f" % [seen, p * 2000.0])
	expect(morning.has(GameData.TROUT) and off.is_empty()
		and float(shares[1]) > float(shares[0]) and float(shares[2]) > float(shares[1])
		and float(shares[3]) > float(shares[2]),
		"so the trout comes up more on fibre, more on iron, more again with fish bait, as often as the weights say",
		"%s %s" % [str(shares), str(off)])

	# **The slot and the gate are iron's.**
	var gates: Array = []
	for tier in 3:
		rod_state["tools"]["rod"] = tier
		gates.append([Fishing.has_bait_slot(rod_state), Fishing.takes_legendary(rod_state)])
	expect(gates == [[false, false], [false, false], [true, true]],
		"only the iron rod has the bait slot, and only it is the rod a legendary takes", str(gates))

	# **Bait is spent at an iron-rod cast and not at a bamboo one.**
	var line := State.create(1813)
	line["day"] = 3
	line["day_tick"] = Phases.tick_at_minute(8 * 60)
	Resources.add(line, GameData.WORM, 2)
	expect(Fishing.choose_bait(line, GameData.WORM) and not Fishing.choose_bait(line, GameData.CARP)
		and Fishing.bait_of(line) == GameData.WORM,
		"the worm goes on; a carp is not a bait")
	Fishing.begin(line, water)
	expect(Resources.amount(line, GameData.WORM) == 2 and StringName(Fishing.cast_of(line)["bait"]) == &"",
		"the bamboo rod has no slot: the worm stays in the tin and does nothing")
	Fishing.give_up(line)
	line["tools"]["rod"] = 2
	Fishing.begin(line, water)
	expect(Resources.amount(line, GameData.WORM) == 1 and StringName(Fishing.cast_of(line)["bait"]) == GameData.WORM
		and int(Fishing.cast_of(line)["left"]) <= int(GameData.FISHING["bite_max_ticks"]) * worm_lever / 100,
		"the iron rod spends one at the cast, and the wait is the worm's",
		str(Fishing.cast_of(line).get("left", -1)))
	Fishing.give_up(line)
	Resources.spend(line, GameData.WORM, 1)
	expect(Fishing.begin(line, water) and StringName(Fishing.cast_of(line)["bait"]) == &""
		and Resources.amount(line, GameData.WORM) == 0,
		"with none left the line still goes in, plain: no bait is no effect, not a refusal")
	Fishing.give_up(line)
	var steps: Array = []
	for _i in 4:
		steps.append(Fishing.step_bait(line, 1))
	steps.append(Fishing.step_bait(line, -1))
	expect(steps == [GameData.BAIT, &"", GameData.WORM, GameData.BAIT, GameData.WORM],
		"stepping goes round worm, fish bait and none, both ways", str(steps))

	# **The hoe finds a worm one cell in `WORM_IN`**, drawn from the run's
	# RNG: every free cell of a farm turned, one at a time.
	var field := State.create(1814)
	var turned := _till_the_farm(field, 2400)
	var found := Resources.amount(field, GameData.WORM)
	var claimed := float(turned) / float(GameData.WORM_IN)
	expect(turned >= 1600 and absf(float(found) - claimed) <= claimed * 0.2,
		"tilling finds worms at the rate claimed", "%d worms in %d cells, %.0f claimed" % [found, turned, claimed])
	var again := State.create(1814)
	_till_the_farm(again, 2400)
	expect(Resources.amount(again, GameData.WORM) == found and str(again["rng"]) == str(field["rng"]),
		"and the same seed finds the same worms")
	var plots: Array = (field["plots"] as Dictionary).keys()
	plots.sort()
	var tilled := Grid.cell(int(plots[0]))
	Farming.plot(field, tilled)["crop"] = GameData.CARROT
	var rng_before := str(field["rng"])
	expect(Farming.clear_crop(field, tilled) and str(field["rng"]) == rng_before
		and Resources.amount(field, GameData.WORM) == found,
		"clearing a crop turns the earth and draws no worm")
	_completed += 1


## Turn up to `most` free cells of the farm with the hoe, one at a time in
## reading order; how many were turned.
func _till_the_farm(state: Dictionary, most: int) -> int:
	var turned := 0
	for y in Grid.HEIGHT:
		for x in Grid.WIDTH:
			if turned < most and Farming.verb_at(state, Vector2i(x, y)) == &"till":
				Farming.act(state, Vector2i(x, y))
				turned += 1
	return turned


## Task 0182: the legendaries and the fish book. The spring legendary never
## bites on the bamboo or fibre rod and does under its conditions on the iron
## rod; each of the four only in its own water, hours and condition, once a
## run, on the hardest bar; and a catch writes the run's book and, folded, the
## profile.
func _task_0182_legendary() -> void:
	expect(GameData.check_fishing(GameData.FISHING).is_empty() and GameData.validate().is_empty(),
		"the four legendaries pass their checks", str(GameData.check_fishing(GameData.FISHING)))
	var rigged: Dictionary = GameData.FISH_SPECIES.duplicate(true)
	rigged[GameData.OLD_CATFISH]["condition"] = &"rain"
	rigged[GameData.GOLDEN_QUEEN]["zone"] = 30
	rigged[GameData.GHOST_PIKE]["seasons"] = [&"spring"]
	rigged[GameData.CARP]["condition"] = &"full_moon"
	var refused := GameData.check_fishing(GameData.FISHING, rigged)
	expect(refused.size() >= 4,
		"a condition no cast can meet, an easy bar, two legendaries in one season and a common that waits are refused",
		str(refused))
	var by_season: Dictionary = {}
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		if Fishing.is_legendary(id):
			by_season[GameData.FISH_SPECIES[id]["seasons"][0]] = id
	expect(by_season == {&"spring": GameData.OLD_CATFISH, &"summer": GameData.GOLDEN_QUEEN,
		&"autumn": GameData.GHOST_PIKE, &"winter": GameData.ICE_STURGEON},
		"one legendary a season: the Old Catfish, the Golden Queen, the Ghost Pike, the Ice Sturgeon", str(by_season))

	# **The spring legendary**: the forest pond after dark on a spring Full
	# Moon day. Six hundred casts a rod, the same seed.
	var water := {}
	for pond in GameData.sorted_names(GameData.PONDS.keys()):
		water[pond] = Vector2i(int(GameData.PONDS[pond][0]), int(GameData.PONDS[pond][1]))
	var moon := int(GameData.FULL_MOON_DAYS[0])
	var night := 21 * 60
	var counts: Array = []
	for tier in 3:
		counts.append(_legend_count(1820, water[&"forest_pond"], moon, night, tier, &"", 600, GameData.OLD_CATFISH))
	expect(counts[0] == 0 and counts[1] == 0 and counts[2] > 0,
		"the Old Catfish never bites on the bamboo or fibre rod, and does on the iron one", str(counts))
	var off: Array = [
		_legend_count(1820, water[&"forest_pond"], moon - 1, night, 2, &"", 600, GameData.OLD_CATFISH),
		_legend_count(1820, water[&"forest_pond"], moon, 12 * 60, 2, &"", 600, GameData.OLD_CATFISH),
		_legend_count(1820, water[&"north_west_pond"], moon, night, 2, &"", 600, GameData.OLD_CATFISH),
		_legend_count(1820, water[&"forest_pond"], moon + GameData.SEASON_DAYS, night, 2, &"", 600, GameData.OLD_CATFISH),
	]
	expect(off == [0, 0, 0, 0],
		"and not the day before the Full Moon, nor at noon, nor in another pond, nor in summer", str(off))
	expect(Fishing.catchable(&"forest_pond", &"spring", night).size() > 0
		and not Fishing.catchable(&"forest_pond", &"spring", night).has(GameData.OLD_CATFISH),
		"the plain draw never holds a legendary; its own gate adds it")

	# **The other three**, each under its own condition and not without it.
	var summer := GameData.SEASON_DAYS + 3
	var autumn := 2 * GameData.SEASON_DAYS + 3
	var winter_moon := 3 * GameData.SEASON_DAYS + moon
	var met: Array = [
		_legend_count(1821, water[&"south_east_lake"], summer, 12 * 60, 2, GameData.WORM, 600, GameData.GOLDEN_QUEEN),
		_legend_count(1822, water[&"north_west_pond"], autumn, 23 * 60, 2, GameData.BAIT, 600, GameData.GHOST_PIKE),
		_legend_count(1823, water[&"south_east_lake"], winter_moon, 7 * 60, 2, &"", 600, GameData.ICE_STURGEON),
	]
	var unmet: Array = [
		_legend_count(1821, water[&"south_east_lake"], summer, 12 * 60, 2, GameData.BAIT, 600, GameData.GOLDEN_QUEEN),
		_legend_count(1822, water[&"north_west_pond"], autumn, 23 * 60, 2, GameData.WORM, 600, GameData.GHOST_PIKE),
		_legend_count(1823, water[&"south_east_lake"], winter_moon - 1, 7 * 60, 2, &"", 600, GameData.ICE_STURGEON),
	]
	expect(met[0] > 0 and met[1] > 0 and met[2] > 0 and unmet == [0, 0, 0],
		"the Golden Queen takes a worm, the Ghost Pike fish bait and the Ice Sturgeon a Full Moon - and none without",
		"%s with, %s without" % [str(met), str(unmet)])

	# **Landed, it is in the book - and once a run.**
	var run := _legend_state(1824, moon, night, 2)
	var drawn := false
	for _i in 2000:
		Fishing.begin(run, water[&"forest_pond"])
		if StringName(Fishing.cast_of(run)["species"]) == GameData.OLD_CATFISH:
			drawn = true
			break
		Fishing.give_up(run)
	var line: Dictionary = Fishing.cast_of(run)
	var hardest := true
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		if not Fishing.is_legendary(id) and (int(GameData.FISH_SPECIES[id]["speed"]) > int(line["speed"])
				or Fishing.zone_for(run, id) < int(line["zone"])):
			hardest = false
	expect(drawn and int(line["needs"]) == 3 and hardest,
		"the Old Catfish is the hardest bar there is: three hits, the fastest marker, the narrowest green", str(line))
	line["stage"] = Fishing.BITING
	Fishing.reel(run)
	var book := Fishing.book_of(run)
	expect(book.has(GameData.OLD_CATFISH) and int(book[GameData.OLD_CATFISH]["caught"]) == 1
		and int(book[GameData.OLD_CATFISH]["first_day"]) == moon
		and Resources.amount(run, GameData.OLD_CATFISH) == 1,
		"a catch writes the book: one Old Catfish, first on the Full Moon", str(book))
	var again := 0
	for _i in 600:
		Fishing.begin(run, water[&"forest_pond"])
		if StringName(Fishing.cast_of(run)["species"]) == GameData.OLD_CATFISH:
			again += 1
		Fishing.give_up(run)
	expect(again == 0 and Fishing.legendaries_at(run, &"forest_pond", &"spring", night, &"").is_empty(),
		"once a run: the book has it, and the draw skips it", str(again))
	Fishing.begin(run, water[&"forest_pond"])
	run["fishing"]["species"] = GameData.CARP
	run["fishing"]["stage"] = Fishing.BITING
	Fishing.reel(run)
	Fishing.begin(run, water[&"forest_pond"])
	run["fishing"]["species"] = GameData.CARP
	run["fishing"]["stage"] = Fishing.BITING
	Fishing.reel(run)
	expect(int(Fishing.book_of(run)[GameData.CARP]["caught"]) == 2,
		"every fish landed counts in the book, the commons too")

	# **The profile keeps it**, folded through `Stats`, banked so a second
	# fold adds nothing, and a new run starts with an empty book.
	var profile := Stats.fold({}, run)
	var twice := Stats.fold(profile, run)
	var life: Dictionary = Stats.lifetime(twice)["fish_book"]
	expect(life == {GameData.CARP: 2, GameData.OLD_CATFISH: 1},
		"the fold writes the book into the profile, and folding again adds nothing", str(life))
	var next_run := _legend_state(1825, moon, night, 2)
	expect(Fishing.book_of(next_run).is_empty()
		and int(Stats.fish_known(twice, next_run).get(GameData.OLD_CATFISH, 0)) == 1
		and not Fishing.legendaries_at(next_run, &"forest_pond", &"spring", night, &"").is_empty(),
		"the next run's book is empty and the profile still knows the Old Catfish, which may bite again")
	Fishing.begin(next_run, water[&"forest_pond"])
	next_run["fishing"]["species"] = GameData.CARP
	next_run["fishing"]["stage"] = Fishing.BITING
	Fishing.reel(next_run)
	expect(int(Stats.fish_known(twice, next_run)[GameData.CARP]) == 3,
		"and a carp landed since is counted on top of the banked two, before the night folds it")

	# **The book survives a save**, and the same casts write the same book.
	var path := "user://task0182-book.sav"
	expect(Save.write_run_at(path, run), "a run with a book writes")
	var loaded := Save.read_run_at(path)
	expect(Fishing.book_of(loaded) == Fishing.book_of(run) and State.hash_of(loaded) == State.hash_of(run),
		"and reads back with the same pages", str(Fishing.book_of(loaded)))
	expect(Fishing.last_catch(loaded) == Fishing.last_catch(run) and not Fishing.last_catch(run).is_empty(),
		"and the last catch with them: declared now, a load no longer drops it", str(Fishing.last_catch(loaded)))
	Save._remove(path)
	Save._remove(path + ".bak")
	expect(State.RUN_DATA.has("fish_book") and not State.TABLES.has("fish_book"),
		"the book's keys come from play")
	_completed += 1


## Task 0183: the coop and the barn. Building a coop moves the map's
## chickens in, their produce with them, and it still comes - collected at
## the door; a full coop refuses another chicken; a barn holds its capacity;
## a lost home's animals wait for the next; a save with loose animals works.
func _task_0183_barns() -> void:
	expect(GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP).is_empty()
		and GameData.validate().is_empty(), "the animals' homes and sources pass their checks",
		str(GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP)))
	var homeless: Dictionary = GameData.LIVESTOCK.duplicate(true)
	homeless[&"cow"]["home"] = &"kitchen"
	var unsourced: Dictionary = GameData.LIVESTOCK.duplicate(true)
	unsourced[&"chicken"]["source"] = &"the_moon"
	var empty_barn: Dictionary = GameData.LIVESTOCK.duplicate(true)
	empty_barn.erase(&"cow")
	var bought: Dictionary = GameData.LIVESTOCK.duplicate(true)
	bought[&"sheep"] = (bought[&"cow"] as Dictionary).duplicate(true)
	bought[&"sheep"]["source"] = &"stall"
	expect(not GameData.check_livestock(homeless, GameData.FARM_MAP).is_empty()
		and not GameData.check_livestock(unsourced, GameData.FARM_MAP).is_empty()
		and not GameData.check_livestock(empty_barn, GameData.FARM_MAP).is_empty(),
		"a kind with no home, one from nowhere, and a barn nobody lives in are refused")
	expect(GameData.check_livestock(bought, GameData.FARM_MAP).is_empty(),
		"and an animal the stall sells need not stand on the map")

	# **The coop takes the map's chickens in.** Their produce comes with them.
	var state := State.create(1830)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var hens := Farm.cells_with(state, &"chicken")
	var cow_cells := Farm.cells_with(state, &"cow")
	expect(hens.size() == 2 and cow_cells.size() == 1, "fixture: the map's two chickens and a cow", str(hens))
	Livestock.tick(state)
	(state["livestock"][Grid.index(hens[0])] as Dictionary)["ready"] = 1
	var coop := _site_spot(state, &"coop")
	expect(coop != Vector2i(-1, -1), "fixture: the coop's site has room for one")
	var version := int(state["grid_version"])
	expect(Building.place(state, &"coop", coop), "a coop goes up by day on its site")
	var cells := Building.footprint(&"coop", coop).size()
	expect(Farm.cells_with(state, &"chicken").is_empty() and Livestock.residents(state, coop).size() == 2
		and not (state["livestock"] as Dictionary).has(Grid.index(hens[0])),
		"and both chickens move in, off the map", str(Livestock.residents(state, coop)))
	expect(int(state["grid_version"]) == version + cells + 1,
		"with one touch of the farm for both", "%d -> %d" % [version, int(state["grid_version"])])
	var door := Livestock.door_of(state, coop)
	expect(door == coop + Vector2i(1, 1) and Livestock.door_of(state, coop + Vector2i(2, 0)) == door,
		"the coop's door is the middle of its front row, from any of its cells", str(door))
	expect(Livestock.ready_at(state, door) == 1 and Interact.verb_at(state, door) == &"collect"
		and Interact.verb_at(state, coop) == &"",
		"the hen's waiting egg-to-be came in with her: the door offers to collect, the wall does not")
	var meat := Resources.amount(state, GameData.MEAT)
	Interact.complete(state, door, &"collect")
	expect(Resources.amount(state, GameData.MEAT) == meat + 1 and Livestock.ready_at(state, door) == 0,
		"collected at the door")
	var every := int(GameData.LIVESTOCK[&"chicken"]["every_ticks"])
	for _i in every:
		Livestock.tick(state)
	expect(Livestock.ready_at(state, door) == 2,
		"and housed, they go on producing on the same clock", str(Livestock.ready_at(state, door)))

	# **A full coop refuses another chicken**; a cow is not the coop's.
	var capacity := int(GameData.BUILDINGS[&"coop"]["capacity"])
	var took: Array = []
	for _i in capacity:
		took.append(Livestock.house(state, coop, &"chicken"))
	expect(took.count(true) == capacity - 2 and took.count(false) == 2
		and Livestock.residents(state, coop).size() == capacity
		and not Livestock.house(state, coop, &"chicken") and not Livestock.house(state, door, &"cow"),
		"the coop fills to its capacity and refuses another chicken, and any cow", str(took))
	expect(Building.why_not_sell(state, coop) == [&"WHY_HOME_IN_USE"] and Building.sell(state, coop).is_empty(),
		"and a coop with hens in it is not sold out from under them")

	# **The barn holds its capacity**: the cow, then as many more as it has room for.
	var barn := _site_spot(state, &"barn")
	expect(barn != Vector2i(-1, -1) and Building.place(state, &"barn", barn),
		"a barn goes up on its site")
	var barn_room := int(GameData.BUILDINGS[&"barn"]["capacity"])
	expect(Farm.cells_with(state, &"cow").is_empty() and Livestock.residents(state, barn).size() == 1,
		"and the map's cow moves in")
	var cows := 1
	while Livestock.house(state, barn, &"cow"):
		cows += 1
	expect(cows == barn_room and Livestock.residents(state, barn).size() == barn_room
		and not Livestock.house(state, barn, &"chicken"),
		"the barn holds its capacity of cows, and no chicken", "%d of %d" % [cows, barn_room])
	expect(Livestock.door_of(state, barn) == barn + Vector2i(2, 3),
		"its door is the middle of its front row too")

	# **A lost home loses no animal**: they wait, and the next coop takes them.
	var before := State.hash_of(state)
	Farm.remove(state, coop)
	expect((state["unhoused"] as Array).size() == capacity and not (state["housed"] as Dictionary).has(Grid.index(coop))
		and State.hash_of(state) != before,
		"a coop knocked down leaves its hens waiting, none lost", str((state["unhoused"] as Array).size()))
	for part in Building.footprint(&"coop", coop):
		Farm.remove(state, part)
	expect(Building.place(state, &"coop", coop) and Livestock.residents(state, coop).size() == capacity
		and (state["unhoused"] as Array).is_empty(),
		"and the next coop takes every one of them back in")

	# **Loose animals work as they did** until a home exists - and in a save.
	var loose := State.create(1831)
	var cow: Vector2i = Farm.cells_with(loose, &"cow")[0]
	for _i in int(GameData.LIVESTOCK[&"cow"]["every_ticks"]):
		Livestock.tick(loose)
	expect(Livestock.ready_at(loose, cow) == 1 and Interact.verb_at(loose, cow) == &"collect",
		"with no barn the cow stands where the map put it and works as before")
	var legacy := Save.read_run_at("res://tools/goldens/run-v8.sav")
	var cow_then: Array = Farm.cells_with(legacy, &"cow")
	for _i in int(GameData.LIVESTOCK[&"cow"]["every_ticks"]):
		Livestock.tick(legacy)
	expect(not legacy.is_empty() and (legacy["housed"] as Dictionary).is_empty() and not cow_then.is_empty()
		and Livestock.ready_at(legacy, cow_then[0]) >= 1,
		"a save with loose animals loads, homeless as it was, and its cow still produces")
	_completed += 1


## The top-left cell of a home's `MAP_SITES` room where one fits, or
## (-1, -1).
func _site_spot(state: Dictionary, id: StringName) -> Vector2i:
	var room: Array = GameData.MAP_SITES[id]
	for y in range(int(room[1]), int(room[1]) + int(room[3])):
		for x in range(int(room[0]), int(room[0]) + int(room[2])):
			if Building.can_place(state, id, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## How many of `casts` casts into `water` on `seed_value`, on `day` at `minute`
## with the rod at `tier` and `bait` on and held, came up `wanted`.
func _legend_count(seed_value: int, water: Vector2i, day: int, minute: int, tier: int,
		bait: StringName, casts: int, wanted: StringName) -> int:
	var state := _legend_state(seed_value, day, minute, tier)
	if bait != &"":
		Resources.add(state, bait, casts)
		Fishing.choose_bait(state, bait)
	var count := 0
	for _i in casts:
		Fishing.begin(state, water)
		if StringName(Fishing.cast_of(state)["species"]) == wanted:
			count += 1
		Fishing.give_up(state)
	return count


## A run on `seed_value` on `day` at `minute` of its clock, the rod at `tier`.
func _legend_state(seed_value: int, day: int, minute: int, tier: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = day
	state["days_held"] = 0
	state["day_tick"] = Phases.tick_at_minute(minute)
	state["tools"]["rod"] = tier
	return state


## `casts` casts into `water` on `seed_value` with the rod at `tier` and
## `bait` on (and always held): the mean, shortest and longest wait, and how
## many came up anything but common.
func _waits(seed_value: int, water: Vector2i, tier: int, bait: StringName, casts: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = 3
	state["day_tick"] = Phases.tick_at_minute(8 * 60)
	state["tools"]["rod"] = tier
	if bait != &"":
		Resources.add(state, bait, casts)
		Fishing.choose_bait(state, bait)
	var total := 0
	var shortest := 1 << 30
	var longest := 0
	var uncommon := 0
	for _i in casts:
		Fishing.begin(state, water)
		var left := int(Fishing.cast_of(state)["left"])
		total += left
		shortest = mini(shortest, left)
		longest = maxi(longest, left)
		if GameData.FISH_SPECIES[Fishing.cast_of(state)["species"]]["tier"] != &"common":
			uncommon += 1
		Fishing.give_up(state)
	return {"mean": float(total) / float(casts), "shortest": shortest, "longest": longest, "uncommon": uncommon}


## A line on `water`, already biting, of `species` - the cast's own draws
## made, then the species set and the bar's green and pace worked out for it.
func _bar_line(seed_value: int, water: Vector2i, species: StringName) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = 3
	state["day_tick"] = Phases.tick_at_minute(8 * 60)
	SuiteKit.stand_the_farmer(state, water + Vector2i.DOWN)
	Fishing.begin(state, water)
	var line: Dictionary = state["fishing"]
	line["species"] = species
	line["zone"] = Fishing.zone_for(state, species)
	line["zone_at"] = mini(int(line["zone_at"]), int(GameData.FISHING["bar_units"]) - int(line["zone"]))
	line["speed"] = Fishing.speed_for(state, species)
	line["needs"] = int(GameData.FISH_SPECIES[species]["hits"])
	line["left"] = 1
	Fishing.tick(state, _beside_line(state))
	return state


func _beside_line(state: Dictionary) -> Vector2i:
	return Fishing.line_cell(state) + Vector2i.DOWN


## Cast, wait out the bite, and press on the green every tick: what lands, on
## which tick, and whether the RNG moved between the bite and the catch.
func _bar_replay(seed_value: int, water: Vector2i) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = 3
	state["day_tick"] = Phases.tick_at_minute(8 * 60)
	SuiteKit.stand_the_farmer(state, water + Vector2i.DOWN)
	Fishing.begin(state, water)
	while not Fishing.is_biting(state):
		Fishing.tick(state, water + Vector2i.DOWN)
	var rng_at_bite := str(state["rng"])
	var tick := 0
	while Fishing.is_casting(state) and tick < 1000:
		if Fishing.in_zone(Fishing.cast_of(state)):
			state["intent"]["interact"] = true
		Fishing.tick(state, water + Vector2i.DOWN)
		tick += 1
	return {"catch": Fishing.last_catch(state), "tick": tick, "rng_still": str(state["rng"]) == rng_at_bite}
