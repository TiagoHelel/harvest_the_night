extends SceneTree

## The rules, asserted with no window.
##
## Run by `python tools/verify.py`. The last line it prints is
## `N asserts, M failed`, and it exits non-zero when M is not zero.
##
## Every rule the backlog adds gets its asserts here in the same pass that adds
## the rule, grouped by the task that introduced them - so a failure says which
## piece of design just moved. **Adding a group means bumping `GROUPS`.**
##
## ## Failing rather than hanging
##
## GDScript has no exceptions. A runtime error does not stop the program: it
## prints, abandons the function it happened in, and returns to the caller. A
## check that dies half way would therefore reach the end of this file with a
## clean `0 failed` and report success for work it never did.
##
## Three things stop that, cheapest first:
##
## 1. Each group increments `_completed` **as its last statement**, so a group
##    that was abandoned mid-way never counts. `_finish()` fails when fewer
##    groups finished than `GROUPS` says exist.
## 2. `_process()` is a watchdog. It only runs when `_initialize()` never
##    returned at all - a parse error in something this file depends on - and it
##    ends the main loop rather than letting the SceneTree idle for ever.
## 3. `verify.py` bounds the whole run with a timeout, as the belt to these
##    braces, and runs `--check-only` over every script before this one starts.

## How long to wait before deciding `_initialize()` is never coming back.
## The whole check takes about a third of a second, so this is ample.
const WATCHDOG_SECONDS := 5.0

## How many `_task_NNNN_*` groups `_run()` is expected to finish.
const GROUPS := 34

const SettingsScript := preload("res://src/app/settings.gd")

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
	push_error("headless_check: watchdog fired after %.0fs" % _elapsed)
	print("WATCHDOG: _initialize() never returned. Something it depends on ",
		"failed to parse - run: godot --headless --path . --check-only ",
		"--script res://src/tools/headless_check.gd")
	_finish()
	return true


func _run() -> void:
	_task_0002_tick_and_rng()
	_task_0003_game_data()
	_task_0005_guards()
	_task_0006_phases()
	_task_0007_resources()
	_task_0008_farm()
	_task_0009_settings()
	_task_0010_save()
	_task_0016_gathering()
	_task_0017_stone()
	_task_0018_wheat()
	_task_0019_workshop()
	_task_0020_shop()
	_task_0021_night_intent()
	_task_0022_reality()
	_task_0023_building()
	_task_0024_tower()
	_task_0025_zombies()
	_task_0026_combat()
	_task_0027_the_loop()
	_task_0028_crops()
	_task_0029_watering()
	_task_0030_fishing()
	_task_0031_iron()
	_task_0032_oil()
	_task_0033_power()
	_task_0034_cooking()
	_task_0035_ammunition()
	_task_0036_inventory()
	_task_0037_queue()
	_task_0038_idle()
	_task_0039_clock()
	_task_0040_shop()
	_task_0041_tutorial()


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


## 0002 - the fixed timestep, the seeded stream and the state hash.
func _task_0002_tick_and_rng() -> void:
	# The same seed, ten thousand ticks, twice.
	var a := State.create(1234)
	var b := State.create(1234)
	Sim.advance(a, 10000)
	Sim.advance(b, 10000)
	var ha := State.hash_of(a)
	var hb := State.hash_of(b)
	expect(ha == hb, "10000 ticks from one seed replay identically",
		"%d vs %d" % [ha, hb])
	expect(int(a["tick"]) == 10000, "the tick count is the ticks asked for",
		str(a["tick"]))
	print("  hash of 10000 ticks @ seed 1234: ", ha)

	# A different seed must not land on the same state.
	var c := State.create(1235)
	Sim.advance(c, 10000)
	expect(State.hash_of(c) != ha, "a different seed diverges")

	# A draw advances the stream the state carries.
	var d := State.create(7)
	var first: Array = []
	for _i in 50:
		first.append(Rng.int_between(d["rng"], 1, 100))
	var e := State.create(7)
	var second: Array = []
	for _i in 50:
		second.append(Rng.int_between(e["rng"], 1, 100))
	expect(first == second, "the RNG stream replays from a seed")

	var lo := 101
	var hi := 0
	for v in first:
		lo = mini(lo, v)
		hi = maxi(hi, v)
	expect(lo >= 1 and hi <= 100, "int_between stays inside its bounds",
		"%d..%d" % [lo, hi])
	expect(lo <= 10 and hi >= 90, "int_between reaches both ends",
		"%d..%d" % [lo, hi])

	# Saving and restoring the stream resumes it exactly: this is the property
	# that lets a save reload mid-night and finish the night the same way.
	var f := State.create(99)
	Sim.advance(f, 100)
	for _i in 10:
		Rng.next_u32(f["rng"])
	var snapshot := State.copy(f)
	var after_a: Array = []
	for _i in 20:
		after_a.append(Rng.next_u32(f["rng"]))
	var after_b: Array = []
	for _i in 20:
		after_b.append(Rng.next_u32(snapshot["rng"]))
	expect(after_a == after_b, "a restored state resumes the same stream")

	# A deep copy cannot be moved by simulating the original - what the "what
	# if I put the tower here" preview will depend on.
	var g := State.create(5)
	var frozen := State.copy(g)
	var frozen_hash := State.hash_of(frozen)
	Sim.advance(g, 500)
	expect(State.hash_of(frozen) == frozen_hash, "a copy is independent")

	# The frame accumulator never produces a partial tick and never spirals.
	var acc := 0.0
	var total := 0
	for _i in 600:                      # ten seconds of 60fps frames
		var owed: Array = Sim.ticks_for(acc, 1.0 / 60.0)
		total += int(owed[0])
		acc = owed[1]
	expect(total == 300, "60fps for 10s owes exactly 300 ticks", str(total))

	var fast := 0
	acc = 0.0
	for _i in 1440:                     # the same ten seconds at 144fps
		var owed: Array = Sim.ticks_for(acc, 1.0 / 144.0)
		fast += int(owed[0])
		acc = owed[1]
	expect(absi(fast - 300) <= 1, "144fps owes the same ticks as 60fps",
		str(fast))

	var stall: Array = Sim.ticks_for(0.0, 30.0)     # a thirty second freeze
	expect(int(stall[0]) == GameData.MAX_CATCH_UP_TICKS,
		"a long stall is capped, not paid", str(stall[0]))
	expect(float(stall[1]) == 0.0, "the dropped backlog is not banked",
		str(stall[1]))

	var tiny: Array = Sim.ticks_for(0.0, 0.001)
	expect(int(tiny[0]) == 0 and float(tiny[1]) > 0.0,
		"a short frame owes no tick and carries the remainder")

	_completed += 1     # last line: an abandoned group never gets here


## 0003 - the lever file: every cross-reference resolves, and the validator
## that says so is itself shown to fail when it should.
func _task_0003_game_data() -> void:
	var errors: Array = GameData.validate()
	expect(errors.is_empty(), "GameData.validate() is clean",
		"; ".join(PackedStringArray(errors)))

	# **The validator has to be seen failing.** One that has never caught
	# anything is one nobody should trust, so it is handed a recipe pointing at
	# a resource that does not exist and asked to name it.
	var broken: Dictionary = {
		&"bad_recipe": {
			"station": &"workshop",
			"inputs": {&"unobtainium": 1},
			"output": {GameData.WOOD: 1},
			"ticks": 30,
		},
	}
	var caught: Array = GameData.check_recipes(broken)
	expect(caught.size() == 1, "a bad recipe input is caught", str(caught))
	expect(caught.size() > 0 and str(caught[0]).contains("unobtainium"),
		"the error names the offending id", str(caught))

	var bad_station: Array = GameData.check_recipes({
		&"homeless": {
			"station": &"nowhere",
			"inputs": {GameData.WOOD: 1},
			"output": {GameData.FOOD: 1},
			"ticks": 30,
		},
	})
	expect(bad_station.size() == 1 and str(bad_station[0]).contains("nowhere"),
		"a recipe at an unknown station is caught", str(bad_station))

	var bad_night: Array = GameData.check_nights([[[&"vampire", 3, 0, 0]]])
	expect(bad_night.size() >= 1 and str(bad_night[0]).contains("vampire"),
		"an unknown enemy in a wave is caught", str(bad_night))

	# Every resource the reference sheet shows is here, and every sellable one
	# has a price.
	#
	# **Named rather than counted.** This was `size() == 13`, which is a test
	# that fails when the game grows and says nothing about what is missing -
	# task 0035 added incendiary rounds and all it reported was "14". The panel
	# on `docs/reference-sheet.png` has twelve things on it; those twelve have
	# to exist. Carrot and incendiary do not appear on that panel and are not
	# listed here, which is the point: the sheet is a floor, not a ceiling.
	for res in [GameData.WOOD, GameData.STONE, GameData.IRON, GameData.FOOD,
			GameData.FISH, GameData.OIL, GameData.WHEAT, GameData.CORN,
			GameData.MEAT, GameData.GUNPOWDER, GameData.MONEY,
			GameData.ENERGY]:
		expect(GameData.RESOURCES.has(res),
			"the sheet shows %s, so the game has it" % res)
	expect(GameData.RESOURCES.size() >= 12,
		"and at least the twelve the sheet shows",
		str(GameData.RESOURCES.size()))
	expect(GameData.RESOURCES.size()
		== GameData.sorted_names(GameData.RESOURCES).size(),
		"with no duplicates in the list", str(GameData.RESOURCES.size()))
	for res in GameData.SELL_PRICE:
		expect(GameData.RESOURCES.has(res), "a priced thing is a resource",
			str(res))

	# Ten nights, per design.md, and each one has at least one wave.
	expect(GameData.NIGHTS.size() == GameData.MVP_NIGHTS, "ten nights",
		str(GameData.NIGHTS.size()))
	for n in GameData.NIGHTS.size():
		expect((GameData.NIGHTS[n] as Array).size() > 0,
			"night %d has waves" % (n + 1))

	# The Giant only shows up on the last one: it is the test of the build, not
	# a thing that wanders in on night 4.
	var giant_nights: Array = []
	for n in GameData.NIGHTS.size():
		for wave in (GameData.NIGHTS[n] as Array):
			if wave[0] == &"giant" and not giant_nights.has(n + 1):
				giant_nights.append(n + 1)
	expect(giant_nights == [10], "the Giant is night 10 and nowhere else",
		str(giant_nights))

	# Buying a material is always worse than going and getting it, at every
	# price, or money quietly replaces playing the game.
	for res in GameData.SELL_PRICE:
		var sell: int = GameData.SELL_PRICE[res]
		var buy: float = float(sell) * GameData.BUY_MARKUP
		expect(buy > float(sell), "buying %s costs more than selling it" % res,
			"%d sell, %.1f buy" % [sell, buy])

	# A crop must be worth more harvested than its seed cost, or nobody plants
	# it twice.
	for crop_id in GameData.CROPS:
		var crop: Dictionary = GameData.CROPS[crop_id]
		var revenue: int = int(crop["yield"]) * int(GameData.SELL_PRICE[crop_id])
		expect(revenue > int(crop["seed_cost"]),
			"%s pays for its own seed" % crop_id,
			"%d seed, %d harvest" % [crop["seed_cost"], revenue])

	# Dusk falls inside the day.
	expect(GameData.DUSK_AT_TICK < GameData.DAY_TICKS, "dusk is before night")

	_completed += 1     # last line: an abandoned group never gets here


## 0005 - the two hash guards: the numbers they watch have to be stable, and
## they have to actually be watching something.
func _task_0005_guards() -> void:
	# A digest that changed between two calls would fail the guard every run
	# and teach everybody to pass --accept without looking, which is how a
	# guard becomes decoration.
	expect(GameData.digest() == GameData.digest(),
		"the data digest is stable across calls")
	expect(GameData.digest() != State.hash_of({}),
		"the data digest actually folds the tables")

	# The scenario the sim guard runs must be reproducible for the guard to
	# mean anything - the same property headless_check asserts for the tick,
	# checked here at the exact length the guard uses.
	var a := State.create(424242)
	var b := State.create(424242)
	Sim.advance(a, 20000)
	Sim.advance(b, 20000)
	expect(State.hash_of(a) == State.hash_of(b),
		"the guarded scenario replays identically")

	_completed += 1     # last line: an abandoned group never gets here


## 0006 - the loop the whole game is, walked with no UI in the room.
func _task_0006_phases() -> void:
	var state := State.create(11)
	expect(int(state["phase"]) == Phases.DAY, "a new game starts in the day",
		Phases.name_of(int(state["phase"])))
	expect(int(state["day"]) == 1, "and on day 1", str(state["day"]))

	# A full cycle, and the day counter moves exactly once across it.
	var day_before: int = int(state["day"])
	Sim.advance(state, 600)
	expect(int(state["day_tick"]) == 600, "the day clock ran",
		str(state["day_tick"]))
	expect(int(state["night_tick"]) == 0, "no zombie spawned in the afternoon",
		str(state["night_tick"]))

	expect(Phases.begin_preparation(state), "the night button works")
	expect(int(state["phase"]) == Phases.PREPARATION, "it lands in preparation")

	# Preparation ends itself after its lever's worth of ticks.
	Sim.advance(state, GameData.PREPARATION_TICKS - 1)
	expect(int(state["phase"]) == Phases.PREPARATION,
		"preparation lasts as long as the lever says")
	Sim.advance(state, 1)
	expect(int(state["phase"]) == Phases.NIGHT, "then the night begins",
		Phases.name_of(int(state["phase"])))
	expect(int(state["night"]) == 1, "it is night 1", str(state["night"]))

	var day_clock_at_dusk: int = int(state["day_tick"])
	Sim.advance(state, 400)
	expect(int(state["night_tick"]) == 400, "the night clock ran",
		str(state["night_tick"]))
	expect(int(state["day_tick"]) == day_clock_at_dusk,
		"nothing grew during the night",
		"%d then %d" % [day_clock_at_dusk, state["day_tick"]])

	expect(Phases.enter_result(state, true), "the night can end")
	expect(int(state["phase"]) == Phases.RESULT, "it lands on the result")
	expect(int(state["day"]) == day_before + 1,
		"the day counter moved exactly once", str(state["day"]))
	expect((state["last_result"] as Dictionary)["survived"] == true,
		"the result records what happened")

	# Nothing at all moves while the player reads the payout.
	var frozen := State.copy(state)
	frozen.erase("tick")
	Sim.advance(state, 300)
	var after := State.copy(state)
	after.erase("tick")
	after.erase("phase_tick")
	frozen.erase("phase_tick")
	expect(State.hash_of(frozen) == State.hash_of(after),
		"the world is still while the result is up")

	expect(Phases.begin_day(state), "and back to the farm")
	expect(int(state["phase"]) == Phases.DAY, "a full cycle closed")
	expect(int(state["day_tick"]) == 0, "the new day starts at dawn",
		str(state["day_tick"]))

	# Dusk asks; it never presses the button itself.
	Sim.advance(state, GameData.DUSK_AT_TICK)
	expect(Phases.is_dusk(state), "dusk is noticed")
	expect(int(state["phase"]) == Phases.DAY,
		"but the day does not end itself - design.md promises that")

	# An illegal move is refused whole, not half applied. The four ERROR lines
	# this prints are deliberate: they are the refusals being tested.
	print("  (the ERROR lines below are deliberate - refused transitions)")
	var guard := State.create(3)
	expect(not Phases.begin_night(guard), "no night straight from the day")
	expect(not Phases.enter_result(guard, true), "no result without a night")
	expect(not Phases.begin_day(guard), "no dawn without a result")
	expect(int(guard["phase"]) == Phases.DAY,
		"a refused transition changed nothing",
		Phases.name_of(int(guard["phase"])))
	expect(int(guard["day"]) == 1, "and did not move the day counter",
		str(guard["day"]))

	_completed += 1     # last line: an abandoned group never gets here


## 0007 - the ledger: all or nothing, never below zero, one source of truth.
func _task_0007_resources() -> void:
	var state := State.create(21)

	# A new game starts on what design.md calls a small amount, and on no iron
	# at all - the first tower has to be earned at the rock face.
	expect(Resources.amount(state, GameData.WOOD) == 12, "starting wood",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Resources.amount(state, GameData.IRON) == 0, "and no starting iron",
		str(Resources.amount(state, GameData.IRON)))
	for id in GameData.RESOURCES:
		expect((state["held"] as Dictionary).has(id),
			"the ledger knows about %s" % id)

	# Adding and spending the simple way.
	Resources.add(state, GameData.IRON, 10)
	expect(Resources.amount(state, GameData.IRON) == 10, "adding works")
	expect(Resources.spend(state, GameData.IRON, 4), "spending works")
	expect(Resources.amount(state, GameData.IRON) == 6, "and leaves the rest",
		str(Resources.amount(state, GameData.IRON)))

	# **Spending more than you have changes nothing at all.**
	var before := State.hash_of(state)
	expect(not Resources.spend(state, GameData.IRON, 7), "overspending fails")
	expect(State.hash_of(state) == before, "and changed nothing")

	# **A cost is all or nothing.** This is the one that matters: the obvious
	# loop-of-spend takes the wood, fails on the iron, and leaves the player
	# poorer with nothing to show for it.
	var cost := {GameData.WOOD: 10, GameData.IRON: 99}
	expect(not Resources.can_afford(state, cost), "a short cost is unaffordable")
	before = State.hash_of(state)
	expect(not Resources.pay(state, cost), "and cannot be paid")
	expect(State.hash_of(state) == before,
		"a failed payment takes neither line - not even the affordable one")
	expect(Resources.amount(state, GameData.WOOD) == 12,
		"the wood is still there", str(Resources.amount(state, GameData.WOOD)))

	# An affordable cost takes every line.
	var real_cost := {GameData.WOOD: 10, GameData.IRON: 6}
	expect(Resources.can_afford(state, real_cost), "an affordable cost is")
	expect(Resources.pay(state, real_cost), "and is paid")
	expect(Resources.amount(state, GameData.WOOD) == 2, "wood taken",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Resources.amount(state, GameData.IRON) == 0, "iron taken",
		str(Resources.amount(state, GameData.IRON)))

	# What it is short by, for the tooltip that explains a greyed button.
	var short := Resources.missing(state, {GameData.WOOD: 5, GameData.STONE: 1})
	expect(short.size() == 1 and int(short[GameData.WOOD]) == 3,
		"missing() names only what is short, and by how much", str(short))

	# Nothing can go below zero, whatever the build.
	expect(Resources.amount(state, GameData.IRON) == 0, "at zero")
	expect(not Resources.spend(state, GameData.IRON, 1), "cannot go below it")
	expect(Resources.amount(state, GameData.IRON) == 0, "still zero",
		str(Resources.amount(state, GameData.IRON)))

	# The running total only ever goes up, which is what the statistics screen
	# of task 0069 will report.
	var gained: Dictionary = state["gained"]
	expect(int(gained[GameData.IRON]) == 10,
		"the total gained remembers what was spent", str(gained[GameData.IRON]))

	# gain() is add() across a whole yield.
	Resources.gain(state, {GameData.FISH: 2, GameData.WHEAT: 3})
	expect(Resources.amount(state, GameData.FISH) == 2, "a yield lands")
	expect(Resources.amount(state, GameData.WHEAT) == 3, "every line of it")

	# An unknown id is refused rather than quietly inventing a resource.
	print("  (the ERROR lines below are deliberate - unknown ids refused)")
	Resources.add(state, &"unobtainium", 5)
	expect(not (state["held"] as Dictionary).has(&"unobtainium"),
		"adding an unknown resource does not create it")
	expect(not Resources.spend(state, &"unobtainium", 1),
		"and it cannot be spent")

	_completed += 1     # last line: an abandoned group never gets here


## 0008 - the farm: one grid, both realities, and a place() that refuses.
func _task_0008_farm() -> void:
	var state := State.create(31)

	expect(Grid.CELLS == 40 * 18, "the farm is 40x18", str(Grid.CELLS))
	expect((state["terrain"] as PackedByteArray).size() == Grid.CELLS,
		"every cell has terrain")

	# Index and cell are each other's inverse, at both corners and in between.
	for idx in [0, 1, 39, 40, 359, Grid.CELLS - 1]:
		expect(Grid.index(Grid.cell(idx)) == idx,
			"index and cell round-trip at %d" % idx)
	expect(Grid.index(Vector2i(-1, 0)) == -1, "off the farm is -1")
	expect(Grid.index(Vector2i(0, -1)) == -1, "off the top is -1 too")
	expect(Grid.index(Vector2i(Grid.WIDTH, 0)) == -1,
		"and one past the right edge does not wrap onto the next row")

	# The map made the farm the design document asks for.
	expect(Farm.cells_with(state, &"house").size() == 9,
		"the farmhouse is three by three",
		str(Farm.cells_with(state, &"house").size()))
	expect(Farm.cells_with(state, &"tree").size() >= 40, "there is a wood",
		str(Farm.cells_with(state, &"tree").size()))
	# **Eight, and the number matters.** A day at the cliff is worth two
	# harvests per node, and task 0031 set that against the price of a gun
	# tower - so an ore node added or removed is a balance change, not scenery.
	expect(Farm.cells_with(state, &"ore").size() == 8, "eight ore nodes",
		str(Farm.cells_with(state, &"ore").size()))
	expect(Farm.cells_of(state, Farm.Terrain.SOIL).size() == 48, "a field",
		str(Farm.cells_of(state, Farm.Terrain.SOIL).size()))
	expect(Farm.cells_of(state, Farm.Terrain.WATER).size() > 60, "a pond",
		str(Farm.cells_of(state, Farm.Terrain.WATER).size()))
	expect(Farm.cells_with(state, &"shop").size() == 2, "a shop stall")

	# Water and rock refuse to be built on, and say why.
	var pond: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	expect(not Farm.buildable(state, pond), "nothing is built in the pond")
	expect(Farm.why_not_buildable(state, pond) == "in the water",
		"and it says why", Farm.why_not_buildable(state, pond))
	expect(not Farm.walkable(state, pond), "and nobody walks into it")

	var cliff: Vector2i = Farm.cells_of(state, Farm.Terrain.ROCK)[0]
	expect(not Farm.buildable(state, cliff), "nor on the rock face")

	# **The house is never buildable and never removable.**
	var house: Vector2i = Farm.cells_with(state, &"house")[0]
	expect(not Farm.buildable(state, house), "nothing is built on the house")
	expect(Farm.why_not_buildable(state, house) == "on the house",
		"and it says so", Farm.why_not_buildable(state, house))
	expect(not Farm.remove(state, house), "and the house cannot be removed")
	expect(Farm.cells_with(state, &"house").size() == 9, "it is still there")

	# **Place then remove leaves the farm byte-identical.** The done-when of
	# this task, and the property a build-then-sell loop depends on.
	# **Found, not written down.** This used to be a hardcoded cell, and task
	# 0019 put the workshop on it - so the test failed for a reason that had
	# nothing to do with what it was checking.
	var spot := _any_buildable(state)
	expect(spot != Vector2i(-1, -1), "there is somewhere to build")
	expect(Farm.buildable(state, spot), "an empty patch of grass is buildable")
	# **The farm, not the whole state.** Since task 0025 the farm carries a
	# `grid_version` that counts how many times it changed - which is the point
	# of it, and which means the state cannot come back byte-identical. What
	# has to come back identical is the ground and what is standing on it.
	var before := _farm_hash(state)
	expect(Farm.place(state, spot, {"id": &"gun_tower", "hp": 60}),
		"a tower goes down")
	expect(_farm_hash(state) != before, "which changed the farm")
	expect(not Farm.buildable(state, spot), "and the cell is taken now")
	expect(not Farm.walkable(state, spot), "and blocks the way")
	expect(Farm.occupant(state, spot)["id"] == &"gun_tower",
		"occupant() says what is there")
	expect(not Farm.place(state, spot, {"id": &"wall"}),
		"a second thing cannot stack on it")
	expect(Farm.remove(state, spot), "and it comes back up")
	expect(_farm_hash(state) == before,
		"leaving the farm byte-identical to before it was placed")

	# A placed occupant is copied in, so the caller's dictionary cannot be a
	# back door into the state afterwards.
	var shared := {"id": &"wall", "hp": 120}
	Farm.place(state, spot, shared)
	shared["hp"] = 9999
	expect(int(Farm.occupant(state, spot)["hp"]) == 120,
		"place() copies rather than aliasing",
		str(Farm.occupant(state, spot)["hp"]))
	Farm.remove(state, spot)

	# One grid, both realities: the night sees exactly what the day built.
	var walled := _any_buildable(state)
	Farm.place(state, walled, {"id": &"wall"})
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(int(state["phase"]) == Phases.NIGHT, "night fell")
	expect(Farm.occupant(state, walled)["id"] == &"wall",
		"and the wall built by day is in the same cell by night")

	_completed += 1     # last line: an abandoned group never gets here


## 0009 - settings: it survives, it never crashes, and a bad file is not fatal.
##
## The autoload is not instantiated in a `--script` run, so these drive a plain
## instance - which is why every method works without being in the tree.
func _task_0009_settings() -> void:
	_wipe_settings_files()

	# **A missing file is the first run, not an error.**
	var s: Node = SettingsScript.new()
	s.load_from_disk()
	expect(s.loaded_from_defaults(), "a missing file starts on defaults")
	expect(is_equal_approx(s.get_float(&"audio/master"), 1.0),
		"and the default is the default", str(s.get_float(&"audio/master")))

	# A changed value fires its own key, once, and only when it changed.
	var fired: Array = []
	s.changed.connect(func(key: StringName) -> void: fired.append(key))
	s.set_value(&"audio/master", 0.4)
	expect(fired == [&"audio/master"], "changing a key emits exactly that key",
		str(fired))
	s.set_value(&"audio/master", 0.4)
	expect(fired.size() == 1, "setting it to what it already is emits nothing",
		str(fired))

	# **It survived.** A second instance reads what the first one wrote.
	var again: Node = SettingsScript.new()
	again.load_from_disk()
	expect(not again.loaded_from_defaults(), "the file was found")
	expect(is_equal_approx(again.get_float(&"audio/master"), 0.4),
		"and the value survived a reload",
		str(again.get_float(&"audio/master")))
	expect(is_equal_approx(again.get_float(&"audio/music"), 0.8),
		"untouched keys are still their defaults")

	# **A corrupt file boots on defaults and says so.**
	var f := FileAccess.open(s.PATH, FileAccess.WRITE)
	f.store_string("[[[ this is not a config file = = = ]]")
	f.close()
	print("  (the WARNING below is deliberate - a corrupt file being refused)")
	var broken: Node = SettingsScript.new()
	broken.load_from_disk()
	expect(broken.loaded_from_defaults(), "a corrupt file starts on defaults")
	expect(is_equal_approx(broken.get_float(&"audio/master"), 1.0),
		"with every value back at its default")
	expect(FileAccess.file_exists(s.PATH),
		"and the bad file is left alone rather than deleted")

	# The same for a file that parses but is somebody else's - ConfigFile is
	# lenient enough that "it loaded" proves nothing about who wrote it.
	var foreign := ConfigFile.new()
	foreign.set_value("audio", "master", 0.9)      # no [meta] version
	foreign.save(s.PATH)
	print("  (the WARNING below is deliberate - a file we did not write)")
	var alien: Node = SettingsScript.new()
	alien.load_from_disk()
	expect(alien.loaded_from_defaults(),
		"a file without our version marker is not trusted")
	expect(is_equal_approx(alien.get_float(&"audio/master"), 1.0),
		"and none of its values are used",
		str(alien.get_float(&"audio/master")))
	alien.free()

	# A key from an older build is dropped rather than kept for ever.
	_wipe_settings_files()
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", broken.VERSION)
	cfg.set_value("audio", "master", 0.25)
	cfg.set_value("audio", "quadrophonic", true)     # never existed
	cfg.set_value("video", "vsync", "yes")           # right key, wrong type
	cfg.save(s.PATH)
	print("  (the WARNING below is deliberate - unknown keys being dropped)")
	var loaded: Node = SettingsScript.new()
	loaded.load_from_disk()
	expect(is_equal_approx(loaded.get_float(&"audio/master"), 0.25),
		"a good key is read")
	expect(loaded.get_bool(&"video/vsync") == true,
		"a key of the wrong type falls back to its default rather than "
		+ "poisoning a panel")

	# Groups are what an options tab is.
	var audio: Dictionary = loaded.group(&"audio")
	expect(audio.size() == 5, "the audio group is five settings",
		str(audio.size()))
	expect(audio.has(&"audio/master") and not audio.has(&"video/vsync"),
		"and holds only its own")

	# Reset puts one key, or all of them, back.
	loaded.set_value(&"a11y/ui_scale", 2.0)
	loaded.reset(&"a11y/ui_scale")
	expect(is_equal_approx(loaded.get_float(&"a11y/ui_scale"), 1.0),
		"one key resets")
	loaded.set_value(&"audio/music", 0.1)
	loaded.reset()
	expect(is_equal_approx(loaded.get_float(&"audio/music"), 0.8),
		"and everything resets")

	# An unknown key is refused at the call site too.
	print("  (the ERROR lines below are deliberate - unknown keys refused)")
	expect(loaded.get_value(&"video/raytracing") == null,
		"reading a key that does not exist returns null and complains")
	loaded.set_value(&"video/raytracing", true)
	expect(not loaded._values.has(&"video/raytracing"),
		"and writing one does not invent it")
	loaded.set_value(&"audio/master", "loud")
	expect(is_equal_approx(loaded.get_float(&"audio/master"), 1.0),
		"a value of the wrong type is refused")

	# **The crash window is covered.** A run that died between removing the old
	# file and renaming the new one leaves only the temporary file; the next
	# load recovers it instead of silently resetting the player's options.
	_wipe_settings_files()
	var rescue := ConfigFile.new()
	rescue.set_value("meta", "version", broken.VERSION)
	rescue.set_value("audio", "sfx", 0.33)
	rescue.save(s.TEMP_PATH)
	print("  (the WARNING below is deliberate - a temp file being recovered)")
	var recovered: Node = SettingsScript.new()
	recovered.load_from_disk()
	expect(is_equal_approx(recovered.get_float(&"audio/sfx"), 0.33),
		"a settings file left half-written is recovered, not thrown away",
		str(recovered.get_float(&"audio/sfx")))

	_wipe_settings_files()
	s.free()
	again.free()
	broken.free()
	loaded.free()
	recovered.free()

	_completed += 1     # last line: an abandoned group never gets here


