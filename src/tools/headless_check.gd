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
const GROUPS := 18

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
	expect(GameData.RESOURCES.size() == 13, "thirteen resources",
		str(GameData.RESOURCES.size()))
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
	expect(Farm.cells_with(state, &"ore").size() == 6, "six ore nodes",
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
	expect(trees.size() == 76, "the wood is the size the map says",
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
	expect(loose.size() == 7, "seven boulders on the lawn", str(loose.size()))
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
	expect(not Crafting.start(broke, poor_bench, &"barricade_kit"),
		"starting it anyway does nothing")
	expect(not Crafting.busy(broke, poor_bench), "and leaves the bench free")

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

	# **Nothing pauses.** design.md section 13 is about a farm that runs
	# itself, and a shop that stopped the world would be the one place it did
	# not.
	var plot: Vector2i = Farm.cells_of(state, Farm.Terrain.SOIL)[0]
	Interact.complete(state, plot, &"till")
	Interact.complete(state, plot, &"plant")
	var growth_before := int(Farming.plot(state, plot)["growth"])
	Sim.advance(state, 60)
	expect(int(Farming.plot(state, plot)["growth"]) == growth_before + 60,
		"the wheat kept growing while the player haggled",
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
	var cold := State.create(507)
	Phases.begin_preparation(cold)
	Sim.advance(cold, GameData.PREPARATION_TICKS)
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
	var started := Time.get_ticks_usec()
	Sim.advance(crowd, 200)
	var per_tick := float(Time.get_ticks_usec() - started) / 200.0
	print("  fifty zombies: %.1f us a tick" % per_tick)
	expect(per_tick < 1000.0, "fifty zombies cost under a millisecond a tick",
		"%.1f us" % per_tick)

	_completed += 1     # last line: an abandoned group never gets here


## A farm at night with nothing on it yet.
func _fresh_night(seed_value: int) -> Dictionary:
	var state := State.create(seed_value)
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	return state


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
