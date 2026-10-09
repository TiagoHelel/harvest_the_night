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
const GROUPS := 34

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
	Sim.advance(early, Phases.tick_at_minute(9 * 60))
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
		GameData.FOOD: 9000}
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
		var plot: Vector2i = Farm.cells_of(farm, Farm.Terrain.SOIL)[0]
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
			if Interact.verb_at(farm, cell) != &"" or Farm.walkable(farm, cell):
				missing.append("%s at %s is not inert" % [id, cell])
	expect(missing.is_empty(), "copper, coal, gold and the hardwood stump are on the map, inert",
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
	var cells := Farm.cells_of(state, Farm.Terrain.SOIL)
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
		var cell: Vector2i = Farm.cells_of(overnight, Farm.Terrain.SOIL)[0]
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