func _wipe_settings_files() -> void:
	for path in ["user://settings.cfg", "user://settings.cfg.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 0010 - saving: exact, atomic, and never fatal when the file is wrong.
func _task_0010_save() -> void:
	Save.delete_run()
	_remove_file(Save.PROFILE_PATH)
	_remove_file(Save.PROFILE_PATH + ".bak")

	expect(not Save.has_run(), "a fresh install has no run")
	expect(Save.read_run().is_empty(), "and reading one gives nothing")
	expect(int(Save.read_profile()["best_night"]) == 0,
		"a missing profile is a fresh profile, not an error")

	# Play a bit of a day, build something, spend something.
	var state := State.create(777)
	Sim.advance(state, 900)
	Resources.add(state, GameData.IRON, 17)
	Resources.pay(state, {GameData.WOOD: 5})
	var built_on := _any_buildable(state)
	Farm.place(state, built_on, {"id": &"gun_tower", "hp": 60})
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS + 500)
	expect(int(state["phase"]) == Phases.NIGHT, "we are mid-night")

	# **The round trip is exact**, which is the whole reason the state is plain
	# data and the save uses var_to_bytes rather than JSON.
	expect(Save.write_run(state), "the run writes")
	expect(Save.has_run(), "and the file is there")
	var loaded := Save.read_run()
	expect(not loaded.is_empty(), "and reads back")
	expect(State.hash_of(loaded) == State.hash_of(state),
		"byte for byte - same resources, same farm, same tick, same RNG",
		"%d vs %d" % [State.hash_of(loaded), State.hash_of(state)])
	expect(Resources.amount(loaded, GameData.IRON) == 17, "resources survived")
	expect(Farm.occupant(loaded, built_on)["id"] == &"gun_tower",
		"the farm survived")
	expect(int(loaded["night_tick"]) == 500, "and the night is where it was",
		str(loaded["night_tick"]))

	# **The night finishes the same way it would have without the interruption.**
	# This is the property that makes saving mid-night safe at all, and it only
	# holds because the RNG stream position is part of the state.
	Sim.advance(state, 3000)
	Sim.advance(loaded, 3000)
	expect(State.hash_of(loaded) == State.hash_of(state),
		"a reloaded night plays out identically to an uninterrupted one",
		"%d vs %d" % [State.hash_of(loaded), State.hash_of(state)])

	# The previous save becomes the backup rather than being thrown away.
	Save.write_run(state)
	expect(FileAccess.file_exists(Save.RUN_PATH + ".bak"),
		"the second save keeps the first as a backup")

	# **A truncated file is refused, not crashed on.**
	var good := FileAccess.open(Save.RUN_PATH, FileAccess.READ)
	var whole := good.get_buffer(good.get_length())
	good.close()

	print("  (the WARNINGs below are deliberate - damaged saves being refused)")
	_write_bytes(Save.RUN_PATH, whole.slice(0, whole.size() / 2))
	expect(Save.read_run().is_empty(), "a truncated save is refused")

	# A flipped bit in the middle is caught by the checksum, not by letting
	# bytes_to_var decode nonsense into a game.
	var bent := whole.duplicate()
	bent[bent.size() - 10] = (int(bent[bent.size() - 10]) + 1) % 256
	_write_bytes(Save.RUN_PATH, bent)
	expect(Save.read_run().is_empty(), "a flipped bit is caught by the checksum")

	# Somebody else's file, and an empty one.
	_write_bytes(Save.RUN_PATH, "not a save at all, just some text".to_ascii_buffer())
	expect(Save.read_run().is_empty(), "a file that is not ours is refused")
	_write_bytes(Save.RUN_PATH, PackedByteArray())
	expect(Save.read_run().is_empty(), "an empty file is refused")

	# A save from a build that does not exist yet is refused rather than
	# half-read into a game that would then be subtly wrong.
	var future := whole.duplicate()
	future[4] = 99
	_write_bytes(Save.RUN_PATH, future)
	expect(Save.read_run().is_empty(), "a save from the future is refused")

	# The profile survives its own round trip.
	var profile := Save.default_profile()
	profile["best_night"] = 7
	profile["runs_won"] = 2
	expect(Save.write_profile(profile), "the profile writes")
	var back := Save.read_profile()
	expect(int(back["best_night"]) == 7 and int(back["runs_won"]) == 2,
		"and reads back", str(back))

	# A profile missing a key this build added gains it rather than breaking.
	expect(Save.write_profile({"version": 1, "best_night": 3}), "an old profile")
	var merged := Save.read_profile()
	expect(int(merged["best_night"]) == 3, "keeps what it had")
	expect(merged.has("unlocks") and merged.has("stats"),
		"and gains the keys this build expects", str(merged.keys()))

	Save.delete_run()
	_remove_file(Save.PROFILE_PATH)
	_remove_file(Save.PROFILE_PATH + ".bak")

	_completed += 1     # last line: an abandoned group never gets here


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 0016 - the wood: swings fell a tree, the ledger gets the wood, and the farm
## grows back.
func _task_0016_gathering() -> void:
	var state := State.create(41)
	var trees := Farm.cells_with(state, &"tree")
	# Counted off the map rather than written down again. The border wood is
	# scenery and it moves when the map does; what matters is that it is a wood.
	expect(trees.size() == _char_count(&"tree"),
		"the wood is the size the map says",
		str(trees.size()))

	var tree: Vector2i = trees[10]
	var node: Dictionary = GameData.GATHERING[&"tree"]
	var swings := int(node["hits"])
	var wood_each := int((node["yield"] as Dictionary)[GameData.WOOD])

	# **A tree has hit points, not a click.** Every swing but the last gives
	# nothing, and the tree is still standing.
	var wood_before := Resources.amount(state, GameData.WOOD)
	for i in swings - 1:
		var got := Gathering.strike(state, tree)
		expect(got.is_empty(), "swing %d gives nothing yet" % (i + 1), str(got))
		expect(Farm.occupant(state, tree)["id"] == &"tree",
			"and the tree is still standing")
	expect(Resources.amount(state, GameData.WOOD) == wood_before,
		"nothing has been paid out yet")

	# The last swing fells it, pays, and leaves a stump.
	var final := Gathering.strike(state, tree)
	expect(int(final.get(GameData.WOOD, 0)) == wood_each,
		"the last swing gives the whole tree", str(final))
	expect(Resources.amount(state, GameData.WOOD) == wood_before + wood_each,
		"through the ledger, not around it",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Farm.occupant(state, tree).get("id", &"") == &"stump",
		"and leaves a stump", str(Farm.occupant(state, tree)))
	expect(Gathering.regrowing(state) == 1, "with one thing coming back")

	# Hitting the stump does nothing: it is scenery, not a second tree.
	expect(Gathering.strike(state, tree).is_empty(), "a stump gives nothing")
	expect(Interact.verb_at(state, tree) == &"", "and offers no verb")

	# **It comes back.** Not a tick early, and as a tree rather than a stump.
	var wait := int(node["regrow_ticks"])
	Sim.advance(state, wait - 1)
	expect(Farm.occupant(state, tree)["id"] == &"stump",
		"still a stump one tick short of the timer")
	Sim.advance(state, 1)
	expect(Farm.occupant(state, tree).get("id", &"") == &"tree",
		"and a tree on the tick the timer says",
		str(Farm.occupant(state, tree)))
	expect(Gathering.regrowing(state) == 0, "with nothing left pending")

	# **The farm cannot be stripped for good.** Chop every tree on it, wait,
	# and the wood is back - all 76 of them.
	var all_trees := Farm.cells_with(state, &"tree")
	var expected_wood := Resources.amount(state, GameData.WOOD) \
		+ all_trees.size() * wood_each
	for cell in all_trees:
		for _i in swings:
			Gathering.strike(state, cell)
	expect(Farm.cells_with(state, &"tree").is_empty(), "the wood is gone")
	expect(Resources.amount(state, GameData.WOOD) == expected_wood,
		"and paid for every tree of it",
		"%d expected, %d held"
		% [expected_wood, Resources.amount(state, GameData.WOOD)])

	Sim.advance(state, wait)
	expect(Farm.cells_with(state, &"tree").size() == all_trees.size(),
		"and after the regrowth delay every one of them is back",
		str(Farm.cells_with(state, &"tree").size()))
	expect(Farm.cells_with(state, &"stump").is_empty(),
		"with no stumps left behind")

	# **A known amount of wood from a known number of ticks.** One tree is
	# `hits` swings of `work_ticks`, driven through the real action machinery
	# rather than by calling strike() directly.
	var timed := State.create(9)
	var target: Vector2i = Farm.cells_with(timed, &"tree")[20]
	var beside := _first_walkable_beside(timed, target)
	expect(beside != Vector2i(-1, -1), "a tree with room to stand beside it")
	if beside != Vector2i(-1, -1):
		var who: Dictionary = timed["player"]
		who["pos"] = [beside.x * Player.SUBTILE + Player.SUBTILE / 2,
			beside.y * Player.SUBTILE + Player.SUBTILE / 2]
		who["facing"] = _face_towards(beside, target)
		(timed["intent"] as Dictionary)["interact"] = true

		var per_tree := int(node["hits"]) * int(node["work_ticks"])
		var before := Resources.amount(timed, GameData.WOOD)
		Sim.advance(timed, per_tree)
		expect(Resources.amount(timed, GameData.WOOD) == before + wood_each,
			"%d ticks of chopping is exactly one tree" % per_tree,
			"%d then %d" % [before, Resources.amount(timed, GameData.WOOD)])

	# **Walking away gives it up.** Half a tree does not stay half chopped.
	var quitter := State.create(3)
	var stand := _first_walkable_beside(quitter,
		Farm.cells_with(quitter, &"tree")[20])
	var chopped: Vector2i = Farm.cells_with(quitter, &"tree")[20]
	if stand != Vector2i(-1, -1):
		var who2: Dictionary = quitter["player"]
		who2["pos"] = [stand.x * Player.SUBTILE + Player.SUBTILE / 2,
			stand.y * Player.SUBTILE + Player.SUBTILE / 2]
		who2["facing"] = _face_towards(stand, chopped)
		(quitter["intent"] as Dictionary)["interact"] = true
		Sim.advance(quitter, int(node["work_ticks"]))
		expect(Gathering.swings_left(quitter, chopped) == swings - 1,
			"one swing landed", str(Gathering.swings_left(quitter, chopped)))
		var move: Array = (quitter["intent"] as Dictionary)["move"]
		move[0] = 1
		Sim.advance(quitter, 2)
		expect(not Player.is_busy(quitter), "walking away stopped the work")

	# **The night does not heal the wood.** A farm that quietly regrew behind a
	# firefight would be the one thing on the night map not about the night.
	var nocturnal := State.create(5)
	var night_tree: Vector2i = Farm.cells_with(nocturnal, &"tree")[5]
	for _i in swings:
		Gathering.strike(nocturnal, night_tree)
	Phases.begin_preparation(nocturnal)
	Sim.advance(nocturnal, GameData.PREPARATION_TICKS)
	var pending_at_dusk := Gathering.regrowing(nocturnal)
	Sim.advance(nocturnal, wait)
	expect(Gathering.regrowing(nocturnal) == pending_at_dusk,
		"a whole night of it moved nothing along",
		"%d then %d" % [pending_at_dusk, Gathering.regrowing(nocturnal)])

	# Something built on the cell keeps it. The farm gives up on that one
	# rather than knocking a tower over to put a tree back.
	var built := State.create(7)
	var taken: Vector2i = Farm.cells_with(built, &"tree")[30]
	for _i in swings:
		Gathering.strike(built, taken)
	Farm.remove(built, taken)                  # clear the stump
	Farm.place(built, taken, {"id": &"gun_tower"})
	Sim.advance(built, wait + 5)
	expect(Farm.occupant(built, taken)["id"] == &"gun_tower",
		"a tower on the cell is not replaced by the tree",
		str(Farm.occupant(built, taken)))

	_completed += 1     # last line: an abandoned group never gets here


func _first_walkable_beside(state: Dictionary, cell: Vector2i) -> Vector2i:
	for step in Grid.STEPS:
		var n: Vector2i = cell + step
		if Grid.in_bounds(n) and Farm.walkable(state, n):
			return n
	return Vector2i(-1, -1)


