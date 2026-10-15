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
const GROUPS := 108

## A005's eight defences, the ones it drew icons for (task 0147). A later
## defence wears its own pack's, or its drawing until then (0224's decoy).
const A005_DEFENCES: Array = [&"auto_crossbow", &"barricade", &"fence", &"flame_tower",
	&"gun_tower", &"mine", &"mortar", &"wall"]

const ActionsScript := preload("res://src/app/input_actions.gd")

var passed := 0
var failed := 0

var _completed := 0
var _finished := false
## Where 0224's decoys found bare ground, once (`_open_square`).
var _decoy_ground := Vector2i(-1, -1)
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
	_task_0184_feed()
	_task_0185_animals()
	_task_0186_barns_night()
	_task_0187_keg()
	_task_0188_mills()
	_task_0189_bin()
	_task_0190_peddler()
	_task_0191_house()
	_task_0192_kitchen()
	_task_0193_supply()
	_task_0194_economy()
	_task_0195_tips()
	_task_0218_perf_ground()
	_task_0219_essence()
	_task_0220_tree_seasons()
	_task_0221_night_loot()
	_task_0222_bone_meal()
	_task_0223_tarps()
	_task_0224_decoy()
	_task_0225_bait()
	_task_0226_beehive()
	_task_0227_catapult()
	_task_0228_garlic()
	_task_0229_light()
	_task_0230_electric_fence()
	_task_0231_strong_walls()
	_task_0232_powers_list()
	_task_0233_powers()
	_task_0234_arsenal()
	_task_0246_bosses()
	_task_0247_spitter()
	_task_0248_rats()
	_task_0249_crow()
	_task_0250_digger()
	_task_0251_frost()
	_task_0252_wraith()
	_task_0253_harvester()
	_task_0254_scarecrow_king()
	_task_0255_winter_lord()
	_task_0256_fog_rain()
	_task_0257_blood_moon()
	_task_0270_year_records()
	_task_0271_spring_nights()
	_task_0272_summer_nights()
	_task_0273_autumn_nights()
	_task_0274_winter_nights()
	_task_0275_perf_year()
	_task_0276_year_autoplay()
	_task_0277_year_balance()
	_task_0281_day_sounds()
	_task_0282_fishing_sounds()
	_task_0283_guardian_sounds()
	_task_0284_enemy_sounds()
	_task_0285_season_music()
	_task_0286_weather_ambience()
	_task_0287_collections()
	_task_0292_options()
	_task_0293_first_week()
	_task_0147_night_icons()
	_task_0161_calendar_icons()
	_task_0162_forecast_heads()
	_task_0163_winter_ground()
	_task_0164_seasonal_trees()
	_task_0202_tool_icons()
	_task_0203_material_icons()
	_task_0211_animal_goods()
	_task_0197_crop_ground()
	_task_0198_spring_crops()
	_task_0199_summer_crops()
	_task_0200_autumn_crops()
	_task_0201_sprinklers()
	_task_0206_fishing_gear()
	_task_0209_sheep_pig()
	_task_0210_cow_chicken()
	_task_0212_coop_barn()
	_task_0215_shipping_bin()
	_task_0216_peddler()
	_task_0217_house_tiers()
	_task_0204_ore_hardwood()
	_task_0205_fish()
	_task_0213_machines()
	_task_0214_artisan_goods()


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
	# because "they are not in `ENDLESS`" is not `ENDLESS` being hashed.
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
	for known in ["CROPS", "SEASON_NIGHTS", "NEIGHBOUR_STEPS"]:
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
		GameData.IRON: 500, GameData.GUNPOWDER: 500, GameData.FOOD: 500,
		GameData.MONEY: 500})
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
	# At the tower's own cell (task 0229): a tile more again if it is lit.
	var reach := Towers.reach_of(far["state"], flame, far["tower"])
	var lit_bonus := GameData.LIGHT_REACH_BONUS if Light.is_lit(far["state"], far["tower"]) else 0
	expect(reach == int(flame["range"]) + 1 + lit_bonus, "long barrels: one tile further",
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
	SuiteKit.open_arsenal(state, [id])
	(state["tech_owned"] as Array).append_array(techs)
	Resources.gain(state, {GameData.WOOD: 900, GameData.STONE: 900,
		GameData.IRON: 900, GameData.OIL: 900, GameData.GUNPOWDER: 900,
		GameData.INCENDIARY: 100, GameData.MONEY: 900})
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

	# **An enemy with no raster art stands in through the lookup** (task
	# 0247): its master, walk, attack and death at the canvas and pivot of
	# the art they stand for, and its head registered - the art groups
	# (0074, 0088) check only the kinds with raster art.
	var standing: Array = []
	var off: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		var master := "res://sprites/enemies/%s.png" % kind
		if RasterArt.FRAMES.has(master):
			continue
		standing.append(kind)
		var paths: Array = [master]
		for pose in ["walk", "attack", "death"]:
			for i in int(PlaceholderArt.art(StringName("%s_%s" % [kind, pose])).get("frames", 0)):
				paths.append("res://sprites/enemies/%s_%s_%d.png" % [kind, pose, i])
		for path in paths:
			var answer := PlaceholderArt.frame(path)
			if PlaceholderArt.is_drawn(path):
				# **Or drawn in code** (task 0248's rat), at its pack's canvas.
				var drawing := WorldView.drawn_enemy(path)
				if answer.is_empty() or drawing == null or Vector2i(drawing.get_size()) != answer["canvas"]:
					off.append(path)
				continue
			var file := PlaceholderArt.texture_path(path)
			var texture: Texture2D = load(file) if file != path and ResourceLoader.exists(file) else null
			if answer.is_empty() or texture == null or Vector2i(texture.get_size()) != answer["canvas"] \
					or answer["pivot"] != PlaceholderArt.frame(file).get("pivot", Vector2i(-1, -1)):
				off.append(path)
		if PlaceholderArt.art(StringName("head_%s" % kind)).is_empty():
			off.append("head_%s" % kind)
	expect(not standing.is_empty() and off.is_empty(),
		"every enemy without raster art stands in through the lookup - master, walk, attack, death and head - at the canvas and pivot of what it stands for, or drawn in code at its pack's",
		"%s: %s" % [str(standing), str(off.slice(0, 4))])
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
		&"farm_bell": "a night bar button: the powers are the bar's upper row on a pad (task 0233), every pad input having an action already",
		&"call_dog": "a night bar button, like farm_bell",
		&"emergency_repair": "a night bar button, like farm_bell",
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
	expect(Ability.ready(state, Ability.FLARE), "the flare is charged at night")
	var house := Farm.house_centre(state) + Vector2i(2, 3)
	intent["ability_cell"] = [house.x, house.y]
	intent["ability"] = true
	Sim.advance(state, 1)
	expect(Ability.aimed_at(state, Ability.FLARE) == [house.x, house.y],
		"a flare lands on the aimed cell", str(Ability.aimed_at(state, Ability.FLARE)))

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
	# **On the frame that is up** (task 0145): A003 measured them on each, and
	# they move with its head - none on the wake's first, still unlit.
	var nodding := GuardianView.eyes(watch, GuardianView.path_of(&"guardian_night", 1))
	var unlit := GuardianView.eyes(watch, GuardianView.path_of(&"guardian_wake", 0))
	var lifted := GuardianView.eyes(watch, GuardianView.path_of(&"guardian_wake", 1))
	expect(nodding.size() == 2 and nodding != eyes and nodding[0] - eyes[0] == Vector2(-1, 0)
		and unlit.is_empty() and lifted.size() == 2 and lifted[0] - eyes[0] == Vector2(0, -1),
		"its eyes follow the frame that is up: a pixel west on the idle's second, none on the wake's first, a pixel up on its second",
		"%s / %s / %s against %s" % [str(nodding), str(unlit), str(lifted), str(eyes)])

	# **The registry** (0120's road): the seven cursor looks, drawn by code in
	# their pack's box. The guardian's four states left it for A003's art in
	# task 0145: twelve frames, the lit ones carrying the emission points and
	# the unlit ones not.
	var wrong: Array = []
	var mine := 0
	for name in [&"guardian_day", &"guardian_wake", &"guardian_night", &"guardian_point"]:
		var count := GuardianView.frames_of(name)
		mine += count
		for i in count:
			var path := GuardianView.path_of(name, i)
			var answer := PlaceholderArt.frame(path)
			var awake: bool = name != &"guardian_day" and not (name == &"guardian_wake" and i == 0)
			if not RasterArt.FRAMES.has(path) or PlaceholderArt.is_drawn(path) or PlaceholderArt.art(name).size() > 0 \
					or answer.get("canvas") != Vector2i(32, 48) or answer.get("pivot") != Vector2i(16, 44) \
					or answer.has("lights") != awake or not ResourceLoader.exists(path):
				wrong.append(path)
	expect(mine == 12 and wrong.is_empty(),
		"the guardian's four states are A003's twelve frames, lit where the eyes are",
		"%d frames, wrong: %s" % [mine, str(wrong.slice(0, 4))])
	# The cursor's seven looks left it for A004's art in task 0146: a 0.4 s
	# pulse of two 16x16 frames each, centred on the cell, and nothing lit.
	mine = 0
	wrong.clear()
	for look in GuardianCursor.LOOKS:
		for i in 2:
			var path := GuardianCursor.path_of(look, i)
			var answer := PlaceholderArt.frame(path)
			mine += 1
			if not RasterArt.FRAMES.has(path) or PlaceholderArt.is_drawn(path) \
					or PlaceholderArt.art(StringName("cursor_%s" % look)).size() > 0 \
					or answer.get("canvas") != Vector2i(16, 16) or answer.get("pivot") != Vector2i(8, 8) \
					or float(answer.get("seconds", 0.0)) != 0.4 or not bool(answer.get("loop", false)) \
					or answer.has("lights") or answer.has("light") or not ResourceLoader.exists(path):
				wrong.append(path)
	expect(mine == 14 and wrong.is_empty(),
		"the cursor's seven looks are A004's fourteen frames, pulsing and unlit",
		"%d frames, wrong: %s" % [mine, str(wrong.slice(0, 4))])
	expect(PlaceholderArt.frame(GuardianView.path_of(&"guardian_day", 0)).get("lights", []).is_empty()
		and not PlaceholderArt.frame(GuardianView.path_of(&"guardian_wake", 0)).has("lights")
		and PlaceholderArt.frame(GuardianView.path_of(&"guardian_wake", 1)).has("lights"),
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
		GameData.FOOD: 9000, GameData.COPPER: 9000, GameData.GOLD: 9000,
		GameData.STRAW: 9000, GameData.SUNFLOWER: 9000, GameData.PUMPKIN: 9000,
		GameData.GARLIC: 9000, GameData.SANDBAG: 9000}
	var phases := {}
	for phase in [Phases.DAY, Phases.PREPARATION, Phases.NIGHT]:
		var state := State.create(1320)
		# Every season's (task 0234): the phase is this group's question.
		SuiteKit.open_arsenal(state, GameData.DEFENCES.keys())
		Resources.gain(state, plenty)
		# A thing from a kit only (task 0225) goes down from its kit.
		for id in GameData.sorted_names(GameData.DEFENCES.keys()):
			if Building.kit_only(id):
				(state["kits"] as Dictionary)[id] = 9
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
		and GameData.sorted_names(Building.catalogue(phases[Phases.NIGHT])) == GameData.sorted_names(GameData.DEFENCES.keys()),
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
	expect(Ability.aimed_at(state, Ability.FLARE) == [aim.x, aim.y], "the flare goes off on the aimed cell",
		str(Ability.aimed_at(state, Ability.FLARE)))
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
		expect(Ability.used(dark, Ability.FLARE) == 0 and Ability.ready(dark, Ability.FLARE)
			and Ability.charge_percent(dark, Ability.FLARE) == 100 and Ability.aimed_at(dark, Ability.FLARE).is_empty(),
			"a flare at %s is refused and keeps its charge" % str(nowhere),
			"used %d, ready %s" % [Ability.used(dark, Ability.FLARE), Ability.ready(dark, Ability.FLARE)])
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

	# **The schedule check**: a night that is still sending at dawn is refused
	# - as a record, and as a key night of the year (task 0270).
	var long: Dictionary = (GameData.KEY_NIGHTS[1] as Dictionary).duplicate(true)
	long["waves"] = [[&"walker", GameData.NIGHT_TICKS / GameData.SPAWN_INTERVAL_TICKS + 5, 0]]
	var long_year := GameData.KEY_NIGHTS.duplicate()
	long_year[1] = long
	expect(not GameData.check_record(long, 1).is_empty()
		and not GameData.check_nights(GameData.SEASON_NIGHTS, long_year).is_empty(),
		"check_nights refuses a schedule longer than the night",
		str(GameData.check_record(long, 1)))
	expect(GameData.check_nights(GameData.SEASON_NIGHTS, GameData.KEY_NIGHTS).is_empty(),
		"and the year's key nights are all inside it",
		str(GameData.check_nights(GameData.SEASON_NIGHTS, GameData.KEY_NIGHTS)))
	# The made nights and the curve past the year against the same rule, from
	# the schedule alone - days 11-40 are `Almanac`'s since task 0270, and
	# the curve begins on day 57.
	var outside: Array = []
	var past := Calendar.year_days()
	for night in range(11, 41) + range(past + 1, past + 31):
		for seed_value in [0, 1, 7]:
			var sent := Waves.schedule_ticks(Waves.night_of(night, seed_value))
			if sent + GameData.DAWN_MARGIN_TICKS > GameData.NIGHT_TICKS:
				outside.append("%d/%d:%d" % [night, seed_value, sent])
	expect(outside.is_empty(), "days 11-40 and the curve's first thirty nights past the year are all sent a margin before dawn",
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
		"thirteen steps since task 0293, which the lever allows, passing their own check",
		str(every))

	# **A scripted first day and night completes day one's steps, in order** -
	# and the bench, which the script queues on day one, early (task 0293
	# puts its line on Spring 3; a lesson found early is done early). The
	# same script runs a second farm whose player read nothing: every line
	# already out of the way before the day starts.
	var day_one: Array = [&"chop", &"plant", &"water", &"craft", &"bed", &"cursor", &"start"]
	var taught := State.create(1410)
	var ignored := State.create(1410)
	((ignored["tutorial"] as Dictionary)["done"] as Array).assign(every.duplicate())
	for farm in [taught, ignored]:
		_first_day_and_night(farm as Dictionary, 0)
	expect(((taught["tutorial"] as Dictionary)["done"] as Array) == day_one,
		"every day-one step up to START completes, in the order the lines come",
		str((taught["tutorial"] as Dictionary)["done"]))
	expect(int(taught["phase"]) == Phases.NIGHT and _same_but_the_lesson(taught, ignored),
		"and the night it reaches is the same night, but for the tutorial",
		Phases.name_of(int(taught["phase"])))
	for farm in [taught, ignored]:
		_first_day_and_night(farm as Dictionary, 1)
	expect(((taught["tutorial"] as Dictionary)["done"] as Array) == day_one + [&"dawn"]
		and not Tutorial.is_finished(taught) and int(taught["day"]) == 2
		and Tutorial.current(taught).get("id", &"") == &"sell"
		and _same_but_the_lesson(taught, ignored),
		"held till dawn, dawn's line goes, the morning is the same morning - and Spring 2's line is the stall's",
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
	expect(Tutorial.current_here(here).get("id", &"") == &"cursor"
		and Farm.buildable(here, aim) and aim != house,
		"in the build step the cursor's line sits on open ground off the house, before the cursor has a cell",
		str(aim))
	(here["intent"] as Dictionary)["build_cell"] = [aim.x + 2, aim.y + 1]
	expect(Tutorial.points_at(here) == aim + Vector2i(2, 1),
		"and on the cursor's own cell once the view writes it (task 0293)",
		str(Tutorial.points_at(here)))
	((here["tutorial"] as Dictionary)["done"] as Array).append(&"cursor")
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

	# **The key night itself, not a copy**: 0152-0154 add their rules on
	# top, and until they do nothing is built per question.
	expect(is_same(Waves.night_of(1), GameData.KEY_NIGHTS[1])
		and is_same(Waves.plain_night(1), GameData.KEY_NIGHTS[1]),
		"night_of(1) is GameData.KEY_NIGHTS[1], the same object")
	var year_end := Calendar.year_days()
	expect(is_same(Waves.plain_night(year_end), GameData.KEY_NIGHTS[year_end])
		and str(Waves.plain_night(year_end + 2, 7)) == str(Endless.night(7, year_end + 2)),
		"the year is its tables to its last day, and the curve takes over past it")

	# **The run's last night, asked in one place**: the year's last day since
	# task 0151.
	expect(Run.final_night() == Calendar.year_days(),
		"Run.final_night() is the year's last night", str(Run.final_night()))
	# A point for each night, and since task 0219 a Full Moon's share of it.
	var least := 0
	for night in range(1, Run.final_night() + 1):
		least += Tech.with_the_moon(int(GameData.REWARDS["tech_points"]), night)
	expect(Tech.least_available() == least,
		"and the least essence a run pays is a point for each of its nights, a Full Moon's share on top",
		"%d against %d" % [Tech.least_available(), least])
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
	expect(is_same(Waves.night_of(5), GameData.KEY_NIGHTS[5])
		and not is_same(Waves.night_of(7), GameData.KEY_NIGHTS[7])
		and not (GameData.KEY_NIGHTS[7] as Dictionary).has("full_moon"),
		"an ordinary night is still the key night as written, and a Full Moon leaves it untouched")

	# **Every Full Moon of the year fits the night** (0137), for both seeds
	# `tools/nights.py --check` reads - every date's record held to the rules
	# of its date (`check_record`, task 0270).
	var faults: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, Calendar.year_days() + 1):
			faults.append_array(GameData.check_record(Waves.night_of(day, seed_value), day))
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
	expect(is_same(Waves.tonight(one), GameData.KEY_NIGHTS[1])
		and not (one["wave"] as Dictionary).has("tonight"),
		"while night 1 is still the key night as written, with nothing kept for it")

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
	var year_faults: Array = []
	for day in range(1, Calendar.year_days() + 1):
		year_faults.append_array(GameData.check_record(Waves.night_of(day, 0), day))
	expect(year_faults.is_empty(),
		"and the year still checks with the boss rows in", str(year_faults))
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
		and int(record["opening_ticks"]) == 0 and GameData.check_record(record, 29).is_empty()
		and not GameData.check_record({"note": "x", "opening_ticks": 0, "waves": []}, 29).is_empty(),
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

	# **The sites are clear** - but for what one was kept for: since task
	# 0189 the shipping bin stands on its own.
	var taken: Array = []
	for id in GameData.sorted_names(GameData.MAP_SITES.keys()):
		var box: Array = GameData.MAP_SITES[id]
		for y in range(int(box[1]), int(box[1]) + int(box[3])):
			for x in range(int(box[0]), int(box[0]) + int(box[2])):
				var on := Farm.occupant(farm, Vector2i(x, y))
				if not on.is_empty() and StringName(on["id"]) != id:
					taken.append([id, Vector2i(x, y)])
	expect(taken.is_empty(), "the coop's, the barn's and the bin's room is clear of anything else", str(taken))

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

	# **Every wave of the year from an open side**, written or made (task
	# 0270), two seeds.
	var stray: Array = []
	for seed_value in [5, 424242]:
		for day in range(1, Calendar.year_days() + 1):
			var open := Calendar.open_sides(day)
			for row in (Waves.plain_night(day, seed_value).get("waves", []) as Array):
				if not open.has(int((row as Array)[2])):
					stray.append([seed_value, day, row])
	expect(stray.is_empty(), "every wave of dates 1-56 comes from a side open that day",
		str(stray.slice(0, 3)))
	var a_side_rule := {"note": "x", "opening_ticks": 0, "waves": [[&"walker", 3, 4]]}
	expect(not GameData.check_record(a_side_rule, 1).is_empty(),
		"and check_record refuses a spring night from the south")

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
	# **What it says is what comes.** A plain key night, summer's Full Moon
	# from two sides and a calm night, each sent through the real road -
	# `Waves.tick` and `Enemies.spawn` - with the gaps skipped and every
	# arrival counted and taken off where it lands, until the last wave is
	# out.
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
			and StringName(said["event"]) == Weather.event(1580, date),
			"date %d: its date, season and day, and the night's weather (task 0256)" % date, str(said))
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

	# **The lookups the packs fill in**: the season's own frame - A012's and
	# A013's, real art since 0163 and 0164 - the base frame where a season
	# has none, and the caps by host.
	expect(SeasonView.frame_for("props/tree", 0) == "props/tree_spring"
		and SeasonView.frame_for("props/tree_b", 3) == "props/tree_b_winter"
		and SeasonView.frame_for("props/tree", 1) == "props/tree"
		and not SeasonView.stand_in("props/tree_b_winter")
		and SeasonView.carries_season("props/tree", 3)
		and SeasonView.texture_file("props/tree_winter") == "res://sprites/props/tree_winter.png",
		"a tree's season is A013's own since task 0164; summer is today's")
	expect(SeasonView.frame_for("terrain/atlas", 3) == "terrain/atlas_winter"
		and SeasonView.carries_season("terrain/atlas", 3)
		and not SeasonView.stand_in("terrain/atlas_winter")
		and SeasonView.frame_for("terrain/atlas", 2) == "terrain/atlas"
		and SeasonView.frame_for("crops/tilled", 3) == "crops/tilled_winter"
		and SeasonView.carries_season("crops/tilled_wet", 3),
		"the winter ground is A012's own since task 0163, and autumn has none")
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
	for outcome in ["won", "escaped", "lost", "lost_after_boss", "giant"]:
		var state := State.create(1600)
		state["day"] = Calendar.year_days() + 3
		state["days_held"] = 3
		NightRoad.to_night(state)
		NightRoad.park(state)
		var down: bool = outcome in ["won", "lost_after_boss"]
		# **The Winter Lord killed on Winter 14** (task 0255), the year's last
		# boss, through `Combat` - and a Giant killed there instead, which no
		# longer ends the year.
		var gate: Vector2i = Enemies.spawn_cells(state, 0)[0]
		if down:
			Combat.hit(state, Entities.spawn(state, &"winter_lord", gate), 1 << 20)
		elif outcome == "giant":
			Combat.hit(state, Entities.spawn(state, &"giant", gate), 1 << 20)
		if outcome == "won":
			expect(Calendar.boss_of(Run.final_night()) == &"winter_lord"
				and Combat.bosses_down_of(state, &"winter_lord") == 1,
				"Winter 14's boss is the Winter Lord, and killing it moves bosses_down_of(winter_lord) to one",
				str(Combat.bosses_down_of(state, &"winter_lord")))
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
		&"cook_meal": 20, &"cook_fish": 16, &"cook_roast": 13, &"make_bait": 48, &"make_hay": 80,
		&"make_butter": 20, &"make_cloth": 12, &"make_sandbag": 24, &"make_flour": 40, &"make_sugar": 24,
		&"cook_stew": 20, &"cook_omelette": 16, &"make_bread": 30, &"cook_supper": 10,
		&"make_gunpowder_coal": 16, &"make_incendiary_pepper": 24, &"press_sunflower_oil": 12,
		&"grind_bone_meal": 60, &"zombie_bait_kit": 40}
	var units := {&"barricade_kit": 40, &"fence_kit": 48, &"mine_kit": 30,
		&"wall_kit": 24, &"press_oil": 12, &"press_fish_oil": 9,
		&"make_incendiary": 96, &"make_gunpowder": 32,
		&"cook_meal": 40, &"cook_fish": 48, &"cook_roast": 52, &"make_bait": 192, &"make_hay": 80,
		&"make_butter": 20, &"make_cloth": 12, &"make_sandbag": 96, &"make_flour": 40, &"make_sugar": 72,
		&"cook_stew": 40, &"cook_omelette": 48, &"make_bread": 30, &"cook_supper": 60,
		&"make_gunpowder_coal": 32, &"make_incendiary_pepper": 144, &"press_sunflower_oil": 12,
		&"grind_bone_meal": 60, &"zombie_bait_kit": 40}
	var ordinary := 0
	for id in GameData.RECIPES:
		if GameData.tool_output(GameData.RECIPES[id]["output"].keys()[0]).is_empty() \
				and Crafting.days_of(id) == 0:
			ordinary += 1
	expect(batches.size() == ordinary,
		"every repeatable recipe timed by the tick has a daily budget; permanent upgrades are once per tier, and a batch in a barrel is counted in mornings (0187)")
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
		# **In its sowing season** since task 0190, which took the stall's
		# stock seasonal from here.
		var sown := State.create(1702)
		sown["day"] = 1 + GameData.SEASON_DAYS * GameData.SEASONS.find((GameData.CROPS[id]["seasons"] as Array)[0])
		Shop.restock(sown)
		expect(packet in Shop.buyable(sown) and Shop.stock_of(sown, packet) > 0, "%s is stocked in its sowing season" % packet)
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
		expect(UiKit.icon(resource) != null and UiKit.icon(resource, true) != null, "both icon sizes resolve, A020's art since 0203")
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
	expect(Pathing._through({"id": &"hardwood_stump"}, 1) == Pathing._through({"id": &"tree"}, 1)
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
		and Farm.terrain_at(state, bare) == Farm.Terrain.SOIL and Pathing._through({"id": &"copper_sprinkler"}, 7) == 7,
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
	expect(heaviest == GameData.CARP and int(loaded["version"]) == State.VERSION
		and Resources.amount(loaded, GameData.CARP) == 7 and int(loaded["gained"][GameData.CARP]) == 9
		and not (loaded["held"] as Dictionary).has(&"fish") and not (loaded["held"] as Dictionary).has("fish"),
		"its seven fish arrive as seven carp, nine gained, and the plain fish is gone",
		str(loaded.get("held", {}).get(GameData.CARP, -1)))
	Save._remove(path)
	Save._remove(path + ".bak")
	var current := Save.read_run_at("res://tools/goldens/run-v8.sav")
	expect(not current.is_empty() and int(current["version"]) == State.VERSION and State.VERSION >= 8,
		"and the version 8 golden reads back at today's version")
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
	# Every kind that lives in the barn (task 0185 added the sheep and the pig).
	for kind in GameData.sorted_names(GameData.LIVESTOCK.keys()):
		if GameData.LIVESTOCK[kind]["home"] == &"barn":
			empty_barn.erase(kind)
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
	# Eggs since task 0184; the count is what matters here.
	var eggs := Resources.amount(state, GameData.EGG)
	Interact.complete(state, door, &"collect")
	expect(Resources.amount(state, GameData.EGG) == eggs + 1 and Livestock.ready_at(state, door) == 0,
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


## Task 0184: fed, or nothing. Mornings come through `Phases.begin_day` and
## produce by stepping `Livestock.tick` an animal's `every_ticks` - never a
## whole day. A fed coop gives eggs the next day, an unfed one gives none and
## every hen is still there; a wheat harvest gives the straw the lever says;
## and the roast's meat still has a source.
func _task_0184_feed() -> void:
	expect(GameData.validate().is_empty()
		and GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP).is_empty()
		and GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE).is_empty(),
		"eggs, milk, straw and hay pass their checks",
		str(GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP)))
	# **The meat decision**: kept, with `cook_roast`, and bought at the stall.
	var meatless: Dictionary = GameData.DAILY_STOCK.duplicate(true)
	meatless.erase(GameData.MEAT)
	var silent: Dictionary = GameData.LIVESTOCK.duplicate(true)
	(silent[&"cow"] as Dictionary).erase("feed_per_day")
	expect(not GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP, meatless).is_empty()
		and not GameData.check_livestock(silent, GameData.FARM_MAP).is_empty(),
		"a farm where no animal gives meat and the stall sells none is refused, and so is a cow that says nothing of what it eats")
	expect((GameData.LIVESTOCK[&"chicken"]["produces"] as Dictionary).has(GameData.EGG)
		and (GameData.LIVESTOCK[&"cow"]["produces"] as Dictionary).has(GameData.MILK)
		and (GameData.RECIPES[&"cook_roast"]["inputs"] as Dictionary).has(GameData.MEAT)
		and int(GameData.DAILY_STOCK.get(GameData.MEAT, 0)) > 0,
		"hens lay eggs and cows give milk; the roast still takes meat, and the stall stocks it")
	var stall := State.create(1840)
	Resources.gain(stall, {GameData.MONEY: 500})
	var meat_held := Resources.amount(stall, GameData.MEAT)
	expect(Shop.buy(stall, GameData.MEAT, 1) and Resources.amount(stall, GameData.MEAT) == meat_held + 1,
		"and meat can be bought there")
	var named := true
	for id in [GameData.STRAW, GameData.HAY, GameData.EGG, GameData.MILK]:
		named = named and Names.KEYS.has(id) and GameData.SELL_PRICE.has(id) and GameData.RESOURCES.has(id)
	expect(named and GameData.RECIPES[&"make_hay"]["station"] == &"workshop" and Names.KEYS.has(&"make_hay")
		and (GameData.RECIPES[&"make_hay"]["output"] as Dictionary).has(GameData.ANIMAL_FEED),
		"straw, hay, eggs and milk are priced and named, and hay is made from straw at the workshop")

	# **A wheat harvest leaves the straw the lever says.**
	var field := State.create(1841)
	var plot: Vector2i = Farming.field_cells(field)[0]
	(field["plots"] as Dictionary)[Grid.index(plot)] = Farming.EMPTY_PLOT.duplicate()
	var here: Dictionary = Farming.plot(field, plot)
	here["crop"] = GameData.WHEAT
	here["growth"] = Farming.days_to_grow(GameData.WHEAT)
	var straw := Resources.amount(field, GameData.STRAW)
	var wheat := Resources.amount(field, GameData.WHEAT)
	expect(Farming.verb_at(field, plot) == &"harvest", "fixture: a ripe wheat plot")
	Farming.act(field, plot)
	var lever := int(GameData.CROPS[GameData.WHEAT]["byproduct"][GameData.STRAW])
	expect(Resources.amount(field, GameData.STRAW) == straw + lever
		and Resources.amount(field, GameData.WHEAT) == wheat + int(GameData.CROPS[GameData.WHEAT]["yield"]),
		"a wheat harvest gives its grain and the straw the lever says", "%d straw" % lever)

	# **Day 1 counts as fed**: a coop built before any morning lays.
	var state := State.create(1842)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var coop := _site_spot(state, &"coop")
	expect(Building.place(state, &"coop", coop) and Livestock.residents(state, coop).size() == 2,
		"fixture: a coop with the map's two hens in it")
	var door := Livestock.door_of(state, coop)
	var every := int(GameData.LIVESTOCK[&"chicken"]["every_ticks"])
	expect(Livestock.is_fed(state, coop, 0) and Livestock.is_fed(state, coop, 1),
		"on day 1, before any morning, both count as fed")
	_tick_livestock(state, every)
	var eggs := Resources.amount(state, GameData.EGG)
	Interact.complete(state, door, &"collect")
	expect(Resources.amount(state, GameData.EGG) == eggs + 2, "and lay an egg each")

	# **A fed coop gives eggs the next day.**
	Resources.add(state, GameData.HAY, 2)
	_next_morning(state)
	expect(Resources.amount(state, GameData.HAY) == 0
		and Livestock.is_fed(state, coop, 0) and Livestock.is_fed(state, coop, 1),
		"the morning feeds each hen a bale")
	_tick_livestock(state, every)
	expect(Livestock.ready_at(state, door) == 2, "and the fed coop lays the next day",
		str(Livestock.ready_at(state, door)))
	Interact.complete(state, door, &"collect")

	# **An unfed one gives none, and every hen is still there.**
	_next_morning(state)
	expect(not Livestock.is_fed(state, coop, 0) and not Livestock.is_fed(state, coop, 1),
		"with no hay, nobody eats")
	_tick_livestock(state, every * 2)
	expect(Livestock.ready_at(state, door) == 0 and Livestock.residents(state, coop).size() == 2
		and Interact.verb_at(state, door) == &"",
		"an unfed coop lays nothing all day, and both hens are still in it")
	# One bale for two hens: the first in the order they moved in eats.
	Resources.add(state, GameData.HAY, 1)
	_next_morning(state)
	expect(Livestock.is_fed(state, coop, 0) and not Livestock.is_fed(state, coop, 1),
		"one bale feeds the first hen and not the second")
	_tick_livestock(state, every)
	expect(Livestock.ready_at(state, door) == 1, "so one egg comes",
		str(Livestock.ready_at(state, door)))

	# **The map's loose animals graze**: no hay, and the cow still gives milk.
	var loose := State.create(1843)
	var cow: Vector2i = Farm.cells_with(loose, &"cow")[0]
	_next_morning(loose)
	_tick_livestock(loose, int(GameData.LIVESTOCK[&"cow"]["every_ticks"]))
	var milk := Resources.amount(loose, GameData.MILK)
	var meat := Resources.amount(loose, GameData.MEAT)
	Interact.complete(loose, cow, &"collect")
	expect(Resources.amount(loose, GameData.HAY) == 0 and Resources.amount(loose, GameData.MILK) == milk + 1
		and Resources.amount(loose, GameData.MEAT) == meat,
		"a loose cow eats nothing and gives milk, not meat")

	# **A saved animal's waiting produce comes out as the new product.**
	var legacy := Save.read_run_at("res://tools/goldens/run-v8.sav")
	var saved_cow: Vector2i = Farm.cells_with(legacy, &"cow")[0]
	Livestock.tick(legacy)
	(legacy["livestock"][Grid.index(saved_cow)] as Dictionary)["ready"] = 2
	var saved_milk := Resources.amount(legacy, GameData.MILK)
	var saved_meat := Resources.amount(legacy, GameData.MEAT)
	Interact.complete(legacy, saved_cow, &"collect")
	expect(Resources.amount(legacy, GameData.MILK) == saved_milk + 2
		and Resources.amount(legacy, GameData.MEAT) == saved_meat,
		"two waiting in an old save come out as two milk")
	_completed += 1


## Task 0185: sheep, pigs and the dog. Mornings come through
## `Phases.begin_day`, never a whole day of ticks. A fed sheep gives wool; a
## fed pig marks spots on open grass by its barn - never a plot, a path or an
## occupied cell - that the farmer digs truffles from, and they go with the
## sun; and a text scan finds no dog in `src/core/`, so the hash cannot
## depend on it.
func _task_0185_animals() -> void:
	expect(GameData.validate().is_empty()
		and GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP).is_empty(),
		"the sheep and the pig pass the livestock check",
		str(GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP)))
	var idle: Dictionary = GameData.LIVESTOCK.duplicate(true)
	(idle[&"pig"] as Dictionary)["digs"] = 0
	expect(not GameData.check_livestock(idle, GameData.FARM_MAP).is_empty(),
		"a pig that gives nothing at the door and digs nothing is refused")
	var kinds_ok := true
	for kind in [&"sheep", &"pig"]:
		kinds_ok = kinds_ok and GameData.LIVESTOCK[kind]["home"] == &"barn" and GameData.LIVESTOCK[kind]["source"] == &"stall"
	expect(kinds_ok and Names.KEYS.has(GameData.WOOL) and Names.KEYS.has(GameData.TRUFFLE)
		and GameData.SELL_PRICE.has(GameData.WOOL) and GameData.SELL_PRICE.has(GameData.TRUFFLE)
		and GameData.group_members(&"animal_goods").has(GameData.WOOL) and GameData.group_members(&"animal_goods").has(GameData.TRUFFLE),
		"sheep and pigs live in the barn and come from the stall; wool and truffles are priced, named and animal goods")

	# **A fed sheep gives wool.**
	var state := State.create(1850)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var barn := _site_spot(state, &"barn")
	expect(Building.place(state, &"barn", barn) and Livestock.house(state, barn, &"sheep")
		and Livestock.house(state, barn, &"pig") and Livestock.residents(state, barn).size() == 3,
		"fixture: a barn with the map's cow, a sheep and a pig")
	Resources.add(state, GameData.HAY, 3)
	_next_morning(state)
	expect(Livestock.is_fed(state, barn, 0) and Livestock.is_fed(state, barn, 1) and Livestock.is_fed(state, barn, 2),
		"the morning feeds all three")
	_tick_livestock(state, int(GameData.LIVESTOCK[&"sheep"]["every_ticks"]))
	var door := Livestock.door_of(state, barn)
	var wool := Resources.amount(state, GameData.WOOL)
	var truffles := Resources.amount(state, GameData.TRUFFLE)
	Interact.complete(state, door, &"collect")
	expect(Resources.amount(state, GameData.WOOL) == wool + 1 and Resources.amount(state, GameData.TRUFFLE) == truffles,
		"a fed sheep gives its fleece at the barn's door, and the pig nothing there")

	# **The fed pig dug this morning**: on open grass by the barn, dug up for
	# a truffle - and the spot's verb wins over the hoe.
	var spots := Livestock.spots(state)
	var digs := int(GameData.LIVESTOCK[&"pig"]["digs"])
	expect(spots.size() == digs, "the fed pig marked its %d spot(s)" % digs, str(spots))
	var spot: Vector2i = spots[0] if not spots.is_empty() else Vector2i(-1, -1)
	expect(Farm.terrain_at(state, spot) == Farm.Terrain.GRASS and Interact.verb_at(state, spot) == &"dig",
		"on open grass, where the hoe would till, the spot offers to dig", str(Interact.verb_at(state, spot)))
	Interact.complete(state, spot, &"dig")
	expect(Resources.amount(state, GameData.TRUFFLE) == truffles + int(GameData.DIG_GIVES[GameData.TRUFFLE])
		and Livestock.spots(state).is_empty() and Interact.verb_at(state, spot) == &"till",
		"dug, it gives a truffle and is gone, and the grass offers the hoe again")

	# **Never on a plot, a path or an occupied cell**, over forty mornings with
	# beds, a path and a fence crowding the barn's grass.
	var crowded := State.create(1851)
	Resources.gain(crowded, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var pen := _site_spot(crowded, &"barn")
	Building.place(crowded, &"barn", pen)
	Livestock.house(crowded, pen, &"pig")
	var reach := GameData.DIG_REACH
	var size := Building.size_of(&"barn")
	var crowding := 0
	for y in range(pen.y, pen.y + size.y + reach):
		for x in range(pen.x - reach, pen.x + size.x + reach):
			var cell := Vector2i(x, y)
			if not Grid.in_bounds(cell) or Farm.terrain_at(crowded, cell) != Farm.Terrain.GRASS or not Farm.is_empty(crowded, cell):
				continue
			crowding += 1
			match crowding % 3:
				0:
					(crowded["plots"] as Dictionary)[Grid.index(cell)] = Farming.EMPTY_PLOT.duplicate()
				1:
					crowded["terrain"][Grid.index(cell)] = Farm.Terrain.PATH
	Farm.touch(crowded)
	var bad: Array = []
	var dug := 0
	for _morning in 40:
		Resources.add(crowded, GameData.HAY, 2)
		_next_morning(crowded)
		for at in Livestock.spots(crowded):
			var cell: Vector2i = at
			if Farming.is_tilled(crowded, cell) or Farm.terrain_at(crowded, cell) != Farm.Terrain.GRASS \
					or not Farm.is_empty(crowded, cell) or not Farm.is_empty(crowded, cell + Vector2i.DOWN) \
					or cell.x < pen.x - reach or cell.x >= pen.x + size.x + reach \
					or cell.y < pen.y or cell.y >= pen.y + size.y + reach:
				bad.append(cell)
			Interact.complete(crowded, cell, &"dig")
			dug += 1
		Phases.begin_preparation(crowded)
	expect(dug >= 40 * digs and bad.is_empty(),
		"forty mornings of spots, every one on open grass within reach beside or in front of the barn - never a bed, a path, a building or behind its roof",
		"%d dug, %s" % [dug, str(bad)])

	# **Unfed, no spot; and the spots go with the sun.**
	_next_morning(crowded)
	expect(not Livestock.is_fed(crowded, pen, 1) and Livestock.spots(crowded).is_empty(),
		"a pig with no hay digs nothing")
	Resources.add(crowded, GameData.HAY, 2)
	_next_morning(crowded)
	var waiting := Livestock.spots(crowded).size()
	Phases.begin_preparation(crowded)
	expect(waiting > 0 and Livestock.spots(crowded).is_empty() and Interact.verb_at(crowded, Vector2i.ZERO) != &"dig",
		"and what is not dug goes when the farmer goes to bed")

	# **The same seed digs the same spots.**
	expect(_pig_spots(1852) == _pig_spots(1852) and not _pig_spots(1852).is_empty(),
		"the same seed and mornings mark the same spots")

	# **No pet in the rules.** Where the dog is is the view's alone; since task
	# 0233 the rules know the power that calls it out - its numbers and its
	# node, its press and its bite - and nothing else, and no key of the
	# state but the power's says dog.
	var found: Array = []
	for file_name in DirAccess.get_files_at("res://src/core/"):
		if String(file_name).ends_with(".gd") \
				and FileAccess.get_file_as_string("res://src/core/" + String(file_name)).to_lower().contains("dog"):
			found.append(file_name)
	found.sort()
	var keyed_dog: Array = []
	var fresh_run := State.create(1853)
	for key in fresh_run.keys():
		if String(key).contains("dog"):
			keyed_dog.append(key)
	for key in (fresh_run["ability"] as Dictionary).keys():
		if String(key).contains("dog") and not String(key).begins_with("dog"):
			keyed_dog.append(key)
	expect(found == ["ability.gd", "game_data.gd", "player.gd"] and keyed_dog.is_empty()
		and not GameData.LIVESTOCK.has(&"dog")
		and FileAccess.get_file_as_string("res://src/ui/animal_view.gd").contains("dog"),
		"a text scan finds the dog in src/core/ only as the power that calls it out - it lives in the view", str(found))
	_completed += 1


## Task 0186: barns at night. A short night with breakers set down beside
## the barn, mornings by `Phases.begin_day`: they reach it and wreck it, then
## leave it for other prey; it stands, gives nothing the next day, keeps
## every animal, and works again after a repair by day.
func _task_0186_barns_night() -> void:
	expect(GameData.validate().is_empty() and Building.wrecks(&"coop") and Building.wrecks(&"barn")
		and not Building.wrecks(&"workshop") and not Building.wrecks(&"wall"),
		"the coop and the barn stand wrecked; nothing else does")
	expect(Pathing.is_prey(&"coop") and Pathing.is_prey(&"barn")
		and not GameData.BUILDINGS[&"barn"].has("path_cost"),
		"breakers hunt coops and barns: buildings with no path cost")

	var state := State.create(1860)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var barn := _site_spot(state, &"barn")
	expect(Building.place(state, &"barn", barn) and Livestock.house(state, barn, &"sheep"),
		"fixture: a barn with the map's cow and a sheep")
	var parts := Building.parts_at(state, barn)
	var herd := _herd(state, barn)
	NightRoad.to_night(state)
	NightRoad.park(state)
	for i in 3:
		Entities.spawn(state, &"breaker", barn + Vector2i(i * 2, 4))
	var lost := Run.structures_lost(state)
	var version := int(state["grid_version"])
	var ticks := 0
	while not Building.is_wrecked(state, barn) and ticks < 8000:
		Sim.tick(state)
		ticks += 1
	var standing := true
	var shared := true
	for part in parts:
		var on := Farm.occupant(state, part)
		standing = standing and StringName(on.get("id", &"")) == &"barn" and Farm.rubble_at(state, part) == &""
		shared = shared and int(on.get("hp", -1)) == 0 and bool(on.get("wrecked", false))
	expect(Building.is_wrecked(state, barn) and standing and shared,
		"breakers set down beside it wreck the barn: every cell at 0, marked, still standing, no rubble",
		"%d ticks" % ticks)
	var prey := Pathing.prey_cells(state)
	var hunted := false
	for part in parts:
		hunted = hunted or prey.has(part)
	expect(not hunted and int(state["grid_version"]) > version and Run.structures_lost(state) == lost + 1,
		"it is no longer prey - the hunt field told - and counts as one structure lost")
	expect(_herd(state, barn) == herd, "every animal is still inside it")
	expect(Interact.verb_at(state, Livestock.door_of(state, barn)) == &"repair",
		"and its door offers only to be mended - repair being the one verb the night keeps (0134)",
		str(Interact.verb_at(state, Livestock.door_of(state, barn))))
	# The view's lantern by the door goes out with it.
	var lamps := Lighting.new()
	lamps._state = state
	expect(not lamps._lights_up(&"barn", Farm.occupant(state, barn), barn),
		"and the lantern by its door is dark")

	# **Then they leave it for other prey.**
	var others := _prey_hp(state)
	var more := 0
	while _prey_hp(state) >= others and more < 6000:
		Sim.tick(state)
		more += 1
	expect(_prey_hp(state) < others and Building.is_wrecked(state, barn)
		and StringName(Farm.occupant(state, barn).get("id", &"")) == &"barn",
		"they go on to other prey, and the wreck stands", "%d more ticks" % more)

	# **The next day it gives nothing and keeps everyone.**
	Resources.add(state, GameData.HAY, 4)
	_next_morning(state)
	var door := Livestock.door_of(state, barn)
	expect(Resources.amount(state, GameData.HAY) == 4 and not Livestock.is_fed(state, barn, 0)
		and not Livestock.is_fed(state, barn, 1),
		"the morning feeds nobody in a wreck, and no hay is spent")
	_tick_livestock(state, int(GameData.LIVESTOCK[&"sheep"]["every_ticks"]))
	expect(Livestock.ready_at(state, door) == 0 and _herd(state, barn) == herd
		and Interact.verb_at(state, door) == &"repair",
		"a wrecked barn gives nothing all day, keeps every animal, and offers only to be mended",
		str(Interact.verb_at(state, door)))

	# **A repair by day brings it back.**
	version = int(state["grid_version"])
	Interact.complete(state, door, &"repair")
	expect(not Building.is_wrecked(state, barn) and int(state["grid_version"]) > version
		and Pathing.prey_cells(state).has(barn)
		and lamps._lights_up(&"barn", Farm.occupant(state, barn), barn),
		"its first hit point back makes it a barn again - something to come for, its lantern lit")
	lamps.free()
	Repair.apply_all(state, door)
	var whole := true
	for part in parts:
		whole = whole and int(Farm.occupant(state, part)["hp"]) == int(GameData.BUILDINGS[&"barn"]["hp"])
	expect(whole, "mended whole, every cell of it")
	_next_morning(state)
	_tick_livestock(state, int(GameData.LIVESTOCK[&"sheep"]["every_ticks"]))
	var wool := Resources.amount(state, GameData.WOOL)
	Interact.complete(state, door, &"collect")
	expect(Livestock.is_fed(state, barn, 1) and Resources.amount(state, GameData.WOOL) == wool + 1,
		"and the next morning its sheep eats and gives its fleece again")
	_completed += 1


## Task 0187: days in a barrel. A recipe may take `days` instead of `ticks`,
## credited each morning from `Phases.begin_day`: grapes in a keg are wine on
## the recipe's last morning and not one before, whatever the days between
## held. The keg and the preserves jar are built by day, and each of their
## four goods is worth its days. At 0 HP a machine stands wrecked with its
## batch inside, aging nothing, until it is mended.
func _task_0187_keg() -> void:
	expect(GameData.validate().is_empty(), "the tables validate with the keg, the jar and their goods",
		str(GameData.validate()))
	var grape := {GameData.GRAPE: 1}
	var wine := {GameData.WINE: 1}
	expect(not GameData.check_recipes({&"x": {"station": &"keg", "inputs": grape, "output": wine, "ticks": 30, "days": 2}}).is_empty()
		and not GameData.check_recipes({&"x": {"station": &"keg", "inputs": grape, "output": wine}}).is_empty()
		and not GameData.check_recipes({&"x": {"station": &"keg", "inputs": grape, "output": wine, "days": 0}}).is_empty()
		and GameData.check_recipes({&"x": {"station": &"keg", "inputs": grape, "output": wine, "days": 2}}).is_empty(),
		"a recipe takes ticks or days: exactly one of them, and more than none")

	# **Four goods, each worth its days.**
	var makes := {&"make_wine": [&"keg", GameData.WINE], &"make_juice": [&"keg", GameData.JUICE],
		&"make_jelly": [&"preserves_jar", GameData.JELLY], &"make_pickles": [&"preserves_jar", GameData.PICKLES]}
	for id in GameData.sorted_names(makes.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		var made: StringName = makes[id][1]
		var margin := GameData._worth(recipe["output"]) - GameData._worth(recipe["inputs"])
		expect(recipe["station"] == makes[id][0] and Crafting.days_of(id) > 0 and not recipe.has("ticks")
			and (recipe["output"] as Dictionary).has(made)
			and GameData.group_members(&"artisan_goods").has(made) and Names.KEYS.has(made) and Names.KEYS.has(id),
			"%s: at the %s, in days, an artisan good with a name" % [id, makes[id][0]])
		expect(margin > 0 and margin >= GameData.AGED_MARGIN_PER_DAY * Crafting.days_of(id),
			"%s adds $%d over %d mornings: a margin worth its days" % [id, margin, Crafting.days_of(id)])
	var cheap := GameData.SELL_PRICE.duplicate()
	cheap[GameData.WINE] = int(cheap[GameData.GRAPE]) + 1
	expect(not GameData.check_chain({&"make_wine": GameData.RECIPES[&"make_wine"]}, cheap).is_empty(),
		"a wine a dollar dearer than its grapes is refused: a week in a keg has to pay")
	expect(GameData.RECIPES[&"make_wine"]["inputs"].has(GameData.GRAPE)
		and GameData.CROPS.has(GameData.MELON) and GameData.RECIPES[&"make_juice"]["inputs"].has(GameData.MELON),
		"the keg makes wine from grapes and juice from another fruit")
	for machine in [&"keg", &"preserves_jar"]:
		expect(Building.wrecks(machine) and Pathing.is_prey(machine) and Names.KEYS.has(machine)
			and Crafting.is_station(machine),
			"the %s is a station with a name, prey to breakers, and wrecks rather than falls" % machine)

	# **Built by day.**
	var state := State.create(1870)
	Resources.gain(state, {GameData.WOOD: 300, GameData.IRON: 30, GameData.STONE: 200, GameData.MONEY: 900})
	expect(Building.catalogue(state).has(&"keg") and Building.catalogue(state).has(&"preserves_jar"),
		"the keg and the jar are in the day's build list")
	var keg := _spot_for(state, &"keg")
	expect(Building.place(state, &"keg", keg), "a keg goes up by day", str(keg))
	var jar := _spot_for(state, &"preserves_jar")
	expect(Building.place(state, &"preserves_jar", jar), "and a preserves jar", str(jar))

	# **Grapes are wine after the recipe's mornings and not one before.**
	var days := Crafting.days_of(&"make_wine")
	Resources.add(state, GameData.GRAPE, 3)
	expect(Crafting.start(state, keg, &"make_wine") and Resources.amount(state, GameData.GRAPE) == 0
		and Crafting.progress_at(state, keg) == [days, days],
		"three grapes go in as the batch starts, %d mornings to go" % days,
		str(Crafting.progress_at(state, keg)))
	Sim.advance(state, GameData.DAY_TICKS / 2)
	expect(Crafting.progress_at(state, keg) == [days, days],
		"half a day of ticks ages it not at all: days are the morning's",
		str(Crafting.progress_at(state, keg)))
	var early := true
	for morning in days - 1:
		# **A day spent elsewhere still counts**: the farmer is nowhere near
		# the keg, and a third of a day passes between two of the mornings.
		if morning == 2:
			Sim.advance(state, GameData.DAY_TICKS / 3)
		_next_morning(state)
		early = early and Resources.amount(state, GameData.WINE) == 0 \
			and int(Crafting.progress_at(state, keg)[0]) == days - morning - 1
	expect(early and Crafting.making(state, keg) == &"make_wine",
		"no wine a morning early: one day off the count each morning, a day spent elsewhere among them",
		str(Crafting.progress_at(state, keg)))
	_next_morning(state)
	expect(Resources.amount(state, GameData.WINE) == 3 and not Crafting.busy(state, keg)
		and int(Crafting.made_at(state, keg).get(&"make_wine", 0)) == 1,
		"and on the %dth morning, three wine and an empty keg" % days,
		str(Resources.amount(state, GameData.WINE)))

	# **Waiting on materials, then started by the tick.**
	expect(Crafting.start(state, keg, &"make_juice") and Crafting.is_stalled(state, keg),
		"juice queued with no melons waits")
	_next_morning(state)
	expect(Crafting.is_stalled(state, keg) and Crafting.progress_at(state, keg) == [0, 0],
		"and a morning does not count a batch that never started")
	Resources.add(state, GameData.MELON, 3)
	Sim.tick(state)
	expect(Crafting.progress_at(state, keg) == [Crafting.days_of(&"make_juice"), Crafting.days_of(&"make_juice")]
		and Resources.amount(state, GameData.MELON) == 0,
		"the melons arrive, and the day's tick starts the batch", str(Crafting.progress_at(state, keg)))
	for _morning in Crafting.days_of(&"make_juice"):
		_next_morning(state)
	expect(Resources.amount(state, GameData.JUICE) == 3, "juice after its mornings")

	# **The jar**, both of its recipes back to back in one queue.
	Resources.gain(state, {GameData.STRAWBERRY: 3, GameData.SUGAR: 1, GameData.PEPPER: 3})
	expect(Crafting.start(state, jar, &"make_jelly") and Crafting.start(state, jar, &"make_pickles"),
		"jelly then pickles queued at the jar")
	for _morning in Crafting.days_of(&"make_jelly"):
		_next_morning(state)
	expect(Resources.amount(state, GameData.JELLY) == 3 and Crafting.making(state, jar) == &"make_pickles"
		and Resources.amount(state, GameData.PEPPER) == 0
		and Crafting.progress_at(state, jar)[0] == Crafting.days_of(&"make_pickles"),
		"jelly on its morning, and the pickles step up, pay and start their own count",
		str(Crafting.progress_at(state, jar)))
	for _morning in Crafting.days_of(&"make_pickles"):
		_next_morning(state)
	expect(Resources.amount(state, GameData.PICKLES) == 3 and not Crafting.busy(state, jar),
		"and pickles on theirs")

	# **Wrecked, never lost**: the batch stays inside and ages nothing.
	Resources.add(state, GameData.GRAPE, 3)
	Crafting.start(state, keg, &"make_wine")
	_next_morning(state)
	_next_morning(state)
	var lost := Run.structures_lost(state)
	Farm.damage(state, keg, 9999)
	var standing := true
	for part in Building.parts_at(state, keg):
		standing = standing and StringName(Farm.occupant(state, part).get("id", &"")) == &"keg" \
			and Farm.rubble_at(state, part) == &""
	expect(Building.is_wrecked(state, keg) and standing and Run.structures_lost(state) == lost + 1
		and Crafting.making(state, keg) == &"make_wine" and Crafting.progress_at(state, keg)[0] == days - 2,
		"a keg at 0 HP stands wrecked, no rubble, its wine inside with %d mornings to go" % (days - 2),
		str(Crafting.progress_at(state, keg)))
	expect(not Pathing.prey_cells(state).has(keg), "and it is nothing a breaker comes for any more")
	_next_morning(state)
	Sim.advance(state, 30)
	Resources.add(state, GameData.GRAPE, 3)
	expect(Crafting.progress_at(state, keg)[0] == days - 2 and not Crafting.can_queue(state, keg, &"make_wine")
		and Interact.verb_at(state, keg) == &"repair",
		"wrecked, a morning and the ticks age it not at all; it takes nothing and offers only to be mended",
		"%s, %s" % [str(Crafting.progress_at(state, keg)), Interact.verb_at(state, keg)])
	Interact.complete(state, keg, &"repair")
	expect(not Building.is_wrecked(state, keg) and Crafting.can_queue(state, keg, &"make_wine")
		and Interact.verb_at(state, keg) in [&"repair", &"craft"],
		"its first hit point back makes it a keg again", str(Interact.verb_at(state, keg)))
	for _morning in days - 2:
		_next_morning(state)
	expect(Resources.amount(state, GameData.WINE) == 6,
		"and the mornings it lost come after: the wine on its count", str(Resources.amount(state, GameData.WINE)))
	_completed += 1


## Task 0188: the dairy, the loom and the mill. Milk into butter by the tick
## and into cheese over two mornings, wool into cloth and cloth with stone
## into sandbags, wheat into flour and beet into sugar - every recipe run at
## its machine and each worth more than its inputs. Jelly now takes the
## mill's sugar, and the stall sells some for a first spring.
func _task_0188_mills() -> void:
	expect(GameData.validate().is_empty(), "the tables validate with the dairy, the loom and the mill",
		str(GameData.validate()))
	var makes := {&"make_butter": [&"dairy", GameData.BUTTER], &"make_cheese": [&"dairy", GameData.CHEESE],
		&"make_cloth": [&"loom", GameData.CLOTH], &"make_sandbag": [&"loom", GameData.SANDBAG],
		&"make_flour": [&"mill", GameData.FLOUR], &"make_sugar": [&"mill", GameData.SUGAR]}
	for id in GameData.sorted_names(makes.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		var made: StringName = makes[id][1]
		expect(recipe["station"] == makes[id][0] and (recipe["output"] as Dictionary).has(made)
			and GameData.SELL_PRICE.has(made) and Names.KEYS.has(made) and Names.KEYS.has(id)
			and GameData.check_chain({id: recipe}, GameData.SELL_PRICE).is_empty()
			and GameData._worth(recipe["output"]) > GameData._worth(recipe["inputs"]),
			"%s: at the %s, named, and check_chain holds ($%d of goods into $%d)" % [id, makes[id][0],
				GameData._worth(recipe["inputs"]), GameData._worth(recipe["output"])])
	expect(Crafting.days_of(&"make_cheese") > 0 and Crafting.days_of(&"make_butter") == 0
		and (GameData.RECIPES[&"make_sandbag"]["inputs"] as Dictionary).has(GameData.CLOTH),
		"cheese ages in mornings, butter is churned by the tick, and a sandbag is made of cloth")
	expect(GameData.group_members(&"materials").has(GameData.SANDBAG)
		and GameData.group_members(&"artisan_goods").has(GameData.CHEESE)
		and GameData.group_members(&"artisan_goods").has(GameData.FLOUR),
		"a sandbag is a material; the rest are artisan goods")
	expect((GameData.RECIPES[&"make_jelly"]["inputs"] as Dictionary).has(GameData.SUGAR)
		and int(GameData.DAILY_STOCK.get(GameData.SUGAR, 0)) > 0
		and GameData.check_stall(GameData.DAILY_STOCK, GameData.SELL_PRICE, GameData.BUY_MARKUP).is_empty(),
		"jelly takes sugar, and the stall sells it for a spring with no beets behind it")
	for machine in [&"dairy", &"loom", &"mill"]:
		expect(Crafting.is_station(machine) and Names.KEYS.has(machine) and Pathing.is_prey(machine)
			and Building.wrecks(machine) and int(GameData.BUILDINGS[machine]["energy_draw"]) == 0,
			"the %s is a named station, prey to breakers, wrecked rather than lost, and draws no power" % machine)

	# **Every recipe runs at its machine.**
	var state := State.create(1880)
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 30, GameData.STONE: 300, GameData.MONEY: 1500})
	var at := {}
	# The jar too, for the sugar below: built before the cheese's mornings,
	# which wake the farmer indoors, where nothing is built.
	for machine in [&"dairy", &"loom", &"mill", &"preserves_jar"]:
		at[machine] = _spot_for(state, machine)
		expect(Building.place(state, machine, at[machine]), "the %s goes up by day" % machine, str(at[machine]))
	for id in GameData.sorted_names(makes.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		var made: StringName = makes[id][1]
		var cell: Vector2i = at[makes[id][0]]
		Resources.gain(state, recipe["inputs"])
		var before := Resources.amount(state, made)
		expect(Crafting.start(state, cell, id) and not Crafting.is_stalled(state, cell), "%s starts" % id)
		if Crafting.days_of(id) > 0:
			for _morning in Crafting.days_of(id):
				_next_morning(state)
		else:
			Sim.advance(state, int(recipe["ticks"]) + 1)
		expect(Resources.amount(state, made) == before + int((recipe["output"] as Dictionary)[made])
			and not Crafting.busy(state, cell),
			"%s runs: %d %s out, the %s free again" % [id, int((recipe["output"] as Dictionary)[made]), made, makes[id][0]],
			str(Resources.amount(state, made)))

	# **Jelly waits for its sugar.**
	var jar: Vector2i = at[&"preserves_jar"]
	Resources.add(state, GameData.STRAWBERRY, 3)
	Resources.spend(state, GameData.SUGAR, Resources.amount(state, GameData.SUGAR))
	var queued := Crafting.start(state, jar, &"make_jelly")
	expect(queued and Crafting.is_stalled(state, jar)
		and Resources.amount(state, GameData.STRAWBERRY) == 3,
		"strawberries without sugar wait in the jar's queue, and are not taken",
		"queued %s, stalled %s, strawberries %d, sugar %d, %s" % [queued, Crafting.is_stalled(state, jar),
			Resources.amount(state, GameData.STRAWBERRY), Resources.amount(state, GameData.SUGAR),
			str(Crafting.queue_at(state, jar))])
	Resources.add(state, GameData.SUGAR, 1)
	Sim.tick(state)
	expect(not Crafting.is_stalled(state, jar) and Resources.amount(state, GameData.STRAWBERRY) == 0
		and Resources.amount(state, GameData.SUGAR) == 0,
		"the sugar arrives and the batch starts, both taken")
	_completed += 1


## Task 0189: the shipping bin by the porch. Ten carrots shipped by day leave
## `held` at once and are paid the next morning at the sell price with the
## tech bonus; the morning report's line names the total, and the line and
## the purse agree. What waits is sold, not stock: a lost night leaves it be.
## The bin is a fixture on its site, and an older save gets one.
func _task_0189_bin() -> void:
	var state := State.create(1890)
	var room: Array = GameData.MAP_SITES[Shipping.BIN]
	var bin := Vector2i(int(room[0]), int(room[1]))
	expect(StringName(Farm.occupant(state, bin).get("id", &"")) == Shipping.BIN
		and Farm.cells_with(state, Shipping.BIN).size() == 1 and Farm.FIXTURES.has(Shipping.BIN)
		and not Pathing.is_prey(Shipping.BIN) and GameData.check_sites(GameData.MAP_SITES, GameData.FARM_MAP).is_empty(),
		"one shipping bin stands on its site by the porch, a fixture nothing hunts")
	expect(Interact.verb_at(state, bin) == &"ship" and Interact.ONE_SHOT.has(&"ship")
		and Interact.DAY_ONLY.has(&"ship") and Interact.all_verbs().has(&"ship") and Sfx.VERB_SOUNDS.has(&"ship"),
		"it offers ship by day, once a press, with a sound")
	expect(Farm.damage(state, bin, 999) == 0 and not Farm.remove(state, bin)
		and StringName(Farm.occupant(state, bin).get("id", &"")) == Shipping.BIN,
		"nothing hurts it and nothing takes it down")

	# **Ten carrots in, out of `held` at once.**
	Interact.complete(state, bin, &"ship")
	expect(Shipping.is_open(state), "ship lifts the lid: the bin's panel is open")
	var clock := int(state["day_tick"])
	Sim.advance(state, 30)
	expect(int(state["day_tick"]) == clock, "and the day stops while it is open, as at the stall")
	Resources.add(state, GameData.CARROT, 10)
	var carrots := Resources.amount(state, GameData.CARROT)
	expect(not Shipping.put(state, GameData.CARROT, carrots + 1) and Resources.amount(state, GameData.CARROT) == carrots,
		"more than he has goes in not at all")
	expect(Shipping.put(state, GameData.CARROT, 10) and Resources.amount(state, GameData.CARROT) == carrots - 10
		and Shipping.count(state, GameData.CARROT) == 10,
		"ten carrots go in and leave held at once")
	expect(not Shipping.takes(GameData.MONEY) and not Shipping.put(state, GameData.MONEY, 1),
		"money does not go in a shipping bin")
	state["intent"]["cancel"] = true
	Sim.advance(state, 1)
	expect(not Shipping.is_open(state), "cancel closes the lid")

	# **Paid at dawn with the tech bonus**, and the report says so first.
	(state["tech_owned"] as Array).append(&"a name at market")
	var paid := Shop.paid_for(state, GameData.CARROT, 10)
	expect(paid == int(GameData.SELL_PRICE[GameData.CARROT]) * 10 * Tech.bonus(state, "sell_percent", 100) / 100
		and paid > int(GameData.SELL_PRICE[GameData.CARROT]) * 10 and Shipping.due(state) == paid,
		"the bin will pay $%d: the sell price and the tech's quarter on top" % paid)
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	Rewards.settle(state, true)
	Phases.enter_result(state, true)
	var screen := ResultScreen.new()
	screen._ready()
	screen.show_state(state)
	screen._build(Rewards.last(state))
	var said := ""
	for label in screen.find_children("*", "Label", true, false):
		if (label as Label).text == I18n.f(&"RES_BIN", [paid]):
			said = (label as Label).text
	screen.free()
	expect(said.contains("$%d" % paid), "the morning report names the total", said)
	var money := Resources.amount(state, GameData.MONEY)
	expect(Phases.begin_day(state) and Resources.amount(state, GameData.MONEY) == money + paid
		and Shipping.waiting(state).is_empty(),
		"and the money lands as the day begins: the line and the purse agree, and the bin is empty")

	# **What waits is sold, not stock.**
	Resources.gain(state, {GameData.CARROT: 8, GameData.WOOD: 40})
	expect(Shipping.put(state, GameData.CARROT, 8), "eight more carrots go in")
	var waiting := Shipping.due(state)
	Phases.go_to_bed(state)
	Phases.start_waves(state)
	expect(Interact.verb_at(state, bin) == &"", "by night the bin offers nothing")
	var wood := Resources.amount(state, GameData.WOOD)
	Rewards.settle(state, false)
	Phases.enter_result(state, false)
	expect(Resources.amount(state, GameData.WOOD) < wood and Shipping.count(state, GameData.CARROT) == 8
		and Shipping.due(state) == waiting,
		"a lost night takes a quarter of the stock and none of the bin")
	money = Resources.amount(state, GameData.MONEY)
	Phases.begin_day(state)
	expect(Resources.amount(state, GameData.MONEY) == money + waiting, "and the morning pays for every carrot in it")

	# **It round-trips, and an older save gets a bin.**
	Shipping.put(state, GameData.WOOD, 5)
	var path := "user://task0189-bin.sav"
	expect(Save.write_run_at(path, state) and Save.read_run_at(path)["shipping"] == state["shipping"],
		"what waits in the bin saves and loads")
	Save._remove(path)
	Save._remove(path + ".bak")
	var old := Save.read_run_at("res://tools/goldens/run-v8.sav")
	expect(not old.is_empty() and int(old["version"]) == State.VERSION
		and StringName(Farm.occupant(old, bin).get("id", &"")) == Shipping.BIN and (old["shipping"] as Dictionary).is_empty(),
		"a version 8 farm gets the bin on its empty site, and an empty bin")
	var raw: Dictionary = Save._read("res://tools/goldens/run-v8.sav")["state"]
	(raw["occupants"] as Dictionary)[Grid.index(bin)] = {"id": &"tree"}
	var stepped := Save.step_up(raw, 8, State.VERSION, Save.migrations())
	expect(StringName(Farm.occupant(stepped, bin).get("id", &"")) == &"tree"
		and Farm.cells_with(stepped, Shipping.BIN).is_empty(),
		"one that put something on the site keeps it, and has no bin")
	_completed += 1


## Task 0190: the peddler and his hours. The stall trades from 08:00 to
## 17:00 (a rigged `day_tick`), its packets are the season's and none in
## winter, and it sells what the farm cannot make: animals, into a coop or a
## barn with room, and the workshop's tool upgrades by the workshop's rule.
func _task_0190_peddler() -> void:
	expect(GameData.validate().is_empty(), "the tables validate with the peddler's",
		str(GameData.validate()))
	expect(GameData.check_stall_hours(GameData.STALL_OPENS, GameData.STALL_CLOSES).is_empty()
		and not GameData.check_stall_hours(GameData.STALL_CLOSES, GameData.STALL_OPENS).is_empty()
		and not GameData.check_stall_hours(5 * 60, GameData.STALL_CLOSES).is_empty()
		and not GameData.check_stall_hours(GameData.STALL_OPENS, GameData.DUSK_MINUTE + 60).is_empty(),
		"the hours are kept in order, after the day starts and before dusk")
	var in_winter := GameData.SEASON_STOCK.duplicate(true)
	in_winter[&"winter"] = {GameData.CARROT_SEED: 5}
	var out_of_season := GameData.SEASON_STOCK.duplicate(true)
	out_of_season[&"summer"] = {GameData.CARROT_SEED: 5}
	expect(not GameData.check_season_stock(in_winter).is_empty()
		and not GameData.check_season_stock(out_of_season).is_empty(),
		"a packet in winter, or out of its sowing season, is refused")
	var cheap := GameData.SELL_PRICE.duplicate()
	cheap[&"cow"] = int(GameData.ANIMAL_PRICE[&"cow"])
	expect(not GameData.check_stall(GameData.stall_stock(&"spring"), cheap, GameData.BUY_MARKUP).is_empty(),
		"an animal that would sell back for what it cost is refused")

	# **His hours, by a rigged clock.**
	var state := State.create(1900)
	var stall: Vector2i = Farm.cells_with(state, &"shop")[0]
	for at in [[GameData.STALL_OPENS - 1, false], [GameData.STALL_OPENS, true],
			[GameData.STALL_CLOSES - 1, true], [GameData.STALL_CLOSES, false]]:
		state["day_tick"] = Phases.tick_at_minute(int(at[0]))
		var open := Interact.verb_at(state, stall) == &"trade" and Interact.why_not(state, stall).is_empty()
		expect(open == bool(at[1]),
			"at %02d:%02d the stall is %s" % [int(at[0]) / 60, int(at[0]) % 60, "open" if at[1] else "shut"],
			str(Interact.why_not(state, stall)))
	state["day_tick"] = Phases.tick_at_minute(GameData.STALL_OPENS - 1)
	Interact.complete(state, stall, &"trade")
	var why := Interact.why_not(state, stall)
	expect(not Shop.is_open(state) and not why.is_empty() and why[0] == &"WHY_STALL_CLOSED"
		and Names.refusal(why).contains("08:00") and Names.refusal(why).contains("17:00"),
		"at 07:59 the verb is refused, and the reason says his hours", Names.refusal(why))
	state["day_tick"] = Phases.tick_at_minute(GameData.STALL_OPENS)
	Interact.complete(state, stall, &"trade")
	expect(Shop.is_open(state), "and at 08:00 it opens the stall")
	Shop.close(state)
	state["day_tick"] = Phases.tick_at_minute(GameData.STALL_CLOSES) - 2
	Interact.complete(state, stall, &"trade")
	Sim.advance(state, 60)
	expect(Shop.is_open(state) and int(state["day_tick"]) == Phases.tick_at_minute(GameData.STALL_CLOSES) - 2,
		"an open panel stops the clock, so the stall never closes under the player")
	Shop.close(state)

	# **The season's packets.**
	for dated in [[1, &"spring"], [GameData.SEASON_DAYS + 1, &"summer"], [GameData.SEASON_DAYS * 3 + 1, &"winter"]]:
		var day := State.create(1901)
		day["day"] = int(dated[0])
		Shop.restock(day)
		var packets: Array = []
		for id in Shop.buyable(day):
			if String(id).ends_with("_seed"):
				packets.append(id)
		var own := true
		for id in packets:
			own = own and (GameData.CROPS[StringName(String(id).trim_suffix("_seed"))]["seasons"] as Array).has(dated[1])
		# Its packet rows: since task 0193 spring and summer carry feed too.
		var on_the_shelf := 0
		for id in GameData.sorted_names((GameData.SEASON_STOCK[dated[1]] as Dictionary).keys()):
			if String(id).ends_with("_seed"):
				on_the_shelf += 1
		expect(own and packets.size() == on_the_shelf
			and (packets.size() > 0) == (dated[1] != &"winter")
			and Shop.buyable(day).has(GameData.WOOD),
			"a %s stall stocks %s packets, beside the materials" % [dated[1], "no" if dated[1] == &"winter" else "only its own"],
			str(packets))

	# **A cow into a barn with room, or not at all.**
	var farm := State.create(1902)
	Resources.gain(farm, {GameData.MONEY: 3000, GameData.WOOD: 300, GameData.STONE: 200})
	var money := Resources.amount(farm, GameData.MONEY)
	why = Shop.why_not_buy(farm, &"cow")
	expect(not Shop.buy(farm, &"cow", 1) and Resources.amount(farm, GameData.MONEY) == money
		and not why.is_empty() and why[0] == &"WHY_NO_HOME",
		"a cow with no barn is refused, and the money kept", str(why))
	var barn := _site_spot(farm, &"barn")
	Building.place(farm, &"barn", barn)
	var herd := Livestock.residents(farm, barn).size()
	money = Resources.amount(farm, GameData.MONEY)
	var shelf := Shop.stock_of(farm, &"cow")
	expect(Shop.buy(farm, &"cow", 1) and Livestock.residents(farm, barn).size() == herd + 1
		and StringName((Livestock.residents(farm, barn).back() as Dictionary)["id"]) == &"cow"
		and bool((Livestock.residents(farm, barn).back() as Dictionary).get("fed", false))
		and Resources.amount(farm, GameData.MONEY) == money - int(GameData.ANIMAL_PRICE[&"cow"])
		and Shop.stock_of(farm, &"cow") == shelf - 1,
		"with a barn the cow arrives in it, fed, at its price, one off the shelf")
	while Livestock.room_for(farm, &"sheep") > 0 and Shop.can_buy(farm, &"sheep"):
		Shop.buy(farm, &"sheep", 1)
	money = Resources.amount(farm, GameData.MONEY)
	expect(Livestock.room_for(farm, &"pig") == 0 and not Shop.buy(farm, &"pig", 1)
		and Resources.amount(farm, GameData.MONEY) == money,
		"a full barn takes no pig, and the money stays", str(Livestock.residents(farm, barn).size()))
	expect(not Shop.can_buy(farm, &"chicken"), "and a hen wants a coop, not a barn")

	# **Tool upgrades, the workshop's order.**
	var tools := State.create(1903)
	Resources.gain(tools, {GameData.MONEY: 1000, GameData.IRON: 100})
	var recipe: Dictionary = GameData.RECIPES[&"upgrade_hoe_iron"]
	money = Resources.amount(tools, GameData.MONEY)
	var iron := Resources.amount(tools, GameData.IRON)
	expect(Shop.buy(tools, &"upgrade_hoe_iron", 1) and ToolTiers.tier(tools, &"hoe") == 0
		and (tools["tools"]["pending"] as Dictionary).has("hoe")
		and Resources.amount(tools, GameData.MONEY) == money - int((recipe["inputs"] as Dictionary)[GameData.MONEY])
		and Resources.amount(tools, GameData.IRON) == iron - int((recipe["inputs"] as Dictionary)[GameData.IRON]),
		"an iron hoe from his pack: the workshop's money and iron, ready tomorrow")
	var bench: Vector2i = Building.anchor_of(tools, Farm.cells_with(tools, &"workshop")[0])
	expect(not Shop.can_buy(tools, &"upgrade_hoe_iron") and not Shop.can_buy(tools, &"upgrade_hoe_gold")
		and not Crafting.can_queue(tools, bench, &"upgrade_hoe_iron"),
		"and one rule for both: not again, no skipping to gold, and the workshop knows it is coming")
	Phases.go_to_bed(tools)
	Phases.start_waves(tools)
	Phases.enter_result(tools, true)
	Phases.begin_day(tools)
	expect(ToolTiers.tier(tools, &"hoe") == 1, "the next morning he hands it over")
	var shelf_state: Dictionary = State.create(1904)["stall"]["stock"]
	expect(shelf_state.has(&"cow") and shelf_state.has(&"upgrade_hoe_iron") and shelf_state.has(GameData.CARROT_SEED)
		and not shelf_state.has(GameData.CORN_SEED),
		"the state's shelf holds the season's packets, the animals and the upgrades")
	_completed += 1


## Task 0191: the house in three tiers. Tier II adds its hit points to the
## whole house, with and without 'stout timbers'; a house repair costs the
## discounted price, after 'a full larder'; the untouched-house bonus reads the
## new whole; and the tier is bought by day only, never past the top, the new
## rooms coming whole.
func _task_0191_house() -> void:
	expect(GameData.validate().is_empty() and GameData.check_house_tiers(GameData.HOUSE_TIERS).is_empty(),
		"the house tiers validate", str(GameData.check_house_tiers(GameData.HOUSE_TIERS)))
	var weaker := GameData.HOUSE_TIERS.duplicate(true)
	weaker[2]["hp_bonus"] = 10
	var paid_first := GameData.HOUSE_TIERS.duplicate(true)
	paid_first[0]["cost"] = {GameData.MONEY: 1}
	var over := GameData.HOUSE_TIERS.duplicate(true)
	over[1]["repair_discount"] = 120
	expect(not GameData.check_house_tiers(weaker).is_empty() and not GameData.check_house_tiers(paid_first).is_empty()
		and not GameData.check_house_tiers(over).is_empty(),
		"a tier weaker than the last, a tier I with a price, and a discount past 100 are refused")

	# **Tier II, with and without 'stout timbers'.**
	var state := State.create(1910)
	var bonus := int((GameData.HOUSE_TIERS[1] as Dictionary)["hp_bonus"])
	expect(House.tier(state) == 1 and Phases.house_full(state) == GameData.HOUSE_HP,
		"a new game's house is tier I, at the table's hit points")
	Resources.gain(state, House.next_cost(state))
	var hp := int(state["house_hp"])
	var money := Resources.amount(state, GameData.MONEY)
	expect(House.buy_tier(state) and House.tier(state) == 2
		and Phases.house_full(state) == GameData.HOUSE_HP + bonus and int(state["house_hp"]) == hp + bonus
		and Resources.amount(state, GameData.MONEY) == money - int(((GameData.HOUSE_TIERS[1] as Dictionary)["cost"] as Dictionary)[GameData.MONEY]),
		"tier II, paid for, adds its %d to the whole house, and the new rooms come whole" % bonus)
	var told := Events.recent(state)
	expect(not told.is_empty() and (told[told.size() - 1] as Dictionary)["kind"] == &"house_tier"
		and int((told[told.size() - 1] as Dictionary)["tier"]) == 2, "and the log is told", str(told))
	# **Every kind the rules record is one `Events` knows.** 0189's `shipped`
	# was not, so the bin's morning line was refused rather than written, and
	# only an error in the output said so. Read from the rules' own source.
	var kinds_used := {}
	var adds := RegEx.create_from_string("Events\\.add\\(\\w+, &\"(\\w+)\"")
	for file in DirAccess.get_files_at("res://src/core/"):
		if file.ends_with(".gd"):
			for found in adds.search_all(FileAccess.get_file_as_string("res://src/core/" + file)):
				kinds_used[StringName((found as RegExMatch).get_string(1))] = file
	var unknown: Array = []
	for kind in GameData.sorted_names(kinds_used.keys()):
		if not Events.KINDS.has(kind):
			unknown.append("%s (%s)" % [kind, kinds_used[kind]])
	expect(kinds_used.has(&"shipped") and kinds_used.has(&"house_tier") and unknown.is_empty(),
		"every kind the rules record is in Events.KINDS, 'shipped' and 'house_tier' among them", str(unknown))
	var timbers := State.create(1911)
	(timbers["tech_owned"] as Array).append(&"stout timbers")
	var with_tech := Phases.house_full(timbers)
	timbers["house_tier"] = 2
	expect(with_tech > GameData.HOUSE_HP and Phases.house_full(timbers) == with_tech + bonus,
		"and on top of stout timbers too", str(Phases.house_full(timbers)))

	# **The repair, discounted after the larder.**
	var mend := State.create(1912)
	var cell := Farm.house_centre(mend)
	var kept := 100 - int((GameData.HOUSE_TIERS[1] as Dictionary)["repair_discount"])
	for larder in [false, true]:
		if larder:
			(mend["tech_owned"] as Array).append(&"a full larder")
		mend["house_tier"] = 1
		var plain := Repair.per_hp_hundredths(mend, cell)
		mend["house_tier"] = 2
		var cheaper := Repair.per_hp_hundredths(mend, cell)
		var right := not plain.is_empty()
		for res in GameData.sorted_names(plain.keys()):
			var raw := int(GameData.REPAIR_COST_PER_HP[res]) * GameData.HOUSE_REPAIR_PERCENT \
				* Tech.bonus(mend, "repair_percent", 100) / 100
			right = right and int(cheaper[res]) == maxi(raw * kept / 100, 1) and int(cheaper[res]) < int(plain[res])
		expect(right, "a tier II house mends at %d%% of tier I's%s" % [kept, ", after a full larder's" if larder else ""],
			"%s against %s" % [str(cheaper), str(plain)])
	mend["house_hp"] = Phases.house_full(mend) - 20
	Resources.gain(mend, {GameData.FOOD: 100, GameData.WOOD: 100})
	var food := Resources.amount(mend, GameData.FOOD)
	Repair.apply(mend, cell, 20)
	var paid := food - Resources.amount(mend, GameData.FOOD)
	expect(int(mend["house_hp"]) == Phases.house_full(mend) and paid > 0
		and paid <= 20 * int(Repair.per_hp_hundredths(mend, cell)[GameData.FOOD]) / 100 + 1,
		"twenty hit points of house cost the discounted food", str(paid))

	# **The untouched-house bonus reads the new whole.**
	var night := State.create(1913)
	night["house_tier"] = 2
	Phases.go_to_bed(night)
	Phases.start_waves(night)
	expect(int(night["house_hp"]) == GameData.HOUSE_HP + bonus, "the night starts the house at tier II's whole")
	var untouched := Rewards._money_from(night, 100)
	night["house_hp"] = GameData.HOUSE_HP
	var short := Rewards._money_from(night, 100)
	expect(int(untouched.get("the house untouched", 0)) > 0 and int(short.get("the house untouched", 0)) == 0,
		"a tier II house is untouched only at its own whole - tier I's is not enough")

	# **By day, and never past the top.**
	var asleep := State.create(1914)
	Resources.gain(asleep, House.next_cost(asleep))
	Phases.go_to_bed(asleep)
	expect(not House.buy_tier(asleep) and House.tier(asleep) == 1
		and House.why_not_tier(asleep)[0] == &"WHY_AFTER_DARK", "not after dark")
	var broke := State.create(1915)
	broke["held"][GameData.MONEY] = 0
	expect(not House.buy_tier(broke) and House.why_not_tier(broke)[0] == &"WHY_SHORT", "not without the money")
	var top := State.create(1916)
	top["house_tier"] = GameData.HOUSE_TIERS.size()
	Resources.gain(top, {GameData.MONEY: 99999, GameData.STONE: 999, GameData.IRON: 999, GameData.WOOD: 999})
	expect(not House.buy_tier(top) and House.why_not_tier(top)[0] == &"WHY_HOUSE_TOP"
		and House.tier(top) == GameData.HOUSE_TIERS.size(), "and not past tier III")

	# **Saved, and filled in for an old save.**
	var path := "user://task0191-house.sav"
	expect(Save.write_run_at(path, state) and int(Save.read_run_at(path)["house_tier"]) == 2,
		"the tier saves and loads")
	Save._remove(path)
	Save._remove(path + ".bak")
	var old := State.create(1917)
	old.erase("house_tier")
	State.reconcile(old)
	expect(int(old["house_tier"]) == 1 and int(old["version"]) == State.VERSION,
		"an old save is filled in at tier I, without a version bump")
	_completed += 1


## Task 0192: the kitchen cooks the new harvest. From spring's stock alone -
## carrot, potato and a fish - it makes food, with no wheat; bread needs the
## mill's flour, and supper the bread; and every kitchen recipe is worth more
## cooked than its parts, the margins printed for the journal.
func _task_0192_kitchen() -> void:
	expect(GameData.validate().is_empty() and GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE).is_empty(),
		"the tables validate, and every recipe passes check_chain", str(GameData.validate()))
	var kitchen := Crafting.recipes_at(&"kitchen")
	for id in [&"cook_meal", &"cook_fish", &"cook_roast", &"cook_stew", &"cook_omelette", &"make_bread", &"cook_supper"]:
		expect(kitchen.has(id) and Names.KEYS.has(id) and I18n.t(Names.KEYS[id]) != String(Names.KEYS[id]),
			"%s is the kitchen's, and has a name" % id)
	# **Every kitchen recipe and its margin**, the list the journal gives.
	var biggest := &""
	for id in kitchen:
		var recipe: Dictionary = GameData.RECIPES[id]
		var into := GameData._worth(recipe["inputs"])
		var made := GameData._worth(recipe["output"])
		print("  %-13s $%2d -> $%2d  +$%-2d  %s" % [id, into, made, made - into, str(recipe["output"])])
		expect(made > into, "%s is worth cooking: $%d of goods into $%d" % [id, into, made])
		var food := int((recipe["output"] as Dictionary).get(GameData.FOOD, 0))
		if biggest == &"" or food > int((GameData.RECIPES[biggest]["output"] as Dictionary).get(GameData.FOOD, 0)):
			biggest = id
	expect(biggest == &"cook_supper" and (GameData.RECIPES[&"cook_supper"]["inputs"] as Dictionary).has(GameData.BREAD),
		"supper, the dish with the bread in it, cooks the kitchen's biggest batch of food", str(biggest))
	expect(Crafting.selected_at(State.create(1920), &"kitchen") == &"cook_fish",
		"and what SPACE at a new kitchen cooks is still the fish, not a loaf wanting flour")
	expect(GameData.SELL_PRICE.has(GameData.BREAD) and Shop.sellable().has(GameData.BREAD)
		and GameData.group_members(&"artisan_goods").has(GameData.BREAD) and Names.KEYS.has(GameData.BREAD)
		and UiKit.icon(GameData.BREAD) != null and UiKit.icon(GameData.BREAD, true) != null
		and not UiKit.missing_icons().has("bread"),
		"bread sells at the stall, is an artisan good, has a name, and its icons, A032's art since 0214")

	# **Spring's stock alone**: a kitchen and nothing but carrots, a potato and
	# a carp - the crops sown in spring and the pond's.
	for crop in [GameData.CARROT, GameData.POTATO]:
		expect((GameData.CROPS[crop]["seasons"] as Array).has(&"spring"), "%s is sown in spring" % crop)
	var state := State.create(1921)
	Resources.gain(state, Building.cost_of(&"kitchen"))
	var cell := _spot_for(state, &"kitchen")
	expect(Building.place(state, &"kitchen", cell), "a kitchen goes up", str(cell))
	Resources.gain(state, {GameData.CARROT: 3, GameData.POTATO: 1, GameData.CARP: 1})
	var startable: Array = []
	for id in kitchen:
		if Crafting.can_start(state, cell, id):
			startable.append(id)
	expect(startable == [&"cook_fish", &"cook_stew"] and Resources.amount(state, GameData.WHEAT) == 0,
		"with no wheat, the fish and the stew are what it can cook", str(startable))
	var food := Resources.amount(state, GameData.FOOD)
	expect(Crafting.start(state, cell, &"cook_stew") and Crafting.start(state, cell, &"cook_fish"),
		"both go on")
	Sim.advance(state, int(GameData.RECIPES[&"cook_stew"]["ticks"]) + int(GameData.RECIPES[&"cook_fish"]["ticks"]) + 2)
	expect(Resources.amount(state, GameData.FOOD) == food + 5 and Resources.amount(state, GameData.POTATO) == 0
		and Resources.amount(state, GameData.CARROT) == 1 and not Crafting.busy(state, cell),
		"two food from the stew and three from the fish, spring's potato and carrots spent",
		str(Resources.amount(state, GameData.FOOD) - food))

	# **Bread needs flour**, and supper the bread.
	var queued := Crafting.start(state, cell, &"make_bread")
	expect(queued and Crafting.is_stalled(state, cell) and Resources.amount(state, GameData.BREAD) == 0,
		"with no flour the loaf waits in the queue")
	Resources.add(state, GameData.FLOUR, 1)
	Sim.advance(state, int(GameData.RECIPES[&"make_bread"]["ticks"]) + 2)
	expect(Resources.amount(state, GameData.BREAD) == 1 and Resources.amount(state, GameData.FLOUR) == 0
		and not Crafting.busy(state, cell), "a sack of flour bakes a loaf")
	Resources.gain(state, {GameData.POTATO: 1, GameData.MILK: 1, GameData.EGG: 2})
	food = Resources.amount(state, GameData.FOOD)
	expect(Crafting.start(state, cell, &"cook_supper") and Crafting.start(state, cell, &"cook_omelette")
		and not Crafting.is_stalled(state, cell), "supper and an omelette go on")
	Sim.advance(state, int(GameData.RECIPES[&"cook_supper"]["ticks"]) + 1)
	expect(Resources.amount(state, GameData.FOOD) == food + 6 and Resources.amount(state, GameData.BREAD) == 0,
		"the loaf, a potato and a milk are six food", str(Resources.amount(state, GameData.FOOD) - food))
	Resources.add(state, GameData.MILK, 1)
	Sim.advance(state, int(GameData.RECIPES[&"cook_omelette"]["ticks"]) + 2)
	expect(Resources.amount(state, GameData.FOOD) == food + 9 and Resources.amount(state, GameData.EGG) == 0
		and not Crafting.busy(state, cell), "and two eggs and a milk are three more")

	# **The quick answers are the old ones.** `headless_check` went past
	# verify's limit with this task, and the time was the autoplayer's field
	# asking the stall about a packet a plot: every purchase built the whole
	# shelf, and every shelf formatted every tool's every tier. The stall now
	# asks without building it, and a tool's output is read off its id.
	var ids: Array = GameData.RESOURCES + GameData.LIVESTOCK.keys() + GameData.RECIPES.keys()
	var same := true
	for season in GameData.SEASONS:
		var shelf := GameData.stall_stock(season)
		for id in ids:
			same = same and GameData.on_the_stall(season, StringName(id)) == shelf.has(id)
	var buyer := State.create(1922)
	for id in GameData.RESOURCES:
		same = same and Shop._sells(buyer, id) == Shop.buyable(buyer).has(id)
	expect(same, "the stall's quick question answers as its whole shelf does, in every season, for everything")
	var decoded := true
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		for tier in (GameData.TOOLS[tool] as Array).size():
			var found := GameData.tool_output(StringName("%s_%s" % [tool, GameData.TOOLS[tool][tier]["name"]]))
			decoded = decoded and (found.is_empty() if tier == 0 else found == {"tool": tool, "tier": tier})
	expect(decoded and GameData.tool_output(&"wood").is_empty() and GameData.tool_output(&"axe").is_empty()
		and GameData.tool_output(&"axe_").is_empty() and GameData.tool_output(&"_iron").is_empty(),
		"every tool's every tier reads back off its id, the first tier and anything else as nothing")
	_completed += 1


## Task 0193: every season can make what it needs. The real tables pass in
## all four seasons, and each fix holds its season up: without the coal
## gunpowder spring cannot make gunpowder, without the stall's feed spring
## and summer have no hay, and a kitchen of only the wheat meal has no spring
## meal until the stew is put back. The routes are printed for the journal.
func _task_0193_supply() -> void:
	var errors := GameData.check_seasonal_supply(GameData.DEFENCES, GameData.RECIPES)
	expect(errors.is_empty() and GameData.validate().is_empty(), "the real tables pass in all four seasons", str(errors))
	var seasons := {}
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var said := GameData.defence_season(GameData.DEFENCES[id]) if GameData.DEFENCES[id].has("season") else &""
		seasons[said] = int(seasons.get(said, 0)) + 1
	expect(seasons == {&"spring": 6, &"summer": 5, &"autumn": 3, &"winter": 2},
		"every defence says the season it opens in: spring's six, summer's flamethrower (0234), decoy (0224), bait (0225), hive (0226) and sandbags (0231), autumn's mortar (0234), catapult (0227) and braid (0228), and winter's searchlight (0229) and electric fence (0230)", str(seasons))
	# **The routes**, season by season: what each kit, round, meal and feed
	# is made of, followed back to the ground.
	for season in GameData.SEASONS:
		var have := GameData.seasonal_supply(season, GameData.RECIPES)
		var needs := GameData.seasonal_needs(season, GameData.DEFENCES, GameData.RECIPES)
		print("  %s:" % season)
		for res in GameData.sorted_names(needs.keys()):
			print("    %s, for %s: %s" % [res, ", ".join(needs[res]), _supply_ways(have, res)])

	# **The coal gunpowder holds spring up.**
	var no_coal := GameData.RECIPES.duplicate(true)
	no_coal.erase(&"make_gunpowder_coal")
	var broken := GameData.check_seasonal_supply(GameData.DEFENCES, no_coal)
	expect(_says(broken, "spring cannot make gunpowder") and not _says(broken, "summer")
		and not _says(broken, "autumn") and not _says(broken, "winter"),
		"without the coal gunpowder spring fails by name, and summer's corn makes it again", str(broken))
	expect(GameData.DAILY_STOCK.has(GameData.CORN) and not GameData.seasonal_supply(&"spring", GameData.RECIPES).has(GameData.CORN),
		"corn bought at the stall in spring is still a summer crop, and not spring's supply")

	# **The stall's feed holds spring and summer up.**
	var no_feed := GameData.SEASON_STOCK.duplicate(true)
	for season in [&"spring", &"summer"]:
		(no_feed[season] as Dictionary).erase(GameData.STRAW)
		(no_feed[season] as Dictionary).erase(GameData.HAY)
	broken = GameData.check_seasonal_supply(GameData.DEFENCES, GameData.RECIPES, no_feed)
	expect(_says(broken, "spring cannot make hay") and _says(broken, "summer cannot make hay")
		and not _says(broken, "autumn") and not _says(broken, "winter"),
		"without straw and hay at the stall the animals go hungry until autumn's wheat", str(broken))
	expect(GameData.check_season_stock(GameData.SEASON_STOCK).is_empty()
		and int((GameData.SEASON_STOCK[&"spring"] as Dictionary).get(GameData.HAY, 0)) > 0
		and not (GameData.SEASON_STOCK[&"autumn"] as Dictionary).has(GameData.HAY),
		"the shelf carries hay in spring and not in autumn, and its check allows feed")

	# **The stew holds spring's meal up** (0192's, checked here).
	var only_meal := GameData.RECIPES.duplicate(true)
	for id in Crafting.recipes_at(&"kitchen"):
		if id != &"cook_meal":
			only_meal.erase(id)
	expect(_says(GameData.check_seasonal_supply(GameData.DEFENCES, only_meal), "spring cannot make food, for mending the house"),
		"a kitchen of only the wheat meal cannot mend the house in spring")
	only_meal[&"cook_stew"] = GameData.RECIPES[&"cook_stew"]
	expect(not _says(GameData.check_seasonal_supply(GameData.DEFENCES, only_meal), "food"),
		"and the stew of potato and carrot does, in every season")

	# **The season field, and the nodes' own seasons.**
	var invented := GameData.DEFENCES.duplicate(true)
	invented[&"pepper_trap"] = {"cost": {GameData.PEPPER: 2, GameData.GOLD: 1}, "season": &"spring"}
	broken = GameData.check_seasonal_supply(invented, GameData.RECIPES)
	expect(_says(broken, "spring cannot make pepper, for the pepper_trap")
		and _says(broken, "spring cannot make gold") and _says(broken, "summer cannot make gold")
		and not _says(broken, "autumn"),
		"a spring defence of summer's pepper and autumn's gold fails until autumn", str(broken))
	(invented[&"pepper_trap"] as Dictionary)["season"] = &"autumn"
	expect(GameData.check_seasonal_supply(invented, GameData.RECIPES).is_empty(),
		"and unlocked in autumn it passes")
	(invented[&"pepper_trap"] as Dictionary)["season"] = &"monsoon"
	expect(_says(GameData.check_seasonal_supply(invented, GameData.RECIPES), "unlocks in 'monsoon', which is no season"),
		"a season that is not one is refused")

	# **The three new recipes.**
	var made := {&"make_gunpowder_coal": [&"workshop", GameData.GUNPOWDER],
		&"make_incendiary_pepper": [&"workshop", GameData.INCENDIARY],
		&"press_sunflower_oil": [&"press", GameData.OIL]}
	for id in GameData.sorted_names(made.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		expect(recipe["station"] == made[id][0] and (recipe["output"] as Dictionary).has(made[id][1])
			and GameData.check_chain({id: recipe}, GameData.SELL_PRICE).is_empty()
			and Names.KEYS.has(id) and I18n.t(Names.KEYS[id]) != String(Names.KEYS[id]),
			"%s: at the %s, named, and worth making ($%d into $%d)" % [id, made[id][0],
				GameData._worth(recipe["inputs"]), GameData._worth(recipe["output"])])
	expect(GameData.check_ammo(GameData.DEFENCES, GameData.RECIPES).is_empty()
		and not (GameData.RECIPES[&"make_gunpowder_coal"]["inputs"] as Dictionary).has(GameData.CORN),
		"the rounds are all makeable, and the coal gunpowder takes no corn")
	var per_oil := func(id: StringName) -> int:
		return int((GameData.RECIPES[id]["output"] as Dictionary)[GameData.INCENDIARY]) \
			/ int((GameData.RECIPES[id]["inputs"] as Dictionary)[GameData.OIL])
	expect(per_oil.call(&"make_incendiary_pepper") > per_oil.call(&"make_incendiary"),
		"pepper makes more incendiary rounds a drop of oil than wood does")
	var fresh := State.create(1930)
	expect(Crafting.selected_at(fresh, &"workshop") == &"barricade_kit" and Crafting.selected_at(fresh, &"press") == &"press_fish_oil",
		"and no station's default recipe changed")
	expect(Shop.buyable(fresh).has(GameData.HAY) and Shop.buyable(fresh).has(GameData.STRAW),
		"a first spring morning's stall sells straw and hay")
	_completed += 1


## Task 0194: the day's economy. A computed - never simulated - day of each
## way of earning lands inside its season's band, every season has several
## ways, and no one way wins them all; the bands and the farm under them are
## checked; and every item has a price.
func _task_0194_economy() -> void:
	expect(GameData.validate().is_empty() and GameData.check_day_targets(GameData.DAY_TARGETS, GameData.DAY_FARM).is_empty(),
		"the bands and the farm they assume pass their check", str(GameData.check_day_targets(GameData.DAY_TARGETS, GameData.DAY_FARM)))
	var winners := {}
	for season in GameData.SEASONS:
		var band: Array = GameData.DAY_TARGETS[season]
		var ways := 0
		var best := &""
		var row: Array = []
		for strategy in Economy.STRATEGIES:
			var money := Economy.day(strategy, season)
			row.append("%s %s" % [strategy, "-" if money < 0 else "$%d" % money])
			if money < 0:
				continue
			ways += 1
			expect(money >= int(band[0]) and money <= int(band[1]),
				"a well-worked %s day of %s makes $%d, inside $%d-%d" % [season, strategy, money, band[0], band[1]])
			if best == &"" or money > Economy.day(best, season):
				best = strategy
		print("  %s ($%d-%d): %s; the most from %s" % [season, band[0], band[1], ", ".join(row), best])
		expect(ways >= 3, "%s has several ways to earn" % season, str(ways))
		winners[best] = true
	expect(winners.size() > 1, "and no one way wins every season", str(winners.keys()))
	# **The seasons without the means**: nothing grows in winter, and a new
	# game has no homes and no machines.
	expect(Economy.crops(&"winter") == -1 and Economy.animals(&"spring") == -1 and Economy.artisan(&"spring") == -1
		and Economy.crops(&"spring") > 0, "crops have no winter, and animals and machines no first spring")

	# **The check refuses a broken table.**
	var falling := GameData.DAY_TARGETS.duplicate(true)
	falling[&"summer"] = [100, 300]
	var upside := GameData.DAY_TARGETS.duplicate(true)
	upside[&"autumn"] = [600, 300]
	var ticking := GameData.DAY_FARM.duplicate(true)
	(ticking["machines"] as Dictionary)[&"summer"] = {&"make_butter": 1}
	var stranger := GameData.DAY_FARM.duplicate(true)
	(stranger["herd"] as Dictionary)[&"summer"] = {&"goat": 2}
	expect(not GameData.check_day_targets(falling, GameData.DAY_FARM).is_empty()
		and not GameData.check_day_targets(upside, GameData.DAY_FARM).is_empty()
		and not GameData.check_day_targets(GameData.DAY_TARGETS, ticking).is_empty()
		and not GameData.check_day_targets(GameData.DAY_TARGETS, stranger).is_empty(),
		"a band that falls, a band upside down, a machine on a recipe of ticks and an animal there is none of are refused")

	# **The model reads the game's own numbers.**
	var fresh := State.create(1940)
	expect(Economy.map_count(&"ore") == Farm.cells_with(fresh, &"ore").size() and Economy.map_count(&"ore") > 0,
		"the cliff's ore is counted off the map the farm is built from", str(Economy.map_count(&"ore")))
	expect(Economy.work_ticks() == Phases.tick_at_minute(GameData.DUSK_MINUTE) and Economy.best_crop(&"spring") == GameData.STRAWBERRY,
		"the day runs to dusk, and spring's money crop is the strawberry")
	expect(Economy.input_cost(&"spring", GameData.HAY) == Shop.buy_price(GameData.HAY) and Economy.input_cost(&"autumn", GameData.HAY) == 0
		and Economy.input_cost(&"summer", GameData.SUGAR) == Shop.buy_price(GameData.SUGAR) and Economy.input_cost(&"autumn", GameData.SUGAR) == 0,
		"hay and sugar are bought until autumn's wheat and beets, the farm's own after")
	expect(GameData.seasonal_supply(&"spring", GameData.RECIPES, {}, {}).has(GameData.MILK),
		"the map's loose cow grazes, and gives milk without hay")

	# **A price for every item.**
	var unpriced: Array = []
	for id in GameData.RESOURCES:
		if id in [GameData.MONEY, GameData.ENERGY, GameData.TECH]:
			continue
		if int(GameData.SELL_PRICE.get(id, 0)) <= 0:
			unpriced.append(id)
	for kind in GameData.sorted_names(GameData.LIVESTOCK.keys()):
		if int(GameData.ANIMAL_PRICE.get(kind, 0)) <= 0:
			unpriced.append(kind)
	for id in GameData.tool_upgrades():
		if (GameData.RECIPES[id]["inputs"] as Dictionary).is_empty():
			unpriced.append(id)
	for id in GameData.sorted_names(GameData.BUILDINGS.keys()):
		if (GameData.BUILDINGS[id].get("cost", {}) as Dictionary).is_empty():
			unpriced.append(id)
	expect(unpriced.is_empty(), "every item, animal, upgrade and building has a price", str(unpriced))
	var stalls := true
	for season in GameData.SEASONS:
		stalls = stalls and GameData.check_stall(GameData.stall_stock(season), GameData.SELL_PRICE, GameData.BUY_MARKUP).is_empty()
	expect(stalls and GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE).is_empty(),
		"and the stall and the recipes still pass at the new prices")
	_completed += 1


## Task 0195: the new day's tips. Each fires on its moment and once - a
## profile that has seen it never sees it again - none on the first day; the
## table passes its check and every line has words; and reading them moves
## nothing in the state.
func _task_0195_tips() -> void:
	expect(GameData.check_tips(GameData.TIPS).is_empty(), "the tip table passes its check",
		str(GameData.check_tips(GameData.TIPS)))
	var twice := GameData.TIPS.duplicate(true)
	twice.append(twice[0])
	var keyless := GameData.TIPS.duplicate(true)
	(keyless[0] as Dictionary)["line"] = &"a line, not a key"
	expect(not GameData.check_tips(twice).is_empty() and not GameData.check_tips(keyless).is_empty(),
		"a tip twice, and a line that is no TIP_ key, are refused")
	var ids: Array = []
	for entry in GameData.TIPS:
		var key := StringName((entry as Dictionary)["line"])
		expect(I18n.t(key) != String(key), "%s has words" % key)
		ids.append(StringName((entry as Dictionary)["id"]))
	expect(ids == [&"till", &"season", &"bin", &"bite", &"animal"],
		"five tips: tilling grass, the seasons, the bin, the bite and the animals", str(ids))
	expect((Save.default_profile().get("tips_seen", null) as Array).is_empty(), "a new profile has seen none")

	# **Each on its moment, once.** The others are marked seen, so each is
	# asked on its own.
	for id in ids:
		var state := _tip_moment(id)
		var others: Array = []
		for other in ids:
			if other != id:
				others.append(String(other))
		var profile := {"tips_seen": others}
		var before := State.hash_of(state)
		expect(Tips.triggered(id, state) and Tips.due(state, profile) == id, "the %s tip is due at its moment" % id)
		expect(Tips.due(state, Tips.remember(profile, id)) == &"", "and never again once the profile has it")
		expect(State.hash_of(state) == before, "reading the %s tip moves nothing in the state" % id)
	var first := _tip_moment(&"bin")
	first["day"] = 1
	expect(Tips.triggered(&"bin", first) and Tips.due(first, {}) == &"",
		"none on the first day, which is the tutorial's, even at its moment")
	var twice_remembered := Tips.remember(Tips.remember({}, &"bite"), &"bite")
	expect((twice_remembered["tips_seen"] as Array) == ["bite"] and Tips.seen(twice_remembered, &"bite"),
		"remembered once, however many times it is written")
	_completed += 1


## 0218 - room for more fields and more bodies, with nothing changed for the
## player: a tower looking near itself picks what a look at the whole farm
## picks, the entity table is lowest id first without being sorted, and a
## field built when asked for is built only then.
func _task_0218_perf_ground() -> void:
	# **The crowd's squares against the whole farm.** A seeded crowd over the
	# farm and a little past its far edges, thick in places, its hit points
	# few enough that ties are everywhere, and every seventh one already
	# accounted for by a shot in the air.
	var state := State.create(21800)
	var rng: Array = state["rng"]
	var crowd: Array = []
	for i in 240:
		var cell := Vector2i(Rng.int_between(rng, 0, Grid.WIDTH - 1), Rng.int_between(rng, 0, Grid.HEIGHT - 1))
		if i % 4 == 0:
			cell = Vector2i(40 + Rng.int_between(rng, -5, 5), 30 + Rng.int_between(rng, -5, 5))
		crowd.append(Entities.spawn(state, &"walker", cell))
	for cell in [Vector2i(Grid.WIDTH, 12), Vector2i(30, Grid.HEIGHT), Vector2i(Grid.WIDTH + 2, Grid.HEIGHT + 2)]:
		crowd.append(Entities.spawn(state, &"walker", cell))
	for i in crowd.size():
		Entities.set_hp(state, int(crowd[i]), 1 + Rng.int_between(rng, 0, 5))
		if i % 7 == 3:
			(state["projectiles"] as Array).append({"target": int(crowd[i]), "damage": 1000})
	var towers: Array = []
	for y in range(2, Grid.HEIGHT, 6):
		for x in range(2, Grid.WIDTH, 6):
			towers.append(Vector2i(x, y))
	for corner in [Vector2i.ZERO, Vector2i(Grid.WIDTH - 1, 0), Vector2i(0, Grid.HEIGHT - 1),
			Vector2i(Grid.WIDTH - 1, Grid.HEIGHT - 1), Vector2i(Grid.WIDTH - 1, 12)]:
		towers.append(corner)
	var asked := 0
	var found := 0
	var differ: Array = []
	for how in GameData.TARGETING:
		for reach in [[3, 0], [5, 0], [12, 4]]:
			var entry := {"range": reach[0], "min_range": reach[1], "targeting": how}
			for from in towers:
				var whole := Towers.acquire_for(state, from, entry)
				var near := Towers.acquire_nearby_for(state, from, entry)
				asked += 1
				if whole != near:
					differ.append([how, reach, from, whole, near])
				if whole == 0:
					continue
				found += 1
				# And its second barrel, with the first one taken.
				if Towers.acquire_for(state, from, entry, [whole]) \
						!= Towers.acquire_nearby_for(state, from, entry, [whole]):
					differ.append([how, reach, from, "second barrel"])
	expect(differ.is_empty(), "a tower looking near itself picks what a look at the whole farm picks, every way of aiming",
		"%d of %d differ, first %s" % [differ.size(), asked, str(differ.slice(0, 3))])
	expect(found > asked / 3, "and most of those looks found somebody to shoot", "%d of %d" % [found, asked])

	# **A tie goes to the lower id however the squares are walked.** The
	# lower id stands in a square the look reaches last, the higher one in the
	# square it reaches first, both the same distance from the tower.
	var tied := State.create(21800)
	var tower := Vector2i(40, 32)
	var lower := Entities.spawn(tied, &"walker", tower + Vector2i(3, 3))
	var higher := Entities.spawn(tied, &"walker", tower + Vector2i(-3, -3))
	var nearest := {"range": 5, "targeting": GameData.TARGET_NEAREST}
	expect(Towers.acquire_nearby_for(tied, tower, nearest) == lower and Towers.acquire_for(tied, tower, nearest) == lower,
		"a tie goes to the lower id, though the higher one is in the square looked in first",
		"%d and %d against %d" % [Towers.acquire_nearby_for(tied, tower, nearest), Towers.acquire_for(tied, tower, nearest), lower])
	expect(higher > lower, "and the two came in that order")

	# **The squares are a local of the tick.** A night of guns and a crowd
	# leaves the state with the keys it had.
	var night := State.create(21803)
	Resources.gain(night, {GameData.WOOD: 500, GameData.STONE: 500, GameData.IRON: 500, GameData.MONEY: 500})
	expect(NightRoad.to_build(night), "a build step to put a gun up in")
	var gun := Vector2i(-1, -1)
	for dy in range(-6, 7):
		for dx in range(3, 10):
			var spot := Farm.house_centre(night) + Vector2i(dx, dy)
			if gun.x < 0 and Building.place(night, &"gun_tower", spot):
				gun = spot
	NightRoad.through_build(night)
	for i in 30:
		Entities.spawn(night, &"walker", gun + Vector2i(2 + i % 5, -2 + i / 5))
	var keys_before := GameData.sorted_names(night.keys())
	var shots := Towers.shots_fired(night)
	for _i in 45:
		Towers.tick(night)
	expect(gun.x >= 0 and Towers.shots_fired(night) > shots, "a gun on the farm, firing into a crowd",
		"%s, %d shots" % [gun, Towers.shots_fired(night) - shots])
	expect(GameData.sorted_names(night.keys()) == keys_before, "and its looking keeps nothing in the state")

	# **The table is lowest id first, without a sort.** Spawned, killed
	# through the rules, spawned again, withdrawn, and through a save.
	var table := State.create(21801)
	expect(NightRoad.to_night(table), "a night to put them in")
	var spawned: Array = Entities.ids(table)
	for i in 40:
		spawned.append(Entities.spawn(table, &"walker", Vector2i(10 + i % 20, 10 + i / 20)))
	expect(Entities.in_order(table) and Entities.ids(table) == spawned, "spawned, the table is lowest id first")
	var killed := 0
	for i in range(0, spawned.size(), 3):
		Combat.hit(table, int(spawned[i]), 100000)
		killed += 1
	var sorted_ids := Entities.ids(table).duplicate()
	sorted_ids.sort()
	expect(Entities.count(table) == spawned.size() - killed and Entities.in_order(table)
		and Entities.ids(table) == sorted_ids, "the kills leave it in order",
		"%d left of %d" % [Entities.count(table), spawned.size()])
	var newest := 0
	for i in 10:
		newest = Entities.spawn(table, &"walker", Vector2i(12 + i, 14))
	expect(Entities.in_order(table) and int(Entities.ids(table).back()) == newest, "and so do the spawns after them")
	var back := _through_a_save(table, "entities_0218")
	expect(not back.is_empty() and Entities.in_order(back) and Entities.ids(back) == Entities.ids(table),
		"a save round trip keeps the order", "%d against %d" % [Entities.count(back), Entities.count(table)])
	var shuffled := table.duplicate(true)
	var reversed := {}
	var backwards: Array = Entities.ids(shuffled)
	backwards.reverse()
	for id in backwards:
		reversed[id] = (shuffled["entities"] as Dictionary)[id]
	shuffled["entities"] = reversed
	var was_out := not Entities.in_order(shuffled)
	var mended := State.reconcile(shuffled)
	expect(was_out and mended.has("put the entities back in id order") and Entities.in_order(shuffled)
		and Entities.ids(shuffled) == Entities.ids(table),
		"a save that came in out of order is put back in order where it is read", str(mended))
	Enemies.withdraw(table)
	var after_dawn := Entities.spawn(table, &"walker", Vector2i(20, 20))
	expect(Entities.count(table) == 1 and Entities.in_order(table) and after_dawn > newest,
		"withdrawn, and the next one still comes after every id there was")

	# **A field built when asked for is built only then.** Written here,
	# shaped like 0224's lure - the first row of `FIELDS` built when asked -
	# and driven down the road `field()` takes, under keys of its own.
	var farm := State.create(21802)
	var lure := {"seeds": &"house", "cost": &"open", "field": "lure_0218",
		"costs": "lure_0218_cost", "version": "lure_0218_version"}
	Pathing.refresh(farm)
	expect(not farm.has("lure_0218") and not farm.has("lure_0218_cost") and not farm.has("lure_0218_version"),
		"a field built when asked for is not built by the rebuild everything else gets")
	var made := Pathing.field_from(farm, lure)
	expect(int(farm.get("lure_0218_version", -1)) == int(farm["grid_version"]) and made.size() == Grid.CELLS,
		"asked for, it is built for the farm as it stands")
	expect(made == farm["flow_open"] and farm["lure_0218_cost"] == farm["open_cost"],
		"and it is the sweep its row describes: from the house, at the open costs")
	farm["lure_0218"] = PackedInt32Array([7])
	expect(Pathing.field_from(farm, lure) == PackedInt32Array([7]),
		"asked again with nothing changed, it is the one already built")
	var door := Farm.house_centre(farm) + Vector2i(0, 4)
	(farm["occupants"] as Dictionary)[Grid.index(door)] = {"id": &"wall", "hp": 10}
	farm["grid_version"] = int(farm["grid_version"]) + 1
	Pathing.refresh(farm)
	expect(farm["lure_0218"] == PackedInt32Array([7]) and int(farm["lure_0218_version"]) != int(farm["grid_version"]),
		"a wall goes up: the rebuild leaves it alone")
	made = Pathing.field_from(farm, lure)
	expect(int(farm["lure_0218_version"]) == int(farm["grid_version"]) and made == farm["flow_open"],
		"and the next ask builds it for the new farm")
	expect(Pathing.field(farm, &"house") == farm["flow"] and Pathing.field(farm, &"around") == farm["flow_open"]
		and Pathing.field(farm, &"hunt") == farm["flow_hunt"],
		"the three every night walks by are the registry's, kept where they always were")
	var probe := Farm.house_centre(farm) + Vector2i(9, 5)
	expect(Pathing.step_by(farm, &"house", probe) == Pathing.step_from(farm, probe)
		and Pathing.step_by(farm, &"around", probe) == Pathing.step_around(farm, probe),
		"and a step by name is the step it always was")
	var fresh := State.create(21802)
	var lazy_keys: Array = []
	for key in fresh:
		if String(key).begins_with("lure_0218"):
			lazy_keys.append(key)
	expect(lazy_keys.is_empty(), "and a new game has no key for it", str(lazy_keys))

	# **The swarm is held to the tick's budget**, and the baseline is inside
	# it: a few hundred bodies more than the worst night.
	var tool_text := FileAccess.get_file_as_string("res://tools/perf.py")
	expect(tool_text.contains("(\"swarm_tick\", TICK_BUDGET_US)"), "tools/perf.py holds swarm_tick to the tick budget")
	var at := tool_text.find("TICK_BUDGET_US = ")
	var budget := tool_text.substr(at + "TICK_BUDGET_US = ".length(), 8).to_int() if at >= 0 else 0
	var swarm_tick := -1
	for line in FileAccess.get_file_as_string("res://tools/perf_baseline.txt").split("\n"):
		var bits := line.strip_edges().split(" ")
		if bits.size() == 2 and bits[0] == "swarm_tick":
			swarm_tick = int(bits[1])
	expect(budget > 0 and swarm_tick > 0 and swarm_tick <= budget, "and the recorded swarm tick is inside it",
		"%dus of %d" % [swarm_tick, budget])
	_completed += 1


## 0219 - essence: what a night pays the tree, under its new name, beside a
## smaller purse. A night won pays `tech_points` and each bonus it earned, a
## Full Moon its share over again, a replayed night none - and the bounty is
## for kills only: whoever walks off at dawn pays nothing.
func _task_0219_essence() -> void:
	var rewards: Dictionary = GameData.REWARDS
	# **The levers, and their check.**
	expect(GameData.check_rewards(rewards).is_empty(), "the night's purse passes its check",
		str(GameData.check_rewards(rewards)))
	var dim := rewards.duplicate(true)
	dim["full_moon_essence_percent"] = 99
	var greedy := rewards.duplicate(true)
	greedy["bounty_percent"] = 101
	expect(not GameData.check_rewards(dim).is_empty() and not GameData.check_rewards(greedy).is_empty(),
		"a Full Moon paying less essence than an ordinary night is refused, and so is a bounty past the kills' worth")
	I18n.use("en")
	expect(Names.of(GameData.TECH) == "essence" and GameData.TECH == &"tech",
		"the currency is called essence, and its id is still tech", Names.of(GameData.TECH))

	# **A won night pays `tech_points` and each bonus it earned**, kept line
	# by line in the payout.
	var each := int(rewards["tech_points"])
	var bonus_points := 0
	var house_bonus := 0
	for row in GameData.TECH_BONUSES:
		bonus_points += int((row as Dictionary)["points"])
		if StringName((row as Dictionary)["id"]) == &"house untouched":
			house_bonus = int((row as Dictionary)["points"])
	var clean := _essence_night(21900, 3)
	var paid := Rewards.settle(clean, true)
	var lines: Dictionary = paid.get("essence_from", {})
	var summed := 0
	for line in GameData.sorted_names(lines.keys()):
		summed += int(lines[line])
	expect(int(paid["tech"]) == each + bonus_points and summed == int(paid["tech"])
		and Tech.held(clean) == each + bonus_points,
		"a night held clean pays the night's essence and every bonus, kept line by line in the payout",
		"%d paid, %s" % [int(paid["tech"]), str(lines)])
	expect(int((paid["gained"] as Dictionary).get(GameData.TECH, 0)) == int(paid["tech"]),
		"and the night's gains say so", str(paid["gained"]))
	var bitten := _essence_night(21901, 3)
	bitten["house_hp"] = Phases.house_full(bitten) - 10
	var less := Rewards.settle(bitten, true)
	expect(int(less["tech"]) == each + bonus_points - house_bonus
		and not (less["essence_from"] as Dictionary).has(&"house untouched"),
		"a house that took a bite earns every bonus but the house's", str(less["essence_from"]))

	# **A Full Moon pays its share over again**, on its own line.
	var moon := _essence_night(21902, 7)
	var moonlit := Rewards.settle(moon, true)
	var ordinary := each + bonus_points
	var share := ordinary * (int(rewards["full_moon_essence_percent"]) - 100) / 100
	expect(Calendar.is_full_moon(7) and share > 0
		and int((moonlit["essence_from"] as Dictionary).get("full moon", 0)) == share
		and int(moonlit["tech"]) == ordinary + share,
		"a Full Moon pays %d%% of the night's essence, its share on its own line"
			% int(rewards["full_moon_essence_percent"]), str(moonlit["essence_from"]))
	var said := ResultScreen.essence_parts(moonlit["essence_from"])
	expect(said.size() == GameData.TECH_BONUSES.size() + 2
		and said[0] == I18n.f(&"RES_ESSENCE_PART", [I18n.t(&"RES_ESSENCE_FOR_SURVIVING"), each])
		and said.back() == I18n.f(&"RES_ESSENCE_PART", [I18n.t(&"RES_ESSENCE_FULL_MOON"), share]),
		"and the morning report itemises it: the night first, then the bonuses, then the Full Moon", str(said))
	var year := 0
	for night in range(1, Run.final_night() + 1):
		year += Tech.with_the_moon(ordinary, night)
	expect(Tech.total_available() == year and year > ordinary * Run.final_night(),
		"a year's best counts every Full Moon's share", "%d against %d" % [Tech.total_available(), year])

	# **A replayed night pays no essence.**
	var again := Rewards.settle(clean, true)
	expect(int(again["tech"]) == 0 and (again["essence_from"] as Dictionary).is_empty()
		and Tech.held(clean) == each + bonus_points,
		"a night already paid pays no essence again", str(again["essence_from"]))

	# **The bounty is for kills only.** Held to dawn with two killed and
	# three still on the farm: the purse pays the two kills' worth at the
	# bounty's percent, and walking off at dawn kills nobody.
	var dawn := State.create(21903)
	expect(NightRoad.to_night(dawn), "a night to hold")
	NightRoad.park(dawn)
	var far: Vector2i = Enemies.spawn_cells(dawn, 0)[0]
	var walkers: Array = []
	for _i in 5:
		walkers.append(Entities.spawn(dawn, &"walker", far))
	for i in 2:
		Combat.hit(dawn, int(walkers[i]), 100000)
	var killed_before := int(Stats.of_run(dawn)["killed"])
	(dawn["wave"] as Dictionary)["dawn_at"] = int(dawn["night_tick"]) + 2
	dawn["house_hp"] = Phases.house_full(dawn)
	for _t in 30:
		if int(dawn["phase"]) != Phases.NIGHT:
			break
		Sim.advance(dawn, 1)
	var settled := Rewards.last(dawn)
	var worth := 2 * int((GameData.ENEMIES[&"walker"] as Dictionary)["reward"])
	expect(bool(settled.get("survived", false)) and int(settled.get("walked", 0)) == 3,
		"held to dawn with three still on the farm", str(settled))
	expect(int((settled.get("money_from", {}) as Dictionary).get("bounty", -1))
		== worth * int(rewards["bounty_percent"]) / 100
		and int((dawn["killed_by_kind"] as Dictionary).get(&"walker", 0)) == 2,
		"the bounty is the two kills' worth at the bounty's percent, and the three are not counted as killed",
		str(settled.get("money_from", {})))
	Phases.begin_day(dawn)
	expect(Entities.count(dawn) == 0 and int((dawn["killed_by_kind"] as Dictionary).get(&"walker", 0)) == 2
		and int(Stats.of_run(dawn)["killed"]) == killed_before,
		"and walking off at dawn kills nobody", "%d left, %d killed" % [Entities.count(dawn),
			int(Stats.of_run(dawn)["killed"])])

	# **A kill's worth, as the cursor says it**: what it puts in the purse.
	var off: Array = []
	for id in GameData.sorted_names(GameData.ENEMIES.keys()):
		var cents := int((GameData.ENEMIES[id] as Dictionary)["reward"]) * int(rewards["bounty_percent"])
		if roundi(float(Describe.bounty_of(id)) * 100.0) != cents:
			off.append("%s %s" % [id, Describe.bounty_of(id)])
	expect(off.is_empty(), "the cursor says what each kill puts in the purse", str(off))
	_completed += 1


## A night won and about to be settled, on a farm where nothing was touched:
## the house whole, nobody through and nothing in the rubble.
func _essence_night(seed_value: int, night: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = night
	state["night"] = night
	state["house_hp"] = Phases.house_full(state)
	state["breaches"] = 0
	return state


## 0220 - the tree by season: a floor a season, opened when the run reaches
## it and kept open into Year 2, and a later floor's number the stronger.
func _task_0220_tree_seasons() -> void:
	# **The table and its check.**
	expect(GameData.check_tech_tree(GameData.TECH_TREE).is_empty(), "the tree's floors pass their check",
		str(GameData.check_tech_tree(GameData.TECH_TREE)))
	var broken := {}
	var tree: Array = GameData.TECH_TREE.duplicate(true)
	var at_heavy := -1
	var at_sights := -1
	for i in tree.size():
		if StringName((tree[i] as Dictionary)["id"]) == &"heavy shot":
			at_heavy = i
		if StringName((tree[i] as Dictionary)["id"]) == &"true sights":
			at_sights = i
	var fifth: Array = tree.duplicate(true)
	(fifth[at_heavy] as Dictionary)["season"] = 4
	broken["a fifth season"] = fifth
	var backwards: Array = tree.duplicate(true)
	(backwards[at_sights] as Dictionary)["needs"] = [&"heavy shot"]
	broken["spring needing summer"] = backwards
	var bare: Array = tree.duplicate(true)
	(bare[at_heavy] as Dictionary)["season"] = 2
	broken["a branch with no summer"] = bare
	var weaker: Array = tree.duplicate(true)
	(weaker[at_heavy] as Dictionary)["gives"] = {"tower_damage_percent": 110}
	broken["a later floor no stronger"] = weaker
	var opposite: Array = tree.duplicate(true)
	(opposite[at_heavy] as Dictionary)["gives"] = {"tower_damage_percent": 90}
	broken["the same number moved the other way"] = opposite
	var refused: Array = []
	for why in GameData.sorted_names(broken.keys()):
		if GameData.check_tech_tree(broken[why]).is_empty():
			refused.append(why)
	expect(refused.is_empty(), "and refuses a fifth season, a need on a later floor, a branch missing a floor, "
		+ "and a later floor that is weaker or pushes the other way", "let through: %s" % str(refused))

	# **The run's seasons**, as `Calendar.season_reached` reads them.
	var dates := {1: [true, false, false, false], 15: [true, true, false, false],
		43: [true, true, true, true], 57: [true, true, true, true]}
	var wrong: Array = []
	for day in [1, 15, 43, 57]:
		var on_day := State.create(22000)
		on_day["day"] = day
		for season in GameData.SEASONS.size():
			if Calendar.season_reached(on_day, season) != bool((dates[day] as Array)[season]):
				wrong.append("day %d season %d" % [day, season])
	expect(wrong.is_empty(), "a season is reached on its first day and stays reached, every one from Year 2",
		str(wrong))

	# **A summer node in spring: refused for its season, before its price.**
	var spring := _tree_day(22001, 9, 0)
	_own_up_to(spring, &"a standing order")
	var why_not := Tech.why_not_buy(spring, &"heavy shot")
	expect(why_not == [&"WHY_NOT_YET_SEASON", &"summer"] and not Tech.buy(spring, &"heavy shot"),
		"a summer node is refused in spring, for its season", str(why_not))
	var broke := _tree_day(22002, 9, 0)
	expect(Tech.why_not_buy(broke, &"heavy shot") == [&"WHY_NOT_YET_SEASON", &"summer"],
		"and the season is the reason before its prerequisites and its price",
		str(Tech.why_not_buy(broke, &"heavy shot")))
	I18n.use("en")
	expect(Names.refusal(why_not) == I18n.f(&"WHY_NOT_YET_SEASON", [Names.of(&"summer")]),
		"which reads as the season", Names.refusal(why_not))

	# **Summer reached: it goes in. Year 2's spring: it still does.**
	var summer := _tree_day(22003, 15, 200)
	_own_up_to(summer, &"a standing order")
	var had := Tech.held(summer)
	expect(Tech.buy(summer, &"heavy shot") and Tech.held(summer) == had - int(Tech.node(&"heavy shot")["cost"]),
		"bought once summer is reached, for its price", str(Tech.why_not_buy(summer, &"heavy shot")))
	var year_two := _tree_day(22004, 57, 400)
	_own_up_to(year_two, &"tall mounts")
	expect(Calendar.season_of(Calendar.date(year_two)) == 0
		and Tech.why_not_buy(year_two, &"greased works").is_empty() and Tech.buy(year_two, &"greased works"),
		"and a winter node is still bought in Year 2's spring", str(Tech.why_not_buy(year_two, &"greased works")))

	# **The stronger wins, whatever the order** - and never the sum.
	var tower: Dictionary = GameData.DEFENCES[&"gun_tower"]
	var plain := _tree_day(22005, 15, 0)
	var first_then_later := _tree_day(22006, 15, 200)
	_own_up_to(first_then_later, &"heavy shot")
	var later_first := _tree_day(22007, 15, 0)
	(later_first["tech_owned"] as Array).assign([&"heavy shot", &"true sights"])
	var both := Tech.bonus(first_then_later, "tower_damage_percent", 100)
	expect(both == 140 and Tech.bonus(later_first, "tower_damage_percent", 100) == 140,
		"owning 'true sights' and 'heavy shot' is 140%, whichever came first", str(both))
	expect(Towers.damage_of(first_then_later, tower) == int(tower["damage"]) * 140 / 100
		and Towers.damage_of(first_then_later, tower) > Towers.damage_of(plain, tower),
		"and a tower hits for it - not for the 168% two fifths on a fifth would be",
		"%d against %d" % [Towers.damage_of(first_then_later, tower), Towers.damage_of(plain, tower)])
	Tech.refund(first_then_later, &"heavy shot")
	expect(Tech.bonus(first_then_later, "tower_damage_percent", 100) == 120,
		"selling the later back falls to the earlier", str(Tech.bonus(first_then_later, "tower_damage_percent", 100)))
	var faster := _tree_day(22008, 50, 0)
	(faster["tech_owned"] as Array).assign([&"oiled works", &"greased works"])
	var bigger := _tree_day(22009, 50, 0)
	(bigger["tech_owned"] as Array).assign([&"spare stakes", &"a stake pile"])
	expect(Tech.bonus(faster, "tower_reload_percent", 100) == 65
		and Tech.bonus(bigger, "barricade_bonus", 0) == 6,
		"below a hundred the smaller wins, and of two bonuses the bigger",
		"%d, %d" % [Tech.bonus(faster, "tower_reload_percent", 100), Tech.bonus(bigger, "barricade_bonus", 0)])
	expect(Tech.bonus(plain, "tower_damage_percent", 100) == 100,
		"and nobody owning anything is what the system had")
	_completed += 1


## 0221 - what the night leaves behind: a body's bones where it fell, moon
## stones on the horde's road the morning after a Full Moon, both picked up
## underfoot by day, and gone after their mornings.
func _task_0221_night_loot() -> void:
	# **The levers and their check.**
	var levers := GameData.check_loot(GameData.LOOT_PILE_CAP, GameData.MOON_STONES,
		GameData.MOON_STONE_ESSENCE, GameData.LOOT_FADE_DAYS, GameData.LOOT_REACH,
		GameData.ENEMIES, GameData.BONES_EVERY)
	expect(levers.is_empty(), "the leftovers' levers pass their check", str(levers))
	var broken := {
		"a pile of none": GameData.check_loot(0, 4, 1, 3, 4, {}, 10),
		"a Full Moon of no stones": GameData.check_loot(9, 0, 1, 3, 4, {}, 10),
		"a stone for no essence": GameData.check_loot(9, 4, 0, 3, 4, {}, 10),
		"a pile that lies no morning": GameData.check_loot(9, 4, 1, 0, 4, {}, 10),
		"a pile that looks nowhere": GameData.check_loot(9, 4, 1, 3, 0, {}, 10),
		"bones from one body in none": GameData.check_loot(9, 4, 1, 3, 4, {}, 0),
		"a body bigger than a pile": GameData.check_loot(9, 4, 1, 3, 4, {&"giant": {"bones": 10}}, 10),
	}
	var whys: Array = broken.keys()
	whys.sort()
	var let_through: Array = []
	for why in whys:
		if (broken[why] as Array).is_empty():
			let_through.append(why)
	expect(let_through.is_empty(),
		"and refuse a cap, a stone count, a rate, a fade, a reach or a share of zero, and a body bigger than a pile",
		"let through: %s" % str(let_through))
	expect(GameData.group_members(&"night_leftovers").has(GameData.BONES)
		and GameData.group_members(&"night_leftovers").has(GameData.MOON_STONE)
		and GameData.SELL_PRICE.has(GameData.BONES) and GameData.SELL_PRICE.has(GameData.MOON_STONE)
		and Names.KEYS.get(GameData.BONES, &"") == &"ITEM_BONES"
		and Names.KEYS.get(GameData.MOON_STONE, &"") == &"ITEM_MOON_STONE"
		and Shop.sellable().has(GameData.MOON_STONE),
		"bones and moon stones are priced, named resources - the night's leftovers - and the stall buys a stone")
	expect(State.RUN_DATA.has("loot") and State.RUN_DATA.has("loot_laid")
		and not State.create(221000).has("moon_phase"),
		"what lies on the farm is run data, and no key is called moon_phase")

	# **A killed walker leaves its bones on its cell**, and is no occupant.
	var state := State.create(221001)
	var open := _open_patch(state)
	NightRoad.to_night(state)
	NightRoad.park(state)
	var first := Entities.spawn(state, &"walker", open)
	Combat.hit(state, first, 9999)
	var walker_bones := int((GameData.ENEMIES[&"walker"] as Dictionary)["bones"])
	expect(walker_bones > 0 and Loot.at(state, open) == {GameData.BONES: walker_bones},
		"a killed walker leaves its bones on its cell", "%s on %s" % [str(Loot.at(state, open)), str(open)])
	expect(Farm.is_empty(state, open) and Farm.walkable(state, open) and Farm.buildable(state, open),
		"and a pile is no occupant: walked on and built on as before")

	# **One body of a kind in BONES_EVERY**, on the night's own tally - and
	# every boss.
	var second_at := open + Vector2i(1, 0)
	var second := Entities.spawn(state, &"walker", second_at)
	Combat.hit(state, second, 9999)
	expect(GameData.BONES_EVERY == 1 or Loot.at(state, second_at).is_empty(),
		"tonight's second walker leaves none", str(Loot.at(state, second_at)))
	expect(Loot.leaves_bones(&"walker", 1) and Loot.leaves_bones(&"walker", GameData.BONES_EVERY + 1)
		and (GameData.BONES_EVERY == 1 or not Loot.leaves_bones(&"walker", 2))
		and Loot.leaves_bones(&"giant", 2) and not Loot.leaves_bones(&"no_such_kind", 1),
		"the first of a kind, then one in BONES_EVERY, leaves its bones, and a boss always does")

	# **The pile survives the morning**; one that walked off at dawn left none.
	var survivor_at := open + Vector2i(2, 0)
	Entities.spawn(state, &"walker", survivor_at)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	expect(Loot.at(state, open) == {GameData.BONES: walker_bones},
		"the pile survives begin_day's sweep", str(Loot.at(state, open)))
	expect(Loot.at(state, survivor_at).is_empty() and Entities.count(state) == 0,
		"and the walker that walked off at dawn left nothing")

	# **Stepping on it by day picks it up**: into the ledger, off the cell.
	House.leave(state)
	SuiteKit.stand_the_farmer(state, open - Vector2i(1, 0))
	var held := Resources.amount(state, GameData.BONES)
	var move: Array = (state["intent"] as Dictionary)["move"]
	move[0] = 1
	move[1] = 0
	for _t in 60:
		if Player.cell(state) == open:
			break
		Sim.tick(state)
	move[0] = 0
	expect(Player.cell(state) == open and Resources.amount(state, GameData.BONES) == held + walker_bones
		and Loot.at(state, open).is_empty() and not (state["loot_laid"] as Dictionary).has(Grid.index(open)),
		"stepping onto the pile by day puts its bones in the ledger and clears the cell",
		"%s, %d held" % [str(Player.cell(state)), Resources.amount(state, GameData.BONES)])

	# **And not after dark.**
	Loot.drop(state, open, GameData.BONES, 2)
	NightRoad.to_night(state)
	NightRoad.park(state)
	expect(Loot.collect_at(state, open).is_empty() and int(Loot.at(state, open).get(GameData.BONES, 0)) == 2,
		"at night the boots pick up nothing", str(Loot.at(state, open)))

	# **A pile holds LOOT_PILE_CAP of a thing**; what falls on a full one is lost.
	var heap := open + Vector2i(0, 1)
	var landed := Loot.drop(state, heap, GameData.BONES, GameData.LOOT_PILE_CAP + 5)
	expect(landed == GameData.LOOT_PILE_CAP and int(Loot.at(state, heap).get(GameData.BONES, 0)) == GameData.LOOT_PILE_CAP
		and Loot.drop(state, heap, GameData.BONES, 1) == 0 and Loot.drop(state, Vector2i(-5, -5), GameData.BONES, 1) == 0,
		"a cell holds LOOT_PILE_CAP bones, and nothing lands off the farm", "%d landed" % landed)

	# **Where he cannot stand, the nearest cell he can**: the nearest first,
	# then reading order - above before left.
	var steps := Loot.nearest_steps()
	expect(steps.size() == (2 * GameData.LOOT_REACH + 1) * (2 * GameData.LOOT_REACH + 1) - 1
		and steps.slice(0, 4) == [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)],
		"the steps go nearest first, then top row first and left first", str(steps.slice(0, 6)))
	var walled := State.create(221002)
	var spot := _open_patch(walled)
	Farm.place(walled, spot, {"id": &"wall", "hp": 30})
	expect(Loot.landing(walled, spot) == spot + Vector2i(0, -1),
		"bones that fall on a wall land on the cell above it", str(Loot.landing(walled, spot)))
	Farm.place(walled, spot + Vector2i(0, -1), {"id": &"wall", "hp": 30})
	NightRoad.to_night(walled)
	NightRoad.park(walled)
	var on_wall := Entities.spawn(walled, &"walker", spot)
	Combat.hit(walled, on_wall, 9999)
	expect(Loot.at(walled, spot).is_empty() and Loot.at(walled, spot + Vector2i(0, -1)).is_empty()
		and Loot.at(walled, spot + Vector2i(-1, 0)) == {GameData.BONES: walker_bones},
		"and with that one walled too, a walker killed on the wall leaves them on the cell to its left",
		str(Loot.cells(walled)))

	# **A pile lies LOOT_FADE_DAYS mornings, then it is gone** - taken as a
	# night ends, so the morning report counts what the morning has.
	var fading := State.create(221003)
	var lying_at := _open_patch(fading)
	Loot.drop(fading, lying_at, GameData.BONES, 1)
	var mornings := 0
	for _night in GameData.LOOT_FADE_DAYS + 1:
		NightRoad.to_night(fading)
		NightRoad.park(fading)
		Phases.enter_result(fading, true)
		Phases.begin_day(fading)
		if not Loot.at(fading, lying_at).is_empty():
			mornings += 1
	expect(mornings == GameData.LOOT_FADE_DAYS and Loot.at(fading, lying_at).is_empty(),
		"an untouched pile lies LOOT_FADE_DAYS mornings and is gone on the next",
		"%d mornings" % mornings)

	# **A Full Moon morning: its stones on the horde's road**, the same cells
	# for the same seed, off a stream of the night's own.
	var moon_a := _moon_morning(221004, 7)
	var dice_kept := _moon_dice_kept
	var moon_b := _moon_morning(221004, 7)
	var stones := Loot.cells_with(moon_a, GameData.MOON_STONE)
	var road := Loot.road(moon_a)
	var off_road: Array = []
	for cell in stones:
		if not road.has(cell) or not Farm.walkable(moon_a, cell):
			off_road.append(cell)
	expect(stones.size() == GameData.MOON_STONES and stones == Loot.cells_with(moon_b, GameData.MOON_STONE),
		"a Full Moon morning lays MOON_STONES stones, on the same cells for the same seed",
		"%s against %s" % [str(stones), str(Loot.cells_with(moon_b, GameData.MOON_STONE))])
	expect(off_road.is_empty() and dice_kept,
		"each on the horde's road, where he can stand, and the run's own dice untouched", str(off_road))
	expect(Loot.cells_with(_moon_morning(221005, 6), GameData.MOON_STONE).is_empty(),
		"and an ordinary night lays none")
	expect(LootView.stone_lights(moon_a).size() == GameData.MOON_STONES,
		"every stone has its light for the night")

	# **A moon stone trades for MOON_STONE_ESSENCE essence by day**, and not
	# after dark.
	var trader := State.create(221006)
	Resources.add(trader, GameData.MOON_STONE, 2)
	var essence := Tech.held(trader)
	expect(Tech.trade_moon_stones(trader, 1) == GameData.MOON_STONE_ESSENCE
		and Tech.held(trader) == essence + GameData.MOON_STONE_ESSENCE
		and Resources.amount(trader, GameData.MOON_STONE) == 1,
		"a traded stone pays the essence lever", "%d essence" % Tech.held(trader))
	expect(Tech.trade_moon_stones(trader, 2) == 0 and Resources.amount(trader, GameData.MOON_STONE) == 1,
		"more stones than are held trade none")
	NightRoad.to_night(trader)
	expect(Tech.trade_moon_stones(trader, 1) == 0 and Resources.amount(trader, GameData.MOON_STONE) == 1
		and Tech.why_not_trade(trader) == [&"WHY_AFTER_DARK"], "and none after dark")
	expect(Tech.why_not_trade(State.create(221007)) == [&"WHY_NO_MOON_STONE"],
		"with no stone held, it says so")

	# **The morning report says what is lying about**, in both languages.
	var language := I18n.locale()
	var report := State.create(221008)
	I18n.use("en")
	var bare := ResultScreen.leftovers_parts(report)
	var at := _open_patch(report)
	Loot.drop(report, at, GameData.BONES, 3)
	Loot.drop(report, at + Vector2i(1, 0), GameData.MOON_STONE, 1)
	var said := ResultScreen.leftovers_parts(report)
	I18n.use("pt_BR")
	var dito := ResultScreen.leftovers_parts(report)
	I18n.use(language)
	expect(bare.is_empty() and said == ["3 bones", "1 moon stone"] and dito == ["3 ossos", "1 pedra da lua"],
		"the report lists 3 bones and 1 moon stone, and nothing on a bare farm",
		"%s / %s / %s" % [str(bare), str(said), str(dito)])
	_completed += 1


## 0223 - the defences sleep under tarps by day: one list in the view, of
## real defences and never a barrier or a mine; A044's footprints drawn at
## their canvases; the change's stages - and not a word of it in the rules.
func _task_0223_tarps() -> void:
	var ids: Array = GameData.sorted_names(Transition.TARPS.keys())
	var strangers: Array = []
	for id in ids:
		if not GameData.DEFENCES.has(id):
			strangers.append(id)
	expect(not ids.is_empty() and strangers.is_empty(),
		"every id in the view's tarp list is a defence", str(strangers))
	var bare := true
	for id in [&"wall", &"fence", &"barricade", &"mine"]:
		bare = bare and not Transition.TARPS.has(id)
	expect(bare and Transition.WAKES.has(&"generator") and not Transition.TARPS.has(&"generator"),
		"barriers and mines sleep bare, and the generator still wakes without a tarp")
	var mentions: Array = []
	for file_name in DirAccess.get_files_at("res://src/core/"):
		if String(file_name).ends_with(".gd") \
				and FileAccess.get_file_as_string("res://src/core/" + file_name).to_lower().contains("tarp"):
			mentions.append(file_name)
	expect(mentions.is_empty(), "nothing in src/core/ mentions a tarp", str(mentions))

	# **A044's three footprints**, its art since task 0243: a cover standing
	# on the pivot's row, a torn one that differs, unveil frames lifting off
	# the ground and then higher, nothing of 0120's road left.
	var footprints := [&"tarp_tower", &"tarp_tall", &"tarp_short"]
	var wrong: Array = []
	for footprint in footprints:
		var foot := TarpArt.pivot(footprint)
		var whole := _art_image(TarpArt.path_of(footprint, TarpArt.COVERED))
		var torn := _art_image(TarpArt.path_of(footprint, TarpArt.COVERED, true))
		var yank := _art_image(TarpArt.path_of(footprint, TarpArt.YANK))
		var away := _art_image(TarpArt.path_of(footprint, TarpArt.AWAY))
		var worn := true
		for stage in [TarpArt.COVERED, TarpArt.YANK, TarpArt.AWAY]:
			var path := TarpArt.path_of(footprint, stage)
			var texture := TarpArt.texture(footprint, stage)
			worn = (worn and RasterArt.FRAMES.has(path) and not PlaceholderArt.is_drawn(path)
				and texture != null and texture.resource_path == path)
		if not (worn and PlaceholderArt.art(footprint).is_empty()
				and Vector2i(whole.get_size()) == TarpArt.canvas(footprint)
				and _lowest_row(whole) == foot.y - 1 and _lowest_row(torn) == foot.y - 1
				and torn.get_data() != whole.get_data()
				and _lowest_row(yank) < foot.y - 5 and _lowest_row(away) < _lowest_row(yank)
				and TarpArt.texture(footprint, TarpArt.OFF) == null):
			wrong.append(footprint)
	var covers := true
	for id in ids:
		covers = covers and footprints.has(Transition.TARPS[id])
	expect(wrong.is_empty() and covers,
		"each footprint's cover is A044's art standing on its pivot's row, the torn one differs, the unveil lifts and flies; every listed defence wears one",
		str(wrong))

	# **The change**: covered in daylight, off in the dark, and at the wake
	# the two frames - forwards into the night, backwards into the day.
	var seconds := GameData.TRANSITION_SECONDS
	var share := Transition.UNVEIL_SECONDS / seconds
	expect(Transition.tarp_stage(false, false, 1.0, seconds) == TarpArt.COVERED
		and Transition.tarp_stage(true, false, 1.0, seconds) == TarpArt.OFF,
		"covered in daylight, off in the dark")
	var dusk: Array = []
	var dawn: Array = []
	for at in [0.3, 0.5 + share * 0.5, 0.5 + share * 1.5, 0.9]:
		dusk.append(Transition.tarp_stage(true, true, at, seconds))
		dawn.append(Transition.tarp_stage(false, true, at, seconds))
	expect(dusk == [TarpArt.COVERED, TarpArt.YANK, TarpArt.AWAY, TarpArt.OFF]
		and dawn == [TarpArt.OFF, TarpArt.AWAY, TarpArt.YANK, TarpArt.COVERED],
		"into the night the cover comes off at the wake, yanked and then away; at dawn the same frames backwards",
		str([dusk, dawn]))
	_completed += 1


## 0224 - the decoy. A straw figure on summer's row, with no `path_cost` and
## nothing to shoot; a lure field in `Pathing`'s registry, swept from every
## decoy standing and built only while one stands. A walker within
## `lure_tiles` of it by the field walks to it and bites it while one beyond
## walks on to the house; a runner is lured, the Giant is not; the lured take
## their own road again on the tick it falls; of two, the nearer by the field
## wins and a tie goes the first way in `Grid.STEPS`.
func _task_0224_decoy() -> void:
	# **The row, the flags, and their checks.**
	var row: Dictionary = GameData.DEFENCES[&"decoy"]
	var cost := Building.materials_of(&"decoy")
	var reach := int(row.get("lure_tiles", 0))
	expect(cost.size() == 2 and cost.has(GameData.STRAW) and cost.has(GameData.WOOD) and Building.money_of(&"decoy") > 0
		and int(row["hp"]) >= 100 and int(row["hp"]) <= 250 and reach >= 3 and reach <= 8
		and not row.has("reload_ticks") and not row.has("path_cost") and not row.has("damage")
		and GameData.defence_season(row) == &"summer",
		"a decoy costs straw, wood and money, stands 100-250, pulls from 3-8 tiles, shoots and blocks nothing, and is summer's",
		str(row))
	var lurable: Array = []
	for id in GameData.sorted_names(GameData.ENEMIES.keys()):
		if bool((GameData.ENEMIES[id] as Dictionary).get("lurable", false)):
			lurable.append(id)
	# And 0251's frost zombie, a walker gone cold: one pulled away from the
	# guns before it dies is an answer to its burst.
	expect(lurable == [&"frost_zombie", &"runner", &"tank", &"walker"] and (GameData.ENEMIES[&"breaker"] as Dictionary).has("lurable"),
		"the walker, the runner, the tank and the frost zombie are lured; the breaker says it is not, and no boss is", str(lurable))
	expect(Pathing.is_prey(&"decoy") and not Traps.is_trap(&"decoy"),
		"a breaker hunts it as prey: nothing to walk through")
	var no_reach := GameData.DEFENCES.duplicate(true)
	(no_reach[&"decoy"] as Dictionary)["lure_tiles"] = 0
	var no_hp := GameData.DEFENCES.duplicate(true)
	(no_hp[&"decoy"] as Dictionary)["hp"] = 0
	var boss := GameData.ENEMIES.duplicate(true)
	(boss[&"giant"] as Dictionary)["lurable"] = true
	expect(_says(GameData.check_defences(no_reach), "lures from no tiles")
		and _says(GameData.check_defences(no_hp), "no hit points to bite")
		and _says(GameData.check_enemies(boss), "is a boss and can be lured")
		and GameData.validate().is_empty(),
		"a lure reaching no tile, one with no hit points and a lurable boss fail the checks; the real tables pass")

	# **The field: a row of the registry, built when asked and only while a
	# decoy stands.** Its keys are a new game's, which moves SIM.
	var spec: Dictionary = Pathing.FIELDS[&"lure"]
	var fresh := State.create(22400)
	expect(not bool(spec.get("eager", false)) and bool(spec.get("none_without_seeds", false))
		and (fresh["flow_lure"] as PackedInt32Array).is_empty() and (fresh["lure_cost"] as PackedInt32Array).is_empty()
		and int(fresh["lure_version"]) == -1 and Pathing.lure_reach() >= reach,
		"the lure is a row of Pathing's registry, built when asked, its keys in a new game")
	var bare: Dictionary = _decoy_night(22401, [])
	var quiet: Dictionary = bare["state"]
	Entities.spawn(quiet, &"walker", (bare["spot"] as Vector2i) + Vector2i(2, 0))
	for _i in 20:
		Enemies.tick(quiet)
	expect(int(quiet["lure_version"]) == int(quiet["grid_version"])
		and (quiet["flow_lure"] as PackedInt32Array).is_empty() and (quiet["lure_cost"] as PackedInt32Array).is_empty(),
		"a farm with no decoy pays nothing for it: asked every tick, no costs and no sweep")

	# **Within reach and beyond.** A walker four tiles off, a runner three,
	# the Giant two; and a walker whose road home never comes within reach.
	var night: Dictionary = _decoy_night(22402)
	var state: Dictionary = night["state"]
	var spot: Vector2i = night["spot"]
	var full := int(Farm.occupant(state, spot).get("hp", 0))
	# Seeded at its head start (task 0225): how much less far it pulls than
	# the widest lure, so it pulls within its own `lure_tiles`.
	var head := Pathing.lure_reach() - reach
	expect(Pathing.lure_cells(state) == [spot] and Pathing.distance_lure(state, spot) == head
		and Pathing.distance_lure(state, spot + Vector2i(reach - 1, 0)) == head + reach - 1
		and Pathing.distance_lure(state, spot + Vector2i(reach + 1, 0)) > Pathing.lure_reach(),
		"a decoy stands at night, and the lure is swept from it", str(spot))
	var beyond := _beyond_the_lure(state, spot, reach)
	var walker := Entities.spawn(state, &"walker", spot + Vector2i(reach - 1, 0))
	var runner := Entities.spawn(state, &"runner", spot + Vector2i(0, 2 - reach))
	var giant := Entities.spawn(state, &"giant", spot + Vector2i(1, 1))
	var stray := Entities.spawn(state, &"walker", beyond)
	var home_before := Pathing.distance(state, beyond)
	var bitten := {}
	var strayed := false
	for _i in 240:
		Enemies.tick(state)
		for id in [walker, runner, giant, stray]:
			if int(Entities.get_one(state, id).get("chewing", -1)) == Grid.index(spot):
				bitten[id] = true
		if not Entities.get_one(state, stray).is_empty():
			strayed = strayed or Pathing.distance_lure(state, Entities.cell_of(state, stray)) <= Pathing.lure_reach()
	var left := int(Farm.occupant(state, spot).get("hp", 0))
	var home_after := Pathing.distance(state, Entities.cell_of(state, stray))
	expect(bitten.has(walker) and left < full, "the walker within reach walks to the decoy and bites it",
		"%d of %d" % [left, full])
	expect(beyond.x >= 0 and not bitten.has(stray) and not strayed and home_after < home_before,
		"while the one beyond walks on to the house", "%s, %d then %d" % [beyond, home_before, home_after])
	expect(bitten.has(runner), "a runner is lured too - round a wall, not round this")
	expect(not bitten.has(giant) and not Entities.get_one(state, giant).is_empty(),
		"and the Giant is not: it walks its own road past the straw")

	# **The tick it falls.** One bite from the end, a walker at it and a
	# second lured one walking in, after it by id: the bite fells it, and the
	# second goes by its own road on that same tick.
	var fall: Dictionary = _decoy_night(22403)
	var felled: Dictionary = fall["state"]
	var at: Vector2i = fall["spot"]
	var biter := Entities.spawn(felled, &"walker", at + Vector2i(1, 0))
	var coming := _turned_by_the_lure(felled, at, reach)
	var follower := Entities.spawn(felled, &"walker", coming)
	var home_step := Pathing.step_from(felled, coming)
	Pathing.field(felled, &"lure")
	var lure_step := Pathing.step_lure(felled, coming)
	var standing := felled.duplicate(true)
	Farm.occupant(felled, at)["hp"] = 1
	Enemies.tick(felled)
	Enemies.tick(standing)
	var moved := _step_of(felled, follower, coming)
	var lured := _step_of(standing, follower, coming)
	expect(biter < follower and Farm.occupant(felled, at).is_empty() and Farm.rubble_at(felled, at) == &"decoy"
		and Pathing.field(felled, &"lure").is_empty(),
		"one bite fells it: its straw on the ground, and no lure left")
	expect(coming.x >= 0 and home_step != lure_step and lured == lure_step - coming and moved == home_step - coming,
		"and the one walking in takes its own road that same tick, where with the decoy up it was walking to it",
		"%s: lured %s, felled %s, home %s" % [coming, lured, moved, home_step - coming])

	# **Two decoys: the nearer by the field, and a tie the first way out.**
	var pair: Dictionary = _decoy_night(22404, [Vector2i(0, -2), Vector2i(0, 2)])
	var two: Dictionary = pair["state"]
	var middle: Vector2i = pair["spot"]
	Pathing.field(two, &"lure")
	expect(Pathing.lure_cells(two).size() == 2
		and Pathing.step_lure(two, middle) == middle + Grid.STEPS[0]
		and Pathing.step_lure(two, middle + Vector2i(0, 1)) == middle + Vector2i(0, 2),
		"of two decoys the nearer by the field wins, and an even walk goes north, first in Grid.STEPS")
	var even := Entities.spawn(two, &"walker", middle)
	var nearer := Entities.spawn(two, &"walker", middle + Vector2i(0, 1))
	for _i in 60:
		Enemies.tick(two)
	expect(int(Entities.get_one(two, even).get("chewing", -1)) == Grid.index(middle + Vector2i(0, -2))
		and int(Entities.get_one(two, nearer).get("chewing", -1)) == Grid.index(middle + Vector2i(0, 2)),
		"and the walkers bite the ones the field sent them to")

	# **The view's road and the words.** A037's art since task 0236, standing
	# on its pivot; the hotbar puts it after spring's eight; its tooltip says
	# how far it pulls, in both languages.
	var road := true
	for name in DecoyArt.STATES:
		var path := DecoyArt.path_of(name)
		var frame := PlaceholderArt.frame(path)
		var texture := DecoyArt.texture(name)
		road = (road and RasterArt.FRAMES.has(path) and not PlaceholderArt.is_drawn(path)
			and PlaceholderArt.art(name).is_empty() and frame.get("canvas") == Vector2i(16, 32)
			and frame.get("pivot") == Vector2i(8, 28) and texture != null and texture.resource_path == path)
	expect(road, "whole, hurt and wrecked it wears A037's art, 16x32 on (8,28), with nothing of 0120's road left")
	var sprite := Sprite2D.new()
	sprite.texture = DecoyArt.texture(&"decoy")
	ArtPlacement.place(sprite, spot)
	expect(sprite.offset == -Vector2(8, 28) and sprite.scale == Vector2.ONE,
		"and a sprite wearing it stands on its pivot", str(sprite.offset))
	sprite.free()
	var swayed: Array = []
	for state_name in [&"decoy", &"decoy_hurt"]:
		for age in [0.05, 0.15, 0.25, 0.35]:
			var swaying := DecoyArt.sway_texture(state_name, age)
			swayed.append(swaying.resource_path if swaying != null else "")
	var sway_frames := true
	for state_name in [&"decoy", &"decoy_hurt"]:
		for i in DecoyArt.SWAY_FRAMES:
			var frame := PlaceholderArt.frame(DecoyArt.sway_path(state_name, i))
			sway_frames = (sway_frames and RasterArt.FRAMES.has(DecoyArt.sway_path(state_name, i))
				and frame.get("canvas") == Vector2i(16, 32) and frame.get("pivot") == Vector2i(8, 28))
	expect(sway_frames and is_equal_approx(DecoyArt.sway_seconds(), 0.1)
		and swayed == [DecoyArt.sway_path(&"decoy", 0), DecoyArt.sway_path(&"decoy", 1), DecoyArt.sway_path(&"decoy", 2), "",
			DecoyArt.sway_path(&"decoy_hurt", 0), DecoyArt.sway_path(&"decoy_hurt", 1), DecoyArt.sway_path(&"decoy_hurt", 2), ""],
		"struck, it plays A037's three sway frames a tenth of a second each - the hurt decoy its own - and stands", str(swayed))
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"decoy")
	bar.free()
	var order := Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_decoy.png" and order.find(&"decoy") >= _first_of_season(order, 1),
		"the hotbar shows A045's decoy icon (task 0244), among summer's after spring's, which keep their places", str(order))
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"decoy")
	I18n.use("en")
	expect(Names.KEYS.get(&"decoy") == &"DEF_DECOY" and said["en"].contains("from up to %d tiles" % reach)
		and said["pt_BR"].contains("%d ladrilhos" % reach) and said["pt_BR"].contains("ESPANTALHO-ISCA"),
		"its name and its pull, in both languages", str(said))

	# **Perf and the picture**: decoys in the swarm, the rebuild with them
	# held to the path's budget, and a lured crowd to photograph.
	var perf_tool := FileAccess.get_file_as_string("res://tools/perf.py")
	var perf_check := FileAccess.get_file_as_string("res://src/tools/perf_check.gd")
	var shots := FileAccess.get_file_as_string("res://src/tools/shot.gd")
	expect(perf_tool.contains("(\"lure_refresh\", PATH_BUDGET_US)") and perf_check.contains("Building.place(state, &\"decoy\"")
		and perf_check.contains("const DECOYS := 4") and shots.contains("[\"decoy\", "),
		"perf.py holds the rebuild with decoys to the path's budget, perf_check puts four in the swarm, and shot.gd has a lured crowd")
	_completed += 1


## 0225 - the zombie bait. A rotten fish the press makes by day from any fish,
## thrown down at night from a kit only; walked over, never hunted and never
## broken through; a crowd beyond any decoy's reach turns toward it and eats
## on it; it goes at its arrival count or its lifetime, leaving nothing, and
## the crowd is back on its road the same tick.
func _task_0225_bait() -> void:
	# **The row, the kit, and their checks.**
	var row: Dictionary = GameData.DEFENCES[&"zombie_bait"]
	var decoy: Dictionary = GameData.DEFENCES[&"decoy"]
	var kit: Dictionary = GameData.RECIPES[&"zombie_bait_kit"]
	var reach := int(row["lure_tiles"])
	var lifetime := int(row["lifetime_ticks"])
	var eaten_by := int(row["eaten_by"])
	expect(Building.materials_of(&"zombie_bait").keys() == [GameData.FISH] and Building.money_of(&"zombie_bait") > 0
		and Building.kit_only(&"zombie_bait")
		and Building.walked_over(&"zombie_bait") and reach >= 6 and reach <= 14 and reach > int(decoy["lure_tiles"])
		and lifetime >= 5 * GameData.SECONDS and lifetime <= 20 * GameData.SECONDS and eaten_by > 0
		and int(row["per_night_limit"]) > 0 and GameData.defence_season(row) == &"summer"
		and not row.has("damage") and not row.has("reload_ticks") and not row.has("path_cost")
		and Pathing.lure_reach() == reach,
		"a bait costs fish and a little money, comes from a kit only, is walked over, pulls further than a decoy, lasts 5-20 s, is eaten up, is rationed, is summer's, and shoots and blocks nothing",
		str(row))
	expect(kit["station"] == &"press" and kit["inputs"] == Building.materials_of(&"zombie_bait")
		and kit["output"] == {&"zombie_bait": 1} and Building.kit_station(&"zombie_bait") == &"press",
		"the press makes its kit, for the bait's own fish", str(kit))
	var paid_in_fish := GameData.DEFENCES.duplicate(true)
	(paid_in_fish[&"decoy"] as Dictionary)["cost"] = {GameData.FISH: 2}
	var priced := GameData.DEFENCES.duplicate(true)
	(priced[&"zombie_bait"] as Dictionary)["path_cost"] = 4
	var uneaten := GameData.DEFENCES.duplicate(true)
	(uneaten[&"zombie_bait"] as Dictionary)["eaten_by"] = 0
	var unmade := GameData.RECIPES.duplicate(true)
	unmade.erase(&"zombie_bait_kit")
	var too_far := GameData.DEFENCES.duplicate(true)
	(too_far[&"zombie_bait"] as Dictionary)["lure_tiles"] = 60
	expect(_says(GameData.check_defences(paid_in_fish), "costs unknown 'fish'")
		and _says(GameData.check_defences(priced), "walked over and priced")
		and _says(GameData.check_defences(uneaten), "eaten by nobody")
		and _says(GameData.check_kits(GameData.DEFENCES, unmade), "nothing makes one")
		and _says(GameData.check_pathing(GameData.TERRAIN_COST, too_far, GameData.BUILDINGS), "wider than WIDEST_STEP")
		and GameData.validate().is_empty(),
		"fish in a cost off a kit, a walked-over barrier, a bait eaten by nobody, a kit nothing makes and a head start the wheel cannot hold all fail; the real tables pass")

	# **Made by day at the press, from any fish - the cheapest first.**
	var day := State.create(22500)
	Resources.gain(day, {GameData.WOOD: 100, GameData.IRON: 20})
	var bench := _clear_for(day, &"press")
	expect(Building.place(day, &"press", bench), "a press goes up by day", str(bench))
	var order := GameData.pay_order(GameData.FISH)
	var cheap: StringName = order[0]
	var dear: StringName = order[order.size() - 1]
	Resources.gain(day, {cheap: 2, dear: 1})
	expect(Crafting.enqueue(day, bench, &"zombie_bait_kit"), "its kit is queued at the press")
	for _i in int(kit["ticks"]) * 4:
		if Crafting.kits(day, &"zombie_bait") > 0:
			break
		Sim.advance(day, 1)
	expect(Crafting.kits(day, &"zombie_bait") == 1 and Resources.amount(day, cheap) == 0
		and Resources.amount(day, dear) == 1,
		"and made: a bait's kit, paid in the cheapest fish held, the dearest left", "%s and %s" % [cheap, dear])

	# **Down from a kit only.**
	var night: Dictionary = _decoy_night(22501, [])
	var state: Dictionary = night["state"]
	var spot: Vector2i = night["spot"]
	Resources.gain(state, {cheap: 4})
	var fish := Resources.amount(state, GameData.FISH)
	expect(not Building.affordable(state, &"zombie_bait")
		and Building.why_not(state, &"zombie_bait", spot) == [&"WHY_KIT_ONLY", &"press"]
		and not Building.place(state, &"zombie_bait", spot) and Resources.amount(state, GameData.FISH) == fish,
		"with fish and no kit it is refused - make one at the press first - and no fish are spent")
	(state["kits"] as Dictionary)[&"zombie_bait"] = 1
	expect(Building.place(state, &"zombie_bait", spot) and Crafting.kits(state, &"zombie_bait") == 0
		and Resources.amount(state, GameData.FISH) == fish,
		"with the kit it goes down, and the fish stay where they were")
	expect(Building.why_not_sell(state, spot) == [&"WHY_THROWN"] and Building.sell(state, spot).is_empty()
		and StringName(Farm.occupant(state, spot).get("id", &"")) == &"zombie_bait",
		"thrown stays thrown: there is no fish to give back")
	Pathing.refresh(state)
	expect(Pathing.entry_cost(state, spot) == Farm.cost_of_terrain(Farm.terrain_at(state, spot))
		and not Pathing.is_prey(&"zombie_bait") and not Pathing.breaks_through(state, spot)
		and Pathing.distance_lure(state, spot) == 0,
		"walked over: the ground's cost, nothing a breaker hunts, nothing to break through, and the lure's 0")

	# **A crowd beyond any decoy's reach turns toward the bait, and eats.**
	# A decoy six west of it; ten walkers three to seven east, nine and more
	# from the straw. The farthest are spawned first, so the last to arrive
	# eats before the ones already eating are walked that tick.
	var pair: Dictionary = _decoy_night(22502, [Vector2i(-6, 0)])
	var both: Dictionary = pair["state"]
	var bait: Vector2i = pair["spot"]
	(both["kits"] as Dictionary)[&"zombie_bait"] = 1
	expect(Building.place(both, &"zombie_bait", bait), "a bait goes down beside the decoy", str(bait))
	Pathing.refresh(both)
	Pathing.field(both, &"lure")
	var crowd: Array = []
	var turned := 0
	for at in [Vector2i(6, -1), Vector2i(6, 1), Vector2i(6, 0), Vector2i(5, -1), Vector2i(5, 1),
			Vector2i(5, 0), Vector2i(4, -1), Vector2i(4, 1), Vector2i(4, 0), Vector2i(3, 0)]:
		var cell: Vector2i = bait + at
		var away := Pathing.distance_lure(both, cell)
		var by_decoy := absi(at.x + 6) + absi(at.y)
		if by_decoy > int(decoy["lure_tiles"]) and away == absi(at.x) + absi(at.y) \
				and Pathing.distance_lure(both, Pathing.step_lure(both, cell)) < away:
			turned += 1
		crowd.append(Entities.spawn(both, &"walker", cell))
	expect(turned == crowd.size(), "ten walkers beyond the decoy's reach, each pulled the bait's way by the field",
		"%d of %d" % [turned, crowd.size()])
	var ever_on := {}
	var gone_at := -1
	var walked_on := 0
	for t in 400:
		var before := {}
		for id in crowd:
			var one := Entities.get_one(both, int(id))
			if not one.is_empty() and Entities.cell_of(both, int(id)) == bait:
				before[id] = [int(one["pos"][0]), int(one["pos"][1])]
		Enemies.tick(both)
		for id in crowd:
			if not Entities.get_one(both, int(id)).is_empty() and Entities.cell_of(both, int(id)) == bait:
				ever_on[id] = true
		if Farm.occupant(both, bait).is_empty():
			gone_at = t
			for id in before:
				var one := Entities.get_one(both, int(id))
				if not one.is_empty() and [int(one["pos"][0]), int(one["pos"][1])] != before[id]:
					walked_on += 1
			break
	expect(gone_at >= 0 and ever_on.size() == eaten_by and walked_on > 0 and Farm.rubble_at(both, bait) == &"",
		"they stop on it to eat; it goes as the %dth reaches it, with nothing left on the ground, and the ones eating on it walk on that very tick" % eaten_by,
		"tick %d: %d reached, %d walked on" % [gone_at, ever_on.size(), walked_on])

	# **At its lifetime**, through the farm's own tick (`Building.expire`
	# first): three eating on it, too few to finish it, walk their own road
	# on the tick it goes.
	var timed: Dictionary = _decoy_night(22503, [])
	var later: Dictionary = timed["state"]
	var cell: Vector2i = timed["spot"]
	(later["kits"] as Dictionary)[&"zombie_bait"] = 1
	Building.place(later, &"zombie_bait", cell)
	var placed_at := int(later["tick"])
	var eaters: Array = []
	for at in [Vector2i(2, 0), Vector2i(0, 3), Vector2i(-3, 0)]:
		eaters.append(Entities.spawn(later, &"walker", cell + at))
	var expired_at := -1
	var homeward := 0
	for _i in lifetime + 30:
		Pathing.refresh(later)
		var roads := {}
		for id in eaters:
			var one := Entities.get_one(later, int(id))
			roads[id] = [Vector2i(int(one["pos"][0]), int(one["pos"][1])),
				Pathing.step_from(later, Entities.cell_of(later, int(id))) * Player.SUBTILE
					+ Vector2i.ONE * (Player.SUBTILE / 2)]
		Sim.tick(later)
		if Farm.occupant(later, cell).is_empty():
			expired_at = int(later["tick"]) - placed_at
			for id in eaters:
				var one := Entities.get_one(later, int(id))
				if _moved_toward(roads[id][0], Vector2i(int(one["pos"][0]), int(one["pos"][1])), roads[id][1]):
					homeward += 1
			break
	expect(absi(expired_at - lifetime) <= 1 and homeward == eaters.size() and Farm.rubble_at(later, cell) == &""
		and Pathing.field(later, &"lure").is_empty(),
		"unfinished, it is gone at its lifetime with nothing left, and the three eating on it walk their own road that tick",
		"%d of %d ticks, %d homeward" % [expired_at, lifetime, homeward])

	# **Rationed, and the tree's spare stakes are the barricade's alone.**
	var limit := int(row["per_night_limit"])
	var staked: Dictionary = _decoy_night(22504, [])["state"]
	(staked["tech_owned"] as Array).assign([&"spare stakes"])
	var bonus := Tech.bonus(staked, "barricade_bonus", 0)
	expect(bonus > 0 and Building.left_tonight(staked, &"zombie_bait") == limit
		and Building.left_tonight(staked, &"barricade") == int(GameData.DEFENCES[&"barricade"]["per_night_limit"]) + bonus,
		"%d baits a night, spare stakes or none, while the stakes add %d barricades" % [limit, bonus])
	(staked["kits"] as Dictionary)[&"zombie_bait"] = limit + 1
	var down := 0
	for dx in limit:
		if Building.place(staked, &"zombie_bait", (_decoy_ground) + Vector2i(dx - 2, 3)):
			down += 1
	expect(down == limit and Building.why_not(staked, &"zombie_bait", _decoy_ground + Vector2i(2, -3))[0] == &"WHY_NIGHT_LIMIT",
		"and the next is refused with the night's reason", str(down))

	# **On the ground and in the hotbar**: A037's art since task 0236.
	var frame := PlaceholderArt.frame(DecoyArt.path_of(&"zombie_bait"))
	var lying := DecoyArt.texture(&"zombie_bait")
	expect(lying != null and RasterArt.FRAMES.has(DecoyArt.path_of(&"zombie_bait"))
		and not PlaceholderArt.is_drawn(DecoyArt.path_of(&"zombie_bait")) and frame.get("canvas") == Vector2i(16, 16)
		and frame.get("pivot") == Vector2i(8, 14) and PlaceholderArt.art(&"zombie_bait").is_empty(),
		"on the ground A037's fish, 16x16 lying on (8,14), with nothing of 0120's road left", str(frame))
	var bar := Hotbar.new()
	bar.show_state(state)
	var icon := bar._icon_of(&"zombie_bait")
	var price := bar._price_line(&"zombie_bait")
	bar.free()
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_zombie_bait.png"
		and PlaceholderArt.art_tint(&"icon_zombie_bait") == Color.WHITE and price.begins_with(I18n.f(&"HOTBAR_KITS", [0])),
		"its slot wears A037's bait icon untinted, and counts its kits, none and all", price)
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = [Describe.defence(&"zombie_bait"), Names.refusal([&"WHY_KIT_ONLY", &"press"])]
	I18n.use("en")
	expect(Names.KEYS.get(&"zombie_bait") == &"DEF_ZOMBIE_BAIT" and Names.KEYS.get(&"zombie_bait_kit") == &"REC_ZOMBIE_BAIT_KIT"
		and (said["en"][0] as String).contains("from up to %d tiles" % reach)
		and (said["en"][0] as String).contains("%d have eaten" % eaten_by)
		and (said["pt_BR"][0] as String).contains("ISCA DE ZUMBI") and (said["pt_BR"][1] as String).contains("prensa"),
		"its name, its pull, its kit and who eats it, in both languages", str(said))
	expect(FileAccess.get_file_as_string("res://implementation/backlog/packs/A037-decoy.md").contains("Final geometry settled by game task 0225"),
		"and A037's table says the geometry this task settled")
	_completed += 1


## 0226 - the beehive. A summer tower whose sting is damage over time in a
## table beside the fire's, refreshed and never stacked; as strong as the
## sunflowers growing round it, counted once at `begin_night`, and fed from
## the store - in whole stings' worth, hives in cell order - where too few
## grow; its bees spread over a crowd; one upgrade, and no family goes past
## its last row.
func _task_0226_beehive() -> void:
	# **The row, the levers and their checks.**
	var row: Dictionary = GameData.DEFENCES[&"beehive"]
	var cost := Building.materials_of(&"beehive")
	var steps: Array = GameData.TOWER_LEVELS[&"beehive"]
	var gives: Dictionary = (steps[0] as Dictionary)["gives"] if steps.size() == 1 else {}
	expect(cost.size() == 2 and cost.has(GameData.WOOD) and cost.has(GameData.SUNFLOWER) and Building.money_of(&"beehive") > 0
		and row.has("reload_ticks") and StringName(row["shape"]) == GameData.SHAPE_STING
		and StringName(row["damage_type"]) == GameData.DAMAGE_STING and int(row["damage"]) > 0
		and int(row["range"]) <= 3 and int(row["sting_ticks"]) > 0 and int(row["energy_draw"]) == 0
		and int(row["flower_reach"]) >= 2 and int(row["flower_reach"]) <= 4 and int(row["stock_flowers"]) > 0
		and GameData.defence_season(row) == &"summer" and Sfx.TOWER_SOUNDS.has(&"beehive")
		and int(gives.get("targets", 1)) > int(row["targets"]),
		"a hive costs wood, sunflowers and money, stings close by, gathers from 2-4 tiles, draws no power, is summer's, sounds, and has one upgrade - to two stings at once",
		str(row))
	var unrefused: Array = []
	for pair in [["damage", "stings for nothing"], ["sting_ticks", "stings for nothing"],
			["flower_reach", "a flower_reach of 0"], ["flowers_per_sting", "a flowers_per_sting of 0"],
			["most_flowers", "a most_flowers of 0"], ["stock_flowers", "a stock_flowers of 0"]]:
		var broken := GameData.DEFENCES.duplicate(true)
		(broken[&"beehive"] as Dictionary)[pair[0]] = 0
		if not _says(GameData.check_defences(broken), pair[1]):
			unrefused.append(pair[0])
	expect(unrefused.is_empty() and GameData.check_defences(GameData.DEFENCES).is_empty()
		and GameData.validate().is_empty(),
		"a sting of no damage or for no time, and each sunflower lever at zero, fail the check; the real tables pass",
		str(unrefused))

	# **The sting: refreshed, never stacked**, in a table of its own. Three
	# walkers held still: one stung once; one stung three times at once, the
	# last weaker and shorter; one topped up two seconds in by a weaker sting.
	var night: Dictionary = _decoy_night(22600, [])
	var state: Dictionary = night["state"]
	var spot: Vector2i = night["spot"]
	var once := Entities.spawn(state, &"walker", spot)
	var thrice := Entities.spawn(state, &"walker", spot + Vector2i(1, 0))
	var topped := Entities.spawn(state, &"walker", spot + Vector2i(2, 0))
	var full := int(Entities.get_one(state, once)["hp"])
	var long := 4 * GameData.SECONDS
	Combat.sting(state, once, 2, long)
	for pair in [[2, long], [2, long], [1, GameData.SECONDS]]:
		Combat.sting(state, thrice, int(pair[0]), int(pair[1]))
	Combat.sting(state, topped, 2, long)
	var one: Dictionary = (state["stung"] as Dictionary).get(thrice, {})
	expect((state["stung"] as Dictionary).size() == 3 and int(one.get("damage", 0)) == 2
		and int(one.get("left", 0)) == long and (state["burning"] as Dictionary).is_empty()
		and State.RUN_DATA.has("stung"),
		"stung three times at once, the last weaker and shorter, it is one sting at the stronger damage for the longer time - in its own table, not the fire's",
		str(one))
	var first := 0
	for tick in 2 * long:
		Combat.tick(state)
		if tick == 0:
			first = full - int(Entities.get_one(state, once)["hp"])
		if tick == 2 * GameData.SECONDS - 1:
			Combat.sting(state, topped, 1, long)
	var lost_once := full - int(Entities.get_one(state, once)["hp"])
	var lost_thrice := full - int(Entities.get_one(state, thrice)["hp"])
	var lost_topped := full - int(Entities.get_one(state, topped)["hp"])
	expect(first == 2 and lost_once == 8 and lost_thrice == lost_once and not Combat.is_stung(state, once),
		"the first hurts at once and one a second after it for its four seconds - 8 off, then gone - and stung three times it lost no more",
		"%d first, %d and %d" % [first, lost_once, lost_thrice])
	expect(lost_topped == 12 and not Combat.is_stung(state, topped),
		"topped up two seconds in by a weaker sting, it ran four seconds again from there at its stronger damage: 12 off",
		str(lost_topped))
	Combat.sting(state, once, 2, long)
	Enemies.withdraw(state)
	expect((state["stung"] as Dictionary).is_empty(), "and a withdrawn night leaves nobody stung")

	# **As strong as its field.** The same hive on the same farm, among nine
	# growing sunflowers and among none, nothing in the store; a walker held
	# in its reach for the sting's four seconds.
	var bloom: Dictionary = _hive_night(22601, 9, 0)
	var bare: Dictionary = _hive_night(22601, 0, 0)
	var hive_bloom := Farm.occupant(bloom["state"], bloom["spot"])
	var hive_bare := Farm.occupant(bare["state"], bare["spot"])
	var per := int(row["flowers_per_sting"])
	var strong := Towers.sting_of(bloom["state"], hive_bloom, row)
	var weak := Towers.sting_of(bare["state"], hive_bare, row)
	expect(int(hive_bloom.get("flowers", -1)) == mini(9, int(row["most_flowers"]))
		and int(hive_bare.get("flowers", -1)) == 0
		and strong == int(row["damage"]) + mini(9, int(row["most_flowers"])) / per and weak == int(row["damage"])
		and Resources.amount(bloom["state"], GameData.SUNFLOWER) == 0,
		"fed at the waves: nine growing within its reach make the sting stronger; with neither, it stings for its damage alone",
		"%d and %d" % [strong, weak])
	var hits := (long + GameData.STING_EVERY_TICKS - 1) / GameData.STING_EVERY_TICKS
	var felt_bloom := _stung_by_hive(bloom, long)
	var felt_bare := _stung_by_hive(bare, long)
	print("  a hive among nine sunflowers took %d off a walker in four seconds; one with none, %d" % [felt_bloom, felt_bare])
	expect(felt_bloom == hits * strong and felt_bare == hits * weak and felt_bloom > felt_bare and felt_bare > 0,
		"a hive among growing sunflowers outdoes one without, and one without still stings, weakly",
		"%d against %d" % [felt_bloom, felt_bare])

	# **Fed from the store where too few grow**, in whole stings' worth: six
	# of twenty; none of one for a hive with four growing; and two hives short
	# of a store of eight share it in cell order, the second taking none of
	# the two left.
	var stocked: Dictionary = _hive_night(22602, 0, 20)
	var odd: Dictionary = _hive_night(22603, 4, 1)
	var pair_night: Dictionary = _hive_night(22604, 0, 8, [Vector2i(0, 3)])
	var stock := int(row["stock_flowers"])
	var took := mini(stock, int(row["most_flowers"])) / per * per
	expect(int(Farm.occupant(stocked["state"], stocked["spot"]).get("flowers", -1)) == took
		and Resources.amount(stocked["state"], GameData.SUNFLOWER) == 20 - took,
		"a hive with stocked sunflowers and none growing takes them at begin_night: %d of 20" % took,
		str(Resources.amount(stocked["state"], GameData.SUNFLOWER)))
	expect(int(Farm.occupant(odd["state"], odd["spot"]).get("flowers", -1)) == 4
		and Resources.amount(odd["state"], GameData.SUNFLOWER) == 1,
		"with four growing and one in the store it eats none: one more would make no sting stronger")
	var second: Vector2i = (pair_night["spot"] as Vector2i) + Vector2i(0, 3)
	expect(int(Farm.occupant(pair_night["state"], pair_night["spot"]).get("flowers", -1)) == took
		and int(Farm.occupant(pair_night["state"], second).get("flowers", -1)) == 0
		and Resources.amount(pair_night["state"], GameData.SUNFLOWER) == 8 - took,
		"two hives short of a store of eight: the first in cell order takes its share, the second none of what is left",
		str(Resources.amount(pair_night["state"], GameData.SUNFLOWER)))

	# **The bees spread**: of two walkers in reach the nearer already stung,
	# the hive stings the other.
	var spread: Dictionary = _hive_night(22605, 0, 0)
	var swarm_state: Dictionary = spread["state"]
	var near := Entities.spawn(swarm_state, &"walker", (spread["spot"] as Vector2i) + Vector2i(1, 0))
	var far := Entities.spawn(swarm_state, &"walker", (spread["spot"] as Vector2i) + Vector2i(2, 0))
	Combat.sting(swarm_state, near, 1, long)
	var left_near := Combat.sting_left(swarm_state, near)
	Towers.tick(swarm_state)
	expect(Combat.is_stung(swarm_state, far) and Combat.sting_left(swarm_state, near) == left_near
		and Towers.shots_fired(swarm_state) == 1,
		"with the nearer in reach already stung, the bees go to the other rather than topping it up")

	# **One upgrade, and no further.** With true sights the hive goes to
	# level two at its price, stinging two at once; a third is refused by
	# name, for nothing.
	var up := State.create(22606)
	SuiteKit.open_arsenal(up, [&"beehive"])
	Resources.gain(up, {GameData.WOOD: 200, GameData.SUNFLOWER: 40, GameData.MONEY: 500})
	(up["tech_owned"] as Array).append(&"true sights")
	NightRoad.into_build(up)
	var cell := _open_square(up, 4, &"beehive")
	expect(Building.place(up, &"beehive", cell), "a hive goes down in the build step", str(cell))
	var bill := Building.upgrade_cost(up, cell)
	var had := Resources.amount(up, GameData.SUNFLOWER)
	expect(Building.upgrade(up, cell) and Building.level_at(up, cell) == 2
		and int(Building.entry_at(up, cell)["targets"]) == 2
		and Resources.amount(up, GameData.SUNFLOWER) == had - int(bill.get(GameData.SUNFLOWER, 0)),
		"it goes to level two at its price, two stings at once", str(bill))
	var wood := Resources.amount(up, GameData.WOOD)
	var refusal := Building.why_not_upgrade(up, cell)
	expect(refusal == [&"WHY_LAST_LEVEL"] and not Building.upgrade(up, cell)
		and Building.level_at(up, cell) == 2 and Building.upgrade_cost(up, cell).is_empty()
		and Resources.amount(up, GameData.WOOD) == wood
		and I18n.t(&"WHY_LAST_LEVEL") != "WHY_LAST_LEVEL",
		"a two-level family refuses a third upgrade - at its last level, for nothing", str(refusal))

	# **The words, the sound and the placeholder road.**
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"beehive")
	I18n.use("en")
	var seconds := "%.1fs" % (float(int(row["sting_ticks"])) / float(GameData.TICK_HZ))
	expect(Names.KEYS.get(&"beehive") == &"DEF_BEEHIVE" and Names.KEYS.get(&"sting") == &"DMG_STING"
		and (said["en"] as String).contains("BEEHIVE") and (said["en"] as String).contains("hurts for " + seconds)
		and (said["en"] as String).contains("every %d sunflowers growing within %d tiles" % [per, int(row["flower_reach"])])
		and (said["en"] as String).contains("up to %d from the store" % stock)
		and (said["pt_BR"] as String).contains("COLMEIA") and (said["pt_BR"] as String).contains("girassóis")
		and (said["pt_BR"] as String).contains("ferrão"),
		"its name, its sting and its sunflowers, in both languages", str(said))
	# **A038's art since task 0237**: an authored tower at each level and
	# state, on the family's canvas, with the point the swarm leaves from.
	var road: Array = []
	for name in [&"beehive", &"beehive_hurt", &"beehive_fire", &"beehive_wreck",
			&"beehive_2", &"beehive_2_hurt", &"beehive_2_fire", &"beehive_2_wreck"]:
		var path := WorldView.BUILDING_DIR + str(name) + ".png"
		var frame: Dictionary = RasterArt.FRAMES.get(path, {})
		var wreck := str(name).ends_with("_wreck")
		if frame.get("canvas") != Vector2i(32, 48) or frame.get("pivot") != Vector2i(16, 44) \
				or not bool(frame.get("tower", false)) or frame.has("muzzle") == wreck \
				or not ResourceLoader.exists(path) or PlaceholderArt.is_drawn(path) or not PlaceholderArt.art(name).is_empty():
			road.append(name)
	var view := WorldView.new()
	var states := [view._worn(&"beehive", {"id": &"beehive", "level": 2, "hp": 10, "reload": GameData.SECONDS}),
		view._worn(&"beehive", {"id": &"beehive", "level": 1, "hp": 10, "reload": 0}),
		view._worn(&"beehive", {"id": &"beehive", "level": 2, "hp": 90, "reload": 0})]
	view.free()
	expect(road.is_empty() and WorldView.authored_tower(&"beehive") and not WorldView.stand_in_tower(&"beehive")
		and states == [&"beehive_2_fire", &"beehive_hurt", &"beehive_2"],
		"A038's art: an authored tower at 32x48 on (16,44), each level and state, the swarm's point on all but the wreck, lit as it stings and hurt below its threshold",
		"%s %s" % [str(road), str(states)])
	var frames: Array = []
	var swarm_art := true
	for i in 3:
		var texture := HiveArt.swarm(i)
		var frame := PlaceholderArt.frame(HiveArt.path_of(i))
		swarm_art = (swarm_art and texture != null and texture.resource_path == HiveArt.path_of(i)
			and RasterArt.FRAMES.has(HiveArt.path_of(i)) and frame.get("canvas") == Vector2i(8, 8)
			and frame.get("pivot") == Vector2i(4, 4) and bool(frame.get("loop", false)))
		if texture != null:
			frames.append(texture.get_image().get_data())
	expect(swarm_art and frames.size() == 3 and frames[0] != frames[1] and frames[1] != frames[2] and frames[0] != frames[2]
		and PlaceholderArt.art(&"bee_swarm").is_empty() and HiveArt.frame_at(0.05) == 0
		and HiveArt.frame_at(0.15) == 1 and HiveArt.frame_at(0.35) == 0 and HiveArt.swarm(3) == HiveArt.swarm(0),
		"the swarm: A038's three looping 8x8 frames round (4,4), a tenth of a second each round and round")
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"beehive")
	bar.free()
	var order := Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_beehive.png"
		and PlaceholderArt.art(&"icon_beehive").is_empty()
		and order.find(&"beehive") >= _first_of_season(order, 1),
		"the hotbar shows A045's hive icon (task 0244), among summer's after spring's", str(order))
	var shots := FileAccess.get_file_as_string("res://src/tools/shot.gd")
	expect(shots.contains("[\"beehive\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A038-beehive.md").contains("Final geometry settled by game task 0226"),
		"shot.gd has a hive at work, and A038's table says the geometry this task settled")
	_completed += 1


## A hive put down in the build step on open ground - with one more at each
## of `more` from it - `growing` sunflowers sown round the first, nearest
## first and within its reach, and `stored` in the store once they are paid
## for; then START into a parked night with nobody in it (task 0226).
func _hive_night(seed_value: int, growing: int, stored: int, more: Array = []) -> Dictionary:
	var state := State.create(seed_value)
	SuiteKit.open_arsenal(state, [&"beehive"])
	var price := int((GameData.DEFENCES[&"beehive"]["cost"] as Dictionary)[GameData.SUNFLOWER])
	Resources.gain(state, {GameData.WOOD: 200, GameData.SUNFLOWER: price * (1 + more.size()) + stored,
		GameData.MONEY: 500})
	NightRoad.into_build(state)
	var spot := _open_square(state, 4, &"beehive")
	expect(Building.place(state, &"beehive", spot), "a hive goes down in the build step", str(spot))
	for offset in more:
		expect(Building.place(state, &"beehive", spot + (offset as Vector2i)), "and another beside it",
			str(spot + (offset as Vector2i)))
	var reach := int(GameData.DEFENCES[&"beehive"]["flower_reach"])
	var sown := 0
	for ring in range(1, reach + 1):
		for cell in Grid.within(spot, ring):
			if sown < growing and Grid.chebyshev(spot, cell) == ring and Farm.occupant(state, cell).is_empty():
				var plot: Dictionary = Farming.EMPTY_PLOT.duplicate()
				plot["crop"] = GameData.SUNFLOWER
				(state["plots"] as Dictionary)[Grid.index(cell)] = plot
				sown += 1
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	return {"state": state, "spot": spot}


## What a hive's stings take off a walker held two tiles east of it, in its
## reach, for `ticks` of the towers and the combat - nothing else moving - with
## hit points enough never to fall (task 0226).
func _stung_by_hive(night: Dictionary, ticks: int) -> int:
	var state: Dictionary = night["state"]
	var walker := Entities.spawn(state, &"walker", (night["spot"] as Vector2i) + Vector2i(2, 0))
	Entities.set_hp(state, walker, 1000)
	for _i in ticks:
		Towers.tick(state)
		Combat.tick(state)
	return 1000 - int(Entities.get_one(state, walker).get("hp", 0))


## 0227 - the pumpkin catapult. An autumn tower that lobs a pumpkin from the
## store at a place and splashes it with the falloff its lever claims - not a
## cheaper mortar; a round may come out of a field as well as off a bench;
## out of pumpkins it throws a stone, weakly, and is never silent; three
## levels laid over its row, the last a volley; and the HUD counts pumpkins
## only once the run has reached autumn.
func _task_0227_catapult() -> void:
	# **The row, and not a cheaper mortar.**
	var row: Dictionary = GameData.DEFENCES[&"catapult"]
	var mortar: Dictionary = GameData.DEFENCES[&"mortar"]
	var cost := Building.materials_of(&"catapult")
	expect(cost.size() == 2 and cost.has(GameData.WOOD) and cost.has(GameData.PUMPKIN) and Building.money_of(&"catapult") > 0
		and StringName(row["shape"]) == GameData.SHAPE_SPLASH and StringName(row["aim"]) == GameData.AIM_BALLISTIC
		and int(row["flight_ticks"]) > 0 and row["ammo"] == {GameData.PUMPKIN: 1}
		and GameData.defence_season(row) == &"autumn" and Sfx.TOWER_SOUNDS.get(&"catapult") == &"sfx/catapult"
		and not GameData.DEFENCES.has(GameData.PUMPKIN),
		"a catapult costs wood, pumpkins and money, lobs a splash at a place a pumpkin a shot, is autumn's and, since 0283, thunks as itself - and its id is not the crop's",
		str(row))
	expect(int(row["range"]) < int(mortar["range"]) and int(row["damage"]) < int(mortar["damage"])
		and int(row.get("min_range", 0)) == 0 and int(mortar["min_range"]) > 0
		and int(row["energy_draw"]) == 0 and not cost.has(GameData.IRON) and not cost.has(GameData.STONE),
		"not a cheaper mortar: a shorter reach and a softer hit, but no ground it cannot touch, and no gunpowder, iron, stone or power")
	var spring := GameData.DEFENCES.duplicate(true)
	(spring[&"catapult"] as Dictionary)["season"] = &"spring"
	var unseasoned := GameData.check_seasonal_supply(spring, GameData.RECIPES)
	expect(GameData.check_seasonal_supply(GameData.DEFENCES, GameData.RECIPES).is_empty()
		and _says(unseasoned, "spring cannot make pumpkin") and _says(unseasoned, "summer cannot make pumpkin")
		and not _says(unseasoned, "autumn"),
		"as autumn's it passes 0193's check; unlocked in spring it fails there - pumpkins are autumn's", str(unseasoned))

	# **A round out of a field.** `check_ammo` takes what a crop yields as
	# well as what a recipe makes; with no field the catapult is refused, and
	# a round nothing makes or grows still is.
	var no_field := GameData.check_ammo(GameData.DEFENCES, GameData.RECIPES, {})
	var exotic := GameData.DEFENCES.duplicate(true)
	(exotic[&"catapult"] as Dictionary)["ammo"] = {GameData.MEAT: 1}
	expect(GameData.check_ammo(GameData.DEFENCES, GameData.RECIPES).is_empty()
		and _says(no_field, "'catapult' fires 'pumpkin'")
		and _says(GameData.check_ammo(exotic, GameData.RECIPES), "'catapult' fires 'meat'"),
		"a round a field grows is a proper shot; with no field the catapult is refused, and so is one nothing makes or grows",
		str(no_field))

	# **It lands where it was aimed, with the falloff the lever claims.** A
	# walker at four tiles, one more on its cell, one a tile off and one at
	# the splash's edge, one past it: the throw goes to the first; it walks
	# off before the pumpkin comes down, which lands on its cell all the same.
	var night: Dictionary = _catapult_night(22700, 5)
	var state: Dictionary = night["state"]
	var spot: Vector2i = night["spot"]
	var reach := int(row["splash_tiles"])
	var aim := spot + Vector2i(4, 0)
	var thrown_at := Entities.spawn(state, &"walker", aim)
	var on_it := Entities.spawn(state, &"walker", aim)
	var off_one := Entities.spawn(state, &"walker", aim + Vector2i(0, -1))
	var at_edge := Entities.spawn(state, &"walker", aim + Vector2i(0, reach))
	var past := Entities.spawn(state, &"walker", aim + Vector2i(0, -reach - 1))
	for id in [thrown_at, on_it, off_one, at_edge, past]:
		Entities.set_hp(state, id, 1000)
	Towers.tick(state)
	var flying: Array = state["projectiles"]
	expect(Towers.shots_fired(state) == 1 and flying.size() == 1 and int(flying[0]["target"]) == thrown_at
		and Vector2i(int(flying[0]["to"][0]), int(flying[0]["to"][1])) == aim
		and Resources.amount(state, GameData.PUMPKIN) == 4,
		"one throw, at the nearest, aimed at its cell, and one pumpkin out of the store", str(flying))
	Entities.get_one(state, thrown_at)["pos"] = [(spot.x + 1) * Player.SUBTILE + Player.SUBTILE / 2,
		(spot.y + 5) * Player.SUBTILE + Player.SUBTILE / 2]
	for _i in int(row["flight_ticks"]):
		Towers.tick(state)
	var full := Towers.damage_of(state, row)
	var edge := int(row["splash_falloff_percent"])
	var took := func(id: int) -> int: return 1000 - int(Entities.get_one(state, id)["hp"])
	var lost := [took.call(on_it), took.call(off_one), took.call(at_edge), took.call(past), took.call(thrown_at)]
	print("  a pumpkin's splash: %s - the middle, a tile off, the edge, past it, the one it was thrown at" % str(lost))
	expect((state["projectiles"] as Array).is_empty()
		and lost == [full, full * (100 - (100 - edge) / reach) / 100, full * edge / 100, 0, 0],
		"it lands where it was aimed: full in the middle, %d%% at the edge as the lever claims, between them on the way out, nothing past it - nor on the one it was thrown at, who walked off" % edge,
		str(lost))

	# **An empty pool still throws**: a stone, the weak shot every tower
	# has - weaker, slower to reload, no splash - at the one it was thrown
	# at, wherever it has walked.
	var dry: Dictionary = _catapult_night(22701, 0)
	var empty: Dictionary = dry["state"]
	var at: Vector2i = dry["spot"]
	var hit := Entities.spawn(empty, &"walker", at + Vector2i(4, 0))
	var near := Entities.spawn(empty, &"walker", at + Vector2i(4, 0))
	for id in [hit, near]:
		Entities.set_hp(empty, id, 1000)
	Towers.tick(empty)
	var stone: Array = empty["projectiles"]
	var thrower := Farm.occupant(empty, at)
	expect(Towers.shots_fired(empty) == 1 and stone.size() == 1 and not bool(stone[0]["armed"])
		and StringName(stone[0]["shape"]) == GameData.SHAPE_SINGLE
		and int(stone[0]["damage"]) == Ammo.weak_damage(full)
		and int(thrower["reload"]) == Ammo.weak_reload(int(row["reload_ticks"])),
		"with no pumpkins it still throws: a stone, for the weak damage, reloading the weak time",
		str(stone))
	Entities.get_one(empty, hit)["pos"] = [(at.x + 2) * Player.SUBTILE + Player.SUBTILE / 2,
		(at.y + 3) * Player.SUBTILE + Player.SUBTILE / 2]
	for _i in int(row["flight_ticks"]):
		Towers.tick(empty)
	expect(1000 - int(Entities.get_one(empty, hit)["hp"]) == Ammo.weak_damage(full)
		and int(Entities.get_one(empty, near)["hp"]) == 1000,
		"and the stone finds the one it was thrown at, with no splash round its cell - never a silent catapult")

	# **Three levels, read through `Building.entry_at`**: each laid over the
	# row as its step gives, the last a volley - two pumpkins a throw.
	var up := State.create(22702)
	SuiteKit.open_arsenal(up, [&"catapult"])
	Resources.gain(up, {GameData.WOOD: 300, GameData.STONE: 100, GameData.IRON: 100, GameData.PUMPKIN: 10,
		GameData.MONEY: 500})
	(up["tech_owned"] as Array).append_array([&"true sights", &"oiled works"])
	NightRoad.into_build(up)
	var cell := _open_square(up, 4, &"catapult")
	expect(Building.place(up, &"catapult", cell), "a catapult goes down in the build step", str(cell))
	var steps: Array = GameData.TOWER_LEVELS[&"catapult"]
	var wanted := row.duplicate(true)
	var read: Array = []
	var laid := true
	for level in [1, 2, 3]:
		if level > 1:
			laid = Building.upgrade(up, cell) and laid
			for key in ((steps[level - 2] as Dictionary)["gives"] as Dictionary):
				wanted[key] = ((steps[level - 2] as Dictionary)["gives"] as Dictionary)[key]
		var entry := Building.entry_at(up, cell)
		read.append([int(entry["damage"]), int(entry["range"]), int(entry["splash_tiles"]), int(entry["targets"])])
		for key in ["damage", "hp", "range", "splash_tiles", "targets", "reload_ticks", "flight_ticks"]:
			laid = laid and int(entry[key]) == int(wanted[key])
	expect(laid and steps.size() == 2 and Building.level_at(up, cell) == 3
		and Building.why_not_upgrade(up, cell) == [&"WHY_TOP_LEVEL"] and int((read.back() as Array)[3]) == 2,
		"levels 1-3 read through Building.entry_at, each its step laid over the row, the third two at once",
		str(read))
	NightRoad.through_build(up)
	NightRoad.park(up)
	Enemies.withdraw(up)
	for offset in [Vector2i(4, 0), Vector2i(4, 2)]:
		Entities.spawn(up, &"walker", cell + (offset as Vector2i))
	var before := Resources.amount(up, GameData.PUMPKIN)
	Towers.tick(up)
	expect(Towers.in_flight(up) == 2 and Resources.amount(up, GameData.PUMPKIN) == before - 1,
		"at level three a throw is a volley: two pumpkins in the air, one out of the store")

	# **The HUD's line counts pumpkins once the run has reached autumn**, and
	# from Year 2 on in every season.
	var dated := State.create(22703)
	var by_season: Array = []
	for day in [1, GameData.SEASON_DAYS + 1, 2 * GameData.SEASON_DAYS + 1, Calendar.year_days() + 1]:
		dated["day"] = day
		by_season.append(Ammo.kinds_reached(dated).has(GameData.PUMPKIN))
	expect(by_season == [false, false, true, true] and Ammo.kinds().has(GameData.PUMPKIN),
		"pumpkins are ammunition, counted on the HUD from autumn and in Year 2's spring", str(by_season))

	# **The words, the sound and the placeholder road.**
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"catapult")
	I18n.use("en")
	expect(Names.KEYS.get(&"catapult") == &"DEF_CATAPULT"
		and (said["en"] as String).contains("PUMPKIN CATAPULT") and (said["en"] as String).contains("1 pumpkin a shot")
		and (said["en"] as String).contains("%d tiles round where it lands" % reach)
		and (said["pt_BR"] as String).contains("CATAPULTA DE ABÓBORA") and (said["pt_BR"] as String).contains("1 abóbora por tiro")
		and Describe.defence(&"mortar").contains("1 gunpowder a shot"),
		"its name, its pumpkin a shot and its splash, in both languages - and the mortar says what it spends too", str(said))
	# **A039's art since task 0238**: an authored tower at every level and
	# state, on the family's canvas, with its throwing arm's point on all but
	# the wreck.
	var road: Array = []
	for level in ["", "_2", "_3"]:
		for state_name in ["", "_hurt", "_fire", "_wreck"]:
			var name := StringName("catapult%s%s" % [level, state_name])
			var path := WorldView.BUILDING_DIR + str(name) + ".png"
			var frame: Dictionary = RasterArt.FRAMES.get(path, {})
			if frame.get("canvas") != Vector2i(32, 48) or frame.get("pivot") != Vector2i(16, 44) \
					or not bool(frame.get("tower", false)) or frame.has("muzzle") == (state_name == "_wreck") \
					or not ResourceLoader.exists(path) or PlaceholderArt.is_drawn(path) or not PlaceholderArt.art(name).is_empty():
				road.append(name)
	var view := WorldView.new()
	var states := [view._worn(&"catapult", {"id": &"catapult", "level": 3, "hp": 10, "reload": WorldView.levelled_stat({"id": &"catapult", "level": 3}, "reload_ticks")}),
		view._worn(&"catapult", {"id": &"catapult", "level": 2, "hp": 10, "reload": 0}),
		view._worn(&"catapult", {"id": &"catapult", "level": 1, "hp": int(row["hp"]), "reload": 0})]
	view.free()
	expect(road.is_empty() and WorldView.authored_tower(&"catapult") and not WorldView.stand_in_tower(&"catapult")
		and WorldView.throws_pumpkins(&"catapult") and not WorldView.throws_pumpkins(&"mortar")
		and states == [&"catapult_3_fire", &"catapult_2_hurt", &"catapult"],
		"A039's art: an authored tower at 32x48 on (16,44), every level and state, the arm's point on all but the wreck, thrown, hurt and whole",
		"%s %s" % [str(road), str(states)])
	var frames: Array = []
	var shot_art := true
	for i in CatapultArt.SHOT_FRAMES:
		var texture := CatapultArt.shot(i)
		var frame := PlaceholderArt.frame(CatapultArt.SHOT_PATH % i)
		shot_art = (shot_art and texture != null and texture.resource_path == CatapultArt.SHOT_PATH % i
			and frame.get("canvas") == Vector2i(8, 8) and frame.get("pivot") == Vector2i(4, 4) and bool(frame.get("loop", false)))
		if texture != null:
			frames.append(texture.get_image().get_data())
	var splats: Array = []
	for i in CatapultArt.SPLAT_FRAMES + 1:
		var splat := CatapultArt.splat(i)
		splats.append(splat.resource_path if splat != null else "")
	expect(shot_art and frames.size() == 3 and frames[0] != frames[1] and frames[1] != frames[2] and frames[0] != frames[2]
		and PlaceholderArt.art(&"pumpkin_shot").is_empty() and PlaceholderArt.art(&"pumpkin_splat").is_empty()
		and CatapultArt.shot(3) == CatapultArt.shot(0) and _held(func() -> Object: return CatapultArt.shot(1))
		and splats == [CatapultArt.SPLAT_PATH % 0, CatapultArt.SPLAT_PATH % 1, CatapultArt.SPLAT_PATH % 2, CatapultArt.SPLAT_PATH % 3, ""]
		and not bool(PlaceholderArt.frame(CatapultArt.SPLAT_PATH % 0).get("loop", true))
		and CatapultArt.splat_pivot() == Vector2i(10, 14) and is_equal_approx(CatapultArt.splat_seconds(), 0.1),
		"the shot: A039's three 8x8 frames of a tumbling pumpkin, round and round; the splat: its four frames on (10,14), once, then gone",
		str(splats))
	var flight := int(row["flight_ticks"])
	expect(WorldView.arc_lift({"from": &"catapult", "left": flight}) == 0.0
		and WorldView.arc_lift({"from": &"catapult", "left": flight / 2}) == WorldView.PUMPKIN_ARC
		and WorldView.arc_lift({"from": &"catapult", "left": 0}) == 0.0,
		"a pumpkin rises on its arc from the throw, highest half way, and comes down on its cell")
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"catapult")
	bar.free()
	var order := Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	var before_autumn := 0
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		if GameData.SEASONS.find(GameData.defence_season(GameData.DEFENCES[id])) < 2:
			before_autumn += 1
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_catapult.png"
		and PlaceholderArt.art(&"icon_catapult").is_empty()
		and order.find(&"catapult") >= before_autumn,
		"the hotbar shows A045's catapult icon (task 0244), among autumn's, after spring's and summer's", str(order))
	var shots := FileAccess.get_file_as_string("res://src/tools/shot.gd")
	expect(shots.contains("[\"catapult\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A039-catapult.md").contains("Final geometry settled by game task 0227"),
		"shot.gd has a volley landing, and A039's table says the geometry this task settled")
	_completed += 1


## 0228 - the garlic braid. Hung on a post in autumn and walked over; the
## ground round it costs more to enter in the priced and the open field
## alike - one braid's worth where two overlap - so a route with a cheap way
## round bends round it, and the ones that come through walk at its speed, or
## a flare's if that is slower, never both. Fresh its first night, wilted its
## second, spent after, moved on at `begin_night` and touching the grid once
## when it changes; spent it does nothing and sells for nothing.
func _task_0228_garlic() -> void:
	# **The row, and its checks.**
	var row: Dictionary = GameData.DEFENCES[&"garlic_braid"]
	var cost := Building.materials_of(&"garlic_braid")
	expect(cost.size() == 2 and cost.has(GameData.GARLIC) and cost.has(GameData.WOOD) and Building.money_of(&"garlic_braid") > 0
		and int(cost[GameData.WOOD]) < int(cost[GameData.GARLIC])
		and GameData.defence_season(row) == &"autumn" and Building.walked_over(&"garlic_braid")
		and not Pathing.is_prey(&"garlic_braid") and not Traps.is_trap(&"garlic_braid")
		and not row.has("damage") and not row.has("path_cost") and not Sfx.TOWER_SOUNDS.has(&"garlic_braid")
		and int(row["repel_tiles"]) >= 1 and int(row["repel_tiles"]) <= 3
		and not GameData.DEFENCES.has(GameData.GARLIC),
		"a braid costs garlic, a little wood and money, is autumn's, is walked over - never prey, never a trap, no sound - and reaches 1-3 tiles; its id is not the crop's",
		str(row))
	var unrefused: Array = []
	for lever in [["repel_tiles", 0, "repels from no tiles"], ["repel_cost", 0, "or for nothing"],
			["repel_speed_percent", 100, "at 100% of their speed"], ["wilted_percent", 101, "keeps 101% of itself"]]:
		var broken := GameData.DEFENCES.duplicate(true)
		(broken[&"garlic_braid"] as Dictionary)[lever[0]] = lever[1]
		if not _says(GameData.check_defences(broken), lever[2]):
			unrefused.append(lever[0])
	var priced := GameData.DEFENCES.duplicate(true)
	(priced[&"garlic_braid"] as Dictionary)["path_cost"] = 4
	var worst := 0
	for ground in GameData.TERRAIN_COST:
		worst = maxi(worst, int(ground))
	var dearest := 0
	for table in [GameData.DEFENCES, GameData.BUILDINGS]:
		for id in GameData.sorted_names((table as Dictionary).keys()):
			dearest = maxi(dearest, int(((table as Dictionary)[id] as Dictionary).get("path_cost", 0)))
	var too_strong := GameData.DEFENCES.duplicate(true)
	(too_strong[&"garlic_braid"] as Dictionary)["repel_cost"] = GameData.WIDEST_STEP - worst - dearest + 1
	expect(unrefused.is_empty() and _says(GameData.check_defences(priced), "walked over and priced as a barrier")
		and _says(GameData.check_pathing(GameData.TERRAIN_COST, too_strong, GameData.BUILDINGS), "wider than WIDEST_STEP")
		and worst + dearest + int(row["repel_cost"]) <= GameData.WIDEST_STEP
		and GameData.validate().is_empty(),
		"no tiles, no cost, full speed and an over-full wilt are refused, and so is a priced braid and a garlic extra that would pass WIDEST_STEP on the worst step; the real tables pass",
		str(unrefused))

	# **The area: a price and a slow, one braid's worth.** A braid on bare
	# ground in the build step, and a second two tiles east whose area
	# overlaps it.
	var built: Dictionary = _garlic_build(22800)
	var state: Dictionary = built["state"]
	var spot: Vector2i = built["spot"]
	var reach := int(row["repel_tiles"])
	var extra := int(row["repel_cost"])
	var share := 100 - int(row["repel_speed_percent"])
	expect(Building.place(state, &"garlic_braid", spot + Vector2i(2, 0)), "a second braid two tiles east")
	Pathing.refresh(state)
	var wrong: Array = []
	for dy in range(-reach - 1, reach + 2):
		for dx in range(-reach - 1, reach + 4):
			var at := spot + Vector2i(dx, dy)
			var ground := Farm.cost_of_terrain(Farm.terrain_at(state, at))
			var within := absi(dy) <= reach and dx >= -reach and dx <= 2 + reach
			var want := ground + (extra if within else 0)
			var open: PackedInt32Array = state["open_cost"]
			if Pathing.entry_cost(state, at) != want or int(open[Grid.index(at)]) != want \
					or Pathing.repelled(state, at) != (share if within else 0):
				wrong.append(at)
	expect(wrong.is_empty(),
		"every cell within reach of a braid costs its extra more to enter, priced and open alike, and slows by its share - once where two overlap - and the ring outside is plain ground",
		str(wrong.slice(0, 4)))

	# **A route with a cheap way round avoids it.** The east road to the
	# house, and a braid on it: the build step's preview bends round its
	# area, and once it is hung the road the wave walks is that preview.
	var road_farm := State.create(22801)
	SuiteKit.open_arsenal(road_farm, [&"garlic_braid"])
	Resources.gain(road_farm, {GameData.GARLIC: 20, GameData.WOOD: 20, GameData.MONEY: 100})
	NightRoad.into_build(road_farm)
	Pathing.refresh(road_farm)
	var from: Vector2i = Enemies.spawn_cells(road_farm, int(Calendar.open_sides(Phases.night_ahead(road_farm))[0]))[0]
	var plain := _walked_from(road_farm, from)
	var hung: Vector2i = plain[mini(12, plain.size() - 1)]
	var bent := Pathing.routes_if_blocked(road_farm, hung, [from], 400, &"garlic_braid")
	expect(Building.place(road_farm, &"garlic_braid", hung), "a braid hung on the road", str(hung))
	Pathing.refresh(road_farm)
	var walked := _walked_from(road_farm, from)
	var crossed := 0
	for cell in walked:
		if Grid.chebyshev(cell as Vector2i, hung) <= reach:
			crossed += 1
	print("  the east road: %d steps straight, %d round a braid at %s" % [plain.size(), walked.size(), str(hung)])
	expect(plain.has(hung) and crossed == 0 and walked.size() > plain.size()
		and walked.slice(1) == bent and Farm.occupant(road_farm, walked.back()).get("id", &"") == &"house",
		"a route with a cheap way round bends round the braid's whole area to the house - the road the build step's preview drew",
		"%d of %d cells in its area" % [crossed, walked.size()])

	# **The ones that come through walk at its speed** - or a flare's if
	# that is slower, never both. Walkers on the braid, held to its area for
	# the ticks a tile takes there; one on plain ground beside them.
	var slow_farm: Dictionary = _garlic_build(22802)
	var crowd: Dictionary = slow_farm["state"]
	var braid: Vector2i = slow_farm["spot"]
	NightRoad.through_build(crowd)
	NightRoad.park(crowd)
	Enemies.withdraw(crowd)
	var walker: Dictionary = GameData.ENEMIES[&"walker"]
	var per_tile := int(walker["ticks_per_tile"])
	var garlic_ticks := Ability.slowed_ticks(per_tile, int(row["repel_speed_percent"]))
	var flare_ticks := Ability.slowed_ticks(per_tile)
	var through: Array = []
	for _i in 4:
		through.append(Entities.spawn(crowd, &"walker", braid))
	var flared := Entities.spawn(crowd, &"walker", braid)
	Entities.get_one(crowd, flared)["slow"] = 100000
	var plain_one := Entities.spawn(crowd, &"walker", braid + Vector2i(0, reach + 2))
	var moved := {}
	var last := {}
	for id in through + [flared, plain_one]:
		moved[id] = 0
		last[id] = Entities.position(crowd, id)
	for tick in maxi(garlic_ticks, flare_ticks):
		Enemies.tick(crowd)
		for id in moved:
			var now := Entities.position(crowd, id)
			var step := absi(now.x - (last[id] as Vector2i).x) + absi(now.y - (last[id] as Vector2i).y)
			if tick < garlic_ticks or id == flared:
				moved[id] = int(moved[id]) + step
			last[id] = now
	var crossing: Array = []
	for id in through:
		crossing.append(int(moved[id]))
	print("  through the garlic: %s units in %d ticks; flared in it %d in %d; on plain ground %d"
		% [str(crossing), garlic_ticks, int(moved[flared]), flare_ticks, int(moved[plain_one])])
	var all_one := true
	for units in crossing:
		all_one = all_one and int(units) == Player.SUBTILE
	expect(all_one and garlic_ticks > per_tile,
		"a crowd forced through walks a tile in %d ticks, at the lever's %d%% of its speed" % [garlic_ticks, int(row["repel_speed_percent"])],
		str(crossing))
	expect(int(moved[flared]) == Player.SUBTILE and flare_ticks > garlic_ticks
		and int(moved[plain_one]) > Player.SUBTILE,
		"flared inside it, the stronger slow - the flare's - and never both; on plain ground a walker goes further",
		"%d and %d" % [int(moved[flared]), int(moved[plain_one])])

	# **It wears**: fresh its first night, wilted its second, spent after -
	# moved on at `begin_night` through the road into each night, never a
	# played one - and the grid touched once on the nights it changes.
	var worn: Dictionary = _garlic_build(22803)
	var farm: Dictionary = worn["state"]
	var post: Vector2i = worn["spot"]
	var seen: Array = []
	for night in 4:
		if night > 0:
			Phases.enter_result(farm, true)
			Phases.begin_day(farm)
			NightRoad.into_build(farm)
		var version := int(farm["grid_version"])
		NightRoad.through_build(farm)
		Pathing.refresh(farm)
		var on := Farm.occupant(farm, post)
		seen.append([String(Garlic.state_of(on)), int(farm["grid_version"]) - version,
			Pathing.entry_cost(farm, post) - Farm.cost_of_terrain(Farm.terrain_at(farm, post)),
			Pathing.repelled(farm, post)])
	var wilted := int(row["wilted_percent"])
	expect(seen == [["fresh", 0, extra, share], ["wilted", 1, extra * wilted / 100, share * wilted / 100],
		["spent", 1, 0, 0], ["spent", 0, 0, 0]],
		"fresh its first night, wilted to %d%% its second, spent after - the grid touched on the two nights it changed and no other" % wilted,
		str(seen))
	var spent := Farm.occupant(farm, post)
	expect(Building.refund_for(farm, post).is_empty() and not spent.is_empty()
		and WorldView.garlic_art(spent) == &"garlic_braid_spent"
		and (farm["repel"] as PackedByteArray).is_empty(),
		"spent it stays, drawn spent, does nothing, and sells for nothing - its garlic is used up")
	var late := State.create(22804)
	SuiteKit.open_arsenal(late, [&"garlic_braid"])
	Resources.gain(late, {GameData.GARLIC: 20, GameData.WOOD: 20, GameData.MONEY: 100})
	NightRoad.to_night(late)
	NightRoad.park(late)
	var late_spot := _open_square(late, 4, &"garlic_braid")
	expect(Building.place(late, &"garlic_braid", late_spot)
		and Garlic.state_of(Farm.occupant(late, late_spot)) == Garlic.FRESH
		and int(Farm.occupant(late, late_spot)["nights"]) == 1,
		"hung mid-wave it is in its first night already: wilted at the next")

	# **The words, the placeholder road and the preview.**
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"garlic_braid")
	I18n.use("en")
	expect(Names.KEYS.get(&"garlic_braid") == &"DEF_GARLIC_BRAID"
		and (said["en"] as String).contains("GARLIC BRAID")
		and (said["en"] as String).contains("round %d tiles of it, at %d%% speed" % [reach, int(row["repel_speed_percent"])])
		and (said["en"] as String).contains("to %d%%" % wilted)
		and (said["pt_BR"] as String).contains("RÉSTIA DE ALHO") and (said["pt_BR"] as String).contains("%d ladrilhos" % reach),
		"its name, its area, its slow and its wear, in both languages", str(said))
	# **A040's art since task 0239**: three states on the barricade's canvas
	# and pivot, each its own picture, picked by the nights the braid has seen.
	var drawn: Array = []
	var pictures := {}
	for name in GarlicArt.STATES:
		var path := GarlicArt.path_of(name)
		var frame := PlaceholderArt.frame(path)
		var texture := GarlicArt.texture(name)
		if texture == null or texture.resource_path != path or not RasterArt.FRAMES.has(path) \
				or PlaceholderArt.is_drawn(path) or not PlaceholderArt.art(name).is_empty() \
				or frame.get("canvas") != Vector2i(16, 24) or frame.get("pivot") != Vector2i(8, 20):
			drawn.append(name)
		elif texture != null:
			pictures[texture.get_image().get_data()] = true
	var aged: Array = []
	for nights in [1, 2, 3]:
		aged.append(WorldView.garlic_art({"id": &"garlic_braid", "nights": nights}))
	if pictures.size() != 3 or aged != GarlicArt.STATES:
		drawn.append("%d pictures, aged %s" % [pictures.size(), str(aged)])
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"garlic_braid")
	bar.free()
	var mode := BuildMode.new()
	var previews := mode._blocks_the_way(&"garlic_braid") and mode._blocks_the_way(&"wall") and not mode._blocks_the_way(&"gun_tower")
	mode.free()
	expect(drawn.is_empty() and icon != null and icon.resource_path == "res://sprites/ui/icon_garlic_braid.png" and previews
		and not WorldView.lies_flat(&"garlic_braid") and WorldView.lies_flat(&"zombie_bait"),
		"A040's art at 16x24 on (8,20), fresh, wilted and spent apart by its nights; standing among the feet that pass, not under them; the hotbar's icon; and a braid in hand draws the route as a wall does",
		str(drawn))
	var perf_tool := FileAccess.get_file_as_string("res://tools/perf.py")
	var perf_check := FileAccess.get_file_as_string("res://src/tools/perf_check.gd")
	var shots := FileAccess.get_file_as_string("res://src/tools/shot.gd")
	expect(perf_tool.contains("(\"garlic_refresh\", PATH_BUDGET_US)") and perf_check.contains("const GARLIC_BRAIDS := 10")
		and shots.contains("[\"garlic\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A040-garlic-braid.md").contains("Final geometry settled by game task 0228"),
		"perf.py holds a rebuild with ten braids to the path's budget, shot.gd has the route bending round one, and A040's table says the geometry this task settled")
	_completed += 1


## 0229 - the searchlight. A winter lamp on a mast, powered and never
## shooting; light as a rule in one place (`Light`): a searchlight's square,
## the porch, the flare's area while it burns and the cell of whatever burns.
## A tower standing in light reaches a tile further; a farm short of power
## lights a tile less, never none; the cache of what stands still rebuilds
## when a searchlight goes up or comes down; one upgrade, to a wider light.
func _task_0229_light() -> void:
	# **The row, and its checks.**
	var row: Dictionary = GameData.DEFENCES[&"searchlight"]
	var cost := Building.materials_of(&"searchlight")
	var tiles := int(row["light_tiles"])
	var steps: Array = GameData.TOWER_LEVELS[&"searchlight"]
	var wider := int(((steps[0] as Dictionary)["gives"] as Dictionary).get("light_tiles", 0)) if steps.size() == 1 else 0
	expect(cost.size() == 2 and cost.has(GameData.IRON) and cost.has(GameData.COPPER) and Building.money_of(&"searchlight") > 0
		and not row.has("reload_ticks") and not row.has("damage") and int(row["energy_draw"]) > 0
		and tiles >= 3 and tiles <= 6 and GameData.defence_season(row) == &"winter"
		and not Sfx.TOWER_SOUNDS.has(&"searchlight") and Pathing.is_prey(&"searchlight") and wider > tiles,
		"a searchlight costs iron, copper and money, draws power, lights 3-6 tiles, shoots nothing, is winter's, is hunted by breakers, and has one upgrade - a wider light",
		str(row))
	var unlit := GameData.DEFENCES.duplicate(true)
	(unlit[&"searchlight"] as Dictionary)["light_tiles"] = 0
	expect(_says(GameData.check_defences(unlit), "lights no tiles") and GameData.validate().is_empty()
		and FileAccess.get_file_as_string("res://src/core/game_data.gd").contains(
			"\"light\": [PORCH_LIGHT_TILES, LIGHT_REACH_BONUS, LIGHT_SHORT_SHRINK]"),
		"a lamp lighting no tiles is refused, the real tables pass, and the porch's radius, the reach in light and a short farm's shrink are in the data's digest")

	# **Each source of light.** The porch, on a farm with nothing else.
	var farm := State.create(22900)
	SuiteKit.open_arsenal(farm, [&"searchlight"])
	Resources.gain(farm, {GameData.IRON: 200, GameData.COPPER: 200, GameData.WOOD: 200, GameData.MONEY: 500})
	var porch := House.porch(farm)
	var expected := {}
	_lit_square(expected, porch, GameData.PORCH_LIGHT_TILES)
	expect(Light.lit_cells(farm) == _sorted_cells(expected) and Light.is_lit(farm, porch)
		and not Light.is_lit(farm, porch + Vector2i(GameData.PORCH_LIGHT_TILES + 1, 0)),
		"the porch lights %d tiles round the door, and no further" % GameData.PORCH_LIGHT_TILES)
	# A searchlight hung on open ground, in the build step.
	NightRoad.into_build(farm)
	var lamp := _open_square(farm, tiles + 2, &"searchlight")
	var before: Array = (farm["light_for"] as Array).duplicate()
	expect(Building.place(farm, &"searchlight", lamp), "a searchlight goes up", str(lamp))
	_lit_square(expected, lamp, tiles)
	expect(Light.is_lit(farm, lamp + Vector2i(tiles, -tiles)) and Light.lit_cells(farm) == _sorted_cells(expected)
		and (farm["light_for"] as Array) != before
		and int((farm["light_for"] as Array)[0]) == int(farm["grid_version"]),
		"a searchlight lights the square %d round it and the porch still lights its own - the cache rebuilt for the farm it went up on" % tiles)
	# The flare while it burns, and the cell of a burning zombie.
	NightRoad.through_build(farm)
	NightRoad.park(farm)
	Enemies.withdraw(farm)
	var flare_at := _a_dark_cell(farm, lamp, 12, int(GameData.ABILITY["radius_tiles"]) + 1)
	(farm["ability"] as Dictionary)["cooldown"] = 0
	(farm["intent"] as Dictionary)["ability_cell"] = [flare_at.x, flare_at.y]
	var radius := int(GameData.ABILITY["radius_tiles"])
	var flared := (Ability.use(farm, Ability.FLARE, Ability.aim_of(farm)) and Light.is_lit(farm, flare_at + Vector2i(radius, radius))
		and not Light.is_lit(farm, flare_at + Vector2i(radius + 1, 0)))
	for _i in int(GameData.ABILITY["flare_ticks"]):
		Ability.tick(farm)
	expect(flared and not Light.is_lit(farm, flare_at),
		"the flare lights its %d tiles while it burns, and the dark comes back when it is out" % radius)
	var torch := _a_dark_cell(farm, lamp, 20, 1)
	var burner := Entities.spawn(farm, &"walker", torch)
	var dark_before := Light.is_lit(farm, torch)
	Combat.set_alight(farm, burner, 1, 2 * GameData.SECONDS)
	expect(not dark_before and Light.is_lit(farm, torch) and not Light.is_lit(farm, torch + Vector2i(1, 0)),
		"a burning zombie lights the cell it burns on, and that one only")
	Enemies.withdraw(farm)

	# **A tower in light reaches a tile further.** A gun tower beside the
	# lamp and one in the dark, a walker one tile past the dark one's reach
	# from each.
	var gun: Dictionary = GameData.DEFENCES[&"gun_tower"]
	var lit_post := lamp + Vector2i(0, 1)
	var dark_post := _a_dark_cell(farm, lamp, 22)
	var plain := Towers.reach_of(farm, gun, dark_post)
	var near := Entities.spawn(farm, &"walker", lit_post + Vector2i(plain + 1, 0))
	var far := Entities.spawn(farm, &"walker", dark_post + Vector2i(plain + 1, 0))
	expect(Towers.reach_of(farm, gun, lit_post) == plain + GameData.LIGHT_REACH_BONUS
		and Towers.acquire_for(farm, lit_post, gun) == near and Towers.acquire_nearby_for(farm, lit_post, gun) == near
		and Towers.acquire_for(farm, dark_post, gun) == 0 and Towers.acquire_nearby_for(farm, dark_post, gun) == 0,
		"a gun tower in light acquires one tile further than one in the dark, by the whole farm's look and the crowd's squares alike",
		"%d and %d" % [Towers.reach_of(farm, gun, lit_post), plain])
	Enemies.withdraw(farm)

	# **A farm short of power lights a tile less, never none**: an auto
	# crossbow beside the lamp, and the power worked out.
	var crossbow := _a_dark_cell(farm, lamp, 8)
	expect(Building.place(farm, &"auto_crossbow", crossbow), "an auto crossbow goes up", str(crossbow))
	Power.tick(farm, false)
	var short_tiles := Light.lamp_tiles(farm, lamp)
	var shrunk := {}
	_lit_square(shrunk, porch, GameData.PORCH_LIGHT_TILES)
	_lit_square(shrunk, lamp, short_tiles)
	expect(Power.is_short(farm) and short_tiles == maxi(tiles - GameData.LIGHT_SHORT_SHRINK, 1)
		and Light.is_lit(farm, lamp + Vector2i(short_tiles, 0)) and Light.lit_cells(farm) == _sorted_cells(shrunk)
		and not WorldView.lamp_at_full(farm),
		"short of power - %d%% - it lights %d tiles, not %d and not none, and its lens shows dark" % [Power.percent(farm), short_tiles, tiles],
		str(short_tiles))
	Building.sell(farm, crossbow)
	Power.tick(farm, false)
	expect(not Power.is_short(farm) and Light.lamp_tiles(farm, lamp) == tiles and WorldView.lamp_at_full(farm),
		"and its light comes back with the power")

	# **The cache rebuilds when a searchlight goes up or comes down.**
	var second := _a_dark_cell(farm, lamp, 16)
	var stamp: Array = (farm["light_for"] as Array).duplicate()
	var dark_then := Light.is_lit(farm, second)
	expect(Building.place(farm, &"searchlight", second), "a second searchlight goes up", str(second))
	var lit_now := Light.is_lit(farm, second)
	var stamp_up: Array = (farm["light_for"] as Array).duplicate()
	Building.sell(farm, second)
	expect(not dark_then and lit_now and stamp_up != stamp and not Light.is_lit(farm, second)
		and (farm["light_for"] as Array) != stamp_up,
		"put up, its cells are lit at once; taken down, they are dark again - the cache rebuilt both times")

	# **One upgrade, to a wider light**, and no further.
	(farm["tech_owned"] as Array).append(&"true sights")
	expect(Building.upgrade(farm, lamp) and Light.lamp_tiles(farm, lamp) == wider
		and Light.is_lit(farm, lamp + Vector2i(wider, 0))
		and Building.why_not_upgrade(farm, lamp) == [&"WHY_LAST_LEVEL"],
		"upgraded it lights %d tiles, and a third level is refused" % wider)

	# **The words and the placeholder road.**
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"searchlight")
	I18n.use("en")
	expect(Names.KEYS.get(&"searchlight") == &"DEF_SEARCHLIGHT"
		and (said["en"] as String).contains("SEARCHLIGHT")
		and (said["en"] as String).contains("lights %d tiles round it, and towers in light reach %d further" % [tiles, GameData.LIGHT_REACH_BONUS])
		and (said["pt_BR"] as String).contains("HOLOFOTE") and (said["pt_BR"] as String).contains("ilumina %d ladrilhos" % tiles),
		"its name, its light and what light gives a tower, in both languages", str(said))
	# **A041's art since task 0240**: an authored tower at each level and
	# state, its lens - where the beam leaves - on all but the wreck, and no
	# weapon outlet.
	var road: Array = []
	for level in ["", "_2"]:
		for state_name in ["", "_hurt", "_fire", "_wreck"]:
			var name := StringName("searchlight%s%s" % [level, state_name])
			var path := WorldView.BUILDING_DIR + str(name) + ".png"
			var frame: Dictionary = RasterArt.FRAMES.get(path, {})
			if frame.get("canvas") != Vector2i(32, 48) or frame.get("pivot") != Vector2i(16, 44) \
					or not bool(frame.get("tower", false)) or frame.has("light") != (state_name != "_wreck") \
					or frame.has("muzzle") or not ResourceLoader.exists(path) or PlaceholderArt.is_drawn(path) \
					or not PlaceholderArt.art(name).is_empty():
				road.append(name)
	var view := WorldView.new()
	view._state = farm
	var shown := [view._worn(&"searchlight", Farm.occupant(farm, lamp))]
	farm["phase"] = Phases.DAY
	shown.append(view._worn(&"searchlight", Farm.occupant(farm, lamp)))
	farm["phase"] = Phases.NIGHT
	view.free()
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"searchlight")
	bar.free()
	expect(road.is_empty() and WorldView.authored_tower(&"searchlight") and not WorldView.stand_in_tower(&"searchlight")
		and shown == [&"searchlight_2_fire", &"searchlight_2"]
		and icon != null and icon.resource_path == "res://sprites/ui/icon_searchlight.png",
		"A041's art: an authored tower at 32x48 on (16,44), its lens a light point on all but the wreck and no muzzle; lit at night at full power, dark by day; the hotbar's icon",
		"%s %s" % [str(road), str(shown)])
	expect(FileAccess.get_file_as_string("res://src/tools/shot.gd").contains("[\"searchlight\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A041-searchlight.md").contains("Final geometry settled by game task 0229"),
		"shot.gd has a lit and an unlit tower line, and A041's table says the geometry this task settled")
	_completed += 1

## 0230 - the electric fence. A winter barrier built as the wooden fence is -
## priced by the field and joined to its neighbours - that stuns whatever
## bites it: the bite lands, then the biter stands, neither walking nor
## biting, for the fence's `stun_ticks`; a boss for its share, a farm short of
## power for less and never none. The stun is a count on the entity that any
## source may set (0233's bell will). Drawn in code until A042.
func _task_0230_electric_fence() -> void:
	# **The row, and its checks.**
	var row: Dictionary = GameData.DEFENCES[&"electric_fence"]
	var cost := Building.materials_of(&"electric_fence")
	var stun := int(row["stun_ticks"])
	var share := int(row["boss_stun_percent"])
	expect(cost.size() == 2 and cost.has(GameData.COPPER) and cost.has(GameData.WOOD) and Building.money_of(&"electric_fence") > 0
		and int(row["path_cost"]) > 0 and int(row["hp"]) > 0 and int(row["energy_draw"]) > 0
		and stun >= GameData.SECONDS and stun <= 3 * GameData.SECONDS and share >= 0 and share < 100
		and not row.has("damage") and not row.has("reload_ticks") and GameData.defence_season(row) == &"winter"
		and not Sfx.TOWER_SOUNDS.has(&"electric_fence") and not Pathing.is_prey(&"electric_fence"),
		"an electric fence costs copper, wood and money, is a barrier with hit points, draws power, stuns for 1-3 seconds and a boss for less, does no damage and makes no tower sound, is winter's, and no breaker hunts it",
		str(row))
	var dead := GameData.DEFENCES.duplicate(true)
	(dead[&"electric_fence"] as Dictionary)["stun_ticks"] = 0
	var greedy := GameData.DEFENCES.duplicate(true)
	(greedy[&"electric_fence"] as Dictionary)["boss_stun_percent"] = 150
	var wide := GameData.DEFENCES.duplicate(true)
	(wide[&"electric_fence"] as Dictionary)["path_cost"] = GameData.WIDEST_STEP
	expect(_says(GameData.check_defences(dead), "stuns for no time at all")
		and _says(GameData.check_defences(greedy), "stuns a boss for 150%")
		and _says(GameData.check_pathing(GameData.TERRAIN_COST, wide, GameData.BUILDINGS), "'electric_fence'")
		and GameData.validate().is_empty(),
		"a stun of no ticks is refused, so is a boss's share past the whole, and a path cost past WIDEST_STEP; the real tables pass")

	# **The field prices it like a barrier**: its ground and its path cost in
	# the priced field, a wall in the runners' open one, a thing to break
	# through - not prey.
	var farm := State.create(23000)
	SuiteKit.open_arsenal(farm, [&"electric_fence"])
	Resources.gain(farm, {GameData.COPPER: 200, GameData.WOOD: 200, GameData.MONEY: 500})
	NightRoad.into_build(farm)
	var spot := _open_square(farm, 4, &"electric_fence")
	expect(Building.place(farm, &"electric_fence", spot), "an electric fence goes down in the build step", str(spot))
	Pathing.refresh(farm)
	var ground := Farm.cost_of_terrain(int((farm["terrain"] as PackedByteArray)[Grid.index(spot)]))
	expect(Pathing.entry_cost(farm, spot) == ground + int(row["path_cost"])
		and int((farm["open_cost"] as PackedInt32Array)[Grid.index(spot)]) == Pathing.IMPASSABLE
		and Pathing.breaks_through(farm, spot),
		"the field prices it like a barrier: %d for its ground and %d to break through, and a wall to the runners" % [ground, int(row["path_cost"])],
		str(Pathing.entry_cost(farm, spot)))

	# **A walker that bites it stands still for the stun, then bites again.**
	# Shut in a ring of each kind of fence, the ticks between its first two
	# bites: a wooden fence's are the bite's own rhythm, an electric fence's
	# that and the stun.
	var wooden := _ring_bites(23001, &"fence", false)
	var wired := _ring_bites(23001, &"electric_fence", false)
	var wired_state: Dictionary = wired["state"]
	expect(Enemies.shock_ticks(wired_state, &"walker", &"electric_fence") == stun
		and int(wooden["gap"]) > 0 and int(wired["gap"]) == int(wooden["gap"]) + stun
		and int(wired["stunned"]) == stun and bool(wired["stood"]) and int(wooden["stunned"]) == 0,
		"a walker that bites an electric fence stands stunned and still for %d ticks, then bites again: %d ticks between bites, a wooden fence's %d"
			% [stun, int(wired["gap"]), int(wooden["gap"])],
		"%d/%d stunned %d" % [int(wired["gap"]), int(wooden["gap"]), int(wired["stunned"])])

	# **A farm short of power stuns for less, never none**: an auto crossbow
	# beyond the ring draws more than the farm has.
	var short := _ring_bites(23001, &"electric_fence", true)
	var percent := int(short["percent"])
	var weak := stun * percent / 100
	expect(percent < 100 and weak > 0 and weak < stun and int(short["gap"]) == int(wooden["gap"]) + weak
		and int(short["stunned"]) == weak,
		"short of power - %d%% - the stun is %d ticks, not %d and not none, and the walker bites again that much sooner" % [percent, weak, stun],
		"%d stunned %d" % [int(short["gap"]), int(short["stunned"])])

	# **A boss stands for its share**, even on the least powered farm; a
	# wooden fence and a wall stun nobody.
	var dim := State.create(23002)
	(dim["power"] as Dictionary)["percent"] = GameData.UNPOWERED_PERCENT
	var boss := stun * share / 100
	expect(Enemies.shock_ticks(farm, &"giant", &"electric_fence") == boss
		and Enemies.shock_ticks(dim, &"giant", &"electric_fence") == maxi(boss * GameData.UNPOWERED_PERCENT / 100, 1)
		and Enemies.shock_ticks(dim, &"walker", &"electric_fence") == stun * GameData.UNPOWERED_PERCENT / 100
		and Enemies.shock_ticks(farm, &"walker", &"fence") == 0 and Enemies.shock_ticks(farm, &"walker", &"wall") == 0,
		"a boss stands %d ticks of it, and on the least powered farm %d - never none; a wooden fence and a wall stun nobody"
			% [boss, Enemies.shock_ticks(dim, &"giant", &"electric_fence")])

	# **The count is any source's** (0233's bell will set it): a walker in the
	# open, stunned for ten ticks - a shorter stun after keeps the longer -
	# stands where it is for exactly those and walks on after, slowly; a
	# flare's slow runs down while it stands.
	var open := State.create(23003)
	Resources.gain(open, {GameData.STRAW: 200, GameData.WOOD: 200})
	NightRoad.to_night(open)
	NightRoad.park(open)
	Enemies.withdraw(open)
	var stander := Entities.spawn(open, &"walker", _open_square(open, 4))
	Enemies.stun(open, stander, 10)
	Enemies.stun(open, stander, 4)
	(Entities.get_one(open, stander) as Dictionary)["slow"] = 15
	var at: Array = (Entities.get_one(open, stander)["pos"] as Array).duplicate()
	var held := 0
	for _i in 10:
		Enemies.tick(open)
		if Entities.get_one(open, stander)["pos"] == at:
			held += 1
	var stood_out := not Enemies.is_stunned(open, stander)
	var slowed := int(Entities.get_one(open, stander).get("slow", 0))
	for _i in 3:
		Enemies.tick(open)
	expect(held == 10 and stood_out and slowed == 5 and Entities.get_one(open, stander)["pos"] != at,
		"stunned for ten ticks by any source, it stands for those ten - a shorter stun after keeps the longer - its flare slow running down, and walks on the next",
		"%d held, slow %d" % [held, slowed])

	# **The words.**
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = Describe.defence(&"electric_fence")
	I18n.use("en")
	var seconds := "%.1fs" % (float(stun) / float(GameData.TICK_HZ))
	expect(Names.KEYS.get(&"electric_fence") == &"DEF_ELECTRIC_FENCE"
		and (said["en"] as String).contains("ELECTRIC FENCE")
		and (said["en"] as String).contains("whatever bites it stands stunned for %s, a boss for %d%% of that" % [seconds, share])
		and (said["en"] as String).contains("for less when power runs short")
		and (said["en"] as String).contains("things walk round it if they can")
		and (said["pt_BR"] as String).contains("CERCA EL") and (said["pt_BR"] as String).contains("atordoado por %s" % seconds),
		"its name, its stun, a boss's share and a short farm's, and that it blocks, in both languages", str(said))

	# **The joins**: it meets its own kind, the wooden fence and the wall -
	# which meet it back - and nothing else.
	var joined := State.create(23004)
	SuiteKit.open_arsenal(joined, [&"electric_fence"])
	Resources.gain(joined, {GameData.COPPER: 20, GameData.WOOD: 20, GameData.MONEY: 100})
	NightRoad.into_build(joined)
	var centre := _open_square(joined, 2, &"electric_fence")
	Farm.place(joined, centre, {"id": &"electric_fence", "hp": 40})
	Farm.place(joined, centre + Vector2i(0, -1), {"id": &"decoy", "hp": 200})
	Farm.place(joined, centre + Vector2i(1, 0), {"id": &"fence", "hp": 30})
	Farm.place(joined, centre + Vector2i(0, 1), {"id": &"wall", "hp": 120})
	Farm.place(joined, centre + Vector2i(-1, 0), {"id": &"electric_fence", "hp": 40})
	var mask := WorldView.barrier_mask(joined, centre)
	var wood_mask := WorldView.barrier_mask(joined, centre + Vector2i(1, 0))
	var wall_mask := WorldView.barrier_mask(joined, centre + Vector2i(0, 1))
	expect(mask == 14 and (wood_mask & 8) != 0 and (wall_mask & 1) != 0 and WorldView.connected_barrier(&"electric_fence"),
		"it joins the wooden fence east, the wall south and its own kind west, not the decoy north, and the fence and the wall join it back",
		"%d %d %d" % [mask, wood_mask, wall_mask])

	# **A042's art since task 0241**: the 32 masks composed by the importer
	# and the wreck, at 16x32 on (8,28), every standing one `connected`, with
	# nothing of 0120's road left.
	var road: Array = []
	for name in ElectricFenceArt.names():
		var path := ElectricFenceArt.path_of(name)
		var frame: Dictionary = RasterArt.FRAMES.get(path, {})
		var texture := ElectricFenceArt.texture(name)
		if (frame.get("canvas") != Vector2i(16, 32) or frame.get("pivot") != Vector2i(8, 28)
				or PlaceholderArt.is_drawn(path) or not PlaceholderArt.art(name).is_empty()
				or bool(frame.get("connected", false)) == (name == ElectricFenceArt.WRECK)
				or texture == null or texture.resource_path != path):
			road.append(name)
	expect(ElectricFenceArt.names().size() == 33 and road.is_empty() and ElectricFenceArt.texture(&"fence") == null
		and ElectricFenceArt.texture(&"decoy") == null,
		"the 32 masks and the wreck are A042's art at 16x32 on (8,28), every standing one connected", str(road))

	# **Each mask's arms match its bits** - the west column, the east column,
	# above the post's cap, below its foot - and every hurt one's alpha
	# differs from the whole one's, the break showing past the post.
	var arms: Array = []
	for hurt in [false, true]:
		for m in 16:
			var name := ElectricFenceArt.name_of(m, hurt)
			var image := _art_image(ElectricFenceArt.path_of(name))
			# North is whatever rises above the post's own top (A042's post
			# stands taller than 0230's drawing), as check_barrier_art asks.
			var post_top := _art_image("res://sprites/buildings/modules/electric_fence_post%s.png" % ("_hurt" if hurt else "")).get_used_rect().position.y
			var seen := [_any_opaque(image, Rect2i(0, 12, 1, 8)), _any_opaque(image, Rect2i(15, 12, 1, 8)),
				image.get_used_rect().position.y < post_top, _any_opaque(image, Rect2i(0, 20, 16, 12))]
			if image.get_size() != Vector2i(16, 32) or seen != [(m & 8) != 0, (m & 2) != 0, (m & 1) != 0, (m & 4) != 0]:
				arms.append(name)
			if hurt and _alpha_apart(image, _art_image(ElectricFenceArt.path_of(ElectricFenceArt.name_of(m, false)))) < 3:
				arms.append("%s as whole" % name)
	expect(arms.is_empty(),
		"every mask's arms match its bits - west, east, above the post, below its foot - and every hurt one differs from its whole one",
		str(arms))
	var pile := _art_image(ElectricFenceArt.path_of(ElectricFenceArt.WRECK)).get_used_rect()
	var wood := _art_image("res://sprites/buildings/fence_join_8.png")
	var straight := _art_image(ElectricFenceArt.path_of(ElectricFenceArt.name_of(10, false)))
	var seam := 0
	for y in 32:
		if straight.get_pixel(15, y).a > 0.0 and wood.get_pixel(0, y).a > 0.0:
			seam += 1
	expect(pile.size.y <= 8 and pile.end.y == 28 and pile.size.x <= 15 and seam >= 2,
		"the wreck is a low pile on the cell's ground line, and a straight run meets the wooden fence's on %d rows" % seam,
		"%s %d" % [str(pile), seam])

	# **The zap**: A042's three 12x12 frames round (6,6), a 0.065 s one-shot.
	var zaps := true
	for i in ElectricFenceArt.ZAP_FRAMES:
		var frame := PlaceholderArt.frame(ElectricFenceArt.ZAP_PATH % i)
		var texture := ElectricFenceArt.zap(i)
		zaps = (zaps and texture != null and texture.resource_path == ElectricFenceArt.ZAP_PATH % i
			and RasterArt.FRAMES.has(ElectricFenceArt.ZAP_PATH % i) and not bool(frame.get("loop", true))
			and frame.get("canvas") == Vector2i(12, 12))
	expect(zaps and ElectricFenceArt.zap(3) == null and PlaceholderArt.art(&"zap").is_empty()
		and is_equal_approx(ElectricFenceArt.zap_seconds(), 0.065) and ElectricFenceArt.zap_pivot() == Vector2i(6, 6),
		"the zap: A042's three 12x12 frames round (6,6), a 0.065 s one-shot")

	# **The view**: a fresh stun is a zap half way to the wire it bit, at the
	# wires' height; the stunned stand cold blue, the hurt cue first.
	var walker := int(wired["walker"])
	var one := Entities.get_one(wired_state, walker)
	var bit := Grid.cell(int(one["chewing"]))
	var here := Entities.cell_of(wired_state, walker)
	var expected_zap := ((Vector2(here) + Vector2(bit)) * 0.5 + Vector2(0.5, 1.0)) * float(GameData.TILE_SIZE) \
		- Vector2(0.0, WorldView.ZAP_LIFT)
	var tints := [WorldView.actor_tint(wired_state, one)]
	one["hurt"] = 2
	tints.append(WorldView.actor_tint(wired_state, one))
	one["hurt"] = 0
	one["stun"] = 0
	tints.append(WorldView.actor_tint(wired_state, one))
	one["stun"] = stun
	expect(WorldView.fresh_stuns(wired_state, {}) == [walker] and WorldView.fresh_stuns(wired_state, {walker: stun}).is_empty()
		and WorldView.fresh_stuns(wired_state, {walker: 3}) == [walker]
		and WorldView.zap_point(wired_state, one).is_equal_approx(expected_zap)
		and tints == [WorldView.STUNNED_TINT, Color(1.25, 1.12, 1.12), Color(1, 1, 1)],
		"a fresh stun plays a zap half way to the wire it bit, %d px up; the stunned stand cold blue, the hurt cue first" % int(WorldView.ZAP_LIFT),
		"%s %s" % [str(WorldView.zap_point(wired_state, one)), str(tints)])

	# **The hotbar**: a straight run in its box, winter's, before the lamp.
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"electric_fence")
	bar.free()
	var order := Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_electric_fence.png"
		and order.find(&"electric_fence") >= 0 and order.find(&"electric_fence") == order.find(&"searchlight") - 1,
		"the hotbar shows A045's electric fence icon (task 0244), winter's first, before the searchlight", str(order))
	expect(FileAccess.get_file_as_string("res://src/tools/shot.gd").contains("[\"electric_fence\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A042-electric-fence.md").contains("Final geometry settled by game task 0230"),
		"shot.gd has a joined run of electric fence, and A042's table says the geometry this task settled")
	_completed += 1


## A walker shut in a ring of `id` on open ground in a parked night - the farm
## `short` of power by an auto crossbow beyond the ring, or not - ticked until
## it has bitten twice: the ticks between the two bites, how many ticks from
## the first it stood stunned, whether it stood exactly where it was, the
## farm's power and the walker (task 0230).
func _ring_bites(seed_value: int, id: StringName, short: bool) -> Dictionary:
	var state := State.create(seed_value)
	SuiteKit.open_arsenal(state, [id])
	Resources.gain(state, {GameData.COPPER: 200, GameData.WOOD: 200, GameData.IRON: 200,
		GameData.MONEY: 500})
	NightRoad.into_build(state)
	var spot := _open_square(state, 4, id)
	var ring: Array = []
	for step in Enemies.NEIGHBOURS:
		var at: Vector2i = spot + step
		expect(Building.place(state, id, at), "a %s goes down round the walker's cell" % id, str(at))
		ring.append(at)
	if short:
		expect(Building.place(state, &"auto_crossbow", spot + Vector2i(3, 0)), "an auto crossbow goes up beyond the ring",
			str(spot))
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	Power.tick(state, false)
	var walker := Entities.spawn(state, &"walker", spot)
	var hp := {}
	for at in ring:
		hp[at] = int(Farm.occupant(state, at)["hp"])
	var bites: Array = []
	var stunned := 0
	var stood := true
	var pos: Array = (Entities.get_one(state, walker)["pos"] as Array).duplicate()
	for tick in 300:
		Enemies.tick(state)
		for at in ring:
			var now := int(Farm.occupant(state, at).get("hp", 0))
			if now < int(hp[at]):
				bites.append(tick)
				hp[at] = now
		if bites.size() >= 2:
			break
		if bites.size() == 1:
			if Enemies.is_stunned(state, walker):
				stunned += 1
			stood = stood and Entities.get_one(state, walker)["pos"] == pos
	return {"state": state, "walker": walker, "stunned": stunned, "stood": stood,
		"gap": int(bites[1]) - int(bites[0]) if bites.size() >= 2 else -1, "percent": Power.percent(state)}


## 0231 - the hardwood wall and the sandbags. The stone wall's level two,
## rebuilt in the big stumps' hardwood behind 'stout timbers': more hit
## points, and dearer for the field to go through - priced at its level - and
## mended in stone and hardwood; no third. The sandbag wall, paid in the
## loom's sandbags, between the fence and the wall on both. Both join the
## line; drawn in code until A043.
func _task_0231_strong_walls() -> void:
	# **The rows, and their checks.**
	var wall: Dictionary = GameData.DEFENCES[&"wall"]
	var fence: Dictionary = GameData.DEFENCES[&"fence"]
	var bags: Dictionary = GameData.DEFENCES[&"sandbag_wall"]
	var steps: Array = GameData.TOWER_LEVELS[&"wall"]
	var step: Dictionary = steps[0] if steps.size() == 1 else {}
	var gives: Dictionary = step.get("gives", {})
	expect(steps.size() == 1 and StringName(step.get("needs", &"")) == &"stout timbers"
		and (step["cost"] as Dictionary).keys() == [GameData.HARDWOOD] and bool(step.get("rebuilds", false))
		and int(gives.get("hp", 0)) > int(wall["hp"]) and int(gives.get("path_cost", 0)) > int(wall["path_cost"]),
		"the wall has one level, behind 'stout timbers' and paid in hardwood, which rebuilds it with more hit points and a dearer way through",
		str(step))
	expect(Building.materials_of(&"sandbag_wall").keys() == [GameData.SANDBAG] and Building.money_of(&"sandbag_wall") > 0
		and GameData.defence_season(bags) == &"summer"
		and int(fence["hp"]) < int(bags["hp"]) and int(bags["hp"]) < int(wall["hp"])
		and int(fence["path_cost"]) < int(bags["path_cost"]) and int(bags["path_cost"]) < int(wall["path_cost"])
		and not bags.has("damage") and not Sfx.TOWER_SOUNDS.has(&"sandbag_wall") and not Pathing.is_prey(&"sandbag_wall"),
		"a sandbag wall is paid in sandbags and a little money, is summer's, sits between the fence and the wall on hit points and path cost, does no damage and nobody hunts it",
		str(bags))
	var levels := GameData.TOWER_LEVELS.duplicate(true)
	((levels[&"wall"] as Array)[0]["gives"] as Dictionary)["path_cost"] = GameData.WIDEST_STEP
	expect(_says(GameData.check_pathing(GameData.TERRAIN_COST, GameData.DEFENCES, GameData.BUILDINGS, levels),
		"a levelled 'wall'") and GameData.check_pathing(GameData.TERRAIN_COST, GameData.DEFENCES,
		GameData.BUILDINGS).is_empty() and GameData.validate().is_empty(),
		"check_pathing reads the levels' path cost too - a level past WIDEST_STEP is refused - and the real tables pass")

	# **Upgraded by the cursor's road, as a tower is**: refused before the
	# node, then once, then never a third.
	var farm := State.create(23100)
	SuiteKit.open_arsenal(farm, [&"sandbag_wall"])
	Resources.gain(farm, {GameData.STONE: 200, GameData.HARDWOOD: 40, GameData.SANDBAG: 20, GameData.MONEY: 200})
	NightRoad.into_build(farm)
	var spot := _open_square(farm, 4, &"wall")
	expect(Building.place(farm, &"wall", spot), "a stone wall goes up in the build step", str(spot))
	var before_node := Building.why_not_upgrade(farm, spot)
	(farm["tech_owned"] as Array).append(&"stout timbers")
	Pathing.refresh(farm)
	var ground := Farm.cost_of_terrain(int((farm["terrain"] as PackedByteArray)[Grid.index(spot)]))
	var stone_cost := Pathing.entry_cost(farm, spot)
	var hardwood_before := Resources.amount(farm, GameData.HARDWOOD)
	var rebuilt := Building.upgrade(farm, spot)
	Pathing.refresh(farm)
	var on := Farm.occupant(farm, spot)
	expect(before_node == [&"WHY_NEEDS_TECH", &"stout timbers"] and rebuilt and Building.level_at(farm, spot) == 2
		and int(on["hp"]) == int(gives["hp"])
		and hardwood_before - Resources.amount(farm, GameData.HARDWOOD) == int((step["cost"] as Dictionary)[GameData.HARDWOOD])
		and Building.why_not_upgrade(farm, spot) == [&"WHY_LAST_LEVEL"] and not Building.upgrade(farm, spot),
		"refused until 'stout timbers', then rebuilt in hardwood to %d hit points, and a third level refused" % int(gives["hp"]),
		"%s %s" % [str(before_node), str(Building.why_not_upgrade(farm, spot))])
	expect(stone_cost == ground + int(wall["path_cost"]) and Pathing.entry_cost(farm, spot) == ground + int(gives["path_cost"])
		and Building.levelled_stat(on, "path_cost") == int(gives["path_cost"])
		and int((farm["open_cost"] as PackedInt32Array)[Grid.index(spot)]) == Pathing.IMPASSABLE,
		"the field prices it at its level: %d to go through the stone wall, %d the hardwood one, a wall to the runners either way"
			% [stone_cost, Pathing.entry_cost(farm, spot)])

	# **A level-two wall takes its hit points' longer to chew through**: a
	# walker shut in a ring of each, its bites until one gives.
	var stone := _ring_breaks(23101, 1)
	var hard := _ring_breaks(23101, 2)
	var bite := int(GameData.ENEMIES[&"walker"]["damage"])
	expect(int(stone["bites"]) == int(wall["hp"]) / bite and int(hard["bites"]) == int(gives["hp"]) / bite
		and int(hard["ticks"]) > int(stone["ticks"]) * 2 - int(stone["gap"]),
		"a walker shut in breaks a stone wall in %d bites and a hardwood one in %d - %d ticks against %d"
			% [int(stone["bites"]), int(hard["bites"]), int(stone["ticks"]), int(hard["ticks"])],
		str([stone, hard]))

	# **Mended to its level, in what it is made of**: stone and hardwood,
	# where a level-one wall mends in stone alone and a tower's upgrades are
	# not in its walls.
	on["hp"] = 100
	var made := Building.made_of(farm, spot)
	var rates := Repair.per_hp_hundredths(farm, spot)
	var plain := _open_square(farm, 2, &"wall")
	var plain_built := Building.place(farm, &"wall", plain)
	var plain_made := Building.made_of(farm, plain)
	var mended := Repair.apply(farm, spot, 1000)
	# Its price is what it is made of (task 0234): the stone wall's stone and
	# money share, and the hardwood its level rebuilt it with.
	expect(made == {GameData.STONE: 10, GameData.MONEY: Building.money_of(&"wall"), GameData.HARDWOOD: 4}
		and rates.has(GameData.STONE) and rates.has(GameData.HARDWOOD)
		and plain_built and plain_made == Building.cost_of(&"wall")
		and Repair.full_hp_at(farm, spot) == int(gives["hp"]) and mended == int(gives["hp"]) - 100
		and int(Farm.occupant(farm, spot)["hp"]) == int(gives["hp"]),
		"a hardwood wall is made of stone and hardwood and mends in both, to %d; a stone one is stone" % int(gives["hp"]),
		"%s %s %d" % [str(made), str(rates), mended])

	# **Sandbags priced between**, by the field too.
	var bag_spot := _open_square(farm, 2, &"sandbag_wall")
	expect(Building.place(farm, &"sandbag_wall", bag_spot), "a sandbag wall goes down in the build step", str(bag_spot))
	Pathing.refresh(farm)
	var bag_ground := Farm.cost_of_terrain(int((farm["terrain"] as PackedByteArray)[Grid.index(bag_spot)]))
	expect(Pathing.entry_cost(farm, bag_spot) == bag_ground + int(bags["path_cost"]) and Pathing.breaks_through(farm, bag_spot),
		"the field prices a sandbag wall at %d to go through" % int(bags["path_cost"]))

	# **The words**: the sandbags' name, the hardwood wall's own, the cursor
	# naming a wall at its level, the node saying what it rebuilds.
	var said := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		said[locale] = [Names.of(&"sandbag_wall"), Names.of_level(&"wall", 2), Names.of_level(&"wall", 1),
			Describe.under_cursor(farm, spot), Names.note_of(&"stout timbers"), Describe.defence(&"sandbag_wall")]
	I18n.use("en")
	var en: Array = said["en"]
	var pt: Array = said["pt_BR"]
	expect(Names.KEYS.get(&"sandbag_wall") == &"DEF_SANDBAG_WALL" and en[0] == "sandbag wall" and en[1] == "hardwood wall"
		and en[2] == "wall" and (en[3] as String).begins_with("HARDWOOD WALL - %d/%d" % [int(gives["hp"]), int(gives["hp"])])
		and (en[4] as String).contains("hardwood") and (en[5] as String).contains("SANDBAG WALL")
		and pt[0] == "sacos de areia" and pt[1] == "muro de madeira de lei" and (pt[4] as String).contains("madeira de lei"),
		"the sandbags and the hardwood wall named in both languages, the cursor naming a wall at its level, and 'stout timbers' saying it rebuilds walls",
		str(said))

	# **The joins**: sandbags meet sandbags, walls at any level, fences - a
	# line is one line - and a hardwood wall is drawn as its level.
	var joined := State.create(23102)
	SuiteKit.open_arsenal(joined, [&"sandbag_wall"])
	Resources.gain(joined, {GameData.SANDBAG: 20, GameData.MONEY: 100})
	NightRoad.into_build(joined)
	var centre := _open_square(joined, 2, &"sandbag_wall")
	Farm.place(joined, centre, {"id": &"sandbag_wall", "hp": 70})
	Farm.place(joined, centre + Vector2i(0, -1), {"id": &"wall", "hp": 240, "level": 2})
	Farm.place(joined, centre + Vector2i(1, 0), {"id": &"sandbag_wall", "hp": 70})
	Farm.place(joined, centre + Vector2i(0, 1), {"id": &"decoy", "hp": 200})
	Farm.place(joined, centre + Vector2i(-1, 0), {"id": &"fence", "hp": 30})
	var view := WorldView.new()
	view._state = joined
	var drawn := [view._barrier_name(Farm.occupant(joined, centre), centre),
		view._barrier_name(Farm.occupant(joined, centre + Vector2i(0, -1)), centre + Vector2i(0, -1))]
	view.free()
	expect(WorldView.barrier_mask(joined, centre) == 11 and WorldView.connected_barrier(&"sandbag_wall")
		and drawn == [&"sandbag_wall_join_11", &"wall_2_join_4"],
		"sandbags join the hardwood wall north, sandbags east and the fence west, not the decoy south; the wall above is drawn as level two, joined down",
		str(drawn))

	# **A043's art since task 0242**: both families' 32 masks, composed by
	# the importer, and wrecks at 16x32 on (8,28), every standing one
	# connected, with nothing of 0120's road left.
	var road: Array = []
	for name in StrongWallArt.names():
		var path := StrongWallArt.path_of(name)
		var frame: Dictionary = RasterArt.FRAMES.get(path, {})
		var texture := StrongWallArt.texture(name)
		if (frame.get("canvas") != Vector2i(16, 32) or frame.get("pivot") != Vector2i(8, 28)
				or PlaceholderArt.is_drawn(path) or not PlaceholderArt.art(name).is_empty()
				or bool(frame.get("connected", false)) == str(name).ends_with("_wreck")
				or texture == null or texture.resource_path != path):
			road.append(name)
	expect(StrongWallArt.names().size() == 66 and road.is_empty() and StrongWallArt.texture(&"wall") == null
		and StrongWallArt.texture(&"electric_fence") == null,
		"both families' 32 masks and wrecks are A043's art at 16x32 on (8,28), every standing one connected",
		str(road))

	# **Each mask's arms match its bits** - north being what rises above
	# both the post and row 8, where a south arm starts - and every hurt one
	# differs from its whole one; the hardwood wall is its own art, not the
	# stone wall's; the sandbags are low.
	var arms: Array = []
	var recoloured := 0
	for family in StrongWallArt.FAMILIES:
		for hurt in [false, true]:
			var post_top := _art_image("res://sprites/buildings/modules/%s_post%s.png" % [family, "_hurt" if hurt else ""]).get_used_rect().position.y
			for m in 16:
				var name := JoinRecipe.name_of(family, m, hurt)
				var image := _art_image(StrongWallArt.path_of(name))
				var seen := [_any_opaque(image, Rect2i(0, 12, 1, 8)), _any_opaque(image, Rect2i(15, 12, 1, 8)),
					_any_opaque(image, Rect2i(0, 0, 16, mini(8, post_top))), _any_opaque(image, Rect2i(0, 20, 16, 12))]
				if image.get_size() != Vector2i(16, 32) or seen != [(m & 8) != 0, (m & 2) != 0, (m & 1) != 0, (m & 4) != 0]:
					arms.append(name)
				if hurt and _alpha_apart(image, _art_image(StrongWallArt.path_of(JoinRecipe.name_of(family, m, false)))) < 3:
					arms.append("%s as whole" % name)
				if family == StrongWallArt.HARDWOOD:
					var stone_image := _art_image("res://sprites/buildings/%s.png" % JoinRecipe.name_of("wall", m, hurt))
					if image.get_data() != stone_image.get_data():
						recoloured += 1
	var post := _art_image("res://sprites/buildings/modules/sandbag_wall_post.png").get_used_rect()
	var bag_wreck := _art_image(StrongWallArt.path_of(StrongWallArt.wreck_of(StrongWallArt.SANDBAGS))).get_used_rect()
	var wood_wreck := _art_image(StrongWallArt.path_of(StrongWallArt.wreck_of(StrongWallArt.HARDWOOD))).get_used_rect()
	expect(arms.is_empty() and recoloured == 32
		and post.size.x >= 8 and post.size.x <= 10 and post.size.y >= 7 and post.size.y <= 9 and post.end.y - 1 == 19
		and bag_wreck.size.y <= 6 and bag_wreck.end.y - 1 == 27 and bag_wreck.size.x <= 14
		and wood_wreck.size.y <= 8 and wood_wreck.end.y - 1 == 27 and wood_wreck.size.x <= 14,
		"every mask's arms match its bits and every hurt one differs from its whole one; the hardwood wall is its own art in all 32 masks; the sandbags' post is low on row 19; both wrecks lie low on row 27",
		"%s post %s wrecks %s %s" % [str(arms.slice(0, 6)), str(post), str(bag_wreck), str(wood_wreck)])

	# **The hotbar**: a straight run of sandbags, among summer's.
	var bar := Hotbar.new()
	var icon := bar._icon_of(&"sandbag_wall")
	bar.free()
	var order := Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	expect(icon != null and icon.resource_path == "res://sprites/ui/icon_sandbag_wall.png"
		and order.find(&"sandbag_wall") >= _first_of_season(order, 1) and Building.season_of(&"sandbag_wall") == 1,
		"the hotbar shows A045's sandbags icon (task 0244), among summer's", str(order))
	expect(FileAccess.get_file_as_string("res://src/tools/shot.gd").contains("[\"strong_walls\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A043-strong-walls.md").contains("Final geometry settled by game task 0231"),
		"shot.gd has a mixed line, and A043's table says the geometry this task settled")
	_completed += 1


## 0232 - powers as a list. The flare is the first entry of `Ability.POWERS`,
## asked and used by id with its own wait and its own aim, and nothing about
## it changed: the keys it keeps in the state, its wait with and without the
## tree's bonus, the burst where it is aimed, the press that sets it off. A
## power that is not one is refused, and the state is not touched.
func _task_0232_powers_list() -> void:
	var table: Dictionary = GameData.ABILITY
	var fresh := State.create(23200)
	expect(Ability.ORDER[0] == Ability.FLARE and Ability.POWERS.keys()[0] == Ability.FLARE
		and Ability.numbers(Ability.FLARE) == table and Ability.is_power(Ability.FLARE)
		and (fresh["ability"] as Dictionary).keys().slice(0, 4) == ["cooldown", "flare", "flare_ticks", "flares"],
		"the flare is the first power, its numbers GameData.ABILITY's and its keys in the state the four it has had since 0054, first",
		str((fresh["ability"] as Dictionary).keys()))

	# **Its wait, through the new calls**: the lever's whole, and the tree's
	# 'a second flare' off it.
	var night := _powers_night(23201)
	var aim := _open_square(night, 5)
	var walker: Dictionary = GameData.ENEMIES[&"walker"]
	var radius := int(table["radius_tiles"])
	var ids: Array = []
	for ring in radius + 2:
		var id := Entities.spawn(night, &"walker", aim + Vector2i(ring, 0))
		Entities.set_hp(night, id, 500)
		ids.append(id)
	var charged := [Ability.ready(night, Ability.FLARE), Ability.charge_percent(night, Ability.FLARE),
		Ability.cooldown_left(night, Ability.FLARE), Ability.full_cooldown(night, Ability.FLARE)]
	var went := Ability.use(night, Ability.FLARE, aim)
	expect(charged == [true, 100, 0, int(table["cooldown_ticks"])] and went
		and Ability.cooldown_left(night, Ability.FLARE) == int(table["cooldown_ticks"])
		and not Ability.ready(night, Ability.FLARE) and Ability.used(night, Ability.FLARE) == 1
		and Ability.charge_percent(night, Ability.FLARE) == 0,
		"charged at night, it goes off and waits its whole %d ticks, counted once" % int(table["cooldown_ticks"]),
		"%s then %d" % [str(charged), Ability.cooldown_left(night, Ability.FLARE)])
	var quick := _powers_night(23202)
	(quick["tech_owned"] as Array).append(&"a second flare")
	var quick_aim := _open_square(quick, 5)
	expect(Ability.use(quick, Ability.FLARE, quick_aim)
		and Ability.cooldown_left(quick, Ability.FLARE) == int(table["cooldown_ticks"])
			* int(Tech.node(&"a second flare")["gives"]["flare_percent"]) / 100,
		"'a second flare' still takes its share off the flare's wait, and only the flare's",
		str(Ability.cooldown_left(quick, Ability.FLARE)))

	# **Its aim and its damage**: the burst lands on the cell it was given,
	# shows for its ticks, and hurts and slows everything within its radius
	# and nothing past it.
	var took: Array = []
	var slowed: Array = []
	for id in ids:
		took.append(500 - int(Entities.get_one(night, int(id)).get("hp", 500)))
		slowed.append(int(Entities.get_one(night, int(id)).get("slow", 0)))
	var hit := maxi(int(table["damage"]) - int(walker.get("armour", 0)), Combat.MINIMUM_HIT)
	var inside := true
	for ring in radius + 1:
		inside = inside and int(took[ring]) == hit and int(slowed[ring]) == int(table["slow_ticks"])
	expect(Ability.aimed_at(night, Ability.FLARE) == [aim.x, aim.y]
		and Ability.showing(night, Ability.FLARE) == int(table["flare_ticks"])
		and inside and int(took[radius + 1]) == 0 and int(slowed[radius + 1]) == 0,
		"the burst lands on the cell it was given, shows %d ticks, and takes %d off and slows everything within %d tiles and nothing past"
			% [int(table["flare_ticks"]), hit, radius], "%s %s" % [str(took), str(slowed)])

	# **Its press**: `intent.ability` with the cursor's cell, as since 0135.
	var pressed := _powers_night(23203)
	var cell := _open_square(pressed, 5)
	(pressed["intent"] as Dictionary)["ability_cell"] = [cell.x, cell.y]
	(pressed["intent"] as Dictionary)["ability"] = true
	Ability.tick(pressed)
	expect(Ability.used(pressed, Ability.FLARE) == 1 and Ability.aimed_at(pressed, Ability.FLARE) == [cell.x, cell.y]
		and Ability.aim_of(pressed) == cell and not bool((pressed["intent"] as Dictionary)["ability"])
		and Ability.cooldown_left(pressed, Ability.FLARE) == int(table["cooldown_ticks"]) - 1
		and Ability.showing(pressed, Ability.FLARE) == int(table["flare_ticks"]) - 1,
		"the ability press flares the cursor's cell and is spent, and the tick runs both counts down")

	# **Recharged and put out, every power.**
	Ability.put_out(pressed)
	var out := [Ability.aimed_at(pressed, Ability.FLARE).is_empty(), Ability.showing(pressed, Ability.FLARE),
		Ability.cooldown_left(pressed, Ability.FLARE) > 0]
	Ability.recharge(pressed)
	expect(out == [true, 0, true] and Ability.ready(pressed, Ability.FLARE)
		and Ability.charge_percent(pressed, Ability.FLARE) == 100,
		"put out, the mark is gone and the wait stays; recharged, it is ready", str(out))

	# **A power that is not one is refused, and nothing is touched.**
	var before := var_to_bytes(pressed)
	var asked := [Ability.use(pressed, &"nonesuch", cell), Ability.ready(pressed, &"nonesuch"),
		Ability.cooldown_left(pressed, &"nonesuch"), Ability.charge_percent(pressed, &"nonesuch"),
		Ability.used(pressed, &"nonesuch"), Ability.aimed_at(pressed, &"nonesuch"),
		Ability.showing(pressed, &"nonesuch"), Ability.numbers(&"nonesuch"), Ability.is_power(&"nonesuch")]
	expect(asked == [false, false, 0, 0, 0, [], 0, {}, false] and var_to_bytes(pressed) == before,
		"an id that is not a power is refused at every call, and the state is byte for byte as it was",
		str(asked))
	_completed += 1


## 0233 - three new powers. The farm bell stops every zombie on the farm for
## its ticks, a boss for its share; the dog runs from the porch and bites the
## zombie nearest the aimed cell after a delay worked out from its run; the
## emergency repair puts a share of a structure's levelled hit points back,
## free, through `Repair.restore`. Each waits its own while, comes back with
## the night, and is refused until its node of the tree is bought.
func _task_0233_powers() -> void:
	# **The table, its check, the digest and the nodes.**
	var powers: Dictionary = GameData.POWERS
	var broken := {}
	var waits: Dictionary = powers.duplicate(true)
	(waits[Ability.FARM_BELL] as Dictionary)["cooldown_ticks"] = 0
	broken["a power that waits for nothing"] = [waits, GameData.TECH_TREE]
	var twice: Array = GameData.TECH_TREE.duplicate(true)
	for row in twice:
		if StringName((row as Dictionary)["id"]) == &"a good dog":
			(row as Dictionary)["gives"] = {"farm_bell_bonus": 1}
	broken["two nodes giving the bell and none the dog"] = [powers, twice]
	var mute: Dictionary = powers.duplicate(true)
	(mute[Ability.FARM_BELL] as Dictionary)["stun_ticks"] = 0
	broken["a bell that stops nobody"] = [mute, GameData.TECH_TREE]
	var bossy: Dictionary = powers.duplicate(true)
	(bossy[Ability.FARM_BELL] as Dictionary)["boss_stun_percent"] = 150
	broken["a boss stopped for more than all of it"] = [bossy, GameData.TECH_TREE]
	var toothless: Dictionary = powers.duplicate(true)
	(toothless[Ability.CALL_DOG] as Dictionary)["damage"] = 0
	broken["a dog that bites for nothing"] = [toothless, GameData.TECH_TREE]
	var odd: Dictionary = powers.duplicate(true)
	(odd[Ability.CALL_DOG] as Dictionary)["damage_type"] = &"tickle"
	broken["a dog biting with no damage type"] = [odd, GameData.TECH_TREE]
	var idle: Dictionary = powers.duplicate(true)
	(idle[Ability.EMERGENCY_REPAIR] as Dictionary)["restore_percent"] = 0
	broken["a repair that puts back nothing"] = [idle, GameData.TECH_TREE]
	var let_through: Array = []
	for why in GameData.sorted_names(broken.keys()):
		if GameData.check_powers(broken[why][0], broken[why][1]).is_empty():
			let_through.append(why)
	var source := FileAccess.get_file_as_string("res://src/core/game_data.gd")
	var nodes := [Tech.node(&"a farm bell"), Tech.node(&"a good dog"), Tech.node(&"an emergency kit")]
	var shaped := true
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		shaped = shaped and StringName(node.get("branch", &"")) == &"survival" and int(node.get("season", -1)) == i + 1
	expect(GameData.validate().is_empty() and let_through.is_empty() and source.contains("\"powers\": POWERS,")
		and shaped and Ability.node_of(Ability.FARM_BELL) == &"a farm bell"
		and Ability.node_of(Ability.CALL_DOG) == &"a good dog" and Ability.node_of(Ability.EMERGENCY_REPAIR) == &"an emergency kit"
		and (nodes[0] as Dictionary)["needs"] == [&"a second flare"] and (nodes[1] as Dictionary)["needs"] == [&"a farm bell"]
		and (nodes[2] as Dictionary)["needs"] == [&"a good dog"]
		and int((nodes[0] as Dictionary)["cost"]) == 16 and int((nodes[1] as Dictionary)["cost"]) == 27
		and int((nodes[2] as Dictionary)["cost"]) == 40,
		"the powers' table passes and is in the digest; a survival node gives each - summer the bell, autumn the dog, winter the repair, a chain off spring's last at a floor's price - and the check refuses a power that waits for nothing, given twice, a mute bell, a boss stopped for more than all, a toothless or untyped dog and a repair of nothing",
		"let through: %s" % str(let_through))

	# **Refused before its node**, and nothing touched; then given.
	var locked := _powers_night(23300)
	var cell := _open_square(locked, 5)
	var before := var_to_bytes(locked)
	var refused: Array = []
	for id in [Ability.FARM_BELL, Ability.CALL_DOG, Ability.EMERGENCY_REPAIR]:
		if Ability.unlocked(locked, id) or Ability.ready(locked, id) or Ability.use(locked, id, cell):
			refused.append(id)
	var said := Describe.power(locked, Ability.FARM_BELL)
	var same := var_to_bytes(locked) == before
	(locked["tech_owned"] as Array).append_array([&"a farm bell", &"a good dog", &"an emergency kit"])
	expect(refused.is_empty() and same
		and said.contains(Names.refusal([&"WHY_NEEDS_TECH", &"a farm bell"]))
		and Ability.ready(locked, Ability.FARM_BELL) and Ability.ready(locked, Ability.CALL_DOG)
		and Ability.ready(locked, Ability.EMERGENCY_REPAIR) and Ability.unlocked(locked, Ability.FLARE),
		"each power is refused before its node is bought - the state untouched, its tooltip naming the node - and ready once it is; the flare needs none",
		"%s / %s" % [str(refused), said])

	# **The bell holds every walker for exactly its ticks**, a boss for its
	# share, and the wait starts.
	var bell: Dictionary = powers[Ability.FARM_BELL]
	var rung := _powers_night(23301)
	(rung["tech_owned"] as Array).append(&"a farm bell")
	var middle := _open_square(rung, 5)
	var walkers: Array = []
	for dx in [-2, 0, 2]:
		walkers.append(Entities.spawn(rung, &"walker", middle + Vector2i(dx, 0)))
	var giant := Entities.spawn(rung, &"giant", middle + Vector2i(0, 3))
	var at: Array = []
	for id in walkers:
		at.append((Entities.get_one(rung, int(id))["pos"] as Array).duplicate())
	var went := Ability.use(rung, Ability.FARM_BELL, middle)
	var stopped := [int(Entities.get_one(rung, int(walkers[0])).get("stun", 0)),
		int(Entities.get_one(rung, giant).get("stun", 0))]
	var held := 0
	for _i in int(bell["stun_ticks"]):
		Enemies.tick(rung)
		var still := true
		for i in walkers.size():
			still = still and Entities.get_one(rung, int(walkers[i]))["pos"] == at[i]
		if still:
			held += 1
	for _i in 3:
		Enemies.tick(rung)
	var moved := 0
	for i in walkers.size():
		if Entities.get_one(rung, int(walkers[i]))["pos"] != at[i]:
			moved += 1
	expect(went and stopped == [int(bell["stun_ticks"]), int(bell["stun_ticks"]) * int(bell["boss_stun_percent"]) / 100]
		and held == int(bell["stun_ticks"]) and moved == walkers.size()
		and Ability.cooldown_left(rung, Ability.FARM_BELL) == int(bell["cooldown_ticks"])
		and Ability.aimed_at(rung, Ability.FARM_BELL) == [middle.x, middle.y],
		"the bell holds every walker for exactly its %d ticks and the giant for %d, they walk on after, and it waits its %d"
			% [int(bell["stun_ticks"]), int(stopped[1]), int(bell["cooldown_ticks"])],
		"%s held %d moved %d" % [str(stopped), held, moved])

	# **The dog bites the zombie nearest the aimed cell, after its run.**
	var dog: Dictionary = powers[Ability.CALL_DOG]
	var sent := _powers_night(23302)
	(sent["tech_owned"] as Array).append_array([&"a farm bell", &"a good dog"])
	var aim := _open_square(sent, 5)
	var near := Entities.spawn(sent, &"walker", aim + Vector2i(1, 0))
	var tied := Entities.spawn(sent, &"walker", aim + Vector2i(-1, 0))
	var far := Entities.spawn(sent, &"walker", aim + Vector2i(int(dog["radius_tiles"]) + 1, 0))
	for id in [near, tied, far]:
		Entities.set_hp(sent, id, 500)
	var delay := Grid.manhattan(House.porch(sent), aim) * int(dog["ticks_per_tile"])
	var calls := Ability.use(sent, Ability.CALL_DOG, aim)
	for _i in delay - 1:
		Ability.tick(sent)
	var early := [500 - int(Entities.get_one(sent, near)["hp"]), 500 - int(Entities.get_one(sent, tied)["hp"])]
	Ability.tick(sent)
	var bitten := [500 - int(Entities.get_one(sent, near)["hp"]), 500 - int(Entities.get_one(sent, tied)["hp"]),
		500 - int(Entities.get_one(sent, far)["hp"])]
	var hit := maxi(int(dog["damage"]) - int((GameData.ENEMIES[&"walker"] as Dictionary).get("armour", 0)), Combat.MINIMUM_HIT)
	expect(calls and delay > 0 and Ability.dog_delay(sent, aim) == delay and early == [0, 0]
		and bitten == [hit, 0, 0] and Ability.dog_target(sent, aim) == mini(near, tied)
		and Ability.showing(sent, Ability.CALL_DOG) == delay + int(dog["bite_ticks"]),
		"the dog runs %d tiles at %d ticks a tile and bites on the %dth tick - the zombie nearest the cell, the lower id of two as near, nobody past %d tiles - for %d"
			% [Grid.manhattan(House.porch(sent), aim), int(dog["ticks_per_tile"]), delay, int(dog["radius_tiles"]), hit],
		"early %s, bitten %s" % [str(early), str(bitten)])

	# **The repair puts back its share of a levelled tower, free**, and is
	# refused on the house, on nothing and on a whole thing.
	var kit: Dictionary = powers[Ability.EMERGENCY_REPAIR]
	var yard := _powers_night(23303)
	(yard["tech_owned"] as Array).append_array([&"a farm bell", &"a good dog", &"an emergency kit", &"true sights"])
	Resources.gain(yard, {GameData.WOOD: 200, GameData.IRON: 200})
	var post := _open_square(yard, 3, &"gun_tower")
	Farm.place(yard, post, {"id": &"gun_tower", "hp": 60, "level": 2})
	var full := Repair.full_hp_at(yard, post)
	(Farm.occupant(yard, post) as Dictionary)["hp"] = 20
	var purse := var_to_bytes(yard["held"])
	var wall := post + Vector2i(2, 0)
	Farm.place(yard, wall, {"id": &"wall", "hp": 120})
	var house_refused := not Ability.use(yard, Ability.EMERGENCY_REPAIR, Farm.house_centre(yard))
	var empty_refused := not Ability.use(yard, Ability.EMERGENCY_REPAIR, post + Vector2i(0, 2))
	var whole_refused := not Ability.use(yard, Ability.EMERGENCY_REPAIR, wall)
	var untouched := Ability.cooldown_left(yard, Ability.EMERGENCY_REPAIR) == 0
	var mended := Ability.use(yard, Ability.EMERGENCY_REPAIR, post)
	var share := full * int(kit["restore_percent"]) / 100
	expect(full == int(((GameData.TOWER_LEVELS[&"gun_tower"] as Array)[0] as Dictionary)["gives"]["hp"])
		and house_refused and empty_refused and whole_refused and untouched and mended
		and int(Farm.occupant(yard, post)["hp"]) == 20 + share and var_to_bytes(yard["held"]) == purse
		and Ability.aimed_at(yard, Ability.EMERGENCY_REPAIR) == [post.x, post.y]
		and Ability.cooldown_left(yard, Ability.EMERGENCY_REPAIR) == int(kit["cooldown_ticks"]),
		"the repair gives a level-two gun tower its %d%% of %d back - %d - free, after refusing the house, an empty cell and a whole wall without waiting"
			% [int(kit["restore_percent"]), full, share], str(Farm.occupant(yard, post)))
	(Farm.occupant(yard, post) as Dictionary)["hp"] = full - 3
	var capped := Repair.restore(yard, post, 50)
	expect(capped == 3 and int(Farm.occupant(yard, post)["hp"]) == full,
		"and the road both mending and the repair take stops at the levelled whole", str(capped))

	# **Every night gives them back**, the dog home.
	Ability.recharge(sent)
	expect(Ability.ready(sent, Ability.CALL_DOG) and Ability.ready(sent, Ability.FARM_BELL)
		and Ability.dog_due(sent) == 0 and Ability.aimed_at(sent, Ability.CALL_DOG).is_empty(),
		"the next night begins with every power charged and the dog home")

	# **Their press**: `intent.power` by id, with the cursor's cell.
	var pressed := _powers_night(23304)
	(pressed["tech_owned"] as Array).append(&"a farm bell")
	var spot := _open_square(pressed, 5)
	GuardianCursor.press(pressed, Ability.FARM_BELL, spot)
	Ability.tick(pressed)
	expect(Ability.used(pressed, Ability.FARM_BELL) == 1 and StringName((pressed["intent"] as Dictionary)["power"]) == &""
		and Ability.aimed_at(pressed, Ability.FARM_BELL) == [spot.x, spot.y],
		"a power's press is spent on the tick, at the cursor's cell")

	# **The words, the keys and the pictures.**
	var words := {}
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		words[locale] = [Names.of(Ability.FARM_BELL), Names.of(Ability.CALL_DOG), Names.of(Ability.EMERGENCY_REPAIR),
			Names.of(&"a good dog"), Names.note_of(&"an emergency kit")]
	I18n.use("en")
	var keyed := true
	for id in [Ability.FARM_BELL, Ability.CALL_DOG, Ability.EMERGENCY_REPAIR]:
		keyed = keyed and InputMap.has_action(id) and ActionsScript.names().has(id)
		keyed = (keyed and PlaceholderArt.art(StringName("hud_%s" % id)).is_empty()
			and RasterArt.FRAMES.has("res://sprites/ui/hud_%s.png" % id) and RasterArt.FRAMES.has("res://sprites/ui/icon_%s.png" % id))
		keyed = keyed and UiKit.picture(StringName("hud_%s" % id)) != null
	expect((words["en"] as Array) == ["farm bell", "call the dog", "emergency repair", "a good dog",
		"an emergency repair: a structure gets back three tenths at once"]
		and (words["pt_BR"] as Array)[0] == "sino da fazenda" and keyed
		and PlaceholderArt.art(&"dog_run").is_empty() and PlaceholderArt.art(&"dog_bite").is_empty()
		and AnimalView.dog_frames(&"dog_run") == 4 and AnimalView.dog_frames(&"dog_bite") == 3
		and AnimalView.dog_frames(&"dog_walk") == 4 and AnimalView.dog_frames(&"dog_sit") == 2
		and is_equal_approx(AnimalView.dog_seconds(&"dog_run"), 0.08)
		and ResourceLoader.exists(AnimalView.dog_path(&"dog_bite", 2))
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A028-dog.md").contains("Final geometry settled by game task 0233")
		and FileAccess.get_file_as_string("res://src/tools/shot.gd").contains("[\"powers\", "),
		"the powers and their nodes named in both languages, an action and a picture each, the dog's run and bite through 0120's road, A028's table final and a shot of the three at work",
		str(words))
	_completed += 1


## 0234 - the arsenal grows with the seasons, and every defence costs money.
## Each defence is refused before its season with the season's name and goes
## down from its first day, and Year 2's spring keeps winter's; a kit still
## pays its money; the checks refuse a kit drifting from its materials, a
## season that is none and a defence with no money or nothing but; the order
## is the year's, a page a season, each from the cheapest; every season opens
## a defence a good day buys; the new families sleep under tarps and wake.
func _task_0234_arsenal() -> void:
	# **The plan's table** (section 5), read off `GameData.DEFENCES`.
	var plan := {&"spring": [&"auto_crossbow", &"barricade", &"fence", &"gun_tower", &"mine", &"wall"],
		&"summer": [&"beehive", &"decoy", &"flame_tower", &"sandbag_wall", &"zombie_bait"],
		&"autumn": [&"catapult", &"garlic_braid", &"mortar"],
		&"winter": [&"electric_fence", &"searchlight"]}
	var by_table := {}
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var season := GameData.defence_season(GameData.DEFENCES[id])
		if not by_table.has(season):
			by_table[season] = []
		(by_table[season] as Array).append(id)
	expect(by_table == plan,
		"each defence opens in the plan's season: spring the guns, the crossbow, the mine and the barriers; summer the flamethrower, the decoy, the hive, the bait and the sandbags; autumn the mortar, the catapult and the garlic; winter the searchlight and the electric fence",
		str(by_table))

	# **A rule**: every defence asked in the build step on the last day
	# before each season, on its first, and on Year 2's first.
	var plenty := {GameData.WOOD: 900, GameData.STONE: 900, GameData.IRON: 900,
		GameData.OIL: 900, GameData.GUNPOWDER: 900, GameData.MONEY: 9000,
		GameData.COPPER: 900, GameData.STRAW: 900, GameData.SUNFLOWER: 900,
		GameData.PUMPKIN: 900, GameData.GARLIC: 900, GameData.SANDBAG: 900}
	var sd := GameData.SEASON_DAYS
	var wrong: Array = []
	var asked := 0
	for day in [1, sd, sd + 1, 2 * sd, 2 * sd + 1, 3 * sd, 3 * sd + 1, Calendar.year_days() + 1]:
		var state := State.create(23400 + day)
		state["day"] = day
		Resources.gain(state, plenty)
		for id in GameData.sorted_names(GameData.DEFENCES.keys()):
			if Building.kit_only(id):
				Crafting.bank_kit(state, id, 3)
		NightRoad.into_build(state)
		var today := Calendar.season_of(day) if Calendar.year_of(day) == 1 else GameData.SEASONS.size() - 1
		for id in GameData.sorted_names(GameData.DEFENCES.keys()):
			var season := Building.season_of(id)
			var want: Array = [] if season <= today else [&"WHY_NOT_YET_SEASON", StringName(GameData.SEASONS[season])]
			var reason := Building.why_not(state, id, _clear_for(state, id))
			asked += 1
			if reason != want:
				wrong.append("%s on day %d: %s" % [id, day, str(reason)])
	expect(wrong.is_empty() and asked == 8 * GameData.DEFENCES.size(),
		"every defence is refused before its season with the season's name and goes down from its first day - and Year 2's spring keeps winter's",
		str(wrong.slice(0, 4)))

	# **Money as well as materials**, under a hundred so the price fits its
	# slot; and the checks.
	var bad_shares: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var money := Building.money_of(id)
		if money <= 0 or money >= 100 or Building.materials_of(id).is_empty():
			bad_shares.append(id)
	var drift_money := GameData.RECIPES.duplicate(true)
	(drift_money[&"mine_kit"] as Dictionary)["inputs"] = Building.cost_of(&"mine").duplicate()
	var drift_iron := GameData.RECIPES.duplicate(true)
	((drift_iron[&"mine_kit"] as Dictionary)["inputs"] as Dictionary)[GameData.IRON] = 4
	var monsoon := GameData.DEFENCES.duplicate(true)
	(monsoon[&"decoy"] as Dictionary)["season"] = &"monsoon"
	var free := GameData.DEFENCES.duplicate(true)
	((free[&"wall"] as Dictionary)["cost"] as Dictionary).erase(GameData.MONEY)
	var only_money := GameData.DEFENCES.duplicate(true)
	(only_money[&"wall"] as Dictionary)["cost"] = {GameData.MONEY: 10}
	expect(bad_shares.is_empty()
		and _says(GameData.check_recipes(drift_money), "a kit has to be the materials paid early")
		and _says(GameData.check_recipes(drift_iron), "a kit has to be the materials paid early")
		and _says(GameData.check_defences(monsoon), "which is no season")
		and _says(GameData.check_defences(free), "costs no money, or nothing but money")
		and _says(GameData.check_defences(only_money), "costs no money, or nothing but money")
		and GameData.validate().is_empty(),
		"every defence costs money under $100 and materials; the checks refuse a kit that pays the money or drifts from the materials, a season that is none, and a defence with no money or nothing but; the real tables pass",
		str(bad_shares))

	# **A kit is the materials paid early, and placing it still charges the
	# money**: refused short of it with the kit kept, then down for the money
	# alone.
	var kit_farm := State.create(23410)
	Crafting.bank_kit(kit_farm, &"mine", 2)
	NightRoad.into_build(kit_farm)
	var mine_spot := _clear_for(kit_farm, &"mine")
	var share := Building.money_of(&"mine")
	Resources.spend(kit_farm, GameData.MONEY, Resources.amount(kit_farm, GameData.MONEY))
	var broke := Building.why_not(kit_farm, &"mine", mine_spot)
	var kept := not Building.place(kit_farm, &"mine", mine_spot) and Crafting.kits(kit_farm, &"mine") == 2
	Resources.gain(kit_farm, {GameData.MONEY: share + 5})
	var iron := Resources.amount(kit_farm, GameData.IRON)
	var powder := Resources.amount(kit_farm, GameData.GUNPOWDER)
	var placed := Building.place(kit_farm, &"mine", mine_spot)
	expect(broke == [&"WHY_SHORT", {GameData.MONEY: share}] and kept and placed
		and Crafting.kits(kit_farm, &"mine") == 1 and Resources.amount(kit_farm, GameData.MONEY) == 5
		and Resources.amount(kit_farm, GameData.IRON) == iron and Resources.amount(kit_farm, GameData.GUNPOWDER) == powder,
		"a mine from a kit still charges its $%d: refused short of it with the kit kept, then down for the money alone - no iron, no powder" % share,
		"%s, $%d left" % [str(broke), Resources.amount(kit_farm, GameData.MONEY)])

	# **Off the ledger, the whole price; sold, the fraction of all of it.**
	var ledger := State.create(23411)
	Resources.gain(ledger, {GameData.WOOD: 10, GameData.IRON: 12})
	NightRoad.into_build(ledger)
	var gun := _clear_for(ledger, &"gun_tower")
	var before := Resources.amount(ledger, GameData.MONEY)
	var up := Building.place(ledger, &"gun_tower", gun)
	var paid := before - Resources.amount(ledger, GameData.MONEY)
	var back := Building.sell(ledger, gun)
	expect(up and paid == Building.money_of(&"gun_tower")
		and back == Building.refund_for_cost(Building.cost_of(&"gun_tower"))
		and int(back.get(GameData.MONEY, 0)) == int(floor(float(Building.money_of(&"gun_tower")) * GameData.SELL_BACK_FRACTION))
		and int(back.get(GameData.MONEY, 0)) > 0,
		"off the ledger a gun tower takes its materials and its $%d, and sold it gives back the fraction of both" % Building.money_of(&"gun_tower"),
		str(back))
	# Mending takes its share of the money too, as a coop's always has.
	var post := State.create(23412)
	Resources.gain(post, {GameData.WOOD: 100, GameData.IRON: 100, GameData.MONEY: 100})
	NightRoad.into_build(post)
	var tower := _clear_for(post, &"gun_tower")
	var built := Building.place(post, &"gun_tower", tower)
	var bill := Repair.cost_at(post, tower, Repair.full_hp_at(post, tower))
	var fair := Building.money_of(&"gun_tower") * GameData.REPAIR_PERCENT / 100
	expect(built and int(bill.get(GameData.MONEY, 0)) >= fair - 1 and int(bill.get(GameData.MONEY, 0)) <= fair,
		"a full mend takes %d%% of the money as of the materials, as a coop's always has" % GameData.REPAIR_PERCENT,
		str(bill))

	# **The order: the year's, each season from the cheapest** - a page a
	# season on the hotbar.
	var order: Array = Building.placeable_ids().slice(0, GameData.DEFENCES.size())
	var in_order := true
	for i in order.size() - 1:
		var a: StringName = order[i]
		var b: StringName = order[i + 1]
		var sa := Building.season_of(a)
		var sb := Building.season_of(b)
		in_order = in_order and (sa < sb or (sa == sb and (Building.price_of(a) < Building.price_of(b)
			or (Building.price_of(a) == Building.price_of(b) and String(a) < String(b)))))
	var sizes: Array = []
	for page in Hotbar.pages_of(order):
		sizes.append((page as Array).size())
	expect(in_order and sizes == [6, 5, 3, 2] and Hotbar.per_page() >= 6 and order[0] == &"barricade",
		"the hotbar's order is the year's, each season from the cheapest - spring's barricade first - a page a season: six, five, three and two",
		"%s %s" % [str(order), str(sizes)])

	# **A good day buys about one new defence** (plan section 5): every season
	# opens one whose money and materials, at what the stall charges, are
	# inside 0194's band for its day; and a new game's purse still pays the
	# first gun tower's money and a fence's on night one.
	var buys := {}
	for id in order:
		var named: StringName = GameData.SEASONS[Building.season_of(id)]
		var band: Array = GameData.DAY_TARGETS[named]
		if Building.price_of(id) >= int(band[0]) and Building.price_of(id) <= int(band[1]):
			buys[named] = id
	var purse := int(GameData.STARTING_RESOURCES[GameData.MONEY])
	expect(buys.size() == GameData.SEASONS.size()
		and purse >= Building.money_of(&"gun_tower") + Building.money_of(&"fence"),
		"every season opens a defence a good day buys - %s - and a new game's $%d still pays a gun tower's money and a fence's on night one" % [str(buys), purse],
		str(buys))

	# **The words**: a defence's tooltip says its season, spring's none; a
	# slot's price, money first, and a kit's money.
	var shelf := State.create(23413)
	Resources.gain(shelf, plenty)
	Crafting.bank_kit(shelf, &"mine")
	var bar := Hotbar.new()
	bar.show_state(shelf)
	var gun_line := bar._price_line(&"gun_tower")
	var kit_line := bar._price_line(&"mine")
	var stake_line := bar._price_line(&"barricade")
	bar.free()
	var dollars := func(id: StringName) -> String: return I18n.f(&"HOTBAR_MONEY", [Building.money_of(id)])
	expect(Describe.defence(&"decoy").contains(I18n.f(&"DESC_SEASON", [Names.of(&"summer")]))
		and not Describe.defence(&"gun_tower").contains(I18n.f(&"DESC_SEASON", [Names.of(&"spring")]))
		and gun_line == "%s 12i\n10w" % dollars.call(&"gun_tower")
		and kit_line == "%s %s" % [I18n.f(&"HOTBAR_KITS", [1]), dollars.call(&"mine")]
		and stake_line.begins_with("%s 4w\n" % dollars.call(&"barricade")),
		"a tooltip says the season a defence comes in, spring's none; a slot shows the money first, and a kit the money it still asks",
		"%s / %s / %s" % [gun_line, kit_line, stake_line])

	# **The new families sleep under tarps and wake at dusk** (0223's list,
	# A044's footprints), and wear A045's icons (its art since task 0244).
	var covered := true
	for pair in [[&"beehive", &"tarp_tower"], [&"catapult", &"tarp_tower"], [&"searchlight", &"tarp_tower"],
			[&"decoy", &"tarp_tall"], [&"garlic_braid", &"tarp_short"]]:
		covered = covered and Transition.TARPS.get(pair[0], &"") == pair[1]
	for id in [&"sandbag_wall", &"electric_fence", &"zombie_bait"]:
		covered = covered and not Transition.TARPS.has(id)
	var woken := Transition.WAKES.has(&"beehive") and Transition.WAKES.has(&"catapult") \
		and Transition.WAKES.has(&"searchlight")
	var unregistered: Array = []
	for id in [&"decoy", &"beehive", &"catapult", &"garlic_braid", &"searchlight", &"electric_fence", &"sandbag_wall"]:
		if not PlaceholderArt.art(StringName("icon_%s" % id)).is_empty() \
				or not RasterArt.FRAMES.has("res://sprites/ui/icon_%s.png" % id):
			unregistered.append(id)
	expect(covered and woken and unregistered.is_empty()
		and PlaceholderArt.art(&"icon_zombie_bait").is_empty() and RasterArt.FRAMES.has("res://sprites/ui/icon_zombie_bait.png"),
		"the hive, the catapult and the searchlight sleep under the tower's tarp and wake, the decoy under the tall one, the braid under the short one - never the sandbags, the wire or the bait; each wears A045's icon (its art since 0244), the bait A037's since 0236",
		str(unregistered))

	# **The robot plans round a shut season**, as round any refusal - in the
	# year-round plan, which carries the mortar; since task 0277 a season's
	# own plan only names what that season opens.
	var robot := State.create(23414)
	var policy := SuiteKit.early_policy(&"towers")
	policy.erase("seasons")
	var at_mortar := (policy["build"] as Array).find(&"mortar")
	robot["autoplay_step"] = at_mortar
	Autoplay._one_thing(robot, policy)
	expect(at_mortar >= 0 and int(robot["autoplay_step"]) == at_mortar + 1,
		"the robot plans round a mortar in spring", str(robot["autoplay_step"]))

	var shots := FileAccess.get_file_as_string("res://src/tools/shot.gd")
	expect(shots.contains("[\"arsenal_spring\", ") and shots.contains("[\"arsenal_winter\", ")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A044-tarps.md").contains("Final geometry settled by game task 0234")
		and FileAccess.get_file_as_string("res://implementation/backlog/packs/A045-power-weapon-icons.md").contains("Final geometry settled by game task 0234"),
		"shot.gd has the hotbar in spring and in winter, and A044's and A045's tables are final")
	_completed += 1


## 0246 - bosses in general. Two Giants on the farm give `bosses_here` both
## ids in order and `boss_here` the lower; `full_hp` is the table's; killing
## one moves `bosses_down_of(state, &"giant")` and `bosses_down` by one each,
## and a kind that is no boss has none; every `is_boss` entry has an intro key
## in the map and a row in the strings table; the view's boss paths read
## `is_boss`, never the Giant's name.
func _task_0246_bosses() -> void:
	var state := _powers_night(24600)
	var house := Farm.house_centre(state)
	var first := Entities.spawn(state, &"giant", house + Vector2i(12, 0))
	var walker := Entities.spawn(state, &"walker", house + Vector2i(12, 2))
	var second := Entities.spawn(state, &"giant", house + Vector2i(12, 4))
	var giant_hp := int((GameData.ENEMIES[&"giant"] as Dictionary)["hp"])
	var walker_hp := int((GameData.ENEMIES[&"walker"] as Dictionary)["hp"])
	expect(Combat.bosses_here(state) == [first, second] and Combat.boss_here(state) == first and first < second
		and Combat.full_hp(state, first) == giant_hp and Combat.full_hp(state, walker) == walker_hp
		and Combat.full_hp(state, second + 99) == 0,
		"two Giants on the farm: bosses_here both, lowest id first, boss_here the lower; full_hp the table's, nobody's 0",
		str(Combat.bosses_here(state)))
	var down := Combat.bosses_down(state)
	var giants := Combat.bosses_down_of(state, &"giant")
	Combat.hit(state, first, 1 << 20)
	expect(Combat.bosses_down_of(state, &"giant") == giants + 1 and Combat.bosses_down(state) == down + 1
		and Combat.bosses_here(state) == [second] and Combat.bosses_down_of(state, &"walker") == 0,
		"killing one moves bosses_down_of(giant) and bosses_down by one each, off the run's tally; a walker is no boss",
		"%d %d" % [Combat.bosses_down_of(state, &"giant"), Combat.bosses_down(state)])

	# **Every boss has its intro**: a literal key in the view's map, a row in
	# the strings table; LOG_BOSS is gone.
	var rows := FileAccess.get_file_as_string("res://assets/locale/strings.csv")
	var missing: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if Combat.is_boss(kind):
			var key := StringName(Names.BOSS_INTROS.get(kind, &""))
			if key == &"" or not rows.contains("\n%s," % key):
				missing.append(kind)
	expect(missing.is_empty() and not rows.contains("\nLOG_BOSS,")
		and Names.boss_intro(&"giant") == I18n.t(&"BOSS_INTRO_GIANT"),
		"every boss has its intro key in the map and a row in the strings table, and LOG_BOSS is gone", str(missing))

	# **The view reads `is_boss`**: the Giant moves in its poses as a boss
	# drawn in them; its voice is the table's; and no boss path names it.
	var view := ["enemy_motion.gd", "enemy_deaths.gd", "pixel_effects.gd", "night_hud.gd", "log_panel.gd", "juice.gd"]
	var by_name: Array = []
	for file in view:
		if SuiteKit.code_lines_of("res://src/ui/" + file).contains("&\"giant\""):
			by_name.append(file)
	var voices := SuiteKit.code_lines_of("res://src/ui/sfx.gd").count("&\"giant\"")
	expect(EnemyMotion.posed_boss(&"giant") and not EnemyMotion.posed_boss(&"walker")
		and EnemyMotion.tracks(&"giant") and EnemyMotion.tracked() == EnemyMotion.FAMILIES + [&"giant"]
		and EnemyMotion.FAMILIES.slice(0, 4) == [&"walker", &"runner", &"tank", &"breaker"]
		and EnemyMotion.TRACKED == EnemyMotion.tracked()
		and Sfx.voice_of(&"giant") == &"sfx/roar_giant" and Sfx.voice_of(&"walker") == &"sfx/groan_walker"
		and by_name.is_empty() and voices == 1,
		"the view reads is_boss: the Giant moves as a boss drawn in its poses (TRACKED its old name), its voice is the table's, and no boss path names it - sfx.gd only in its table of voices",
		"%s %d" % [str(by_name), voices])
	_completed += 1


## 0247 - the spitter. With a tower within `spit_range` it stands off and
## lands `spit_damage` every `spit_every_ticks` - measured - and with none it
## walks to the house; one seed lands the same spits on the same ticks; dawn
## leaves nothing in the air; a glob on an empty cell does nothing and one
## that brings a tower down leaves rubble and a `structure_lost`. A tower whose
## reach covers it kills it first; one that cannot reach it is worn down.
func _task_0247_spitter() -> void:
	var row: Dictionary = GameData.ENEMIES[&"spitter"]
	var gun := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["range"])
	var reach := int(row["spit_range"])
	var every := int(row["spit_every_ticks"])
	var spit := int(row["spit_damage"])
	expect(reach >= 1 and reach < gun and spit > 0 and every > 0 and int(row["spit_tiles_per_second"]) > 0
		and not bool(row.get("lurable", false)) and not Combat.is_boss(&"spitter"),
		"a spitter spits from short of a gun tower's reach, at every lever's own number, and is neither lured nor a boss",
		str(row))
	var none := GameData.ENEMIES.duplicate(true)
	(none[&"spitter"] as Dictionary)["spit_range"] = 0
	var far := GameData.ENEMIES.duplicate(true)
	(far[&"spitter"] as Dictionary)["spit_range"] = gun
	var dry := GameData.ENEMIES.duplicate(true)
	(dry[&"spitter"] as Dictionary)["spit_damage"] = 0
	expect(GameData.check_enemies(GameData.ENEMIES).is_empty() and _says(GameData.check_enemies(none), "spits from no tiles")
		and _says(GameData.check_enemies(far), "as far as a gun tower") and _says(GameData.check_enemies(dry), "spits with no spit_damage"),
		"check_enemies refuses a spit range of nothing or as long as the gun tower's, and a spit of nothing")

	# **It stands off a gun tower and spits, measured**: every landing is
	# `spit_damage`, a `spit_every_ticks` apart, and it never moves - kept
	# alive to be measured, as the tower would kill it.
	var stood := _spit_duel(24700, &"gun_tower", 1 << 20)
	var drops: Array = stood["drops"]
	var apart: Array = []
	var each: Array = []
	for i in drops.size():
		each.append(int((drops[i] as Array)[1]))
		if i > 0:
			apart.append(int((drops[i] as Array)[0]) - int((drops[i - 1] as Array)[0]))
	var lands := drops.size() >= 3
	for one in each:
		lands = lands and int(one) == spit
	for gap in apart:
		lands = lands and int(gap) == every
	expect(lands and not bool(stood["moved"]) and int(stood["tower_hp"]) == 0
		and Farm.rubble_at(stood["state"], stood["cell"]) == &"gun_tower" and int(stood["lost"]) == 1,
		"with a gun tower in reach it stands and lands spit_damage every spit_every_ticks, measured, until the tower is rubble with a structure_lost",
		"%s apart %s, moved %s" % [str(each), str(apart), stood["moved"]])
	var again := _spit_duel(24700, &"gun_tower", 1 << 20)
	expect(str(again["drops"]) == str(stood["drops"]),
		"two runs of one seed land the same spits on the same ticks", str(again["drops"]))

	# **With none it walks to the house** and bites like a walker, spitting
	# at nothing on the way.
	var walk := _powers_night(24701)
	var full := int(walk["house_hp"])
	var walker := Enemies.spawn(walk, &"spitter", 0)
	var spat := false
	for _i in 6000:
		Sim.advance(walk, 1)
		spat = spat or not (walk["enemy_shots"] as Array).is_empty() or Enemies.spitting_at(walk, walker).x >= 0
		if not Entities.alive(walk, walker):
			break
	expect(walker > 0 and not Entities.alive(walk, walker) and not spat
		and int(walk["house_hp"]) == full - int(row["damage"]),
		"with no tower in reach it walks the field to the house and bites it like a walker",
		"house %d of %d, spat %s" % [int(walk["house_hp"]), full, spat])

	# **Dawn leaves nothing in the air.**
	var dawn := _powers_night(24702)
	var post := _spit_ground(dawn)
	Farm.place(dawn, post, {"id": &"gun_tower", "hp": 60})
	Entities.set_hp(dawn, Entities.spawn(dawn, &"spitter", post + Vector2i(reach, 0)), 1 << 20)
	for _i in 120:
		Sim.advance(dawn, 1)
		if not (dawn["enemy_shots"] as Array).is_empty():
			break
	var aloft := (dawn["enemy_shots"] as Array).size()
	(dawn["wave"] as Dictionary)["dawn_at"] = int(dawn["night_tick"]) + 1
	Sim.advance(dawn, 2)
	var day := Phases.begin_day(dawn)
	expect(aloft > 0 and day and (dawn["enemy_shots"] as Array).is_empty() and Entities.count(dawn) == 0,
		"a glob in the air at dawn is gone with the spitter when the day begins", "%d aloft" % aloft)

	# **A glob on an empty cell does nothing**: the tower taken away under it
	# - no rubble, nothing lost.
	var empty := _powers_night(24703)
	var gone := _spit_ground(empty)
	Farm.place(empty, gone, {"id": &"gun_tower", "hp": 60})
	Entities.set_hp(empty, Entities.spawn(empty, &"spitter", gone + Vector2i(reach, 0)), 1 << 20)
	for _i in 120:
		Sim.advance(empty, 1)
		if not (empty["enemy_shots"] as Array).is_empty():
			break
	var flying := (empty["enemy_shots"] as Array).size()
	Farm.remove(empty, gone)
	var from := int(empty["tick"])
	for _i in 120:
		Sim.advance(empty, 1)
		if (empty["enemy_shots"] as Array).is_empty():
			break
	var lost := 0
	for event in Events.since(empty, from):
		if StringName((event as Dictionary)["kind"]) == &"structure_lost":
			lost += 1
	expect(flying > 0 and (empty["enemy_shots"] as Array).is_empty() and Farm.occupant(empty, gone).is_empty()
		and Farm.rubble_at(empty, gone) == &"" and lost == 0,
		"a glob landing on a cell left empty does nothing: no rubble, nothing lost", "%d lost" % lost)

	# **A tower whose reach covers it kills it before losing the tower; one
	# that cannot reach it is worn down.** Both numbers printed.
	var covered := _spit_duel(24704, &"gun_tower", 0)
	var short := _spit_duel(24705, &"flame_tower", 0)
	var flame := int((GameData.DEFENCES[&"flame_tower"] as Dictionary)["range"])
	print("  a spitter at %d tiles: a gun tower (reach %d) kills it in %d ticks with %d of %d hit points left; a flamethrower (reach %d) is worn down in %d ticks, the spitter untouched at %d"
		% [reach, gun, int(covered["ticks"]), int(covered["tower_hp"]), int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"]),
			flame, int(short["ticks"]), int(short["spitter_hp"])])
	expect(not bool(covered["alive"]) and int(covered["tower_hp"]) > 0,
		"a gun tower, whose reach covers it, kills it before losing the tower", str(covered["tower_hp"]))
	expect(flame < reach and bool(short["alive"]) and int(short["spitter_hp"]) == int(row["hp"])
		and int(short["tower_hp"]) == 0 and Farm.rubble_at(short["state"], short["cell"]) == &"flame_tower" and int(short["lost"]) == 1,
		"a flamethrower, which cannot reach it, is worn down to rubble with the spitter untouched",
		"%d ticks" % int(short["ticks"]))

	# **The words and the voice**: its name, its tooltip's reach, the
	# walker's groan borrowed.
	expect(Names.of(&"spitter") == I18n.t(&"ENEMY_SPITTER")
		and Describe.enemy(&"spitter").contains(I18n.f(&"DESC_SPITS", [reach]))
		and Sfx.ENEMY_SOUNDS.get(&"spitter", &"") == &"sfx/voice_spitter",
		"it has its name, a tooltip line for its reach, and since 0284 a voice of its own")

	# **The view plays it off the rules**: the release and the recovery after
	# each spit, the rear before the next, standing between and walking off
	# the clock; the glob lifted from the mouth to the tower on its arc.
	var poses: Array = []
	for wait in [every, every - SPIT_SETTLE, 3, every / 2]:
		poses.append(WorldView.posed_off_the_rules(stood["state"],
			{"id": 1, "kind": &"spitter", "spitting": 0, "spit_wait": wait}))
	poses.append(WorldView.posed_off_the_rules(stood["state"], {"id": 1, "kind": &"spitter"}))
	var shot := {"pos": [0, 0], "left": 10, "flight": 10}
	var leaves := WorldView.spit_position(shot)
	shot["left"] = 0
	var arrives := WorldView.spit_position(shot)
	expect(poses.slice(0, 4) == [&"spitter_attack_1", &"spitter_attack_2", &"spitter_attack_0", &"spitter"]
		and String(poses[4]).begins_with("spitter_walk_")
		and is_equal_approx(-leaves.y, WorldView.SPIT_MOUTH_LIFT) and is_equal_approx(-arrives.y, WorldView.SPIT_HIT_LIFT),
		"the view plays the spit off the rules, and the glob leaves the mouth and lands up the tower", str(poses))

	# **The glob and the splat**, A046's art since task 0260: the glob 4-6
	# pixels inside its 8x8, its two frames apart, held for `draw_texture`;
	# the splat growing then shrinking inside its 12x12; a pixel clear all
	# round; nothing of 0120's road left.
	var sizes: Array = []
	var bordered := true
	for i in SpitterArt.GLOB_FRAMES:
		var image := SpitterArt.glob(i).get_image()
		var used := image.get_used_rect()
		sizes.append(used.size)
		bordered = bordered and image.get_size() == Vector2i(8, 8) and used.position.x >= 1 and used.position.y >= 1 \
			and used.end.x <= 7 and used.end.y <= 7
	var areas: Array = []
	for i in SpitterArt.SPLAT_FRAMES:
		var image := SpitterArt.splat(i).get_image()
		var used := image.get_used_rect()
		var area := 0
		for y in image.get_height():
			for x in image.get_width():
				area += 1 if image.get_pixel(x, y).a > 0.0 else 0
		areas.append(area)
		bordered = bordered and image.get_size() == Vector2i(12, 12) and used.position.x >= 1 and used.position.y >= 1 \
			and used.end.x <= 11 and used.end.y <= 11 and used.size.x <= 10 and used.size.y <= 10
	var round_glob := true
	for size in sizes:
		round_glob = round_glob and (size as Vector2i).x >= 4 and (size as Vector2i).x <= 6 and (size as Vector2i).y >= 4 and (size as Vector2i).y <= 6
	var raster := (SpitterArt.glob(0).resource_path == SpitterArt.GLOB_PATH % 0
		and SpitterArt.splat(2).resource_path == SpitterArt.SPLAT_PATH % 2
		and PlaceholderArt.art(&"spit").is_empty() and PlaceholderArt.art(&"spit_splat").is_empty()
		and PlaceholderArt.art(&"spitter_walk").is_empty() and PlaceholderArt.art(&"head_spitter").is_empty()
		and _held(func() -> Object: return SpitterArt.glob(1))
		and SpitterArt.glob(0).get_image().get_data() != SpitterArt.glob(1).get_image().get_data())
	expect(bordered and round_glob and raster and int(areas[0]) < int(areas[1]) and int(areas[2]) < int(areas[1])
		and SpitterArt.splat(SpitterArt.SPLAT_FRAMES) == null,
		"A046's glob is 4-6 pixels a frame, its two frames apart and held; the splat grows and shrinks, a pixel clear all round",
		"%s %s" % [str(sizes), str(areas)])
	_completed += 1


## 0248 - the rat swarm. One release is `cluster` rats on adjacent cells on
## one tick, with no draw past the first; a wave sends the bodies
## `Waves.size_of` counts, a cluster a release; a mine under the cluster kills
## more rats for its price than a gun tower in the same lane; and a swarm's
## bounty stays small beside a night's fee.
func _task_0248_rats() -> void:
	var row: Dictionary = GameData.ENEMIES[&"rat"]
	var runner := int((GameData.ENEMIES[&"runner"] as Dictionary)["ticks_per_tile"])
	var cluster := int(row["cluster"])
	expect(int(row["hp"]) >= 2 and int(row["hp"]) <= 6 and int(row["ticks_per_tile"]) >= 10
		and int(row["ticks_per_tile"]) <= 14 and int(row["damage"]) >= 1 and int(row["damage"]) <= 2
		and int(row["reward"]) == 1 and int(row.get("armour", 0)) == 0 and cluster >= 4 and cluster <= 10
		and not bool(row.get("ignores_structures", false)) and int(row["ticks_per_tile"]) > runner,
		"a rat: 2-6 hit points, 10-14 ticks a tile - slower than the runner, as it stops for walls - 1-2 to the house, $1, no armour, 4-10 at a time",
		str(row))
	var none := GameData.ENEMIES.duplicate(true)
	(none[&"rat"] as Dictionary)["cluster"] = 0
	var fast := GameData.ENEMIES.duplicate(true)
	(fast[&"rat"] as Dictionary)["ticks_per_tile"] = runner
	expect(GameData.check_enemies(GameData.ENEMIES).is_empty() and _says(GameData.check_enemies(none), "comes 0 at a time")
		and _says(GameData.check_enemies(fast), "ignores structures without being faster"),
		"check_enemies refuses a cluster of nothing, and a rat that stops for walls as fast as the runner")

	# **One release, round the first, no draw past it**: the rest on its
	# walkable, reachable neighbours in `Enemies.NEIGHBOURS` order, round
	# again past the last.
	var placed := _powers_night(24800)
	var drawn := State.copy(placed)
	var alone := Enemies.spawn(drawn, &"rat", 0)
	var ids := Enemies.spawn_cluster(placed, &"rat", 0, cluster)
	var first := Entities.cell_of(placed, int(ids[0]))
	var ring: Array = []
	for step in Enemies.NEIGHBOURS:
		var cell: Vector2i = first + step
		if Grid.in_bounds(cell) and Farm.walkable(placed, cell) and Pathing.reachable(placed, cell):
			ring.append(cell)
	var round_it := ids.size() == cluster and not ring.is_empty()
	for i in range(1, ids.size()):
		round_it = round_it and Entities.cell_of(placed, int(ids[i])) == ring[(i - 1) % ring.size()]
	expect(round_it and first == Entities.cell_of(drawn, alone) and str(placed["rng"]) == str(drawn["rng"]),
		"a cluster is the first on a spawn cell from the run's RNG and the rest round it in NEIGHBOURS order, with no draw past the first",
		"%s round %s" % [str(first), str(ring)])

	# **A wave counts bodies, a cluster a release**: two full clusters and a
	# short one, each out on one tick, `Waves.size_of`'s count in all.
	var swarm := State.create(24801)
	swarm["day"] = 30
	swarm["nights_won"] = 29
	Phases.begin_preparation(swarm)
	var bodies := 2 * cluster + 2
	var record := {"note": "a swarm", "opening_ticks": 0, "waves": [[&"rat", bodies, 0]], "for_night": 30}
	(swarm["wave"] as Dictionary)["tonight"] = record
	NightRoad.through_build(swarm)
	swarm["house_hp"] = 100000
	var rises: Array = []
	var was := Entities.count(swarm)
	if was > 0:
		rises.append(was)
	for _i in 4 * (Waves.interval_in(record) + 1):
		Sim.tick(swarm)
		var now := Entities.count(swarm)
		if now != was:
			rises.append(now - was)
		was = now
	var sent := 0
	for rise in rises:
		sent += int(rise)
	expect(rises == [cluster, cluster, 2] and sent == Waves.size_in(record) and Waves.releases_of(record["waves"][0]) == 3
		and Waves.schedule_ticks(record) == 1 + 2 * (Waves.interval_in(record) + 1) and int((swarm["wave"] as Dictionary)["left"]) == 0,
		"a wave of %d rats comes out a cluster a tick - %d, %d and %d - which is the count Waves.size_of gave, three releases long" % [bodies, cluster, cluster, 2],
		str(rises))

	# **A mine under the cluster, against a gun tower in the same lane**, and
	# the crossbow and the flamethrower beside them: what each kills of three
	# clusters passing, and what a rat costs - by the money it is put down
	# with, the night's purse since 0234, and by its whole price at the stall.
	var lanes := {}
	for id in [&"mine", &"gun_tower", &"auto_crossbow", &"flame_tower"]:
		lanes[id] = _rat_lane(24802, id)
	var parts: Array = []
	for id in [&"mine", &"gun_tower", &"auto_crossbow", &"flame_tower"]:
		var lane: Dictionary = lanes[id]
		var kills := maxi(int(lane["kills"]), 1)
		parts.append("%s %d killed, $%.2f a rat by its money ($%d), $%.2f by its price ($%d)" % [id, int(lane["kills"]),
			float(lane["money"]) / float(kills), int(lane["money"]), float(lane["price"]) / float(kills), int(lane["price"])])
	print("  three clusters of %d down one lane: %s" % [cluster, "; ".join(parts)])
	var mine: Dictionary = lanes[&"mine"]
	var gun: Dictionary = lanes[&"gun_tower"]
	expect(int(mine["kills"]) >= cluster - 1 and int(mine["kills"]) * int(gun["money"]) > int(gun["kills"]) * int(mine["money"])
		and int(gun["kills"]) <= int(gun["shots"]) and int(gun["kills"]) < 3 * cluster,
		"a mine under the cluster takes it with one charge and kills more rats for its money than a gun tower in the same lane, which kills a rat a shot at most and lets most by",
		"; ".join(parts))
	expect(int((lanes[&"flame_tower"] as Dictionary)["kills"]) > int(gun["kills"])
		and int((lanes[&"auto_crossbow"] as Dictionary)["kills"]) > int(gun["kills"]),
		"and the flame cone and the crossbow's line kill more of the lane than the gun tower", "; ".join(parts))

	# **A swarm does not out-earn a day**: three hundred rats - the perf
	# swarm - pay a bounty under the fee for holding the summer's last night.
	var bounty := 300 * int(row["reward"]) * int(GameData.REWARDS["bounty_percent"]) / 100
	var fee := int(GameData.REWARDS["base_money"]) + int(GameData.REWARDS["money_per_night"]) * 2 * GameData.SEASON_DAYS
	expect(bounty < fee and int(row.get("bones", 0)) == 0,
		"three hundred rats pay $%d of bounty, under the $%d fee for holding Summer 14, and leave no bones" % [bounty, fee])

	# **The words and the voice**: its name, its tooltip's cluster, the
	# runner's voice borrowed.
	expect(Names.of(&"rat") == I18n.t(&"ENEMY_RAT") and Describe.enemy(&"rat").contains(I18n.f(&"DESC_SWARMS", [cluster]))
		and Sfx.ENEMY_SOUNDS.get(&"rat", &"") == &"sfx/squeak",
		"it has its name, a tooltip line for its cluster, and since 0284 a voice of its own")

	# **Drawn in code until A047**: every frame 24x16 with its feet on row
	# 13 and a pixel clear all round, none the same as another, 7-9 tall
	# standing and 20 long at most, the death never growing and ending at 6
	# at most; the head on A011's box, cut flat at row 14.
	var frames: Array = [&"rat"]
	for pose in [["walk", 4], ["attack", 3], ["death", 3]]:
		for i in int(pose[1]):
			frames.append(StringName("rat_%s_%d" % [pose[0], i]))
	var shapes := {}
	var wrong: Array = []
	var heights := {}
	for name in frames:
		var texture := WorldView.drawn_enemy(WorldView.ENEMY_DIR + str(name) + ".png")
		var image := texture.get_image() if texture != null else null
		if image == null:
			wrong.append(name)
			continue
		var used := image.get_used_rect()
		heights[name] = used.size.y
		shapes[image.get_data()] = true
		if image.get_size() != Vector2i(24, 16) or used.end.y != 14 or used.position.x < 1 or used.position.y < 1 \
				or used.end.x > 23:
			wrong.append("%s %s" % [name, used])
		heights[str(name) + " long"] = used.size.x
	var standing := true
	for name in [&"rat", &"rat_walk_0", &"rat_walk_1", &"rat_walk_2", &"rat_walk_3", &"rat_attack_2"]:
		standing = standing and int(heights.get(name, 0)) >= 7 and int(heights.get(name, 0)) <= 9 \
			and int(heights.get(str(name) + " long", 99)) <= 20
	# The lunge's snout at most 3 pixels past the standing one.
	standing = standing and int(heights.get("rat_attack_1 long", 99)) <= int(heights.get("rat long", 0)) + 3
	var head := WorldView.drawn_enemy("res://sprites/ui/head_rat.png")
	var head_used := head.get_image().get_used_rect() if head != null else Rect2i()
	# A047's own, nothing of 0120's road; tracked, so its three death frames
	# play (task 0261).
	standing = (standing and PlaceholderArt.art(&"rat_walk").is_empty() and PlaceholderArt.art(&"head_rat").is_empty()
		and head != null and head.resource_path == "res://sprites/ui/head_rat.png"
		and EnemyMotion.tracks(&"rat") and EnemyDeaths.death_frames(&"rat") == 3 and EnemyDeaths.death_frames(&"walker") == 4)
	expect(wrong.is_empty() and shapes.size() == frames.size() and standing
		and int(heights.get(&"rat_death_1", 99)) <= int(heights.get(&"rat_death_0", 0))
		and int(heights.get(&"rat_death_2", 99)) <= int(heights.get(&"rat_death_1", 0)) and int(heights.get(&"rat_death_2", 99)) <= 6
		and head != null and head.get_size() == Vector2(16, 16) and head_used.end.y == 15 and head_used.size.x <= 13
		and head_used.size.y >= 12 and head_used.size.y <= 13,
		"the rat is A047's art (task 0261): feet on row 13, a pixel clear, every frame its own, 7-9 tall and 20 long standing, the lunge 3 further, dying lower to 6, its head on A011's box",
		"%s %s head %s" % [str(wrong), str(heights), str(head_used)])
	_completed += 1


## 0249 - the crow. Spawned behind a wall line it flies over the wall and a
## mine - neither touched - to a planted plot in the straight-line tick
## count, eats it `peck_ticks` after landing and says so in the log; with
## nothing planted it flies at the house and bites. In the air only the
## towers that `hits_flying` acquire it, and no ground weapon, mine or dog
## reaches it; landed, everything does. The flare and the bell reach it in
## the air.
func _task_0249_crow() -> void:
	var row: Dictionary = GameData.ENEMIES[&"crow"]
	var tank: Dictionary = GameData.ENEMIES[&"tank"]
	var per_tile := int(row["ticks_per_tile"])
	var peck := int(row["peck_ticks"])
	expect(bool(row["flies"]) and not row.has("ignores_structures") and not row.has("targets_structures")
		and peck > 0 and int(row["hp"]) < int(tank["hp"]) and int(row.get("armour", 0)) < int(tank["armour"])
		and per_tile < int(tank["ticks_per_tile"]) and not Combat.is_boss(&"crow"),
		"a crow flies, says nothing of walls, eats in peck_ticks, and sits inside the tank's bounds", str(row))
	var walks := GameData.ENEMIES.duplicate(true)
	(walks[&"crow"] as Dictionary)["ignores_structures"] = true
	var quick := GameData.ENEMIES.duplicate(true)
	(quick[&"crow"] as Dictionary)["ticks_per_tile"] = 2
	var greedy := GameData.ENEMIES.duplicate(true)
	(greedy[&"crow"] as Dictionary)["peck_ticks"] = 0
	var untold := GameData.DEFENCES.duplicate(true)
	(untold[&"gun_tower"] as Dictionary).erase("hits_flying")
	var undecided: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var entry: Dictionary = GameData.DEFENCES[id]
		if entry.has("reload_ticks") and not entry.has("hits_flying"):
			undecided.append(id)
	expect(GameData.check_enemies(GameData.ENEMIES).is_empty() and _says(GameData.check_enemies(walks), "flies and says how it walks")
		and GameData.check_enemies(quick).is_empty() and _says(GameData.check_enemies(greedy), "eats a crop in no time")
		and undecided.is_empty() and _says(GameData.check_defences(untold), "never says whether it hits what flies"),
		"check_enemies refuses a flyer that walks round walls or eats in no time and leaves a fast one out of the runner's race; every tower says whether it hits what flies, and check_defences refuses one that does not",
		str(undecided))

	# **Over the wall and the mine, straight to the crop**: in the tick count
	# of its straight line, eaten `peck_ticks` after it lands, and the wall
	# and the mine untouched.
	var state := _powers_night(24900)
	var crop: Vector2i = Farming.field_cells(state)[0]
	_sow(state, crop, &"carrot")
	var start := crop + Vector2i(14, 3)
	var crow := Entities.spawn(state, &"crow", start)
	var from := Vector2i(int(Entities.get_one(state, crow)["pos"][0]), int(Entities.get_one(state, crow)["pos"][1]))
	var goal := crop * Player.SUBTILE + Vector2i(Player.SUBTILE / 2, Player.SUBTILE / 2)
	# Its line, cell by cell, as it will fly it: a wall across it two cells
	# out and a mine on it past the wall, on the first ground each can go on.
	var line: Array = []
	var step := from
	while step != goal:
		var delta := goal - step
		if absi(delta.x) >= absi(delta.y):
			step.x += signi(delta.x)
		else:
			step.y += signi(delta.y)
		var over := Vector2i(step.x / Player.SUBTILE, step.y / Player.SUBTILE)
		if line.is_empty() or line.back() != over:
			line.append(over)
	var walls: Array = []
	var mine := Vector2i(-1, -1)
	for i in range(2, line.size() - 2):
		var cell: Vector2i = line[i]
		if walls.is_empty() and Farm.buildable(state, cell):
			for dy in [-1, 0, 1]:
				var at_wall := cell + Vector2i(0, int(dy))
				if Farm.buildable(state, at_wall):
					Farm.place(state, at_wall, {"id": &"wall", "hp": int((GameData.DEFENCES[&"wall"] as Dictionary)["hp"])})
					walls.append(at_wall)
		elif not walls.is_empty() and mine.x < 0 and i > line.find(walls[0]) + 1 and Farm.buildable(state, cell):
			mine = cell
			Farm.place(state, mine, {"id": &"mine", "hp": 1})
	Pathing.refresh(state)
	var straight := (absi(goal.x - from.x) + absi(goal.y - from.y)) * per_tile
	straight = (straight + Player.SUBTILE - 1) / Player.SUBTILE
	var landed := -1
	var eaten := -1
	var aloft_over_wall := false
	for t in 2000:
		Sim.advance(state, 1)
		var one := Entities.get_one(state, crow)
		aloft_over_wall = aloft_over_wall or (walls.has(Entities.cell_of(state, crow)) and Enemies.airborne(state, crow))
		if landed < 0 and one.has("peck"):
			landed = t + 1
		if Farming.crop_on(state, crop) == &"":
			eaten = t + 1
			break
	var said := ""
	for event in Events.since(state, 0):
		if StringName((event as Dictionary)["kind"]) == &"crop_eaten":
			said = LogPanel.line_for(event)
	var standing := true
	for cell in walls:
		standing = standing and int(Farm.occupant(state, cell as Vector2i).get("hp", 0)) == int((GameData.DEFENCES[&"wall"] as Dictionary)["hp"])
	expect(walls.size() >= 2 and mine.x >= 0 and aloft_over_wall and landed == straight and eaten == landed + peck
		and StringName(Farm.occupant(state, mine).get("id", &"")) == &"mine" and int(state.get("traps_sprung", 0)) == 0 and standing
		and Farming.is_tilled(state, crop) and said == I18n.f(&"LOG_CROP_EATEN", [Names.of(&"carrot")]),
		"a crow flies over a wall line and a mine, neither touched, lands on the crop in the straight line's %d ticks and eats it %d later - the plot still tilled, and the log says so" % [straight, peck],
		"landed %d, eaten %d, over the wall %s, '%s'" % [landed, eaten, aloft_over_wall, said])

	# **With nothing planted it flies at the house and bites** - an empty
	# field never holds a night open.
	var bare := _powers_night(24901)
	var full := int(bare["house_hp"])
	var hungry := Entities.spawn(bare, &"crow", Farm.house_centre(bare) + Vector2i(12, 4))
	var gone := -1
	for t in 2000:
		Sim.advance(bare, 1)
		if not Entities.alive(bare, hungry):
			gone = t + 1
			break
	expect(gone > 0 and int(bare["house_hp"]) == full - int(row["damage"]),
		"with nothing planted it flies at the house and bites, %d ticks out" % gone, "%d of %d" % [int(bare["house_hp"]), full])

	# **What reaches it in the air, and what reaches it landed.** Every tower
	# asked from four tiles off: in the air, only the ones that hit what
	# flies; landed, all of them.
	var sky := _powers_night(24902)
	var field: Vector2i = Farming.field_cells(sky)[2]
	_sow(sky, field, &"carrot")
	var bird := Entities.spawn(sky, &"crow", field)
	var picked: Array = []
	var wrong: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var entry: Dictionary = Building.entry_of(id)
		if not entry.has("reload_ticks"):
			continue
		# From as far as it reaches, four tiles at most and never inside its
		# floor: the hive's two, the flamethrower's three.
		var post := field + Vector2i(clampi(int(entry.get("range", 0)), maxi(int(entry.get("min_range", 0)), 1), 4), 0)
		var up := bool(entry["hits_flying"])
		var aloft := Towers.acquire_for(sky, post, entry) == bird
		(Entities.get_one(sky, bird))["peck"] = peck
		var down := Towers.acquire_for(sky, post, entry) == bird
		(Entities.get_one(sky, bird)).erase("peck")
		picked.append("%s %s/%s" % [id, aloft, down])
		if aloft != up or not down:
			wrong.append(id)
	expect(Enemies.airborne(sky, bird) and wrong.is_empty() and picked.size() == 6,
		"in the air only the towers that hit what flies pick it, and landed every tower does", "%s; wrong %s" % [str(picked), str(wrong)])
	var was := int(Entities.get_one(sky, bird)["hp"])
	Towers.burn_cone_for_test(sky, field + Vector2i(2, 0), Building.entry_of(&"flame_tower"), bird, true)
	Towers.land_at_for_test(sky, Building.entry_of(&"mortar"), field)
	Farm.place(sky, field + Vector2i(1, 1), {"id": &"mine", "hp": 1})
	Traps.detonate_for_test(sky, field + Vector2i(1, 1))
	var dog := Ability.dog_target(sky, field)
	var unhurt := int(Entities.get_one(sky, bird)["hp"]) == was and dog == 0
	(Entities.get_one(sky, bird))["peck"] = peck
	var on_the_ground := Ability.dog_target(sky, field) == bird
	Towers.land_at_for_test(sky, Building.entry_of(&"mortar"), field)
	var shelled := not Entities.alive(sky, bird) or int(Entities.get_one(sky, bird)["hp"]) < was
	expect(unhurt and on_the_ground and shelled,
		"in the air no flame, shell, mine or dog reaches it; landed, the dog would bite it and a shell hits it")

	# **The flare and the bell reach the air**: a flare hits and slows it, the
	# bell stuns it where it flies.
	var flared := _powers_night(24903)
	(flared["tech_owned"] as Array).append_array([&"a farm bell"])
	var flyer := Entities.spawn(flared, &"crow", Farm.house_centre(flared) + Vector2i(10, 6))
	# Kept alive through the flare's blast to be looked at: it kills a crow.
	Entities.set_hp(flared, flyer, 999)
	var at := Entities.cell_of(flared, flyer)
	var lit := Ability.use(flared, Ability.FLARE, at)
	var rung := Ability.use(flared, Ability.FARM_BELL, at)
	expect(lit and rung and Enemies.airborne(flared, flyer) and int(Entities.get_one(flared, flyer)["hp"]) < 999
		and Ability.is_slowed(flared, flyer) and Enemies.is_stunned(flared, flyer),
		"a flare hits and slows a crow in the air, and the bell stuns it there")

	# **The words and the voice.**
	expect(Names.of(&"crow") == I18n.t(&"ENEMY_CROW") and Describe.enemy(&"crow").contains(I18n.t(&"DESC_FLIES"))
		and Sfx.ENEMY_SOUNDS.get(&"crow", &"") == &"sfx/caw" and LogPanel.SEVERITY.has(&"crop_eaten"),
		"it has its name, a tooltip line that it flies, a voice of its own (0284), and a log line")

	# **The view lifts it in the air and sets it down to eat**: `FLIGHT_LIFT`
	# over its shadow flying, nothing landed; the wingbeat aloft, touchdown and
	# peck on the field.
	var sight := {"id": 1, "kind": &"crow", "pos": [0, 0], "flying_to": -1}
	var aloft_lift := WorldView.flight_lift(state, sight)
	var aloft_pose := WorldView.flyer_pose(state, sight)
	sight["peck"] = peck
	var touch := WorldView.flyer_pose(state, sight)
	sight["peck"] = peck / 2
	var pecking := WorldView.flyer_pose(state, sight)
	expect(is_equal_approx(aloft_lift, WorldView.FLIGHT_LIFT) and is_equal_approx(WorldView.flight_lift(state, sight), 0.0)
		and String(aloft_pose).begins_with("crow_fly_") and touch == &"crow_land_0" and String(pecking).begins_with("crow_peck_"),
		"the view lifts a crow over its shadow in the air and sets it down to peck", "%s %s %s" % [aloft_pose, touch, pecking])

	# **Drawn in code until A048**: every frame 32x24 with a pixel clear all
	# round, none the same as another; the grounded ones on row 21, the
	# flight ones clear of the pivot row; the fall never growing and ending
	# on the ground at 8 tall at most; the head on A011's box.
	var grounded := [&"crow", &"crow_land_0", &"crow_peck_0", &"crow_peck_1", &"crow_peck_2", &"crow_death_3"]
	var aloft := [&"crow_fly_0", &"crow_fly_1", &"crow_fly_2", &"crow_fly_3", &"crow_death_0", &"crow_death_1", &"crow_death_2"]
	var shapes := {}
	var off: Array = []
	var tall := {}
	for name in grounded + aloft:
		var texture := WorldView.drawn_enemy(WorldView.ENEMY_DIR + str(name) + ".png")
		var image := texture.get_image() if texture != null else null
		if image == null:
			off.append(name)
			continue
		var used := image.get_used_rect()
		shapes[image.get_data()] = true
		tall[name] = used.size.y
		var bottom_ok := used.end.y == 22 if grounded.has(name) else used.end.y <= 22
		if image.get_size() != Vector2i(32, 24) or not bottom_ok or used.position.x < 1 or used.position.y < 1 or used.end.x > 31:
			off.append("%s %s" % [name, used])
	var head := WorldView.drawn_enemy("res://sprites/ui/head_crow.png")
	var head_used := head.get_image().get_used_rect() if head != null else Rect2i()
	# A048's own, nothing of 0120's road; its fall played as a death (task
	# 0262) though it flies untracked.
	var crow_art := (PlaceholderArt.art(&"crow_fly").is_empty() and PlaceholderArt.art(&"head_crow").is_empty()
		and head != null and head.resource_path == "res://sprites/ui/head_crow.png"
		and Enemies.flies(&"crow") and not EnemyMotion.tracks(&"crow") and EnemyDeaths.death_frames(&"crow") == 4)
	expect(off.is_empty() and crow_art and shapes.size() == grounded.size() + aloft.size()
		and int(tall[&"crow_death_1"]) <= int(tall[&"crow_death_0"]) and int(tall[&"crow_death_2"]) <= int(tall[&"crow_death_1"])
		and int(tall[&"crow_death_3"]) <= mini(int(tall[&"crow_death_2"]), 8)
		and head != null and head_used.end.y == 15 and head_used.size.x <= 13 and head_used.size.y >= 12 and head_used.size.y <= 13,
		"the crow is A048's art (task 0262): grounded on row 21, flying clear of it, every frame its own, the fall settling at 8 at most, the head on A011's box",
		"%s %s head %s" % [str(off), str(tall), str(head_used)])
	_completed += 1


## 0250 - the digger. It reaches the house through a column of fences across
## the farm without a fence losing a hit point - under them, where no tower
## can see it and no step goes back - and a column of walls makes it gnaw. The
## burrow field is never built on a night without one, and a save keeps it.
func _task_0250_digger() -> void:
	var row: Dictionary = GameData.ENEMIES[&"digger"]
	var tank: Dictionary = GameData.ENEMIES[&"tank"]
	var runner := int((GameData.ENEMIES[&"runner"] as Dictionary)["ticks_per_tile"])
	expect(bool(row["burrows"]) and int(row["ticks_per_tile"]) > runner and int(row["hp"]) < int(tank["hp"])
		and int(row.get("armour", 0)) < int(tank["armour"]) and int(row["ticks_per_tile"]) < int(tank["ticks_per_tile"])
		and not Combat.is_boss(&"digger") and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"a digger burrows, slower than the runner and inside the tank's bounds", str(row))
	var undecided: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var entry: Dictionary = GameData.DEFENCES[id]
		if int(entry.get("path_cost", 0)) > 0 and not entry.has("burrowable"):
			undecided.append(id)
	var untold := GameData.DEFENCES.duplicate(true)
	(untold[&"fence"] as Dictionary).erase("burrowable")
	var under: Array = []
	for id in [&"fence", &"barricade", &"electric_fence", &"wall", &"sandbag_wall"]:
		if Pathing.burrowable(id):
			under.append(id)
	expect(undecided.is_empty() and _says(GameData.check_defences(untold), "never says whether a digger goes under it")
		and under == [&"fence", &"barricade", &"electric_fence"],
		"every barrier says whether a digger goes under it - the fence, the barricade and the wire yes, the wall and the sandbags no - and check_defences refuses one that does not",
		"%s; under %s" % [str(undecided), str(under)])

	# **No digger, no burrow field**: a night of walkers never builds it.
	var plain := _powers_night(25001)
	Entities.spawn(plain, &"walker", Enemies.spawn_cells(plain, 0)[0])
	Sim.advance(plain, 300)
	expect(not plain.has("flow_burrow") and not plain.has("burrow_cost") and not plain.has("burrow_version"),
		"a night without a digger never builds the burrow field")

	# **Under a column of fences**: home, no fence a hit point the worse, out
	# of every tower's sight while it is under one, and never a step back.
	var fenced := _digger_column(25000, &"fence")
	expect(bool(fenced["home"]) and int(fenced["lost"]) == 0 and int(fenced["under"]) > 0
		and int(fenced["seen_under"]) == 0 and bool(fenced["onward"]),
		"a digger reaches the house through a column of fences across the farm, under them - no fence a hit point the worse, no tower picking it while it is down there, no step back",
		str(fenced))
	var walled := _digger_column(25000, &"wall")
	expect(bool(walled["home"]) and int(walled["lost"]) > 0 and int(walled["under"]) == 0,
		"a column of walls it gnaws through, as a walker does", str(walled))

	# **The burrow field's costs**: a fence costs the ground under it, a wall
	# its price; and a save keeps the field it was built with.
	var priced := _powers_night(25002)
	var post := _open_square(priced, 3, &"wall")
	var post_wall := post + Vector2i(2, 0)
	Farm.place(priced, post, {"id": &"fence", "hp": 30})
	Farm.place(priced, post_wall, {"id": &"wall", "hp": 120})
	var dug := Pathing.field(priced, &"burrow")
	var costs: PackedInt32Array = priced["burrow_cost"]
	var ground := Farm.cost_of_terrain(Farm.terrain_at(priced, post))
	var wall_ground := Farm.cost_of_terrain(Farm.terrain_at(priced, post_wall))
	var kept := State.copy(priced)
	var notes := State.reconcile(kept)
	expect(dug.size() == Grid.CELLS and int(costs[Grid.index(post)]) == ground
		and int(costs[Grid.index(post_wall)]) == wall_ground + int((GameData.DEFENCES[&"wall"] as Dictionary)["path_cost"])
		and notes.is_empty() and kept.has("flow_burrow"),
		"in the burrow field a fence costs the ground under it and a wall its price, and a save keeps the field", str(notes))

	# **Nothing that hits reaches it under a fence**: a shell's splash, a mine's
	# blast, the dog; the bell's peal does.
	var hidden := _powers_night(25003)
	(hidden["tech_owned"] as Array).append_array([&"a farm bell"])
	var gate := _open_square(hidden, 3, &"wall")
	Farm.place(hidden, gate, {"id": &"fence", "hp": 30})
	var mole := Entities.spawn(hidden, &"digger", gate)
	var whole := int(Entities.get_one(hidden, mole)["hp"])
	Towers.land_at_for_test(hidden, Building.entry_of(&"mortar"), gate)
	Farm.place(hidden, gate + Vector2i(1, 0), {"id": &"mine", "hp": 1})
	Traps.detonate_for_test(hidden, gate + Vector2i(1, 0))
	var bitten := Ability.dog_target(hidden, gate)
	var rung := Ability.use(hidden, Ability.FARM_BELL, gate)
	expect(Enemies.underground(hidden, mole) and int(Entities.get_one(hidden, mole)["hp"]) == whole and bitten == 0
		and int(Farm.occupant(hidden, gate).get("hp", 0)) == 30 and rung and Enemies.is_stunned(hidden, mole),
		"under a fence no shell, mine or dog reaches it and the fence takes nothing - the bell's peal does")

	# **The words and the voice.**
	expect(Names.of(&"digger") == I18n.t(&"ENEMY_DIGGER") and Describe.enemy(&"digger").contains(I18n.t(&"DESC_BURROWS"))
		and Sfx.ENEMY_SOUNDS.get(&"digger", &"") == &"sfx/rumble",
		"it has its name, a tooltip line that it digs, and since 0284 a voice of its own")

	# **The view**: under a fence its mound, on open ground its walk; the
	# mound drawn in code on A049's canvas - feet on row 43, centred, 14-18
	# wide and 5-7 tall with a trail of at most 8 behind, every frame its own.
	var down := WorldView.posed_off_the_rules(hidden, Entities.get_one(hidden, mole))
	var up := WorldView.posed_off_the_rules(hidden, {"id": 99, "kind": &"digger", "pos": [0, 0]})
	var mounds := {}
	var off: Array = []
	for i in 3:
		var path := WorldView.ENEMY_DIR + "digger_mound_%d.png" % i
		var drawing := WorldView.drawn_enemy(path)
		var image := drawing.get_image() if drawing != null else null
		if image == null:
			off.append(path)
			continue
		mounds[image.get_data()] = true
		var heap := Rect2i()
		for y in image.get_height():
			for x in range(0, 41):
				if image.get_pixel(x, y).a > 0.0:
					heap = heap.expand(Vector2i(x, y)) if heap.has_area() or heap.position != Vector2i.ZERO else Rect2i(x, y, 1, 1)
		var used := image.get_used_rect()
		if image.get_size() != Vector2i(64, 48) or used.end.y != 44 or used.end.x - 41 > 8 \
				or absi((heap.position.x + heap.end.x) / 2 - 32) > 1 or heap.size.x + 1 < 14 or heap.size.x + 1 > 18 \
				or heap.size.y + 1 < 5 or heap.size.y + 1 > 7:
			off.append("%s heap %s used %s" % [path, heap, used])
	expect(String(down).begins_with("digger_mound_") and String(up).begins_with("digger_walk_")
		and off.is_empty() and mounds.size() == 3,
		"under a fence it is drawn as its mound and on open ground walking; the mound sits on A049's canvas, every frame its own",
		"%s %s %s" % [down, up, str(off)])
	_completed += 1


## **A digger against a column of `with_what` across the farm** (task 0250),
## three cells in from the east spawn's road, every buildable cell of it: home
## or not, the hit points the column lost, the ticks it spent under ground,
## how often a gun tower beside it picked it there, and whether every step
## went on to a cell it had not stood on.
func _digger_column(seed_value: int, with_what: StringName) -> Dictionary:
	var state := _powers_night(seed_value)
	Pathing.refresh(state)
	var spawn: Vector2i = Enemies.spawn_cells(state, 0)[0]
	var at := spawn
	for _i in 3:
		at = Pathing.step_from(state, at)
	var hp := int((GameData.DEFENCES[with_what] as Dictionary)["hp"])
	var cells: Array = []
	for y in Grid.HEIGHT:
		var cell := Vector2i(at.x, y)
		if Farm.buildable(state, cell):
			Farm.place(state, cell, {"id": with_what, "hp": hp})
			cells.append(cell)
	Pathing.refresh(state)
	var before := int(state["house_hp"])
	var id := Entities.spawn(state, &"digger", spawn)
	var under := 0
	var seen := 0
	var onward := true
	var trail: Array = [Entities.cell_of(state, id)]
	for _t in 6000:
		Sim.advance(state, 1)
		if not Entities.alive(state, id):
			break
		var here := Entities.cell_of(state, id)
		if here != trail.back():
			onward = onward and not trail.has(here)
			trail.append(here)
		if Enemies.underground(state, id):
			under += 1
			if Towers.acquire_for(state, here + Vector2i(2, 0), GameData.DEFENCES[&"gun_tower"]) == id:
				seen += 1
	var left := 0
	for cell in cells:
		left += int(Farm.occupant(state, cell as Vector2i).get("hp", 0))
	return {"home": int(state["house_hp"]) < before, "lost": cells.size() * hp - left,
		"under": under, "seen_under": seen, "onward": onward, "cells": cells.size()}


## 0251 - the frost zombie. One killed beside two towers makes their next
## reload slower by its chill for exactly its ticks; a tower out of its reach
## is untouched, the farm's shape never moves, a save keeps the chill and the
## morning thaws it. Two bursts on one tower refresh, never stack.
func _task_0251_frost() -> void:
	var row: Dictionary = GameData.ENEMIES[&"frost_zombie"]
	var tank: Dictionary = GameData.ENEMIES[&"tank"]
	var ticks := int(row["chill_ticks"])
	var percent := int(row["chill_reload_percent"])
	var tiles := int(row["chill_tiles"])
	expect(Combat.chills(&"frost_zombie") and not Combat.chills(&"walker") and tiles >= 1 and tiles <= 3
		and percent >= 25 and percent <= 75 and ticks > 0 and int(row["hp"]) < int(tank["hp"])
		and int(row.get("armour", 0)) < int(tank["armour"]) and int(row["ticks_per_tile"]) < int(tank["ticks_per_tile"])
		and not Combat.is_boss(&"frost_zombie") and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"a frost zombie bursts over 1-3 tiles at 25-75 percent of the reload speed, inside the tank's bounds", str(row))
	var refused: Array = []
	for broken in [{"chill_tiles": 0}, {"chill_ticks": 0}, {"chill_reload_percent": 0}, {"chill_reload_percent": 100}]:
		var table := GameData.ENEMIES.duplicate(true)
		(table[&"frost_zombie"] as Dictionary).merge(broken as Dictionary, true)
		if not GameData.check_enemies(table).is_empty():
			refused.append(broken)
	expect(refused.size() == 4, "check_enemies refuses a burst over no tiles, for no time, or at a speed of 0 or 100",
		str(refused))

	# **The burst**: three gun towers in a row, the first two a tile from
	# where one is killed and the third four tiles off; a tank in reach of
	# all three to shoot at.
	var state := _powers_night(25100)
	var fell := _open_square(state, 5, &"gun_tower")
	var near_a := fell + Vector2i(-1, -1)
	var near_b := fell + Vector2i(1, -1)
	var far := fell + Vector2i(4, -1)
	var gun_hp := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])
	for at in [near_a, near_b, far]:
		Farm.place(state, at as Vector2i, {"id": &"gun_tower", "hp": gun_hp})
	var version := int(state["grid_version"])
	var frost := Entities.spawn(state, &"frost_zombie", fell)
	Combat.hit(state, frost, 999)
	var a := Farm.occupant(state, near_a)
	var b := Farm.occupant(state, near_b)
	var c := Farm.occupant(state, far)
	expect(not Entities.alive(state, frost) and Towers.chill_left(state, near_a) == ticks
		and Towers.chill_left(state, near_b) == ticks and Towers.chill_left(state, far) == 0
		and not c.has("chill") and not c.has("chill_percent") and int(state["grid_version"]) == version,
		"killed, it chills the two towers beside it for chill_ticks and not the one four tiles off - and grid_version stays put",
		"%d %d %d, version %d -> %d" % [Towers.chill_left(state, near_a), Towers.chill_left(state, near_b),
			Towers.chill_left(state, far), version, int(state["grid_version"])])
	var saved := State.copy(state)
	var notes := State.reconcile(saved)
	expect(notes.is_empty() and Towers.chill_left(saved, near_a) == ticks,
		"a save made mid-night keeps the chill: the occupants are the run's", str(notes))

	# Their next reload, shot on the same tick as the third's.
	Entities.spawn(state, &"tank", fell + Vector2i(1, 1))
	Sim.advance(state, 1)
	var normal := int(c.get("reload", 0))
	expect(normal > 0 and int(a.get("reload", 0)) == normal * 100 / percent
		and int(b.get("reload", 0)) == normal * 100 / percent,
		"their next reload is chill_reload_percent as fast as the untouched tower's, shot on the same tick",
		"%d and %d against %d" % [int(a.get("reload", 0)), int(b.get("reload", 0)), normal])
	expect(WorldView.just_fired(a) and not WorldView.just_fired(a.merged({"reload": normal}, true))
		and WorldView.chill_tint(state, near_a) != Color.WHITE and WorldView.chill_tint(state, far) == Color.WHITE,
		"the view frosts a chilled tower and not the other, and measures its flash against the slow reload it was given")

	# **For exactly chill_ticks**, counted every turn whatever the tower does.
	Sim.advance(state, ticks - 2)
	var last := Towers.chill_left(state, near_a)
	Sim.advance(state, 1)
	expect(last == 1 and Towers.chill_left(state, near_a) == 0 and not a.has("chill")
		and int(state["grid_version"]) == version,
		"the chill lasts exactly chill_ticks and goes, the farm's shape never moved", "%d at the last tick" % last)
	# And the next shot after it, at the speed it always had.
	a["reload"] = 0
	Entities.spawn(state, &"tank", near_a + Vector2i(0, 2))
	Sim.advance(state, 1)
	expect(int(a.get("reload", 0)) == normal and not a.has("chill_percent"),
		"once the chill is gone a shot reloads as it always did", str(a.get("reload", 0)))

	# **The morning thaws it**: a burst late in the night, gone at dawn.
	var frost_late := Entities.spawn(state, &"frost_zombie", fell)
	Combat.hit(state, frost_late, 999)
	var chilled_late := Towers.chill_left(state, near_b)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	expect(chilled_late == ticks and Towers.chill_left(state, near_a) == 0 and Towers.chill_left(state, near_b) == 0
		and not Farm.occupant(state, near_b).has("chill_percent"),
		"no chill outlives the night: the morning thaws every tower", str(chilled_late))

	# **Two bursts refresh, never stack**: the second, forty ticks on, starts
	# the chill again, and the reload is slowed once - asserted on the number.
	var twice := _powers_night(25101)
	var spot := _open_square(twice, 5, &"gun_tower")
	var held := spot + Vector2i(-1, -1)
	var free := spot + Vector2i(4, -1)
	Farm.place(twice, held, {"id": &"gun_tower", "hp": gun_hp})
	Farm.place(twice, free, {"id": &"gun_tower", "hp": gun_hp})
	Combat.hit(twice, Entities.spawn(twice, &"frost_zombie", spot), 999)
	Sim.advance(twice, 40)
	var between := Towers.chill_left(twice, held)
	Combat.hit(twice, Entities.spawn(twice, &"frost_zombie", spot), 999)
	var refreshed := Towers.chill_left(twice, held)
	Entities.spawn(twice, &"tank", spot + Vector2i(1, 1))
	Sim.advance(twice, 1)
	var once := int(Farm.occupant(twice, free).get("reload", 0))
	expect(between == ticks - 40 and refreshed == ticks
		and int(Farm.occupant(twice, held).get("reload", 0)) == once * 100 / percent and once > 0,
		"two bursts on one tower refresh its chill rather than stack it: its reload is slowed once",
		"%d then %d; %d against %d" % [between, refreshed, int(Farm.occupant(twice, held).get("reload", 0)), once])

	# **The words and the voice.**
	expect(Names.of(&"frost_zombie") == I18n.t(&"ENEMY_FROST_ZOMBIE")
		and Describe.enemy(&"frost_zombie").contains(I18n.t(&"DESC_CHILLS"))
		and Sfx.ENEMY_SOUNDS.get(&"frost_zombie", &"") == &"sfx/voice_frost",
		"it has its name, a tooltip line that its death slows towers, and since 0284 a voice of its own")

	# **The burst on screen**: `PixelEffects` plays the shatter where one is
	# killed inside a tick, at its body's middle - and none for one that only
	# bit the house, which was no death.
	var shown := _powers_night(25102)
	var doomed := Entities.spawn(shown, &"frost_zombie", _open_square(shown, 3, &"gun_tower"))
	var feet: Array = Entities.get_one(shown, doomed)["pos"]
	Combat.sting(shown, doomed, 999, 30)
	var forms := PixelEffects.new()
	forms.before_tick(shown, [])
	Sim.advance(shown, 1)
	forms.after_tick(shown)
	var per := float(GameData.TILE_SIZE) / float(Player.SUBTILE)
	var bursts: Array = []
	for record in forms.records:
		if StringName(record["family"]) == &"ice_shatter":
			bursts.append(record["at"])
	var middle := Vector2(int(feet[0]), int(feet[1])) * per - Vector2(0, PixelEffects.BODY_LIFT)
	var biter := _powers_night(25103)
	var porch := House.porch(biter)
	var hungry := Entities.spawn(biter, &"frost_zombie", porch)
	var watched := PixelEffects.new()
	var house_before := int(biter["house_hp"])
	for _t in 300:
		watched.before_tick(biter, [])
		Sim.advance(biter, 1)
		watched.after_tick(biter)
		if not Entities.alive(biter, hungry):
			break
	var quiet := true
	for record in watched.records:
		quiet = quiet and StringName(record["family"]) != &"ice_shatter"
	expect(not Entities.alive(shown, doomed) and bursts.size() == 1 and (bursts[0] as Vector2) == middle
		and not Entities.alive(biter, hungry) and int(biter["house_hp"]) < house_before and quiet,
		"killed in a tick it bursts into ice at its body's middle; one that bites the house bursts nothing",
		"%s against %s; bitten %s, quiet %s" % [str(bursts), str(middle), int(biter["house_hp"]) < house_before, quiet])

	# **The drawing**: A050's shatter on 24x24 round (12,12), a 1 px clear
	# border, growing to frame 1 - at most 22 by 18 - and smaller by frame 3,
	# every frame its own, in the pack's ice keys only.
	var allowed: Array = []
	for key in [&"ink", &"ink_soft", &"water_dark", &"water", &"water_light", &"moon", &"bone", &"stone_light", &"night_light"]:
		allowed.append(PaletteData.COLOURS[key])
	var counts: Array = []
	var boxes: Array = []
	var frames := {}
	var off: Array = []
	for i in 4:
		var path := FrostArt.SHATTER_PATH % i
		var texture := FrostArt.texture_at(path)
		var image := texture.get_image() if texture != null else null
		if image == null or image.get_size() != Vector2i(24, 24) \
				or PlaceholderArt.frame(path).get("pivot", Vector2i.ZERO) != Vector2i(12, 12):
			off.append(path)
			continue
		frames[image.get_data()] = true
		var used := image.get_used_rect()
		boxes.append(used)
		var count := 0
		for y in 24:
			for x in 24:
				var colour := image.get_pixel(x, y)
				if colour.a <= 0.0:
					continue
				count += 1
				if not allowed.has(colour):
					off.append("%s: %s at %d,%d" % [path, colour, x, y])
		counts.append(count)
		if used.position.x < 1 or used.position.y < 1 or used.end.x > 23 or used.end.y > 23:
			off.append("%s off its border: %s" % [path, used])
	expect(off.is_empty() and frames.size() == 4 and int(counts[0]) < int(counts[1]) and int(counts[3]) < int(counts[1])
		and (boxes[1] as Rect2i).size.x <= 22 and (boxes[1] as Rect2i).size.y <= 18
		and (boxes[3] as Rect2i).get_area() < (boxes[1] as Rect2i).get_area(),
		"the ice burst sits on A050's canvas, grows to its widest and fades, every frame its own, in the ice's keys",
		"%s %s %s" % [str(off), str(counts), str(boxes)])
	_completed += 1


## 0252 - the wraith. A gun tower lets one walk past it in the dark and shoots
## it on the first tick it stands in a searchlight's square, a flare's burst or
## a fire under it; a shot already in the air still lands; and what does not
## aim - a shell's splash, a mine, the dog's nose - finds it in the dark.
func _task_0252_wraith() -> void:
	var row: Dictionary = GameData.ENEMIES[&"wraith"]
	var tank: Dictionary = GameData.ENEMIES[&"tank"]
	expect(Enemies.needs_light(&"wraith") and not Enemies.needs_light(&"walker") and int(row["hp"]) < int(tank["hp"])
		and int(row.get("armour", 0)) < int(tank["armour"]) and int(row["ticks_per_tile"]) < int(tank["ticks_per_tile"])
		and int(row["hp"]) > int(GameData.ABILITY["damage"]) and not Combat.is_boss(&"wraith")
		and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"a wraith needs light to be aimed at, outlives a flare's burst, and sits inside the tank's bounds", str(row))

	# **Past a gun tower in the dark, shot on the first tick it stands lit**:
	# in the searchlight's square, in a flare's burst, with a fire under it.
	for light in [&"searchlight", &"flare", &"fire"]:
		var run := _wraith_past_a_tower(25200 + ["searchlight", "flare", "fire"].find(String(light)), light)
		expect(int(run["dark_in_reach"]) > 0 and int(run["shot_in_dark"]) == 0 and int(run["first_lit"]) >= 0
			and int(run["shot_at"]) == int(run["first_lit"]) and String(run["source"]) == String(light),
			"a gun tower lets a wraith walk past it in the dark and shoots it on the first tick it stands lit by the %s" % light,
			str(run))
		if light == &"searchlight":
			expect(bool(run["landed_in_dark"]),
				"the shot already in the air lands, though the lamp came down under it", str(run))

	# **What does not aim finds it in the dark**: no tower picks it and
	# `worth_shooting` passes it over, but the dog goes by its nose, a shell's
	# splash lands on it and a mine's blast reaches it.
	var dark := _powers_night(25203)
	var spot := _open_square(dark, 3, &"gun_tower")
	var shade := Entities.spawn(dark, &"wraith", spot)
	var whole := int(Entities.get_one(dark, shade)["hp"])
	var unseen := not Light.is_lit(dark, spot) and not Enemies.in_sight(dark, shade) and not Combat.worth_shooting(dark, shade) \
		and Towers.acquire_for(dark, spot + Vector2i(2, 1), GameData.DEFENCES[&"gun_tower"]) == 0
	var sniffed := Ability.dog_target(dark, spot) == shade
	Towers.land_at_for_test(dark, Building.entry_of(&"mortar"), spot)
	var shelled := not Entities.alive(dark, shade) or int(Entities.get_one(dark, shade)["hp"]) < whole
	# The mine on a night of its own, so the shell has not already done it.
	var mined := _powers_night(25205)
	var other := Entities.spawn(mined, &"wraith", spot)
	Farm.place(mined, spot + Vector2i(1, 0), {"id": &"mine", "hp": 1})
	Traps.detonate_for_test(mined, spot + Vector2i(1, 0))
	var blasted := not Entities.alive(mined, other) or int(Entities.get_one(mined, other)["hp"]) < whole
	expect(unseen and sniffed and shelled and blasted,
		"in the dark no tower aims at it, but the dog's nose, a shell's splash and a mine's blast find it",
		"unseen %s, dog %s, shell %s, mine %s" % [unseen, sniffed, shelled, blasted])

	# **The view asks the same rule, writing nothing** (`Light.lit_now`): the
	# same answer as `is_lit` on a row of cells across a lamp's square, and
	# the cache untouched until the rules ask.
	var lamps := _powers_night(25204)
	var lamp := _open_square(lamps, 5, &"searchlight")
	Farm.place(lamps, lamp, {"id": &"searchlight", "hp": int((GameData.DEFENCES[&"searchlight"] as Dictionary)["hp"])})
	var stamp: Array = (lamps["light_for"] as Array).duplicate()
	var seen: Array = []
	for dx in range(-7, 8):
		seen.append(Light.lit_now(lamps, lamp + Vector2i(dx, 1)))
	var untouched: bool = lamps["light_for"] == stamp
	var agree := true
	for dx in range(-7, 8):
		agree = agree and bool(seen[dx + 7]) == Light.is_lit(lamps, lamp + Vector2i(dx, 1))
	expect(untouched and agree and seen.has(true) and seen.has(false)
		and WorldView.wraith_presence(true) == 1.0 and WorldView.wraith_presence(false) == WorldView.WRAITH_FAINT
		and WorldView.WRAITH_FAINT > 0.0 and WorldView.WRAITH_FAINT < 1.0,
		"the view's light is the rules' light, asked without writing; a wraith shows solid in it and faint - never gone - outside",
		"%s %s %s" % [untouched, agree, str(seen)])

	# **The words and the voice.**
	expect(Names.of(&"wraith") == I18n.t(&"ENEMY_WRAITH") and Describe.enemy(&"wraith").contains(I18n.t(&"DESC_NEEDS_LIGHT"))
		and Sfx.ENEMY_SOUNDS.get(&"wraith", &"") == &"sfx/whisper",
		"it has its name, a tooltip line that it can only be aimed at in light, and since 0284 a voice of its own")
	_completed += 1


## **A wraith from the east spawn past a gun tower** (task 0252): the tower two
## cells beside its road at the fifth step, in reach of it in the dark, and
## `light` coming on where it walks - `searchlight`, a lamp two cells beside its
## road about its eleventh step, on the first open ground there (a tree stood
## on the first try), whose square starts four steps short of it; `flare` set
## off on it and
## `fire` set under it once it has walked twenty ticks in reach in the dark.
## The ticks it spent in reach and dark, shots fired at it in the dark, the
## first tick it stood lit and the tick the tower first fired at it, what lit
## it, and - the lamp's - whether that shot landed after the lamp came down.
func _wraith_past_a_tower(seed_value: int, light: StringName) -> Dictionary:
	var state := _powers_night(seed_value)
	Pathing.refresh(state)
	var road: Array = [Enemies.spawn_cells(state, 0)[0]]
	for _i in 14:
		road.append(Pathing.step_from(state, road.back() as Vector2i))
	var heading: Vector2i = (road[5] as Vector2i) - (road[4] as Vector2i)
	var side := Vector2i(heading.y, heading.x) * 2
	if not Farm.buildable(state, (road[4] as Vector2i) + side):
		side = -side
	var tower: Vector2i = (road[4] as Vector2i) + side
	Farm.place(state, tower, {"id": &"gun_tower", "hp": int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])})
	var lamp := Vector2i(-1, -1)
	if light == &"searchlight":
		for k in [10, 11, 12, 9]:
			for s in [side, -side]:
				var at: Vector2i = (road[k] as Vector2i) + (s as Vector2i)
				if lamp.x < 0 and Farm.buildable(state, at):
					lamp = at
		Farm.place(state, lamp, {"id": &"searchlight", "hp": int((GameData.DEFENCES[&"searchlight"] as Dictionary)["hp"])})
	Pathing.refresh(state)
	var gun: Dictionary = GameData.DEFENCES[&"gun_tower"]
	var id := Entities.spawn(state, &"wraith", road[0] as Vector2i)
	var out := {"dark_in_reach": 0, "shot_in_dark": 0, "first_lit": -1, "shot_at": -1, "source": "",
		"landed_in_dark": false}
	var hp_at_shot := -1
	for t in 600:
		var before := int(state["shots_fired"])
		Sim.advance(state, 1)
		if not Entities.alive(state, id):
			break
		var here := Entities.cell_of(state, id)
		var fired := int(state["shots_fired"]) > before
		if not Light.is_lit(state, here):
			if Grid.chebyshev(here, tower) <= Towers.reach_of(state, gun, tower):
				out["dark_in_reach"] = int(out["dark_in_reach"]) + 1
			if fired and int(out["first_lit"]) < 0:
				out["shot_in_dark"] = int(out["shot_in_dark"]) + 1
			# The flare and the fire come on after twenty ticks of it in reach
			# in the dark, the tower looking straight at it.
			if int(out["first_lit"]) < 0 and int(out["dark_in_reach"]) == 20:
				if light == &"flare":
					Ability.use(state, Ability.FLARE, here)
				elif light == &"fire":
					Combat.set_alight(state, id, 1, 10 * GameData.SECONDS)
		elif int(out["first_lit"]) < 0:
			out["first_lit"] = t
			out["source"] = "searchlight" if Light.lamp_tiles(state, lamp) > 0 \
				and Grid.chebyshev(lamp, here) <= Light.lamp_tiles(state, lamp) \
				else ("flare" if not Ability.aimed_at(state, Ability.FLARE).is_empty()
				else ("fire" if Combat.is_burning(state, id) else "porch"))
		if fired and int(out["shot_at"]) < 0:
			out["shot_at"] = t
			hp_at_shot = int(Entities.get_one(state, id)["hp"])
			if light == &"searchlight":
				# **The lamp comes down under the shot in the air.**
				Farm.remove(state, lamp)
		if int(out["shot_at"]) >= 0:
			var flying := false
			for shot in (state["projectiles"] as Array):
				flying = flying or int((shot as Dictionary)["target"]) == id
			if not flying:
				out["landed_in_dark"] = int(Entities.get_one(state, id)["hp"]) < hp_at_shot \
					and not Light.is_lit(state, Entities.cell_of(state, id))
				break
	return out


## 0253 - the Harvester. Its line is fixed when the wind-up starts and the
## wind-up lasts its telegraph's ticks; three stone layers fall to one charge
## and a hardwood wall holds it; it never crosses water; three walls brought
## down on one tick cost the fields one rebuild; sealed in, it still reaches
## the house; killing it moves its tally; Summer 14 is its night.
func _task_0253_harvester() -> void:
	var row: Dictionary = GameData.ENEMIES[&"harvester"]
	var telegraph := int(row["telegraph_ticks"])
	var crush := int(row["crush_damage"])
	var stone := int((GameData.DEFENCES[&"wall"] as Dictionary)["hp"])
	var hardwood := Building.levelled_stat({"id": &"wall", "level": 2}, "hp")
	var refused: Array = []
	for key in ["charge_every_ticks", "charge_tiles", "charge_ticks_per_tile", "crush_damage", "telegraph_ticks"]:
		for broken in ["zero", "gone"]:
			var table := GameData.ENEMIES.duplicate(true)
			if broken == "gone":
				(table[&"harvester"] as Dictionary).erase(key)
			else:
				(table[&"harvester"] as Dictionary)[key] = 0
			if _says(GameData.check_enemies(table), "charges with no %s" % key):
				refused.append("%s %s" % [key, broken])
	var slow := GameData.ENEMIES.duplicate(true)
	(slow[&"harvester"] as Dictionary)["charge_ticks_per_tile"] = int(row["ticks_per_tile"])
	expect(Combat.is_boss(&"harvester") and crush > stone and crush < hardwood and refused.size() == 10
		and _says(GameData.check_enemies(slow), "charges no faster than it walks")
		and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"the Harvester is a boss whose crush brings a stone wall down and leaves the hardwood one standing; check_enemies refuses a charger missing a lever, with one at zero, or charging no faster than it rolls",
		"%d against %d and %d; %s" % [crush, stone, hardwood, str(refused)])

	# **One charge down its line**: three stone layers on its second, third
	# and fourth cells and a hardwood wall on its sixth; a fourth stone wall
	# laid on its first cell while it winds up.
	var state := _powers_night(25300)
	var spot := _open_square(state, 6, &"wall")
	var dir := Enemies.charge_direction(state, spot)
	for k in [2, 3, 4]:
		Farm.place(state, spot + dir * int(k), {"id": &"wall", "hp": stone})
	var holding := spot + dir * 6
	Farm.place(state, holding, {"id": &"wall", "hp": hardwood, "level": 2})
	Pathing.refresh(state)
	var boss := Entities.spawn(state, &"harvester", spot)
	(Entities.get_one(state, boss))["charge_in"] = 1
	Sim.advance(state, 1)
	var line := Enemies.charge_line(state, boss)
	var rearing := WorldView.posed_off_the_rules(state, Entities.get_one(state, boss))
	var wound := 0
	while Enemies.is_winding(state, boss) and wound < 1000:
		wound += 1
		if wound == telegraph / 2:
			Farm.place(state, spot + dir, {"id": &"wall", "hp": stone})
		Sim.advance(state, 1)
	var running := WorldView.posed_off_the_rules(state, Entities.get_one(state, boss))
	var crossed: Array = [Entities.cell_of(state, boss)]
	var ran := 0
	while Entities.alive(state, boss) and Entities.get_one(state, boss).has("charge_dir") and ran < 200:
		Sim.advance(state, 1)
		ran += 1
		var at := Entities.cell_of(state, boss)
		if crossed.back() != at:
			crossed.append(at)
	var want_line: Array = []
	var want_crossed: Array = [spot]
	for k in range(1, 7):
		want_line.append(spot + dir * k)
		if k < 6:
			want_crossed.append(spot + dir * k)
	var down := true
	for k in [1, 2, 3, 4]:
		down = down and Farm.occupant(state, spot + dir * int(k)).is_empty() \
			and Farm.rubble_at(state, spot + dir * int(k)) == &"wall"
	expect(wound == telegraph and line == want_line and crossed == want_crossed and down
		and int(Farm.occupant(state, holding).get("hp", 0)) == hardwood - crush
		and String(rearing).begins_with("harvester_windup_") and String(running).begins_with("harvester_charge_"),
		"fixed when the wind-up starts, the wind-up lasts telegraph_ticks; then it runs its line through four stone walls - the one laid while it wound up too - and stops before the hardwood, which loses crush_damage and holds",
		"wound %d, line %s, crossed %s, hardwood %d, %s / %s" % [wound, str(line), str(crossed),
			int(Farm.occupant(state, holding).get("hp", 0)), rearing, running])

	# **It never crosses water**: three cells of land and then the pond on its
	# line - it stops on the shore.
	var wet := _powers_night(25301)
	var pond := Vector2i(-1, -1)
	var way := Vector2i.ZERO
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if pond.x >= 0 or Farm.terrain_at(wet, cell) != Farm.Terrain.WATER:
			continue
		var d := Enemies.charge_direction(wet, cell)
		if d == Vector2i.ZERO or Enemies.charge_direction(wet, cell - d * 3) != d:
			continue
		var dry := true
		for k in [1, 2, 3]:
			dry = dry and Enemies.charge_meets(wet, cell - d * int(k)) == Enemies.CHARGE_ON
		if dry:
			pond = cell
			way = d
	var swimmer := Entities.spawn(wet, &"harvester", pond - way * 3)
	(Entities.get_one(wet, swimmer))["charge_in"] = 1
	Sim.advance(wet, 1)
	var shore_line := Enemies.charge_line(wet, swimmer)
	var touched_water := false
	for _t in 300:
		Sim.advance(wet, 1)
		touched_water = touched_water or Farm.terrain_at(wet, Entities.cell_of(wet, swimmer)) == Farm.Terrain.WATER
		if not Entities.get_one(wet, swimmer).has("charge_dir"):
			break
	expect(pond.x >= 0 and shore_line == [pond - way * 2, pond - way] and not touched_water
		and Entities.cell_of(wet, swimmer) == pond - way,
		"a charge at a pond stops on the shore: its line ends there and it never stands in the water",
		"%s %s at %s" % [str(pond), str(shore_line), str(Entities.cell_of(wet, swimmer))])

	# **Three walls down on one tick, one rebuild**: three Harvesters charging
	# side by side, a stone wall two cells down each line - the fields are
	# rebuilt once, at the next tick's refresh, not once a wall.
	var three := _powers_night(25302)
	var middle := _open_square(three, 6, &"wall")
	var ahead := Enemies.charge_direction(three, middle)
	var across := Vector2i(ahead.y, ahead.x)
	var bosses: Array = []
	var aligned := true
	for k in [-2, 0, 2]:
		var from: Vector2i = middle + across * int(k)
		aligned = aligned and Enemies.charge_direction(three, from) == ahead
		Farm.place(three, from + ahead * 2, {"id": &"wall", "hp": stone})
		bosses.append(Entities.spawn(three, &"harvester", from))
	Pathing.refresh(three)
	for id in bosses:
		(Entities.get_one(three, int(id)))["charge_in"] = 1
	var fell := 0
	var built_during := -1
	var grid_after := -1
	for _t in 300:
		var grid_before := int(three["grid_version"])
		Sim.advance(three, 1)
		fell = int(three["grid_version"]) - grid_before
		if fell > 0:
			built_during = int(three["flow_version"]) - grid_before
			grid_after = int(three["grid_version"])
			break
	Sim.advance(three, 1)
	expect(aligned and fell == 3 and built_during == 0 and int(three["flow_version"]) == grid_after,
		"three walls brought down by three charges on one tick rebuild the fields once, at the next tick's refresh",
		"%s: %d fell, flow %d behind during, then %d against %d" % [aligned, fell, built_during,
			int(three["flow_version"]), grid_after])

	# **Sealed in a ring of stone walls, it still reaches the house**; and
	# killing one moves its tally.
	var sealed := _powers_night(25303)
	var pen := _open_square(sealed, 4, &"wall")
	for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		Farm.place(sealed, pen + (step as Vector2i), {"id": &"wall", "hp": stone})
	Pathing.refresh(sealed)
	var penned := Entities.spawn(sealed, &"harvester", pen)
	var roof := int(sealed["house_hp"])
	for _t in 9000:
		Sim.advance(sealed, 1)
		if not Entities.alive(sealed, penned):
			break
	var tally := Combat.bosses_down_of(sealed, &"harvester")
	var victim := Entities.spawn(sealed, &"harvester", pen)
	Combat.hit(sealed, victim, 1 << 20)
	expect(int(sealed["house_hp"]) < roof and not Entities.alive(sealed, penned)
		and Combat.bosses_down_of(sealed, &"harvester") == tally + 1,
		"sealed in a ring of stone walls it still reaches the house and bites it; killing one moves bosses_down_of(harvester)",
		"%d of %d" % [int(sealed["house_hp"]), roof])

	# **Summer 14 is its night**, and Spring 14 still the Giant's; its words
	# and its voice.
	var summer := 2 * GameData.SEASON_DAYS
	expect(GameData.SEASON_BOSSES[1] == &"harvester" and Calendar.boss_of(summer) == &"harvester"
		and Calendar.boss_of(GameData.SEASON_DAYS) == &"giant"
		and StringName(Waves.night_of(summer).get("boss", &"")) == &"harvester" and Waves.kinds_of(summer).has(&"harvester")
		and Names.of(&"harvester") == I18n.t(&"ENEMY_HARVESTER") and Names.boss_intro(&"harvester") == I18n.t(&"BOSS_INTRO_HARVESTER")
		and Describe.enemy(&"harvester").contains(I18n.t(&"DESC_CHARGES")) and Sfx.voice_of(&"harvester") == &"sfx/engine",
		"Summer 14 is the Harvester's night and Spring 14 still the Giant's; it has its name, its intro, a tooltip line that it charges, and since 0284 a voice of its own")
	_completed += 1


## 0254 - the Scarecrow King. Each cast raises `flock_size` crows on the
## listed cells after exactly `telegraph_ticks`, two runs agree cell for cell,
## and no night raises more than `summon_cap`; a field with no cover in the
## air loses crops to the flock and one with it few; the flock is no wave's
## and the night's: no bounty, no bones, and the night waits for it.
func _task_0254_scarecrow_king() -> void:
	var row: Dictionary = GameData.ENEMIES[&"scarecrow_king"]
	var telegraph := int(row["telegraph_ticks"])
	var flock := int(row["flock_size"])
	var cap := int(row["summon_cap"])
	var big := GameData.ENEMIES.duplicate(true)
	(big[&"scarecrow_king"] as Dictionary)["flock_size"] = GameData.SUMMON_OFFSETS.size() + 1
	var small := GameData.ENEMIES.duplicate(true)
	(small[&"scarecrow_king"] as Dictionary)["summon_cap"] = flock - 1
	var walking := GameData.ENEMIES.duplicate(true)
	(walking[&"scarecrow_king"] as Dictionary)["summons"] = &"walker"
	expect(Combat.is_boss(&"scarecrow_king") and StringName(row["summons"]) == &"crow" and flock <= GameData.SUMMON_OFFSETS.size()
		and cap >= flock and _says(GameData.check_enemies(big), "SUMMON_OFFSETS has")
		and _says(GameData.check_enemies(small), "less than one flock") and _says(GameData.check_enemies(walking), "which does not fly")
		and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"the King is a boss that summons crows; check_enemies refuses a flock bigger than the offsets, a night's cap under a flock, and a summoned kind that walks",
		"%d of %d, cap %d" % [flock, GameData.SUMMON_OFFSETS.size(), cap])

	# **The casts**: each `telegraph_ticks` long, each flock on the listed
	# cells round where it cast, until the night's cap - twice, cell for cell.
	var first := _king_casts(25400)
	var second := _king_casts(25400)
	var exact := true
	for i in (first["casts"] as Array).size():
		var cast: Dictionary = (first["casts"] as Array)[i]
		var want: Array = []
		for offset in GameData.SUMMON_OFFSETS:
			var at: Vector2i = (cast["from"] as Vector2i) + (offset as Vector2i)
			if want.size() < mini(flock, cap - flock * i) and Grid.in_bounds(at):
				want.append(at)
		exact = exact and int(cast["ticks"]) == telegraph and cast["cells"] == want \
			and cast["marked"] == want and String(cast["pose"]).begins_with("scarecrow_king_cast_")
	expect(exact and (first["casts"] as Array).size() == ceili(float(cap) / float(flock))
		and int(first["raised"]) == cap and bool(first["summoned"]) and bool(first["waves_untouched"])
		and first["casts"] == second["casts"],
		"each cast stands telegraph_ticks, cast pose and marks on the cells, then raises its flock on the listed cells; no night raises more than summon_cap; two runs agree cell for cell, and the waves' own counts never move",
		"%s raised %d" % [str(first["casts"]).left(400), int(first["raised"])])

	# **Cover in the air**: the same field and the same King, once with no
	# tower that hits what flies and once with gun towers round it.
	var bare := _king_over_a_field(25401, false)
	var covered := _king_over_a_field(25401, true)
	print("  0254: the flock took %d crops off a field with no cover in the air, %d off one with gun towers round it" % [bare, covered])
	expect(bare > 0 and covered < bare,
		"a King's flock costs a field with no cover in the air crops, and one with gun towers round it fewer",
		"%d bare, %d covered" % [bare, covered])

	# **The flock is the King's, not the night's**: a summoned crow killed is a
	# kill, but pays no bounty and leaves no bones - a wave's crow does both;
	# and with the waves done the night waits for the flock.
	var night := _powers_night(25402)
	var spot := _open_square(night, 3, &"wall")
	var wild := Entities.spawn(night, &"crow", spot)
	var raised := Entities.spawn(night, &"crow", spot + Vector2i(2, 0))
	(Entities.get_one(night, raised))["summoned"] = true
	var tally: Dictionary = (night["killed_by_kind"] as Dictionary).duplicate()
	var kills := int(night["killed"])
	var run := int(night["killed_all_run"])
	var piles := (night["loot"] as Dictionary).size()
	Combat.hit(night, raised, 999)
	var after_raised := [int((night["killed_by_kind"] as Dictionary).get(&"crow", 0)), int(night["killed"]),
		int(night["killed_all_run"]), (night["loot"] as Dictionary).size()]
	Combat.hit(night, wild, 999)
	var flown := Entities.spawn(night, &"crow", spot + Vector2i(0, 2))
	(Entities.get_one(night, flown))["summoned"] = true
	(night["wave"] as Dictionary)["done"] = true
	Sim.advance(night, 1)
	var waited := int(night["phase"]) == Phases.NIGHT
	Combat.hit(night, flown, 999)
	Sim.advance(night, 1)
	expect(after_raised == [int(tally.get(&"crow", 0)), kills + 1, run + 1, piles]
		and int((night["killed_by_kind"] as Dictionary).get(&"crow", 0)) == int(tally.get(&"crow", 0)) + 1
		and waited and int(night["phase"]) == Phases.RESULT,
		"a summoned crow killed is a kill but pays no bounty and leaves no bones, where a wave's crow counts; with the waves done the night waits for the flock and ends when it is dead",
		"%s; waited %s" % [str(after_raised), waited])

	# **Autumn 14 is its night**; its words and voice.
	var autumn := 3 * GameData.SEASON_DAYS
	expect(GameData.SEASON_BOSSES[2] == &"scarecrow_king" and Calendar.boss_of(autumn) == &"scarecrow_king"
		and StringName(Waves.night_of(autumn).get("boss", &"")) == &"scarecrow_king"
		and Calendar.boss_of(2 * GameData.SEASON_DAYS) == &"harvester" and Calendar.boss_of(GameData.SEASON_DAYS) == &"giant"
		and Names.of(&"scarecrow_king") == I18n.t(&"ENEMY_SCARECROW_KING")
		and Names.boss_intro(&"scarecrow_king") == I18n.t(&"BOSS_INTRO_SCARECROW_KING")
		and Describe.enemy(&"scarecrow_king").contains(I18n.t(&"DESC_SUMMONS"))
		and Sfx.voice_of(&"scarecrow_king") == &"sfx/king_call",
		"Autumn 14 is the Scarecrow King's night; it has its name, its intro, a tooltip line that it calls down crows, and since 0284 a voice of its own")
	_completed += 1


## **A King's casts until its night's cap** (task 0254): on open ground in a
## parked night, ringed in hardwood so it stays put, its clock run out each
## time it walks again. For each cast, where it stood, the ticks from its
## start to its flock, the cells the flock rose on and the cells the view was
## told while it cast, and its pose then; how many rose in all, whether every
## one is `summoned`, and whether the waves' own counts stayed put - what is
## left of the wave, which wave, whether they are done (the first try
## compared the whole record, and a parked night's wait runs down every tick).
func _king_casts(seed_value: int) -> Dictionary:
	var state := _powers_night(seed_value)
	var spot := _open_square(state, 4, &"wall")
	_ring_in_hardwood(state, spot)
	var king := Entities.spawn(state, &"scarecrow_king", spot)
	# The waves' own counts - what is left of this one, which one, whether
	# they are done; their wait runs down whatever happens.
	var counts := func() -> Array:
		var wave: Dictionary = state["wave"]
		return [int(wave["left"]), int(wave["index"]), bool(wave["done"])]
	var before_counts: Array = counts.call()
	var casts: Array = []
	var summoned := true
	for _try in 8:
		(Entities.get_one(state, king))["summon_in"] = 1
		var before := Entities.ids(state)
		Sim.advance(state, 1)
		if not Enemies.is_casting(state, king):
			break
		var from := Grid.cell(int(Entities.get_one(state, king)["casting"]))
		var marked := Enemies.flock_cells(state, king)
		var pose := WorldView.posed_off_the_rules(state, Entities.get_one(state, king))
		var ticks := 1
		while Enemies.is_casting(state, king) and ticks < 1000:
			Sim.advance(state, 1)
			ticks += 1
		var cells: Array = []
		for id in Entities.ids(state):
			if not before.has(id) and int(id) != king:
				cells.append(Entities.cell_of(state, int(id)))
				summoned = summoned and Enemies.is_summoned(state, int(id))
		casts.append({"from": from, "ticks": ticks - 1, "cells": cells, "marked": marked, "pose": pose})
	return {"casts": casts, "raised": int(Entities.get_one(state, king).get("raised", 0)),
		"summoned": summoned, "waves_untouched": counts.call() == before_counts}


## **A King and its flock over a planted field** (task 0254): the starter
## field sown with carrots, the King ringed in hardwood a dozen tiles east of
## it, its casts on their own clock; `covered` puts gun towers - which hit
## what flies - on the open ground round the field. How many crops the flock
## had eaten after a minute and a half.
func _king_over_a_field(seed_value: int, covered: bool) -> int:
	var state := _powers_night(seed_value)
	var field := Farming.field_cells(state)
	for cell in field:
		_sow(state, cell as Vector2i, &"carrot")
	var lo := field[0] as Vector2i
	var hi := field[0] as Vector2i
	for cell in field:
		lo = Vector2i(mini(lo.x, (cell as Vector2i).x), mini(lo.y, (cell as Vector2i).y))
		hi = Vector2i(maxi(hi.x, (cell as Vector2i).x), maxi(hi.y, (cell as Vector2i).y))
	if covered:
		for at in [Vector2i(lo.x - 2, lo.y - 2), Vector2i(hi.x + 2, lo.y - 2), Vector2i(lo.x - 2, hi.y + 2),
				Vector2i(hi.x + 2, hi.y + 2), Vector2i((lo.x + hi.x) / 2, lo.y - 2), Vector2i((lo.x + hi.x) / 2, hi.y + 2)]:
			if Farm.buildable(state, at as Vector2i):
				Farm.place(state, at as Vector2i, {"id": &"gun_tower", "hp": int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])})
	var lair := Vector2i(hi.x + 12, (lo.y + hi.y) / 2)
	for dx in 8:
		if not Farm.buildable(state, lair):
			lair.x += 1
	_ring_in_hardwood(state, lair)
	Pathing.refresh(state)
	Entities.spawn(state, &"scarecrow_king", lair)
	Sim.advance(state, 90 * GameData.SECONDS)
	var eaten := 0
	for cell in field:
		if Farming.crop_on(state, cell as Vector2i) == &"":
			eaten += 1
	return eaten


## Eight hardwood walls round `cell` (task 0254), on what of them will go down.
func _ring_in_hardwood(state: Dictionary, cell: Vector2i) -> void:
	var hp := Building.levelled_stat({"id": &"wall", "level": 2}, "hp")
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				Farm.place(state, cell + Vector2i(int(dx), int(dy)), {"id": &"wall", "hp": hp, "level": 2})


## 0255 - the Winter Lord. A cast freezes exactly the towers inside
## `aura_tiles` for `freeze_ticks` - their reloads held, no shot - with
## `grid_version` still, and every tower fires again afterwards; a second
## freeze refreshes and never stacks; dawn thaws them; it is the strongest
## boss, and Winter 14 is its night.
func _task_0255_winter_lord() -> void:
	var row: Dictionary = GameData.ENEMIES[&"winter_lord"]
	var telegraph := int(row["telegraph_ticks"])
	var aura := int(row["aura_tiles"])
	var freeze := int(row["freeze_ticks"])
	var weaker: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if kind != &"winter_lord" and Combat.is_boss(kind) and int((GameData.ENEMIES[kind] as Dictionary)["hp"]) >= int(row["hp"]):
			weaker.append(kind)
	var refused: Array = []
	for key in ["freeze_every_ticks", "aura_tiles", "freeze_ticks", "telegraph_ticks"]:
		var table := GameData.ENEMIES.duplicate(true)
		(table[&"winter_lord"] as Dictionary)[key] = 0
		if _says(GameData.check_enemies(table), "freezes with no %s" % key):
			refused.append(key)
	expect(Combat.is_boss(&"winter_lord") and weaker.is_empty() and refused.size() == 4
		and int(row["hp"]) > int((GameData.ENEMIES[&"harvester"] as Dictionary)["hp"])
		and int(row["hp"]) > int((GameData.ENEMIES[&"scarecrow_king"] as Dictionary)["hp"])
		and GameData.check_enemies(GameData.ENEMIES).is_empty(),
		"the Winter Lord is the strongest boss in the table - more than the Harvester and the King - and check_enemies refuses a freeze with any lever at zero",
		"%s %s" % [str(weaker), str(refused)])

	# **One cast**: gun towers two and three tiles from where it stands - in
	# its aura - and four and five tiles off; the Lord the one they shoot.
	var state := _powers_night(25500)
	var spot := _open_square(state, 6, &"wall")
	var gun_hp := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])
	var inside: Array = [spot + Vector2i(2, 0), spot + Vector2i(-3, 1), spot + Vector2i(0, -3)]
	var outside: Array = [spot + Vector2i(4, 0), spot + Vector2i(-2, 5)]
	for at in inside + outside:
		Farm.place(state, at as Vector2i, {"id": &"gun_tower", "hp": gun_hp})
	_ring_in_hardwood(state, spot)
	Pathing.refresh(state)
	var lord := Entities.spawn(state, &"winter_lord", spot)
	(Entities.get_one(state, lord))["freeze_in"] = 1
	Sim.advance(state, 1)
	var square := Enemies.aura_cells(state, lord)
	var flashing := Enemies.is_winding(state, lord)
	var pose := WorldView.posed_off_the_rules(state, Entities.get_one(state, lord))
	var cast := 1
	while Enemies.is_freezing(state, lord) and cast < 1000:
		Sim.advance(state, 1)
		cast += 1
	var version := int(state["grid_version"])
	var froze := true
	# The tick it lands is the freeze's first turn: it lands in the enemies'
	# turn, before the towers'.
	for at in inside:
		froze = froze and Towers.frozen_left(state, at as Vector2i) == freeze - 1 \
			and WorldView.chill_tint(state, at as Vector2i) == WorldView.FROZEN_TINT
	for at in outside:
		froze = froze and Towers.frozen_left(state, at as Vector2i) == 0 \
			and not Farm.occupant(state, at as Vector2i).has("frozen")
	expect(cast - 1 == telegraph and flashing and String(pose).begins_with("winter_lord_cast_")
		and square.size() == (2 * aura + 1) * (2 * aura + 1) and square.has(spot + Vector2i(aura, aura))
		and not square.has(spot + Vector2i(aura + 1, 0)) and froze,
		"a cast stands telegraph_ticks, its bar flashing and its reach on the ground, then freezes exactly the towers inside aura_tiles for freeze_ticks",
		"cast %d, %d cells, %s" % [cast - 1, square.size(), pose])
	# Held: their reloads do not count and they do not fire, for exactly
	# `freeze_ticks`; the others go on firing; then every one fires again.
	# The Lord stunned from here - a target still - so its gnawing at the
	# hardwood round it moves no grid under the count (the first run's did).
	Enemies.stun(state, lord, 100 * GameData.SECONDS)
	var held: Dictionary = {}
	for at in inside:
		held[at] = int(Farm.occupant(state, at as Vector2i).get("reload", 0))
	var still := true
	for _t in freeze - 2:
		Sim.advance(state, 1)
		for at in inside:
			still = still and int(Farm.occupant(state, at as Vector2i).get("reload", 0)) == int(held[at])
	var last := Towers.frozen_left(state, inside[0] as Vector2i)
	Sim.advance(state, 1)
	for at in inside:
		still = still and int(Farm.occupant(state, at as Vector2i).get("reload", 0)) == int(held[at])
	var thawed := Towers.frozen_left(state, inside[0] as Vector2i) == 0
	var fired_again: Dictionary = {}
	var fired_outside := false
	var before: Dictionary = {}
	for at in inside + outside:
		before[at] = int(Farm.occupant(state, at as Vector2i).get("reload", 0))
	for _t in 3 * GameData.SECONDS:
		Sim.advance(state, 1)
		for at in inside + outside:
			var now := int(Farm.occupant(state, at as Vector2i).get("reload", 0))
			if now > int(before[at]):
				if inside.has(at):
					fired_again[at] = true
				else:
					fired_outside = true
			before[at] = now
	expect(still and last == 1 and thawed and fired_again.size() == inside.size() and fired_outside
		and int(state["grid_version"]) == version,
		"frozen, their reloads hold for exactly freeze_ticks while the others fire; then every one fires again, and grid_version never moved",
		"held %s, last %d, thawed %s, again %s, outside %s, grid %d against %d" % [still, last, thawed,
			str(fired_again.keys()), fired_outside, int(state["grid_version"]), version])

	# **Refreshed, never stacked; thawed at dawn.**
	Towers.freeze_around(state, spot, aura, freeze)
	Sim.advance(state, 10)
	Towers.freeze_around(state, spot, aura, freeze)
	var refreshed := Towers.frozen_left(state, inside[0] as Vector2i)
	Phases.enter_result(state, true)
	Phases.begin_day(state)
	expect(refreshed == freeze and Towers.frozen_left(state, inside[0] as Vector2i) == 0
		and not Farm.occupant(state, inside[0] as Vector2i).has("frozen"),
		"a second freeze refreshes the first rather than stacking, and dawn thaws every tower", str(refreshed))

	# **Winter 14 is its night**; its words and its voice.
	var winter := 4 * GameData.SEASON_DAYS
	expect(GameData.SEASON_BOSSES[3] == &"winter_lord" and Calendar.boss_of(winter) == &"winter_lord"
		and Calendar.boss_of(Run.final_night()) == &"winter_lord"
		and StringName(Waves.night_of(winter).get("boss", &"")) == &"winter_lord"
		and Names.of(&"winter_lord") == I18n.t(&"ENEMY_WINTER_LORD")
		and Names.boss_intro(&"winter_lord") == I18n.t(&"BOSS_INTRO_WINTER_LORD")
		and Describe.enemy(&"winter_lord").contains(I18n.t(&"DESC_FREEZES"))
		and Sfx.voice_of(&"winter_lord") == &"sfx/lord_ice",
		"Winter 14, the year's last night, is the Winter Lord's; it has its name, its intro, a tooltip line that it freezes the towers, and since 0284 a voice of its own")
	_completed += 1


## 0256 - fog and rain. A night's weather is a function of the seed and the
## date: the same however often it is asked and whatever the run's stream
## did, none on Spring 1 or a calm night, each season's share within five
## points of its weight, and the forecast names it. In fog a tower in the
## dark reaches a tile less - by every shape, and through the towers' own
## tick - and one in light does not; in the rain fire is damped and a sting
## is not, and a walker takes the mud's slower count per tile while a flyer
## keeps its own.
func _task_0256_fog_rain() -> void:
	# **The table, and its checks.**
	var events: Dictionary = GameData.NIGHT_EVENTS
	var spring_fog := int(((events[Weather.FOG] as Dictionary)["weights"] as Dictionary)[&"spring"])
	var unrefused: Array = []
	for broken in [
			[[Weather.FOG, "weights", &"spring"], 101, "falls on 101% of spring's nights, outside 0-100"],
			[[Weather.RAIN, "weights", &"summer"], -1, "outside 0-100"],
			[[Weather.RAIN, "weights", &"spring"], 101 - spring_fog, "add up to 101% of its nights"],
			[[Weather.FOG, "fog_reach_penalty"], 0, "fog_reach_penalty of 0, outside 1-2"],
			[[Weather.RAIN, "rain_fire_percent"], 100, "rain_fire_percent of 100, outside 25-90"],
			[[Weather.RAIN, "rain_mud_percent"], 0, "rain_mud_percent of 0, outside 10-50"],
			[[&"hail", "weights"], {}, "'hail' is not one Weather can play"]]:
		if not _says(GameData.check_night_events(_night_events_with(broken[0], broken[1])), broken[2]):
			unrefused.append(broken[2])
	var unseasoned := events.duplicate(true)
	((unseasoned[Weather.RAIN] as Dictionary)["weights"] as Dictionary).erase(&"winter")
	((unseasoned[Weather.RAIN] as Dictionary)["weights"] as Dictionary)[&"monsoon"] = 5
	var unseasoned_errors := GameData.check_night_events(unseasoned)
	expect(unrefused.is_empty() and _says(unseasoned_errors, "no share of winter's nights")
		and _says(unseasoned_errors, "'monsoon', which is no season")
		and GameData.check_night_events(events).is_empty() and GameData.validate().is_empty()
		and Weather.EVENTS.slice(0, 2) == [Weather.FOG, Weather.RAIN]
		and GameData.sorted_names(events.keys()) == GameData.sorted_names(Weather.EVENTS)
		and FileAccess.get_file_as_string("res://src/core/game_data.gd").contains(
			"\"night_events\": [NIGHT_EVENTS, NIGHT_EVENT_LEVERS, NIGHT_EVENT_FIRST_SEASON]"),
		"a share outside 0-100, a season's shares over 100, a lever out of its range, an event Weather cannot play, a season missing and one that is none are all refused; the real table passes and is in the data's digest",
		str(unrefused))

	# **The roll**: steady, none on Spring 1 or a calm night, and each
	# season's share near its weight - pure calls, no simulation.
	var nights := {}
	var fell := {}
	var unsteady: Array = []
	var on_quiet: Array = []
	for seed_value in 50:
		for date in range(1, Calendar.year_days() + 1):
			var one := Weather.event(seed_value, date)
			if Weather.event(seed_value, date) != one:
				unsteady.append([seed_value, date])
			if date == 1 or Calendar.is_calm(date):
				if one != Weather.NONE:
					on_quiet.append([seed_value, date, one])
				continue
			# **A pinned night is written, not rolled** (0270): the
			# introductions 0272-0274 keep clear say nothing about the share
			# the roll gives a season.
			if (GameData.KEY_NIGHTS.get(date, {}) as Dictionary).has("event"):
				continue
			var season := Calendar.season_id(date)
			nights[season] = int(nights.get(season, 0)) + 1
			if one != Weather.NONE:
				var tally: Dictionary = fell.get(season, {})
				tally[one] = int(tally.get(one, 0)) + 1
				fell[season] = tally
	var off: Array = []
	var shares := PackedStringArray()
	for season in GameData.SEASONS:
		for kind in [Weather.FOG, Weather.RAIN]:
			var weight := int(((events[kind] as Dictionary)["weights"] as Dictionary)[season])
			var count := int((fell.get(season, {}) as Dictionary).get(kind, 0))
			var share := 100.0 * count / maxi(int(nights.get(season, 0)), 1)
			shares.append("%s %s %.1f%% of %d (weight %d)" % [season, kind, share, int(nights.get(season, 0)), weight])
			if absf(share - weight) > 5.0:
				off.append("%s %s %.1f against %d" % [season, kind, share, weight])
	print("  the weather over seeds 0-49, Spring 1 to Winter 14: " + ", ".join(shares))
	expect(unsteady.is_empty() and on_quiet.is_empty(),
		"a night's weather is the same however often it is asked, and Spring 1 and the calm nights have none",
		"%s %s" % [str(unsteady.slice(0, 3)), str(on_quiet.slice(0, 3))])
	expect(off.is_empty(), "each season's share of fog and of rain is within five points of its weight", str(off))
	var unnamed: Array = []
	for seed_value in 5:
		for date in range(1, Calendar.year_days() + 1):
			if StringName(Forecast.of(seed_value, date)["event"]) != Weather.event(seed_value, date):
				unnamed.append([seed_value, date])
	expect(unnamed.is_empty(), "and the forecast names the night's own weather", str(unnamed.slice(0, 3)))

	# **Never the run's stream, and nothing kept.**
	var fog_at := _weather_date(Weather.FOG)
	var foggy := _parked_on(int(fog_at[0]), int(fog_at[1]))
	var keys := foggy.keys().size()
	var hash_before := State.hash_of(foggy)
	for _i in 1000:
		Weather.tonight(foggy)
	var unmoved := State.hash_of(foggy) == hash_before
	for _i in 100:
		Rng.next_u32(foggy["rng"])
	expect(unmoved and Weather.tonight(foggy) == Weather.FOG
		and Weather.event(int(fog_at[0]), int(fog_at[1])) == Weather.FOG
		and StringName(Forecast.tonight(foggy)["event"]) == Weather.FOG and foggy.keys().size() == keys
		and not foggy.has("weather") and not foggy.has("moon_phase"),
		"a thousand asks leave the state's hash alone, and after a hundred draws from the run's stream the night is still foggy, in the forecast too - and no State key holds it",
		"%s, unmoved %s" % [str(fog_at), unmoved])

	# **Fog: a tile less in the dark, none less in light.** Its clear twin is
	# the same farm on a night of the same season with no weather.
	var clear := _parked_on(int(fog_at[0]), _clear_date(int(fog_at[0]), int(fog_at[1])))
	var penalty := int((events[Weather.FOG] as Dictionary)["fog_reach_penalty"])
	var gun: Dictionary = GameData.DEFENCES[&"gun_tower"]
	var flame: Dictionary = GameData.DEFENCES[&"flame_tower"]
	var bow: Dictionary = GameData.DEFENCES[&"auto_crossbow"]
	var porch := House.porch(foggy)
	var dark := _a_dark_cell(foggy, porch, 10)
	var plain := Towers.reach_of(clear, gun, dark)
	var short := Towers.reach_of(foggy, gun, dark)
	var lit := Towers.reach_of(foggy, gun, porch)
	expect(Weather.tonight(clear) == Weather.NONE and plain == int(gun["range"]) and short == plain - penalty
		and lit == Towers.reach_of(clear, gun, porch) and lit == plain + GameData.LIGHT_REACH_BONUS
		and Towers.reach_of(foggy, {"range": 1}, dark) == 1,
		"in fog a gun tower in the dark reaches %d less, never under one tile, and one on the lit porch as far as on a clear night" % penalty,
		"%d clear, %d in fog, %d lit" % [plain, short, lit])
	# Every shape: a walker at the clear night's reach of each is reached on
	# the clear night and not in the fog - the gun's look, the crowd's
	# squares, the flame's cone and the crossbow's bolt.
	var full := int((GameData.ENEMIES[&"walker"] as Dictionary)["hp"])
	var reached: Array = []
	for farm in [clear, foggy]:
		var walker := Entities.spawn(farm, &"walker", dark + Vector2i(plain, 0))
		var looked := Towers.acquire_for(farm, dark, gun) == walker
		var squared := Towers.acquire_nearby_for(farm, dark, gun) == walker
		Enemies.withdraw(farm)
		var nearer := Entities.spawn(farm, &"walker", dark + Vector2i(plain - penalty, 0))
		var near_seen := Towers.acquire_for(farm, dark, gun) == nearer
		Enemies.withdraw(farm)
		var burnt := Entities.spawn(farm, &"walker", dark + Vector2i(int(flame["range"]), 0))
		Towers.burn_cone_for_test(farm, dark, flame, burnt, true)
		var cone := int(Entities.get_one(farm, burnt)["hp"]) < full
		Enemies.withdraw(farm)
		var shot := Entities.spawn(farm, &"walker", dark + Vector2i(int(bow["range"]), 0))
		Towers.pierce_line_for_test(farm, dark, bow, shot, true)
		var bolt := int(Entities.get_one(farm, shot)["hp"]) < full
		Enemies.withdraw(farm)
		reached.append([looked, squared, near_seen, cone, bolt])
	expect(reached == [[true, true, true, true, true], [false, false, true, false, false]],
		"at the clear night's reach the gun, its crowd's squares, the flame's cone and the crossbow's bolt all reach a walker; in the fog none does, and the gun reaches one a tile nearer",
		str(reached))
	# And through the towers' own tick, which asks the weather once.
	var fired: Array = []
	for farm in [clear, foggy]:
		Farm.place(farm, dark, {"id": &"gun_tower", "hp": int(gun["hp"])})
		Entities.spawn(farm, &"walker", dark + Vector2i(plain, 0))
		var before := int(farm["shots_fired"])
		Towers.tick(farm)
		fired.append(int(farm["shots_fired"]) - before)
		Enemies.withdraw(farm)
	expect(fired == [1, 0], "and in the towers' own tick: on the clear night the gun fires at it, in the fog it holds", str(fired))

	# **Rain: fire damped, never a sting.**
	var rain_at := _weather_date(Weather.RAIN)
	var rainy := _parked_on(int(rain_at[0]), int(rain_at[1]))
	var dry := _parked_on(int(rain_at[0]), _clear_date(int(rain_at[0]), int(rain_at[1])))
	var fire_percent := int((events[Weather.RAIN] as Dictionary)["rain_fire_percent"])
	var open := _a_dark_cell(rainy, Farm.house_centre(rainy), 12)
	var lost: Array = []
	for farm in [dry, rainy]:
		var burnt := Entities.spawn(farm, &"walker", open + Vector2i(2, 0))
		Towers.burn_cone_for_test(farm, open, flame, burnt, true)
		var hp := int(Entities.get_one(farm, burnt)["hp"])
		for _t in GameData.BURN_EVERY_TICKS:
			Combat.tick(farm)
		var by_burn := hp - int(Entities.get_one(farm, burnt)["hp"])
		var stung := Entities.spawn(farm, &"walker", open + Vector2i(0, 3))
		Combat.sting(farm, stung, 4, 2 * GameData.SECONDS)
		Combat.tick(farm)
		lost.append([full - hp, by_burn, full - int(Entities.get_one(farm, stung)["hp"])])
		Enemies.withdraw(farm)
	var dry_lost: Array = lost[0]
	var wet_lost: Array = lost[1]
	expect(Weather.tonight(rainy) == Weather.RAIN and Weather.tonight(dry) == Weather.NONE
		and dry_lost == [int(flame["damage"]), int(flame["burn_damage"]), 4]
		and wet_lost == [maxi(int(flame["damage"]) * fire_percent / 100, 1),
			maxi(int(flame["burn_damage"]) * fire_percent / 100, 1), 4]
		and int(wet_lost[0]) < int(dry_lost[0]) and int(wet_lost[1]) < int(dry_lost[1])
		and Weather.damped(6, GameData.DAMAGE_FIRE, Weather.RAIN) == 6 * fire_percent / 100
		and Weather.damped(1, GameData.DAMAGE_FIRE, Weather.RAIN) == 1
		and Weather.damped(6, GameData.DAMAGE_STING, Weather.RAIN) == 6
		and Weather.damped(6, GameData.DAMAGE_IMPACT, Weather.RAIN) == 6
		and Weather.damped(6, GameData.DAMAGE_FIRE, Weather.FOG) == 6,
		"in the rain the flame's cone and its burn deal %d%% of themselves, never under one, and a hive's sting all of itself" % fire_percent,
		"dry %s, rain %s" % [str(dry_lost), str(wet_lost)])

	# **The mud: a walker's slower count, a flyer's own.**
	var mud := int((events[Weather.RAIN] as Dictionary)["rain_mud_percent"])
	var base := int((GameData.ENEMIES[&"walker"] as Dictionary)["ticks_per_tile"])
	var muddy := Ability.slowed_ticks(base, 100 - mud)
	var moved: Array = []
	for farm in [dry, rainy]:
		var walker := Entities.spawn(farm, &"walker", open)
		var crow := Entities.spawn(farm, &"crow", open + Vector2i(0, 4))
		var walked := 0
		var flown := 0
		var at_w := Entities.position(farm, walker)
		var at_c := Entities.position(farm, crow)
		for _t in muddy:
			Enemies.tick(farm)
			var now_w := Entities.position(farm, walker)
			var now_c := Entities.position(farm, crow)
			walked += absi(now_w.x - at_w.x) + absi(now_w.y - at_w.y)
			flown += absi(now_c.x - at_c.x) + absi(now_c.y - at_c.y)
			at_w = now_w
			at_c = now_c
		moved.append([walked, flown])
		Enemies.withdraw(farm)
	print("  in %d ticks: dry, the walker %d units and the crow %d; in the rain %d and %d"
		% [muddy, int(moved[0][0]), int(moved[0][1]), int(moved[1][0]), int(moved[1][1])])
	expect(Weather.mud_percent(Weather.RAIN) == mud and Weather.mud_percent(Weather.FOG) == 0 and muddy > base
		and int(moved[1][0]) == Player.SUBTILE and int(moved[0][0]) > Player.SUBTILE
		and int(moved[1][1]) == int(moved[0][1]) and int(moved[1][1]) > 0,
		"in the rain a walker crosses a tile in %d ticks rather than %d, and a crow flies as far as on a dry night" % [muddy, base],
		str(moved))
	var flare := Ability.slowed_ticks(base)
	var garlic := 100 - int((GameData.DEFENCES[&"garlic_braid"] as Dictionary)["repel_speed_percent"])
	var braided := Ability.slowed_ticks(base, 100 - garlic)
	expect(Enemies.slowed_ticks(base, false, 0, 0) == base and Enemies.slowed_ticks(base, false, 0, mud) == muddy
		and Enemies.slowed_ticks(base, true, 0, mud) == maxi(flare, muddy)
		and Enemies.slowed_ticks(base, false, garlic, mud) == maxi(braided, muddy)
		and Enemies.slowed_ticks(base, true, garlic, mud) == maxi(maxi(flare, braided), muddy),
		"the mud joins the flare's and the garlic's slows by their one rule: the slowest of those on a walker, never two at once")

	# **Its marks** through 0120's road until 0269: A055's fog and rain at
	# both boxes, drawn in code; the forecast has a word for each.
	var marks_wrong: Array = []
	for which in Weather.EVENTS:
		for small in [false, true]:
			var side := CalendarMark.HUD if small else CalendarMark.ICON
			var path := CalendarMark.file_of(which, small)
			var mark := CalendarMark.new()
			mark.setup(which, small)
			var texture := mark.texture()
			if (not PlaceholderArt.is_drawn(path)
					or str(PlaceholderArt.art(StringName(path.get_file().get_basename())).get("pack", "")) != "A055"
					or texture == null or texture.resource_name != path
					or Vector2i(texture.get_size()) != Vector2i(side, side)):
				marks_wrong.append(path.get_file())
			mark.free()
	expect(marks_wrong.is_empty() and not CalendarMark.MARKS.has(Weather.FOG)
		and GameData.sorted_names(ForecastPanel.EVENT_WORDS.keys()) == GameData.sorted_names(Weather.EVENTS),
		"every night event - fog, rain and since 0257 the Blood Moon - has A055's marks at 16x16 and 10x10, drawn in code until 0269, and a word on the forecast",
		str(marks_wrong))
	_completed += 1


## 0257 - the Blood Moon. A rare red night from autumn on: never in spring or
## summer, on a boss night or on a Full Moon. Every body that comes is an
## elite with the lever's share of hit points - a boss never - whose full
## health `Combat.full_hp` reads; the night sends no more of them than it
## would; and a won one pays its essence on its own line, once.
func _task_0257_blood_moon() -> void:
	var row: Dictionary = GameData.NIGHT_EVENTS[Weather.BLOOD_MOON]
	var weights: Dictionary = row["weights"]
	var percent := int(row["blood_moon_hp_percent"])
	var essence := int(GameData.REWARDS["blood_moon_essence"])
	# **The row, and its checks.**
	var unrefused: Array = []
	for broken in [
			[[Weather.BLOOD_MOON, "weights", &"spring"], 1, "'blood_moon' falls in spring, before autumn"],
			[[Weather.BLOOD_MOON, "weights", &"summer"], 1, "'blood_moon' falls in summer, before autumn"],
			[[Weather.BLOOD_MOON, "blood_moon_hp_percent"], 119, "blood_moon_hp_percent of 119, outside 120-200"],
			[[Weather.BLOOD_MOON, "blood_moon_hp_percent"], 201, "blood_moon_hp_percent of 201, outside 120-200"]]:
		if not _says(GameData.check_night_events(_night_events_with(broken[0], broken[1])), broken[2]):
			unrefused.append(broken[2])
	var unpaid := GameData.REWARDS.duplicate(true)
	unpaid["blood_moon_essence"] = 0
	expect(unrefused.is_empty() and _says(GameData.check_rewards(unpaid), "a Blood Moon pays 0 essence")
		and int(weights[&"spring"]) == 0 and int(weights[&"summer"]) == 0
		and int(weights[&"autumn"]) > 0 and int(weights[&"autumn"]) <= 10
		and int(weights[&"winter"]) > 0 and int(weights[&"winter"]) <= 10
		and percent >= 120 and percent <= 200 and essence >= 1
		and Weather.EVENTS.back() == Weather.BLOOD_MOON
		and GameData.check_night_events(GameData.NIGHT_EVENTS).is_empty() and GameData.validate().is_empty(),
		"a Blood Moon before autumn, an elite outside 120-200% and a Blood Moon that pays nothing are refused; the real table gives it a small share of autumn's and winter's nights, last in the roll",
		str(unrefused))

	# **When it rises** - pure calls, no simulation.
	var risen := {}
	var misplaced: Array = []
	for seed_value in 50:
		for date in range(1, Calendar.year_days() + 1):
			if Weather.event(seed_value, date) != Weather.BLOOD_MOON:
				continue
			if (Calendar.season_of(date) < 2 or Calendar.is_boss_night(date)
					or Calendar.is_full_moon(date)):
				misplaced.append([seed_value, date])
			var season := Calendar.season_id(date)
			risen[season] = int(risen.get(season, 0)) + 1
	print("  Blood Moons over seeds 0-49, Spring 1 to Winter 14: %d in autumn and %d in winter"
		% [int(risen.get(&"autumn", 0)), int(risen.get(&"winter", 0))])
	expect(misplaced.is_empty() and int(risen.get(&"autumn", 0)) > 0 and int(risen.get(&"winter", 0)) > 0,
		"no Blood Moon falls in spring, in summer, on a boss night or on a Full Moon, and some rise in autumn and in winter",
		str(misplaced.slice(0, 3)))

	# **Elites**: on a Blood Moon a walker - put down or sent by a wave - comes
	# with the lever's share of hit points, written down as `max_hp`, which
	# `full_hp` reads after a hit; a Giant comes as it is; and a night of the
	# same season with no weather sends plain ones.
	var at := _weather_date(Weather.BLOOD_MOON)
	var seed_found := int(at[0])
	var date_found := int(at[1])
	var red := _parked_on(seed_found, date_found)
	var plain_night := _parked_on(seed_found, _clear_date(seed_found, date_found))
	var walker_hp := int((GameData.ENEMIES[&"walker"] as Dictionary)["hp"])
	var elite_hp := walker_hp * percent / 100
	var elite := Entities.spawn(red, &"walker", Enemies.spawn_cells(red, 0)[0])
	var by_wave := Enemies.spawn(red, &"walker", 0)
	var giant := Entities.spawn(red, &"giant", Enemies.spawn_cells(red, 0)[0])
	var plain := Entities.spawn(plain_night, &"walker", Enemies.spawn_cells(plain_night, 0)[0])
	Combat.hit(red, elite, 5)
	var one := Entities.get_one(red, elite)
	expect(Weather.tonight(red) == Weather.BLOOD_MOON and Weather.tonight(plain_night) == Weather.NONE
		and Weather.elite_hp(walker_hp) == elite_hp and elite_hp > walker_hp
		and int(one.get("max_hp", 0)) == elite_hp and int(one["hp"]) == elite_hp - 5
		and Combat.full_hp(red, elite) == elite_hp
		and Entities.is_elite(red, elite) and Entities.is_elite(red, by_wave)
		and int(Entities.get_one(red, by_wave)["hp"]) == elite_hp
		and not Entities.is_elite(red, giant)
		and int(Entities.get_one(red, giant)["hp"]) == int((GameData.ENEMIES[&"giant"] as Dictionary)["hp"])
		and not Entities.is_elite(plain_night, plain) and Combat.full_hp(plain_night, plain) == walker_hp,
		"on the Blood Moon a walker comes with %d%% of its hit points as its max_hp, which full_hp reads after a hit; a Giant comes as it is, and a plain night's walker has no max_hp" % percent,
		"%s %s" % [str(at), str(one)])
	var said := Forecast.of(seed_found, date_found)
	expect(StringName(said["event"]) == Weather.BLOOD_MOON
		and int(said["count"]) == Waves.size_in(Waves.night_of(date_found, seed_found))
		and not SuiteKit.code_lines_of("res://src/core/waves.gd").contains("Weather"),
		"its forecast names the Blood Moon and counts what the night sends, and the waves never ask the weather: elites are tougher, not more",
		str(said))

	# **A won Blood Moon pays its essence on its own line, once.**
	I18n.use("en")
	var won := _essence_night(seed_found, date_found)
	var paid := Rewards.settle(won, true)
	var lines: Dictionary = paid["essence_from"]
	var summed := 0
	for line in GameData.sorted_names(lines.keys()):
		summed += int(lines[line])
	var again := Rewards.settle(won, true)
	var quiet := Rewards.settle(_essence_night(seed_found, _clear_date(seed_found, date_found)), true)
	var parts := ResultScreen.essence_parts(lines)
	expect(int(lines.get("blood moon", 0)) == essence and summed == int(paid["tech"])
		and int(again["tech"]) == 0 and (again["essence_from"] as Dictionary).is_empty()
		and Tech.held(won) == int(paid["tech"])
		and not (quiet["essence_from"] as Dictionary).has("blood moon")
		and int(quiet["tech"]) == int(paid["tech"]) - essence
		and not parts.is_empty()
		and parts.back() == I18n.f(&"RES_ESSENCE_PART", [I18n.t(&"RES_ESSENCE_BLOOD_MOON"), essence]),
		"a won Blood Moon pays %d essence more on its own line, which the morning report names last; a plain night of its season does not, and nothing is paid a second time" % essence,
		"%s, again %s" % [str(lines), str(again["essence_from"])])

	# **On the forecast**: its word in the boss's red beside A055's mark,
	# drawn in code until 0269 - a red disc whose drip changes its outline, so
	# it is never only the colour that tells it from A010's Full Moon.
	var mark := CalendarMark.new()
	mark.setup(Weather.BLOOD_MOON)
	var small := CalendarMark.new()
	small.setup(Weather.BLOOD_MOON, true)
	var texture := mark.texture()
	var full_moon: Texture2D = load(CalendarMark.file_of(&"full_moon", false))
	var outline_differs := false
	if texture != null and full_moon != null:
		var drawn := texture.get_image()
		var white := full_moon.get_image()
		for y in CalendarMark.ICON:
			for x in CalendarMark.ICON:
				if (drawn.get_pixel(x, y).a > 0.5) != (white.get_pixel(x, y).a > 0.5):
					outline_differs = true
	expect(ForecastPanel.EVENT_WORDS.get(Weather.BLOOD_MOON, &"") == &"FCAST_BLOOD_MOON"
		and ForecastPanel.EVENT_ROLES.get(Weather.BLOOD_MOON, &"") == UiKit.BAD
		and texture != null and Vector2i(texture.get_size()) == Vector2i(CalendarMark.ICON, CalendarMark.ICON)
		and small.texture() != null and Vector2i(small.texture().get_size()) == Vector2i(CalendarMark.HUD, CalendarMark.HUD)
		and PlaceholderArt.is_drawn(CalendarMark.file_of(Weather.BLOOD_MOON, false))
		and outline_differs,
		"the forecast says BLOOD MOON in the boss's red beside A055's mark, drawn in code until 0269 at both boxes, its outline not the Full Moon's")
	mark.free()
	small.free()
	_completed += 1


## 0270 - fifty-six nights as data. Every day of the year is a key night, a
## night made from its season's template or a calm date, for every seed; a
## made night keeps the rules a written one does, has its template's numbers
## for the day, sends the same crowd on every seed and never touches the run's
## stream; no kind comes before the day that introduces it; day 1 is the old
## night 1 to the byte; `check_nights` refuses what the tables must not hold;
## a key night's weather pin is read instead of the roll; a Full Moon is
## scaled in one place; and the forecast's counts are what is sent.
func _task_0270_year_records() -> void:
	var days := Calendar.year_days()
	# **Every day is one of three things**, for seeds 0-4, and a made night
	# is held to exactly the rules a written one is - as made and as fought.
	var unplaced: Array = []
	var faults: Array = []
	var made_days := 0
	for seed_value in range(5):
		for day in range(1, days + 1):
			var key := Almanac.is_key(day)
			var made := Almanac.is_made(day)
			var calm := Calendar.is_calm(day)
			var plain := Waves.plain_night(day, seed_value)
			if int(key) + int(made) + int(calm) != 1:
				unplaced.append([seed_value, day, key, made, calm])
			elif key and not is_same(plain, GameData.KEY_NIGHTS[day]):
				unplaced.append([seed_value, day, "not its key night"])
			elif calm and not (plain.is_empty() and bool(Waves.night_of(day, seed_value).get("calm", false))):
				unplaced.append([seed_value, day, "a calm date with a record of its own"])
			elif made:
				made_days += 1
				faults.append_array(GameData.check_record(plain, day))
				faults.append_array(GameData.check_record(Waves.night_of(day, seed_value), day))
	print("  the year: %d key nights, %d made a seed, %d calm"
		% [GameData.KEY_NIGHTS.size(), made_days / 5, days - GameData.KEY_NIGHTS.size() - made_days / 5])
	expect(unplaced.is_empty() and faults.is_empty() and made_days > 0,
		"for seeds 0-4 every day 1-56 is a key night, a made one or a calm date, and every made night passes check_record as made and as fought",
		"%s %s" % [str(unplaced.slice(0, 3)), str(faults.slice(0, 3))])

	# **The template's numbers, on the day**: its hit points within a body of
	# each kind, its gap - the least since 0271, a deal short of the fill line
	# spaced further and then all sent on it - and only the sides that have
	# joined.
	var off: Array = []
	for day in range(1, days + 1):
		if not Almanac.is_made(day):
			continue
		var of_season := Calendar.day_of_season(day)
		var template: Dictionary = GameData.SEASON_NIGHTS[Calendar.season_of(day)]
		var plain := Waves.plain_night(day, 3)
		var want := Almanac.on_day(template["size"], of_season)
		var slack := 0
		var mix := Almanac.mix_on(template, of_season)
		for kind in GameData.sorted_names(mix.keys()):
			slack += int((GameData.ENEMIES[kind] as Dictionary)["hp"])
		var least := Almanac.on_day(template["gap_ticks"], of_season)
		var spaced := int(plain["gap_ticks"]) > least
		if absi(Waves.hit_points_in(plain) - want) >= slack or int(plain["gap_ticks"]) < least \
				or spaced and Waves.schedule_ticks(plain) >= Waves.fill_line() + (plain["waves"] as Array).size():
			off.append([day, Waves.hit_points_in(plain), want, plain["gap_ticks"]])
		var joined := Almanac.sides_on(template, of_season)
		for side in Waves.spawns_in(plain):
			if not joined.has(side):
				off.append([day, "side", side])
	expect(off.is_empty(),
		"a made night has its template's hit points for the day, give or take a body of each kind, its gap or one spaced to the fill line, and only the sides joined by then",
		str(off.slice(0, 3)))

	# **The seed orders, it never weighs** (the `Endless` contract): every
	# seed's day sends the same count of every kind.
	var unequal: Array = []
	for day in range(1, days + 1):
		var first := Waves.kinds_of(day, 0)
		for seed_value in range(1, 5):
			var other := Waves.kinds_of(day, seed_value)
			if GameData.sorted_names(first.keys()) != GameData.sorted_names(other.keys()):
				unequal.append([seed_value, day])
				continue
			for kind in GameData.sorted_names(first.keys()):
				if int(first[kind]) != int(other[kind]):
					unequal.append([seed_value, day, kind])
	var orders := {}
	for seed_value in range(5):
		orders[str(Waves.table(30, seed_value))] = true
	expect(unequal.is_empty() and orders.size() > 1,
		"two seeds send the same totals per kind on every day, while the seed orders day 30's waves",
		"%s, %d orders" % [str(unequal.slice(0, 3)), orders.size()])

	# **Never the run's stream**: making day 30 and keeping it as tonight's
	# leaves `state["rng"]` as it was - and a key night no rule touches is
	# fought as written, with nothing kept.
	var run := State.create(2700)
	run["day"] = 30
	run["night"] = 30
	var rng_before := str(run["rng"])
	var made_30 := Waves.tonight(run)
	var key_run := State.create(2701)
	key_run["day"] = 3
	key_run["night"] = 3
	expect(str(run["rng"]) == rng_before and Almanac.is_made(30) and is_same(made_30, Waves.tonight(run))
		and int(made_30.get("for_night", 0)) == 30
		and str(Almanac.night(2700, 30)) == str(Waves.night_of(30, 2700))
		and is_same(Waves.tonight(key_run), GameData.KEY_NIGHTS[3])
		and not (key_run["wave"] as Dictionary).has("tonight"),
		"making day 30 leaves state['rng'] untouched and is kept as tonight's, while key night 3 is fought as written",
		"%s against %s" % [str(run["rng"]), rng_before])

	# **Nothing before its introduction**: a kind's first day is the first key
	# night that writes it or the day its template lets it join, and no day
	# of any seed sends it sooner.
	var introduced := {}
	for day in range(1, days + 1):
		if Almanac.is_key(day):
			var writes := Waves.kinds_in(GameData.KEY_NIGHTS[day])
			for kind in GameData.sorted_names(writes.keys()):
				if not introduced.has(kind):
					introduced[kind] = day
	for season in GameData.SEASON_NIGHTS.size():
		var season_mix: Dictionary = (GameData.SEASON_NIGHTS[season] as Dictionary)["mix"]
		for kind in GameData.sorted_names(season_mix.keys()):
			var joins := season * GameData.SEASON_DAYS + int((season_mix[kind] as Array)[1])
			introduced[kind] = mini(int(introduced.get(kind, joins)), joins)
	var early: Array = []
	for seed_value in range(5):
		for day in range(1, days + 1):
			var sent := Waves.kinds_in(Waves.plain_night(day, seed_value))
			for kind in GameData.sorted_names(sent.keys()):
				if day < int(introduced.get(kind, days + 1)):
					early.append([seed_value, day, kind])
	expect(early.is_empty() and int(introduced.get(&"walker", 0)) == 1
		and int(introduced.get(&"runner", 0)) == 3 and int(introduced.get(&"tank", 0)) == 5
		and int(introduced.get(&"breaker", 0)) == 8,
		"no kind is sent before the day its key night or template introduces it - the walker on 1, the runner on 3, the tank on 5, the breaker on 8",
		"%s %s" % [str(early.slice(0, 3)), str(introduced)])

	# **Day 1 is the old night 1**, to the byte.
	var old_one := {
		"note": "the tutorial night: one tower, one side, and time to watch",
		"opening_ticks": 0,
		"waves": [
			[&"walker", 3, 0],
			[&"walker", 4, 0],
			[&"walker", 5, 0],
		],
	}
	expect(var_to_str(Waves.night_of(1)) == var_to_str(old_one)
		and is_same(Waves.night_of(1), GameData.KEY_NIGHTS[1]),
		"day 1's record is the old night 1, byte for byte", var_to_str(Waves.night_of(1)))

	# **The tables' check refuses what they must not hold.**
	var boss_key := GameData.KEY_NIGHTS.duplicate(true)
	(boss_key[5]["waves"] as Array).append([&"giant", 1, 0])
	var stranger := GameData.SEASON_NIGHTS.duplicate(true)
	(stranger[1]["mix"] as Dictionary)[&"vampire"] = [10, 1]
	var south_east_template := GameData.SEASON_NIGHTS.duplicate(true)
	(south_east_template[0]["sides"] as Array).append([1, 4])
	var south_east_key := GameData.KEY_NIGHTS.duplicate(true)
	(south_east_key[5]["waves"][0] as Array)[2] = 1
	var on_fifteen := GameData.KEY_NIGHTS.duplicate()
	on_fifteen[15] = GameData.KEY_NIGHTS[3]
	var past_year := GameData.KEY_NIGHTS.duplicate()
	past_year[days + 1] = GameData.KEY_NIGHTS[3]
	var moonless := GameData.KEY_NIGHTS.duplicate()
	moonless.erase(21)
	var falling := GameData.SEASON_NIGHTS.duplicate(true)
	falling[0]["size"] = [2600, 400]
	var loosening := GameData.SEASON_NIGHTS.duplicate(true)
	loosening[0]["gap_ticks"] = [6 * GameData.SECONDS, 15 * GameData.SECONDS]
	var unrefused: Array = []
	for broken in [
			[GameData.SEASON_NIGHTS, boss_key, "the key night of day 5 names a boss, 'giant'"],
			[stranger, GameData.KEY_NIGHTS, "the summer template mixes 'vampire', which is not an enemy"],
			[south_east_template, GameData.KEY_NIGHTS, "the spring template comes from side 1, which its season has not opened"],
			[GameData.SEASON_NIGHTS, south_east_key, "night 5 comes from side 1, which its season has not opened"],
			[GameData.SEASON_NIGHTS, on_fifteen, "a key night on day 15, a calm date"],
			[GameData.SEASON_NIGHTS, past_year, "a key night on day %d, outside 1-%d" % [days + 1, days]],
			[GameData.SEASON_NIGHTS, moonless, "day 21 is a Full Moon with no key night"],
			[falling, GameData.KEY_NIGHTS, "the spring template's size falls"],
			[loosening, GameData.KEY_NIGHTS, "the spring template's gap grows"],
			[GameData.SEASON_NIGHTS, _key_event(3, &"hail"), "pins 'hail', which is no event"],
			[GameData.SEASON_NIGHTS, _key_event(3, Weather.BLOOD_MOON), "pins 'blood_moon' before autumn"],
			[GameData.SEASON_NIGHTS, _key_event(35, Weather.BLOOD_MOON), "pins a Blood Moon on the moon's own night"],
			[GameData.SEASON_NIGHTS, _key_event(1, Weather.FOG), "on the game's first night"]]:
		if not _says(GameData.check_nights(broken[0], broken[1]), broken[2]):
			unrefused.append(broken[2])
	expect(unrefused.is_empty() and GameData.check_nights(GameData.SEASON_NIGHTS, GameData.KEY_NIGHTS).is_empty()
		and GameData.check_nights(GameData.SEASON_NIGHTS, _key_event(3, &"")).is_empty()
		and GameData.check_nights(GameData.SEASON_NIGHTS, _key_event(31, Weather.BLOOD_MOON)).is_empty(),
		"check_nights refuses a boss in a key night, an unknown kind in a template, a spring night from the south east, a key night on day 15 - and one past the year, a Full Moon unwritten, a falling size, a growing gap and a pin the weather would not allow - while the shipped year, a forbidding pin and an autumn Blood Moon pass",
		str(unrefused))

	# **The weather pin is read instead of the roll** (0256's chooser): fog
	# pinned on day 9 is fog for every seed, and a forbidding pin clears a
	# night that rolled fog. Day 1 and the days past the year read none.
	var foggy := _weather_date(Weather.FOG)
	var pinned := _key_event(9, Weather.FOG)
	var always := true
	for seed_value in range(5):
		always = always and Weather.event_in(pinned, seed_value, 9) == Weather.FOG \
			and Weather.event_in(GameData.KEY_NIGHTS, seed_value, 9) == Weather.event(seed_value, 9)
	expect(always and int(foggy[0]) >= 0
		and Weather.event_in(_key_event(int(foggy[1]), &""), int(foggy[0]), int(foggy[1])) == Weather.NONE
		and Weather.event_in(_key_event(1, Weather.FOG), 0, 1) == Weather.NONE
		and Weather.event_in(_key_event(days + 2, Weather.FOG), 0, days + 2) == Weather.event(0, days + 2),
		"a key night's event pins its weather on every seed and an empty one forbids it; day 1 and the days past the year read no pin",
		str(foggy))

	# **A Full Moon is scaled once** (0152), in `night_of`: its key night is
	# written at an ordinary night's size with no flag, and what the forecast
	# counts is what that scaling sends.
	var moon_wrong: Array = []
	for day in range(1, days + 1):
		if not Calendar.is_full_moon(day):
			continue
		var written: Dictionary = GameData.KEY_NIGHTS[day]
		var want := 0
		for row in (written["waves"] as Array):
			want += maxi(int((row as Array)[1]) * GameData.FULL_MOON_HORDE_PERCENT / 100, int((row as Array)[1]))
		if Calendar.is_boss_night(day):
			want += 1
		if written.has("full_moon") or Waves.size_of(day) != want or int(Forecast.of(0, day)["count"]) != want:
			moon_wrong.append([day, Waves.size_of(day), want])
	expect(moon_wrong.is_empty(),
		"a key Full Moon is written at an ordinary night's size and scaled once, in night_of - the forecast's count is what is sent",
		str(moon_wrong))

	# **The forecast is what is sent** (0158), every day of the year for two
	# seeds: its count is `size_of`, its kinds `kinds_of`.
	var told_wrong: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, days + 1):
			var told := Forecast.of(seed_value, day)
			var kinds := Waves.kinds_of(day, seed_value)
			var listed := {}
			for pair in (told["kinds"] as Array):
				listed[StringName((pair as Array)[0])] = int((pair as Array)[1])
			if int(told["count"]) != Waves.size_of(day, seed_value) \
					or GameData.sorted_names(listed.keys()) != GameData.sorted_names(kinds.keys()):
				told_wrong.append([seed_value, day])
				continue
			for kind in GameData.sorted_names(kinds.keys()):
				if int(listed[kind]) != int(kinds[kind]):
					told_wrong.append([seed_value, day, kind])
	expect(told_wrong.is_empty(),
		"for days 1-56 and two seeds the forecast's counts are size_of and kinds_of for the day",
		str(told_wrong.slice(0, 3)))

	# **Past the year the curve goes on** (0070, until 0279), from Spring
	# 14's key night as written - the tenth without its Giant - and day 57
	# is calm.
	expect(Endless.size_of(Endless.DRAWN_PAST) == Waves.size_in(GameData.KEY_NIGHTS[GameData.SEASON_DAYS])
		and bool(Waves.night_of(days + 1).get("calm", false))
		and str(Waves.plain_night(days + 2, 3)) == str(Endless.night(3, days + 2)),
		"past the year the curve goes on from Spring 14's key night as written, and day 57 is calm",
		str(Endless.size_of(Endless.DRAWN_PAST)))
	_completed += 1


## The year's key nights with day `day`'s pinning `event` - its own record,
## or a copy of day 3's where it has none (task 0270; day 2 is made since
## 0271).
func _key_event(day: int, event: StringName) -> Dictionary:
	var keys := GameData.KEY_NIGHTS.duplicate()
	var one: Dictionary = (GameData.KEY_NIGHTS.get(day, GameData.KEY_NIGHTS[3]) as Dictionary).duplicate(true)
	one["event"] = event
	keys[day] = one
	return keys


## 0271 - spring's fourteen nights. Days 1-14 send only the walker, the
## runner, the tank, the breaker and the Giant, only from the east; each kind
## is first sent on the day spring introduces it, and the night after sends
## more of it; day 7 is the largest of days 1-7 and day 14 of spring, in hit
## points, the days between growing; the Giant comes on day 14 and on no
## other; every spring night is still sending at the fill line and all sent
## before the dawn margin, a made one spaced to it when its deal comes out
## short; and the tutorial night keeps the house pace.
func _task_0271_spring_nights() -> void:
	var days := GameData.SEASON_DAYS
	var allowed := [&"walker", &"runner", &"tank", &"breaker", &"giant"]
	var intro := {&"walker": 1, &"runner": 3, &"tank": 5, &"breaker": 8, &"giant": days}
	var strays: Array = []
	var firsts: Array = []
	var bland: Array = []
	var unfilled: Array = []
	for seed_value in range(5):
		var first := {}
		for day in range(1, days + 1):
			var one := Waves.night_of(day, seed_value)
			for row in (one["waves"] as Array):
				var kind := StringName((row as Array)[0])
				if not allowed.has(kind) or int((row as Array)[2]) != 0:
					strays.append([seed_value, day, row])
				if not first.has(kind):
					first[kind] = day
			var sent := Waves.schedule_ticks(one)
			if sent < Waves.fill_line() or sent + GameData.DAWN_MARGIN_TICKS > GameData.NIGHT_TICKS:
				unfilled.append([seed_value, day, sent])
		for kind in GameData.sorted_names(intro.keys()):
			var day := int(intro[kind])
			if int(first.get(kind, -1)) != day:
				firsts.append([seed_value, kind, first.get(kind, -1)])
			# **The night after is where it bites** (0060's rule): more of it.
			if day < days and int(Waves.kinds_of(day + 1, seed_value).get(kind, 0)) \
					<= int(Waves.kinds_of(day, seed_value).get(kind, 0)):
				bland.append([seed_value, kind])
	expect(strays.is_empty(),
		"spring sends only the walker, the runner, the tank, the breaker and the Giant, and only from the east",
		str(strays.slice(0, 3)))
	expect(firsts.is_empty() and bland.is_empty(),
		"each kind is first sent on the day spring introduces it - 1, 3, 5, 8 and the Giant on 14 - and the night after sends more of it",
		"%s %s" % [str(firsts.slice(0, 3)), str(bland.slice(0, 3))])
	expect(unfilled.is_empty(),
		"every spring night is still sending at the fill line, %d s, and all sent %d s before dawn"
			% [Waves.fill_line() / GameData.SECONDS, GameData.DAWN_MARGIN_TICKS / GameData.SECONDS],
		str(unfilled.slice(0, 3)))

	# **The plan's rhythm, in hit points as fought**: days 1-6 grow, day 7
	# is the largest of them, days 8-13 grow again, day 14 is the season's.
	var hp: Array = [0]
	for day in range(1, days + 1):
		hp.append(Waves.hit_points_in(Waves.night_of(day, 0)))
	var peaks := true
	for day in range(1, 7):
		peaks = peaks and int(hp[day]) < int(hp[7])
	for day in range(1, days):
		peaks = peaks and int(hp[day]) < int(hp[days])
	var climbs := true
	for day in range(2, 7) + range(9, days):
		climbs = climbs and int(hp[day]) > int(hp[day - 1])
	expect(peaks and climbs,
		"day 7 is the largest of days 1-7 and day 14 the largest of spring in hit points, and days 1-6 and 8-13 grow",
		str(hp))

	# **The Giant on day 14 and nowhere else**, the year round.
	var giants: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, Calendar.year_days() + 1):
			if Waves.kinds_of(day, seed_value).has(&"giant"):
				giants.append([seed_value, day])
	expect(giants == [[0, days], [424242, days]], "the Giant comes on day 14 and on no other day of the year",
		str(giants))

	# **A made night is spaced to the fill line** (`Almanac`): a deal that
	# came out in two waves waits longer between them, one wave waits to
	# begin, and a night already past the line is left as it was.
	var short := {"note": "x", "opening_ticks": 0, "gap_ticks": 30, "waves": [[&"walker", 3, 0], [&"walker", 3, 0]]}
	Almanac._fill_the_night(short)
	var lone := {"note": "x", "opening_ticks": 0, "gap_ticks": 30, "waves": [[&"walker", 3, 0]]}
	Almanac._fill_the_night(lone)
	var long := {"note": "x", "opening_ticks": 0, "gap_ticks": Waves.fill_line(), "waves": [[&"walker", 3, 0], [&"walker", 3, 0]]}
	var before := var_to_str(long)
	Almanac._fill_the_night(long)
	expect(Waves.schedule_ticks(short) == Waves.fill_line() and int(short["gap_ticks"]) > 30
		and Waves.schedule_ticks(lone) == Waves.fill_line() and int(lone["opening_ticks"]) > 0
		and var_to_str(long) == before
		and Waves.fill_line() == GameData.NIGHT_TICKS - GameData.DAWN_MARGIN_TICKS - GameData.NIGHT_FILL_TICKS
		and Waves.fill_line() > 0,
		"a made night short of the fill line waits longer between its waves, or before its one, and one past it is left alone",
		"%d %d" % [Waves.schedule_ticks(short), Waves.schedule_ticks(lone)])

	# **The tutorial night keeps the house pace**: no gap of its own, a
	# minute between its three waves of walkers, and still a handful.
	var tutorial: Dictionary = GameData.KEY_NIGHTS[1]
	expect(not tutorial.has("gap_ticks") and Waves.delay_before(1, 1) == GameData.WAVE_GAP_TICKS
		and Waves.kinds_of(1).keys() == [&"walker"] and Waves.size_of(1) <= 16,
		"the tutorial night takes WAVE_GAP_TICKS between three waves of walkers, a handful of them",
		"%d, %s" % [Waves.delay_before(1, 1), str(Waves.kinds_of(1))])
	_completed += 1


## **Summer's fourteen nights** (task 0272): spring's rhythm a side wider -
## the calm night on 15, summer's first fight on 16, the south east opened by
## a handful on 17, the spitter on 19, a Full Moon of what is known on 21,
## the rats on 22 and the Harvester's company on 28.
func _task_0272_summer_nights() -> void:
	var days := GameData.SEASON_DAYS
	var first_day := days + 1
	var last_day := 2 * days
	var rows := _season_rows(first_day, [&"walker", &"runner", &"tank", &"breaker"],
		{&"spitter": first_day + 4, &"rat": first_day + 7, &"harvester": last_day}, [0, 1])
	expect((rows["strays"] as Array).is_empty(),
		"days 16-28 send only kinds met by that day - spring's four, the spitter from 19, the rats from 22, the Harvester on 28 - and only from the east and the south east",
		str((rows["strays"] as Array).slice(0, 3)))
	expect((rows["firsts"] as Array).is_empty() and (rows["bland"] as Array).is_empty(),
		"the spitter is first sent on 19 and the rats on 22, different nights, the Harvester on 28, and the night after each sends more of it",
		"%s %s" % [str((rows["firsts"] as Array).slice(0, 3)), str((rows["bland"] as Array).slice(0, 3))])
	expect((rows["unfilled"] as Array).is_empty(),
		"every summer night is still sending at the fill line and all sent before the dawn margin",
		str((rows["unfilled"] as Array).slice(0, 3)))
	var crowded := _side_learned(first_day, 1)
	var cloudy := _cloudy([first_day + 2, first_day + 4, first_day + 7])
	expect(crowded.is_empty() and cloudy.is_empty(),
		"the south east sends nothing on 16, a handful on 17 and more on 18, and no introduction has weather",
		"%s %s" % [str(crowded.slice(0, 3)), str(cloudy.slice(0, 3))])

	# **The rhythm in hit points as fought**, and summer's first fight
	# between spring's sixth night and its Full Moon.
	var hp := _hit_points_to(last_day)
	var opens := int(hp[6]) < int(hp[first_day + 1]) and int(hp[first_day + 1]) < int(hp[7])
	expect(opens and _season_shape(first_day, hp),
		"day 16 starts between spring's sixth night and its Full Moon, days 21 and 28 are the largest of their halves, and the days between grow",
		str(hp))

	expect(_boss_days(&"harvester") == [[0, last_day], [424242, last_day]],
		"the Harvester comes on day 28 and on no other day of the year", str(_boss_days(&"harvester")))
	_completed += 1


## **Autumn's fourteen nights** (task 0273): the same rhythm with the north
## added - the calm night on 29, autumn's first fight on 30, the north opened
## by a handful on 31, the crow on 33, a Full Moon of what is known on 35,
## the digger on 36 and the Scarecrow King's company on 42.
func _task_0273_autumn_nights() -> void:
	var days := GameData.SEASON_DAYS
	var first_day := 2 * days + 1
	var last_day := 3 * days
	var rows := _season_rows(first_day, [&"walker", &"runner", &"tank", &"breaker", &"spitter", &"rat"],
		{&"crow": first_day + 4, &"digger": first_day + 7, &"scarecrow_king": last_day}, [0, 1, 2])
	expect((rows["strays"] as Array).is_empty(),
		"days 30-42 send only kinds met by that day - spring's and summer's, the crow from 33, the digger from 36, the Scarecrow King on 42 - and only from the east, the south east and the north",
		str((rows["strays"] as Array).slice(0, 3)))
	expect((rows["firsts"] as Array).is_empty() and (rows["bland"] as Array).is_empty(),
		"the crow is first sent on 33 and the digger on 36, different nights, the Scarecrow King on 42, and the night after each sends more of it",
		"%s %s" % [str((rows["firsts"] as Array).slice(0, 3)), str((rows["bland"] as Array).slice(0, 3))])
	expect((rows["unfilled"] as Array).is_empty(),
		"every autumn night is still sending at the fill line and all sent before the dawn margin",
		str((rows["unfilled"] as Array).slice(0, 3)))
	var crowded := _side_learned(first_day, 2)
	var cloudy := _cloudy([first_day + 2, first_day + 4, first_day + 7])
	expect(crowded.is_empty() and cloudy.is_empty(),
		"the north sends nothing on 30, a handful on 31 and more on 32, and no introduction has weather - a Blood Moon least of all",
		"%s %s" % [str(crowded.slice(0, 3)), str(cloudy.slice(0, 3))])

	# **The crows' first night is gentle** - the farm is what they are after
	# - and the King's night says he calls more than it sends.
	var first_crows := int(Waves.kinds_of(first_day + 4).get(&"crow", 0))
	expect(first_crows > 0 and first_crows <= 10
		and String((GameData.KEY_NIGHTS[last_day] as Dictionary)["note"]).contains("calls crows"),
		"the first crow night sends ten crows at most, and day 42's note says the King calls crows",
		str(first_crows))

	# **The rhythm in hit points as fought**, climbing on from summer:
	# autumn's template starts where summer's ends, and its first fight
	# sends more than summer's last made night.
	var hp := _hit_points_to(last_day)
	var summer: Dictionary = GameData.SEASON_NIGHTS[1]
	var autumn: Dictionary = GameData.SEASON_NIGHTS[2]
	var opens := int((autumn["size"] as Array)[0]) >= int((summer["size"] as Array)[1]) \
		and int(hp[first_day + 1]) > int(hp[first_day - 2])
	expect(opens and _season_shape(first_day, hp),
		"autumn climbs on from summer's last made night, days 35 and 42 are the largest of their halves, and the days between grow",
		str(hp))

	expect(_boss_days(&"scarecrow_king") == [[0, last_day], [424242, last_day]],
		"the Scarecrow King comes on day 42 and on no other day of the year", str(_boss_days(&"scarecrow_king")))
	_completed += 1


## **Winter's fourteen nights** (task 0274), the exam: the calm night on 43,
## winter's first fight on 44, the west opened by a handful on 45 and the
## south on 46, the frost zombie on 47, a Full Moon of what is known on 49,
## the wraith on 50 and the Winter Lord's company on 56 - and with all four
## seasons written, a night over before the fill line is refused.
func _task_0274_winter_nights() -> void:
	var days := GameData.SEASON_DAYS
	var first_day := 3 * days + 1
	var last_day := 4 * days
	var rows := _season_rows(first_day,
		[&"walker", &"runner", &"tank", &"breaker", &"spitter", &"rat", &"crow", &"digger"],
		{&"frost_zombie": first_day + 4, &"wraith": first_day + 7, &"winter_lord": last_day}, [0, 1, 2, 3, 4])
	expect((rows["strays"] as Array).is_empty(),
		"days 44-56 send only kinds met by that day - the year's eight, the frost zombie from 47, the wraith from 50, the Winter Lord on 56",
		str((rows["strays"] as Array).slice(0, 3)))
	expect((rows["firsts"] as Array).is_empty() and (rows["bland"] as Array).is_empty(),
		"the frost zombie is first sent on 47 and the wraith on 50, different nights, the Winter Lord on 56, and the night after each sends more of it",
		"%s %s" % [str((rows["firsts"] as Array).slice(0, 3)), str((rows["bland"] as Array).slice(0, 3))])
	expect((rows["unfilled"] as Array).is_empty(),
		"every winter night is still sending at the fill line and all sent before the dawn margin",
		str((rows["unfilled"] as Array).slice(0, 3)))
	# **Two new sides over two nights, neither an introduction's**: the west
	# a handful on 45, the south a handful on 46, each more the night after.
	var west := _side_learned(first_day, 3)
	var south := _side_learned(first_day + 1, 4)
	var cloudy := _cloudy([first_day + 2, first_day + 3, first_day + 4, first_day + 7])
	expect(west.is_empty() and south.is_empty() and cloudy.is_empty()
		and not [first_day + 4, first_day + 7].has(first_day + 2)
		and not [first_day + 4, first_day + 7].has(first_day + 3),
		"the west opens on 45 and the south on 46 with a handful each and more the night after, on no introduction's night, and no night that brings something new has weather",
		"%s %s %s" % [str(west), str(south), str(cloudy)])

	# **The first wraith night is small**: answerable with the light a farm
	# has without a searchlight, because it is the night that teaches one.
	var first_wraiths := int(Waves.kinds_of(first_day + 7).get(&"wraith", 0))
	expect(first_wraiths > 0 and first_wraiths <= 6,
		"the first wraith night sends six wraiths at most", str(first_wraiths))

	# **A climb in variety, not in bodies**: winter's ordinary nights send no
	# more bodies than autumn's did, since nothing grows to pay for more.
	var most := {}
	for season in [2, 3]:
		for day in range(season * days + 2, (season + 1) * days):
			if Almanac.is_made(day):
				most[season] = maxi(int(most.get(season, 0)), Waves.size_of(day))
	expect(int(most.get(3, 0)) > 0 and int(most[3]) <= int(most.get(2, 0)),
		"winter's made nights send no more bodies than autumn's", str(most))

	# **The rhythm in hit points as fought**, and day 56 the year's largest.
	var hp := _hit_points_to(last_day)
	var largest := true
	for day in range(1, last_day):
		largest = largest and int(hp[day]) < int(hp[last_day])
	expect(_season_shape(first_day, hp) and largest,
		"days 49 and 56 are the largest of their halves, the days between grow, and day 56 is the largest night of the year",
		str(hp))
	expect(_boss_days(&"winter_lord") == [[0, last_day], [424242, last_day]],
		"the Winter Lord comes on day 56 and on no other day of the year", str(_boss_days(&"winter_lord")))

	# **A night over before the fill line is refused** (0148, 0271): a copy
	# of spring 3 with its gaps gone sends everything in under a minute, and
	# so does one of winter's Full Moon - asked as the moon fights it.
	var hurried := GameData.KEY_NIGHTS.duplicate(true)
	(hurried[3] as Dictionary)["gap_ticks"] = 0
	var hurried_moon := GameData.KEY_NIGHTS.duplicate(true)
	(hurried_moon[first_day + 6] as Dictionary)["gap_ticks"] = 0
	(hurried_moon[first_day + 6] as Dictionary)["interval_ticks"] = 1
	var refusal := GameData.check_nights(GameData.SEASON_NIGHTS, hurried)
	var moon_refusal := GameData.check_nights(GameData.SEASON_NIGHTS, hurried_moon)
	expect(str(refusal).contains("night 3 is all sent at") and str(refusal).contains("before the fill line")
		and str(moon_refusal).contains("night %d is all sent at" % (first_day + 6))
		and GameData.check_nights(GameData.SEASON_NIGHTS, GameData.KEY_NIGHTS).is_empty()
		and Waves.as_fought(Waves.night_of(last_day), last_day) == Waves.night_of(last_day),
		"check_nights refuses a night all sent before the fill line, a Full Moon asked as it is fought, and passes the year",
		"%s %s" % [str(refusal), str(moon_refusal)])
	_completed += 1


## **The worst night of the year, within budget** (task 0275), checked without
## being run, as `_task_0102_budget` checks the benchmark against `sim.gd`:
## every system `PerfNames` lists has its own branch in `perf_check._tick_one`
## - an unmapped one only logs an error and still prints a row - the worst
## case is the calendar's Winter 14 on a seed whose weather gives it fog, and
## the budgets have not moved.
func _task_0275_perf_year() -> void:
	var bench := FileAccess.get_file_as_string("res://src/tools/perf_check.gd")
	var tool_text := FileAccess.get_file_as_string("res://tools/perf.py")
	var from := bench.find("func _tick_one(")
	var to := bench.find("\nfunc ", from + 1)
	var body := bench.substr(from, to - from) if from >= 0 and to > from else ""
	var missing: Array = []
	for named in PerfNames.NIGHT + PerfNames.DAY:
		if not body.contains("&\"%s\": %s.tick(state)" % [named, named]):
			missing.append(named)
	expect(not body.is_empty() and missing.is_empty(),
		"every system PerfNames names for a night or a day has its own branch in perf_check's _tick_one",
		"missing: %s" % str(missing))

	# **Winter 14, by the calendar, in fog**: the date is `day`, which
	# `Calendar.date` reads, and the seed is found, never forced.
	var night := Calendar.year_days()
	var foggy := -1
	for seed_value in range(102102, 102102 + 4000):
		if Weather.event(seed_value, night) == Weather.FOG:
			foggy = seed_value
			break
	expect(foggy >= 0 and Calendar.boss_of(night) == &"winter_lord"
		and bench.contains("state[\"day\"] = Calendar.year_days()")
		and bench.contains("Weather.event(seed_value, night) == Weather.FOG")
		and bench.contains("const FIRST_SEED := 102102"),
		"the worst case is Winter 14 by the calendar, the Winter Lord's night, on the first seed from 102102 that gives it fog",
		str(foggy))
	expect(bench.contains("for name in GameData.sorted_names(Pathing.FIELDS.keys()):")
		and bench.contains("COUNT winter_night_ms") and bench.contains("COUNT boss ")
		and bench.contains("COUNT defence_%s %d")
		and tool_text.contains("TICK_BUDGET_US = 8333") and tool_text.contains("PATH_BUDGET_US = 33333"),
		"the rebuild asks every field in Pathing.FIELDS, the case counts its defences and its boss, a winter night is timed end to end, and the budgets are 8333 and 33333 us")
	_completed += 1


## **The autoplayer plays a whole year** (task 0276), checked on a slice: from
## a prepared mid-summer farm the `balanced` policy plays one day and one night
## twice on one seed, and gets the same night both times. That day it landed
## a fish through the bar's presses, filled the shipping bin and collected
## from the coop's door; that night it put a defence down by the cursor in the
## build step and fired a power. Timed, printed, and under `SLICE_BUDGET_MS`:
## over it, the slice's day shrinks - bed as soon as it is done - and the cap
## does not move.
const SLICE_BUDGET_MS := 15000
func _task_0276_year_autoplay() -> void:
	var started := Time.get_ticks_msec()
	var policy: Dictionary = (Autoplay.POLICIES[&"balanced"] as Dictionary).duplicate(true)
	policy["bed_minute"] = 10 * 60
	var rows: Array = []
	for _twice in 2:
		var state := _mid_summer_farm()
		rows.append(Autoplay._one_night(state, policy))
	var once: Dictionary = rows[0]
	var did: Dictionary = once["did"]
	var spent := Time.get_ticks_msec() - started
	print("  0276: a mid-summer day and night, twice, in %d ms: %s" % [spent, str(did)])
	expect(var_to_str(rows[0]) == var_to_str(rows[1]),
		"the balanced policy plays the same mid-summer day and night twice on one seed",
		"%s against %s" % [str(rows[0]), str(rows[1])])
	expect(int(did.get(&"fish", 0)) >= 1 and int(did.get(&"shipped", 0)) >= 1
		and int(did.get(&"collected", 0)) >= 1,
		"its day landed a fish through the bar, filled the shipping bin and collected from the coop",
		str(did))
	var fired := 0
	for key in did:
		if String(key).begins_with("power_"):
			fired += int(did[key])
	expect(int(did.get(&"placed", 0)) >= 1 and fired >= 1,
		"its night put a defence down by the cursor in the build step and fired a power",
		str(did))
	expect(int(once["steps"]) > 0 and spent < SLICE_BUDGET_MS,
		"it walked, and the slice took under %d ms" % SLICE_BUDGET_MS,
		"%d steps, %d ms" % [int(once["steps"]), spent])
	var plays := FileAccess.get_file_as_string("res://src/tools/play_nights.gd")
	expect(plays.contains("const DEFAULT_DAYS := %d" % Calendar.year_days())
		and plays.contains("const BOSS_REPEATS := "),
		"play_nights plays the whole year by default and fights a boss night again")
	_completed += 1



## **Task 0277: the instrument the year is balanced with.** Two faults 0277's
## losing runs showed, fixed in the autoplayer rather than tuned around: it
## walled its own porch in with a kitchen and a generator, and woke on Spring
## 13 in six cells with nothing to do; and it kept nine of every fish for the
## kitchen, $3 in the purse and a tower to put back. And the owner's calls:
## spring's stall carries `SPRING_IRON`, the robot buys it when the purse can
## spare it, the RUN line says what each boss had left, the robot saves for
## its season's weapon - autumn's mortar - before anything else new, and a
## defence brought to 0 is a ruin, mended back up.
func _task_0277_year_balance() -> void:
	var state := State.create(27700)
	var bounds := Farm.house_bounds(state)
	var porch := House.porch(state)
	# A pocket under the house, the porch in it, closed but for one cell.
	var ring: Array = [Vector2i(bounds.position.x - 1, porch.y), Vector2i(bounds.end.x, porch.y)]
	for x in range(bounds.position.x, bounds.end.x - 1):
		ring.append(Vector2i(x, porch.y + 1))
	var gap := Vector2i(bounds.end.x - 1, porch.y + 1)
	# A cell the map already fills (the bin, a fixture) closes it as well.
	var walled := 0
	for cell in ring:
		Farm.place(state, cell, {"id": &"fence", "hp": 10})
		if not Farm.walkable(state, cell):
			walled += 1
	var reach := Autoplay._reach_from_porch(state, {})
	expect(walled == ring.size() and reach > 100,
		"a pocket under the porch is walled in but for one cell, and the farm is still reached through it",
		"%d of %d walled, %d cells reached" % [walled, ring.size(), reach])
	expect(not Autoplay._keeps_the_road(state, gap, Vector2i.ONE, reach),
		"the robot will not put anything on the last cell between the porch and the farm")
	var kitchen := Autoplay._room_for(state, &"kitchen")
	expect(kitchen.x >= 0 and Autoplay._keeps_the_road(state, kitchen,
			Building.size_of(&"kitchen"), reach),
		"and the kitchen it does find room for leaves the porch its road", str(kitchen))

	# The bin leaves the kitchen two batches: the fish as one group.
	var larder := State.create(27701)
	var site := Vector2i(-1, -1)
	for cell in Autoplay._near_the_house(larder):
		if site.x < 0 and Farm.buildable(larder, cell):
			site = cell
	Farm.place(larder, site, {"id": &"kitchen", "hp": 50})
	var cheapest := StringName(GameData.pay_order(GameData.FISH)[0])
	Resources.gain(larder, {cheapest: 30, GameData.CARROT: 30})
	var keep := Autoplay._inputs_on_the_farm(larder)
	var fish_kept := 0
	for species in GameData.group_members(GameData.FISH):
		fish_kept += int(keep.get(StringName(species), 0))
	expect(fish_kept == Autoplay.KEEP_BATCHES and int(keep.get(GameData.CARROT, 0)) == 2 * Autoplay.KEEP_BATCHES,
		"a kitchen keeps two meals back from the bin - %d fish of any kind, %d carrots - not nine of each"
			% [Autoplay.KEEP_BATCHES, 2 * Autoplay.KEEP_BATCHES],
		str(keep))

	# Ready for the boss: five nights out the line is deepened, the lowest
	# tower first, and only once the tree allows its next level.
	var policy: Dictionary = Autoplay.POLICIES[&"balanced"]
	var early := State.create(27702)
	early["day"] = GameData.SEASON_DAYS - 5
	var ready := State.create(27702)
	ready["day"] = GameData.SEASON_DAYS - 4
	expect(not Autoplay._boss_prep(early, policy) and Autoplay._boss_prep(ready, policy),
		"the balanced robot readies for the Giant from Spring %d, five nights out, and not before"
			% (GameData.SEASON_DAYS - 4),
		"%d, %d" % [Calendar.date(early), Calendar.date(ready)])
	var line: Array = []
	for cell in Autoplay._near_the_house(ready):
		if line.size() < 2 and Farm.buildable(ready, cell) and Autoplay._house_distance(ready, cell) >= 3:
			line.append(cell)
	Farm.place(ready, line[0], {"id": &"gun_tower", "hp": 90, "level": 2})
	Farm.place(ready, line[1], {"id": &"auto_crossbow", "hp": 40})
	var untaught := Autoplay._prep_target(ready)
	(ready["tech_owned"] as Array).append(&"true sights")
	expect(untaught.x < 0 and Autoplay._prep_target(ready) == line[1],
		"it takes up the level one crossbow before the level two gun, once 'true sights' is bought",
		"%s, then %s" % [str(untaught), str(Autoplay._prep_target(ready))])
	# **Guns before walls** (the owner's call, 2026-10-13): a wall at level
	# one waits while a gun can still go up.
	var guarded := State.create(27703)
	(guarded["tech_owned"] as Array).append_array([&"true sights", &"stout timbers"])
	guarded["day"] = GameData.SEASON_DAYS - 4
	var spots: Array = []
	for cell in Autoplay._near_the_house(guarded):
		if spots.size() < 2 and Farm.buildable(guarded, cell) and Autoplay._house_distance(guarded, cell) >= 3:
			spots.append(cell)
	Farm.place(guarded, spots[0], {"id": &"wall", "hp": 120})
	Farm.place(guarded, spots[1], {"id": &"gun_tower", "hp": 60})
	expect(Autoplay._prep_target(guarded) == spots[1],
		"the boss prep takes a gun up before a wall", str(Autoplay._prep_target(guarded)))

	# **Each season's weapons** (the owner's call on 0277): every season a
	# policy names is a season, and what it builds and walks exists.
	var seasonal: Array = []
	for name in Autoplay.names():
		var plans: Dictionary = (Autoplay.POLICIES[name] as Dictionary).get("seasons", {})
		for season in GameData.sorted_names(plans.keys()):
			var plan: Dictionary = plans[season]
			var ok := GameData.SEASONS.has(StringName(season))
			for id in (plan.get("build", []) as Array):
				ok = ok and Building.entry_of(StringName(id)) != null
			for id in (plan.get("tech", []) as Array):
				ok = ok and not Tech.node(StringName(id)).is_empty()
			if not ok:
				seasonal.append("%s %s" % [name, season])
	var balanced_plans: Dictionary = (Autoplay.POLICIES[&"balanced"] as Dictionary)["seasons"]
	expect(seasonal.is_empty() and (balanced_plans[&"spring"]["build"] as Array).has(&"mine")
			and (balanced_plans[&"summer"]["build"] as Array).has(&"flame_tower")
			and (balanced_plans[&"autumn"]["build"] as Array).has(&"mortar")
			and (balanced_plans[&"autumn"]["build"] as Array).has(&"catapult")
			and (Autoplay.POLICIES[&"balanced"]["tech"] as Array).has(&"oiled works"),
		"every season plan names real seasons, things and nodes; balanced fields mines, the flamethrower, the mortar, the catapult and level three",
		str(seasonal))

	# **Made, not planned around**: gunpowder from coal and the pond's oil
	# once a press stands; corn only in its season; and the bench makes
	# neither a kit the plan never puts up nor bone meal.
	var bench := State.create(27704)
	expect(not Autoplay._can_be_had(bench, GameData.GUNPOWDER),
		"with no press, gunpowder is planned around as before")
	Resources.gain(bench, {GameData.WOOD: 200, GameData.STONE: 200, GameData.IRON: 200,
		GameData.MONEY: 500})
	var pressed := Building.place(bench, &"press", Autoplay._room_for(bench, &"press"))
	expect(pressed and Autoplay._can_be_had(bench, GameData.GUNPOWDER)
			and not Autoplay._can_be_had(bench, GameData.CORN),
		"with one, gunpowder can be had - the seams' coal, the pond's oil - and spring's corn cannot")
	var spring_plan: Array = balanced_plans[&"spring"]["build"]
	expect(not Autoplay._worth_making(bench, &"barricade_kit", spring_plan)
			and not Autoplay._worth_making(bench, &"grind_bone_meal", spring_plan)
			and not Autoplay._worth_making(bench, &"make_bait", spring_plan)
			and Autoplay._worth_making(bench, &"make_gunpowder_coal", spring_plan)
			and Autoplay._worth_making(bench, &"wall_kit", spring_plan),
		"the bench makes gunpowder and the plan's wall kits, never barricade kits, bone meal or bait")

	# **A rebuild is not a new one**: the lost count falls when a lost tower
	# goes back up.
	var rebuilt := State.create(27705)
	Resources.gain(rebuilt, {GameData.WOOD: 100, GameData.IRON: 100, GameData.MONEY: 200})
	NightRoad.into_build(rebuilt)
	var first := Autoplay._room_for(rebuilt, &"gun_tower")
	Autoplay._place_by_cursor(rebuilt, &"gun_tower", first)
	Farm.remove(rebuilt, first)
	var lost_before := Autoplay._lost_defences(rebuilt).size()
	Autoplay._place_by_cursor(rebuilt, &"gun_tower", Autoplay._room_for(rebuilt, &"gun_tower"), false)
	expect(lost_before == 1 and Autoplay._lost_defences(rebuilt).is_empty(),
		"a lost gun put back is off the lost list", "%d, then %d" % [lost_before, Autoplay._lost_defences(rebuilt).size()])

	# **A mine on the horde's road**, the free cell of it nearest the house.
	var mined := State.create(27706)
	mined["day"] = GameData.SEASON_DAYS
	mined["nights_won"] = GameData.SEASON_DAYS - 1
	Resources.gain(mined, {GameData.IRON: 50, GameData.GUNPOWDER: 50, GameData.MONEY: 200})
	NightRoad.into_build(mined)
	var road := Pathing.horde_routes(mined, Waves.spawns_in(Waves.night_of(GameData.SEASON_DAYS, int(mined["seed"]))))
	var at := Autoplay._mine_spot(mined)
	expect(at.x >= 0 and road.has(at) and Building.why_not(mined, &"mine", at).is_empty(),
		"the boss prep's mine goes on the road the horde walks to the house", str(at))

	# **Spring's iron at the stall** (the owner's call): a spring morning's
	# shelf holds `SPRING_IRON`, more than the year's `DAILY_STOCK`; summer's
	# is the year's again.
	var spring_stall := State.create(27708)
	var year_iron := int(GameData.DAILY_STOCK[GameData.IRON])
	expect(Shop.season(spring_stall) == GameData.SEASONS[0]
		and Shop.stock_of(spring_stall, GameData.IRON) == GameData.SPRING_IRON
		and GameData.SPRING_IRON > year_iron
		and int(GameData.stall_stock(GameData.SEASONS[1]).get(GameData.IRON, 0)) == year_iron,
		"a spring morning's stall holds SPRING_IRON iron, more than the year's; summer's is the year's",
		"%d, %d" % [Shop.stock_of(spring_stall, GameData.IRON), year_iron])

	# **Bought before dug, when the purse can spare it**: the plan's gun short
	# of iron and the stall open. Over the plan's money, the packets and
	# `BUY_BEFORE_DIGGING`, the iron is bought; with the gun's money alone it
	# is dug.
	var buyer := SuiteKit.early_policy(&"towers")
	buyer.erase("seasons")
	var flush := State.create(27709)
	flush["autoplay_step"] = (buyer["build"] as Array).find(&"gun_tower")
	flush["day_tick"] = Phases.tick_at_minute(GameData.STALL_OPENS)
	Resources.spend(flush, GameData.IRON, Resources.amount(flush, GameData.IRON))
	Resources.spend(flush, GameData.MONEY, Resources.amount(flush, GameData.MONEY))
	Resources.gain(flush, {GameData.WOOD: 100})
	var poor := flush.duplicate(true)
	var gun_money := int((GameData.DEFENCES[&"gun_tower"]["cost"] as Dictionary)[GameData.MONEY])
	Resources.gain(flush, {GameData.MONEY: 1000})
	Resources.gain(poor, {GameData.MONEY: gun_money + Autoplay.BUY_BEFORE_DIGGING / 2})
	Autoplay._one_thing(flush, buyer)
	Autoplay._one_thing(poor, buyer)
	var flush_did: Dictionary = flush.get("autoplay_did", {})
	var poor_did: Dictionary = poor.get("autoplay_did", {})
	expect(int(flush_did.get(&"bought_iron", 0)) == 1 and Resources.amount(flush, GameData.IRON) > 0
		and int(poor_did.get(&"bought_iron", 0)) == 0,
		"with money to spare the gun's iron is bought at the stall; with the gun's money alone it is not",
		"%s / %s" % [str(flush_did), str(poor_did)])

	# **What each boss had left, on the RUN line**: a fight it survived at
	# 120, one it fell in at 0, nights with no boss left out.
	var runner: GDScript = load("res://src/tools/autoplay_run.gd")
	var season_row := {"losses": 0, "repeats": 1, "money": 0, "essence": 0}
	var run_line := String(runner._run_line({"policy": &"balanced", "seed": 1, "capped": false,
		"year_over": false, "walked": 0, "seasons": [season_row],
		"nights": [{"date": 13, "held": true, "boss_left": -1},
			{"date": 14, "held": false, "boss_left": 120},
			{"date": 14, "held": true, "boss_left": 0}]}, 0))
	expect(run_line.contains(" lost=14 boss_left=120,0 "),
		"the RUN line carries each boss fight's hit points left, 0 for one it fell in", run_line)

	# **The season's weapon saved for** (the owner's call): on an autumn day
	# with a press, the plan wants the mortar first and keeps its bill from a
	# gun; with no press, or once a mortar stands, nothing is kept.
	var autumn := State.create(27710)
	autumn["day"] = 2 * GameData.SEASON_DAYS + 1
	autumn["nights_won"] = 2 * GameData.SEASON_DAYS
	var gunner: Dictionary = Autoplay.POLICIES[&"towers"]
	var unpressed := Autoplay._season_weapon(autumn, gunner)
	Resources.gain(autumn, {GameData.WOOD: 200, GameData.STONE: 200, GameData.IRON: 200,
		GameData.MONEY: 500})
	var autumn_press := Building.place(autumn, &"press", Autoplay._room_for(autumn, &"press"))
	Resources.spend(autumn, GameData.IRON, Resources.amount(autumn, GameData.IRON))
	Resources.gain(autumn, {GameData.IRON: 20})
	var saved := Autoplay._the_plan_ahead(autumn, gunner)
	NightRoad.into_build(autumn)
	autumn["autoplay_step"] = ((gunner["seasons"] as Dictionary)[&"autumn"]["build"] as Array).find(&"gun_tower")
	Autoplay._one_defence_thing(autumn, gunner)
	var guns_kept_back := Farm.cells_with(autumn, &"gun_tower").is_empty()
	Resources.gain(autumn, {GameData.IRON: 40, GameData.GUNPOWDER: 20})
	Autoplay._one_defence_thing(autumn, gunner)
	expect(autumn_press and unpressed == &"" and StringName(saved["want"]) == &"mortar" and bool(saved.get("weapon", false))
			and guns_kept_back and not Farm.cells_with(autumn, &"mortar").is_empty()
			and Autoplay._season_weapon(autumn, gunner) == &""
			and Autoplay._kept_for_weapon(autumn, gunner).is_empty(),
		"autumn's plan saves for the mortar first, keeps its iron from a gun, puts it up once paid for, and then keeps nothing",
		"%s %s %s" % [str(saved), str(guns_kept_back), str(Farm.cells_with(autumn, &"mortar"))])

	# **A defence brought to 0 is a ruin, mended back** (the owner's call): a
	# level two gun knocked down leaves its cell open and a ruin at level two
	# that the morning does not sweep, where a mine's rubble goes; mending it
	# raises the level two gun for half its price in its own materials, and
	# something built over a ruin takes its place.
	var ruined := State.create(27711)
	var gun_cell := Autoplay._room_for(ruined, &"gun_tower")
	Farm.place(ruined, gun_cell, {"id": &"gun_tower", "hp": 1, "level": 2})
	var wall_cell := Autoplay._room_for(ruined, &"wall")
	Farm.place(ruined, wall_cell, {"id": &"wall", "hp": 1})
	var mine_cell := Autoplay._room_for(ruined, &"mine")
	Farm.place(ruined, mine_cell, {"id": &"mine", "hp": 1})
	for cell in [gun_cell, wall_cell, mine_cell]:
		Farm.damage(ruined, cell, 9999)
	Farm.clear_rubble(ruined)
	var gun_ruin := Farm.ruin_at(ruined, gun_cell)
	var level_two_hp := Building.levelled_stat({"id": &"gun_tower", "level": 2}, "hp")
	var whole_mend := Repair.cost_at(ruined, gun_cell, level_two_hp)
	var gun_iron := int((GameData.DEFENCES[&"gun_tower"]["cost"] as Dictionary)[GameData.IRON])
	var ruin_open := Farm.walkable(ruined, gun_cell) and Farm.occupant(ruined, gun_cell).is_empty()
	Resources.gain(ruined, {GameData.WOOD: 100, GameData.IRON: 100, GameData.MONEY: 200})
	var aimed := GuardianCursor.mend_target(ruined, gun_cell)
	var raised := Repair.apply(ruined, gun_cell, level_two_hp)
	var back := Farm.occupant(ruined, gun_cell)
	Farm.place(ruined, wall_cell, {"id": &"fence", "hp": 1})
	expect(gun_ruin == {"id": &"gun_tower", "level": 2} and ruin_open and aimed == gun_cell
			and Repair.damage_at(ruined, mine_cell) == 0 and Farm.rubble_at(ruined, mine_cell) == &""
			and int(whole_mend.get(GameData.IRON, 0)) > 0
			and int(whole_mend.get(GameData.IRON, 0)) <= gun_iron * GameData.REPAIR_PERCENT / 100
			and raised == level_two_hp and StringName(back.get("id", &"")) == &"gun_tower"
			and int(back.get("level", 1)) == 2 and int(back.get("hp", 0)) == level_two_hp
			and Farm.ruin_at(ruined, gun_cell).is_empty() and Farm.rubble_at(ruined, gun_cell) == &""
			and Farm.ruin_at(ruined, wall_cell).is_empty() and Farm.rubble_at(ruined, wall_cell) == &"",
		"a gun knocked down is an open cell and a level two ruin the morning keeps, a mine's rubble is swept; mending raises it at level two for half its iron, and a fence built over a ruin takes its place",
		"%s %s %s %d %s" % [str(gun_ruin), str(whole_mend), str(back), raised, str(aimed)])
	expect(Building.ruins(&"gun_tower") and Building.ruins(&"wall") and Building.ruins(&"mortar")
			and not Building.ruins(&"mine") and not Building.ruins(&"barricade")
			and not Building.ruins(&"zombie_bait") and not Building.ruins(&"garlic_braid")
			and not Building.ruins(&"kitchen"),
		"every defence ruins but a trap, a thing walked over and a thing with a lifetime; no building does")

	# **The robot mends its ruins back, whole**: its plan saves for a ruin's
	# mend before anything else, and the build step raises it only once the
	# purse runs to all of it.
	var mender := State.create(27712)
	var mend_policy := SuiteKit.early_policy(&"towers")
	mend_policy.erase("seasons")
	var mend_cell := Autoplay._room_for(mender, &"gun_tower")
	Farm.place(mender, mend_cell, {"id": &"gun_tower", "hp": 1})
	Farm.damage(mender, mend_cell, 9999)
	Resources.spend(mender, GameData.IRON, Resources.amount(mender, GameData.IRON))
	var mend_ahead := Autoplay._the_plan_ahead(mender, mend_policy)
	NightRoad.into_build(mender)
	var raised_poor := Autoplay._mend_one(mender)
	Resources.gain(mender, {GameData.IRON: 20, GameData.WOOD: 20, GameData.MONEY: 50})
	var raised_rich := Autoplay._mend_one(mender)
	var gun_full := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])
	expect(StringName(mend_ahead["want"]) == &"gun_tower" and bool(mend_ahead.get("rebuild", false))
			and not raised_poor and raised_rich
			and int(Farm.occupant(mender, mend_cell).get("hp", 0)) == gun_full,
		"the robot's plan saves for a ruin's mend first, and it raises the ruin only whole",
		"%s %s %s %s" % [str(mend_ahead), str(raised_poor), str(raised_rich), str(Farm.occupant(mender, mend_cell))])
	_completed += 1

## **Task 0281: the new day's sounds.** Every new id is a file. What a verb is
## done to, the verbs that used to borrow, and the smith's anvil keep the
## furniture rule `_task_0084_day_sounds` holds - quieter and shorter than the
## bite. The moments are a named list under the alarm, the same six in
## `gen_sfx.py` and in `Sfx`. Ore and machine targets resolve to their own
## sound, and an unknown target to its verb's.
func _task_0281_day_sounds() -> void:
	var furniture: Array = [Sfx.ANVIL_SOUND, Sfx.VERB_SOUNDS[&"dig"],
		Sfx.VERB_SOUNDS[&"ship"], Sfx.VERB_SOUNDS[&"fertilise"]]
	for target in GameData.sorted_names(Sfx.TARGET_SOUNDS.keys()):
		furniture.append(Sfx.TARGET_SOUNDS[target])
	var missing: Array = []
	for id in furniture + Sfx.MOMENT_SOUNDS:
		if not FileAccess.file_exists("res://assets/%s.wav" % id):
			missing.append(id)
	expect(missing.is_empty(), "every new day sound is a file in assets/sfx", str(missing))

	var bite := _wav_measure("res://assets/%s.wav" % Sfx.BITE_SOUND)
	var alarm := _wav_measure("res://assets/%s.wav" % Sfx.HOUSE_SOUND)
	var loud: Array = []
	for id in furniture:
		var one := _wav_measure("res://assets/%s.wav" % id)
		if one.is_empty() or float(one["peak"]) > 0.6 or float(one["seconds"]) >= 0.6 \
				or float(one["peak"]) >= float(bite["peak"]) \
				or float(one["seconds"]) >= float(bite["seconds"]):
			loud.append("%s %s" % [id, str(one)])
	expect(loud.is_empty() and not bite.is_empty(),
		"the new per-action sounds are furniture: under 0.6 and 0.6 s, quieter and shorter than the bite",
		str(loud))

	# The moments: once or twice a day, their own list and peak, under the
	# alarm - named in the generator as in `Sfx`.
	var over: Array = []
	for id in Sfx.MOMENT_SOUNDS:
		var one := _wav_measure("res://assets/%s.wav" % id)
		if one.is_empty() or float(one["peak"]) >= float(alarm["peak"]):
			over.append("%s %s" % [id, str(one)])
	var gen := FileAccess.get_file_as_string("res://tools/gen_sfx.py")
	var named: Array = []
	for id in Sfx.MOMENT_SOUNDS:
		if gen.contains("(\"%s\", %s, MOMENT_PEAK)" % [String(id).get_file(), String(id).get_file()]):
			named.append(id)
	var moment_peak := _py_number(gen, "MOMENT_PEAK")
	var alarm_peak := _py_number(gen, "ALARM_PEAK")
	expect(over.is_empty() and not alarm.is_empty(),
		"the day's moments are quieter than the house being hit", str(over))
	expect(named.size() == Sfx.MOMENT_SOUNDS.size() and Sfx.MOMENT_SOUNDS.size() == 6
			and moment_peak > 0.0 and moment_peak < alarm_peak,
		"they are the six of gen_sfx.py's MOMENT_SOUNDS, at a MOMENT_PEAK under ALARM_PEAK",
		"%d named, %.2f against %.2f" % [named.size(), moment_peak, alarm_peak])

	# What a verb is done to, before the verb.
	var wrong: Array = []
	for pair in [[&"mine", &"copper_ore", &"sfx/mine_copper"], [&"mine", &"coal_seam", &"sfx/mine_coal"],
			[&"mine", &"gold_ore", &"sfx/mine_gold"], [&"mine", &"rock", &"sfx/mine"],
			[&"craft", &"workshop", &"sfx/craft"], [&"chop", &"", &"sfx/chop"]]:
		if Sfx.sound_for(StringName(pair[0]), StringName(pair[1])) != StringName(pair[2]):
			wrong.append(pair)
	for machine in Autoplay.MACHINES:
		var own := Sfx.sound_for(&"craft", StringName(machine))
		if own != StringName("sfx/%s" % machine):
			wrong.append([&"craft", machine, own])
	expect(wrong.is_empty(),
		"copper, coal and gold strike as their ore and each machine sounds as itself; a rock, the workshop and nothing at all fall back to the verb",
		str(wrong))
	expect(Sfx.sound_for(&"repair", &"keg") == &"",
		"and a deliberately silent verb stays silent whatever it is done to")

	# **Every day verb its own file** - the three that borrowed in 0185,
	# 0189 and 0222 included.
	var seen := {}
	var shared: Array = []
	for verb in Interact.DAY_ONLY:
		if Interact.is_instant(verb) or not Sfx.VERB_SOUNDS.has(verb):
			continue
		var id: StringName = Sfx.VERB_SOUNDS[verb]
		if seen.has(id):
			shared.append("%s and %s: %s" % [seen[id], verb, id])
		seen[id] = verb
	expect(shared.is_empty(), "no two day verbs share a sound", str(shared))
	_completed += 1


## **Task 0282: the fishing bar, by ear.** The tick, the hit, the miss and the
## catch are files and furniture against the bite, which opens the window and
## stays the loudest and longest day sound. The legendary's fanfare is music:
## in `assets/music/`, under five seconds, at most `STING_PEAK`, and built on
## `MOTIF`. The reel is kept, as the line coming in.
func _task_0282_fishing_sounds() -> void:
	var bite := _wav_measure("res://assets/%s.wav" % Sfx.BITE_SOUND)
	var wrong: Array = []
	for id in [Sfx.TICK_SOUND, Sfx.HIT_SOUND, Sfx.MISS_SOUND, Sfx.CATCH_SOUND]:
		var one := _wav_measure("res://assets/%s.wav" % id)
		if one.is_empty() or float(one["peak"]) > 0.56 \
				or float(one["peak"]) >= float(bite.get("peak", 0.0)) \
				or float(one["seconds"]) >= float(bite.get("seconds", 0.0)):
			wrong.append("%s %s" % [id, str(one)])
	expect(wrong.is_empty() and not bite.is_empty(),
		"the bar's tick, hit, miss and catch are files, at most SOFT_PEAK, quieter and shorter than the bite",
		str(wrong))

	var music := FileAccess.get_file_as_string("res://tools/gen_music.py")
	var cue := _wav_measure("res://assets/%s.wav" % Sfx.LEGEND_SOUND)
	var sting_peak := _py_number(music, "STING_PEAK")
	expect(String(Sfx.LEGEND_SOUND).begins_with("music/") and not cue.is_empty()
			and float(cue["seconds"]) < 5.0 and float(cue["peak"]) <= sting_peak + 0.001,
		"the legendary's fanfare is a cue in assets/music, under five seconds and at most STING_PEAK",
		"%s at %.2f" % [str(cue), sting_peak])
	var recipe := ""
	if music.contains("def fanfare():"):
		recipe = music.get_slice("def fanfare():", 1).get_slice("\ndef ", 0).get_slice("\n## ", 0)
	expect(recipe.contains("MOTIF") and music.contains("(\"fanfare\", fanfare, STING_PEAK)"),
		"built on the year's MOTIF, and a PIECES entry so --check knows it")
	expect(Interact.DAY_ONLY.has(&"reel") and Sfx.VERB_SOUNDS.get(&"reel", &"") == &"sfx/reel"
			and FileAccess.file_exists("res://assets/sfx/reel.wav"),
		"the reel verb is still a day verb, so its sound stays - played as the line comes in")
	_completed += 1


## **Task 0283: the guardian's sounds.** Every new id is a file under the
## weapons' `NIGHT_PEAK` and shorter than the Giant's roar; no two damaging
## defences share a shot; every defence without `damage` is out of
## `TOWER_SOUNDS`; and `Sfx.vanished_as` tells a sale from a wreck with
## rubble, a spent mine and a barricade whose life ran out.
func _task_0283_guardian_sounds() -> void:
	var new_ids: Array = [Sfx.PLACE_SOUND, Sfx.UPGRADE_SOUND, Sfx.MEND_SOUND,
		Sfx.SELL_BACK_SOUND, Sfx.HORN_SOUND, Sfx.DOG_BITE_SOUND, Sfx.SPLAT_SOUND,
		Sfx.TOWER_SOUNDS[&"beehive"], Sfx.TOWER_SOUNDS[&"catapult"]]
	for id in GameData.sorted_names(Sfx.DEFENCE_SOUNDS.keys()):
		new_ids.append(Sfx.DEFENCE_SOUNDS[id])
	for id in Ability.ORDER:
		new_ids.append(Sfx.POWER_SOUNDS[id])
	var gen := FileAccess.get_file_as_string("res://tools/gen_sfx.py")
	var night_peak := _py_number(gen, "NIGHT_PEAK")
	var roar := _wav_measure("res://assets/%s.wav" % Sfx.ENEMY_SOUNDS[&"giant"])
	var wrong: Array = []
	for id in new_ids:
		var one := _wav_measure("res://assets/%s.wav" % id)
		if one.is_empty() or float(one["peak"]) >= night_peak \
				or float(one["seconds"]) >= float(roar.get("seconds", 0.0)):
			wrong.append("%s %s" % [id, str(one)])
	expect(wrong.is_empty() and night_peak > 0.0,
		"every new night sound is a file under NIGHT_PEAK and shorter than the Giant's roar",
		str(wrong))
	var hand := _wav_measure("res://assets/%s.wav" % Sfx.PLACE_SOUND)
	expect(not hand.is_empty() and float(hand["peak"]) <= _py_number(gen, "SOFT_PEAK") + 0.001,
		"the cursor's hand is quieter than the weapons, at SOFT_PEAK", str(hand))

	var shots := {}
	var shared: Array = []
	var stray: Array = []
	for id in GameData.sorted_names(GameData.DEFENCES.keys()):
		var hurts := (GameData.DEFENCES[id] as Dictionary).has("damage")
		if not hurts and Sfx.TOWER_SOUNDS.has(id):
			stray.append(id)
		if hurts and Sfx.TOWER_SOUNDS.has(id):
			var file: StringName = Sfx.TOWER_SOUNDS[id]
			if shots.has(file):
				shared.append("%s and %s" % [shots[file], id])
			shots[file] = id
	expect(shared.is_empty(), "no two damaging defences share a shot", str(shared))
	expect(stray.is_empty() and not Sfx.DEFENCE_SOUNDS.is_empty(),
		"every defence without damage is out of TOWER_SOUNDS, its noise in DEFENCE_SOUNDS",
		str(stray))

	# Sold, broken, spent, expired.
	var state := State.create(28300)
	var cell := Vector2i(5, 5)
	var broke := State.create(28301)
	(broke["rubble"] as Dictionary)[Grid.index(cell)] = &"wall"
	var answers := [Sfx.vanished_as(state, cell, &"gun_tower"),
		Sfx.vanished_as(broke, cell, &"wall"), Sfx.vanished_as(state, cell, &"mine"),
		Sfx.vanished_as(state, cell, &"barricade")]
	expect(answers == [&"sold", &"broke", &"spent", &"expired"],
		"a gun tower gone with nothing left was sold, a wall gone with rubble broke, a mine was spent, a barricade expired",
		str(answers))
	_completed += 1


## **Task 0284: the new enemies and bosses, heard.** Every enemy has a voice
## file of its own; every boss's voice is longer than every ordinary night
## sound and quieter than the house being hit; the new things they do are
## files; and fifty rats are one entry in `nearest_by_kind`.
func _task_0284_enemy_sounds() -> void:
	var owners := {}
	var wrong: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		var voice := Sfx.voice_of(StringName(kind))
		if voice == &"" or not FileAccess.file_exists("res://assets/%s.wav" % voice):
			wrong.append("%s has no file" % kind)
		elif owners.has(voice):
			wrong.append("%s and %s share %s" % [owners[voice], kind, voice])
		owners[voice] = kind
	expect(wrong.is_empty(), "every enemy has a voice file of its own", str(wrong))

	var alarm := _wav_measure("res://assets/%s.wav" % Sfx.HOUSE_SOUND)
	var ordinary := 0.0
	for id in [Sfx.SPIT_SOUND, Sfx.SPIT_LAND_SOUND, Sfx.SURFACE_SOUND, Sfx.CHILL_SOUND,
			Sfx.CHARGE_SOUND, Sfx.CRUSH_SOUND, Sfx.SUMMON_SOUND, Sfx.FREEZE_SOUND,
			Sfx.DEATH_SOUNDS[&"frost_zombie"], Sfx.HORN_SOUND, Sfx.POWER_SOUNDS[&"farm_bell"]]:
		var one := _wav_measure("res://assets/%s.wav" % id)
		ordinary = maxf(ordinary, float(one.get("seconds", 99.0)))
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if not Combat.is_boss(StringName(kind)):
			var one := _wav_measure("res://assets/%s.wav" % Sfx.voice_of(StringName(kind)))
			ordinary = maxf(ordinary, float(one.get("seconds", 99.0)))
	var bosses: Array = []
	for kind in GameData.sorted_names(GameData.ENEMIES.keys()):
		if not Combat.is_boss(StringName(kind)):
			continue
		var one := _wav_measure("res://assets/%s.wav" % Sfx.voice_of(StringName(kind)))
		if one.is_empty() or float(one["seconds"]) <= ordinary \
				or float(one["peak"]) >= float(alarm.get("peak", 0.0)):
			bosses.append("%s %s" % [kind, str(one)])
	expect(bosses.is_empty() and not alarm.is_empty(),
		"every boss's voice is longer than any ordinary night sound (%.2fs) and quieter than the alarm" % ordinary,
		str(bosses))

	# **Fifty rats are one voice** (0085's promise, for the swarm of 0248).
	var state := State.create(28400)
	var home := Farm.house_centre(state)
	for i in 50:
		Entities.spawn(state, &"rat", home + Vector2i(6 + i % 5, -3 + i / 10))
	Entities.spawn(state, &"walker", home + Vector2i(-6, 0))
	var ears := Sfx.new()
	ears.show_state(state)
	var voices := ears.nearest_by_kind()
	ears.free()
	expect(voices.size() == 2 and voices.has(&"rat") and voices.has(&"walker"),
		"fifty rats and a walker are two voices, not fifty-one", str(voices.keys()))
	_completed += 1


## **Task 0285: music for four seasons.** `piece_for` answers each season by
## day and the night (the winter one in winter), a boss night from its build
## step to dawn, the ending screen and a menu with the setting off and on.
## Every looping piece's seam is at most 1.0 of its 99th-percentile step and
## it runs over 15 s; every arrangement reads `MOTIF`; the credits run as
## long as 0160's roll and play once.
func _task_0285_season_music() -> void:
	var wrong: Array = []
	var day := {&"spring": Music.FARM, &"summer": Music.SUMMER,
		&"autumn": Music.AUTUMN, &"winter": Music.WINTER}
	for season in GameData.SEASONS:
		var night := Music.WINTER_NIGHT if season == &"winter" else Music.NIGHT
		var asked := [Music.piece_for(Phases.DAY, false, false, season),
			Music.piece_for(Phases.PREPARATION, false, false, season),
			Music.piece_for(Phases.NIGHT, false, false, season),
			Music.piece_for(Phases.RESULT, false, false, season),
			Music.piece_for(Phases.PREPARATION, false, false, season, true),
			Music.piece_for(Phases.NIGHT, false, false, season, true),
			Music.piece_for(Phases.RESULT, false, false, season, true)]
		var wanted := [day[season], night, night, night, Music.BOSS, Music.BOSS, night]
		if asked != wanted:
			wrong.append("%s: %s" % [season, str(asked)])
	expect(wrong.is_empty(),
		"each season's day plays its piece, the night (winter's in winter) the build step, waves and report, and a boss night the boss track until dawn",
		str(wrong))
	expect(Music.piece_for(Phases.RESULT, false, false, &"winter", false, true) == Music.CREDITS
			and Music.piece_for(Phases.DAY, true, false, &"autumn") == &""
			and Music.piece_for(Phases.DAY, true, true, &"autumn") == Music.FARM,
		"the ending screen plays the credits, and a menu is silent or spring's as the setting says")

	var seams: Array = []
	for id in Music.LOOPS:
		var seam := _seam_of("res://assets/%s.wav" % id)
		if seam.is_empty() or float(seam["ratio"]) > 1.0 or float(seam["seconds"]) <= 15.0:
			seams.append("%s %s" % [id, str(seam)])
	expect(seams.is_empty(), "every looping piece joins under its own 99th-percentile step and runs over 15 s",
		str(seams))

	var source := FileAccess.get_file_as_string("res://tools/gen_music.py")
	var deaf: Array = []
	for id in Music.LOOPS:
		var file := String(id).get_file()
		var recipe := source.get_slice("(\"%s\", " % file, 1).get_slice(",", 0).strip_edges()
		if recipe == "" or not source.get_slice("def %s():" % recipe, 1).get_slice("\ndef ", 0).contains("MOTIF"):
			deaf.append(id)
	expect(deaf.is_empty(), "every arrangement reads MOTIF", str(deaf))

	var roll := _wav_measure("res://assets/%s.wav" % Music.CREDITS)
	expect(not roll.is_empty() and absf(float(roll["seconds"]) - CreditsRoll.roll_seconds()) < 0.1
			and Music.PLAYS_ONCE.has(Music.CREDITS) and not Music.LOOPS.has(Music.CREDITS)
			and source.get_slice("NOT_LOOPS = [", 1).get_slice("]", 0).contains("\"credits\""),
		"the credits run as long as the roll (%.1f s) and are named as playing once" % CreditsRoll.roll_seconds(),
		str(roll))
	_completed += 1


## **Task 0286: fog, rain and winter wind.** `bed_for` answers every season,
## phase and event; the new beds loop and stay under the old beds' peak; no
## touch is in both a day and a night list, and winter's hold no cricket and
## no songbird; the animals are offered only where a coop or barn with them
## stands; each stinger is a cue in `assets/music/` at most `STING_PEAK` and
## on 0285's not-loop list.
func _task_0286_weather_ambience() -> void:
	var wrong: Array = []
	for season in GameData.SEASONS:
		for event in [&"", &"fog", &"rain", &"blood_moon"]:
			for phase in [Phases.DAY, Phases.PREPARATION, Phases.NIGHT, Phases.RESULT]:
				var want := Ambience.DAY_BED if phase == Phases.DAY else Ambience.NIGHT_BED
				if season == &"winter":
					want = Ambience.WINTER_BED
				if phase != Phases.DAY and event == &"fog":
					want = Ambience.FOG_BED
				if phase != Phases.DAY and event == &"rain":
					want = Ambience.RAIN_BED
				var got := Ambience.bed_for(phase, season, event)
				if got != want:
					wrong.append("%s %s %s: %s" % [season, event, Phases.name_of(phase), got])
	expect(wrong.is_empty(),
		"the day and night beds, winter's wind by day and night, and fog and rain from an event night's build step to its report",
		str(wrong))

	var old_peak := float(_wav_measure("res://assets/%s.wav" % Ambience.DAY_BED).get("peak", 0.0))
	var beds: Array = []
	for id in [Ambience.FOG_BED, Ambience.RAIN_BED, Ambience.WINTER_BED]:
		var seam := _seam_of("res://assets/%s.wav" % id)
		var one := _wav_measure("res://assets/%s.wav" % id)
		if seam.is_empty() or float(seam["ratio"]) > 1.0 or one.is_empty() \
				or float(one["peak"]) > old_peak + 0.001:
			beds.append("%s %s %s" % [id, str(seam), str(one)])
	expect(beds.is_empty() and old_peak > 0.0,
		"the fog, rain and winter beds loop and peak no higher than the old beds (%.2f)" % old_peak,
		str(beds))

	var day_lists: Array = Ambience.DAY_TOUCHES + Ambience.WINTER_DAY_TOUCHES + Ambience.ANIMAL_CALLS.values()
	var night_lists: Array = Ambience.NIGHT_TOUCHES + Ambience.WINTER_NIGHT_TOUCHES + [Ambience.MURMUR]
	var both: Array = []
	for id in day_lists:
		if night_lists.has(id):
			both.append(id)
	var summery: Array = []
	for id in Ambience.WINTER_DAY_TOUCHES + Ambience.WINTER_NIGHT_TOUCHES:
		if String(id).contains("cricket") or String(id).contains("bird"):
			summery.append(id)
	expect(both.is_empty() and summery.is_empty()
			and Ambience.touches_for(Phases.DAY, &"winter") == Ambience.WINTER_DAY_TOUCHES
			and Ambience.touches_for(Phases.NIGHT, &"winter") == Ambience.WINTER_NIGHT_TOUCHES,
		"no touch is in a day list and a night list, and winter's hold no cricket and no songbird",
		"%s / %s" % [str(both), str(summery)])

	# The animals: none without a home with them in it; the hens' cluck by
	# day and the murmur at night where a coop with hens stands.
	var bare := State.create(28600)
	var coop_farm := _mid_summer_farm()
	var emptied := _mid_summer_farm()
	for idx in (emptied["housed"] as Dictionary):
		((emptied["housed"][idx] as Dictionary).get("animals", []) as Array).clear()
	var empty_coop := Ambience.animal_touches(emptied, Phases.DAY)
	var placed := not Farm.cells_with(coop_farm, &"coop").is_empty()
	expect(placed and Ambience.animal_touches(bare, Phases.DAY).is_empty()
			and empty_coop.is_empty()
			and Ambience.animal_touches(coop_farm, Phases.DAY) == [Ambience.ANIMAL_CALLS[&"chicken"]]
			and Ambience.animal_touches(coop_farm, Phases.NIGHT) == [Ambience.MURMUR],
		"no call where no home has animals; a coop with a hen clucks by day and murmurs at night",
		"%s, %s, %s" % [str(empty_coop), str(Ambience.animal_touches(coop_farm, Phases.DAY)),
			str(Ambience.animal_touches(coop_farm, Phases.NIGHT))])

	var music := FileAccess.get_file_as_string("res://tools/gen_music.py")
	var sting_peak := _py_number(music, "STING_PEAK")
	var cues: Array = []
	for key in GameData.sorted_names(Ambience.STINGERS.keys()):
		var id: StringName = Ambience.STINGERS[key]
		var one := _wav_measure("res://assets/%s.wav" % id)
		var file := String(id).get_file()
		var listed := music.get_slice("NOT_LOOPS = [", 1).get_slice("]", 0).contains("\"%s\"" % file)
		if not String(id).begins_with("music/") or one.is_empty() \
				or float(one["peak"]) > sting_peak + 0.001 or not listed:
			cues.append("%s %s listed %s" % [id, str(one), listed])
	expect(cues.is_empty() and Ambience.stinger_for(&"fog", true) == Ambience.STINGERS[&"fog"]
			and Ambience.stinger_for(&"", true) == Ambience.STINGERS[&"full_moon"]
			and Ambience.stinger_for(&"", false) == &"",
		"each stinger is a cue in assets/music at most STING_PEAK on the not-loop list; the weather's beats the Full Moon's, and a plain night has none",
		str(cues))
	_completed += 1

## 0287 - the collections and the achievements. A harvest ticks its crop's
## page and the same crop bought does not; a boss killed hangs its trophy; a
## run that lost a night never earns the year, one whose boss only walked
## off still can, and one that lost none and beat Winter 14 does; folding
## twice adds nothing; a profile from before reads with the new keys; the
## achievements' table is checked; and A056 is registered on 0120's road.
## On crafted states: a 56-night run would not fit the 120 s.
func _task_0287_collections() -> void:
	var blank := Save.default_profile()
	var none := Collections.counts(blank, {})
	expect(str(none) == str({"fish": [0, Collections.fish_ids().size()],
			"crops": [0, Collections.crop_ids().size()],
			"trophies": [0, Collections.boss_ids().size()], "year": 0,
			"achievements": [0, GameData.ACHIEVEMENTS.size()]})
		and Collections.fish_ids().size() == 16 and Collections.crop_ids().size() == 12
		and Collections.boss_ids() == [&"giant", &"harvester", &"scarecrow_king", &"winter_lord"],
		"a new profile has every page and nothing on them: 16 fish, 12 crops, 4 bosses, 12 badges",
		str(none))

	# **A harvest, not the haul.**
	var field := State.create(2870)
	var plot: Vector2i = Farming.field_cells(field)[0]
	(field["plots"] as Dictionary)[Grid.index(plot)] = Farming.EMPTY_PLOT.duplicate()
	var here: Dictionary = Farming.plot(field, plot)
	here["crop"] = GameData.WHEAT
	here["growth"] = Farming.days_to_grow(GameData.WHEAT)
	expect(Farming.verb_at(field, plot) == &"harvest", "fixture: a ripe wheat plot")
	Farming.act(field, plot)
	expect(int(Collections.crops(blank, field).get(GameData.WHEAT, 0)) == 1
			and Collections.counts(blank, field)["crops"][0] == 1,
		"a harvested crop ticks its page", str(Collections.crops(blank, field)))
	Resources.add(field, GameData.WHEAT, 5)
	Resources.add(field, GameData.CARROT, 5)
	expect(int(Collections.crops(blank, field).get(GameData.WHEAT, 0)) == 1
			and not Collections.crops(blank, field).has(GameData.CARROT),
		"and the same crop or another brought in by Resources.add does not",
		str(Collections.crops(blank, field)))
	var once := Stats.fold(blank, field)
	var twice := Stats.fold(once, field)
	expect(int((once["collections"]["crops"] as Dictionary).get(GameData.WHEAT, 0)) == 1
			and str(twice["collections"]) == str(once["collections"])
			and str(twice["achievements"]) == str(once["achievements"])
			and int(Collections.crops(twice, field).get(GameData.WHEAT, 0)) == 1,
		"folding twice adds nothing: one wheat banked, and read back as one",
		"%s / %s" % [str(once["collections"]), str(twice["collections"])])

	# **A boss killed hangs its trophy**; an ordinary kill does not.
	var hunt := State.create(2871)
	var giant := Enemies.spawn(hunt, &"giant", 0)
	var walker := Enemies.spawn(hunt, &"walker", 0)
	expect(giant != 0 and walker != 0, "fixture: a giant and a walker on the farm")
	Combat._kill(hunt, walker)
	expect(Collections.trophies(blank, hunt).is_empty(), "a walker killed is no trophy")
	Combat._kill(hunt, giant)
	expect(int(Collections.trophies(blank, hunt).get(&"giant", 0)) == 1
			and Collections.counts(blank, hunt)["trophies"][0] == 1,
		"a giant killed adds its trophy", str(Collections.trophies(blank, hunt)))
	var hung := Stats.fold(blank, hunt)
	expect(int(Collections.trophies(hung, hunt).get(&"giant", 0)) == 1
			and int(Collections.trophies(hung, {}).get(&"giant", 0)) == 1,
		"and it is in the profile once folded, run or no run")

	# **The year**: Winter 14's boss down and no night the house fell.
	var lost := State.create(2872)
	NightRoad.to_night(lost)
	Phases.enter_result(lost, false)
	_past_the_year(lost)
	expect(int(lost["stats"]["nights_lost"]) == 1 and Run.beat_the_year(lost)
			and not Collections.year_earned(lost)
			and int(Stats.fold(blank, lost)["collections"]["years"]) == 0,
		"a run that lost a night never earns the year, Winter 14 beaten or not",
		str(lost["stats"]))
	var fled := State.create(2873)
	NightRoad.to_night(fled)
	Phases.enter_result(fled, false, true)
	_past_the_year(fled)
	expect(int(fled["stats"]["nights_lost"]) == 0 and Collections.year_earned(fled),
		"a boss that only walked off at dawn is not a lost house: that run can still earn it",
		str(fled["stats"]))
	var clean := State.create(2874)
	expect(not Collections.year_earned(clean), "a run short of Winter 14 has not earned it")
	clean["nights_won"] = 1
	_past_the_year(clean)
	var won := Stats.fold(blank, clean)
	var won_again := Stats.fold(won, clean)
	expect(Collections.year_earned(clean) and int(won["collections"]["years"]) == 1
			and int(won_again["collections"]["years"]) == 1
			and Collections.years(won_again, clean) == 1 and Collections.years(won_again, {}) == 1,
		"one that lost none and beat Winter 14 earns it, once however often it folds",
		str(won_again["collections"]))

	# **The achievements**: banked at the fold, never taken away.
	var badges: Dictionary = won["achievements"]
	expect(badges.has(&"first_night") and badges.has(&"year_two")
			and not badges.has(&"hundred_nights") and not badges.has(&"legend"),
		"a night survived and Year 2 reached earn their badges, and nothing else",
		str(badges.keys()))
	var later := Stats.fold(won, State.create(2875))
	expect((later["achievements"] as Dictionary).has(&"year_two"),
		"and a badge stays when the next run has not earned it")
	var moonlit := State.create(2876)
	var moon_day := 0
	for day in range(1, GameData.SEASON_DAYS + 1):
		if Calendar.is_full_moon(day):
			moon_day = day
			break
	moonlit["last_result"] = {"night": moon_day, "survived": true, "escaped": false, "ticks": 1}
	var moon: Dictionary = GameData.ACHIEVEMENTS[&"full_moon"]
	expect(moon_day > 0 and Collections.passes(blank, moonlit, moon),
		"a Full Moon held passes its test", str(moon_day))
	moonlit["last_result"]["survived"] = false
	expect(not Collections.passes(blank, moonlit, moon), "and a Full Moon lost does not")
	expect(GameData.check_achievements(GameData.ACHIEVEMENTS).is_empty()
			and GameData.ACHIEVEMENTS.size() == 12,
		"the table names a dozen, each a test and a number that exist",
		str(GameData.check_achievements(GameData.ACHIEVEMENTS)))
	var unknown := {&"x": {"name": &"ACH_X", "desc": &"ACH_X_DESC", "kind": &"teleported"}}
	var unread := {&"x": {"name": &"ACH_X", "desc": &"ACH_X_DESC", "kind": &"lifetime",
		"field": "dances", "n": 3}}
	var unset := {&"x": {"name": &"ACH_X", "desc": &"ACH_X_DESC", "kind": &"run",
		"field": "nights", "n": 0}}
	expect(GameData.check_achievements(unknown).size() == 1
			and GameData.check_achievements(unread).size() == 1
			and GameData.check_achievements(unset).size() == 1,
		"and validate refuses one naming an unknown test, an unknown number or no threshold")

	# **A profile from before reads with the new keys**, no format bump.
	var old := Save.default_profile()
	old.erase("collections")
	old.erase("achievements")
	old["runs_started"] = 4
	var path := "user://task_0287_profile.sav"
	expect(Save.write_profile_at(path, old), "fixture: an old profile written")
	var read := Save.read_profile_at(path)
	expect(str(read.get("collections")) == str({"crops": {}, "years": 0})
			and (read.get("achievements", null) as Dictionary).is_empty()
			and int(read["runs_started"]) == 4,
		"a profile without the new keys reads with their defaults and keeps its own",
		str(read.get("collections")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# **A056 on 0120's road**: every piece registered in its box until 0288.
	var unregistered: Array = []
	for boss in Collections.boss_ids():
		var name := StringName("trophy_%s" % boss)
		if PlaceholderArt.art(name).get("geometry") != PlaceholderArt.TROPHY \
				or UiKit.picture(name) == null:
			unregistered.append(name)
	for id in GameData.ACHIEVEMENTS:
		if not PlaceholderArt.is_drawn("res://sprites/ui/badge_%s.png" % id) \
				or not CollectionArt.EMBLEMS.has(id):
			unregistered.append(id)
	for tab in [&"crops", &"bosses", &"year", &"achievements"]:
		for cut in ["icon_book_%s", "hud_book_%s"]:
			if UiKit.picture(StringName(cut % tab)) == null:
				unregistered.append(cut % tab)
	for piece in [&"collection_cover", &"collection_ornament"]:
		if not PlaceholderArt.is_drawn("res://sprites/ui/%s.png" % piece):
			unregistered.append(piece)
	var emblems: Dictionary = {}
	for id in CollectionArt.EMBLEMS:
		emblems[CollectionArt.EMBLEMS[id]] = true
	expect(unregistered.is_empty() and emblems.size() == GameData.ACHIEVEMENTS.size()
			and PlaceholderArt.frame("res://sprites/ui/collection_cover.png").get("canvas") == Vector2i(48, 64),
		"A056's cover, ornament, eight tab cuts, four trophies and twelve badges stand in, each badge its own emblem",
		str(unregistered))
	_completed += 1


## Move a state's calendar past Winter 14, however many days its boss nights
## held it.
func _past_the_year(state: Dictionary) -> void:
	state["day"] = Run.final_night() + 1 + int(state.get("days_held", 0))


## 0293 - the first week, taught. No step is offered before its day; a
## scripted player who does only what `Tutorial.current_here()` and
## `points_at()` ask gets from Spring 1 at 06:00 to Spring 2's morning with
## the house standing and every day-one step done (to bed early and the night
## held to a near dawn, as 0141's script does, so the group stays quick); and
## a 0.1 `settings.cfg` loads with its own values kept, the rest at their
## defaults, and its `tutorial_seen` of `true` turned into the 0.1 steps - so
## only the new ones are offered.
func _task_0293_first_week() -> void:
	var errors := GameData.check_tutorial(Tutorial.steps())
	expect(errors.is_empty(), "the week passes its own check, per day and in all", str(errors))
	var crowded: Array = []
	for i in GameData.MAX_TUTORIAL_LINES_PER_DAY + 1:
		crowded.append({"id": StringName("x%d" % i), "line": &"TUT_CHOP", "from_day": 2})
	var unscheduled: Array = [{"id": &"x", "line": &"TUT_CHOP", "from_day": 0}]
	var nowhen: Array = [{"id": &"x", "line": &"TUT_CHOP", "from_day": 1, "when": &"noon"}]
	expect(not GameData.check_tutorial(crowded).is_empty()
			and not GameData.check_tutorial(unscheduled).is_empty()
			and not GameData.check_tutorial(nowhen).is_empty(),
		"and refuses a crowded day, a step with no Spring date and one taught at no part of a day")

	# **Nothing before its day**: each step, with every other one done, is
	# offered on its own date and in its own part of it, and not the day
	# before.
	var early: Array = []
	var on_time: Array = []
	for entry in Tutorial.steps():
		var one: Dictionary = entry
		for day in [int(one["from_day"]) - 1, int(one["from_day"])]:
			if day < 1:
				continue
			var probe := _week_probe(one, day, [])
			var offered: bool = Tutorial.current_here(probe).get("id", &"") == StringName(one["id"])
			if day < int(one["from_day"]) and (offered
					or Tutorial.current(probe).get("id", &"") == StringName(one["id"])):
				early.append(one["id"])
			if day == int(one["from_day"]) and offered:
				on_time.append(one["id"])
	expect(early.is_empty() and on_time.size() == Tutorial.steps().size(),
		"every step is offered on its own day and part of the day, and none the day before",
		"early %s, on time %d" % [str(early), on_time.size()])

	# **A player who does only what the lines ask.**
	var state := State.create(2931)
	var asked: Array = []
	var too_soon: Array = []
	for _turn in 80:
		if int(state["day"]) >= 2 and int(state["phase"]) == Phases.DAY:
			break
		var step := Tutorial.current_here(state)
		var id := StringName(step.get("id", &""))
		if id != &"":
			if int(step["from_day"]) > Calendar.date(state):
				too_soon.append(id)
			if not asked.has(id):
				asked.append(id)
		var at := Tutorial.points_at(state)
		match id:
			&"chop":
				Interact.complete(state, at, &"chop")
			&"plant":
				Farming.act(state, at)
				Farming.act(state, at)
			&"water":
				state["water_can"] = 2
			&"bed":
				(state["intent"] as Dictionary)["sleep"] = true
			&"cursor":
				var placed := false
				for radius in 4:
					for cell in Grid.within(at, radius):
						if not placed and Building.place(state, &"barricade", cell):
							placed = true
			&"start":
				NightRoad.press_start(state)
			&"dawn":
				NightRoad.park(state)
				(state["wave"] as Dictionary)["dawn_at"] = int(state["night_tick"]) + 3
		if int(state["phase"]) == Phases.RESULT:
			(state["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(state, GameData.TUTORIAL_CHECK_TICKS + 1)
	# He wakes in his bed, and the rules watch nothing in the house: out of
	# the door, as 0141's script goes.
	House.leave(state)
	Sim.advance(state, GameData.TUTORIAL_CHECK_TICKS + 1)
	var day_one: Array = [&"chop", &"plant", &"water", &"bed", &"cursor", &"start", &"dawn"]
	var all_done := true
	for id in day_one:
		all_done = all_done and Tutorial.is_done(state, id)
	expect(asked == day_one and too_soon.is_empty(),
		"the lines asked for day one's seven, in order, and nothing before its day",
		"%s, too soon %s" % [str(asked), str(too_soon)])
	expect(Calendar.date(state) == 2 and int(state["phase"]) == Phases.DAY
			and int(state["house_hp"]) > 0 and all_done,
		"and doing only that reaches Spring 2's morning, the house standing and day one taught",
		"day %d %s, house %d, done %s" % [Calendar.date(state), Phases.name_of(int(state["phase"])),
			int(state["house_hp"]), str((state["tutorial"] as Dictionary)["done"])])
	expect(Tutorial.current(state).get("id", &"") == &"sell",
		"where the next line is Spring 2's, the stall's", str(Tutorial.current(state)))

	# **The 0.1 settings, read today** (`tools/goldens/settings-v1.cfg`).
	var fresh: Node = (load("res://src/app/settings.gd") as GDScript).new()
	fresh.load_from_disk("res://tools/goldens/settings-v1.cfg")
	var mine: Dictionary = {&"gameplay/language": "pt_BR", &"audio/master": 0.6,
		&"audio/music": 0.35, &"audio/sfx": 0.9}
	var kept := true
	for key in mine:
		kept = kept and str(fresh.get_value(key)) == str(mine[key])
	kept = kept and str((fresh.get_value(&"controls/bindings") as Dictionary).get("interact", "")) == "key:74"
	expect(kept, "a 0.1 settings.cfg keeps its language, its volumes and its rebind",
		"%s %s" % [fresh.get_value(&"gameplay/language"), str(fresh.get_value(&"controls/bindings"))])
	var defaults: Dictionary = (load("res://src/app/settings.gd") as GDScript).get_script_constant_map()["DEFAULTS"]
	var off: Array = []
	for key in GameData.sorted_names(defaults.keys()):
		if mine.has(StringName(key)) or [&"controls/bindings", &"gameplay/tutorial_seen"].has(StringName(key)):
			continue
		if str(fresh.get_value(StringName(key))) != str(defaults[key]):
			off.append(key)
	expect(off.is_empty(), "and every key it lacks is at its default", str(off))
	var seen: Array = fresh.get_value(&"gameplay/tutorial_seen")
	var v1: Array = []
	for id in GameData.TUTORIAL_V1:
		v1.append(String(id))
	expect(seen == v1, "and its tutorial_seen of true is the 0.1 day one's steps", str(seen))
	fresh.free()
	var offered: Array = []
	for entry in Tutorial.steps():
		var one: Dictionary = entry
		var probe := _week_probe(one, int(one["from_day"]), [])
		if Tutorial.current_here(probe, seen).get("id", &"") == StringName(one["id"]):
			offered.append(one["id"])
	expect(offered == [&"bed", &"cursor", &"start", &"dawn", &"forecast", &"fish",
			&"season", &"full_moon"],
		"so only the steps 0.1 never had are offered - the bed, the cursor and the rest of the week",
		str(offered))
	_completed += 1


## A farm on `day`, in `one`'s part of the day, with every other step done
## (and `done` besides).
func _week_probe(one: Dictionary, day: int, done: Array) -> Dictionary:
	var probe := State.create(2930)
	probe["day"] = day
	probe["nights_won"] = day - 1
	probe["phase"] = Tutorial.phase_of(one)
	if Tutorial.when_of(one) == &"dusk":
		probe["day_tick"] = Phases.tick_at_minute(GameData.DUSK_MINUTE)
	for entry in Tutorial.steps():
		var id := StringName((entry as Dictionary)["id"])
		if id != StringName(one["id"]):
			((probe["tutorial"] as Dictionary)["done"] as Array).append(id)
	for id in done:
		((probe["tutorial"] as Dictionary)["done"] as Array).append(id)
	return probe

## 0292 - the options for the new controls. Five keys with their defaults
## (0131's rate, 0130's band on, 0121's 0.2, both game switches off), each on
## its page's reset list with its default among its steps; nothing in
## src/core/ names `Settings`; and the forecast read at 08:00 is the one read
## at 18:00, so seeing it at breakfast changes nothing.
func _task_0292_options() -> void:
	var defaults: Dictionary = (load("res://src/app/settings.gd") as GDScript).get_script_constant_map()["DEFAULTS"]
	expect(defaults.get(&"controls/cursor_speed") == 100
			and defaults.get(&"controls/edge_pan") == true
			and is_equal_approx(float(defaults.get(&"controls/pad_deadzone", -1.0)), 0.2)
			and defaults.get(&"gameplay/fishing_assist") == false
			and defaults.get(&"gameplay/forecast_all_day") == false,
		"five keys: cursor speed 100, edge pan on, deadzone 0.2, the assist and the all-day forecast off")
	var controls := OptionsControls.new()
	var game := OptionsGame.new()
	expect(controls.resets.has(&"controls/cursor_speed") and controls.resets.has(&"controls/edge_pan")
			and controls.resets.has(&"controls/pad_deadzone")
			and game.resets.has(&"gameplay/fishing_assist")
			and game.resets.has(&"gameplay/forecast_all_day"),
		"each on its page's reset list", "%s / %s" % [str(controls.resets), str(game.resets)])
	controls.free()
	game.free()
	expect(OptionsControls.CURSOR_SPEEDS == [50, 75, 100, 150, 200]
			and OptionsControls.DEADZONES.size() == 9
			and is_equal_approx(float(OptionsControls.DEADZONES[0]), 0.1)
			and is_equal_approx(float(OptionsControls.DEADZONES[8]), 0.5)
			and OptionsControls.DEADZONES.has(0.2),
		"the steps sit with their rows: 50-200 percent, and 0.10-0.50 in 0.05s with the shipped 0.2")
	var shipped := true
	for action in ActionsScript.STICK_ACTIONS:
		var entry: Variant = ProjectSettings.get_setting("input/%s" % action)
		if not InputMap.has_action(action) or not (entry is Dictionary) \
				or not is_equal_approx(float((entry as Dictionary).get("deadzone", -1.0)),
					ActionsScript.SHIPPED_DEADZONE):
			shipped = false
	expect(shipped and ActionsScript.STICK_ACTIONS.size() == 8,
		"the deadzone is set on the four move and four pan actions, all shipped at 0.2")

	# **No rule reads a preference.**
	var naming: Array = []
	var named := RegEx.create_from_string("\\bSettings\\b")
	for file in DirAccess.get_files_at("res://src/core"):
		if not String(file).ends_with(".gd"):
			continue
		if named.search(SuiteKit.code_lines_of("res://src/core".path_join(file))) != null:
			naming.append(file)
	expect(naming.is_empty(), "no file in src/core/ names Settings", str(naming))

	# **The forecast is the seed's and the date's**, at any hour.
	var state := State.create(2920)
	state["day"] = 9
	state["nights_won"] = 8
	state["day_tick"] = Phases.tick_at_minute(8 * 60)
	var breakfast := Forecast.tonight(state)
	state["day_tick"] = Phases.tick_at_minute(18 * 60)
	var dusk := Forecast.tonight(state)
	expect(not breakfast.is_empty() and str(breakfast) == str(dusk),
		"Forecast.tonight gives the same record at 08:00 as at 18:00", str(breakfast))
	_completed += 1


## A WAV's join against its own 99th-percentile step, the way
## `_task_0086_music` measures a seam: `{ratio, seconds}`.
func _seam_of(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_bytes(path)
	var at := 12
	while at + 8 <= raw.size():
		var tag := raw.slice(at, at + 4).get_string_from_ascii()
		var size := raw.decode_u32(at + 4)
		if tag == "data":
			var start := at + 8
			var count := mini(size, raw.size() - start) / 2
			if count < 3:
				return {}
			var steps: Array = []
			var previous := raw.decode_s16(start)
			for i in range(1, count, 97):
				var v := raw.decode_s16(start + i * 2)
				steps.append(absi(v - previous))
				previous = v
			steps.sort()
			var p99 := float(steps[mini(int(steps.size() * 0.99), steps.size() - 1)])
			var join := absf(float(raw.decode_s16(start)) - float(raw.decode_s16(start + (count - 1) * 2)))
			return {"ratio": join / maxf(p99, 1.0), "seconds": float(count) / 22050.0}
		at += 8 + size + (size & 1)
	return {}


## Length and peak of a 16-bit mono WAV at 22,050 Hz, read off its bytes -
## the importer's QOA is lossy, and the question is what `gen_sfx.py` wrote.
func _wav_measure(path: String) -> Dictionary:
	var raw := FileAccess.get_file_as_bytes(path)
	var at := 12
	while at + 8 <= raw.size():
		var tag := raw.slice(at, at + 4).get_string_from_ascii()
		var size := raw.decode_u32(at + 4)
		if tag == "data":
			var count := mini(size, raw.size() - at - 8) / 2
			var peak := 0.0
			for i in count:
				peak = maxf(peak, absf(float(raw.decode_s16(at + 8 + i * 2)) / 32768.0))
			return {"seconds": float(count) / 22050.0, "peak": peak}
		at += 8 + size + (size & 1)
	return {}


## A top-level `NAME = number` out of a Python file.
func _py_number(text: String, name: String) -> float:
	for line in text.split("\n"):
		if line.begins_with(name + " = "):
			return float(line.get_slice("=", 1).strip_edges())
	return -1.0


## **A mid-summer farm** (task 0276): Summer 6 of a run, every night before it
## won and the lessons behind it, a coop on its site with four hens whose eggs
## wait at the door, and a purse - money, wood, iron and stone - for the
## build step's first tower.
func _mid_summer_farm() -> Dictionary:
	var state := State.create(27600)
	state["day"] = GameData.SEASON_DAYS + 6
	state["nights_won"] = GameData.SEASON_DAYS + 5
	var lessons: Array = []
	for step in Tutorial.steps():
		lessons.append(StringName((step as Dictionary)["id"]))
	((state["tutorial"] as Dictionary)["done"] as Array).assign(lessons)
	Resources.gain(state, {GameData.MONEY: 400, GameData.WOOD: 200, GameData.IRON: 100,
		GameData.STONE: 200})
	var room: Array = GameData.MAP_SITES[&"barn"]
	var site := Vector2i(int(room[0]), int(room[1]))
	var coop := Vector2i(-1, -1)
	for y in range(site.y, site.y + 6):
		for x in range(site.x, site.x + 14):
			if coop.x < 0 and Building.can_place(state, &"coop", Vector2i(x, y)):
				coop = Vector2i(x, y)
	if coop.x >= 0 and Building.place(state, &"coop", coop):
		for _i in 4:
			Livestock.house(state, coop, &"chicken", 1)
	return state


## How many bodies `one` sends from `side`.
func _bodies_from(one: Dictionary, side: int) -> int:
	var out := 0
	for row in (one.get("waves", []) as Array):
		if int((row as Array)[2]) == side:
			out += int((row as Array)[1])
	return out


## **A season's nights against what it has met** (tasks 0272-0274), for
## seeds 0-4, from `first_day` - the season's calm night - to its last:
## `strays`, the rows that send a kind not met by their day, or from a side
## not in `sides`; `firsts`, each kind of `intro` not first sent on its day
## of the year; `bland`, each whose next night sends no more of it (0060's
## rule); and `unfilled`, every fighting night not still sending at the fill
## line or not all sent before the dawn margin. `known` are the kinds met
## before the season.
func _season_rows(first_day: int, known: Array, intro: Dictionary, sides: Array) -> Dictionary:
	var last_day := first_day + GameData.SEASON_DAYS - 1
	var out := {"strays": [], "firsts": [], "bland": [], "unfilled": []}
	for seed_value in range(5):
		var first := {}
		for day in range(1, last_day + 1):
			var one := Waves.night_of(day, seed_value)
			for row in (one["waves"] as Array):
				var kind := StringName((row as Array)[0])
				if not first.has(kind):
					first[kind] = day
				if day < first_day:
					continue
				var met := known.has(kind) or day >= int(intro.get(kind, last_day + 1))
				if not met or not sides.has(int((row as Array)[2])):
					(out["strays"] as Array).append([seed_value, day, row])
			var sent := Waves.schedule_ticks(one)
			if day > first_day and (sent < Waves.fill_line()
					or sent + GameData.DAWN_MARGIN_TICKS > GameData.NIGHT_TICKS):
				(out["unfilled"] as Array).append([seed_value, day, sent])
		for kind in GameData.sorted_names(intro.keys()):
			var day := int(intro[kind])
			if int(first.get(kind, -1)) != day:
				(out["firsts"] as Array).append([seed_value, kind, first.get(kind, -1)])
			if day < last_day and int(Waves.kinds_of(day + 1, seed_value).get(kind, 0)) \
					<= int(Waves.kinds_of(day, seed_value).get(kind, 0)):
				(out["bland"] as Array).append([seed_value, kind])
	return out


## **A new side is learned before it is tested** (tasks 0272-0274): the
## seeds of 0-4 for which `side` sends something on the season's first
## fight, the day after `first_day`, or on the next sends nothing or a tenth
## of the night or more, or on the day after that no more - each with what
## the three days sent from it.
func _side_learned(first_day: int, side: int) -> Array:
	var out: Array = []
	for seed_value in range(5):
		var sent: Array = []
		for day in range(first_day + 1, first_day + 4):
			sent.append(_bodies_from(Waves.night_of(day, seed_value), side))
		if int(sent[0]) != 0 or int(sent[1]) <= 0 \
				or int(sent[1]) * 10 > Waves.size_of(first_day + 2, seed_value) \
				or int(sent[2]) <= int(sent[1]):
			out.append([seed_value, sent])
	return out


## **A first look is a clear one** (tasks 0272-0274): the `[seed, day,
## event]` of every day of `days` with weather, for seeds 0-4.
func _cloudy(days: Array) -> Array:
	var out: Array = []
	for seed_value in range(5):
		for day in days:
			if Weather.event(seed_value, int(day)) != Weather.NONE:
				out.append([seed_value, day, Weather.event(seed_value, int(day))])
	return out


## Every night's hit points as fought on seed 0, day 1 to `last_day`.
func _hit_points_to(last_day: int) -> Dictionary:
	var hp := {}
	for day in range(1, last_day + 1):
		hp[day] = Waves.hit_points_in(Waves.night_of(day, 0))
	return hp


## **The plan's rhythm in hit points** (tasks 0271-0274) for the season
## whose calm night is `first_day`: its first fight to its Full Moon growing,
## the moon the largest of its half and under the season's last night, the
## day after the moon over the day before it, the days after it growing to
## the last, and the last the largest of the season.
func _season_shape(first_day: int, hp: Dictionary) -> bool:
	var moon := first_day + 6
	var last_day := first_day + GameData.SEASON_DAYS - 1
	var shaped := int(hp[moon]) < int(hp[last_day]) and int(hp[moon + 1]) > int(hp[moon - 1])
	for day in range(first_day, moon):
		shaped = shaped and int(hp[day]) < int(hp[moon])
	for day in range(moon + 1, last_day):
		shaped = shaped and int(hp[day]) < int(hp[last_day])
	for day in range(first_day + 2, moon) + range(moon + 2, last_day):
		shaped = shaped and int(hp[day]) > int(hp[day - 1])
	return shaped


## The `[seed, day]` of every night of the year that sends `boss`, for seeds
## 0 and 424242.
func _boss_days(boss: StringName) -> Array:
	var out: Array = []
	for seed_value in [0, 424242]:
		for day in range(1, Calendar.year_days() + 1):
			if Waves.kinds_of(day, seed_value).has(boss):
				out.append([seed_value, day])
	return out

## `GameData.NIGHT_EVENTS` with one value set at `path` - an event, then the
## keys under it, made where missing - for a check to refuse (task 0256).
func _night_events_with(path: Array, value: Variant) -> Dictionary:
	var table := GameData.NIGHT_EVENTS.duplicate(true)
	var at: Dictionary = table
	for key in path.slice(0, path.size() - 1):
		if not at.has(key):
			at[key] = {}
		at = at[key]
	at[path.back()] = value
	return table


## The first `(seed, date)` from seed 25600 whose night `Weather` makes
## `kind` - found, never forced - and not a Full Moon, so the night sends
## nothing a test did not put there (task 0256).
func _weather_date(kind: StringName) -> Array:
	for seed_value in range(25600, 25800):
		for date in range(2, Calendar.year_days() + 1):
			if Weather.event(seed_value, date) == kind and not Calendar.is_full_moon(date):
				return [seed_value, date]
	return [-1, -1]


## A night of `date`'s season with no weather in the same run - not the first
## of the game, a calm night or a Full Moon: the clear twin a weather test
## compares with (task 0256).
func _clear_date(seed_value: int, date: int) -> int:
	var first := date - Calendar.day_of_season(date) + 1
	for day in range(first, first + GameData.SEASON_DAYS):
		if (day > 1 and not Calendar.is_calm(day) and not Calendar.is_full_moon(day)
				and Weather.event(seed_value, day) == Weather.NONE):
			return day
	return 1


## A parked night with nobody in it on `date` of a run started on
## `seed_value`, every night before it won (task 0256).
func _parked_on(seed_value: int, date: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = date
	state["nights_won"] = date - 1
	expect(NightRoad.to_night(state), "into the night of day %d" % date)
	NightRoad.park(state)
	Enemies.withdraw(state)
	return state


## A crop on `cell` (task 0249): tilled, sown with `crop`, nothing grown yet.
func _sow(state: Dictionary, cell: Vector2i, crop: StringName) -> void:
	var plot := Farming.EMPTY_PLOT.duplicate()
	plot["crop"] = crop
	(state["plots"] as Dictionary)[Grid.index(cell)] = plot


## **Three clusters of rats down one lane past `id`** (task 0248): a parked
## night, the east spawn's road home, the clusters `SPAWN_INTERVAL_TICKS`
## apart from four cells along it and `id` six on - a mine on the road, a
## tower on the first open cell beside it - with rounds for anything that
## burns them. What it killed before the last rat was dead or home, its
## money and its price, and the shots fired.
func _rat_lane(seed_value: int, id: StringName) -> Dictionary:
	var state := _powers_night(seed_value)
	state["house_hp"] = 100000
	var needs := Ammo.needed_by(id)
	for res in GameData.sorted_names(needs.keys()):
		Resources.gain(state, {res: 100})
	var at: Vector2i = Enemies.spawn_cells(state, 0)[0]
	var road: Array = [at]
	for _i in Grid.CELLS:
		var next := Pathing.step_from(state, at)
		if next == at:
			break
		road.append(next)
		at = next
	var start: Vector2i = road[4]
	var post: Vector2i = road[10]
	if id != &"mine":
		var side := Vector2i(-1, -1)
		for step in Enemies.NEIGHBOURS:
			var cell: Vector2i = (road[10] as Vector2i) + step
			if side.x < 0 and not road.has(cell) and Farm.buildable(state, cell):
				side = cell
		post = side
	Farm.place(state, post, {"id": id, "hp": int((GameData.DEFENCES[id] as Dictionary)["hp"])})
	Pathing.refresh(state)
	var cluster := int((GameData.ENEMIES[&"rat"] as Dictionary)["cluster"])
	var sent: Array = []
	for t in 900:
		if t % (GameData.SPAWN_INTERVAL_TICKS + 1) == 0 and sent.size() < 3 * cluster:
			sent.append_array(Enemies.cluster_at(state, &"rat", start, cluster))
		Sim.advance(state, 1)
		if sent.size() >= 3 * cluster and Entities.count(state) == 0:
			break
	return {"kills": int((state["killed_by_kind"] as Dictionary).get(&"rat", 0)),
		"price": Building.price_of(id), "money": Building.money_of(id), "post": post,
		"shots": Towers.shots_fired(state)}


## How many ticks into its gap the recovery pose has given way (task 0247):
## past the release and into the recovery.
const SPIT_SETTLE := 4


## **A spitter against one tower** (task 0247): a parked night, `tower` on
## open ground and a spitter `spit_range` east of it - at `hp` when that is
## not 0 - ticked until one of them is gone. The landings on the tower as
## `[tick, damage]`, whether the spitter moved while the tower stood, who is
## left and at what, the ticks it took and the `structure_lost`s.
func _spit_duel(seed_value: int, tower: StringName, hp: int) -> Dictionary:
	var state := _powers_night(seed_value)
	var at := _spit_ground(state)
	var full := int((GameData.DEFENCES[tower] as Dictionary)["hp"])
	Farm.place(state, at, {"id": tower, "hp": full})
	var reach := int((GameData.ENEMIES[&"spitter"] as Dictionary)["spit_range"])
	var id := Entities.spawn(state, &"spitter", at + Vector2i(reach, 0))
	if hp > 0:
		Entities.set_hp(state, id, hp)
	var start: Array = (Entities.get_one(state, id)["pos"] as Array).duplicate()
	var from := int(state["tick"])
	var last := full
	var drops: Array = []
	var moved := false
	var ticks := 0
	for t in 3000:
		Sim.advance(state, 1)
		ticks = t + 1
		var on := Farm.occupant(state, at)
		var now := int(on.get("hp", 0)) if StringName(on.get("id", &"")) == tower else 0
		if now < last:
			drops.append([int(state["tick"]), last - now])
			last = now
		# While the tower stands: the tick it falls, the spitter walks on.
		if Entities.alive(state, id) and now > 0:
			moved = moved or str(Entities.get_one(state, id)["pos"]) != str(start)
		if not Entities.alive(state, id) or now <= 0:
			break
	var lost := 0
	for event in Events.since(state, from):
		if StringName((event as Dictionary)["kind"]) == &"structure_lost":
			lost += 1
	return {"state": state, "cell": at, "drops": drops, "moved": moved, "ticks": ticks,
		"alive": Entities.alive(state, id), "spitter_hp": int(Entities.get_one(state, id).get("hp", 0)),
		"tower_hp": last, "lost": lost}


## Open ground for a tower with the six cells east of it open too - room for
## a spitter to stand at its range (task 0247).
func _spit_ground(state: Dictionary) -> Vector2i:
	var house := Farm.house_centre(state)
	for ring in range(6, 30):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var cell := house + Vector2i(dx, dy)
				var open := Farm.buildable(state, cell)
				for x in range(1, 7):
					open = open and Farm.walkable(state, cell + Vector2i(x, 0)) and Farm.buildable(state, cell + Vector2i(x, 0))
				if open:
					return cell
	return Vector2i(-1, -1)


## A parked night with nobody on the farm (task 0232).
func _powers_night(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.STRAW: 200, GameData.WOOD: 200})
	NightRoad.to_night(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	return state


## A walker shut in a ring of stone walls at `level` on open ground in a
## parked night, ticked until one of them gives: how many bites that took, the
## ticks from the first bite to the last, and the ticks between two bites
## (task 0231).
func _ring_breaks(seed_value: int, level: int) -> Dictionary:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.STONE: 200, GameData.HARDWOOD: 40})
	(state["tech_owned"] as Array).append(&"stout timbers")
	NightRoad.into_build(state)
	var spot := _open_square(state, 4, &"wall")
	var ring: Array = []
	for step in Enemies.NEIGHBOURS:
		var at: Vector2i = spot + step
		expect(Building.place(state, &"wall", at) and (level < 2 or Building.upgrade(state, at)),
			"a level %d wall goes up round the walker's cell" % level, str(at))
		ring.append(at)
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	Entities.spawn(state, &"walker", spot)
	var hp := {}
	for at in ring:
		hp[at] = int(Farm.occupant(state, at)["hp"])
	var bites: Array = []
	for tick in 2000:
		Enemies.tick(state)
		var broke := false
		for at in ring:
			var now := int(Farm.occupant(state, at).get("hp", 0))
			if now < int(hp[at]):
				bites.append(tick)
				hp[at] = now
				broke = broke or now <= 0
		if broke:
			break
	return {"bites": bites.size(), "ticks": int(bites.back()) - int(bites[0]) if bites.size() > 1 else 0,
		"gap": int(bites[1]) - int(bites[0]) if bites.size() > 1 else 0}


## Whether anything in `rect` of `image` is opaque (task 0230).
func _any_opaque(image: Image, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y).a > 0.0:
				return true
	return false


## How many pixels of `image` are opaque (task 0230).
func _opaque_count(image: Image) -> int:
	var n := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				n += 1
	return n


## How many pixels are opaque in one of two same-sized images and not the
## other (task 0230).
func _alpha_apart(a: Image, b: Image) -> int:
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			if (a.get_pixel(x, y).a > 0.0) != (b.get_pixel(x, y).a > 0.0):
				n += 1
	return n


## Every cell within `radius` of `centre`, a square, into `cells` (task 0229).
func _lit_square(cells: Dictionary, centre: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var at := centre + Vector2i(dx, dy)
			if Grid.in_bounds(at):
				cells[Grid.index(at)] = true


func _sorted_cells(cells: Dictionary) -> Array:
	var keys: Array = cells.keys()
	keys.sort()
	var out: Array = []
	for idx in keys:
		out.append(Grid.cell(int(idx)))
	return out


## The first cell, ring by ring out from `from` at `at_least` tiles or more,
## that is buildable, has room eight tiles east, and is dark - with every cell
## within `clear` of it dark too (task 0229).
func _a_dark_cell(state: Dictionary, from: Vector2i, at_least: int, clear: int = 0) -> Vector2i:
	for ring in range(at_least, 60):
		for cell in Grid.within(from, ring):
			if Grid.chebyshev(from, cell) != ring or not Farm.buildable(state, cell) \
					or not Grid.in_bounds(cell + Vector2i(8, 0)):
				continue
			var dark := true
			for dy in range(-clear, clear + 1):
				for dx in range(-clear, clear + 1):
					var at: Vector2i = cell + Vector2i(dx, dy)
					dark = dark and Grid.in_bounds(at) and not Light.is_lit(state, at)
			if dark:
				return cell
	return Vector2i(-1, -1)


## A braid hung in the build step on bare ground - four cells of it every way,
## nothing on it - with garlic and wood to spare (task 0228).
func _garlic_build(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	SuiteKit.open_arsenal(state, [&"garlic_braid"])
	Resources.gain(state, {GameData.GARLIC: 40, GameData.WOOD: 40, GameData.MONEY: 500})
	NightRoad.into_build(state)
	var spot := _open_square(state, 4, &"garlic_braid")
	expect(Building.place(state, &"garlic_braid", spot), "a braid hung in the build step", str(spot))
	return {"state": state, "spot": spot}


## The road from `from` down the house's field, every cell of it, `from` first.
func _walked_from(state: Dictionary, from: Vector2i) -> Array:
	var road: Array = [from]
	var at := from
	for _i in Grid.CELLS:
		var next := Pathing.step_from(state, at)
		if next == at:
			break
		road.append(next)
		at = next
	return road


## A catapult put down in the build step on open ground, `pumpkins` in the
## store once it is paid for, then START into a parked night with nobody in
## it (task 0227).
func _catapult_night(seed_value: int, pumpkins: int) -> Dictionary:
	var state := State.create(seed_value)
	SuiteKit.open_arsenal(state, [&"catapult"])
	var price := int((GameData.DEFENCES[&"catapult"]["cost"] as Dictionary)[GameData.PUMPKIN])
	Resources.gain(state, {GameData.WOOD: 200, GameData.PUMPKIN: price + pumpkins, GameData.MONEY: 500})
	NightRoad.into_build(state)
	var spot := _open_square(state, 6, &"catapult")
	expect(Building.place(state, &"catapult", spot), "a catapult goes down in the build step", str(spot))
	NightRoad.through_build(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	return {"state": state, "spot": spot}


## Whether a body that was at `from` moved toward `aim` this tick, as `Enemies`
## moves one: along the bigger of the two gaps, a unit at a time (0225).
func _moved_toward(from: Vector2i, now: Vector2i, aim: Vector2i) -> bool:
	var gap := aim - from
	var moved := now - from
	if absi(gap.x) >= absi(gap.y):
		return gap.x != 0 and signi(moved.x) == signi(gap.x) and moved.y == 0
	return signi(moved.y) == signi(gap.y) and moved.x == 0


## A parked night with a clear square of ground round `spot` - six cells every
## way and nothing on it - and a decoy on each of `offsets` from it, put down
## at night (task 0224). Nobody else on the farm.
func _decoy_night(seed_value: int, offsets: Array = [Vector2i.ZERO]) -> Dictionary:
	var state := State.create(seed_value)
	SuiteKit.open_arsenal(state, [&"decoy"])
	Resources.gain(state, {GameData.STRAW: 200, GameData.WOOD: 200, GameData.MONEY: 500})
	NightRoad.to_night(state)
	NightRoad.park(state)
	Enemies.withdraw(state)
	var spot := _open_square(state, 6)
	for offset in offsets:
		expect(Building.place(state, &"decoy", spot + (offset as Vector2i)), "a decoy goes down at night",
			str(spot + (offset as Vector2i)))
	Pathing.refresh(state)
	return {"state": state, "spot": spot}


## The cell nearest the house, ring by ring and each ring in reading order,
## with `radius` cells of bare ground every way round it - grass or path, a
## step of one each - and ground for a decoy, or for `id` (task 0226's hive).
## **The ground, not the rules** (task 0234): what it costs and the season it
## opens in are the test's to ask, so a fixture finds the same ground in
## spring as in winter.
func _open_square(state: Dictionary, radius: int, id: StringName = &"decoy") -> Vector2i:
	# Every new game has the same farm, so the ground found once is asked
	# about first.
	if _decoy_ground.x >= 0 and _ground_for(state, id, _decoy_ground) \
			and _bare_round(state, _decoy_ground, radius):
		return _decoy_ground
	var house := Farm.house_centre(state)
	for ring in range(radius + 2, 60):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var cell := house + Vector2i(dx, dy)
				if _ground_for(state, id, cell) and _bare_round(state, cell, radius):
					_decoy_ground = cell
					return cell
	return Vector2i(-1, -1)


## Whether what `make` returns outlives the call that made it (task 0238): a
## texture drawn with `draw_texture` must be held by someone, or it is freed
## before the frame renders and draws as a white square.
func _held(make: Callable) -> bool:
	var weak: WeakRef = weakref(make.call())
	return weak.get_ref() != null


## A raster art file's own pixels (task 0241), as the image the view draws.
func _art_image(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


## Where a season's defences start in a hotbar order (task 0234).
func _first_of_season(order: Array, season: int) -> int:
	for i in order.size():
		if Building.season_of(StringName(order[i])) >= season:
			return i
	return order.size()


## Whether every cell `id` would cover is ground a thing may go on.
func _ground_for(state: Dictionary, id: StringName, cell: Vector2i) -> bool:
	for at in Building.footprint(id, cell):
		if not Farm.why_not_buildable(state, at).is_empty():
			return false
	return true


func _bare_round(state: Dictionary, centre: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var cell := centre + Vector2i(dx, dy)
			if not Grid.in_bounds(cell) or not Farm.occupant(state, cell).is_empty() \
					or Farm.cost_of_terrain(Farm.terrain_at(state, cell)) != 1:
				return false
	return true


## A bare cell out of a decoy's reach whose whole road home stays out of it
## (task 0224), the first in reading order a few tiles past the reach.
func _beyond_the_lure(state: Dictionary, spot: Vector2i, reach: int) -> Vector2i:
	Pathing.refresh(state)
	for dy in range(-reach - 6, reach + 7):
		for dx in range(-reach - 6, reach + 7):
			var cell := spot + Vector2i(dx, dy)
			var apart := absi(dx) + absi(dy)
			if apart < reach + 3 or not Grid.in_bounds(cell) or not Farm.occupant(state, cell).is_empty() \
					or not Pathing.reachable(state, cell):
				continue
			var clear := true
			var at := cell
			for _step in 40:
				clear = clear and Pathing.distance_lure(state, at) > Pathing.lure_reach()
				var next := Pathing.step_from(state, at)
				if next == at:
					break
				at = next
			if clear:
				return cell
	return Vector2i(-1, -1)


## A bare cell within a decoy's reach where the lure and the road home part
## ways - the first in reading order - so which one is walked shows (0224).
func _turned_by_the_lure(state: Dictionary, spot: Vector2i, reach: int) -> Vector2i:
	Pathing.refresh(state)
	Pathing.field(state, &"lure")
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var cell := spot + Vector2i(dx, dy)
			var away := Pathing.distance_lure(state, cell)
			if absi(dx) + absi(dy) < 2 or away > Pathing.lure_reach() or not Farm.occupant(state, cell).is_empty():
				continue
			if Pathing.step_lure(state, cell) != Pathing.step_from(state, cell):
				return cell
	return Vector2i(-1, -1)


## Which way one walked from the middle of `from` on the last tick: the unit
## step of its move, or zero.
func _step_of(state: Dictionary, id: int, from: Vector2i) -> Vector2i:
	var one := Entities.get_one(state, id)
	if one.is_empty():
		return Vector2i.ZERO
	var middle := from * Player.SUBTILE + Vector2i.ONE * (Player.SUBTILE / 2)
	var moved := Vector2i(int(one["pos"][0]), int(one["pos"][1])) - middle
	return Vector2i(signi(moved.x), signi(moved.y))


## 0147 - A005's night icons: the 24 cuts are raster art at their boxes and
## nothing stands in for them; the hotbar draws each defence's own 16x16 and
## the night bar its 10x10 pictures, START's, the flare's, the speed's and
## the setting moon's.
func _task_0147_night_icons() -> void:
	var ids: Array = A005_DEFENCES + NightHud.ICONS
	var wrong: Array = []
	for id in ids:
		for cut in [["icon", 16], ["hud", 10]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var side := int(cut[1])
			if frame.get("canvas") != Vector2i(side, side) \
					or frame.get("pivot") != Vector2i(side / 2, side / 2) \
					or bool(frame.get("loop", true)) or frame.has("stand_in") \
					or not PlaceholderArt.art(name).is_empty() or not ResourceLoader.exists(path):
				wrong.append(name)
	expect(ids.size() == 12 and wrong.is_empty(),
		"A005's 24 cuts are raster art at 16x16 (8,8) and 10x10 (5,5), and none has a stand-in",
		str(wrong))

	var bar := Hotbar.new()
	var bare: Array = []
	for id in A005_DEFENCES:
		var texture := bar._icon_of(id)
		if texture == null or texture.resource_path != "res://sprites/ui/icon_%s.png" % id \
				or texture.get_size() != Vector2(16, 16):
			bare.append(id)
	bar.free()
	expect(bare.is_empty(), "the hotbar draws each of A005's defences its own 16x16 icon", str(bare))

	var hud := NightHud.new()
	hud._ready()
	var worn := {
		"start": hud._start.icon, "flare": hud._flare.icon, "speed": hud._speed.icon,
		"dawn_moon": hud._dawn_moon.texture,
	}
	var undressed: Array = []
	for id in worn:
		var texture: Texture2D = worn[id]
		if texture == null or texture.resource_path != "res://sprites/ui/hud_%s.png" % id \
				or texture.get_size() != Vector2(10, 10):
			undressed.append(id)
	expect(undressed.is_empty() and hud._skip.icon == null,
		"START, the flare and the speed wear their 10x10 pictures and the countdown its setting moon; SKIP keeps its word alone",
		str(undressed))
	expect(hud._dawn_moon.position.x + hud._dawn_moon.size.x + NightHud.PICTURE_GAP
		<= hud._dawn.position.x and hud._speed.position.x >= NightHud.FLARE_SIZE.x
		and hud._speed.position.x + NightHud.SPEED_SIZE.x < hud._skip.position.x
		and hud._skip.position.x + NightHud.BUTTON_SIZE.x <= NightHud.BAR_SIZE.x,
		"the moon stands just left of the countdown, and the bar's three buttons still fit it side by side")
	hud.free()
	expect(UiKit.orphan_icons().is_empty(), "every icon in sprites/ui is claimed",
		str(UiKit.orphan_icons()))
	_completed += 1


## 0161 - A010's calendar marks: the 14 cuts are raster art at their boxes,
## nothing stands in for them, and a mark draws its pack file - seven marks
## told apart at both sizes.
func _task_0161_calendar_icons() -> void:
	var wrong: Array = []
	var drawn: Array = []
	var seen := {16: {}, 10: {}}
	for which in CalendarMark.MARKS:
		for small in [false, true]:
			var side := CalendarMark.HUD if small else CalendarMark.ICON
			var path := CalendarMark.file_of(which, small)
			var frame := PlaceholderArt.frame(path)
			if frame.get("canvas") != Vector2i(side, side) \
					or frame.get("pivot") != Vector2i(side / 2, side / 2) \
					or frame.has("stand_in") or PlaceholderArt.is_drawn(path) \
					or not PlaceholderArt.art(StringName(path.get_file().get_basename())).is_empty():
				wrong.append(path.get_file())
			var mark := CalendarMark.new()
			mark.setup(which, small)
			var texture := mark.texture()
			if texture == null or texture.resource_path != path \
					or texture.get_size() != Vector2(side, side) or mark.size != Vector2(side, side):
				drawn.append(path.get_file())
			elif seen[side].has(texture.get_image().get_data()):
				drawn.append("%s copies %s" % [path.get_file(), seen[side][texture.get_image().get_data()]])
			else:
				seen[side][texture.get_image().get_data()] = path.get_file()
			mark.free()
	expect(CalendarMark.MARKS.size() == 7 and wrong.is_empty(),
		"A010's 14 cuts are raster art at 16x16 (8,8) and 10x10 (5,5), and none is drawn by code",
		str(wrong))
	expect(drawn.is_empty(), "every mark draws its own pack file at its size, no two alike",
		str(drawn))
	expect(UiKit.orphan_icons().is_empty(), "and every icon in sprites/ui is claimed",
		str(UiKit.orphan_icons()))
	_completed += 1


## 0162 - A011's forecast heads: the five are raster art at 16x16 (8,8) with
## nothing standing in, and the panel shows each kind its own whole file - no
## box cut out of a walk frame any more - in its body's own colours.
func _task_0162_forecast_heads() -> void:
	var kinds: Array = [&"walker", &"runner", &"tank", &"breaker", &"giant"]
	var wrong: Array = []
	var shown: Array = []
	var panel := ForecastPanel.new()
	for kind in kinds:
		var name := StringName("head_%s" % kind)
		var path := "res://sprites/ui/%s.png" % name
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != Vector2i(16, 16) or frame.get("pivot") != Vector2i(8, 8) \
				or frame.has("stand_in") or not PlaceholderArt.art(name).is_empty() \
				or not ResourceLoader.exists(path):
			wrong.append(kind)
		var head := panel._head_of(kind)
		if head == null or head is AtlasTexture or head.resource_path != path \
				or head.get_size() != Vector2(16, 16):
			shown.append(kind)
			continue
		var body := Image.load_from_file(ProjectSettings.globalize_path(
			"res://sprites/enemies/%s_walk_0.png" % kind))
		var colours := {}
		for y in body.get_height():
			for x in body.get_width():
				var c := body.get_pixel(x, y)
				if c.a > 0.5:
					colours[c.to_html(false)] = true
		var image := head.get_image()
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				if c.a > 0.5 and not colours.has(c.to_html(false)) and not shown.has(kind):
					shown.append(kind)
	panel.free()
	expect(wrong.is_empty(), "A011's five heads are raster art at 16x16 (8,8), and none has a stand-in",
		str(wrong))
	expect(shown.is_empty(),
		"the forecast shows each kind its own whole head file, in its body's own colours",
		str(shown))
	_completed += 1


## 0163 - A012's winter ground: its 24 tiles (11 approved, 13 rotated or
## sliced from them) are raster art in their 16x16 box, nothing stands in,
## and the winter atlas is today's grid with snow where A012 drew it - the
## water, the rock and the floor are today's, so a pond is never frozen.
func _task_0163_winter_ground() -> void:
	var names: Array = []
	for name in ["grass", "grass_b", "grass_c", "grass_d", "path", "soil"]:
		names.append("terrain/%s_winter" % name)
	for prefix in ["edge", "shore"]:
		for side in ["n", "e", "s", "w"]:
			names.append("terrain/%s_%s_winter" % [prefix, side])
		for corner in ["nw", "ne", "se", "sw"]:
			names.append("terrain/%s_corner_%s_winter" % [prefix, corner])
	names.append("crops/tilled_winter")
	names.append("crops/tilled_wet_winter")
	var wrong: Array = []
	for name in names:
		var path := "res://sprites/%s.png" % name
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != Vector2i(16, 16) or frame.get("pivot") != Vector2i(8, 16) \
				or frame.has("stand_in") or SeasonView.stand_in(name) or not ResourceLoader.exists(path):
			wrong.append(name)
	expect(names.size() == 24 and wrong.is_empty(),
		"A012's 24 winter tiles are raster art at 16x16 (8,16), and none has a stand-in",
		str(wrong))

	var today := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/terrain/atlas.png"))
	var winter := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/terrain/atlas_winter.png"))
	var kept := true
	var snowed := 0
	# Row 0 is the terrain byte's order (`gen_sprites.ATLAS_ROWS[0]`).
	var row := [&"grass", &"soil", &"water", &"rock", &"path", &"floor"]
	for column in row.size():
		var cell := Rect2i(column * 16, 0, 16, 16)
		var same := today.get_region(cell).get_data() == winter.get_region(cell).get_data()
		if [&"water", &"rock", &"floor"].has(row[column]):
			kept = kept and same
		elif not same:
			snowed += 1
	for column in 3:
		var cell := Rect2i(column * 16, 16, 16, 16)
		kept = kept and today.get_region(cell).get_data() == winter.get_region(cell).get_data()
	expect(winter.get_size() == Vector2i(256, 80) and kept and snowed == 3,
		"the winter atlas is today's 256x80 grid: grass, soil and path snowed, the water's three frames, the rock and the floor today's",
		"%s, %d snowed" % [winter.get_size(), snowed])
	_completed += 1


## 0164 - A013's seasons of the trees and its snow caps: raster art in their
## boxes with nothing standing in, every tree on today's tree's ground row,
## summer still today's, and each node's cap its own - the copper, coal and
## gold nodes the generic one, the hardwood stump the 2x2.
func _task_0164_seasonal_trees() -> void:
	var wrong: Array = []
	for tree in ["tree", "tree_b"]:
		for season in ["spring", "autumn", "winter"]:
			var name := "props/%s_%s" % [tree, season]
			var path := "res://sprites/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			if frame.get("canvas") != Vector2i(40, 48) or frame.get("pivot") != Vector2i(20, 44) \
					or frame.has("stand_in") or SeasonView.stand_in(name) or not ResourceLoader.exists(path) \
					or _lowest_row(Image.load_from_file(ProjectSettings.globalize_path(path))) != 43:
				wrong.append(name)
		if SeasonView.frame_for("props/" + tree, 1) != "props/" + tree:
			wrong.append("summer's %s" % tree)
	for cap in ["stump", "rock", "rock_b", "ore", "ore_b", "seam", "seam_b"]:
		var name := "props/%s_snow" % cap
		var path := "res://sprites/%s.png" % name
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != Vector2i(16, 16) or frame.get("pivot") != Vector2i(8, 14) \
				or SeasonView.stand_in(name) or SeasonView.cap_for(StringName(cap), false) != name:
			wrong.append(name)
	var two := PlaceholderArt.frame("res://sprites/props/snow_cap_2x2.png")
	if two.get("canvas") != Vector2i(32, 32) or two.get("pivot") != Vector2i(16, 30) \
			or SeasonView.stand_in("props/snow_cap_2x2") \
			or SeasonView.cap_for(&"hardwood_stump", true) != "props/snow_cap_2x2" \
			or SeasonView.cap_for(&"copper_ore", false) != "props/snow_cap" \
			or SeasonView.stand_in("props/snow_cap"):
		wrong.append("the generic caps")
	expect(wrong.is_empty(),
		"A013's six trees stand on today's row 43 and its nine caps are its own, none a stand-in; summer keeps today's trees",
		str(wrong))
	_completed += 1


## 0202 - A019's tool icons: every tool at every tier, as 0173 named them, is
## raster art at 16x16 and 10x10 with nothing standing in and no tint, what
## the workshop, the ledger and the stall ask `UiKit.icon` for - and the tool
## in his hand keeps 0173's head ramps, A019's recorded tier ramps exactly.
func _task_0202_tool_icons() -> void:
	var wrong: Array = []
	var asked := 0
	for tool in GameData.sorted_names(GameData.TOOLS.keys()):
		for tier in (GameData.TOOLS[tool] as Array).size():
			var item := ToolTiers.item(tool, tier)
			for cut in [["icon", 16, false], ["hud", 10, true]]:
				var name := StringName("%s_%s" % [cut[0], item])
				var path := "res://sprites/ui/%s.png" % name
				var frame := PlaceholderArt.frame(path)
				var texture := UiKit.icon(item, bool(cut[2]))
				var side := int(cut[1])
				if frame.get("canvas") != Vector2i(side, side) or frame.has("stand_in") \
						or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE \
						or texture == null or texture.resource_path != path:
					wrong.append(name)
				asked += 1
	expect(asked == 30 and wrong.is_empty(),
		"A019's 30 cuts are raster art that UiKit hands out untinted, none a stand-in", str(wrong))
	# **The tiers' ramps** (A019's contract `tier_ramps`, dark to light), which
	# the in-hand head tint maps stone_dark/stone/stone_light onto.
	var ramps := {
		&"basic": [&"ink_soft", &"stone_dark", &"stone"],
		&"iron": [&"stone_dark", &"stone", &"stone_light"],
		&"gold": [&"gold_dark", &"gold", &"gold_light"],
		&"bamboo": [&"gold_dark", &"bone_dark", &"gold_light"],
		&"fibre": [&"roof_dark", &"roof", &"roof_light"],
	}
	var drift: Array = []
	for name in ramps:
		for i in 3:
			if (PlayerWork.HEAD_RAMPS[name][i] as Color).to_rgba32() \
					!= (PaletteData.COLOURS[ramps[name][i]] as Color).to_rgba32():
				drift.append("%s %d" % [name, i])
	expect(PlayerWork.HEAD_RAMPS.size() == ramps.size() and drift.is_empty(),
		"the tool in his hand keeps A019's recorded tier ramps", str(drift))
	_completed += 1


## **A020's materials** (task 0203): copper, gold and coal from the forge
## (0176), hardwood (0177), hay and straw (0184), each at 16 and at 10 - the
## raster files `UiKit.icon` hands the ledger, the stall and the workshop,
## untinted, with no stand-in left behind them.
func _task_0203_material_icons() -> void:
	var wrong: Array = []
	var asked := 0
	for id in [GameData.COPPER, GameData.GOLD, GameData.COAL, GameData.HARDWOOD,
			GameData.HAY, GameData.STRAW]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			var side := int(cut[1])
			if frame.get("canvas") != Vector2i(side, side) or frame.has("stand_in") 					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE 					or texture == null or texture.resource_path != path:
				wrong.append(name)
			asked += 1
	expect(asked == 12 and wrong.is_empty(),
		"A020's 12 cuts are raster art that UiKit hands out untinted, none a stand-in", str(wrong))
	_completed += 1


## **A029's animal goods** (task 0211): the egg, the milk, the wool and the
## truffle at 16 and at 10 - the raster files `UiKit.icon` hands the ledger
## and the stall, untinted - and the pig's dig spot, the approved mound the
## barnyard draws where 0185 marks one.
func _task_0211_animal_goods() -> void:
	var wrong: Array = []
	var asked := 0
	for id in [GameData.EGG, GameData.MILK, GameData.WOOL, GameData.TRUFFLE]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			var side := int(cut[1])
			if frame.get("canvas") != Vector2i(side, side) or frame.has("stand_in") 					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE 					or texture == null or texture.resource_path != path:
				wrong.append(name)
			asked += 1
	expect(asked == 8 and wrong.is_empty(),
		"A029's 8 cuts are raster art that UiKit hands out untinted, none a stand-in", str(wrong))
	var spot := PlaceholderArt.frame("res://sprites/props/truffle_spot.png")
	var view := AnimalView.new()
	var texture := view._texture(&"truffle_spot", 0, &"truffle_spot")
	expect(PlaceholderArt.art(&"truffle_spot").is_empty() and spot.get("canvas") == Vector2i(16, 16)
		and spot.get("pivot") == Vector2i(8, 14) and not spot.has("stand_in")
		and texture != null and texture.resource_path == "res://sprites/props/truffle_spot.png"
		and view._pivot(texture) == Vector2(8, 14),
		"the dig spot is A029's raster mound, 16x16 at (8,14), and the barnyard draws that file",
		str(spot))
	view.free()
	_completed += 1


## **A014's crop ground** (task 0197): the trampled and withered crops at
## (8,14) and the bed's turf edge and corner at (8,16) are raster art the
## plots draw untinted, with the drawn stand-ins of 0155 and 0171 gone.
func _task_0197_crop_ground() -> void:
	var wrong: Array = []
	for art in [[&"trampled", Vector2i(8, 14)], [&"withered", Vector2i(8, 14)],
			[&"tilled_edge_n", Vector2i(8, 16)], [&"tilled_edge_corner_nw", Vector2i(8, 16)]]:
		var path := WorldView.CROP_DIR + str(art[0]) + ".png"
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != Vector2i(16, 16) or frame.get("pivot") != art[1] \
				or frame.has("stand_in") or not PlaceholderArt.art(art[0]).is_empty() \
				or PlaceholderArt.is_drawn(path) or PlaceholderArt.texture_path(path) != path \
				or PlaceholderArt.art_tint(art[0]) != Color.WHITE:
			wrong.append(art[0])
	expect(wrong.is_empty(), "A014's four pieces are raster art at their pivots, none a stand-in",
		str(wrong))
	var view := WorldView.new()
	expect(not view.has_method("_withered_sprite") and not view.has_method("_trampled_sprite")
		and not ResourceLoader.exists("res://src/ui/withered.gdshader"),
		"the drawn withered and trampled stand-ins are gone with their shader")
	view.free()
	_completed += 1


## **A015's spring crops** (task 0198): potato, garlic and strawberry at
## their four stages and the strawberry regrowing, 16x16 at (8,14), and the
## produce's and the four spring packets' icons at 16 and at 10 - raster art
## the plots and `UiKit` hand out untinted. The carrot keeps its own crop and
## produce; only its packet is A015's.
func _task_0198_spring_crops() -> void:
	var wrong: Array = []
	var frames: Array = []
	for crop in [GameData.POTATO, GameData.GARLIC, GameData.STRAWBERRY]:
		for stage in 4:
			frames.append("%s_%d" % [crop, stage])
	frames.append("strawberry_regrow")
	for art in frames:
		var path := WorldView.CROP_DIR + str(art) + ".png"
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != Vector2i(16, 16) or frame.get("pivot") != Vector2i(8, 14) 				or frame.has("stand_in") or PlaceholderArt.texture_path(path) != path:
			wrong.append(art)
	for id in [GameData.POTATO, GameData.GARLIC, GameData.STRAWBERRY, GameData.CARROT_SEED,
			GameData.POTATO_SEED, GameData.GARLIC_SEED, GameData.STRAWBERRY_SEED]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			if frame.get("canvas") != Vector2i(int(cut[1]), int(cut[1])) or frame.has("stand_in") 					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE 					or texture == null or texture.resource_path != path:
				wrong.append(name)
	for crop in [GameData.POTATO, GameData.GARLIC, GameData.STRAWBERRY]:
		if not PlaceholderArt.art(crop).is_empty() or PlaceholderArt.art_tint(crop) != Color.WHITE:
			wrong.append(crop)
	expect(frames.size() == 13 and wrong.is_empty(),
		"A015's 13 crop frames and 14 icon cuts are raster art, untinted, none a stand-in", str(wrong))
	_completed += 1


## **A016's summer crops** (task 0199): pepper and melon at their four
## stages, 16x16 at (8,14), the tall sunflower's 16x32 at (8,30), pepper's
## and corn's regrowing stages, and the produce's and the four summer
## packets' icons at 16 and at 10 - raster art, untinted. Corn keeps its own
## four stages; only its regrowth is A016's.
func _task_0199_summer_crops() -> void:
	var wrong: Array = []
	var frames: Array = []
	for crop in [GameData.PEPPER, GameData.MELON]:
		for stage in 4:
			frames.append(["%s_%d" % [crop, stage], Vector2i(16, 16), Vector2i(8, 14)])
	for stage in 4:
		frames.append(["sunflower_%d" % stage, Vector2i(16, 32), Vector2i(8, 30)])
	frames.append(["pepper_regrow", Vector2i(16, 16), Vector2i(8, 14)])
	frames.append(["corn_regrow", Vector2i(16, 24), Vector2i(8, 22)])
	for art in frames:
		var path := WorldView.CROP_DIR + str(art[0]) + ".png"
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != art[1] or frame.get("pivot") != art[2] \
				or frame.has("stand_in") or PlaceholderArt.texture_path(path) != path:
			wrong.append(art[0])
	for id in [GameData.PEPPER, GameData.SUNFLOWER, GameData.MELON, GameData.CORN_SEED,
			GameData.PEPPER_SEED, GameData.SUNFLOWER_SEED, GameData.MELON_SEED]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			if frame.get("canvas") != Vector2i(int(cut[1]), int(cut[1])) or frame.has("stand_in") \
					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE \
					or texture == null or texture.resource_path != path:
				wrong.append(name)
	for crop in [GameData.PEPPER, GameData.SUNFLOWER, GameData.MELON, &"corn_regrow", &"pepper_regrow"]:
		if not PlaceholderArt.art(crop).is_empty() or PlaceholderArt.art_tint(crop) != Color.WHITE:
			wrong.append(crop)
	expect(frames.size() == 14 and wrong.is_empty(),
		"A016's 14 crop frames and 14 icon cuts are raster art, untinted, none a stand-in", str(wrong))
	_completed += 1


## **A017's autumn crops** (task 0200): pumpkin and beet at their four
## stages, 16x16 at (8,14), the grape on its trellis at the tall 16x32 on
## (8,30) and its regrowing stage, and the produce's and the four autumn
## packets' icons - wheat's among them - at 16 and at 10: raster art,
## untinted, none a stand-in. Wheat keeps its own four stages.
func _task_0200_autumn_crops() -> void:
	var wrong: Array = []
	var frames: Array = []
	for crop in [GameData.PUMPKIN, GameData.BEET]:
		for stage in 4:
			frames.append(["%s_%d" % [crop, stage], Vector2i(16, 16), Vector2i(8, 14)])
	for stage in 4:
		frames.append(["grape_%d" % stage, Vector2i(16, 32), Vector2i(8, 30)])
	frames.append(["grape_regrow", Vector2i(16, 32), Vector2i(8, 30)])
	for art in frames:
		var path := WorldView.CROP_DIR + str(art[0]) + ".png"
		var frame := PlaceholderArt.frame(path)
		if frame.get("canvas") != art[1] or frame.get("pivot") != art[2] \
				or frame.has("stand_in") or PlaceholderArt.texture_path(path) != path:
			wrong.append(art[0])
	for id in [GameData.PUMPKIN, GameData.GRAPE, GameData.BEET, GameData.WHEAT_SEED,
			GameData.PUMPKIN_SEED, GameData.GRAPE_SEED, GameData.BEET_SEED]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			if frame.get("canvas") != Vector2i(int(cut[1]), int(cut[1])) or frame.has("stand_in") \
					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE \
					or texture == null or texture.resource_path != path:
				wrong.append(name)
	for crop in [GameData.PUMPKIN, GameData.GRAPE, GameData.BEET, &"grape_regrow"]:
		if not PlaceholderArt.art(crop).is_empty() or PlaceholderArt.art_tint(crop) != Color.WHITE:
			wrong.append(crop)
	expect(frames.size() == 13 and wrong.is_empty(),
		"A017's 13 crop frames and 14 icon cuts are raster art, untinted, none a stand-in", str(wrong))
	_completed += 1


## **A018's sprinklers** (task 0201): each tier's idle cut and its four
## spray frames on 16x16 at (8,14), and its icon pair - raster art, untinted,
## none a stand-in. Through the first hour of the day a sprinkler shows its
## spray, a tenth of a second a frame round and round, and its idle cut after;
## the drops leave from the nozzle A018 marked, not the old point over the
## cell's middle.
func _task_0201_sprinklers() -> void:
	var wrong: Array = []
	for tier in [&"copper_sprinkler", &"iron_sprinkler", &"gold_sprinkler"]:
		for name in [String(tier)] + Array(range(4)).map(func(i: int) -> String: return "%s_spray_%d" % [tier, i]):
			var path: String = WorldView.PROP_DIR + str(name) + ".png"
			var frame := PlaceholderArt.frame(path)
			if not RasterArt.FRAMES.has(path) or frame.get("canvas") != Vector2i(16, 16) 					or frame.get("pivot") != Vector2i(8, 14) or (str(name) != String(tier)) != frame.has("spray"):
				wrong.append(name)
		if not PlaceholderArt.art(tier).is_empty():
			wrong.append(tier)
		for cut in [["icon", false], ["hud", true]]:
			var texture := UiKit.icon(tier, bool(cut[1]))
			if texture == null or texture.resource_path != "res://sprites/ui/%s_%s.png" % [cut[0], tier]:
				wrong.append("%s_%s" % [cut[0], tier])
	var morning := State.create(20101)
	var cell := Vector2i(10, 10)
	morning["day_tick"] = 0
	var spraying := [WorldView.sprinkler_art(morning, &"copper_sprinkler", 0.0),
		WorldView.sprinkler_art(morning, &"copper_sprinkler", 0.15),
		WorldView.sprinkler_art(morning, &"copper_sprinkler", 0.45)]
	morning["day_tick"] = Phases.tick_at_minute(Particles.SPRAY_UNTIL_MINUTE)
	var after := WorldView.sprinkler_art(morning, &"copper_sprinkler", 0.15)
	var nozzle: Vector2i = PlaceholderArt.frame(WorldView.PROP_DIR + "copper_sprinkler_spray_0.png")["spray"]
	var head := WorldView.spray_head(&"copper_sprinkler", cell)
	expect(wrong.is_empty() and spraying == [&"copper_sprinkler_spray_0", &"copper_sprinkler_spray_1", &"copper_sprinkler_spray_0"]
		and after == &"copper_sprinkler" and nozzle == Vector2i(8, 5)
		and head == Vector2(cell) * float(GameData.TILE_SIZE) + Vector2(8, 16) - Vector2(8, 14) + Vector2(nozzle),
		"A018's sprinklers are raster art; through the morning's hour a sprinkler turns its head a tenth of a second a frame, idle after, and its drops leave the nozzle",
		"%s; %s / %s; head %s" % [str(wrong), str(spraying), after, head])
	_completed += 1


## **A023's fishing gear** (task 0206): the worm's, the bait's and the fish
## book tab's icons, the bar's pieces and the bobber - raster art, none a
## stand-in. The bar's track and caps are the art's own; the float bobs on
## its two frames while the line waits and sinks through its three bite
## frames, held under, when a fish takes it.
func _task_0206_fishing_gear() -> void:
	var wrong: Array = []
	for id in [GameData.WORM, GameData.BAIT]:
		for cut in [["icon", false], ["hud", true]]:
			var texture := UiKit.icon(id, bool(cut[1]))
			if texture == null or texture.resource_path != "res://sprites/ui/%s_%s.png" % [cut[0], id] \
					or not PlaceholderArt.art(StringName("%s_%s" % [cut[0], id])).is_empty():
				wrong.append("%s_%s" % [cut[0], id])
	for name in ["icon_book_fish", "hud_book_fish", "fishbar_frame", "fishbar_zone", "fishbar_marker",
			"fishbar_hit_0", "fishbar_hit_2", "fishbar_miss_0", "fishbar_miss_2"]:
		var path := "res://sprites/ui/%s.png" % name
		if not RasterArt.FRAMES.has(path) or PlaceholderArt.is_drawn(path) or not ResourceLoader.exists(path):
			wrong.append(name)
	var frame := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/ui/fishbar_frame.png"))
	var zone := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/ui/fishbar_zone.png"))
	var bobbing := [BobberView.frame_name(false, 0.0), BobberView.frame_name(false, 0.45), BobberView.frame_name(false, 0.85)]
	var sinking := [BobberView.frame_name(true, 0.0), BobberView.frame_name(true, 0.15), BobberView.frame_name(true, 2.0)]
	var line: Vector2i = PlaceholderArt.frame(BobberView.DIR + "bobber_bite_2.png").get("line", Vector2i(-1, -1))
	expect(wrong.is_empty() and frame.get_size() == FishingBar.FRAME and zone.get_height() == FishingBar.TRACK.size.y
		and zone.get_width() > 2 * FishingBar.ZONE_CAP and is_equal_approx(FishingBar.FLASH_SECONDS, 0.195)
		and bobbing == ["bobber_float_0", "bobber_float_1", "bobber_float_0"]
		and sinking == ["bobber_bite_0", "bobber_bite_1", "bobber_bite_2"] and line == Vector2i(4, 5),
		"A023's fishing gear is raster art: the bar's frame and green fit its track, the flash is three frames of 0.065 s, and the float bobs on two frames and sinks through three, held under",
		"%s; %s / %s; line %s" % [str(wrong), str(bobbing), str(sinking), line])
	_completed += 1


## **A026's sheep and pig** (task 0209): every pose A026 drew - idle, walk,
## eat, sleep and the pig's dig - is raster art on 40x32 at (20,30), none a
## stand-in. A drawn pose loops on its own seconds, and the dig plays once
## and holds its last frame. The cow and the chicken are still on 0120's road
## until 0210.
func _task_0209_sheep_pig() -> void:
	var wrong: Array = []
	for pose in [&"sheep_idle", &"sheep_walk", &"sheep_eat", &"sheep_sleep", &"pig_idle", &"pig_walk",
			&"pig_eat", &"pig_sleep", &"pig_dig"]:
		var frame := PlaceholderArt.frame(AnimalView.pose_path(pose, 0))
		if not AnimalView.drawn(pose) or not PlaceholderArt.art(pose).is_empty() \
				or frame.get("canvas") != Vector2i(40, 32) or frame.get("pivot") != Vector2i(20, 30):
			wrong.append(pose)
	var walking := [AnimalView.animal_frame(&"sheep_walk", 0.0, 0.0), AnimalView.animal_frame(&"sheep_walk", 0.16, 0.0),
		AnimalView.animal_frame(&"sheep_walk", 0.61, 0.0)]
	var digging := [AnimalView.animal_frame(&"pig_dig", 9.0, 0.0), AnimalView.animal_frame(&"pig_dig", 9.0, 0.15),
		AnimalView.animal_frame(&"pig_dig", 9.0, 3.0)]
	expect(wrong.is_empty() and walking == [0, 1, 0] and digging == [0, 1, 2],
		"A026's sheep and pig are raster art at their box; a walk loops on its seconds and the dig plays once, held",
		"%s; walk %s, dig %s" % [str(wrong), str(walking), str(digging)])
	_completed += 1


## **A027's cow and hen** (task 0210): every pose A027 drew - idle, walk,
## eat and sleep - is raster art, the cow on 40x32 at (20,30) and the hen on
## 24x24 at (12,22), none a stand-in. No animal is left on 0120's road.
func _task_0210_cow_chicken() -> void:
	var wrong: Array = []
	for kind in [[&"cow", Vector2i(40, 32), Vector2i(20, 30)], [&"chicken", Vector2i(24, 24), Vector2i(12, 22)]]:
		for mode in [&"idle", &"walk", &"eat", &"sleep"]:
			var pose := StringName("%s_%s" % [kind[0], mode])
			var frame := PlaceholderArt.frame(AnimalView.pose_path(pose, 0))
			if not AnimalView.drawn(pose) or not PlaceholderArt.art(pose).is_empty() \
					or frame.get("canvas") != kind[1] or frame.get("pivot") != kind[2]:
				wrong.append(pose)
	var road: Array = []
	for name in GameData.sorted_names(PlaceholderArt.ART.keys()):
		if ["A026", "A027"].has(str((PlaceholderArt.ART[name] as Dictionary)["pack"])):
			road.append(name)
	var grazing := [AnimalView.animal_frame(&"cow_eat", 0.0, 0.0), AnimalView.animal_frame(&"cow_eat", 0.21, 0.0),
		AnimalView.animal_frame(&"chicken_sleep", 0.61, 0.0)]
	expect(wrong.is_empty() and road.is_empty() and grazing == [0, 1, 1],
		"A027's cow and hen are raster art at their boxes and no animal is left on 0120's road",
		"%s; road %s; %s" % [str(wrong), str(road), str(grazing)])
	_completed += 1


## **A030's coop and barn** (task 0212): whole, hurt and wrecked, raster art
## at full density - not in `ArtPlacement.visual_scale`'s 2.0 list - over
## the footprint 0183 settled, its canvas offset that footprint's. The lantern
## and the glass are on the whole and the hurt ones, none on a wreck, and the
## barn's windows land on its own cells.
func _task_0212_coop_barn() -> void:
	var wrong: Array = []
	for home in [[&"coop", Vector2i(64, 64), Vector2i(32, 60), Vector2i(3, 2)],
			[&"barn", Vector2i(96, 100), Vector2i(48, 96), Vector2i(5, 4)]]:
		for suffix in ["", "_hurt", "_wreck"]:
			var path := WorldView.BUILDING_DIR + "%s%s.png" % [home[0], suffix]
			var frame := PlaceholderArt.frame(path)
			var size: Vector2i = home[3]
			var pivot: Vector2i = home[2]
			if frame.get("canvas") != home[1] or frame.get("pivot") != pivot or frame.has("stand_in") \
					or frame.get("cell_offset") != Vector2i(size.x * 8, size.y * 16) - pivot \
					or ArtPlacement.visual_scale(path) != 1.0 or frame.has("windows") == (suffix == "_wreck"):
				wrong.append(path)
	var corner := Vector2(10, 10) * float(GameData.TILE_SIZE)
	var panes := ArtPlacement.emissions(&"barn", corner, &"windows", corner, &"light", Vector2i(5, 4))
	var inside := panes.size() == 2
	for pane in panes:
		inside = inside and Rect2(corner, Vector2(5, 4) * float(GameData.TILE_SIZE)).has_point(pane)
	expect(wrong.is_empty() and inside,
		"A030's coop and barn are raster art at full density over their footprints, lit whole and hurt and dark wrecked, the barn's panes on its own cells",
		"%s; panes %s" % [str(wrong), str(panes)])
	_completed += 1


## **A033's shipping bin** (task 0215): closed and its lid's three opening
## frames are raster art at 24x24 on (12,22), none a stand-in; with the
## panel open the lid lifts through them a tenth of a second each and holds
## the last, and shuts back down the same way.
func _task_0215_shipping_bin() -> void:
	var wrong: Array = []
	for name in ["shipping_bin", "shipping_bin_open_0", "shipping_bin_open_1", "shipping_bin_open_2"]:
		var frame := PlaceholderArt.frame(WorldView.PROP_DIR + name + ".png")
		if frame.get("canvas") != Vector2i(24, 24) or frame.get("pivot") != Vector2i(12, 22) or frame.has("stand_in"):
			wrong.append(name)
	if not PlaceholderArt.art(&"shipping_bin").is_empty():
		wrong.append("registry")
	var lifting := [WorldView.bin_art(0.0), WorldView.bin_art(0.1), WorldView.bin_art(0.2), WorldView.bin_art(0.3),
		WorldView.bin_art(9.0)]
	expect(wrong.is_empty() and lifting == [&"shipping_bin", &"shipping_bin_open_0", &"shipping_bin_open_1",
			&"shipping_bin_open_2", &"shipping_bin_open_2"],
		"A033's shipping bin is raster art; its lid lifts through three frames and holds the last",
		"%s; %s" % [str(wrong), str(lifting)])
	_completed += 1


## **A034's peddler and the shut stall** (task 0216): his idle, talk and
## walk are raster art on 40x40 at (20,36) at 1.0 - four, four and six frames
## - and the shut stall the shop's 32x40 at (16,36) at 2.0; none a stand-in.
func _task_0216_peddler() -> void:
	var wrong: Array = []
	for pose in [[&"peddler_idle", 4], [&"peddler_talk", 4], [&"peddler_walk", 6]]:
		var frame := PlaceholderArt.frame("res://sprites/actors/%s_0.png" % pose[0])
		if PeddlerView.frames_of(pose[0]) != pose[1] or not PlaceholderArt.art(pose[0]).is_empty() \
				or frame.get("canvas") != Vector2i(40, 40) or frame.get("pivot") != Vector2i(20, 36) or frame.has("stand_in"):
			wrong.append(pose[0])
	var shut := PlaceholderArt.frame("res://sprites/props/shop_closed.png")
	if shut.get("canvas") != Vector2i(32, 40) or shut.get("pivot") != Vector2i(16, 36) or shut.has("stand_in") \
			or ArtPlacement.visual_scale("res://sprites/props/shop_closed.png") != 2.0 \
			or PlaceholderArt.art_tint(&"shop_closed") != Color.WHITE:
		wrong.append("shop_closed")
	expect(wrong.is_empty(),
		"A034's peddler is raster art - four idle, four talking and six walking frames - and the shut stall the shop's box at 2.0",
		str(wrong))
	_completed += 1


## **A035's farmhouse tiers** (task 0217): tier I, II and III, whole and
## hurt, raster art at full density - 128x128 on (64,120) at 1.0, out of
## `ArtPlacement.visual_scale`'s 2.0 list - over the 6x4 footprint, with their
## nine slices each; the windows and the chimney land on the drawing's own
## points over that footprint, and no tier is on 0120's road.
func _task_0217_house_tiers() -> void:
	var wrong: Array = []
	for tier in ["house", "house_2", "house_3"]:
		for suffix in ["", "_hurt"]:
			var path: String = WorldView.BUILDING_DIR + str(tier) + str(suffix) + ".png"
			var frame := PlaceholderArt.frame(path)
			if frame.get("canvas") != Vector2i(128, 128) or frame.get("pivot") != Vector2i(64, 120) \
					or frame.get("cell_offset") != Vector2i(-16, -56) or frame.has("stand_in") \
					or ArtPlacement.visual_scale(path) != 1.0 or (frame.get("windows", []) as Array).size() != 5 \
					or not PlaceholderArt.art(StringName(str(tier) + str(suffix))).is_empty():
				wrong.append(str(tier) + str(suffix))
			for c in 3:
				for r in 3:
					var piece: String = WorldView.BUILDING_DIR + "%s_%d_%d%s.png" % [tier, c, r, suffix]
					if not ResourceLoader.exists(piece):
						wrong.append(piece.get_file())
	var corner := Vector2(10, 10) * float(GameData.TILE_SIZE)
	var contact := corner + Vector2(GameData.HOUSE_SIZE.x * 8, GameData.HOUSE_SIZE.y * 16)
	var shape := PlaceholderArt.frame(WorldView.BUILDING_DIR + "house.png")
	var smoke := ArtPlacement.emission(&"house", corner, &"smoke", Vector2.ZERO, GameData.HOUSE_SIZE)
	var panes := ArtPlacement.emissions(&"house", corner, &"windows", Vector2.ZERO, &"light", GameData.HOUSE_SIZE)
	expect(wrong.is_empty() and smoke == contact - Vector2(shape["pivot"]) + Vector2(shape["smoke"])
		and panes.size() == 5 and panes[0] == contact - Vector2(shape["pivot"]) + Vector2((shape["windows"] as Array)[0]),
		"A035's three house tiers, whole and hurt, are raster art at full density over the 6x4 footprint, sliced, their glass and chimney on the drawing's own points",
		"%s; smoke %s, panes %s" % [str(wrong), smoke, str(panes)])
	_completed += 1


## **A021's nodes** (task 0204): copper, coal and gold and their `_b`
## variants at 16x16 on (8,14), and the big stump whole and chipped at 32x32 on
## (16,30) - raster art, untinted, no stand-in left. The map picks each forge
## node's variant by cell as it does the ore's, the chipped stump is drawn from
## the first swing, and the coal seams wear the seam's snow cap.
func _task_0204_ore_hardwood() -> void:
	var wrong: Array = []
	for art in [[&"copper_ore", Vector2i(16, 16)], [&"copper_ore_b", Vector2i(16, 16)],
			[&"coal_seam", Vector2i(16, 16)], [&"coal_seam_b", Vector2i(16, 16)],
			[&"gold_ore", Vector2i(16, 16)], [&"gold_ore_b", Vector2i(16, 16)],
			[&"hardwood_stump", Vector2i(32, 32)], [&"hardwood_stump_chipped", Vector2i(32, 32)]]:
		var path := WorldView.PROP_DIR + str(art[0]) + ".png"
		var frame := PlaceholderArt.frame(path)
		var pivot := Vector2i(8, 14) if art[1] == Vector2i(16, 16) else Vector2i(16, 30)
		if frame.get("canvas") != art[1] or frame.get("pivot") != pivot or frame.has("stand_in") \
				or not PlaceholderArt.art(art[0]).is_empty() or PlaceholderArt.art_tint(art[0]) != Color.WHITE \
				or PlaceholderArt.texture_path(path) != path:
			wrong.append(art[0])
	for id in [&"copper_ore", &"coal_seam", &"gold_ore"]:
		if WorldView.PROP_VARIANTS.get(id, []) != [id, StringName("%s_b" % id)]:
			wrong.append("variants of %s" % id)
	expect(wrong.is_empty(), "A021's eight nodes are raster art at their boxes, each forge node with its variant",
		str(wrong))
	var state := State.create(4321)
	var anchor := Building.anchor_of(state, Farm.cells_with(state, &"hardwood_stump")[0])
	var whole := WorldView.struck_art(state, &"hardwood_stump", anchor)
	state["tools"]["axe"] = 1
	Gathering.strike(state, anchor)
	expect(whole == &"hardwood_stump" and WorldView.struck_art(state, &"hardwood_stump", anchor) == &"hardwood_stump_chipped"
		and SeasonView.cap_for(&"coal_seam", false) == "props/seam_snow"
		and SeasonView.cap_for(&"coal_seam_b", false) == "props/seam_snow"
		and SeasonView.cap_for(&"gold_ore_b", false) == "props/snow_cap",
		"the big stump is drawn chipped from its first swing, and coal wears the seam's cap",
		"%s, %s" % [whole, WorldView.struck_art(state, &"hardwood_stump", anchor)])
	_completed += 1


## **A022's fish** (task 0205): every species of the book - the twelve and
## the four legendaries - at three scales from one source, raster art,
## untinted: the icon pair `UiKit.icon` hands the ledger and the stall, and the
## portrait the book draws (black while the fish is unknown). The generic
## `icon_fish` a recipe names stays the resource icon it was.
func _task_0205_fish() -> void:
	var wrong: Array = []
	var asked := 0
	for id in GameData.sorted_names(GameData.FISH_SPECIES.keys()):
		for cut in [["icon", 16, false], ["hud", 10, true], ["portrait", 32, false]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.picture(name) if cut[0] == "portrait" else UiKit.icon(id, bool(cut[2]))
			if frame.get("canvas") != Vector2i(int(cut[1]), int(cut[1])) or frame.has("stand_in") \
					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE \
					or texture == null or texture.resource_path != path:
				wrong.append(name)
			asked += 1
	var generic := UiKit.icon(GameData.FISH)
	expect(asked == 48 and wrong.is_empty() and generic != null
		and generic.resource_path == "res://sprites/ui/icon_fish.png",
		"A022's 48 cuts are raster art, untinted, none a stand-in, and the generic fish stays",
		str(wrong))
	_completed += 1


## **A031's machines** (task 0213): the keg, the preserves jar, the dairy, the
## loom and the mill, each idle, active, hurt and wrecked - raster art at the
## boxes 0188 settled, at full density, every state a variant of the idle one.
## A wreck draws as a wreck, and the jar's fire and smoke rise from A031's
## firebox: inside its drawing, where the footprint puts the canvas.
func _task_0213_machines() -> void:
	var wrong: Array = []
	var boxes := {&"keg": [Vector2i(48, 56), Vector2i(24, 52)], &"preserves_jar": [Vector2i(48, 56), Vector2i(24, 52)],
		&"dairy": [Vector2i(64, 64), Vector2i(32, 60)], &"loom": [Vector2i(64, 64), Vector2i(32, 60)],
		&"mill": [Vector2i(64, 96), Vector2i(32, 92)]}
	for id in boxes:
		for suffix in ["", "_active", "_hurt", "_wreck"]:
			var art := StringName("%s%s" % [id, suffix])
			var path := WorldView.BUILDING_DIR + str(art) + ".png"
			var frame := PlaceholderArt.frame(path)
			var size := Building.size_of(id)
			var offset: Vector2i = Vector2i(size.x * 8, size.y * 16) - boxes[id][1]
			if frame.get("canvas") != boxes[id][0] or frame.get("pivot") != boxes[id][1] \
					or frame.get("cell_offset") != offset or frame.has("stand_in") \
					or not PlaceholderArt.art(art).is_empty() or PlaceholderArt.art_tint(art) != Color.WHITE \
					or ArtPlacement.visual_scale(path) != 1.0:
				wrong.append(art)
	expect(wrong.is_empty(), "A031's twenty states are raster art at their boxes and full density", str(wrong))
	var state := State.create(4321)
	var view := WorldView.new()
	view._state = state
	var wreck := {"id": &"loom", "hp": 0}
	var corner := Vector2(64, 96)
	var light := ArtPlacement.emission(&"preserves_jar", corner, &"light", Vector2.ZERO, Vector2i(2, 2))
	var smoke := ArtPlacement.emission(&"preserves_jar", corner, &"smoke", Vector2.ZERO, Vector2i(2, 2))
	# The canvas's corner sits at the footprint's bottom middle less the pivot.
	var canvas := corner + Vector2(16, 32) - Vector2(24, 52)
	expect(view._station_art(&"loom", wreck, Vector2i(4, 6)) == &"loom_wreck"
		and light == canvas + Vector2(21, 47) and smoke == canvas + Vector2(35, 22)
		and not PlaceholderArt.frame(WorldView.BUILDING_DIR + "preserves_jar_wreck.png").has("light"),
		"a wrecked machine draws its wreck, and the jar's fire and smoke rise from its firebox",
		"%s %s %s" % [view._station_art(&"loom", wreck, Vector2i(4, 6)), light, smoke])
	view.free()
	_completed += 1


## **A032's artisan goods** (task 0214): the eleven goods of the machines
## and the kitchen at 16 and at 10 - raster art `UiKit.icon` hands the ledger,
## the stall and the panels, untinted - while the oil's and the food's icons
## stay the resource icons they were.
func _task_0214_artisan_goods() -> void:
	var wrong: Array = []
	var asked := 0
	for id in [GameData.WINE, GameData.JUICE, GameData.JELLY, GameData.PICKLES, GameData.CHEESE,
			GameData.BUTTER, GameData.CLOTH, GameData.SANDBAG, GameData.FLOUR, GameData.SUGAR,
			GameData.BREAD]:
		for cut in [["icon", 16, false], ["hud", 10, true]]:
			var name := StringName("%s_%s" % [cut[0], id])
			var path := "res://sprites/ui/%s.png" % name
			var frame := PlaceholderArt.frame(path)
			var texture := UiKit.icon(id, bool(cut[2]))
			if frame.get("canvas") != Vector2i(int(cut[1]), int(cut[1])) or frame.has("stand_in") \
					or not PlaceholderArt.art(name).is_empty() or PlaceholderArt.art_tint(name) != Color.WHITE \
					or texture == null or texture.resource_path != path:
				wrong.append(name)
			asked += 1
	var oil := UiKit.icon(GameData.OIL)
	var food := UiKit.icon(GameData.FOOD)
	expect(asked == 22 and wrong.is_empty() and oil != null and oil.resource_path == "res://sprites/ui/icon_oil.png"
		and food != null and food.resource_path == "res://sprites/ui/icon_food.png",
		"A032's 22 cuts are raster art, untinted, none a stand-in, and oil and food keep theirs",
		str(wrong))
	_completed += 1


## The lowest row with anything drawn on it, or -1.
func _lowest_row(image: Image) -> int:
	for y in range(image.get_height() - 1, -1, -1):
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				return y
	return -1


## 0222 - bone meal: bones ground at the workshop give a plot one more
## morning of growth, once, on the first morning it grows at all.
func _task_0222_bone_meal() -> void:
	# **The resource and its recipe.**
	var recipe: Dictionary = GameData.RECIPES.get(&"grind_bone_meal", {})
	var bones_in := int((recipe.get("inputs", {}) as Dictionary).get(GameData.BONES, 0))
	var chain := str(GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE))
	expect(StringName(recipe.get("station", &"")) == &"workshop" and bones_in > 0
		and recipe.get("output", {}) == {GameData.BONE_MEAL: 1}
		and int(GameData.SELL_PRICE.get(GameData.BONE_MEAL, 0)) > bones_in * int(GameData.SELL_PRICE[GameData.BONES])
		and not chain.contains("grind_bone_meal"),
		"the workshop grinds bones into bone meal worth more than its bones", chain)
	expect(GameData.group_members(&"night_leftovers").has(GameData.BONE_MEAL)
		and Names.KEYS.get(GameData.BONE_MEAL, &"") == &"ITEM_BONE_MEAL"
		and Names.KEYS.get(&"grind_bone_meal", &"") == &"REC_GRIND_BONE_MEAL"
		and Crafting.recipes_at(&"workshop")[0] == &"barricade_kit",
		"bone meal is a named night leftover, its recipe named, and the workshop still opens on barricades")
	var language := I18n.locale()
	var named := true
	for locale in ["en", "pt_BR"]:
		I18n.use(locale)
		named = named and Names.of(GameData.BONE_MEAL) != "ITEM_BONE_MEAL" \
			and Names.of(&"grind_bone_meal") != "REC_GRIND_BONE_MEAL"
	I18n.use(language)
	expect(named, "in both languages")

	# **Ground at the workshop**: two bones in, a sack out.
	var mill := State.create(222001)
	var bench := Building.anchor_of(mill, Farm.cells_with(mill, &"workshop")[0])
	Resources.add(mill, GameData.BONES, bones_in)
	var ground := Crafting.start(mill, bench, &"grind_bone_meal")
	for _t in int(recipe.get("ticks", 0)) + 2:
		Crafting.tick(mill)
	expect(ground and Resources.amount(mill, GameData.BONES) == 0
		and Resources.amount(mill, GameData.BONE_MEAL) == 1,
		"the workshop turns the bones into a sack of bone meal",
		"%d bones, %d meal" % [Resources.amount(mill, GameData.BONES), Resources.amount(mill, GameData.BONE_MEAL)])

	# **Choosing it**: refused with none, chosen with some, put down by a
	# seed, and on the bumpers' road after the season's seeds.
	var state := State.create(222002)
	var seeds := Farming.in_season(state)
	expect(not Farming.select_bone_meal(state) and not Farming.fertilising(state),
		"bone meal cannot be chosen with none held")
	Resources.add(state, GameData.BONE_MEAL, 3)
	expect(Farming.select_bone_meal(state) and Farming.fertilising(state)
		and Farming.selected_seed(state) == seeds[0],
		"with some it is chosen, the seed still chosen under it")
	expect(Farming.select_seed(state, seeds[1]) and not Farming.fertilising(state),
		"and a seed chosen puts it down")
	Farming.select_seed(state, seeds[seeds.size() - 1])
	var stepped := Farming.step_choice(state, 1) and Farming.fertilising(state)
	stepped = stepped and Farming.step_choice(state, 1) and not Farming.fertilising(state) \
		and Farming.selected_seed(state) == seeds[0]
	stepped = stepped and Farming.step_choice(state, -1) and Farming.fertilising(state)
	expect(stepped, "the bumpers step from the last seed to the bone meal and round to the first")
	var winter := State.create(222003)
	winter["day"] = 3 * GameData.SEASON_DAYS + 1
	Resources.add(winter, GameData.BONE_MEAL, 1)
	expect(not Farming.select_bone_meal(winter) and not Farming.fertilising(winter),
		"and never in winter, when nothing grows")

	# **The verb**: the plot's before planting and watering, never before
	# a harvest, and a day verb with a pose and a sound.
	var a: Vector2i = Farming.field_cells(state)[0]
	var b: Vector2i = Farming.field_cells(state)[1]
	SuiteKit.crop_supplies(state, GameData.CARROT)
	Farming.select_seed(state, GameData.CARROT)
	for cell in [a, b]:
		Farming.act(state, cell)
		Farming.act(state, cell)
	expect(Farming.crop_on(state, a) == GameData.CARROT and Farming.crop_on(state, b) == GameData.CARROT,
		"fixture: two plots of carrots, sown together")
	Farming.select_bone_meal(state)
	var meal := Resources.amount(state, GameData.BONE_MEAL)
	expect(Interact.verb_at(state, a) == &"fertilise", "with bone meal chosen a sown plot offers it",
		str(Interact.verb_at(state, a)))
	Farming.act(state, a)
	expect(Farming.is_fertilised(state, a) and Resources.amount(state, GameData.BONE_MEAL) == meal - 1
		and Interact.verb_at(state, a) != &"fertilise" and not Farming.is_fertilised(state, b),
		"and takes one sack, once")
	Farming.select_seed(state, GameData.CARROT)
	expect(Interact.DAY_ONLY.has(&"fertilise") and Interact.DEFAULT_TICKS.has(&"fertilise")
		and Interact.all_verbs().has(&"fertilise") and Sfx.VERB_SOUNDS.get(&"fertilise", &"") == &"sfx/fertilise"
		and PlayerArt.VERBS.get(&"fertilise", &"") == &"plant",
		"a day verb, as long as a sowing, with the sowing's stoop - and since 0281 a sound of its own")

	# **The rule**: the fertilised plot finishes exactly a morning before
	# the other, and its second morning grants nothing extra.
	var needed := Farming.days_to_grow(GameData.CARROT)
	var ready_on := {}
	var growth_a: Array = []
	for morning in range(1, needed + 1):
		for cell in [a, b]:
			if Farming.is_ready(state, cell):
				continue
			state["water_can"] = 1
			Farming.act(state, cell)
		Farming.dry_out(state)
		Farming.morning(state)
		growth_a.append(int(Farming.plot(state, a)["growth"]))
		for cell in [a, b]:
			if Farming.is_ready(state, cell) and not ready_on.has(cell):
				ready_on[cell] = morning
	expect(int(ready_on.get(a, 0)) == needed - GameData.FERTILISED_EXTRA_DAYS and int(ready_on.get(b, 0)) == needed,
		"two carrots sown together: the fertilised one is ready a morning before the other",
		str(ready_on))
	expect(growth_a.size() >= 2 and int(growth_a[0]) == 1 + GameData.FERTILISED_EXTRA_DAYS
		and int(growth_a[1]) == int(growth_a[0]) + 1 and not Farming.is_fertilised(state, a),
		"its first morning grew it twice, its second once, and the mark is spent", str(growth_a))

	# **It wants the can**: dry, the mark waits; watered, it pays.
	var dry := State.create(222004)
	var c: Vector2i = Farming.field_cells(dry)[0]
	SuiteKit.crop_supplies(dry, GameData.CARROT)
	Farming.select_seed(dry, GameData.CARROT)
	Farming.act(dry, c)
	Farming.act(dry, c)
	Farming.plot(dry, c)["fertilised"] = true
	Farming.dry_out(dry)
	Farming.morning(dry)
	var after_dry := int(Farming.plot(dry, c)["growth"])
	dry["water_can"] = 1
	Farming.act(dry, c)
	Farming.dry_out(dry)
	Farming.morning(dry)
	expect(after_dry == 0 and int(Farming.plot(dry, c)["growth"]) == 1 + GameData.FERTILISED_EXTRA_DAYS
		and not Farming.is_fertilised(dry, c),
		"a dry morning grows nothing and keeps the mark; the watered one spends it")

	# **Unsown, it keeps the mark until it is sown; ready, a harvest clears
	# it; one morning short, it never grows past ready.**
	var unsown := State.create(222005)
	var d: Vector2i = Farming.field_cells(unsown)[0]
	Farming.act(unsown, d)
	Farming.plot(unsown, d)["fertilised"] = true
	unsown["water_can"] = 1
	Farming.dry_out(unsown)
	Farming.morning(unsown)
	expect(Farming.is_tilled(unsown, d) and Farming.crop_on(unsown, d) == &"" and Farming.is_fertilised(unsown, d),
		"an unsown fertilised plot keeps its mark through the morning")
	var plot_d := Farming.plot(unsown, d)
	plot_d["crop"] = GameData.CARROT
	plot_d["growth"] = needed - 1
	plot_d["watered"] = true
	Farming.dry_out(unsown)
	Farming.morning(unsown)
	expect(int(plot_d["growth"]) == needed and not Farming.is_fertilised(unsown, d),
		"sown and a morning short, it is ready - never past it - and the mark is spent",
		str(plot_d))
	plot_d["fertilised"] = true
	var yield_before := Resources.amount(unsown, GameData.CARROT)
	Farming.act(unsown, d)
	expect(Resources.amount(unsown, GameData.CARROT) > yield_before and not Farming.is_fertilised(unsown, d),
		"and a harvest clears a mark the crop never used")

	# **Winter grows nothing**, fertilised or not, and the mark waits.
	var cold := State.create(222006)
	var e: Vector2i = Farming.field_cells(cold)[0]
	SuiteKit.crop_supplies(cold, GameData.CARROT)
	Farming.select_seed(cold, GameData.CARROT)
	Farming.act(cold, e)
	Farming.act(cold, e)
	Farming.plot(cold, e)["fertilised"] = true
	cold["day"] = 3 * GameData.SEASON_DAYS + 2
	cold["water_can"] = 1
	Farming.plot(cold, e)["watered"] = true
	Farming.dry_out(cold)
	Farming.morning(cold)
	expect(int(Farming.plot(cold, e)["growth"]) == 0 and Farming.is_fertilised(cold, e),
		"a winter morning grows nothing and spends nothing")
	expect(not Farming.is_fertilised(State.create(222007), Farming.field_cells(State.create(222007))[0]),
		"and a plot with no mark on it - any save's - is not fertilised")
	_completed += 1


## The first cell in reading order with open ground `reach` tiles round it:
## buildable, untilled and empty.
func _open_patch(state: Dictionary, reach: int = 3) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		var open := true
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var near := cell + Vector2i(dx, dy)
				if not Grid.in_bounds(near) or not Farm.buildable(state, near) \
						or Farming.is_tilled(state, near):
					open = false
					break
			if not open:
				break
		if open:
			return cell
	return Vector2i(-1, -1)


## Whether the last `_moon_morning` night ended with the run's dice untouched.
var _moon_dice_kept := false


## The morning after `day`'s night, held: through the build step, the night
## parked, its end and the day begun.
func _moon_morning(seed_value: int, day: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = day
	state["nights_won"] = day - 1
	NightRoad.to_night(state)
	NightRoad.park(state)
	var dice: Array = (state["rng"] as Array).duplicate()
	Phases.enter_result(state, true)
	_moon_dice_kept = dice == (state["rng"] as Array)
	Phases.begin_day(state)
	return state


## A day of the run with `essence` in hand.
func _tree_day(seed_value: int, day: int, essence: int) -> Dictionary:
	var state := State.create(seed_value)
	state["day"] = day
	if essence > 0:
		Resources.add(state, GameData.TECH, essence)
	return state


## Own `last` and everything it needs, without paying: written straight into
## the tree, prerequisites first.
func _own_up_to(state: Dictionary, last: StringName) -> void:
	var chain: Array = []
	var at := last
	while at != &"":
		chain.push_front(at)
		var needs: Array = Tech.node(at)["needs"]
		at = StringName(needs[0]) if not needs.is_empty() else &""
	for id in chain:
		if not Tech.owns(state, id):
			(state["tech_owned"] as Array).append(id)


## A state at a tip's moment (task 0195), on day two or later: facing open
## grass, a season's first morning, facing the bin, a fish biting, a coop
## with the map's hens in it.
func _tip_moment(id: StringName) -> Dictionary:
	var state := State.create(1950)
	state["day"] = 2
	match id:
		&"till":
			for idx in Grid.CELLS:
				var cell := Grid.cell(idx)
				var stand := cell + Vector2i.DOWN
				if Farm.terrain_at(state, cell) == Farm.Terrain.GRASS and Interact.verb_at(state, cell) == &"till" \
						and Grid.in_bounds(stand) and Farm.walkable(state, stand):
					SuiteKit.stand_the_farmer(state, stand)
					state["player"]["facing"] = Player.NORTH
					break
		&"season":
			state["day"] = GameData.SEASON_DAYS + 1
		&"bin":
			SuiteKit.stand_the_farmer(state, Farm.cells_with(state, Shipping.BIN)[0] + Vector2i.RIGHT)
			state["player"]["facing"] = Player.WEST
		&"bite":
			for found in Farm.cells_of(state, Farm.Terrain.WATER):
				var dry: Vector2i = found + Vector2i.DOWN
				if Grid.in_bounds(dry) and Farm.walkable(state, dry) and not Fishing.is_casting(state):
					SuiteKit.stand_the_farmer(state, dry)
					state["player"]["facing"] = Player.NORTH
					Fishing.begin(state, found)
					state["fishing"]["left"] = 1
					Sim.advance(state, 2)
		&"animal":
			Resources.gain(state, Building.cost_of(&"coop"))
			Building.place(state, &"coop", _spot_for(state, &"coop"))
	return state


## Whether any of `errors` says `text`.
func _says(errors: Array, text: String) -> bool:
	for error in errors:
		if String(error).contains(text):
			return true
	return false


## Every way a season comes by `res` (task 0193): each recipe that makes it
## and whose inputs the season has, with where those come from - or, for a
## thing no recipe makes, the field, the node, the pond or the stall.
func _supply_ways(have: Dictionary, res: StringName) -> String:
	var ways: Array = []
	for id in GameData.sorted_names(GameData.RECIPES.keys()):
		var recipe: Dictionary = GameData.RECIPES[id]
		if not (recipe["output"] as Dictionary).has(res):
			continue
		var parts: Array = []
		for input in GameData.sorted_names((recipe["inputs"] as Dictionary).keys()):
			parts.append("%s from %s" % [input, have.get(input, "nowhere")])
		if not String(", ".join(parts)).contains("nowhere"):
			ways.append("%s (%s)" % [id, ", ".join(parts)])
	# What it comes from without a recipe - the stall's hay - goes first.
	if ways.is_empty() or not GameData.RECIPES.has(StringName(String(have.get(res, "")))):
		ways.push_front(String(have.get(res, "nowhere")))
	return "; ".join(ways)


## The top-left cell of the first place a building of this id fits, in cell
## order, or (-1, -1).
func _spot_for(state: Dictionary, id: StringName) -> Vector2i:
	for idx in Grid.CELLS:
		if Building.can_place(state, id, Grid.cell(idx)):
			return Grid.cell(idx)
	return Vector2i(-1, -1)


## Who lives in the home on `cell`, by kind and in order.
func _herd(state: Dictionary, cell: Vector2i) -> Array:
	var out: Array = []
	for animal in Livestock.residents(state, cell):
		out.append(StringName((animal as Dictionary)["id"]))
	return out


## The hit points of everything a breaker would come for.
func _prey_hp(state: Dictionary) -> int:
	var total := 0
	for cell in Pathing.prey_cells(state):
		total += int(Farm.occupant(state, cell).get("hp", 0))
	return total


## Five mornings of one fed pig in a barn on `seed_value`: every spot marked.
func _pig_spots(seed_value: int) -> Array:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 500, GameData.STONE: 500, GameData.MONEY: 2000})
	var barn := _site_spot(state, &"barn")
	Building.place(state, &"barn", barn)
	Livestock.house(state, barn, &"pig")
	var out: Array = []
	for _morning in 5:
		Resources.add(state, GameData.HAY, 2)
		_next_morning(state)
		out.append_array(Livestock.spots(state))
		Phases.begin_preparation(state)
	return out


## Step the animals' clocks `ticks` times, and nothing else.
func _tick_livestock(state: Dictionary, ticks: int) -> void:
	for _i in ticks:
		Livestock.tick(state)


## The next morning, as the end of a night hands it over.
func _next_morning(state: Dictionary) -> void:
	state["phase"] = Phases.RESULT
	Phases.begin_day(state)


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
