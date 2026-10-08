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
const GROUPS := 20

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

	# **A boss holds the night past dawn** (until 0153).
	var giant := _a_night_near_dawn(1373, 5)
	Entities.spawn(giant, &"giant", Enemies.spawn_cells(giant, 0)[0])
	Sim.advance(giant, 30)
	expect(int(giant["phase"]) == Phases.NIGHT and Phases.ticks_to_dawn(giant) == 0,
		"dawn does not end a night while a boss is on the farm",
		Phases.name_of(int(giant["phase"])))

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