func _face_towards(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var d: Vector2i = to_cell - from_cell
	if d.y > 0:
		return Player.SOUTH
	if d.y < 0:
		return Player.NORTH
	if d.x < 0:
		return Player.WEST
	return Player.EAST


## 0017 - stone: the same machine with different rows, and a lawn you can clear
## for good.
func _task_0017_stone() -> void:
	var state := State.create(61)

	# Two sources, and they behave differently on purpose.
	var loose := Farm.cells_with(state, &"rock")
	var seams := Farm.cells_with(state, &"seam")
	expect(loose.size() == _char_count(&"rock"),
		"the boulders on the lawn are the ones the map drew", str(loose.size()))
	expect(seams.size() == 5, "five seams in the rock face", str(seams.size()))

	for cell in seams:
		expect(Farm.terrain_at(state, cell) == Farm.Terrain.ROCK,
			"a seam is in the rock face, not on the grass", str(cell))
	for cell in loose:
		expect(Farm.terrain_at(state, cell) == Farm.Terrain.GRASS,
			"and a boulder is on the grass", str(cell))

	# Stone arrives through the ledger, exactly as wood does.
	var rock_data: Dictionary = GameData.GATHERING[&"rock"]
	var per_rock := int((rock_data["yield"] as Dictionary)[GameData.STONE])
	var boulder: Vector2i = loose[0]
	var before := Resources.amount(state, GameData.STONE)
	for i in int(rock_data["hits"]) - 1:
		expect(Gathering.strike(state, boulder).is_empty(),
			"boulder swing %d gives nothing yet" % (i + 1))
	Gathering.strike(state, boulder)
	expect(Resources.amount(state, GameData.STONE) == before + per_rock,
		"and the last swing pays the whole boulder",
		"%d then %d" % [before, Resources.amount(state, GameData.STONE)])

	# **A cleared boulder does not come back, and the cell is yours.** That is
	# the reward for tidying the lawn.
	expect(Farm.occupant(state, boulder).is_empty(), "the cell is empty")
	expect(Farm.buildable(state, boulder), "and buildable now")
	Sim.advance(state, int(GameData.GATHERING[&"seam"]["regrow_ticks"]) * 3)
	expect(Farm.occupant(state, boulder).is_empty(),
		"and three regrowth delays later it is still empty",
		str(Farm.occupant(state, boulder)))

	# **The seam does come back**, which is what keeps stone infinite.
	var seam_data: Dictionary = GameData.GATHERING[&"seam"]
	var per_seam := int((seam_data["yield"] as Dictionary)[GameData.STONE])
	var seam: Vector2i = seams[0]
	before = Resources.amount(state, GameData.STONE)
	for _i in int(seam_data["hits"]):
		Gathering.strike(state, seam)
	expect(Resources.amount(state, GameData.STONE) == before + per_seam,
		"a seam pays %d stone" % per_seam,
		str(Resources.amount(state, GameData.STONE) - before))
	expect(Farm.occupant(state, seam).is_empty(), "and is worked out")
	Sim.advance(state, int(seam_data["regrow_ticks"]))
	expect(Farm.occupant(state, seam).get("id", &"") == &"seam",
		"until the rock face puts it back", str(Farm.occupant(state, seam)))

	# **The farm cannot be stripped of stone**, even after every boulder is
	# gone for ever: the rock face alone keeps paying.
	var stripped := State.create(62)
	for cell in Farm.cells_with(stripped, &"rock"):
		for _i in int(rock_data["hits"]):
			Gathering.strike(stripped, cell)
	expect(Farm.cells_with(stripped, &"rock").is_empty(),
		"every boulder cleared")
	var stone_before := Resources.amount(stripped, GameData.STONE)
	for _round in 3:
		for cell in Farm.cells_with(stripped, &"seam"):
			for _i in int(seam_data["hits"]):
				Gathering.strike(stripped, cell)
		Sim.advance(stripped, int(seam_data["regrow_ticks"]))
	expect(Resources.amount(stripped, GameData.STONE)
		== stone_before + 3 * seams.size() * per_seam,
		"and three cycles of the rock face paid %d more"
		% (3 * seams.size() * per_seam),
		str(Resources.amount(stripped, GameData.STONE) - stone_before))

	# **Ore comes back too**, which nothing checked until this task: it lives
	# in the rock face, and the rock face is not buildable, so regrowth going
	# through the player's own placement rule meant it never returned.
	var ore_data: Dictionary = GameData.GATHERING[&"ore"]
	var vein: Vector2i = Farm.cells_with(state, &"ore")[0]
	var iron_before := Resources.amount(state, GameData.IRON)
	for _i in int(ore_data["hits"]):
		Gathering.strike(state, vein)
	expect(Resources.amount(state, GameData.IRON) > iron_before,
		"a vein pays iron")
	expect(Farm.occupant(state, vein).is_empty(), "and is worked out")
	Sim.advance(state, int(ore_data["regrow_ticks"]))
	expect(Farm.occupant(state, vein).get("id", &"") == &"ore",
		"and the rock face puts it back", str(Farm.occupant(state, vein)))

	# A seam is mined, like ore, and offers the verb to prove it.
	expect(Interact.verb_at(state, seams[1]) == &"mine",
		"a seam offers mining")
	expect(Interact.verb_at(state, Farm.cells_with(state, &"ore")[0]) == &"mine",
		"and so does ore")

	_completed += 1     # last line: an abandoned group never gets here


## 0018 - wheat: till, plant, wait, harvest, and a night that changes nothing.
func _task_0018_wheat() -> void:
	var state := State.create(71)
	# **Asked for by name.** Since task 0028 there are three crops and a new
	# farm starts on carrot, the cheapest; a group about wheat has to say wheat
	# rather than lean on whichever one happens to be the default.
	Farming.select_seed(state, GameData.WHEAT)
	var field := Farm.cells_of(state, Farm.Terrain.SOIL)
	expect(field.size() == 48, "there is a field", str(field.size()))

	var plot: Vector2i = field[0]
	var data: Dictionary = GameData.CROPS[GameData.WHEAT]
	var grow_ticks := int(data["growth_ticks"])

	# **Four verbs, and the cell says which one it is offering.** "farm" would
	# have been one word for four different keypresses.
	expect(Interact.verb_at(state, plot) == &"till", "untouched soil offers a till")
	Interact.complete(state, plot, &"till")
	expect(Farming.is_tilled(state, plot), "and tilling turns it over")
	expect(Interact.verb_at(state, plot) == &"plant", "turned earth offers a seed")

	var money_before := Resources.amount(state, GameData.MONEY)
	Interact.complete(state, plot, &"plant")
	expect(Farming.crop_on(state, plot) == GameData.WHEAT, "which goes in")
	expect(Resources.amount(state, GameData.MONEY)
		== money_before - int(data["seed_cost"]),
		"and is paid for", str(Resources.amount(state, GameData.MONEY)))
	expect(Interact.verb_at(state, plot) == &"",
		"a growing crop offers nothing - there is nothing useful to do yet")

	# It grows, in stages, and only reaches the last one when it is ready.
	expect(Farming.stage(state, plot) == 0, "it starts at stage 0")
	Sim.advance(state, grow_ticks / 2)
	var midway := Farming.stage(state, plot)
	expect(midway > 0 and midway < int(data["stages"]) - 1,
		"halfway through it is halfway through", str(midway))
	expect(not Farming.is_ready(state, plot), "and not ready")

	Sim.advance(state, grow_ticks - grow_ticks / 2)
	expect(Farming.is_ready(state, plot), "on the tick the lever says, it is")
	expect(Farming.stage(state, plot) == int(data["stages"]) - 1,
		"at its last stage", str(Farming.stage(state, plot)))
	expect(Interact.verb_at(state, plot) == &"harvest", "and offers a harvest")

	# Harvest pays through the ledger and leaves the ground ready for the next.
	var wheat_before := Resources.amount(state, GameData.WHEAT)
	Interact.complete(state, plot, &"harvest")
	expect(Resources.amount(state, GameData.WHEAT)
		== wheat_before + int(data["yield"]),
		"harvesting pays the yield",
		str(Resources.amount(state, GameData.WHEAT)))
	expect(Farming.is_tilled(state, plot), "and leaves the ground turned over")
	expect(Farming.crop_on(state, plot) == &"", "with nothing in it")
	expect(Interact.verb_at(state, plot) == &"plant", "ready for the next seed")

	# **A night changes nothing, and the morning picks up where it left off.**
	# The done-when of this task, and the reason a plot is plain data.
	var overnight := State.create(72)
	Farming.select_seed(overnight, GameData.WHEAT)
	var bed: Vector2i = Farm.cells_of(overnight, Farm.Terrain.SOIL)[3]
	Interact.complete(overnight, bed, &"till")
	Interact.complete(overnight, bed, &"plant")
	Sim.advance(overnight, 300)
	var growth_at_dusk := int(Farming.plot(overnight, bed)["growth"])
	expect(growth_at_dusk == 300, "it grew all afternoon", str(growth_at_dusk))

	Phases.begin_preparation(overnight)
	Sim.advance(overnight, GameData.PREPARATION_TICKS + 2000)
	expect(int(Farming.plot(overnight, bed)["growth"]) == growth_at_dusk,
		"and not one tick during the whole night",
		str(Farming.plot(overnight, bed)["growth"]))
	expect(Farming.crop_on(overnight, bed) == GameData.WHEAT,
		"the crop is still in the ground")

	Phases.enter_result(overnight, true)
	Phases.begin_day(overnight)
	Sim.advance(overnight, 100)
	expect(int(Farming.plot(overnight, bed)["growth"]) == growth_at_dusk + 100,
		"and in the morning it carries on from exactly where it was",
		str(Farming.plot(overnight, bed)["growth"]))

	# No money, no seed, and no half-planted tile.
	var broke := State.create(73)
	var dirt: Vector2i = Farm.cells_of(broke, Farm.Terrain.SOIL)[0]
	Resources.spend(broke, GameData.MONEY,
		Resources.amount(broke, GameData.MONEY))
	Interact.complete(broke, dirt, &"till")
	Interact.complete(broke, dirt, &"plant")
	expect(Farming.crop_on(broke, dirt) == &"",
		"planting with no money plants nothing")
	expect(Farming.is_tilled(broke, dirt), "and leaves the tilled ground alone")

	# A whole field, because one plot is not a field.
	var farmed := State.create(74)
	Farming.select_seed(farmed, GameData.WHEAT)
	Resources.add(farmed, GameData.MONEY, 500)
	for cell in Farm.cells_of(farmed, Farm.Terrain.SOIL):
		Interact.complete(farmed, cell, &"till")
		Interact.complete(farmed, cell, &"plant")
	var counts := Farming.counts(farmed)
	expect(int(counts["planted"]) == 48, "forty-eight plots planted",
		str(counts))
	Sim.advance(farmed, grow_ticks)
	expect(int(Farming.counts(farmed)["ready"]) == 48,
		"and all of them come up together",
		str(Farming.counts(farmed)))
	var before_harvest := Resources.amount(farmed, GameData.WHEAT)
	for cell in Farm.cells_of(farmed, Farm.Terrain.SOIL):
		Interact.complete(farmed, cell, &"harvest")
	expect(Resources.amount(farmed, GameData.WHEAT)
		== before_harvest + 48 * int(data["yield"]),
		"paying the whole field", str(Resources.amount(farmed, GameData.WHEAT)))

	# You can walk across your own field, and a zombie will be able to too.
	expect(Farm.walkable(farmed, Farm.cells_of(farmed, Farm.Terrain.SOIL)[10]),
		"a planted tile is still ground, not furniture")

	_completed += 1     # last line: an abandoned group never gets here


## Somewhere on the farm nothing is standing and something could be.
##
## Tests ask for one rather than naming a cell, because a named cell is a test
## that breaks whenever the map gains a building - which is a failure that
## teaches nothing about the thing being tested.
## The ground and what is standing on it, without the counters that describe
## how it got that way.
func _farm_hash(state: Dictionary) -> int:
	return State.hash_of({
		"terrain": state["terrain"],
		"occupants": state["occupants"],
	})


func _any_buildable(state: Dictionary) -> Vector2i:
	for idx in Grid.CELLS:
		var cell := Grid.cell(idx)
		if Farm.buildable(state, cell) and not Farming.is_tilled(state, cell):
			return cell
	return Vector2i(-1, -1)


## 0019 - the workshop: wood and stone stop being things you sell.
func _task_0019_workshop() -> void:
	var state := State.create(81)

	var benches := Farm.cells_with(state, &"workshop")
	expect(benches.size() == 4, "the farm comes with a workshop",
		str(benches.size()))
	var bench: Vector2i = benches[0]
	expect(Interact.verb_at(state, bench) == &"craft",
		"and it offers crafting")

	var recipe: Dictionary = GameData.RECIPES[&"barricade_kit"]
	var inputs: Dictionary = recipe["inputs"]
	var ticks := int(recipe["ticks"])

	# **The inputs go in at the start.** That is what makes cancelling a
	# decision rather than a free undo.
	Resources.add(state, GameData.WOOD, 20)
	Resources.add(state, GameData.STONE, 20)
	var wood_before := Resources.amount(state, GameData.WOOD)
	var stone_before := Resources.amount(state, GameData.STONE)

	expect(Crafting.can_start(state, bench, &"barricade_kit"),
		"an affordable recipe can be started")
	expect(Crafting.start(state, bench, &"barricade_kit"), "and starting works")
	expect(Resources.amount(state, GameData.WOOD)
		== wood_before - int(inputs[GameData.WOOD]),
		"the wood is gone immediately",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Resources.amount(state, GameData.STONE)
		== stone_before - int(inputs[GameData.STONE]),
		"and so is the stone")
	expect(Crafting.busy(state, bench), "the bench is busy")
	expect(Crafting.kits(state, &"barricade") == 0, "and nothing is made yet")

	# One recipe at a time until task 0037.
	expect(not Crafting.can_start(state, bench, &"barricade_kit"),
		"a busy bench takes no second job")

	# **It finishes on the tick the recipe says**, and it runs whether or not
	# anybody is watching it.
	Sim.advance(state, ticks - 1)
	expect(Crafting.kits(state, &"barricade") == 0,
		"one tick short of the recipe, nothing")
	Sim.advance(state, 1)
	expect(Crafting.kits(state, &"barricade") == 1,
		"and on the tick, a barricade",
		str(Crafting.kits(state, &"barricade")))
	expect(not Crafting.busy(state, bench), "the bench is free again")
	expect(Resources.amount(state, GameData.WOOD)
		== wood_before - int(inputs[GameData.WOOD]),
		"and nothing came back that should not have")

	# **A kit is not a resource.** It has to be somewhere build mode can find
	# it, and nowhere the shop or the HUD will.
	expect(not GameData.RESOURCES.has(&"barricade"),
		"a barricade is not in the resource table")
	expect(Resources.amount(state, GameData.WOOD) >= 0, "and wood still is")
	expect(Crafting.take_kit(state, &"barricade"), "a kit can be taken")
	expect(Crafting.kits(state, &"barricade") == 0, "leaving none")
	expect(not Crafting.take_kit(state, &"barricade"),
		"and taking one that is not there is refused, not negative")

	# **Cancelling refunds nothing and duplicates nothing.**
	var wood_at_start := Resources.amount(state, GameData.WOOD)
	Crafting.start(state, bench, &"barricade_kit")
	var wood_after_start := Resources.amount(state, GameData.WOOD)
	Sim.advance(state, ticks / 2)
	expect(Crafting.cancel(state, bench), "a job can be given up")
	expect(Resources.amount(state, GameData.WOOD) == wood_after_start,
		"and nothing comes back",
		"%d at start, %d after cancelling"
		% [wood_at_start, Resources.amount(state, GameData.WOOD)])
	Sim.advance(state, ticks * 2)
	expect(Crafting.kits(state, &"barricade") == 0,
		"nor does the cancelled job quietly finish later")
	expect(not Crafting.busy(state, bench), "the bench is free")

	# **A recipe you cannot afford is refused, not hidden.** A menu that grows
	# as you get richer teaches nothing about what to go and get.
	var broke := State.create(82)
	var poor_bench: Vector2i = Farm.cells_with(broke, &"workshop")[0]
	Resources.spend(broke, GameData.WOOD,
		Resources.amount(broke, GameData.WOOD))
	expect(not Crafting.can_start(broke, poor_bench, &"barricade_kit"),
		"with no wood it cannot be started")
	expect(Crafting.recipes_at(&"workshop").has(&"barricade_kit"),
		"but it is still on the list")
	var short := Crafting.missing(broke, &"barricade_kit")
	expect(short.has(GameData.WOOD) and not short.has(GameData.STONE),
		"and the shortfall names the wood and not the stone", str(short))
	# **Queuing it anyway is allowed, and costs nothing.** This asserted the
	# opposite until task 0037: inputs used to be taken the moment a job was
	# started, so starting one you could not afford had to be refused. Now they
	# are taken when an item reaches the front, which means a player can line
	# up five barricades and go and fetch the wood - and an item that cannot be
	# paid for waits rather than being thrown away for being early.
	var purse := Resources.amount(broke, GameData.STONE)
	expect(Crafting.start(broke, poor_bench, &"barricade_kit"),
		"queuing it anyway is allowed")
	expect(Crafting.busy(broke, poor_bench), "and the bench has it lined up")
	expect(Crafting.is_stalled(broke, poor_bench),
		"waiting on materials rather than on time")
	expect(Resources.amount(broke, GameData.STONE) == purse,
		"and nothing has been taken for it",
		str(Resources.amount(broke, GameData.STONE)))
	Sim.advance(broke, 60)
	expect(Crafting.is_stalled(broke, poor_bench),
		"it is still waiting a couple of seconds later")
	expect(Resources.amount(broke, GameData.STONE) == purse,
		"and still nothing taken")

	Resources.gain(broke, {GameData.WOOD: 20})
	Sim.advance(broke, 2)
	expect(not Crafting.is_stalled(broke, poor_bench),
		"the wood arriving starts it")
	expect(Resources.amount(broke, GameData.WOOD) < 20,
		"and that is when the wood goes in",
		str(Resources.amount(broke, GameData.WOOD)))
	Crafting.cancel_all(broke, poor_bench)

	# A job belongs to its station, so the press and the kitchen need no new
	# machinery - and neither would a second workshop.
	expect(not Crafting.can_start(state, Farm.cells_with(state, &"shop")[0],
		&"barricade_kit"),
		"a recipe cannot be made at the wrong station")

	# A recipe whose output is a resource goes to the ledger instead.
	var presser := State.create(83)
	var press_recipe: Dictionary = GameData.RECIPES[&"press_oil"]
	expect(GameData.RESOURCES.has((press_recipe["output"] as Dictionary).keys()[0]),
		"the press makes a resource, not a kit")

	_completed += 1     # last line: an abandoned group never gets here


## 0020 - the stall: selling is how a morning becomes a tower, and buying is
## always a bad deal.
func _task_0020_shop() -> void:
	var state := State.create(91)
	var stall: Vector2i = Farm.cells_with(state, &"shop")[0]

	expect(Interact.verb_at(state, stall) == &"trade", "the stall offers trade")
	expect(not Shop.is_open(state), "and nothing is open to begin with")
	Interact.complete(state, stall, &"trade")
	expect(Shop.is_open(state), "interacting opens it")

	# **A panel takes the keys.** Walking away from a stall you are standing at
	# would be a way to shop while running.
	var before_cell := Player.cell(state)
	var move: Array = (state["intent"] as Dictionary)["move"]
	move[0] = 1
	Sim.advance(state, 30)
	expect(Player.cell(state) == before_cell,
		"the player does not wander off while shopping",
		"%s to %s" % [before_cell, Player.cell(state)])
	expect(Shop.is_open(state), "and the panel is still up")

	# **The stall pauses the day, and this used to assert the opposite.**
	#
	# Task 0020 read `design.md` section 13 - a farm that runs itself - as
	# meaning the shop must not stop the world, and asserted that the wheat
	# kept growing while the player haggled. Task 0039 asks for the reverse in
	# as many words: "time does not pass in menus", with a done-when naming the
	# shop panel.
	#
	# 0039 wins, and it is the better reading: section 13 is about the farm
	# running while you are *doing something else on the farm*, which is what
	# task 0038 measures. Standing at a stall talking to a shopkeeper is not
	# somewhere else on the farm, it is a conversation - and a player who
	# opened the shop to think and came back to a dead field would learn to
	# think somewhere else. The inventory of task 0036 is the other half of
	# the distinction: a glance at your own pockets does not stop anything.
	var plot: Vector2i = Farm.cells_of(state, Farm.Terrain.SOIL)[0]
	Interact.complete(state, plot, &"till")
	Interact.complete(state, plot, &"plant")
	var growth_before := int(Farming.plot(state, plot)["growth"])
	var clock_before := int(state["day_tick"])
	Sim.advance(state, 60)
	expect(int(state["day_tick"]) == clock_before,
		"the clock stops while the player haggles",
		str(int(state["day_tick"]) - clock_before))
	expect(int(Farming.plot(state, plot)["growth"]) == growth_before,
		"and so does the wheat",
		str(Farming.plot(state, plot)["growth"]))

	move[0] = 0
	(state["intent"] as Dictionary)["cancel"] = true
	Sim.advance(state, 1)
	expect(not Shop.is_open(state), "cancel closes it")

	# **Selling ten wood pays exactly ten times the listed price.**
	var trader := State.create(92)
	Resources.add(trader, GameData.WOOD, 10)
	var wood_price := Shop.sell_price(GameData.WOOD)
	var money_before := Resources.amount(trader, GameData.MONEY)
	var wood_before := Resources.amount(trader, GameData.WOOD)
	var paid := Shop.sell(trader, GameData.WOOD, 10)
	expect(paid == wood_price * 10, "ten wood pays ten times the price",
		"%d for %d each" % [paid, wood_price])
	expect(Resources.amount(trader, GameData.MONEY) == money_before + paid,
		"through the ledger")
	expect(Resources.amount(trader, GameData.WOOD) == wood_before - 10,
		"and the wood is gone")

	# **All or nothing.** A shop that quietly sold what it could would empty
	# your bag when you fumbled a number.
	Resources.spend(trader, GameData.WOOD,
		Resources.amount(trader, GameData.WOOD))
	Resources.add(trader, GameData.WOOD, 4)
	var hash_before := State.hash_of(trader)
	expect(Shop.sell(trader, GameData.WOOD, 10) == 0,
		"selling more than you have sells none of it")
	expect(State.hash_of(trader) == hash_before, "and changes nothing at all")
	expect(Shop.sell_all(trader, GameData.WOOD) == wood_price * 4,
		"while sell-all sells what is there")

	# Money does not sell for money, and neither does energy.
	expect(not Shop.sellable().has(GameData.MONEY), "money is not sellable")
	expect(not Shop.sellable().has(GameData.ENERGY), "nor is energy")
	expect(Shop.sell(trader, GameData.MONEY, 1) == 0,
		"and trying is refused")

	# **Buying is always worse than going and getting it.** At every price, or
	# money quietly replaces playing the game.
	for id in Shop.sellable():
		expect(Shop.buy_price(id) > Shop.sell_price(id),
			"%s costs more to buy than it pays to sell" % id,
			"%d buy, %d sell" % [Shop.buy_price(id), Shop.sell_price(id)])

	var buyer := State.create(93)
	Resources.add(buyer, GameData.MONEY, 1000)
	var stone_before := Resources.amount(buyer, GameData.STONE)
	var cost := Shop.buy_price(GameData.STONE) * 5
	var purse := Resources.amount(buyer, GameData.MONEY)
	expect(Shop.buy(buyer, GameData.STONE, 5), "five stone can be bought")
	expect(Resources.amount(buyer, GameData.STONE) == stone_before + 5,
		"and arrive")
	expect(Resources.amount(buyer, GameData.MONEY) == purse - cost,
		"at the price on the label",
		str(Resources.amount(buyer, GameData.MONEY)))

	# **The shop refuses rather than going negative.**
	var broke := State.create(94)
	Resources.spend(broke, GameData.MONEY,
		Resources.amount(broke, GameData.MONEY))
	var broke_hash := State.hash_of(broke)
	expect(not Shop.buy(broke, GameData.IRON, 1),
		"with no money nothing is bought")
	expect(State.hash_of(broke) == broke_hash, "and nothing moves")
	expect(Resources.amount(broke, GameData.MONEY) == 0,
		"least of all the money", str(Resources.amount(broke, GameData.MONEY)))

	# Buy then sell always loses. The round trip has to be a loss at every
	# price or there is a money printer on the farm.
	for id in Shop.buyable():
		expect(Shop.buy_price(id) > Shop.sell_price(id),
			"buying %s and selling it back loses money" % id)

	_completed += 1     # last line: an abandoned group never gets here


## 0021 - the night is asked for, not taken. The HUD writes an intent and the
## rules decide, so the keyboard, the mouse and the autoplayer share a road.
func _task_0021_night_intent() -> void:
	var state := State.create(101)
	expect(int(state["phase"]) == Phases.DAY, "it is the day")

	(state["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(state, 1)
	expect(int(state["phase"]) == Phases.PREPARATION,
		"asking for the night gets it", Phases.name_of(int(state["phase"])))
	expect(not bool((state["intent"] as Dictionary)["begin_night"]),
		"and the asking is consumed, not remembered")

	# Asking again from the wrong phase is refused, the way every transition is.
	print("  (the ERROR line below is deliberate - a refused transition)")
	(state["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(state, 1)
	expect(int(state["phase"]) == Phases.PREPARATION,
		"asking twice changes nothing")

	# Dusk asks and does not press. The whole promise of design.md section 4.
	var evening := State.create(102)
	Sim.advance(evening, GameData.DUSK_AT_TICK + 600)
	expect(Phases.is_dusk(evening), "it is past dusk")
	expect(int(evening["phase"]) == Phases.DAY,
		"and the day has still not ended itself",
		Phases.name_of(int(evening["phase"])))

	_completed += 1     # last line: an abandoned group never gets here


## 0022 - the same farm, a different world. Nothing moves but the light and
## what the farm will let you do.
func _task_0022_reality() -> void:
	var state := State.create(111)

	# Build something and note the whole farm, so that "nothing moved" can be
	# checked rather than eyeballed.
	var spot := _any_buildable(state)
	Farm.place(state, spot, {"id": &"gun_tower", "hp": 60})
	var tilled: Vector2i = Farm.cells_of(state, Farm.Terrain.SOIL)[0]
	Interact.complete(state, tilled, &"till")
	Interact.complete(state, tilled, &"plant")
	var farm_by_day := State.hash_of({
		"terrain": state["terrain"],
		"occupants": state["occupants"],
		"plots": state["plots"],
	})

	# **The switch is a transition, not a new world.**
	expect(Phases.begin_preparation(state), "the day can end")
	expect(int(state["phase"]) == Phases.PREPARATION, "into preparation")
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(int(state["phase"]) == Phases.NIGHT, "and then the night")

	expect(Farm.occupant(state, spot)["id"] == &"gun_tower",
		"the tower built by day is in the same cell by night")
	expect(State.hash_of({
		"terrain": state["terrain"],
		"occupants": state["occupants"],
		"plots": state["plots"],
	}) == farm_by_day, "and the whole farm is the farm it was")

	# **The farm is asleep after dark.** The verbs of the daylight are put away,
	# so nothing offers to be chopped while a wave is coming in.
	var tree: Vector2i = Farm.cells_with(state, &"tree")[10]
	expect(Interact.verb_at(state, tree) == &"",
		"a tree offers nothing at night", str(Interact.verb_at(state, tree)))
	expect(Interact.verb_at(state, Farm.cells_with(state, &"shop")[0]) == &"",
		"and neither does the stall")
	expect(Interact.verb_at(state, tilled) == &"", "nor the field")

	# But the player is still out there, and still walks.
	var before := Player.cell(state)
	var move: Array = (state["intent"] as Dictionary)["move"]
	move[0] = 1
	Sim.advance(state, 40)
	move[0] = 0
	expect(Player.cell(state) != before,
		"the player walks their defences at night",
		"%s to %s" % [before, Player.cell(state)])

	# A panel does not survive the sunset.
	var shopper := State.create(112)
	Shop.open(shopper)
	expect(Shop.is_open(shopper), "the market is open")
	Phases.begin_preparation(shopper)
	expect(not Shop.is_open(shopper), "and closes with the day")

	# **Switching twice gives back the same day, one number further on.**
	var cycled := State.create(113)
	var morning := State.copy(cycled)
	Phases.begin_preparation(cycled)
	Sim.advance(cycled, GameData.PREPARATION_TICKS + 500)
	Phases.enter_result(cycled, true)
	Phases.begin_day(cycled)

	expect(int(cycled["day"]) == int(morning["day"]) + 1,
		"the day counter moved once", str(cycled["day"]))
	for key in ["terrain", "occupants", "plots", "held"]:
		expect(State.hash_of({key: cycled[key]})
			== State.hash_of({key: morning[key]}),
			"and %s came back untouched" % key)

	# Daylight puts the verbs back.
	expect(Interact.verb_at(cycled, Farm.cells_with(cycled, &"tree")[10])
		== &"chop", "and in the morning there are trees to chop again")

	_completed += 1     # last line: an abandoned group never gets here


## 0023 - build mode: what goes down, where, at what price, and what comes back.
func _task_0023_building() -> void:
	var state := State.create(121)
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200,
		GameData.IRON: 200, GameData.GUNPOWDER: 50, GameData.OIL: 50})

	# **A structure cannot go on water, on the rock face, or on something.**
	var pond: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
	var cliff: Vector2i = Farm.cells_of(state, Farm.Terrain.ROCK)[0]
	var house: Vector2i = Farm.cells_with(state, &"house")[0]
	expect(Building.why_not(state, &"wall", pond) == "in the water",
		"not in the pond", Building.why_not(state, &"wall", pond))
	expect(Building.why_not(state, &"wall", cliff) == "on the rock face",
		"not on the cliff", Building.why_not(state, &"wall", cliff))
	expect(Building.why_not(state, &"wall", house) == "on the house",
		"not on the house", Building.why_not(state, &"wall", house))
	expect(not Building.place(state, &"wall", pond), "and placing is refused")

	# On grass it goes, and the cost comes out of the ledger.
	var spot := _any_buildable(state)
	var cost := Building.cost_of(&"gun_tower")
	var wood_before := Resources.amount(state, GameData.WOOD)
	var iron_before := Resources.amount(state, GameData.IRON)
	expect(Building.can_place(state, &"gun_tower", spot), "grass will take it")
	expect(Building.place(state, &"gun_tower", spot), "and it goes down")
	expect(Farm.occupant(state, spot)["id"] == &"gun_tower", "it is there")
	expect(int(Farm.occupant(state, spot)["hp"])
		== int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"]),
		"with its hit points")
	expect(Resources.amount(state, GameData.WOOD)
		== wood_before - int(cost[GameData.WOOD]), "the wood was paid")
	expect(Resources.amount(state, GameData.IRON)
		== iron_before - int(cost[GameData.IRON]), "and the iron")
	expect(not Building.place(state, &"wall", spot),
		"a second thing cannot stack on it")

	# **Place and sell in a loop is always a loss**, never a money printer.
	var before_loop := State.hash_of(state)
	var loop_cell := _any_buildable(state)
	for _i in 5:
		Building.place(state, &"wall", loop_cell)
		Building.sell(state, loop_cell)
	expect(Resources.amount(state, GameData.STONE) < 200,
		"five build-and-sell cycles cost stone",
		str(Resources.amount(state, GameData.STONE)))
	expect(Farm.occupant(state, loop_cell).is_empty(),
		"and the cell is empty at the end")
	expect(before_loop != State.hash_of(state), "the loop was not free")

	# The refund is a fraction, rounded down so the round trip always loses.
	var refund_cell := _any_buildable(state)
	Building.place(state, &"wall", refund_cell)
	var stone_before := Resources.amount(state, GameData.STONE)
	var back := Building.sell(state, refund_cell)
	expect(int(back.get(GameData.STONE, 0))
		== int(floor(float(Building.cost_of(&"wall")[GameData.STONE])
			* GameData.SELL_BACK_FRACTION)),
		"the refund is the fraction, rounded down", str(back))
	expect(Resources.amount(state, GameData.STONE) > stone_before,
		"and it arrives through the ledger")
	for id in Building.catalogue(state):
		var full := Building.cost_of(id)
		var given := Building.refund_for_cost(full)
		for res in full:
			expect(int(given.get(res, 0)) < int(full[res]),
				"selling a %s back never returns all its %s" % [id, res])

	# **Nothing of the farm's is the player's to sell.**
	expect(Building.sell(state, Farm.cells_with(state, &"tree")[0]).is_empty(),
		"a tree cannot be sold back")
	expect(Building.sell(state, house).is_empty(), "nor the house")
	expect(Farm.cells_with(state, &"house").size() == 9, "which is still there")

	# **A kit is the cost paid early**, and it is spent instead of the ledger.
	var banker := State.create(122)
	Resources.gain(banker, {GameData.WOOD: 100, GameData.STONE: 100})
	var bench: Vector2i = Farm.cells_with(banker, &"workshop")[0]
	Crafting.start(banker, bench, &"wall_kit")
	Sim.advance(banker, int((GameData.RECIPES[&"wall_kit"] as Dictionary)["ticks"]))
	expect(Crafting.kits(banker, &"wall") == 1, "a wall is banked")
	var stone_banked := Resources.amount(banker, GameData.STONE)
	var kit_cell := _any_buildable(banker)
	expect(Building.place(banker, &"wall", kit_cell), "and goes down")
	expect(Crafting.kits(banker, &"wall") == 0, "spending the kit")
	expect(Resources.amount(banker, GameData.STONE) == stone_banked,
		"and not the ledger", str(Resources.amount(banker, GameData.STONE)))

	# **Night takes only what says it may.** That is what makes the barricade
	# the emergency answer rather than a cheaper wall.
	var nightly := State.create(123)
	Resources.gain(nightly, {GameData.WOOD: 100, GameData.STONE: 100})
	Phases.begin_preparation(nightly)
	expect(Building.allowed_in_phase(nightly, &"wall"),
		"preparation takes anything")
	Sim.advance(nightly, GameData.PREPARATION_TICKS)
	expect(int(nightly["phase"]) == Phases.NIGHT, "and then it is night")
	_park_the_waves(nightly)
	expect(not Building.allowed_in_phase(nightly, &"wall"),
		"a wall cannot go up mid-wave")
	expect(Building.allowed_in_phase(nightly, &"barricade"),
		"but a barricade can")
	expect(Building.why_not(nightly, &"wall", _any_buildable(nightly))
		== "not at night", "and it says why")

	# A barricade expires rather than quietly becoming a wall.
	var quick := _any_buildable(nightly)
	expect(Building.place(nightly, &"barricade", quick), "one goes down")
	var life := int((GameData.DEFENCES[&"barricade"] as Dictionary)["lifetime_ticks"])
	Sim.advance(nightly, life - 2)
	expect(Farm.occupant(nightly, quick).get("id", &"") == &"barricade",
		"and holds for its lifetime")
	Sim.advance(nightly, 4)
	expect(Farm.occupant(nightly, quick).is_empty(),
		"then takes itself away", str(Farm.occupant(nightly, quick)))

	# Through the intent, which is the road the autoplayer takes.
	var driven := State.create(124)
	Resources.gain(driven, {GameData.WOOD: 100, GameData.IRON: 100})
	var target := _any_buildable(driven)
	Building.select(driven, &"gun_tower")
	var intent: Dictionary = driven["intent"]
	intent["build_cell"] = [target.x, target.y]
	intent["build_place"] = true
	Sim.advance(driven, 1)
	expect(Farm.occupant(driven, target).get("id", &"") == &"gun_tower",
		"writing the intent builds it", str(Farm.occupant(driven, target)))
	intent["build_cell"] = [target.x, target.y]
	intent["build_sell"] = true
	Sim.advance(driven, 1)
	expect(Farm.occupant(driven, target).is_empty(),
		"and writing the other one takes it back up")

	_completed += 1     # last line: an abandoned group never gets here


## 0024 - the gun tower: it reloads, it picks the right target, and it puts
## something in the air rather than subtracting a number.
func _task_0024_tower() -> void:
	var entry: Dictionary = GameData.DEFENCES[&"gun_tower"]

	# **Nothing during the day.** A tower is furniture until the sun goes down.
	var daytime := _night_with_tower(false)
	var tower_cell: Vector2i = daytime["tower"]
	var state: Dictionary = daytime["state"]
	Entities.spawn(state, &"walker", tower_cell + Vector2i(2, 0))
	var hp_before := int(Entities.get_one(state, 1)["hp"])
	Sim.advance(state, int(entry["reload_ticks"]) * 3)
	expect(Entities.get_one(state, 1).get("hp", -1) == hp_before,
		"a tower does nothing at all during the day",
		str(Entities.get_one(state, 1)))

	# At night it shoots.
	var night := _night_with_tower(true)
	state = night["state"]
	tower_cell = night["tower"]
	var victim := Entities.spawn(state, &"walker", tower_cell + Vector2i(2, 0))
	expect(Towers.target_of(state, tower_cell) == victim,
		"it picks the one thing in range", str(Towers.target_of(state, tower_cell)))

	# **Something travels.** A shot is in the air before it is a subtraction.
	Sim.advance(state, 1)
	expect(Towers.in_flight(state) == 1, "a shot is in the air",
		str(Towers.in_flight(state)))
	expect(Entities.alive(state, victim), "and the target is still up")

	Sim.advance(state, 20)
	expect(Towers.in_flight(state) == 0, "the shot lands")
	expect(int(Entities.get_one(state, victim)["hp"])
		< int((GameData.ENEMIES[&"walker"] as Dictionary)["hp"]),
		"and takes hit points off", str(Entities.get_one(state, victim)))

	# **Out of range is out of range.**
	var far := _night_with_tower(true)
	state = far["state"]
	tower_cell = far["tower"]
	var distant := tower_cell + Vector2i(int(entry["range"]) + 3, 0)
	if Grid.in_bounds(distant):
		Entities.spawn(state, &"walker", distant)
		expect(Towers.target_of(state, tower_cell) == 0,
			"nothing beyond the range is a target")
		Sim.advance(state, int(entry["reload_ticks"]) + 5)
		expect(Towers.in_flight(state) == 0, "and nothing is fired")

	# **Nearest the house, not nearest the tower.** The thing about to reach
	# the farmhouse is the thing worth shooting.
	var choosing := _night_with_tower(true)
	state = choosing["state"]
	tower_cell = choosing["tower"]
	var house := Farm.house_centre(state)
	var near_tower := Entities.spawn(state, &"walker", tower_cell + Vector2i(1, 0))
	var near_house := Entities.spawn(state, &"walker", tower_cell + Vector2i(-1, 0))
	var a := Grid.manhattan(Entities.cell_of(state, near_tower), house)
	var b := Grid.manhattan(Entities.cell_of(state, near_house), house)
	var expected := near_house if b < a else near_tower
	expect(Towers.target_of(state, tower_cell) == expected,
		"it shoots whichever is closer to the house",
		"%d at %d from the house, %d at %d" % [near_tower, a, near_house, b])

	# **A tie is broken by the lower id, never by iteration order.**
	var tied := _night_with_tower(true)
	state = tied["state"]
	tower_cell = tied["tower"]
	var first := 0
	var second := 0
	for id in Entities.ids(state):
		Entities.remove(state, id)
	# Two at the same distance from the house, on either side of the tower.
	var left := tower_cell + Vector2i(-1, 0)
	var right := tower_cell + Vector2i(1, 0)
	if Grid.manhattan(left, house) == Grid.manhattan(right, house):
		first = Entities.spawn(state, &"walker", left)
		second = Entities.spawn(state, &"walker", right)
		expect(Towers.target_of(state, tower_cell) == mini(first, second),
			"a tie goes to the lower id",
			"%d vs %d" % [first, second])

	# **Two runs of the same seed fire at the same targets on the same ticks.**
	var log_a := _shooting_log(301)
	var log_b := _shooting_log(301)
	expect(log_a == log_b, "the same seed shoots the same script",
		"%d entries vs %d" % [log_a.size(), log_b.size()])
	expect(log_a.size() > 3, "and there was something to compare",
		str(log_a.size()))

	# **Halving the rate of fire halves the shots.** The lever is the lever.
	var fast := _shots_in(600, int(entry["reload_ticks"]))
	var slow := _shots_in(600, int(entry["reload_ticks"]) * 2)
	expect(absi(fast - slow * 2) <= 1,
		"twice the reload is half the shots", "%d against %d" % [fast, slow])

	_completed += 1     # last line: an abandoned group never gets here


## A farm at night with one gun tower on it, and the cell it stands on.
func _night_with_tower(at_night: bool) -> Dictionary:
	var state := State.create(201)
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200})
	var cell := Vector2i(24, 9)
	while not Farm.buildable(state, cell) and cell.x < 34:
		cell.x += 1
	Building.place(state, &"gun_tower", cell)
	if at_night:
		Phases.begin_preparation(state)
		Sim.advance(state, GameData.PREPARATION_TICKS)
		_park_the_waves(state)
	return {"state": state, "tower": cell}


## Which target was hit on which tick, for a run of a given seed.
func _shooting_log(seed_value: int) -> Array:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200})
	var cell := Vector2i(24, 9)
	while not Farm.buildable(state, cell) and cell.x < 34:
		cell.x += 1
	Building.place(state, &"gun_tower", cell)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	_park_the_waves(state)
	for offset in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(-1, 1)]:
		Entities.spawn(state, &"walker", cell + offset)

	var log: Array = []
	for _i in 400:
		var before := Towers.in_flight(state)
		Sim.advance(state, 1)
		if Towers.in_flight(state) > before:
			log.append([int(state["tick"]),
				Towers.target_of(state, cell), Entities.count(state)])
	return log


## How many shots a tower gets off in `ticks`, with a given reload.
func _shots_in(ticks: int, reload: int) -> int:
	var state := State.create(202)
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200})
	var cell := Vector2i(24, 9)
	while not Farm.buildable(state, cell) and cell.x < 34:
		cell.x += 1
	Building.place(state, &"gun_tower", cell)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	_park_the_waves(state)

	# A target that cannot die, so the count is about the reload and nothing
	# else. Its hit points are topped up every tick.
	var dummy := Entities.spawn(state, &"walker", cell + Vector2i(1, 0))
	var fired := 0
	for _i in ticks:
		Farm.occupant(state, cell)["reload"] = mini(
			int(Farm.occupant(state, cell).get("reload", 0)), reload)
		var before := Towers.in_flight(state)
		Sim.advance(state, 1)
		if Towers.in_flight(state) > before:
			fired += 1
			Farm.occupant(state, cell)["reload"] = reload
		Entities.get_one(state, dummy)["hp"] = 9999
	return fired


