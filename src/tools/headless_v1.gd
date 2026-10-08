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
const GROUPS := 9

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
	# Where the build step's lever may still be named, and why.
	var allowed := {
		"res://src/tools/night_road.gd": "the road itself",
		"res://src/tools/headless_check.gd:_task_0006_phases":
			"the timer is the subject of the assert; 0136 rewrites it",
	}
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
				if code.contains(timer):
					if allowed.has(path) or allowed.has(path + ":" + where):
						seen[path] = true
					else:
						timers.append("%s:%s" % [path, where])
				if code.contains(door):
					doors.append("%s:%s" % [path, where])
	expect(seen.has("res://src/tools/night_road.gd")
		and seen.has("res://src/tools/headless_check.gd"),
		"the scan sees the road and the 0006 timer assert", str(seen.keys()))
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

	# **The same ticks as before the road.** On a fresh build step it runs off
	# exactly the lever's worth, and the night starts on the last of them.
	# The lever's worth, measured the long way: one tick at a time.
	var counted := State.create(1183)
	Phases.begin_preparation(counted)
	var by_hand := 0
	while int(counted["phase"]) == Phases.PREPARATION and by_hand < 100000:
		Sim.tick(counted)
		by_hand += 1
	var fresh := State.create(1183)
	NightRoad.into_build(fresh)
	var tick := int(fresh["tick"])
	var left := NightRoad.build_ticks_left(fresh)
	NightRoad.through_build(fresh)
	expect(int(fresh["tick"]) - tick == left and left == by_hand
		and int(fresh["phase"]) == Phases.NIGHT
		and State.hash_of(fresh) == State.hash_of(counted),
		"a fresh build step is the lever's ticks, ending in the night",
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
	var run := PlayerArt.animation(&"run_south")
	expect(int(run.get("frames", 0)) == 8
		and is_equal_approx(float(run.get("seconds", 0.0)), 0.07),
		"run_south: eight frames at 0.07 s, from the registry", str(run))
	expect(PlayerArt.texture_path(&"run_south", 0)
		== PlayerArt.texture_path(&"walk_south", 0),
		"and its frame 0 is the walk's texture", PlayerArt.texture_path(&"run_south", 0))
	var walk := PlayerArt.animation(&"walk_south")
	expect(int(walk.get("frames", 0)) == int(PlayerFrames.COUNT[&"walk_south"]),
		"a real animation still answers from PlayerFrames", str(walk))
	expect(PlayerArt.animation(&"nobody").is_empty(), "and an unknown one, nothing")
	# Nothing asks for the stand-ins yet: the run is still the walk, faster.
	var running := PlayerArt.pose(Player.SOUTH, true, &"", true)
	expect(running["name"] == &"walk_south"
		and is_equal_approx(float(running["seconds"]), PlayerArt.RUN_FRAME_SECONDS),
		"PlayerArt.pose still names walk_<dir> for the run", str(running))
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
		&"slot_1": "six seed slots outnumber the free buttons; 0133's hotbar picks slots on a pad",
		&"slot_2": "the seed slots: see slot_1",
		&"slot_3": "the seed slots: see slot_1",
		&"slot_4": "the seed slots: see slot_1",
		&"slot_5": "the seed slots: see slot_1",
		&"slot_6": "the seed slots: see slot_1",
		&"speed": "a focusable night HUD button; 0139 gives every HUD control focus or an action",
		&"skip_night": "a focusable night HUD button, like speed",
		&"stats": "a read-only screen no play depends on, and no button left over",
		&"log": "a read-only screen, like stats",
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
	var line := I18n.f(&"DHUD_DAY", [3, (late / 60) % 24, late % 60, ""])
	expect(line.contains("01:30") and not line.contains("25:30"),
		"01:30, never 25:30", line)
	var morning := I18n.f(&"DHUD_DAY", [1, 6, 0, ""])
	expect(morning.contains("06:00"), "and 06:00 with its zero", morning)
	_completed += 1
