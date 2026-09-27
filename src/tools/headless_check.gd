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
const GROUPS := 10

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
	var spot := Vector2i(12, 8)
	expect(Farm.buildable(state, spot), "an empty patch of grass is buildable")
	var before := State.hash_of(state)
	expect(Farm.place(state, spot, {"id": &"gun_tower", "hp": 60}),
		"a tower goes down")
	expect(State.hash_of(state) != before, "which changed the farm")
	expect(not Farm.buildable(state, spot), "and the cell is taken now")
	expect(not Farm.walkable(state, spot), "and blocks the way")
	expect(Farm.occupant(state, spot)["id"] == &"gun_tower",
		"occupant() says what is there")
	expect(not Farm.place(state, spot, {"id": &"wall"}),
		"a second thing cannot stack on it")
	expect(Farm.remove(state, spot), "and it comes back up")
	expect(State.hash_of(state) == before,
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
	Farm.place(state, Vector2i(13, 8), {"id": &"wall"})
	Phases.begin_preparation(state)
	Sim.advance(state, GameData.PREPARATION_TICKS)
	expect(int(state["phase"]) == Phases.NIGHT, "night fell")
	expect(Farm.occupant(state, Vector2i(13, 8))["id"] == &"wall",
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
	Farm.place(state, Vector2i(12, 8), {"id": &"gun_tower", "hp": 60})
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
	expect(Farm.occupant(loaded, Vector2i(12, 8))["id"] == &"gun_tower",
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