## 0025 - the walk in: one field, every zombie, and a house that can fall.
func _task_0025_zombies() -> void:
	var state := _fresh_night(401)

	# **The field is built from the house outwards.**
	Pathing.refresh(state)
	var house: Vector2i = Farm.cells_with(state, &"house")[0]
	expect(Pathing.distance(state, house) == 0, "the house is distance zero")
	var beside := house + Vector2i(0, 1)
	expect(Pathing.distance(state, beside) <= 2, "next to it is next to it",
		str(Pathing.distance(state, beside)))
	expect(Pathing.distance(state, Farm.cells_of(state, Farm.Terrain.WATER)[0])
		== Pathing.UNREACHABLE, "and the pond is not a route")

	# Every spawn point can get there, or it is not a spawn point.
	for where in GameData.SPAWNS.size():
		var cells := Enemies.spawn_cells(state, where)
		expect(not cells.is_empty(), "spawn point %d has somewhere to stand"
			% where)
		for cell in cells:
			expect(Pathing.reachable(state, cell),
				"and %s can reach the house" % cell)

	# **Rebuilt only when the grid changes.**
	var version := int(state["flow_version"])
	Sim.advance(state, 30)
	expect(int(state["flow_version"]) == version,
		"thirty quiet ticks rebuild nothing", str(state["flow_version"]))
	# Through `Farm` rather than `Building`: a wall may not go up mid-wave, and
	# what is checked here is the field noticing, not the phase rule.
	Farm.place(state, _any_buildable(state), {"id": &"wall", "hp": 120})
	Pathing.refresh(state)
	expect(int(state["flow_version"]) > version,
		"and a wall going up does", str(state["flow_version"]))

	# **A wall reroutes the wave.** Box the house in and the way round is
	# longer than it was.
	var walled := _fresh_night(402)
	Pathing.refresh(walled)
	var corner: Vector2i = Farm.cells_with(walled, &"house")[0] + Vector2i(4, 4)
	var straight := Pathing.distance(walled, corner)
	for dy in range(-3, 4):
		var block: Vector2i = Farm.house_centre(walled) + Vector2i(2, dy)
		if Farm.buildable(walled, block):
			Farm.place(walled, block, {"id": &"wall", "hp": 120})
	Pathing.refresh(walled)
	expect(Pathing.distance(walled, corner) > straight,
		"a wall makes the way round longer",
		"%d then %d" % [straight, Pathing.distance(walled, corner)])

	# **Nowhere to go is an answer, not a crash.**
	var boxed := _fresh_night(403)
	var spot := Vector2i(30, 9)
	while not Farm.buildable(boxed, spot) and spot.x < 36:
		spot.x += 1
	for offset in Grid.STEPS_8:
		var wall_cell: Vector2i = spot + offset
		if Farm.buildable(boxed, wall_cell):
			Farm.place(boxed, wall_cell, {"id": &"wall", "hp": 120})
	Pathing.refresh(boxed)
	var trapped := Entities.spawn(boxed, &"walker", spot)
	var where_it_was := Entities.position(boxed, trapped)
	Sim.advance(boxed, 90)
	expect(Entities.alive(boxed, trapped), "a boxed-in zombie is still there")
	expect(Entities.position(boxed, trapped) == where_it_was,
		"and stands still rather than crashing",
		str(Entities.position(boxed, trapped)))

	# **It walks in, and the house feels it.**
	var raided := _fresh_night(404)
	Pathing.refresh(raided)
	var start: Vector2i = Enemies.spawn_cells(raided, 0)[0]
	var walker := Entities.spawn(raided, &"walker", start)
	var far := Pathing.distance(raided, start)
	expect(far > 5, "it starts a good way out", str(far))

	var hp_before := int(raided["house_hp"])
	var per_tile := int((GameData.ENEMIES[&"walker"] as Dictionary)["ticks_per_tile"])
	Sim.advance(raided, far * per_tile + 60)
	expect(not Entities.alive(raided, walker),
		"it arrives and is spent", str(Entities.count(raided)))
	expect(int(raided["house_hp"])
		== hp_before - int((GameData.ENEMIES[&"walker"] as Dictionary)["damage"]),
		"taking a bite out of the house", str(raided["house_hp"]))
	expect(int(raided["breaches"]) == 1, "and counted as a breach")

	# **The speed is exactly what the lever says.** Not what integer division
	# left behind: 64 units over 20 ticks is 3.2, and truncating that would be
	# a sixth slower than the table promises.
	var timed := _fresh_night(405)
	Pathing.refresh(timed)
	var lane: Vector2i = Enemies.spawn_cells(timed, 0)[0]
	var runner := Entities.spawn(timed, &"walker", lane)
	var before_distance := Pathing.distance(timed, lane)
	Sim.advance(timed, per_tile * 4)
	if Entities.alive(timed, runner):
		var now := Pathing.distance(timed, Entities.cell_of(timed, runner))
		expect(before_distance - now == 4,
			"four tiles in four tiles' worth of ticks",
			"%d then %d" % [before_distance, now])

	# **The house falling ends the night.**
	var doomed := _fresh_night(406)
	Pathing.refresh(doomed)
	doomed["house_hp"] = 1
	# Just outside it, so the walk in is what lands the blow.
	var porch: Vector2i = Farm.house_centre(doomed) + Vector2i(0, 2)
	while not Farm.walkable(doomed, porch) and porch.y < Grid.HEIGHT - 1:
		porch.y += 1
	Entities.spawn(doomed, &"walker", porch)
	Sim.advance(doomed, per_tile * 3)
	expect(int(doomed["house_hp"]) == 0, "the house falls",
		str(doomed["house_hp"]))
	expect(int(doomed["phase"]) == Phases.RESULT,
		"and the night ends there and then",
		Phases.name_of(int(doomed["phase"])))
	expect((doomed["last_result"] as Dictionary)["survived"] == false,
		"recorded as a loss")

	# **Spawning works on a night nobody has prepared.** The test above had
	# called `Pathing.refresh()` by hand, which is a precondition the game does
	# not arrange - and with it the first wave of every night spawned nothing.
	var cold := _fresh_night(507)
	expect(Enemies.spawn(cold, &"walker", 0) > 0,
		"the first zombie of a night spawns without anybody refreshing anything")
	expect(Entities.count(cold) == 1, "and is out there",
		str(Entities.count(cold)))

	# **The same seed puts every zombie in the same place at tick 1000.**
	expect(_horde_positions(501) == _horde_positions(501),
		"a seed replays the whole horde")
	expect(_horde_positions(501) != _horde_positions(502),
		"and a different seed does not")

	# **Fifty of them cost almost nothing**, because the field is built once.
	var crowd := _fresh_night(503)
	for _i in 50:
		Enemies.spawn(crowd, &"walker", 0)
	expect(Entities.count(crowd) == 50, "fifty are out there",
		str(Entities.count(crowd)))
	# **The invariant, not the clock.** The cost of fifty zombies is that the
	# field is built once and read, so what is checked is that it was built
	# once - which is true on any machine. A microsecond assert here failed
	# under `verify.py` and passed on its own, because the machine was busier,
	# and a correctness suite that fails when the machine is busy is a suite
	# people learn to re-run. Task 0102 owns the wall-clock budget.
	var rebuilds := int(crowd["flow_version"])
	var started := Time.get_ticks_usec()
	Sim.advance(crowd, 200)
	var per_tick := float(Time.get_ticks_usec() - started) / 200.0
	print("  fifty zombies: %.1f us a tick (for information, not a gate)"
		% per_tick)
	expect(int(crowd["flow_version"]) == rebuilds,
		"two hundred ticks of fifty zombies rebuild the field no times at all",
		"%d then %d" % [rebuilds, crowd["flow_version"]])
	expect(Entities.count(crowd) > 0, "and they are still walking",
		str(Entities.count(crowd)))

	_completed += 1     # last line: an abandoned group never gets here


## A farm at night with nothing on it and nothing coming.
##
## **The wave schedule is parked.** Since task 0027 a night sends what its table
## says and ends when everything sent is dead - which is right, and which means
## a test about pathing or a barricade's lifetime would otherwise be fighting
## twelve walkers it did not ask for, or would find the night over before it
## started. Tests that are about waves use `_scheduled_night()`.
func _fresh_night(seed_value: int) -> Dictionary:
	var state := _scheduled_night(seed_value)
	_park_the_waves(state)
	return state


## A farm at night with its real schedule running.
func _scheduled_night(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	return state


## Stop the night sending anything, and stop it deciding it is finished.
func _park_the_waves(state: Dictionary) -> void:
	var wave: Dictionary = state["wave"]
	wave["done"] = false
	wave["index"] = 0
	wave["left"] = 0
	wave["wait"] = 1 << 30


## Where every zombie is at tick 1000, for a given seed.
func _horde_positions(seed_value: int) -> Array:
	var state := _fresh_night(seed_value)
	for _i in 12:
		Enemies.spawn(state, &"walker", 0)
		Enemies.spawn(state, &"walker", 1)
	Sim.advance(state, 1000)
	var out: Array = []
	for id in Entities.ids(state):
		out.append([id, Entities.position(state, id)])
	return out


## 0026 - the kill: one place damage happens, and nothing shoots a corpse.
func _task_0026_combat() -> void:
	var state := _fresh_night(601)
	var walker_hp := int((GameData.ENEMIES[&"walker"] as Dictionary)["hp"])

	# **Armour comes off every hit, and never all of it.**
	var soft := Entities.spawn(state, &"walker", Enemies.spawn_cells(state, 0)[0])
	expect(Combat.hit(state, soft, 6) == 6, "no armour, no reduction")
	var tank := Entities.spawn(state, &"tank", Enemies.spawn_cells(state, 0)[1])
	var armour := int((GameData.ENEMIES[&"tank"] as Dictionary)["armour"])
	expect(Combat.hit(state, tank, 10) == 10 - armour,
		"armour takes a slice off", str(Combat.hit(state, tank, 10)))
	expect(Combat.hit(state, tank, 1) == Combat.MINIMUM_HIT,
		"but never all of it - an immune enemy is a stuck night",
		str(Combat.hit(state, tank, 1)))

	# **Overkill is not reported as damage dealt.**
	var doomed := Entities.spawn(state, &"walker",
		Enemies.spawn_cells(state, 0)[2])
	expect(Combat.hit(state, doomed, 9999) == walker_hp,
		"a huge hit deals exactly what was left", str(walker_hp))
	expect(not Entities.alive(state, doomed), "and kills it")
	expect(Combat.hit(state, doomed, 10) == 0, "hitting it again does nothing")

	# **Death leaves nothing pointing at it.**
	var lane := _fresh_night(602)
	var tower := _tower_at(lane, Vector2i(30, 9))
	var victim := Entities.spawn(lane, &"walker", tower + Vector2i(2, 0))
	Sim.advance(lane, 2)
	expect(Towers.in_flight(lane) > 0, "a shot is on its way")
	Entities.remove(lane, victim)
	Sim.advance(lane, 2)
	expect(Towers.in_flight(lane) == 0,
		"and is dropped when what it was chasing is gone",
		str(Towers.in_flight(lane)))
	for shot in (lane["projectiles"] as Array):
		expect(Entities.alive(lane, int(shot["target"])),
			"no shot in the air points at anything dead")

	# **Nothing commits to a target that is already accounted for.**
	var crowded := _fresh_night(603)
	var a := _tower_at(crowded, Vector2i(30, 8))
	var b := _tower_at(crowded, Vector2i(30, 10))
	var c := _tower_at(crowded, Vector2i(31, 9))
	var first := Entities.spawn(crowded, &"walker", Vector2i(29, 9))
	var second := Entities.spawn(crowded, &"walker", Vector2i(28, 9))
	expect(a != Vector2i(-1, -1) and b != Vector2i(-1, -1)
		and c != Vector2i(-1, -1), "three towers cover the lane")
	Entities.get_one(crowded, first)["hp"] = 6      # one shot's worth
	Sim.advance(crowded, 1)
	var on_first := 0
	var on_second := 0
	for shot in (crowded["projectiles"] as Array):
		if int(shot["target"]) == first:
			on_first += 1
		elif int(shot["target"]) == second:
			on_second += 1
	expect(on_first <= 1, "only one shot is committed to the dying one",
		"%d at it" % on_first)
	expect(on_second >= 1, "and the rest go to the one behind",
		"%d at it" % on_second)

	# **A pen of ten takes the number of shots the arithmetic says.**
	#
	# Penned rather than walking, because a walking lane is a test of the
	# balance and not of the arithmetic - see the note below, where one gun
	# tower turned out not to stop seven walkers at all. What is checked here
	# is that every shot lands on something that needed it.
	var counted := _fresh_night(604)
	var pen := Vector2i(30, 9)
	var gun := _tower_at(counted, pen + Vector2i(-2, 0))
	expect(gun != Vector2i(-1, -1), "a tower covers the pen")
	var damage := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["damage"])
	var per_walker := int(ceil(float(walker_hp) / float(damage)))

	var reach := int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["range"])
	var penned := 0
	for i in 10:
		var at := pen + Vector2i(i % 3, i / 3 - 1)
		if not Farm.walkable(counted, at):
			continue
		if Grid.chebyshev(at, gun) > reach:
			continue
		if Entities.spawn(counted, &"walker", at) > 0:
			penned += 1
	expect(penned >= 8, "a pen of them, all in range", str(penned))

	# Walled in on every side, so the flow field tells each of them to stay
	# where it is and the fight is the tower against the arithmetic.
	for id in Entities.ids(counted):
		for offset in Grid.STEPS_8:
			var block: Vector2i = Entities.cell_of(counted, id) + offset
			if Farm.buildable(counted, block) and block != gun:
				Farm.place(counted, block, {"id": &"wall", "hp": 9999})

	var shots := 0
	for _i in 6000:
		var before := Towers.in_flight(counted)
		Sim.advance(counted, 1)
		if Towers.in_flight(counted) > before:
			shots += 1
		if Entities.count(counted) == 0:
			break
	expect(Entities.count(counted) == 0, "the pen is cleared",
		str(Entities.count(counted)))
	expect(shots == penned * per_walker,
		"in exactly %d shots - %d each, and none wasted"
			% [penned * per_walker, per_walker],
		"%d fired" % shots)
	expect(int(counted["killed"]) == penned, "and every one of them counted",
		str(counted["killed"]))
	expect(int((counted["killed_by_kind"] as Dictionary)[&"walker"]) == penned,
		"by kind as well")

	# **What one gun tower actually stops**, which is a different question and
	# worth knowing before task 0060 writes ten nights.
	var lane_test := _fresh_night(606)
	var solo := _tower_at(lane_test, Vector2i(30, 9))
	for i in 7:
		Entities.spawn(lane_test, &"walker", Vector2i(33 + i % 3, 8 + i / 3))
	for _i in 3000:
		Sim.advance(lane_test, 1)
		if Entities.count(lane_test) == 0:
			break
	print("  one gun tower against seven walkers: %d killed, %d got through"
		% [int(lane_test["killed"]), int(lane_test["breaches"])])
	expect(int(lane_test["killed"]) + int(lane_test["breaches"]) == 7,
		"every one of them is accounted for",
		"%d killed, %d through" % [int(lane_test["killed"]),
			int(lane_test["breaches"])])

	# **A hit reads at a glance**, because the rules say so rather than the
	# view remembering.
	var flashing := _fresh_night(605)
	var lit := Entities.spawn(flashing, &"tank",
		Enemies.spawn_cells(flashing, 0)[0])
	Combat.hit(flashing, lit, 5)
	expect(int(Entities.get_one(flashing, lit)["hurt"]) == GameData.HURT_TICKS,
		"being hit lights it up")
	Sim.advance(flashing, GameData.HURT_TICKS)
	expect(int(Entities.get_one(flashing, lit).get("hurt", 0)) == 0,
		"and it fades on the tick the lever says",
		str(Entities.get_one(flashing, lit).get("hurt", -1)))

	# **Ids do not depend on spawn order being lucky.** Two runs that spawn the
	# same things in the same order give the same ids, and the hash follows.
	expect(_fight_result(701) == _fight_result(701),
		"the same seed fights the same fight")

	_completed += 1     # last line: an abandoned group never gets here


## Put a gun tower somewhere near a cell, and return where it went.
func _tower_at(state: Dictionary, near: Vector2i) -> Vector2i:
	var cell := near
	while not Farm.buildable(state, cell) and cell.x < Grid.WIDTH - 1:
		cell.x += 1
	if not Farm.buildable(state, cell):
		return Vector2i(-1, -1)
	Farm.place(state, cell, {"id": &"gun_tower",
		"hp": int((GameData.DEFENCES[&"gun_tower"] as Dictionary)["hp"])})
	return cell


## A whole scripted fight, as one number.
func _fight_result(seed_value: int) -> Array:
	var state := _fresh_night(seed_value)
	_tower_at(state, Vector2i(30, 9))
	_tower_at(state, Vector2i(30, 11))
	for _i in 8:
		Enemies.spawn(state, &"walker", 0)
	Sim.advance(state, 1200)
	return [int(state["killed"]), Entities.count(state),
		int(state["house_hp"]), State.hash_of(state)]


