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
const GROUPS := 6

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