## 0027 - the whole loop: three waves, a payout, and a day 2.
func _task_0027_the_loop() -> void:
	# **Night one is what design.md says it is.**
	var rows := Waves.table(1)
	expect(rows.size() == 3, "night one is three waves", str(rows.size()))
	expect(Waves.size_of(1) == 12, "of twelve walkers in total",
		str(Waves.size_of(1)))
	for row in rows:
		expect(StringName((row as Array)[0]) == &"walker",
			"all of them basic - it is the tutorial night")

	# **Everything the table says arrives, one at a time.**
	var sent := _scheduled_night(801)
	expect(int(sent["night"]) == 1, "it is night one", str(sent["night"]))
	var seen := 0
	var most_at_once := 0
	for _i in 6000:
		var before := Entities.count(sent)
		Sim.advance(sent, 1)
		if Entities.count(sent) > before:
			seen += Entities.count(sent) - before
		most_at_once = maxi(most_at_once, Entities.count(sent))
		if int(sent["phase"]) != Phases.NIGHT:
			break
	expect(seen == 12, "all twelve were sent", str(seen))
	expect(most_at_once < 12,
		"and never all at once - they walk out of the dark in a line",
		str(most_at_once))

	# **The night ends by itself**, one way or the other.
	expect(int(sent["phase"]) == Phases.RESULT,
		"the night ended on its own", Phases.name_of(int(sent["phase"])))

	# **An undefended farm loses.** Twelve walkers at five damage against a
	# hundred hit points, and nothing shooting back.
	var naked := _scheduled_night(802)
	for _i in 6000:
		Sim.advance(naked, 1)
		if int(naked["phase"]) != Phases.NIGHT:
			break
	expect(not bool((naked["last_result"] as Dictionary)["survived"]),
		"a farm with no towers on it loses night one")
	expect(int(naked["house_hp"]) == 0, "with the house down",
		str(naked["house_hp"]))

	# **A defended farm survives, and gets paid.**
	var held := _defended_night(803)
	for _i in 8000:
		Sim.advance(held, 1)
		if int(held["phase"]) != Phases.NIGHT:
			break
	expect(int(held["phase"]) == Phases.RESULT, "the night ends",
		Phases.name_of(int(held["phase"])))
	var payout := Rewards.last(held)
	print("  night one, four towers: survived=%s killed=%d through=%d house=%d"
		% [payout.get("survived", false), int(payout.get("killed", 0)),
			int(payout.get("breaches", 0)), int(payout.get("house_hp", 0))])
	expect(bool(payout["survived"]), "four towers hold night one",
		str(payout))
	expect(int(payout["killed"]) == 12, "killing all twelve",
		str(payout["killed"]))

	# The payout is itemised and it is what arrived.
	var gained: Dictionary = payout["gained"]
	expect(gained.has(GameData.MONEY), "it pays money")
	expect(gained.has(GameData.WOOD) and gained.has(GameData.IRON),
		"and materials towards the next night", str(gained.keys()))
	expect(int(gained[GameData.MONEY]) > int(GameData.REWARDS["base_money"]),
		"more than the flat fee, because things were killed",
		str(gained[GameData.MONEY]))

	# **Defending well pays more than barely holding.** The same night, one
	# with the house untouched and one without.
	var scratched := _defended_night(803)
	scratched["house_hp"] = GameData.HOUSE_HP - 1
	scratched["killed_by_kind"] = {}
	scratched["killed"] = 0
	var poorer := Rewards.preview(scratched, true)
	var untouched := _defended_night(803)
	untouched["killed_by_kind"] = {}
	untouched["killed"] = 0
	var richer := Rewards.preview(untouched, true)
	expect(int(richer[GameData.MONEY]) > int(poorer[GameData.MONEY]),
		"an untouched house is worth more than a scratched one",
		"%d against %d" % [richer[GameData.MONEY], poorer[GameData.MONEY]])

	# **Losing costs a share of the stock and nothing else.**
	var beaten := _scheduled_night(804)
	Resources.gain(beaten, {GameData.WOOD: 100, GameData.STONE: 40})
	# What was held, not what was handed over: the farm starts with some.
	var wood_before := Resources.amount(beaten, GameData.WOOD)
	var money_before := Resources.amount(beaten, GameData.MONEY)
	for _i in 6000:
		Sim.advance(beaten, 1)
		if int(beaten["phase"]) != Phases.NIGHT:
			break
	expect(Resources.amount(beaten, GameData.WOOD)
		== wood_before - int(floor(float(wood_before)
			* GameData.DEFEAT_RESOURCE_LOSS)),
		"a quarter of the wood is gone",
		"%d of %d left" % [Resources.amount(beaten, GameData.WOOD), wood_before])
	expect(Resources.amount(beaten, GameData.MONEY) == money_before,
		"the money is not - a loss costs a day, not the run",
		str(Resources.amount(beaten, GameData.MONEY)))

	# **Confirming goes back to the farm, one day on.**
	var day_before := int(beaten["day"])
	expect(int(beaten["phase"]) == Phases.RESULT, "the payout is up")
	(beaten["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(beaten, 1)
	expect(int(beaten["phase"]) == Phases.DAY, "and confirming ends it",
		Phases.name_of(int(beaten["phase"])))
	expect(int(beaten["day"]) == day_before,
		"the day counter moved when the night ended, not twice",
		str(beaten["day"]))
	expect(int(beaten["day_tick"]) == 0, "a fresh morning")
	expect(int(beaten["house_hp"]) == 0,
		"and the house is still down until night two rebuilds it")

	# **The farm is still there in the morning**, which is what makes a loss a
	# setback rather than an ending.
	expect(Farm.cells_with(beaten, &"tree").size() > 0, "the wood is there")
	expect(Interact.verb_at(beaten, Farm.cells_with(beaten, &"tree")[0])
		== &"chop", "and can be chopped again")

	# **The whole cycle, driven end to end.** Day, build, night, payout, day.
	var run := State.create(805)
	expect(int(run["day"]) == 1 and int(run["phase"]) == Phases.DAY, "day one")
	Resources.gain(run, {GameData.WOOD: 60, GameData.IRON: 60})
	_arm_the_farm(run, 4)
	(run["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(run, 1)
	expect(int(run["phase"]) == Phases.PREPARATION, "the night is asked for")
	var ticks := 0
	for _i in 12000:
		Sim.advance(run, 1)
		ticks += 1
		if int(run["phase"]) == Phases.RESULT:
			break
	(run["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(run, 1)
	expect(int(run["phase"]) == Phases.DAY, "and it comes back to the farm")
	expect(int(run["day"]) == 2, "on day two", str(run["day"]))
	print("  a whole night takes %d ticks - %.0f seconds"
		% [ticks, float(ticks) / float(GameData.TICK_HZ)])
	expect(ticks < 240 * GameData.SECONDS,
		"and a night is minutes, not an evening",
		"%d ticks" % ticks)

	_completed += 1     # last line: an abandoned group never gets here


## A night with towers already up, the way a player who spent their day would
## arrive at one.
func _defended_night(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 200, GameData.IRON: 200,
		GameData.STONE: 200})
	_arm_the_farm(state, 4)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	return state


## Put `count` gun towers between the east spawn and the house.
func _arm_the_farm(state: Dictionary, count: int) -> void:
	var placed := 0
	for x in range(22, 34):
		for y in [7, 9, 11, 5]:
			if placed >= count:
				return
			var cell := Vector2i(x, y)
			if Farm.buildable(state, cell):
				if Building.place(state, &"gun_tower", cell):
					placed += 1


## 0028 - three crops, and no right answer among them.
func _task_0028_crops() -> void:
	# **Sorting StringNames is not what it looks like.** `Array.sort()` orders
	# them by internal pointer - by the order the strings were interned in -
	# so a "sorted" list of ids comes out in source-file order and moves when
	# somebody reorders two `const` lines. Found by adding a fourth crop and
	# getting [pumpkin, carrot, corn, wheat] back. Everything in src/core/ that
	# sorts ids goes through GameData.sorted_names() now, and this is the assert
	# that keeps it there.
	var jumbled: Array = [&"zebra", &"apple", &"mango", &"apple pie"]
	expect(GameData.sorted_names(jumbled)
		== [&"apple", &"apple pie", &"mango", &"zebra"],
		"sorted_names sorts by the text, which is what sorted means",
		str(GameData.sorted_names(jumbled)))
	expect(GameData.sorted_names([]) == [], "and an empty list stays empty")

	var ids := Farming.seeds()
	expect(ids.size() == GameData.CROPS.size(),
		"every crop is in the seed list", str(ids))
	expect(ids == [GameData.CARROT, GameData.CORN, GameData.WHEAT],
		"in a fixed, sorted order - the state is not allowed to depend on "
		+ "Dictionary order", str(ids))

	# **Each crop yields and times what the table says.** Planted, grown a tick
	# at a time, and harvested through the real verbs.
	for id in ids:
		var data: Dictionary = GameData.CROPS[id]
		var state := State.create(900)
		Resources.gain(state, {GameData.MONEY: 100})
		var money_before := Resources.amount(state, GameData.MONEY)
		var cell := _a_plot(state)
		expect(Farming.select_seed(state, id), "%s can be chosen" % id)
		Farming.act(state, cell)                # till
		Farming.act(state, cell)                # plant
		expect(Farming.crop_on(state, cell) == id,
			"%s is what went in the ground" % id,
			str(Farming.crop_on(state, cell)))
		expect(Resources.amount(state, GameData.MONEY)
			== money_before - int(data["seed_cost"]),
			"and the seed was paid for",
			str(Resources.amount(state, GameData.MONEY)))

		var needed := int(data["growth_ticks"])
		Sim.advance(state, needed - 1)
		expect(not Farming.is_ready(state, cell),
			"%s is not ready a tick early" % id)
		expect(Farming.verb_at(state, cell) == &"",
			"and offers nothing to do while it grows", str(id))
		Sim.advance(state, 1)
		expect(Farming.is_ready(state, cell),
			"%s is ready on the tick the table says" % id, str(needed))
		expect(Farming.verb_at(state, cell) == &"harvest",
			"and now it can be harvested")

		var before := Resources.amount(state, id)
		Farming.act(state, cell)
		expect(Resources.amount(state, id) - before == int(data["yield"]),
			"%s yields what the table says" % id,
			str(Resources.amount(state, id) - before))
		expect(Farming.is_tilled(state, cell)
			and Farming.crop_on(state, cell) == &"",
			"and leaves the ground turned over for the next one")

	# **They differ, on every axis.** Three crops that grew at the same rate
	# would be one crop with three names.
	var times: Array = []
	var values: Array = []
	var costs: Array = []
	for id in ids:
		times.append(Farming.seconds_to_grow(id))
		values.append(Farming.value_per_day(id))
		costs.append(int((GameData.CROPS[id] as Dictionary)["seed_cost"]))
		print("  %-7s $%d seed, %3ds, %d a harvest, %d visits, %d a day"
			% [id, int((GameData.CROPS[id] as Dictionary)["seed_cost"]),
				Farming.seconds_to_grow(id), Farming.value_per_harvest(id),
				Farming.harvests_per_day(id), Farming.value_per_day(id)])
	expect(_all_different(times), "no two crops grow at the same rate",
		str(times))
	expect(_all_different(values), "and none is worth the same over a day",
		str(values))
	expect(_all_different(costs), "and none costs the same to start",
		str(costs))

	# **No crop is the right answer at every money level.** More money per day,
	# for no more trips across the farm, off a no larger seed, would make every
	# other crop a mistake. `GameData.check_crops()` is what enforces it; this
	# is the same sum spelled out, so a failure here names the pair.
	for a in ids:
		for b in ids:
			if a == b:
				continue
			var seed_a := int((GameData.CROPS[a] as Dictionary)["seed_cost"])
			var seed_b := int((GameData.CROPS[b] as Dictionary)["seed_cost"])
			expect(not (Farming.value_per_day(a) >= Farming.value_per_day(b)
				and Farming.harvests_per_day(a) <= Farming.harvests_per_day(b)
				and seed_a <= seed_b),
				"%s does not dominate %s" % [a, b],
				"%d a day in %d visits off a $%d seed, against %d/%d/$%d"
					% [Farming.value_per_day(a), Farming.harvests_per_day(a),
						seed_a, Farming.value_per_day(b),
						Farming.harvests_per_day(b), seed_b])

	# And each one wins at something, which is the other half of a real choice.
	expect(_wins_at(ids, func(id: StringName) -> int:
		return Farming.value_per_day(id)) == GameData.CARROT,
		"carrot pays the most over a day")
	expect(_wins_at(ids, func(id: StringName) -> int:
		return -Farming.harvests_per_day(id)) == GameData.CORN,
		"corn asks for the fewest trips across the farm")
	expect(_wins_at(ids, func(id: StringName) -> int:
		return -int((GameData.CROPS[id] as Dictionary)["seed_cost"]))
		== GameData.CARROT, "and carrot is what a broke player can afford")
	expect(Farming.value_per_day(GameData.WHEAT)
		> Farming.value_per_day(GameData.CORN)
		and Farming.harvests_per_day(GameData.WHEAT)
		< Farming.harvests_per_day(GameData.CARROT),
		"wheat beats corn on money and carrot on walking")

	# **A broke player has exactly one option**, which is what "no right answer
	# at every money level" means when you have a dollar.
	var broke := State.create(901)
	Resources.spend(broke, GameData.MONEY,
		Resources.amount(broke, GameData.MONEY) - 1)
	expect(Resources.amount(broke, GameData.MONEY) == 1, "a dollar left")
	var affordable: Array = []
	for id in ids:
		if int((GameData.CROPS[id] as Dictionary)["seed_cost"]) <= 1:
			affordable.append(id)
	expect(affordable == [GameData.CARROT],
		"and carrot is the only thing that can go in the ground",
		str(affordable))

	# The furrow refuses rather than half-planting: no money, no seed, and the
	# plot is still tilled and still empty.
	var poor_cell := _a_plot(broke)
	Farming.select_seed(broke, GameData.CORN)
	Farming.act(broke, poor_cell)               # till
	Farming.act(broke, poor_cell)               # plant - and cannot
	expect(Farming.crop_on(broke, poor_cell) == &"",
		"corn at four dollars does not go in on one")
	expect(Resources.amount(broke, GameData.MONEY) == 1,
		"and the dollar is safe")
	expect(Farming.verb_at(broke, poor_cell) == &"plant",
		"the plot is still waiting for a seed")

	# **Selecting refuses what is not a crop**, rather than storing it and
	# failing at the furrow a minute later.
	var picky := State.create(902)
	expect(not Farming.select_seed(picky, &"gun_tower"),
		"a gun tower is not a seed")
	expect(not Farming.select_seed_at(picky, ids.size()),
		"and there is no slot past the last crop")
	expect(Farming.selected_seed(picky) == StringName(ids[0]),
		"so the selection is untouched", str(Farming.selected_seed(picky)))
	expect(Farming.select_seed_at(picky, 1), "slot 2 picks the second crop")
	expect(Farming.selected_seed(picky) == StringName(ids[1]),
		"which is the sorted second", str(Farming.selected_seed(picky)))

	# **A fourth crop is one dictionary entry.** Nothing outside GameData names
	# a crop, so the list the menu, the number keys and the save file work from
	# is whatever the table turned out to hold.
	expect(Farming.seeds().size() == GameData.CROPS.size(),
		"the seed list is the crop table, not a copy of it")
	expect(DayHud.SEED_KEYS.size() > GameData.CROPS.size(),
		"and there is a spare number key for the next one",
		str(DayHud.SEED_KEYS.size()))
	expect(GameData.check_crops(GameData.CROPS).is_empty(),
		"the shipped table passes its own balance check",
		str(GameData.check_crops(GameData.CROPS)))

	# The check has teeth: a crop that beats another on all three axes is
	# refused. Built here rather than shipped, so the table stays honest.
	var rigged: Dictionary = GameData.CROPS.duplicate(true)
	(rigged[GameData.WHEAT] as Dictionary)["seed_cost"] = 0
	(rigged[GameData.WHEAT] as Dictionary)["growth_ticks"] = \
		int((GameData.CROPS[GameData.CARROT] as Dictionary)["growth_ticks"])
	expect(not GameData.check_crops(rigged).is_empty(),
		"a free crop that grows as fast as carrot and sells for more is refused",
		str(GameData.check_crops(rigged)))

	_completed += 1     # last line: an abandoned group never gets here


## A soil cell nobody has touched.
func _a_plot(state: Dictionary) -> Vector2i:
	for cell in Farm.cells_of(state, Farm.Terrain.SOIL):
		if Farm.is_empty(state, cell) and not Farming.is_tilled(state, cell):
			return cell
	return Vector2i(-1, -1)


func _all_different(values: Array) -> bool:
	for i in values.size():
		for j in range(i + 1, values.size()):
			if values[i] == values[j]:
				return false
	return true


## Which id scores highest on `score`, or `&""` when two of them tie.
func _wins_at(ids: Array, score: Callable) -> StringName:
	var best: StringName = &""
	var best_score := -(1 << 40)
	var tied := false
	for id in ids:
		var n := int(score.call(id))
		if n > best_score:
			best_score = n
			best = StringName(id)
			tied = false
		elif n == best_score:
			tied = true
	return &"" if tied else best


## 0029 - four stages you can see, and one chore worth doing.
func _task_0029_watering() -> void:
	# **Four stages, and each one is reachable.** The stage is computed from the
	# growth ticks already in data, so this is really a check that the division
	# lands on every step rather than skipping one on a short crop.
	for id in Farming.seeds():
		var data: Dictionary = GameData.CROPS[id]
		var stages := int(data["stages"])
		expect(stages == 4, "%s has four stages" % id, str(stages))
		var state := State.create(1100)
		Resources.gain(state, {GameData.MONEY: 100})
		Farming.select_seed(state, id)
		var cell := _a_plot(state)
		Farming.act(state, cell)
		Farming.act(state, cell)
		var seen: Array = []
		for _i in int(data["growth_ticks"]) + 1:
			var stage := Farming.stage(state, cell)
			if not seen.has(stage):
				seen.append(stage)
			Sim.advance(state, 1)
		seen.sort()
		expect(seen == [0, 1, 2, 3],
			"%s passes through every one of them" % id, str(seen))

		# And there is art for each, so "visible" means visible.
		for stage in 4:
			var path := "res://sprites/crops/%s_%d.png" % [id, stage]
			expect(ResourceLoader.exists(path),
				"%s stage %d has a sprite" % [id, stage], path)

	# **The water comes from the pond and the well**, and both answer the same
	# question the same way.
	var farm := State.create(1101)
	var pond: Vector2i = Farm.cells_of(farm, Farm.Terrain.WATER)[0]
	expect(Farming.is_water_source(farm, pond), "the pond is a water source")
	var wells := Farm.cells_with(farm, &"well")
	expect(wells.size() == 1, "there is a well on the farm", str(wells.size()))
	expect(Farming.is_water_source(farm, wells[0]), "and it is a water source")
	expect(not Farming.is_water_source(farm, _a_plot(farm)),
		"a soil tile is not")
	expect(not Farm.remove(farm, wells[0]),
		"and the well cannot be sold - it is the only water north of the pond")

	# **The can fills by standing next to water**, not by pressing anything. A
	# water tile already offers `fish`, and a tile that offered two things would
	# make the player guess which.
	expect(Farming.water_carried(farm) == 0, "the can starts empty",
		str(Farming.water_carried(farm)))
	expect(not Farming.refill_beside(farm, _a_plot(farm)),
		"standing in the field fills nothing")
	expect(Farming.refill_beside(farm, wells[0] + Vector2i(0, 1)),
		"standing next to the well fills the can")
	expect(Farming.water_carried(farm) == GameData.WATER_CAN_CAPACITY,
		"right to the top", str(Farming.water_carried(farm)))
	expect(not Farming.refill_beside(farm, wells[0] + Vector2i(0, 1)),
		"and a full can does not refill - nothing to do, nothing done")

	var shore := pond + Vector2i(0, -1)
	var beside_pond := State.create(1102)
	expect(Farming.refill_beside(beside_pond, shore),
		"the pond fills it too", str(shore))

	# **Watered finishes measurably ahead of dry.** The done-when of this task,
	# and the one number a player will actually feel.
	var race := State.create(1103)
	Resources.gain(race, {GameData.MONEY: 100})
	Farming.select_seed(race, GameData.WHEAT)
	var field := Farm.cells_of(race, Farm.Terrain.SOIL)
	var wet: Vector2i = field[0]
	var dry: Vector2i = field[1]
	for cell in [wet, dry]:
		Farming.act(race, cell)             # till
		Farming.act(race, cell)             # plant
	race["water_can"] = GameData.WATER_CAN_CAPACITY
	expect(Farming.verb_at(race, wet) == &"water",
		"a growing crop with water in hand offers the can",
		str(Farming.verb_at(race, wet)))
	Farming.act(race, wet)
	expect(Farming.is_watered(race, wet), "and watering it takes")
	expect(not Farming.is_watered(race, dry), "the one beside it is still dry")
	expect(Farming.water_carried(race) == GameData.WATER_CAN_CAPACITY - 1,
		"one tile off the can", str(Farming.water_carried(race)))
	expect(Farming.verb_at(race, wet) == &"",
		"and a wet tile offers nothing - which is what stops a held key "
		+ "watering it twice", str(Farming.verb_at(race, wet)))
	Farming.act(race, wet)
	expect(Farming.water_carried(race) == GameData.WATER_CAN_CAPACITY - 1,
		"watering it again spends nothing", str(Farming.water_carried(race)))

	var wet_at := -1
	var dry_at := -1
	for t in 8000:
		Sim.advance(race, 1)
		if wet_at < 0 and Farming.is_ready(race, wet):
			wet_at = t
		if dry_at < 0 and Farming.is_ready(race, dry):
			dry_at = t
		if wet_at >= 0 and dry_at >= 0:
			break
	print("  wheat: watered ready at %d ticks, dry at %d - %d apart"
		% [wet_at, dry_at, dry_at - wet_at])
	expect(wet_at > 0 and dry_at > 0, "both of them came up",
		"%d and %d" % [wet_at, dry_at])
	expect(wet_at < dry_at, "the watered one first",
		"%d against %d" % [wet_at, dry_at])
	# A second of daylight apart is the floor for "measurable": less than that
	# and nobody watching the field would be able to tell.
	expect(dry_at - wet_at >= GameData.SECONDS,
		"by more than a second of daylight", "%d ticks" % (dry_at - wet_at))
	# And it is the bonus, not a coincidence: dry takes the ticks the table
	# says, watered takes those ticks scaled by the lever.
	var needed := int((GameData.CROPS[GameData.WHEAT] as Dictionary)["growth_ticks"])
	expect(dry_at == needed - 1, "dry takes exactly what the table says",
		"%d against %d" % [dry_at, needed])
	expect(absi(wet_at - (needed * 100 / (100 + GameData.WATER_GROWTH_BONUS))) <= 2,
		"and watered takes that over the lever", "%d ticks" % wet_at)

	# **Never fatal.** The dry one still ripened, and it still pays the same.
	var paid := Resources.amount(race, GameData.WHEAT)
	Farming.act(race, dry)
	expect(Resources.amount(race, GameData.WHEAT) - paid
		== int((GameData.CROPS[GameData.WHEAT] as Dictionary)["yield"]),
		"and a crop nobody watered pays the same as one they did",
		str(Resources.amount(race, GameData.WHEAT) - paid))

	# **An empty can offers nothing**, rather than offering a verb that fails.
	var empty := State.create(1104)
	Resources.gain(empty, {GameData.MONEY: 100})
	var thirsty := _a_plot(empty)
	Farming.act(empty, thirsty)
	Farming.act(empty, thirsty)
	expect(Farming.water_carried(empty) == 0, "no water in hand")
	expect(Farming.verb_at(empty, thirsty) == &"",
		"so the tile offers nothing to do",
		str(Farming.verb_at(empty, thirsty)))
	Farming.act(empty, thirsty)
	expect(not Farming.is_watered(empty, thirsty),
		"and watering with an empty can does nothing")
	expect(Farming.water_carried(empty) == 0, "least of all go negative",
		str(Farming.water_carried(empty)))

	# **The carry limit is a limit.** One canful waters exactly that many tiles.
	var carrying := State.create(1105)
	Resources.gain(carrying, {GameData.MONEY: 200})
	carrying["water_can"] = GameData.WATER_CAN_CAPACITY
	var row := Farm.cells_of(carrying, Farm.Terrain.SOIL)
	var watered := 0
	for i in GameData.WATER_CAN_CAPACITY + 3:
		var cell: Vector2i = row[i]
		Farming.act(carrying, cell)         # till
		Farming.act(carrying, cell)         # plant
		Farming.act(carrying, cell)         # water, while there is water
		if Farming.is_watered(carrying, cell):
			watered += 1
	expect(watered == GameData.WATER_CAN_CAPACITY,
		"a canful waters exactly what the lever says", str(watered))
	expect(Farming.water_carried(carrying) == 0, "and then it is empty")

	# **The water goes off with the sun.** A plot that stayed wet overnight
	# would make this a once-per-run job rather than a daily one.
	expect(Farming.is_watered(carrying, row[0]), "wet at dusk")
	var soaked := int(Farming.plot(carrying, row[0])["soak"])
	Phases.begin_preparation(carrying)
	expect(not Farming.is_watered(carrying, row[0]),
		"and dry when the night begins")
	expect(int(Farming.plot(carrying, row[0])["soak"]) == 0,
		"with the banked fraction gone too - a crop cannot save up a night's "
		+ "worth of watering it did not get", str(soaked))
	expect(Farming.crop_on(carrying, row[0]) != &"",
		"the crop itself is untouched")

	# **The verb is instant**, which is what lets a held key water a row while
	# the player walks down it. Every other verb stops dead when they step.
	expect(Interact.is_instant(&"water"), "watering is an instant verb")
	for verb in [&"chop", &"mine", &"till", &"plant", &"harvest"]:
		expect(not Interact.is_instant(verb),
			"%s is not - it is work, and walking away gives up on it" % verb)
	expect(Interact.DAY_ONLY.has(&"water"),
		"and it belongs to the daylight like the rest of the farm")

	_completed += 1     # last line: an abandoned group never gets here


## 0030 - the pond: a wait you have to watch, and a miss that costs nothing.
func _task_0030_fishing() -> void:
	var table: Dictionary = GameData.FISHING
	expect(GameData.check_fishing(table).is_empty(),
		"the shipped pond passes its own check",
		str(GameData.check_fishing(table)))

	# The check has teeth. A window of no ticks is a pond nobody can fish, and
	# a rare fish worth less than the common one is not a rare fish.
	var broken: Dictionary = table.duplicate(true)
	broken["window_ticks"] = 0
	expect(not GameData.check_fishing(broken).is_empty(),
		"a pond with no window to react in is refused")
	broken = table.duplicate(true)
	broken["rare_yield"] = (table["common_yield"] as Dictionary).duplicate()
	expect(not GameData.check_fishing(broken).is_empty(),
		"and so is a rare fish worth no more than the common one")
	broken = table.duplicate(true)
	broken["bite_min_ticks"] = int(table["bite_max_ticks"]) + 1
	expect(not GameData.check_fishing(broken).is_empty(),
		"and a bite that comes sooner than it can")

	# **You cast from the shore at the water**, and only at the water.
	var state := State.create(1200)
	var shore := _a_shore(state)
	expect(shore != Vector2i(-1, -1), "there is somewhere to fish from")
	var pond := _water_beside(state, shore)
	expect(Interact.verb_at(state, pond) == &"fish",
		"open water offers a cast", str(Interact.verb_at(state, pond)))
	expect(not Fishing.begin(state, shore),
		"and dry land does not - you cannot fish the lawn")
	expect(not Fishing.is_casting(state), "so nothing is in the water")

	# **The wait is drawn at the cast**, once, inside the lever range.
	expect(Fishing.begin(state, pond), "casting puts a line in")
	expect(Fishing.is_casting(state), "and there is a line in the water")
	expect(Fishing.line_cell(state) == pond, "at the cell it was cast into",
		str(Fishing.line_cell(state)))
	var wait := Fishing.ticks_left(state)
	expect(wait >= int(table["bite_min_ticks"])
		and wait <= int(table["bite_max_ticks"]),
		"and the wait is inside the lever range", "%d ticks" % wait)
	expect(not Fishing.is_biting(state), "nothing is biting yet")
	expect(not Fishing.begin(state, pond),
		"and a second cast is refused - one farmer, one rod")

	# **One rod, one cell.** Other water offers nothing while a line is out.
	var elsewhere := _other_water(state, pond)
	if elsewhere != Vector2i(-1, -1):
		expect(Interact.verb_at(state, elsewhere) == &"",
			"other water offers nothing while a line is out",
			str(Interact.verb_at(state, elsewhere)))
	expect(Interact.verb_at(state, pond) == &"",
		"and waiting is waiting - there is nothing to press",
		str(Interact.verb_at(state, pond)))

	# **The float goes under on the tick the draw said**, and the window opens.
	for _i in wait - 1:
		Fishing.tick(state, shore)
	expect(not Fishing.is_biting(state), "still nothing a tick early",
		str(Fishing.ticks_left(state)))
	Fishing.tick(state, shore)
	expect(Fishing.is_biting(state), "and then it bites")
	expect(Fishing.ticks_left(state) == int(table["window_ticks"]),
		"with the whole window to react in", str(Fishing.ticks_left(state)))
	expect(Interact.verb_at(state, pond) == &"reel",
		"now the water says reel rather than cast",
		str(Interact.verb_at(state, pond)))

	# **Reeling in the window pays.**
	var before := Resources.amount(state, GameData.FISH)
	var caught := Fishing.reel(state)
	expect(not caught.is_empty(), "reeling in the window lands it", str(caught))
	expect(Resources.amount(state, GameData.FISH) > before,
		"and the fish is in the basket",
		str(Resources.amount(state, GameData.FISH)))
	expect(not Fishing.is_casting(state), "the line comes out with it")
	expect(Interact.verb_at(state, pond) == &"fish", "and the water can be "
		+ "cast into again", str(Interact.verb_at(state, pond)))

	# **The same seed lands the same fish on the same tick.** The done-when of
	# this task, and the reason the draw happens at the cast.
	var first := _fishing_log(1201, 30)
	var again := _fishing_log(1201, 30)
	expect(first == again, "the same seed fishes the same pond",
		"%s against %s" % [first.slice(0, 4), again.slice(0, 4)])
	var other := _fishing_log(1202, 30)
	expect(first != other, "and a different seed does not - the wait is "
		+ "really being drawn", str(other.slice(0, 4)))
	print("  thirty casts on seed 1201: %d rare, first four waits %s"
		% [_rare_in(first), str(first.slice(0, 4))])

	# **Both fish exist, and the rare one is rarer.** Thirty casts is a small
	# sample, so this asks for the shape rather than the exact fraction.
	var log := _fishing_log(1203, 400)
	var rare := _rare_in(log)
	expect(rare > 0, "the rare fish happens", str(rare))
	expect(rare < log.size(), "and so does the common one", str(rare))
	var expected := log.size() / int(table["rare_in"])
	expect(absi(rare - expected) <= expected / 2,
		"about one in %d of them, over four hundred casts"
			% int(table["rare_in"]),
		"%d where %d was expected" % [rare, expected])

	# **Missing the window loses nothing but the time.**
	var patient := State.create(1204)
	var shore2 := _a_shore(patient)
	var pond2 := _water_beside(patient, shore2)
	var purse := Resources.amount(patient, GameData.MONEY)
	expect(Fishing.begin(patient, pond2), "a line goes in")
	for _i in int(table["bite_max_ticks"]) + int(table["window_ticks"]) + 2:
		Fishing.tick(patient, shore2)
	expect(not Fishing.is_casting(patient),
		"a window nobody reacted to closes on its own")
	expect(Resources.amount(patient, GameData.FISH) == 0,
		"with no fish", str(Resources.amount(patient, GameData.FISH)))
	expect(Resources.amount(patient, GameData.MONEY) == purse,
		"and nothing taken for it - a miss costs the time and no more",
		str(Resources.amount(patient, GameData.MONEY)))
	expect(Fishing.reel(patient).is_empty(),
		"reeling an empty pond catches nothing")

	# **A whole day of not reacting yields nothing and crashes nothing.** The
	# other done-when, driven through `Sim` rather than by hand.
	var idle := State.create(1205)
	var idle_shore := _a_shore(idle)
	var idle_pond := _water_beside(idle, idle_shore)
	var who: Dictionary = idle["player"]
	who["pos"] = [idle_shore.x * Player.SUBTILE + Player.SUBTILE / 2,
		idle_shore.y * Player.SUBTILE + Player.SUBTILE / 2]
	expect(Fishing.begin(idle, idle_pond), "cast, and then look away")
	Sim.advance(idle, GameData.DAY_TICKS)
	expect(Resources.amount(idle, GameData.FISH) == 0,
		"a whole day of not reacting catches nothing",
		str(Resources.amount(idle, GameData.FISH)))
	expect(not Fishing.is_casting(idle), "and leaves no line in the water")
	expect(int(idle["phase"]) == Phases.DAY, "and the day is still standing")

	# **Walking away gives the cast up.** Without this a player could cast, go
	# mining, and come back to a fish that waited all day - which is the
	# opposite of what the pond charges for.
	var wanderer := State.create(1206)
	var bank := _a_shore(wanderer)
	var water := _water_beside(wanderer, bank)
	expect(Fishing.begin(wanderer, water), "a line goes in")
	Fishing.tick(wanderer, bank)
	expect(Fishing.is_casting(wanderer), "and standing there keeps it")
	Fishing.tick(wanderer, bank + Vector2i(0, -3))
	expect(not Fishing.is_casting(wanderer),
		"walking off gives it up, like every other job on the farm")

	# **The pond is asleep after dark**, like the rest of the farm.
	var nightly := State.create(1207)
	var night_shore := _a_shore(nightly)
	var night_pond := _water_beside(nightly, night_shore)
	expect(Interact.verb_at(nightly, night_pond) == &"fish", "by day, a cast")
	Phases.begin_preparation(nightly)
	Sim.advance(nightly, GameData.PREPARATION_TICKS)
	expect(Interact.verb_at(nightly, night_pond) == &"",
		"and after dark the pond offers nothing",
		str(Interact.verb_at(nightly, night_pond)))

	# **Reeling is a press, not a hold.** A held key that reeled would land
	# every fish without the player ever reacting to one.
	expect(Interact.ONE_SHOT.has(&"reel"), "reeling happens once per press")
	expect(not Interact.is_instant(&"reel"),
		"and it is not an instant verb - that is what watering is for")
	expect(Interact.all_verbs().has(&"reel"),
		"and the tooltip of task 0089 can find it",
		str(Interact.all_verbs()))

	_completed += 1     # last line: an abandoned group never gets here


## Land you can stand on with open water orthogonally beside it.
func _a_shore(state: Dictionary) -> Vector2i:
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		var wet: Vector2i = found
		for step in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0),
				Vector2i(0, 1)]:
			var dry: Vector2i = wet + step
			if Farm.walkable(state, dry):
				return dry
	return Vector2i(-1, -1)


func _water_beside(state: Dictionary, shore: Vector2i) -> Vector2i:
	for step in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, -1)]:
		if Farm.terrain_at(state, shore + step) == Farm.Terrain.WATER:
			return shore + step
	return Vector2i(-1, -1)


func _other_water(state: Dictionary, not_this: Vector2i) -> Vector2i:
	for found in Farm.cells_of(state, Farm.Terrain.WATER):
		var wet: Vector2i = found
		if wet != not_this:
			return wet
	return Vector2i(-1, -1)


## `casts` casts on one seed, always reeled the moment they bite. Each entry is
## the wait that was drawn and whether it was the rare one - which is the whole
## of what the RNG decides about a cast, so two identical logs are two
## identical ponds.
func _fishing_log(seed_value: int, casts: int) -> Array:
	var state := State.create(seed_value)
	var shore := _a_shore(state)
	var pond := _water_beside(state, shore)
	var out: Array = []
	for _i in casts:
		Fishing.begin(state, pond)
		var wait := Fishing.ticks_left(state)
		var rare := bool(Fishing.cast_of(state)["rare"])
		while not Fishing.is_biting(state):
			Fishing.tick(state, shore)
		Fishing.reel(state)
		out.append([wait, rare])
	return out


func _rare_in(log: Array) -> int:
	var n := 0
	for entry in log:
		if bool((entry as Array)[1]):
			n += 1
	return n


## How many of an occupant the farm map draws. For asserts about scenery, which
## moves when the map does - the ones that are really about balance name their
## number and say why.
func _char_count(id: StringName) -> int:
	var ch := ""
	for key in GameData.MAP_LEGEND:
		if StringName((GameData.MAP_LEGEND[key] as Array)[1]) == id:
			ch = key
			break
	if ch == "":
		return 0
	var n := 0
	for row in GameData.FARM_MAP:
		n += (row as String).count(ch)
	return n


## 0031 - iron: the slow resource, out of the cliff and nowhere else.
func _task_0031_iron() -> void:
	var ore: Dictionary = GameData.GATHERING[&"ore"]
	var seam: Dictionary = GameData.GATHERING[&"seam"]

	# **Worse than stone on all three dials**, which is what stops the cliff
	# being one resource with two names.
	expect(int(ore["work_ticks"]) > int(seam["work_ticks"]),
		"ore takes longer per swing than stone",
		"%d against %d" % [ore["work_ticks"], seam["work_ticks"]])
	expect(int(ore["regrow_ticks"]) > int(seam["regrow_ticks"]),
		"and comes back slower",
		"%d against %d" % [ore["regrow_ticks"], seam["regrow_ticks"]])
	var ore_yield := 0
	for res in (ore["yield"] as Dictionary):
		ore_yield += int((ore["yield"] as Dictionary)[res])
	var seam_yield := 0
	for res in (seam["yield"] as Dictionary):
		seam_yield += int((seam["yield"] as Dictionary)[res])
	expect(ore_yield < seam_yield, "and yields less for it",
		"%d against %d" % [ore_yield, seam_yield])

	# **Iron comes out of ore and nothing else.**
	var state := State.create(1300)
	for id in [&"tree", &"rock", &"seam"]:
		var out: Dictionary = (GameData.GATHERING[id] as Dictionary)["yield"]
		expect(not out.has(GameData.IRON),
			"a %s gives no iron" % id, str(out))
	expect((ore["yield"] as Dictionary).has(GameData.IRON),
		"and ore is what does")

	# **Every node is in the cliff**, and the check that says so has teeth.
	expect(GameData.check_iron(GameData.GATHERING, GameData.FARM_MAP).is_empty(),
		"the shipped farm passes the iron check",
		str(GameData.check_iron(GameData.GATHERING, GameData.FARM_MAP)))
	var lawn: Array = GameData.FARM_MAP.duplicate()
	lawn[12] = (lawn[12] as String).substr(0, 8) + "o" \
		+ (lawn[12] as String).substr(9)
	expect(not GameData.check_iron(GameData.GATHERING, lawn).is_empty(),
		"and an ore node dropped on the lawn is refused",
		str(GameData.check_iron(GameData.GATHERING, lawn)))
	var quick: Dictionary = GameData.GATHERING.duplicate(true)
	(quick[&"ore"] as Dictionary)["work_ticks"] = int(seam["work_ticks"])
	expect(not GameData.check_iron(quick, GameData.FARM_MAP).is_empty(),
		"and ore that swings as fast as stone is refused")

	# **Nothing on the map is walled in.** The five stone seams were, from the
	# day the map was drawn until this task, and no assert noticed because they
	# all fetched a seam by id from a cell nobody could stand next to.
	expect(GameData.check_reachable(GameData.GATHERING,
		GameData.FARM_MAP).is_empty(),
		"every node on the farm has somewhere to stand beside it",
		str(GameData.check_reachable(GameData.GATHERING, GameData.FARM_MAP)))
	for found in Farm.cells_with(state, &"ore") + Farm.cells_with(state, &"seam"):
		var node: Vector2i = found
		expect(_somewhere_to_stand(state, node),
			"a farmer can reach the node at %s" % node)

	var buried: Array = GameData.FARM_MAP.duplicate()
	buried[1] = "T..................#########........T..T"
	buried[2] = "T..ssssss......ppp.####o####...........T"
	buried[3] = "...ssssss.....pHHHp.########...........T"
	expect(not GameData.check_reachable(GameData.GATHERING, buried).is_empty(),
		"and a node with cliff on all four sides is refused",
		str(GameData.check_reachable(GameData.GATHERING, buried)))

	# **A day at the cliff buys a tower.** The arithmetic the journal claims,
	# measured by mining for a whole day and counting what comes out.
	# Two routes: a tight one where the next node is always the next tile, and
	# a deliberately bad one that spends ten seconds walking to each. **The
	# cliff is regrowth-bound, not swing-bound** - below about ninety ticks of
	# travel a node the waiting absorbs the walk entirely, which is why the
	# first two of these are the same number.
	var mined := _mine_for_a_day(1301, 0)
	var strolled := _mine_for_a_day(1302, 45)
	var walked := _mine_for_a_day(1303, 300)
	print("  a day at the cliff: %d iron on a tight route, %d strolling, "
		% [mined, strolled] + "%d on a bad one" % walked)
	expect(strolled == mined,
		"a short walk between nodes costs nothing - the day is spent waiting "
		+ "for the cliff, not swinging at it", "%d against %d" % [strolled, mined])
	expect(walked < mined,
		"and a bad route does cost, so the regrowth lever is not the only one",
		"%d against %d" % [walked, mined])
	var tower: Dictionary = (GameData.DEFENCES[&"gun_tower"] as Dictionary)["cost"]
	var needed := int(tower[GameData.IRON])
	expect(mined >= 12 and mined <= 18,
		"a day of nothing but mining is 12 to 18 iron", str(mined))
	expect(walked >= 12, "and even a bad route is 12 or more", str(walked))
	expect(mined >= needed,
		"which buys a gun tower", "%d iron for a %d iron tower" % [mined, needed])
	expect(mined < needed * 2,
		"and only just - two towers is two days", str(mined))

	# **The rock face cannot be exhausted.** Strip every node on it and come
	# back; a farm that could be mined flat would be a run that ended on day 3.
	var stripped := State.create(1310)
	var cliff := Farm.cells_with(stripped, &"ore") \
		+ Farm.cells_with(stripped, &"seam")
	expect(cliff.size() == 13, "thirteen nodes in the cliff", str(cliff.size()))
	for found in cliff:
		var node: Vector2i = found
		for _swing in 12:
			if Farm.is_empty(stripped, node):
				break
			Gathering.strike(stripped, node)
	expect(Farm.cells_with(stripped, &"ore").is_empty(),
		"the whole face can be mined out")
	expect(Farm.cells_with(stripped, &"seam").is_empty(), "every seam too")
	expect(Gathering.regrowing(stripped) == cliff.size(),
		"and all of it is coming back", str(Gathering.regrowing(stripped)))

	Sim.advance(stripped, int(ore["regrow_ticks"]) + 2)
	expect(Farm.cells_with(stripped, &"ore").size() == 8,
		"every ore node is back",
		str(Farm.cells_with(stripped, &"ore").size()))
	expect(Farm.cells_with(stripped, &"seam").size() == 5,
		"and every seam", str(Farm.cells_with(stripped, &"seam").size()))
	expect(Gathering.regrowing(stripped) == 0, "with nothing left pending")

	# And it survives being done over and over, which is what "permanently"
	# means - one regrowth working is not the same as the cliff being eternal.
	for _round in 3:
		for found in Farm.cells_with(stripped, &"ore"):
			var node: Vector2i = found
			for _swing in 12:
				if Farm.is_empty(stripped, node):
					break
				Gathering.strike(stripped, node)
		Sim.advance(stripped, int(ore["regrow_ticks"]) + 2)
	expect(Farm.cells_with(stripped, &"ore").size() == 8,
		"and it is still all there after four days of stripping it",
		str(Farm.cells_with(stripped, &"ore").size()))

	# **A loose boulder does not come back**, which is the reward for clearing
	# one, and it is not iron so it does not touch this balance.
	var lawn_state := State.create(1304)
	var boulders := Farm.cells_with(lawn_state, &"rock")
	expect(boulders.size() > 0, "there are boulders on the lawn")
	var boulder: Vector2i = boulders[0]
	for _swing in 12:
		if Farm.is_empty(lawn_state, boulder):
			break
		Gathering.strike(lawn_state, boulder)
	Sim.advance(lawn_state, int(ore["regrow_ticks"]) * 3)
	expect(Farm.is_empty(lawn_state, boulder),
		"and a cleared one stays cleared - that is the build space you earned")

	# **Iron cannot be turned into more iron through the stall.** Selling a
	# tower's worth and buying it straight back has to be a loss, or mining
	# stops being the way you get iron.
	var paid := Shop.sell_price(GameData.IRON) * needed
	var back := Shop.buy_price(GameData.IRON) * needed
	expect(paid < back,
		"selling a tower's iron does not buy a tower's iron back",
		"$%d for it, $%d to replace it" % [paid, back])
	expect(Shop.buy_price(GameData.IRON) > Shop.sell_price(GameData.IRON),
		"the stall always charges more than it pays for iron",
		"%d against %d" % [Shop.buy_price(GameData.IRON),
			Shop.sell_price(GameData.IRON)])

	_completed += 1     # last line: an abandoned group never gets here


## Whether there is anywhere beside this cell that a person could stand.
func _somewhere_to_stand(state: Dictionary, cell: Vector2i) -> bool:
	for step in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0),
			Vector2i(-1, 0)]:
		var at: Vector2i = cell + (step as Vector2i)
		if Farm.walkable(state, at):
			return true
	return false


## Mine ore, and nothing else, for a whole day. Returns the iron.
##
## `travel` is ticks spent getting from one node to the next, so the same
## measurement can say what the cliff is worth standing on it and what it is
## worth walking around it.
func _mine_for_a_day(seed_value: int, travel: int) -> int:
	var state := State.create(seed_value)
	var start := Resources.amount(state, GameData.IRON)
	var swing := int((GameData.GATHERING[&"ore"] as Dictionary)["work_ticks"])
	var at := Vector2i(-1, -1)
	var left := 0

	for _tick in GameData.DAY_TICKS:
		if at == Vector2i(-1, -1):
			var free := Farm.cells_with(state, &"ore")
			if free.is_empty():
				Sim.advance(state, 1)       # nothing up; wait for regrowth
				continue
			at = free[0]
			left = swing + travel
		left -= 1
		if left <= 0:
			Gathering.strike(state, at)
			left = swing
			if Farm.is_empty(state, at):
				at = Vector2i(-1, -1)
		Sim.advance(state, 1)

	return Resources.amount(state, GameData.IRON) - start


## 0032 - oil: the first resource that costs a building.
func _task_0032_oil() -> void:
	# **Two ways in**, which is what "corn or fish" asks for.
	var into_oil: Array = []
	for id in Crafting.recipes_at(&"press"):
		into_oil.append(id)
	expect(into_oil.size() >= 2, "the press takes more than one thing",
		str(into_oil))
	var corn_route := false
	var fish_route := false
	for id in into_oil:
		var recipe: Dictionary = GameData.RECIPES[id]
		expect((recipe["output"] as Dictionary).has(GameData.OIL),
			"%s makes oil" % id, str(recipe["output"]))
		if (recipe["inputs"] as Dictionary).has(GameData.CORN):
			corn_route = true
		if (recipe["inputs"] as Dictionary).has(GameData.FISH):
			fish_route = true
	expect(corn_route, "corn presses into oil")
	expect(fish_route, "and so does fish")

	# **Oil is the most valuable thing on the farm to sell.**
	var dearest := &""
	var best := -1
	for res in GameData.sorted_names(GameData.SELL_PRICE.keys()):
		if int(GameData.SELL_PRICE[res]) > best:
			best = int(GameData.SELL_PRICE[res])
			dearest = res
	expect(dearest == GameData.OIL, "oil is the dearest thing in the ledger",
		"%s at $%d" % [dearest, best])

	# **And pressing gains value**, or the tension is not a tension: you would
	# keep the oil because selling it was worse, which is not a decision.
	var corn_in := 4 * int(GameData.SELL_PRICE[GameData.CORN])
	var oil_out := int(GameData.SELL_PRICE[GameData.OIL])
	expect(oil_out > corn_in,
		"four corn is worth more as a drop of oil than as four corn",
		"$%d against $%d" % [oil_out, corn_in])
	expect(GameData.check_chain(GameData.RECIPES,
		GameData.SELL_PRICE).is_empty(),
		"and every recipe in the game gains value",
		str(GameData.check_chain(GameData.RECIPES, GameData.SELL_PRICE)))
	var cheap: Dictionary = GameData.SELL_PRICE.duplicate()
	cheap[GameData.OIL] = 1
	expect(not GameData.check_chain(GameData.RECIPES, cheap).is_empty(),
		"a press that destroyed value would be refused")

	# **The temptation, in money.** A flamethrower's oil against what that oil
	# would fetch at the stall.
	var flame: Dictionary = (GameData.DEFENCES[&"flame_tower"] as Dictionary)["cost"]
	expect(flame.has(GameData.OIL), "the flamethrower burns oil", str(flame))
	var tower_oil := int(flame[GameData.OIL])
	var temptation := tower_oil * oil_out
	print("  a flamethrower is %d oil - $%d if you sell it instead"
		% [tower_oil, temptation])
	expect(temptation > int(GameData.REWARDS["base_money"]) * 3,
		"and selling it instead is real money, not pocket change",
		"$%d" % temptation)

	# **A press is built, not inherited.** It costs, it covers four tiles, and
	# it will not hang off the edge of the farm.
	var state := State.create(1400)
	expect(Building.is_placeable(&"press"), "a press can be placed")
	expect(Building.size_of(&"press") == Vector2i(2, 2), "two by two",
		str(Building.size_of(&"press")))
	expect(Building.footprint(&"press", Vector2i(4, 4)).size() == 4,
		"covering four cells")
	expect(Building.catalogue(state).has(&"press"),
		"and the build palette offers it")

	var cost := Building.cost_of(&"press")
	expect(not cost.is_empty(), "it costs something", str(cost))
	expect(not Building.affordable(state, &"press"),
		"and a farm on day one cannot afford it - that is the point of the task")
	Resources.gain(state, cost)
	expect(Building.affordable(state, &"press"), "having gathered for it, it can")

	var spot := _room_for(state, Vector2i(2, 2))
	expect(spot != Vector2i(-1, -1), "there is room for one")
	var purse := Resources.amount(state, GameData.WOOD)
	expect(Building.place(state, &"press", spot), "and down it goes")
	expect(Resources.amount(state, GameData.WOOD)
		< purse, "paid for out of the ledger")
	for at in Building.footprint(&"press", spot):
		expect(Farm.occupant(state, at).get("id", &"") == &"press",
			"every tile of it is press", str(at))
		expect(Building.anchor_of(state, at) == spot,
			"and every tile points at the same press", str(at))
		expect(not Farm.walkable(state, at), "you cannot walk through it")

	# **Off the edge is refused, and refused before anything is paid.**
	var edge := State.create(1401)
	Resources.gain(edge, Building.cost_of(&"press"))
	var wood_before := Resources.amount(edge, GameData.WOOD)
	var brink := Vector2i(-1, -1)
	for y in Grid.HEIGHT:
		var at := Vector2i(Grid.WIDTH - 1, y)
		if Farm.buildable(edge, at):
			brink = at
			break
	expect(brink != Vector2i(-1, -1), "there is a clear cell on the east edge")
	expect(not Building.place(edge, &"press", brink),
		"a press hanging off the farm is refused", str(brink))
	expect(Resources.amount(edge, GameData.WOOD) == wood_before,
		"and nothing was charged for it",
		str(Resources.amount(edge, GameData.WOOD)))
	expect(Farm.occupant(edge, brink).is_empty(),
		"and no half a press was left behind")

	# **Standing at any tile of it works the same press.**
	var corner: Vector2i = Building.footprint(&"press", spot)[3]
	expect(Interact.verb_at(state, corner) == &"craft",
		"a press offers to make something",
		str(Interact.verb_at(state, corner)))
	expect(Crafting.selected_at(state, &"press") != &"",
		"and it arrives knowing what to make",
		str(Crafting.selected_at(state, &"press")))
	expect(Crafting.selected_at(state, &"press") in Crafting.recipes_at(&"press"),
		"which is something a press can make")

	# **The press runs for exactly the ticks the recipe says.** The done-when.
	var recipe_id := &"press_oil"
	var recipe: Dictionary = GameData.RECIPES[recipe_id]
	var ticks := int(recipe["ticks"])
	expect(Crafting.select_recipe(state, recipe_id), "set it to press oil")
	Resources.gain(state, recipe["inputs"])
	var corn_before := Resources.amount(state, GameData.CORN)
	var oil_before := Resources.amount(state, GameData.OIL)

	expect(Interact.verb_at(state, corner) == &"craft", "still offers craft")
	Interact.complete(state, corner, &"craft")
	expect(Crafting.busy(state, spot),
		"pressing interact at the far corner starts a job on the press")
	expect(Resources.amount(state, GameData.CORN)
		== corn_before - int((recipe["inputs"] as Dictionary)[GameData.CORN]),
		"the corn goes in when the job starts, not when it finishes",
		str(Resources.amount(state, GameData.CORN)))

	Sim.advance(state, ticks - 1)
	expect(Resources.amount(state, GameData.OIL) == oil_before,
		"no oil a tick early", str(Resources.amount(state, GameData.OIL)))
	expect(Crafting.busy(state, spot), "and the press is still working")
	Sim.advance(state, 1)
	expect(Resources.amount(state, GameData.OIL)
		== oil_before + int((recipe["output"] as Dictionary)[GameData.OIL]),
		"and on the tick the recipe says, oil",
		str(Resources.amount(state, GameData.OIL)))
	expect(not Crafting.busy(state, spot), "the press is free again")
	print("  the press: %d corn in, %d ticks, %d oil out"
		% [int((recipe["inputs"] as Dictionary)[GameData.CORN]), ticks,
			int((recipe["output"] as Dictionary)[GameData.OIL])])

	# **Throughput is a lever**, which means the tick count is the only thing
	# that decides how long it takes.
	expect(ticks > 0 and ticks == int(GameData.RECIPES[recipe_id]["ticks"]),
		"the press runs on the recipe's own tick count", str(ticks))

	# **Four corners, one job.** Four presses' worth of work out of one press
	# would be the bug a 2x2 station invites.
	Resources.gain(state, {GameData.CORN: 40})
	Interact.complete(state, corner, &"craft")
	expect(Crafting.busy(state, spot), "a job is running")
	var corn_mid := Resources.amount(state, GameData.CORN)
	for at in Building.footprint(&"press", spot):
		Interact.complete(state, at, &"craft")
	expect(Resources.amount(state, GameData.CORN) == corn_mid,
		"and the other three corners take no more corn - it is one press",
		str(Resources.amount(state, GameData.CORN)))

	# **Oil can be sold.**
	Sim.advance(state, ticks)
	var oil_held := Resources.amount(state, GameData.OIL)
	expect(oil_held > 0, "there is oil to sell", str(oil_held))
	expect(Shop.sellable().has(GameData.OIL), "and the stall takes it")
	var money_before := Resources.amount(state, GameData.MONEY)
	var paid := Shop.sell(state, GameData.OIL, oil_held)
	expect(paid == oil_held * oil_out, "at the price the table says",
		"$%d for %d" % [paid, oil_held])
	expect(Resources.amount(state, GameData.MONEY) == money_before + paid,
		"and the money arrives")
	expect(Resources.amount(state, GameData.OIL) == 0, "and the oil is gone")

	# **Selling any tile of it sells the whole press.**
	var torn := State.create(1402)
	Resources.gain(torn, Building.cost_of(&"press"))
	var plot := _room_for(torn, Vector2i(2, 2))
	expect(Building.place(torn, &"press", plot), "a press to tear down")
	var far: Vector2i = Building.footprint(&"press", plot)[3]
	var back := Building.sell(torn, far)
	expect(not back.is_empty(), "selling the far corner sells it", str(back))
	for at in Building.footprint(&"press", plot):
		expect(Farm.is_empty(torn, at),
			"and every tile of it comes up", str(at))

	_completed += 1     # last line: an abandoned group never gets here


## Somewhere a thing of this size will fit, clear of everything.
func _room_for(state: Dictionary, size: Vector2i) -> Vector2i:
	for y in range(Grid.HEIGHT - size.y):
		for x in range(Grid.WIDTH - size.x):
			var origin := Vector2i(x, y)
			var clear := true
			for dy in size.y:
				for dx in size.x:
					if not Farm.buildable(state, origin + Vector2i(dx, dy)):
						clear = false
						break
				if not clear:
					break
			if clear:
				return origin
	return Vector2i(-1, -1)


## 0033 - energy: a rate, and a farm that slows rather than stops.
func _task_0033_power() -> void:
	# **Energy is not a stockpile**, and the clearest statement of that is that
	# there is none of it in the ledger, ever.
	var state := State.create(1500)
	expect(Resources.amount(state, GameData.ENERGY) == 0,
		"no energy in the ledger", str(Resources.amount(state, GameData.ENERGY)))
	Sim.advance(state, 300)
	expect(Resources.amount(state, GameData.ENERGY) == 0,
		"and none accumulates - it is a rate, not a tank",
		str(Resources.amount(state, GameData.ENERGY)))

	# **A bare farm runs at full speed.** Nothing built, nothing drawing.
	expect(Power.draw(state) == 0, "an empty farm draws nothing",
		str(Power.draw(state)))
	expect(Power.supply(state) == GameData.BASE_ENERGY,
		"and makes its own trickle", str(Power.supply(state)))
	expect(Power.percent(state) == 100, "so everything runs at full speed")
	expect(not Power.is_short(state), "and nothing is short")

	# **Draw is what is standing on the farm.**
	Resources.gain(state, {GameData.WOOD: 400, GameData.IRON: 400,
		GameData.STONE: 400, GameData.OIL: 400, GameData.GUNPOWDER: 200})
	var towers := _line_of_towers(state, &"gun_tower", GameData.BASE_ENERGY)
	expect(towers.size() == GameData.BASE_ENERGY, "a tower per unit of supply",
		str(towers.size()))
	Sim.advance(state, 1)
	var each := int((GameData.DEFENCES[&"gun_tower"]
		as Dictionary)["energy_draw"])
	expect(Power.draw(state) == towers.size() * each,
		"every tower draws", str(Power.draw(state)))
	expect(Power.percent(state) == 100,
		"and the farm's own supply covers exactly this many",
		"%d/%d" % [Power.supply(state), Power.draw(state)])

	# **One too many, and everything slows.** The done-when.
	var reload := int((GameData.DEFENCES[&"gun_tower"]
		as Dictionary)["reload_ticks"])
	expect(Power.scaled_ticks(state, reload) == reload,
		"a full farm reloads in the time the table says", str(reload))

	var extra := _line_of_towers(state, &"gun_tower", 1, towers)
	expect(extra.size() == 1, "one more tower goes up")
	Sim.advance(state, 1)
	expect(Power.is_short(state), "and now the farm is short",
		"%d/%d" % [Power.supply(state), Power.draw(state)])
	var slowed := Power.scaled_ticks(state, reload)
	print("  %d towers on %d supply: %d%% - reload %d ticks becomes %d"
		% [towers.size() + 1, Power.supply(state), Power.percent(state),
			reload, slowed])
	expect(slowed > reload, "so everything takes longer", str(slowed))
	expect(Power.percent(state) > 0 and slowed < reload * 100,
		"and nothing has stopped - slower, not off", str(slowed))

	# **It is proportional**, not a cliff. Twice the draw, about twice as slow.
	expect(Power.percent(state)
		== GameData.BASE_ENERGY * 100 / Power.draw(state),
		"the percentage is supply over draw", str(Power.percent(state)))

	# **The floor holds.** Build far past your means and the farm is slow, not
	# dead - `design.md` does not do punishment mechanics.
	var swamped := State.create(1501)
	Resources.gain(swamped, {GameData.WOOD: 900, GameData.IRON: 900})
	_line_of_towers(swamped, &"auto_crossbow", 12)
	Sim.advance(swamped, 1)
	expect(Power.draw(swamped) > GameData.BASE_ENERGY * 4,
		"a farm built well past its means", str(Power.draw(swamped)))
	expect(Power.percent(swamped) == GameData.UNPOWERED_PERCENT,
		"runs at the floor and no lower", str(Power.percent(swamped)))
	var crawl := Power.scaled_ticks(swamped, reload)
	expect(crawl == reload * 100 / GameData.UNPOWERED_PERCENT,
		"which is a quarter speed, not a stop", str(crawl))

	# **A generator supplies, burns fuel, and stops when the oil runs out.**
	var plant := State.create(1502)
	Resources.gain(plant, {GameData.WOOD: 400, GameData.IRON: 400})
	_line_of_towers(plant, &"auto_crossbow", 4)
	Sim.advance(plant, 1)
	var unpowered := Power.percent(plant)
	expect(unpowered < 100, "four hungry towers outrun the farm",
		"%d/%d" % [Power.supply(plant), Power.draw(plant)])

	Resources.gain(plant, Building.cost_of(&"generator"))
	var spot := _room_for(plant, Building.size_of(&"generator"))
	expect(Building.place(plant, &"generator", spot), "a generator goes up")
	expect(Power.generators(plant).size() == 1, "one generator",
		str(Power.generators(plant).size()))
	expect(Power.draw(plant) == 4 * int((GameData.DEFENCES[&"auto_crossbow"]
		as Dictionary)["energy_draw"]),
		"which draws nothing itself", str(Power.draw(plant)))

	var fuel: Dictionary = (GameData.BUILDINGS[&"generator"]
		as Dictionary)["fuel"]
	Resources.gain(plant, {GameData.OIL: 2})
	var oil_before := Resources.amount(plant, GameData.OIL)
	Sim.advance(plant, 1)
	expect(Power.is_running(plant, spot), "and it lights")
	expect(Resources.amount(plant, GameData.OIL)
		== oil_before - int(fuel[GameData.OIL]),
		"burning a drop to start", str(Resources.amount(plant, GameData.OIL)))
	expect(Power.supply(plant) == GameData.BASE_ENERGY
		+ int((GameData.BUILDINGS[&"generator"] as Dictionary)["energy_output"]),
		"and supplying on top of the farm's own",
		str(Power.supply(plant)))
	expect(Power.percent(plant) > unpowered,
		"so the towers speed up", "%d against %d"
			% [Power.percent(plant), unpowered])

	# It burns on the tick the lever says, and no sooner.
	var every := int((GameData.BUILDINGS[&"generator"]
		as Dictionary)["fuel_every_ticks"])
	var held := Resources.amount(plant, GameData.OIL)
	Sim.advance(plant, every - 2)
	expect(Resources.amount(plant, GameData.OIL) == held,
		"no second drop early", str(Resources.amount(plant, GameData.OIL)))
	Sim.advance(plant, 2)
	expect(Resources.amount(plant, GameData.OIL) == held - 1,
		"and one exactly when the lever says",
		str(Resources.amount(plant, GameData.OIL)))

	# Out of oil: it stops supplying, and the farm falls back to its own.
	Sim.advance(plant, every * 2)
	expect(Resources.amount(plant, GameData.OIL) == 0, "the oil runs out",
		str(Resources.amount(plant, GameData.OIL)))
	expect(not Power.is_running(plant, spot), "and the generator stops")
	expect(Power.supply(plant) == GameData.BASE_ENERGY,
		"leaving the farm on its own trickle", str(Power.supply(plant)))
	expect(Power.percent(plant) == unpowered,
		"exactly where it was before the generator",
		"%d against %d" % [Power.percent(plant), unpowered])

	# **A generator with nothing to power does not burn anything.**
	var idle := State.create(1503)
	Resources.gain(idle, Building.cost_of(&"generator"))
	Resources.gain(idle, {GameData.OIL: 5})
	var idle_spot := _room_for(idle, Building.size_of(&"generator"))
	expect(Building.place(idle, &"generator", idle_spot), "a generator alone")
	Sim.advance(idle, every * 3)
	expect(Resources.amount(idle, GameData.OIL) == 5,
		"burns nothing when nothing is drawing - there is no tank for it to "
		+ "go into", str(Resources.amount(idle, GameData.OIL)))

	# **Running out mid-night degrades the defence and the night resolves.**
	# The other done-when, driven all the way to the payout.
	var night := State.create(1504)
	Resources.gain(night, {GameData.WOOD: 600, GameData.IRON: 600})
	_line_of_towers(night, &"auto_crossbow", 5)
	Resources.gain(night, Building.cost_of(&"generator"))
	var gen := _room_for(night, Building.size_of(&"generator"))
	expect(Building.place(night, &"generator", gen), "a generator for the night")
	Resources.spend(night, GameData.OIL, Resources.amount(night, GameData.OIL))
	Resources.gain(night, {GameData.OIL: 1})    # one drop: a minute of power

	# **A late night**, because night one is over in forty seconds and a drop
	# of oil lasts a minute - the generator would outlive the wave and there
	# would be no brown-out to watch.
	night["day"] = 8
	Phases.begin_preparation(night)
	Sim.advance(night, GameData.PREPARATION_TICKS)
	expect(int(night["phase"]) == Phases.NIGHT, "a long night, with the lights on")
	Sim.advance(night, 1)           # the first night tick is what lights it
	expect(Power.is_running(night, gen), "the generator is turning")
	var lit := Power.percent(night)

	var dark_at := -1
	var shots := 0
	for t in 12000:
		var before := Towers.in_flight(night)
		Sim.advance(night, 1)
		if Towers.in_flight(night) > before:
			shots += 1
		if dark_at < 0 and not Power.is_running(night, gen):
			dark_at = t
		if int(night["phase"]) != Phases.NIGHT:
			break
	expect(dark_at > 0, "the oil ran out part way through", str(dark_at))
	expect(Power.percent(night) < lit, "and the farm dimmed",
		"%d then %d" % [lit, Power.percent(night)])
	expect(shots > 0, "the towers kept shooting in the dark", str(shots))
	expect(int(night["phase"]) == Phases.RESULT,
		"and the night resolved rather than hanging",
		Phases.name_of(int(night["phase"])))
	print("  a night on one drop of oil: dark at tick %d, %d shots, %s"
		% [dark_at, shots,
			"survived" if bool(Rewards.last(night)["survived"]) else "lost"])

	# **The build phase does not burn fuel**, because the clock does not run.
	var waiting := State.create(1505)
	Resources.gain(waiting, {GameData.WOOD: 400, GameData.IRON: 400})
	_line_of_towers(waiting, &"auto_crossbow", 4)
	Resources.gain(waiting, Building.cost_of(&"generator"))
	var idle_gen := _room_for(waiting, Building.size_of(&"generator"))
	Building.place(waiting, &"generator", idle_gen)
	Resources.spend(waiting, GameData.OIL,
		Resources.amount(waiting, GameData.OIL))
	Resources.gain(waiting, {GameData.OIL: 10})
	Phases.begin_preparation(waiting)
	var oil_at_dusk := Resources.amount(waiting, GameData.OIL)
	Sim.advance(waiting, GameData.PREPARATION_TICKS - 1)
	expect(Resources.amount(waiting, GameData.OIL) == oil_at_dusk,
		"a generator burns nothing while the player is deciding where to build",
		str(Resources.amount(waiting, GameData.OIL)))

	_completed += 1     # last line: an abandoned group never gets here


## `count` towers in a row somewhere they will fit. Returns where they went.
func _line_of_towers(state: Dictionary, id: StringName, count: int,
		avoid: Array = []) -> Array:
	var out: Array = []
	for y in range(2, Grid.HEIGHT - 2):
		for x in range(20, Grid.WIDTH - 2):
			if out.size() >= count:
				return out
			var cell := Vector2i(x, y)
			if avoid.has(cell):
				continue
			if Building.place(state, id, cell):
				out.append(cell)
	return out


## 0034 - the kitchen, the animals, and what food is actually for.
func _task_0034_cooking() -> void:
	# **Crops, fish and meat all become food.**
	var kitchen := Crafting.recipes_at(&"kitchen")
	expect(kitchen.size() >= 3, "the kitchen has a few things to cook",
		str(kitchen))
	var from_crop := false
	var from_fish := false
	var from_meat := false
	for id in kitchen:
		var recipe: Dictionary = GameData.RECIPES[id]
		expect((recipe["output"] as Dictionary).has(GameData.FOOD),
			"%s makes food" % id, str(recipe["output"]))
		var inputs: Dictionary = recipe["inputs"]
		for res in GameData.sorted_names(inputs.keys()):
			if GameData.CROPS.has(res):
				from_crop = true
			if res == GameData.FISH:
				from_fish = true
			if res == GameData.MEAT:
				from_meat = true
	expect(from_crop, "crops go in the pot")
	expect(from_fish, "and fish")
	expect(from_meat, "and meat")

	# **Every dish is worth more cooked than its parts sold separately**, or
	# the kitchen has no reason to exist. The margins, stated.
	for id in kitchen:
		var recipe: Dictionary = GameData.RECIPES[id]
		var into := _price_of(recipe["inputs"])
		var made := _price_of(recipe["output"])
		print("  %-11s $%2d of inputs -> $%2d of food   +$%d (%d%%)"
			% [id, into, made, made - into, made * 100 / maxi(into, 1)])
		expect(made > into, "%s is worth cooking" % id,
			"$%d against $%d" % [made, into])

	# **Meat comes from somewhere now.** It has been in the resource table with
	# a price and a recipe since task 0003 and nothing in the world made any.
	var state := State.create(1600)
	var cows := Farm.cells_with(state, &"cow")
	var hens := Farm.cells_with(state, &"chicken")
	expect(cows.size() > 0, "there is a cow on the farm", str(cows.size()))
	expect(hens.size() > 0, "and chickens", str(hens.size()))
	expect(GameData.check_livestock(GameData.LIVESTOCK,
		GameData.FARM_MAP).is_empty(),
		"the farm passes its own livestock check",
		str(GameData.check_livestock(GameData.LIVESTOCK, GameData.FARM_MAP)))
	var barren: Dictionary = GameData.LIVESTOCK.duplicate(true)
	for id in barren:
		(barren[id] as Dictionary)["produces"] = {GameData.WOOD: 1}
	expect(not GameData.check_livestock(barren, GameData.FARM_MAP).is_empty(),
		"and a farm where nothing produces meat is refused")

	# **A trickle: nothing to do but come back.**
	var cow: Vector2i = cows[0]
	var entry: Dictionary = GameData.LIVESTOCK[&"cow"]
	expect(Livestock.ready_at(state, cow) == 0, "the cow starts with nothing")
	expect(Interact.verb_at(state, cow) == &"",
		"and offers nothing to do", str(Interact.verb_at(state, cow)))

	Sim.advance(state, int(entry["every_ticks"]) - 1)
	expect(Livestock.ready_at(state, cow) == 0, "nothing a tick early")
	Sim.advance(state, 1)
	expect(Livestock.ready_at(state, cow) == 1,
		"and one on the tick the lever says", str(Livestock.ready_at(state, cow)))
	expect(Interact.verb_at(state, cow) == &"collect",
		"now there is something to take", str(Interact.verb_at(state, cow)))

	# **It fills up and stops.** A cow nobody visits does not bank a fortnight
	# of beef; the farm rewards coming back, not being left alone.
	Sim.advance(state, int(entry["every_ticks"]) * (int(entry["holds"]) + 3))
	expect(Livestock.ready_at(state, cow) == int(entry["holds"]),
		"a cow fills up and stops", str(Livestock.ready_at(state, cow)))

	var meat_before := Resources.amount(state, GameData.MEAT)
	Interact.complete(state, cow, &"collect")
	expect(Resources.amount(state, GameData.MEAT)
		== meat_before + int(entry["holds"]),
		"and collecting takes all of it",
		str(Resources.amount(state, GameData.MEAT)))
	expect(Livestock.ready_at(state, cow) == 0, "leaving the cow empty")
	expect(Interact.verb_at(state, cow) == &"",
		"with nothing to do until it has something again")
	var after_collect := Resources.amount(state, GameData.MEAT)
	Interact.complete(state, cow, &"collect")
	expect(Resources.amount(state, GameData.MEAT) == after_collect,
		"and collecting an empty cow takes nothing",
		str(Resources.amount(state, GameData.MEAT)))

	# **The animals are asleep at night**, like the rest of the farm.
	var nightly := State.create(1601)
	var hen: Vector2i = Farm.cells_with(nightly, &"chicken")[0]
	var hen_entry: Dictionary = GameData.LIVESTOCK[&"chicken"]
	Phases.begin_preparation(nightly)
	Sim.advance(nightly, GameData.PREPARATION_TICKS)
	Sim.advance(nightly, int(hen_entry["every_ticks"]) * 2)
	expect(Livestock.ready_at(nightly, hen) == 0,
		"a chicken lays nothing during a wave",
		str(Livestock.ready_at(nightly, hen)))
	expect(Interact.verb_at(nightly, hen) == &"",
		"and there is nothing to collect in the dark")

	# **Cooking, end to end, at a real kitchen.**
	var cooking := State.create(1602)
	Resources.gain(cooking, Building.cost_of(&"kitchen"))
	var spot := _room_for(cooking, Building.size_of(&"kitchen"))
	expect(Building.place(cooking, &"kitchen", spot), "a kitchen goes up")
	expect(Interact.verb_at(cooking, spot) == &"craft",
		"and offers to cook", str(Interact.verb_at(cooking, spot)))
	expect(Crafting.selected_at(cooking, &"kitchen") in kitchen,
		"knowing a kitchen recipe", str(Crafting.selected_at(cooking, &"kitchen")))

	var dish := &"cook_roast"
	var roast: Dictionary = GameData.RECIPES[dish]
	expect(Crafting.select_recipe(cooking, dish), "set it to the roast")
	Resources.gain(cooking, roast["inputs"])
	var food_before := Resources.amount(cooking, GameData.FOOD)
	Interact.complete(cooking, spot, &"craft")
	expect(Crafting.busy(cooking, spot), "it starts")
	Sim.advance(cooking, int(roast["ticks"]))
	expect(Resources.amount(cooking, GameData.FOOD)
		== food_before + int((roast["output"] as Dictionary)[GameData.FOOD]),
		"and out comes dinner",
		str(Resources.amount(cooking, GameData.FOOD)))

	# ------------------------------------------------ what food is actually for

	# **Repairing costs food, and it comes out of the ledger.** The done-when.
	expect(GameData.REPAIR_COST_PER_HP.has(GameData.FOOD),
		"repair is paid for in food", str(GameData.REPAIR_COST_PER_HP))
	var per_hp := Repair.cost_for(1)
	expect(per_hp == GameData.REPAIR_COST_PER_HP, "one hit point is one lot",
		str(per_hp))
	var ten := Repair.cost_for(10)
	for res in GameData.sorted_names(ten.keys()):
		expect(int(ten[res]) == int(GameData.REPAIR_COST_PER_HP[res]) * 10,
			"ten hit points is ten lots of %s" % res, str(ten[res]))
	expect(Repair.cost_for(0).is_empty(), "and nothing costs nothing")

	var hurt := State.create(1603)
	var house: Vector2i = Farm.cells_with(hurt, &"house")[0]
	Phases.begin_preparation(hurt)
	Sim.advance(hurt, GameData.PREPARATION_TICKS)
	expect(int(hurt["phase"]) == Phases.NIGHT, "it is night")
	expect(Repair.damage_at(hurt, house) == 0, "the house is whole")
	expect(not Repair.needs_repair(hurt, house), "so there is nothing to mend")
	expect(Repair.apply(hurt, house, 5) == 0,
		"and repairing a whole house does nothing")

	hurt["house_hp"] = GameData.HOUSE_HP - 20
	expect(Repair.damage_at(hurt, house) == 20, "twenty hit points of damage",
		str(Repair.damage_at(hurt, house)))
	expect(Repair.needs_repair(hurt, house), "which wants mending")

	# No food, no repair - and nothing taken for the attempt.
	for res in GameData.sorted_names(GameData.REPAIR_COST_PER_HP.keys()):
		Resources.spend(hurt, res, Resources.amount(hurt, res))
	expect(Repair.affordable_hp(hurt) == 0, "an empty larder buys no repair")
	expect(Repair.apply(hurt, house, 10) == 0, "so nothing goes back")
	expect(int(hurt["house_hp"]) == GameData.HOUSE_HP - 20,
		"and the house is where it was", str(hurt["house_hp"]))

	# With food, it does - and the food is gone from the ledger.
	Resources.gain(hurt, {GameData.FOOD: 12, GameData.WOOD: 12})
	var food_held := Resources.amount(hurt, GameData.FOOD)
	var wood_held := Resources.amount(hurt, GameData.WOOD)
	var put_back := Repair.apply(hurt, house, 8)
	expect(put_back == 8, "eight hit points go back", str(put_back))
	expect(int(hurt["house_hp"]) == GameData.HOUSE_HP - 12,
		"and the house is that much better", str(hurt["house_hp"]))
	expect(Resources.amount(hurt, GameData.FOOD)
		== food_held - 8 * int(GameData.REPAIR_COST_PER_HP[GameData.FOOD]),
		"paid for in food, out of the ledger",
		str(Resources.amount(hurt, GameData.FOOD)))
	expect(Resources.amount(hurt, GameData.WOOD)
		== wood_held - 8 * int(GameData.REPAIR_COST_PER_HP[GameData.WOOD]),
		"and in wood", str(Resources.amount(hurt, GameData.WOOD)))

	# **Never more than is broken, and never more than is paid for.**
	expect(Repair.max_affordable(hurt, house) == mini(12,
		Repair.affordable_hp(hurt)),
		"what is missing, capped by what is in the larder",
		str(Repair.max_affordable(hurt, house)))
	var rest := Repair.apply_all(hurt, house)
	expect(int(hurt["house_hp"]) <= GameData.HOUSE_HP,
		"a house is never mended past whole", str(hurt["house_hp"]))
	print("  repair: %d hp for %s, house back to %d/%d"
		% [put_back + rest, str(Repair.cost_for(put_back + rest)),
			int(hurt["house_hp"]), GameData.HOUSE_HP])

	# **Food is worth spending rather than selling**, at least sometimes: a
	# night's repair has to be a real alternative to the money.
	expect(int(GameData.SELL_PRICE[GameData.FOOD]) > 0,
		"food has a price, so spending it is a decision")
	expect(int(GameData.REPAIR_COST_PER_HP[GameData.FOOD]) > 0,
		"and repair is what it is spent on")

	_completed += 1     # last line: an abandoned group never gets here


## What a pile of resources fetches at the stall.
func _price_of(amounts: Dictionary) -> int:
	var total := 0
	for res in GameData.sorted_names(amounts.keys()):
		total += int(GameData.SELL_PRICE.get(res, 0)) * int(amounts[res])
	return total


## 0035 - what you made today decides what tonight can do.
func _task_0035_ammunition() -> void:
	# **Both kinds of round, from what `design.md` section 5 says makes them.**
	var powder: Dictionary = GameData.RECIPES[&"make_gunpowder"]
	expect((powder["inputs"] as Dictionary).has(GameData.CORN)
		and (powder["inputs"] as Dictionary).has(GameData.OIL),
		"gunpowder comes from corn and oil", str(powder["inputs"]))
	var rounds: Dictionary = GameData.RECIPES[&"make_incendiary"]
	expect((rounds["inputs"] as Dictionary).has(GameData.OIL)
		and (rounds["inputs"] as Dictionary).has(GameData.WOOD),
		"and incendiary rounds from oil and wood", str(rounds["inputs"]))
	expect((rounds["output"] as Dictionary).has(GameData.INCENDIARY),
		"which is what comes out", str(rounds["output"]))

	# **Everything a tower fires can be made.** The meat bug of task 0034, one
	# table along: a tower may declare it fires anything at all.
	expect(GameData.check_ammo(GameData.DEFENCES, GameData.RECIPES).is_empty(),
		"every round a tower fires is one the farm can make",
		str(GameData.check_ammo(GameData.DEFENCES, GameData.RECIPES)))
	var exotic: Dictionary = GameData.DEFENCES.duplicate(true)
	(exotic[&"mortar"] as Dictionary)["ammo"] = {GameData.MEAT: 1}
	expect(not GameData.check_ammo(exotic, GameData.RECIPES).is_empty(),
		"and a tower firing something no recipe makes is refused")

	# **The flamethrower burns rounds, not raw oil.** It used to declare a drop
	# of oil every two seconds, which at $26 a drop is eleven hundred dollars of
	# fuel across one night.
	var flame := Ammo.needed_by(&"flame_tower")
	expect(flame.has(GameData.INCENDIARY),
		"the flamethrower burns incendiary rounds", str(flame))
	expect(not flame.has(GameData.OIL),
		"and not the oil itself - that is what the rounds are made of")
	var per_round := 0
	for res in GameData.sorted_names((rounds["inputs"] as Dictionary).keys()):
		per_round += int(GameData.SELL_PRICE.get(res, 0)) \
			* int((rounds["inputs"] as Dictionary)[res])
	print("  a burst of %d rounds costs $%d of goods, against $%d of raw oil"
		% [int((rounds["output"] as Dictionary)[GameData.INCENDIARY]), per_round,
			int((rounds["output"] as Dictionary)[GameData.INCENDIARY])
				* int(GameData.SELL_PRICE[GameData.OIL])])

	# **One pool, in the ledger, shared.**
	var state := State.create(1700)
	expect(Ammo.kinds().size() >= 2, "there is more than one kind of round",
		str(Ammo.kinds()))
	for res in Ammo.kinds():
		expect(GameData.RESOURCES.has(res),
			"%s is a resource, so it is in the ledger" % res)
	expect(not Ammo.uses_ammo(&"gun_tower"),
		"the basic tower needs nothing - it is what you have on a bad day")
	expect(Ammo.uses_ammo(&"mortar"), "the mortar does")
	expect(Ammo.shots_left(state, &"gun_tower") > 1000,
		"a tower that needs nothing is never short",
		str(Ammo.shots_left(state, &"gun_tower")))

	Resources.spend(state, GameData.GUNPOWDER,
		Resources.amount(state, GameData.GUNPOWDER))
	expect(Ammo.shots_left(state, &"mortar") == 0, "an empty pool is empty")
	expect(not Ammo.has_ammo(state, &"mortar"), "and the mortar knows it")
	Resources.gain(state, {GameData.GUNPOWDER: 7})
	expect(Ammo.shots_left(state, &"mortar") == 7, "seven rounds, seven shots",
		str(Ammo.shots_left(state, &"mortar")))
	expect(Ammo.spend(state, &"mortar"), "firing takes one")
	expect(Resources.amount(state, GameData.GUNPOWDER) == 6,
		"out of the ledger", str(Resources.amount(state, GameData.GUNPOWDER)))

	# **Towers compete for it.** Six mortars drain it six times as fast, which
	# is what makes how many you build a question about supply.
	for _i in 6:
		Ammo.spend(state, &"mortar")
	expect(Resources.amount(state, GameData.GUNPOWDER) == 0,
		"six more shots and it is gone",
		str(Resources.amount(state, GameData.GUNPOWDER)))
	expect(not Ammo.spend(state, &"mortar"),
		"and the seventh finds nothing")
	expect(Resources.amount(state, GameData.GUNPOWDER) == 0,
		"taking nothing for the attempt")

	# **The weak shot is weak, not absent.**
	var full := int((GameData.DEFENCES[&"mortar"] as Dictionary)["damage"])
	expect(Ammo.weak_damage(full) < full, "an unarmed shot hits for less",
		"%d against %d" % [Ammo.weak_damage(full), full])
	expect(Ammo.weak_damage(full) > 0, "but it does hit",
		str(Ammo.weak_damage(full)))
	expect(Ammo.weak_damage(1) >= 1,
		"and the weakest tower in the game still does something")
	var reload := int((GameData.DEFENCES[&"mortar"] as Dictionary)["reload_ticks"])
	expect(Ammo.weak_reload(reload) > reload, "and takes longer over it",
		"%d against %d" % [Ammo.weak_reload(reload), reload])
	expect(Ammo.weak_reload(reload) < reload * 10,
		"but not so long that it may as well have stopped",
		str(Ammo.weak_reload(reload)))

	# **The pool drains at the rate the levers claim.** The done-when: a
	# scripted night, counting shots against rounds spent.
	var armed := _mixed_night(1701, 60)
	var spent := 60 - int(armed["left"])
	print("  a night with 60 rounds: %d shots (%s), %d rounds gone, %d left"
		% [int(armed["shots"]), str(armed["by_kind"]), spent,
			int(armed["left"])])
	expect(int(armed["mortar_shots"]) > 0, "the mortars fired",
		str(armed["by_kind"]))
	var per_shot := int((GameData.DEFENCES[&"mortar"]
		as Dictionary)["ammo"][GameData.GUNPOWDER])
	expect(spent == int(armed["mortar_shots"]) * per_shot,
		"one round per mortar shot, exactly what the table says - and nothing "
		+ "at all for the gun towers, which fire for free",
		"%d rounds for %d mortar shots of %d total"
			% [spent, armed["mortar_shots"], armed["shots"]])

	# **Ammunition left over carries into the next night.** Nothing clears it,
	# because it is a resource - but that is worth an assert rather than a
	# assumption.
	var carried := int(armed["left"])
	if carried > 0:
		var after: Dictionary = armed["state"]
		(after["intent"] as Dictionary)["confirm_result"] = true
		Sim.advance(after, 1)
		expect(int(after["phase"]) == Phases.DAY, "morning")
		expect(Resources.amount(after, GameData.GUNPOWDER) >= carried,
			"and what was left in the pool is still there",
			str(Resources.amount(after, GameData.GUNPOWDER)))

	# **A night with no powder is survivable but clearly worse.** The other
	# done-when, measured: the same night, the same seed, the same towers.
	var dry := _mixed_night(1701, 0)
	print("  with powder: %d killed, house %d, %d mortar shots"
		% [int(armed["killed"]), int(armed["house"]),
			int(armed["mortar_shots"])])
	print("  without:     %d killed, house %d, %d mortar shots"
		% [int(dry["killed"]), int(dry["house"]), int(dry["mortar_shots"])])
	expect(int(dry["mortar_shots"]) > 0,
		"an empty pool still shoots - never a silent dead tower",
		str(dry["by_kind"]))
	expect(int(dry["mortar_shots"]) < int(armed["mortar_shots"]),
		"more slowly", "%d against %d"
			% [dry["mortar_shots"], armed["mortar_shots"]])
	expect(int(dry["killed"]) < int(armed["killed"]),
		"and it kills fewer",
		"%d against %d" % [dry["killed"], armed["killed"]])
	expect(int(dry["house"]) < int(armed["house"]),
		"and the house takes more for it",
		"%d against %d" % [dry["house"], armed["house"]])
	expect(int(dry["house"]) > 0,
		"but the night is survivable without a workshop behind it",
		str(dry["house"]))

	_completed += 1     # last line: an abandoned group never gets here


## A scripted night behind a mixed defence, with `rounds` in the pool.
##
## Everything about it is fixed - the seed, the towers, the night, the power -
## so the only thing that differs between two runs is the ammunition.
##
## **Gun towers as well as mortars**, deliberately. A mortar cannot defend
## itself inside its own minimum range, so a farm defended only by mortars
## loses whatever is in the pool; and a night that is lost both ways cannot
## show that the pool made a difference. The guns need no ammunition, which is
## also the answer to "what do I do on a night the workshop stood idle".
##
## **A generator, with oil**, so that energy is not the variable. Six towers on
## the farm's own four would be running at two thirds speed and the comparison
## would be measuring that instead.
##
## **A late night**, because an early one is over before the difference shows:
## on night three the guns alone held it without the house being touched, and
## with powder and without came out identical in every number.
func _mixed_night(seed_value: int, rounds: int) -> Dictionary:
	var state := State.create(seed_value)
	# **Gunpowder to build with, as well as to fire.** A mortar costs fifteen
	# of it, so the first version of this granted wood, iron, stone and oil and
	# then placed no mortars at all - and reported seventy-two shots and zero
	# rounds spent, which is exactly what three gun towers on their own look
	# like. The pool is emptied again below, after the building is paid for.
	Resources.gain(state, {GameData.WOOD: 900, GameData.IRON: 900,
		GameData.STONE: 900, GameData.OIL: 400, GameData.GUNPOWDER: 200})

	var guns := 0
	for y in [7, 9]:
		for x in range(22, 30):
			if guns >= 2:
				break
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				guns += 1
		if guns >= 2:
			break
	var mortars := 0
	for y in [7, 9, 11, 12]:
		for x in range(10, 18):
			if mortars >= 4:
				break
			if Building.place(state, &"mortar", Vector2i(x, y)):
				mortars += 1
		if mortars >= 4:
			break

	var gen := _room_for(state, Building.size_of(&"generator"))
	Building.place(state, &"generator", gen)

	# The pool, set exactly, after everything is paid for.
	Resources.spend(state, GameData.GUNPOWDER,
		Resources.amount(state, GameData.GUNPOWDER))
	if rounds > 0:
		Resources.gain(state, {GameData.GUNPOWDER: rounds})
	Resources.gain(state, {GameData.OIL: 80})

	state["day"] = 7
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(guns == 2 and mortars == 4,
		"the scripted night has the towers it thinks it has",
		"%d guns, %d mortars" % [guns, mortars])

	# **Shots counted per kind, off the projectile id.** Watching `in_flight`
	# misses a shot created and resolved inside one tick, which at a mortar's
	# range is most of them; and a total across all towers cannot be compared
	# against rounds spent, because a gun tower fires for nothing.
	var next_id := int(state["next_projectile_id"])
	var by_kind := {}
	for _t in 20000:
		Sim.advance(state, 1)
		for shot in (state["projectiles"] as Array):
			var fired: Dictionary = shot
			if int(fired["id"]) < next_id:
				continue
			var kind: StringName = fired["from"]
			by_kind[kind] = int(by_kind.get(kind, 0)) + 1
			next_id = maxi(next_id, int(fired["id"]) + 1)
		if int(state["phase"]) != Phases.NIGHT:
			break

	var total := 0
	for kind in GameData.sorted_names(by_kind.keys()):
		total += int(by_kind[kind])

	return {
		"state": state,
		"shots": total,
		"by_kind": by_kind,
		"mortar_shots": int(by_kind.get(&"mortar", 0)),
		"left": Resources.amount(state, GameData.GUNPOWDER),
		"killed": int(state["killed"]),
		"house": int(state["house_hp"]),
		"survived": bool((Rewards.last(state) as Dictionary).get("survived",
			false)),
		"towers": guns + mortars,
	}


## 0036 - everything you own, once each.
func _task_0036_inventory() -> void:
	var state := State.create(1800)

	# **Every resource appears, and none of them twice.** The done-when.
	var rows := Inventory.rows(state)
	var seen: Dictionary = {}
	for entry in rows:
		var r: Dictionary = entry
		var id: StringName = r["id"]
		expect(not seen.has(id), "%s is listed once" % id)
		seen[id] = true
		expect(GameData.RESOURCES.has(id),
			"and %s is a real resource" % id)
	expect(rows.size() == GameData.RESOURCES.size(),
		"every resource in game_data is on the list",
		"%d rows for %d resources"
			% [rows.size(), GameData.RESOURCES.size()])
	for id in GameData.RESOURCES:
		expect(seen.has(id), "%s is not left off" % id)

	# **Grouped, and the groups are the reference sheet's.**
	var grouped := Inventory.groups(state)
	expect(grouped.size() >= 2, "there is more than one group",
		str(grouped.size()))
	var names: Array = []
	for entry in grouped:
		names.append(StringName((entry as Dictionary)["name"]))
	expect(names.size() == GameData.sorted_names(names).size(),
		"no group appears twice", str(names))
	print("  %d rows in %d groups: %s"
		% [rows.size(), grouped.size(), str(names)])

	expect(GameData.check_groups(GameData.RESOURCE_GROUPS,
		GameData.RESOURCES).is_empty(),
		"the shipped grouping passes its own check",
		str(GameData.check_groups(GameData.RESOURCE_GROUPS,
			GameData.RESOURCES)))
	var twice: Array = GameData.RESOURCE_GROUPS.duplicate(true)
	((twice[1] as Dictionary)["members"] as Array).append(GameData.WOOD)
	expect(not GameData.check_groups(twice, GameData.RESOURCES).is_empty(),
		"and a resource put in two groups is refused")
	var ghost: Array = GameData.RESOURCE_GROUPS.duplicate(true)
	((ghost[0] as Dictionary)["members"] as Array).append(&"moonstone")
	expect(not GameData.check_groups(ghost, GameData.RESOURCES).is_empty(),
		"and a group naming something that is not a resource")

	# **Nothing falls off the end.** Every resource is in a named group, so the
	# catch-all is empty today - and it is there so that the day somebody adds
	# a resource and forgets the grouping table, it shows up anyway.
	var stray := 0
	for entry in grouped:
		if StringName((entry as Dictionary)["name"]) == GameData.GROUP_OTHER:
			stray = ((entry as Dictionary)["rows"] as Array).size()
	expect(stray == 0, "everything the game ships with has a group",
		str(stray))

	# **It is a view of the ledger, not a copy of it.**
	var before := 0
	for entry in Inventory.rows(state):
		if StringName((entry as Dictionary)["id"]) == GameData.WOOD:
			before = int((entry as Dictionary)["held"])
	Resources.gain(state, {GameData.WOOD: 7})
	var after := 0
	for entry in Inventory.rows(state):
		if StringName((entry as Dictionary)["id"]) == GameData.WOOD:
			after = int((entry as Dictionary)["held"])
	expect(after == before + 7,
		"a number that moves in the ledger has moved here too",
		"%d then %d" % [before, after])
	expect(not state.has("inventory"),
		"and there is no inventory in the state to disagree with it",
		str(state.keys().size()))

	# **Prices, and the difference between free and not for sale.**
	for entry in Inventory.rows(state):
		var r: Dictionary = entry
		if GameData.SELL_PRICE.has(r["id"]):
			expect(bool(r["sellable"]), "%s can be sold" % r["id"])
			expect(int(r["price"]) == int(GameData.SELL_PRICE[r["id"]]),
				"at the price the table says", str(r["price"]))
		else:
			expect(not bool(r["sellable"]),
				"%s is not for sale, which is not the same as worth nothing"
					% r["id"])
	expect(not GameData.SELL_PRICE.has(GameData.MONEY),
		"money does not sell for money")
	expect(not GameData.SELL_PRICE.has(GameData.ENERGY),
		"and energy is a rate, not a thing in a sack")

	# **What the larder is worth**, which is what the shop of task 0040 shows
	# against what you are about to spend.
	var by_hand := 0
	for entry in Inventory.rows(state):
		var r: Dictionary = entry
		by_hand += int(r["held"]) * int(r["price"])
	expect(Inventory.worth(state) == by_hand, "the total is the sum of it",
		str(Inventory.worth(state)))

	var bare := State.create(1801)
	for id in GameData.RESOURCES:
		Resources.spend(bare, id, Resources.amount(bare, id))
	expect(Inventory.worth(bare) == 0, "an empty farm is worth nothing",
		str(Inventory.worth(bare)))
	expect(Inventory.kinds_held(bare) == 0, "and holds nothing")
	expect(Inventory.rows(bare).size() == rows.size(),
		"but still lists everything - a resource you have none of is a "
		+ "resource you can go and get", str(Inventory.rows(bare).size()))
	Resources.gain(bare, {GameData.IRON: 3})
	expect(Inventory.kinds_held(bare) == 1, "one kind held")
	expect(Inventory.worth(bare)
		== 3 * int(GameData.SELL_PRICE[GameData.IRON]),
		"and worth what it is worth", str(Inventory.worth(bare)))

	# **The order is fixed**, so two runs draw the same panel.
	var again := Inventory.rows(State.create(1800))
	var first_ids: Array = []
	var second_ids: Array = []
	for entry in rows:
		first_ids.append(StringName((entry as Dictionary)["id"]))
	for entry in again:
		second_ids.append(StringName((entry as Dictionary)["id"]))
	expect(first_ids == second_ids, "the panel is in the same order every run",
		str(second_ids))

	_completed += 1     # last line: an abandoned group never gets here


## 0037 - queue five things, walk away, come back to five things.
func _task_0037_queue() -> void:
	var state := State.create(1900)
	Resources.gain(state, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench := Building.anchor_of(state,
		Farm.cells_with(state, &"workshop")[0])

	# **The queue has a length and it is a lever.**
	expect(Crafting.room_at(state, bench) == GameData.QUEUE_LENGTH,
		"an idle bench will take a full queue",
		str(Crafting.room_at(state, bench)))
	for _i in GameData.QUEUE_LENGTH:
		expect(Crafting.enqueue(state, bench, &"barricade_kit"),
			"another one goes on")
	expect(Crafting.room_at(state, bench) == 0, "until it is full")
	expect(not Crafting.enqueue(state, bench, &"barricade_kit"),
		"and then it takes no more")
	expect(Crafting.queue_at(state, bench).size() == GameData.QUEUE_LENGTH,
		"exactly as many as the lever says",
		str(Crafting.queue_at(state, bench).size()))
	Crafting.cancel_all(state, bench)

	# **Inputs are taken when an item starts, not when it is queued.**
	var recipe: Dictionary = GameData.RECIPES[&"barricade_kit"]
	var wood_each := int((recipe["inputs"] as Dictionary)[GameData.WOOD])
	var wood_before := Resources.amount(state, GameData.WOOD)
	for _i in 3:
		Crafting.enqueue(state, bench, &"barricade_kit")
	expect(Resources.amount(state, GameData.WOOD)
		== wood_before - wood_each,
		"three queued, one paid for - the front one and no more",
		"%d of %d" % [wood_before - Resources.amount(state, GameData.WOOD),
			wood_each * 3])
	expect(Crafting.making(state, bench) == &"barricade_kit",
		"the first is running", str(Crafting.making(state, bench)))
	expect(not Crafting.is_stalled(state, bench), "and not waiting on anything")

	# **Cancelling one that has not started costs nothing and gives nothing.**
	var held := Resources.amount(state, GameData.WOOD)
	expect(Crafting.cancel_at(state, bench, 2),
		"the third can be taken off")
	expect(Resources.amount(state, GameData.WOOD) == held,
		"and nothing comes back, because nothing went in",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Crafting.queue_at(state, bench).size() == 2, "two left",
		str(Crafting.queue_at(state, bench).size()))

	# **Cancelling the running one loses its inputs.** That is what makes
	# stopping a decision rather than a free undo.
	Crafting.cancel_at(state, bench, 0)
	expect(Resources.amount(state, GameData.WOOD) == held - wood_each,
		"the next one steps up and pays its own way",
		str(Resources.amount(state, GameData.WOOD)))
	expect(Crafting.queue_at(state, bench).size() == 1, "one left")
	Crafting.cancel_all(state, bench)

	# ---------------------------------------------------- the two done-whens

	# **Queue three barricades, walk to the pond and back, and three exist.**
	var walk := State.create(1901)
	Resources.gain(walk, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench2 := Building.anchor_of(walk,
		Farm.cells_with(walk, &"workshop")[0])
	var kits_before := Crafting.kits(walk, &"barricade")
	var larder := Resources.amount(walk, GameData.WOOD)
	for _i in 3:
		expect(Crafting.enqueue(walk, bench2, &"barricade_kit"),
			"one of three on the queue")

	# Off to the pond, which is the far corner of the farm, and back.
	var pond: Vector2i = Farm.cells_of(walk, Farm.Terrain.WATER)[0]
	var who: Dictionary = walk["player"]
	who["pos"] = [pond.x * Player.SUBTILE + Player.SUBTILE / 2,
		(pond.y - 1) * Player.SUBTILE + Player.SUBTILE / 2]
	var each := int(recipe["ticks"])
	Sim.advance(walk, each * 3 + 6)
	who["pos"] = [bench2.x * Player.SUBTILE + Player.SUBTILE / 2,
		(bench2.y + 1) * Player.SUBTILE + Player.SUBTILE / 2]

	expect(Crafting.kits(walk, &"barricade") == kits_before + 3,
		"three queued, three made, nobody watching",
		str(Crafting.kits(walk, &"barricade")))
	expect(not Crafting.busy(walk, bench2), "and the bench is free again")
	expect(larder - Resources.amount(walk, GameData.WOOD) == wood_each * 3,
		"having paid for exactly three",
		"%d of wood gone" % (larder - Resources.amount(walk, GameData.WOOD)))

	# **Cancelling the second of three leaves the first and the third.**
	var three := State.create(1902)
	Resources.gain(three, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench3 := Building.anchor_of(three,
		Farm.cells_with(three, &"workshop")[0])
	Crafting.enqueue(three, bench3, &"barricade_kit")
	Crafting.enqueue(three, bench3, &"fence_kit")
	Crafting.enqueue(three, bench3, &"wall_kit")
	expect(Crafting.queue_at(three, bench3)
		== [&"barricade_kit", &"fence_kit", &"wall_kit"],
		"three different things, in order",
		str(Crafting.queue_at(three, bench3)))

	expect(Crafting.cancel_at(three, bench3, 1), "the middle one comes off")
	expect(Crafting.queue_at(three, bench3) == [&"barricade_kit", &"wall_kit"],
		"leaving the first and the third, in order",
		str(Crafting.queue_at(three, bench3)))
	expect(Crafting.making(three, bench3) == &"barricade_kit",
		"the one that was running is still running",
		str(Crafting.making(three, bench3)))

	var walls_before := Crafting.kits(three, &"wall")
	var fences_before := Crafting.kits(three, &"fence")
	Sim.advance(three, int(recipe["ticks"])
		+ int((GameData.RECIPES[&"wall_kit"] as Dictionary)["ticks"]) + 6)
	expect(Crafting.kits(three, &"barricade") == 1, "the first one arrives",
		str(Crafting.kits(three, &"barricade")))
	expect(Crafting.kits(three, &"wall") == walls_before + 1,
		"and the third", str(Crafting.kits(three, &"wall")))
	expect(Crafting.kits(three, &"fence") == fences_before,
		"and nothing at all from the one that was cancelled",
		str(Crafting.kits(three, &"fence")))

	# **A queue advances on the tick whether anyone is looking**, and it is one
	# item at a time rather than all of them at once.
	var watched := State.create(1903)
	Resources.gain(watched, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench4 := Building.anchor_of(watched,
		Farm.cells_with(watched, &"workshop")[0])
	for _i in 3:
		Crafting.enqueue(watched, bench4, &"barricade_kit")
	Sim.advance(watched, int(recipe["ticks"]) + 1)
	expect(Crafting.kits(watched, &"barricade") == 1,
		"one item's worth of ticks makes one item",
		str(Crafting.kits(watched, &"barricade")))
	expect(Crafting.queue_at(watched, bench4).size() == 2,
		"and the queue is one shorter",
		str(Crafting.queue_at(watched, bench4).size()))
	var progress := Crafting.progress_at(watched, bench4)
	expect(int(progress[1]) == int(recipe["ticks"]),
		"the next one has a full run ahead of it", str(progress))
	expect(int(progress[0]) > 0 and int(progress[0]) <= int(progress[1]),
		"and some of it left", str(progress))

	# **A queue you cannot pay for waits rather than being thrown away.**
	var early := State.create(1904)
	var bench5 := Building.anchor_of(early,
		Farm.cells_with(early, &"workshop")[0])
	for id in GameData.RESOURCES:
		Resources.spend(early, id, Resources.amount(early, id))
	for _i in 3:
		expect(Crafting.enqueue(early, bench5, &"barricade_kit"),
			"queuing with an empty larder is allowed")
	expect(Crafting.is_stalled(early, bench5), "and the front one waits")
	Sim.advance(early, 200)
	expect(Crafting.kits(early, &"barricade") == 0, "nothing is made",
		str(Crafting.kits(early, &"barricade")))
	expect(Crafting.queue_at(early, bench5).size() == 3,
		"and nothing is thrown away for being early",
		str(Crafting.queue_at(early, bench5).size()))

	Resources.gain(early, {GameData.WOOD: 200, GameData.STONE: 200})
	Sim.advance(early, int(recipe["ticks"]) + 4)
	expect(Crafting.kits(early, &"barricade") == 1,
		"and the wood arriving sets the whole thing going",
		str(Crafting.kits(early, &"barricade")))

	print("  a queue of %d, one at a time, %d ticks each"
		% [GameData.QUEUE_LENGTH, int(recipe["ticks"])])

	_completed += 1     # last line: an abandoned group never gets here


## 0038 - the farm does not care where you are standing.
func _task_0038_idle() -> void:
	# **The same day, twice, with the farmer in two different places.**
	#
	# This is the whole task in one assert. Not "I read the code and nothing
	# looked at the camera" - the same scripted day run with the player parked
	# at the pond and parked at the bench, and every number that came out of
	# the farm compared.
	var pond_day := _a_busy_day(2000, true)
	var bench_day := _a_busy_day(2000, false)

	for key in GameData.sorted_names(pond_day.keys()):
		if key == &"where":
			continue        # the one thing that is meant to differ
		expect(pond_day[key] == bench_day[key],
			"a day at the pond and a day at the bench produce the same %s" % key,
			"%s against %s" % [pond_day[key], bench_day[key]])
	print("  a day at the pond: %s" % str(pond_day))

	# **A scripted day where the player never leaves the pond still finishes
	# the crafting queue.** The done-when, named.
	expect(int(pond_day[&"kits"]) >= 3,
		"three queued at dawn, three in the pile by dusk, nobody watching",
		str(pond_day[&"kits"]))
	expect(int(pond_day[&"oil"]) > 0, "the press pressed", str(pond_day[&"oil"]))
	expect(int(pond_day[&"grown"]) > 0, "the crops grew",
		str(pond_day[&"grown"]))
	expect(int(pond_day[&"meat"]) > 0, "the animals produced",
		str(pond_day[&"meat"]))

	# **And a bench records what it did**, so walking back up to it is not a
	# silent jump from three queued to three kits in the pile.
	var log := State.create(2001)
	Resources.gain(log, {GameData.WOOD: 200, GameData.STONE: 200})
	var bench := Building.anchor_of(log, Farm.cells_with(log, &"workshop")[0])
	expect(Crafting.made_at(log, bench).is_empty(),
		"a bench nobody has used has made nothing")
	expect(Crafting.last_delivery_at(log, bench) == -1,
		"and has never delivered anything")

	for _i in 2:
		Crafting.enqueue(log, bench, &"barricade_kit")
	var ticks := int((GameData.RECIPES[&"barricade_kit"]
		as Dictionary)["ticks"])
	Sim.advance(log, ticks + 2)
	expect(int(Crafting.made_at(log, bench).get(&"barricade_kit", 0)) == 1,
		"one delivered", str(Crafting.made_at(log, bench)))
	var first_at := Crafting.last_delivery_at(log, bench)
	expect(first_at > 0, "on a tick it wrote down", str(first_at))

	Sim.advance(log, ticks + 2)
	expect(int(Crafting.made_at(log, bench).get(&"barricade_kit", 0)) == 2,
		"two delivered", str(Crafting.made_at(log, bench)))
	expect(Crafting.last_delivery_at(log, bench) > first_at,
		"and the second is later than the first",
		str(Crafting.last_delivery_at(log, bench)))

	# The record outlives the queue, which is the point of keeping it apart.
	expect(not Crafting.busy(log, bench), "the queue has emptied")
	expect(int(Crafting.made_at(log, bench).get(&"barricade_kit", 0)) == 2,
		"and the record of what it made is still there",
		str(Crafting.made_at(log, bench)))

	# **The tick cost of a fully built farm stays inside the budget.**
	#
	# The budget is that a tick takes less than a tick: at 30Hz the game has
	# 33 milliseconds and everything else on the machine needs some of them.
	# Task 0102 owns tuning this; what is asserted here is a wide margin, and
	# the real number is printed either way so a regression is visible in the
	# log before it is a failure.
	var loaded := _a_full_farm(2002)
	var towers := Farm.cells_with(loaded, &"gun_tower").size()
	var planted := int(Farming.counts(loaded)["planted"])
	var started := Time.get_ticks_usec()
	Sim.advance(loaded, 1800)               # a minute of a busy farm
	var spent := Time.get_ticks_usec() - started
	var per_tick := float(spent) / 1800.0
	var budget := 1000000.0 / float(GameData.TICK_HZ)
	# **Counted after the run, not before it.** The first version printed the
	# entity count before advancing, which is always zero: the waves had not
	# started yet. A number in a log that is not the number being measured is
	# worse than no number.
	print("  a full farm (%d towers, %d crops, %d zombies): %.1f us a tick"
		% [towers, planted, Entities.count(loaded), per_tick])
	print("    which is %.0f%% of the %.0f us a tick at %dHz allows"
		% [per_tick * 100.0 / budget, budget, GameData.TICK_HZ])
	expect(per_tick < budget / 2.0,
		"a busy farm ticks in well under half its budget",
		"%.1f us against %.0f" % [per_tick, budget])

	_completed += 1     # last line: an abandoned group never gets here


## A day with everything on the farm working, and the farmer parked somewhere.
##
## `at_the_pond` decides where they stand and nothing else. Two runs of this
## with different answers have to come out identical in every number, which is
## what "no system may depend on being on screen" means when it is measured
## rather than read.
func _a_busy_day(seed_value: int, at_the_pond: bool) -> Dictionary:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 400, GameData.STONE: 400,
		GameData.IRON: 400, GameData.CORN: 80, GameData.MONEY: 400})

	# A field, sown and watered.
	var seeds := Farming.seeds()
	var sown := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		if sown >= 9:
			break
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, cell)
		Farming.act(state, cell)
		sown += 1

	# A queue on the bench.
	var bench := Building.anchor_of(state, Farm.cells_with(state, &"workshop")[0])
	for _i in 3:
		Crafting.enqueue(state, bench, &"barricade_kit")

	# A press, running.
	var press := _room_for(state, Building.size_of(&"press"))
	Resources.gain(state, Building.cost_of(&"press"))
	Building.place(state, &"press", press)
	Crafting.select_recipe(state, &"press_oil")
	for _i in 3:
		Crafting.enqueue(state, press, &"press_oil")

	# And the farmer, parked, doing nothing at all for the whole day.
	var stand: Vector2i = bench + Vector2i(0, 1)
	if at_the_pond:
		var wet: Vector2i = Farm.cells_of(state, Farm.Terrain.WATER)[0]
		stand = wet + Vector2i(0, -1)
	var who: Dictionary = state["player"]
	who["pos"] = [stand.x * Player.SUBTILE + Player.SUBTILE / 2,
		stand.y * Player.SUBTILE + Player.SUBTILE / 2]

	var grown_before := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		grown_before += int(Farming.plot(state, found).get("growth", 0))

	Sim.advance(state, GameData.DAY_TICKS - int(state["tick"]))

	var grown := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		grown += int(Farming.plot(state, found).get("growth", 0))
	var meat := 0
	for found in Farm.cells_with(state, &"cow") + Farm.cells_with(state, &"chicken"):
		meat += Livestock.ready_at(state, found)

	return {
		&"where": &"pond" if at_the_pond else &"bench",
		&"kits": Crafting.kits(state, &"barricade"),
		&"oil": Resources.amount(state, GameData.OIL),
		&"grown": grown - grown_before,
		&"meat": meat,
		&"made": Crafting.made_at(state, bench).get(&"barricade_kit", 0),
		&"hash": _hash_of_the_farm(state),
	}


## The whole state except the parts that are *supposed* to depend on where the
## farmer is standing.
##
## A far stronger check than comparing half a dozen counters: it says every
## byte of the farm came out the same. The four exceptions are the complete
## list of things in this game that care about the player's position, and each
## of them is deliberate:
##
## - `player` and `intent` are the farmer themselves.
## - `water_can` fills by standing next to water (task 0029), so a day at the
##   pond ends with a full can and a day at the bench does not.
## - `fishing` is a line in the water, which is given up by walking away
##   (task 0030).
##
## **Nothing that produces anything is on that list**, which is the task.
func _hash_of_the_farm(state: Dictionary) -> int:
	var bare: Dictionary = state.duplicate(true)
	for key in ["player", "intent", "water_can", "fishing"]:
		bare.erase(key)
	return State.hash_of(bare)


## A farm with as much on it as the MVP allows, for the tick budget.
func _a_full_farm(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	Resources.gain(state, {GameData.WOOD: 4000, GameData.STONE: 4000,
		GameData.IRON: 4000, GameData.OIL: 400, GameData.GUNPOWDER: 400,
		GameData.INCENDIARY: 400, GameData.CORN: 400})

	# Every soil tile planted.
	var seeds := Farming.seeds()
	var sown := 0
	for found in Farm.cells_of(state, Farm.Terrain.SOIL):
		var cell: Vector2i = found
		Farming.select_seed(state, StringName(seeds[sown % seeds.size()]))
		Farming.act(state, cell)
		Farming.act(state, cell)
		sown += 1

	# As many towers as will fit on the east half.
	var built := 0
	for y in range(1, Grid.HEIGHT - 1):
		for x in range(19, Grid.WIDTH - 1):
			if Building.place(state, &"gun_tower", Vector2i(x, y)):
				built += 1
	var gen := _room_for(state, Building.size_of(&"generator"))
	Building.place(state, &"generator", gen)

	# A night, with everything the table sends.
	state["day"] = GameData.MVP_NIGHTS
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	return state


## 0039 - time passing, without taking the choice away.
func _task_0039_clock() -> void:
	var state := State.create(2100)

	# **A day is a lever's worth of ticks**, and the clock counts today rather
	# than the session.
	expect(int(state["day_tick"]) == 0, "a day starts at zero")
	expect(Phases.day_percent(state) == 0, "and nought through it")
	Sim.advance(state, GameData.DAY_TICKS / 2)
	expect(absi(Phases.day_percent(state) - 50) <= 1, "halfway at halfway",
		str(Phases.day_percent(state)))
	expect(int(state["day_tick"]) == GameData.DAY_TICKS / 2,
		"the day clock is the day's", str(state["day_tick"]))

	# **Dusk is where the lever says, and it is not the end of anything.**
	expect(not Phases.is_dusk(state), "halfway is not dusk")
	expect(Phases.overtime_percent(state) == 0, "and nothing is overtime yet")
	Sim.advance(state, GameData.DUSK_AT_TICK - int(state["day_tick"]))
	expect(Phases.is_dusk(state), "dusk falls where the lever says",
		str(state["day_tick"]))
	expect(int(state["phase"]) == Phases.DAY,
		"and the day carries on through it",
		Phases.name_of(int(state["phase"])))

	# **A player who ignores the clock is not punished for it.** The done-when,
	# and the whole of `design.md`'s promise that the player switches reality
	# when they want to.
	var stubborn := State.create(2101)
	Resources.gain(stubborn, {GameData.WOOD: 100, GameData.MONEY: 100})
	var plot: Vector2i = Farm.cells_of(stubborn, Farm.Terrain.SOIL)[0]
	Farming.act(stubborn, plot)
	Farming.act(stubborn, plot)
	var house_before := int(stubborn["house_hp"])
	var purse := Resources.amount(stubborn, GameData.MONEY)
	var wood := Resources.amount(stubborn, GameData.WOOD)

	# Three whole days' worth of ticks without ever pressing the night button.
	Sim.advance(stubborn, GameData.DAY_TICKS * 3)
	expect(int(stubborn["phase"]) == Phases.DAY,
		"the night never starts itself, however long you leave it",
		Phases.name_of(int(stubborn["phase"])))
	expect(int(stubborn["day"]) == 1, "and the day counter does not creep",
		str(stubborn["day"]))
	expect(int(stubborn["house_hp"]) == house_before,
		"the house is untouched", str(stubborn["house_hp"]))
	expect(Resources.amount(stubborn, GameData.MONEY) == purse,
		"nothing is taken", str(Resources.amount(stubborn, GameData.MONEY)))
	expect(Resources.amount(stubborn, GameData.WOOD) >= wood,
		"nothing spoils", str(Resources.amount(stubborn, GameData.WOOD)))
	expect(Farming.is_ready(stubborn, plot),
		"and the crop that was planted is simply ready")
	expect(Farming.crop_on(stubborn, plot) != &"",
		"rather than having withered for being left")
	print("  three days past dusk: %d%% through, %d%% overtime, house %d/%d"
		% [Phases.day_percent(stubborn), Phases.overtime_percent(stubborn),
			int(stubborn["house_hp"]), GameData.HOUSE_HP])

	# The nudge is a nudge: a number that grows, nothing that bites.
	expect(Phases.overtime_percent(stubborn) > 100,
		"the overtime is plainly visible",
		str(Phases.overtime_percent(stubborn)))
	expect(Phases.is_dusk(stubborn), "and it is still saying so")

	# **The night starts when the player says so, at any hour.**
	(stubborn["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(stubborn, 1)
	expect(int(stubborn["phase"]) == Phases.PREPARATION,
		"pressing the button three days late still works",
		Phases.name_of(int(stubborn["phase"])))

	var early := State.create(2102)
	(early["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(early, 1)
	expect(int(early["phase"]) == Phases.PREPARATION,
		"and pressing it at dawn works too - it is the player's choice",
		Phases.name_of(int(early["phase"])))

	# **The clock stops in the shop and resumes on close.** The other
	# done-when, and it changed an assert of task 0020's that said the
	# opposite - see the note in that group.
	var shopping := State.create(2103)
	var shop_plot: Vector2i = Farm.cells_of(shopping, Farm.Terrain.SOIL)[0]
	Farming.act(shopping, shop_plot)
	Farming.act(shopping, shop_plot)
	Sim.advance(shopping, 30)
	var clock := int(shopping["day_tick"])
	var grown := int(Farming.plot(shopping, shop_plot)["growth"])

	Shop.open(shopping)
	expect(Shop.is_open(shopping), "the stall is open")
	Sim.advance(shopping, 300)
	expect(int(shopping["day_tick"]) == clock,
		"ten seconds of haggling is not ten seconds of the day",
		str(int(shopping["day_tick"]) - clock))
	expect(int(Farming.plot(shopping, shop_plot)["growth"]) == grown,
		"and the crop did not grow through it",
		str(Farming.plot(shopping, shop_plot)["growth"]))

	Shop.close(shopping)
	Sim.advance(shopping, 60)
	expect(int(shopping["day_tick"]) == clock + 60,
		"and closing it starts the day again",
		str(int(shopping["day_tick"]) - clock))
	expect(int(Farming.plot(shopping, shop_plot)["growth"]) == grown + 60,
		"with the crop picking up where it left off",
		str(Farming.plot(shopping, shop_plot)["growth"]))

	# **The inventory is not a menu**, which is the other half of the
	# distinction: a glance at your own pockets stops nothing.
	expect(StringName(shopping["open_panel"]) == &"",
		"nothing is open now")
	var looking := int(shopping["day_tick"])
	Sim.advance(shopping, 30)
	expect(int(shopping["day_tick"]) == looking + 30,
		"and with no modal panel up the day runs",
		str(int(shopping["day_tick"]) - looking))

	# **Cancel still leaves the stall**, which is the one thing that has to
	# work while the world is stopped.
	Shop.open(shopping)
	(shopping["intent"] as Dictionary)["cancel"] = true
	Sim.advance(shopping, 1)
	expect(not Shop.is_open(shopping),
		"cancel gets you out of a stopped world")

	# **Night and the payout are not the day clock.** Stopping for a menu is a
	# daytime rule; a wave does not wait for anybody.
	var nightly := State.create(2104)
	Phases.begin_preparation(nightly)
	Sim.advance(nightly, GameData.PREPARATION_TICKS)
	var night_tick := int(nightly["night_tick"])
	Sim.advance(nightly, 30)
	expect(int(nightly["night_tick"]) == night_tick + 30,
		"the night runs on its own clock",
		str(int(nightly["night_tick"]) - night_tick))
	expect(Phases.day_percent(nightly) == 100,
		"and the day is over as far as the sun is concerned",
		str(Phases.day_percent(nightly)))
	expect(Phases.overtime_percent(nightly) == 0,
		"with no overtime at night", str(Phases.overtime_percent(nightly)))

	_completed += 1     # last line: an abandoned group never gets here


## 0040 - a stall with stock, and no way to make money standing at it.
func _task_0040_shop() -> void:
	var state := State.create(2200)

	# **Buy-then-sell loses money at every price.** The done-when, and the one
	# thing that would break the game if it were false - a single item that
	# could be bought and sold back at a profit is an infinite money button.
	var worst := 999999
	var worst_id := &""
	for id in GameData.sorted_names(GameData.SELL_PRICE.keys()):
		var costs := Shop.buy_price(id)
		var fetches := Shop.sell_price(id)
		expect(costs > fetches,
			"%s costs more than it fetches" % id,
			"$%d against $%d" % [costs, fetches])
		if costs - fetches < worst:
			worst = costs - fetches
			worst_id = id
	print("  the thinnest margin in the shop is %s, %d in the stall's favour"
		% [worst_id, worst])
	expect(worst > 0, "and the thinnest of them is still the stall's",
		str(worst))

	expect(GameData.check_stall(GameData.DAILY_STOCK, GameData.SELL_PRICE,
		GameData.BUY_MARKUP).is_empty(),
		"the shipped stall passes its own check",
		str(GameData.check_stall(GameData.DAILY_STOCK, GameData.SELL_PRICE,
			GameData.BUY_MARKUP)))
	expect(not GameData.check_stall(GameData.DAILY_STOCK,
		GameData.SELL_PRICE, 1.0).is_empty(),
		"and a markup of one is refused - that is the money button")

	# Round-tripped for real, through the ledger, on every single thing.
	for id in Shop.buyable():
		var round_trip := State.create(2201)
		Resources.gain(round_trip, {GameData.MONEY: 5000})
		var purse := Resources.amount(round_trip, GameData.MONEY)
		expect(Shop.buy(round_trip, id, 3), "three %s bought" % id)
		Shop.sell(round_trip, id, 3)
		expect(Resources.amount(round_trip, GameData.MONEY) < purse,
			"buying three %s and selling them back is a loss" % id,
			"%d then %d" % [purse,
				Resources.amount(round_trip, GameData.MONEY)])

	# **Buying is always worse than gathering.** A tree is three wood for three
	# swings and costs nothing; the same wood at the stall is real money.
	var tree: Dictionary = GameData.GATHERING[&"tree"]
	var from_a_tree := int((tree["yield"] as Dictionary)[GameData.WOOD])
	expect(Shop.buy_price(GameData.WOOD) * from_a_tree > 0,
		"a tree's worth of wood costs money at the stall",
		str(Shop.buy_price(GameData.WOOD) * from_a_tree))
	expect(Shop.buy_price(GameData.WOOD)
		> Shop.sell_price(GameData.WOOD),
		"and you cannot chop, sell, and buy back more than you had")

	# **Seeds for all three crops**, side by side with what the choice needs.
	for id in Farming.seeds():
		expect(GameData.CROPS.has(id), "%s is a crop" % id)
		expect(Farming.value_per_day(id) > 0,
			"with a day's worth to compare", str(Farming.value_per_day(id)))
		expect(Farming.seconds_to_grow(id) > 0, "and a growing time")
		expect(Shop.buyable().has(id),
			"and the stall deals in %s itself" % id, str(Shop.buyable()))

	# **Nothing the workshop makes is for sale.** A stall that sold oil would
	# be a way to skip owning a press.
	for id in [GameData.OIL, GameData.GUNPOWDER, GameData.INCENDIARY,
			GameData.FOOD]:
		expect(not Shop.buyable().has(id),
			"the stall does not sell %s - that is what the farm is for" % id)
		expect(Shop.sellable().has(id), "but it will take it off you")

	# ------------------------------------------------- stock, and when it comes

	# **A daily stock, out from the first morning.**
	for id in Shop.buyable():
		expect(Shop.stock_of(state, id) == int(GameData.DAILY_STOCK[id]),
			"day one opens with a full shelf of %s" % id,
			str(Shop.stock_of(state, id)))

	# **It runs out**, and running out is the point.
	var buyer := State.create(2202)
	Resources.gain(buyer, {GameData.MONEY: 100000})
	var shelf := Shop.stock_of(buyer, GameData.STONE)
	expect(Shop.buy(buyer, GameData.STONE, shelf),
		"the whole shelf can be bought", str(shelf))
	expect(Shop.stock_of(buyer, GameData.STONE) == 0, "and then it is empty")
	expect(not Shop.buy(buyer, GameData.STONE, 1),
		"with no more to be had at any price")
	expect(not Shop.can_buy(buyer, GameData.STONE, 1),
		"and the panel is told so rather than finding out")
	expect(Shop.can_buy(buyer, GameData.WOOD, 1),
		"while the rest of the shelf is untouched")

	# All or nothing against the stock, the same as against the purse.
	var few := State.create(2203)
	Resources.gain(few, {GameData.MONEY: 100000})
	var iron := Shop.stock_of(few, GameData.IRON)
	expect(not Shop.buy(few, GameData.IRON, iron + 1),
		"buying more than is there buys none of it")
	expect(Shop.stock_of(few, GameData.IRON) == iron,
		"and the shelf is untouched", str(Shop.stock_of(few, GameData.IRON)))

	# **Refreshes once per day, not once per visit.** The other done-when.
	var visits := State.create(2204)
	Resources.gain(visits, {GameData.MONEY: 100000})
	Shop.buy(visits, GameData.WOOD, 5)
	var left := Shop.stock_of(visits, GameData.WOOD)
	expect(left == int(GameData.DAILY_STOCK[GameData.WOOD]) - 5,
		"five off the shelf", str(left))

	for _visit in 4:
		Shop.open(visits)
		Sim.advance(visits, 5)
		Shop.close(visits)
		Sim.advance(visits, 30)
	expect(Shop.stock_of(visits, GameData.WOOD) == left,
		"four more visits put nothing back on the shelf",
		str(Shop.stock_of(visits, GameData.WOOD)))
	expect(not Shop.restock(visits),
		"and asking for a restock on the same day refuses")

	# A night, and the morning after.
	Phases.begin_preparation(visits)
	Sim.advance(visits, GameData.PREPARATION_TICKS)
	expect(Shop.stock_of(visits, GameData.WOOD) == left,
		"the night puts nothing back either",
		str(Shop.stock_of(visits, GameData.WOOD)))
	Phases.enter_result(visits, true)
	(visits["intent"] as Dictionary)["confirm_result"] = true
	Sim.advance(visits, 2)
	expect(int(visits["phase"]) == Phases.DAY, "morning")
	expect(Shop.stock_of(visits, GameData.WOOD)
		== int(GameData.DAILY_STOCK[GameData.WOOD]),
		"and the shelf is full again",
		str(Shop.stock_of(visits, GameData.WOOD)))

	# **The tabs are a fact about the game**, so the autoplayer can switch
	# them and a test can ask which one is showing.
	expect(Shop.tab(state) == Shop.SELL,
		"the stall opens on selling, which is what you came for",
		str(Shop.tab(state)))
	expect(Shop.show_tab(state, Shop.BUY), "and can be switched to buying")
	expect(Shop.tab(state) == Shop.BUY, "which sticks", str(Shop.tab(state)))
	expect(not Shop.show_tab(state, &"haggle"),
		"there is no third tab")
	expect(Shop.tab(state) == Shop.BUY, "and asking for one changes nothing")

	_completed += 1     # last line: an abandoned group never gets here


## 0041 - day one teaches itself, and teaches nothing by force.
func _task_0041_tutorial() -> void:
	# **Five lines, and seven allowed.** Short enough to read walking.
	var steps := Tutorial.steps()
	expect(steps.size() <= GameData.MAX_TUTORIAL_LINES,
		"day one says no more than the task allows",
		"%d lines" % steps.size())
	expect(GameData.check_tutorial(steps).is_empty(),
		"and the shipped lines pass their own check",
		str(GameData.check_tutorial(steps)))
	var longest := 0
	for entry in steps:
		longest = maxi(longest, (entry as Dictionary)["line"].length())
	print("  day one: %d lines, longest %d characters"
		% [steps.size(), longest])

	var wordy: Array = steps.duplicate(true)
	(wordy[0] as Dictionary)["line"] = "x".repeat(200)
	expect(not GameData.check_tutorial(wordy).is_empty(),
		"a line nobody could read at a glance is refused")
	var twice: Array = steps.duplicate(true)
	twice.append((steps[0] as Dictionary).duplicate())
	expect(not GameData.check_tutorial(twice).is_empty(),
		"and the same step twice")
	var crowded: Array = []
	for i in GameData.MAX_TUTORIAL_LINES + 1:
		crowded.append({"id": StringName("x%d" % i), "line": "a line"})
	expect(not GameData.check_tutorial(crowded).is_empty(),
		"and one line too many")

	# **It teaches the five things the task names.**
	var ids: Array = []
	for entry in steps:
		ids.append(StringName((entry as Dictionary)["id"]))
	for wanted in [&"chop", &"plant", &"craft", &"build", &"night"]:
		expect(ids.has(wanted), "day one covers %s" % wanted, str(ids))

	# **It starts at the beginning and points at something.**
	var state := State.create(2300)
	expect(Tutorial.progress(state) == 0, "nothing done yet")
	expect(Tutorial.current(state)["id"] == &"chop",
		"the first line is about the trees",
		str(Tutorial.current(state)))
	expect(Tutorial.points_at(state) != Tutorial.NOWHERE,
		"and it points at a tile", str(Tutorial.points_at(state)))
	expect(Farm.occupant(state, Tutorial.points_at(state)).get("id", &"")
		== &"tree", "which has a tree on it",
		str(Farm.occupant(state, Tutorial.points_at(state))))

	# It points at the *nearest* one, so it is a label and not a treasure hunt.
	var trees := Farm.cells_with(state, &"tree")
	var here := Player.cell(state)
	var pointed := Tutorial.points_at(state)
	var closest := 1 << 30
	for found in trees:
		var cell: Vector2i = found
		closest = mini(closest, absi(cell.x - here.x) + absi(cell.y - here.y))
	expect(absi(pointed.x - here.x) + absi(pointed.y - here.y) == closest,
		"the nearest one", "%s from %s" % [pointed, here])

	# **A step finishes when the thing happens**, however it happened - which
	# is what makes following the prompts and ignoring them the same game.
	Resources.gain(state, {GameData.WOOD: 5})
	Sim.advance(state, 2)
	expect(Tutorial.is_done(state, &"chop"),
		"wood arriving finishes the first line, whatever brought it")
	expect(Tutorial.current(state)["id"] == &"plant",
		"and the second one is up", str(Tutorial.current(state)))
	expect(Tutorial.points_at(state) != Tutorial.NOWHERE,
		"pointing at bare soil")
	expect(Farm.terrain_at(state, Tutorial.points_at(state))
		== Farm.Terrain.SOIL, "which is soil",
		str(Tutorial.points_at(state)))

	# **A finished step stays finished.**
	Resources.spend(state, GameData.WOOD,
		Resources.amount(state, GameData.WOOD))
	Sim.advance(state, 2)
	expect(Tutorial.is_done(state, &"chop"),
		"selling the wood again does not put the line back")

	# **Nothing is locked.** The done-when: skipping every prompt leaves the
	# game exactly as playable. Run the whole of day one **backwards** - the
	# night button first, which is the last line - and check it all works.
	var rebel := State.create(2301)
	Resources.gain(rebel, {GameData.WOOD: 200, GameData.STONE: 200,
		GameData.IRON: 200, GameData.MONEY: 200})
	expect(Tutorial.current(rebel)["id"] == &"chop",
		"the first line is up and being ignored")

	var spot := _room_for(rebel, Vector2i(1, 1))
	expect(Building.place(rebel, &"gun_tower", spot),
		"a tower goes down while the game is still saying 'chop a tree'")
	var bench := Building.anchor_of(rebel,
		Farm.cells_with(rebel, &"workshop")[0])
	expect(Crafting.enqueue(rebel, bench, &"wall_kit"),
		"and the bench takes a job out of order")
	var plot := _a_plot(rebel)
	Farming.act(rebel, plot)
	Farming.act(rebel, plot)
	expect(Farming.crop_on(rebel, plot) != &"",
		"and a seed goes in the ground")
	Sim.advance(rebel, 2)
	expect(Tutorial.progress(rebel) >= 4,
		"four of the five lines are simply gone, unread",
		str(Tutorial.progress(rebel)))

	# **And night one is still winnable for the player who read nothing.** The
	# other done-when, driven to the payout.
	var armed := State.create(2302)
	Resources.gain(armed, {GameData.WOOD: 200, GameData.IRON: 200})
	var placed := 0
	for y in [7, 9, 11]:
		for x in range(22, 32):
			if placed >= 4:
				break
			if Building.place(armed, &"gun_tower", Vector2i(x, y)):
				placed += 1
	expect(placed == 4, "four towers, which is a day's iron", str(placed))
	expect(Tutorial.progress(armed) == 0,
		"and not a single prompt has been finished on purpose",
		str(Tutorial.progress(armed)))

	(armed["intent"] as Dictionary)["begin_night"] = true
	Sim.advance(armed, 1)
	Sim.advance(armed, GameData.PREPARATION_TICKS)
	for _t in 12000:
		Sim.advance(armed, 1)
		if int(armed["phase"]) != Phases.NIGHT:
			break
	expect(int(armed["phase"]) == Phases.RESULT, "the night resolves",
		Phases.name_of(int(armed["phase"])))
	var payout := Rewards.last(armed)
	expect(bool(payout["survived"]),
		"and night one is survived by somebody who read nothing",
		str(payout))
	print("  night one, having ignored every prompt: %s, house %d/%d"
		% ["survived" if bool(payout["survived"]) else "lost",
			int(payout["house_hp"]), GameData.HOUSE_HP])

	# **Night one is still the tutorial night.** A handful of basic zombies.
	var wave := Waves.table(1)
	expect(Waves.size_of(1) <= 16, "night one is a handful",
		str(Waves.size_of(1)))
	for row in wave:
		expect(StringName((row as Array)[0]) == &"walker",
			"and all of them the basic kind", str(row))

	# **The last line finishes when the night is sent for**, which is the one
	# step the player cannot do by accident.
	var sender := State.create(2303)
	for id in [&"chop", &"plant", &"craft", &"build"]:
		((sender["tutorial"] as Dictionary)["done"] as Array).append(id)
	expect(Tutorial.current(sender)["id"] == &"night",
		"the last line is about the button", str(Tutorial.current(sender)))
	expect(not Tutorial.is_finished(sender), "and it is not finished yet")
	Phases.begin_preparation(sender)
	expect(Tutorial.is_finished(sender),
		"sending for the night finishes day one")

	_completed += 1     # last line: an abandoned group never gets here
